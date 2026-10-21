# ADR-057: Drill model v2: rungs, subjects, challenge rules and focused sessions

**Status:** Accepted
**Date:** 2026-10-14
**Deciders:** Gilson (Product Owner)
**Accepted:** 2026-10-14, by Gilson, with the refinements listed in specs#318 (current rung,
plan-level "You chose this", chosen-session leftover time, core-planned options, comeback for
drills with no second way, families installed per slice, `fretboard_cell.v2` unchanged).
**Input:** plan "Drill set v2 and focused practice sessions" (MOT-77 anchor, local); the reports
"Effective Music Drills — Research Benchmark" and "Automatic Drills — How They Work Today";
PO answers Q1–Q7 of 2026-10-14; MOT-77 decisions D22–D25.
**Amends:** ADR-046 (session composition, guess correction, distractors). ADR-046 stays in force
for everything this ADR doesn't change.
**Amended:** 2026-10-20, planning the play-along in every key (MOT-150, slice P4), by Gilson. The
next-key drill is not a play-along of a diagram: no diagram holds a progression, and an open-chord
fingering doesn't move to another key by frets. It is a new generated family, the **progression
key tour** (`progression_keys:<layout id>:<progression key>`, rung `move`). One progression of
the progression catalog is played along with, key after key around the cycle of fourths from C,
self-rated (`self_rating.v1`, the take sending its key):
- a clean take moves the next take to the next key not yet clean, at the same tempo; an almost
  or a struggle stays in the key, and a struggle lowers the tour tempo by 5 BPM;
- when all 12 keys are clean, the tour starts again at C, 5 BPM faster. Keys come first, then
  tempo: the item has one tempo ladder, not one per key;
- on guitar the chart is in chord symbols, with chord boxes on demand. On bass the board marks
  each chord's root, third and fifth, so the line shows the chord's quality;
- like chords, it is played in hand only, at most once a session.

A play-along of a diagram keeps the fixed rung `play_in_time` and no next-key take.

**Amended:** 2026-10-21, planning find every instance (MOT-153, slice P7), by Gilson (D43). Find
every instance is a third way of asking a **fretboard cell**, `fretboard_cell:find_every_instance`
(rung `know`), not a `fretboard_note` item: the planned cell's note is named, and the student taps
every place of it in the fret window. One answer is graded on **every cell it covers**, which
amends ADR-046's one observation per answer:
- each place of the note in the window gets evidence on its cell: right if tapped, wrong if
  missed. Each other cell tapped gets wrong evidence. Every cell of the window counts, whichever
  skill it serves;
- the answered event names the planned cell. Each cell's evidence id is a name-based UUID (v5)
  of that cell's item key, under the event id as namespace, so a redelivered event still can't
  count twice. This amends ADR-046's "the evidence id is the event id" for answers graded on
  several items; every other answer keeps the event id;
- it counts for accuracy, never for fluency: one time covers several taps, so the way has no
  fluent time and its evidence no latency;
- it isn't asked among options, so it has no second way and never comes back. The composer asks
  a cell the way with the fewest right answers, as it does for naming and finding the note.

The `fretboard_note` key, never installed, is dropped, and `find-octaves` loses its planned
drill. Rejected: a `fretboard_note` item with its own level. It would leave untouched the cells
the drill is meant to make fluent.

---

## Context

ADR-046 built practice on evidence: every item is graded, a fold derives what the student knows,
and a rules-based composer fills a session with due, weak and new items. Four generated drills
exist (name and find the note on a fretboard cell, name the shape and find the degree on a
diagram shape), all of them recall in the head. The research benchmark sets a target drill set
of eleven more, along the ladder a teacher climbs with a student: **know** a thing, **hear** it,
**play** it **clean**, play it **in time**, **move** it to another key or place, **target** it
while playing, and **use** it in music. Most of them are about harmony (numerals, functions,
progressions by ear, chord changes, guide tones), and every one of them needs a bass version.

Three gaps stop those drills from being added one by one:

