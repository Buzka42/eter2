# Eter · how it actually works

The model calls, the endpoint they go to, what is stored on the device, and the
art. Four documents were folded in here on 5 August 2026 — the AI flow, the endpoint
contract, data storage and the asset manifest — and their originals are in
`archive/`.

If you are new to the repository and want one thing to read before touching the
model layer, read **the trust boundary** in the AI flow below. It is the section
that says what may never leave the device, and it is the one property this
product is built to keep.

## What is in here

1. **The AI flow** — six kinds of call, what each carries, what it costs, what
   happens when one fails.
2. **The endpoint contract** — what the client sends and what the worker is
   forbidden to do.
3. **Data storage** — every table, its retention, and what the cloud mirror is
   allowed to hold.
4. **Assets** — the commissioned art, what exists and what is still a
   placeholder.

---

## Eter · how the AI flow works

Current as of 5 August 2026, prompt **v14**, schema **15**. Supersedes
`archive/AI_FLOW-2026-07-28.md`.

What leaves the device, what is asked of the model, what is done with the
answer, and what happens when any of it fails.

This document is the authority for the AI boundary. Where it and a code comment
disagree, the code is wrong.

---

### 0. The six calls

Eter makes exactly **six** kinds of model call. There is no chat, no
streaming, no background poll.

| Call | Trigger | Consent required | Writes |
|---|---|---|---|
| **guidance** | Dashboard composes for the day (`AetherComposer`) | `aiConsentAt`; journal material additionally needs `journalAiConsentAt` | 4 `GuidanceHistory` rows + 1 `GuidanceRecalls` row |
| **journalInterpretation** | **Automatic**, on every kept entry — `JournalAutoInterpreter`, max 5 per pass, when the Journal opens | `aiConsentAt` | `JournalEntries.extractionJson` + unconfirmed `NutritionEntries` + `LifestyleEntries` |
| **journalDayStory** | Journal opens, and after each entry saves | `aiConsentAt` **and** `journalAiConsentAt` | One `JournalDayStories` row (story + digest) |
| **vesselReadings** | The moment a birth time is saved, and retried when the Vessel opens if any part is still missing. No control asks for it | `aiConsentAt`, **and a stated birth time** | One `VesselReadings` row per chart **per part** — five reserved keys, the chart's synopsis keeping `configuration` |
| **positions** | `READ TODAY` in the Vessel | `aiConsentAt` | One `TransitReadings` row per (date, chart hash) |
| **letter** | The Journal opens in a new month (`LetterComposer`) | `aiConsentAt`; journal-derived recalls additionally need `journalAiConsentAt` | One `Letters` row per month |

**Six kinds of call, and the Vessel's is made five times.** The Vessel is read
in six parts — the wheel, the twelve houses, the angles, the chart's synopsis,
the figure place by place, and the figure's synopsis — of which the wheel is
device arithmetic and the other five are composed. All five go out under the
**same `vesselReadings` call name**: the worker checks the name and nothing
else, because the prompt and the schema are built on the device. This is why
the split needed no redeploy, and it is why `server/worker.js` still knows
about six names.

Each part caches under its own reserved key, so a part that fails is retried
alone and the four that succeeded are not paid for twice. A part is asked for
**at most once per opening** of the Vessel: the retry hangs on a post-frame
callback, and without that guard a part the model kept refusing would be
requested — and billed — on every frame that touched the surface.

The chart, the Life Path, the Arcana and the daily card involve **no model at
all** — they are device arithmetic (`core/symbolic`, `core/arcana`).

Every call is bounded, provider-independent, and fail-closed: a refusal, a
malformed answer, or an unsafe one writes nothing and says so on the surface.

Code map:

```
core/ai/prompts.dart        the system instruction + JSON Schema for all six
                            (and `vesselPart`, one per part of the Vessel)
core/ai/transport.dart      the only network call in the app; six thin adapters
server/worker.js            the owner-controlled endpoint (Cloudflare Worker)
core/aether/*               guidance: assemble → request → prompt → parse → store
core/journal/*              interpretation and the day story
core/vessel/*               readings and positions
```

---

### 1. The trust boundary

#### Never assembled, therefore never sent

`AetherRequest`, `VesselReadingRequest` and the journal payloads have no field
for any of this:

name · date of birth · birth time · birth place · coordinates · timezone ·
account or device identifiers · row ids · vendor/source names · the chart
input hash · anything from a day outside the requested window.

#### The one identifier that leaves the device, and where it stops

`x-eter-install`: sixteen random bytes minted on first use
(`core/ai/install_id.dart`), sent as an **HTTP header** and never assembled into
a payload. The endpoint meters on it and drops it; it does not reach the model,
and a test asserts it is absent from the request body.

It was added because the endpoint's only other way to tell callers apart was the
connecting address, and that is wrong twice: behind carrier NAT thousands of people
share one, and the deployment's cap was global — so one looping install could spend
the day's budget and every other person, including a paying one, would be refused
for it.

What keeps it cheap: it is derived from nothing about the person, it changes on
reinstall, `deleteAllLocalData` erases it, and the server stores only a counter
under a salted hash of it with a short expiry. Nobody holding it can link it to an
account, an address or a name. It is deliberately *not* a hardware or advertising
identifier, which would have been less code and materially worse — those are stable
across reinstalls, shared between apps, and personal data on their own in several
jurisdictions.

Null is supported: a client that sends none is metered by address instead, and the
endpoint logs `metered=by-address` rather than silently doing something else.

Age crosses as **derived years**. The register crosses as a mode name.
Reliability crosses as two booleans. The chart crosses as *already-computed
placements* (sun sign, moon sign, optional ascendant, Life Path, personal year,
sun card) — never the inputs they came from.

#### What each call actually sends

