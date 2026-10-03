# Content pack format (v1)

A content pack holds a run of consecutive nights. `pack-001.json` will hold
nights 1 to 30 at launch; today it is the 7-night test pack. Pack 1 is bundled in
the app binary (`assets/packs/`), so night 1 works offline. Later packs will come
from the CDN (phase 4).

The pipeline writes packs (`content/tools/build_pack.py`), and the app imports
them (`lib/data/content_pack.dart`).

```jsonc
{
  "format": 1,              // bump on breaking changes; the app rejects unknown formats
  "pack_id": 1,
  "version": 1,             // a higher version replaces the pack's works and days
  "first_day": 1,
  "last_day": 7,
  "generated_at": "2026-10-03T11:40:00+00:00",
  "days": [
    { "day_number": 1, "story_id": "wilde-the-nightingale-and-the-rose",
      "poem_id": "poe-a-dream-within-a-dream", "essay_id": "stevenson-el-dorado" }
  ],
  "works": [
    {
      "id": "wilde-the-nightingale-and-the-rose",   // <author surname>-<title slug>
      "type": "story",                              // story | poem | essay
      "title": "The Nightingale and the Rose",
      "author": "Oscar Wilde",
      "year": 1888,
      "word_count": 2326,
      "est_minutes": 10,                            // word_count / 230 wpm
      "part_label": null,                           // "from" for excerpts, or "Part 1 of 3"
      "text_md": "…",                               // see below
      "image_path": "assets/packs/pack-001/images/rose.webp",
      "source_ref": "github.com/GITenberg/The-Happy-Prince-and-Other-Tales_902/902-0.txt",
      "rights_note": "Published 1888; public domain in the US (published 1930 or earlier). Pending legal review.",
      "pull_quote": "Ah, on what little things does happiness depend!"   // optional; shown on Night complete
    }
  ]
}
```

## `text_md`

This is a small subset of Markdown, so the reader can render it exactly and
store highlight offsets into it:

- Blocks (paragraphs or stanzas) are separated by one blank line.
- In poems, a single newline is a line break. In prose, there are no single
  newlines.
- `*text*` marks italics. No other markup is used.
- Quotes and dashes are already typographic (`“ ” ‘ ’ —`).

## Images

WebP images come in two sizes, using Flutter's resolution-aware assets:
`images/<name>.webp` at 600×400 and `images/2.0x/<name>.webp` at 1200×800.

## Import rules

- `validate()` checks that work ids are unique, types are valid, and every
  night references works that exist in the pack.
- Importing the same `pack_id` and `version` again does nothing. A higher version
  upserts works and days, and never touches user progress.
