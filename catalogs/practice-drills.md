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
  | play-along | `play_in_time` |
  | progression key tour | `move` |
  | chord change | `play_in_time` |
  | single chord, self-rated | `play_clean` |
  | song chart item | `use` |

- **Second way.** A generated template that asks among options names its `second_way`: another
  template of the same item kind that asks the same item another way. The composer asks an item
  the way with fewer right answers, so a lucky guess meets the other way. A template with no
  second way of its own instead brings its item back later in the same session, after at least
  three other items. A template marked `comes_back` does both: an ear drill's second way is
  seen, not heard, so the item also comes back by ear in the same session.

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
- **Play-alongs and chord changes** have no template. A play-along is measured in tempo,
  against the target its music sets; a chord change in clean changes per minute, against the
  catalog's change target (see "Chord drills").
- An answer's template comes from its item kind and response type (and, for exercises, the
  exercise's type; for a generated question asked among options, the way it was asked:
  `diatonic_chord:numeral_to_chord`). Keys never change.

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

## Drill families v2

Declared by ADR-057 and built one slice at a time. The item key schemes, response types,
graders and golden cases of every family are specified together (`PracticeItemKey` and the
responses in the practice schemas; `golden/practice-graders/`), so each is graded alike from
the start. Each slice then adds its templates and fluent times to `practice-drills.yaml` (with
fixed IDs) and its generator; until then a family installs nothing. The P1 harmony families
and the P2 ear families are installed (see "Harmony drills" and "Ear drills" below), and so
are the P3 chord families (see "Chord drills"). Every family has a bass version on the
`electric-bass` layout: chord boxes become chord symbols, or the answer is a chord tone tapped
on the bass fretboard, at positions computed from the chord's formula and the tuning.

