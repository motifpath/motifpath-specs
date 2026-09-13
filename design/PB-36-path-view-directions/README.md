# PB-36 — Path view redesign: Phase 1 directions

Four layout directions for "My Path" (`PathStep`/`PathContent`), each shown at mobile portrait,
mobile landscape, and desktop, built from the real `motifpath-brand` tokens. A single static
HTML page (not a design-canvas prototype), with a light/dark toggle.

**Published version (with live comment history):**
https://claude.ai/code/artifact/7d019ff3-c305-49cd-b694-5995fccfd98c

## Directions

- **A — Refined list**: closest to what ships today; only the current step gets a distinct
  treatment. No new component.
- **B — Step cards**: every step is its own bordered card with a status badge and pill. No new
  component.
- **C — Focused timeline**: a connecting rail plus a larger focus card for the current step;
  reflows to a side-by-side rail + focus layout at landscape/desktop. Most likely to need a new
  ("7th") shared primitive beyond the existing six owned components.
- **D — Cards + focus** (added after review feedback on C): blends B's step cards for every
  collapsed step with C's focus card for the current step only, dropping C's rail. A smaller
  candidate for the same 7th-primitive question.

## Status

Phase 1 sketches only — **the Phase 2 decision checkpoint (pick one direction; confirm whether
it needs a 7th shared primitive) was still open as of 2026-09-13.** Plan file:
`plans/PB-35-path-view-redesign.md` (still under its pre-epic-split name).
