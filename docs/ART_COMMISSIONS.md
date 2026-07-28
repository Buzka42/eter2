# Eter · Art commissions for ChatGPT

Working document for commissioning raster art through ChatGPT image
generation. Each brief is self-contained and ready to paste. The asset
authority is [`ASSET_MANIFEST.md`](ASSET_MANIFEST.md); this file tracks what
is being asked for, what comes back, and whether it passed the acceptance
gate. Do not commission anything listed under **Do not commission** — those
surfaces are code-native by decision, and raster versions will blur, fail
theming and break accessibility.

House rules that apply to every brief below:

- The concept plates in `docs/concepts/` are mood references only. Never
  upload them for cropping, never ship them, and do not ask the model to
  reproduce their interface elements, typography or icons.
- Keep the centre of every background calm. Dark editorial text (`#1C2B3A`)
  must sit comfortably on the middle 65% of the frame.
- One asset per conversation turn works better than batches; review each
  against the acceptance gate before deriving anything from it.
- After acceptance: record the file, dimensions, model, prompt and job/chat
  reference in the table at the bottom, and compress a production WebP
  derivative (target 500–900 KB) while keeping the PNG master outside the
  app bundle.

---

## Commission 1 — Refined day sky background (Priority 0, needed now)

**Why:** the defining prototype currently falls back to `bg-air-light-v5.webp`,
which the manifest rates usable but more saturated and visually emptier than
the approved day direction. This is the one asset the prototype gate is
waiting on.

**Deliverables:**

- `bg-air-day-v6-master.png` — 2160×3840 (9:16), full quality.
- `bg-air-day-v6.webp` — production derivative, 500–900 KB, goes in
  `app/assets/art/` and `pubspec.yaml` once accepted.

**Prompt (paste as-is):**

> A quiet vertical atmospheric background for a minimalist editorial
> wellbeing app. Pale powder-blue sky dissolving into warm ivory and
> parchment mist; layered soft clouds with natural tonal variation and a very
> faint paper-like texture; contemplative, intelligent and timeless; diffused
> daylight; almost abstract. Keep the centre 65% of the image calm and
> low-contrast, suitable for dark editorial text. Slightly more cloud
> structure near the lower edge and the extreme corners, never forming a
> landscape subject. No mountains, no horizon line, no figures, no
> architecture, no text, no symbols, no stars, no astrology, no gold
> decoration, no interface elements, no frames, no borders, no synthetic-
> looking gradients, no watermark, no vignette.

**Composition constraints to check on review:**

- Text-safe centre from roughly 15–80% of image height.
- No important feature near the top notch or bottom home-indicator areas.
- Worst-case text area must support dark ink `#1C2B3A`; the app can add a
  light scrim but the art must not force a large opaque panel.
- Still image only — the day register has no ambient motion by design.
- Crop-test at 320×568, 390×844, 430×932 and 600×960 dp (`BoxFit.cover`); a
  cloud edge must not turn into a visual divider behind the guidance text.

---

## Commission 2 — Tablet crop of the day sky (hold)

Only after Commission 1 is approved on phone: ask for a 4:3-friendly
reframing of the same master (or generate at 2400×1800 with identical art
direction). Do not generate speculative aspect ratios before the phone
composition is accepted.

---

## Commission 3 — Journal empty-state folio ornament (hold)

Only if the empty Journal page still feels unanchored once its real layout,
date heading and prompt are working (verifiable in the prototype goldens).
If needed: a single small folio mark — a faint gold-and-ink line engraving of
an open book or quill rest, ~1200×900 transparent PNG, quiet enough to sit
under one line of Cormorant Garamond text. Request it with a screenshot of
the exact negative space it must occupy.

---

## Commission 4 — Arcana card backs, both registers (Priority 0)

**Why:** the shipped backs (`card-back-v2-light/dark.webp`) are the only cards
in the deck that were not authored at the deck's own proportion. They arrived
at 1.70 and were centre-cropped to the canonical 620×920 on 28 July 2026, which
tightened the composition until the gothic arches now run off the top and
bottom edges. They also predate the interface they sit in: the shell's
signature is a graduated arc, a plumb line and a four-point compass star, and
the back's rose-window medallion belongs to a different vocabulary.

