#!/usr/bin/env python3
"""Put raw app screenshots into phone frames, side by side, for the README.

    flutter test test/screenshots --dart-define=SCREENSHOTS=true
    python3 tool/frame_screenshots.py

Reads docs/screenshots/<name>.png (1179x2556) and writes
docs/screenshots/hero.png and docs/screenshots/more.png.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / "docs" / "screenshots"
FONT = ROOT / "assets" / "fonts" / "Newsreader-Medium.ttf"

SCALE = 0.42  # screenshot scale inside the frame
BEZEL = 18
BG = (34, 35, 39)


def status_bar(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    w = img.width
    # dark glyphs on light reader themes (Sepia, Paper)
    light_bg = sum(img.getpixel((40, 40))) > 450
    fg = (34, 30, 26) if light_bg else (239, 230, 214)
    font = ImageFont.truetype(str(FONT), 46)
    d.text((150, 84), "9:41", font=font, fill=fg, anchor="mm")
    # dynamic island
    d.rounded_rectangle((w / 2 - 190, 36, w / 2 + 190, 140), radius=52, fill=(0, 0, 0))
    # signal, wifi, battery (simple)
    x = w - 300
    for i, h in enumerate((14, 20, 26, 32)):
        d.rounded_rectangle((x + i * 14, 100 - h, x + i * 14 + 9, 100), radius=2, fill=fg)
    d.pieslice((w - 222, 64, w - 168, 118), 225, 315, fill=fg)
    d.rounded_rectangle((w - 150, 70, w - 76, 104), radius=9, outline=fg, width=3)
    d.rounded_rectangle((w - 145, 75, w - 81, 99), radius=6, fill=fg)
    # home indicator
    d.rounded_rectangle((w / 2 - 210, img.height - 32, w / 2 + 210, img.height - 20), radius=6, fill=fg)


def framed(name: str) -> Image.Image:
    shot = Image.open(SHOTS / f"{name}.png").convert("RGB")
    status_bar(shot)
    shot = shot.resize((int(shot.width * SCALE), int(shot.height * SCALE)), Image.LANCZOS)
    w, h = shot.width + BEZEL * 2, shot.height + BEZEL * 2
    frame = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=78, fill=(12, 12, 14), outline=(70, 70, 76), width=3)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width - 1, shot.height - 1), radius=62, fill=255)
    frame.paste(shot, (BEZEL, BEZEL), mask)
    return frame


def sheet(names: list[str], out: str) -> None:
    frames = [framed(n) for n in names]
    gap, pad = 40, 50
    w = sum(f.width for f in frames) + gap * (len(frames) - 1) + pad * 2
    h = max(f.height for f in frames) + pad * 2
    img = Image.new("RGB", (w, h), BG)
    x = pad
    for f in frames:
        img.paste(f, (x, pad), f)
        x += f.width + gap
    img.save(SHOTS / out, optimize=True)
    print("wrote", SHOTS / out)


if __name__ == "__main__":
    sheet(["tonight", "reader", "journey"], "hero.png")
    sheet(["tonight-progress", "night-complete", "library", "reader-poem-sepia"], "more.png")
