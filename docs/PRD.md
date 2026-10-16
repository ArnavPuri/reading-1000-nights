# 1000 Nights: PRD and Build Plan

Oct 3, 2026 · @Arnav Puri

## Summary

1000 Nights is a reading habit app that serves one short story, one poem and one essay from the public domain every night for 1000 nights. It is iOS-first, built in Flutter, and local-first with no account required in v1.

The texts are free elsewhere. The product is the ritual: a calm reader, a nightly sequence that needs no choosing, and a visible record of becoming a reader.

**Positioning line:** "A thousand nights. One story, one poem, one essay."

**Target user:** adults who want to read more literature but stall on what to read and on sitting down to do it. They already use habit apps such as Duolingo or Headspace and read on their phone at night.

## Goals and metrics

v1 proves two things: people come back for seven nights, and enough of them pay at night 8.

**Goals**

- Ship an iOS app with the three approved screens (Tonight, Reader, Journey), onboarding and a paywall.
- Launch with 90 nights of vetted content and a pipeline that stays 60 nights ahead of the furthest user.
- Make a night finishable in about 20 minutes.

**Non-goals for v1**

- Accounts, cloud sync and social features.
- Android, iPad and web.
- Audio narration, AI summaries or notes on the texts.
- A browsable store of all Gutenberg books. The Library tab holds only nights already unlocked.

**Success metrics**

| Metric | Target | Why it matters |
| --- | --- | --- |
| Night 1 completion (at least one piece read) | 60% of installs | Onboarding and first reading work |
| Night 7 reached | 20% of installs | The habit forms before the paywall |
| Trial start at the night 8 gate | 25% of users who reach it | The streak is worth keeping |
| Trial to paid | 40% | The price is right |
| Median session length | 12 to 20 min | Nights are sized correctly |

These targets are starting guesses, not benchmarks. Revisit them after the first 500 installs.

## Core experience

The app has three tabs and three flows around them. Tonight, Reader and Journey follow the approved mockups.

### Tonight (home)

- Header shows "NIGHT 12 OF 1000", a hairline progress bar across all 1000 nights, and the candle streak count.
- Three cards in fixed order: Short Story, Poem, Essay. Each shows the title, author, read time and an engraving-style illustration.
- A finished card dims and shows a small amber check. Cards can be read in any order.
- When all three are done, the screen shows the completion state and a preview of tomorrow's titles.
- The next night unlocks at local midnight, and only if the current night has at least one piece read. Users never fall behind: night N is their Nth night, not a calendar date.

### Reader

- Title and author in small caps, an ornamental drop cap, serif body text.
- The amber ribbon on the right edge shows scroll progress.
- Long-press selects a word; drag the two handles to choose where a highlight starts and ends, across paragraphs if needed. A small menu offers Highlight, Copy and Share. Highlights are saved to the Library.
- "Aa" opens type size (5 steps), line spacing (3 steps) and theme (Night, Sepia, Paper).
- A piece counts as read when the user reaches the end and taps "Finish". Scroll position is saved if they leave early.
- The tab bar hides while reading. The mockup shows it, but it competes with the text.

### Night complete

- Lit candle, "Night 12 complete", one line from tonight's reading, and the week as seven dots.
- No confetti or sound. It should feel like closing a book.

### Journey

- Stats row: nights completed, current streak, total time read.
- Constellation map: each completed night is a lit star, joined to the previous one. Milestones at 7, 30, 100, 365 and 1000 are labelled along a dotted path.
- Each milestone completes a named constellation. This is the app's signature element.
- Tapping a lit star opens that night's three readings.

### Library

- A list of unlocked nights, newest first, plus a Highlights view.
- Re-reading any past night is always allowed.

### Onboarding

1. The positioning line over an engraving.
2. "When do you read?" with Morning, Evening and Before bed, then an exact time.
3. Notification permission, asked in context: "We'll remind you at 9:30 pm."
4. A skippable trial offer.
5. "Begin night one" opens Tonight.

### Streak rules

- A night counts when at least one piece is finished that calendar day.
- Nights completed never decreases. The streak resets to zero on a missed day unless a freeze is available.
- Subscribers get two freezes a month, applied automatically. Free users get none.
- One reminder a day at the chosen time, and one "streak at risk" reminder two hours before midnight if nothing is read.

## Design system

The look is ink-navy, candle amber and parchment serif, taken from the approved mockups. Hex values are the ones specified in the generation prompt; confirm them against the final mockup export.

| Token | Value | Use |
| --- | --- | --- |
| `ink` | #12151F | App background |
| `ink-raised` | about 6% lighter than ink | Cards, tab bar |
| `amber` | #E8B76A | Accent: labels, progress, active tab, drop cap, lit stars |
| `parchment` | #EFE6D6 | Primary text |
| `parchment-dim` | parchment at 60% | Authors, read times, inactive tabs |
| `highlight` | amber at 18% | Highlighted sentences |

**Type**

- Titles and body: a transitional serif. Newsreader is the first choice (free, variable, has optical sizes).
- Labels ("SHORT STORY", "NIGHT 12 OF 1000"): the same serif or a humanist sans in small caps, letter-spaced about 15%.
- Reader body defaults to 19 pt with 1.6 line height.

