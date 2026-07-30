// The endpoint from docs/AI_ENDPOINT.md, as a Cloudflare Worker.
//
// This is the deployable version of tool/dev_endpoint.dart. It exists because
// the key has to live somewhere that is not the phone and not a laptop that
// has to stay awake: Workers' free tier needs no card, and the key is stored
// as an encrypted secret rather than in the source.
//
// Deploy:
//   npm install -g wrangler
//   wrangler login
//   wrangler secret put GEMINI_API_KEY      # paste the key, never commit it
//   wrangler secret put ETER_CLIENT_TOKEN   # any long random string
//   wrangler deploy
//
// Then build the app against it:
//   flutter build apk --release \
//     --dart-define=ETER_AI_ENDPOINT=https://<name>.<subdomain>.workers.dev \
//     --dart-define=ETER_AI_TOKEN=<the same client token>
//
// What it deliberately does not do: add context, repair the model's JSON,
// substitute a fallback, or log a payload. See §3 of AI_ENDPOINT.md for why
// each of those would break something the app depends on.

// Each call, and how much room it gets to choose its words.
//
// Not one setting for all five. Guidance, readings and positions are writing,
// and writing at 0.2 reads like a form letter. Interpretation is not writing:
// it derives kcal, grams, reps and kilograms from prose, and the same page
// must produce the same numbers today and on a retry tomorrow — at 0.7 it did
// not. The day story sits between: it is prose, but prose that must stay close
// to what someone actually wrote.
const CALLS = new Map([
  ['guidance', 0.7],
  ['journalDayStory', 0.5],
  ['journalInterpretation', 0.1],
  ['vesselReadings', 0.7],
  ['positions', 0.7],
]);

const MODEL = 'gemini-3.5-flash-lite';

// Per install, per day. Five calls is an ordinary day — guidance once, a day
// story or two, the odd reading — so this is generous room for a heavy user and
// still a wall against a loop.
const INSTALL_DAILY_CAP = 60;

// A short burst window, also per install. Catches a retry loop within seconds
// rather than after it has spent the day's allowance.
const BURST_WINDOW_SECONDS = 60;
const BURST_CAP = 12;

// The whole deployment, as a cost backstop and nothing else. It used to be 500,
// which at five calls a day is a hundred users: a paying customer would have been
// refused because strangers were busy. It is high enough now that reaching it
// means something is wrong rather than that the product is popular.
const GLOBAL_DAILY_CAP = 20000;

// Who is calling, for metering only.
//
// The client sends `x-eter-install`: sixteen random bytes minted on the device,
// derived from nothing about the person, never in the payload. Metering needs
// something stable per install, and the connecting address is not it — behind
// carrier NAT thousands of people share one, so an address-keyed limit throttles
// a whole mobile network while leaving anyone on a home connection unmetered.
//
// The address remains the fallback for a client that sends no id, which is worse
// but not nothing.
//
// Either way the value is hashed with the client token as salt before it is used
// as a key, so the store holds no address and no install id — only a counter
// under an opaque digest that expires.
async function callerKey(request, salt) {
  const install = request.headers.get('x-eter-install');
  const subject = install
    ? `install:${install}`
    : `address:${request.headers.get('cf-connecting-ip') || 'unknown'}`;
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(`${salt}:${subject}`),
  );
  return [...new Uint8Array(digest)]
    .slice(0, 8)
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

// Counting, atomically, which is the part KV cannot do.
//
// The previous version read a counter and wrote back `n + 1`. Two problems, and
// the second is fatal rather than merely sloppy:
//
//   1. Read-then-write is not atomic. Concurrent requests read the same value and
//      both store the same increment.
//   2. KV reads are cached at the edge for up to 60 seconds, and the burst window
//      *was* 60 seconds. So the counter a request read was routinely stale or
//      absent, and the limiter it fed was decorative.
//
// `env.RATE_LIMITER` is Cloudflare's own rate-limiting binding and is atomic and
// consistent. Bind it in `wrangler.toml`. When it is absent this falls back to the
// KV counter, and says so in the log rather than pretending the limit holds —
// enough for development, not enough for paying users.
async function withinLimit(env, key, limitPerPeriod, periodSeconds) {
  if (env.RATE_LIMITER) {
    const { success } = await env.RATE_LIMITER.limit({ key });
    return success;
  }
  if (!env.ETER_USAGE) return true;
  const window = Math.floor(Date.now() / (periodSeconds * 1000));
  const slot = `${key}:${window}`;
  const used = Number((await env.ETER_USAGE.get(slot)) || 0);
  if (used >= limitPerPeriod) return false;
  await env.ETER_USAGE.put(slot, String(used + 1), {
    expirationTtl: Math.max(60, periodSeconds * 2),
  });
  return true;
}

