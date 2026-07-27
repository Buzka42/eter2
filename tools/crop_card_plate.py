"""Crop a generated clip back to the card plate and the master's geometry.

Video models return their own canvas, so the card sits inside a margin at an
aspect ratio the app never uses. Cropping to the plate here means the widget
never has to cover-crop a mismatched clip and cut the gold border rule off.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


def plate_bounds(path: Path, threshold: int) -> tuple[int, int, int, int]:
    """Return the tightest box containing the dark plate in every frame."""
    capture = cv2.VideoCapture(str(path))
    boxes: list[tuple[int, int, int, int]] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        ys, xs = np.where(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) < threshold)
        if len(xs) == 0:
            raise RuntimeError(f"No plate found in {path}")
        boxes.append((xs.min(), xs.max(), ys.min(), ys.max()))
    capture.release()
    if not boxes:
        raise RuntimeError(f"Cannot decode {path}")
    array = np.array(boxes)
    # The intersection, so a plate edge that wobbles by a pixel never leaves
    # background showing at the frame edge.
    return (
        int(array[:, 0].max()),
        int(array[:, 1].min()),
        int(array[:, 2].max()),
        int(array[:, 3].min()),
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("master", type=Path, help="Static master to match.")
    parser.add_argument("output", type=Path)
    parser.add_argument("--threshold", type=int, default=120)
    args = parser.parse_args()

    master = cv2.imread(str(args.master))
    if master is None:
        raise RuntimeError(f"Cannot read {args.master}")
    target_height, target_width = master.shape[:2]
    target_ratio = target_width / target_height
    # H.264 needs even dimensions; some masters are an odd number of pixels
    # wide.
    target_width -= target_width % 2
    target_height -= target_height % 2

    x0, x1, y0, y1 = plate_bounds(args.input, args.threshold)
    width, height = x1 - x0, y1 - y0

    # Trim the longer axis so the crop matches the master's aspect exactly and
    # nothing is stretched.
    if width / height > target_ratio:
        trimmed = round(height * target_ratio)
        x0 += (width - trimmed) // 2
        width = trimmed
    else:
        trimmed = round(width / target_ratio)
        y0 += (height - trimmed) // 2
        height = trimmed
    x0, y0 = x0 - x0 % 2, y0 - y0 % 2
    width, height = width - width % 2, height - height % 2

    args.output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error",
            "-i", str(args.input),
            "-vf",
            f"crop={width}:{height}:{x0}:{y0},"
            f"scale={target_width}:{target_height}:flags=lanczos",
            "-c:v", "libx264", "-crf", "12", "-pix_fmt", "yuv420p", "-an",
            str(args.output),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    print(
        f"Cropped {width}x{height}+{x0}+{y0} to "
        f"{target_width}x{target_height} ({args.master.name} geometry)"
    )


if __name__ == "__main__":
    main()
