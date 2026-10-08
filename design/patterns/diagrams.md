# Pattern: diagrams in practice

**Source:** ADR-049 §2 (Diagram with playback) · ADR-041 (diagram content) · MOT-55 (Figma
"Practice Shell — flows", rows 7–10, 14, 15; decisions D12–D16, D26)

## When

Use it whenever a practice item shows an instrument diagram: a fretboard drill, a scale or shape to
play along with, a chord, a diagram embedded in a prompt, or a diagram option.

## Why

A student taps diagrams with the instrument in their other hand, so markers must stay big enough to
hit. A full neck doesn't fit a phone at that size, and shrinking it makes every marker a guess.

## How

- **Shared components:** `Fretboard` (Frets = the window drawn: 5 for drills and shapes, 12 for a
  full neck; Strings = 4, 6 or 7; Layout = horizontal or vertical), `FretMarker` (Note · Root ·
  Sounding · Asked · Right · Wrong), `ChordBox` with `ChordDot` and `ChordBarre`. No screen draws its
  own board.
- **Markers keep tap size:** at least 28 px drawn and a 44 px hit area, at every size class. The
  sounding note is the dashed yellow ring of the reviewed PB-71 spike.
- **Too wide to fit** (D12, every diagram, animated or not): the board scrolls sideways at readable
  size, with an **overview strip** under it. The strip's window follows the scroll both ways:
  scrolling the board moves the window; dragging or tapping the window scrolls the board. During
  playback the board follows the sounding note.
- **Fit-to-width** is allowed only for a diagram the student doesn't tap (a read-only stimulus).
- **Wider screens** (D26): a diagram may leave the 560 px text column — full width on Medium (720 px),
  up to 960 px on Expanded. A 12-fret neck then fits at tap size and the overview strip is hidden;
  it shows only when a diagram still doesn't fit. In landscape on a phone, a 12-fret neck shows whole.
- **Diagram stack:** two diagrams on one board, each in its own hue, named in a legend (never colour
  alone).
- **Chords** (D15): the author sets the default view per usage — chord box or fretboard — and the
  student switches in place with **Box | Neck**, remembered as their preference. Same diagram data
  either way.
- **Audio from a diagram** (D14, proposal in MOT-74): a listening exercise may play a diagram instead
  of an uploaded clip. The board stays hidden until the answer; then "What you heard" reveals it.
- **Keyboard diagrams** (D13): post-v1 (MOT-34). Drawn as a `Keyboard` component that scrolls like a
  fretboard.

## Do not

- Shrink markers below tap size to make a diagram fit.
- Fit a tappable diagram to the screen width.
- Draw a board by hand on a screen instead of using the shared components.
- Tell diagrams in a stack apart by colour alone.