| Family (item kind) | One item is | Templates (rung) | Second way | Nodes | Slice |
|---|---|---|---|---|---|
| `diatonic_chord` | a numeral in a major key | `numeral_to_chord` (know): "In G, which chord is vi?", pick the chord · `chord_to_numeral` (know): a chord and a key, pick the numeral | each other | `diatonic-chords`, `roman-numerals` | P1 |
| `chord_function` | a numeral in a major key | `chord_to_function` (know): "In G, D is…", pick tonic, subdominant or dominant · `function_to_chord` (know): pick a chord with the asked function | each other | `chord-function` | P1 |
| `chart_progression` | a progression (`progressions.yaml`) | `chart_to_numbers` (know): its chart in a key, pick the progression · `numbers_to_chart` (know): a progression and a key, pick its chart | each other | `read-chord-charts`, `common-progressions` | P1 |
| `heard_chord` | a numeral in a major key | `cadence_then_chord` (hear): a cadence sets the key, a chord plays, pick the numeral; the tonic alone once accurate · `see_then_name` (hear): a key and the chord drawn, pick the numeral | each other, and comes back by ear | `hear-chord-quality`, `hear-progressions` | P2 |
| `heard_progression` | a 4-bar progression | `progression_by_number` (hear): four chords in a random key, pick the progression; confusable progressions offered | comes back | `hear-progressions`, `common-progressions` | P2 |
| `chord_voicing` | a chord voicing (bass: a chord's root and fifth) | none, self-rated (play_clean) | — | `play-open-chords` (bass: `play-root-fifth-lines`) | P3 |
| `chord_change` | two chords (bass: their roots) | none, changes per minute (play_in_time) | — | `change-chords` (bass: `play-root-notes`) | P3 |
| `progression_keys` | a progression (`progressions.yaml`) on a layout | none, self-rated at a tempo; the key moves on after a clean take (move) | — | `common-progressions`, `play-shapes-in-any-key` (bass: `play-chord-tone-lines`) | P4 |
| `guide_tone` | a progression in a key | `tap_the_third` (target): over the playback, tap the 3rd of each chord as it arrives; the 7th at higher levels | — (not asked among options) | `target-chord-tones`, `voice-lead` (bass: `play-chord-tone-lines`) | P5 |
| `song_chart` | a song chart built on a progression | none, self-rated (use) | — | `common-progressions` | P6 |
| `fretboard_note` | a note on a layout | `find_every_instance` (know): tap every place of the note in the fret window | — (not asked among options) | `find-octaves` | P7 |

**Item keys and graders.** A key is part of the item when the fact differs per key (the vi of
G is not the vi of E♭); a relative skill is one item in every key, and the key is picked each
time it is asked and sent back with the answer. The same goes for a guide tone's tone and tempo,
and for a find every instance's fret window.

| Kind | Item key | Picked each time | Response | Grader |
|---|---|---|---|---|
| `diatonic_chord` | `diatonic_chord:<key>:<numeral>` | — | `generated_choice` | `generated_choice.v1` |
| `chord_function` | `chord_function:<key>:<numeral>` | — | `generated_choice` | `generated_choice.v1` |
| `chart_progression` | `chart_progression:<progression key>` | key | `generated_choice` | `generated_choice.v1` |
| `heard_chord` | `heard_chord:<numeral>` | key | `generated_choice` | `generated_choice.v1` |
| `heard_progression` | `heard_progression:<progression key>` | key | `generated_choice` | `generated_choice.v1` |
| `chord_voicing` | `chord_voicing:<diagram id>` | — | `self_rating`, no measure | `self_rating.v1` |
| `root_fifth` (bass) | `root_fifth:<layout id>:<chord>` | — | `self_rating`, no measure | `self_rating.v1` |
| `root_change` (bass) | `root_change:<layout id>:<from chord>:<to chord>` | — | `self_rating` + changes per minute | `self_rating.v1` |
| `progression_keys` | `progression_keys:<layout id>:<progression key>` | key (the tour's) | `self_rating` + tempo and key | `self_rating.v1` |
| `guide_tone` | `guide_tone:<layout id>:<progression key>` | key, tone, tempo | `timed_taps` | `timed_taps.v1` |
| `fretboard_note` | `fretboard_note:<layout id>:<note>` | fret window | `multi_tap` | `multi_tap.v1` |

The bass versions of the harmony and ear families are the same items: only how an option is
drawn changes (a chord symbol instead of a chord box). `play_along` keeps its key and grader.

## Harmony drills

`diatonic_chord`, `chord_function` and `chart_progression` are generated from the major keys
and the progression catalog, never authored, and recalled in the head on every instrument.

- **Items:**
  - `diatonic_chord` and `chord_function`: the numerals ii iii IV V vi viio in each of the 12
    major keys, 72 items each. The tonic is never an item: its chord is the key's own name, so
    a question about it would answer itself. The I chord still appears as an option and in
    every chart.
  - `chart_progression`: every progression of the progression catalog, asked in a key picked
    each time.
  - They roll up to the nodes of the families table, and a chart progression also to its
    progression's nodes. They suit every instrument, so a student who plays guitar and bass
    practises one set. Like fretboard cells, they are practised in the head only.
  - **They count toward their nodes like any item, from the day they are installed.** Unseen
    ones count as new. A node a student made accurate through lessons and exercises can
    therefore show a lower level, and the readiness that requires it can drop, until the
    drills are practised: the level says what is still to do.
- **The chords** are the key's triads: major on I IV V, minor on ii iii vi, diminished on viio,
  spelled as the chord catalog spells roots. A progression's I7, IV7 and V7 are dominant
  sevenths. A chord function question asks the triad, never a seventh, which would give the
  dominant away.
- **The options** are shuffled, four at most:
  - numeral to chord: the answer and the three chords of the key whose numerals are nearest
    the asked one around the scale (one step away, then two), so every option is a chord of
    the key;
  - chord to numeral: the answer and the three numerals nearest it;
  - chord to function: tonic, subdominant and dominant;
  - function to chord: one chord of the key with the asked function, and three of the key's
    chords with other functions;
  - read the chart and pick the chart: the progression, then its confusables, then theirs, up
    to four, all with as many bars as the progression. The two 12-bar forms are confusable
    only with each other, so they offer two.

  A tie between equally near options is broken at random.
- **The prompt** names the key and what the question gives (the numeral, the chord, the
  function or the progression), never the answer.
- **How it is drawn:**
  - On guitar, a chord is a chord box, unnamed until answered. A chord always gets the same
    box: its open voicing if the chord catalog has one, else its lowest-difficulty voicing,
    the lowest fret on a tie. The plan names the voicing, so every client draws the same box.
  - On bass, a chord is its chord symbol.
  - A four-bar chart is drawn as boxes on guitar and as symbols on bass. A 12-bar chart is
    drawn as symbols on every instrument, in three lines of four, as a blues is written.
  - **Which reading a session uses:** harmony items are recalled in the head, where no
    instrument is in hand, so a session takes its reading from the student's fretboard
    layouts. With one of `guitar` and `electric-bass`, always that one. With both, sessions in
    the head take turns: guitar when the student has started an even number of sessions in the
    head so far, bass when odd, so both readings get practised. With neither, chord symbols.
    Every harmony item of a session is drawn the same way.
- **New items come key by key,** around the circle of fifths from C (C G F D B♭ A E♭ E A♭ B D♭
  F#). A student is offered the new numerals of a key before any of the next key.
- **The key of a chart question** (rule 5) is picked among C G D F A while the student is new
  or learning on the item, and among all 12 keys from accurate on.
- **Ways:** each family's two templates are each other's second way. With no right answers
  yet, numeral to chord, chord to function and read the chart come first.

## Ear drills

`heard_chord` and `heard_progression` are generated from the major keys and the progression
catalog, like the harmony drills, and recognised by ear in the head on every instrument.

- **Items:**
  - `heard_chord`: the numerals ii iii IV V vi viio, 6 items, each asked in a key picked each
    time among all 12. The tonic is never an item, since the cadence ends on it.
  - `heard_progression`: every 4-bar progression of the progression catalog. The 12-bar forms
    are never asked by ear: twelve bars are too long to hold before answering.
  - They roll up to the nodes of the families table, and a heard progression also to its
    progression's nodes. Like the harmony drills, they count toward their nodes from the day
    they are installed, and suit every instrument.
- **The playback** is in 4/4, one chord a bar, in the chords' voicings (the voicing rule of
  the harmony drills):
  - `cadence_then_chord`: I IV V I, then the asked chord, while the student is new or learning
    on the item. From accurate on, the tonic chord alone, for one bar, then the asked chord: a
    numeral still needs a key, and the tonic is the least it takes.
  - `progression_by_number`: the progression's four bars.
  - The bars that set the key show their numerals; the asked chord's bar shows "?", and a
    progression's bars show nothing. The chords are sounded, never named.
  - On a session that reads chords on bass, each chord's root also plays under it in the bass
    voice. The chords keep their guitar voicing.
- **The tempo** starts by the student's level on the item (`hear_tempo_bpm`): 70 BPM while new
  or learning, 90 once accurate, 110 once fluent. The student may change the tempo and the note
  value (quarters, eighths, triplets, sixteenths) before or between plays. A note value is a
  speed factor, as for play-alongs: eighths play two chords a bar. Neither is graded; the
  latency is judged net of the sound heard once, at the speed it was played (`audio_ms`).
- **The options:**
  - `cadence_then_chord` and `see_then_name`: the answer and the three numerals nearest it
    around the scale (one step away, then two), until the student is fluent on the item; then
    all seven numerals, the tonic included, in scale order.
  - `progression_by_number`: the progression, then its confusables, then theirs, up to four,
    all of four bars. Confusable progressions are asked next to each other in a session.
- **`see_then_name`** names the key and draws the chord, a box on guitar and a symbol on bass,
  by the session's reading (the harmony drills' rule). It plays nothing. It is the ear drill's
  second way, so a lucky guess by ear meets the chord's numeral by sight; the item also comes
  back by ear later in the same session.
- **Ways:** `cadence_then_chord` comes first. When an item comes back in the same session, it
  is asked by ear again, in a newly picked key.

## Chord drills

`chord_voicing` and `chord_change` (on bass, `root_fifth` and `root_change`) are played with the
instrument in hand and rated, never recalled in the head.

- **Items** are a curated set (`chord_drills`), not every voicing of the chord catalog:
  - single chords: the open voicings of C, A, G, E, D, Am, Em and Dm, keyed
    `chord_voicing:<voicing diagram id>`;
  - changes: ten pairs of those chords (Am–C, C–G, G–D, D–A, A–E, Am–E, Em–G, D–Em, Am–Dm,
    Em–C), keyed `chord_change:<from diagram id>:<to diagram id>` in the order listed. A pair is
    one item, practised both ways in the same minute;
  - on bass, the same chords by symbol on the `electric-bass` layout:
    `root_fifth:<layout id>:<chord>` and `root_change:<layout id>:<from chord>:<to chord>`.
  - They roll up to the nodes of the families table: `play-open-chords` and `change-chords` on
    guitar, `play-root-fifth-lines` and `play-root-notes` on bass. A chord voicing suits the
    instruments its diagram is linked to; a bass item suits the instruments of its layout.
  - They are offered like any node's items: a path skill's as new, whatever it requires (no
    prerequisite in practice), and other nodes' as stretch. Which chords a student has met is
    not tracked.
- **In a session** they are focus items of an in-hand session, never in the head, never the
  warm-up or the application ending. At most 4 single chords and 2 changes a session. A single
  chord takes 20 seconds, a change 90 (a bar of count-in, the minute and the count). On guitar,
  a single chord comes before a change that uses it in the same session.
- **How they are drawn:** a guitar chord is its voicing's chord box, named (playing it is the
  skill, so the name gives nothing away). On bass, the root and fifth are marked on the bass
  board, at the positions ADR-057 computes (lowest fret, then lowest string), inside frets 0–5;
  a root change marks both roots.