- **Nothing says what a drill is for.** A template knows its item kind and response type, but
  not which rung of the ladder it trains, and an item reaches knowledge nodes only through what
  it points at (a cell's skill, a diagram's nodes). A composer that should "practise diatonic
  chords at the right level" has nothing to choose with.
- **Sessions have no focus.** Today's mix takes due, weak and new items from every node on the
  student's paths, so a 10-minute session can touch eight subjects and the student can't say
  what they worked on. The student also has no way to say "I want to work on progressions"
  (MOT-77): practice the student chooses was left as a later feature.
- **Nothing stops a question from giving its answer away.** "Tap the roots" on a diagram that
  draws the roots as stars is answered without the skill. Generated drills are produced by the
  thousand, so a rule broken by one generator breaks thousands of items at once.

ADR-046 also decided (2026-10-08) to correct guesses among few choices, charging a wrong pick
1/(k−1). It was never built (its scenarios are still `@wip`), and the PO withdrew it on
2026-10-14 in favour of asking an item again.

## Decision

### 1. A drill template carries a rung

- **The ladder** has seven rungs, in order: `know`, `hear`, `play_clean`, `play_in_time`, `move`,
  `target`, `use`.
- **Every drill template declares its rung** in the practice drill catalog. A template is now
  item kind + response type + rung. Kinds without a template take a fixed rung: a play-along is
  `play_in_time`, a chord change is `play_in_time`, a progression key tour is `move` (amended
  2026-10-20), a song chart item is `use`.
- Authored exercise families are `know`, or `hear` when the student answers what they hear
  (`exercise:audio_recognition`, `exercise:audio_selection`).
- **Generated drill families are declared in the catalog**: their templates, the reference data
  their items come from (fretboard cells, diagram shapes, chord voicings, progressions), the
  knowledge nodes their items roll up to, and how each way of asking is checked. A new family is
  a catalog entry plus a generator, a grader and golden cases; the composer needs no change.

### 2. A subject is one knowledge node

- A **subject** is one knowledge node (a skill or a concept). An item practises a subject when
  one of its nodes is that node or a `part_of` descendant of it.
- Related nodes stay separate subjects: `common-progressions`, `diatonic-chords` and
  `hear-progressions` are three subjects, never one grouped subject.
- **Practice has no prerequisites.** Any node with material can be practised. `requires` edges
  only rank stretch, as before; they never gate a session or add items to it.

### 3. Every generated question must challenge

A generated item is valid only when all five rules hold. The generators check them, and a
property test runs every family over its whole catalog.

1. **No marked answer.** Nothing in the stimulus sets the right answer(s) apart from the rest: no
   label, marker shape, colour, highlight, size or position unique to them. What the question
   gives (the root in find the degree) may be marked, and is never asked.
2. **Plausible distractors.** Options are near misses a learner confuses (a fret or a string off;
   the same root with another quality; a neighbouring numeral; a confusable progression). None can
   be ruled out without the skill: every option of a numeral question belongs to the asked key.
3. **The answer is never in the wording.** Neither the prompt nor an option's name contains the
   answer.
4. **Asked twice.** Every template that asks among options names a **second way** of asking the
   same item (name the note ↔ find the note), or brings the item back within the session after
   other items. Picking the way with fewer right answers, as the composer already does for cells
   and shapes, makes a lucky guess meet the other way.
5. **Harder as the level rises.** A template may declare **variants** by the student's level on
   the item: more keys, less context (a cadence first, then none), a faster tempo. The level picks
   the variant, never the student.

These rules bind generated drills only. Authored exercises are the author's responsibility.

**Core plans the options of new choice drills.** For every family added from this ADR on, the
plan carries the options, and the response sends back the options it was answered among, as
name the note sends its choices. Name the note keeps its client-picked near notes (ADR-046).

### 4. No guess correction

The 1/(k−1) correction is **withdrawn** before it shipped. A wrong pick among choices counts 0,
like any wrong answer. A lucky guess is caught by asking again (rule 4) and by the levels already
needing 3+ counted answers for `accurate` and 5+ for `fluent`. `fretboard_cell.v2` stays as it
is: it checks the choices and keeps them in the answer key, for the record. The `@wip`
guess-correction scenarios are retired.

