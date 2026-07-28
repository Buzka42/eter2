# UI brief

You are building the surfaces of Eter. The foundation beneath them exists: the
design system, the register, the symbolic engine, the content layer and the
database are done, tested, and described below.

**Read [`STEERING_BRIEF.md`](STEERING_BRIEF.md) first.** It is the product
authority and it overrides this document wherever they disagree. This brief
tells you what to build and what you have to build it with; that one tells you
what the product *is*.

Then read [`UI_DIRECTION.md`](UI_DIRECTION.md). It translates both briefs into
a compositional system, interaction-state checklist and three concept plates.
The plates are mood and hierarchy studies, not screenshots to trace.

---

## 1. The one-paragraph version

Eter is a private AI companion. You write or dictate into a **Journal**; a
**Dashboard** carries the day's guidance, a health widget and your astrogram.
Aether is the intelligence that reads them together. The surface shows a few
carefully chosen sentences and almost nothing else; everything detailed is one
deliberate tap beneath it. The application should feel like *one quiet
continuous space*, not a set of tools.

---

## 2. Non-negotiables

These are not preferences. Violating one is a defect.

1. **No capsules.** No `BorderRadius.circular(999)`, no stadium buttons, no
   pills, no chips-as-lozenges. `EterAction` exists precisely because Material's
   filled button is the single strongest "AI slop" tell. It has no filled
   variant by design.
2. **Radius is 0.** Everything is square-cornered. The only exceptions in the
   entire system are `rChip = 12` (the arcana card) and `rSheet = 28` (modal
   sheets). Do not introduce a third.
3. **No glassmorphism, no ring gauges, no neon, no gradient meshes, no
   uniform-radius card grids.** The brief lists these; they read as generated.
4. **Text readability beats atmosphere.** Every time. The brief says so
   explicitly.
5. **No gamification.** No streaks, no badges, no confetti, no milestone
   fanfare. The v1 milestone system was deleted, not ported.
6. **Reduced motion is honoured everywhere.** Check
   `MediaQuery.disableAnimationsOf(context)`. Under it: no ambient motion, no
   card drift, no video, no staggered reveal — the text simply appears.
7. **Nothing essential behind a gesture alone.** The brief: *"Minimalism must
   not make important features difficult to discover. Essential functions should
   not depend entirely on hidden gestures or unexplained symbols."* The
   Journal↔Dashboard pager therefore needs a **persistent visible affordance**.
   A swipe alone is a defect.
8. **Never present symbolic content as medical fact**, and never let it override
   a health number. `safety_policy.dart` enforces this on generated text; you
   enforce it in layout and copy.
9. **The resting surface shows less than the concept plates.** No metrics,
   charts or three-section menu below the initial guidance. Present one quiet
   disclosure at a time.
10. **Ordinary actions are borderless.** Keep their visible form compact while
    preserving an invisible minimum 48×48 dp target. Four-sided button borders
    are not part of the house language.

---

## 3. The register — read this carefully, it drives everything

`lib/core/register.dart`.

There are two visual registers, **`EterRegister.day`** and
**`EterRegister.night`**. There is no third.

The user's setting is `GuidanceMode` (`grounded` | `balanced` | `immersive`),
and it resolves like this:

| Setting | Renders as |
|---|---|
| `grounded` | always `day` |
| `immersive` | always `night` |
| `balanced` *(default)* | `day` between local sunrise and sunset, `night` after |

Sunrise and sunset are real, computed from the user's coordinates
(`core/symbolic/solar.dart`). The app turns symbolic at *their* sunset, in
*their* city. `nextPhaseChangeAfter()` tells you when to schedule the rebuild —
do not poll.

**Day is still. Night moves.** There are 25 night card loops and zero day loops,
and that is deliberate, not a gap. Never request motion in the day register.

### The ceiling model

`EterRegister` is a **ceiling**, not a level. Pair it with `SurfaceIntent`:

- `SurfaceIntent.plain` — instruments. The Journal, figures, charts, the
  Sanctum. Never ornamented, whatever the register.
- `SurfaceIntent.ritual` — moments. The guidance reveal, onboarding, the arcana
  reveal, the Vessel. Ornamented as far as the register permits.

Always resolve through **`showsOrnamentHere(context)`**, never
`EterRegister.of(context).showsOrnament` directly. Wrap subtrees in
`SurfaceIntentScope`.

