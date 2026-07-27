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
            "Grade the delivered sky master toward the Day Sky 'sunny morning' "
            "register. Unlike grade_sky_background.py — which desaturated the "
            "photograph until the light theme read as neutral grey — this keeps "
            "the sky blue, lifts it to a daylight exposure, and blooms a warm "
            "sun low on the frame so the surface has a light source."
        )
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--sat", type=float, default=0.92,
                        help="saturation multiplier; stays near 1 so the sky is blue")
    parser.add_argument("--lift", type=float, default=0.46,
                        help="lightness gamma (<1 brightens mids toward daylight)")
    parser.add_argument("--blend", type=float, default=0.30,
                        help="fraction of the vertical design gradient in the result")
    parser.add_argument("--top", default="#BFDDF2",
                        help="gradient top — open sky, between sky200 and sky300")
    parser.add_argument("--bottom", default="#FDFBF4",
                        help="gradient bottom — warm horizon haze")
    parser.add_argument("--sun-x", type=float, default=0.72,
                        help="sun centre, fraction of width")
    parser.add_argument("--sun-y", type=float, default=0.86,
                        help="sun centre, fraction of height")
    parser.add_argument("--sun-strength", type=float, default=0.34)
    parser.add_argument("--despeckle", type=int, default=9,
                        help="median kernel that removes the master's dusk stars")
    parser.add_argument("--sun-radius", type=float, default=0.78,
                        help="bloom radius as a fraction of the short edge")
    args = parser.parse_args()

    bgr = cv2.imread(str(args.input), cv2.IMREAD_COLOR)
    if bgr is None:
        raise SystemExit(f"cannot read {args.input}")

    # The master is a dusk exposure and still holds a few visible stars. A
    # daylight sky must not, and lifting the mids only makes them more
    # obvious, so they are median-filtered out before grading. The sky is a
    # smooth gradient, so nothing else is lost.
    if args.despeckle > 1:
        k = args.despeckle | 1  # medianBlur requires an odd kernel
        bgr = cv2.medianBlur(bgr, k)

    hls = cv2.cvtColor(bgr, cv2.COLOR_BGR2HLS).astype(np.float32)
    hls[..., 1] = 255.0 * (hls[..., 1] / 255.0) ** args.lift
    hls[..., 2] = np.clip(hls[..., 2] * args.sat, 0, 255)
    graded = cv2.cvtColor(hls.astype(np.uint8), cv2.COLOR_HLS2BGR).astype(np.float32)

    height, width = graded.shape[:2]
    top = hex_to_bgr(args.top)
    bottom = hex_to_bgr(args.bottom)
    t = np.linspace(0.0, 1.0, height, dtype=np.float32)[:, None, None]
    # Ease the vertical ramp so the horizon haze gathers low instead of
    # washing the whole frame evenly.
    t = t ** 1.6
    gradient = np.repeat(top[None, None, :] * (1 - t) + bottom[None, None, :] * t,
                         width, axis=1)
    out = graded * (1.0 - args.blend) + gradient * args.blend

    # Warm sun bloom: a soft radial falloff toward a low-saturation warm white.
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    cx, cy = args.sun_x * width, args.sun_y * height
    radius = args.sun_radius * min(width, height)
    distance = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / radius
    falloff = np.clip(1.0 - distance, 0.0, 1.0) ** 2.2
    bloom = (falloff * args.sun_strength)[..., None]
    sun = hex_to_bgr("#FFF6E2")[None, None, :]
    out = out * (1.0 - bloom) + sun * bloom

    cv2.imwrite(str(args.output), np.clip(out, 0, 255).astype(np.uint8))
    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
