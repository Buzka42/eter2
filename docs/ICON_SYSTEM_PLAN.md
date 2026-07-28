# Eter custom icon system — commissioning and integration plan

Status: code-native disclosure mark integrated; broader set remains optional
Prepared: 25 July 2026

## 1. Goal

Replace the remaining Material iconography with a bespoke thin-line set that
matches the tarot line-work of the Arcana masters: 1 px optical stroke,
geometric-mystical vocabulary (circles, rays, crescents, threads), quiet
enough for an ultra-minimal interface.

The two production disclosure chevrons no longer use Material icons. They now
share `EterDisclosureMark`, a code-native bead-and-thread painter in
`app/lib/core/icons.dart`. This resolves the only currently visible generic
glyphs without introducing an asset dependency. The larger 24-glyph set below
remains a commissioning menu for future surfaces, not a blocker or a reason to
add icons where words already work.

## 2. The set (24 glyphs)

Navigation and instruments:

| Slot | Glyph | Concept |
|---|---|---|
| `ic-aether` | Nine-pointed star in a circle | The guidance surface |
| `ic-ledger` | Open book with a single thread line | Log |
| `ic-pulse` | Heart outline with one ECG thread | Live |
| `ic-balance` | Two pans on a hairline beam | Balance |
| `ic-timeline` | Vertical thread with three beads | Timeline |
| `ic-sanctum` | Archway with a keystone star | Settings |

Domain glyphs:

| Slot | Glyph | Concept |
|---|---|---|
| `ic-meal` | Chalice with steam curl | Food entry |
| `ic-steps` | Two overlapping footprint arcs | Steps |
| `ic-flame` | Single-line flame | Active energy |
| `ic-moon` | Crescent with one star | Sleep |
| `ic-drop` | Water drop with inner ripple | Hydration |
| `ic-weight` | Plumb line over a horizon | Weight |
| `ic-strength` | Column with capital | Strength training |
| `ic-breath` | Three concentric arcs | Breathwork |

Elemental set (used wherever the zodiac element is surfaced):

| Slot | Glyph | Concept |
|---|---|---|
| `ic-elem-air` | Three ascending wind lines | Air |
| `ic-elem-fire` | Triangle with inner flame line | Fire |
| `ic-elem-water` | Two nested wave threads | Water |
| `ic-elem-earth` | Horizon with seedling arc | Earth |

State glyphs:

| Slot | Glyph | Concept |
|---|---|---|
| `ic-check` | Single-line check in a thin circle | Confirm |
| `ic-close` | Crossed threads | Dismiss |
| `ic-reveal` | Eye with a star pupil | Reveal moments |
| `ic-descend` | Downward thread with chevron | Scroll hint |

## 3. Generation brief (paste-ready for the image model)

Generate each glyph individually with this prompt skeleton:

> Minimalist line icon of {concept}, single continuous 1 px stroke, elegant
> geometric style inspired by art nouveau tarot engravings and astronomical
> charts, perfectly centered on a pure white background, no shading, no
> fill, no text, symmetrical balance, generous whitespace, stroke color
> #1C2B3A, vector-like precision, 1024x1024.

Rules for every glyph: one stroke weight, no gradients, no shadows, no
background texture, glyph occupies the central 60% of the canvas.

## 4. Post-processing pipeline

1. Upscale/crop to 1024x1024, threshold to pure black on white.
2. Trace to SVG (potrace or vectorizer.ai), simplify paths (< 60 nodes).
3. Normalize: 24x24 viewBox, stroke 1.5, round caps, currentColor.
4. Convert to a Dart `IconData` font via `fluttericon.com` or ship as SVG
   assets rendered through `flutter_svg` (add dependency at integration).
5. Deliverables land in `app/assets/icons/` with a manifest mapping slot
   names to files.

## 5. Integration

- Replace `IconData` usages in `shell.dart` (instrument index) and feature
  screens with the new set through a single `EterIcons` registry
  (`app/lib/core/icons.dart`), so future glyph swaps touch one file.
- Active state: gold (`aura500`); idle: `ink600`/`nightText2`; element
  glyphs additionally tinted by `elementProvider`.
- Golden-test the registry: every glyph renders at 20, 24, 32 px in both
  themes without overflow.

## 6. Acceptance

- No Material icons remain on the guidance surface or instrument index.
- Stroke weight is optically consistent across the set at 20 px.
- Reduced-motion and high-contrast text-scale modes keep glyphs legible.