Available on the register: `showsOrnament`, `showsCompanionCard`,
`showsHeroCard`, `showsAmbientMotion`, `brightness`, `ornamentIntensity`
(0.2 day / 0.7 night — tune opacities against this rather than scattering
constants).

---

## 4. What you have to build with

All ported, all working. Do not rebuild these; do not reach for Material
equivalents.

### `core/tokens.dart`
- `EterColors` — day sky (`mist0`, `mist50`, `sky100`–`sky500`), ink
  (`ink900/600/400`), gold (`aura200`–`aura700`, `gild`), night
  (`night900/800/700`, `nightText/2/3`), semantic (`success`, `warn`, `danger`),
  element accents with contrast-safe `*Deep` variants for day surfaces.
- `EterMotion` — `easeAir` is the house curve. Durations: `durMicro` 180,
  `durStandard` 320, `durEmphasis` 600, `durReveal` 900, `durSentence` 1200,
  `listStagger` 40.
- `EterSpace` — 4/8/12/16/24/32/48/64, `gutter` 24.

### `core/controls.dart`
`EterInk` (the one place colours resolve — use it), `EterAction`
(primary/secondary/quiet; emphasis changes the *rule*, not a fill),
`EterOptionChip`, `EterToggle`, `EterSlider`, `EterRule`. Minimum target 52 px.

### `core/widgets.dart`
`EterPlate` (flat, sharp-edged, hairline top rule — the surface primitive),
`ElementMedallion`, `EmptyStateOrnament`, `AuraRing`, `CountUpText`,
`StarOrnament` (the eight-pointed signature mark), `OrnamentDivider`.

### `core/instruments.dart`
`EngravedBalance` — a real beam balance with an elastic settle. This is the
idiom for **every** chart you build. See §7.

### `core/theme.dart`
`EterTheme.day()` / `EterTheme.night()`. `SkyBackground` is the shared plate
(static WebP under an optional night video, 3% oversample panned over 180 s).
`EterPageTransitionsBuilder` is the "gust" — fade plus 2.5% slide on `easeAir`.

Typography: **Cormorant Garamond** for display and editorial prose, **Inter**
for text and numerals with tabular figures forced on. Marcellus and Manrope are
gone; do not reintroduce them.

### `core/arcana/`
`Zodiac`, `MajorArcana` (22 cards, `assetFor(brightness)`,
`nightLoopFor(brightness)`), `AnimatedArcanaCard` (flip reveal; static art is
mandatory and video only ever composites on top), and **`SymbolContent`** — the
static keyword layer, see §8.

---

## 5. The shell

Three destinations. Not five, not a tab bar.

```
   ← Journal ═══════════════ Dashboard →     horizontal pager, one continuous space
                  ↕
               Sanctum                        settings, overlay
```

- A horizontal `PageView` between Journal and Dashboard. This honours "one
  space, not separate dashboards" while giving the user two front doors.
- `Profile.startSurface` (`journal` | `dashboard`) picks the initial page.
- **Both destinations need a persistent visible affordance** — see
  non-negotiable 7. Solve it in the house idiom: two letterspaced caps labels
  with a travelling gold hairline beneath the active one, not a Material tab bar
  and not a dot indicator.
- Centre the small `ETER` mark in a shallow, shared solar/lunar or astrolabe
  engraving. This approved astrological flavor is the shell's main ornamental
  signature and the visible Sanctum threshold. Keep it identical on Journal
  and Dashboard; exclude the engraving from semantics while exposing the
  complete 300×72 mark as the `Open Sanctum` button.
- The Sanctum is an overlay with `PopScope` to intercept system back, not a
  route push.
- State is preserved across page changes. Scroll position, expansion state, a
  half-written journal entry — all survive.

---

## 6. The Journal

An open, date-led personal journal page. `SurfaceIntent.plain`.

- Two inputs: keyboard and dictation. Dictation is on-device
  (`speech_to_text`), so it carries transcription error the user may want to
  fix — make correction easy, not buried.
- It must look like a journal, not a form or chat composer: a warm paper-like
  writing field, subtle grain and margin rhythm, open prose, date as heading and
  time in the margin. No complete border around the editor and no card per
  entry.
- Keyboard input starts by tapping the open page. Dictation is the only
  persistent visible action, rendered as a compact borderless word with a
  48×48 dp semantic hit region. Saving is automatic and invisible; there is
  no Done, Save, checkmark, privacy toggle or completion state in the writing
  surface.
- Today's entries in reverse-chronological order; older days behind a date
  affordance.
