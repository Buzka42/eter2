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

const CALLS = new Set([
  'guidance',
  'journalDayStory',
  'journalInterpretation',
  'vesselReadings',
  'positions',
]);

const MODEL = 'gemini-3.5-flash-lite';

// Free-tier ceilings, enforced here as well as by Google, so a runaway client
// cannot burn the day's quota in a minute. Raise deliberately.
const DAILY_CAP = 500;

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'POST only' }, 405);

    // The caller's credential, not the model's. Compared in full to avoid
    // leaking length through timing.
    const auth = request.headers.get('authorization') || '';
    if (!env.ETER_CLIENT_TOKEN || auth !== `Bearer ${env.ETER_CLIENT_TOKEN}`) {
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
    if (typeof system !== 'string' || !system || typeof user !== 'object') {
      return json({ error: 'Missing system or user' }, 400);
    }

    // A day counter in KV when one is bound; without it the Google-side free
    // tier is the only ceiling, which is still a ceiling and still not a bill.
    if (env.ETER_USAGE) {
      const day = new Date().toISOString().slice(0, 10);
      const used = Number((await env.ETER_USAGE.get(day)) || 0);
      if (used >= DAILY_CAP) {
        return json({ error: 'Daily cap reached. Try again tomorrow.' }, 429);
      }
      await env.ETER_USAGE.put(day, String(used + 1), {
        expirationTtl: 60 * 60 * 48,
      });
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
            temperature: 0.7,
          },
        }),
      },
    );

    if (!upstream.ok) {
      const detail = await upstream.text();
      // Logged without the payload: the request body is one person's records.
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
