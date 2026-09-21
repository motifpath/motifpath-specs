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

Three forces shape the decision:

1. **The platform-first premise.** MVP validation and student retention must not depend on
   external teacher supply; the team is the concierge. Retention is a product responsibility, so
   the "what's next" answer has to live in the product, not in a staff member's availability.
2. **Templates are authoring artifacts, not products.** A `LearningPath` is edited by content
   authors, has no student-facing description, and is listed to teachers and admins only
   (`GET /learning-paths` refuses students). A student-facing catalog needs a title, summary and
   lifecycle (draft, published, withdrawn) that a template should not carry.
3. **Business-model risk.** A browsable catalog can slide the platform toward a
   commodity-marketplace model and demote the teacher from curator to content supplier — the
   positioning the H4 hypothesis says MotifPath is against. The backlog item's original mitigation
   was to keep enrollment teacher/concierge-mediated. **This ADR knowingly departs from that
   mitigation** (see Decision and Consequences).

Alternatives considered:

- **Listing flag on `LearningPath`** (published state, summary, level added to the template) —
  smallest change, rejected below.
- **Teacher/concierge-mediated enrollment**, optionally with a student "request" step — the
  original PB-32 mitigation, rejected below.
- **A staff-only catalog** (list endpoint over templates, no student view) — cannot test the
  retention hypothesis, since the student never sees "what's next".

## Decision

MotifPath will add a **`Course`** entity as the student-facing catalog listing, let students
**self-enroll** in published courses, and complete the **multi-path lifecycle** ADR-017 left open.

**`Course` — the catalog entry.** A `Course` wraps one `LearningPath` template and carries the
student-facing listing:

- `id`, `title`, `summary`, `level` (nullable; `beginner` | `intermediate` | `advanced`),
  `learning_path_id` (required FK to the template), `status`, `created_by`, `created_at`,
  `published_at` (nullable).
- `status` is `draft` → `published` → `retired`. Only `published` courses appear to students.
  `retired` removes a course from the catalog without touching any `StudentPath` already created
  from it.
- A `Course` wraps exactly **one** template at MVP. A course composed of several sequenced
  templates (a "series") is out of scope; the entity boundary is what makes it possible later.
- A template referenced by any `Course` cannot be deleted (restrict). ADR-017's "template deletion
  is safe" still holds for *student instances* — they are copies — but no longer for a template a
  catalog entry points at; retire the course first.
- Enrollment copies the template's **current** items at the moment of enrollment. There is no
  course versioning at MVP: editing the template changes what *future* enrollees receive and never
  changes an existing `StudentPath` (ADR-017: template edits do not propagate).

**Authoring and publishing.** Teachers and admins may create and edit courses (same authorisation
as learning-path authoring). **Publishing and retiring are admin-only**, because with
self-enrollment a publish exposes the course to every student.

**Catalog read.** `GET /courses` returns published courses to students; teachers and admins see
all statuses (filterable). `GET /courses/{course_id}` returns the listing plus an **outline** — the
ordered item titles grouped by `section_label`, never lesson content — so a student can see what
they would be committing to. No search, tags, ranking or recommendation at MVP; the list is small
and ordered by `published_at` then `id`. Classification-driven browsing (ADR-026) and AI ranking
are follow-ups.

**Self-enrollment.** A student enrolls with `POST /students/me/paths` `{course_id}`. The operation
runs ADR-017's copy-on-assign in one transaction: it creates a `StudentPath` from the course's
template, records `source_course_id` (new nullable field on `StudentPath`, beside
`source_template_id`) and sets `assigned_by` to the student's own `user_id`. **`StudentPath` is the
enrollment record; no separate `Enrollment` table exists.**

- Enrollment sets the student's current path **only when it is null**. A student already working a
  path is never silently switched away from it.
- A student may hold **at most one non-archived `StudentPath` per course**; enrolling again while
  one exists is a conflict (409). After archiving it, enrolling again creates a fresh copy.
- Enrolling in a `draft` or `retired` course, or an unknown id, is not-found.
- **Concierge assignment is unchanged in kind:** staff can still assign *any* template (a course's
  or a bespoke one) to a student, producing a `StudentPath` with `source_course_id` null when it is
  not from a course. Staff assignment continues to set the current path (ADR-017).

