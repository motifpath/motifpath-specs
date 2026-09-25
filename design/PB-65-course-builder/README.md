# PB-65 — Course builder (authoring UI)

**Status:** Draft, awaiting PO review
**Repos:** `motifpath-web` only. No API change: every call below already exists in
`openapi/core-domain-service.yaml` (`createCourse`, `getCourse`, `replaceCourse`,
`getPublishedCourse`, `publishCourse`, `retireCourse`, `listLearningPaths`).
**Builds on:** the teacher Courses tab (`/teacher/courses`, from PB-32), ADR-029 (course
versions), ADR-037 (authoring list is staff-only).

## Problem

Teachers and admins can list the courses they manage at `/teacher/courses`, but can't open
one. The web app has no way to create a course, edit its draft, or publish or retire it, even
though the API has supported all of that since PB-31/32. Today a course can only be made
through the seeders or direct API calls.

## Decisions (PO, 2026-09-25)

1. **Publishing and retiring stay admin-only**, as the API already enforces. A teacher builds
   and edits drafts; an admin publishes them. The page tells a teacher this instead of
   showing buttons they can't use.
2. **Deleting a draft is out of scope.** No delete endpoint exists. It's filed as its own
   backlog item (see Follow-ups).
3. **Clicking a course opens the builder**, loaded with the course's live draft. There is no
   separate read-only overview page.

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
(`listLearningPaths`): searchable by title, paginated with **Load more** like the other
library lists. Picking a path adds it as the last checkpoint. The same learning path may
appear in more than one checkpoint; the API allows it and the builder doesn't prevent it.

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

For a **teacher**: no Publish or Retire buttons. A short note says an admin publishes
courses, so the teacher knows the course isn't visible to learners yet.

### Retired courses

A retired course opens read-only: the fields and checkpoints are shown but can't be changed,
Save is hidden, and a notice explains the course is retired. (The API doesn't forbid editing
a retired draft, but nothing can bring the course back to the catalog. Editing it would only
be confusing.)

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

Courses aren't localized: title, summary and checkpoint overrides are single strings, as the
API defines them. All labels on these pages are translated in `en` and `pt-BR`.

## Acceptance criteria

1. Clicking a course in `/teacher/courses` opens its builder with the live draft loaded.
2. **New course** opens an empty builder. The first save creates the course and moves to its
   edit URL. The next save updates it and doesn't create another course.
3. Save is disabled until title, summary, level and at least one checkpoint are set.
4. Checkpoints can be added from the learning path library, reordered by drag or by the
   move buttons, retitled, and removed. Saving sends them in the shown order, and a blank
   override is sent as no title.
5. An admin sees Publish and, for a published course, Retire. Each asks for confirmation.
   Publish saves first, and is disabled when there's nothing new to publish.
6. A teacher sees neither button, and sees that an admin publishes courses.
7. "See what learners see" shows the published outline and appears only for published
   courses.
8. A retired course opens read-only.
9. Unsaved changes prompt before leaving the page.
10. Loading, error and not-found states render with no broken UI, in both languages.

## Out of scope and follow-ups

- **Deleting a never-published draft:** needs a new endpoint and scenarios. To be filed as
  its own backlog item.
- **Un-retiring a course:** no endpoint exists. Not planned.
- **A teacher requesting publication:** rejected for now; publishing stays an admin action.
- **Toggling a version's `available_for_new_enrollments`:** no UI in this item.
- **Localized course text:** not planned. It would need an API change like ADR-033's for
  diagrams.

## For the PO to confirm

The API leaves two rules open, and one behavior is new to the authoring pages. The defaults
above are proposals:
1. Retired courses open **read-only** (see "Retired courses").
2. **Publish is disabled** when a published course has no unpublished changes.
3. **Leaving with unsaved changes asks for confirmation.** None of the other builders do
   this today. If it's kept here, it could later be added to them too.