**Components**

- Reading card: 20 px radius, hairline border, illustration bleeding off the right side under a dark fade.
- Candle streak badge, hairline progress bar, ribbon progress, drop cap, constellation star and link.
- Tab bar with three line icons: moon, open book, constellation.

**Illustrations**

- Engraving-style, monochrome with at most one muted colour. One per work on the cards.
- 270 are needed for the 90-night launch. Generate them in a fixed style, then review by hand.
- Fallback: a set of about 12 generic engravings by theme (sea, forest, city, night sky) for works without their own.

**Motion**

- Slow and sparse: a candle flicker on completion, a star lighting on Journey, cross-fades between screens. Nothing bounces.

## Content

Content is the largest piece of work: 1000 nights is 3000 pieces, and each must be sourced, cleaned, sized and rights-checked. v1 ships 90 nights (270 pieces).

**Sourcing rules**

- Use only works published in 1930 or earlier, which are public domain in the US as of 2026. Translations count by the translation's own publication date.
- This rule excludes some items on the archive.org list, such as Orwell's "Good Bad Books" (1945).
- Take texts from Project Gutenberg, remove its header and licence text, and do not use the Project Gutenberg name or logo in the app or store listing.
- Build our own nightly list. The archive.org list is inspiration, not a source to copy night for night.
- This is a working rule, not legal advice. Get a short legal review before launch, since the app sells worldwide.

**Sizing rules**

- A night totals 15 to 25 minutes at 230 words a minute: story 8 to 15 min, poem 1 to 4 min, essay 5 to 10 min.
- Long works are split across consecutive nights ("Part 1 of 3") or excerpted with a clear "from" label.
- The first 7 nights are the shortest and most gripping in the set. They decide retention.

**Pipeline**

1. Curate: add a row to the master sheet with title, author, type, year, source URL and target night.
2. Fetch: a script downloads the Gutenberg plain text and cuts the chosen piece by start and end markers.
3. Clean: normalise quotes and dashes, rejoin hard-wrapped lines, mark italics and stanza breaks, output Markdown.
4. Measure: compute word count and read time, and flag anything outside the sizing rules.
5. Review: read each piece once on a phone for OCR errors and bad breaks.
6. Illustrate: generate and approve the card engraving.
7. Pack: bundle nights into packs of 30 as JSON plus images, versioned, and upload to the CDN.

**Curation balance per 30 nights**

- At least 10 authors who are not British or American, and at least 8 women.
- No author more than three times.
- A mix of moods across each week, so heavy pieces are followed by light ones.

## Architecture and data

The app is local-first: all state lives in SQLite on the device, and the only network calls are content pack downloads, purchases and analytics.

**Stack**

- Flutter, iOS first. Reuse the Daily Dharma scaffold for the shell, theming, notifications and streak logic where it fits.
- Riverpod for state, Drift for SQLite, go\_router for navigation.
- RevenueCat for subscriptions and the paywall.
- A static CDN (Cloudflare R2 or similar) for content packs. No custom backend.
- PostHog or Firebase Analytics for the funnel events.

**Content pack format**

- `pack-001.json` holds nights 1 to 30: the `days` rows and the `works` rows with full Markdown text.
- Images ship beside it as WebP at two sizes.
- Pack 1 is bundled in the app binary so night 1 works offline. Later packs download in the background when the user is within 10 nights of the end of their last pack.

**Schema**

| Table | Columns | Notes |
| --- | --- | --- |
| `works` | id, type, title, author, year, word\_count, est\_minutes, part\_label, text\_md, image\_path, source\_ref, rights\_note | type is story, poem or essay |
| `days` | day\_number, story\_id, poem\_id, essay\_id, pack\_id | One row per night |
| `progress` | work\_id, day\_number, scroll\_pos, started\_at, completed\_at | One row per piece opened |
| `nights` | day\_number, unlocked\_on, completed\_on, pieces\_done | Drives Tonight and Journey |
| `streak` | current, longest, last\_read\_date, freezes\_left, freezes\_reset\_on | Single row |
| `highlights` | id, work\_id, start\_offset, end\_offset, text, created\_at | Offsets into text\_md |
| `settings` | reminder\_time, theme, font\_step, line\_step, onboarding\_done | Single row |

**Events to track**

`onboarding_completed`, `reminder_enabled`, `piece_started`, `piece_completed`, `night_completed`, `streak_broken`, `paywall_shown`, `trial_started`, `purchase_completed`, each with `day_number`.

## Monetization

Nights 1 to 7 are fully free, and the hard gate is at night 8 with the line "Keep your 7-night streak."

**Flow**

- Onboarding ends with a skippable offer of a 7-day free trial.
- Night 8 shows the paywall before Tonight. Seven lit candles, the eighth unlit.
- Users who decline keep the poem each night, their streak and the Journey map. The story, essay, Library and freezes are locked.

**What a subscription includes**

- All three readings every night and the full Library of past nights.
- Two streak freezes a month.
- Highlights and all reader themes.

**Starting prices**

