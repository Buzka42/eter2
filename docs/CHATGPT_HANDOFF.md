# ChatGPT handoff — Eter v2 prototype

State of the work as of 28 July 2026, and what is asked of you. Read the
canonical documents first — [`STEERING_BRIEF.md`](STEERING_BRIEF.md) (product
authority), [`UI_BRIEF.md`](UI_BRIEF.md) (implementation contract),
[`UI_DIRECTION.md`](UI_DIRECTION.md) (composition and the prototype approval
gate). Art commissioning has its own track in
[`ART_COMMISSIONS.md`](ART_COMMISSIONS.md).

## What exists now

The defining prototype from the UI direction's approval gate, implemented in
Flutter against the real Drift contracts. Fixture content lives only in the
test harness (`app/lib/features/prototype/fixtures.dart`); production startup
never seeds a fictional profile or health history. `flutter analyze` is clean.

| Piece | File | Notes |
|---|---|---|
| Signature arrival | `app/lib/core/arrival.dart` | One widget serves guidance and Journal. Word groups resolve from blur in ≤ `durSentence` per sentence, pauses between sentences, ≤4 dp displacement on `easeAir`, tap completes, reduced motion renders settled on frame one. |
| Shell | `app/lib/features/shell/eter_shell.dart`, `shell_header.dart` | Horizontal pager Journal↔Dashboard, `allowImplicitScrolling` + keep-alive for state preservation, persistent two-word switch with travelling gold hairline, ETER header as `CustomPainter` in two registers — day draws the colophon alone, night draws the full astrolabe and drifts one revolution per six minutes; the drift ticker runs only in night with motion allowed, so day and every reduced-motion surface are genuinely still and the goldens stay deterministic. |
| Dashboard | `app/lib/features/dashboard/dashboard_page.dart`, `body_section.dart` | Synthesis owns the resting view above one `LOOK DEEPER` threshold. Its in-place chooser opens expanded Guidance or Body, never simultaneous rows. The only disclosure glyph is the code-native bead-and-thread `EterDisclosureMark`; no Material icon remains on production surfaces. An uncomposed day exposes one quiet `COMPOSE GUIDANCE` action; expanded Guidance offers `REFRESH`, reuses unchanged context without another provider call, preserves existing content on failure, and announces status accessibly. Production `sentences + primaryAction` responses and legacy fixture caches both render as prose. Guidance renders Health/Mind/Spirit prose and marginal evidence receipts. Body begins with a conclusion, states missing signals, then recovery prose, `EngravedBalance`, engraved RHR/HRV/weight trends, a measured sleep-stage rail, compact manual activity, confirmed-meal and weight entry, and editable food lines; estimates are visibly not counted until corrected/confirmed. Manual activity uses the same canonical minute deduplication and reactive day-summary path as connected health data, so overlaps do not inflate burn. Manual meals accept factual energy plus optional macros, update an existing day-summary intake mirror transactionally, and make core nutrition usable without an AI transport. Manual weight atomically updates both history and the profile input used by later energy estimates. Strength sits at the same line rhythm and stays one line at rest: `Record` opens the complete tracker — exercises, sets, reps, load, technique and earlier work — and nothing of that apparatus exists on the resting screen. Its energy is derived from the spec-08 MET fallback over the real sets with EPOC applied once, never typed by the user, and it refuses to estimate at all without a recorded body weight. The session is written through `ManualActivityService`, so strength minutes deduplicate against watch and phone minutes instead of being added on top of them. Every instrument has a complete semantic summary. |
| Journal | `app/lib/features/journal/journal_page.dart` | Date-led ruled parchment page (grain reused, no enclosing border), tap-page-to-write, invisible 900 ms autosave and one borderless `DICTATE` action (`speech_to_text`). No checkmarks, Done/Save action, toggle or composer chrome. Two code-native bead-and-thread page-turn marks expose earlier/later days with 48 dp semantic targets; future days are disabled, historical pages are read-only, and leaving today safely saves a non-empty draft and stops dictation first. Entries read as continuous timed prose and arrive via the shared reveal. The day's self-report lives here and only here: mood, stress and recovery as marginal annotations that open a five-mark engraved rail in place, meditation and breathwork as minute sittings. A reading is the day's answer and answering again corrects it transactionally; sittings accumulate; a historical page shows the same annotations inert and says nothing at all when the day holds none. Each saved passage has quiet `KEEP LOCAL` / `ALLOW AETHER` and explicit `INTERPRET` actions. Interpretation requires current AI consent, supports one bounded clarification, announces progress/failure accessibly, and offers `UNDO INTERPRETATION`, which removes the derived rows without deleting the prose. Excluded prose remains omitted from guidance context. |
| Register wiring | `app/lib/main.dart` | A genuinely empty database enters onboarding. After profile creation, `GuidanceMode` → `EterRegister` via real sunrise/sunset (`core/symbolic/solar.dart`), with one scheduled rebuild at the next phase change and no polling. |
| Onboarding | `app/lib/features/onboarding/onboarding_flow.dart` | Creates the required local profile (birth date, weight, height and body context), enforces the documented 16+ gate, records the primary intention and keeps AI, journal-prose and cloud consent independent and off by default. Height is required so resting burn can be estimated rather than invented. Existing users can resume an incomplete intake without losing their profile. |
| Sanctum | `app/lib/features/sanctum/sanctum_overlay.dart` | Tapping the complete ETER signature opens a plain overlay without unmounting either page. Opening page and guidance register persist through narrow profile updates; system back and explicit Close dismiss it. A collapsed Birth Context editor fulfils onboarding’s promise that exact time can be added later: local time and historical UTC offset are validated as a pair, the place is resolved through the device geocoder, and only then are label/coordinates committed together. Chart-specific readings for old inputs are removed and an open Vessel refreshes immediately. AI, journal-prose and cloud permissions are visible and independently revocable; revoking AI also immediately revokes journal-prose permission while leaving cloud unchanged. A compact Week in View can be prepared entirely on-device from the last seven complete days; it describes only recorded movement, sleep, journal and self-report coverage, explicitly omits missing days rather than converting them to zero, and updates one stable weekly cache row. The Aether Memory `REVIEW` action runs a conservative local-only pattern pass over canonical signals. The first production rule compares sleep after late activity with other nights only when both groups contain at least three observations and differ by at least 30 minutes; its sample counts, window and coefficient remain inspectable, it is always labelled non-causal, and recomputation never revives a dismissed pattern. A two-step memory reset clears only derived Aether guidance/patterns/retrospectives; a separate two-step device deletion clears every local table and explicitly does not claim cloud deletion. |
| Local privacy operations | `app/lib/core/privacy/local_data_export.dart`, `core/db/app_database.dart` | Startup enforces 90-day raw-bucket and 180-day live-HR-series retention without deleting derived winners or session aggregates. The Sanctum can prepare a versioned JSON snapshot of every local table plus CSVs for raw/winning buckets and activity/live sessions. This is explicitly local-only; the authenticated cloud export Function is not represented as complete. |
| Aether trust boundary | `app/lib/core/aether/request_contract.dart`, `context_assembler.dart`, `guidance_contract.dart`, `composer.dart` | Production context assembly reads a bounded seven-day window from canonical local summaries, vitals, staged sleep and AI-eligible journal entries. Provider payloads require current AI consent, contain derived age rather than DOB, omit identity/location/vendor IDs, separately gate and bound journal prose, and fingerprint stable context. Responses must contain exactly four validated dimensions; unsafe or malformed output writes nothing, while unchanged context reuses the complete cached set. The Dashboard compose/refresh trigger is wired through this boundary. Guidance is assigned to the caller’s local day even when health context is empty or spans seven days. No live provider is configured yet; absent transport is stated without changing data. |
| Journal interpretation boundary | `app/lib/core/journal/classification_contract.dart`, `classifier.dart`, `core/db/app_database.dart` | Explicit classification requires current AI consent and accepts only bounded food/lifestyle shapes. Food estimates retain confidence and assumptions, land unconfirmed, and cannot affect totals before review. Classification and derived rows commit atomically and are replay-safe; ambiguous prose records one clarifying question without derived data. The explicit Journal trigger, clarification response and undo path are implemented. No live provider or automatic transmission is configured; without an injected provider the action explains that honestly and writes nothing. |
| Phone health hub | `app/lib/core/health/health_hub.dart`, `platform_health_gateway.dart`, `features/sanctum/sanctum_overlay.dart` | Sanctum exposes one borderless Connect/Refresh Health action on iOS and Android. Apple Health and Health Connect map movement, HR, RHR, HRV, respiratory rate and staged sleep into canonical replay-safe tables; minute overlap still resolves through the existing priority ladder. Each successful movement import refreshes the reactive daily Body summary, preserves intake, and identifies downward recalibration. Resting burn is only derived when height is present, so legacy profiles never receive a fabricated basal total. Permission denial imports no zeroes and is recorded as disconnected. Native permission declarations, HealthKit entitlement and Android FragmentActivity/minSdk 26 are configured. |
| Vessel | `app/lib/features/vessel/vessel_section.dart`, `core/vessel/reading_composer.dart` | Third option inside `LOOK DEEPER`. Natal positions and Life Path calculate locally; shipped `SymbolContent` provides offline keywords. The deterministic daily card appears first with its stored selection reason. `READ DEEPER` shows cached per-chart readings and explicit normal “not composed yet” states. `COMPOSE READINGS` requests only missing positions, preserves cached prose and keywords during work/failure, requires AI consent, validates exact/safe output, and commits the missing set atomically. Provider context contains derived position/card/keyword/reliability data—not name, DOB, place, coordinates or the local chart hash. Unknown birth time/place is stated and never presented as a reliable Ascendant. No live reading provider is configured. |
| Tokens | `app/lib/core/tokens.dart` | One additive token: `EterColors.parchment`. Nothing else touched. |

