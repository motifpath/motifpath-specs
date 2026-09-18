# ADR-023: Challenge time threshold is informational, and remediation targets move to Exercise

**Status:** Accepted
**Date:** 2026-09-18
**Deciders:** Gilson (Product Owner)

---

## Context

`motifpath-specs` PR #72 (Phase 1 of the teacher content-authoring implementation plan,
`motifpath-web/plans/PB-40-content-authoring-web.md`) added list and update endpoints for
`ContentNode`, `Challenge`, `ExpandedContent`, and `LearningPath` — the first real review pass
these schemas had received since ADR-019 defined the Challenge/Exercise model. That review
surfaced two gaps in the model ADR-019 committed to, neither of which is addressed by simply
adding update endpoints to what already existed.

**Timing has no place in the model at all.** `Exercise` carries an optional
`estimated_duration_seconds`, described only as "used to fit practice sessions and challenges to
a student's available time" — but nothing reads or aggregates it. A `Challenge` has a
score-based `pass_threshold` and no time dimension whatsoever. The product needs a way to reason
about how long a challenge takes, both to show a student what to expect and to give the team
data for tuning content — not to gate or cut off an attempt.

**Remediation is scoped to the wrong resource, and to the wrong content shape.**
`CreateChallengeRequest.remediation_target_content_node_id` is a single, optional reference to
another internal `ContentNode`, attached at the whole-Challenge level. Two problems with that:

1. A student's failing score on a challenge with several exercises says nothing about *which*
   exercise they actually struggled with — the remediation-worthy signal lives at the exercise
   level, not the challenge level. A single challenge-wide target can only ever be a generic
   fallback, never a targeted "here's help with the specific thing you got wrong."
2. The target can only be another `ContentNode` already published inside MotifPath. Real
   remediation content is often a specific YouTube tutorial, an external article, or a short
   clarifying note that doesn't warrant authoring a full lesson — none of which fits a bare
   `content_node_id` reference, and a plain URL string is too thin to carry a caption or explain
   *why* the link is being suggested.

Both gaps were raised as PR #72 review comments, not discovered independently — this ADR
formalizes the direction the PO gave in that review rather than treating the endpoint-shape
questions as implementation details to guess at.

Nothing has shipped against the pre-PR-72 shape: PR #72 itself is unmerged, and no consuming
code (`motifpath-core`, `motifpath-web`) has been written against either the old
`remediation_target_content_node_id` field or the absence of a time dimension on `Challenge`.
This is a schema correction before first implementation, not a breaking change to deployed
behavior.

Alternatives considered:

- **Keep remediation at the Challenge level, just widen it to a list.** Rejected — this fixes
  none of the actual problem (a list of generic fallbacks is still not *which exercise* the
  student struggled with) and defers the real fix to a later, harder migration once Challenge-
  level remediation is already in use.
- **Store external remediation as a plain URL string.** Rejected — a URL alone can't carry a
  caption, can't distinguish "watch this video" from "read this note," and duplicates a
  document-authoring capability (links, embedded video, embedded audio) the platform already
  built for exercise prompts and lesson content under ADR-020. Introducing a second, thinner way
  to reference external content is unnecessary and inconsistent.
- **Make the time threshold a hard limit that fails or auto-submits the attempt.** Rejected for
  now, explicitly by the PO — the product need today is visibility and internal tuning data, not
  enforcement. A hard limit is a real feature with its own UX and scoring implications (what
  happens to an in-progress answer when time runs out?) that this ADR does not decide.
- **Store the Challenge time threshold as a persisted, frozen default at creation time.**
  Rejected — a Challenge's exercises are linked *after* creation
  (`POST /challenges/{challenge_id}/exercises/{exercise_id}`), so no exercise total exists yet
  at `createChallenge` time. Freezing a default then would either be wrong (zero, since nothing
  is linked yet) or require a write on every link/unlink to keep it current. A read-time
  computed fallback avoids both.

## Decision

**Challenge gains an optional, informational time threshold. Remediation targets move from a
single Challenge-level content-node reference to a list of Exercise-level targets, each either
an internal content node or inline rich content authored the same way ADR-020 already defines.**

1. **`Challenge.time_threshold_ms`** — a nullable integer, milliseconds. When a teacher sets it
   explicitly (via `CreateChallengeRequest`/`UpdateChallengeRequest`), that value is
   authoritative. When omitted, the value returned in the `Challenge` response is computed at
   read time as the sum of `estimated_duration_seconds * 1000` across the challenge's currently
   linked exercises (an exercise with no `estimated_duration_seconds` set contributes 0) — never
   persisted as a frozen default, so it always reflects the challenge's current exercise links.
   This field is **purely informational**: it is not enforced anywhere, does not gate
   submission, and does not affect scoring. It exists for two purposes — shown to the student as
   a pacing expectation before they start a challenge, and used internally by the team for
   content-tuning judgment (a challenge whose real completion times run far past its threshold
   is a signal the content or threshold needs revisiting). Milliseconds, not seconds, to keep it
   consistent with tracking-event timestamp precision (`occurred_at`) rather than
   `estimated_duration_seconds`'s coarser unit — the two units differ deliberately, since one is
   an authoring-time estimate and the other is meant to line up with runtime measurement.