| Plan | US price | Notes |
| --- | --- | --- |
| Yearly | $29.99 | Default selection, 7-day free trial |
| Monthly | $4.99 | No trial |
| Lifetime | $59.99 | "All 1000 nights", one-time purchase |

Use App Store regional price tiers for India and other lower-income markets rather than a straight currency conversion.

**Tests to run after launch**

- Gate at night 8 versus night 4.
- Free tier of poem only versus no free tier.
- Lifetime shown versus hidden.

## Build phases

The build runs in five phases, each ending at a gate that must pass before the next starts. Content work runs alongside from phase 1 and must be done before launch.

&#91;embedded content: build roadmap · 5 phases, 4 gates, 1 parallel content track\]

Each diamond is a gate; the words under it are its exit test. Rough solo-developer estimate: about a week per phase and six weeks in total, assuming focused time.

### Phase 0: Foundations

- [ ] Create the repo from the Daily Dharma scaffold; strip what does not apply.
- [ ] Add theme tokens (colours, type scale, radii) and the Newsreader font.
- [ ] Define the Drift schema and migrations for all seven tables.
- [ ] Define the content pack JSON format and write the importer.
- [ ] Hand-build a 7-night test pack (21 pieces) with placeholder images.
- [ ] Set up the tab shell and routing with empty Tonight, Library and Journey screens.

**Gate:** the app launches, imports the test pack and shows night 1's three titles from the database.

### Phase 1: Reading loop

- [ ] Tonight screen: header, progress hairline, three cards, done states.
- [ ] Reader: Markdown rendering, drop cap, ribbon progress, saved scroll position.
- [ ] "Finish" action that writes progress and returns to Tonight.
- [ ] Night complete screen with the candle, quote and week dots.
- [ ] A debug menu to jump nights and reset state.

**Gate:** all 7 test nights can be read end to end on a real device, and progress survives an app restart.

### Phase 2: Habit

- [ ] Night unlock logic and streak rules, with unit tests for midnight, time zone changes and missed days.
- [ ] Journey: stats row, constellation renderer, milestone labels, tap a star to open a night.
- [ ] Onboarding flow with reading time and notification permission.
- [ ] Daily reminder and "streak at risk" local notifications.
- [ ] Analytics events wired up.

**Gate:** seven consecutive days of your own real use on TestFlight with no state bugs.

### Phase 3: Paywall

- [ ] RevenueCat setup: products, entitlement, offerings for yearly, monthly and lifetime.
- [ ] Paywall screen (seven candles) at onboarding and at night 8.
- [ ] Content gating for free users after night 7; restore purchases.
- [ ] Streak freezes for subscribers.
- [ ] Library: past nights list and highlights; highlight selection in the Reader.

**Gate:** a sandbox purchase unlocks night 8 in full, and a declined paywall leaves only the poem readable.

### Phase 4: Launch

- [ ] Reader settings: type size, line spacing, three themes.
- [ ] Motion pass: candle flicker, star lighting, transitions.
- [ ] Accessibility: Dynamic Type, VoiceOver labels, contrast check.
- [ ] CDN pack downloads with retry and offline handling.
- [ ] App Store listing: screenshots, description, privacy labels, review notes.
- [ ] TestFlight beta with 20 to 30 readers for one week; fix what they hit.
- [ ] Legal review of the content list, then submit.

**Gate:** approved on the App Store with 90 nights live.

### Content track (parallel, from phase 1)

- [ ] Master sheet with the first 90 nights curated against the balance rules.
- [ ] Fetch and extract script (Gutenberg text to a cut piece).
- [ ] Clean script (quotes, line joins, italics, stanzas) and the measuring step.
- [ ] Rights check for every work, recorded in `rights_note`.
- [ ] Read-through of all 270 pieces on a phone.
- [ ] Illustration style locked; 270 card images generated and approved.
- [ ] Packs 1 to 3 built and uploaded.

**Gate:** 90 nights reviewed and packed before the phase 4 beta starts.

## Risks and open questions

**Risks**

| Risk | Mitigation |
| --- | --- |
| Content work outruns the build: 270 pieces to clean and review for launch | Start the content track in phase 1; script everything except the final read-through |
| A rights mistake gets the app pulled | The 1930 rule, a `rights_note` on every work, and a legal review before submission |
| Users quit before night 8 and never see the paywall | Make nights 1 to 7 short and strong; test an earlier gate at night 4 |
| "It's just free books" reviews | Sell the ritual in the store listing; keep the poem free forever |
| App Review questions a paid app built on public domain text | Curation, original illustrations and the reader are the added value; say so in review notes |
| Illustration style drifts across 270 images | One fixed prompt and palette, batch review, generic fallbacks |

**Open questions**

- [ ] Final name: "1000 Nights" or "Thousand Nights"? Check App Store and trademark conflicts, including with One Thousand and One Nights titles.
- [ ] Does a night unlock at local midnight, or on the user's chosen reading time?
- [ ] Should free users after night 8 keep the poem, or rotate which piece is free?
- [ ] Who does the final read-through of each piece, and how many can be reviewed per day?
- [ ] Is the 7-day trial at onboarding worth offering when nights 1 to 7 are already free?
