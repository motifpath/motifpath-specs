# Pattern: practice session (the Practice Shell)

**Source:** ADR-049 §1, §4 and §5 · first used by PB-22 slice 3 Phase 7 · revised in MOT-55
(Figma "Practice Shell — flows", decisions D1–D27)

## When

Use it for every practice run: a practice session, a focused session on a chosen skill or concept
(MOT-77), an S7 challenge run, a song chart and any new practice kind. Never use it for browsing, summaries or authoring; those stay in the App Shell.

## Why

A student practises on a phone, often with the instrument in their hands. Global navigation during
a run is a way out that costs attention and taps. One fixed anatomy means every practice kind feels
like the same product.

## How

```text
┌────────────────────────────┐
│ ×          4 / 10          │  exit · position · (options, once one exists)
│ ██████████░░░░░░░░         │  progress, one segment per item
│ ITEM TITLE · why picked    │  what this item is, and why it's in the session
│          STIMULUS          │  what is played or shown
│         INTERACTION        │  what the student does
│                            │
├────────────────────────────┤
│  FEEDBACK · PRIMARY ACTION │  bottom action bar, thumb zone
└────────────────────────────┘
```

- **Phases:** setup → today's plan → run → summary. All of them sit in the shell.
- **Setup:** one screen asks both questions — the instrument in the student's hands (or **In my
  head**) and how long they have — with today's choice preselected, so **Start practising** is one
  tap (D1). **Practice** in the navigation opens the setup; from an instrument tab on the home, it
  opens with that instrument chosen. A second choice, **What to practise: Today's mix | I'll
  choose**, opens the focus picker (MOT-77, D22–D24); "Practise this" on a skill or concept opens
  the setup with the focus already chosen.
- **Nothing to practise:** when the chosen instrument has nothing to play, the way out is the
  primary action, never a secondary button under an error: **Choose what to practise** (D2, D20).
  A student who has never started a course or path gets **Find where to start** instead, which
  opens the first run on Home (`landing-and-first-run.md`, MOT-59 D9).
- **Today's plan:** before the first item, the session lists what it holds, in order: each
  play-along and exercise by its name, with why it was picked, and the fretboard cells grouped by
  drill with how many there are ("Name the note · 8 notes"). Its primary action is **Let's go**; ×
  leaves without starting the session, so nothing is recorded.
- **Item title:** every item names what it is above its stimulus: a play-along by its diagram's
  name, an exercise by its title. A fretboard cell's prompt is its title. The reason it was picked
  stays next to it.
- **Next up:** when a play-along's last take is rated, the run stays on a card in place before the
  next item: what was just played and the fastest tempo it was played at, then **Next:** the next
  item's name and why it was picked. **Continue** starts it. A song chart shows the song so far. After the session's last item the
  summary follows instead, with no card. Exercises and fretboard cells move on as before: they are
  short, and their title names the change.
- **Summary:** what the run did — minutes, instrument, items — then each item with its result
  ("up to 76 BPM · Clean", "6 of 8 right", "Not quite"), and the This week tiles of ADR-051. The
  primary action is **Done** (back to Home); **Practise again** is tertiary (D5).
- **S7 challenge run:** the same shell, not the App Bar. "How to answer" is an in-place disclosure,
  not a modal; "Ask my teacher" is a tertiary link under the options (D6). After Finish, the review
  lists each exercise with the student's answer and the right one (D7).
- **Errors and unavailable items** render in place; see `unavailable-and-errors.md`.
- **Exit (×):**
  - in setup, × goes back to where the student came from;
  - during a run, × ends the session as left early;
  - × never asks for confirmation: leaving is reversible, since the student starts a new session.
- **Position:** `n / N` and segmented progress. A play-along segment fills by takes.
- **Action bar:** fixed at the bottom, with padding for the safe area (`env(safe-area-inset-bottom)`).
  The primary action is at least 48 px tall and spans the bar on Compact.
- **Screen:** the screen stays on during a run (wake lock, released on exit, on finishing and when
  leaving the page). Height uses `dvh`.
- **Keyboard:** Enter or Space presses the primary action, keys 1–9 choose options, and Esc exits.
  This lets a Bluetooth page-turner pedal drive a run.
- **Back:** the browser's back button leaves the run like ×.

### Size classes (D25, D26)

The shell keeps hiding global navigation at every size: no rail and no sidebar during a run.

| | Compact (< 600 px) | Medium (600–839 px) | Expanded (≥ 840 px) |
|---|---|---|---|
| Text, options, feedback | full width, 24 px gutters | one centred column, 560 px max | one centred column, 560 px max |
| Action bar | at the bottom, primary spans it | at the bottom, content aligned to the column | at the bottom, content aligned to the column |
| Large stimulus (diagram) | readable size, scrolls (`diagrams.md`) | may leave the column: full width | may leave the column: up to 960 px |
| Stimulus that is also the interaction (image regions, diagram cells, song chart) | stacked | stacked | own pane on the left; prompt, feedback and options in a 400 px pane on the right |

The action bar never moves to the end of the content on wide screens: the thumb and the pedal find
it in the same place, and Enter covers a keyboard.

## Do not

- Show the app bar, the footer or any other navigation during setup or a run.
- Open a modal during a run. Information, feedback and explanations render in place.
- Put more than one primary action in the action bar.
- Rely on hover for any control.
- Show a navigation rail or sidebar during a run on a wide screen.
- Use two panes on Medium.
