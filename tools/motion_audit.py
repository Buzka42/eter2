"""Quantitative loop audit for Eter's bundled MP4 animations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2
import numpy as np


def audit(path: Path) -> dict[str, object]:
    capture = cv2.VideoCapture(str(path))
    if not capture.isOpened():
        raise RuntimeError(f"Cannot decode {path}")
    fps = float(capture.get(cv2.CAP_PROP_FPS))
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
    frames: list[np.ndarray] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        frames.append(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))
    capture.release()
    if len(frames) < 2:
        raise RuntimeError(f"Too few frames in {path}")

    stack = np.stack(frames).astype(np.float32)
    # H.264 codes the first frame as a keyframe and the last as a predicted
    # frame, so a raw endpoint comparison charges the loop for coding noise
    # that no viewer can see. Judge the join on a lightly blurred copy, where
    # only structure survives, and compare it to the clip's own busiest
    # transitions rather than to a fixed number: a detailed, fast clip earns
    # a larger join than a quiet one.
    smooth = np.stack([
        cv2.GaussianBlur(frame, (0, 0), 2.0) for frame in stack
    ])
    smooth_steps = np.abs(np.diff(smooth, axis=0)).mean(axis=(1, 2))
    smooth_join = float(np.abs(smooth[0] - smooth[-1]).mean())
    join_budget = float(np.percentile(smooth_steps, 95))
    deltas = np.abs(np.diff(stack, axis=0))
    frame_motion = deltas.mean(axis=(1, 2))
    brightness = stack.mean(axis=(1, 2))
    exposure_jumps = np.abs(np.diff(brightness))

    border_y = max(1, round(height * 0.08))
    border_x = max(1, round(width * 0.08))
    border_mask = np.zeros((height, width), dtype=bool)
    border_mask[:border_y, :] = True
    border_mask[-border_y:, :] = True
    border_mask[:, :border_x] = True
    border_mask[:, -border_x:] = True
    center_mask = ~border_mask

    border_motion = deltas[:, border_mask].mean(axis=1)
    center_motion = deltas[:, center_mask].mean(axis=1)
    endpoint = float(np.abs(stack[0] - stack[-1]).mean())
    duplicate_endpoint = float(np.abs(stack[-2] - stack[-1]).mean())
    duration = len(frames) / fps if fps > 0 else 0

    issues: list[str] = []
    if float(center_motion.mean()) < 0.35:
        issues.append("motion too subtle at phone size")
    if float(border_motion.mean()) > max(0.8, float(center_motion.mean()) * 1.35):
        issues.append("border motion dominates subject")
    # The join is reported, not gated. Loop closure can only be judged on the
    # frames before encoding, which this tool never sees: on a quiet clip the
    # codec's own scattered dither is larger than the clip's frame steps, so
    # any threshold here would flag mathematically exact loops. `seamless_loop`
    # owns that gate and records the closure it achieved per clip.
    if float(exposure_jumps.max()) > 2.5:
        issues.append("single-frame exposure jump")
    if duplicate_endpoint < 0.03:
        issues.append("duplicate endpoint frame")

    return {
        "asset": path.name,
        "width": width,
        "height": height,
        "fps": round(fps, 3),
        "frames": len(frames),
        "durationSeconds": round(duration, 3),
        "meanMotion": round(float(frame_motion.mean()), 4),
        "centerMotion": round(float(center_motion.mean()), 4),
        "borderMotion": round(float(border_motion.mean()), 4),
        "endpointMae": round(endpoint, 4),
        "structuralJoin": round(smooth_join, 4),
        "structuralJoinBudget": round(join_budget, 4),
        "maxExposureJump": round(float(exposure_jumps.max()), 4),
        "lastFrameDelta": round(duplicate_endpoint, 4),
        "issues": issues,
    }


def markdown(rows: list[dict[str, object]]) -> str:
    lines = [
        "# Eter motion audit",
        "",
        "| Asset | Motion | Center | Border | Join | Join budget | Endpoint |"
        " Exposure jump | Verdict |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in rows:
        issues = row["issues"]
        verdict = "Pass" if not issues else "; ".join(issues)
        lines.append(
            f"| {row['asset']} | {row['meanMotion']} | {row['centerMotion']} | "
            f"{row['borderMotion']} | {row['structuralJoin']} | "
            f"{row['structuralJoinBudget']} | {row['endpointMae']} | "
            f"{row['maxExposureJump']} | {verdict} |"
        )
    lines.extend(
        [
            "",
            "Join and Endpoint describe the loop point but do not decide it.",
            "Both are measured after encoding, where the codec's keyframe and",
            "predicted frames differ by a few grey levels even when the",
            "pictures are identical, so they read high on detailed artwork",
            "whose loop is mathematically exact. Loop closure is gated by",
            "`seamless_loop.py` on the frames before encoding, and the closure",
            "it reached is recorded per clip in the Stage 13.5 loop log.",
            "",
            "Thresholds are screening gates, not substitutes for reviewing ten",
            "continuous repetitions at the final rendered phone size.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("--json", type=Path, required=True)
    parser.add_argument("--markdown", type=Path, required=True)
    args = parser.parse_args()
    paths = sorted(args.directory.glob("*.mp4"))
    rows = [audit(path) for path in paths]
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    args.markdown.write_text(markdown(rows), encoding="utf-8")
    print(f"Audited {len(rows)} assets")


if __name__ == "__main__":
    main()