- **guidance** — up to 7 days of `{localDate, steps, activeKcal, sleepMinutes,
  restingHeartRate, hrvMs}` (days with no records are omitted, never
  zero-filled); derived age; optional body-fat %; the mode; optional symbolic
  block; up to 4 patterns as `{summary, confidence, observations, window}`,
  strongest first; self-reports as `{localDate, kind, value?,
  durationMinutes?, note?}`; and — only under journal consent — per-day
  digests plus up to **5 raw entries inside a 1200-character budget**,
  whitespace-normalised, excluding anything marked `KEEP LOCAL`. Days already
  reduced to a digest do not also travel as prose.

  A passage that does not fit is cut **at a word boundary**, marked with `…`
  and `"truncated": true`, and the instruction gains a paragraph saying a
  marked passage is incomplete. A remnant shorter than about a clause is
  dropped rather than sent.

  Self-reports split by origin: a margin check-in (`source: 'self-report'`)
  crosses on general AI consent; one derived from a page (`source:
  'journal:<id>'`) is prose in another shape and crosses only under journal
  consent.

  Plus `recalled` — a fortnight of Aether's own compressed notes. See §1a.
- **journalInterpretation** — one entry's text, plus one clarification string
  if the model previously asked for one. Nothing else: not the day's other
  entries, not the health context.
- **journalDayStory** — every kept, non-excluded entry for one local date, with
  timestamps. This is the widest payload in the app; it exists so that guidance
  can send a bounded digest instead of raw prose.
- **vesselReadings** — the whole configuration in one request: every position
  with its key, label, resolved card and that card's shipped keywords, plus the
  two reliability booleans. It answers with three to five *movements*, each a
  titled passage about how several placements stand to each other.

  It used to send a few positions at a time and answer with one passage each.
  What came back was correct and generic — eighteen entries on a full chart,
  each of which had seen one placement and never the chart. Nothing is composed
  without a birth time: the angles are most of what makes a configuration
  particular, and a reading of a noon-cast chart would be cached for life.
- **positions** — today's date, moon phase and sign, sun sign, and the list of
  contacts already computed on device with aspect, orb and applying/separating.

#### 1a. Memory

Each composition returns a fifth field alongside the four dimensions:
`recall`, at most 160 characters, telegraphic. It is never shown to anyone. It
is written to `GuidanceRecalls` (one row per local day, replaced on recompose)
together with that day's `primaryAction`.

The next fourteen days of those notes travel with every request, oldest first,
**never including today** — a note in its own request's fingerprint would make a
day want recomposing the moment it finished.

The instruction tells the model to write like a telegram: no articles, no
hedges, no complete sentences. `"third short night. hrv still down. work
deadline friday. offered early wind-down."` — not the prose it came from, which
is already in `GuidanceHistory`.

Reading them back, three limits are stated and all three are load-bearing:

- **They are the model's words, never the person's.** Handed a note about a hard
  week, a model will otherwise write "you told me the week was hard", and nobody
  told it anything.
- **A note is not evidence.** It cannot support a claim about a body and can
  never appear in `evidence` — `AetherEvidenceScope` would reject it anyway,
  since notes carry no numbers from the payload.
- **Today outranks the thread.** If the records disagree with a note, the records
  are what happened.

Referring back explicitly *is* wanted: "the third short night this week", "the
same stretch you were in on Monday". The prompt says so — "a companion that
cannot say 'again' is not one."

Consent: each row records `usedJournal`, true when the composition could see
journal material. Withdrawing `journalAiConsentAt` stops those notes travelling,
so revoking cannot leave last week's pages reaching the model laundered through
Eter's own prose.

The note is validated by `AetherSafetyPolicy` like anything else composed here —
it is never displayed, but it seeds the next request.

#### How the shares are stated

Guidance names three proportions explicitly, because a vaguer instruction
("blend them") produces whichever the model finds easiest, which is always the
numbers:

| Register | Journal & self-reports | Chart | Measured |
|---|---|---|---|
| Grounded | 40% | 20% | 40% |
| Balanced, by day | 50% | 25% | 25% |
| Balanced, after sunset | 45% | 40% | 15% |
| Immersive, by day | 40% | 40% | 20% |
| Immersive, after sunset | 30% | 60% | 10% |

The journal is the largest share in every register except immersive at night —
it is the only input that says *why* a day went the way it did. In grounded the
symbolic share is emphasis only and never reaches the words.

**Where the sky is the louder half, the payload changes with the shares.**
Guidance read as health reporting even on immersive, and the stated 40% was not
the reason: the symbolic half arrived as a *single sentence* while the measured
half arrived as a table, so there was nothing to spend the share on. A model
cannot weight what it was not given. In immersive, and in balanced once the sun
is down, today's Positions passage travels in full rather than as its
one-sentence note — already written and already validated by the Positions
call's own safety policy, so nothing new is composed to get it there. Grounded
never leans; that register exists to be plain. The resolved register comes from
the Dashboard, which is the only place that has a horizon and a clock.

With no journal material at all, that share is redistributed proportionally
between the other two and the model is told the material is absent
(`weightsWithoutJournal`). Naming a 50% share of something not in the payload
invites the model to fill it.

The shares are described as *where a reading draws from, not a quota to fill*:
"If a share has nothing behind it today, that share is simply smaller and you
say less."


#### Consent

Two independent flags on the profile row, both nullable timestamps, both
re-read on every pass rather than cached:

- `aiConsentAt` — gates all six calls.
- `journalAiConsentAt` — additionally gates journal *prose and digests*
  reaching guidance, and gates the day story entirely.

Revoking `aiConsentAt` also nulls `journalAiConsentAt`
(`AppDatabase.updateProfileConsents`). `AetherRequestBuilder.build` throws
`AetherConsentException` without consent, and again under age 16.

Per-entry, `excludedFromAi` (`KEEP LOCAL`) holds a single page back from every
call while leaving it in the record and in the cloud mirror.

---

### 2. Transport

`core/ai/transport.dart` is the only file that opens a socket. It posts
`{call, promptVersion, system, user, responseSchema}` to an
owner-controlled endpoint and returns the response body as a string.

- **No model credential ships in the app.** The client authenticates to *the
  owner's* endpoint with `ETER_AI_TOKEN`; the endpoint holds the model key.
- **No parsing, no repair, no fallback.** Every failure throws. A day with no
  guidance is a correct outcome; a day with invented guidance is not.
