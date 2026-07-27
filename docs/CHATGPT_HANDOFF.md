# ChatGPT handoff — Eter v2 prototype

State of the work as of 28 July 2026, and what is asked of you. Read the
canonical documents first — [`STEERING_BRIEF.md`](STEERING_BRIEF.md) (product
authority), [`UI_BRIEF.md`](UI_BRIEF.md) (implementation contract),
[`UI_DIRECTION.md`](UI_DIRECTION.md) (composition and the prototype approval
gate). Art commissioning has its own track in
[`ART_COMMISSIONS.md`](ART_COMMISSIONS.md).

## What exists now

The defining prototype from the UI direction's approval gate, implemented in
Flutter against the real Drift contracts with fixture content
(`app/lib/features/prototype/fixtures.dart`). `flutter analyze` is clean.

| Piece | File | Notes |
|---|---|---|
| Signature arrival | `app/lib/core/arrival.dart` | One widget serves guidance and Journal. Word groups resolve from blur in ≤ `durSentence` per sentence, pauses between sentences, ≤4 dp displacement on `easeAir`, tap completes, reduced motion renders settled on frame one. |
| Shell | `app/lib/features/shell/eter_shell.dart`, `shell_header.dart` | Horizontal pager Journal↔Dashboard, `allowImplicitScrolling` + keep-alive for state preservation, persistent two-word switch with travelling gold hairline, ETER celestial header as `CustomPainter` (commissioned as code in the asset manifest). |
| Dashboard | `app/lib/features/dashboard/dashboard_page.dart`, `body_section.dart` | Synthesis owns the resting view above one `LOOK DEEPER` threshold. Its in-place chooser opens expanded Guidance or Body, never simultaneous rows. Guidance renders Health/Mind/Spirit prose and marginal evidence receipts. Body begins with a conclusion, states missing signals, then recovery prose, `EngravedBalance`, engraved RHR/HRV/weight trends, a measured sleep-stage rail, and editable food lines; estimates are visibly not counted until corrected/confirmed. Every instrument has a complete semantic summary. |
| Journal | `app/lib/features/journal/journal_page.dart` | Date-led ruled parchment page (grain reused, no enclosing border), tap-page-to-write, invisible 900 ms autosave and one borderless `DICTATE` action (`speech_to_text`). No checkmarks, Done/Save action, toggle or composer chrome. Entries read as continuous timed prose and arrive via the shared reveal. |
| Register wiring | `app/lib/main.dart` | `GuidanceMode` → `EterRegister` via real sunrise/sunset (`core/symbolic/solar.dart`), one scheduled rebuild at the next phase change, no polling. |
| Sanctum | `app/lib/features/sanctum/sanctum_overlay.dart` | Tapping the complete ETER signature opens a plain overlay without unmounting either page. Opening page and guidance register persist through narrow profile updates; system back and explicit Close dismiss it. |
| Vessel | `app/lib/features/vessel/vessel_section.dart` | Third option inside `LOOK DEEPER`. Natal positions and Life Path calculate locally; shipped `SymbolContent` provides offline keywords. The deterministic daily card appears first with its stored selection reason. `READ DEEPER` shows cached per-chart readings and explicit normal “not composed yet” states. Unknown birth time/place is stated and never presented as a reliable Ascendant. |
| Tokens | `app/lib/core/tokens.dart` | One additive token: `EterColors.parchment`. Nothing else touched. |

## Verified

- `app/test/arrival_test.dart` — 7/7 passing. This is the contract for the
  reveal (cadence, per-sentence budget, tap-to-complete, reduced motion,
  settled rendering). Keep it green.
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
  correction and the offline/cached Vessel are complete. The 7/30-day sleep
  view and activity-by-time instrument still need connected-series handling;
  the fixture deliberately shows activity as unavailable rather than zero.
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
