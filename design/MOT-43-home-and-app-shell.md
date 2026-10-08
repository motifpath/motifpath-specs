# MOT-43 — App Shell, Home and Your progress

**Status:** Approved by the PO (Gilson), 2026-10-07
**Date:** 2026-10-07
**Decides under:** ADR-049 (experience language), ADR-051 (minutes and day streak, Accepted)
**Figma:** [MotifPath — Experience Language](https://www.figma.com/design/TJmPotheGhPe5npXMZWQEB):
pages *App Shell* (Option A), *Home — exploration* (H3, revised) and *Components*. Figma explores;
code and Storybook are the source of truth (ADR-049 §8).

## Decisions (Gilson, 2026-10-07)

| Topic | Decision |
|---|---|
| Bottom navigation | Option A: Home · Practice · My path · Learning · Discover. Rail on Medium, sidebar on Expanded. See `patterns/navigation.md`. |
| Home | H3, revised: Today's practice → Your path card → This week tiles → Your skills. Details on demand in Your progress. |
| This week tiles | Minutes (+ change vs the week before) · Day streak (+ best) · Skills up. Streak shown kindly (ADR-051). |
| Your skills / Your progress scope | Per instrument. No "All" choice: levels don't add up meaningfully across instruments. Your progress offers the student's instruments plus "Any instrument". |
| Typeface | **Manrope** (already the web face in tokens.json). |
| Rejected | App Shell options B ("Me" tab) and C (today's five as they are); Home H1 (too little) and H2 (too dense). Kept in Figma's *Archive* page. |

## Screens

**Home** (`features/web/home.feature`)

1. *Today's practice*: the top next step across instruments (`PracticeOverview.instruments[].top_next_step`,
   first card), its instrument and length, and the screen's only primary action, "Start practice".
2. *Your path*: path name, "8 of 14", a progress bar, and the next step with its kind. No length: lessons carry no duration (MOT-56, D4).
   The whole card opens the step. No second primary button.
3. *This week*: three `MetricTile`s from the overview (new fields, ADR-051). Tapping a tile opens
   Your progress.
4. *Your skills*: `LevelBar` (learning · accurate · fluent · retained) and a "N fading" chip from
   the practice summary of today's practice instrument. "See all" opens Your progress.

**Your progress** (pushed page, back returns to the home)

- `SegmentedControl` of the student's instruments + "Any instrument".
- This week tiles, practice days and learning days (`WeekDots`), Your skills, Moved this week
  (`SkillProgressRow` from `progress_this_week`).

## API changes (`openapi/core-domain-service.yaml` 0.29.0)

`PracticeOverview` gains `minutes_practised_last_7`, `minutes_practised_previous_7`,
`day_streak_current`, `day_streak_best` and `skills_up_last_7`. Scenarios:
`features/practice/practice-overview.feature`, tagged `@wip` until core implements them.
No new endpoint and no new event.

## Components

| Component | In code today | Work |
|---|---|---|
| NavigationBar / NavigationRail / Sidebar (`NavItem`) | No — AppBar with hamburger drawer | New; replaces the Compact drawer |
| Button variants (Secondary, Tertiary, Destructive) | Primary only (`PrimaryButton`) | New variants as screens need them |
| `MetricTile` | No | New |
| `LevelBar` | No (levels exist on the fretboard map) | New, uses the level colour tokens |
| `PathCard` | `FocusCard` / `StepRow` | New; replaces FocusCard on the home |
| `WeekDots` | `DayMarks` | Reuse DayMarks |
| `SkillProgressRow` | Inside `PracticeSummaryPanel` | Extract |
| `SegmentedControl` | No | New; also used by Discover |
| `Chip` | Inline badge classes | New |

Each new component gets a Storybook story (motifpath-web#100 enforces one per shared component).

## Typeface: Manrope

- Swap Tailwind's `font-sans` from Inter to Manrope (self-hosted, weights 400/500/600/700).
- **Manrope has no italic.** Italic marks in prompts and rich text are synthesized by the browser
  (slanted regular). Acceptable for emphasis; check PromptRenderer's italic in both themes.
- Manrope runs wider than Inter: recheck pt-BR labels on Compact (bottom bar, tiles, path card).

## Suggested slices (each its own PR, TDD)

1. Typeface swap to Manrope (tokens + Tailwind), with a pt-BR visual check in Storybook.
2. App Shell: NavigationBar / rail / sidebar, account menu with Teach, Discover with Courses | Paths.
3. Core: the five overview fields (ADR-051), then untag the `@wip` scenarios.
4. Home: Today's practice, PathCard, This week tiles, Your skills.
5. Your progress page.

## Approved

- The home (H3, revised) and Your progress, as above.
- ADR-051's definitions: minutes count every session (even left early); the streak ends at yesterday
  until today is over; skills up count once per instrument.
- A lower week's minutes still show the change, in a neutral colour (`features/web/home.feature`).
