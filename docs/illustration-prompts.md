# Illustration prompt pack

Oct 14, 2026 · for the card engravings (PRD: Design system → Illustrations; Pipeline step 6)

This is the brief for every card illustration in 1000 Nights. It locks one style, gives a prompt template for the main image models, and has ready-to-paste prompts for the 12 generic theme engravings and the 21 pieces in nights 1 to 7.

The approved direction is the card art in `docs/mockups/approved-mockups.webp`: a fine engraving on near-black ink, bleeding off the right side of a dark card under a fade. The current files in `assets/packs/pack-001/images/` are procedural placeholders from `content/tools/placeholder_art.py`. These prompts replace them.

## 1. Style lock

### Master style

Every image is a 19th-century steel or wood engraving, printed in reverse: fine, warm parchment lines on a deep ink-navy ground, as if a plate from a Victorian illustrated edition were printed in light ink on dark paper. All tone comes from line: cross-hatching, parallel shading and stipple. There are no washes, no soft gradients and no photographic light. The mood is night or dusk, still and quiet. The image is monochrome, with at most one small, muted amber accent for a single source of light or meaning: a flame, a lit window, a low sun. The subject sits right of centre with space around it, and the left third is dark, empty ground that melts into the card. No text, letters, borders, frames or signatures, ever.

### Palette

| Role | Colour | Rule |
| --- | --- | --- |
| Ground | ink #12151F, up to about #1B1F2B in the hatched mid-tones | Most of the image. The left third stays at this value. |
| Linework | parchment #EFE6D6, down to about #D6C9B2 in fine lines | All drawing. Brightest highlights only on the focal point. |
| Accent (optional) | amber #E8B76A, muted | One accent per image, under 5% of the area, only where the prompt names it. Many images have none. |

Nothing else. No blue skies, no green leaves, no red. Image models do not follow hex codes reliably, so the prompts describe the colours in words ("parchment-cream", "ink-navy, almost black", "muted candle-amber"). Check the result against the hex values in review.

**The red rose.** The approved mockup and the current `rose` placeholder show a muted red rose. The lock above is amber only, so the prompts draw roses in parchment line. If the team wants the mockup's red rose on the Nightingale card, treat a muted rose-red (about #8E3B36) as a single named exception for that one image, write it in the log (section 5), and never put red and amber in the same image.

### Medium

- 19th-century steel engraving or white-line wood engraving. Think of a Bewick vignette or a Doré plate, reversed.
- Fine, even line weight. Cross-hatching for shadow, parallel lines for sky and water, stipple for texture.
- Crisp at 100%. Lines must survive downscaling to 600×400 without turning to mush, so avoid ultra-fine noise.
- No painterly blobs, airbrush gradients, glow effects beyond a hatched halo, or 3D-render shading.

### How the card crops the image

`lib/features/tonight/reading_card.dart` places the image in a 260 pt wide box on the right of the card, `BoxFit.cover`, aligned `centerRight`. A dark gradient covers the card from the left. On a 393 pt wide phone (card about 353 pt wide, minimum 186 pt tall), that works out like this, measured across the image's width:

| Image x | What the reader sees |
| --- | --- |
| 0 to 21% | Fully under the card colour. Invisible. |
| 21 to 59% | Fade from 100% to 60% cover. Barely visible. |
| 59 to 100% | Fade from 60% cover to clear. This is where the art reads. |

Other facts that shape composition:

- **Height is never cropped.** The card is at least 186 pt tall and the image is 3:2, so the image always fits the card height.
- **The left edge gets cropped on taller cards.** With a long title or large Dynamic Type the card grows, the image scales up, and the extra width is cut from the left. At 240 pt tall, the left 28% is gone. The right edge is always kept.
- **The top-right corner holds the done badge.** A finished card shows a 26 pt amber check about 85 to 94% across and 9 to 23% down. A finished card also dims to 55% opacity.
- **The card has 20 pt rounded corners** that clip the top-right and bottom-right corners.

### How the share card crops the image

Share cards are planned (see the `share_card_*` analytics events) but not built. Assume a 4:5 portrait card (1080×1350) with the art filling the card from the top and the pull quote over a fade in the lower third. A 3:2 image fitted to 4:5 at full height keeps only 53% of its width. A dead-centre crop keeps x 23 to 77%.

So the subject must be centred enough to survive a centred 4:5 crop, while still sitting right of centre for the card. The safe zone below does both. When the share card is built, crop with `Alignment(0.5, -1)`: the window then covers x 35 to 89%, centred on the focal point.

### Composition rules

Measured on the 1800×1200 master:

