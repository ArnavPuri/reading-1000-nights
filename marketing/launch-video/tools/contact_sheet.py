#!/usr/bin/env python3
"""contact_sheet.py OUT.png frame1.png frame2.png ...  — 4-across sheet with time labels
and the 9:16 platform-UI unsafe zones (top 220 / bottom 380) tinted for review."""
import re
import sys

from PIL import Image, ImageDraw

out, files = sys.argv[1], sys.argv[2:]
ims = [Image.open(f).convert("RGB") for f in files]
w0, h0 = ims[0].size
portrait = h0 > w0
scale = 300 / w0 if portrait else 480 / w0
tw, th = int(w0 * scale), int(h0 * scale)
cols = 6 if portrait else 3
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (cols * (tw + 10) + 10, rows * (th + 34) + 10), (40, 40, 44))
d = ImageDraw.Draw(sheet)
for i, (im, f) in enumerate(zip(ims, files)):
    x, y = 10 + (i % cols) * (tw + 10), 10 + (i // cols) * (th + 34)
    t = im.resize((tw, th), Image.LANCZOS)
    if portrait and h0 == 1920:
        ov = Image.new("RGBA", t.size, (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        od.rectangle((0, 0, tw, int(220 * scale)), fill=(255, 0, 0, 40))
        od.rectangle((0, th - int(380 * scale), tw, th), fill=(255, 0, 0, 40))
        t = Image.alpha_composite(t.convert("RGBA"), ov).convert("RGB")
    sheet.paste(t, (x, y))
    m = re.search(r"_t([\d.]+)\.png", f)
    d.text((x, y + th + 6), f"t={m.group(1) if m else i}s", fill=(220, 220, 220))
sheet.save(out)
print("wrote", out)
