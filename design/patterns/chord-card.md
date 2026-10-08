# Pattern: chord card

**Source:** ADR-049 §4 (no modal inside a run) · MOT-55 (Figma "Practice Shell — flows", row 11 and
14f / 15e; decisions D15, D18, D27) · MOT-76 (song chart practice)

## When

Use it whenever a student taps a chord symbol in a song chart: in practice, in the chord sheet and in
the song reader.

## Why

A student playing from a chart needs to look up a chord without losing their place. A modal would
stop the reading; a fixed dock under the chart would cover the lines they're about to play on a long
song.

## How

- **Floats, never a modal** (D18): the card sits over the chart, and the chart keeps scrolling and
  stays tappable. Tapping another chord shows that chord in the same card.
- **States:** Expanded (chord name, Box | Neck, the voicing, Strum, the voicing chips) and Minimized
  (a chip with the chord name). Scrolling on minimizes it; tapping the chip expands it. × closes it.
- **Placement:** the student drags it between corners. The chart gets bottom padding so its last lines
  can scroll above the card.
- **Voicings:** chips named by position — Open · 3fr · 10fr — never "1 of 3 ‹ ›". The choice is
  remembered per chord per song.
- **View:** Box | Neck switches between the chord box and the fretboard, remembered as the student's
  preference (D15, `diagrams.md`).
- **Strum** plays the voicing shown.
- **Size classes** (D27):
  - Compact: floats, as above.
  - Medium: floats in a corner of the side margin.
  - Expanded: docked in a side pane next to the chart. It opens on the first chord tap and shows the
    last chord tapped; × collapses the pane and the chart re-centres. Same component, only the
    placement changes.
- A popover anchored at the tapped chord suits the chord sheet better than playing: it covers the
  next lines and must close before reading on.

## Do not

- Open a chord in a dialog or a sheet during a run.
- Block scrolling or tapping the chart while the card is open.
- Page through voicings with arrows and a counter.
