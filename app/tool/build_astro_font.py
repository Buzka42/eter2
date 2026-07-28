"""Rebuild `assets/fonts/EterAstro.ttf`.

The astrological glyphs are not in Cormorant or Inter, and hand-drawing them as
paths does not converge — every correction is another guess. They come instead
from Google's Noto, subset to exactly the codepoints Eter draws and merged into
one 5.5 KB face.

Two sources are needed because the block is split across them: Noto Sans
Symbols carries the Moon, the planets and all twelve signs, and only Noto Sans
Symbols 2 carries the Sun at U+2609.

Both are SIL Open Font License 1.1, which permits subsetting, merging and
redistribution with the software. See assets/fonts/EterAstro.LICENSE.txt.

Run from `app/`:  python tool/build_astro_font.py
"""

import os
import tempfile
import urllib.request

from fontTools.merge import Merger
from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SYMBOLS = (
    'https://github.com/google/fonts/raw/main/ofl/notosanssymbols/'
    'NotoSansSymbols%5Bwght%5D.ttf'
)
SYMBOLS_2 = (
    'https://github.com/google/fonts/raw/main/ofl/notosanssymbols2/'
    'NotoSansSymbols2-Regular.ttf'
)

# Moon and planets, then the twelve signs. The Sun is fetched separately.
FROM_SYMBOLS = [0x263D, 0x263F, 0x2640, 0x2642, 0x2643, 0x2644, 0x2645,
                0x2646, 0x2647] + list(range(0x2648, 0x2654))
FROM_SYMBOLS_2 = [0x2609]

OUT = 'assets/fonts/EterAstro.ttf'


def subset(path: str, codepoints: list[int], out: str) -> str:
    font = TTFont(path)
    if 'fvar' in font:
        # Pin the variable axis: the app uses one weight and a variable font
        # would carry the whole design space for no benefit.
        font = instancer.instantiateVariableFont(font, {'wght': 400})
    options = Options()
    options.layout_features = []
    options.name_IDs = ['*']
    options.drop_tables += ['DSIG']
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)
    font.save(out)
    return out


def main() -> None:
    with tempfile.TemporaryDirectory() as work:
        parts = []
        for url, codepoints, name in [
            (SYMBOLS, FROM_SYMBOLS, 'symbols'),
            (SYMBOLS_2, FROM_SYMBOLS_2, 'symbols2'),
        ]:
            source = os.path.join(work, f'{name}.ttf')
            urllib.request.urlretrieve(url, source)
            parts.append(subset(source, codepoints,
                                os.path.join(work, f'{name}-subset.ttf')))
        Merger().merge(parts).save(OUT)

    expected = FROM_SYMBOLS + FROM_SYMBOLS_2
    cmap = TTFont(OUT, lazy=True).getBestCmap()
    missing = [hex(c) for c in expected if c not in cmap]
    if missing:
        raise SystemExit(f'{OUT} is missing {missing}')
    print(f'{OUT}: {len(expected)} glyphs, '
          f'{os.path.getsize(OUT) / 1024:.1f} KB')


if __name__ == '__main__':
    main()
