# ADR-046: Practice is evidence-based: graded evidence per item, knowledge state derived per instrument

**Status:** Proposed
**Date:** 2026-10-03
**Deciders:** Gilson (Product Owner)
**Input:** spike findings `spikes/PB-22-practice-findings.md` (specs#153), Phases 1–7, 2026-10-01 to
2026-10-03
**Revised:** 2026-10-03, in review. Practice item kinds are an open set, with a recipe for adding one;
the table lists the first kinds. Recorded takes are out of scope: the platform has no storage for
student videos (teacher reviews arrive over WhatsApp), and storing them needs its own cost and
infrastructure decision.

---

## Context

Retention is the platform's problem to solve without depending on teachers (platform-first premise).
Practice is the main lever for it: short, repeated sessions that build fluency (for example, knowing
every note on the fretboard without thinking) and show the student that they are improving. PB-22
(PB-8f) is that feature. Today the platform has lessons, the S7 challenge that gates progress along a
path, and authored exercises (ADR-019). It has nothing that tracks how well a student knows each thing
over time, decides what to practise next, or shows progress.

Four gaps block it:

- **No learning record.** `exercise.answer_sent` carries neither correctness, response time, a tempo or
  a self-rating, and it can't identify a generated item (a fretboard cell has no row anywhere).
- **No mastery measure for the knowledge graph.** ADR-043 gave nodes `requires` edges with a mastery
  level, so readiness ("n of m steps there") and stretch need a level for each node. ADR-043 left the
  rule that rolls item knowledge up into a node level to this decision.
- **Instruments.** Exercises are scoped to instruments (PB-86), nodes are scoped to instruments, and
  `requires` counts per instrument (ADR-043). Diagrams share a layout across instruments with the same
  geometry (ADR-045). A student can learn more than one instrument.
- **Timed drills need thresholds.** Fluency is about speed, and today's thresholds are guesses.

A throwaway spike tested the model and the flows before this decision (not an MVP, no real students):
TypeScript types shaped like future schemas, 163 tests of pure logic, simulated student histories and
populations, a clickable prototype, and scripted walkthroughs. Its findings are the evidence behind the
rules below. The spike also built private recorded takes with a then-vs-now comparison; this ADR
leaves them out (see Recorded takes). The alternatives it weighed: a model call composing sessions;
storing a mutable mastery state; grading in the client; a different evidence shape per kind of
practice; time-only threshold calibration; the map's calibration level for ranking.

## Decision

MotifPath will record practice as **evidence about items**: one observation per answer, rating or
review, graded on the server from the raw response. A student's knowledge state for each item, the
level of each knowledge node and the next session are all **derived from that evidence by versioned
rules**. Nothing about mastery is stored except the evidence itself and teacher notes.

### Practice and assessment are different things

- The S7 challenge stays the assessment that gates progress along a path. Practice is open-ended and
  adaptive, and is never "done".
- **Practice is never blocked**: not by low grades, not by waiting on a teacher, not by an unmet
  `requires`. Teacher suggestions and requirements only reorder or inform.

### Practice items

A practice item is the smallest thing whose knowledge is tracked. Every item has a stable, readable
`item_key` that evidence and events point at, its knowledge-node links (`skill_ids`, `concept_ids`)
and `instrument_ids` (empty means every instrument, as for exercises).

**Item kinds are an open set.** The model fixes what every item must provide, not which kinds exist.
Adding a kind (rhythm tapping from the PB-43 spike, interval or chord recognition by ear, sight
reading, scale runs) takes:

- an `item_key` scheme, stable and readable, that also works for generated items;
- the response shape(s) a client sends, and a versioned grader for them (or the self-rating grader);
- its projection onto a hit, miss or hold, with an accuracy and a fluency goal (a timed threshold, a
  tempo or a count), so mastery, levels and sessions need no change;
- whether it needs the instrument in hand, and how long it takes in a session;
- golden cases for the grader.

No other part of the model changes. The first kinds:

| Kind | `item_key` | Instruments |
|---|---|---|
| Fretboard cell (generated, no row) | `fretboard_cell:<layout instrument>:<string>:<fret>` | every instrument sharing that layout's geometry |
| Authored exercise | `exercise:<exercise_id>` | the exercise's own (PB-86) |
| Play-along (diagram + tempo ladder) | `play_along:<diagram_id>` | the diagram's linked instruments (ADR-045) |
| Chord change (two diagrams, changes per minute) | `chord_change:<from>:<to>` | the diagrams' common instruments |

A fretboard cell is keyed by the **layout instrument** (ADR-045), not by each instrument: a student
who plays acoustic and electric guitar knows one fretboard, not two. A drill template's generated items
follow the same classification rule as content (nodes must suit the item's instruments).

### Responses and grading

- The client sends the **raw response**, never a verdict: the note named, the cell tapped, the option
  picked, or a self-rating with its tempo or change count.
- The **server grades it** against reference data (tuning, the exercise's options) through a registry
  of **versioned graders** (`fretboard_cell.v1`, `exercise_option.v1`, `self_rating.v1`). A grader
  either returns the evidence payload or rejects the response, and stores nothing when it rejects.
- The client grades only for instant feedback, with the same rules. **Golden cases** (item, response,
  expected result) live in motifpath-specs as language-neutral JSON and are run by both the Go grader
  and the web client.
- Enharmonic spellings count as the same note; the asked note an octave up on the asked string counts
  as right.

### Evidence

One piece of evidence per observation, the only stored learning state:

- `source`: `auto_graded` (correct, latency), `self_assessed` (rating struggled/almost/clean, tempo or
  change count) or `teacher_reviewed` (rating, measure, `verified`, teacher note). `audio_detected` is
  reserved.
- Auto-graded and self-assessed evidence keeps the **raw response** and the **grader id**, so a grader
  change can regrade it. Timed answers also keep the student's **tap time** (below).
- The evidence id is the event id that produced it, so a redelivered event can't count twice.
- Evidence and teacher notes live in MongoDB. An archive to object storage is deferred until a
  measured trigger (volume or cost) calls for it.

### Events: the `practice.*` family

- `practice.session_started`: the instrument in hand (or none), the minutes, and the composed plan with
  a reason for every item.
- `practice.item_answered`: `event_id`, `item_key` and the raw response.
- `practice.session_ended`: the answered count, whether the student left early, and how each timed
  drill felt (below).
- `practice.item_reviewed`: written by core when a teacher note judges an item. It uses the teacher
  note's id as its session id.
- The S7 challenge's answers move onto `practice.item_answered`, so assessment and practice feed one
  evidence record. `exercise.answer_sent` is retired once nothing emits it.

### Knowledge state: a fold over evidence

- **One rule set, reduced to three readings.** Each piece of evidence becomes a hit, a miss or a hold,
  plus an accuracy value and a fluency ratio against the item's goal: the timed threshold, the target
  tempo, or the target change count. Ratings map clean → hit, almost → hold, struggled → miss.
- **Weighted averages by source:** auto-graded 0.3, self-assessed 0.3, teacher-reviewed 0.6.
- **Spaced repetition:** Leitner boxes with waits of 1, 2, 4, 8, 16 and 32 days. A hit moves the item up
  one box only once it is due, a miss sends it back to box 1, and a hold changes nothing.
- **Levels:** `new` → `learning` → `accurate` (3+ attempts, accuracy ≥ 0.8) → `fluent` (5+ attempts,
  accuracy ≥ 0.9, fluency ≥ 0.8) → `retained` (fluent and box 5 or higher). An item is **fading** once
  its review is due; its shown level drops one step once the review is overdue by more than its wait.
- **Exploration is not forgetting:** a self-rated take that isn't clean *above* the best clean tempo
  since the last teacher review doesn't count against the student. At or below it, it does.
- **A teacher review resets self-claims:** best tempos count only clean takes since the latest review,
  and `verified` is the latest review's vouch. Verification is always a manual teacher call.
- **Incremental fold, single writer.** The state is a time-ordered fold over an item's evidence plus a
  view at "now". The fold carries, beyond the state itself: counted attempts, the clean-tempo edge since
  the last review, the latest review's vouch, the best clean measures since then, the last ten correct
  latencies, and the latest timestamp. The Aggregation Worker (ADR-011) gains an evidence processor
  that is the single writer for each student, keyed by `student_id` as the event stream already is
  (ADR-006). A duplicate is dropped by evidence id. Evidence older than the item's latest folded
  timestamp rebuilds that item from its evidence. Evidence sharing a timestamp folds in arrival order.
- **Mastery rules are versioned.** A rule change rebuilds folds from evidence, which is always possible
  because the evidence is never modified.

### Node level and readiness, per instrument

- **A node's level** for an instrument is the highest level that at least **80%** of the items in its
  subtree reach, counting items that suit that instrument plus items for every instrument. Unseen items
  count as `new`. A node with nothing to practise has **no level**, not `new`.
- Levels are kept apart per instrument: notes on the E and A strings can be fluent on guitar and new on
  bass for the same student.
- **Wide nodes show progress through their relationships.** A parent or wide concept is shown as
  coverage plus its children's levels, never as a single level of its own.
- **Readiness** counts a node's `requires` edges whose two ends are for the instrument, met when the
  target's level reaches the edge's level. It informs and never gates. A requirement on a node with
  nothing to practise can never be met, so the knowledge-map editor's coverage view flags those nodes.
- `applies` never carries mastery.

### Session composition

- **Rules, not a model call.** Every pick carries a reason (`teacher_suggested`, `due`, `weak`, `new`,
  `warm_up`, `application`, `review_ahead`, `stretch`) and can be explained to the student.
- **Instruments:** a student's instruments are those of the paths and courses they're enrolled in (one
  for every instrument adds none), plus any they add in their profile. A session starts with the
  instrument in hand ("Guitar in hand?" with one instrument, "Which instrument is in your hands?" with
  several) or none, then the minutes. An in-hand session takes only items that suit that instrument.
  A session in the head covers all the student's instruments, and items for every instrument suit
  any session. Questions name the instrument when the student has several.
- **Scope:** skills met on the student's paths, teacher suggestions, then, when caught up, review ahead
  and stretch.
- **Mix:** teacher suggestions first; then due 60%, weak 25%, new 15%. The new share is a **ceiling**,
  and new items are **balanced across the student's instruments**, so adding an instrument doesn't
  flood every session with it.
- **Caught up:** the remaining time is split **50/50** between **review ahead** (known items coming due
  soonest) and **stretch** (unseen items of any node whose readiness is complete, for the instrument),
  each taking over the other's share when it runs out. Stretch ranks nodes that build on something
  the student meets first, then by **requires depth** for the instrument (the longest chain of
  requirements below the node), then catalog order. The map's calibration level is not installed and
  is not used.
- **With the instrument in hand:** a warm-up on something known, never on what the teacher flagged and
  skipped under 5 minutes; a focus block; and, from 10 minutes, applying the skill to music. A warm-up
  play-along starts at about 80% of the best clean tempo, outside the tempo ladder.
- **Tempo ladder:** start at the best clean tempo; +5 BPM after two clean takes; −5 after a struggle;
  clamped to the item's start and target. The count-in is part of the step sequence (rest steps), so
  audio starts inside the student's tap on every platform.

### Teacher notes and suggestions

- One note shape covers a review of a video the student sent and a live-lesson note: an optional item, a rating and
  measure, `verified`, a 1–5 rubric (timing, clean notes, tension, dynamics), timestamped comments, a
  summary, skills and concepts that need work, suggested items, and a **target level** (default
  `accurate`). A note that judges an item also writes `teacher_reviewed` evidence.
- Students send videos for review over WhatsApp, as the concierge does today (PB-78). The teacher, or
  the team acting as one, watches it there and records the note on the platform. Timestamped comments
  refer to that video, which the platform doesn't store.
- **A suggestion ends** when its item or node reaches the target level **after the note was written**,
  or when the teacher closes the note, with a **30-day safety expiry**. A suggestion never ends on a
  level the student already had.

### Timed thresholds: versioned reference data, calibrated with felt ratings

- A threshold is defined per **drill template** (`fretboard_cell:name_the_note`,
  `fretboard_cell:find_the_note`, authored exercises grouped by family) as the fluent time spent
  *knowing*: latency minus the student's tap time. It has a version, a start date, a source
  (`benchmark` or `calibrated`) and the data behind it. Tempo-measured items keep musical targets.
- **Version 1** is twice the team's median net time on the drill, measured by the team before launch.
- **Tap baseline:** a 20-second "tap the highlighted fret" check gives each student's tap time.
  Ingestion stamps it on every timed answer, so replays stay stable.
- **Felt ratings:** after a session, at most one or two "How did it feel? Easy / About right / Hard"
  questions, for the drill templates with the least calibration data. Felt ratings calibrate
  thresholds and **never count toward mastery**.
- **Calibration:** the net time that best separates sessions felt "hard" from the rest, blended with the
  current version by sample size. It runs only from about **100 sessions by 20 students**, and one step
  changes a threshold by at most **±25%**.
- **Forward only:** each answer is judged by the version in force when it happened. A new version needs
  no rebuild and never takes back a level.

### The student summary and home

- One derived summary per student and instrument is the home's single read: practice days in the last
  7 (never a streak, never a reset), progress this week per skill with both values ("accuracy 72% →
  86%"), next steps (refresh, strengthen, ready to start; the top three plus "see all"), and practice
  nodes grouped by area. Instrument-independent nodes get an **"Any instrument"** group. Concepts appear
  in the map and as context, not as separate progress lines.
- The home is organised by skills and concepts, never by exercise type, with progress before next
  steps and no red badges. Practice days are counted in the student's time zone.

### Recorded takes are out of scope

The platform doesn't store student recordings. Videos for review go over WhatsApp, so the platform
can't show a then-vs-now comparison. Storing takes on the platform (upload, storage, playback, retention,
privacy) needs its own decision after a cost and infrastructure review, tracked as a separate backlog
item. If that decision stores takes, a note gains an optional take reference. Progress over time is
still shown from evidence (tempo history, speed per string, levels).

## Rationale

- **Open item kinds behind one contract, over a fixed list.** Practice will grow (rhythm, ear, reading),
  and each new kind should cost a key scheme, a grader and a projection, not a change to mastery,
  levels or sessions.
- **No platform storage for takes yet, over building video upload now.** Student video means storage,
  delivery and retention costs on the single-VM hosting (ADR-039), plus privacy handling for
  students' recordings, minors' included. WhatsApp already carries the review loop at no infrastructure cost, so the comparison
  feature waits for a decision on cost.
- **Evidence plus derivation, over a stored mastery state.** A mutable state can't be audited, can't be
  recomputed when a rule improves, and drifts when events arrive twice or late. Deriving from immutable
  evidence makes every rule change a rebuild, and the spike's property test showed the incremental fold
  gives exactly the batch result for every simulated student.
- **One evidence shape, over one per kind of practice.** All the first kinds fit one shape with
  source-specific fields. Mastery branches on kind in one projection only, so new kinds of practice
  cost a projection, not a new model.
- **Server grading, over trusting the client.** The client's verdict could be wrong or manipulated, and
  a rule change could never be replayed. Golden cases shared by both sides keep the instant feedback
  identical to the record.
- **Rules, over a model call, for composing sessions.** Every pick must be explainable to the student,
  and the spike needed several rule corrections (tempo ladder start, exploration takes, warm-ups,
  caught-up students) that would have been invisible inside a model's output. The composer is cheap,
  deterministic and testable.
- **An 80% share for node levels, over the weakest item or the mean.** The weakest item would keep a
  72-cell node at `new` forever; the mean hides gaps. The share is honest for the leaf skills that
  `requires` points at, and wide nodes are shown through their children instead.
- **Requires depth, over the map's calibration level, for ranking.** The calibration level varies by
  instrument and is deliberately not installed; the graph already carries the order of learning.
- **Felt-calibrated thresholds, over fixed guesses or time alone.** In simulated populations with a
  known answer, calibration from felt ratings landed within ±4%. Time alone (how fast students who know
  the drill answer) landed 35–51% off: it measures speed, not where a drill gets hard. Without
  subtracting tap time, thresholds came out 12–29% too lax, worse on phones.
- **Absolute thresholds for levels, over each student's own baseline.** A level must mean the same for
  everyone for `requires` to work. Personal improvement is still shown on the home as progress.
- **Leitner boxes, over FSRS, for now.** Leitner is simple to explain and was enough for the simulated
  stories. FSRS needs fitted parameters and review data the platform doesn't have yet.
- **Practice days, over streaks.** Streak resets punish a missed day; the home shows practice without
  penalty.

## Consequences

### Positive

- One evidence record serves practice, the S7 challenge, the home, recommendations (PB-8g) and teacher
  insight.
- Every level, due date and pick can be explained and recomputed from evidence.
- Generated drills (fretboard cells) are first-class without any content rows.
- Thresholds improve with use and never take back a level.
- Students who play several instruments get separate, honest levels, and identical fretboards count once.

### Negative / Trade-offs

- **More event types and a new processor.** The `practice.*` family, the grader registry and the evidence
  processor are new code in core, plus a migration of the S7 challenge onto `practice.item_answered`.
- **Two sources of rules to keep in step.** Graders run in Go and in the web client; the shared golden
  cases are the guard, and they must be kept current.
- **The fold carries more than the state.** Its extra fields are part of the processor's contract, and a
  rebuild replays a student's whole history for the affected item.
- **Calibration depends on an untested assumption**: that a timed drill starts to feel hard once the
  student is slower than fluent. Only real students can confirm it, and until enough sessions exist,
  version 1 (the team's benchmark) is what students are measured against.
- **Overconfident populations bias calibration toward lax thresholds**; the ±25% step cap limits the
  damage but doesn't remove it. Teacher-reviewed (and later audio) evidence is the check.
- **No then-vs-now comparison.** The spike's most motivating flow for students without a teacher waits
  for the take-storage decision, and teacher reviews depend on a manual WhatsApp step.
- **Requirements on empty nodes stay unmet** until content exists, which the map editor has to surface.
- **Small-sample instability.** Below the calibration gate, thresholds don't move at all, even when the
  benchmark is visibly off.

### Neutral

- `exercise.answer_sent` is retired once the challenge emits `practice.item_answered`.
- Evidence stays in MongoDB; the archive question is reopened only by a measured trigger.
- Tempo targets for play-alongs and chord changes stay authored (they come from the music).
- Audio detection is reserved as an evidence source and is its own later spike.
- A future take-storage decision can extend ADR-021 (presigned upload, object storage) to student
  media, and add an optional take reference to teacher notes.

## Follow-up slices

1. **Spec:** item and evidence schemas, the `practice.*` events, the grader golden cases, threshold
   reference data, and the practice endpoints (session plan, answer, summary).
2. **Play-along drill:** tempo ladder, count-in, self-rating, and the knowledge-state read model.
3. **Session composer and practice home:** instrument choice, time budget, reasons, summary.
4. **Mental fretboard drill and heatmap**, with the tap check, felt questions and benchmark thresholds;
   calibration runs once real sessions accumulate.
5. **Teacher notes** for videos received over WhatsApp: rubric, comments, needs-work, suggestions.
   Validate with a WhatsApp Wizard-of-Oz before building the review UI.
6. **Authored exercises in the scheduler**, the S7 challenge on `practice.item_answered`, and the feed
   into recommendations (PB-8g).

## Related ADRs

- **ADR-006** (Kafka topology): `student_id` partitioning makes the evidence processor a single writer
  per student.
- **ADR-011** (Aggregation Worker): gains the evidence processor and the student summary.
- **ADR-019** (Exercise as a first-class entity): authored exercises become practice items.
- **ADR-021** (media storage): the starting point if student takes are ever stored.
- **ADR-039** (single-VM hosting): the cost and capacity context for student media.
- **ADR-023** (challenge time threshold is informational): timed thresholds here measure fluency, not
  pass/fail.
- **ADR-026 / ADR-043** (knowledge graph): node levels, readiness and stretch build on `part_of` and
  `requires`; this ADR decides the rollup rule ADR-043 left open.
- **ADR-040** (fretboard cells as answers) and **ADR-041** (diagram playback): fretboard drills and
  play-alongs.
- **ADR-045** (catalog guitar instrument scope): fretboard cells are keyed by layout; play-alongs take
  the diagram's linked instruments.

---

*This ADR was proposed on 2026-10-03. To revise, create a new ADR with Status: Supersedes ADR-046.*
