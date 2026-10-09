# MOT-63 — Design sign-off review

**Status:** **Signed off by the PO (Gilson), 2026-10-09.** Every MOT-43 implementation slice is unblocked by design.
**Date:** 2026-10-09
**Gate for:** every MOT-43 implementation slice (MOT-64…MOT-97)
**Figma:** [MotifPath — Experience Language](https://www.figma.com/design/TJmPotheGhPe5npXMZWQEB)

All nine design items are Done (MOT-55…MOT-62, MOT-73). This review covers the four passes MOT-63
asks for. It used scripts over the whole Figma file (every page, component and colour variable),
contrast computed from the variable values, and the Linear slices and specs as of today.

## Summary

| Pass | Result |
|---|---|
| Coverage (sizes, dark, pt-BR) | Complete on 9 pages. **Gaps:** Home + Your progress, and Install (D5). |
| Library consistency | Every component fill and stroke is bound to a variable. Code tokens (`motifpath-web/src/design/tokens.json`) match Figma exactly. Hygiene items below; none block. |
| Accessibility | **One real failure:** `ink-subtle` text (D1). Small fixes: level colours (D2), warning (D3), two tap targets (D4). Colour is never the only cue. |
| Slices vs final designs | **Home lost "Skills up" to Songs today**, but MOT-65/66, ADR-051, `home.feature` and OpenAPI still say Skills up (D6). No implementation ticket for the Practice Shell itself (D7). |

## Decisions taken (Gilson, 2026-10-09)

| # | Decision | Where it landed |
|---|---|---|
| D1 | A: change the `ink-subtle` token | Figma variables (Light `#70698A`, Dark `#8682A1`); code in MOT-71 |
| D2 | Per-mode level colours | Figma variables (accurate Dark `#6959C5`, fluent Light `#19A472`); code with LevelBar in MOT-66 |
| D3 | Light `warning` `#B25209` | Figma variables; code in MOT-71 |
| D4 | 40 px reason chips; 8 px star gap | Figma Overlays (12 chips, all copies) and Learning (8 star rows); 48 px hit areas noted in MOT-82 |
| D5 | **Draw the missing rows before any implementation** | Done 2026-10-09. Home page: Dark·pt-BR (Compact), Medium (rail, one 560 px column) and Expanded (sidebar, two columns) rows for Home and Your progress. Offline & install: Dark·pt-BR copy of row 3 and a new row 4, Expanded desktop Chrome (summary + InstallCard, Chrome's own dialog, the account menu's Install row) |
| D6.1 | **Keep `skills_up_last_7`**; it moves to Your progress | MOT-65 unchanged; MOT-67 shows Skills up |
| D6.2 | **Songs = songs played from `song_chart.completed` now; repertoire (MOT-76) later** | New core ticket MOT-99; ADR-051 amendment, OpenAPI and features in their own spec PR |
| D7 | Clean up and organise the tickets | New MOT-98 (Practice Shell) and MOT-99; MOT-64/66/67/71/82 updated; "Blocked" label on every slice MOT-63 blocks |

pt-BR findings from D5: "Qualquer instrumento" doesn't fit a third of the SegmentedControl on
Compact, so the segment reads "Qualquer" there (full label from Medium up); This week captions run
to two lines and every tile grows with them; Day streak is "Dias seguidos" everywhere (Practice
Shell wording). Your progress now shows four This week tiles in a 2×2 grid on Compact and in one
row from Medium up (Skills up, D6.1).

Song charts carry no instrument (the chord catalog is guitar-only, ADR-045), so the Songs count
isn't per instrument until MOT-76 decides it (song-chart.md D19).

## Decisions for the PO (as proposed)

### D1 — `ink-subtle` fails as text (blocking)

`ink-subtle` is 2.80:1 on `surface` (Light) and 3.66:1 (Dark), but it colours about 350 text nodes
at 12–16 px, for example eyebrows ("INSTRUMENT IN YOUR HANDS", "VERSE 1", "WHAT YOU PRACTISED"),
hints ("Tap an option, or press 1–2."), card metadata ("Guitar · 4 parts · 44 lessons"), step
numbers, the landing footnote and placeholders. Text needs 4.5:1.

- **A (recommended):** change the token. Light `#9A94AE → #70698A` (4.96 on surface, 4.58 on
  sunken); Dark `#6E698C → #8682A1` (5.15 on surface, 4.57 on raised). It stays a step lighter than
  `ink-muted`, so the hierarchy holds. It is one change in Figma and one in `tokens.json`, and it
  also fixes today's app.
- B: move every text use to `ink-muted` and keep `ink-subtle` for disabled and decorative only.
  This loses one text level and touches about 350 nodes.

### D2 — Level colours are the same in both modes

`color/level/*` has one value for Light and Dark. As fills (LevelBar, legend dots) they need 3:1:
`accurate` is 2.21:1 on Dark surface and `fluent` is 2.71:1 on Light surface. The LevelBar has
text labels, so colour isn't the only cue. The bars still need to be visible.

- **Recommended:** give each its own mode value: `accurate` Dark `#6959C5` (3.45), `fluent` Light
  `#19A472` (3.07). The others pass.

### D3 — Warning text on its muted background

`warning` on `warning-muted` is 4.47:1 in Light (Chip, SelfRating, InlineNotice, StepRow "Only in
English for now", ConnectionBar, StatusPanel). **Recommended:** Light `warning` `#B45309 → #B25209`
(4.55). The difference isn't visible.

### D4 — Two tap targets under 48 px

- **Report a problem → "What went wrong?"** (Overlays row 3, Compact sheet and dark copy): the
  reason ChoiceChips are 24 px high with 8 px gaps, a 32 px pitch. **Recommended:** use the
  library's 40 px ChoiceChip with an 8 px gap, as in Discover's filters.
- **Course rating stars** (Learning row 3): 40 px stars with 4 px gaps, a 44 px pitch.
  **Recommended:** 8 px gap.

Checked and fine: Avatar 32 in a 48 hit area; Segment 40 inside a 48 SegmentedControl; ChoiceChip
40 in 48-pitch rows; Chip 24 is display-only (status, meta); Switch sits in full-width rows; the
34 px table toolbar and the 44 px SidebarItem are on Expanded only (pointer).
For implementation: chips and stars get a 48 px hit area even where the visual is smaller.

### D5 — Coverage gaps

The rows below were approved before the "Compact + Medium + Expanded + Dark·pt-BR" convention, or
skipped it:

| Screen | Has | Missing | Gates |
|---|---|---|---|
| Home (H3) | Compact light/dark, English | pt-BR; Medium; Expanded | MOT-66 |
| Your progress | Compact light, English | Dark; pt-BR; Medium; Expanded | MOT-67 |
| Install (Offline & install, row 3) | Compact light, English | Dark·pt-BR; Expanded (desktop Chrome install) | MOT-91 |

The offline rows 1–2 on the same page belong to MOT-89 (after the store apps) and are out of scope.
**Recommended:** draw the missing rows before sign-off, in the same style as the other pages.

### D6 — Skills up → Songs: the slices still say Skills up

`design/MOT-43-home-and-app-shell.md` was revised today (MOT-73 D17): the third This week tile is
**Songs** (in your repertoire, + this week), not Skills up. These still say Skills up:

- MOT-65 (core, **In Progress**, no branch yet): `skills_up_last_7` in `PracticeOverview`.
- MOT-66 scope; `features/web/home.feature` ("This week shows minutes, day streak and skills up");
  ADR-051 §3; `openapi/core-domain-service.yaml` (`skills_up_last_7`, required).

Decide before MOT-65 writes code:

1. Is `skills_up_last_7` dropped, or kept only for Your progress? (Your progress already has
   "Moved this week" from `progress_this_week`, so **drop** is the recommendation.)
2. Where does the Songs count come from: `song_chart.completed` events (MOT-96, available now), or
   repertoire from MOT-76 (Backlog)? If MOT-76, Home's third tile waits for it.

Then: ADR-051 amendment, OpenAPI, `home.feature`, MOT-65 and MOT-66 updated together (spec first).

### D7 — Slice tickets to align

- **No implementation ticket for the Practice Shell** (MOT-55 rows 1–15: PracticeHeader,
  OptionTile, PracticeActionBar, SelfRating, Next up, summary, S7 challenge run, row 12 errors,
  Medium/Expanded). Only the follow-ups exist (MOT-74…80). **Recommended:** file one, blocked by
  MOT-63, linked to PB-22 slice 3 Phase 7 (on hold as the pilot).
- **MOT-64 and MOT-82 both claim the account menu.** MOT-64 says "Account menu with Teach for
  authors"; MOT-82 implements the account menu (MOT-60). **Recommended:** MOT-82 owns the menu;
  MOT-64 only places the avatar and the Teach entry.
- **MOT-66 (written 2026-10-07)** predates MOT-59/60/73: add the first-run hand-off (MOT-88 owns
  the first run), the standard states from MOT-82, the Songs tile (D6) and the size classes (D5).

## Library hygiene — done 2026-10-09

- **Text styles:** 199 text nodes in components and screens now use the Manrope text styles, but
  only where a style matches the font, weight, size, letter spacing and case, and only where binding
  doesn't change the owner's size. 51 were left unbound because the styles' fixed line heights would
  grow them by 2–3 px (NavItem, LevelBar, SkillProgressRow, PathStep, WeekSummary, PathCard,
  FocusRow, the Home screens). Off-scale combinations with no style: Medium 14, Medium 11,
  SemiBold 11–13 and 15, sentence-case SemiBold 12, Bold 15/16/18/20 (mostly the wordmark and
  annotations), plus the scaled diagram labels. **For implementation:** code uses the token scale;
  map these to the nearest style rather than adding sizes, and keep the line height the component
  needs (MOT-71 rechecks).
- **Scrim:** one variable `color/scrim/scrim` (Light `#0F0D1F`, Dark `#000000`, web
  `rgb(var(--color-scrim))`) at 40% on every scrim (67 across 7 pages; 16 were at 45%). Add
  `scrim` to `tokens.json` in MOT-71.
- **Icons:** all 84 `Icon/*` components now live in one Icons grid on the Components page, every
  instance still linked. Three unused duplicates were deleted (`rotate-ccw`, `file-text`,
  `ellipsis-vertical`). The two chevrons weren't duplicates (20 px for compact rows, 24 px), so the
  20 px one is now `Icon/chevron-right-20`.

### Hygiene as found in the review

- Base components set text without text styles: Button, Chip, NavItem, Segment, MetricTile,
  LevelBar, PathStep and others (about 100 text nodes). Same in a few feature components
  (OverviewStrip, DiagramTile, SoundSource, StatusPanel). Bind them to the Manrope styles.
- Three scrims: `#000000` at 40%, `#0F0D1F` and `#0D0A1A`. One scrim token (`color/scrim`) for
  both modes.
- On screens, the App Shell nav labels are drawn by hand (unstyled SemiBold 14) instead of NavItem
  instances, and the wordmark is 15 px in some app bars and 16 px in others.
- Video player chrome uses raw `#171421` and white. Media stays dark in both modes, so this is
  intended; name it (`color/media/*`) when the player is built (MOT-55 / Vidstack, ADR-025).
- Icons: 87 `Icon/*` components spread over seven pages, four of them duplicated
  (`Icon/rotate-ccw`, `Icon/file-text`, `Icon/ellipsis-vertical`, `Icon/chevron-right`).
  Move them to the Components page and keep one of each.
- Leftover Inter appears only in design notes and the drawn Chrome install sheet (intended).

## Not in this review

Offline and sync states (MOT-89), and the store apps. The design notes on each page stay English
by decision.
