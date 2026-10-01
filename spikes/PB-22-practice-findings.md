# Spike Findings: PB-22 — Practice sessions: data model and user experience

**Task:** PB-22 (= PB-8f, Practice & assessment), step 0
**Date:** 2026-10-01
**Author:** Gilson + Claude
**ADR:** input to the PB-22 practice-model ADR (to be written)
**Spike branch:** `motifpath-web@spike/PB-22/practice-model` (throwaway, not for merge; delete once
the ADR lands)

---

## Summary

The spike checks one question: **can a single data model represent every kind of practice we
discussed, and do the flows built on it feel smooth?** It is not an MVP or an A/B test. There were
no real students and no behavioural metrics.

I wrote the model as TypeScript types shaped like future OpenAPI schemas, with fixtures for six
kinds of content. I wrote its logic as pure functions, test-first (61 tests): drill generator,
mastery derivation, spaced repetition, tempo ladder, session composer, and Skill/Concept rollups.
A simulator produces 3–4 weeks of history for four student archetypes (improving, plateau, decaying,
overconfident). A clickable prototype (`spike-practice.html`) renders only from that model.

A scripted walkthrough drove the prototype in headless Chrome, with a fake camera, through every
loop. It ran: mind session → summary. Guitar session (recorded take, rating, chord-change minute) →
summary. Take sent for review → teacher video review → the note on the student's home → the next
session's focus "Suggested by your teacher". Decaying and overconfident students on the progress
screen. No console errors.

**Recommendations:**

1. **Adopt the model below as the ADR's basis.** One evidence shape covers all four item kinds. All
   state is derived from evidence at read time, and the only thing stored is evidence (plus teacher
   notes and takes).
2. **Generated items need an `item_key` identity in the answer event.** Today's
   `exercise.answer_sent` can't express them, and it carries no correctness, latency, tempo or
   rating either. This is the first spec change.