| Zone | Where | Rule |
| --- | --- | --- |
| Focal point | about (66%, 40%), around (1190, 480) px | The single most important detail: the bird's head, the flame, the lit window. |
| Essential subject | x 48 to 80%, y 10 to 65% (864 to 1440, 120 to 780 px) | Everything that must be seen. Survives the card fade, the left crop and a centred 4:5 crop. |
| Left third | x 0 to 33% (0 to 600 px) | Dark, low-contrast ground: sky, water, shadow, faint hatching. No objects, no bright lines. |
| Badge corner | x over 84%, y under 24% | Nothing important. A moon or star here is fine only if it is not the focal point. |
| Bottom fifth | y over 80% | Quiet ground. It sits under the share-card quote. |
| Edges | 5% margin all round | Nothing essential touches an edge. |

Also:

- Aspect ratio is 3:2, landscape.
- One subject, not a scene with three centres of interest. The card is small.
- People are small, seen from behind or in silhouette. No faces in close-up.
- No text, letters, numbers, pseudo-lettering, borders, frames, cartouches, signatures or monograms.

### Deliverables

| File | Spec | Location |
| --- | --- | --- |
| Master | 1800×1200 or larger, exactly 3:2, PNG, sRGB | Outside the app bundle (see section 5) |
| 2x | 1200×800 WebP, quality 72, method 6 | `assets/packs/pack-001/images/2.0x/<name>.webp` |
| 1x | 600×400 WebP, quality 78, method 6 | `assets/packs/pack-001/images/<name>.webp` |

`<name>` is the theme name for the generic set (`moon-sea.webp`) and the work id for per-work art (`wilde-the-nightingale-and-the-rose.webp`). Lowercase, hyphens, `.webp`. These match the sizes and settings in `placeholder_art.py` and `docs/content-pack-format.md`.

Size budget: about 150 KB at 2x and 50 KB at 1x. Pack 1 is bundled in the app, so 90 works means roughly 18 MB. Dense hatching compresses badly; if a file is far over budget, simplify the sky hatching rather than dropping quality below 70.

## 2. Prompt template

### Midjourney (primary)

`{subject}` is one or two sentences: what is in the picture, where it sits, and what (if anything) is amber. It always ends with "Amber only in …" or "No amber."

```
{subject} 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

| Parameter | Why |
| --- | --- |
| `--ar 3:2` | The card ratio. |
| `--style raw` | Less Midjourney house style; follows the prompt more literally. |
| `--v 7` | Pin the version that made the anchors. Do not change it mid-pack. If a newer version is current, use it, but pin it. |
| `--stylize 75` | Low enough to keep the prompt literal and the palette tight. |
| `--chaos 0` | The four variants stay close to each other. |
| `--seed 1001` | One house seed for every first-pass job. Record the seed of each approved image. Seeds only reproduce with the same prompt, version and refs. |
| `--sref ANCHOR_URLS --sw 150` | The style lock. Replace `ANCHOR_URLS` with the anchor image URLs (below). |
| `--no …` | Negatives. Midjourney's `--no` takes a comma list. |

Also: turn personalization off (no `--p`), since it drifts with whoever is logged in. Use "Upscale (Subtle)", not "Creative": creative upscaling invents new lines. The subtle 2x upscale gives a master above 1800 px wide.

**The `--sref` workflow.**

1. Bootstrap. Remove `--sref ANCHOR_URLS --sw 150` and generate the first three theme images: `moon-sea` (landscape), `candle` (still life) and `garden` (dense foliage). Optionally use a crop of the art only (no UI text) from the mockup's Nightingale card as a temporary `--sref`.
2. Reroll each until it passes the review checklist (section 2, below). Retouch if needed.
3. These three are the **anchors**. Save them to `content/illustrations/anchors/`, note their Midjourney URLs in the table below, and replace `ANCHOR_URLS` everywhere with the three URLs, space-separated.
4. Generate everything else with the anchors as `--sref`. Do not swap in newer images as anchors; that is how drift starts. Change anchors only on purpose, at the start of a pack, and log it.

| Anchor | File | URL | Seed | Date |
| --- | --- | --- | --- | --- |
| 1 (landscape) | `anchors/moon-sea.png` | | | |
| 2 (still life) | `anchors/candle.png` | | | |
| 3 (foliage) | `anchors/garden.png` | | | |

### GPT-image / DALL·E style models

These models read prose, not parameters. Request `size=1536x1024` (exactly 3:2) and `quality=high`. Attach the anchor images as reference inputs. Upscale 1536×1024 to 1800×1200 with a plain Lanczos resize (1.17x); no AI upscaler is needed at that scale.

```
Create a 3:2 landscape illustration.

Subject: {subject}

