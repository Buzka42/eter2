"""Re-encode shipped art to the size the interface actually renders it at.

The commissioned masters were authored generously — Arcana cards at 1030 px
wide for a surface that draws them at 92 dp, loops at 5.4 Mbit/s for the same
92 dp. That generosity is why the release bundle was 186 MB against Play's
150 MB ceiling.

Nothing here changes what any surface shows. Every target below carries at
least 2x headroom over the largest size the interface can render the asset at,
so a future larger card or a 3x screen still has pixels to spare.

The lossless masters are untouched: they live in the v1 tree
(`../Eter/app/assets/art/masters/`) and in this repository's history.

Run from `app/`:  python tool/compress_assets.py [--dry-run]
"""

import glob
import os
import subprocess
import sys

FFMPEG = (
    r"C:/Users/Arawn/AppData/Local/Programs/Python/Python313/Lib/site-packages"
    r"/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe"
)

DRY = "--dry-run" in sys.argv


def size(path: str) -> int:
    return os.path.getsize(path) if os.path.exists(path) else 0


def run(args: list[str]) -> None:
    if DRY:
        print("   would run:", " ".join(args[:6]), "...")
        return
    subprocess.run(args, check=True, capture_output=True)


def encode_video(path: str, width: int, crf: int) -> None:
    """Re-encode in place through a temporary file."""
    before = size(path)
    temp = path + ".tmp.mp4"
    run([
        FFMPEG, "-hide_banner", "-loglevel", "error", "-i", path,
        "-vf", f"scale={width}:-2:flags=lanczos",
        "-an",
        "-c:v", "libx264", "-preset", "veryslow", "-crf", str(crf),
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        "-y", temp,
    ])
    if DRY:
        return
    os.replace(temp, path)
    print(f"   {os.path.basename(path)}: {before/1e6:.1f} -> {size(path)/1e6:.1f} MB")


def encode_image(path: str, width: int, quality: int, to_webp: bool = False) -> None:
    before = size(path)
    target = os.path.splitext(path)[0] + ".webp" if to_webp else path
    temp = target + ".tmp.webp"
    run([
        FFMPEG, "-hide_banner", "-loglevel", "error", "-i", path,
        "-vf", f"scale={width}:-1:flags=lanczos",
        "-c:v", "libwebp", "-quality", str(quality), "-compression_level", "6",
        "-y", temp,
    ])
    if DRY:
        return
    os.replace(temp, target)
    if target != path:
        os.remove(path)
    print(f"   {os.path.basename(path)}: {before/1e6:.2f} -> {size(target)/1e6:.2f} MB")


def main() -> None:
    total_before = 0
    total_after = 0

    def account(paths):
        return sum(size(p) for p in paths)

    # --- Arcana loops. Drawn, when they are drawn at all, inside a card the
    # Vessel renders at 92 dp; 720 px wide is 2.6x a 3x-density render.
    loops = [
        p for p in sorted(glob.glob("assets/art/animations/*.mp4"))
        if "air-field" not in os.path.basename(p)
    ]
    print(f"Arcana loops ({len(loops)}):")
    total_before += account(loops)
    for path in loops:
        encode_video(path, width=720, crf=30)
    total_after += account(loops)

    # --- The day ambient field. Full-screen, so it keeps phone width.
    day_field = ["assets/art/animations/air-field-light.mp4"]
    print("Day ambient field:")
    total_before += account(day_field)
    encode_video(day_field[0], width=1080, crf=30)
    total_after += account(day_field)

    # --- The Arcana deck. Rendered at 92 dp; 620 px is 2.2x a 3x render.
    cards = sorted(glob.glob("assets/art/cards/*.webp"))
    print(f"Arcana deck ({len(cards)}):")
    total_before += account(cards)
    for path in cards:
        encode_image(path, width=620, quality=82)
    total_after += account(cards)

    # --- Card backs, same treatment.
    backs = sorted(glob.glob("assets/art/card-back-v2-*.webp"))
    print("Card backs:")
    total_before += account(backs)
    for path in backs:
        encode_image(path, width=620, quality=82)
    total_after += account(backs)

    # --- The Vessel plates ship as full-size PNGs. No surface draws them
    # today; they are converted rather than deleted so the decision to keep or
    # cut them stays the product owner's.
    plates = sorted(glob.glob("assets/art/vessel/*.png"))
    print(f"Vessel plates ({len(plates)}):")
    total_before += account(plates)
    for path in plates:
        encode_image(path, width=720, quality=80, to_webp=True)
    total_after += account(sorted(glob.glob("assets/art/vessel/*")))

    print(
        f"\nTotal: {total_before/1e6:.1f} -> {total_after/1e6:.1f} MB "
        f"({(1 - total_after / max(total_before, 1)) * 100:.0f}% smaller)"
    )


if __name__ == "__main__":
    main()
