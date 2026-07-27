"""Re-encode bundled artwork as WebP and keep the PNG masters aside.

The card and background masters are painterly renders, and PNG stores them
about six times larger than WebP does for a difference no phone screen shows:
they are downscaled to a fraction of their pixel size before anyone sees them.
The masters are not deleted — they move to an undeclared directory, so the
originals stay in the repository without being packaged into the app.

Images with transparency are left alone by default. They are fine line work
whose edges are the whole point, and they are small enough not to matter.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

import numpy as np
from PIL import Image


def psnr(original: Image.Image, encoded: Image.Image) -> float:
    a = np.asarray(original.convert('RGB'), dtype=np.float32)
    b = np.asarray(encoded.convert('RGB'), dtype=np.float32)
    mse = float(((a - b) ** 2).mean())
    if mse == 0:
        return float('inf')
    return 10 * float(np.log10(255 ** 2 / mse))


def convert(
    source: Path,
    masters: Path,
    quality: int,
    minimum_psnr: float,
    include_alpha: bool,
    dry_run: bool,
) -> tuple[int, int, bool]:
    image = Image.open(source)
    has_alpha = image.mode in ('RGBA', 'LA') or 'transparency' in image.info
    if has_alpha and not include_alpha:
        return source.stat().st_size, source.stat().st_size, False

    # Quality is chosen per image, not fixed. Flat dark fields with fine gold
    # line work show error far more readily than a painted scene does, so a
    # single setting either bloats the easy images or degrades the hard ones.
    target = source.with_suffix('.webp')
    chosen = None
    for candidate in sorted({quality, 97, 98, 99, 100}):
        if candidate < quality:
            continue
        image.save(target, 'WEBP', quality=candidate, method=6)
        measured = psnr(image, Image.open(target))
        if measured >= minimum_psnr:
            chosen = (candidate, measured)
            break
    if chosen is None:
        image.save(target, 'WEBP', lossless=True, method=6)
        chosen = (100, float('inf'))

    before, after = source.stat().st_size, target.stat().st_size
    quality_used, measured = chosen
    label = 'lossless' if measured == float('inf') else f'q{quality_used}'
    print(f'  {label:<9}', end='')
    if dry_run:
        target.unlink()
        return before, after, True

    masters.mkdir(parents=True, exist_ok=True)
    shutil.move(str(source), masters / source.name)
    return before, after, True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'directory',
        type=Path,
        help='Directory to convert, or the parent of --files.',
    )
    parser.add_argument(
        '--files',
        nargs='+',
        default=None,
        help='Convert only these names inside the directory. Use when a '
             'directory holds undeclared masters that must stay untouched.',
    )
    parser.add_argument(
        '--masters',
        type=Path,
        required=True,
        help='Where the PNG originals are moved to (must not be bundled).',
    )
    parser.add_argument('--quality', type=int, default=95)
    parser.add_argument(
        '--minimum-psnr',
        type=float,
        default=36.0,
        help='Refuse to write an encode worse than this against the master.',
    )
    parser.add_argument('--include-alpha', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--recursive', action='store_true')
    args = parser.parse_args()

    if args.files:
        sources = [args.directory / name for name in args.files]
        missing = [str(p) for p in sources if not p.exists()]
        if missing:
            raise SystemExit('Not found: ' + ', '.join(missing))
    else:
        pattern = '**/*.png' if args.recursive else '*.png'
        sources = sorted(args.directory.glob(pattern))

    total_before = total_after = 0
    converted = 0
    for source in sources:
        before, after, did = convert(
            source,
            args.masters,
            args.quality,
            args.minimum_psnr,
            args.include_alpha,
            args.dry_run,
        )
        total_before += before
        total_after += after
        if did:
            converted += 1
            print(f'{source.name:<32} {before/1024:8.0f} KB -> '
                  f'{after/1024:7.0f} KB')
        else:
            print(f'{source.name:<32} kept as PNG (transparency)')

    saved = total_before - total_after
    print(f'\n{converted} converted: {total_before/1048576:.1f} MB -> '
          f'{total_after/1048576:.1f} MB (saved {saved/1048576:.1f} MB)')
    if args.dry_run:
        print('Dry run: nothing was written or moved.')


if __name__ == '__main__':
    main()
