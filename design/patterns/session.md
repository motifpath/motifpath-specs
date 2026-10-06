# Pattern: practice session (the Practice Shell)

**Source:** ADR-049 §1, §4 and §5 · first used by PB-22 slice 3 Phase 7

## When

Use it for every practice run: a practice session, and later the S7 challenge and any new practice
kind. Never use it for browsing, summaries or authoring; those stay in the App Shell.

## Why

A student practises on a phone, often with the instrument in their hands. Global navigation during
a run is a way out that costs attention and taps. One fixed anatomy means every practice kind feels
like the same product.

## How

```text
┌────────────────────────────┐
│ ×          4 / 10          │  exit · position · (options, once one exists)
│ ██████████░░░░░░░░         │  progress, one segment per item
│                            │
│          STIMULUS          │  what is played or shown
│         INTERACTION        │  what the student does
│                            │
├────────────────────────────┤
│  FEEDBACK · PRIMARY ACTION │  bottom action bar, thumb zone
└────────────────────────────┘
```

- **Phases:** setup (what the student holds and how long they have) → run → summary. All three sit in
  the shell. Setup asks one question per step, with today's choice preselected, so a returning
  student starts in two taps from the practice home.
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

## Do not

- Show the app bar, the footer or any other navigation during setup or a run.
- Open a modal during a run. Information, feedback and explanations render in place.
- Put more than one primary action in the action bar.
- Rely on hover for any control.
