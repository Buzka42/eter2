# Eter — Codex Steering Brief

> **Provenance.** This is a faithful transcription of an 11-page PDF authored by the
> product owner, previously existing only as rendered page images in the gitignored
> `tmp/pdfs/steering-brief/` directory on a single machine. It is the authoritative
> product direction and supersedes the product framing in `README.md` and the archived
> specification set. Transcribed 27 July 2026 so that it survives a fresh clone.
>
> An editorial note recording where the approved v2 rebuild plan knowingly diverges from
> this brief appears at the end, clearly separated from the brief's own text.

---

## Product direction

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

## Core concept

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

## Eter and Aether

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

## Main experience

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

## Continuous interface

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

## Visual direction

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

## Guidance styles

Allow users to control how strongly the mystical layer appears.

Use three broad modes:

### Grounded

Primarily practical health and behavioral guidance.

Astrology, numerology, and Arcana remain subtle or hidden.

### Balanced

Health information and symbolic interpretation are both visible.

### Immersive

Astrology, numerology, Arcana, and contemplative language have a stronger presence.

These should not be three separate products or recommendation systems.

The underlying health reasoning and safety rules should remain consistent. The main
differences should be tone, framing, symbolism, and visible depth.

---

## Health and symbolic information

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

## Arcana

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

## AI direction

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

## AI food tracking

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

## Personalization and memory

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

## Privacy and safety

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

## Free and premium direction

Use one application with feature entitlements rather than two applications.

A possible product structure is:

### Core experience

- health tracking;
- basic nutrition;
- weight and activity;
- basic daily guidance;
- Grounded mode;
- local records;
- limited AI food assistance.

### Expanded experience

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

## Rebuild approach

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

## First design objective

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

## Decision-making principles

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

## Desired result

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

# Editorial note — where the v2 plan diverges

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
