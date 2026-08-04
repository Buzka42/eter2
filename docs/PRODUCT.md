# Eter · what it is, and why it is like this

Everything about the product that the code cannot tell you: the owner's own
brief, the surfaces it asks for, and the decisions that have been settled since.

Four documents were folded in here on 5 August 2026 — the steering brief, the
UI brief, the UI direction and the decision log. Their originals are in
`archive/`, unchanged, if you ever need to see one on its own.

**Read the steering brief first and treat it as the authority.** It is a
faithful transcription of the owner's own document and it overrides everything
below it wherever they disagree. The UI brief says what to build; the direction
says what it should feel like; the decision log says what has already been
argued out and must not be relitigated.

## What is in here

1. **The steering brief** — the product, in the owner's words.
2. **The UI brief** — the surfaces, their contracts, and the non-negotiables.
3. **The UI direction** — composition, register, the concept plates.
4. **Decisions** — what was chosen, what it was chosen over, and what it cost.

---

## Eter — Codex Steering Brief

> **Provenance.** This is a faithful transcription of an 11-page PDF authored by the
> product owner, previously existing only as rendered page images in the gitignored
> `tmp/pdfs/steering-brief/` directory on a single machine. It is the authoritative
> product direction and supersedes the product framing in `README.md` and the archived
> specification set. Transcribed 27 July 2026 so that it survives a fresh clone.
>
> An editorial note recording where the approved v2 rebuild plan knowingly diverges from
> this brief appears at the end, clearly separated from the brief's own text.

---

### Product direction

Eter should evolve from its current health-tracking application into a minimalist AI
lifestyle companion.

This is not intended to be a clean-slate rewrite. Inspect the existing repository and
reuse as much as reasonably possible, especially:

- working health-tracking logic;
- data models and persistence;
- nutrition, weight, activity, and strength features;
- timeline functionality;
- Bluetooth and live-session functionality;
- theme foundations;
- Arcana artwork and animations;
- existing tests and platform integrations.

Improve or replace existing components only when there is a clear architectural,
usability, performance, safety, or maintainability reason.

Do not assume the existing README is a complete or authoritative product specification.
Treat it as background information about the current application.

The detailed implementation plan should be designed after auditing the repository.

---

### Core concept

Eter is a private AI companion that helps users improve their health and, over time,
their broader lifestyle.

The initial priority is physical wellbeing:

- nutrition;
- weight;
- movement;
- strength training;
- sleep;
- recovery;
- stress;
- mood;
- meditation;
- breathwork;
- reflection.

The application should gradually develop into a broader lifestyle companion capable of
helping users decide:

- when to act;
- when to recover;
- what deserves attention;
- which habit should be improved;
- when discipline is useful;
- when restraint is more appropriate;
- which reflective or contemplative practice may help.

The guiding idea is that physical wellbeing provides the foundation for mental and
spiritual wellbeing.

Eter should not present itself as a medical device or as a replacement for professional
healthcare.

---

### Eter and Aether

Use one application named **Eter**.

Do not build separate Lite and Premium applications.

Use **Aether** as the identity of the AI guide inside Eter.

Examples:

- Aether prepared today's guidance.
- Aether noticed a pattern.
- Ask Aether.
- Why did Aether suggest this?

The distinction should be:

- **Eter:** the application and personal environment;
- **Aether:** the intelligence that interprets the user's information.

---

### Main experience

The main feature should be a small amount of personalized advice appearing on screen.

The advice should form progressively, as if the sentences were being written into the
air. It should not resemble a terminal or conventional typewriter animation.

Possible qualities include:

- characters resolving from blur;
- words gently appearing from darkness or light;
- subtle movement into focus;
- restrained pauses between sentences;
- a faint sense of depth or atmosphere.

The user should be able to reveal the full text immediately.

Reduced-motion settings must be respected.

The default screen should remain spacious and text-focused. Health metrics, charts,
controls, and symbolic details should not compete with the advice.

The complexity should exist beneath the interface rather than on its surface.

---

### Continuous interface

The application should feel like one continuous space.

Features should not feel like separate applications, dashboards, or disconnected pages.
Opening nutrition, astrology, journaling, workouts, or insights should feel like
extending the current experience.

Examples:

- nutrition information unfolds beneath the advice;
- a reflection field grows from the daily question;
- astrological geometry gradually emerges in the background;
- an Arcana card resolves from an existing visual motif;
- detailed health information appears only when requested;
- closing a feature naturally restores the main guidance.

The internal code may remain modular, but the user should not perceive strong divisions
between modules.

Prefer shared transitions, state preservation, and visual continuity over abrupt route
changes.

Minimalism must not make important features difficult to discover. Essential functions
should not depend entirely on hidden gestures or unexplained symbols.

---

### Visual direction

Preserve the general artistic identity of the existing application and improve it.

The desired direction is:

> Ethereal minimalism focused on wisdom.

Retain or refine elements such as:

- midnight navy;
- cloud blue;
- parchment;
- warm ivory;
- antique gold;
- celestial engravings;
- astronomical instruments;
- Arcana artwork;
- constellations;
- subtle atmospheric movement;
- complete light and dark themes.

The application should feel contemplative, intelligent, weightless, and timeless.

Avoid:

- generic fantasy-game interfaces;
- neon occult imagery;
- excessive visual effects;
- dense dashboards;
- decorative fonts that reduce readability;
- stereotypical crystal or fortune-telling aesthetics;
- heavy gamification.

Text readability and interaction clarity take priority over atmosphere.

---

### Guidance styles

Allow users to control how strongly the mystical layer appears.

Use three broad modes:

#### Grounded

Primarily practical health and behavioral guidance.

Astrology, numerology, and Arcana remain subtle or hidden.

#### Balanced

Health information and symbolic interpretation are both visible.

#### Immersive

Astrology, numerology, Arcana, and contemplative language have a stronger presence.

These should not be three separate products or recommendation systems.

The underlying health reasoning and safety rules should remain consistent. The main
differences should be tone, framing, symbolism, and visible depth.

---

### Health and symbolic information

Keep objective and symbolic information conceptually separate.

Objective information may include:

- food and nutrition;
- weight and trends;
- sleep;
- workouts;
- activity;
- recovery;
- mood;
- stress;
- meditation;
- breathwork;
- journals;
- goals;
- behavioral patterns.

Symbolic information may include:

- natal astrology;
- current transits;
- moon phase;
- numerology;
- personal cycles;
- Arcana;
- symbolic themes.

Astrology and numerology calculations should be deterministic rather than calculated by
the language model.

The AI should receive structured results and interpret them alongside the user's actual
health and lifestyle context.

Health and safety information should override conflicting symbolic interpretations.

Symbolic systems should be used as frameworks for reflection and presentation, not as
scientifically proven predictors.

---

### Arcana

Arcana should remain an important part of the experience, but they should not dominate
every screen.

The daily card should ideally be connected to the user's context rather than selected
without explanation.

Its relevance may be influenced by:

- numerological cycles;
- astrological context;
- recent health information;
- goals;
- recent behavior;
- previous cards;
- current lifestyle needs.

The precise selection system should be designed during implementation.

The AI may interpret the selected card, but the application should retain control over
how the card is chosen.

The card may appear as:

- a faint background engraving;
- a subtle symbol;
- an atmospheric motif;
- an optional full reveal;
- part of the daily guidance.

---

### AI direction

Use Gemini initially, but keep the application independent from a single AI provider.

Aether should be accessed through a provider abstraction so the system can later support:

- another cloud provider;
- a self-hosted model;
- an on-device model;
- different models for different tasks.

Do not expose Gemini credentials in the mobile client.

Use an appropriate backend or secure proxy for provider access, rate limits, validation,
and usage controls.

Important AI outputs should use structured responses rather than depending entirely on
unvalidated prose.

AI should initially support:

- daily guidance;
- food estimation from natural language;
- reflective prompts;
- concise explanations;
- pattern interpretation;
- periodic summaries.

Avoid turning the first release into an unrestricted general-purpose chatbot.

---

### AI food tracking

Provide two broad nutrition paths:

1. import nutrition data from supported external health or calorie-tracking sources where
   technically and legally available;
2. use Aether as a personal food-logging assistant.

The user should be able to describe a meal naturally.

Aether should estimate:

- food items;
- portions;
- calories;
- protein;
- carbohydrates;
- fat;
- confidence;
- important assumptions.

The result should remain editable and require confirmation before being saved.

Food estimates must be presented as estimates rather than precise measurements.

Reuse existing nutrition data structures where they remain suitable.

---

### Personalization and memory

Aether should become more useful as it learns the user's patterns.

Examples might include:

- sleep tends to decline after late workouts;
- mood often improves after walking;
- protein intake falls on weekends;
- meditation is associated with lower reported stress;
- performance improves after sufficient recovery.

Do not treat correlations as proven causes.

Users should be able to:

- inspect learned patterns;
- dismiss incorrect patterns;
- control what information Aether may use;
- exclude journal content;
- reset personalization;
- export or delete their information.

Avoid sending an unlimited raw history to the AI. Consider maintaining concise,
structured, inspectable summaries.

The detailed memory architecture should be proposed after reviewing the current data
model.

---

### Privacy and safety

The product should remain local-first where practical.

Core tracking should continue to work without AI availability.

Sensitive health, journal, birth, and behavioral information should be treated carefully.

The user should have clear control over which data is sent for AI processing.

The application should not:

- diagnose medical conditions;
- prescribe treatment;
- advise medication changes;
- recommend dangerous calorie restriction;
- encourage compulsive exercise;
- recommend ignoring pain or injury;
- use astrology as medical evidence;
- make deterministic predictions about major life events;
- imply that users must consult Aether before making decisions.

Provide graceful fallback behavior when Gemini is unavailable.

The fallback may use:

- locally calculated health summaries;
- deterministic Arcana;
- rule-based safe suggestions;
- cached previous guidance.

---

### Free and premium direction

Use one application with feature entitlements rather than two applications.

A possible product structure is:

#### Core experience

- health tracking;
- basic nutrition;
- weight and activity;
- basic daily guidance;
- Grounded mode;
- local records;
- limited AI food assistance.

#### Expanded experience

- Balanced and Immersive modes;
- full astrology and numerology;
- deeper Arcana interpretation;
- advanced personalization;
- learned patterns;
- periodic reviews;
- broader meditation and breathwork guidance;
- more extensive Aether access;
- future synchronization or advanced integrations.

Treat this as a direction, not a fixed pricing specification.

Design entitlements so features can change without deeply coupling subscription checks to
individual widgets.

---

### Rebuild approach

Begin by auditing the existing repository.

The audit should determine:

- what is stable;
- what can be reused directly;
- what should be refactored;
- what must be replaced;
- which assets should be preserved;
- whether the current database can be migrated safely;
- where current architecture will obstruct the new experience;
- which existing features already meet the intended direction.

After the audit, propose:

- a target architecture;
- an incremental migration strategy;
- a main experience-shell concept;
- an AI integration strategy;
- a data and privacy approach;
- a staged implementation plan;
- an initial prototype scope.

Do not create a large fixed implementation plan before understanding the existing code.

Favor incremental evolution over broad replacement.

Keep the application runnable throughout the process.

Preserve user data and introduce migrations where needed.

---

### First design objective

Before integrating every planned feature, prove the central experience.

The first prototype should demonstrate:

- the atmospheric main screen;
- progressively appearing advice;
- immediate text reveal;
- reduced-motion behavior;
- a minimal feature control;
- one existing health feature opening as an extension of the main screen;
- a smooth return to the advice;
- preservation of state;
- reuse of existing theme or artwork.

The exact feature, architecture, and animation implementation should be selected after
inspecting the codebase.

Use mock advice if necessary.

The purpose is to verify the product's defining interaction before rebuilding the
surrounding application.

---

### Decision-making principles

Use these principles when detailed requirements are unclear:

1. Reuse before replacing.
2. Simplicity at the surface, depth underneath.
3. Health before mysticism when safety is involved.
4. Extension rather than visible division.
5. Guidance before dashboards.
6. User agency before AI authority.
7. Deterministic calculations before model improvisation.
8. Local functionality before cloud dependency.
9. Structured, inspectable personalization before opaque memory.
10. Accessibility before decorative animation.
11. One application rather than duplicated products.
12. Provider independence before Gemini lock-in.
13. Incremental migration rather than destructive rebuilding.

---

### Desired result

Eter should not feel like a collection of health and spiritual tools.

It should feel like a quiet environment containing an intelligence that understands the
user's physical condition, goals, habits, and chosen symbolic framework.

At the surface, the product should present:

- a few carefully chosen sentences;
- one clear direction;
- a calm visual atmosphere;
- minimal controls.

Behind that surface, users should be able to access:

- nutrition;
- activity;
- strength;
- sleep;
- weight;
- recovery;
- reflection;
- meditation;
- astrology;
- numerology;
- Arcana;
- insights;
- long-term history;
- personalization.

Codex should use this brief to steer the redesign, inspect the existing application, and
propose the precise technical and implementation plan before making major changes.

---

---

## Editorial note — where the v2 plan diverges

*Not part of the brief. Recorded here so the divergences are deliberate and visible
rather than accidental.*

The v2 rebuild plan was approved by the product owner on 27 July 2026 with four decisions
that knowingly depart from this document. Each was raised explicitly and confirmed.