- **Capture is the whole game.** The path from intent to recording should be as
  close to one tap as the platform allows. If your layout adds a step, the
  layout is wrong.

### The arrival

New entries do not appear. They **arrive**, using the same reveal as the
guidance. From the brief:

> The advice should form progressively, as if the sentences were being written
> into the air. It should not resemble a terminal or conventional typewriter
> animation.
>
> Possible qualities: characters resolving from blur; words gently appearing
> from darkness or light; subtle movement into focus; restrained pauses between
> sentences; a faint sense of depth or atmosphere.

Requirements:
- **Build this once.** One reveal widget serves both the Journal and the
  guidance. It is the product's signature interaction and must not exist twice.
- Tap anywhere reveals the full text immediately.
- Under reduced motion it does not animate at all.
- `EterMotion.durSentence` (1200 ms) is the per-sentence budget.

**This is the highest-value thing you will build.** The steering brief's *First
design objective* says to prove exactly this interaction before building the
surrounding application. Do that: build the reveal and one surface around it,
get it right, then continue.

---

## 7. The Dashboard

Three content sections exist, but they are **not three persistent rows on the
resting screen**. The resting Dashboard shows guidance and one compact,
contextual disclosure. Choosing Body, Vessel or expanded Guidance opens that
section in place (`AnimatedSize`)—never a route push. Only one may be expanded.
Closing it restores the guidance and its scroll state.

### 7.1 Guidance — top
- **Collapsed:** the day's reading, two or three sentences, one clear direction.
  Nothing else. This is the default screen and it should be spacious and
  text-focused; the brief is explicit that metrics, charts and symbols must not
  compete with it.
- **Expanded:** three dimensions — Health, Mind, Spirit — each its own passage.
- **Evidence chips.** Any claim resting on data carries a tappable receipt: n,
  window, coefficient, and the non-causal caveat. Data is in
  `GuidanceHistory.evidenceJson`. Design these to feel like a marginal
  annotation — a small gold reference mark — not a Material chip.
- `SurfaceIntent.ritual`.

### 7.2 The Body — health, middle
- **Collapsed:** no permanent metric strip. When Body is the contextual
  disclosure, it may show one short textual fact beside the word `Body`, never
  a multi-metric row or sparkline competing with guidance.
- **Expanded:** full charts, manual activity entry, food editing **including
  per-item correction** (changing one line of an extracted meal from 320 kcal to
  260). This was specced in v1 and never shipped; it is required now.
- **Unconfirmed food estimates must be visibly unconfirmed** and must not read
  as fact. The database already excludes them from totals; the UI must not imply
  otherwise.
- **Say what you cannot see.** A user with no wearable has steps and nothing
  else. State the absence rather than rendering an empty chart that implies
  zero. This is the v1 lesson that mattered most: the old build showed
  "−828 kcal · a lighter balance today" when the user simply had not logged
  food, which in a calorie app is an endorsement the product must never make.
- `SurfaceIntent.plain`.

**Charts are `CustomPainter` in the `EngravedBalance` idiom.** No charting
package — importing one imports a visual language this codebase has spent
fourteen commits removing. Engraved hairlines, measure ticks, tabular numerals.
Needed: sleep stages (stacked, 7/30 d), resting HR trend (30/90 d), HRV trend,
activity by time of day (24 buckets), intake vs burn (use `EngravedBalance`),
weight.

### 7.3 The Vessel — astrogram and life path, bottom
- **Collapsed:** each position, its card, and 3–5 keywords. Exactly the shape
  the product owner specified: `Strength · power, energy, action, courage,
  magnanimity`. All of this is local and offline — see §8.
- **Expanded:** the full interpretation, composed against *this user's* chart.
- **The daily card sits at the top with its reason.** The application chooses
  it, not the model; `DailyCards.reason` holds why, in the app's own words, and
  the user can ask. The brief requires this.
- `SurfaceIntent.ritual`.

---

## 8. Content — two layers, and the split matters

**Static, shipped, offline** — `SymbolContent.load()`, from
`assets/content/*.json`. Keywords, correspondences, domains, reframed subtitles,
for 22 cards, 12 signs, 12 life paths, 12 houses, 13 chart points. This is what
the collapsed Vessel renders and what shows when there is no network. It is
complete and test-enforced.

**Composed per user, cached forever** — the long-form reading. Generated against
the real chart and stored in `VesselReadings`, keyed by `(inputHash,
positionKey)`. Composed once, ever.

