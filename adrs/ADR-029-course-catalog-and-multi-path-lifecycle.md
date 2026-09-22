# ADR-029: Course Catalog with Student Self-Enrollment, and the Multi-Path Lifecycle

**Status:** Proposed
**Date:** 2026-09-21
**Deciders:** Gilson Yamada (solo engineering at MVP)

---

## Context

This is PB-32 ("Path catalog & multi-enrollment — paths-as-courses"). Its hypothesis: informal
students churn after finishing (or stalling on) a single path because there is no visible "what's
next"; offering more paths to move into should raise 90-day retention and the share of
path-completers who start a second path within 30 days.

ADR-017 already decided the *shape* of a student's path: a reusable `LearningPath` template is
**copied** into a per-student `StudentPath`, a student may hold many, and one is "current" via
`StudentLearningState.current_student_path_id`. It deliberately stopped there: no list endpoint, no
catalog, no enrollment UI. That model is accepted but **not yet specified or built** — the OpenAPI
and Gherkin in this repo still describe the single-assignment `PathAssignment` model
(`POST /students/{student_id}/path-assignments`, `GET /students/me/path` returning `assignment_id`).
PB-32 therefore cannot be specified in isolation: it needs the multi-path lifecycle (list my paths,
switch current, archive) that ADR-017 left implicit, and it needs something for students to
browse.

Four forces shape the decision:

1. **The platform-first premise.** MVP validation and student retention must not depend on
   external teacher supply; the team is the concierge. Retention is a product responsibility, so
   the "what's next" answer has to live in the product, not in a staff member's availability.
2. **A course is a journey, not a single checkpoint.** A student's learning arc is naturally a
   sequence of stages — e.g. "fingerstyle basics" then "fingerstyle repertoire" — each of which is
   itself a coherent, independently assignable `LearningPath`. Modeling a `Course` as a wrapper
   around exactly one template would collapse that structure and misname the "checkpoint" concept
   as "the whole course".
3. **Nothing may retroactively change what a student already has.** ADR-017 established that
   template edits do not propagate to an existing `StudentPath`. This ADR extends the same
   principle two levels further: a course can gain a new version without disturbing a student
   mid-journey, and a content node can gain a new version without silently altering — or worse,
   un-completing — work a student already finished.
4. **Business-model risk.** A browsable catalog can slide the platform toward a
   commodity-marketplace model and demote the teacher from curator to content supplier — the
   positioning the H4 hypothesis says MotifPath is against. The backlog item's original mitigation
   was to keep enrollment teacher/concierge-mediated. **This ADR knowingly departs from that
   mitigation** (see Decision and Consequences).

Alternatives considered:

- **Course wraps exactly one `LearningPath`** — the original draft of this ADR. Rejected in
  review: it cannot express a multi-stage journey ("checkpoints"), which is the actual shape of
  the retention hypothesis (a student needs a *next stage*, not just an unrelated second path).
- **Teacher/concierge-mediated enrollment**, optionally with a student "request" step — the
  original PB-32 mitigation, rejected below.
- **A staff-only catalog** (list endpoint over templates, no student view) — cannot test the
  retention hypothesis, since the student never sees "what's next".
- **No versioning; require courses/nodes to be edited in place** — rejected: an in-place edit to a
  published course or a content node a student has already worked through would retroactively
  change what that student sees or has completed, which ADR-017 already ruled out at the template
  level.

## Decision

MotifPath will add a **`Course`** entity as an ordered journey of `LearningPath` checkpoints, let
students **self-enroll**, version both courses and content nodes so existing student work is never
silently altered, and complete the **multi-path lifecycle** ADR-017 left open.

**`Course` — the journey.** A `Course` is a student-facing catalog entry composed of an **ordered
list of checkpoints**, each checkpoint referencing one `LearningPath` template:

- `Course{id, title, summary, level, status, created_by, created_at, published_at (nullable)}`.
- `CourseCheckpoint{course_id, position, learning_path_id, title (optional override of the
  template's own title, e.g. "Stage 1: Open chords")}`.