- **HTTPS, or loopback.** `isTransportSecure` permits `https`, plus `http` to
  `localhost`/`127.0.0.1`/`::1`/`10.0.2.2`, plus an explicit
  `ETER_AI_ALLOW_INSECURE` debug define that release builds cannot use.
- Configured entirely at build time via `--dart-define`; with no defines the
  app runs with no transport and every AI surface says so.

`server/worker.js` — see `ENGINEERING.md` — authenticates the caller, checks
the call name is one of the six, enforces a daily cap in KV, forwards to
Gemini with `responseJsonSchema` constrained decoding at a **per-call
temperature** (interpretation 0.1, day story 0.5, the three writing calls
0.7), and returns
`{"raw": text}` unparsed. It logs `call=<name> <status>` and **never the
payload**.

---

### 3. What comes back, and what is done with it

Each contract owns its own parser; the transport is forbidden to help.

| Contract | Parser | Rejects |
|---|---|---|
| `aether/guidance_contract.dart` | `AetherGuidanceParser` | missing dimension, empty sentences, >3 sentences, `AetherSafetyPolicy` violation, **evidence not present in the payload** (`AetherEvidenceScope`) |
| `journal/classification_contract.dart` | classification parser | out-of-range kcal/ratings, unknown lifestyle kind, a report with no rating/duration/words, missing assumptions |
| `journal/day_story.dart` | `JournalDayStoryParser` | story >700 chars, digest field >160 chars, >3 notable phrases |
| `vessel/reading_composer.dart` | reading parser | unrequested key, passage >1800 chars |
| `vessel/positions_composer.dart` | positions parser | passage >1200, note >140 chars |
| `aether/letter.dart` | `LetterParser` | missing or empty letter, >2400 chars, `AetherSafetyPolicy` violation |

`AetherSafetyPolicy` (`aether/safety_policy.dart`) is the post-hoc half of the
prompt's SAFETY block: a blocklist of medication/diagnosis/1200-kcal/punishment
phrasings, a 3000-character ceiling, and a grounded-mode ban on fated phrasing.
Prevention (prompt) and defence (policy) are deliberately separate — the prompt
is not a security boundary.

Model estimates never silently become facts: food derived from a journal page
is written with `confirmed: false` and `source: 'aether-estimate'`, carrying
`journalEntryId`, `confidence` and `assumptions` in `metadataJson`, and is
excluded from totals until the person reviews it.
`revertJournalEntryRows` deletes everything one entry produced.

---

### 4. Caching, so the same day is not paid for twice

| Call | Cache key | Effect |
|---|---|---|
| guidance | `contextFingerprint` — FNV-1a over the whole stable payload | Identical context returns the stored 4-row set, no network |
| day story | `sourceFingerprint` — FNV-1a over the day's prose in order | Unedited day, no network |
| vessel readings | `(inputHash, part)` over birth inputs | Only *missing* parts are requested, and each at most once per opening |
| positions | `(date, inputHash)` | One call per day per chart |
| interpretation | `appliedAt != null` | An applied entry is never sent twice; `needsDetail` is not retried unprompted |
| letter | the month, `YYYY-MM` | A month already written is never composed again — one request per person per month |

---

### 5. Failure

- No transport configured → every surface reports it; nothing is written.
- Network/timeout → `EterTransportException` with a sentence written for a
  human, not a stack trace. Nothing changed.
- Endpoint 4xx/5xx → same, with status. The Worker's daily cap answers 429.
- Malformed or unsafe answer → parser/policy throws; nothing is written; the
  cache is untouched so a retry is a real retry.
- Auto-interpretation is best-effort per entry: one unreadable page is logged
  via `debugPrint` and leaves the entry `pending` for the next pass. It never
  surfaces as an error, because nothing was asked for.

---

### 6. Provenance and retention (schema 15)

Every row of model output records the `EterPrompts.version` that composed it,
in a nullable `promptVersion` column. Null means the row predates the column —
an honest "we no longer know" rather than a backfilled guess. Bumping
`EterPrompts.version` therefore makes stale output identifiable.

**It is at 11**, and the last three are worth knowing because each of them was
found by *reading* recorded output rather than by any test:

- **10** — the Vessel's five parts, on their first live run, produced an
  archive narrator ("the records show"), the request's own field names in the
  prose ("occupants"), keywords recited as lists, orbs printed to two decimals,
  ten of twelve houses opening with one clause and a swapped noun, and a
  synopsis naming places by their internal keys. Every one of those passed the
  parser and the safety policy.
- **11** — the Polish side, recorded for the first time. Polish marks gender on
  the past tense, and nothing had chosen one: the day story addressed the
  reader as masculine and, two calls later, the letter had Eter call itself
  feminine. The owner's rule is to agree with the profile and default to the
  masculine, and `languageFor` carries a Polish-only section saying so.
- Also at 11: the letter's "we" is no longer only an instruction.
  `LetterParser` refuses it outright, in both languages, because four
  consecutive prompt versions forbade it and a recorded letter still closed
  with "We saw the short nights return".

Model output expires on its own rather than when someone remembers to clear it
(`AppDatabase.runLocalRetention`):

| Table | Bound |
|---|---|
| `GuidanceHistory` | 365 days |
| `TransitReadings` | 90 days |
| `Letters` | kept — see below |
| `JournalEntries.extractionJson` | 90 days (the derived records stay) |
| `RawBuckets` | 90 days |
| `LiveSessions.hrSeriesJson` | 180 days |

`extractionJson` is also cleared immediately by `revertJournalEntryRows` — the
model's account of a page goes with the rows the person just rejected.

`Letters` is the one table of model output with **no expiry**, and that is a
decision rather than an omission. Twelve short pages a year is not a retention
problem, and a letter is addressed correspondence: deleting one on a timer
because it happens to have been composed rather than typed would treat it as
cache. It goes with everything else on `DELETE FROM THIS DEVICE`.

`server/worker.js` meters **per install first** — a 12-request burst window and 60
calls a day — and treats the deployment-wide cap as a cost backstop rather than the
real limit. That order is the correction: the shared cap used to be the only
enforceable one at 500 a day, which is about a hundred users, and when it tripped it
refused everybody indiscriminately.

