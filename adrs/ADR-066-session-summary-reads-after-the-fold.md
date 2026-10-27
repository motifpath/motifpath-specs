# ADR-066: The session summary reads each subject's rung level once the session's end is folded

**Status:** Accepted
**Date:** 2026-10-26
**Deciders:** Gilson (Product Owner)
**Input:** MOT-163 (the session summary shows each subject's level change and the next rung),
Figma "Practice Shell — flows" 13h and 16b (D32). PO answers, 2026-10-26: wait for the fold; name
the next rung only when the student reaches it.
**Accepted:** 2026-10-27, by Gilson.

---

## Context

Since MOT-77, the session summary shows one result per subject: the score and the rungs practised.
D32 asks for more: the level change on the rung practised, and the next rung once that rung is
reached ("Know it: Learning → Accurate · next: Hear it"). The summary is shown right after the
client sends `practice.session_ended`.

Levels come from the item states that the Aggregation Worker folds from `practice.item_answered`
events, and the worker runs asynchronously. A read made right after the session can still see some
of its answers unfolded. Read then, the summary would show a change that is too small or none at
all. That is worse than showing no change, because it tells the student their practice didn't count.

The "before" has the opposite problem. Once the session's answers are folded, the earlier levels
are gone, so they have to be captured when the session is composed.

The alternatives considered:
- read the subjects list again after a fixed delay;
- compute the level after in the client, by replaying the fold rules on the session's outcomes;
- show no change in the summary and let the next plan name it;
- a summary read that says whether the session's answers are all folded, with the levels before
  carried in the plan.

## Decision

**The plan carries each subject's rung and its level on that rung when composed. A new read gives
each subject's rung levels now, and whether the session is caught up: the worker has recorded the
session's end. The web waits a few seconds for that. If the session doesn't catch up, the summary
keeps the line it shows today.**

- **Before.** Each `PracticeFocusNode` in the plan gains:
  - `rung`, the subject's current rung for the session: the lowest rung with material whose items
    aren't yet accurate, or the top one;
  - `rung_level`, the student's level on that rung, over the items of the subject's subtree at that
    rung that suit the session. This is rolled up as a node's level is: the highest level at least
    80% of those items reach.
- **After.** `GET /students/me/practice-sessions/{practice_session_id}/subject-progress` takes the
  session's `instrument_id` (none for a session in the head) and its subjects' `node_id`s. For each
  subject it returns:
  - its current rung now;
  - its level on every rung with material, worked out as `rung_level` is.

  It also returns `caught_up`: true once the worker has recorded the session's
  `practice.session_ended`.
- **Why the end is enough.** `motifpath.events` is partitioned by `student_id`, and the worker
  handles a partition in order (ADR-006). An answer is graded and folded before it is recorded in
  its session. So once the end is recorded, every answer that reached the worker before it is
  already folded.
- **The line.** The web compares `rung_level` with the rung's level after, on the same rung:
  - it reached accurate or better from below: "Know it: Learning → Accurate · next: Hear it". The
    next rung is the subject's current rung now. When there is no rung above, no next is named;
  - it is unchanged: "Know it: Accurate · steady";
  - otherwise: "Hear it: New → Learning". This includes a level that fell.
- **Waiting.** The web reads the progress straight away and again every second, for up to 5 seconds,
  until `caught_up`. Meanwhile the score shows, and the line waits in place. If the session never
  catches up, the line names the rungs practised, as it does today.

## Rationale

- **A fixed delay** gives no guarantee. Worker lag depends on load, and a restart can stall it.
  The subjects list also gives the node's level, not the rung's, so the before and after wouldn't
  be on the same scale.
- **Replaying the fold in the client** would copy the mastery rules into a second repo: weights,
  attempt counts, fluent times and re-ask rules. The two copies would drift the first time the rules
  change (the rules already carry a version for that reason). One rule, computed in one place.
- **Moving the change to the next plan** loses the moment: the summary is where the student
  finishes and decides whether to come back.
- **Waiting on the recorded end** reuses guarantees the pipeline already has: ordering per student,
  and fold before record. It adds no new state. Core already reads the worker's `practice_sessions`
  collection, for alpha observation.

## Consequences

### Positive
- The summary shows a level change only once it is real, computed by the same rules as everywhere
  else.
- Nothing new is stored: the plan carries the before, and the after is read live.
- The read is safe to repeat and changes nothing, so polling is harmless.

### Negative / Trade-offs
- The client sends answers fire-and-forget. An answer whose POST is still in flight, or is retried,
  when the end is sent can reach the worker after the end. It is then left out of the change shown.
  This is rare, and the next session's plan reflects it.
- The summary depends on the worker being healthy within 5 seconds. Otherwise it falls back to the
  rungs practised. The student never waits on a spinner, but they lose the change.
- The before is only what the client kept. The summary of a session resumed from elsewhere can't
  show a change, and none exists today.
- Up to five extra reads per finished session.

### Neutral
- A wide node (one with child nodes) has a rung level too, over its subtree. The subjects list
  still shows no level for it.
- A subject whose practised rung falls (accurate to learning after misses) shows the fall, without
  a next rung.

## Related ADRs

- ADR-006: Kafka topology. Partitioning by student_id gives the per-student ordering this read
  relies on.
- ADR-057: Drill model v2. Subjects, rungs and the current rung.
- ADR-064: The precomputed practice subject catalog. The rung material the read tallies.

---

*This ADR was decided on 2026-10-26. To revise, create a new ADR with Status: Supersedes ADR-066.*
