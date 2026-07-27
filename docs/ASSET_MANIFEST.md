# Eter · Asset Manifest

## V2 UI commissioning plan

This section is the asset authority for the Kimi K3 UI handoff. The historical
generation record below documents the earlier art set; it is not a requirement
to regenerate that set.

The concept plates in `docs/concepts/` are reference images only. Never crop UI
elements out of them or ship them as application backgrounds.

### Priority 0 — needed for the defining prototype

#### 1. Refined day environment

**Status:** two options generated. Option A passed the complete responsive and
dynamic-type capture gate and is integrated as
`app/assets/art/bg-air-day-v6.webp`; option B is retained under
`assets/review/` for product-owner comparison. The existing
`bg-air-light-v5.webp` is superseded.

**Deliverables:**

- `bg-air-day-v6-master.png` — 2160×3840 master, 9:16.
- `bg-air-day-v6.webp` — production derivative, target 500–900 KB.
- Optional tablet crop only after the phone composition is approved; do not
  generate several speculative aspect ratios.

**Art direction:**

> A quiet vertical atmospheric background for a minimalist editorial wellbeing
> app. Pale powder-blue sky dissolving into warm ivory and parchment mist;
> layered soft clouds with natural tonal variation and very faint paper-like
> texture; contemplative, intelligent and timeless; diffused daylight; almost
> abstract. Keep the centre 65% calm and low-contrast for dark editorial text.
> Slightly more cloud structure near the lower edge and extreme corners, never
> forming a landscape subject. No mountains, horizon, figures, architecture,
> text, symbols, stars, astrology, gold decoration, interface elements, frames,
> borders, gradients that look synthetic, watermark or vignette.

**Composition constraints:**

- Text-safe centre from roughly 15–80% of image height.
- No important feature within device-notch or home-indicator regions.
- Worst-case text area must support `ink900`; the UI may add its existing ivory
  legibility lift, but the art must not force a large opaque panel.
- Still image only. Day has no ambient motion.
- Test with `BoxFit.cover` at 320×568, 390×844, 430×932 and 600×960 dp before
  approval. The crop must not turn a cloud edge into a visual divider.

#### 2. ETER celestial header engraving

**Status:** two concept families generated under `assets/review/`. The quieter
colophon family (option B) is provisionally implemented with `CustomPainter`;
the concept bitmaps are not runtime assets.

**Deliverable:** one shallow, symmetrical path composition around the wordmark,
approximately 300×56 logical units, authored as SVG paths or reproducible
Flutter paths. The `ETER` text itself remains live typography and is not part of
the asset.

**Motif:** a restrained solar mark on one side, lunar mark on the other, joined
by one fine orbital arc with at most one eight-point star at its centre. It
should feel like an astronomical instrument engraving, not a horoscope banner.

**Rules:**

- One-color paths; tint from `EterInk`/register in code.
- 1–1.25 dp apparent stroke at normal phone width.
- No zodiac glyph row, constellation field, labels, fill, glow or animation.
- Decorative semantics only.
- Identical geometry on Journal and Dashboard.

This is the one approved astrological flavor at the top of the resting surface.
Do not add more header decoration to compensate for empty space.

### Reuse — no new commission

#### Journal paper character

Reuse `grain-subtle.webp` as a low-opacity repeat/cover texture over a
code-defined warm parchment field. The existing file is sufficiently neutral.
Page margin, date heading, baselines, folio marks and page transitions are UI,
not raster art.

Do not generate a photographed notebook, page with baked-in lines, page curl,
spiral binding, leather cover, handwriting or fixed shadows. Those would fight
dynamic type, localization and the continuous sky.

#### Night environment and Arcana

Reuse `bg-air-dark-v3.webp`, the existing optional night loop, and the shipped
light/dark Arcana set. The night concept does not authorize a replacement tarot
deck or a busier celestial background.

#### Controls, rules and instruments

The following must remain code-native: Journal/Dashboard hairline, disclosure
chevrons, microphone and calendar icons, evidence marks, section rules, sleep
and vital charts, `EngravedBalance`, toggles, focus states and all text. Raster
versions will blur, fail theming and break accessibility.

### Priority 1 — commission only when the implementing state exists

- A single Journal empty-state folio ornament, only if the empty page still
  needs orientation after its real layout and prompt are working.
- No separate Sanctum threshold engraving. The approved code-native ETER
  header is the threshold; the overlay itself is deliberately unornamented.
