from __future__ import annotations

import argparse
from pathlib import Path

import cv2
import numpy as np


def hex_to_bgr(value: str) -> np.ndarray:
    value = value.lstrip("#")
    r, g, b = (int(value[i : i + 2], 16) for i in (0, 2, 4))
    return np.array([b, g, r], dtype=np.float32)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Grade the delivered night master into a Night Sky astrophotography "
            "plate. The master is a real long exposure whose galactic band runs "
            "corner to corner, but it ships crushed (mean luminance ~10/255), so "
            "the app read as flat black and the symbolic StarField overlay was "
            "doing all the visible work. This applies the standard astro stretch "
            "— subtract the sky background, then asinh — which lifts the band "
            "without lifting the black point, and warms the dense star regions."
        )
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--black", type=float, default=6.0,
                        help="sky-background level subtracted before stretching")
    parser.add_argument("--stretch", type=float, default=13.0,
                        help="asinh softening factor; higher reveals more band")
    parser.add_argument("--gain", type=float, default=62.0,
                        help="output scale applied after the stretch")
    parser.add_argument("--sat", type=float, default=1.5,
                        help="saturation multiplier for the nebula colour")
    parser.add_argument("--floor", default="#0B111F",
                        help="deepest sky colour; keeps night OLED-safe")
    parser.add_argument("--warm", default="#F2D9A8",
                        help="tint mixed into the brightest star regions")
    parser.add_argument("--warm-strength", type=float, default=0.20)
    parser.add_argument("--aspect", type=float, default=0.0,
                        help=(
                            "if set, crop to this width/height before grading. "
                            "The master is 9:16 but phones are narrower, so a "
                            "cover fit would crop the galactic band off the "
                            "right edge — the one feature worth keeping."
                        ))
    parser.add_argument("--anchor", type=float, default=1.0,
                        help="horizontal crop anchor, 0 = left … 1 = right")
    args = parser.parse_args()

    bgr = cv2.imread(str(args.input), cv2.IMREAD_COLOR)
    if bgr is None:
        raise SystemExit(f"cannot read {args.input}")

    if args.aspect > 0:
        height, width = bgr.shape[:2]
        target = int(round(height * args.aspect))
        if target < width:
            left = int(round((width - target) * args.anchor))
            bgr = bgr[:, left : left + target]

    image = bgr.astype(np.float32)

    # 1. Subtract the sky background so the stretch acts on signal, not offset.
    signal = np.clip(image - args.black, 0, None)

    # 2. asinh stretch. Unlike a gamma curve it compresses the bright stars
    #    while lifting faint nebulosity, which is exactly the asymmetry an
    #    astrophotograph needs: the band appears, the stars stay points.
    stretched = np.arcsinh(signal / args.stretch) * args.gain

    # 3. Saturate what the stretch revealed — the band carries the colour.
    hls = cv2.cvtColor(np.clip(stretched, 0, 255).astype(np.uint8),
                       cv2.COLOR_BGR2HLS).astype(np.float32)
    hls[..., 2] = np.clip(hls[..., 2] * args.sat, 0, 255)
    out = cv2.cvtColor(hls.astype(np.uint8), cv2.COLOR_HLS2BGR).astype(np.float32)

    # 4. Re-seat the black point on the design system's deepest night, so the
    #    empty sky is Eter's blue-black rather than a neutral grey-black.
    luma = cv2.cvtColor(out.astype(np.uint8), cv2.COLOR_BGR2GRAY).astype(np.float32)
    depth = np.clip(1.0 - luma / 40.0, 0.0, 1.0)[..., None]
    out = out * (1.0 - depth) + hex_to_bgr(args.floor)[None, None, :] * depth

    # 5. Warm the dense star clouds. Real galactic core imagery is not
    #    monochrome blue; a little gold keeps it from reading as a gradient.
    heat = np.clip((luma - 55.0) / 90.0, 0.0, 1.0)[..., None] * args.warm_strength
    out = out * (1.0 - heat) + hex_to_bgr(args.warm)[None, None, :] * heat

    cv2.imwrite(str(args.output), np.clip(out, 0, 255).astype(np.uint8))
    result = cv2.cvtColor(np.clip(out, 0, 255).astype(np.uint8), cv2.COLOR_BGR2GRAY)
    print(f"wrote {args.output}  mean luminance {result.mean():.1f}")


if __name__ == "__main__":
    main()
