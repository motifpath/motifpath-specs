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
  - `diagrams`: the diagrams that exist. A drill shape also has its layout instrument, its
    family and member, and its positions with their intervals.
  - `shape_families`: each shape family's members, in the order they are offered.
  - `progressions`: progressions of the progression catalog by key, with their numerals one
    bar each. Keys, numerals, chords and chord tones are computed, so they have no reference.
- `cases`: each case is an `item_key`, a raw `response` (as a client sends it in
  `practice.item_answered`) and the `expected` result. The result is either
  `{"result": "graded", "evidence": {...}}`, `{"result": "graded", "evidence_by_item": [...]}`
  for an answer graded on several items (each entry an `item_key` and the `evidence` stored on
  it), or `{"result": "rejected", "reason": "..."}`.

## Rules every grader follows

- **The grader for an item comes from its key's kind:**
  - `fretboard_cell` → `fretboard_cell.v2` (`fretboard_cell.v1` before 2026-10-08; its file stays
    for the evidence it graded), or `multi_tap.v2` when the response is `multi_tap`
  - `exercise` → `exercise_option.v1`
  - `play_along`, `chord_change`, `chord_voicing`, `root_fifth`, `root_change` and
    `progression_keys` → `self_rating.v1`
  - `diagram_shape` → `diagram_shape.v1`
  - `diatonic_chord`, `chord_function`, `chart_progression`, `heard_chord` and
    `heard_progression` → `generated_choice.v1`
  - `guide_tone` → `timed_taps.v1`
  - `fretboard_note` → `multi_tap.v1`. Retired before it was installed: it never graded an
    answer, and its file goes once core and web drop it.
- **Checks run in this order, and the first failure is the rejection:**
  1. The response type fits the item kind (`response_does_not_fit_item`).
  2. What the key points at exists (`unknown_reference`).
  3. The cell, the selected options, the named shape or the asked degree exist
     (`invalid_cell`, `unknown_option`, `degree_not_in_shape`), and a note's choices are
     valid (`invalid_choices`), in that order.
  4. The response carries the measure its kind needs, and no other (`measure_missing`,
     `response_does_not_fit_item`).
- **A rejection stores no evidence.**
- **A `not_answered` response is never graded.** It fits every item kind, reaches no grader and
  yields no evidence, so it has no cases here.
- **Auto-graded evidence** is `source`, `correct` and `latency_ms`, with `latency_ms` copied
  from the response, plus `audio_ms` copied from it when the response carries one.
- **Auto-graded evidence keeps its `answer_key`:** what a right answer was when it was graded,
  so a disputed answer can be checked from the evidence alone. For a fretboard cell, the asked
  `string` and `fret` and the cell's `note_name`, spelled with sharps (any spelling of that
  pitch is right, and for find the note any octave on that string), plus the `choices` exactly
  as sent when the note was named among them. For an exercise, its
  `options` in the exercise's order, each with `option_id` and `is_correct`; the server also
  copies each option's content (label, image, audio, region, diagram), which these cases
  don't pin since their reference has none. The server stores it; a client's instant
  feedback may ignore it.
  For a named diagram shape, its `shape_family` and `shape`. For a degree found on one, the
  asked `interval` and the `cells` (string and fret) of every position of the shape that is
  that interval, in the diagram's position order. For a generated question, its `way`, its
  `music_key` when the item doesn't fix one, the right `answer` and the options `offered` as
  shown. For a guide-tone take, its `music_key`, `tone` and `bars`. For a note found
  everywhere, its `note_name`, `fret_window` and `cells`.
  Adding it to `exercise_option.v1`'s cases changes no grading rule.
- **Self-assessed evidence** is `source`, `rating` and the measure its kind takes:
  `tempo_bpm` (and its `note_value`, when sent) for a play-along, the same plus `music_key`
  for a progression key tour take, `tempo_bpm` and
  `changes_per_minute` for a chord change or a root change, none for a chord voicing or a root
  and fifth.

### Music in the new graders

- **A key** is a major key, spelled as the chord catalog spells roots (C D♭ D E♭ E F F# G A♭ A
  B♭ B, written `Db`, `Eb`, `Ab`, `Bb`).
- **The numerals** are I ii iii IV V vi viio (vii°), and their chords are the key's triads:
  major on I IV V, minor on ii iii vi, diminished on viio. A progression's I7, IV7 and V7 are
  dominant sevenths.
