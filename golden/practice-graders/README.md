# Practice grader golden cases

Language-neutral cases that pin what each practice grader returns. The server's graders
(Go, in motifpath-core) and the web client's instant-feedback graders (TypeScript, in
motifpath-web) both run every case here, so a student never sees feedback that the record
contradicts.

## Files

- `<grader>.v<version>.json`: one file per grader version, for example
  `fretboard_cell.v1.json`. A file is never edited once a consumer ships that version,
  except to add cases. A rule change is a new version in a new file, and the old file stays
  for the evidence it graded.
- `schema.json`: the JSON Schema every case file follows.

Each file holds:

- `grader`: the grader id, matching the file name.
- `reference`: the reference data the grader reads. Anything an item key points at that is
  missing here counts as unknown.
  - `instruments`: layout instruments with their tuning, lowest string first.
  - `exercises`: options, and which of them are correct.
  - `diagrams`: the diagrams that exist.
- `cases`: each case is an `item_key`, a raw `response` (as a client sends it in
  `practice.item_answered`) and the `expected` result. The result is either
  `{"result": "graded", "evidence": {...}}` or `{"result": "rejected", "reason": "..."}`.

## Rules every grader follows

- **The grader for an item comes from its key's kind:**
  - `fretboard_cell` → `fretboard_cell.v1`
  - `exercise` → `exercise_option.v1`
  - `play_along` and `chord_change` → `self_rating.v1`
- **Checks run in this order, and the first failure is the rejection:**
  1. The response type fits the item kind (`response_does_not_fit_item`).
  2. What the key points at exists (`unknown_reference`).
  3. The cell or the selected options exist (`invalid_cell`, `unknown_option`).
  4. The response carries the measure its kind needs, and no other (`measure_missing`,
     `response_does_not_fit_item`).
- **A rejection stores no evidence.**
- **Auto-graded evidence** is `source`, `correct` and `latency_ms`, with `latency_ms` copied
  from the response.
- **Self-assessed evidence** is `source`, `rating` and the one measure its kind takes:
  `tempo_bpm` for a play-along, `changes_per_minute` for a chord change.

### `fretboard_cell.v1`

- Strings count from 1, the highest-pitched. The tuning lists the lowest string first, so
  string 1 is the last entry. A cell's pitch is its string's open pitch raised by the fret
  number, in semitones.
- **Name the note:** right when the named note is the cell's pitch class, in any spelling
  (`F#` and `Gb`, `E#` and `F`, `Cb` and `B`).
- **Find the note:** right when the tap is on the asked string and has the asked pitch
  class. Any octave counts, so fret 13 finds the same note as fret 1. The same pitch on
  another string is wrong.
- A string outside 1 to the tuning's string count, in the key or in a tap, is
  `invalid_cell`.

### `exercise_option.v1`

- Right only when the selected options are exactly the exercise's correct options, in any
  order. Selecting fewer or more is wrong.
- Selecting an option the exercise doesn't have is `unknown_option`.

### `self_rating.v1`

- The rating and its measure are kept as given. A take of zero chord changes is still a
  rating.
- A play-along needs `tempo_bpm` and takes no `changes_per_minute`. A chord change needs
  `changes_per_minute` and takes no `tempo_bpm`.

## Using the cases

The specs repo is read as a sibling checkout (`../motifpath-specs`), the same way core and
web read the OpenAPI specs. A consumer test loads every `*.v*.json` file for the graders it
implements, builds its reference lookups from `reference`, and checks that each case gives
exactly `expected`.

`npm run validate:golden` (run in CI) checks three things:

- every file against `schema.json`;
- each file name against its grader id;
- every case's `item_key` and `response` against `PracticeItemKey` and `PracticeResponse` in
  `openapi/components/schemas/practice.yaml`.
