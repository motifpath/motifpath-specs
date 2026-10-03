# Spike Findings: PB-22 — Practice sessions: data model and user experience

**Task:** PB-22 (= PB-8f, Practice & assessment), step 0
**Date:** 2026-10-01 (Phase 5, knowledge-graph model: 2026-10-02)
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
5. **Phase 5 moved the model onto the knowledge graph** (ADR-043) and checked the 2026-10-01
   architecture decisions in code: server-side grading through versioned graders, a `practice.*`
   event family, a single-writer incremental fold proven equal to batch derivation, a node level
   and readiness, "review ahead, then stretch" for caught-up students, and a skill-centred home.
   See [Phase 5](#phase-5--the-knowledge-graph-model).
6. **Still open for the PO** before the ADR: how wide nodes (parents, concepts) show progress
   (Finding 17), whether the home reports concepts beside skills (Finding 24), and the caught-up
   time split (Finding 20).

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

PracticeResponse      the raw answer a client sends, never a verdict
                      name_the_note {chosen_note} · find_the_note {string, fret}
                      option_choice {option_id} · self_rating {rating, bpm?, changes_per_minute?}

Evidence              one observation about one item — the only stored learning state
  source              auto_graded | self_assessed | teacher_reviewed   (audio_detected reserved)
  auto_graded         correct, latency_ms, grader, response
  self_assessed       rating (struggled | almost | clean), bpm?, changes_per_minute?, grader, response
  teacher_reviewed    rating, bpm?, changes_per_minute?, verified, teacher_note_id

KnowledgeState        derived at read time, never stored
  attempts, accuracy, fluency (0..1), box + due_at (spaced repetition),
  level (new → learning → accurate → fluent → retained), effective_level, fading, verified,
  median_latency_ms, best_clean_bpm, best_changes_per_minute

TeacherNote           a video review or a live-lesson note — one shape
  take_id?, item_key?, rating?, bpm?, verified, rubric (timing, clean_notes, tension, dynamics: 1–5),
  comments [{at_seconds, text}], summary, needs_work {skill_ids, concept_ids}, suggested_item_keys,
  target_level, closed_at

RecordedTake          take_id, item_key, recorded_at, bpm, duration, media_url, sent_for_review

Session               composed, not stored: blocks [{kind, entries [{item_key, reason}]}]
  block kinds         warm_up | focus | application | mental
  reasons             teacher_suggested | due | weak | new | warm_up | application
                      | review_ahead | stretch (with the node it opens)

Practice events       practice.session_started {plan} · practice.item_answered {event_id,
                      item_key, response} · practice.session_ended {answered_count, ended_early}
                      (event_id becomes the evidence id; teacher reviews are written with the note)

StudentSummary        derived per student, the home's one read: practice_days_last_7,
                      progress [{node, from, to}], opportunities (refresh | strengthen | start),
                      areas [{root, practice nodes with level, met/total, accuracy, fluency}]
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

## Phase 5 — the knowledge-graph model

Added 2026-10-02, once the knowledge graph (ADR-043, PB-85) shipped. Items now link real keys of
the reviewed knowledge map, and a fixture slice of it carries the real `requires`/`applies` edges
and instruments. The spike's suite grew from 61 to 124 tests. A scripted headless walkthrough ran
every archetype's home, caught-up sessions, a live graded answer and closing a teacher note, with
no console errors.

**M7 — One node-level rule for big and small nodes? For leaf skills, yes.** A node is at level L
when at least 80% of the items in its subtree show L or above (unseen counts as new). A node with
nothing to practise has no level, rather than `new`. That works for what `requires` points at,
usually a leaf skill. It misleads for wide nodes: after three weeks the improving student is
`fluent` on the E/A-string notes, yet the concept *Note names* (72 cells) and the parent *Fretboard
fluency* read `new` (Finding 17).

**M8 — Is readiness meaningful? Yes, and it exposes content gaps.** Readiness counts the `requires`
edges whose ends are both for the student's instrument, met when the target's level reaches the
edge's level. Two real edges point at nodes with no items (`change-chords → play-open-chords`,
`hear-intervals → match-pitch`), so they can never be met (Finding 18). It informs and never gates,
so nothing breaks, but authors need to see it.

**M9 — Does "review ahead, then stretch" fill a caught-up session? Yes, sharing the time.** Review
ahead takes known items soonest due. Stretch takes unseen items of **any ready node for the
student's instrument** (decided 2026-10-02), ranked: builds on something the student has, then the
map's calibration level, then catalog order. A strict order starved stretch (Finding 20), so the
spike splits the leftover time half and half. Every pick is still explainable, and a stretch names
the node it opens.

**M10 — Can the state be folded incrementally? Yes, identically.** `deriveState` is now a
time-ordered, clock-free fold step plus a view at "now". A property test checks fold == batch for
every archetype and item at two moments. A duplicate is dropped by its evidence id, and a late piece
rebuilds its item from the log. The fold carries more than the knowledge state (Finding 23).