- **A single chord** is fretted, strummed once and rated clean, almost or struggled by the
  student. It has no measure, so a clean take is fully fluent and accuracy alone decides its
  level.
- **A change** is one minute at a tempo, one change on every beat:
  - the student sets the tempo before the minute (the metronome ticks while they try it), starts
    it after a bar of count-in, and counts the changes that rang clean when it is over. The count
    starts at the item's last count;
  - the take sends the tempo and the count. Its rating follows from the share of the beats that
    changed cleanly, count ÷ tempo: clean from 0.9, almost from 0.6, struggled below. The student
    doesn't rate it, so the count and the rating never disagree;
  - **the ladder** runs across sessions, since a session plays a change once. The plan starts a
    change at the tempo of its last minute: 5 BPM up after two clean minutes in a row, 5 down
    after a struggled one, never below 20. A change never played starts at 40;
  - **the target** is the catalog's change target, the same for every pair and instrument: 60
    clean changes a minute (version 1). A minute's fluency is its count ÷ the target. The best
    clean count is the student's edge: a minute that isn't clean above it doesn't count against
    them, as for a play-along's tempo.
- **Not asked among options**, so the challenge rules on options and second ways don't apply.

## Progression key tours

`progression_keys` is played with the instrument in hand and rated. The student plays one
progression of the progression catalog along with its backing, key after key around the cycle of
fourths, and so learns it by number instead of by one fingering (MOT-150).

