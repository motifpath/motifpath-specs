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

Five forces shape the decision:

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
4. **A course author needs to keep working after publishing.** A teacher publishing course v1
   cannot be blocked from shaping v2 (reordering checkpoints, swapping a template) until they
   choose to release it. Editing and publishing are different actions with different timing,
   entirely the author's call.
5. **Business-model risk.** A browsable catalog can slide the platform toward a
   commodity-marketplace model and demote the teacher from curator to content supplier — the
   positioning the H4 hypothesis says MotifPath is against. The backlog item's original mitigation
   was to keep enrollment teacher/concierge-mediated. **This ADR knowingly departs from that
   mitigation** (see Decision and Consequences).

Alternatives considered:

- **Course wraps exactly one `LearningPath`** — the original draft of this ADR. Rejected in
  review: it cannot express a multi-stage journey ("checkpoints"), which is the actual shape of
  the retention hypothesis (a student needs a *next stage*, not just an unrelated second path).
- **Publishing edits a course in place** — an earlier draft of this ADR. Rejected in review: it
  gives the author no way to shape a future version without either blocking on a release decision
  or exposing half-finished changes to students immediately.
- **One global "current path" pointer across all of a student's paths** — the original draft's
  model, inherited unmodified from ADR-017. Rejected in review: a student can be enrolled in
  several courses at once, and "which path is active" is really two questions — which *course* is
  the student running right now, and which *checkpoint* within it — not one flat pointer.
- **Teacher/concierge-mediated enrollment**, optionally with a student "request" step — the
  original PB-32 mitigation, rejected below.
- **A staff-only catalog** (list endpoint over templates, no student view) — cannot test the
  retention hypothesis, since the student never sees "what's next".
- **No versioning; require courses/nodes to be edited in place** — rejected: an in-place edit to a
  published course or a content node a student has already worked through would retroactively
  change what that student sees or has completed, which ADR-017 already ruled out at the template
  level.

## Decision

MotifPath will add a **`Course`** entity as an ordered, author-editable journey of `LearningPath`
checkpoints with an explicit draft/publish split, let students **self-enroll** with a per-course
active checkpoint, version content nodes so existing student work is never silently altered, and
complete the **multi-path lifecycle** ADR-017 left open.

**`Course` — the journey, live-editable.** The `Course` row and its `CourseCheckpoint` rows are the
author's **working draft**, always editable by their creator, independent of whether the course has
ever been published:

- `Course{id, title, summary, level, status, created_by, created_at, latest_published_version
  (nullable)}`.
- `CourseCheckpoint{course_id, position, learning_path_id, title (optional override, e.g. "Stage 1:
  Open chords")}` — the live, currently-being-authored sequence.