They are also the most-seen card in the product. Every Vessel reading that has
not been composed shows a back, and the animated card flips through one on
every reveal.

**Deliverables:**

- `card-back-v3-dark-master.png` — 1240×1840 (exactly 2× the deck), full
  quality.
- `card-back-v3-light-master.png` — 1240×1840.
- Derivatives at 620×920, WebP quality 82, to `app/assets/art/`, replacing the
  v2 pair after the gate passes.

**Prompt — dark register (paste as-is):**

> A tarot card back for a quiet, editorial astrology application. Deep
> midnight-navy ground, almost black at the corners. A single centred
> symmetrical emblem in fine antique-gold line-work: an eight-pointed compass
> star at the centre, held inside two concentric graduated rings struck with
> fine degree ticks like an astronomical instrument, with a slender vertical
> plumb line descending below the star and a shallow arc rising above it. A
> restrained double hairline border inset from the edge on all four sides,
> with generous empty ground between the border and the emblem. Engraved
> hairline quality throughout, one gold tone, no shading, no gradient mesh, no
> glow, no bloom, no metallic sheen, no gemstones, no filigree crowding. It
> must read as an instrument plate rather than an ornate playing card. No
> zodiac symbols, no planetary glyphs, no constellation map, no eye, no moon
> phases, no sun face, no figures, no animals, no text, no numerals, no
> watermark, no signature. Perfectly vertically and horizontally symmetrical.

**Prompt — light register:** the same, with one substitution:

> …warm parchment ground with a very faint paper grain instead of midnight
> navy, and antique-gold line-work deep enough to hold against it (a darker,
> browner gold rather than a pale one).

**Composition constraints to check on review:**

- **Author at 620×920 proportion (1.4839).** Do not deliver a taller card and
  crop it; the crop is what broke the current pair.
- The emblem occupies the central 55–65% of the height. Nothing important
  within 6% of any edge — the app draws the card with a 12 dp corner radius,
  which eats the corners.
- The two registers must be the **same drawing**, not two designs. Placed side
  by side they should differ only in ground and ink.
- Symmetrical on both axes, so a flip animation has no preferred orientation.
- Must hold at 92 dp (a position thumbnail) and at 340 dp (the Sun card's
  width). Check both: an emblem that dissolves at 92 dp fails.
- The dark back is composited under `animations/card-back-dark.mp4`; the loop's
  motion sits on top of the still, so the still must be legible on its own and
  the emblem must not sit where the loop's brightest movement is.
- No text of any kind. The deck's faces carry their titles; the back does not.

**Once accepted:** run `python tool/normalise_cards.py`, which will confirm both
files are already 620×920 and leave them untouched if they are. Then re-record
the golden and inventory captures.

---

## Later (not yet, states do not exist)

- **Sanctum threshold engraving** — no longer needed. The code-native ETER
  header is the visible threshold and the plain overlay needs no ornament.
- **Onboarding hero** — only if `onboarding-hero.webp` cannot be cropped into
  the refined day register.
- **The remaining 11 Arcana cards** — these belong to the Higgsfield
  `nano_banana_pro` pipeline with the template recorded in
  `ASSET_MANIFEST.md`; commissioning them through a different generator would
  break the deck's coherence. Keep them there.

## Do not commission

