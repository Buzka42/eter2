"""Repair a tarot loop while locking its approved static frame and typography."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path

import cv2
import numpy as np


def ffmpeg_executable() -> str:
    configured = os.environ.get("ETER_FFMPEG")
    if configured and Path(configured).is_file():
        return configured
    discovered = shutil.which("ffmpeg")
    if discovered:
        return discovered
    try:
        import imageio_ffmpeg

        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        pass
    playwright = Path(
        r"C:\Users\Arawn\AppData\Local\ms-playwright\ffmpeg-1011\ffmpeg-win64.exe"
    )
    if playwright.is_file():
        return str(playwright)
    raise RuntimeError("No ffmpeg executable is available")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("master", type=Path)
    parser.add_argument("motion", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--crossfade-frames", type=int, default=16)
    parser.add_argument("--motion-gain", type=float, default=1.0)
    args = parser.parse_args()

    master = cv2.imread(str(args.master))
    if master is None:
        raise RuntimeError(f"Cannot read {args.master}")
    height, width = master.shape[:2]

    # Admit the illustrated field while locking both frames, corner ornaments,
    # title, numeral, and the extreme top/bottom artwork.
    mask = np.zeros((height, width), np.uint8)
    left, top = round(.095 * width), round(.055 * height)
    right, bottom = round(.905 * width), round(.865 * height)
    cv2.rectangle(mask, (left, top), (right, bottom), 255, -1)
    mask = cv2.GaussianBlur(mask, (0, 0), sigmaX=16, sigmaY=16)
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
    if len(generated) < 24:
        raise RuntimeError("Motion clip is too short")
    temporal_mean = np.mean(
        np.stack(generated, axis=0).astype(np.float32),
        axis=0,
    )

    count = min(args.crossfade_frames, len(generated) // 4)
    for index in range(count):
        amount = (index + 1) / count
        tail = len(generated) - count + index
        start = count - 1 - index
        generated[tail] = cv2.addWeighted(
            generated[tail], 1 - amount, generated[start], amount, 0
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(
        [
            ffmpeg_executable(),
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
            "medium",
            "-crf",
            "14",
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
    for generated_frame in generated:
        if args.motion_gain == 1:
            frame = (
                master.astype(np.float32) * (1 - alpha)
                + generated_frame.astype(np.float32) * alpha
            )
        else:
            dynamic = generated_frame.astype(np.float32) - temporal_mean
            frame = master.astype(np.float32) + (
                dynamic * args.motion_gain * alpha
            )
        frame = np.clip(frame, 0, 255).astype(np.uint8)
        process.stdin.write(frame.tobytes())
    process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("Encoding failed")
    print(f"Repaired {args.motion.name}: {len(generated)} frames at {fps:g} fps")


if __name__ == "__main__":
    main()