- **A chord symbol** is a root, then `m`, `dim`, `7` or nothing. A root may be spelled either
  way in a response (`F#m` and `Gbm` are one chord); an answer key spells it as the catalog
  does, even where the key would spell it otherwise (IV of D♭ is kept as `F#`).
- **Functions:** I iii vi are tonic, ii IV subdominant, V viio dominant.

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

### `fretboard_cell.v2`

Every `fretboard_cell.v1` rule, plus four choices for name the note:

- **Name the note with `choices`:** the four choices must be four different pitches (`C` and
  `B#` are one pitch), include the cell's pitch and include the note named; otherwise
  `invalid_choices`. The choices are kept in the answer key in the order and spelling sent.
  Which near notes a client offers is the client's rule (ADR-046) and isn't checked here.
- **Name the note without `choices`:** an answer given on the earlier twelve-note keypad,
  graded exactly as `fretboard_cell.v1` graded it, with no choices in the answer key.
- A string outside the tuning is `invalid_cell` before any check of the choices.

### `exercise_option.v1`

- Right only when the selected options are exactly the exercise's correct options, in any
  order. Selecting fewer or more is wrong.
- Selecting an option the exercise doesn't have is `unknown_option`.

### `diagram_shape.v1`

- The item key names a diagram. A diagram that isn't a drill shape (it has no family) is
  `unknown_reference`.
- **Name the shape:** right when the named member is the diagram's member. A member its
  family doesn't have is `unknown_option`.
- **Find the degree:** right when the tap is one of the diagram's positions with the asked
  interval; any of them counts. A tap anywhere else is wrong, the same pitch outside the
  shape included. The root is shown, so asking `R`, or an interval the shape doesn't have,
  is `degree_not_in_shape`. A string outside 1 to the layout instrument's string count is
  `invalid_cell`.

### `self_rating.v1`

- The rating and its measure are kept as given, except a change's rating (below). A take of
  zero chord changes is still a rating.
- A play-along needs `tempo_bpm` and takes no `changes_per_minute`. It may carry the
  `note_value` the take was played at, which is kept as given (absent means quarters); any
  other kind but a progression key tour with a `note_value` is `response_does_not_fit_item`. A chord change and a root
  change need both `tempo_bpm` and `changes_per_minute`. A chord voicing and a root and
  fifth are rated alone: either measure is `response_does_not_fit_item`.
- A chord voicing's diagram, and a root and fifth's or a root change's layout, must exist
  (`unknown_reference`).
- **A progression key tour take** is rated like a play-along: it needs `tempo_bpm`
  (`measure_missing`), may carry its `note_value`, and takes no `changes_per_minute`. It also
  needs the `music_key` it was played in, which is kept as given. A missing `music_key`, or a
  `music_key` on any other kind this grader takes, is `response_does_not_fit_item`. Its
  progression and its layout must exist (`unknown_reference`).
- **A change is one minute at `tempo_bpm`, one change on every beat**, and
  `changes_per_minute` counts the changes that rang clean. More clean changes than beats is
  `response_does_not_fit_item`.
- **A change's rating follows from its count**, whatever rating was sent: the share of the
  beats that changed cleanly, `changes_per_minute / tempo_bpm`. `clean` from 0.9, `almost` from
  0.6, `struggled` below. The evidence keeps the derived rating, the tempo and the count.

### `generated_choice.v1`

- **The way must be one of the kind's ways:** `numeral_to_chord` or `chord_to_numeral` for a
  diatonic chord; `chord_to_function` or `function_to_chord` for a chord function;
  `chart_to_numbers` or `numbers_to_chart` for a chart progression; `cadence_then_chord` or
  `see_then_name` for a heard chord; `progression_by_number` for a heard progression. Any other way is
  `response_does_not_fit_item`.
- **`music_key` comes with the kinds asked in any key** (chart progression, heard chord, heard
  progression), and with no other kind. Missing or extra, it is `response_does_not_fit_item`.
- A progression the catalog doesn't have, in the item key, is `unknown_reference`.
- **The right answer:**
  - `numeral_to_chord`: the key's chord on the numeral.
  - `chord_to_numeral`, `cadence_then_chord` and `see_then_name`: the numeral.
  - `chord_to_function`: the numeral's function.
  - `function_to_chord`: the key's chord on the numeral.
  - `chart_to_numbers` and `progression_by_number`: the progression's key.
  - `numbers_to_chart`: the progression's chords in `music_key`, one per bar, separated by
    single spaces.