| Brief says | v2 plan does | Why |
|---|---|---|
| "Incremental migration rather than destructive rebuilding" (principle 13); "keep the application runnable throughout"; "preserve user data and introduce migrations where needed" | New folder, fresh Drift schema v1, no migration path | The fitness-shaped schema and the five-movement Aether scroll obstruct the new information architecture. There are no external users, so no user data is at risk. Roughly 60% of `lib/` still ports across intact — this remains a port, not a rewrite. |
| "The product should remain local-first where practical"; sensitive journal information "treated carefully" | Journal prose is sent to the model **and** synced to Firestore | The product owner chose guidance that can reference what the user actually wrote, and cloud history that survives a phone swap. This retires the codebase's hardest-enforced privacy invariant. Mitigations required: explicit consent in onboarding, per-entry exclusion (which this brief itself calls for), and a delete that provably removes both copies. |
| "Avoid sending an unlimited raw history to the AI. Consider maintaining concise, structured, inspectable summaries." | Bounded recent prose window plus structured summaries for older material | Honours the intent. The window is bounded and the summaries are inspectable; only the most recent entries cross as prose. |
| Grounded / Balanced / Immersive as user-chosen modes | **Balanced becomes an automatic mode** — Grounded between local sunrise and sunset, Immersive after. Grounded and Immersive remain as always-on overrides. | The product owner's own refinement. Consistent with the brief: the modes still differ only in "tone, framing, symbolism, and visible depth," and the underlying health reasoning is unchanged. |

Two further points from this brief that the plan **adopts and should not lose**:

- *"Minimalism must not make important features difficult to discover. Essential functions
  should not depend entirely on hidden gestures."* The Journal and Dashboard sit on a
  horizontal pager. A swipe alone is not sufficient — both destinations need a persistent
  visible affordance.
- *"First design objective."* Phase 1 of the plan should be scoped as exactly the
  prototype described above: atmospheric main screen, progressively forming advice with
  immediate reveal and reduced-motion support, one health feature opening as an extension
  and closing back to the advice, mock content where needed. Prove the defining
  interaction before building the surrounding application.

---

## UI brief

You are building the surfaces of Eter. The foundation beneath them exists: the
design system, the register, the symbolic engine, the content layer and the
database are done, tested, and described below.

**The steering brief above is the product authority** and it overrides this
document wherever they disagree. This brief
tells you what to build and what you have to build it with; that one tells you
what the product *is*.

Then read the UI direction, which follows this. It translates both briefs into
a compositional system, interaction-state checklist and three concept plates.
The plates are mood and hierarchy studies, not screenshots to trace.

---

### 1. The one-paragraph version

Eter is a private AI companion. You write or dictate into a **Journal**; a
**Dashboard** carries the day's guidance, a health widget and your astrogram.
Aether is the intelligence that reads them together. The surface shows a few
carefully chosen sentences and almost nothing else; everything detailed is one
deliberate tap beneath it. The application should feel like *one quiet
continuous space*, not a set of tools.

---

### 2. Non-negotiables

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

### 3. The register — read this carefully, it drives everything

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

#### The ceiling model

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

### 4. What you have to build with

All ported, all working. Do not rebuild these; do not reach for Material
equivalents.

#### `core/tokens.dart`
- `EterColors` — day sky (`mist0`, `mist50`, `sky100`–`sky500`), ink
  (`ink900/600/400`), gold (`aura200`–`aura700`, `gild`), night
  (`night900/800/700`, `nightText/2/3`), semantic (`success`, `warn`, `danger`),
  element accents with contrast-safe `*Deep` variants for day surfaces.
- `EterMotion` — `easeAir` is the house curve. Durations: `durMicro` 180,
  `durStandard` 320, `durEmphasis` 600, `durReveal` 900, `durSentence` 1200,
  `listStagger` 40.
- `EterSpace` — 4/8/12/16/24/32/48/64, `gutter` 24.

#### `core/controls.dart`
`EterInk` (the one place colours resolve — use it), `EterAction`
(primary/secondary/quiet; emphasis changes the *rule*, not a fill),
`EterOptionChip`, `EterToggle`, `EterSlider`, `EterRule`. Minimum target 52 px.

#### `core/widgets.dart`
`EterPlate` (flat, sharp-edged, hairline top rule — the surface primitive),
`ElementMedallion`, `AuraRing`, `CountUpText`, `StarOrnament` (the eight-pointed
signature mark), `OrnamentDivider`.

`EmptyStateOrnament` was here and is gone: nothing ever constructed it, and it was
the only consumer of three shipped PNGs. Every empty state Eter ships states its
absence in words, which this brief prefers anyway — *say what you cannot see*.

#### `core/instruments.dart`
`EngravedBalance` — a real beam balance with an elastic settle. This is the
idiom for **every** chart you build. See §7.

#### `core/theme.dart`
`EterTheme.day()` / `EterTheme.night()`. `SkyBackground` is the shared plate
(static WebP under an optional night video, 3% oversample panned over 180 s).
`EterPageTransitionsBuilder` is the "gust" — fade plus 2.5% slide on `easeAir`.

Typography: **Cormorant Garamond** for display and editorial prose, **Inter**
for text and numerals with tabular figures forced on. Marcellus and Manrope are
gone; do not reintroduce them.

#### `core/arcana/`
`Zodiac`, `MajorArcana` (22 cards, `assetFor(brightness)`,
`nightLoopFor(brightness)`), `ArcanaCardMedia` (static art with an optional loop
composited on top; the still is mandatory and any decode failure silently leaves it
in place), and **`SymbolContent`** — the static keyword layer, see §8.

`AnimatedArcanaCard`, the flip-reveal card, is gone — `EterArcanaPlate` in the
Vessel supersedes it and reaches all 22 night loops through `ArcanaCardMedia`.

---

### 5. The shell

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
- Centre the small `ETER` mark in a shallow celestial engraving. This approved
  astrological flavor is the shell's main ornamental signature. Keep it identical
  on Journal and Dashboard; exclude the engraving from semantics while exposing the
  complete 300×72 mark as an `Open Sanctum` button.
- **The way into the Sanctum is `EterSanctumMark`, centred on the destination
  row.** An astrolabe's mater — two rings, a centre point, one index line — with a
  soft static aura, sitting dead centre between `JOURNAL` and `DASHBOARD`, on the
  same vertical axis as the arc, the wordmark and the plumb above it.

  Chosen over four alternatives on rendered pixels, in both languages. A *word*
  there needs about 90 dp and has to take it from the rail, which pushes the
  destinations off the wordmark's axis; `SANKTUARIUM` is eleven letterspaced caps
  where `SANCTUM` is seven, so Polish decided it. A glyph fits in the ~70 dp the
  two labels already leave between them, so nothing moves and no row is added.

  Two things keep it legitimate. The travelling hairline still belongs only to the
  active destination, so it does not read as a third page. And the tutorial
  **draws the mark** on first run — non-negotiable 7 forbids *unexplained*
  symbols, and that is the explanation. Remove the tutorial passage and this
  affordance becomes a violation.

  The `ETER` mark stays tappable for anyone who learned it, and is now silent to
  assistive technology: it carried `Open Sanctum` while it was the only way in,
  and leaving the label announced the same door twice.

  Earlier placements, all rejected: under the wordmark as a word (read as a
  caption on the ornament), in the top corner (put the settings door in the first
  thing anyone looked at), at the foot of the screen as a `SANCTUM` word (cost a
  row and sat where the keyboard wants to be), and beside the rail (moved the
  destinations off-axis).
