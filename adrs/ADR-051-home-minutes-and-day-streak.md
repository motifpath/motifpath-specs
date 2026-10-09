# ADR-051: Minutes Practised and a Day Streak on the Home

**Status:** Accepted
**Date:** 2026-10-07 (Proposed) · 2026-10-07 (Accepted, in review of specs#235)
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-43
**Amends:** ADR-046 (the "counts, never streaks" decision for the home)
**Amended:** 2026-10-09 — Songs replaces Skills up on the home (see the end)

---

## Context

The home is being redesigned with the App Shell (ADR-049, MOT-43). It leads with what to do now
(today's practice, then the invitation to continue the path), then shows two motivating blocks:
**This week**, as three tiles, and **Your skills**, as the count of skills at each knowledge level.
Everything else (practice and learning days, what moved this week) moves to a **Your progress**
page opened on demand.

The Product Owner chose the tiles for motivation: **minutes practised this week** (with the change
against the week before), **day streak** (with the best one), and **skills up this week**. Two of
the three don't exist:

- the practice overview counts practice days and learning days, but not time;
- ADR-046 decided that the home counts days and **never shows a streak**, because a streak reset
  punishes a missed day. It also kept the raw activity (every session's start, answers and end) so
  that "a streak or another measure can be evaluated later without new tracking".

Practising a little on most days matters more for a student's progress than long, rare sessions,
and a streak is the most widely understood signal for it. The risk ADR-046 named is real: a reset
can make a student who missed one day feel they lost everything, and quit.

Alternatives considered:

- **(a) Keep ADR-046 as it is**: show "practice days, 4 of 7" instead of a streak. No reset, and
  the data exists.
- **(b) A forgiving streak**: a missed day is "frozen" once a week, or the streak counts weeks with
  at least N practice days.
- **(c) A plain day streak, shown kindly** — this ADR.

## Decision

MotifPath will show **minutes practised** and a **day streak** on the home, computed from the
activity the worker already keeps. This amends ADR-046 only in its "never streaks" rule. Practice
days, learning days and every other rule there remain.

1. **Minutes practised** in a 7-day window is the sum, over the student's practice sessions that
   started in the window, of the time from the session's start to its last practice event. Every
   session counts, including one left early or abandoned: the minutes were practised even when the
   session doesn't count as a practice day. The total is rounded down to whole minutes. The overview
   returns this week's minutes (the last 7 calendar days, including today, in the student's time
   zone) and the previous 7 days' minutes, so the home can show the change.
2. **Day streak** is the number of consecutive calendar days, in the student's time zone, that are
   practice days (as ADR-046 defines them: a finished session, not left early and not abandoned).
   It ends **today, or yesterday when the student hasn't practised yet today**. Today without
   practice never breaks the streak before the day is over. The **best streak** is the longest run
   the student has ever had.
3. **Skills up this week** is the number of skills, counted once per instrument, with at least one
   improved measure in that instrument's progress this week.
4. **Shown kindly**: the home never says a streak was lost or broken, and never shows it in a
   warning or danger colour. When the current streak is 0, the tile invites the student to start
   one, and still shows the best streak. Losing a streak raises no notification or badge.

## Rationale

- **Over (a), practice days only**: a 7-day count already rewards consistency, but it caps at 7 and
  restarts every week by construction. A streak gives a student who practises daily a number that
  keeps growing, and the best streak is an achievement the student keeps. The PO chose the streak
  for motivation.
- **Over (b), a forgiving streak**: freezes and weekly streaks need rules a student has to learn
  ("how many freezes do I have left?") and screens to explain them. A plain day streak is
  understood without explanation. The punishment ADR-046 worried about is mostly how a reset is
  *shown*, which decision 4 addresses: no "lost" message, no red, an invitation instead of a zero,
  and a best streak that is never taken away.
- **Today never breaks the streak** because a student opening the app at 8 a.m. hasn't missed
  anything yet. Ending the streak at yesterday until the day is over avoids showing 0 every morning.
- **Minutes count every session**, unlike practice days, because time spent practising is real even
  in a session left early. Counting it rewards effort without changing what a practice day means.
- **No new tracking**: all three measures come from the raw activity ADR-046 already keeps
  (session starts, answers, ends and per-item progress snapshots). This is exactly the later
  evaluation ADR-046 anticipated.

## Consequences

### Positive

- The home shows effort (minutes), consistency (streak) and improvement (skills up) at a glance,
  the motivation the redesign is for.
- No new event or tracking: the worker derives everything from activity it already keeps.
- The best streak gives every student a lasting achievement, even after a gap.

### Negative / Trade-offs

- A streak can still discourage a student who breaks a long one, however kindly it is shown. The
  retention baseline (ADR-049 §10) should be watched for students returning after a broken streak.
- "Minutes practised" measures time in the app, not attention: a session left open while doing
  something else counts until its last practice event. Ending at the last event, not at the session's
  end, limits this.
- Two more aggregations on the overview read, over the student's whole history for the best streak.
  The worker may need to keep the best streak as a running value instead of recomputing it.

### Neutral

- Practice days and learning days stay as ADR-046 defines them; they move from the home to Your
  progress.
- The streak is across instruments, like the overview's practice days. No per-instrument streak.

## Related ADRs

- ADR-046: Evidence-based practice model — defines practice days and the raw activity; amended here
  in its "never streaks" rule only.
- ADR-049: Practice-first experience language — the App Shell and home redesign this serves.
- ADR-012: Idempotency and delivery guarantees — a re-sent session event is stored once, so it never
  counts minutes twice.

---

*This ADR was proposed and accepted on 2026-10-07. To revise, create a new ADR with Status: Supersedes ADR-051.*

## Amendment (2026-10-09) — Songs replaces Skills up on the home

**Task:** MOT-63 (design sign-off, decision D6), MOT-99 · **Decided by:** Gilson Yamada (PO)

The song chart redesign (MOT-73, D17) found that Skills up repeated **Your skills**, the block right
under it, and that the home showed no growth in music the student recognises. The third This week
tile becomes **Songs**.

**Decision:**

1. The home's This week tiles are **minutes practised**, **day streak** and **songs played**.
2. **Songs played** is the number of distinct song charts the student has marked as played with the
   reader's "I played it" (`song_chart.completed`), ever, plus how many of them were first marked
   in the last 7 calendar days, in the student's time zone. Marking the same chart again counts
   once. A chart withdrawn later still counts: the student played it.
3. **Skills up this week** (decision 3 above) stays as it is and is shown on **Your progress**,
   with the other This week tiles.
4. When song practice lands (MOT-76), the tile switches from songs played to songs **in your
   repertoire** (clean on two separate days). That change will be its own amendment.

**Rationale:**

- **Over dropping Skills up:** it costs nothing more (the measure is specified and in progress) and
  Your progress is where students who want detail look.
- **Over waiting for repertoire (MOT-76):** repertoire needs song practice, self-ratings and review
  scheduling, none of which exists yet. Songs played comes from an event the reader already sends,
  so the home can show song growth now.

**Consequences:**

- Core consumes `song_chart.completed`, an event no consumer used before, and keeps each student's
  first-played date per chart.
- Song charts have no instrument (the first chord catalog is guitar-only, ADR-045), so songs played
  is across instruments, like the streak. Per-instrument songs are MOT-76's decision.
- "Played" is the student's own claim, not graded. That is the point of a growth signal, and it is
  why repertoire will later replace it.
