# Practice drill catalog

The drill templates, the generated fretboard cells, the diagram shape families and the timed
thresholds that every MotifPath environment starts with, production included. The data lives
in `practice-drills.yaml`; this page holds the rules it follows and what an installation must
guarantee.

## Drill templates

A drill template is a way of asking: what is shown, what the student answers, whether the
answer is timed, and which rung of the practice ladder it trains (ADR-057). Thresholds and felt
questions are per template, never per item.

- **The ladder**, in order: `know`, `hear`, `play_clean`, `play_in_time`, `move`, `target`,
  `use`. Every template names its `rung`. Kinds with no template take a fixed rung:

  | Kind | Rung |
  |---|---|
  | play-along | `play_in_time` (its next-key take, `move`) |
  | chord change | `play_in_time` |
  | single chord, self-rated | `play_clean` |
  | song chart item | `use` |

- **Second way.** A generated template that asks among options names its `second_way`: another
  template of the same item kind that asks the same item another way. The composer asks an item
  the way with fewer right answers, so a lucky guess meets the other way. A template with no
  second way of its own instead brings its item back later in the same session, after at least
  three other items.

- **Fretboard cells** have two templates, one for each way of asking about a cell:
  - `fretboard_cell:name_the_note`: the cell is shown, and the student names its note.
  - `fretboard_cell:find_the_note`: a note and string are named, and the student taps the
    cell.
- **Diagram shapes** have two templates:
  - `diagram_shape:name_the_shape`: the shape is shown without its name, and the student
    picks which member of its family it is.
  - `diagram_shape:find_the_degree`: the shape is shown with its root marked and its other
    positions unlabelled, and the student taps the asked degree.
- **Authored exercises** are grouped into families by exercise type, one template each:
  `exercise:<exercise_type>`. They are `know`, or `hear` when the student answers what they hear
  (`audio_recognition`, `audio_selection`). A family's exercises share one threshold, since one exercise
  rarely gathers enough answers to calibrate on its own.
- **Play-alongs and chord changes** have no template. They are measured in tempo and changes
  per minute, against targets that come from the music.
- An answer's template comes from its item kind and response type (and, for exercises, the
  exercise's type). Keys never change.

## Challenge rules

Every generated question must test the skill it names (ADR-057). A planned item is valid only
when:

1. **No marked answer.** Nothing in the stimulus sets the right answer(s) apart: no label, marker
   shape, colour, highlight, size or position unique to them. What the question gives (the root
   in find the degree) may be marked, and is never asked.
2. **Plausible distractors.** Options are near misses a learner confuses, and none can be ruled
   out without the skill: a numeral question offers only chords of the asked key; a progression
   question offers its confusable progressions (`progressions.yaml`).
3. **The answer is never in the wording.** Neither the prompt nor an option's name contains it.
4. **Asked twice.** A template asked among options has a second way, or brings the item back
   later in the session.
5. **Harder as the level rises.** A template may list **variants** by the student's level on
   the item (more keys, no cadence, a faster tempo). The level picks the variant.

They bind generated drills only: authored exercises are their author's responsibility. A family
whose generator can produce an invalid item is not installed: its property test runs over every
item of the catalog, every way and every variant.

## Drill families v2 (planned)

Declared by ADR-057 and built one slice at a time. Each slice adds its templates and fluent
times to `practice-drills.yaml` (with fixed IDs), its item key scheme, grader and golden cases;
until then a family installs nothing. Every family has a bass version on the `electric-bass`
layout: chord boxes become chord symbols, or the answer is the chord's root (or chord tone)
tapped on the bass fretboard, at positions computed from the chord's formula and the tuning.

