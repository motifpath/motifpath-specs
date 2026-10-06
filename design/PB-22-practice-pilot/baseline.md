# Practice pilot — friction baseline

**Task:** PB-22 slice 3 Phase 7 · MOT-43 (ADR-049 §10)
**Measured:** 2026-10-06, motifpath-web `dev` at `d1d0ad1`, before the Practice Shell.

ADR-049 asks for a baseline before the pilot and the same measures after it. Taps are counted from
the screens as built, with the defaults a returning student sees: the first fretted instrument and
10 minutes are preselected.

## Measures

| Measure | Compact (< 600 px) | Medium / Expanded | After the pilot |
|---|---|---|---|
| Opening the app → first item (taps) | 3: menu → Practice → Start | 2: Practice → Start | 4 / 3: one more, the practice home (menu → Practice → Start practising → Start); the App Shell's bottom navigation will take the menu tap away on Compact |
| …with another instrument and length | 5 | 4 | 6 / 5, or 5 / 4 when the home's instrument tab is open, since the setup preselects it |
| Screens before the first item | 1 (the picker page, inside the App Shell) | 1 | 2: the practice home (App Shell), then the setup (Practice Shell) |
| Single-answer exercise (taps) | 3: choose → Check → Next | 3 | **1** when right (it moves on by itself); 2 when wrong (+ Continue, after the right option is revealed) |
| Multiple-answer exercise, *k* right options (taps) | *k* + 2: choose ×*k* → Check → Next | *k* + 2 | *k* + 1 when right; *k* + 2 when wrong |
| Play-along take (taps) | 2: Start take → rating | 2 | 2 (unchanged; Enter or a pedal can start a take) |
| Play-along item, 4 takes (taps) | 8 | 8 | 8 |
| Global navigation visible during a run | yes (app bar and footer) | yes | no |
| Wrong answer shows the right option | no | no | yes, for every option type |
| Time from opening the app to the first item | measured on Gilson's phone at `d1d0ad1` before the Phase 9 smoke | | |
| Sessions left early / abandoned | n/a: no real students yet; compared over team walkthroughs | | |

## Notes

- Today the latency of a single-answer exercise is taken when Check is pressed. That time includes the
  extra tap, which ADR-049 §3 removes.
- Every exercise asks for Next, even after a right answer.
- After (web#84–#86): the exercise taps fall by two thirds, while the home adds one tap before the
  first item. A pilot finding to weigh: a one-tap start from an open instrument tab (default minutes)
  would bring the start back to today's count.
- **2026-10-06, the home moved** (PB-22 slice 4 Phase 0b): the overview and instrument tabs became the
  app's general home, and Practice opens the setup directly. Opening the app → first item is back to
  **3 / 2** (menu → Practice → Start on Compact, Practice → Start wider), or **2** from the home the app
  opens on (an instrument tab's Start → Start). One screen comes before the first item: the setup.