- `level` reuses ADR-026's five-value difficulty enum (`beginner | early_intermediate |
  intermediate | advanced | expert`) rather than a separate three-value scale — it is the level a
  student should be at to start the course, using the same rubric already applied to content nodes.
- `status` is `draft` → `published` → `retired`, as before. Only `published` courses appear to
  students. `retired` removes a course from the catalog without touching any in-progress
  enrollment.
- A template referenced by any checkpoint, in any course version, cannot be deleted (restrict);
  retire the course (or superseding version — see below) first.

**Enrollment creates one `StudentPath` per checkpoint, in sequence.** Enrolling in a course creates
the `StudentPath` for checkpoint 1 immediately (copy-on-assign, as ADR-017); it becomes the
student's current path if they have none. Completing every item in a checkpoint's `StudentPath`
auto-creates the next checkpoint's `StudentPath` and offers it as the new current path (a
client-visible "next stage unlocked" moment — the concrete answer to "what's next" the PB-32
hypothesis is testing). `StudentPath` gains `source_course_id` (nullable) and
`course_checkpoint_position` (nullable, set together) so a student's progress through the journey
is reconstructable without a separate enrollment/progress table. A `CourseEnrollment` marker row
is **not** needed for the single-course case: "is the student in this course" is answered by "does
a `StudentPath` with this `source_course_id` exist for them". (If a student may later enroll in the
same course twice — e.g. after finishing it — `source_course_enrollment_id` replaces
`source_course_id` as a grouping key; deferred until that need is confirmed.)

**Authoring and publishing.** Teachers and admins may create and edit courses and checkpoints (same
authorisation as learning-path authoring). **Publishing and retiring are admin-only**, because with
self-enrollment a publish exposes the course to every student.

**Catalog read.** `GET /courses` returns published courses to students; teachers and admins see all
statuses (filterable). `GET /courses/{course_id}` returns the listing plus an **outline**: each
checkpoint's title and its ordered item titles grouped by `section_label` (ADR-015), never lesson
content — so a student can see the whole journey, not just the first stage, before enrolling. No
search, tags, ranking or recommendation at MVP; the list is small and ordered by `published_at`
then `id`. Classification-driven browsing (ADR-026) and AI ranking are follow-ups.

**Self-enrollment.** A student enrolls with `POST /students/me/paths` `{course_id}`, which creates
checkpoint 1's `StudentPath` as described above.

- A student may hold **at most one active (non-fully-abandoned) journey per course**: re-enrolling
  while any of that course's `StudentPath`s are non-archived is a conflict (409). Archiving all of
  them allows enrolling again, starting fresh at checkpoint 1.
- Enrolling in a `draft` or `retired` course, or an unknown id, is not-found.
- **Concierge assignment is unchanged in kind:** staff can still assign any template directly
  (course-independent), producing a `StudentPath` with `source_course_id` null. Staff assignment
  continues to set the current path (ADR-017) and is exempt from the archive-before-switch rule
  below, since it is an explicit, supervised act.

**Course versioning.** A `Course` may be revised after publishing (checkpoints added, reordered, or
repointed to a different template version). Revising a published course creates a new
`CourseVersion` row (`course_id, version_number, checkpoints snapshot, published_at`); the `Course`
row always points at its current version for new enrollments. An existing `StudentPath` records
which `course_version_number` it was enrolled under (new field, alongside `source_course_id`) and
is **never** moved to a newer version automatically. A student partway through an older version
sees a "a newer version of this course is available" notice (derived by comparing their
`course_version_number` to the course's current version) but keeps progressing through the
version they started — including which checkpoint comes next. Whether a course version stays
available to new enrollees or is limited to students already on it is a per-version flag
(`available_for_new_enrollments`), set at authoring time; default true.

**Content node versioning.** `ContentNode` gains a `version_number` and a `superseded_by_node_id`
(nullable, set when a new version is published). Editing a published node's substance (not a typo
fix — that stays a same-version edit) publishes a new node version: the new version reuses the
node's stable identity for authoring purposes but is a distinct row with its own id, and the old
version's row is marked `superseded_by_node_id`. A `StudentPathItem` and its per-node completion
fact continue to reference the exact node version the student worked with: an existing completion
is never retargeted to the new version and is never invalidated. A freshly copied `StudentPathItem`
(new enrollment, or a template/course pointing at the node going forward) always resolves to the
current version. This is the same "copy is a point-in-time snapshot, never live" rule ADR-017
already applies to templates, now applied one level down. Node authoring UX and the exact
migration of existing `ContentNode.classification` rows are out of scope here — this ADR settles
only that versions exist and how completion and path items resolve them.

**Multi-path lifecycle (completes ADR-017's surface).**

- `GET /students/me/paths` — the student's non-archived paths, each with derived summary progress
  (completed / total items), which course and checkpoint (if any) it belongs to, and whether it is
  the current one.
- `PUT /students/me/current-path` `{student_path_id}` — switch current. The target must belong to
  the caller and be non-archived; otherwise not-found.
- `POST /students/me/paths/{student_path_id}/archive` — a student may archive (leave) their own
  path; staff may archive any student's path. **A student cannot archive their current path directly
  while another non-archived path exists** — they must switch current (`PUT
  .../current-path`) to the other path first, then archive the one they left. If the path being
  archived is the student's *only* non-archived path, archiving it is allowed and clears the
  current-path pointer; `GET /students/me/path` then 404s until the student enrolls in or is
  assigned something new.
- `GET /students/me/path` is unchanged from ADR-017: singular, resolves the current pointer,
  `assignment_id` → `student_path_id`.
- "Path completed" is derived (every item `completed`); nothing new is stored beyond the
  checkpoint-advance trigger above.

This ADR **amends ADR-017** in two respects — self-enrollment does not always set the current
pointer, and a current path can no longer be archived out from under a student who has another
path available — and otherwise builds on it. Exact request/response shapes, error bodies and
Gherkin are settled in the OpenAPI and feature files, not here.

## Rationale

- **Course as an ordered set of checkpoints, not a 1:1 template wrapper.** The retention
  hypothesis is specifically about "what's next" — a student finishing one stage should be handed
  the next stage of the *same* journey, not merely nudged toward an unrelated second path. A
  checkpoint sequence expresses that directly and reuses `LearningPath` unchanged as the unit of
  content structure ADR-017 already defined; `CourseCheckpoint` is a thin ordering layer, not a
  new content model.
- **One `StudentPath` per checkpoint, auto-advanced on completion**, over one `StudentPath`
  spanning the whole course. Keeping the existing `StudentPath` = "one linear sequence of items"
  contract intact means completion, unlock and read-time status derivation (ADR-017,
  `BuildStudentPathItems`) need no changes; the course layer only decides *when to create the next
  one*. The cost is an extra row per checkpoint transition instead of one continuous list, accepted
  because it keeps the per-path invariants simple.
- **Self-enrollment over teacher/concierge-mediated enrollment.** Mediated enrollment makes the
  answer to "what's next" depend on a staff member acting, which contradicts the platform-first
  premise and cannot be measured cleanly. Self-enrollment tests the hypothesis directly. It is a
  deliberate reversal of the backlog item's original teacher-mediation mitigation, taken because
  the MVP team *is* the concierge and staff-gated enrollment does not scale past the alpha. The
  marketplace risk is contained differently — by keeping publishing admin-only — rather than by
  gating the student.
- **Course and node versioning, both non-retroactive.** ADR-017 already decided that a template
  edit must never change an existing `StudentPath`. Once a course can be revised after students are
  mid-journey, and a node can be re-authored after students have completed it, the same guarantee
  has to extend to both, or an edit anywhere in the content graph becomes a hazard to in-progress or
  completed student work. Versioning both, with an explicit "new version available" notice rather
  than silent adoption, keeps that guarantee uniform at every layer instead of holding only at the
  top.
- **A student cannot archive their current path while another exists.** Letting "archive current"
  silently clear the pointer (the original draft) puts a student one click from a dead-end home
  screen even when they have somewhere to go. Forcing "switch, then archive" makes the student's
  intent explicit and keeps `GET /students/me/path` 404 reserved for the genuine "nothing assigned"
  case rather than an accidental one.
- **`StudentPath.source_course_id` (not a separate `Enrollment` table) as the enrollment record**,
  scoped per checkpoint. It already has `student_id`, `assigned_by`, `assigned_at` and the copied
  items; a separate table would duplicate all of it. Retention metrics (second course/checkpoint
  started within 30 days) are computable from existing `assigned_at` timestamps with no new event.

## Consequences

### Positive
- The product itself answers "what's next" at two grains: a new checkpoint within a course, and a
  new course once a journey ends — both measurable from existing data.
- Course and node edits are safe to make at any time; no in-progress or completed student work can
  be retroactively altered by an authoring change.
- The catalog lifecycle is decoupled from template authoring; a course (or a version of it) can be
  withdrawn or edited safely.
- ADR-017's deferred surface (list, switch, archive) is specified once, together with the reason it
  is needed, and the current-path archive hazard from the original draft is closed.

### Negative / Trade-offs
- **Business-model risk is accepted, not mitigated by mediation.** Student self-enrollment moves
  MotifPath closer to a browsable marketplace and away from the teacher-as-curator positioning.
  Admin-only publishing is the only guard. PB-32's Notion "Business Risk" mitigation text is now out
  of date and must be revised.
- **Significantly larger surface than the original draft.** `CourseCheckpoint`, `CourseVersion`,
  and `ContentNode` versioning are all new; this is a bigger `motifpath-core` change than a simple
  catalog listing would have been.
- **Two versioning schemes to keep consistent** (course version, node version), each with its own
  "what does an in-progress student see" rule. More surface for a future author-facing UI to get
  wrong, and more to test.
- **The PB-32 validation plan is not waived.** The backlog item calls for watching the alpha, 5–8
  teacher interviews and a landing-page/waitlist test before building. This ADR records the design
  decision only; whether and when to implement stays a backlog decision.
- **PB-31 is a hard prerequisite.** Nothing here can be built until the `StudentPath` /
  `StudentLearningState` model exists; this ADR only specifies the catalog on top of it.
- No cap on concurrent journeys per student across different courses; acceptable at alpha scale.
- Node versioning duplicates node rows over time (a `superseded_by_node_id` chain); no archival or
  cleanup policy is decided here.
- Amending ADR-017 means its "assigning sets the current path" and "archiving clears the pointer"
  sentences are now qualified; readers must consult this ADR for self-enrollment and for the
  archive-current restriction.
- The web client needs: a "next checkpoint unlocked" moment, a "newer course/node version
  available" notice, and a "must switch before archiving" flow — three new UI states beyond today's
  holding-state screen.

### Neutral
- `source_course_id` / `course_checkpoint_position` / `course_version_number` on `StudentPath` are
  provenance and resolution fields; none are used for completion logic, which stays
  `(student, content_node_version)`.
- Student data-erasure scope is unchanged in kind: enrollments are still `StudentPath` rows,
  already swept by ADR-017's list. `Course`, `CourseCheckpoint` and `CourseVersion` hold no student
  data.

## Related ADRs

- **ADR-017** (Student path as a copied instance) — the model this builds on; amended so
  self-enrollment sets the current pointer only when none is set, and a current path cannot be
  archived while another exists. Extended with the list / switch / archive surface.
- **ADR-015** (Node challenge and path sections) — `section_label` groups the outline shown per
  checkpoint in `GET /courses/{course_id}`.
- **ADR-026** (Content classification graph) — `Course.level` reuses its 5-level difficulty enum;
  node versioning here extends the same `ContentNode` this ADR classifies.
- **ADR-011** (Minimal Aggregation Worker) — unchanged in mechanism; completion now keys off a
  specific node version rather than a version-less node id.

---

*This ADR was decided on 2026-09-21. To revise, create a new ADR with Status: Supersedes ADR-029.*