| Family (item kind) | One item is | Templates (rung) | Second way | Nodes | Slice |
|---|---|---|---|---|---|
| `diatonic_chord` | a numeral in a major key | `numeral_to_chord` (know): "In G, which chord is vi?", pick the chord · `chord_to_numeral` (know): a chord and a key, pick the numeral | each other | `diatonic-chords`, `roman-numerals` | P1 |
| `chord_function` | a numeral in a major key | `chord_to_function` (know): "In D, A7 is…", pick tonic, subdominant or dominant · `function_to_chord` (know): pick a chord with the asked function | each other | `chord-function` | P1 |
| `chart_progression` | a progression (`progressions.yaml`) | `chart_to_numbers` (know): four chords in a key, pick the progression · `numbers_to_chart` (know): a progression and a key, pick its chart | each other | `read-chord-charts`, `common-progressions` | P1 |
| `heard_chord` | a numeral in a major key | `cadence_then_chord` (hear): a cadence sets the key, a chord plays, pick the numeral; no cadence once accurate | comes back | `hear-chord-quality`, `hear-progressions` | P2 |
| `heard_progression` | a progression | `progression_by_number` (hear): four chords in a random key, pick the progression; confusable progressions offered | comes back | `hear-progressions`, `common-progressions` | P2 |
| `chord_voicing` | a chord voicing (bass: a chord's root and fifth) | none, self-rated (play_clean) | — | `play-open-chords` (bass: `play-root-fifth-lines`) | P3 |
| `chord_change` | two chords (bass: their roots) | none, changes per minute (play_in_time) | — | `change-chords` (bass: `play-root-notes`) | P3 |
| `play_along` | a diagram | next key after a clean take (move) | — | the diagram's nodes, `play-shapes-in-any-key` | P4 |
| `guide_tone` | a progression in a key | `tap_the_third` (target): over the playback, tap the 3rd of each chord as it arrives; the 7th at higher levels | — (not asked among options) | `target-chord-tones`, `voice-lead` (bass: `play-chord-tone-lines`) | P5 |
| `song_chart` | a song chart built on a progression | none, self-rated (use) | — | `common-progressions` | P6 |
| `fretboard_note` | a note on a layout | `find_every_instance` (know): tap every place of the note in the fret window | — (not asked among options) | `find-octaves` | P7 |

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

## Diagram shapes

- **Shapes come from the diagram catalog, never authored.** A family takes the catalog
  diagrams whose key matches its pattern (`basic-guitar-diagrams.md`), and the pattern's
  `{shape}` part says which member each diagram is. A diagram is one practice item, keyed
  `diagram_shape:<diagram id>`: the same shape at another root has other positions, so it is
  another item.
- **Instruments:** a shape suits the instruments its diagram is linked to. It is recalled in
  the head, and an in-hand session on one of those instruments may pick it too, like a
  fretboard cell.
- **Knowledge nodes:** a shape rolls up to its diagram's skill and concept.
- v1 families (tier A of the catalog), on standard guitar:

  | Family | Catalog diagrams | Members | Shapes | Skill |
  |---|---|---|---|---|
  | `caged-grip` | CAGED major grips | C, A, G, E, D | 52 | `map-fretboard-caged` |
  | `major-pentatonic-box` | major pentatonic boxes | Box 1–5 | 47 | `play-pentatonic-positions` |
  | `minor-pentatonic-box` | minor pentatonic boxes | Box 1–5 | 47 | `play-pentatonic-positions` |
  | `triad` | triad arpeggio maps, frets 0–12 | major, minor, diminished, augmented | 48 | `play-arpeggios` |
  | `major-scale-window` | CAGED windows of the major scale | C, A, G, E, D | 52 | `play-scale-positions` |
  | `natural-minor-scale-window` | CAGED windows of the natural minor scale | C, A, G, E, D | 52 | `play-scale-positions` |

  298 shapes in all. Not every member fits inside frets 0–12 at every root (B has no C-shape
  grip there), so a family has fewer than 12 × its members.
- **Name the shape: the options are every member of the family**, in the catalog's order,
  whether or not that member exists at this root. Member names never mention the root, so
  the root shown never gives the answer away.
- **Find the degree: the asked degree** is picked at random among the shape's intervals other
  than its root. The root is shown, so it is never asked.
- Tiers B and C (modes, 3NPS, extensions, substitutions) and "name the degree" (a marker is
  lit and the student names its interval) come later.

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
    | `fretboard_cell:name_the_note` | 3 s |
    | `fretboard_cell:find_the_note` | 4 s |
    | `diagram_shape:name_the_shape` | 4 s |
    | `diagram_shape:find_the_degree` | 4 s |

    The fretboard and diagram shape defaults stand in until the team benchmarks the drill,
    which needs the drill built first; the benchmark is their version 2.

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

- Every template names a rung of the ladder, and a `second_way` names another template of the
  same item kind.

- Installing on an empty database twice gives identical template and threshold IDs.
- The generated cells for a layout are exactly the strings and frets listed. A string the
  layout's instrument doesn't have fails the installation.
- Every `skill` key exists in the knowledge map and suits the layout's instruments.
- Every family matches at least one catalog diagram, every matched diagram's `{shape}` is
  one of its family's members, and no diagram belongs to two families.
- Installing aborts if a row with a fixed ID already exists with different data.