## Verified

- The complete suite — 196 tests, 31 golden captures — passes.
- `app/test/arrival_test.dart` — 7/7 passing. This is the contract for the
  reveal (cadence, per-sentence budget, tap-to-complete, reduced motion,
  settled rendering). Keep it green.
- `app/test/lifestyle_check_in_test.dart` and
  `app/test/strength_workout_test.dart` are the contracts for the two
  decisions closed on 28 July 2026: reading replacement vs. sitting
  accumulation, and strength energy reaching the day only through the
  deduplicated path.
- `flutter analyze` — no issues.

## Approval-gate status

The previously open shell and capture work is complete:

1. Explicit Journal/Dashboard words use deterministic page jumps; swiping
   retains the continuous pager motion. Shell tests cover navigation, retained
   expansion/draft state and exact semantics.
2. `test/golden/prototype_visual_test.dart` captures Dashboard at 320×568,
   390×844 and 600×960, each at text scales 1.0 and 2.0 in day and night,
   plus Journal day/night and a mid-arrival frame.
3. The matrix caught and drove fixes for the 320 dp/200% Body-row overflow and
   the decorative wordmark's dynamic-type collision. The wordmark now keeps
   fixed lockup geometry while all reading and navigation content scales.
4. Day background option A (`bg-air-day-v6`) is integrated and intentionally
   still. Option B and two header-direction studies remain in `assets/review/`
   for product-owner comparison.