Counting goes through Cloudflare's rate-limiting binding when it is bound, because
KV cannot do it: the previous version read a counter and wrote back an increment,
which is not atomic, and KV reads are cached at the edge for up to 60 seconds against
a window that was 60 seconds — so the limiter was measuring a value that had often
not arrived. The KV path remains as a development fallback and the worker logs
`limits=kv-approximate` when it is running that way, rather than letting the weaker
mode pass for the stronger one.

Keys are a salted truncated SHA-256, so the store holds neither an install id nor an
address — only an opaque counter that expires.

### 6a. The language it answers in

Every one of the five instructions carries a `LANGUAGE` block naming the
language to write in, built by `EterPrompts.languageFor` and parameterised by
`AppLanguage`. English prompts carry it too: if only the Polish prompt had it,
the two would differ in two ways instead of one and a difference in output could
not be attributed.

The block is **written in English regardless of what it asks for** — an English
directive inside an otherwise-English system prompt is followed far more
reliably than the same directive in the target language.

The load-bearing half is the second paragraph, which says what is *not* writing:

> Do not translate the structure. Every JSON key, and every value that comes
> from a fixed set named in these instructions, stays exactly as written here,
> in English, character for character.

Every contract in this product validates against fixed English values —
`synthesis`, `needsDetail`, `mood`, `breakfast`, the dimension names, the
position keys, and every field name inside `evidence`, which is compared
key-for-key against the payload. A model told only "answer in Polish" will
helpfully rename `sleepMinutes` to `minutySnu`, and `AetherSafetyPolicy` then
discards the entire composition — correctly, and invisibly, so the Dashboard
simply never fills in. Numbers, dates and units are excluded too: Polish writes
decimals with a comma, and `evidence` is checked digit for digit.

The language is an **instruction, not context**. It changes the system prompt
and nothing about what crosses the boundary: `prompt.user` is byte-identical in
every language, and so is `prompt.responseSchema`. A test asserts both.

Each composer resolves the language from `Profile.language` itself rather than
receiving it from a widget, so automatic and background composition are written
in the same language a tap would produce. `AppLanguage.forProfile` is the single
place that rule lives.

The two pieces of prose Eter writes *itself* — the weekly retrospective and the
correlation sweep's findings — are not covered by any prompt and so were the
ones most likely to stay English. The retrospective is composed in the profile's
language and discarded when the language changes; the sweep keeps its English
sentence (that is what travels to the model) and the Sanctum re-words each
finding from the pattern's key and evidence at display time.

### 7. What a page may report about a day

`journalInterpretation` derives lifestyle records from twelve kinds, wider than
the margin's check-in (three readings, two practices) because a page is where
someone says the week is heavy:

`mood` · `stress` · `recovery` · `energy` · `focus` · `motivation` — felt
states, with an optional 0–10 rating
`social` — connection or its absence · `spirit` — meaning, purpose, feeling
adrift · `carrying` — a pressure, a worry, a conflict, a loss, something
unresolved
`sleep` — what they *said* about sleeping · `meditation` · `breathwork` — a
practice with a duration

A report needs a rating, a duration, or the words it came from; a kind with
nothing in it is refused. `carrying` is stored as context and never treated as
a problem the product then tries to solve — the prompt says so explicitly:
"Do not advise on it, do not resolve it, and do not moralise about it."

### 8. Open questions

- `journalDayStory` sends *every* kept entry for a date, uncapped. It exists so
  guidance can send bounded digests instead, but the story pass itself has no
  character budget.
- `AetherSafetyPolicy` is an exact-substring blocklist. It catches the literal
  phrasings and nothing adjacent to them.
- Each call is stateless. There is no model-side memory: continuity exists only
  because the device re-sends digests, patterns, self-reports and the fortnight
  of `recalled` notes. The other four calls have no memory at all — a Vessel
  reading does not know what last week's reading said.

---

## Eter · the endpoint contract

What the client sends, what it expects back, and what the server is forbidden
to do. The client half is implemented in `app/lib/core/ai/transport.dart` and
tested in `app/test/ai_transport_test.dart`; this file is the other half, which
only the product owner can build.

---

### 1. What the client does

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
to the model, log it, or store it unhashed** — see `ENGINEERING.md` §1 for what it is
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

### 1a. Running the whole thing on one machine

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

### 2. What the server must do

**Hold the model key.** This is the entire reason the endpoint exists. The
client authenticates to *you*; you authenticate to the model provider. A build
of Eter carrying a model key would hand that key to everyone who installed it.

**Forward `system`, `user` and `responseSchema` unchanged.** The payload's
boundedness is the privacy guarantee — see `ENGINEERING.md` §1 for what is
excluded by construction and why.

**Authenticate the caller.** The bearer token above is a placeholder for
whatever scheme you choose; the client sends whatever it was compiled with and
cares only that the endpoint accepts it.

**Meter per `call`.** The six calls have very different frequencies and costs.
`call` is on the wire precisely so you can route, rate-limit and bill them
separately without inspecting the payload.

### 3. What the server must not do

- **Add context of its own.** Not the user's identity, not a history, not a
  "helpful" system preamble. The client already built the complete prompt, and
  anything the server adds is content nobody consented to.
- **Repair the model's JSON.** Return it as it came. The parsers in each
  contract are the validation that keeps invented content out of a person's
  record, and a helpful repair upstream defeats them.
- **Substitute a fallback on failure.** Return an error. A day with no guidance
  is a correct outcome; a day with guidance nobody composed is not.
- **Log the payload.** It is one person's health records and, for two of the
  six calls, their own prose. Log the `call`, the `promptVersion`, the
  latency, the token counts and the status. Not the body.

### 4. What the client accepts back

Either the model's raw text as the whole body, or `{"raw": "<text>"}`.
`{"error": "<reason>"}` surfaces as a transport failure. An empty body is a
failure. Non-2xx is a failure. Every failure reaches the surface that asked as
a stated absence, never as content.

The client does not parse the model's answer — it hands the string to the
contract's own parser, which validates shape, bounds and safety before a single
character is stored.

### 5. A minimal shape

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

### 6. Before the first real call ships

