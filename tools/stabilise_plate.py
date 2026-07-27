"""Lock a generated card clip to its first frame.

Video models drift: over a few seconds the whole plate creeps by a pixel or
two, which is invisible in isolation but obvious on a tarot card, where a
ruled gold border frames the art and the clip plays over a static master that
does not move. This removes that drift by measuring each frame's offset
against the first and shifting it back.

Only whole-frame translation is corrected. Scale and rotation drift are
reported so they cannot pass unnoticed, because correcting those means
resampling the whole picture and softening the line work this exists to
protect.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


def frames_of(path: Path) -> list[np.ndarray]:
    capture = cv2.VideoCapture(str(path))
    frames: list[np.ndarray] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        frames.append(frame)
    capture.release()
    if not frames:
        raise RuntimeError(f"Cannot decode {path}")
    return frames


def offset(reference: np.ndarray, frame: np.ndarray) -> tuple[float, float]:
    """Sub-pixel translation of `frame` relative to `reference`."""
    window = cv2.createHanningWindow(
        (reference.shape[1], reference.shape[0]), cv2.CV_32F
    )
    shift, _ = cv2.phaseCorrelate(reference, frame, window)
    return shift


def border_motion(frames: list[np.ndarray], band: float = 0.03) -> float:
    gray = np.stack(
        [cv2.cvtColor(f, cv2.COLOR_BGR2GRAY).astype(np.float32) for f in frames]
    )
    height, width = gray.shape[1:]
    mask = np.zeros((height, width), bool)
    top, side = max(2, int(height * band)), max(2, int(width * band))
    mask[:top, :] = mask[-top:, :] = True
    mask[:, :side] = mask[:, -side:] = True
    return float(np.abs(np.diff(gray, axis=0))[:, mask].mean())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fps", type=float, default=24)
    parser.add_argument("--crf", type=int, default=16)
    args = parser.parse_args()

    frames = frames_of(args.input)
    reference = cv2.cvtColor(frames[0], cv2.COLOR_BGR2GRAY).astype(np.float32)

    corrected: list[np.ndarray] = [frames[0]]
    shifts: list[tuple[float, float]] = [(0.0, 0.0)]
    for frame in frames[1:]:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY).astype(np.float32)
        dx, dy = offset(reference, gray)
        shifts.append((dx, dy))
        matrix = np.float32([[1, 0, -dx], [0, 1, -dy]])
        corrected.append(
            cv2.warpAffine(
                frame,
                matrix,
                (frame.shape[1], frame.shape[0]),
                flags=cv2.INTER_LANCZOS4,
                borderMode=cv2.BORDER_REPLICATE,
            )
        )

    travel = max(abs(dx) + abs(dy) for dx, dy in shifts)
    before, after = border_motion(frames), border_motion(corrected)
    print(f"Largest drift corrected: {travel:.2f} px")
    print(f"Border motion {before:.4f} -> {after:.4f}")
    if after > before:
        raise SystemExit(
            "Stabilisation made the border worse; the drift is probably scale "
            "or rotation, which this tool does not correct."
        )

    height, width = corrected[0].shape[:2]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(
        [
            imageio_ffmpeg.get_ffmpeg_exe(), "-y",
            "-f", "rawvideo", "-pix_fmt", "bgr24",
            "-s", f"{width}x{height}", "-r", str(args.fps), "-i", "-",
            "-an", "-c:v", "libx264", "-preset", "medium",
            "-crf", str(args.crf), "-pix_fmt", "yuv420p", str(args.output),
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    assert process.stdin is not None
    try:
        for frame in corrected:
            process.stdin.write(frame.tobytes())
    finally:
        process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("Encoding failed")
    print(f"Wrote {len(corrected)} stabilised frames")


if __name__ == "__main__":
    main()
