#!/usr/bin/env python3
"""Generate placeholder engraving-style card art for the generic themes.

These stand in for the real per-work illustrations (PRD "Illustrations":
a fallback set of ~12 generic engravings by theme). They are procedural:
parchment line hatching on ink, with at most one muted colour.

Writes Flutter resolution-aware variants:
    assets/packs/pack-001/images/<theme>.webp       (600x400, 1x)
    assets/packs/pack-001/images/2.0x/<theme>.webp  (1200x800, 2x)

Usage: python3 content/tools/placeholder_art.py [--pack 1]
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
W, H = 1200, 800
INK = (18, 21, 31)
LINE = (214, 201, 178)
AMBER = (232, 183, 106)
ROSE = (150, 52, 46)


def hatch(size, spacing=7, angle=35, width=1, jitter=1.2, seed=0):
    """A full-canvas layer of roughly parallel engraving lines."""
    rnd = random.Random(seed)
    img = Image.new("L", size, 0)
    d = ImageDraw.Draw(img)
    w, h = size
    diag = int(math.hypot(w, h))
    a = math.radians(angle)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    cx, cy = w / 2, h / 2
    for k in range(-diag, diag, spacing):
        pts = []
        for t in range(-diag, diag, 40):
            off = k + rnd.uniform(-jitter, jitter)
            pts.append((cx + dx * t + nx * off, cy + dy * t + ny * off))
        d.line(pts, fill=255, width=width)
    return img


def shade(canvas, mask, spacing=7, angle=35, colour=LINE, width=1, seed=0, strength=1.0):
    lines = hatch(canvas.size, spacing, angle, width, seed=seed)
    m = ImageChops.multiply(lines, mask)
    if strength < 1:
        m = m.point(lambda v: int(v * strength))
    canvas.paste(Image.new("RGB", canvas.size, colour), (0, 0), m)


def mask_from(draw_fn):
    m = Image.new("L", (W, H), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def stars(canvas, n, seed, y_max=H, colour=LINE):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(canvas)
    for _ in range(n):
        x, y = rnd.uniform(0, W), rnd.uniform(0, y_max)
        r = rnd.choice([1, 1, 1, 2, 2, 3])
        d.ellipse((x - r, y - r, x + r, y + r), fill=colour)


def moon(canvas, cx, cy, r, seed=1):
    glow = mask_from(lambda d: d.ellipse((cx - r * 1.8, cy - r * 1.8, cx + r * 1.8, cy + r * 1.8), fill=70))
    glow = glow.filter(ImageFilter.GaussianBlur(r * 0.6))
    canvas.paste(Image.new("RGB", canvas.size, LINE), (0, 0), glow)
    disc = mask_from(lambda d: d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255))
    canvas.paste(Image.new("RGB", canvas.size, (226, 214, 190)), (0, 0), disc)
    craters = mask_from(lambda d: [d.ellipse((cx + ox * r - s * r, cy + oy * r - s * r,
                                              cx + ox * r + s * r, cy + oy * r + s * r), fill=255)
                                   for ox, oy, s in [(-.3, -.2, .25), (.25, .3, .2), (.1, -.45, .12), (-.2, .4, .15)]])
    shade(canvas, craters, spacing=5, angle=-20, colour=(150, 140, 122), width=2, seed=seed)


def hills(canvas, base, amp, seed, spacing=6, angle=-12, fill_dark=True):
    rnd = random.Random(seed)
    phase = rnd.uniform(0, 6)
    pts = [(x, base - amp * (0.6 * math.sin(x / 210 + phase) + 0.4 * math.sin(x / 83 + phase * 2)))
           for x in range(0, W + 10, 10)]
    poly = pts + [(W, H), (0, H)]
    if fill_dark:
        ImageDraw.Draw(canvas).polygon(poly, fill=INK)
    m = mask_from(lambda d: d.polygon(poly, fill=255))
    shade(canvas, m, spacing=spacing, angle=angle, seed=seed, strength=0.75)
    ImageDraw.Draw(canvas).line(pts, fill=LINE, width=2)
    return pts


def tree(d, x, y, h, w):
    d.polygon([(x, y - h), (x - w, y), (x + w, y)], fill=INK, outline=LINE)
    for i in range(1, 7):
        yy = y - h + h * i / 7
        ww = w * i / 7
        d.line([(x - ww, yy), (x + ww * 0.6, yy - 6)], fill=LINE, width=1)


# --------------------------------------------------------------------------
# Themes
# --------------------------------------------------------------------------

def theme_moon_sea(c):
    stars(c, 120, 1, y_max=H * 0.5)
    moon(c, 820, 230, 95)
    clouds = mask_from(lambda d: [d.ellipse(b, fill=255) for b in
                                  [(420, 300, 760, 380), (560, 270, 900, 360), (850, 320, 1150, 390),
                                   (100, 200, 380, 260)]])
    shade(c, clouds, spacing=5, angle=0, seed=3, strength=0.6)
    d = ImageDraw.Draw(c)
    rnd = random.Random(4)
    for i, y in enumerate(range(470, H, 9)):
        gap = 6 + i * 0.8
        x = rnd.uniform(-40, 0)
        while x < W:
            seg = rnd.uniform(30, 110)
            near_moon = 1 - min(1, abs(x + seg / 2 - 820) / 260)
            col = tuple(int(LINE[k] * (0.45 + 0.55 * near_moon)) for k in range(3))
            d.line([(x, y + rnd.uniform(-1.5, 1.5)), (x + seg, y + rnd.uniform(-1.5, 1.5))], fill=col, width=2)
            x += seg + gap + rnd.uniform(0, 20)


def theme_road(c):
    stars(c, 40, 2, y_max=H * 0.3)
    moon(c, 1000, 140, 45)
    hills(c, 330, 70, 11, spacing=9, angle=-8)
    hills(c, 430, 60, 12, spacing=7, angle=-15)
    hills(c, 560, 50, 13, spacing=5, angle=-25)
    road = []
    for i in range(0, 101):
        t = i / 100
        y = 760 - t * 340
        x = 700 + 240 * math.sin(t * 5.2) * (1 - t) - 120 * t
        road.append((x, y, 140 * (1 - t) + 6))
    left = [(x - w / 2, y) for x, y, w in road]
    right = [(x + w / 2, y) for x, y, w in reversed(road)]
    d = ImageDraw.Draw(c)
    d.polygon(left + right, fill=(40, 40, 46))
    d.line(left, fill=LINE, width=2)
    d.line(list(reversed(right)), fill=LINE, width=2)
    for x in (180, 230, 1080):
        tree(d, x, 600, 230, 26)


def theme_rose(c):
    stars(c, 30, 5)
    d = ImageDraw.Draw(c)
    d.line([(900, 800), (860, 560), (880, 430)], fill=LINE, width=5)
    for lx, ly, s in [(820, 600, 1), (930, 650, -1), (850, 500, 1)]:
        leaf = mask_from(lambda m: m.ellipse((lx - 70, ly - 26, lx + 70, ly + 26), fill=255))
        leaf = leaf.rotate(30 * s, center=(lx, ly))
        c.paste(Image.new("RGB", c.size, INK), (0, 0), leaf)
        shade(c, leaf, spacing=6, angle=60 * s, seed=lx, strength=0.8)
    cx, cy = 880, 330
    for i in range(16, 0, -1):
        r = i * 11
        ang = i * 47
        petal = mask_from(lambda m: m.pieslice((cx - r, cy - r * .85, cx + r, cy + r * .85),
                                               ang, ang + 230, fill=255))
        col = tuple(int(ROSE[k] * (0.55 + 0.03 * (16 - i))) for k in range(3))
        c.paste(Image.new("RGB", c.size, col), (0, 0), petal)
        d.arc((cx - r, cy - r * .85, cx + r, cy + r * .85), ang, ang + 230, fill=(205, 150, 130), width=2)
    moon(c, 300, 180, 60)


def theme_bird(c):
    moon(c, 950, 200, 110)
    stars(c, 60, 6)
    d = ImageDraw.Draw(c)
    d.line([(300, 640), (700, 560), (1200, 600)], fill=LINE, width=7)
    d.line([(560, 585), (520, 500)], fill=LINE, width=4)
    body = mask_from(lambda m: m.ellipse((700, 400, 900, 540), fill=255))
    head = mask_from(lambda m: m.ellipse((850, 370, 940, 450), fill=255))
    tail = mask_from(lambda m: m.polygon([(710, 470), (560, 430), (590, 470), (720, 500)], fill=255))
    for m in (tail, body, head):
        c.paste(Image.new("RGB", c.size, INK), (0, 0), m)
        shade(c, m, spacing=5, angle=-30, seed=8)
    d.polygon([(935, 405), (975, 415), (935, 425)], fill=LINE)
    d.ellipse((892, 395, 904, 407), fill=AMBER)
    d.line([(780, 535), (770, 575)], fill=LINE, width=3)
    d.line([(820, 535), (820, 575)], fill=LINE, width=3)


def theme_city(c):
    stars(c, 90, 7, y_max=H * 0.45)
    moon(c, 260, 160, 60)
    rnd = random.Random(9)
    d = ImageDraw.Draw(c)
    x = 0
    while x < W:
        w = rnd.randint(70, 150)
        h = rnd.randint(200, 420)
        top = H - h
        d.rectangle((x, top, x + w, H), fill=INK, outline=LINE)
        if rnd.random() < .5:
            d.polygon([(x, top), (x + w / 2, top - 50), (x + w, top)], fill=INK, outline=LINE)
        m = mask_from(lambda mm: mm.rectangle((x, top, x + w, H), fill=255))
        shade(c, m, spacing=8, angle=90, seed=x, strength=0.35)
        for wy in range(top + 30, H - 20, 46):
            for wx in range(x + 14, x + w - 20, 32):
                if rnd.random() < .3:
                    d.rectangle((wx, wy, wx + 12, wy + 20), fill=AMBER)
        x += w + rnd.randint(0, 12)


def theme_candle(c):
    glow = mask_from(lambda d: d.ellipse((620, 80, 1060, 520), fill=120)).filter(ImageFilter.GaussianBlur(70))
    c.paste(Image.new("RGB", c.size, AMBER), (0, 0), glow)
    d = ImageDraw.Draw(c)
    body = mask_from(lambda m: m.rectangle((790, 330, 890, 680), fill=255))
    c.paste(Image.new("RGB", c.size, (60, 56, 52)), (0, 0), body)
    shade(c, body, spacing=5, angle=90, seed=11)
    d.line([(840, 330), (840, 300)], fill=LINE, width=3)
    d.ellipse((815, 210, 865, 305), fill=AMBER)
    d.ellipse((828, 250, 852, 300), fill=(250, 230, 190))
    d.ellipse((690, 660, 990, 720), fill=INK, outline=LINE, width=3)
    books = mask_from(lambda m: [m.rectangle(b, fill=255) for b in
                                 [(150, 600, 560, 650), (180, 650, 600, 700), (130, 700, 620, 760)]])
    c.paste(Image.new("RGB", c.size, INK), (0, 0), books)
    shade(c, books, spacing=4, angle=0, seed=12)


def theme_night_sky(c):
    rnd = random.Random(13)
    stars(c, 260, 13, y_max=H * 0.75)
    band = mask_from(lambda d: d.polygon([(0, 500), (400, 250), (1200, 0), (1200, 180), (500, 420), (0, 650)], fill=90))
    band = band.filter(ImageFilter.GaussianBlur(40))
    c.paste(Image.new("RGB", c.size, LINE), (0, 0), band)
    d = ImageDraw.Draw(c)
    pts = [(820, 120), (880, 200), (960, 230), (1020, 320), (980, 400), (900, 380)]
    d.line(pts, fill=AMBER, width=2)
    for x, y in pts:
        d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=AMBER)
    hills(c, 650, 60, 14, spacing=6, angle=-10)
    for x in (120, 160, 1050):
        tree(d, x, 700, 160 + rnd.randint(0, 40), 20)


def theme_garden(c):
    stars(c, 25, 15, y_max=H * 0.3)
    hills(c, 520, 30, 16, spacing=8, angle=-5)
    d = ImageDraw.Draw(c)
    rnd = random.Random(17)
    for _ in range(26):
        x = rnd.uniform(380, 1200)
        base = rnd.uniform(620, 800)
        top = base - rnd.uniform(120, 260)
        d.line([(x, base), (x + rnd.uniform(-20, 20), top)], fill=LINE, width=2)
        r = rnd.uniform(14, 30)
        col = ROSE if rnd.random() < .25 else LINE
        flower = mask_from(lambda m: m.ellipse((x - r, top - r, x + r, top + r), fill=255))
        c.paste(Image.new("RGB", c.size, INK), (0, 0), flower)
        shade(c, flower, spacing=4, angle=rnd.uniform(0, 180), colour=col, seed=int(x), width=2)
    moon(c, 980, 150, 50)


def theme_forest(c):
    stars(c, 50, 18, y_max=H * 0.35)
    moon(c, 300, 130, 55)
    rnd = random.Random(19)
    d = ImageDraw.Draw(c)
    for layer, (base, hmin, hmax, wscale) in enumerate([(520, 140, 200, 18), (640, 200, 300, 26), (800, 280, 420, 38)]):
        x = rnd.uniform(-40, 40)
        while x < W + 40:
            if x > 360 or layer == 2:
                tree(d, x, base, rnd.uniform(hmin, hmax), wscale)
            x += wscale * rnd.uniform(1.4, 2.6)


def theme_tea(c):
    stars(c, 30, 20)
    d = ImageDraw.Draw(c)
    cup = mask_from(lambda m: m.chord((640, 300, 1080, 760), 0, 180, fill=255))
    c.paste(Image.new("RGB", c.size, INK), (0, 0), cup)
    shade(c, cup, spacing=5, angle=-40, seed=21)
    d.chord((640, 300, 1080, 760), 0, 180, outline=LINE, width=3)
    d.ellipse((640, 500, 1080, 560), fill=(70, 60, 40), outline=LINE, width=3)
    d.ellipse((560, 700, 1160, 780), outline=LINE, width=3)
    for k, x0 in enumerate((760, 850, 940)):
        pts = [(x0 + 30 * math.sin(t / 22 + k), 480 - t) for t in range(0, 300, 6)]
        d.line(pts, fill=(170, 160, 140), width=2)
    branch = [(80, 160), (300, 220), (420, 200), (520, 260)]
    d.line(branch, fill=LINE, width=4)
    for x, y in branch[1:]:
        d.ellipse((x - 14, y - 14, x + 14, y + 14), fill=ROSE)


THEMES = {
    "moon-sea": theme_moon_sea,
    "road": theme_road,
    "rose": theme_rose,
    "bird": theme_bird,
    "city": theme_city,
    "candle": theme_candle,
    "night-sky": theme_night_sky,
    "garden": theme_garden,
    "forest": theme_forest,
    "tea": theme_tea,
}


def render(name: str) -> Image.Image:
    c = Image.new("RGB", (W, H), INK)
    THEMES[name](c)
    grain = Image.effect_noise((W, H), 18).convert("L")
    c = Image.blend(c, Image.merge("RGB", (grain,) * 3), 0.04)
    return c


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pack", type=int, default=1)
    a = ap.parse_args()
    out = ROOT / "assets" / "packs" / f"pack-{a.pack:03d}" / "images"
    (out / "2.0x").mkdir(parents=True, exist_ok=True)
    for name in THEMES:
        img = render(name)
        img.save(out / "2.0x" / f"{name}.webp", "WEBP", quality=72, method=6)
        img.resize((W // 2, H // 2), Image.LANCZOS).save(out / f"{name}.webp", "WEBP", quality=78, method=6)
        print("wrote", name)


if __name__ == "__main__":
    main()