2. **`remediation_target_content_node_id` is removed from `Challenge`.** Remediation moves
   entirely to `Exercise`, which gains `remediation_targets`: an ordered list, each entry either

   - an internal reference (`content_node_id`), or
   - inline rich content (`rich_content`, the same ProseMirror-JSON document shape ADR-020
     defines for `PromptDocument`) — for a specific external video, article, or short clarifying
     note, using the links/embedded-video/embedded-audio nodes ADR-020's authoring model already
     supports, with no separate URL field or content type needed.

   Each entry is one or the other, never both. A student's remediation suggestion is now
   attached to the exercise they actually got wrong, not to the challenge as a whole — a
   challenge's overall remediation experience (if the product wants one) is derived by whoever
   consumes this data from the specific exercises the student missed, which is PB-8g's decision
   to make, not this ADR's.

## Rationale

Time-as-information rather than time-as-enforcement matches what the product actually needs
right now: a pacing signal for the student and a tuning signal for the team, neither of which
requires solving the harder problem of what happens to an in-progress, ungraded attempt when a
clock runs out. Milliseconds were chosen deliberately over reusing `estimated_duration_seconds`'s
unit, so the two fields don't silently invite an inconsistent-precision bug the moment someone
compares a threshold against a real measured duration.

Computing the un-overridden threshold at read time, from currently-linked exercises, is the only
option that stays correct as a teacher adds or removes exercises after creating the challenge —
a stored default would either be created wrong (before any exercises are linked) or require
extra write-path bookkeeping this ADR has no reason to introduce for a purely informational
field.

Moving remediation to Exercise follows the same principle ADR-019 already established for the
Exercise/Challenge relationship itself: the exercise, not the challenge, is the unit that
actually carries meaning independent of its container. ADR-019 made Exercise reusable across
challenges for exactly this reason: a student's difficulty with alternate picking is a fact
about that skill, not about whichever challenge happened to contain the exercise that surfaced
it. Remediation is the same shape of fact — attaching it to the specific exercise the student
missed, rather than the challenge, is consistent with that ADR rather than a departure from it.

Reusing ADR-020's rich-content model for external targets, instead of a raw URL field, avoids
building a second, thinner content-authoring mechanism next to a first-party one the platform
already committed to. A remediation note that's "watch this video, starting around the chorus"
needs exactly the caption-plus-embed capability ADR-020's document model already provides —
duplicating a weaker version of it for this one field would be pure waste.

## Consequences

### Positive

- Students get a pacing expectation before attempting a challenge, without the product having to
  decide (yet) what a hard time limit does to an in-progress attempt.
- The team gets real completion-time data to compare against authored thresholds, informing
  content and threshold tuning over time.
- Remediation is now targeted at the specific exercise a student struggled with, not a generic
  challenge-wide fallback — a materially more useful signal for whatever PB-8g eventually builds
  on top of it.
- External remediation content (a video, an article, a short note) is expressed with the same
  rich-content model already used for exercise prompts and lesson content, rather than a second,
  thinner mechanism — one authoring pattern for "content with embedded media and links" across
  the whole platform.

### Negative / Trade-offs

- `Challenge.time_threshold_ms`'s read-time computation means two calls to `GET /challenges/{id}`
  for the same un-overridden challenge can return different values if exercises were linked or
  unlinked in between — expected and desired (it should reflect current links), but worth calling
  out since it's a genuine departure from every other field on this resource, which is stable
  between writes.
- `Exercise.remediation_targets` is a bigger schema surface than a single nullable UUID —
  `motifpath-core`'s domain model, `motifpath-web`'s authoring UI, and any future remediation
  consumer must all handle "which shape is this target" branching, not just an optional
  reference.
- Removing `remediation_target_content_node_id` from `Challenge` is a breaking schema change
  relative to what ADR-019/the original PR #72 draft specced — acceptable here only because
  nothing has implemented or shipped against it yet; this would not be an acceptable path once
  `motifpath-core` has real code and data depending on the old shape.
- No enforcement mechanism exists for `time_threshold_ms` — a challenge that reports a threshold
  a student consistently blows past has no automatic consequence. If the product later wants
  enforcement, that is a new decision (with real scoring/UX implications for an in-progress,
  ungraded attempt), not something this ADR pre-authorizes.

### Neutral

- `Exercise.estimated_duration_seconds` is unchanged by this ADR — it remains the per-exercise,
  author-supplied estimate, in seconds, that `time_threshold_ms`'s default computation reads
  from (converting to milliseconds at read time). This ADR does not rename, re-unit, or
  otherwise touch that existing field.
- PB-8g's remediation-recommendation logic is unaffected in scope by this ADR — it gains a
  richer, exercise-scoped signal to consume, but the decision of when/whom to surface a
  remediation target to remains PB-8g's, unchanged.

## Related ADRs

- **ADR-019** (Practice content model) — this ADR amends ADR-019's implicit Challenge shape
  (the `remediation_target_content_node_id` field ADR-019's implementation carried, though not a
  field ADR-019's own decision text named explicitly) by moving remediation to Exercise. ADR-019's
  Exercise/Challenge many-to-many relationship, skill tags, exercise typology, and
  option-selection checking model are all unchanged by this ADR.
- **ADR-020** (Tiptap content-authoring editor) — `Exercise.remediation_targets[].rich_content`
  reuses the `PromptDocument` ProseMirror-JSON shape ADR-020 committed to for exercise prompts,
  with the full node set (links, video, audio) ADR-020's decision point 3 already defines for
  its authoring editor — not the narrower node set ADR-020's 2026-09-17 amendment scoped down
  specifically for the exercise-*prompt* field. This ADR does not change ADR-020's decisions; it
  is a new consumer of the same document shape.

---

*This ADR was decided on 2026-09-18. To revise, create a new ADR with Status: Supersedes ADR-023.*
