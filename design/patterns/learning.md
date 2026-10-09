# Pattern: Learning (my courses, course detail, course completed)

**Source:** ADR-049 §1 and §5 · ADR-017 (the student's copied path) · MOT-57 (Figma "Learning",
rows 1–5; decisions D1–D10, D2 revised after a benchmark)

## When

Use it for the Learning destination of the App Shell, for the learner view of a course, and for the
screen shown when a course is completed. My path shows the one course part or path the student is on
now (`path.md`); Learning holds everything the student has started and is where they switch.

## Why

A student who started more than one thing needs one place to see it all, pick up where they left off,
and see what they finished. The list has to be quick to scan on a phone, so the student recognises a
course by its picture before reading its title.

## How

### Learning (the destination)

- **What it holds (D1):** every course enrolment and every standalone path, together, in three
  groups: **In progress**, **Finished**, **Left**. Left is folded by default ("Left · 2"), and its
  header has no done check.
- **Order:** the current item first, then by most recently started (`enrolled_at`; there is no
  last-activity time).
- **Rows (`LearningCard`):** a compact row with no button (D2, revised):
  - a 16:9 thumbnail at 96 × 54 (`thumbnail_url`, cover); without one, the course or path icon on a
    tinted tile in the same box;
  - an eyebrow with the kind and where the student is: "Course · Part 2 of 4", "Path · Assigned by
    Ana", "Course · Finished";
  - the title;
  - a thin `ProgressBar` with a short count: a course counts **parts** ("1 of 4 parts", D3), a path
    counts lessons ("5 of 9 lessons");
  - ⋯ at the top right.
  - The current item: "Current" as a badge on the thumbnail and an accent border.
  - Finished: success tone, full bar.
  - Level and author are not on the row; the detail shows them.
- **Tapping a row continues (D2):** it opens My path on that item. If it is not the current one, it
  becomes current first and a toast says "Now on Reading rhythm" with **Undo** (switching is
  reversible, `overlays.md`). A finished or left item has nothing to continue, so a tap opens its
  detail.
- **⋯** opens "Course details" and "Leave course" ("Remove from Learning" for a standalone path):
  a sheet on Compact, a menu anchored to ⋯ on Medium and Expanded.
- **Left rows** show the title and "start again from part 1"; a tap opens the course detail with
  "Start course".
- **Empty:** `StateBlock` "Nothing here yet" — courses and paths you start show up here — with
  "Explore courses and paths" (Discover).
- **Everything finished:** a "Nothing in progress" card with "Find your next course" above the
  Finished group.
- **States:** skeleton rows while loading (after 300 ms); a load error is an `InlineNotice` with
  "Try again" in place, and the shell stays (`states.md`).

### Course detail (learner view)

- A page inside Learning, with a back arrow ("Learning", or "Discover" when it was opened from
  there). The Compact bottom bar **stays** (D6); only lessons hide it.
- **Top:** the 16:9 thumbnail, chips (level, language, instrument), title, "by <author>", summary.
- **Enrolled:** a progress row ("Part 2 of 4") and one primary action, "Continue part 2", which opens
  My path on this course (switching first if needed).
- **Not enrolled, or left before:** "Start course"; a left course adds "You left this course before.
  Starting again begins at part 1." The catalog side belongs to Discover (`discover.md`).
- **Outline (D4):** one `PartRow` per part: Done (check), Current (highlighted, number, "7 of 14
  lessons done" from the active StudentPath), Upcoming (muted). The current part opens unfolded with
  its lesson titles and "Open in My path"; the others unfold to titles only. Lessons open from My
  path, not from the outline (the outline is titles only).
- **Leave (D5):** a quiet "Leave this course" in danger colour at the end of the page (and in ⋯ on
  the row). It always confirms, because leaving cannot be undone (`overlays.md`): "Leave Guitar
  foundations?" — you lose your place; starting again begins at part 1; your practice and skill
  levels stay. Sheet on Compact (destructive on top), alert dialog from Medium (safe left,
  destructive right).
- **Finished (D9):** a "Finished" chip, every part done, and "Practise what you learned" as a
  secondary button; no lesson review for now.

### Course completed

- Shown after the last lesson of the last part; afterwards the course sits under Finished.
- A card with the course thumbnail, a celebration icon, "You finished <course>", and "4 parts · 44
  lessons. What you learned keeps coming back in Practice so it stays with you." No completion date
  (the API has none).
- **Rating (D8):** "How was this course? (optional)" with five stars (`RatingStar`, 48 px row). One
  tap saves, another tap changes it; no text, asked only here. Built with MOT-27, not with the
  redesign.
- **The way on (D7):** if another course or path is in progress, "Continue <it>" is the primary and
  "Find your next course" the quiet action; otherwise "Find your next course" (Discover › Courses) is
  the primary and "Practise what you learned" the quiet one.

### Size classes

| Size class | Learning | Course detail | Completed |
|---|---|---|---|
| Compact | Bottom bar; one column of rows. | One column; ⋯ and leave confirm as sheets. | One column. |
| Medium | Rail; one 560 px column of rows (two columns would squeeze the titles). | 560 px column, same order; leave confirm as an alert dialog; ⋯ as an anchored menu. | 560 px column. |
| Expanded | Sidebar; rows in two 467 px columns — the same component, never large tiles (this is a list to manage, not a shelf to browse). | A 600 px outline pane and a 320 px side card that stays in view: thumbnail, progress, "Continue part 2", "Leave this course". | 560 px column, centred. |

## Do not

- Put a button on a Learning row; the row is the action.
- Show a course's progress in lessons across the whole course: the enrolment only knows the part
  (D3). Adding it is an OpenAPI change first.
- Show the level or author on the rows, or a lesson length anywhere.
- Undo a leave: it is irreversible today, so it confirms.
- Add concept pages to Learning (D10). "Practise this" lives on Your skills, Your progress, the
  practice setup picker and the lesson end (MOT-77).

## Spec changes this needs

- None for D1–D7 and D9: the data exists (`CourseEnrollment`, `CourseDetail`, `StudentPath`).
- **D8 (rating):** MOT-27 — an endpoint to save a 1–5 course rating per enrolment (spec-first).
- **D3 option B** (lessons across the course) was not chosen; it would need a completed-lesson count
  on `CourseEnrollment`.
