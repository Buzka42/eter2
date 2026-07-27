"""Create a seamless shimmer constrained to painted water-path regions."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


REGIONS = {
    "star": ((.18, .56, .38, .82), (.64, .55, .84, .82)),
    "temperance": ((.32, .30, .68, .54),),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=REGIONS)
    parser.add_argument("master", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    master = cv2.imread(str(args.master))
    if master is None:
        raise RuntimeError(f"Cannot read {args.master}")
    height, width = master.shape[:2]
    luminance = cv2.cvtColor(master, cv2.COLOR_BGR2GRAY)
    water_mask = np.zeros((height, width), np.float32)

    for x0, y0, x1, y1 in REGIONS[args.kind]:
        xa, ya, xb, yb = (
            round(x0 * width),
            round(y0 * height),
            round(x1 * width),
            round(y1 * height),
        )
        roi = luminance[ya:yb, xa:xb]
        # Water is among the brightest painted material in these tightly
        # bounded regions. A soft threshold catches streams and sparkles only.
        selected = np.clip((roi.astype(np.float32) - 112) / 70, 0, 1)
        water_mask[ya:yb, xa:xb] = np.maximum(
            water_mask[ya:yb, xa:xb], selected
        )
    water_mask = cv2.GaussianBlur(water_mask, (0, 0), sigmaX=2.2, sigmaY=2.2)

    yy, xx = np.mgrid[0:height, 0:width]
    travel = (yy / height) * 8.5 + (xx / width) * 1.5
    frames: list[np.ndarray] = []
    base = master.astype(np.float32)
    frame_count = 96
    for index in range(frame_count):
        # Three closed shimmer cycles per four-second asset avoid a perceptual
        # pause at the sine extrema while preserving an exact loop.
        phase = 6 * np.pi * index / frame_count
        shimmer = (np.sin(2 * np.pi * travel - phase) + 1) / 2
        sparkle = (np.sin(4 * np.pi * travel - 2 * phase) + 1) / 2
        # Localized water occupies only a small fraction of the card, so the
        # modulation must remain legible after phone-size downsampling.
        gain = water_mask * (0.90 * shimmer + 0.50 * sparkle)
        frames.append(np.clip(base * (1 + gain[:, :, None]), 0, 255).astype(np.uint8))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(
        [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-y",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "bgr24",
            "-s",
            f"{width}x{height}",
            "-r",
            "24",
            "-i",
            "-",
            "-an",
            "-c:v",
            "libx264",
            "-vf",
            "pad=ceil(iw/2)*2:ceil(ih/2)*2",
            "-preset",
            "medium",
            "-crf",
            "19",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            str(args.output),
        ],
        stdin=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    assert process.stdin is not None
    for frame in frames:
        process.stdin.write(frame.tobytes())
    process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("Encoding failed")
    print(f"Animated {args.kind} water path in {frame_count} seamless frames")


if __name__ == "__main__":
    main()
