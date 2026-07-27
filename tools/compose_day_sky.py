"""Compose the Day Sky plate: graded gradient + real cumulus + grain.

The v4 grade fixed the colour of day but not its character. A perfectly smooth
vertical ramp is the most generic background there is — no light direction, no
texture, and 8-bit banding across the large flat area. This composites real
photographic cloud (taken from the onboarding plate, which is an actual sky
photograph) low and to one side so the frame has an asymmetric light source,
then dithers the whole thing so no band survives.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import cv2
import numpy as np


def feathered_cloud(
    source: Path,
    crop: tuple[int, int, int, int],
    size: tuple[int, int],
) -> tuple[np.ndarray, np.ndarray]:
    """Return a cloud tile and the alpha that dissolves it into open sky.

    The alpha is derived from the cloud's own luminance, so the wisps fade out
    where they are already thin rather than along a rectangular edge.
    """
    image = cv2.imread(str(source), cv2.IMREAD_COLOR)
    if image is None:
        raise SystemExit(f"cannot read {source}")
    x0, y0, x1, y1 = crop
    tile = image[y0:y1, x0:x1]
    tile = cv2.resize(tile, size, interpolation=cv2.INTER_CUBIC)

    luma = cv2.cvtColor(tile, cv2.COLOR_BGR2GRAY).astype(np.float32)
    # Cloud is the bright part; open sky behind it is darker and bluer.
    alpha = np.clip((luma - 178.0) / 62.0, 0.0, 1.0)
    alpha = cv2.GaussianBlur(alpha, (0, 0), 9)
    return tile.astype(np.float32), alpha


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path, help="graded day gradient (v4)")
    parser.add_argument("clouds", type=Path, help="plate holding real cumulus")
    parser.add_argument("output", type=Path)
    parser.add_argument("--cloud-opacity", type=float, default=0.62)
    parser.add_argument("--cloud-top", type=float, default=0.58,
                        help="where the cloud band begins, fraction of height")
    parser.add_argument("--grain", type=float, default=2.6,
                        help="grain sigma in grey levels; 0 disables")
    args = parser.parse_args()

    base = cv2.imread(str(args.base), cv2.IMREAD_COLOR)
    if base is None:
        raise SystemExit(f"cannot read {args.base}")
    out = base.astype(np.float32)
    height, width = out.shape[:2]

    band_top = int(height * args.cloud_top)
    band_height = height - band_top
    tile, alpha = feathered_cloud(
        args.clouds,
        # A clean stretch of cumulus from the onboarding plate, clear of its
        # gold frame and corner ornament.
        crop=(700, 2000, 1460, 2500),
        size=(width, band_height),
    )

    # Fade the band out at its top edge so cloud emerges from haze rather than
    # starting at a horizontal line.
    ramp = np.clip(np.linspace(0.0, 1.0, band_height) * 2.2, 0.0, 1.0)
    alpha = alpha * ramp[:, None] * args.cloud_opacity

    region = out[band_top:, :, :]
    # Straight alpha over, not screen. Screening cloud onto the warm lower
    # haze drove both toward white and the cumulus disappeared entirely; the
    # band has to sit against sky that is still blue enough to read against.
    out[band_top:, :, :] = region * (1 - alpha[..., None]) + tile * alpha[..., None]

    if args.grain > 0:
        # Per-channel noise, not luminance noise: matched noise across channels
        # reads as dirt, while independent noise reads as film and, crucially,
        # dithers away the banding in the flat upper sky.
        rng = np.random.default_rng(0xE7E4)
        out += rng.normal(0.0, args.grain, out.shape).astype(np.float32)

    cv2.imwrite(str(args.output), np.clip(out, 0, 255).astype(np.uint8))
    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
