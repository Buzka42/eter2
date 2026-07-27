from __future__ import annotations

import argparse
from pathlib import Path

import cv2
import numpy as np


def hex_to_rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Grade a delivered sky master toward the Aether Light pale-morning "
            "register: desaturate, lift lightness, then blend with the design "
            "system's vertical background gradient so foreground contrast holds."
        )
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--sat", type=float, default=0.40,
                        help="saturation multiplier (0-1)")
    parser.add_argument("--lift", type=float, default=0.55,
                        help="lightness gamma (<1 brightens mids)")
    parser.add_argument("--blend", type=float, default=0.45,
                        help="fraction of the target gradient in the result")
    parser.add_argument("--top", default="#FAFCFE", help="gradient top (mist50)")
    parser.add_argument("--bottom", default="#D6EAF7", help="gradient bottom (sky200)")
    args = parser.parse_args()

    bgr = cv2.imread(str(args.input), cv2.IMREAD_COLOR)
    if bgr is None:
        raise SystemExit(f"cannot read {args.input}")
    hls = cv2.cvtColor(bgr, cv2.COLOR_BGR2HLS).astype(np.float32)
    hls[..., 1] = 255.0 * (hls[..., 1] / 255.0) ** args.lift
    hls[..., 2] = np.clip(hls[..., 2] * args.sat, 0, 255)
    graded = cv2.cvtColor(hls.astype(np.uint8), cv2.COLOR_HLS2BGR).astype(np.float32)

    height, width = graded.shape[:2]
    top = np.array(hex_to_rgb(args.top)[::-1], dtype=np.float32)
    bottom = np.array(hex_to_rgb(args.bottom)[::-1], dtype=np.float32)
    t = np.linspace(0.0, 1.0, height, dtype=np.float32)[:, None, None]
    gradient = top[None, None, :] * (1 - t) + bottom[None, None, :] * t
    gradient = np.repeat(gradient, width, axis=1)

    out = graded * (1.0 - args.blend) + gradient * args.blend
    cv2.imwrite(str(args.output), np.clip(out, 0, 255).astype(np.uint8))
    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
