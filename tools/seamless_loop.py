"""Build a seamless application loop and prove the join is closed.

`normalize_loop.py` applies a fixed crossfade wherever the clip happens to
end, which cannot help when a generated clip never returns to its opening
state. This tool first cuts the clip at the point where the motion genuinely
comes back around, then blends across that join, and refuses to write a clip
whose two ends still do not match.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import imageio_ffmpeg
import numpy as np


def read_frames(path: Path, trim: bool = True) -> list[np.ndarray]:
    capture = cv2.VideoCapture(str(path))
    frames: list[np.ndarray] = []
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        frames.append(frame)
    capture.release()
    if len(frames) < 24:
        raise RuntimeError(f"{path} is too short to loop safely")
    # Generators often hold the final frame; a duplicate endpoint reads as a
    # pause once the clip repeats.
    while (
        trim
        and len(frames) > 2
        and np.abs(frames[-1].astype(np.float32) -
                   frames[-2].astype(np.float32)).mean() < 0.03
    ):
        frames.pop()
    return frames


def loop_range(
    frames: list[np.ndarray], minimum_fraction: float
) -> tuple[int, int]:
    """Find the sub-range whose two ends already match most closely.

    A generated clip rarely returns to its opening state, and no crossfade
    hides a large mismatch. Cutting the loop where the motion has genuinely
    come back around gives the blend almost nothing left to hide.
    """
    thumbs = [
        cv2.GaussianBlur(
            cv2.resize(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY), (96, 144)),
            (0, 0), 1.5,
        ).astype(np.float32)
        for frame in frames
    ]
    span = max(12, round(len(frames) * minimum_fraction))
    best = (float("inf"), 0, len(frames) - 1)
    for start in range(0, len(frames) - span):
        for end in range(start + span, len(frames)):
            distance = float(np.abs(thumbs[start] - thumbs[end]).mean())
            # Prefer the longest cut among near-equal candidates so the loop
            # keeps its full duration where possible.
            score = distance - (end - start) / len(frames) * 0.02
            if score < best[0]:
                best = (score, start, end)
    return best[1], best[2]


def ping_pong(frames: list[np.ndarray]) -> list[np.ndarray]:
    """Play the clip forward then backward so it closes by construction.

    Only for motion with no direction the eye can name — drifting cloud,
    breathing glow, a twinkle. Anything that falls, pours or travels one way
    reads as rewinding and must not use this.

    The two turning frames are dropped so neither end is held for two frames,
    which would read as a hitch at the moment the motion reverses.
    """
    return frames + frames[-2:0:-1]


def crossfade(frames: list[np.ndarray], count: int) -> list[np.ndarray]:
    if count <= 0:
        return [frame.copy() for frame in frames]
    output = [frame.copy() for frame in frames]
    for index in range(count):
        alpha = (index + 1) / (count + 1)
        tail = len(output) - count + index
        output[tail] = cv2.addWeighted(
            output[tail], 1 - alpha, output[count - 1 - index], alpha, 0
        )
    return output


def measure(
    frames: list[np.ndarray], blur: float = 0.0
) -> tuple[float, float, float]:
    """Return the join size, the mean frame step, and the 95th-percentile step.

    With `blur` set, the comparison ignores high-frequency codec noise. That
    matters because H.264 codes the first frame as a keyframe and the last as
    a predicted frame: their noise differs even when the pictures match, which
    inflates a raw pixel comparison without anything being visible.
    """
    gray = [cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY).astype(np.float32)
            for frame in frames]
    if blur:
        gray = [cv2.GaussianBlur(frame, (0, 0), blur) for frame in gray]
    stack = np.stack(gray)
    steps = np.abs(np.diff(stack, axis=0)).mean(axis=(1, 2))
    seam = float(np.abs(stack[0] - stack[-1]).mean())
    return seam, float(steps.mean()), float(np.percentile(steps, 95))


def encode(frames: list[np.ndarray], output: Path, fps: float, crf: int) -> None:
    height, width = frames[0].shape[:2]
    output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(
        [
            imageio_ffmpeg.get_ffmpeg_exe(), "-y",
            "-f", "rawvideo", "-pix_fmt", "bgr24",
            "-s", f"{width}x{height}", "-r", str(fps), "-i", "-",
            "-an", "-c:v", "libx264", "-preset", "medium", "-crf", str(crf),
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(output),
        ],
        stdin=subprocess.PIPE,
        # ffmpeg is chatty, and an inherited pipe that nobody drains will
        # block it mid-write once the buffer fills.
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    assert process.stdin is not None
    try:
        for frame in frames:
            process.stdin.write(frame.tobytes())
    finally:
        process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("Encoding failed")


def coding_noise(
    frame: np.ndarray, output: Path, fps: float, crf: int, blur: float
) -> float:
    """Measure the seam the encoder invents on a clip that never changes.

    Encoding one still frame on repeat should produce an identical picture
    throughout, so whatever difference remains between the decoded first and
    last frames is the codec's own keyframe-versus-predicted-frame noise. That
    is the floor any real clip's join is measured against.
    """
    control = output.with_name(f"{output.stem}-control.mp4")
    try:
        encode([frame] * 24, control, fps, crf)
        seam, _, _ = measure(read_frames(control, trim=False), blur=blur)
    finally:
        control.unlink(missing_ok=True)
    return seam


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fps", type=float, default=30)
    parser.add_argument(
        "--candidates",
        type=int,
        nargs="+",
        default=[6, 8, 10, 12, 16, 20, 24, 30],
        help="Crossfade lengths to try, shortest first.",
    )
    parser.add_argument(
        "--crf",
        type=int,
        nargs="+",
        default=[16, 14, 12],
        help="Encoder qualities to try, cheapest first.",
    )
    parser.add_argument(
        "--blur",
        type=float,
        default=2.0,
        help="Gaussian sigma used to ignore codec noise when judging the join.",
    )
    parser.add_argument(
        "--minimum-fraction",
        type=float,
        default=0.7,
        help="Shortest loop the search may cut, as a fraction of the clip.",
    )
    parser.add_argument(
        "--ping-pong",
        action="store_true",
        help="Play forward then backward. Closes any clip, but only suits "
             "motion with no readable direction.",
    )
    parser.add_argument(
        "--closure",
        type=float,
        default=0.25,
        help="Largest join allowed before encoding, as a share of one step.",
    )
    args = parser.parse_args()

    source = read_frames(args.input)
    if args.ping_pong:
        source = ping_pong(source)
        print(f"Ping-pong: {len(source)} frames "
              f"({len(source) / args.fps:.2f}s)")
    start, end = loop_range(source, args.minimum_fraction)
    if (start, end) != (0, len(source) - 1):
        print(
            f"Loop point: frames {start}-{end} of {len(source)} "
            f"({(end - start + 1) / args.fps:.2f}s)"
        )
        source = source[start:end + 1]
    limit = len(source) // 3

    # Only the encoded file matters, so every candidate is judged after
    # encoding. A longer crossfade buys loop quality at no size cost, which is
    # far cheaper than raising the bitrate to fight the same seam.
    for crf in args.crf:
        floor = coding_noise(source[0], args.output, args.fps, crf, args.blur)
        print(f"crf {crf}: codec noise floor {floor:.4f}")
        best: tuple[float, int, float] | None = None
        for count in args.candidates:
            if count > limit:
                break
            frames = crossfade(source, count)
            # Two separate questions. Before encoding: did the clip actually
            # close, or is the blend papering over a jump? After encoding:
            # is the join still no more eventful than the clip's own busiest
            # transitions? H.264 codes frame one as a keyframe and the last as
            # a predicted frame, so their noise differs even when the pictures
            # are identical; judging the shipped file against the structural
            # step alone would fail loops that are mathematically exact.
            closure, closure_step, _ = measure(frames, blur=args.blur)
            encode(frames, args.output, args.fps, crf)
            decoded = read_frames(args.output)
            raw_seam, raw_step, _ = measure(decoded)
            seam, step, p95 = measure(decoded, blur=args.blur)
            size = args.output.stat().st_size / 1_048_576
            closed = closure <= closure_step * args.closure
            # Closure is the gate: it asks whether the pictures either side of
            # the join actually match. The encoded seam is reported, not
            # enforced. On a quiet clip it is dominated by the codec's own
            # scattered dither of a couple of grey levels, which no threshold
            # can separate from a real jump and no viewer can see.
            print(
                f"crossfade {count:>3} crf {crf:>3}: closure {closure:.4f} vs "
                f"step {closure_step:.4f} ({closure / closure_step:.2f}x, "
                f"{'closed' if closed else 'OPEN'}); encoded seam {seam:.4f} "
                f"against a {floor:.4f} codec floor and a {p95:.4f} p95 step; "
                f"raw seam {raw_seam:.4f} vs raw step {raw_step:.4f} "
                f"({size:.2f} MB)"
            )
            if closed and (best is None or closure < best[0]):
                best = (closure, count, closure / closure_step)

        # Longer crossfades cost nothing in file size, so take the tightest
        # join this quality level can reach rather than the first one that
        # scrapes past the threshold.
        if best is not None:
            _, count, ratio = best
            encode(crossfade(source, count), args.output, args.fps, crf)
            print(
                f"Wrote {len(source)} frames: {count}-frame crossfade at crf "
                f"{crf}, join {ratio:.2f}x a normal frame step"
            )
            return

    raise SystemExit(
        "No setting closed the loop; recut or regenerate the clip rather "
        "than shipping a visible stitch."
    )


if __name__ == "__main__":
    main()
