# Progress log

This log tracks the build against the phases in [PRD.md](PRD.md). The newest
entry is at the top.

## 2026-10-14: Stage 1 community (favourites and share cards) and illustration prompts

Stage 1 of the community plan: everything that works without accounts or a backend.

### Done

**Favourites**

- [x] A `favorites` table (one row per work, with when it was saved). Schema version 2, with the first real migration: `onUpgrade` creates the table on existing installs. A test opens a version 1 database file, upgrades it, and checks that nights, progress, the streak, settings and highlights all survive.
- [x] Reader: a ribbon bookmark next to "Aa". It fills in amber when the piece is a favourite. Tapping it gives a light haptic and sends `favorite_added` or `favorite_removed` with the piece's night.
- [x] Library → Saved: favourites, newest first, as type and night, title and author. A tap opens the piece in the Reader. Swipe left to remove it.
- [x] "Reset" in the debug menu also clears favourites.

**Share cards**

- [x] Share cards (`lib/features/share`): a 4:5 image, 1080 x 1350, in three kinds. A highlight shows the sentence over the work's engraving. A night shows the lit candle, "Night N complete", the pull quote and the three titles. A milestone shows its constellation, "Night 30", the constellation's name and the reading stats. Every card ends with the wordmark and "One story, one poem, one essay."
- [x] A preview sheet with "Share" and "Close". "Share" renders the card to a PNG and opens the iOS share sheet through `share_plus`.
- [x] Entry points: a share button on each Library highlight, "Share" on the "Highlight saved" snackbar in the reader, "Share" on Night complete, and on Journey a share button in the stats row plus a tap on a reached milestone's name on the map.
- [x] Analytics: `share_card_opened` when the preview opens and `share_card_shared` when the share completes, each with `kind` and `day_number`.

The three cards are rendered by the screenshot test: [highlight](screenshots/share-highlight.png), [night](screenshots/share-night.png) and [milestone](screenshots/share-milestone.png).

### Decisions

- **App name**: the wordmark and tagline live in `ShareBrand` in `share_card.dart`, because the final name is still open.
- **Highlight night**: a highlight belongs to a work, not a night, so the card shows the first night that carries the work.
- **Quote marks**: the card draws its own amber quote mark. Quote marks around the whole sentence are dropped, and quote marks inside the sentence are kept.
- **Milestone figure**: night 7 shows the first-week figure. Later milestones show nine stars sampled along their stretch of the Journey path.
- **Native setup**: `share_plus` adds an iOS plugin. No Podfile is committed, so CocoaPods picks the plugin up on the first Mac build and nothing else is needed.

**Illustrations**

- [x] [illustration-prompts.md](illustration-prompts.md): the style lock, prompt templates for Midjourney, GPT-image and SDXL/Flux, prompts for the 12 theme engravings and for all 21 pieces in nights 1 to 7, and the drop-in steps.
- [x] `build_pack.py` uses `images/<work id>.webp` when it exists at 1x and 2x and falls back to the theme image. The measure report says which one each work got. `--version` bumps the pack version so installed apps pick up new art. `placeholder_art.py` no longer overwrites existing files without `--force`.
- [x] Real art for nights 1 to 7: the 12 theme engravings (the 10 placeholder themes plus `hearth` and `river`) and one engraving for each of the 21 pieces, exported to 1200 x 800 and 600 x 400 WebP. Every work now uses its own image, and pack 1 is version 2. The rose is drawn in parchment, so the red-rose question is moot.
- [ ] Replace the 2x files with exports from the full-size originals. These were cut from 2x2 review sheets, so most sources were about 665 px wide and the 1200 px files are upscaled. Only "On Noise" came from a full-size image.


## 2026-10-03: Scaffold (phase 0 complete, most of phase 1, parts of phases 2 to 4)

### Done

**Phase 0: Foundations**

- [x] Created the repo. There was no Daily Dharma scaffold in this environment, so this is a fresh `flutter create` (iOS only). See the open questions below.
- [x] Theme tokens (`lib/core/theme.dart`): ink `#12151F`, ink-raised, amber `#E8B76A`, parchment `#EFE6D6`, dim, hairline and highlight. Also the type scale and the 20 px card radius.
- [x] Newsreader font (OFL), cut into static instances: Regular, Medium and Italic at opsz 16, plus a Display cut at opsz 72 for titles and the drop cap.
- [x] Drift schema for all seven PRD tables (`lib/data/database.dart`), plus `imported_packs`. Schema version 1 (no migrations yet).
- [x] Content pack JSON format v1 ([content-pack-format.md](content-pack-format.md)), and an importer that validates, is idempotent and is versioned.
- [x] A 7-night test pack (21 real public-domain pieces) built by the content pipeline, with placeholder engravings.
- [x] Tab shell and routing (go_router `StatefulShellRoute`) for Tonight, Library and Journey.

