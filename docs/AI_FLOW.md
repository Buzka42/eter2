# Eter · how the AI flow works

Current as of 30 July 2026, prompt v3. Supersedes
`archive/AI_FLOW-2026-07-28.md`.

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
| **guidance** | Dashboard composes for the day (`AetherComposer`) | `aiConsentAt`; journal material additionally needs `journalAiConsentAt` | 4 `GuidanceHistory` rows + 1 `GuidanceRecalls` row |
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

### The one identifier that leaves the device, and where it stops

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

### What each call actually sends

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
- **vesselReadings** — for each *missing* position only: key, label, resolved
  card, that card's shipped keywords, and the two reliability booleans.
- **positions** — today's date, moon phase and sign, sun sign, and the list of
  contacts already computed on device with aspect, orb and applying/separating.

### 1a. Memory

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

### How the shares are stated

Guidance names three proportions explicitly, because a vaguer instruction
("blend them") produces whichever the model finds easiest, which is always the
numbers:

| Register | Journal & self-reports | Chart | Measured |
|---|---|---|---|
| Grounded | 40% | 20% | 40% |
| Balanced | 50% | 25% | 25% |
| Immersive | 40% | 40% | 20% |

The journal is the largest share in every register — it is the only input that
says *why* a day went the way it did. In grounded the symbolic share is
emphasis only and never reaches the words.

With no journal material at all, that share is redistributed proportionally
between the other two and the model is told the material is absent
(`weightsWithoutJournal`). Naming a 50% share of something not in the payload
invites the model to fill it.

The shares are described as *where a reading draws from, not a quota to fill*:
"If a share has nothing behind it today, that share is simply smaller and you
say less."


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
Gemini with `responseJsonSchema` constrained decoding at a **per-call
temperature** (interpretation 0.1, day story 0.5, the three writing calls
0.7), and returns
`{"raw": text}` unparsed. It logs `call=<name> <status>` and **never the
payload**.

---

## 3. What comes back, and what is done with it

Each contract owns its own parser; the transport is forbidden to help.

| Contract | Parser | Rejects |
|---|---|---|
| `aether/guidance_contract.dart` | `AetherGuidanceParser` | missing dimension, empty sentences, >3 sentences, `AetherSafetyPolicy` violation, **evidence not present in the payload** (`AetherEvidenceScope`) |
| `journal/classification_contract.dart` | classification parser | out-of-range kcal/ratings, unknown lifestyle kind, a report with no rating/duration/words, missing assumptions |
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

## 6. Provenance and retention (schema 12)

Every row of model output records the `EterPrompts.version` that composed it,
in a nullable `promptVersion` column. Null means the row predates the column —
an honest "we no longer know" rather than a backfilled guess. Bumping
`EterPrompts.version` therefore makes stale output identifiable.

Model output expires on its own rather than when someone remembers to clear it
(`AppDatabase.runLocalRetention`):

| Table | Bound |
|---|---|
| `GuidanceHistory` | 365 days |
| `TransitReadings` | 90 days |
| `JournalEntries.extractionJson` | 90 days (the derived records stay) |
| `RawBuckets` | 90 days |
| `LiveSessions.hrSeriesJson` | 180 days |

`extractionJson` is also cleared immediately by `revertJournalEntryRows` — the
model's account of a page goes with the rows the person just rejected.

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

## 6a. The language it answers in

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

## 7. What a page may report about a day

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

## 8. Open questions

- `journalDayStory` sends *every* kept entry for a date, uncapped. It exists so
  guidance can send bounded digests instead, but the story pass itself has no
  character budget.
- `AetherSafetyPolicy` is an exact-substring blocklist. It catches the literal
  phrasings and nothing adjacent to them.
- Each call is stateless. There is no model-side memory: continuity exists only
  because the device re-sends digests, patterns, self-reports and the fortnight
  of `recalled` notes. The other four calls have no memory at all — a Vessel
  reading does not know what last week's reading said.