**M11 — One grader interface? Yes.** Clients send raw responses. Three versioned graders
(`fretboard_cell.v1`, `exercise_option.v1`, `self_rating.v1`) check them against reference data
(tuning, the exercise's options) and either return the evidence payload or reject the response. 15
golden cases live in a language-neutral JSON file a Go grader can run. Evidence keeps the response
and the grader id, so a rule change can regrade.

**U7 — Is the skill-centred home readable? Mostly.** Progress this week comes first, with both values
("accuracy 93% → 96%, Accurate → Fluent"). Then the opportunities, phrased as next steps (refresh,
strengthen, ready to start). Then the practice nodes grouped by area, with no level for the area
itself. There are no streaks or red badges, and the `learning` chip moved off the danger colour. Two
problems remain: concepts echo skills (Finding 24), and the opportunity list grows too long
(Finding 25).

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

*Phase 5:*

15. **The map has no per-string skills.** It tracks notes on the E and A strings and notes on the
    D string and above. The per-string view belongs to the heatmap, at item level.
16. **A teacher suggestion can't end on a level the student already had.** A flagged item that is
    already fluent, or an overconfident self-claim, would end the suggestion the moment it's
    written. **Rule:** it ends once practised *since the note* at the teacher's target level, or
    when the teacher closes it, with a 30-day safety expiry.
17. **The 80% rule dilutes wide nodes.** The concept *Note names* and the parent *Fretboard
    fluency* read `new` after three weeks of real progress on the E/A strings. **Proposed:** keep
    the rule for the node level that `requires` checks. Show parents and wide concepts as coverage
    plus their children, never as a single level. **Decided 2026-10-03:** as proposed.
18. **Requirements on empty nodes can never be met.** Readiness stays at 0/1 for everyone, forever.
    The map editor's coverage view should flag "required, nothing to practise".
19. **A node without `requires` is trivially ready.** Ranking "builds on something you have" first
    keeps those behind real next steps (the power-chord riff, which requires the root-string notes).
20. **"Review ahead, then stretch" in strict order starves stretch.** A caught-up 5-minute session
    holds all 27 review-ahead items. **Spike default:** split the leftover time half and half, each
    taking over the other's share when it runs out. **Open for the PO.**
21. **Graders work only from reference data.** The client's verdict is never trusted, and the
    client shows feedback with the same grader. Enharmonic spellings and the same note an octave up
    on the asked string count as right.
22. **Two things are versioned, not one.** Graders map a response to a verdict, and the mastery
    rules map evidence to a state. Keeping the raw response makes a grader change replayable. A
    mastery-rule change only needs a fold rebuild.
23. **The fold needs more than the knowledge state.** It also carries: counted attempts, the
    clean-tempo edge since the last review, the latest review's vouch, the best clean tempo or count
    since then, the last ten correct latencies, and the latest timestamp, which detects late
    evidence. Evidence sharing a timestamp needs a defined tiebreak (arrival sequence) for
    fold == batch to hold.
24. **Concepts echo skills on the home.** A concept backed by the same items as a skill repeats its
    progress line and its opportunities. **Proposed:** progress and opportunities per skill, with
    concepts in the map and as context. **Decided 2026-10-03:** as proposed.
25. **The opportunity list needs a cap.** Nine entries for the improving student. **Proposed:** the
    top three (one refresh, one strengthen, one start) and "see all".
26. **Practice days need the student's time zone.** The spike counts UTC dates.

## Decided

- **Practice ≠ assessment.** The existing challenge stays the path gate. Practice is open-ended and
  adaptive, and is never "done".
- **Verification is a manual teacher call.**
- **Server grading is authoritative**; the client grades only for instant feedback (2026-10-01).
- **A `practice.*` event family** carries raw responses (2026-10-01).
- **Practice is never blocked**, by grades or by waiting on a teacher. Suggestions only reorder
  (2026-10-01).
- **A teacher suggestion ends** when the item reaches the target level (default `accurate`) after the
  note, or when the teacher closes it, with a 30-day safety expiry (2026-10-02).
- **Stretch draws from any ready node** for the student's instrument, ranked closest first
  (2026-10-02).
- **Wide nodes show progress through their relationships**, not as one level of their own: a
  parent or wide concept shows coverage plus its children's levels (Finding 17, 2026-10-03).
- **The home reports progress and next steps per skill**; concepts appear in the map and as context
  (Finding 24, 2026-10-03).
- **The home is organised by skills and concepts**, never by exercise type. Progress comes before
  opportunities, and there are no streak resets or red badges (2026-10-01).

## Open for the ADR

| Question | Spike default |
|---|---|
| Caught-up time split, review ahead vs stretch (Finding 20) | half and half |
| Node-level share | 80% of the subtree's items at the level |
| Leitner boxes or FSRS for spaced repetition | Leitner, with waits of 1, 2, 4, 8, 16, 32 days |
| Fluent latency: fixed, or relative to the student's own baseline | fixed 2 s per fretboard cell |
| Session mix | due 60 / weak 25 / new 15 |
| Source weights | auto 0.3, self 0.3, teacher 0.6 |
| Real metronome click in play-along | not built: the drill's own sound only |
| Practice scope | path skills, teacher suggestions, then review ahead and stretch when caught up |
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

Phase 5 added `#progress` readiness, a skill-centred home and teacher-note closing; the suite is 124 tests.

No backend is needed: the page answers the voice list itself, using the same public guitar samples
the platform's voices come from. Hash links jump straight in: `#run=mind-5`, `#run=guitar-15`,
`#progress`, `#takes`, `#teacher`. The controls panel switches between simulated students, moves
"today", and shows any item's raw evidence next to its derived state. Live activity persists in the
browser. Recorded takes last only until reload.
