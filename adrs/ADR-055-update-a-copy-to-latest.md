# ADR-055: Updating a Learner's Copy to the Latest Published Course or Path

**Status:** Accepted
**Date:** 2026-10-12 (Proposed) · 2026-10-12 (Accepted, in review of specs#299)
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-36 (PB-81). Design: Figma "Learning", row 6, decisions U1–U8, approved 2026-10-12.

---

## Context

A learner's copy is fixed when it is made. A `StudentPath` copies its template's items and
presentation (ADR-017, ADR-042), and a `CourseEnrollment` is pinned to one `CourseVersion`
(ADR-029). When an author fixes or improves a published path or course, existing learners never
see the change. The only way to get it today is to leave and start again (ADR-042: archive, then
enroll), which loses the learner's place. MOT-83 made this visible: Learning rows show the
thumbnail saved at copy time, so a picture added later never reaches anyone who has already
started.

The current model is less pinned than the ADRs suggest, and those gaps define what needs fixing:

- **Lessons are effectively live already.** A `StudentPathItem` stores `content_node_version_id`
  (ADR-029), but nothing reads it. The learner's view takes each lesson's title and content from
  the live `ContentNode`, and there is no way to fetch a node version by id. So the node level needs
  no update.
- **Paths have no versions.** A published path is edited in place (ADR-042), so a copy cannot be
  "behind a version". It can only differ from its template.
- **Course parts copy live paths.** A `CourseVersion` pins its checkpoint list, but each checkpoint
  points to a live `LearningPath`. A part's `StudentPath` is copied when the part starts. Lessons in
  later parts are therefore never pinned by the course version.
- **Checkpoint advance ignores the pin.** When a learner finishes a part, core reads the next
  checkpoint from the course's latest `CourseVersion`, not from the enrollment's pinned one. This
  contradicts ADR-029.
- **Progress is per content node** (ADR-011, ADR-029), and a path's current item is derived: it is
  the first unfinished item. Finished lessons survive any change to the item list.

We considered three options: keeping the status quo (leave and start again); pushing template
edits to every copy automatically; and upgrading node versions inside a copy.

## Decision

MotifPath will let a learner update one of their own **in-progress** course enrollments or
standalone paths to the latest published content, as an explicit and irreversible step.

**1. When a copy is "behind" (the update is offered only then):**

- **A standalone `StudentPath`** that is not archived, not finished, and whose template is still
  published is behind when it differs from the template. That means any difference in:
  - the item list: the ordered `content_node_id`s and their `section_label`s;
  - the title;
  - the summary, level or thumbnail snapshots.
- **An active `CourseEnrollment`** is behind when either is true:
  - the course has a published `CourseVersion` newer than `course_version_number`;
  - the active part's `StudentPath` differs from its template, by the rule above.
- Finished, abandoned, archived or completed items are never offered the update. Starting a left
  item again already copies the latest content.
- Learner reads that list courses and paths (Learning, course detail) carry a derived
  `update_available` flag. The exact shapes are settled in the OpenAPI.

**2. Updating a standalone path** replaces the copy's items with the template's current items. Each
item's `content_node_version_id` resolves to the node's latest published version, as on any copy
(ADR-029). The update also refreshes the title and the summary, level and thumbnail snapshots. The
copy keeps its id, `assigned_by`/`assigned_at`, and whether it is current. Progress is untouched:
completion is per node, so finished lessons stay finished. The current item is still derived as
the first unfinished one, which also covers a removed current lesson.

**3. Updating a course enrollment:**

- It re-pins `course_version_number` to the latest published version and refreshes `course_title`
  and `course_thumbnail_url` from that version.
- **The active part:**
  - If the active part's path is still a checkpoint in the new version, the learner stays on it.
    `active_checkpoint_position` takes its position in the new version, and its `StudentPath` is
    updated as in (2).
  - If the active part's path is no longer a checkpoint, its `StudentPath` is archived. The new
    active part is the first checkpoint in the new version whose path the learner has not finished
    (where every lesson is completed), and it is copied as on a normal advance.
  - If every checkpoint is already finished, the enrollment completes.
- Parts before the active one in the new order count as passed, even when they are new. A course
  is a guide, and any of its paths can be taken on its own from the path catalog (ADR-042).
- **Advancing uses the pin.** Checkpoint advance reads the next checkpoint from the enrollment's
  pinned `CourseVersion`, as ADR-029 always said. From now on, this update is the only way an
  enrollment moves to a newer version.

**4. Rules common to both:**

- Only the learner can update, and only their own copies, whether self-enrolled or
  staff-assigned. No endpoint edits a copy today. Once concierge edits to a copy exist (ADR-017
  allows them), an edited copy will not be offered the update, so the update cannot overwrite the
  edits. Updating on a learner's behalf is not in the MVP.
- Updating a copy that is no longer behind changes nothing and returns it as it is.
- The update does not keep the previous items or version, so it cannot be undone. The client
  confirms first with a generic message. There is no preview of the changes (see Rationale).
- Updating never changes which item is current, never emits a learning event, and never touches
  practice or skill state.

**5. The node pin is an audit trail.** `StudentPathItem.content_node_version_id` records which
version was published when the item was copied, and the update rewrites it. No learner-facing read
depends on it. There is no node-level update.

## Rationale

- **Explicit update rather than automatic propagation.** Changing a copy can move or remove the
  lesson a learner is on. Pushing every template edit to every copy would break ADR-017's promise
  that a copy is independent of its template, and learners would find their path rearranged without
  being asked. One explicit, confirmed step keeps that promise. It also lets authors fix content
  without stranding existing learners.
- **No node level.** Lessons already show their live content, so a node update would change
  nothing a learner sees. Making the pin real, by serving the pinned version, would turn today's
  silent fixes (typos, a better video) into an opt-in, which is worse for learners. We rejected it.
- **Comparing with the template rather than adding path versions.** Paths are versionless by design
  (ADR-042). Comparing a copy's item list and presentation with its template answers "is it behind?"
  exactly, without a new versioning scheme. Course versions already exist, so courses compare
  version numbers and also check the active part's copy, since that is the only copied part.
- **No change counts in the confirm.** We considered an update-preview call that would list lessons
  added and removed. The counts would be misleading: a reordered or replaced lesson reads as "1
  removed, 1 added", and lessons in later course parts come from live paths, so they are not part of
  a course version at all. A generic message that is always true ("finished lessons stay finished;
  if the lesson you're on was removed, you continue at the next unfinished one") is honest. It also
  needs no extra endpoint.
- **Staying on the active part.** Learners told "you stay where you are" don't expect to be sent
  back to a part added earlier in the course. Treating earlier parts as passed matches how
  the course outline already reads (by position), and the learner can still take such a part's path
  on its own.
- **Fixing checkpoint advance here.** Without the fix, every enrollment would drift to the latest
  version at each part boundary anyway. Courses would then follow two rules at once, and the
  "behind" flag would be wrong after a part ended.
- **No Undo.** Undo would require keeping the previous item list and version for every updated
  copy, which is a history model for a rare action. A confirm is the pattern for irreversible
  actions (`overlays.md`), and nothing the learner did is lost. Progress, practice and skills are
  all keyed by node.

## Consequences

### Positive

- Corrected and improved content, including a new thumbnail, reaches learners who have already
  started, without losing their place.
- Courses follow one rule: the version is pinned until the learner updates.
- No new versioning model for paths. The comparison works on data that already exists.

### Negative / Trade-offs

- Working out whether a copy is behind means reading the template's items for every listed copy.
  That is fine at MVP scale, but it is per-row work on Learning reads.
- The confirm cannot tell the learner what changed. A learner who wants to know has to update first
  and look afterwards.
- A part inserted before the learner's active part is counted as passed without being done.
- The update cannot be undone. A learner who dislikes the new version cannot go back.
- An enrollment that would have moved to a newer version at its next part boundary no longer does.
  The learner has to accept the update.

### Neutral

- `StudentPathItem.content_node_version_id` stays in the schema but is only a record of the version
  that was published at copy time.
- How many learners accept the update is measured by the concierge for now (the MOT-36 validation
  method). No event is added.

## Related ADRs

- ADR-017: Student path as a copied instance. **Amended:** a copy may be updated from its template
  on the learner's explicit request; "template edits do not propagate" still holds for everything
  else.
- ADR-029: Course catalog and the multi-path lifecycle. **Amended:** an enrollment's pinned version
  changes only through this update, and checkpoint advance uses the pinned version. The node version
  stored on a copy is an audit trail.
- ADR-042: Path catalog and self-enrollment. **Amended:** besides archiving and enrolling again, a
  learner can update a standalone copy in place.
- ADR-011: Completion keyed by `(student, content_node_id)`. This is what lets progress survive an
  update.

---

*This ADR was decided on 2026-10-12. To revise it, create a new ADR with the status
"Supersedes ADR-055".*