- `level` reuses ADR-026's five-value difficulty enum (`beginner | early_intermediate |
  intermediate | advanced | expert`) rather than a separate three-value scale — the level a
  student should be at to start the course, using the same rubric already applied to content
  nodes.
- `status` is `draft` (never published) → `published` (has at least one `CourseVersion`) →
  `retired`. **Editing the live `Course`/`CourseCheckpoint` rows never changes `status` and never
  affects what a student sees** — only publishing does that (below). A `published` course with
  unreleased draft edits is still `published`; the draft/published split is orthogonal to status.
- A template referenced by any checkpoint, in any published `CourseVersion`, cannot be deleted
  (restrict); retire the course first.

**Publishing snapshots the draft into an immutable `CourseVersion`.** `CourseVersion{course_id,
version_number, checkpoints_snapshot, published_at, available_for_new_enrollments}` is created only
by an explicit **admin-only** publish action, which copies the current `Course`/`CourseCheckpoint`
state verbatim. `Course.latest_published_version` then points at it. **Students and new enrollees
only ever see the latest `CourseVersion`, never the live draft** — so an author can freely reshape
checkpoints toward the next release while every current student keeps seeing the last published,
stable sequence. A course with `status = draft` (nothing published yet) is not in the catalog at
all. `available_for_new_enrollments` (default true) lets an author freeze a version to only the
students already progressing through it, while a newer version takes new enrollees.

**Enrollment is its own record, tracking a per-course active checkpoint.**
`CourseEnrollment{id, student_id, course_id, course_version_number, enrolled_at, status (active |
completed | abandoned), active_checkpoint_student_path_id}`. Enrolling creates the `CourseEnrollment`
row pinned to the course's `latest_published_version` at that moment, plus checkpoint 1's
`StudentPath` (copy-on-assign, as ADR-017), which becomes `active_checkpoint_student_path_id`.
`StudentPath` gains `source_course_enrollment_id` (nullable) and `course_checkpoint_position`
(nullable, set together) for provenance. Completing every item in the active checkpoint's
`StudentPath` creates the next checkpoint's `StudentPath` and updates
`active_checkpoint_student_path_id` to it (a client-visible "next stage unlocked" moment — the
concrete answer to "what's next" the PB-32 hypothesis is testing). Completing the last checkpoint
sets `CourseEnrollment.status = completed`; the enrollment (and its checkpoint history) is kept, not
deleted.

**Authoring.** Teachers and admins may create and edit courses and checkpoints (same authorisation
as learning-path authoring) at any time, published or not. **Publishing and retiring are
admin-only**, because publishing exposes the current draft state to every student for the first
time (or moves existing students onto a new sequence's *future* checkpoints — never their
already-copied ones).

**Catalog read.** `GET /courses` returns courses with `status = published` to students; teachers and
admins see all statuses (filterable), each annotated with whether unpublished draft changes exist.
`GET /courses/{course_id}` returns the latest `CourseVersion`'s listing plus an **outline**: each
checkpoint's title and its ordered item titles grouped by `section_label` (ADR-015), never lesson
content. No search, tags, ranking or recommendation at MVP; the list is small and ordered by
first-published-at then `id`. Classification-driven browsing (ADR-026) and AI ranking are
follow-ups.

**Self-enrollment.** A student enrolls with `POST /students/me/course-enrollments` `{course_id}`,
creating the `CourseEnrollment` and checkpoint 1's `StudentPath` as described above.

- A student may hold **at most one active `CourseEnrollment` per course**; enrolling again while one
  is `active` is a conflict (409). A `completed` or `abandoned` enrollment does not block
  re-enrolling — a fresh `CourseEnrollment` is created, starting again at checkpoint 1.
- Enrolling in a `draft` or `retired` course, a version with `available_for_new_enrollments = false`
  as the latest, or an unknown id, is not-found.
- **Concierge (staff) assignment is unchanged in kind and stays course-independent:** staff assign a
  bare `LearningPath` template directly to a student, producing a **standalone** `StudentPath`
  (`source_course_enrollment_id` null). This is not a `CourseEnrollment` at all — see the current-path
  model below for how standalone paths coexist with course enrollments.

**The "current" path is two-level: current course (or standalone path), then that course's active
checkpoint.** `StudentLearningState{student_id PK, current_course_enrollment_id (nullable FK to
CourseEnrollment), current_standalone_path_id (nullable FK to StudentPath)}`. Application-layer
invariant: **at most one of the two is set**; both null means nothing is running.
`GET /students/me/path` resolves whichever is set — for a course enrollment, that enrollment's
`active_checkpoint_student_path_id`; for a standalone pointer, that `StudentPath` directly — and
404s when neither is set. `assignment_id` becomes `student_path_id` in the response, as ADR-017
already decided.

- A student can be **enrolled in several courses at once** (each with its own `CourseEnrollment`
  independently tracking its own active checkpoint) but only **one course, or one standalone path,
  is "current"** at a time. **"Switching courses" means repointing `StudentLearningState`**, not
  touching any `CourseEnrollment`'s own progress — switching back later resumes exactly where that
  course's checkpoint was left.
- `PUT /students/me/current-path` `{course_enrollment_id}` **or** `{student_path_id}` (exactly one)
  — switches which is current. The target must belong to the caller (an active, non-abandoned
  `CourseEnrollment`, or a non-archived standalone `StudentPath`); otherwise not-found.
- Enrolling in a course sets it as current **only when nothing is currently set**. A student
  actively running another course, or a standalone path, is never silently switched away from it.
  Staff assignment of a standalone path **does** set it as current unconditionally (ADR-017,
  unchanged) — an explicit, supervised act.

**Leaving / archiving.**

- `POST /students/me/course-enrollments/{id}/abandon` — sets `status = abandoned` on the whole
  enrollment (all of its checkpoints' `StudentPath`s are implicitly left behind; per-checkpoint
  partial archiving does not exist, since checkpoints are sequential and owned by one enrollment).
- `POST /students/me/paths/{student_path_id}/archive` — archives a **standalone** `StudentPath`
  only (course checkpoints are managed via the enrollment action above).
- **Neither action may remove the student's only current thing** while something else eligible
  exists to become current: abandoning the current `CourseEnrollment`, or archiving the current
  standalone path, is refused (409) if the student has another active `CourseEnrollment` or
  non-archived standalone path available — the student must `PUT
  .../current-path` to switch first. If it truly is the student's *only* running thing, the action
  is allowed and clears `StudentLearningState` entirely; `GET /students/me/path` then 404s until
  the student enrolls in or is assigned something new.
- "Path completed" / "course completed" are derived (every item `completed`; `CourseEnrollment`
  reaching its last checkpoint's completion); nothing new is stored beyond the checkpoint-advance
  and `status` transitions above.

This ADR **amends ADR-017** in three respects — the current-path pointer becomes two-level and
lives partly on a new `CourseEnrollment` entity rather than solely on `StudentLearningState`;
self-enrollment sets current only when nothing is set; and a current course/path can no longer be
left while another is available without switching first — and otherwise builds on it. Exact
request/response shapes, error bodies and Gherkin are settled in the OpenAPI and feature files, not
here.

**Content node versioning.** `ContentNode` gains a `version_number` and a `superseded_by_node_id`
(nullable, set when a new version is published). Editing a published node's substance (not a typo
fix — that stays a same-version edit) publishes a new node version: the new version reuses the
node's stable identity for authoring purposes but is a distinct row with its own id, and the old
version's row is marked `superseded_by_node_id`. A `StudentPathItem` and its per-node completion
fact continue to reference the exact node version the student worked with: an existing completion
is never retargeted to the new version and is never invalidated. A freshly copied `StudentPathItem`
(new enrollment, or a template/checkpoint pointing at the node going forward) always resolves to the
current version. This is the same "copy is a point-in-time snapshot, never live" rule ADR-017
already applies to templates, and this ADR now applies to courses, applied one level further down.
Node authoring UX and the exact migration of existing `ContentNode.classification` rows are out of
scope here — this ADR settles only that versions exist and how completion and path items resolve
them.

## Rationale

- **Course as an ordered set of checkpoints, not a 1:1 template wrapper.** The retention
  hypothesis is specifically about "what's next" — a student finishing one stage should be handed
  the next stage of the *same* journey, not merely nudged toward an unrelated second path. A
  checkpoint sequence expresses that directly and reuses `LearningPath` unchanged as the unit of
  content structure ADR-017 already defined; `CourseCheckpoint` is a thin ordering layer, not a new
  content model.
- **A live draft separate from an immutable published snapshot.** Coupling "editable" to
  "published" would force an author to choose between freezing improvements until release or
  exposing half-built changes to students. Splitting them lets authoring proceed continuously while
  `CourseVersion` gives every enrolled student a stable, citable sequence that only moves forward
  when the author decides. The cost is two representations of "the checkpoints" (live draft rows vs.
  a version snapshot) instead of one, accepted because the alternative directly blocks authoring
  workflow.
- **`CourseEnrollment` as its own entity, not folded into `StudentPath`.** Once a student can run
  several courses in parallel, each needs its own "where am I in this course" state independent of
  which one is globally current — that is exactly what `active_checkpoint_student_path_id` on
  `CourseEnrollment` gives, and it also resolves re-enrollment (a fresh `CourseEnrollment` row per
  attempt) without inventing a separate grouping key. `StudentPath` stays what ADR-017 defined it as
  — one linear sequence of items — and now optionally carries provenance back to the enrollment and
  checkpoint that produced it.
- **A two-level current pointer (course-or-standalone, then per-enrollment checkpoint) over one flat
  pointer.** A single `current_student_path_id` cannot express "the student is running course A, on
  its second checkpoint, while also enrolled in course B, still on its first" — switching courses
  would have had to silently lose or fabricate checkpoint position. Splitting "which course/path is
  current" (`StudentLearningState`) from "which checkpoint is active within a given course"
  (`CourseEnrollment`) lets switching be a cheap, lossless pointer change in both directions.
- **Self-enrollment over teacher/concierge-mediated enrollment.** Mediated enrollment makes the
  answer to "what's next" depend on a staff member acting, which contradicts the platform-first
  premise and cannot be measured cleanly. Self-enrollment tests the hypothesis directly. It is a
  deliberate reversal of the backlog item's original teacher-mediation mitigation, taken because the
  MVP team *is* the concierge and staff-gated enrollment does not scale past the alpha. The
  marketplace risk is contained differently — by keeping publishing admin-only — rather than by
  gating the student.
- **Course and node versioning, both non-retroactive.** ADR-017 already decided that a template edit
  must never change an existing `StudentPath`. Once a course can be revised after students are
  mid-journey, and a node can be re-authored after students have completed it, the same guarantee
  has to extend to both, or an edit anywhere in the content graph becomes a hazard to in-progress or
  completed student work.
- **A student cannot leave their only current course/path without a replacement, but abandoning is
  otherwise free.** Letting "abandon current" silently clear the pointer when nothing else is
  available puts a student one click from a dead-end home screen even when they have somewhere to
  go. Forcing "switch, then leave" when an alternative exists makes the student's intent explicit;
  allowing it outright when nothing else exists keeps `GET /students/me/path` 404 reserved for the
  genuine "nothing assigned" case.

## Consequences

### Positive
- The product itself answers "what's next" at two grains: a new checkpoint within a course, and a
  new course once a journey ends — both measurable from existing data.
- Authors can continuously improve a course without ever exposing in-progress edits to students, and
  without blocking on a publish decision to keep working.
- A student can run multiple courses in parallel with independent progress in each, switching
  between them without losing position in either.
- Course and node edits are safe to make at any time; no in-progress or completed student work can
  be retroactively altered by an authoring change.
- ADR-017's deferred surface (list, switch, archive) is specified once, together with the reason it
  is needed, and the current-path abandonment hazard from the original draft is closed.

### Negative / Trade-offs
- **Business-model risk is accepted, not mitigated by mediation.** Student self-enrollment moves
  MotifPath closer to a browsable marketplace and away from the teacher-as-curator positioning.
  Admin-only publishing is the only guard. PB-32's Notion "Business Risk" mitigation text is now out
  of date and must be revised.
- **Substantially larger surface than the original draft.** `CourseCheckpoint`, `CourseVersion`,
  `CourseEnrollment`, and `ContentNode` versioning are all new; this is a bigger `motifpath-core`
  change than a simple catalog listing would have been, and the two-level current-path model is more
  state to keep consistent than ADR-017's single pointer.
- **Two versioning schemes to keep consistent** (course version, node version), each with its own
  "what does an in-progress student see" rule. More surface for a future author-facing UI to get
  wrong, and more to test.
- **The PB-32 validation plan is not waived.** The backlog item calls for watching the alpha, 5–8
  teacher interviews and a landing-page/waitlist test before building. This ADR records the design
  decision only; whether and when to implement stays a backlog decision.
- **PB-31 is a hard prerequisite.** Nothing here can be built until the `StudentPath` /
  `StudentLearningState` model exists; this ADR only specifies the catalog on top of it.
- No cap on concurrent `CourseEnrollment`s per student; acceptable at alpha scale.
- Node versioning duplicates node rows over time (a `superseded_by_node_id` chain); no archival or
  cleanup policy is decided here.
- Amending ADR-017 means its "assigning sets the current path" and single-pointer sentences are now
  qualified or restructured; readers must consult this ADR for self-enrollment, the two-level current
  model, and the leave/archive restriction.
- The web client needs: a "next checkpoint unlocked" moment, a "newer course/node version available"
  notice, a course switcher distinct from a plain path switcher, and a "must switch before leaving"
  flow — several new UI states beyond today's holding-state screen.

### Neutral
- `source_course_enrollment_id` / `course_checkpoint_position` on `StudentPath`, and
  `course_version_number` on `CourseEnrollment`, are provenance and resolution fields; none are used
  for completion logic, which stays `(student, content_node_version)`.
- Student data-erasure scope grows to include `CourseEnrollment` alongside `StudentPath`,
  `StudentPathItem` and `StudentLearningState`; `Course`, `CourseCheckpoint` and `CourseVersion` hold
  no student data.

## Related ADRs

- **ADR-017** (Student path as a copied instance) — the model this builds on; amended so the current
  pointer is two-level (course-or-standalone, then per-enrollment active checkpoint), self-enrollment
  sets current only when nothing is set, and a current course/path cannot be left while another is
  available. Extended with the list / switch / leave surface.
- **ADR-015** (Node challenge and path sections) — `section_label` groups the outline shown per
  checkpoint in `GET /courses/{course_id}`.
- **ADR-026** (Content classification graph) — `Course.level` reuses its 5-level difficulty enum;
  node versioning here extends the same `ContentNode` this ADR classifies.
- **ADR-011** (Minimal Aggregation Worker) — unchanged in mechanism; completion now keys off a
  specific node version rather than a version-less node id.

---

*This ADR was decided on 2026-09-21. To revise, create a new ADR with Status: Supersedes ADR-029.*