- **The Sanctum is also the index.** Anything reached by extension rather than by
  navigation — the Long View, Letters, the Correspondence — carries a named entry
  there too, so no feature exists only behind a gesture. See
  `PRODUCT.md`.
- **The signature is register-dependent** (steering decision, 28 July 2026).
  Day is the sparse register: the wordmark and the lower plumb-and-star
  colophon only — no arc, no solar or lunar mark above the name. Night is the
  elaborate register: the full astrolabe reading — graduated arc, solar and
  lunar marks, an inner declination arc and its tick ring — plus a slow,
  reduced-motion-respecting drift. Geometry, hit region and the composition
  size stay identical across registers so the lockup never moves; only the
  drawn matter changes.
- The Sanctum is an overlay with `PopScope` to intercept system back, not a
  route push.
- State is preserved across page changes. Scroll position, expansion state, a
  half-written journal entry — all survive.

---

### 5a. Where input happens

**The Dashboard reads; the Journal writes** (product rule, 28 July 2026).

Every capture control has been removed from the Body: no add activity, no add
meal, no record strength, no record weight. The Dashboard exists for guidance
and analysis, and it asks the user for nothing.

All input outside the Sanctum happens by writing a Journal page and letting
interpretation derive from it. The Sanctum keeps settings, consents, birth
context and the health connection, because those are configuration rather than
the day's record.

Two consequences, both binding:

- **Do not add a capture control to a reading surface**, however small or
  quiet, and however obviously useful. The rule is the point.
- **Journal classification is the only route into the record**, so its contract
  covers weight, activity and strength as well as food and lifestyle. Done:
  `classification_contract.dart` holds the shapes and `journal/body_commit.dart`
  commits them *through* `ManualWeightService`, `ManualActivityService` and
  `StrengthWorkoutService` rather than around them, so a run written in the Journal
  lands where a run entered by hand lands.

Lifestyle self-reports are not an exception to this and no longer have a
control: mood, energy and sleep are derived from what the page says, like
everything else. Asking for them separately asked twice for the same thing.

The one interaction that survives on a reading surface is correcting a
*derived* food estimate, which is review of something the Journal produced —
and which the brief requires before an estimate may count toward a total.

---

### 6. The Journal

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
  affordance. The implemented affordance is a pair of borderless,
  code-native bead-and-thread page turns beside the date. Both retain 48 dp
  semantic targets. Future pages are disabled, past pages are read-only, and
  leaving today stops dictation and commits any non-empty draft before the
  date changes.
- **Capture is the whole game.** The path from intent to recording should be as
  close to one tap as the platform allows. If your layout adds a step, the
  layout is wrong.

#### The arrival

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

### 7. The Dashboard

Three content sections exist, but they are **not three persistent rows on the
resting screen**. The resting Dashboard shows guidance and one compact,
contextual disclosure. Choosing Body, Vessel or expanded Guidance opens that
section in place (`AnimatedSize`)—never a route push. Only one may be expanded.
Closing it restores the guidance and its scroll state.

#### 7.1 Guidance — top
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

#### 7.2 The Body — health, middle
- **Collapsed:** no permanent metric strip. When Body is the contextual
  disclosure, it may show one short textual fact beside the word `Body`, never
  a multi-metric row or sparkline competing with guidance.
- **Expanded:** full charts, manual activity entry, food editing **including
  per-item correction** (changing one line of an extracted meal from 320 kcal to
  260). Both workflows are now implemented. Manual activity accepts an explicit
  name, duration and active-energy value, then passes through canonical
  minute-level deduplication; it does not present an inferred estimate as fact.
- **Unconfirmed food estimates must be visibly unconfirmed** and must not read
  as fact. The database already excludes them from totals; the UI must not imply
  otherwise.
- Expanded Body also exposes a collapsed `ADD MEAL` path so local nutrition
  does not depend on an AI transport. A named meal and factual kcal value are
  required; protein, carbohydrate and fat are optional. These rows are
  explicitly manual and confirmed, and insertion/correction/deletion refresh
  an existing day-summary intake mirror in the same transaction.
- A matching collapsed `RECORD` path accepts a factual weight in kilograms.
  It appends to history and updates the profile weight used by later energy
  calculations in one local transaction.
- **Say what you cannot see.** A user with no wearable has steps and nothing
  else. State the absence rather than rendering an empty chart that implies
  zero. This is the v1 lesson that mattered most: the old build showed
  "−828 kcal · a lighter balance today" when the user simply had not logged
  food, which in a calorie app is an endorsement the product must never make.
- A successful Apple Health / Health Connect movement import refreshes the
  canonical day summary that this surface watches. The refresh is replay-safe,
  preserves logged intake, and may mark a lower corrected total as
  recalibrated. Resting burn requires profile height; for a legacy profile
  without it, show the available raw signals and request the missing context
  instead of manufacturing a basal number.
- `SurfaceIntent.plain`.

**Charts are `CustomPainter` in the `EngravedBalance` idiom.** No charting
package — importing one imports a visual language this codebase has spent
fourteen commits removing. Engraved hairlines, measure ticks, tabular numerals.
Needed: sleep stages (stacked, 7/30 d), resting HR trend (30/90 d), HRV trend,
activity by time of day (24 buckets), intake vs burn (use `EngravedBalance`),
weight.

#### 7.3 The Vessel — astrogram and life path, bottom
- **Collapsed:** each position, its card, and 3–5 keywords. Exactly the shape
  the product owner specified: `Strength · power, energy, action, courage,
  magnanimity`. All of this is local and offline — see §8.
- **Expanded:** the full interpretation, composed against *this user's* chart.
- **The daily card sits at the top with its reason.** The application chooses
  it, not the model; `DailyCards.reason` holds why, in the app's own words, and
  the user can ask. The brief requires this.
- `SurfaceIntent.ritual`.

---

### 8. Content — two layers, and the split matters

**Static, shipped, offline** — `SymbolContent.load()`, from
`assets/content/*.json`. Keywords, correspondences, domains, reframed subtitles,
for 22 cards, 12 signs, 12 life paths, 12 houses, 13 chart points. This is what
the collapsed Vessel renders and what shows when there is no network. It is
complete and test-enforced.

**Composed per user, cached forever** — the long-form reading. Generated against
the real chart and stored in `VesselReadings`, keyed by `(inputHash,
positionKey)`. Composed once, ever.

The explicit `COMPOSE READINGS` bridge is implemented. It sends only derived
position labels, cards, keywords and reliability flags; raw birth inputs,
identity, location and the local chart hash stay on device. It requests only
missing positions, validates an exact safe response, commits the set
atomically, and never replaces known keywords or cached prose with a spinner.
The deployed live reading transport remains unconfigured.