### 5. Sessions are focused

- **At most three subjects per session**: one main subject and up to two more. The plan names
  them (`focus_nodes`, main first), and the client shows them ("Today: diatonic chords · ii–V–I").
- **Today's mix** picks its subjects in this order until it has three: a teacher's suggestion
  (its node is the main subject); the nodes with the most due and weak time (the estimated time
  of their due and weak items), most first; the nodes the new items come from, path skills first;
  then the stretch nodes. Every due, weak, new, review-ahead and stretch item comes from those
  subjects, with one exception:
- **The review block.** Due items of other nodes would wait forever, so Today's mix takes them
  in a review block: at most **20% of the focus time or 5 items**, whichever is fewer, most
  overdue first, out of the due share. They keep the reason `due` and are not subjects.
- **A chosen session** (`focus_node_id`) holds only items of the chosen node's subtree: its own
  due items first, then weak, then new, at the usual shares; its leftover time goes to reviewing
  its known items ahead and then to more of its new items, never outside it. Due items of other
  nodes wait for Today's mix. It has **no warm-up**, and an application ending only when a
  play-along exists in the subtree. The plan says it was chosen (`focus_source: chosen`), and the
  client shows "You chose this" for the session; each item keeps the reason it was picked
  (due, weak, new, review ahead, application).
- **The rung climbs with the student.** For each subject, the composer finds the **current
  rung**: the lowest rung that has material for the session (in hand or in the head) and whose
  items on that subject are not yet `accurate` (by the node-level rule, over that rung's items
  only). **New and stretch items** come from the current rung and the next rung with material,
  never further. A subject accurate on every rung it has material for takes them from its top
  rung. Due, weak and review-ahead items are taken whatever their rung: a review is of
  something already learnt.
- **Confusable items are interleaved on purpose** within a subject: the A shape next to the E
  shape, I–V–vi–IV next to I–vi–IV–V. Interleaving by drill (ADR-046) still applies.

A **subjects list** (`listPracticeSubjects`) tells the client which nodes have material for an
instrument in hand, or in the head, grouped by area, with the student's level and current rung
on each, so the picker never offers an empty subject.

### 6. Progressions are reference data

A new catalog, `catalogs/progressions.yaml`, lists the common progressions by number (I–IV–V,
I–V–vi–IV, I–vi–IV–V, ii–V–I, the 12-bar blues…), each with its mode, its nodes and its
**confusable** progressions. Progressions are keyed and installed with fixed IDs like every
catalog. Harmony and ear drills take their numerals, keys and distractors from it; chord
voicings come from the chord catalog.

### 7. Bass patterns are computed, not catalogued

Bass drills work on roots, fifths and chord tones on the `electric-bass` layout. Their positions
are **computed** from the chord's formula (chord catalog) and the bass tuning, inside the drill's
fret window. Where a tone has several places in the window, a drill that shows one takes the
lowest fret, then the lowest string; a drill that asks for a tap accepts any of them. No bass
pattern catalog is added.

## Rationale

- **Rung per template, over rung per item.** A template is a way of asking, and the way of asking
  is what makes a drill "know" or "hear": the same chord is `know` when its numeral is picked and
  `hear` when it is recognised by ear. Per-item rungs would repeat the same value thousands of
  times.
- **A climbing current rung, over a fixed level-to-rung table.** The first draft mapped the
  node's level to rungs (new → know/hear, learning/accurate → play, fluent → move/target/use).
  A node's level is the level 80% of *all* its items reach, so a student who knows every numeral
  but has never played a chord reads as `new` on the node and would be held on `know` forever;
  and a student `learning` the numerals would jump to playing before knowing them. Reading each
  rung's own items gives the same ladder without the loop.
- **Three subjects, over the whole path.** One to three subjects is what a student can name after
  a session, and what the benchmark found sessions with a goal need. More subjects let due items
  scatter the session again.