- The ETER celestial header — already implemented as `CustomPainter`
  (one-colour paths tinted by register, per the manifest's own instruction).
- Controls, rules, chevrons, microphone/calendar icons, evidence marks,
  charts, the beam balance, toggles, focus states, all text. This includes the
  shipped 7/30-day sleep-stage and 24-hour activity instruments: both are
  accessible code-native engravings and require no raster or animation asset.
- Journal paper — a code-defined parchment field plus the existing
  `grain-subtle.webp` at low opacity.
- Night sky, night loops, card art, card backs — the shipped set is reused
  as-is; the night concept plate does not authorize replacements.
- Anything with baked-in text, lines on the journal page, page curls,
  bindings, leather covers, handwriting or fixed shadows.

---

## Acceptance gate (run for every returned asset)

1. Show it underneath real day/night text at text scales 1.0 and 2.0.
2. Show all required phone crops and one 600 dp layout.
3. Verify the screen still reads correctly with the decoration removed.
4. Verify no essential information is baked into pixels.
5. Compress a derivative; retain the master outside the runtime bundle.
6. Record it below.

## Commission log

| File | Dimensions | Generator/model | Prompt | Source/job | Status |
|---|---|---|---|---|---|
| `assets/masters/bg-air-day-v6-master.png` | 2160×3840 | ChatGPT built-in image generation | Commission 1 above | `call_XkgiCKmNuX8kHHd4D41zlQpS` | **accepted and integrated as option A**; passed 320/390/600 dp × 1×/2× text gate |
| `assets/review/bg-air-day-option-b-master.png` | 2160×3840 | ChatGPT built-in image generation | Warm parchment-dominant watercolor alternative | `call_xTh5s5BjEIZprlpTlXsnIaMc` | review option B |
| `assets/review/eter-header-option-a-astrolabe.png` | 2048×819 concept | ChatGPT built-in image generation | Detailed astronomical-instrument lockup | `call_Kn0xNG8XGEauKAa0ypA0VL7y` | review option A; do not ship bitmap |
| `assets/review/eter-header-option-b-colophon.png` | 1776×887 concept | ChatGPT built-in image generation | Sparse celestial editorial seal | `call_TVNaGkbBnXX9I8cOlZcs5F06` | **provisional code-native direction** |

The two header images are design studies. The runtime implementation remains
live Cormorant type and `CustomPainter` paths. Option B is provisionally
implemented because it preserves the product's minimalism; the owner can select
either family without replacing a raster asset.

No motion asset is commissioned for this gate. The signature text arrival,
section expansion and night drift are code-native, accessibility-aware motion.
If a later Sanctum or Arcana state needs authored animation, add a Higgsfield
brief here only after the exact still composition and reduced-motion fallback
exist; commission at least two variants from that locked frame.

The manual Body activity entry added on 28 July 2026 intentionally requests no
authored asset. It is a plain factual passage using the existing typographic
actions and hairline fields; decoration would compete with the values being
entered. Because no asset was generated, the two-option review gate is not
triggered.

The Journal interpretation, clarification and undo passage added on 28 July
2026 also remains code-native. It extends the ruled page with marginal
typographic actions and one ordinary answer line; adding an AI badge, sparkle
or animated oracle would overstate model authority and violate the journal
direction. No generated asset exists, so no two-option review is required.

The Dashboard compose/refresh bridge added on 28 July 2026 uses the existing
typographic action system and the signature text arrival. No loading oracle,
AI emblem or ambient animation was commissioned: known guidance stays visible
during refresh, and a live text status carries the state. No asset was
generated, so the two-option gate does not apply.

The Vessel `COMPOSE READINGS` state added on 28 July 2026 reuses the shipped
Arcana imagery, offline keywords and typographic actions. Composition is a
content transition, not a new visual event; cached material remains visible
and a live text status carries progress or failure. No animation or generated
asset was added, so no two-option review is triggered.

The local pattern-review milestone also adds no raster commission. Evidence is
deliberately typographic and inspectable; illustrating a correlation would
give weak local statistics more authority than the product intends. No
two-option asset decision is triggered by this slice.

The local Week in View is likewise editorial text, not an illustration or
animated event. Its value is factual continuity across recorded days; adding a
hero image would make the quiet Sanctum denser and imply a model-authored
reading. No asset was generated, so the two-option gate does not apply.

Journal history uses a code-native bead, thread and chevron page-turn mark.
This is interface line work, scales cleanly at dynamic type, and belongs to the
existing disclosure family; a raster calendar or page-curl asset would add
chrome the owner explicitly rejected. No generated asset exists, so no
two-option review is required.

The collapsed Birth Context editor is ordinary Sanctum typography and line
fields. It needs accuracy and clear failure copy, not a map, globe, or zodiac
asset; those would add density without helping users enter time, offset, and
place. No generated asset exists, so no two-option review is required.

Manual meal capture uses the same hidden-until-requested typographic passage
as manual activity. Food photography, ingredient icons, or a scan animation
would make expanded Body busier and falsely imply capabilities not present in
the factual entry path. No generated asset exists, so no two-option review is
required.

Manual weight capture is likewise an ordinary factual line. A scale icon,
body silhouette or progress animation would turn a neutral measurement into
judgment and add density without information. It remains code-native, so no
two-option review is required.