Birth context is editable later from a collapsed Sanctum section, as
onboarding promises. Exact local time and the historical UTC offset are a
validated pair; place lookup uses the device geocoder and commits the returned
coordinates atomically with the label. Failed lookup changes nothing. Updating
these inputs removes readings belonging to stale chart hashes and refreshes an
already-open Vessel without requiring an app restart.

**What this means for you:** an uncomposed reading is a normal state, not an
error. Show the keywords and say the reading has not been composed yet. Never
show a spinner where a keyword would do, and never show an error for something
that has simply not been asked for yet.

Death and The Devil keep their authentic names; the reframing lives in the
subtitle (`Card of Transformation`, `Card of Ambition`). Do not soften the
names.

---

### 9. Data contracts

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
- The live Aether provider transport.
  The explicit Dashboard compose/refresh trigger, production context assembly,
  provider-independent request/response boundaries, consent gates, PII
  omission, seven-day health/journal bounds, safety validation, atomic
  persistence, correct local-day assignment, production response rendering,
  and unchanged-context caching are implemented. Only the deployed live
  transport remains.
- Vendor-direct integrations and background/differential sync. The phone health
  hub is implemented for an explicit 30-day Apple Health / Health Connect
  read from Sanctum, including native permissions, canonical minute
  deduplication, replay-safe day-summary refresh, staged sleep, daily vitals,
  honest denial/error states, and integration diagnostics.
- The live journal-classification provider. The explicit Journal trigger,
  strict food/lifestyle response contract, current-consent gate, atomic
  application, replay protection, one-question clarification path,
  unconfirmed-estimate behavior and user-visible undo are implemented.
- Profile providers, auth and Firebase wiring. Local onboarding is implemented.

Where you need data that does not exist yet, read the table it will land in and
render fixtures. The schema is stable.

---

### 10. Accessibility

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

Pattern discovery itself is local and explicit. The Aether Memory `REVIEW`
action may retain a
correlation only when its minimum sample and effect thresholds are met. The
receipt exposes the observation count, date window and coefficient, always says
“correlation, not cause,” and a later review must never reactivate something
the user dismissed.

The adjacent Week in View is also local-first. `PREPARE` summarizes the seven
complete days before today using only canonical recorded movement, sleep,
journal-entry counts and self-reported signal counts. It never sends journal
prose, never invents advice, and says that missing days were omitted rather
than treated as zero. Re-preparing the same period updates one cached review.

---

### 11. Testing

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

### 12. Order of work

1. **The reveal, and one surface around it.** Prove the defining interaction
   with mock content. Nothing else matters until this feels right.
2. The shell — pager, visible affordance, Sanctum overlay, state preservation.
3. The Journal.
4. The Dashboard, collapsed only.
5. Expansion, section by section, charts last.
6. Onboarding.

Do not build all three sections before the first one is right.

---

### 13. When something is ambiguous

Use the brief's own principles, in order: reuse before replacing · simplicity at
the surface, depth underneath · health before mysticism when safety is involved
· extension rather than visible division · guidance before dashboards · user
agency before AI authority · deterministic calculation before model
improvisation · local before cloud · structured, inspectable personalization
before opaque memory · accessibility before decorative animation.

If the answer is still unclear, build the quieter option.

---

## Eter UI direction

This document is the visual bridge between the product authority in
the steering brief and the implementation contract in
the UI brief, both above. It gives the UI implementer a compositional north
star. It does not override either brief.

The concept images are **mood and hierarchy studies, not screenshots to trace**.
Generated typography, icons, chart values and spacing are illustrative. The
Flutter tokens, accessibility requirements, real data contracts and existing
art remain authoritative.

Asset commissioning and reuse decisions live in
`ENGINEERING.md`. Read its V2 UI commissioning plan
before generating or importing visual material.

### Product-owner refinement — 27 July 2026

The concept plates established the correct atmosphere, but they contain too
much visible interface. The implementation must be **quieter than the plates**.

- Preserve the custom pale-sky character of the day concept. Treat it as the
  preferred direction for the day background rather than recreating the
  concept's mountains literally.
- Keep the small astrological engraving around the `ETER` name. This is the
  shell's principal decorative signature and should be shared by Journal and
  Dashboard.
- Remove borders and boxes from ordinary actions. Actions should usually be
  compact words or familiar glyphs resting directly on the background.
- A control may look small while retaining an invisible minimum 48×48 dp hit
  region. “Smaller” never means harder to tap or read.
- Make the Journal feel like an actual personal journal, not a form, chat
  composer or bordered text area.
- Show less at once. The resting state should feel intentionally incomplete:
  one voice, one subtle way deeper, and no preview dashboard competing below.

### The visual thesis

Eter is an **editorial sky with a private journal and instruments beneath it**.

The first viewport is closer to the opening page of a beautifully typeset book
than to a wellness dashboard. It offers one thought, one direction and enough
space for the user to hear both. Detail is not removed; it is folded beneath
engraved rules and opened in place.

The system has one skeleton and two atmospheric registers:

- **Day:** the concept plate's pale, softly variegated cloud sky; dark ink;
  generous ivory lift behind text only when contrast needs it; stillness;
  extremely restrained ornament.
- **Night:** the identical hierarchy in midnight navy and warm ivory, with
  antique-gold engraving and slow ambient depth. Ornament grows; density does
  not.

Do not make day the plain product and night the premium-looking product. Both
must feel complete.

### Concept plates

#### Day guidance

![Day guidance concept](concepts/eter-day-guidance.png)

What to keep: guidance owns the viewport; navigation is visible but quiet;
the sky continues behind the whole composition; the pale atmospheric day
background is the preferred replacement direction for the current one.

What not to copy literally: the rendered phone proportions, oversized display
type, mountain placement, bordered action and three simultaneous section rows.
The real resting screen must contain less. Fit real devices from 320–600 dp and
dynamic type to 200%.

#### Night Vessel

![Night Vessel concept](concepts/eter-night-vessel.png)

What to keep: night is luminous ink rather than neon glow; the Arcana card is
the one physical object allowed to feel card-like; symbolic material remains
subordinate to guidance; astrological geometry belongs near the edge and below
content, never between text and reader. The fine solar/lunar engraving around
the Eter name is approved and should become a restrained shared-header motif.

What not to copy literally: the generated card illustration. Use the shipped
Arcana assets and `ArcanaCardMedia`. Do not add ornamental glyphs merely to
fill space.

#### Capture → arrival → extension

![Continuous flow concept](concepts/eter-continuous-flow.png)

What to keep: capture is immediate; the same text-arrival grammar serves
Journal and guidance; an expanded instrument grows directly beneath the
guidance; missing data is stated in words; closing restores the prior
composition and scroll state.

What not to copy literally: the bordered writing box, large boxed Dictate/Save
controls, iconography and exact charts. Use the existing control vocabulary and
build charts in the `EngravedBalance` idiom.

### Composition grammar

Every primary surface should be assembled in this order:

1. **Place** — `SkyBackground` establishes one continuous environment.
2. **Signature** — Eter mark with one shared solar/lunar or astrolabe
   engraving. Keep it fine, shallow and identical across primary surfaces.
   The complete mark is the visible threshold into the Sanctum; its decorative
   paths remain excluded while the hit region announces `Open Sanctum`.
3. **Orientation** — Journal/Dashboard labels and travelling hairline.
4. **Voice** — the dominant guidance or journal writing field.
5. **Threshold** — one quiet text affordance announcing deeper content.
6. **Instrument** — health detail or symbolic object expanded in place.
7. **Return** — an explicit compact close affordance that restores the voice.

This order is also the semantic and focus order. Background ornament is always
excluded from semantics.

#### Density budget

- In the initial Dashboard viewport, allow one primary passage and optionally
  one supporting passage. Do not show metrics, charts, section previews or
  multiple boxed thresholds in the resting state.
- Offer deeper content through one quiet disclosure line at a time. The
  currently relevant doorway may read `Body`, `Vessel` or `More`; the other
  destinations remain discoverable through the same compact disclosure area,
  not three competing rows.
- Only one Dashboard section may be expanded at a time.
- An expanded section begins with its conclusion, then evidence, then controls.
  Never lead with a chart.
- Do not place health and symbolic instruments side by side on phone widths.
- A line, change in spacing or typography should solve containment before
  `EterPlate` is introduced.
- Ornament, navigation, evidence and controls must never all be visually
  assertive at once. If the page feels “designed”, remove something.

#### Vertical rhythm

Use the token scale, with `s24` as the ordinary editorial beat and `s48`/`s64`
around the main voice. Hairlines may touch the viewport edges; readable content
keeps `gutter`. Avoid evenly spaced component stacks—the main passage needs
more air than instruments.

#### Typography roles

- Cormorant Garamond: guidance, journal prompts, composed readings and sparse
  editorial headings.
- Inter: controls, navigation, evidence, timestamps, labels and every number.
- Set numerals tabular. Keep prose line length near 24–34 characters on a
  typical phone.
- Display scale must respond to both width and text scale. The concept plates'
  large type is a mood cue, not a fixed size.
- Letterspaced capitals are for orientation, not paragraphs or warnings.

### The Journal as an object

The Journal is not a health input form with a literary font. It should feel like
opening the same private book each day.

- Retain the atmospheric sky around the page, but give the writing region a
  warmer, quieter parchment field with subtle paper grain and a natural page
  edge or inner margin. No complete rectangular border.
- Use a date-led page: weekday and date act as the entry's heading. Time is a
  quiet marginal annotation, not metadata in a card header.
- The writing field is visually open. No rounded container, outline, fill or
  “message composer” bar. A faint baseline or ruled rhythm is permitted only if
  it remains readable at all text scales and does not resemble a form.
- Existing entries read as continuous dated prose separated by space, a small
  folio mark or a short hairline—not individual cards.
- Place the insertion point where a pen would begin on a page. Tapping the open
  page starts writing immediately.
- Dictation is the page's only persistent action: a small borderless word
  (`DICTATE`, changing to an explicit stop state while listening) with a
  conventional meaning and a 48×48 dp invisible target. Saving is automatic
  and invisible. Do not add Done, Save, checkmarks, completion controls or a
  composer toolbar.
- Date browsing should evoke page movement through typography and transition,
  but must also have explicit previous/next and calendar targets.
- AI inclusion remains a data capability, but it is not edited in the writing
  surface. If exposed later, place it in entry management outside the capture
  flow; never interrupt the page with a toggle or checkmark.
- Night Journal remains `SurfaceIntent.plain`: warm ivory-on-navy or a dark
  paper field, without constellations beneath prose.

### The signature arrival

The reveal should feel like focus arriving across a sentence:

1. Sentence begins slightly displaced (no more than 4 dp), softly blurred and
   low-contrast.
2. Words resolve in short overlapping groups; never reveal character by
   character and never show a cursor.
3. Contrast, blur and displacement settle together on `easeAir`.
4. Pause between sentences, not between every word. The full sentence consumes
   no more than `durSentence`.
5. Any tap in the reveal region resolves the whole passage immediately.
6. With reduced motion, render the final state on the first frame.

Build one reusable widget and test it with both guidance and Journal arrival.
Avoid shader complexity until a simple opacity/blur/translation prototype has
been profiled on a mid-range Android device.

### Interaction states the implementation must design

Each surface needs deliberate states, not just its ideal screenshot:

| Surface | Required states |
|---|---|
| Guidance | arriving, settled, immediately revealed, expanded, stale/cached, offline fallback |
| Journal | empty, composing, dictating, transcription correction, saving, arrived, excluded from Aether |
| Body | partial data, no wearable, stale source, loading local data, unconfirmed meal, corrected meal |
| Vessel | keywords only, composing, composed, daily card revealed, reduced motion |
| Shell | Journal active, Dashboard active, Sanctum overlay, keyboard open, restored state |

Loading should preserve known content. An uncomposed reading is content, not a
spinner. Unknown health data is an explicit absence, not zero.

### Control and icon direction

- Prefer words over novel glyphs for essential actions.
- Use icons only when the symbol is conventional or paired with a label.
- Ordinary actions have **no visible border, surrounding box or fill**. Use
  weight, tone and placement for hierarchy.
- Primary action: a compact text label, optionally accompanied by a short
  underline that belongs to the typography rather than enclosing the control.
- Quiet action: a small word or familiar glyph with a minimum 48×48 dp
  invisible hit region.
- A surrounding rule is reserved for section structure, not used as the four
  sides of a button.
- Toggles are square and mechanical, like a small instrument switch.
- Evidence receipts use a superscript-sized gold reference mark; tapping opens
  a readable square-cornered annotation or the one permitted rounded sheet.
- Do not invent new celestial decoration at feature level. Reuse
  `StarOrnament`, `OrnamentDivider`, commissioned element art and chart
  instrument language.

### Motion hierarchy

Only one motion may ask for attention at a time.

1. Text arrival is primary.
2. In-place expansion is secondary.
3. Night atmosphere is ambient and stops being perceptible when the user reads.
4. Arcana motion occurs only during a deliberate reveal.

Day has no ambient motion. Scrolling must not trigger decorative parallax.
Expansion uses `AnimatedSize` and should preserve the passage's visual anchor.

### Prototype approval gate

Before building the complete Journal or any chart suite, produce one runnable
prototype containing:

- day and night Dashboard guidance;
- the shared arrival widget, tap-to-complete and reduced-motion behavior;
- the refined day background and shared astrological Eter header;
- the persistent Journal/Dashboard affordance;
- an actual-journal capture surface with borderless keyboard/dictation actions;
- one compact, borderless Body disclosure opening one fixture-backed instrument
  in place;
- explicit close and state restoration;
- 320 dp, 390 dp and 600 dp width captures at text scales 1.0 and 2.0.

Approve the prototype on six questions:

1. Does the first glance land on guidance rather than navigation or metrics?
2. Can a new user discover Journal and Body without being taught a gesture?
3. Does night feel deeper without becoming busier?
4. Can every animation disappear without losing meaning?
5. Does the Journal feel like a place to write rather than a data-entry form?
6. Can any visible border or control be removed without harming discovery?

If any answer is no, fix the defining interaction before expanding scope.

#### Gate result — 28 July 2026

All six questions answer **yes** against the committed day/night capture
matrix. Guidance owns the first glance; Journal and Body are explicit text
destinations; night changes depth rather than density; reduced motion removes
animation without removing content; the Journal is an open ruled page with
only typing and dictation; and ordinary actions retain no visible enclosure.

The matrix includes 320×568, 390×844 and 600×960 Dashboard captures at text
scales 1.0 and 2.0 in both registers, Journal in both registers, and one
mid-arrival frame. The 200% review directly found and resolved the Body-row
overflow and decorative-header collision.

### Handoff instruction for Kimi K3

Read in this order:

1. `PRODUCT.md`
2. `PRODUCT.md`
3. this document and its three concept plates
4. `ENGINEERING.md`, especially the V2 UI commissioning plan
5. `core/register.dart`, `core/tokens.dart`, `core/theme.dart`,
   `core/controls.dart`, `core/widgets.dart` and `core/instruments.dart`

Implement the prototype approval gate only. Use fixture data against the real
database contracts. Do not redesign the tokens, add a component library, add a
chart package, or broaden the first pass into all application surfaces. Treat
the product-owner refinement at the top of this document as the final visual
word when a concept plate shows more interface than these instructions allow.

---

## Eter · product decisions

Decisions the product owner has made that the code alone cannot explain, newest
first. Each says what was chosen, what it was chosen *over*, and what it costs —
because the reasoning is the part that gets lost, and a decision whose reasoning
is gone gets relitigated every few months.

This file is not a changelog. It records choices, not work.

---

### 3 August 2026

#### The houses get a band of their own, and numerals

The astrogram was reported as not looking right for a chart whose data and
geometry were both verified correct. Rendering the specimen sheet showed four
faults rather than the one that had been hypothesised:

- The eight ordinary cusps were painted in `faint`, **the same weight as the
  sign ring's twenty-four 10° graduation ticks**. That, not the radial extent,
  is why the houses did not read as houses: they were the twenty-fifth through
  thirty-second tick marks.
- The four angular cusps read as unexplained heavy dashes.
- The cusps shared an annulus with the body glyphs, so collision was structural
  rather than bad luck — a cusp through Saturn on the Reykjavík specimen, and
  through the Sun on the reporting chart.
- Nothing said which house was which.

**Chosen: the houses get an annulus to themselves**, between the aspect circle
and 0.62 of the outer radius, closed by a circle at each edge so it reads as a
band. All twelve cusps run its full width, the angles distinguished by weight;
the ordinary eight move up to `thin` so they can never again be confused with a
graduation. All twelve houses carry a numeral at the middle of the arc they
actually occupy.

Chosen **over** two cheaper options. Fixing only the weights and adding numerals
in the existing band would have left the glyph collisions, which are the part
that reads as a bug rather than as a plain chart. Alternating shaded sectors
would have been the most legible of the three and was refused because this
surface's stated rule is no fill and one colour, and a decision that costs a
rule is more expensive than it looks.

**This is not the attempt that failed.** That one ran the cusps to radius zero
and laid two diameters through the aspect figure.

**What it costs:** the aspect figure gives up its outer fifth, 0.62 → 0.50.
Charts drawn *without* houses — anyone who has not given a birth time — keep the
larger figure, because there is nothing to put in the band and a smaller figure
inside a ring of empty paper would be a cost paid for nothing.

**Numerals over no numerals, and over numbering the angular four only.** An
unnumbered division is precisely the unexplained symbol non-negotiable 7
forbids, and the wheel is the one place a person could otherwise never learn
which house a body is in.

---

### 1 August 2026

#### The Vessel reads the chart, and asks for nothing

The Life Path and the astrogram were two disclosures with a compose button
each. They are now **one menu**, the reading arrives on its own, and there is
no control anywhere that asks for it.

**What changed in the writing.** The call wrote one passage per position —
eighteen on a full chart. Each was correct; none had looked at the chart. The
owner's word was "generalistic", and the cause is structural: a passage that
can only see one placement has nothing to relate it to. It now returns three
to five **movements**, each about how several placements stand to each other,
naming them as evidence rather than as subjects.