// Length is compared first and short-circuits, which leaks the length and only
// the length — unavoidable without hashing, and a token's length is not the
// secret. Everything after that is fixed-work.
function constantTimeEquals(a, b) {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) {
    difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return difference === 0;
}

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'POST only' }, 405);

    // The caller's credential, not the model's.
    //
    // The comment here used to claim this was "compared in full to avoid leaking
    // length through timing", which `!==` does not do — a JavaScript string
    // comparison stops at the first differing byte. The claim mattered more than
    // the risk: network jitter dwarfs the signal, but a security comment asserting
    // something untrue is worse than no comment. This compares in constant time
    // for real, which is cheap enough not to argue about.
    const auth = request.headers.get('authorization') || '';
    if (!env.ETER_CLIENT_TOKEN || !constantTimeEquals(auth, `Bearer ${env.ETER_CLIENT_TOKEN}`)) {
      return json({ error: 'Not authorised' }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Body must be a JSON object' }, 400);
    }

    const { call, system, user, responseSchema } = body || {};
    if (!CALLS.has(call)) return json({ error: `Unknown call: ${call}` }, 400);
    const temperature = CALLS.get(call);
    if (typeof system !== 'string' || !system || typeof user !== 'object') {
      return json({ error: 'Missing system or user' }, 400);
    }

    // Metering, per install first and per deployment only as a backstop.
    //
    // The order matters: a caller that is over its own limit is refused before it
    // can consume any of the shared allowance. That is the whole correction —
    // previously the shared cap was the *only* real limit, so one looping install
    // could exhaust it and everybody else got the refusal.
    if (env.RATE_LIMITER || env.ETER_USAGE) {
      const caller = await callerKey(request, env.ETER_CLIENT_TOKEN);
      const identified = request.headers.has('x-eter-install');

      if (!await withinLimit(env, `burst:${caller}`, BURST_CAP, BURST_WINDOW_SECONDS)) {
        return json({ error: 'Too many requests. Try again shortly.' }, 429);
      }
      if (!await withinLimit(env, `day:${caller}`, INSTALL_DAILY_CAP, 86400)) {
        return json({ error: 'Daily limit reached. Try again tomorrow.' }, 429);
      }
      if (!await withinLimit(env, 'day:all', GLOBAL_DAILY_CAP, 86400)) {
        // Nobody's fault in particular, and worth logging loudly: reaching this
        // means either real scale or a fault, and the two want different actions.
        console.log(`call=${call} refused=global-cap`);
        return json({ error: 'Guidance is unavailable right now.' }, 429);
      }
      if (!identified) console.log(`call=${call} metered=by-address`);
      if (!env.RATE_LIMITER) console.log('limits=kv-approximate');
    }

    const model = env.ETER_MODEL || MODEL;
    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: system }] },
          contents: [{ role: 'user', parts: [{ text: JSON.stringify(user) }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            // Constrained decoding against the client's own schema. Without
            // it the model invents field names and the app's parsers refuse
            // the answer -- which is correct of them, and useless to everyone.
            ...(responseSchema ? { responseJsonSchema: responseSchema } : {}),
            temperature,
          },
        }),
      },
    );

    if (!upstream.ok) {
      const detail = await upstream.text();
      // Logged without the payload: the request body is one person's records.
      //
      // 404 here means the model name is wrong or retired, which is worth
      // separating from a real failure: it takes down all five calls at once and
      // the fix is a one-line `ETER_MODEL` secret rather than a deploy.
      if (upstream.status === 404) {
        console.log(`call=${call} upstream=404 model=${model} — check the model name`);
      }
      console.log(`call=${call} upstream=${upstream.status}`);
      return json(
        { error: `Model returned ${upstream.status}`, detail: detail.slice(0, 300) },
        502,
      );
    }

    const answer = await upstream.json();
    const text = answer?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== 'string' || !text.trim()) {
      console.log(`call=${call} empty`);
      return json({ error: 'Model returned no text' }, 502);
    }

    console.log(`call=${call} ok`);
    // Unparsed and unrepaired. The app's parsers are the contract.
    return json({ raw: text });
  },
};