- **Items:** every progression of the progression catalog on each of the `guitar` and
  `electric-bass` layouts, keyed `progression_keys:<layout id>:<progression key>`, 20 items.
  - Each item rolls up to `common-progressions` and its progression's nodes, plus
    `play-shapes-in-any-key` on guitar or `play-chord-tone-lines` on bass.
  - An item suits the instruments of its layout.
  - Items are offered like any node's: a path skill's as new, with no prerequisite in practice.
- **In a session**, a tour is a focus item of an in-hand session:
  - never in the head, never the warm-up and never the application ending. Sessions in the head
    practise the same progressions through the harmony and ear drills;
  - at most 1 a session, played over up to 3 takes;
  - it is sized like a play-along. Each take is a bar of count-in plus its bars at the start
    tempo, then about 10 seconds to rate it.
- **A take** plays the progression four times through (16 bars) when it has four bars, and once
  when it is a 12-bar blues.
  - It is in 4/4, one chord a bar, after a bar of count-in.
  - The backing plays the chords in their voicings (the harmony drills' voicing rule) at the
    take's tempo and note value.
- **The key order** is the cycle of fourths from C, the same on every instrument: C F B♭ E♭ A♭
  D♭ F# B E A D G. Keys are spelled as the chord catalog spells roots.
- **The tour** keeps one tempo for the item, across sessions.
  - **A clean key:** a key is clean when a take in it is rated clean at an effective speed at or
    above the tour tempo. A clean take slower than the tour tempo, at a tempo the student chose,
    doesn't make its key clean.
  - **The next take:** after a clean take, it is in the next key of the cycle that isn't clean
    yet, at the same tempo. After an almost or a struggle, it stays in the key.
  - **A struggle** lowers the tour tempo by 5 BPM, never below 60% of the target. Keys already
    clean stay clean, since they were clean faster.
  - **A finished tour:** when all 12 keys are clean, the tour tempo goes up 5 BPM and the tour
    starts again at C, with no key clean. By itself it never climbs past the target.
  - **Choosing a tempo:** the student may choose any tempo for a take, as on a play-along.
  - **The start:** a session starts the item at the first key of the cycle not yet clean, at the
    tour tempo, in the note value of the last clean take (quarters with none). A tour never
    played starts at C, at 60% of the target rounded down to 5 BPM.
  - **The target** is 100 BPM in quarters, the same for every progression and instrument
    (`progression_keys.target_tempo_bpm`).
- **How it is drawn** (Figma 17k; bass 18z):
  - the progression's name; the last clean key and tempo with the key to play ("Clean in G at
    84 BPM · now in A");
  - the chart in chord symbols, in the take's key (a 12-bar blues in three lines of four);
  - the key line: five keys of the cycle around the current one, with the clean ones ticked;
  - the tempo control.
  - **On guitar**, each chord's box is shown on demand (the chord card), from the harmony drills'
    voicing rule, so every client draws the same box.
  - **On bass**, the board marks each chord's root, third and fifth, so the line says whether
    the chord is major or minor. Each tone sits at its lowest fret, then its lowest string,
    inside frets 0–5: the rule of a root and fifth. A dominant seventh keeps root, third and
    fifth on the board, and its symbol shows the 7.
- **Rating:** the student rates each take clean, almost or struggled (`self_rating.v1`). The take
  sends its tempo, its note value and the key it was played in. As for a play-along, a take's
  fluency is its effective speed ÷ the target.
- **The summary** says how many keys are clean at the tour tempo: "Clean in 3 of 12 keys at
  85 BPM".
- **Not asked among options**, so the challenge rules on options and second ways don't apply.

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
    | `diatonic_chord:numeral_to_chord` | 4 s |
    | `diatonic_chord:chord_to_numeral` | 4 s |
    | `chord_function:chord_to_function` | 3 s |
    | `chord_function:function_to_chord` | 4 s |
    | `chart_progression:chart_to_numbers` | 6 s |
    | `chart_progression:numbers_to_chart` | 8 s |
    | `heard_chord:cadence_then_chord` | 3 s after the sound |
    | `heard_chord:see_then_name` | 4 s |
    | `heard_progression:progression_by_number` | 5 s after the sound |

    The fretboard, diagram shape, harmony and ear defaults stand in until the team benchmarks the drill,
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
- `hear_tempo_bpm` gives a tempo for every knowledge level.
- Every chord drill names an open voicing of the chord catalog that exists, every change pair
  names two of the chord drills' voicings, and no pair is listed twice in either order.
- The chord drills' chord symbols are the chords of their voicings.
- A change target version 1 is installed before chord changes reach students.
- `progression_keys.key_order` holds each of the 12 major keys once. Its layouts exist, and
  every bass tour's chord tones fall inside frets 0–5 of the `electric-bass` layout.

- Installing on an empty database twice gives identical template and threshold IDs.
- The generated cells for a layout are exactly the strings and frets listed. A string the
  layout's instrument doesn't have fails the installation.
- Every `skill` key exists in the knowledge map and suits the layout's instruments.
- Every family matches at least one catalog diagram, every matched diagram's `{shape}` is
  one of its family's members, and no diagram belongs to two families.
- Installing aborts if a row with a fixed ID already exists with different data.
- Every chord a harmony item can draw on guitar (every key's triads, every progression's chords
  in every key) has an active voicing in the chord catalog.
