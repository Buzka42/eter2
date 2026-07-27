"""Normalize an approved motion clip to a stable H.264 application loop."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fps", type=float, default=30)
    parser.add_argument("--crossfade-frames", type=int, default=6)
    args = parser.parse_args()

    capture = cv2.VideoCapture(str(args.input))
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
    frames: list[np.ndarray] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        frames.append(frame)
    capture.release()
    if len(frames) < max(12, args.crossfade_frames * 2):
        raise RuntimeError("Clip is too short to normalize safely")

    while (
        len(frames) > 2
        and np.abs(frames[-1].astype(float) - frames[-2].astype(float)).mean()
        < 0.03
    ):
        frames.pop()

    blend_count = max(0, min(args.crossfade_frames, len(frames) // 4))
    if blend_count:
        for index in range(blend_count):
            alpha = (index + 1) / blend_count
            tail_index = len(frames) - blend_count + index
            start_index = blend_count - 1 - index
            frames[tail_index] = cv2.addWeighted(
                frames[tail_index],
                1 - alpha,
                frames[start_index],
                alpha,
                0,
            )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    command = [
        ffmpeg,
        "-y",
        "-f",
        "rawvideo",
        "-pix_fmt",
        "bgr24",
        "-s",
        f"{width}x{height}",
        "-r",
        str(args.fps),
        "-i",
        "-",
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-crf",
        "14",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(args.output),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None
    try:
        for frame in frames:
            process.stdin.write(frame.tobytes())
    finally:
        process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("ffmpeg encoding failed")
    print(f"Encoded {len(frames)} frames to {args.output}")


if __name__ == "__main__":
    main()
