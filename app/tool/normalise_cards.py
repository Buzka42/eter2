"""Make the Arcana one deck.

An audit of the shipped art found three ways the deck was not internally
consistent:

1. **Four aspect ratios across 22 cards.** Fifteen sat at 1.485, five at 1.500,
   and the Magician and the Tower at their own values. Stacked in a column at a
   fixed width, a card sat visibly taller or shorter than its neighbours.
2. **Nine cards whose light and dark versions were different heights.** The
   same card changed shape when the register changed, which is the one place a
   difference is most visible.
3. **Judgement's loop was framed 5.5% tighter than its still**, so the art
   jumped and the deck's gold border was cut off the moment the loop began.

This normalises all three. The canonical ratio is the majority's, 620x920, and
resampling the faces by at most 1.5% in one axis is well below what the eye
resolves — cropping them instead would eat into the border the deck draws.

The two card backs are the exception: they ship at 1.70, and squashing a 13%
difference is visible distortion rather than a rounding. They are centre-cropped
to the canonical ratio, which costs a little of a repeating pattern and no
drawn detail.

The loop fix is not a resize: Judgement's loop is composited *onto its own
still*, scaled to the alignment the audit measured, so the border under the
motion is the deck's real border rather than a guess at one.

Run from `app/`:  python tool/normalise_cards.py [--dry-run]
"""

import glob
import os
import subprocess
import sys

from PIL import Image

FFMPEG = (
    r"C:/Users/Arawn/AppData/Local/Programs/Python/Python313/Lib/site-packages"
    r"/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe"
)

DRY = "--dry-run" in sys.argv

# The majority's ratio, rounded so both axes stay even: x264 refuses odd
# dimensions in yuv420p, and a still that disagreed with its loop by a pixel
# would put the mismatch back.
CARD_W, CARD_H = 620, 920          # 1.4839
LOOP_W, LOOP_H = 720, 1068         # 1.4833 — a 0.04% difference, invisible

# Measured by correlating the loop against the still; see the module docstring.
JUDGEMENT_SCALE = 0.945


def run(args: list[str]) -> None:
    if DRY:
        print("   would run:", " ".join(args[:8]), "...")
        return
    subprocess.run(args, check=True, capture_output=True)


def normalise_stills() -> None:
    changed = 0
    for path in sorted(glob.glob("assets/art/cards/*.webp")):
        with Image.open(path) as image:
            if image.size == (CARD_W, CARD_H):
                continue
            before = image.size
            resized = image.convert("RGB").resize(
                (CARD_W, CARD_H), Image.LANCZOS
            )
        if DRY:
            print(f"   {os.path.basename(path)}: {before} -> "
                  f"{(CARD_W, CARD_H)}")
            continue
        resized.save(path, "WEBP", quality=82, method=6)
        changed += 1
        print(f"   {os.path.basename(path)}: {before} -> {(CARD_W, CARD_H)}")
    print(f"stills normalised: {changed}")


def normalise_backs() -> None:
    """Centre-crop the backs rather than squash them."""
    for path in sorted(glob.glob("assets/art/card-back-v2-*.webp")):
        with Image.open(path) as image:
            if image.size == (CARD_W, CARD_H):
                continue
            before = image.size
            width, height = image.size
            target = CARD_H / CARD_W
            if height / width > target:
                keep = round(width * target)
                top = (height - keep) // 2
                box = (0, top, width, top + keep)
            else:
                keep = round(height / target)
                left = (width - keep) // 2
                box = (left, 0, left + keep, height)
            cropped = image.convert("RGB").crop(box).resize(
                (CARD_W, CARD_H), Image.LANCZOS
            )
        if DRY:
            print(f"   {os.path.basename(path)}: {before} cropped -> "
                  f"{(CARD_W, CARD_H)}")
            continue
        cropped.save(path, "WEBP", quality=82, method=6)
        print(f"   {os.path.basename(path)}: {before} cropped -> "
              f"{(CARD_W, CARD_H)}")


def normalise_loops() -> None:
    changed = 0
    for path in sorted(glob.glob("assets/art/animations/*-dark.mp4")):
        if "air-field" in os.path.basename(path):
            continue
        temp = path + ".tmp.mp4"
        run([
            FFMPEG, "-hide_banner", "-loglevel", "error", "-i", path,
            "-vf", f"scale={LOOP_W}:{LOOP_H}:flags=lanczos",
            "-an", "-c:v", "libx264", "-preset", "veryslow", "-crf", "30",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-y", temp,
        ])
        if DRY:
            continue
        os.replace(temp, path)
        changed += 1
    print(f"loops normalised: {changed}")


def refit_judgement() -> None:
    """Composite the loop onto its own still so the border is the deck's."""
    loop = "assets/art/animations/judgement-dark.mp4"
    still = "assets/art/cards/judgement-dark.webp"
    temp = loop + ".tmp.mp4"
    run([
        FFMPEG, "-hide_banner", "-loglevel", "error",
        "-loop", "1", "-i", still,
        "-i", loop,
        "-filter_complex",
        f"[0:v]scale={LOOP_W}:{LOOP_H}:flags=lanczos,setsar=1[bg];"
        f"[1:v]scale=iw*{JUDGEMENT_SCALE}:ih*{JUDGEMENT_SCALE}:flags=lanczos,"
        f"setsar=1[fg];"
        f"[bg][fg]overlay=(W-w)/2:(H-h)/2:shortest=1,format=yuv420p[v]",
        "-map", "[v]", "-an",
        "-c:v", "libx264", "-preset", "veryslow", "-crf", "30",
        "-movflags", "+faststart", "-y", temp,
    ])
    if DRY:
        return
    os.replace(temp, loop)
    print("judgement loop refitted to its still")


def main() -> None:
    print("Stills:")
    normalise_stills()
    print("Backs:")
    normalise_backs()
    print("Loops:")
    normalise_loops()
    refit_judgement()


if __name__ == "__main__":
    main()
