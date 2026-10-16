# 1000 Nights launch film

| File | What |
|---|---|
| `1000-nights-launch-9x16.mp4` | Hero cut, 1080×1920, 30 fps, 39.5 s (Reels / TikTok / Shorts / Stories) |
| `1000-nights-launch-16x9.mp4` | Landscape restage, 1920×1080, 30 fps, 39.5 s (YouTube / X / website) |
| `1000-nights-teaser-1x1.mp4` | Seamless 7 s loop, 1080×1080 |
| `poster-9x16.png`, `poster-16x9.png` | End-card frame of each cut |
| `STORYBOARD.md` | Concept, shot list, animation principles, motion/type/colour spec, sound cue sheet |
| `src/index.html`, `src/comp.js` | The composition: one canvas, `window.renderFrame(t)` is a pure function of time |
| `render.mjs` | Steps t = frame/30 in headless Chromium, captures PNGs to scratch, encodes with ffmpeg |
| `tools/prep_assets.py` | Derives the "unlit" helper images in `derived/` from the real app assets |
| `tools/synth_audio.py` | Synthesises the quiet ambient bed from the composition's cue list (no samples) |
| `tools/contact_sheet.py` | Contact sheets for review |

## Re-render everything

```sh
python3 marketing/launch-video/tools/prep_assets.py && node marketing/launch-video/render.mjs
```

Run this from the repo root. It needs Node 22 with Playwright (a global install under `/opt/node22/lib/node_modules` is
picked up automatically), Python 3 with Pillow and numpy, and ffmpeg. Frames are written to `$FRAMES_DIR`, which
defaults to the session scratchpad (`…/scratchpad/video-frames/<fmt>/`), never to the repo. Rendering takes about 6–8
minutes per long cut on 4 cores.

Useful flags:

```sh
node marketing/launch-video/render.mjs --fmt 16x9            # one cut (9x16 | 16x9 | 1x1, comma-separated)
node marketing/launch-video/render.mjs --fmt 9x16 --contact  # 12-frame contact sheet in the scratchpad
node marketing/launch-video/render.mjs --fmt 9x16 --stills 1.3,4.2,30   # single frames
node marketing/launch-video/render.mjs --no-audio            # silent encode
```

To preview interactively, serve the repo root (for example `npx http-server -p 8080`) and open
`/marketing/launch-video/src/index.html?fmt=9x16&t=12.5`, or add `&play=1` for a realtime preview with a scrubber.
The realtime preview is the only place the wall clock is used. Rendering never uses it.

Encoding is H.264 High@4.2, CRF 18 (17 for the teaser), `-preset slow -tune film`, yuv420p with BT.709 tags,
`+faststart`, and AAC 160 kbps for the bed. To ship silent, use `ffmpeg -i in.mp4 -c copy -an out.mp4`.