**Chosen over** one single passage (eighteen placements compressed into 1800
characters returns to the generic) and over keeping the per-card passages
underneath a synthesis (which is what "rather than treating each card as
individual" ruled out).

**Nothing is composed without a birth time**, approximate or exact. The angles
are most of what makes a configuration particular, and the reading is cached
for the life of the chart — so a chart cast at noon would be read once, wrongly,
and kept. Somebody with no birth time still gets the wheel, the cards and every
computed placement; only the writing waits.

**The cost, and the mitigation.** Composing on save with no button means a save
that fails has nothing to retry it. So the Vessel attempts it silently when
opened if the reading is still missing — the same automatic behaviour, not a
new affordance. Without that, one offline save would leave the reading
permanently unwritten.

#### Guidance leans on the sky at night, and is given something to lean on

In immersive, and in balanced once the sun is down, the symbolic share rises
(to 60% and 40%) and the measured share falls.

**The stated proportions were not the problem.** Immersive already said 40%
symbolic and still read as health reporting. The symbolic half arrived as a
*single sentence* while the measured half arrived as a table — a model cannot
weight what it was not given. So the payload changed with the numbers: today's
Positions passage now travels in full rather than as its one-sentence note. It
was already written and already validated by the Positions call's own safety
policy, so nothing new is composed to carry it.

**Grounded never leans.** That register exists to be plain.

#### The Sanctum orders by frequency

The band at the top holds what people actually change — opening page, language,
register, and the evening invitation — and everything once-ever (birth context,
the consents, export, deletion, connections) sinks below the hairline.

**Chosen over** grouping by consequence, which read better as philosophy but
put the register three screens down, and over collapsible sections, which would
have introduced a disclosure idiom the product uses nowhere else. The evening
invitation moved into the top band *although it is stored as a consent*: it is
the one consent people revisit with the seasons.

**The cost:** the "what leaves this device" story is no longer a single
contiguous block — the invitation sits apart from its siblings. The copy on the
toggle still says what it grants.

#### The guidance depths slide sideways, by tap

`LOOK DEEPER` now opens a persistent row — guidance · body · vessel, each with
a drawn glyph — and the chosen depth slides in horizontally beneath it while
the day's guidance stays put. Switching depths never scrolls you back to the
top, which was the whole complaint.

**Chosen over** the in-place vertical expansion (the "shell game"), and over a
swipeable nested pager: the shell's pager already owns the horizontal *gesture*
for journal ↔ dashboard, so the depths borrow only the horizontal *motion*. A
swipe that meant "next depth" here and "other surface" a centimetre higher
would be one gesture with two meanings.

**The glyphs are placeholders** in the engraved language (a risen point, a
graduated rule, a bowl), drawn so generated artwork can replace the painters
without touching the row. The text label stays beside each mark —
non-negotiable 7 forbids an unexplained symbol, and nothing has taught these
yet.

#### The chart's own writing is not a seventh call

**Superseded the same day on the shape, upheld on the substance** — see "The
Vessel reads the chart" above. It is still one call, still the same composer,
cache and table; what changed is that it answers with movements about the whole
configuration rather than a passage per body, and the separate `THE CHART`
menu is gone. The reasoning below is why it was never a seventh contract, and
that part still holds.

The astrogram explanation behind `THE CHART` composed one passage per
remaining body through the existing `VesselReadingComposer`, into the existing
`VesselReadings` table, under the existing `inputHash`.

**Chosen over** a dedicated `astrogram` call returning one long essay. The
per-position shape means a chart is still paid for **once** — the cache key
already keys on the birth inputs, so re-opening the panel costs nothing and a
reader who composes the named positions today and the planets next week is
billed for exactly the passages they asked for. A single essay would also have
been a seventh contract to parse, version and safety-check.

**The cost:** seven passages read as seven passages, not as one account of a
chart. If that turns out to be the wrong register, the fix is prompt work
inside the same call rather than a new one.

#### Birth-place suggestions answer in the geocoder's tongue

The autocomplete asks the device geocoder once, in the device locale, and shows
whatever spelling comes back; either "Warsaw" or "Warszawa" is accepted as
typed.

**Chosen over** resolving in both app languages and merging, which would have
cost two lookups per debounced keystroke to translate a name the person did not
type. The cost: a Polish interface can show an English suggestion on an
English-locale phone. The typed text still resolves on save either way, so the
suggestion list is a convenience, never a gate.

---

### 30 July 2026

#### Navigation: extension, not a menu

New material extends something that already exists rather than becoming a
destination. The Long View is the Journal's date axis pulled back — day, week,
month, year, through the page-turn affordance the Journal already owns. The Letter
arrives *as* a Journal page. The Correspondence is one extra line beneath today's
guidance, not a screen.

**Chosen over** a hamburger drawer, which was the obvious answer and the wrong
one: it would have been a fourth navigation idiom in a product that has kept to
one, and a drawer listing features frames them as separate applications — the
exact thing `PRODUCT.md` says Eter must never feel like.

**The cost, and the mitigation.** Extension is discoverable only if you already
use the thing being extended. So the Sanctum additionally carries named entries
for Long View, Letters and Correspondence — the one place that names everything,
satisfying `PRODUCT.md` non-negotiable 7 without putting a menu at the front of
the app. Practices, when they arrive, open from the guidance sentence that
recommends them rather than from a list.

**Note on a stale brief.** `PRODUCT.md` §5 said the ETER mark *is* the Sanctum
button, and an audit pass repeated that as a defect. It is not: the shell has had
a named `SANCTUM` word at the foot of the screen for some time, and the mark is
ornament that stays tappable for anyone who learned it. The brief was behind the
code. Corrected there.

#### Pricing: $5/month, said plainly to be a launch price

30-day free trial, then **$4.99/month or $39.99/year**, and **20 PLN/month in
Poland** — set as a regional price, not a conversion, which would have been about
36. Polish is one of Eter's two languages and its cheapest acquisition market, and
Polish subscription apps land at 19–29; pricing it at the dollar conversion would
discard the one distribution advantage Eter starts with.

The paywall says in words that $5 is a launch price and will rise.
**No grandfathering** — early subscribers move to the new price rather than
keeping the old one forever.

**Trial length was 14 days and is 30, and the code decided that.** Eter's
differentiator is a learned pattern about your own body, and
`statistics.dart`'s `minimumPairs = 21` means the first one cannot exist before day
21. The recall window that lets guidance say "the third short night this week"
only fills at day 14. A 14-day trial therefore ended one week before the product
became the thing it is sold as, and asked for money on a promise. Thirty days
crosses day 21, so the decision to pay is made by someone who has read a true
sentence about themselves.

**Counted from first launch, stored locally. No clock defence** — moving the
device clock to extend a trial is accepted as a fringe case not worth engineering
against. The commoner hole is a reinstall, which resets a local trial; both stores
track introductory-offer eligibility per account, so the store's own mechanism is
the real per-person gate once billing lands.

**One thing is not fully in our hands:** Apple requires existing subscribers to
actively consent to a price increase above certain thresholds, or the subscription
lapses. So some early users will effectively grandfather themselves by ignoring
the prompt, and others will churn at the raise. Saying "launch price" up front is
what makes that honest rather than a surprise.

**Free stays genuinely good.** Journal, dictation, the local health record, the
Body charts, the deterministic Vessel and export all work with no network and no
model. Gate the intelligence, never the record — for a privacy-positioned product
that is how the right to charge is earned.

#### BLE straps arrive with breathwork, not before

The schema (`LiveSessions`, `RememberedSensors`) stays, empty, rather than being
deleted as dead weight.

**Why it is not redundant**, which was the question: Health Connect and HealthKit
give you *recorded* data and a pre-computed overnight HRV. A BLE strap gives a
live stream and **raw RR intervals** — beat-to-beat timing. Coherent breathing at
about six breaths a minute raises HRV measurably within 60–90 seconds, and you can
only *show* someone that with RR intervals as they happen. That is the difference
between "we logged eight minutes" and "here is what those eight minutes did to
you", and it is the whole reason breathwork would be more than a timer.

`LiveSessions.hrSeriesJson` is already the right shape for that series and
`RememberedSensors` for "your strap", so deleting them would mean re-adding them.

#### On-device interpretation: dropped

Running `journalInterpretation` locally on Gemini Nano or Apple Foundation Models
was proposed as the strongest privacy position available — "your journal never
leaves this phone" *and* working intelligence.

**Dropped in favour of a self-hosted model later.** If Eter launches, the owner
intends to run a model that can be trained to give better guidance, which is a
different and larger bet than shrinking one call onto the handset.

#### Eter may speak first, once

One quiet local notification in the evening, inviting a page. **Off by default.**
Nothing else: no morning reading, no streak nudge, no re-engagement.

This closes an open question that `archive/ROADMAP.md` §2.4 and
`archive/RELEASE_PLAN.md` §3 both left undecided. Worth scheduling on the real
sunset the register already computes rather than a clock time, so the invitation
arrives with the night register instead of arbitrarily.

#### Descoped for now

Vendor integrations (Garmin, Polar, Fitbit, Oura) and Sign in with Apple — the
latter blocked on a paid Apple membership in any case. `archive/11-wearable-integrations.md`
holds the per-vendor research, including that the Garmin Health API needs
developer-program approval that takes weeks, which is the reason to start it early
whenever it starts.

Also not built: "Why did Aether suggest this?", and meditation/breathwork
*guidance* as opposed to logging.
