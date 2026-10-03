# Content pipeline

The pipeline follows the PRD steps: curate, fetch, cut, clean, measure, then
pack. Review and illustration are the manual steps in between.

```bash
python3 content/tools/build_pack.py --pack 1 --nights 1-7   # writes assets/packs/pack-001.json + content/reports/pack-001.md
python3 content/tools/placeholder_art.py --pack 1           # placeholder card engravings
```

The only dependency is Python 3. `placeholder_art.py` also needs Pillow
(`pip install pillow`).

## Master sheet (`master_sheet.csv`)

There is one row per piece:

| Column | Meaning |
| --- | --- |
| `night`, `type` | target night and `story` / `poem` / `essay` |
| `title`, `author`, `year` | `year` is first publication; the 1930 rule is checked at build time |
| `translator` | e.g. `Constance Garnett (1916)`; the translation's own year is what counts |
| `origin`, `gender` | for the curation-balance rules (≥10 non-UK/US authors and ≥8 women per 30 nights) |
| `source`, `source_file` | GITenberg repo + file, or `manual` + a file in `content/manual/` |
| `start` | `after=<heading line>[#n]` (piece starts on the next line) or `at=<text in first line>[#n]` |
| `end` | `before=<heading line>[#n]` (counted from the start), `blank=<n>` (n blank lines in a row), or `eof` |
| `max_words`, `label` | cut an excerpt at a paragraph boundary; `label=from` marks it as an excerpt |
| `theme` | card image: one of the generic engravings |
| `pull_quote` | optional line for the Night complete screen |

## Sources

Project Gutenberg itself (`gutenberg.org`) is blocked from the build
environment, so the fetch step reads the same texts from the
[GITenberg](https://github.com/GITenberg) mirror on GitHub. The Gutenberg header
and licence never enter a pack: only the text between the markers is kept, and
the build fails if a piece mentions Gutenberg. The app and store listing must not
use the Project Gutenberg name or logo (PRD).

`content/manual/` holds texts that were not fetched. Today that is only Poe's "A
Dream Within a Dream" (1849), which was transcribed by hand. Check it against a
printed source during review.

## Measure report

Each build writes `content/reports/pack-NNN.md` with words, minutes and sizing
flags (story 8–15 min, poem 1–4, essay 5–10, night 15–25). The current test pack
has these known flags:

- Night 5 is 13 min. The Little Match-Seller is short.
- Night 6: Dr. Heidegger's Experiment is 16 min, and The Common Reader is a
  1-minute essay. The night total is fine at 18 min.