- **A capped review block, over letting due items wait.** Due items outside the subjects would
  otherwise fall further behind each session and drop the student's levels. Capping the block
  keeps the session about its subjects. A chosen session has no block (PO, Q2): the student asked
  for one subject.
- **Plan-level "You chose this", over a `chosen` item reason.** MOT-77 D23 asked for the reason
  "You chose this". Every item of a chosen session would carry it, so it says nothing per item,
  and it would hide which items are due. The plan carries it once, and items keep their own
  reasons.
- **Re-asking, over guess correction** (PO, 2026-10-14). The composer already asks a cell or a
  shape the other way once it has more right answers; requiring that of every new choice drill
  costs nothing more. The correction would have needed a new mastery-rules version, a fold
  change and uneven treatment across kinds, for a small gain.
- **Core-planned options, over client-picked distractors, for new families.** ADR-046 let the
  client pick name the note's near notes, a presentation choice. Harmony distractors depend on
  music theory (same key, neighbouring numerals, confusable progressions), and the challenge rules
  must be checked over the whole catalog in one place. The server is that place.
- **Computed bass patterns, over a bass pattern catalog.** A root, a fifth or a chord tone on a
  string is a pure function of the chord and the tuning. A catalog would repeat 12 keys × every
  quality × every position, and could drift from the chord catalog.
- **A new ADR, over another ADR-046 amendment.** ADR-046 already carries a dozen amendments; the
  drill model and focus rules are a decision of their own that later slices will cite.

## Consequences

### Positive

- A student can name what a session worked on, and choose it (MOT-77).
- New drills are catalog entries plus a generator; the composer, the fold and the summary don't
  change per drill.
- Marked answers are caught by a test over every generated item, not by a student.
- The ladder gives every subject a next step, from knowing it to using it in a song.

### Negative / Trade-offs

- **Fewer subjects means slower coverage.** A student with many weak nodes reaches each of them
  less often; due items outside the subjects rely on a review block of at most 5 items.
- **A chosen session lets other reviews slip.** A student who only chooses sessions never meets
  their due items elsewhere; their levels fade until they take Today's mix.
- **Rung reading costs a level computation per rung per subject** at compose time.
- **Two ways of picking distractors** coexist: client-picked for name the note, server-planned for
  the new families.
- **Without guess correction, four-choice accuracy reads a little high** until the item has been
  asked the other way; `accurate` may come a session early on choice drills.
- **Bass positions follow one rule** (lowest fret, then lowest string), not a teacher's
  fingering choice.

### Neutral

- Evidence, grading, the fold and the Leitner boxes are unchanged.
- Existing drills get rungs (all `know`) and keep their behaviour.
- The guess-correction scenarios and their ADR-046 text are retired; `fretboard_cell.v2` is
  unchanged.

## Follow-up slices

- **C2** (MOT-144): the generated-drill framework in core; cells and shapes move onto it.
- **C4** (MOT-145): graders and golden cases for the new families. *(Amended 2026-10-14, PO:
  C4 also owns every new family's item key scheme and response type, so all of them are graded
  alike before any slice starts.)*
- **C3** (MOT-146): the composer's focus rules, current rung and the subjects list.
- **C5** (MOT-147) and **D0** (MOT-143): web building blocks and Figma.
- **P1–P8**: one slice per drill group, each with its templates, generator and default fluent
  times, on the item keys and graders C4 specified. *(Amended 2026-10-14: item schemas, graders
  and golden cases moved to C4.)*

## Related ADRs

- **ADR-046** (evidence-based practice): amended here for composition, guess correction and
  distractors, and (2026-10-21) for one answer graded on several cells and their evidence ids.
- **ADR-043** (knowledge graph): subjects are its nodes; `part_of` gives a subject's subtree.
- **ADR-047** (practice reference snapshot): the new families' reference data reaches graders
  through it.
- **ADR-050** (chord library and song charts): chord voicings and song charts feed the harmony,
  chord and use drills.
- **ADR-040** (fretboard cells as answers): find every instance taps several cells, and grades
  each of them.

---

*This ADR was accepted on 2026-10-14. To revise, create a new ADR with Status: Supersedes ADR-057.*