- New onboarding art, only if the existing onboarding hero cannot be cropped
  into the refined day register.

These are not prototype blockers. Kimi should first attempt the surface with
existing assets and request them with a screenshot showing the exact negative
space they must occupy.

### Asset acceptance gate

Before bundling commissioned art:

1. Show it underneath real day/night text at text scales 1.0 and 2.0.
2. Show all required phone crops and one 600 dp layout.
3. Verify the screen still reads correctly with the decoration removed.
4. Verify no essential information is baked into pixels.
5. Compress a derivative; retain the master outside the runtime bundle.
6. Record filename, dimensions, generator/model, prompt and source/job ID here.

If an asset does not survive these checks, it is not ready for the application.

---

Generated with Higgsfield (`nano_banana_pro` / nano_banana_2, 2K). All assets share one style string — reuse it verbatim for every new asset so the set stays coherent:

> **Eter style string:** "ethereal light-and-airy aesthetic, pale powder-blue and warm-white palette, delicate gold celestial line art, soft volumetric clouds, dreamy diffused light, premium minimal tarot engraving flavor, high detail"

| File | Size | Use in app | Prep needed before bundling |
|---|---|---|---|
| `app-icon.png` | 2048² | App icon source (iOS AppIcon set / Android adaptive foreground) | Crop to the inner rounded square; export icon sizes; for Android adaptive, separate cloud (foreground) from gradient (background) |
| `bg-onboarding.png` | 1536×2752 | Onboarding + Arcana reveal background (05) | Compress to WebP ~500 KB; keep center negative space clear of UI |
| `cloud-hero.png` | 2048² | Source for Cloud shader-fallback layers (04 §1) | Use the cutout below; derive 3 opacity/scale variants `cloud-hero-{1,2,3}.png` |
| `cloud-hero-cutout.png` | 2048² | Transparent-background cloud (fallback layers, empty states, watch tile art) | Ready to use |
| `tarot-card-back.png` | 1696×2528 | Card back for Arcana reveal (04 §4), placeholder for unshipped sign cards | Crop to card edges (remove outer margin), round corners 4% in-app |
| `tarot-the-star.png` | 1696×2528 | Aquarius Arcana card art (05) + style template for the other 11 | **Crop to card edges** (it rendered as a mockup on a gray backdrop); round corners in-app |
| `sigil-loading.png` | 2048² | Reference for the animated loading sigil (04 §5) | Trace to SVG paths for the stroke-draw animation; PNG itself only as static fallback |

## Regenerating / extending the set

Model: `nano_banana_pro`, resolution `2k`. Aspect: cards 2:3, backgrounds 9:16, icons/squares 1:1.

**Remaining 11 Arcana cards** — use this template, swapping the scene per card (keep everything after the scene identical):

> "Tarot card '{CARD NAME}' ({NUMERAL}) reimagined in an ethereal light-and-airy style: {SCENE}, pale powder-blue and warm-white palette with delicate gold line art, thin double gold border frame, caption text at the bottom in elegant gold serif capitals: {CARD NAME UPPER} · {NUMERAL}, dreamy diffused light, premium minimal tarot engraving flavor, high detail"

Scene suggestions per card: Emperor — enthroned figure on a cliff of cumulus, gold ram-horn armrests; Hierophant — robed figure between two cloud pillars, twin keys of light; Lovers — two figures beneath a sun-crowned angel of mist; Chariot — charioteer drawn by two wind-horses of cloud; Strength — woman gently closing a golden lion's mouth, both wreathed in mist; Hermit — cloaked figure on a cloud peak holding a lantern with a gold star inside; Justice — seated figure with upright sword and glowing scales; Death — white rose held by a serene armored figure, dawn breaking through clouds (keep gentle); Temperance — winged figure pouring light between two cups, one foot on cloud one in a pool of sky; Devil — chained gold censer smoking beneath a watchful horned silhouette kept distant and small (keep elegant, not dark); Moon — twin towers in mist, a path of light across water, calm crescent above.

**Night Sky variants** (dark mode backgrounds): same prompts + "deep indigo night sky #16203A, gold constellations brighter, moonlit clouds".

Generation record (Higgsfield job ids, 2026-07-12): icon `1c56b36d`, onboarding bg `8e02b1ac`, cloud `9a358166`, card back `a885166c`, star card `1f45a220`, sigil `5078f6f4`, cloud cutout `70f0eb91`.
