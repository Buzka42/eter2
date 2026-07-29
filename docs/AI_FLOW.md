# Eter · how the AI flow works

Current as of 29 July 2026. Supersedes `archive/AI_FLOW-2026-07-28.md`.

What leaves the device, what is asked of the model, what is done with the
answer, and what happens when any of it fails.

This document is the authority for the AI boundary. Where it and a code comment
disagree, the code is wrong.

---

## 0. The five calls

Eter makes exactly **five** kinds of model call. There is no chat, no
streaming, no background poll.

| Call | Trigger | Consent required | Writes |
|---|---|---|---|
| **guidance** | Dashboard composes for the day (`AetherComposer`) | `aiConsentAt`; journal material additionally needs `journalAiConsentAt` | 4 `GuidanceHistory` rows (one per dimension) |
| **journalInterpretation** | **Automatic**, on every kept entry — `JournalAutoInterpreter`, max 5 per pass, when the Journal opens | `aiConsentAt` | `JournalEntries.extractionJson` + unconfirmed `NutritionEntries` + `LifestyleEntries` |
| **journalDayStory** | Journal opens, and after each entry saves | `aiConsentAt` **and** `journalAiConsentAt` | One `JournalDayStories` row (story + digest) |
| **vesselReadings** | Once at account creation, then `COMPOSE READINGS` | `aiConsentAt` | One `VesselReadings` row per position |
| **positions** | `READ TODAY` in the Vessel | `aiConsentAt` | One `TransitReadings` row per (date, chart hash) |

The chart, the Life Path, the Arcana and the daily card involve **no model at
all** — they are device arithmetic (`core/symbolic`, `core/arcana`).

Every call is bounded, provider-independent, and fail-closed: a refusal, a
malformed answer, or an unsafe one writes nothing and says so on the surface.

Code map:

```
core/ai/prompts.dart        the system instruction + JSON Schema for all five
core/ai/transport.dart      the only network call in the app; five thin adapters
server/worker.js            the owner-controlled endpoint (Cloudflare Worker)
core/aether/*               guidance: assemble → request → prompt → parse → store
core/journal/*              interpretation and the day story
core/vessel/*               readings and positions
```

---

## 1. The trust boundary

### Never assembled, therefore never sent

`AetherRequest`, `VesselReadingRequest` and the journal payloads have no field
for any of this:

name · date of birth · birth time · birth place · coordinates · timezone ·
account or device identifiers · row ids · vendor/source names · the chart
input hash · anything from a day outside the requested window.

Age crosses as **derived years**. The register crosses as a mode name.
Reliability crosses as two booleans. The chart crosses as *already-computed
placements* (sun sign, moon sign, optional ascendant, Life Path, personal year,
sun card) — never the inputs they came from.

### What each call actually sends

- **guidance** — up to 7 days of `{localDate, steps, activeKcal, sleepMinutes,
  restingHeartRate, hrvMs}` (days with no records are omitted, never
  zero-filled); derived age; optional body-fat %; the mode; optional symbolic
  block; up to 4 locally-derived pattern sentences; and — only under journal
  consent — per-day journal digests plus up to **5 raw entries inside a
  1200-character budget**, whitespace-normalised, excluding anything marked
  `KEEP LOCAL`. Days already reduced to a digest do not also travel as prose.
- **journalInterpretation** — one entry's text, plus one clarification string
  if the model previously asked for one. Nothing else: not the day's other
  entries, not the health context.
- **journalDayStory** — every kept, non-excluded entry for one local date, with
  timestamps. This is the widest payload in the app; it exists so that guidance
  can send a bounded digest instead of raw prose.
- **vesselReadings** — for each *missing* position only: key, label, resolved
  card, that card's shipped keywords, and the two reliability booleans.
- **positions** — today's date, moon phase and sign, sun sign, and the list of
  contacts already computed on device with aspect, orb and applying/separating.

### Consent

Two independent flags on the profile row, both nullable timestamps, both
re-read on every pass rather than cached:

- `aiConsentAt` — gates all five calls.
- `journalAiConsentAt` — additionally gates journal *prose and digests*
  reaching guidance, and gates the day story entirely.

Revoking `aiConsentAt` also nulls `journalAiConsentAt`
(`AppDatabase.updateProfileConsents`). `AetherRequestBuilder.build` throws
`AetherConsentException` without consent, and again under age 16.

Per-entry, `excludedFromAi` (`KEEP LOCAL`) holds a single page back from every
call while leaving it in the record and in the cloud mirror.

---

## 2. Transport

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

`server/worker.js` — see `AI_ENDPOINT.md` — authenticates the caller, checks
the call name is one of the five, enforces a daily cap in KV, forwards to
Gemini with `responseJsonSchema` constrained decoding, and returns
`{"raw": text}` unparsed. It logs `call=<name> <status>` and **never the
payload**.

---

## 3. What comes back, and what is done with it

Each contract owns its own parser; the transport is forbidden to help.

| Contract | Parser | Rejects |
|---|---|---|
| `aether/guidance_contract.dart` | `AetherGuidanceParser` | missing dimension, empty sentences, >3 sentences, `AetherSafetyPolicy` violation |
| `journal/classification_contract.dart` | classification parser | out-of-range kcal/ratings, unknown lifestyle kind, missing assumptions |
| `journal/day_story.dart` | `JournalDayStoryParser` | story >700 chars, digest field >160 chars, >3 notable phrases |
| `vessel/reading_composer.dart` | reading parser | unrequested key, passage >1800 chars |
| `vessel/positions_composer.dart` | positions parser | passage >1200, note >140 chars |

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

## 4. Caching, so the same day is not paid for twice

| Call | Cache key | Effect |
|---|---|---|
| guidance | `contextFingerprint` — FNV-1a over the whole stable payload | Identical context returns the stored 4-row set, no network |
| day story | `sourceFingerprint` — FNV-1a over the day's prose in order | Unedited day, no network |
| vessel readings | `inputHash` over birth inputs | Only *missing* positions are requested |
| positions | `(date, inputHash)` | One call per day per chart |
| interpretation | `appliedAt != null` | An applied entry is never sent twice; `needsDetail` is not retried unprompted |

---

## 5. Failure

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

## 6. Known gaps

Carried here so they are not rediscovered:

1. **`promptVersion` is sent but not stored.** Rows record
   `model: 'provider'`, not which instruction produced the passage, so
   `EterPrompts.version` cannot be used to invalidate stale output.
2. **`GuidanceHistory` and `TransitReadings` have no retention bound.** They
   grow forever until `resetPersonalization()` is run by hand from the Sanctum.
3. **`pruneJournalProse` still has no caller.** The retention control it exists
   for is not exposed anywhere.
4. **Discarding a journal entry does not remove its cloud copy.**
   `discardJournalEntry` blanks the local text and nulls `syncedAt`, but the
   mirrored document keeps the original prose until `deleteEverything`.
5. **`extractionJson` retains the full model reading** on the entry
   indefinitely, including for entries whose derived rows were later reverted.
6. **The endpoint has no per-user metering** — the daily cap is global across
   every installation sharing one deployment.
