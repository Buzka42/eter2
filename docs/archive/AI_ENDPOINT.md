# Eter · the endpoint contract

What the client sends, what it expects back, and what the server is forbidden
to do. The client half is implemented in `app/lib/core/ai/transport.dart` and
tested in `app/test/ai_transport_test.dart`; this file is the other half, which
only the product owner can build.

---

## 1. What the client does

One HTTPS POST per call. Nothing else in the app opens a socket.

```
POST <ETER_AI_ENDPOINT>
authorization: Bearer <ETER_AI_TOKEN>
x-eter-install: <16 random bytes, hex — omitted when the client has none>
content-type: application/json; charset=utf-8

{
  "call": "guidance" | "journalDayStory" | "journalInterpretation"
        | "vesselReadings" | "positions",
  "promptVersion": 1,
  "system": "<the instruction, built on the device>",
  "user": { ...the bounded context, exactly as the contract built it... },
  "responseSchema": { ...the shape the parser will enforce... }
}
```

`x-eter-install` is for metering and nothing else. **The server must not forward it
to the model, log it, or store it unhashed** — see `AI_FLOW.md` §1 for what it is
made of and why it is a header rather than a field. Treat its absence as normal and
fall back to the connecting address.

The endpoint and token come from `--dart-define` at build time:

```bash
flutter build appbundle --release --dart-define=ETER_AI_ENDPOINT=https://… --dart-define=ETER_AI_TOKEN=…
```

A build compiled without `ETER_AI_ENDPOINT` has no transport at all. That is a
supported, shippable configuration — the app is complete without a model and
every surface says so rather than pretending. Plain `http://` is refused
client-side before anything is sent.

## 1a. Running the whole thing on one machine

`app/tool/dev_endpoint.dart` is a working stand-in that does the two things
that matter — it holds the credential, and it forwards the triple unchanged.
It listens on loopback only and has no authentication worth the name, so it is
for development and nothing else.

```bash
dart run tool/dev_endpoint.dart
```

It reads the key from `GEMINI_API_KEY`, or from `app/tool/dev_endpoint.secret`
(one line, gitignored). Model defaults to `gemini-3.5-flash-lite`; override
with `ETER_DEV_MODEL`.

Then, from `app/`:

```bash
flutter run --dart-define=ETER_AI_ENDPOINT=http://10.0.2.2:8787
```

`10.0.2.2` is how the Android emulator reaches its host; use `127.0.0.1` for a
desktop build. Debug builds may reach a cleartext loopback endpoint — release
builds cannot, and do not merge the config that would let them.

To check the whole chain without opening the app:

```bash
flutter test test/manual/live_smoke_test.dart --dart-define=ETER_LIVE_SMOKE=true
```

That drives all five contracts through the real transport and runs each real
parser over what comes back. It is the fastest way to tell a transport problem
from a prompt problem, and it prints any response a parser refuses.

## 2. What the server must do

**Hold the model key.** This is the entire reason the endpoint exists. The
client authenticates to *you*; you authenticate to the model provider. A build
of Eter carrying a model key would hand that key to everyone who installed it.

**Forward `system`, `user` and `responseSchema` unchanged.** The payload's
boundedness is the privacy guarantee — see `AI_FLOW.md` §1 for what is
excluded by construction and why.

**Authenticate the caller.** The bearer token above is a placeholder for
whatever scheme you choose; the client sends whatever it was compiled with and
cares only that the endpoint accepts it.

**Meter per `call`.** The five calls have very different frequencies and costs.
`call` is on the wire precisely so you can route, rate-limit and bill them
separately without inspecting the payload.

## 3. What the server must not do

- **Add context of its own.** Not the user's identity, not a history, not a
  "helpful" system preamble. The client already built the complete prompt, and
  anything the server adds is content nobody consented to.
- **Repair the model's JSON.** Return it as it came. The parsers in each
  contract are the validation that keeps invented content out of a person's
  record, and a helpful repair upstream defeats them.
- **Substitute a fallback on failure.** Return an error. A day with no guidance
  is a correct outcome; a day with guidance nobody composed is not.
- **Log the payload.** It is one person's health records and, for two of the
  five calls, their own prose. Log the `call`, the `promptVersion`, the
  latency, the token counts and the status. Not the body.

## 4. What the client accepts back

Either the model's raw text as the whole body, or `{"raw": "<text>"}`.
`{"error": "<reason>"}` surfaces as a transport failure. An empty body is a
failure. Non-2xx is a failure. Every failure reaches the surface that asked as
a stated absence, never as content.

The client does not parse the model's answer — it hands the string to the
contract's own parser, which validates shape, bounds and safety before a single
character is stored.

## 5. A minimal shape

Roughly forty lines in any runtime that can hold a secret. Pseudocode, because
the choice of provider and host is yours:

```
on POST:
  reject unless caller is authenticated
  reject unless body.call is one of the five
  record(call, promptVersion, caller)          # not the body
  answer = model.generate(
      system: body.system,
      user:   json(body.user),
      schema: body.responseSchema,             # if the provider supports it
  )
  return { "raw": answer.text }                # unparsed, unrepaired
on failure:
  return { "error": reason }, non-2xx
```

## 6. Before the first real call ships

Record the fixture set from `AI_FLOW.md` §5.5 — a good, a malformed, an unsafe
and an empty response for each of the five calls — and test the parsers against
them. Today they are tested against hand-written JSON, which proves the parsers
self-consistent and nothing more.