Style: a 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines (#EFE6D6) on a deep ink-navy, almost black ground (#12151F). All tone comes from cross-hatching, parallel lines and stipple. No painterly washes, no soft gradients, no photographic lighting. Monochrome. The only colour allowed is a small, muted amber (#E8B76A), and only where the subject says so.

Composition: put the subject right of centre, with its focal point about two-thirds of the way across and a little above the middle. Keep the left third of the image dark, empty and low in contrast. Keep everything important away from the edges and keep the bottom fifth quiet. Any people are small and seen from behind.

Match the line weight, hatching density and palette of the attached reference images exactly. Do not copy their subjects.

Do not include any text, letters, numbers, signatures, monograms, watermarks, borders, frames or ornamental cartouches. No modern objects. No full colour.
```

### Stable Diffusion XL / Flux

Positive prompt:

```
19th century steel engraving, white-line wood engraving, victorian book illustration plate, fine parchment-cream linework on deep ink-navy black ground, dense cross-hatching, parallel line shading, stipple, monochrome with one small muted amber accent, quiet night, {subject}, subject right of centre, dark empty low-contrast left third, generous margins, crisp fine lines, high detail
```

Negative prompt (SDXL and other CFG models):

```
text, letters, words, numbers, caption, signature, monogram, watermark, logo, frame, border, cartouche, colorful, saturated, red, blue, green, purple, photo, photorealistic, 3d render, cgi, oil painting, watercolor, airbrush, soft gradient, blur, bokeh, glow, anime, cartoon, modern objects, car, plastic, electric light, deformed hands, extra fingers, detailed face, uncanny face, lowres, jpeg artifacts, cropped subject
```

| Setting | SDXL | Flux.1 |
| --- | --- | --- |
| Size | 1216×832, then crop to 3:2 and upscale | 1536×1024 (exact 3:2) |
| Steps | 30 to 40 | 28 to 40 |
| Guidance | CFG 5 to 7 | Guidance 3 to 3.5 |
| Sampler | DPM++ 2M Karras | Default (Euler) |
| Seed | Fixed, 1001 | Fixed, 1001 |
| Style lock | IP-Adapter with the anchors, weight 0.5 to 0.7 | Redux or IP-Adapter with the anchors |

Standard Flux ignores negative prompts. Put "no text, no frame, no colour" plainly in the positive prompt and rely on review, or use a true-CFG workflow. After the first 30 approved images, a small LoRA trained on them is the strongest style lock for either model.

### Consistency workflow

1. **Anchors first.** Make the three anchors, then the other nine themes, before any per-work art. The theme set is the fallback, so a pack can ship on it.
2. **Generate in batches of 30** (10 nights). One job per prompt. Four variants per job gives about 120 candidates.
3. **First pass, same day.** At full size, cut each job to its best variant or reject the job. Expect about one job in three to need a reroll.
4. **Second pass, next day, in context.** Export the picks at 1x and 2x, drop them in (section 5), and look at them in the app or the screenshot run: on the card, finished and unfinished, at large Dynamic Type, and in a centred 4:5 crop.
5. **Reroll at most twice.** Change the subject wording, not the style text. If a work still fails, it ships with its theme image and goes on a list for later.
6. **Side-by-side check.** Before signing off a batch, put its 30 images in a grid next to the anchors and the previous batch. Look for drift in line weight, darkness and warmth.
7. **Log every approved image** (section 5).

**Light retouching is allowed and encouraged:** nudge the crop, darken the left third with levels, remove a stray letter-like mark, or remap the tones to exact ink and parchment with a gradient map (mask out the amber first). Hand work also makes the art more clearly original.

**Review checklist.** Every item must pass.

- [ ] Palette: ink ground, parchment lines, amber only where named and under 5% of the area. Desaturating the image changes nothing but the amber.
- [ ] Medium: reads as an engraving at 100%: lines and hatching, not paint or a photo filter.
- [ ] Composition: focal point near (66%, 40%); subject inside x 48 to 80%, y 10 to 65%; left third dark; badge corner, bottom fifth and edges clear.
- [ ] Subject: matches the prompt, period-correct, follows the accuracy notes, gives nothing away.
- [ ] Artefacts: no text or pseudo-letters, no signature, no frame; hands, legs and wings anatomically right.
- [ ] In context: works on the card (finished and unfinished), at large type, and in a 4:5 crop.
- [ ] Consistency: sits with the anchors and the rest of the batch.

**Rejection criteria.**

| Reject when | What it looks like |
| --- | --- |
| Colour drift | Blue sky, green leaves, sepia or brown cast, amber spread across the image, a second accent colour. |
| Wrong medium | Watercolour wash, airbrush glow, smooth 3D shading, photographic depth of field. |
| Text artefacts | Lettering on book spines, signs, coins, scrolls or letters; a signature or monogram in a corner; numbers. |
| Frames | A drawn border, ornamental cartouche, plate mark or vignette edge. |
| Uncanny faces | Detailed faces, staring eyes, faces in mirrors or windows. People must be small or turned away. |
| Bad anatomy | Extra fingers, birds with three legs, spiders without eight legs, horses with wrong joints. |
| Modern objects | Electric streetlights, cars, wires, plastic, zips, modern glasses or shoes. |
| Anachronisms | Wrong era or place for the text: an 1840s scene with 1900s dress, the wrong country's buildings. |
| Cultural errors | The cases in the accuracy notes: mixed Chinese and Japanese motifs, exotic clichés, stereotypes. |
| Spoilers | The ending or the twist drawn on the card. |
| Composition | Subject centred or left, bright left third, focal point under the badge, subject cut by an edge. |
| Too busy | So dense it reads as grey texture at 600×400. |

## 3. The 12 theme engravings

These are the PRD's fallback set, for works without their own art. The first ten use the existing placeholder names exactly, so the files drop straight in over the placeholders. `hearth` and `river` are new: classic short fiction is full of firesides and rivers (Dickens, Chekhov, Mansfield, Twain, Maupassant, Tagore), and nothing in the current set covers them. To use a new theme, put its name in the master sheet's `theme` column; `build_pack.py` builds the path from that name.

| File | Intent |
| --- | --- |
| `moon-sea.webp` | Night sea under a moon. Poems of longing, loss, dreams, voyages. |
| `road.webp` | A road over hills to a far horizon. Journeys, essays on travel and aims. |
| `rose.webp` | A single rose. Love poems, beauty, loss. |
| `bird.webp` | A small bird on a branch. Hope, song, freedom, the soul. |
| `city.webp` | Old town rooftops at night. Urban stories, poverty and plenty, crowds. |
| `candle.webp` | A candle and books. Essays on reading, thought, solitude. |
| `night-sky.webp` | Stars over a low land. Wonder, the soul, faith, time. |
| `garden.webp` | A walled garden at night. Domestic stories, love, secrets, summer. |
| `forest.webp` | A path into old woods. Nature writing, wildness, fairy tales. |
| `tea.webp` | A teapot and cups on a table. Hospitality, conversation, quiet rituals. |
| `hearth.webp` | NEW. A fireside interior. Family, winter, home, ghost stories, letters. |
| `river.webp` | NEW. A boat at a riverbank. River journeys, fishing, crossing, ferrymen, partings. |

### `moon-sea.webp`

Night sea under a moon. Poems of longing, loss, dreams, voyages.

```
A full moon half veiled by torn clouds above a wide dark sea, a broad path of moonlight on slow rolling waves, a low rocky headland on the far right. No amber; the moon is parchment. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `road.webp`

A road over hills to a far horizon. Journeys, essays on travel and aims.

```
A winding country road climbing over rolling hills toward a far horizon at dusk, two tall slender cypresses beside the road, the road's last bend right of centre. Amber only as a thin glow along the far horizon. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `rose.webp`

A single rose. Love poems, beauty, loss.

```
A single open rose on a thorny stem with three leaves, seen close, a small moon behind it, a few faint stars. No amber; the rose is drawn in parchment line. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `bird.webp`

A small bird on a branch. Hope, song, freedom, the soul.

```
A small songbird perched on a bare branch under a large pale moon, the branch entering from the right edge, the bird in profile facing left. No amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `city.webp`

Old town rooftops at night. Urban stories, poverty and plenty, crowds.

```
Nineteenth-century town rooftops at night, chimney stacks, gables and a church spire, the roofline rising toward the right, a few small lit windows in muted amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `candle.webp`

A candle and books. Essays on reading, thought, solitude.

```
A lit tallow candle in a plain brass holder beside a stack of old leather-bound books with blank spines, one book lying open, on a bare wooden table. Amber only in the flame and its soft halo. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `night-sky.webp`

Stars over a low land. Wonder, the soul, faith, time.

```
A vast field of stars and a faint Milky Way arching over a low line of hills with a few dark trees, the densest stars right of centre. Amber only on the single brightest star. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `garden.webp`

A walled garden at night. Domestic stories, love, secrets, summer.

```
A walled garden at night, tall flowers and leafy stalks in an oval bed, an old brick wall with an arched wooden gate on the right, a small moon above. No amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `forest.webp`

A path into old woods. Nature writing, wildness, fairy tales.

```
A footpath entering an old forest of tall trunks, moonlight falling between the trees, the path vanishing into the trees right of centre. No amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `tea.webp`

A teapot and cups on a table. Hospitality, conversation, quiet rituals.

```
A plain steaming earthenware teapot and two small cups on a bare wooden table by a window at night, a thin curl of steam rising. Amber only in a faint glow through the window. Culturally neutral: no Japanese or Chinese ceremony implements, no saucers with pattern. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `hearth.webp`

NEW. A fireside interior. Family, winter, home, ghost stories, letters.

```
A plain fireplace in a modest nineteenth-century room, embers low in the grate, a kettle on the hob, an empty wooden armchair angled toward the fire, shadows filling the room. Amber only in the embers. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### `river.webp`

NEW. A boat at a riverbank. River journeys, fishing, crossing, ferrymen, partings.

```
A small wooden rowing boat moored among reeds under a leaning willow at a quiet river bend at night, the moon reflected in still water, the boat right of centre. Amber only in a small lantern on the boat. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

## 4. Per-work prompts, nights 1 to 7

The subjects come from the texts in `assets/packs/pack-001.json`. Each is a concrete scene or object from early in the piece, so the card sets a mood without giving anything away. The file name is the work id. For GPT-image or SD/Flux, the subject is the prompt text before "19th-century steel engraving"; paste it into the template in section 2.

| Night | Type | Title | Author | File |
| --- | --- | --- | --- | --- |
| 1 | Story | The Nightingale and the Rose | Oscar Wilde | `wilde-the-nightingale-and-the-rose.webp` |
| 1 | Poem | A Dream Within a Dream | Edgar Allan Poe | `poe-a-dream-within-a-dream.webp` |
| 1 | Essay | El Dorado | Robert Louis Stevenson | `stevenson-el-dorado.webp` |
| 2 | Story | The Gift of the Magi | O. Henry | `henry-the-gift-of-the-magi.webp` |
| 2 | Poem | Hope | Emily Dickinson | `dickinson-hope.webp` |
| 2 | Essay | On Reading and Books | Arthur Schopenhauer | `schopenhauer-on-reading-and-books.webp` |
| 3 | Story | Araby | James Joyce | `joyce-araby.webp` |
| 3 | Poem | Where the Mind Is Without Fear | Rabindranath Tagore | `tagore-where-the-mind-is-without-fear.webp` |
| 3 | Essay | Walking Tours | Robert Louis Stevenson | `stevenson-walking-tours.webp` |
| 4 | Story | Désirée's Baby | Kate Chopin | `chopin-desirees-baby.webp` |
| 4 | Poem | When I Heard the Learn'd Astronomer | Walt Whitman | `whitman-when-i-heard-the-learnd-astronomer.webp` |
| 4 | Essay | Walking | Henry David Thoreau | `thoreau-walking.webp` |
| 5 | Story | The Little Match-Seller | Hans Christian Andersen | `andersen-the-little-match-seller.webp` |
| 5 | Poem | How Do I Love Thee? | Elizabeth Barrett Browning | `browning-how-do-i-love-thee.webp` |
| 5 | Essay | The Cup of Humanity | Kakuzo Okakura | `okakura-the-cup-of-humanity.webp` |
| 6 | Story | Dr. Heidegger's Experiment | Nathaniel Hawthorne | `hawthorne-dr-heideggers-experiment.webp` |
| 6 | Poem | A Noiseless Patient Spider | Walt Whitman | `whitman-a-noiseless-patient-spider.webp` |
| 6 | Essay | The Common Reader | Virginia Woolf | `woolf-the-common-reader.webp` |
| 7 | Story | Kew Gardens | Virginia Woolf | `woolf-kew-gardens.webp` |
| 7 | Poem | The Chariot | Emily Dickinson | `dickinson-the-chariot.webp` |
| 7 | Essay | On Noise | Arthur Schopenhauer | `schopenhauer-on-noise.webp` |

### Night 1 · Story · The Nightingale and the Rose

Oscar Wilde. File: `wilde-the-nightingale-and-the-rose.webp`

**Accuracy:** A nightingale is a small plain brown bird, not a colourful songbird. The mockup shows this card with a muted red rose; see the colour note in section 1. Do not show the thorn piercing the bird: that is the ending.

```
A small plain russet-brown nightingale perched on a thorny branch of a rose-tree beside a single half-open rose, under a full moon, glossy holm-oak leaves behind. No amber; the rose is drawn in parchment line. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 1 · Poem · A Dream Within a Dream

Edgar Allan Poe. File: `poe-a-dream-within-a-dream.webp`

**Accuracy:** 1849 American. The figure stays small and faceless. No modern clothes.

```
A small solitary figure in a long 1840s coat seen from behind on a rocky, surf-beaten shore at night, heavy waves breaking white, a low moon behind torn clouds. No amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 1 · Essay · El Dorado

Robert Louis Stevenson. File: `stevenson-el-dorado.webp`

**Accuracy:** El Dorado is Stevenson's metaphor for a hope never reached. No conquistadors, gold idols or jungle temples.

```
A narrow path climbing over ridge after ridge toward a far horizon, a tiny traveller with a staff on the path, and on the farthest ridge the faint distant towers of a city that is never reached, under a single bright star. Amber only in the faint glow of the distant city. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 2 · Story · The Gift of the Magi

O. Henry. File: `henry-the-gift-of-the-magi.webp`

**Accuracy:** New York, 1905: sash window, gas bracket, iron fire escape at most. Coins show no legible lettering. Do not show the comb or the watch chain: those are the twist.

```
A worn wooden table by the window of a shabby furnished flat at winter dusk, a small heap of old pennies and a few silver coins counted into little stacks, and through the window a grey cat walking a grey fence in a narrow backyard. Amber only as faint gaslight on the coins. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 2 · Poem · Hope

Emily Dickinson. File: `dickinson-hope.webp`

**Accuracy:** New England, 1860s: a sparrow-like native bird, not exotic. The poem is metaphor, so no human figure.

```
A small songbird perched upright on a slender branch bent by a gale, wind and rain in long diagonal hatching, a dark storm sky, the bird singing calmly. Amber only as a faint warmth in the bird's breast. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 2 · Essay · On Reading and Books

Arthur Schopenhauer. File: `schopenhauer-on-reading-and-books.webp`

**Accuracy:** German scholar's library, 1850s. Spines are blank: models love to invent lettering here. No globes or modern lamps.

```
Tall library shelves of old leather-bound volumes laid in rows like strata of rock, receding into darkness, and in front a single candle on a reading desk beside one closed book. Amber only in the candle flame. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 3 · Story · Araby

James Joyce. File: `joyce-araby.webp`

**Accuracy:** Dublin, about 1895: Victorian red-brick terraces with railings and area steps, gas lamps, no cars or tram wires. Do not show the bazaar: it is the ending.

```
A quiet dead-end street of brown-brick terraced houses at winter dusk, gas street lamps on iron posts lifting feeble lanterns, and at the blind end a detached two-storey house standing empty in its own square ground. Amber only in the small lamp flames. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 3 · Poem · Where the Mind Is Without Fear

Rabindranath Tagore. File: `tagore-where-the-mind-is-without-fear.webp`

**Accuracy:** Rural Bengal, early 1900s: palmyra (tal) palms, banyan, bamboo, thatched mud houses, wide river sandbanks. No Mughal domes or Taj Mahal, no elephants or camels, no desert landscape, no deities or temple icons, no turbaned "oriental" figures. Best with no people. Gitanjali is devotional and the poem is a prayer for a nation's waking: keep it calm and dignified.

```
A clear stream winding across pale sandbanks toward a wide open horizon at first light in rural Bengal, palmyra palms and a great banyan with hanging roots on the near bank, a small thatched mud hut among bamboo. Amber only in the thin band of dawn on the horizon. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 3 · Essay · Walking Tours

Robert Louis Stevenson. File: `stevenson-walking-tours.webp`

**Accuracy:** Britain or France, 1870s: leather and canvas, no modern hiking gear. No signposts or milestones, which invite lettering.

```
A canvas knapsack and an ash walking stick resting against a dry-stone wall beside a country road at evening, the first stars out, and down the road the lit window of a village inn. Amber only in the inn window. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 4 · Story · Désirée's Baby

Kate Chopin. File: `chopin-desirees-baby.webp`

**Accuracy:** Louisiana, antebellum Creole country. The story is about race and slavery. Do not show enslaved people, quarters or a romanticised plantation house, and no figures at all. No fire: the bonfire is the ending.

```
The big stone pillar of an old gateway in deep shade under a live oak hung with Spanish moss, late afternoon, an empty road beyond. No amber. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 4 · Poem · When I Heard the Learn'd Astronomer

Walt Whitman. File: `whitman-when-i-heard-the-learnd-astronomer.webp`

**Accuracy:** America, 1860s: frock coat and soft hat. No telescopes, charts or diagrams in the sky. The figure stays small.

```
A lone man seen from behind standing in a damp meadow at night, looking up in silence at a vast field of stars, and far behind him the small lit windows of a lecture hall. Amber only in the hall windows. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 4 · Essay · Walking

Henry David Thoreau. File: `thoreau-walking.webp`

**Accuracy:** Concord, Massachusetts, 1850s: white pine, oak, maple, fieldstone walls, gentle land. No Alpine peaks or giant redwoods.

```
A footpath leaving an old stone wall and a field and entering a New England woodland of white pines and oaks in late afternoon, low light slanting from the west through the trunks. Amber only in that thin band of western light. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 5 · Story · The Little Match-Seller

Hans Christian Andersen. File: `andersen-the-little-match-seller.webp`

**Accuracy:** Copenhagen, 1840s: stepped gables, half-timbering, cobbles under snow, no electric streetlamps. Do not show the child: no suffering child, no faces, and her fate is the ending.

```
A snowy corner where one old house juts out beyond another on New Year's Eve, snow falling thickly, warm windows lit above, and in the corner a small bundle of matches in the snow with one struck match flaring. Amber only in the match flame and the windows. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 5 · Poem · How Do I Love Thee?

Elizabeth Barrett Browning. File: `browning-how-do-i-love-thee.webp`

**Accuracy:** England, 1840s: quill or steel nib, sealing wax, no envelope stamps or legible handwriting. The letter is folded and blank on its face.

```
A writing desk at night: a folded letter tied with a ribbon, a quill pen, a stick of sealing wax and a single rose laid across the letter, lit by one candle. Amber only in the candle flame. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 5 · Essay · The Cup of Humanity

Kakuzo Okakura. File: `okakura-the-cup-of-humanity.webp`

**Accuracy:** Chanoyu implements, named correctly: chawan (handleless, rough and asymmetric, not a cup and saucer), chasen (bamboo whisk), chashaku (bamboo scoop), kama (iron kettle) on a ro (sunken hearth), tokonoma (alcove), shoji. Powdered tea, not leaf tea in a teapot. Wabi taste: simple, worn, imperfect. No Chinese teapots with handles, no cherry-blossom excess, no geisha, pagodas or dragons, no mixing of Chinese and Japanese motifs. No hanging scroll, because it will grow fake calligraphy; use the flower.

```
A Japanese tea room: an iron kettle steaming over a sunken hearth set in tatami, beside it an irregular handleless raku tea bowl, a bamboo whisk and a bamboo scoop, and behind them a single camellia in a bamboo vase in a plain alcove, a paper shoji screen softly lit. Amber only in the charcoal glow of the hearth. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 6 · Story · Dr. Heidegger's Experiment

Nathaniel Hawthorne. File: `hawthorne-dr-heideggers-experiment.webp`

**Accuracy:** New England, 1830s. The mirror reflects only the dark room: no faces in it. No skeleton, no glowing potion. Do not show the rose reviving or the guests.

```
A dim old study: on a small round ebony table a cut-glass vase of sparkling water caught by a shaft of sunlight between faded damask curtains, and behind it oaken bookcases of huge folios, a bronze bust on top, and a tall dusty mirror in a tarnished gilt frame. Amber only where the light catches the water. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 6 · Poem · A Noiseless Patient Spider

Walt Whitman. File: `whitman-a-noiseless-patient-spider.webp`

**Accuracy:** An ordinary small spider with eight legs, quiet and patient, not menacing. No giant or horror spider, no web full of prey.

```
A small spider standing on the tip of a little rocky promontory, launching fine silk filaments out into a vast dark space scattered with stars, the threads drifting toward the right. Amber only at the tip of the longest thread. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 6 · Essay · The Common Reader

Virginia Woolf. File: `woolf-the-common-reader.webp`

**Accuracy:** London, 1920s: oil lamp or early electric lamp, plain furniture, blank spines. No figure: the reader is the viewer.

```
A small humble room full of books, books on narrow shelves, stacked on the floor and on a chair, a worn armchair by a night window with an open book face-down on its arm, and a reading lamp with a cloth shade. Amber only in the lamp's glow. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 7 · Story · Kew Gardens

Virginia Woolf. File: `woolf-kew-gardens.webp`

**Accuracy:** Kew, July 1919. The Palm House is the 1848 curved glasshouse, not a modern greenhouse. The couples who pass are optional and should stay tiny and faceless.

```
A close, low view of a snail with a spiral shell on a smooth grey pebble in an oval flower-bed, among heart-shaped and tongue-shaped leaves and tall flower stalks, a raindrop on a leaf, and far behind the curved iron-and-glass Palm House. Amber only where light catches the raindrop. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 7 · Poem · The Chariot

Emily Dickinson. File: `dickinson-the-chariot.webp`

**Accuracy:** New England, 1860s carriage. Death in this poem is a courteous gentleman: no skull, scythe, reaper, hearse or coffin. No visible driver's face.

```
A closed horse-drawn carriage with two dark horses moving slowly along a country road past fields of standing grain toward a setting sun low on the horizon. Amber only in the low sun. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

### Night 7 · Essay · On Noise

Arthur Schopenhauer. File: `schopenhauer-on-noise.webp`

**Accuracy:** Frankfurt, 1850s: stone and half-timbered houses, horse traffic, no cars. The essay names the cracking of whips as the worst noise. Keep the carter small and faceless; no cruelty to the horse.

```
A narrow cobbled street between tall old gabled town houses at evening, a small carter on a horse-drawn cart cracking a long whip whose lash curls in the air, and high above one lit window of a quiet study. Amber only in that window. 19th-century steel engraving, like a plate from a Victorian illustrated edition, printed in reverse: fine warm parchment-cream lines on a deep ink-navy, almost black ground, dense cross-hatching, parallel-line shading and stipple, crisp fine linework, monochrome except the one muted candle-amber accent named above, quiet still night mood, main subject right of centre with clear space around it, left third of the frame dark, empty and low in contrast, nothing touching the edges --ar 3:2 --style raw --v 7 --stylize 75 --chaos 0 --seed 1001 --sref ANCHOR_URLS --sw 150 --no text, lettering, letters, words, numbers, signature, monogram, watermark, frame, border, cartouche, full colour, red, blue, green, purple, photograph, 3d render, painting, watercolour, modern objects
```

## 5. How to drop them in

### Files

1. Keep masters out of `assets/`. `pubspec.yaml` bundles every file in `assets/packs/pack-001/images/`, so a master there ships in the app. Keep masters in cloud storage (a private folder in the content bucket, or a shared drive), named `<name>.png`. They are too big for git.
2. Export both sizes from the master, run from the repo root. This needs Pillow, which `placeholder_art.py` already uses.

```bash
python3 - masters/wilde-the-nightingale-and-the-rose.png wilde-the-nightingale-and-the-rose <<'EOF'
import sys
from PIL import Image, ImageOps
src, name = sys.argv[1], sys.argv[2]
out = "assets/packs/pack-001/images"
img = ImageOps.fit(Image.open(src).convert("RGB"), (1200, 800), Image.LANCZOS)
img.save(f"{out}/2.0x/{name}.webp", "WEBP", quality=72, method=6)
img.resize((600, 400), Image.LANCZOS).save(f"{out}/{name}.webp", "WEBP", quality=78, method=6)
EOF
```

3. Theme images overwrite the placeholders of the same name. After that, do not run `placeholder_art.py` again: it rewrites all ten theme files. Retire it, or make it skip files that exist.

### Point works at their own image

Today `build_pack.py` ignores per-work files. It sets every work's image from the master sheet's `theme` column:

```python
"image_path": f"assets/packs/pack-{pack_id:03d}/images/{r.theme}.webp",
```

It needs one change: use `images/<work id>.webp` when that file exists at both 1x and 2x, and fall back to `images/<theme>.webp` otherwise. The build should fail if neither exists, and the measure report in `content/reports/` should gain a column saying which image each work got (own or theme). The `theme` column stays: it is the fallback, and it is what a work uses until its own art is approved. An optional `image` column in the master sheet could override both, for example to share one image across "Part 1 of 3" to "Part 3 of 3".

The pack `version` also needs to change. `build_pack.py` always writes `"version": 1`, and the importer (`lib/data/content_pack.dart`) skips a pack whose version it already has. A device or simulator that imported version 1 would keep the old placeholder paths. Add a `--version` flag (or bump the constant) so new art ships as version 2. In development, the debug menu reset or a reinstall also works.

Packs 2 and 3 will download from the CDN. The card uses `Image.asset`, which only reads bundled files, so downloaded art will need a file-based image path. That is phase 4 work, noted here so the per-work file names stay the same.

### Rebuild and check

```bash
python3 content/tools/build_pack.py --pack 1 --nights 1-7
flutter test
flutter test test/screenshots --dart-define=SCREENSHOTS=true
python3 tool/frame_screenshots.py
```

Then look at `docs/screenshots/tonight.png` and `tonight-progress.png`. Check each card unfinished and finished, and on a real device at the largest text size. If every card looks too dim, the lever is the gradient stops in `reading_card.dart`, not brighter art.

### Log and licensing

Keep a log at `content/illustrations/log.csv`, one row per approved image: file name, work id or theme, tool, model and version, full prompt, seed, `--sref` URLs, job id or image URL, retouching done, approver, date. Keep the anchors in `content/illustrations/anchors/`. With this doc, the log and the anchors in the repo, any image can be regenerated or extended in the same style.

Before generating anything for release, check the commercial-use terms of the exact tool and plan used, and record them in the log:

- Midjourney: a paid plan is required for commercial use, and larger companies need a higher tier. Images made outside Stealth mode are public in the gallery.
- OpenAI image models: the terms assign output rights to the user. Check the current terms and the usage policies.
- Open-weight models: licences differ by model. SDXL's licence allows commercial use. Flux.1 [schnell] is Apache 2.0; Flux.1 [dev] has a non-commercial licence, so read its terms before using its output.

Purely AI-generated images may not be protected by copyright in the US, so others could reuse them. The PRD lists "original illustrations" in the App Review notes, and hand retouching strengthens that claim. Add the illustrations to the pre-launch legal review. This is a working rule, not legal advice.

## 6. Scaling to 270 launch images

The launch needs 270 per-work images for 90 nights, plus the 12 themes. That is 9 batches of 30, three per pack.

| When | What |
| --- | --- |
| Before batch 1 | Anchors, then the other 9 themes. Log them. Replace the placeholders. |
| Each batch (10 nights, 30 images) | Day 1: write the 30 subjects, generate, first pass. Day 2: export, view in the app, second pass, rerolls. Day 3: final rerolls, side-by-side check, log, drop in. |
| Each pack (3 batches, 90 images) | Grid review of all 90 against the anchors. Re-anchor only here, and only on purpose. Bump the pack version and rebuild. |
| Ongoing | Keep art at least one pack ahead of the content pipeline's 60-night lead. |

- **Write subjects during the read-through.** Pipeline step 5 has someone read each piece on a phone. That is the cheapest moment to note a subject and any accuracy points.
- **Pace.** One batch every two to three days is about three to four weeks for all 270, part time. It must finish before the phase 4 beta gate.
- **Fallback.** A work without approved art ships with its theme image. That is fine for launch. Keep a list and fill it in later.
- **Balance.** Watch the theme mix per pack the way the curation rules watch authors: no more than a few cards in a row that are moons over water.
