# Eter · Asset Manifest

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
