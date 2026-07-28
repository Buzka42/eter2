# Eter · how the AI flow works

Pass 3 of three, 28 July 2026. What leaves the device, what is asked of the
model, what is done with the answer, and what happens when any of it fails.

This document is the authority for the AI boundary. Where it and a code comment
disagree, the code is wrong.

---

## 0. The shape of the whole thing

Eter makes exactly **five** calls to a model. There are no others, there is no
chat, and nothing is sent in the background.

| Call | Trigger | Consent required | Writes |
|---|---|---|---|
| **Guidance** | The day's first look at the Dashboard, or `COMPOSE NOW` | AI; journal prose additionally gated | 4 `GuidanceHistory` rows |
| **Journal interpretation** | Explicit `INTERPRET` on one entry | AI | Unconfirmed `NutritionEntries` + `LifestyleEntries` |
| **Vessel readings** | Once at account creation, then `COMPOSE READINGS` | AI | `VesselReadings` rows, one per position |
| **The day's story** | Journal opens, and after each entry saves | AI **and** journal prose | One `JournalDayStories` row: the story and its digest |
| **Positions** | Explicit `READ TODAY` in the Vessel | AI | One `TransitReadings` row per day and chart |

Every one of them is:

- **user-initiated or once-daily**, never a poll, never a stream;
- **bounded** — a fixed window, a character budget, a position list;
- **provider-independent** — the contracts know nothing about any vendor;
- **fail-closed** — a refusal, a malformed answer or an unsafe one writes
  nothing at all, and says so on the surface.

The chart, the Life Path and the daily card are **not** in that table, because
no model is involved in them at all. See §4.

---

## 1. The trust boundary

### What is never sent, by construction

Not filtered out — never assembled in the first place. `AetherRequest`,
`VesselReadingRequest` and the journal payload have no field for any of it:

name · date of birth · birth time · birth place · coordinates · timezone ·
device or account identifiers · row ids · vendor or source names · the local
chart hash · anything at all from a day outside the requested window.

Age crosses as **derived years**, not a birthday. The register crosses as a
mode name. Reliability crosses as two booleans.

`test/ai_prompts_test.dart` asserts this against the encoded payload rather
than trusting the comment.

### What is sent

**Guidance** — up to seven days, each `{localDate, steps, activeKcal,
sleepMinutes, restingHeartRate, hrvMs}`, days with no records omitted entirely
rather than zero-filled; derived age; the mode; and, only when journal-prose
consent is separately given, up to **5 entries within a 1200-character total**,
normalized whitespace, skipping any entry the user marked `KEEP LOCAL`.

**Journal interpretation** — one entry's text, plus one clarification string if
the model previously asked for one. Nothing else. Not the day's other entries,
not the health context.

**Vessel readings** — for each *missing* position only: key, label, the card it
resolved to, that card's shipped keywords, an optional degree detail, and the
two reliability booleans. Already-composed positions are never re-sent.

### Consent, exactly

Three independent switches, all off by default, all revocable
(`Profiles.aiConsentAt`, `journalAiConsentAt`, `cloudSyncConsentAt`):

- **AI off** → all three calls raise before any payload is built.
- **AI on, journal prose off** → guidance runs with health only, and the prompt
  is told, in words, that no prose was included so it cannot imply otherwise.
- **Revoking AI** also immediately revokes journal-prose consent.
- Age under 16 raises, independently of consent.

---

## 2. What the model is actually asked

`lib/core/ai/prompts.dart`, versioned as `EterPrompts.version`. Before it
existed, the contracts defined a payload and a loose shape hint and **nothing
said what the model should do** — which meant the product's voice and its
safety posture would have been set by whoever wired the transport.

Each prompt returns three things: a system instruction, the payload, and a real
**JSON Schema** for structured output. Providers that support schema-
constrained decoding should pass the schema through; the parsers validate
regardless, because the schema is an optimisation and the parser is the rule.

### The shared language

- **Voice** — one of three blocks, chosen by mode. Grounded forbids symbolic
  language outright ("no stars, no charts, no destiny"). Balanced allows
  symbolism to colour a framing but never to be a reason. Immersive allows it
  to open or close a passage, and still requires every recommendation to rest
  on the records. This mirrors the brief: the modes differ in tone and framing;
  the health reasoning underneath is identical.
- **Safety** — no diagnosis, no medication, no sub-1200-kcal recommendation, no
  deficit for someone whose records suggest under-eating, no "push through the
  pain", no symbolism presented as medical fact, no streaks or scores, and
  "refuse nothing silently: if you cannot say something safely, say less".
- **Absence** — missing data is information. Say it is absent, reason without
  it, never estimate an unrecorded number, never treat a gap as a zero.

### Per call

**Guidance** asks for exactly four dimensions. `synthesis` is the sentence the
app opens with — at most two sentences, no greeting, begins with the
observation. `health`, `mind` and `spirit` follow. Each has 1–3 sentences and
exactly one `primaryAction` phrased as an invitation, plus optional `evidence`
naming the records used — with the rule that no number may appear in
`evidence` that was not in the context.

