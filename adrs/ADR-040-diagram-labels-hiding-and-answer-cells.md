# ADR-040: Per-use diagram labels and position hiding, and fretboard cells as diagram exercise answers

**Status:** Proposed
**Date:** 2026-09-28
**Deciders:** Gilson (Product Owner)
**Partially supersedes:** ADR-028's `diagram_ref.layers` (`intervals`, `subset`) and its rule that a
diagram-driven `image_recognition` exercise's clickable options are the diagram's visible positions.
Everything else in ADR-028 stands.

---

## Context

The first authoring UI for diagram embeds (the shared diagram picker, used by rich text, video and
article pop-ups, and the exercise editor) exposed three limits of the `diagram_ref` render config as
ADR-028 defined it.

**Labels are a yes/no, but authors choose among four.** `layers.intervals` is a boolean: show the
interval label, or not. A diagram's markers can show an interval, a note name, an author's custom
label (ADR-034), or nothing, and the right choice depends on where the diagram is used. The same
pentatonic box is labelled by interval in a theory lesson and by note name in a fretboard-memory
drill. Today the only per-diagram choice is the stored `label_display`, which every usage inherits.

**Hiding works only by whole interval.** `layers.subset` keeps the positions whose interval is in a
list. An author can't hide one particular position, for example the root on the 6th string but
not the one on the 4th.

**A diagram exercise gives its answers away.** ADR-028 made each visible position one clickable
option, and `correct_intervals` marks which intervals are correct. So everything a student can tap
is a drawn marker: the exercise shows where the notes are and asks only which ones are correct. An
author can't ask "find the roots of this shape" without drawing them, and a student can never
answer wrong by tapping an empty fret or an open string. Gilson's requirement: every position the
author picks is a correct answer, **drawn or hidden**, and every other fretboard cell in view,
open strings included, is a wrong answer.

## Decision

### 1. A per-use label mode

`diagram_ref.layers` gains `label: "interval" | "note" | "custom" | "none" | null`.

- `interval` / `note` show the position's interval or note name.
- `custom` shows the position's custom label (ADR-034) where it has one, and otherwise what the
  diagram's own `label_display` shows.
- `none` shows no text in the markers.
- `null` (or absent) keeps the old behaviour: `layers.intervals: false` means `none`, and anything
  else means the diagram's own `label_display`.

`layers.intervals` becomes optional and deprecated. It is still read when `label` is absent, but
new refs write `label` instead.

### 2. Per-position hiding

`diagram_ref.layers` gains `hidden_position_ids: uuid[] | null`: positions of the diagram that
this usage doesn't draw. `layers.subset` stays valid and is still honoured (a position is drawn
only if it passes both), but the picker no longer writes it. Its interval shortcuts hide or show
every position of an interval by writing `hidden_position_ids`.

### 3. Author-marked correct positions

For an `image_recognition` exercise's `diagram_ref`, `correct_position_ids: uuid[]` (at least one,
each a position of the diagram, hidden or not) replaces `correct_intervals`. `correct_intervals`
is deprecated: when a request gives it without `correct_position_ids`, the server converts it once,
at save, to the drawn positions whose interval is listed, which is its old meaning.

### 4. Fretboard cells are the answer options

For a fretted diagram stimulus, the server derives **one option per fretboard cell in the answer
window**, instead of one per visible position:

- **Answer window.** Over **all** the diagram's positions (hidden ones included) and its regions,
  take `low = max(min fret − 1, 0)` and `high = low + max(max fret + 1 − low, 3)`. This is the
  viewer's fret window, computed over every position rather than the drawn ones. With no positions
  or regions, `low = 0` and `high = 3`.
- **Cells.** Every string `1..string_count` at every fret `low + 1 .. high`, plus fret `0` (the open
  string) on every string **when `low = 0`**, meaning the window reaches the nut and the open
  strings are drawn.
- **Each cell option** carries `fret_cell {string, fret}`, and `diagram_id`/`diagram_position_id`
  when a position of the diagram occupies that cell. It is correct exactly when that position's id
  is in `correct_position_ids`. Every other cell is a wrong answer, whether it's an unmarked
  position, an empty fret or an open string.

