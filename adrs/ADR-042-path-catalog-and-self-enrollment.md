# ADR-042: A published path catalog with learner self-enrollment

**Status:** Accepted
**Date:** 2026-09-30
**Deciders:** Gilson (Product Owner)
**Revised:** 2026-09-30, in spec review. Staff may assign only published paths.
**Amends:** ADR-029 (standalone paths are staff-assigned only) and ADR-017 (what a `StudentPath`
records at copy time). It extends ADR-038's filterable path library and reuses PB-68's course
presentation.

---

## Context

PB-68 made the course catalog convert: a shared card, a detail page, filters, and a return to the
catalog that keeps the learner's place. PB-80 asks for the same thing for paths. A learner should be
able to open "Find a path", filter, read a path's detail, and enroll in it without a teacher.

ADR-029 rules that out today. Only staff can start a standalone `StudentPath`, by assigning a
`LearningPath` template to a student (`POST /students/{student_id}/student-paths`). Learners reach
paths only through `GET /students/me/path`, and `GET /learning-paths` is an authoring listing that
learners can't call. The template itself isn't ready to be shown to a learner:

1. **No published state.** Every path in the library is visible to staff: half-built paths, and
   paths that exist only to fill a course checkpoint. Nothing marks a path as offered to learners.
2. **Nothing to sell it with.** A `LearningPath` has a title, a level, instruments and a thumbnail,
   but no summary and no language, the two fields the course card and the language filter rely on.
3. **Nothing to show it with once enrolled.** A `StudentPath` copies only the title. "My courses"
   can't show a standalone path on the same card as a course, and the template it was copied from
   may since have been edited or deleted (ADR-017 allows both).

We considered three ways to decide what a learner sees:

- **List every path in the library.** No new state, but learners would see drafts and
  checkpoint-only paths.
- **Course-style versioning:** draft/published plus an immutable `PathVersion` snapshot per
  publish, like `CourseVersion`. Authors could keep editing without learners seeing it.
- **A published flag without versions.** Only published paths are listed; edits to a published
  path are live.

We also considered showing paths inside "Find a course". We rejected it: ranking and filtering two
kinds of result in one list is hard to follow, and paths have no checkpoints to count.

## Decision

**`LearningPath` gains a `status` (`draft | published`), a `summary` and a `language`.**

- `summary` and `language` work like `level` (ADR-038): a path created before them has no value
  until it's next saved. `language` is a `Language.code` other than `"any"`, as for courses.
- Every path starts as `draft`. Only `published` paths appear to learners.
- **Publishing and unpublishing are admin-only**, as for courses (ADR-029):
  `POST /learning-paths/{learning_path_id}/publish` and `.../unpublish`. Publishing is refused
  (409) unless the path has a title, summary, language, level, at least one item, and every item's
  content node has at least one published version. Unpublishing returns the path to `draft`: it
  leaves the catalog, and every `StudentPath` already copied from it is untouched.
- **There are no path versions.** Edits to a published path are live, and the next enrollment copies
  them. Nobody sees a half-edited path, because `PUT /learning-paths/{id}` replaces the whole path
  in one step. A replace that would leave a published path unpublishable (for example, removing its
  summary or its last item) is refused (409).
- A published path can't be deleted (409). Unpublish it first. The existing rule still applies:
  a path used by any published course version can never be deleted.
- A path can be published standalone and also used as a course checkpoint. The two are unrelated.

**A learner catalog for paths, parallel to the course catalog (ADR-037).** The same for every
caller, whatever their role:

- `GET /catalog/paths`: published paths only, paginated `{items, total, limit, offset}` (ADR-031),
  ordered by title then id. It has the same optional filters as `GET /catalog/courses`: `q`,
  `levels`, `created_by`, `skill_ids`, `concept_ids`, `language` and `instrument_id`. A path matches
  `skill_ids`/`concept_ids` as in ADR-038's library filter. Each entry carries the card fields
  (title, summary, level, language, creator, instruments, thumbnail) plus `lesson_count` (the number
  of items). No authoring detail is exposed.
- `GET /catalog/paths/{learning_path_id}`: one published path's detail. It adds an outline (item
  titles grouped by `section_label`, ADR-015) and never lesson content. A draft or unknown path is
  404.
- `GET /catalog/path-creators`: every distinct creator of at least one published path, with the
  same shape and ordering as `GET /catalog/creators`.

**Learners enroll themselves: `POST /students/me/student-paths` `{learning_path_id}`.**

- It copies the published template into a new standalone `StudentPath`, exactly as a staff
  assignment does (ADR-017, copy-on-assign). `assigned_by` is the learner.
- **The new path always becomes current**, the same as a staff assignment. Enrolling is an explicit
  "start this now". Course enrollment differs on purpose: it sets current only when nothing is set
  (ADR-029). The course-or-path the learner was on keeps its progress and is one switch away.
- **Enrolling is never refused because of what the learner already holds.** A path that also
  appears as a checkpoint of one of the learner's courses can be enrolled in directly. Progress is
  kept per content node, not per copy, so lessons already finished show as completed in the new
  copy, and finishing them there counts in the course too.
- **Re-enrolling reuses the active copy.** If the learner already holds a non-archived standalone
  `StudentPath` copied from the same template, enrolling makes that copy current and returns it
  (200) instead of creating a second one. Otherwise it creates the copy (201). An archived copy
  isn't reused: enrolling again creates a fresh copy.