**Journal interpretation** is deliberately narrow: derive food and the six
lifestyle kinds, and nothing else. It is told explicitly not to derive anything
the page did not say, not to read another day's events, not to touch weight,
workouts or heart rate, and to produce records rather than commentary. When
something material is unknown it must return `needsDetail` with exactly one
question and no derived rows — *"an unanswered question costs nothing, and a
wrong meal costs trust"*. An empty result is stated as normal and frequent.

**Vessel readings** are told the calculation already happened on the device and
they are not casting anything. Provisional positions must be named as
provisional in the passage. Symbolism describes a tendency, never a fate and
never a fact about the body; nothing in a reading may instruct anyone about
health, eating or medication.

---

## 3. What happens to the answer

Two independent layers, and the prompt is neither of them.

**Shape.** `AetherGuidanceParser` requires exactly the four dimension keys and
no others, 1–3 non-empty sentences each, a non-empty action, and an object for
evidence if present. `JournalClassificationParser` bounds kcal to (0, 5000],
macros to [0, 1000], confidence to [0, 1], lifestyle values to [0, 10],
durations to (0, 1440], and rejects any `needsDetail` that also carries derived
rows. `VesselReadingComposer` requires exactly the requested keys back —
no extras, no omissions — and caps a passage at 1800 characters.

**Safety.** `AetherSafetyPolicy` runs over guidance and vessel prose: a blocked
phrase, output over 3000 characters, or fated phrasing while in grounded mode
raises and the write is abandoned.

**Then, and only then, the write.**

- Guidance writes four rows in one set, keyed by `contextFingerprint` (FNV-1a
  over the stable payload). An unchanged fingerprint returns the cached set
  without calling the provider at all — which is what makes `REFRESH` free when
  nothing has happened since.
- Interpretation commits its derived rows atomically with the entry's status,
  and is replay-safe: a retry cannot double-log. Food arrives **unconfirmed**
  and cannot affect any total until the person reviews it — the estimate's
  `assumptions` are shown so the review is possible. `UNDO INTERPRETATION`
  removes the derived rows and leaves the prose untouched.
- Readings are cached per `(inputHash, positionKey)`. Changing birth context
  changes the hash, which retires the old readings rather than editing them.

**Every failure path writes nothing** and says so plainly on the surface:
consent missing, no transport configured, malformed JSON, unsafe content,
network error. None of them leaves a half-composed day.

---

## 4. The parts with no AI in them at all

Worth stating clearly, because they look like the places a model would be used
and are the places it must not be.

- **The natal chart** (`core/symbolic/natal_chart.dart`) is computed locally
  from birth inputs with `astronomia`. Sun, Moon, Ascendant and house
  placements are arithmetic.
- **The Life Path** (`core/symbolic/numerology.dart`) is digit reduction over
  the birth date. It is deterministic and testable, and it is tested.
- **The daily card** is a deterministic selection stored with the reason it was
  chosen, so the same day always yields the same card and the reason can be
  read back.
- **The keyword layer** (`core/arcana/symbol_content.dart`) ships with the app.
  Every position has meaning available offline, before any model is involved.

This is the load-bearing decision of the symbolic half: **the model never
decides what is true about the chart, only how to say it.** A composition
failure costs prose, never meaning — which is why the Vessel is fully usable
with no transport at all.

---

## 5. What is still missing

1. **A transport.** All three providers are `null` in `main.dart`. The app
   states this honestly on each surface and writes nothing. This is the
   remaining blocker for the whole feature.
2. **A server.** The client must never hold a model key — the steering brief is
   explicit and so is `RELEASE.md`. The call belongs behind an
   owner-controlled endpoint that authenticates the caller, holds the
   credential, and forwards the already-bounded payload.
3. **Rate and cost policy.** Nothing today limits how often `COMPOSE NOW` may
   be pressed. The fingerprint cache makes a repeat free when context is
   unchanged, which covers the common case and not a determined one.
4. **The input rule's other half.** With capture removed from the Dashboard,
   interpretation is the only route into the record — and it covers food and
   lifestyle only. Weight, activity and strength need bounded shapes in
   `classification_contract.dart` and a commit path through the services that
   already exist. See `ROADMAP.md` §1a.
5. **Prompt evaluation.** The prompts are asserted structurally (voice by mode,
   safety present, schema matching the parser) but never evaluated against real
   output, because there is no provider to produce any. A small fixture set of
   recorded responses — good, malformed, unsafe, empty — should exist before
   the first real call ships.

---

## 6. If you are wiring the transport

In order:

1. Build the endpoint. It authenticates, holds the key, and forwards
   `{system, user, responseSchema}` unchanged. It must not add context of its
   own — the payload's boundedness is the privacy guarantee.
2. Implement `AetherProvider`, `JournalClassificationProvider` and
   `VesselReadingProvider` as thin clients that call it and return the raw
   response string. **Do not parse in the transport.** The parsers are the
   contract; a transport that "helpfully" repairs JSON defeats them.
3. Override the three providers in `main.dart`.
4. Record the fixture set from §5.5 before shipping.
5. Leave every failure path returning an error rather than a fallback string.
   A day with no guidance is a correct outcome; a day with invented guidance
   is not.