**Gate passed**: the app imports the test pack and shows night 1's three titles from the database (`test/data/pack_importer_test.dart`, `test/features/app_flow_test.dart`).

**Phase 1: Reading loop**

- [x] Tonight: header, hairline progress across 1000 nights, candle streak badge, three cards with done states, a completion state with tomorrow's titles, and an end-of-content state.
- [x] Reader: Markdown rendering, small-caps title and author, a drop cap three lines tall, the amber ribbon, saved scroll position, and time read. The tab bar is hidden.
- [x] "Finish" writes progress and returns to Tonight, or goes to Night complete after the third piece.
- [x] Night complete: a flickering candle, "Night N complete", the pull quote, and week dots.
- [x] Debug menu (long-press "NIGHT N OF 1000" in debug builds): advance or rewind the day, finish tonight, jump to night N, reset.

**Gate, partly passed**: "progress survives an app restart" is covered by a test against a file-backed database. "Read all 7 nights end to end on a real device" still needs a Mac with Xcode, which this environment does not have.

**Phase 2: Habit (partial)**

- [x] Night unlock and streak rules as pure functions (`lib/domain`), with unit tests for midnight, time zone changes east and west, DST, missed days, freezes and the monthly refill.
- [x] Journey: stats row, constellation renderer (nights 1–7 as a figure, then a path through 30, 100, 365 and 1000), milestone labels and constellation names, a newest-star lighting animation, and tap a lit star to open that night.
- [x] An analytics event list and interface (`lib/core/analytics.dart`), with debug logging. The PostHog/Firebase choice is still open.
- [ ] Onboarding flow, reading time and notification permission.
- [ ] Daily reminder and "streak at risk" local notifications.

**Phase 3 and 4 items pulled forward (cheap and visible in the mockups)**

- [x] Highlights: long-press selects a sentence, offsets are stored into `text_md`, and a tap on the same sentence removes it. They are listed in Library → Highlights.
- [x] Library: unlocked nights (newest first) and Highlights.
- [x] Reader settings ("Aa"): 5 type sizes, 3 line spacings, and the Night, Sepia and Paper themes.
- [x] Motion: candle flicker, star lighting, and cross-fades between screens.
- [x] Accessibility basics: semantics labels on cards, tabs and stats, and the reader follows the system text scale.

**Content track**

- [x] Master sheet format, and a fetch → cut → clean → measure → pack script (`content/tools/build_pack.py`).
- [x] Clean step: curly quotes, em dashes, rejoined hard wraps, italics, stanzas, spaced contractions (`I 've` → `I've`), and decapitalised opening words.
- [x] Rights check: the 1930 rule is enforced at build time, and every work gets a `rights_note`.
- [ ] Curate nights 8–90.
- [ ] Read-through of every piece on a phone.
- [x] Real illustrations for nights 1 to 7 (2026-10-14).

### Screenshots

The screenshots come from the real app, rendered headless by
`test/screenshots/screenshots_test.dart` and framed by
`tool/frame_screenshots.py`. See the [README](../README.md).

### Decisions and deviations from the PRD

- **Extra columns**: `works.pull_quote` holds the line for Night complete. `progress.seconds_read` holds the time read on Journey. `settings.debug_day_offset` lets the debug menu move the clock. The PRD schema had nowhere to keep these.
- **Unlock time**: the next night unlocks at local midnight, as the PRD's Tonight section says. The open question about unlocking at the reading time is still open, and changing it is a one-line change in `NightRules`.
- **Freezes**: a freeze covers a missed day but does not add to the streak. If a gap is longer than the freezes left, the streak breaks and the freezes are kept.
- **Week dots** count days with any finished piece, ending today.
- **Excerpts** show as "ESSAY · EXCERPT" on cards and "FROM …" in the reader.
- **Sources**: Gutenberg is blocked from the build environment, so the texts come from the GITenberg mirror on GitHub. Hazlitt's "On Going a Journey" (in the mockup) was not available there, so night 1's essay is Stevenson's "El Dorado".
- **Night 8 paywall** is not built yet (phase 3). `isSubscriberProvider` is hard-wired to `false`.

### Next

1. Phase 2: onboarding, local notifications, and the TestFlight 7-day self-test. This needs a Mac with Xcode, and the Daily Dharma notification code if it can be reused.
2. Phase 3: RevenueCat, the paywall at onboarding and night 8, and gating.
3. Content: curate nights 8–30 for pack 1 against the balance rules.

### Open questions for Arnav

1. **Daily Dharma scaffold**: it was not available here. Should notifications and streak code be ported from it later, or should we keep this fresh base?
2. **Night 1 essay**: the mockup shows Hazlitt's "On Going a Journey". Should it go back on night 1 once it can be sourced?
3. The PRD's open questions are still open. The midnight-versus-reading-time unlock is the one that affects the code most.