- A draft or unknown path is 404. Any user may enroll, whatever their role (ADR-037).
- **Staff can assign only published paths** (`POST /students/{student_id}/student-paths`). Assigning a
  draft path is refused (409). Otherwise assignment is unchanged: it still sets the path as current
  unconditionally. A path a learner is asked to follow must meet the same bar as a path a learner
  finds for themselves. A draft path is unfinished whoever hands it out.

**A `StudentPath` records its presentation at copy time.** On every copy (standalone or course
checkpoint, self-enrolled or staff-assigned), the `StudentPath` gains snapshots of the template's
`summary`, `level`, `thumbnail_url` and creator, next to the `title` it already copies.
`GET /students/me/student-paths` also returns a derived `lesson_count` and `completed_count` from the
path's own items. A path copied before this change has no snapshots and shows only its title.

**The authoring library (`GET /learning-paths`) gains `language` and `status` filters**, and each
entry reports its `status`. That way the teacher's path list offers the same filters as "Find a
path", plus the publishing state.

## Rationale

**A published flag, not versions.** Course versions exist because a course is a sequence that
learners move through over weeks. When a later checkpoint changes, an enrolled learner meets it
later, so ADR-029 pins each enrollment to a snapshot. A standalone path doesn't have that problem.
Enrolling copies the whole path at once, and each item pins its content node's published version
(ADR-017). Later edits to the template never reach an existing learner. The only thing a version
would protect is the catalog entry between edits, and replace-in-one-step already covers that. A
`PathVersion` table, a version-pinned read model and a publish-snapshot flow would cost a lot for
that one benefit. We rejected "list everything" because learners must never see drafts or
checkpoint-only paths.

**Admin-only publishing** follows ADR-029's reason: publishing exposes a path to every learner for
the first time. The concierge team stays the gatekeeper at MVP.

**Always current, unlike courses.** We accept the difference in behavior. Choosing a path from the
catalog is a deliberate "start this now", the same act as a teacher assigning one, so it gets the
same effect. ADR-029 protected a learner mid-course from being switched away, but that was about
enrolling in *another course* from the congrats page. Here the learner is choosing a path directly.
Their other enrollments keep their progress, and "My learning" switches back in one click.

**No refusal on overlap.** A course is a guide: a structured order through paths that are shared.
A learner who wants one path from a course can go straight to it. Refusing enrollment, as ADR-029
does for a second active enrollment in the same course, would protect nothing. Progress is per
content node, so a node finished in one path is finished in every path that contains it. We rejected
a 409 on a second active copy for that reason. **Reusing the active copy** on re-enrollment is only
about tidiness: a double click, or a learner who forgot, lands on the path they already have instead
of listing the same path twice in "My learning". The trade-off is that the reused copy keeps the
items it was copied with, even if the template has changed since. A learner who wants the current
version archives the old copy and enrolls again.

**Snapshot presentation on the copy** keeps ADR-017's promise that a copy is independent of its
template: the template can be edited or deleted without touching any student's path. Reading the
card live from the template would break "My learning" when a template is deleted. PB-68 hit exactly
that failure with course drafts (core 299bdfc). The snapshot is four small columns, written once.

## Consequences

### Positive
- Learners have a second way in, which targets the PB-32 "what's next" hypothesis without a teacher,
  in line with the platform-first premise.
- The web reuses PB-68's card, detail layout, filters and catalog-return behavior for paths.
- "My courses", renamed "My learning", shows courses and standalone paths on the same card.

### Negative / Trade-offs
- An admin who edits a published path changes what the next enrollee copies, immediately. There's
  no staging area. Authors who need one must unpublish, edit, then republish.
- Course enrollment and path enrollment set the current path differently. The UI must make the
  switch visible (enrolling in a path lands the learner on it).
- Existing paths have no summary or language. They must be completed before an admin can publish
  them, and older `StudentPath`s show a title-only card.
- Every existing path starts as a draft, and staff can assign only published paths. Until an admin
  completes and publishes a path, no one can assign it. The concierge must publish before
  assigning, and a path meant for one student only is still visible in the catalog once published.
- Two catalogs mean two creator lists and two filter sets to keep in step.

### Neutral
- `StudentPath` gains four nullable snapshot columns, written on every copy, including course
  checkpoints, where the course card doesn't show them yet.
- Self-enrolled paths go through the existing archive flow (ADR-029). Nothing new is needed to
  leave one.

## Related ADRs

- ADR-015: Node challenge and path sections. The outline groups items by `section_label`.
- ADR-017: Student path copied instance. Amended here: a copy also records its presentation.
- ADR-026: Content classification graph. It powers the skill and concept filters.
- ADR-029: Course catalog and multi-path lifecycle. Amended here: learners may self-enroll in
  published standalone paths, and doing so sets the path as current.
- ADR-031: Offset pagination for content lists.
- ADR-036: Localized catalog names.
- ADR-037: Every user can learn. Any role may browse the path catalog and enroll.
- ADR-038: Course authoring metadata and a filterable path library. The library gains `language`
  and `status` filters.

---

*This ADR was accepted on 2026-09-30. To revise, create a new ADR with Status: Supersedes ADR-042.*