**Multi-path lifecycle (completes ADR-017's surface).**

- `GET /students/me/paths` — the student's non-archived paths, each with derived summary progress
  (completed / total items, and whether it is the current one).
- `PUT /students/me/current-path` `{student_path_id}` — switch current. The target must belong to
  the caller and be non-archived; otherwise not-found.
- `POST /students/me/paths/{student_path_id}/archive` — a student may archive (leave) their own
  path; staff may archive any student's path. Archiving the current path **clears** the pointer
  (deterministic; no automatic "next path" choice), and `GET /students/me/path` returns 404 until
  the student picks another.
- `GET /students/me/path` is unchanged from ADR-017: singular, resolves the current pointer,
  `assignment_id` → `student_path_id`.
- "Path completed" is derived (every item `completed`); nothing new is stored. The "what's next"
  prompt is a client behaviour over `GET /students/me/paths` and `GET /courses`.

This ADR **amends ADR-017** in one respect — self-enrollment does not always set the current
pointer — and otherwise builds on it. Exact request/response shapes, error bodies and Gherkin are
settled in the OpenAPI and feature files, not here.

## Rationale

- **`Course` over a listing flag on `LearningPath`.** A template is an authoring artifact with no
  student audience; putting `published`, `summary` and `level` on it welds two lifecycles together
  (a half-edited template is one flag away from being public) and makes "withdraw from the
  catalog" indistinguishable from "delete the template". A separate entity lets a course be
  retired, re-pointed or retitled without touching the template, keeps enrollment provenance
  (`source_course_id`) stable, and is the boundary a future multi-template series needs. The cost
  is a second aggregate that is one-to-one with a template at MVP; we accept that because the
  alternative would be a migration the day a course stops mapping one-to-one.
- **Self-enrollment over teacher/concierge-mediated enrollment.** Mediated enrollment makes the
  answer to "what's next" depend on a staff member acting, which contradicts the platform-first
  premise and cannot be measured cleanly: a low second-path rate could mean the catalog is weak or
  that nobody approved requests. Self-enrollment tests the hypothesis directly. It is a deliberate
  reversal of the backlog item's original teacher-mediation mitigation, taken because the MVP
  team *is* the concierge and staff-gated enrollment does not scale past the alpha. The marketplace
  risk is contained differently — by keeping publishing admin-only, so the catalog stays curated —
  rather than by gating the student.
- **Enrollment sets current only when null.** Self-service means a student can enroll while
  mid-path; silently repointing "current" would make their home screen jump. Staff assignment
  keeps ADR-017's behaviour because it is an explicit, supervised act.
- **`StudentPath` as the enrollment record.** It already has `student_id`, `assigned_by`,
  `assigned_at` and the copied items; a separate `Enrollment` row would duplicate all of it and add
  a consistency problem. Retention metrics (second path within 30 days of completing the first)
  are computable from `StudentPath.assigned_at` and derived completion with no new event or table.
- **Archiving the current path clears the pointer** instead of auto-selecting another, because
  "which path is next" is exactly the choice the catalog exists to prompt; auto-picking would hide
  it and add a non-obvious rule to test.
- **One non-archived path per course** prevents accidental duplicate copies from a double-click or
  retry without forbidding a deliberate restart (archive, then enroll again).

## Consequences

### Positive
- The product itself answers "what's next": a student who finishes a path can browse and start
  another with no staff involvement, and the PB-32 metric is measurable from existing data.
- The catalog lifecycle is decoupled from template authoring; a course can be withdrawn or edited
  safely.
- ADR-017's deferred surface (list, switch, archive) is specified once, together with the reason
  it is needed.
- No new completion state, no change to ADR-011 or the Aggregation Worker.

### Negative / Trade-offs
- **Business-model risk is accepted, not mitigated by mediation.** Student self-enrollment moves
  MotifPath closer to a browsable marketplace and away from the teacher-as-curator positioning.
  Admin-only publishing is the only guard. PB-32's Notion "Business Risk" mitigation text is now
  out of date and must be revised.
- **The PB-32 validation plan is not waived.** The backlog item calls for watching the alpha, 5–8
  teacher interviews and a landing-page/waitlist test before building. This ADR records the design
  decision only; whether and when to implement stays a backlog decision.
- **PB-31 is a hard prerequisite.** Nothing here can be built until the `StudentPath` /
  `StudentLearningState` model exists; this ADR only specifies the catalog on top of it.
- No cap on concurrent non-archived paths per student; a student could enroll in many courses.
  Acceptable at alpha scale, revisit if it shows up in usage.
- A `Course` is one-to-one with a template at MVP, so it is an extra table and endpoint set that
  adds no capability yet beyond listing metadata and lifecycle.
- Because courses use the template's live items, a mid-flight template edit changes what the next
  enrollee gets without any signal on the course. Course versioning is deferred.
- Amending ADR-017 means its "assigning sets the current path" sentence is now true only for staff
  assignment; readers must consult this ADR for self-enrollment.
- The web client needs a "no current path but has paths" state distinct from the "your teacher is
  building your path" holding state, since archiving the current path now yields a 404 for a
  student who still has other paths.

### Neutral
- `source_course_id` joins `source_template_id` on `StudentPath` for provenance; neither is used
  for behaviour after the copy.
- Student data-erasure scope is unchanged: enrollments *are* `StudentPath` rows already swept by
  ADR-017's list. `Course` holds no student data.

## Related ADRs

- **ADR-017** (Student path as a copied instance) — the model this builds on; amended so
  self-enrollment sets the current pointer only when null, and extended with the list / switch /
  archive surface.
- **ADR-015** (Node challenge and path sections) — `section_label` groups the outline shown in
  `GET /courses/{course_id}`.
- **ADR-011** (Minimal Aggregation Worker) — unchanged; per-`(student, node)` completion still
  drives derived path progress.
- **ADR-026** (Content classification graph) — a candidate for later catalog filtering and
  recommendation; out of scope here.

---

*This ADR was decided on 2026-09-21. To revise, create a new ADR with Status: Supersedes ADR-029.*
