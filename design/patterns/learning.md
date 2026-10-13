# Pattern: Learning (my courses, course detail, course completed)

**Source:** ADR-049 §1 and §5 · ADR-017 (the student's copied path) · MOT-57 (Figma "Learning",
rows 1–5; decisions D1–D10, D2 revised after a benchmark) · MOT-36 (row 6, decisions U1–U8;
ADR-055) · MOT-106 (row 7, decisions R1–R6, approved 2026-10-13, R4 revised)

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
  - a 16:9 thumbnail at 96 × 54 (`thumbnail_url`, whole picture, letterboxed — never cropped); without one, the course or path icon on a
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

### Updating to the latest version (MOT-36)

A course or path the student started keeps the content it had when they started it. When the author
publishes changes, the student can choose to take them (ADR-055).

- **When it is offered (U3):** only for an item **In progress** that is behind its published course or
  path (`update_available`). Finished and Left items are never offered it. Starting a left item again
  already gets the latest version.
- **The row (U1):** `LearningCard` with **New version** on: a refresh icon before the eyebrow, with
  the accessible name "New version available". The eyebrow, the progress and the tap behaviour
  stay the same.
- **Where it starts (U2):**
  - "Update to the latest version" is the **first** item in the row's ⋯ menu.
  - On the course detail, a quiet card under Continue says "A newer version is available", with a
    secondary "Update course" button. A held path's detail has the same card, with "Update path".
  - Both open the same confirm.
- **The confirm (U4, U6):**
  - It is a sheet on Compact and a centred dialog from Medium, with Not now on the left and Update
    on the right.
  - The title is "Update Guitar foundations?". The text is always the same: you get the latest parts,
    lessons and picture; lessons you finished stay finished; if the lesson you are on was removed,
    you continue at the next one you haven't finished; this can't be undone.
  - It has no list of changes, because counts would mislead.
  - The primary ("Update course" or "Update path") is not destructive, because nothing done is lost.
  - There is no Undo.
- **States:**
  - While updating, the primary is busy and Not now is disabled.
  - On success, the sheet closes and a success toast says "Guitar foundations is up to date", with no
    action. The row loses the icon and shows the new picture and title.
  - On failure, the sheet stays open with an error `InlineNotice` (nothing changed) and the primary
    becomes "Try again".
- **Your place (U5):**
  - Finished lessons stay finished.
  - In a course, the student stays on their part if it still exists; otherwise they continue at the
    first part they haven't finished.
  - In a path, they continue at the first unfinished lesson, as My path always does.
  - Updating never changes which item is current.

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
- **Leaving the current item (MOT-83):** the current course or path cannot be left while another
  is in progress, so the app first makes the next item in progress (top of the order) current, then
  leaves. The confirm names it: "You'll continue with Reading rhythm." Leaving the only item in
  progress leaves nothing current.
- **Finished (D9):** a "Finished" chip, every part done, and "Practise what you learned" as a
  secondary button.
- **Reviewing a finished course (MOT-106, R1):** every part folds; tapping one unfolds all its
  lessons as `StepRow` (Done) rows, indented under the part, and each opens the lesson for review.
  No "… N more" and no "Open in My path". The parts and lessons are the version the student took
  (`listMyCourseEnrollmentParts`). A course still in progress keeps its outline as titles only.
- **A finished standalone path (R2):** a learner path detail shaped like the finished course:
  chips, progress ("9 of 9 lessons"), "Practise what you learned", then "Lessons" under their
  `SectionHeader`s, each a `StepRow` (Done) that opens for review (`getMyStudentPath`).
- **States (R6):** lessons that fail to load show an `InlineNotice` with "Try again" in the
  outline's place; "Practise what you learned" stays.

### Reviewing a lesson (MOT-106)

The lesson screen (`lesson.md`), opened from a finished course or path. Nothing is locked, and
nothing changes the current course or path, an enrolment or a status.

- **Telling it apart (R3):** no banner. The back arrow names the course or path, the meta reads
  "Part 1 · Lesson 2 of 5 · Video · Done" (a path: "Lesson 4 of 9 · Video · Done"), and there is
  no completion action, as when reviewing a done step on My path.
- **The way on (R4, revised):** when a lesson ends, a `NextStepCard` for the next lesson of the
  course ("Up next · Part 1 · Lesson 3 of 5", into the next part after a part's last lesson), with a
  quiet "Back to <course>". No "Step done", since nothing completes. After the last lesson of the
  course or path: "That was the last lesson of <course>." and one primary, "Go to Learning", where
  the next course or path is. No celebration, and no automatic redirect, so the end can be watched
  again.
- **Challenges (R5):** "Practise again" redoes the challenge; finishing it returns to the lesson. Its
  answers count as practice evidence; a score under the threshold changes nothing.
- **Tracking:** lesson and exercise events carry the review marker (`content_context.review`,
  `trigger_context.review`).
- **Not reachable (R6):** a lesson of a course the student has not finished, opened from a link,
  says it opens later and offers "Go to My path".
- **Sizes (R6):** no new layout. Medium and Expanded reuse the course detail and the lesson; the
  aside lists the part's lessons.

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
- Count or list what changed in an update, or offer the update on a finished or left item.
- Add concept pages to Learning (D10). "Practise this" lives on Your skills, Your progress, the
  practice setup picker and the lesson end (MOT-77).

## Spec changes this needs

- **MOT-36 (update a copy):** `update_available` on the learner's course enrollments and standalone
  paths, and an update action for each (ADR-055). Spec-first.

- None for D1–D7 and D9: the data exists (`CourseEnrollment`, `CourseDetail`, `StudentPath`).
- **D8 (rating):** MOT-27 — an endpoint to save a 1–5 course rating per enrolment (spec-first).
- **D3 option B** (lessons across the course) was not chosen; it would need a completed-lesson count
  on `CourseEnrollment`.
