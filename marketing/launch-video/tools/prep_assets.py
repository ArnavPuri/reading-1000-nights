#!/usr/bin/env python3
"""Derive the few helper images the composition needs from the real app assets.

Everything here is a deterministic transform of files already in the repo:
  * icon-unlit.png / icon-flame.png  - the app icon with its flame removed, and
    the flame + halo as an additive sprite (so the comp can light and flicker it)
  * nc-unlit.png / nc-flame.png      - same split for the Night-complete candle
  * nc-dots-unlit.png                - the week dots, unlit (grey) for sequential lighting
  * journey-unlit.png                - the constellation with its 7 lit stars dimmed
  * reader-noribbon.png              - reader screenshot without the progress ribbon
Run:  python3 marketing/launch-video/tools/prep_assets.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parents[1] / "derived"
SHOTS = ROOT / "docs" / "screenshots"
APP_BG = np.array([18, 21, 31])


def load(p):
    return np.array(Image.open(p).convert("RGB")).astype(np.float32)


def save(a, name):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(OUT / name, optimize=True)
    print("wrote", OUT / name)


def icon():
    a = load(ROOT / "assets/branding/app-icon-1024.png")
    bg = np.array([15, 19, 29], np.float32)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    # flame + halo ellipse, above the candle's wax rim
    ell = ((xx - 512) / 132.0) ** 2 + ((yy - 250) / 134.0) ** 2 <= 1.0
    lum = a.mean(axis=2)
    # what to remove: inside the halo ellipse, everything that is not wax
    cut = np.zeros((h, w), bool)
    wax = (xx >= 472) & (xx <= 550)
    edge = ((xx >= 466) & (xx < 472)) | ((xx > 550) & (xx <= 555))
    cut |= wax & (yy < 334)
    cut |= wax & (yy >= 334) & (yy < 346) & (lum < 90)
    cut |= edge & (yy < 341)
    cut |= ~wax & ~edge
    mask = ell & cut
    unlit = a.copy()
    unlit[mask] = bg
    # a cold, charred wick standing out of the wax
    unlit[310:338, 509:512] = np.array([52, 44, 38], np.float32)
    unlit[310:313, 509:512] = np.array([30, 26, 24], np.float32)
    save(unlit, "icon-unlit.png")
    x0, y0, x1, y1 = 370, 105, 654, 385
    flame = np.clip(a[y0:y1, x0:x1] - unlit[y0:y1, x0:x1], 0, 255)
    save(flame, "icon-flame.png")


def night_complete():
    a = load(SHOTS / "night-complete.png")
    x0, y0, x1, y1 = 290, 330, 890, 960
    crop = a[y0:y1, x0:x1].copy()
    h, w = crop.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    X, Y = xx + x0, yy + y0
    body = (X >= 544) & (X <= 636) & (Y >= 694) & (Y <= 906)
    unlit = crop.copy()
    unlit[~body] = APP_BG
    # cool the wax a touch: an unlit candle is not glowing
    unlit[body] = APP_BG + (crop[body] - APP_BG) * 0.78
    save(unlit, "nc-unlit.png")
    save(np.clip(crop - unlit, 0, 255), "nc-flame.png")
    # week dots: grey, dim
    d = a[1720:1775, 150:1030].copy()
    lum = d.mean(axis=2, keepdims=True)
    warm = np.clip((d[..., :1] - d[..., 2:3]) / 120.0, 0, 1)
    grey = APP_BG + (lum - APP_BG.mean()) * 0.32
    save(d * (1 - warm) + grey * warm, "nc-dots-unlit.png")


def journey():
    a = load(SHOTS / "journey.png")
    x0, y0, x1, y1 = 100, 860, 700, 1400
    c = a[y0:y1, x0:x1].copy()
    warm = np.clip((c[..., 0] - c[..., 2] + 10) / 25.0, 0, 1)[..., None]
    lum = c.mean(axis=2, keepdims=True)
    base = np.array([22, 24, 34], np.float32)
    dim = base + np.clip(lum - 40, 0, 255) * np.array([0.30, 0.31, 0.36], np.float32)
    save(c * (1 - warm) + dim * warm, "journey-unlit.png")


def reader():
    a = load(SHOTS / "reader.png")
    a[300:, 1118:1144] = APP_BG
    save(a, "reader-noribbon.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    icon()
    night_complete()
    journey()
    reader()