The shell phase now includes its third destination. The next implementation
phase may expand the complete product one section at a time in the order
defined by `UI_BRIEF.md`. Do not reintroduce prototype chrome while doing so.

## Test-environment lessons (hard-won, do not rediscover)

- **Never `await db.close()` in a widget test.** Drift defers stream-store
  closing with `Timer(Duration.zero)`; under FakeAsync it never fires and
  `close()` deadlocks the whole run. Leave the in-memory database open.
- That same deferred timer fails teardown with "pending timers" when the
  widget tree is disposed. Flush inside the test:
  `await tester.pumpWidget(const SizedBox()); await tester.pumpAndSettle();`
- **Cache every `watch*()` stream in `State`.** Drift returns a fresh
  stream per call; created in `build`, every animation frame resubscribes
  the `StreamBuilder` and schedules close timers. Recreate only when the
  day key changes (see `BodySection._ensureStreams`).
- **Never `pumpAndSettle` against a live `SkyBackground`** — its 180 s
  drift ticker never settles. Use timed pumps, or dispose the tree first.
- Semantics finders need `tester.ensureSemantics()`; dispose the handle.
- On Windows, a killed test run orphans `flutter_tester`, which locks
  `build\native_assets\windows\sqlite3.dll` and breaks the next run. Kill
  `flutter_tester` processes before rerunning.
