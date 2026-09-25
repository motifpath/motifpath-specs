# PB-65 — Course builder (authoring UI)

**Status:** Draft, revised after PO review (2026-09-25)
**Repos:** `motifpath-specs` (ADR-038, OpenAPI 0.14.0, scenarios), `motifpath-core`,
`motifpath-web`.
**API:** the existing course calls (`createCourse`, `getCourse`, `replaceCourse`,
`getPublishedCourse`, `publishCourse`, `retireCourse`), plus what ADR-038 adds:
- `Course.language`, and a `language` filter on both course lists;
- `POST /courses/{course_id}/reactivate`;
- `LearningPath.level` and `updated_at`;
- `listLearningPaths` filters (`created_by`, `levels`, `skill_ids`, `concept_ids`) and `sort`;
- `instrument_ids` and `thumbnail_url` on courses, learning paths and content nodes, an
  `instrument_id` filter on their lists, and the `thumbnail` upload purpose.

**Builds on:** the teacher Courses tab (`/teacher/courses`, from PB-32), ADR-029 (course
versions), ADR-037 (authoring list is staff-only), ADR-038 (this item's API additions).

## Problem

Teachers and admins can list the courses they manage at `/teacher/courses`, but can't open
one. The web app has no way to create a course, edit its draft, or publish or retire it, even
though the API has supported all of that since PB-31/32. Today a course can only be made
through the seeders or direct API calls.

## Decisions (PO, 2026-09-25)

1. **Publishing, retiring and reactivating are admin-only.** A teacher builds and edits
   drafts; an admin publishes them. The page tells a teacher this instead of showing buttons
   they can't use.
2. **Deleting a draft is out of scope.** No delete endpoint exists. It's filed as its own
   backlog item (see Follow-ups).
3. **Clicking a course opens the builder**, loaded with the course's live draft. There is no
   separate read-only overview page.
4. **A course has one language**, because the catalog lets learners filter by language and
   courses aren't localized. It is never "any". Existing courses are backfilled to English.
5. **A retired course can be reactivated**, through its own admin action rather than a status
   field on the course update (see ADR-038's rationale).
6. **The checkpoint picker filters and sorts the learning path library** by author, level,
   skills and concepts, sorted by title or by last update. A path's level is **authored on the
   path**, so the path builder gains a level field too.
7. **Courses, paths and content nodes say which instruments they're for**, or that they suit
   every instrument (music theory, for example).
8. **Courses, paths and content nodes can have a thumbnail.**
9. **All of it ships under PB-65**: spec, then core, then web.

## Pages and routes

| Route | Name | Who | What |
|---|---|---|---|
| `/teacher/courses` | `teacher-courses` | teacher, admin | Existing list. Changes below. |
| `/teacher/courses/new` | `teacher-course-new` | teacher, admin | Empty builder. |
| `/teacher/courses/:id/edit` | `teacher-course-edit` | teacher, admin | Builder loaded with the course's live draft. |

These mirror `/teacher/paths`, `/teacher/paths/new` and `/teacher/paths/:id/edit`.

### Changes to the course list

- Each course row becomes a link to `teacher-course-edit` for that course: the whole row is
  clickable, shows a pointer and a hover state, and is reachable by keyboard.
- A **New course** button next to the page title opens `teacher-course-new`.
- Everything else stays as PB-32 built it (status tabs, filters, unpublished-changes badge,
  admin-only teacher name).

## The builder

Same shape as the learning-path builder: the app bar carries **Save**, the page body holds
the form, and a side panel (below the form on phones) holds status and actions.

### Fields

| Field | Control | Rule |
|---|---|---|
| Title | Large text input, like the diagram and path name inputs | Required, not blank. |
| Summary | Multi-line text | Required, not blank. Shown to learners in the catalog. |
| Level | Segmented choice of the five levels (`beginner` … `expert`) | Required. Uses the same level labels as elsewhere (`levels.*`). |
| Language | Single choice of the languages MotifPath offers, shown by name | Required, exactly one. A new course starts in the author's UI language. |
| Instruments | Multi-select of the instruments, with an **Every instrument** option | Every instrument (an empty list) or one or more instruments. A new course starts at Every instrument. |
| Thumbnail | Image upload with a preview, plus **Remove** | Optional. Uploaded through the `thumbnail` upload purpose; images only. |
| Checkpoints | Ordered list (below) | At least one. |

**Save** is disabled until every rule holds. It stays disabled while a save is running, and
shows the usual "Saved" confirmation afterwards.

### Checkpoints

Each checkpoint row shows:
- its position (1, 2, 3 …);
- the learning path's own title;
- an optional **title override** input, whose placeholder is the learning path's title (for
  example "Stage 1: Open chords");
- a drag handle to reorder, plus **Move up** and **Move down** buttons for keyboard and touch
  users;
- a **Remove** button.

**Add checkpoint** opens a picker dialog listing the learning path library
(`listLearningPaths`), paginated with **Load more** like the other library lists. Each
result shows the path's thumbnail, title, author, level, instruments and when it was last
updated. The picker
narrows the library with:
- a title search;
- an instrument filter (a path for every instrument always matches);
- an author filter (the same searchable teacher picker the course list uses);
- a level filter (any of the five levels);
- skill and concept filters (the same tree pickers the course filters use);
- a sort toggle: **Title** (the default) or **Recently updated**.

Paths with no level recorded (created before levels existed) still appear, marked "No
level", but never match a level filter.

Picking a path adds it as the last checkpoint. The same learning path may appear in more
than one checkpoint; the API allows it and the builder doesn't prevent it.

A checkpoint whose override is blank or whitespace sends no `title`, so the path's own title
is used.

### Saving

- **New course:** the first save calls `createCourse`, then replaces the URL with
  `teacher-course-edit` for the new id, so later saves update the same course and a reload
  reopens it.
- **Existing course:** every save calls `replaceCourse` with the full form (title, summary,
  level, every checkpoint in order).
- A failed save keeps the form as it is and shows the error in a toast.
- Leaving the page with unsaved changes asks for confirmation. No other builder does this
  yet; it's proposed here because a course is a long form (see "For the PO to confirm").

### Status and actions panel

Always shown for a saved course:
- **Status:** Draft, Published (with the version number, "v3") or Retired.
- **Unpublished changes** badge when the live draft differs from the latest published version
  (`has_unpublished_changes`).
- **See what learners see** opens the published outline (`getPublishedCourse`) in a dialog:
  each checkpoint's title and its items grouped by section. Shown only once the course has
  been published.

For an **admin**:
- **Publish** saves the form first, then calls `publishCourse`, then shows the new version
  number. It is disabled when the course is already published and has no unpublished
  changes, so identical versions don't pile up. A confirmation dialog says learners who
  enroll from now on get this version, and people already enrolled keep theirs.
- **Retire** (published courses only) asks for confirmation, explaining the course leaves the
  catalog for new enrollments and existing enrollments are unaffected. It calls
  `retireCourse`.
- **Reactivate** (retired courses only) asks for confirmation, explaining the course returns
  to the catalog with its latest published version. It calls `reactivateCourse`.

For a **teacher**: no Publish, Retire or Reactivate buttons. A short note says an admin publishes
courses, so the teacher knows the course isn't visible to learners yet.

### Retired courses

A retired course opens read-only: the fields and checkpoints are shown but can't be changed,
Save is hidden, and a notice explains the course is retired. An admin sees **Reactivate** in
the actions panel; once reactivated, the course is editable again.

### Who may open what

- A teacher only ever sees their own courses in the list (the API already scopes it), so
  every course they can open is theirs to edit.
- An admin can open and edit any course.
- A student reaching these routes gets the same permission notice as the other authoring
  pages.
- Opening an id that doesn't exist shows a "course not found" state with a link back to the
  list.

### States

Every page that loads data shows loading and error states with a retry, like the other
authoring pages:
- the course itself;
- the learning path picker;
- the published outline dialog.

### Language

Courses aren't localized: title, summary and checkpoint overrides are single strings, written
in the course's language. All labels on these pages are translated in `en` and `pt-BR`.

The course list shows each course's language, and its filters gain a language filter.

## Changes outside the course pages

- **Path builder (`/teacher/paths/new`, `/teacher/paths/:id/edit`):** gains a required
  **Level** field (the same segmented choice as the course builder), plus the same
  **Instruments** and **Thumbnail** fields. A path opened without a level shows the field empty
  and can't be saved until one is chosen.
- **Content authoring (`/teacher/content/...`):** gains the same **Instruments** and
  **Thumbnail** fields. Publishing a content node publishes them too.
- **Library lists (courses, paths, content):** each row shows its thumbnail and instruments,
  and the filters gain an instrument filter.
- **Learner catalog (`/courses`):** each course card shows its thumbnail, language and
  instruments, and the filters gain a language filter (defaulting to the learner's own
  language) and an instrument filter.

## Acceptance criteria

1. Clicking a course in `/teacher/courses` opens its builder with the live draft loaded.
2. **New course** opens an empty builder. The first save creates the course and moves to its
   edit URL. The next save updates it and doesn't create another course.
3. Save is disabled until title, summary, level and at least one checkpoint are set.
4. Checkpoints can be added from the learning path library, reordered by drag or by the
   move buttons, retitled, and removed. Saving sends them in the shown order, and a blank
   override is sent as no title.
5. An admin sees Publish, Retire for a published course, and Reactivate for a retired one.
   Each asks for confirmation. Publish saves first, and is disabled when there's nothing new
   to publish.
6. A teacher sees none of those buttons, and sees that an admin publishes courses.
7. "See what learners see" shows the published outline and appears only for published
   courses.
8. A retired course opens read-only, and an admin can reactivate it.
9. Unsaved changes prompt before leaving the page.
10. Loading, error and not-found states render with no broken UI, in both languages.
11. A course can't be saved without a language, and both course lists can be filtered by
    language.
12. The checkpoint picker filters by author, level, skills and concepts, and sorts by title or
    by last update.
13. The path builder requires a level.
14. Courses, paths and content nodes can be tagged with instruments or marked for every
    instrument, and every list can be filtered by instrument without losing items for every
    instrument.
15. Courses, paths and content nodes can be given, shown with, and cleared of a thumbnail.

## Out of scope and follow-ups

- **Deleting a never-published draft:** needs a new endpoint and scenarios. To be filed as
  its own backlog item.
- **A teacher requesting publication:** rejected for now; publishing stays an admin action.
- **Toggling a version's `available_for_new_enrollments`:** no UI in this item.
- **Localized course text:** not planned. It would need an API change like ADR-033's for
  diagrams.

## For the PO to confirm

Still open. The defaults above are proposals:
1. Retired courses open **read-only** (see "Retired courses").
2. **Publish is disabled** when a published course has no unpublished changes.
3. **Leaving with unsaved changes asks for confirmation.** None of the other builders do
   this today. If it's kept here, it could later be added to them too.
4. **The learner catalog's language filter defaults to the learner's own language.** They
   can clear it to see every course.
5. **"Every instrument" is the default** for new courses, paths and content nodes, and for
   everything that exists today.
6. **Items with no thumbnail show a neutral placeholder** in cards and lists, rather than
   leaving a gap.
