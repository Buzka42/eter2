"""Assemble the UI inventory into reviewable contact sheets.

`test_capture/ui_inventory_test.dart` writes one PNG per surface and state to
`artifacts/ui/`. This groups them the way a review actually proceeds — by
journey, not alphabetically — and labels each frame with its capture name so a
note can point at something unambiguously.

Run from `app/`, after refreshing the inventory:

    flutter test test_capture --update-goldens
    python tool/build_contact_sheets.py
"""

import os

from PIL import Image, ImageDraw, ImageFont

SRC = "../artifacts/ui"
OUT = "../artifacts/sheets"
THUMB_W = 300

SHEETS: dict[str, list[str]] = {
    "1-arrival": [
        "onboarding-1", "onboarding-2", "onboarding-3",
        "empty-dashboard-day", "empty-journal-day", "empty-body-day",
    ],
    "2-resting": [
        "dashboard-resting-day", "dashboard-resting-night",
        "chooser-day", "chooser-night",
        "guidance-day", "guidance-night",
    ],
    "3-journal": [
        "journal-day", "journal-night",
        "journal-earlier-day",
        "whole-journal-day",
    ],
    "4-body": [
        "body-1-day", "body-2-day", "body-3-day",
        "body-1-night", "body-2-night", "body-3-night",
    ],
    "5-capture": [
        "capture-activity", "capture-meal", "capture-strength",
        "vessel-top-day", "vessel-readings-day", "vessel-top-night",
    ],
    "6-sanctum": [
        "sanctum-1-day", "sanctum-2-day", "sanctum-3-day",
        "sanctum-1-night", "sanctum-2-night", "sanctum-3-night",
    ],
    "7-stress": ["stress-dashboard-320-200", "stress-body-320-200"],
    "8-whole": [
        "whole-body-day", "whole-body-night",
        "whole-vessel-day", "whole-vessel-night",
        "whole-sanctum-day", "whole-sanctum-night",
    ],
    "9-whole-capture": [
        "whole-capture-activity", "whole-capture-meal",
        "whole-capture-strength", "whole-onboarding-2",
    ],
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    font = ImageFont.truetype("assets/fonts/Inter-Medium.ttf", 15)

    for name, keys in SHEETS.items():
        frames = []
        for key in keys:
            path = os.path.join(SRC, f"{key}.png")
            if not os.path.exists(path):
                print("missing:", key)
                continue
            image = Image.open(path).convert("RGB")
            height = round(image.height * THUMB_W / image.width)
            frames.append((key, image.resize((THUMB_W, height), Image.LANCZOS)))
        if not frames:
            continue

        columns = min(3, len(frames))
        rows = (len(frames) + columns - 1) // columns
        cell = max(image.height for _, image in frames) + 34
        sheet = Image.new(
            "RGB",
            (columns * (THUMB_W + 16) + 16, rows * (cell + 16) + 16),
            (18, 18, 22),
        )
        draw = ImageDraw.Draw(sheet)
        for index, (key, image) in enumerate(frames):
            column, row = index % columns, index // columns
            x = 16 + column * (THUMB_W + 16)
            y = 16 + row * (cell + 16)
            draw.text((x, y), key, font=font, fill=(210, 210, 215))
            sheet.paste(image, (x, y + 24))
        sheet.save(os.path.join(OUT, f"{name}.png"))
        print("wrote", name, sheet.size)


if __name__ == "__main__":
    main()