- **The options are checked** before the pick (`invalid_choices` on any failure):
  - every option is a possible answer of the way:
    - a chord of the key, triads only, for `numeral_to_chord` and `function_to_chord`;
    - a numeral, for `chord_to_numeral`, `cadence_then_chord` and `see_then_name`;
    - `tonic`, `subdominant` or `dominant`, for `chord_to_function`;
    - a progression of the catalog, for `chart_to_numbers` and `progression_by_number`;
    - the chart of a catalog progression in `music_key`, for `numbers_to_chart`;
  - no two options are the same answer (`F#dim` and `Gbdim` are one);
  - the right answer is among them, and so is the pick;
  - for `function_to_chord`, no other option has the asked function.
  Whether the distractors are near misses is the planner's rule, checked over the catalog by
  its own tests, not here.
- Right when the pick is the right answer.
- `latency_ms` and `audio_ms` are copied as for every auto-graded answer.

### `timed_taps.v1`

- The layout in the key and the progression must exist (`unknown_reference`). A tap on a
  string outside the layout's tuning is `invalid_cell`.
- The progression plays in `music_key` at `tempo_bpm`, four beats to a bar. Bar *i* (from 0)
  starts at *i* × 240000 / `tempo_bpm` ms, rounded down, and runs to the next bar's start. A
  tap belongs to the bar it falls in; a tap after the last bar ends is not graded.
- **The asked tone** of each bar's chord: its third for `3` (minor on ii iii vi viio, major
  otherwise); its seventh in the key for `7` (major on I and IV, minor on every other numeral
  and on a dominant seventh).
- **A bar is hit** when at least one of its taps sounds the asked tone (on the layout's tuning,
  any octave) and none sounds another note.
- **Right only when every bar is hit.**
- **`latency_ms`** is the latest delay, over every bar, from the bar's start to its first right
  tap; a bar not hit counts its full length.
- The answer key's `bars` list every bar in order, with its `chord`, the asked tone's
  `note_name` and `hit`.

### `multi_tap.v1`

- The layout in the key must exist (`unknown_reference`).
- The window covers `from_fret` to `from_fret` + 4, or the open string to fret 5 when
  `from_fret` is 0. A tap outside it, or on a string outside the tuning, is `invalid_cell`.
- **The note's places** are every cell of the window, on every string, that sounds the note in
  any octave; the answer key lists them by string from 1, then fret from the lowest.
- **Right only when the cells tapped are exactly those places**, in any order. A place missed
  or an extra cell is wrong.

### `multi_tap.v2`

A fretboard cell asked to find every instance: the cell's note is named, and every place of it
in the window is tapped.

- The layout in the key must exist (`unknown_reference`).
- The window is the same as in `multi_tap.v1`. The planned cell, a tap outside the window, or a
  tap on a string outside the tuning is `invalid_cell`.
- **The note** is the planned cell's note. Its places are found as in `multi_tap.v1`.
- **Graded on every cell it covers** (`evidence_by_item`), one entry per cell, by string from 1
  and then fret from the lowest: each place of the note is right when tapped and wrong when
  missed, and each other cell tapped is wrong. Every cell of the window counts, whatever skill
  it serves.
- **Accuracy only:** the evidence has no `latency_ms`, since one time covers several taps.
- Each entry's answer key is the cell's `string` and `fret`, the asked `note_name` (on an extra
  tap, not the cell's own), the `fret_window` and the note's places as `cells`.
- Each entry's evidence id is a name-based UUID (version 5) of its item key under the event id.
  The cases don't pin ids, since they have no event.

## Using the cases

The specs repo is read as a sibling checkout (`../motifpath-specs`), the same way core and
web read the OpenAPI specs. A consumer test loads every `*.v*.json` file for the graders it
implements, builds its reference lookups from `reference`, and checks that each case gives
exactly `expected`.

`npm run validate:golden` (run in CI) checks three things:

- every file against `schema.json`;
- each file name against its grader id;
- every case's `item_key` and `response`, and each `evidence_by_item` entry's `item_key`, against
  `PracticeItemKey` and `PracticeResponse` in `openapi/components/schemas/practice.yaml`.