Record the fixture set from `ENGINEERING.md` §5.5 — a good, a malformed, an unsafe
and an empty response for each of the six calls — and test the parsers against
them. Today they are tested against hand-written JSON, which proves the parsers
self-consistent and nothing more.

---

## Eter · what is stored, where, and for how long

Current as of 5 August 2026, schema **15**. Supersedes
`archive/14-data-models-firebase.md` and `archive/16-privacy-compliance.md`.

Principle: **the device is canonical.** Every surface reads local SQLite.
The cloud is a mirror written to when there is a connection and read from
exactly once — on a signed-in device with no history of its own.

---

### 1. Local store

Drift/SQLite at `<app documents>/eter.sqlite`, defined in
`core/db/tables.dart`, accessed only through `core/db/app_database.dart`.

#### Identity and consent

| Table | Holds |
|---|---|
| `Profiles` (single row, id=1) | first name, DOB, sex, weight, height, body fat, units, guidance mode, start surface, `language`, **birth time / UTC offset / place / lat / lon**, **home place / lat / lon**, and five consent timestamps: `aiConsentAt`, `journalAiConsentAt`, `crashReportConsentAt`, `cloudSyncConsentAt`, `journalCloudSyncConsentAt` |

This is the only place birth time and coordinates exist. They never enter an
AI payload; they are used on-device by `NatalChartEngine` and as the
`inputHash` that keys cached readings.

#### Birth place and home place are not the same column, and must not become one

`birth*` casts the chart. `home*` is where the person lives, and it is the only
thing the register's sunrise and sunset may be computed from.

Conflating them is not hypothetical — it shipped. `dayPhaseAt` was fed the birth
coordinates because they were the only ones stored, so anyone who had moved got a
register turning on a city they had left: born in Warsaw, living in Vancouver, and
the night register arrived mid-morning in the default mode, silently.

`registerCoordinates` (`core/symbolic/solar.dart`) resolves it. Home coordinates
win. With none, birth coordinates serve *only while the device's own UTC offset
agrees they are plausible* — a birth longitude implies a solar offset, and a phone
hours away from it proves the person is elsewhere. When they disagree it returns
null, the register falls back to a plain 07:00–19:00 clock, and the Sanctum asks.
No location permission, and no confident wrong answer. The tolerance is three
hours because Madrid keeps central European time on Greenwich's meridian and
Kashgar shares Beijing's offset five hours from its own sun; anything tighter
strands people who never moved.

Changing home place invalidates nothing composed. `updateHomePlace` is
deliberately *not* part of `updateBirthContext`, which clears readings belonging to
superseded chart hashes — moving house does not recast a chart.

#### Measured record

| Table | Holds | Retention |
|---|---|---|
| `RawBuckets` | pre-dedup minute imports, per source | **90 days** (`pruneRawBuckets`) |
| `MinuteBuckets` | deduplicated winners + provenance | **400 days** (`pruneMinuteBuckets`) |
| `DaySummaries` | per-day totals | unbounded |
| `SleepSegments` | stages, keyed to `nightOf` | unbounded |
| `DailyVitals` | RHR, HRV, respiratory rate, temp delta, scores | unbounded |
| `ActivitySessions`, `StrengthWorkouts`, `LiveSessions` | sessions; live HR series | HR series **180 days** (`pruneLiveHeartRateSeries`) |
| `WeightEntries`, `NutritionEntries`, `LifestyleEntries` | manual and derived records; `mirrorId`, and `writtenBackAt` on the first two | unbounded |
| `Integrations`, `RememberedSensors` | device-local connection state | device-local |

`runLocalRetention()` runs every bounded prune. See §4.

#### Written and generated content

| Table | Holds | Notes |
|---|---|---|
| `JournalEntries` | the person's prose, `status`, `excludedFromAi`, `extractionJson`, `model`, `appliedAt` | discarding blanks the text and sets `status: 'discarded'`; the row id is retained so nothing can be re-pointed at a different page |
| `JournalDayStories` | one story + digest per local date, `sourceFingerprint` | model output |
| `GuidanceHistory` | one row per dimension per composition, `contentJson`, `evidenceJson`, `contextFingerprint` | model output |
| `GuidanceRecalls` | one telegraphic note per local day, plus that day's action, `usedJournal`, replaced on recompose | model output; the fortnight guidance reads so it stops repeating itself |
| `VesselReadings` | one passage per position, keyed by `inputHash` | model output; `clearVesselReadingsExcept` drops readings for superseded charts |
| `TransitReadings` | one passage per (date, `inputHash`) | model output |
| `DailyCards` | the day's Arcana draw + reason | device arithmetic, no model |
| `PatternCandidates` | locally discovered correlations, `status` | dismissed patterns are never re-sent to a model |
| `Retrospectives`, `IntakeAnswers` | periodic summaries; onboarding answers | |

#### Local controls

- `discardJournalEntry(id)` — blank one page.
- `pruneJournalProse(olderThanUtc)` — bulk-blank old prose, keeping derived
  facts. Exposed as **Sanctum → Old pages → Clear**, at one year.
- `revertJournalEntryRows(id)` — delete every record one entry produced.
- `resetPersonalization()` — clears guidance, its recall notes, patterns and
  retrospectives.
- `deleteAllLocalData()` — truncates every table. Distinct from account
  deletion, and the Sanctum now presents both as separately confirmed actions
  with different consequences. Its warning states which situation you are in:
  with an account copy still standing, wiping the device is not permanent and
  `RESTORE` would bring it back, so the copy says so instead of promising
  otherwise.
- `SyncService.withdraw` — the copy, then the account. **The order is
  load-bearing.** `firestore.rules` authorises every delete by
  `request.auth.uid`, so deleting the account first takes the only credential
  that can satisfy that rule and leaves the whole mirror standing under a uid
  nobody can present again: unreachable, and therefore permanently undeleted.
  A failed mirror clear leaves the account alone so a retry still has authority;
  a failed account delete leaves an already-empty mirror, which is the safe
  direction. Reached from the Sanctum's `DELETE ACCOUNT`, which both stores
  require to exist in-app.
