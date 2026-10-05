# Practice drill catalog

The drill templates, the generated fretboard cells and the timed thresholds that every
MotifPath environment starts with, production included. The data lives in
`practice-drills.yaml`; this page holds the rules it follows and what an installation must
guarantee.

## Drill templates

A drill template is a way of asking: what is shown, what the student answers, and whether
the answer is timed. Thresholds and felt questions are per template, never per item.

- **Fretboard cells** have two templates, one for each way of asking about a cell:
  - `fretboard_cell:name_the_note`: the cell is shown, and the student names its note.
  - `fretboard_cell:find_the_note`: a note and string are named, and the student taps the
    cell.
- **Authored exercises** are grouped into families by exercise type, one template each:
  `exercise:<exercise_type>`. A family's exercises share one threshold, since one exercise
  rarely gathers enough answers to calibrate on its own.
- **Play-alongs and chord changes** have no template. They are measured in tempo and changes
  per minute, against targets that come from the music.
- An answer's template comes from its item kind and response type (and, for exercises, the
  exercise's type). Keys never change.

## Fretboard cells

- **Cells are generated, never authored.** For each skill, each layout lists the strings and
  the fret range whose cells serve it. Every cell in that range is a practice item, keyed
  `fretboard_cell:<layout instrument id>:<string>:<fret>`.
- **Layouts:** cells belong to the layout instrument, so a student who plays acoustic and
  electric guitar practises one set of cells. v1 has two layouts:
  - `guitar`, shared by `guitar` and `electric-guitar`;
  - `electric-bass`.
- **Strings follow the skill's name, which holds on every instrument.** "Find notes on the E
  and A strings" is strings 6 and 5 on guitar, and strings 4 and 3 on bass.
- **Frets 0 to 11:** the open string and the first eleven frets, one of each note. Fret 12
  repeats the open string an octave up, and `find_the_note` already accepts any octave on the
  asked string.
- v1 cells, at 12 frets per string:

  | Layout | `find-notes-root-strings` | `find-notes-top-strings` | Total |
  |---|---|---|---|
  | `guitar` | 24 | 48 | 72 |
  | `electric-bass` | 24 | 24 | 48 |

## Timed thresholds

- **What a threshold is:** the time a fluent student spends *knowing* the answer: latency
  minus the student's tap time. A student who never did a tap check has a tap time of 0.
  For an exercise with audio, the audio the student has to hear once is also taken off: the
  exercise's sound, or all its sound options added together. Replays are not taken off.
- **What a version records:**
  - `template`, `version` and `effective_from`;
  - `fluent_net_ms`;
  - `source`: `default`, `benchmark` or `calibrated`;
  - the data behind it: `sessions` and `students` (both 0 for a benchmark).
- **Version 1** must be installed before a timed drill reaches students. It is either:
  - a **default**, a fluent time the team sets per drill template as a starting point. Every
    exercise family starts from one, so exercises can reach `fluent` before the team has
    measured them. Defaults (net):

    | Template | Fluent time |
    |---|---|
    | `exercise:text_response` | 6 s |
    | `exercise:image_recognition` | 5 s |
    | `exercise:image_choice` | 5 s |
    | `exercise:audio_recognition` | 4 s after the audio |
    | `exercise:audio_selection` | 4 s after the audio options |

  - or a **benchmark**, twice the team's median net time on the drill.
- **A benchmark after a default** is added as the next version. It doesn't replace the default.
- **Fluent times are configuration.** Adjusting one means adding a version with a later
  `effective_from` to the catalog. It needs no code change, and an installed version is never
  edited.
- **Calibration** finds the net time that best separates sessions that felt "hard" from the
  rest, and blends it with the current version by sample size.
  - It runs only once a template has **at least 100 felt-rated sessions from at least 20
    students**.
  - One step changes the threshold by at most **±25%**.
  - A new version starts at its `effective_from` and never replaces an older one.
- **Forward only:**
  - Each timed answer is judged by the version in force when it was given, so a new version
    never takes back a level.
  - An answer given before a template has any version counts for accuracy, never for fluency.
    That's why version 1 must be installed before a timed drill reaches students.

## Felt questions

- After a session, at most **two** "How did it feel? Easy / About right / Hard" questions, for
  the timed templates practised in that session that have the fewest felt-rated sessions.
- Felt ratings calibrate thresholds and **never** count toward the student's mastery.

## Acceptance

- Installing on an empty database twice gives identical template and threshold IDs.
- The generated cells for a layout are exactly the strings and frets listed. A string the
  layout's instrument doesn't have fails the installation.
- Every `skill` key exists in the knowledge map and suits the layout's instruments.
- Installing aborts if a row with a fixed ID already exists with different data.