Grading and answer events are unchanged: a student selects option ids, and the exercise is graded
by the options' `is_correct`, as for every other exercise type. The viewer makes every cell of the
window tappable: drawn markers as today, and empty cells as a quiet target.

Keyboard diagrams keep position-only options until a keyboard viewer exists, since there is no
agreed key window to derive cells from yet. A stacked stimulus (never authored by the picker) keeps
ADR-028's behaviour.

## Rationale

- **Cells derived by the server, graded by option id** (chosen) keeps one grading path for every
  exercise type and leaves `exercise.answer_sent`, the practice attempt model and the analytics
  untouched. Rejected alternative: **grade by coordinates** (the student's answer is a set of
  string/fret pairs). It needs no window rule, but it changes the answer payload, the grading code
  and every consumer of answer events, only to avoid a deterministic rule both sides can share.
- **The window rule lives in the spec**, not only in the viewer's code, because the server has to
  derive the same cells the student sees. Reusing the viewer's existing rule (one fret either
  side, at least three frets, nut-anchored) means students see exactly the cells they can answer.
  Computing it over all positions keeps a hidden correct answer inside the window.
- **Open strings only when the window reaches the nut.** A shape at the 5th fret is drawn without
  the nut, so there would be nowhere to tap an open string. Rejected: always adding an open-string
  column. It would draw a disconnected strip to the left of every high shape, only to hold answers
  that are wrong by construction.
- **Author-marked positions over intervals.** Intervals can't say "this root, not that one", and
  can't be made to mean "correct but hidden". Rejected: **every diagram position is correct**. It
  is simpler, but "tap every root" would then need a separate roots-only diagram in the library.
- **`label` replaces a boolean** with the four choices authors actually make. Falling back to the
  diagram's `label_display` for `custom` is Gilson's rule: a custom label is an exception layered
  on the diagram's own default, as in the editor.
- **Additive, deprecate-don't-remove** for `intervals`, `subset` and `correct_intervals`: stored
  refs in content bodies, pop-ups and exercises keep rendering and grading as before, with no data
  migration.

## Consequences

### Positive
- Authors choose labels per usage, hide single positions, and mark individual positions correct.
- Diagram exercises test knowledge instead of recognition: nothing correct is given away, and
  wrong answers exist everywhere on the visible fretboard.
- Grading, answer events and practice analytics are unchanged.

### Negative / Trade-offs
- The window rule is duplicated in core (option derivation) and web (viewer). Drift would make a
  cell unanswerable or an answer undrawable. Mitigation: the rule is specified here and in the
  OpenAPI description, and both sides test the same cases.
- A diagram exercise now has ~20–40 options (6 strings × 4–6 frets, plus open strings) instead of
  a handful. Payloads and stored option rows grow proportionally; this is still small.
- Three fields become deprecated-but-honoured (`layers.intervals`, `layers.subset`,
  `correct_intervals`). Readers must keep handling them until a later cleanup removes them.
- Open strings are not answerable for shapes whose window doesn't reach the nut.

### Neutral
- Options are still snapshotted at save. Editing the diagram afterwards doesn't change a saved
  exercise's cells, which is the existing behaviour for derived options.
- `image_choice` options' own `diagram_ref`s get `label` and `hidden_position_ids` like any other
  usage, and ignore `correct_position_ids`.

## Related ADRs

- [ADR-028: Diagram as a first-class content entity](./ADR-028-prebuilt-diagram-content-model.md): the `diagram_ref` shape and diagram-driven options this partially supersedes.
- [ADR-019: Practice content model](./ADR-019-practice-content-model.md): option-selection grading, which this keeps.
- [ADR-030: Diagram as an embedded resource](./ADR-030-diagram-embedded-resource.md): the embed points that carry these refs.
- [ADR-034: Diagram annotations](./ADR-034-diagram-annotations.md): custom labels, which `label: custom` shows.

---

*This ADR was decided on 2026-09-28. To revise, create a new ADR with Status: Supersedes ADR-040.*