- `LocalDataExporter` (`core/privacy/local_data_export.dart`) — writes a JSON
  snapshot of every table plus CSVs for the high-volume tables, no account and
  no network involved.

---

### 2. Cloud mirror

Firestore, under `users/{uid}/…`, behind the `CloudMirror` interface so the
sync rules are testable without a project. Requires `cloudSyncConsentAt` **and**
a confirmed email account (`account.canSync`).

**Mirrored:** `profile`, `weights`, `nutrition`, `lifestyle`, `sessions`,
`strength`, `days` — and `journal` only under the separate
`journalCloudSyncConsentAt`.

**Withheld, with the reason recorded in `SyncService.withheld`:**
`minuteBuckets`, `rawBuckets`, `guidanceHistory`, `guidanceRecalls`,
`vesselReadings`, `transitReadings`, `journalDayStories`, `integrations`.

So: **no model output is ever mirrored.** The cloud holds the record, not the
readings composed from it.

Note that the mirrored `profile` document *does* carry `firstName`, `dob`,
`birthTimeMinutes`, `birthUtcOffsetMinutes`, `birthPlace`, `birthLatitude`,
`birthLongitude` and the three `home*` fields — the full identity set the AI
boundary deliberately excludes. Different boundary, different rules: the mirror is
the person's own backup.

Rules of the road:

- A push marks `syncedAt` only after the write is acknowledged. A failed sync
  is a delay, never a loss.
- **Pushes happen on their own**, not only when somebody presses `SYNC NOW`.
  `BackgroundSync` fires on resume and on the app leaving — the latter being the
  moment worth catching, since it follows someone finishing a page. Debounced to
  one push per five minutes. Consent is re-checked by `push` itself rather than by
  the caller, so that rule lives in one place. A force-stopped app never delivers
  `paused`, so a page written and then force-closed reaches the cloud one session
  late; pushing at launch instead would put a network call on every cold start.
- Restore refuses on a device that already has history — merging two divergent
  health records has no correct answer.
- Restore does **not** restore consent, including cloud consent. A new phone asks
  again. This was untrue until 30 July 2026: `_restoreProfile` granted
  `cloudSyncConsentAt` on the line directly beneath a comment promising it did
  not, so a restore silently began copying a record to the mirror with nobody on
  that phone having agreed.
- **Documents are keyed on `mirrorId`, not the local row id.** A restore
  reassigns autoincrement ids, so id-keyed documents drifted: after a phone swap
  every push wrote beside the document it meant to replace. For the journal that
  mattered most — discarding a page pushes a blanked row *in order to* overwrite
  the prose, and the overwrite was landing on a document nobody had read, leaving
  the original page in the cloud permanently. `sessions`, `strength` and `days`
  were always safe; they carry stable string keys. `readAll` returns
  `MirrorEntry`, carrying the key, because it is not recoverable from the
  contents.
- `forget(userId)` / `deleteEverything` walks all eight subcollections, because
  Firestore does not delete subcollections with their parent.

`firestore.rules` enforces ownership server-side (`request.auth.uid == userId`),
caps documents at 40 keys and text fields at 20 000 characters, and denies
every path not explicitly named.

---

### 3. What crosses which boundary

| | Device | AI endpoint | Cloud mirror |
|---|---|---|---|
| Name, DOB, birth time, coordinates | ✔ | ✘ never | ✔ under cloud consent |
| Derived age, sun/moon sign, Life Path | ✔ | ✔ under AI consent | derived, not stored |
| Measured health records | ✔ | ✔ 7-day window, under AI consent | ✔ under cloud consent |
| Raw/minute buckets | ✔ | ✘ | ✘ |
| Journal prose | ✔ | ✔ under *journal* AI consent, bounded | ✔ under *journal* cloud consent |
| Journal digests | ✔ | ✔ under journal AI consent | ✘ |
| Model output (guidance, stories, readings) | ✔ | ✘ | ✘ |
| Aether's own recall notes | ✔ | ✔ 14 days, under AI consent; journal-derived notes need journal consent | ✘ |
| Account/row identifiers | ✔ | ✘ never | uid scoping only |

---

### 4. Retention, as of schema 15

`runLocalRetention()` bounds everything that is a cache or an interpretation
rather than a fact:

| What | Bound | Why it is not a fact |
|---|---|---|
| `RawBuckets` | 90 days | ingest staging; the winners survive |
| `MinuteBuckets` | 400 days | ingest detail; `DaySummaries` carries the result and is unbounded |
| `LiveSessions.hrSeriesJson` | 180 days | the session aggregate survives |
| `GuidanceHistory` | 365 days | composed from the record, recomposable from it |
| `GuidanceRecalls` | 60 days | a summary of prose that has itself expired; only 14 are ever read |
| `TransitReadings` | 90 days | a passage about one day's sky |
| `JournalEntries.extractionJson` | 90 days | the model's reading; the records it produced stay |

Discarding a journal entry now also removes the cloud copy: the blanked row is
pushed and overwrites the mirrored prose, and restore skips tombstones. Model
output is still never mirrored at all.

`revertJournalEntryRows` clears `extractionJson` with the rows it produced.
The Sanctum exposes **Old pages → Clear**, which runs `pruneJournalProse` over
anything older than a year behind a second confirmation.

#### Changing language discards composed prose

`Profile.language` is `en` | `pl` | null, and null means *nobody has chosen* —
that install follows the phone on every launch, so moving the OS to Polish is
met in Polish. A stored code is the person's and stops following anything.

`chooseLanguage()` writes the code and then deletes `GuidanceHistory`,
`GuidanceRecalls`, `VesselReadings`, `TransitReadings`, `JournalDayStories` and
`Retrospectives`. This is not tidiness: every composer keys its cache on a
fingerprint of its *inputs*, none of which change when the language does, so a
Polish Dashboard would open on an English paragraph that every composer
considered current and would never replace. Clearing is what makes the switch
take effect.

Nothing measured moves. Journal pages, weights, meals, sleep, day totals,
consents and the whole symbolic chart are untouched, and learned patterns
survive because a pattern stores structured evidence and is *worded at display
time* rather than kept as a sentence. The count of discarded rows is returned so
the Sanctum can say what actually happened.