- `PageView` does not mount offscreen children by default; keep-alive only
  preserves what was once built. The shell sets
  `allowImplicitScrolling: true`.

## Guardrails (from the Kimi handoff, still binding)

- Build one Dashboard expansion at a time. Guidance, intake/burn, RHR, HRV,
  single-night sleep stages, weight, recovery summary, per-item nutrition
  correction, the offline/cached Vessel, and the local onboarding/consent gate
  are complete. Onboarding defaults every outbound permission off, records AI,
  journal-prose and cloud consent separately, and remains usable without any
  of them. The 7/30-day stacked sleep history and 24-hour activity instrument
  are also complete against the real sleep-segment and winning-minute
  contracts. Their empty states still say when connected-series data is
  absent; they never convert absence into zero.
- Do not redesign tokens, add a component library, or add a chart package.
  Charts are `CustomPainter` in the `EngravedBalance` idiom.
- Non-negotiables in `UI_BRIEF.md` §2 are defects if violated: no capsules,
  radius 0 (only `rChip`/`rSheet`), no glassmorphism/ring gauges/neon, no
  gamification, reduced motion honoured, nothing essential behind a gesture
  alone, ordinary actions borderless with invisible 48 dp targets.
- Fixture data against the real database contracts; the schema is stable.
- The arrival widget must remain the only implementation of the reveal.

## Definition of done for this milestone

1. The approval questions in `UI_DIRECTION.md` answer *yes* against the
   committed capture matrix.
2. The complete Flutter test suite and `flutter analyze` are green.
3. Goldens contain no `failures/` output; v6 background and its retained
   master/review alternatives are recorded in the asset and commission logs.

## Post-prototype product decisions

The local-first prototype is complete and green. These are the remaining
vertical slices, not hidden cleanup:

1. **Lifestyle capture placement.** *Decided 28 July 2026: the Journal.*
   Mood, stress, recovery, meditation and breathwork are marginal Journal
   prompts, not a Dashboard control cluster. They sit in the Journal's margin
   beside the day's writing, are recorded straight into `LifestyleEntries`,
   and never add a card, a form or a completion state. Body stays a reading
   surface for them; the weekly review keeps consuming the same canonical rows.
2. **Strength experience.** *Decided 28 July 2026: full functionality behind
   progressive disclosure.* Exercise selection, sets/reps/load editing and
   history are complete — not a reduced "workout note" — but nothing of that
   apparatus is visible at rest. Body shows one quiet line; the whole tracker
   opens from it, inside the approved editorial shell (radius 0, borderless
   actions, no capsules, no gym chrome).
3. **Production intelligence.** Guidance, Journal classification and Vessel
   reading contracts are implemented, consent-gated and provider-independent.
   Shipping them needs a selected backend/provider, credentials and deployment
   boundary; the client must not embed a model secret.
4. **Identity and cloud mirror.** Local-only mode is complete. Auth, Firestore
   mirroring, cloud deletion and conflict policy remain a separate
   security-sensitive slice and require a real Firebase project.
5. **Live health/session expansion.** HealthKit/Health Connect import works
   through the platform gateway. Vendor OAuth, BLE sessions and background
   refresh require hardware/vendor choices and platform entitlements.

Until those choices are made, prefer improving verified local flows over
adding placeholders to the resting screen.

## Steering answers — 28 July 2026

The product owner closed four open questions. They are binding.

1. **Lifestyle check-ins → Journal margin.** See decision 1 above.
2. **Strength → complete tracker behind progressive disclosure.** See
   decision 2 above.
3. **ETER header → register-dependent.** Day goes *more* minimal than the
   shipped colophon: the wordmark and the lower plumb-and-star graphic, and
   nothing else. Night is where the elaborate astrolabe concept lives, and
   night may animate. The astrolabe is not a day/night shared asset; it is a
   night register.
4. **Expanded Body density → accepted as is.** `FOOD / ADD MEAL` and
   `WEIGHT / RECORD` stand. Do not re-open that line rhythm; new Body matter
   (strength) must reuse it rather than invent another.
