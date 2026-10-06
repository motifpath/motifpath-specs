# Practice pilot — friction baseline

**Task:** PB-22 slice 3 Phase 7 · MOT-43 (ADR-049 §10)
**Measured:** 2026-10-06, motifpath-web `dev` at `d1d0ad1`, before the Practice Shell.

ADR-049 asks for a baseline before the pilot and the same measures after it. Taps are counted from
the screens as built, with the defaults a returning student sees: the first fretted instrument and
10 minutes are preselected.

## Measures

| Measure | Compact (< 600 px) | Medium / Expanded | After the pilot |
|---|---|---|---|
| Opening the app → first item (taps) | 3: menu → Practice → Start | 2: Practice → Start | |
| …with another instrument and length | 5 | 4 | |
| Screens before the first item | 1 (the picker page, inside the App Shell) | 1 | |
| Single-answer exercise (taps) | 3: choose → Check → Next | 3 | |
| Multiple-answer exercise, *k* right options (taps) | *k* + 2: choose ×*k* → Check → Next | *k* + 2 | |
| Play-along take (taps) | 2: Start take → rating | 2 | |
| Play-along item, 4 takes (taps) | 8 | 8 | |
| Global navigation visible during a run | yes (app bar and footer) | yes | |
| Wrong answer shows the right option | no | no | |
| Time from opening the app to the first item | measured on Gilson's phone at `d1d0ad1` before the Phase 9 smoke | | |
| Sessions left early / abandoned | n/a: no real students yet; compared over team walkthroughs | | |

## Notes

- Today the latency of a single-answer exercise is taken when Check is pressed. That time includes the
  extra tap, which ADR-049 §3 removes.
- Every exercise asks for Next, even after a right answer.