3. **Keep session composition rule-based** (no LLM). Every pick in the spike is explainable ("why
   this item?"), and the rules needed several corrections that would have been invisible inside a
   model call.
4. **Build the instrument slice first.** Play-along reuses diagram playback, and that's where the
   model needed the most correction (tempo ladder, exploration takes, warm-ups).
5. **Two decisions are still open for the PO** before the ADR: what a caught-up student practises
   (Finding 12), and how a teacher suggestion ends (Finding 9).

---

## The model

```text
PracticeItem          the smallest thing whose knowledge we track
  item_key            stable, readable id; generated items have no row anywhere
                      e.g. fretboard_cell:<instrument>:<string>:<fret> · exercise:<id>
                           play_along:<diagram_id> · chord_change:<from>:<to>
  kind                fretboard_cell | exercise | play_along | chord_change
  skill_ids, concept_ids   the existing Skill/Concept tree
  + per kind          cell (string, fret, note) · exercise_id · diagram_id + purpose
                      (technique | repertoire) + PlayAlongParams · chord pair + target changes/min

PlayAlongParams       start_bpm, target_bpm, step_bpm, cleans_to_advance, loops, count_in_beats

Evidence              one observation about one item — the only stored learning state
  source              auto_graded | self_assessed | teacher_reviewed   (audio_detected reserved)
  auto_graded         correct, latency_ms
  self_assessed       rating (struggled | almost | clean), bpm?, changes_per_minute?
  teacher_reviewed    rating, bpm?, changes_per_minute?, verified, teacher_note_id

KnowledgeState        derived at read time, never stored
  attempts, accuracy, fluency (0..1), box + due_at (spaced repetition),
  level (new → learning → accurate → fluent → retained), effective_level, fading, verified,
  median_latency_ms, best_clean_bpm, best_changes_per_minute

TeacherNote           a video review or a live-lesson note — one shape
  take_id?, item_key?, rating?, bpm?, verified, rubric (timing, clean_notes, tension, dynamics: 1–5),
  comments [{at_seconds, text}], summary, needs_work {skill_ids, concept_ids}, suggested_item_keys

RecordedTake          take_id, item_key, recorded_at, bpm, duration, media_url, sent_for_review

Session               composed, not stored: blocks [{kind, entries [{item_key, reason}]}]
  block kinds         warm_up | focus | application | mental
  reasons             teacher_suggested | due | weak | new | warm_up | application
```

**Mastery rules as they stand after the spike:**

- **Every piece of evidence reduces to a hit, a miss or a hold**, plus an accuracy value and a
  fluency ratio against the item's goal:
  - **Knowledge items:** the fluency ratio compares latency with a fluent time (2 s for a fretboard
    cell).
  - **Play-along:** clean tempo against the target tempo.
  - **Chord change:** changes per minute against the target.
  - **Ratings:** clean = hit, almost = hold, struggled = miss.
- **Weighted averages by source:** auto-graded and self-assessed 0.3, teacher-reviewed 0.6.
- **Spaced repetition:** Leitner boxes with waits of 1, 2, 4, 8, 16 and 32 days. A hit moves the item
  up one box only once it's due, a miss sends it back to box 1, and a hold changes nothing.
- **Levels:**
  - `accurate`: at least 3 attempts and accuracy ≥ 0.8.
  - `fluent`: at least 5 attempts, accuracy ≥ 0.9 and fluency ≥ 0.8.
  - `retained`: fluent and in box 5 or higher.
- **Teacher review:** a review resets the student's claims. The best clean tempo counts only clean
  takes since the latest review, and `verified` is the latest review's vouch.

## Data-model questions

**M1 — One shape for every kind? Yes, for evidence; no, for items.** Items need per-kind fields:
which cell, which diagram and its tempo parameters, which chord pair. Evidence needs only its
source-specific fields. Mastery never branches on kind beyond one function that projects a piece of
evidence onto hit/miss/hold, accuracy and fluency. All six fixtures fit the types with no casts or
escape hatches.

**M2 — Can sources be weighted without special cases? Yes, with two rules.** The source weights
alone were not enough. Two rules made the simulated stories come out right:
- **A teacher review resets self-claims.**
- **A non-clean take above the best clean tempo is exploration, not a miss.** See Finding 6.

Verification is a **manual teacher call**, decided 2026-10-01. No automatic rule sets `verified`.

**M3 — What's derived and what's stored?** Only evidence, teacher notes and recorded takes are
stored. Everything else is derived at read time from evidence and "now":
- levels, due dates, fading
- best tempos
- rollups over the Skill/Concept tree
- "speed two weeks ago vs now" (replay evidence up to an earlier date)

For production, the Aggregation Worker could materialize `KnowledgeState` per (student, item) as a
cache. The rules stay the same.

**M4 — What the answer event must carry.** `item_key` (works for generated and authored items
alike), `correct` + `latency_ms` for graded answers, `rating` + `bpm` / `changes_per_minute` for
self-assessments, and the `session_id`. Teacher reviews are not client events: they're written with
the teacher note.

**M5 — One teacher-note shape for video and live lesson? Yes.** `take_id` and `item_key` are both
optional. A note with an item and a rating also writes a `teacher_reviewed` piece of evidence.
`needs_work` and `suggested_item_keys` steer the session composer. Suggestions need a lifetime
(Finding 9). A flagged item must not be used as a warm-up (Finding 13).

**M6 — Do the default numbers give sane states?** After the fixes, yes, for all four archetypes:
- **Improving:** most practised cells reach fluent or retained, and clean tempo reaches ≥ 100 of
  120 BPM in three weeks.
- **Plateau:** never reaches fluent, and stays under 90 BPM.
- **Decaying:** most cells are fading two weeks after stopping, and at day 30 a 5-minute session is
  26 due reviews.
- **Overconfident:** the teacher review drops the claimed tempo and leaves the drill unverified.

Two default rules had to change: the tempo ladder's starting point (Finding 1) and the meaning of
"fading" (Finding 2).

## UX questions

**U1 — One or two taps to start? Two.** "Guitar in hand? Yes / No", then "3 / 5 / 15 min" starts the
first item. There's no separate preview screen: the session plan opens from a "Plan" link, with the
reason for every item. Sessions under 5 minutes with the guitar skip the warm-up (Finding 14).

**U2 — Is a play-along readable while playing?** Partly answered. The diagram rings each note on
the audio clock, a 4-beat count-in shows over the board, the take ends on its own and rating follows
immediately, and a "Moving guide" toggle hides the animation. **Still needs Gilson's hands-on check
with a guitar:** whether the diagram is readable from a music stand, and whether a real metronome
click is needed instead of the drill's own sound.

**U3 — Self-assessment under 20 s?** It's one tap per take (Struggled / Almost / Clean), and one tap
plus a ± count for chord changes. In a tempo-ladder flow it has to happen per take, because each
rating sets the next tempo. A separate end-of-session self-check would repeat it.

**U4 — Readable at a glance?** Mostly. The fretboard heatmap (colour = level, dashed = fading),
speed per string ("4.0s → 1.2s") and the tempo history make gaps and progress visible. Rollups
needed **coverage** next to fluency (Finding 8).

**U5 — Is the loop from teacher review to sessions visible?** Yes. The note's summary and its
skills to work on appear on the student's home, and the next session's focus item is labelled
"Suggested by your teacher".

**U6 — Is then-vs-now worth its screen?** The flow works: record during a take, then see the first
and latest takes side by side, then send one for review. Whether it motivates is a question for
real students, outside this spike.

---

## Findings

1. **The tempo ladder stalled.** Sessions started one step below the best clean tempo. With two
   clean takes per step and four takes per session, the improving student only ever climbed back to
   their old best and stayed at 75 BPM for three weeks. **Fix:** start at the best clean tempo.
2. **"Due" and "lapsed" are different signals.** Defining fading as "overdue by more than the
   item's own wait" left cells untouched for two weeks reading as not fading. **Fix:** `fading`
   means the review is due, which drives "9 notes are fading". The shown level drops only once the
   review is overdue by more than the wait.
3. **One projection covers every kind of evidence** (see M1).
4. **A teacher review resets self-claims** (see M2).
5. **Generated items need an identity in events** (see M4).
6. **Takes above the best clean tempo are exploration.** The ladder pushes every session to the
   student's limit, so "almost" and "struggled" at a new tempo dragged accuracy down: an improving
   student clean at 115 of 120 BPM read as "Learning" at 74%. **Fix:** a self-assessed take that
   isn't clean *above* the best clean tempo (since the last review) doesn't count. At or below that
   tempo it's a real miss. A teacher rating always counts.
7. **The warm-up tempo isn't the ladder's start.** A warm-up starts comfortably below the best
   (about 80%), outside the ladder.
8. **Rollups need coverage.** "Fretboard knowledge 96%", with only 24 of 72 cells ever practised,
   misleads. **Fix:** show "n/N met" with the mean fluency over the met items.
9. **Teacher suggestions need a lifetime.** Without one, a note steers every future session. The
   spike uses 14 days. **Open:** expire after a time, end once the student has practised it, or the
   teacher closes it.
10. **The count-in belongs in the sequence, not a timer.** iOS only starts audio inside the tap. So
    the count-in is rest steps at the front of the take, and the drill's loops are unrolled, so a
    take ends on its own.
11. **Verification is manual** (decided 2026-10-01).
12. **A caught-up student runs dry.** The improving student's 3-minute mind session had 4 items,
    because everything on the path was fresh. **Open for the PO:**
    - **"review ahead":** the least secure items that aren't due yet. Stays within the path.
    - **"stretch":** the next skills on the path.
    - both.
13. **A flagged item must not be the warm-up.** The composer chose the drill the teacher had just
    flagged as the warm-up, because it was the most fluent. Warm-ups now exclude suggested items.
14. **Short guitar sessions skip the warm-up.** At 3 minutes the warm-up took the whole time.

## Decided

- **Practice ≠ assessment.** The existing challenge stays the path gate. Practice is open-ended and
  adaptive, and is never "done".
- **Verification is a manual teacher call.**

## Open for the ADR

| Question | Spike default |
|---|---|
| What does a caught-up student practise? (Finding 12) | nothing more: the session ends early |
| How does a teacher suggestion end? (Finding 9) | 14 days |
| Leitner boxes or FSRS for spaced repetition | Leitner, with waits of 1, 2, 4, 8, 16, 32 days |
| Fluent latency: fixed, or relative to the student's own baseline | fixed 2 s per fretboard cell |
| Session mix | due 60 / weak 25 / new 15 |
| Source weights | auto 0.3, self 0.3, teacher 0.6 |
| Real metronome click in play-along | not built: the drill's own sound only |
| Practice scope: only skills met on the path, or free drills too | path skills plus teacher suggestions |
| Streak, or practice days per week | practice days in the last 7 days, no streak |

## Recommended slices after the ADR

1. **Spec:** the item/evidence model, the extended answer event (`item_key`, correctness, latency,
   rating, tempo), and the practice endpoints.
2. **Play-along drill:** tempo ladder, count-in, self-rating, plus the knowledge-state read model.
3. **Session composer and practice home:** guitar in hand or not, time budget, reasons.
4. **Mental fretboard drill and heatmap.**
5. **Recorded takes, then vs now.**
6. **Teacher notes:** rubric, comments, skills to work on, suggestions. Validate with a WhatsApp
   Wizard-of-Oz before building the review UI.
7. **Authored exercises in the scheduler, and the feed into recommendations.**

## How to rerun the spike

```bash
cd motifpath-web
git checkout spike/PB-22/practice-model
npx vitest run src/spikes          # the model's logic
npx vite                           # then open /spike-practice.html
```

No backend is needed: the page answers the voice list itself, using the same public guitar samples
the platform's voices come from. Hash links jump straight in: `#run=mind-5`, `#run=guitar-15`,
`#progress`, `#takes`, `#teacher`. The controls panel switches between simulated students, moves
"today", and shows any item's raw evidence next to its derived state. Live activity persists in the
browser. Recorded takes last only until reload.
