"""Create an evenly sampled contact sheet for visual motion review."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import cv2
import numpy as np


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("video", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--samples", type=int, default=9)
    args = parser.parse_args()
    capture = cv2.VideoCapture(str(args.video))
    count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
    frames: list[np.ndarray] = []
    for index in np.linspace(0, max(0, count - 1), args.samples).astype(int):
        capture.set(cv2.CAP_PROP_POS_FRAMES, int(index))
        ok, frame = capture.read()
        if not ok:
            continue
        target_height = 360
        scale = target_height / frame.shape[0]
        frame = cv2.resize(
            frame,
            (round(frame.shape[1] * scale), target_height),
            interpolation=cv2.INTER_AREA,
        )
        cv2.putText(
            frame,
            f"f{index}",
            (10, 28),
            cv2.FONT_HERSHEY_SIMPLEX,
            .7,
            (255, 255, 255),
            2,
            cv2.LINE_AA,
        )
        frames.append(frame)
    capture.release()
    columns = 3
    rows = math.ceil(len(frames) / columns)
    cell_height = max(frame.shape[0] for frame in frames)
    cell_width = max(frame.shape[1] for frame in frames)
    sheet = np.zeros((rows * cell_height, columns * cell_width, 3), np.uint8)
    for index, frame in enumerate(frames):
        row, column = divmod(index, columns)
        sheet[
            row * cell_height : row * cell_height + frame.shape[0],
            column * cell_width : column * cell_width + frame.shape[1],
        ] = frame
    args.output.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(args.output), sheet)


if __name__ == "__main__":
    main()
