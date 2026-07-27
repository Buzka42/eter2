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
| Dashboard | `app/lib/features/dashboard/dashboard_page.dart`, `body_section.dart` | Guidance from `GuidanceHistory` (synthesis), one borderless `Body` disclosure, in-place `AnimatedSize` expansion: conclusion in words first, then one fixture-backed `EngravedBalance`, explicit close. Absences stated, never zeroed. |
| Journal | `app/lib/features/journal/journal_page.dart` | Date-led parchment page (grain reused, no border), tap-page-to-write, 900 ms autosave, borderless dictate (`speech_to_text`) and Done actions, marginal privacy switch writing `excludedFromAi`, entries arrive via the shared reveal. |
| Register wiring | `app/lib/main.dart` | `GuidanceMode` → `EterRegister` via real sunrise/sunset (`core/symbolic/solar.dart`), one scheduled rebuild at the next phase change, no polling. |
| Tokens | `app/lib/core/tokens.dart` | One additive token: `EterColors.parchment`. Nothing else touched. |

## Verified

- `app/test/arrival_test.dart` — 7/7 passing. This is the contract for the
  reveal (cadence, per-sentence budget, tap-to-complete, reduced motion,
  settled rendering). Keep it green.
- `flutter analyze` — no issues.

## Known-open — start here

1. **Shell navigation in widget tests.** In `app/test/shell_test.dart`, 3/8
   pass. The failing five share one symptom: after
   `tester.tap(find.text('JOURNAL'))` + `pump(400 ms)`, `JournalPage` is not
   in the tree and the page does not change. Two hypotheses, in order:
   (a) test-environment artifact — the offscreen page is not mounted even
   with `allowImplicitScrolling`, and/or the tap does not reach `_goTo`;
   (b) a real defect in the switch or pager. Check on a device or emulator
   first; if the tap works there, fix the tests, not the shell. If it does
   not, the fallback is `_controller.jumpToPage`, which cannot silently fail.
2. **Unverified behaviours the tests were meant to prove:** expansion and
   half-written-entry state surviving the page crossing; the exclusion
   switch persisting `excludedFromAi`; tap-target sizes via
   `tester.getSemantics` (needs `tester.ensureSemantics()` first).
3. **Golden captures — the remaining gate deliverable.** Widths 320/390/600
   dp × text scales 1.0/2.0 × day/night for the Dashboard, plus Journal
   day/night and one mid-arrival capture. Harness pieces exist in
   `app/test/helpers/prototype_harness.dart` (real fonts via `FontLoader`,
   pinned clock via `nowProvider`, in-memory Drift, surface sizing). Put
   scenarios in `app/test/golden/`, images beside them; `test/**/failures/`
   is already gitignored — keep it that way.

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

- Prototype approval gate scope only — no Sanctum, no Vessel section, no
  expanded guidance dimensions, no evidence chips yet.
- Do not redesign tokens, add a component library, or add a chart package.
  Charts are `CustomPainter` in the `EngravedBalance` idiom.
- Non-negotiables in `UI_BRIEF.md` §2 are defects if violated: no capsules,
  radius 0 (only `rChip`/`rSheet`), no glassmorphism/ring gauges/neon, no
  gamification, reduced motion honoured, nothing essential behind a gesture
  alone, ordinary actions borderless with invisible 48 dp targets.
- Fixture data against the real database contracts; the schema is stable.
- The arrival widget must remain the only implementation of the reveal.

## Definition of done for the next step

1. The six approval questions in `UI_DIRECTION.md` answered *yes* against
   the running prototype (they require the captures in item 3 above).
2. `shell_test.dart` green, `arrival_test.dart` still green, goldens
   committed (no `failures/` images).
3. `bg-air-day-v6` commissioned via `ART_COMMISSIONS.md`, accepted through
   its gate, swapped into `SkyBackground` (replacing the v5 fallback) and
   recorded in the manifest log.
