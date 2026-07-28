"""Render the launcher icon from the shell header's own vocabulary.

The icon is not separate art: it is the ETER signature as
`features/shell/shell_header.dart` paints it in the night register — a
graduated arc with struck degree ticks, a solar mark at one end and a lunar
mark at the other, the wordmark in Cormorant Garamond Medium on a wide
letterspacing, and the plumb-and-star colophon beneath. Same ground, same
gold, same face.

What changes is proportion, and only because a launcher icon is a square that
gets masked and shrunk to 48 dp. The header is a 300x72 band; laying that band
literally into a square leaves it a thin stripe in an empty field, and the
graduations disappear at small sizes. So the same elements are re-proportioned
for a square: the arc spans less width, the wordmark is much larger relative
to it, and the colophon sits closer. Everything is drawn oversized and
downsampled, because PIL has no analytic antialiasing for hairlines.

Run from `app/`:  python tool/render_app_icon.py
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersampling factor
SIZE = 1024

GROUND = (4, 22, 46)
# aura500 as the night header flattens it over the ground, plus a slightly
# brighter value for the two solid marks so they hold at small sizes.
GOLD = (150, 129, 90)
GOLD_BRIGHT = (183, 156, 105)
INK = (233, 239, 247)

# Every figure below is a fraction of the icon's width.
ARC_SPAN = 0.60          # end to end of the graduated arc
ARC_RISE = 0.085         # how far its apex lifts above its ends
ARC_Y = 0.335            # the arc's ends
WORD_SIZE = 0.165
WORD_TRACKING = 0.058
WORD_Y = 0.545           # optical centre of the wordmark
COLOPHON_TOP = 0.70
COLOPHON_BOTTOM = 0.775
STAR_Y = 0.815
STAR_R = 0.032


def render(path: str) -> None:
    px = SIZE * SS
    image = Image.new("RGB", (px, px), GROUND)
    draw = ImageDraw.Draw(image)

    def u(fraction: float) -> float:
        return fraction * px

    stroke = max(1, round(u(0.0055)))
    hairline = max(1, round(u(0.0035)))

    # --- the graduated arc
    left = (u(0.5 - ARC_SPAN / 2), u(ARC_Y))
    right = (u(0.5 + ARC_SPAN / 2), u(ARC_Y))
    control = (u(0.5), u(ARC_Y - ARC_RISE * 2))
    # The arc stops short of the two marks rather than running into them.
    inset = u(0.045)
    arc_left = (left[0] + inset, left[1] - u(0.008))
    arc_right = (right[0] - inset, right[1] - u(0.008))

    def bezier(p0, p1, p2, steps=600):
        return [
            (
                (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1],
            )
            for t in (i / steps for i in range(steps + 1))
        ]

    arc = bezier(arc_left, control, arc_right)
    draw.line(arc, fill=GOLD, width=stroke, joint="curve")

    # --- graduations struck outward from the arc
    for i in range(1, 12):
        index = round(i / 12 * (len(arc) - 1))
        pointer = arc[index]
        before = arc[max(index - 4, 0)]
        after = arc[min(index + 4, len(arc) - 1)]
        tangent = (after[0] - before[0], after[1] - before[1])
        length = math.hypot(*tangent) or 1
        normal = (tangent[1] / length, -tangent[0] / length)
        reach = u(0.030 if i % 3 == 0 else 0.017)
        draw.line(
            [
                pointer,
                (pointer[0] + normal[0] * reach, pointer[1] + normal[1] * reach),
            ],
            fill=GOLD,
            width=hairline,
        )

    # --- solar mark at the arc's left end
    r = u(0.021)
    draw.ellipse(
        [left[0] - r, left[1] - r, left[0] + r, left[1] + r],
        outline=GOLD,
        width=stroke,
    )
    for i in range(8):
        angle = i * math.pi / 4
        draw.line(
            [
                (left[0] + math.cos(angle) * r * 1.55,
                 left[1] + math.sin(angle) * r * 1.55),
                (left[0] + math.cos(angle) * r * 2.25,
                 left[1] + math.sin(angle) * r * 2.25),
            ],
            fill=GOLD,
            width=hairline,
        )

    # --- lunar mark at the right end. Filled rather than stroked: a hairline
    # crescent does not survive a 48 dp launcher.
    outer = u(0.026)
    inner = u(0.0225)
    draw.ellipse(
        [right[0] - outer, right[1] - outer, right[0] + outer, right[1] + outer],
        fill=GOLD_BRIGHT,
    )
    cut = (right[0] + u(0.012), right[1] - u(0.004))
    draw.ellipse(
        [cut[0] - inner, cut[1] - inner, cut[0] + inner, cut[1] + inner],
        fill=GROUND,
    )

    # --- the wordmark, in the shell's own face and letterspacing
    font = ImageFont.truetype(
        "assets/fonts/CormorantGaramond-Medium.ttf", round(u(WORD_SIZE))
    )
    tracking = u(WORD_TRACKING)
    letters = "ETER"
    widths = [draw.textlength(ch, font=font) for ch in letters]
    total = sum(widths) + tracking * (len(letters) - 1)
    x = px / 2 - total / 2
    for ch, width in zip(letters, widths):
        draw.text((x, u(WORD_Y)), ch, font=font, fill=INK, anchor="lm")
        x += width + tracking

    # --- colophon: plumb line, compass star, centre bead
    draw.line(
        [(px / 2, u(COLOPHON_TOP)), (px / 2, u(COLOPHON_BOTTOM))],
        fill=GOLD,
        width=stroke,
    )
    star = (px / 2, u(STAR_Y))
    for rotation in (0.0, math.pi / 4):
        draw.polygon(
            [
                (star[0] + math.cos(rotation + i * math.pi / 2) * u(STAR_R),
                 star[1] + math.sin(rotation + i * math.pi / 2) * u(STAR_R))
                for i in range(4)
            ],
            outline=GOLD,
            width=stroke,
        )
    bead = u(0.006)
    draw.ellipse(
        [star[0] - bead, star[1] - bead, star[0] + bead, star[1] + bead],
        fill=GOLD_BRIGHT,
    )

    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.resize((SIZE, SIZE), Image.LANCZOS).save(path)
    print("wrote", path)


def emit_platform_icons(master: Image.Image) -> None:
    """Write every launcher size both platforms declare, from one master."""
    import json

    # iOS wants opaque squares at each declared size.
    appicon = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    manifest = json.load(open(os.path.join(appicon, "Contents.json")))
    for image in manifest["images"]:
        name = image.get("filename")
        if not name:
            continue
        side = round(
            float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x"))
        )
        master.resize((side, side), Image.LANCZOS).save(os.path.join(appicon, name))

    # Android legacy square launcher.
    for folder, side in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                         ("xxhdpi", 144), ("xxxhdpi", 192)]:
        path = f"android/app/src/main/res/mipmap-{folder}"
        os.makedirs(path, exist_ok=True)
        master.resize((side, side), Image.LANCZOS).save(f"{path}/ic_launcher.png")

    # Android adaptive foreground: the same mark, keyed off its ground and
    # held inside the 66% safe zone so no launcher mask shape clips it.
    import numpy as np

    array = np.asarray(master.convert("RGB")).astype(np.float32)
    distance = np.linalg.norm(array - np.array(GROUND, dtype=np.float32), axis=-1)
    alpha = np.clip((distance - 6) / 22, 0, 1)
    keyed = Image.fromarray(
        np.dstack([array.astype(np.uint8), (alpha * 255).astype(np.uint8)]), "RGBA"
    )
    keyed = keyed.crop(keyed.getbbox())
    for folder, side in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                         ("xxhdpi", 324), ("xxxhdpi", 432)]:
        safe = round(side * 0.62)
        scaled = keyed.copy()
        scaled.thumbnail((safe, safe), Image.LANCZOS)
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(
            scaled,
            ((side - scaled.width) // 2, (side - scaled.height) // 2),
            scaled,
        )
        path = f"android/app/src/main/res/mipmap-{folder}"
        canvas.save(f"{path}/ic_launcher_foreground.png")
    print("platform icons written")


if __name__ == "__main__":
    master_path = "../assets/review/app-icon-signature.png"
    render(master_path)
    emit_platform_icons(Image.open(master_path).convert("RGB"))