**What this means for you:** an uncomposed reading is a normal state, not an
error. Show the keywords and say the reading has not been composed yet. Never
show a spinner where a keyword would do, and never show an error for something
that has simply not been asked for yet.

Death and The Devil keep their authentic names; the reframing lives in the
subtitle (`Card of Transformation`, `Card of Ambition`). Do not soften the
names.

---

## 9. Data contracts

**Built and available now:**
- `core/db/app_database.dart` — 21 tables, all queries. `watchProfile`,
  `watchDaySummary`, `watchJournalForRange`, `watchNutritionForRange`,
  `watchSleepForNight`, `watchVitals`, `watchGuidanceForDate`,
  `watchIntegrations`, `loadActivePatterns`, `loadDailyCard`,
  `loadVesselReading`, `loadIntakeAnswers`. Streams where the UI should react.
- `core/symbolic/natal_chart.dart` — deterministic chart, 13 points, aspects.
- `core/symbolic/numerology.dart`, `core/symbolic/solar.dart`.
- `core/arcana/symbol_content.dart`.
- `core/energy/energy.dart` — RMR, HR→kcal, the deduplication ladder.

**Not built yet.** Build against the database and use fixtures; do not block:
- The live Aether provider transport and app-level composition trigger.
  Production context assembly, provider-independent request/response
  boundaries, consent gates, PII omission, seven-day health/journal bounds,
  safety validation, atomic persistence, and unchanged-context caching are
  implemented.
- Vendor-direct integrations and background/differential sync. The phone health
  hub is implemented for an explicit 30-day Apple Health / Health Connect
  read from Sanctum, including native permissions, canonical minute
  deduplication, staged sleep, daily vitals, honest denial/error states, and
  integration diagnostics.
- The live journal-classification provider and explicit UI trigger. The strict
  food/lifestyle response contract, current-consent gate, atomic application,
  replay protection, clarification state, and unconfirmed-estimate behavior
  are implemented.
- Profile providers, auth, Firebase wiring, onboarding.

Where you need data that does not exist yet, read the table it will land in and
render fixtures. The schema is stable.

---

## 10. Accessibility

Not a later pass. The brief ranks accessibility above decorative animation.

- Dynamic type to 200% with no clipped essential content.
- 320–600 dp widths.
- Every control has a meaningful semantic label and a sensible focus order.
- Minimum 48 px targets; `EterAction` is already 52.
- Screen-reader order matches visual order, including inside expanded sections.
- Gold line-work on the day sky measures ~1.15:1 — it is decorative only.
  **Never carry information in it on a day surface.** (This remains an open
  product decision; treat it as decoration until told otherwise.)

Sanctum’s structured personalization controls follow the same contract:
pattern evidence is spoken before its independent Dismiss action, and both
memory reset and full local deletion require a consequence-revealing first
action before the destructive second action appears.

---

## 11. Testing

Port the v1 golden harness — it already solves the hard parts: real fonts via
`FontLoader` in `setUpAll`, the clock pinned through `nowProvider`
(`core/clock.dart`), an in-memory Drift database, and a warm-up render pass
before capture.

Scenarios, each × day/night: Journal (empty, writing, arrived), Dashboard
collapsed, each section expanded, each chart, onboarding intake, consent, the
Sanctum. Plus a reduced-motion pass asserting no `VideoPlayer` mounts and no
ambient animation runs, and a tap-target pass.

**Add `test/**/failures/` to `.gitignore` before you generate a single golden.**
The v1 tree committed 132 golden-failure images and left the suite red. Already
done in this repo's `.gitignore` — keep it that way.

---

## 12. Order of work

1. **The reveal, and one surface around it.** Prove the defining interaction
   with mock content. Nothing else matters until this feels right.
2. The shell — pager, visible affordance, Sanctum overlay, state preservation.
3. The Journal.
4. The Dashboard, collapsed only.
5. Expansion, section by section, charts last.
6. Onboarding.

Do not build all three sections before the first one is right.

---

## 13. When something is ambiguous

Use the brief's own principles, in order: reuse before replacing · simplicity at
the surface, depth underneath · health before mysticism when safety is involved
· extension rather than visible division · guidance before dashboards · user
agency before AI authority · deterministic calculation before model
improvisation · local before cloud · structured, inspectable personalization
before opaque memory · accessibility before decorative animation.

If the answer is still unclear, build the quieter option.