### 5. Writing back to the platform

Eter read fourteen kinds of health data and wrote none, which made it a good
citizen of nobody's phone: a weight typed here never appeared in Apple Health.
`core/health/write_back.dart` sends two things — weights, and **confirmed** meals.

**The origin filter is the whole design.** Only rows Eter originated go back;
anything read from the hub never does. Returning the platform's own data under
Eter's name survives one round trip and is then read back as a second, independent
measurement, so the day's intake would climb every time the app was opened and the
cause would be nearly invisible. `source` makes the filter possible, matched as a
prefix because the hub stamps the contributing app onto it — `healthConnect:garmin`
is still the hub.

Unconfirmed estimates are excluded too. A model's guess is kept out of Eter's own
totals until somebody confirms it; writing it into Apple Health would launder it
into a fact by moving it somewhere more authoritative.

`writtenBackAt` stops a row being offered twice, and each write carries a stable
`clientRecordId` so a repeat replaces rather than duplicates. No Eter-level consent
sits in front of this: the platform's own per-type permission dialog is the gate,
revocable in its own interface, exactly as it is for reading.

Nutrition goes through `Health.writeMeal`, not `writeHealthData`.
`DIETARY_ENERGY_CONSUMED` is Apple-only, and on Android `isDataTypeAvailable`
filtered it out *silently* — the permission sheet asked for Weight alone and
nutrition would have failed forever without saying why. Only a device showed that.

### 6. Still open

1. **The export bundle is written to app documents** and is not encrypted;
   anything that can read the sandbox can read the export. There is also still no
   import, so the versioned snapshot cannot be read back.
2. **`DaySummaries`, `SleepSegments` and `DailyVitals` are unbounded.** Deliberate
   — they are the record, and they are small.
3. **Nutrition write-back has never run against a real Health Connect.** Nine
   tests cover the rules; the device run stopped at the permission sheet.

---

## Eter · Asset Manifest

### V2 UI commissioning plan

This section is the asset authority for the Kimi K3 UI handoff. The historical
generation record below documents the earlier art set; it is not a requirement
to regenerate that set.

The concept plates in `docs/concepts/` are reference images only. Never crop UI
elements out of them or ship them as application backgrounds.

#### Priority 0 — needed for the defining prototype

##### 1. Refined day environment

**Status:** two options generated. Option A passed the complete responsive and
dynamic-type capture gate and is integrated as
`app/assets/art/bg-air-day-v6.webp`; option B is retained under
`assets/review/` for product-owner comparison. The existing
`bg-air-light-v5.webp` is superseded.

**Deliverables:**

- `bg-air-day-v6-master.png` — 2160×3840 master, 9:16.
- `bg-air-day-v6.webp` — production derivative, target 500–900 KB.
- Optional tablet crop only after the phone composition is approved; do not
  generate several speculative aspect ratios.

**Art direction:**

> A quiet vertical atmospheric background for a minimalist editorial wellbeing
> app. Pale powder-blue sky dissolving into warm ivory and parchment mist;
> layered soft clouds with natural tonal variation and very faint paper-like
> texture; contemplative, intelligent and timeless; diffused daylight; almost
> abstract. Keep the centre 65% calm and low-contrast for dark editorial text.
> Slightly more cloud structure near the lower edge and extreme corners, never
> forming a landscape subject. No mountains, horizon, figures, architecture,
> text, symbols, stars, astrology, gold decoration, interface elements, frames,
> borders, gradients that look synthetic, watermark or vignette.

**Composition constraints:**

- Text-safe centre from roughly 15–80% of image height.
- No important feature within device-notch or home-indicator regions.
- Worst-case text area must support `ink900`; the UI may add its existing ivory
  legibility lift, but the art must not force a large opaque panel.
- Still image only. Day has no ambient motion.
- Test with `BoxFit.cover` at 320×568, 390×844, 430×932 and 600×960 dp before
  approval. The crop must not turn a cloud edge into a visual divider.

##### 2. ETER celestial header engraving

**Status:** closed as code, in two registers (steering decision, 28 July 2026).
Day draws the colophon alone — plumb line and compass star under the wordmark,
nothing above the name. Night draws the elaborate astrolabe and is the only
place the graduated arc, solar/lunar marks and drift exist. Both live in
`features/shell/shell_header.dart`; the concept bitmaps under `assets/review/`
are retained for comparison and are not runtime assets.

**Deliverable:** one shallow, symmetrical path composition around the wordmark,
approximately 300×56 logical units, authored as SVG paths or reproducible
Flutter paths. The `ETER` text itself remains live typography and is not part of
the asset.

**Motif:** night keeps a restrained solar mark on one side, lunar mark on the
other, joined by one fine graduated arc, an inner declination arc and a ring of
struck graduations. Day keeps only the plumb line and the four-point compass
star. Both should feel like an astronomical instrument engraving, not a
horoscope banner.

**Rules:**

- One-color paths; tint from `EterInk`/register in code.
- 1–1.25 dp apparent stroke at normal phone width.
- No zodiac glyph row, constellation field, labels, fill or glow.
- Motion is night-only, one revolution per six minutes, and renders settled on
  frame one under reduced motion. Day never animates.
- Decorative semantics only.
- Identical geometry, lockup and hit region on Journal and Dashboard, and
  across registers — only the drawn matter changes.

This is the one approved astrological flavor at the top of the resting surface.
Do not add more header decoration to compensate for empty space.

#### Reuse — no new commission

##### Journal paper character

Reuse `grain-subtle.webp` as a low-opacity repeat/cover texture over a
code-defined warm parchment field. The existing file is sufficiently neutral.
Page margin, date heading, baselines, folio marks and page transitions are UI,
not raster art.

Do not generate a photographed notebook, page with baked-in lines, page curl,
spiral binding, leather cover, handwriting or fixed shadows. Those would fight
dynamic type, localization and the continuous sky.

##### Night environment and Arcana

**Refreshed 28 July 2026.** The night register now has its own plate and loop
at the quality bar Day v6 set:

- `bg-air-night-v1.webp` — 2160×3840, replaces the graded v3 astrophotograph.
  Same constraints as the day entry above: calm text-safe centre, the band held
  in the upper third, no synthetic nebula palette, still image.
- `animations/air-field-dark-v2.mp4` — the optional night loop, generated from
  the plate itself so its motion belongs to that sky, then mirrored
  forward-and-back so the loop point is frame-exact. 1080×1920, 12 s, silent,
  ~1.2 MB. Night only; day has no loop and must not gain one.

Both retired predecessors are kept under `assets/review/` (`*-retired`).

Reuse the shipped light/dark Arcana set. The night concept does not authorize a
replacement tarot deck or a busier celestial background.

**Rejected 28 July 2026:** generated engraved fields behind the Sanctum and the
Vessel (armillary threshold plate, chart wheel). They were built, reviewed
against the real surfaces and turned down — the Sanctum stays plain in both
registers as originally specified, and the Vessel carries no backdrop. Do not
regenerate this idea without a fresh decision.

##### Controls, rules and instruments

The following must remain code-native: Journal/Dashboard hairline, disclosure
chevrons, microphone and calendar icons, evidence marks, section rules, sleep
and vital charts, `EngravedBalance`, toggles, focus states and all text. Raster
versions will blur, fail theming and break accessibility.

#### Priority 1 — commission only when the implementing state exists

- A single Journal empty-state folio ornament, only if the empty page still
  needs orientation after its real layout and prompt are working.
- No separate Sanctum threshold engraving. The approved code-native ETER
  header is the threshold; the overlay itself is deliberately unornamented.
- New onboarding art, only if the existing onboarding hero cannot be cropped
  into the refined day register.

These are not prototype blockers. Kimi should first attempt the surface with
existing assets and request them with a screenshot showing the exact negative
space they must occupy.

#### Asset acceptance gate

Before bundling commissioned art:

1. Show it underneath real day/night text at text scales 1.0 and 2.0.
2. Show all required phone crops and one 600 dp layout.
3. Verify the screen still reads correctly with the decoration removed.
4. Verify no essential information is baked into pixels.
5. Compress a derivative; retain the master outside the runtime bundle.
6. Record filename, dimensions, generator/model, prompt and source/job ID here.

If an asset does not survive these checks, it is not ready for the application.

---

Generated with Higgsfield (`nano_banana_pro` / nano_banana_2, 2K). All assets share one style string — reuse it verbatim for every new asset so the set stays coherent:

> **Eter style string:** "ethereal light-and-airy aesthetic, pale powder-blue and warm-white palette, delicate gold celestial line art, soft volumetric clouds, dreamy diffused light, premium minimal tarot engraving flavor, high detail"

| File | Size | Use in app | Prep needed before bundling |
|---|---|---|---|
| `app-icon.png` | 2048² | App icon source (iOS AppIcon set / Android adaptive foreground) | Crop to the inner rounded square; export icon sizes; for Android adaptive, separate cloud (foreground) from gradient (background) |
| `bg-onboarding.png` | 1536×2752 | Onboarding + Arcana reveal background (05) | Compress to WebP ~500 KB; keep center negative space clear of UI |
| `cloud-hero.png` | 2048² | Source for Cloud shader-fallback layers (04 §1) | Use the cutout below; derive 3 opacity/scale variants `cloud-hero-{1,2,3}.png` |
| `cloud-hero-cutout.png` | 2048² | Transparent-background cloud (fallback layers, empty states, watch tile art) | **Removed from the app 30 Jul 2026** — 4.1 MB, declared in `pubspec.yaml`, drawn by nothing. Master in the v1 tree and in history; re-add it if a surface ever wants it, through `compress_assets.py`. |
| `tarot-card-back.png` | 1696×2528 | Card back for Arcana reveal (04 §4), placeholder for unshipped sign cards | Crop to card edges (remove outer margin), round corners 4% in-app |
| `tarot-the-star.png` | 1696×2528 | Aquarius Arcana card art (05) + style template for the other 11 | **Crop to card edges** (it rendered as a mockup on a gray backdrop); round corners in-app |
| `sigil-loading.png` | 2048² | Reference for the animated loading sigil (04 §5) | Trace to SVG paths for the stroke-draw animation; PNG itself only as static fallback |

### Regenerating / extending the set

Model: `nano_banana_pro`, resolution `2k`. Aspect: cards 2:3, backgrounds 9:16, icons/squares 1:1.

**Remaining 11 Arcana cards** — use this template, swapping the scene per card (keep everything after the scene identical):

> "Tarot card '{CARD NAME}' ({NUMERAL}) reimagined in an ethereal light-and-airy style: {SCENE}, pale powder-blue and warm-white palette with delicate gold line art, thin double gold border frame, caption text at the bottom in elegant gold serif capitals: {CARD NAME UPPER} · {NUMERAL}, dreamy diffused light, premium minimal tarot engraving flavor, high detail"

Scene suggestions per card: Emperor — enthroned figure on a cliff of cumulus, gold ram-horn armrests; Hierophant — robed figure between two cloud pillars, twin keys of light; Lovers — two figures beneath a sun-crowned angel of mist; Chariot — charioteer drawn by two wind-horses of cloud; Strength — woman gently closing a golden lion's mouth, both wreathed in mist; Hermit — cloaked figure on a cloud peak holding a lantern with a gold star inside; Justice — seated figure with upright sword and glowing scales; Death — white rose held by a serene armored figure, dawn breaking through clouds (keep gentle); Temperance — winged figure pouring light between two cups, one foot on cloud one in a pool of sky; Devil — chained gold censer smoking beneath a watchful horned silhouette kept distant and small (keep elegant, not dark); Moon — twin towers in mist, a path of light across water, calm crescent above.

**Night Sky variants** (dark mode backgrounds): same prompts + "deep indigo night sky #16203A, gold constellations brighter, moonlit clouds".

Generation record (Higgsfield job ids, 2026-07-12): icon `1c56b36d`, onboarding bg `8e02b1ac`, cloud `9a358166`, card back `a885166c`, star card `1f45a220`, sigil `5078f6f4`, cloud cutout `70f0eb91`.
