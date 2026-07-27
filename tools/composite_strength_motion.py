"""Composite restrained Strength motion over its immutable approved master."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("master", type=Path)
    parser.add_argument("motion", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    master = cv2.imread(str(args.master))
    if master is None:
        raise RuntimeError("Cannot read master")
    height, width = master.shape[:2]

    # Deliberately excludes all borders, corner ornaments, title, and infinity
    # mark. The soft ellipse admits the figures and their nearby atmosphere.
    mask = np.zeros((height, width), np.uint8)
    cv2.ellipse(
        mask,
        (round(.50 * width), round(.53 * height)),
        (round(.34 * width), round(.37 * height)),
        0,
        0,
        360,
        255,
        -1,
    )
    mask = cv2.GaussianBlur(mask, (0, 0), sigmaX=18, sigmaY=18)
    alpha = mask.astype(np.float32)[:, :, None] / 255

    capture = cv2.VideoCapture(str(args.motion))
    fps = float(capture.get(cv2.CAP_PROP_FPS)) or 24
    generated: list[np.ndarray] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        generated.append(cv2.resize(frame, (width, height)))
    capture.release()
    if len(generated) < 12:
        raise RuntimeError("Motion clip is too short")

    blend_count = min(16, len(generated) // 4)
    for index in range(blend_count):
        amount = (index + 1) / blend_count
        tail = len(generated) - blend_count + index
        start = blend_count - 1 - index
        generated[tail] = cv2.addWeighted(
            generated[tail], 1 - amount, generated[start], amount, 0
        )

    frames = [
        (
            master.astype(np.float32) * (1 - alpha)
            + frame.astype(np.float32) * alpha
        ).astype(np.uint8)
        for frame in generated
    ]

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
            str(fps),
            "-i",
            "-",
            "-an",
            "-c:v",
            "libx264",
            "-vf",
            "pad=ceil(iw/2)*2:ceil(ih/2)*2",
            "-preset",
            "slow",
            "-crf",
            "20",
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
    print(f"Composited {len(frames)} locked-master frames")


if __name__ == "__main__":
    main()
