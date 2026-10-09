# Pattern: Discover (course and path catalog, filters, path detail)

**Source:** ADR-049 §1 and §5 · ADR-029 (course catalog) · MOT-58 (Figma "Discover", rows 1–5;
decisions D1–D11, D5 revised twice)

## When

Use it for the Discover destination of the App Shell: finding a course or a path to start, filtering
the catalog, and the path detail before or after starting. The course detail is the learner view in
`learning.md` (Learning 2d); Discover only adds the way in.

## Why

A student should find something to start in a few taps, on a phone, without knowing how the content
is organised. One destination for both catalogs means one search and one set of filters to learn.
Students look for a goal ("blues", "fingerstyle"), not for a place in the skill tree, so the filters
stay short.

## How

### Discover (the destination)

- **One destination, two segments:** a `SegmentedControl` with Courses | Paths; Courses is shown
  first (D1). The segment, the search and the filters live in the URL, so Back from a detail returns
  to the same list.
- **Top:** title, the segmented control, then a `SearchField` and a `FilterButton` side by side.
  Search and filters are shared by both segments; switching keeps them (D4).
- **Applied filters** show under the search as removable `FilterChip`s with "Clear all"; the filter
  button shows how many are on.
- **Count line:** "14 courses · A–Z". Results come A–Z by title, the only order the API has; there
  is no sort control (D7).
- **Rows (`CatalogCard`, Layout=Row):** a 16:9 thumbnail (112 × 63; the course or path icon on a
  tinted tile without one), an eyebrow "level · language", the title (two lines), "by <teacher>",
  and "instrument · size" ("Guitar · 4 parts · 44 lessons", "Guitar · 9 lessons") (D2).
  - **Tap opens the detail** (D3). There is no Start button and no "More from this teacher" on the
    row.
  - A badge on the thumbnail says **In Learning** or **Finished** when the student already has it.
    The catalog does not know this; the badge comes from the student's enrolments and paths.
- **Paging:** 20 at a time, more as the student scrolls.
- **Search** runs as the student types (after 300 ms) and matches the title and summary.
- **No matches (D8):** `StateBlock` "No courses match" that names the search and the filters, with
  "Clear filters". If the other segment has matches, "2 paths match · Show paths" underneath (one
  extra count call).
- **States:** skeleton rows while loading (after 300 ms); a load error is an `InlineNotice` with
  "Try again" in place, and the shell stays (`states.md`).

### Filters (D5, D6)

- **What a student can filter by:** Level (Beginner, Intermediate, Advanced; several allowed),
  Instrument (one), Language (one), Teacher (one). That is all.
  - Level, Instrument and Language are `ChoiceChip` groups. Teacher is a `MenuRow` that opens a
    searchable single-choice list ("Any teacher" first).
  - **No skill or concept picker for students.** There are 216 skills in 16 areas and 124 concepts
    in 11 areas; a picker for them was too busy on a phone (two versions were rejected), and most
    skills match no course in a small catalog.
- **A skill or concept filter arrives only from context:** "Find courses for this skill" on Your
  skills / Your progress (MOT-77) opens Discover with that skill as one removable chip ("2 courses
  teach this skill"). The API already takes `skill_ids` and `concept_ids`.
- **Compact:** a bottom sheet (`overlays.md`): the chip groups, the Teacher row, then "Clear all"
  (Tertiary) and "Show 2 courses" (Primary), whose count updates as filters change. The Teacher list
  replaces the sheet's content and gets a back arrow — never a sheet on a sheet.
- **Medium:** the same content in a 480 px dialog; actions bottom-right, primary last.
- **Expanded:** a 260 px filter panel to the left of the results that applies at once (no Show
  button), with "Clear all" in its header. The Teacher list is a menu anchored to the Teacher row.

### Path detail (D10)

- The course detail's anatomy: 16:9 thumbnail, chips (level, language, instrument), title,
  "by <teacher>", summary, one primary action, then the outline. The back arrow says "Discover".
  The Compact bottom bar stays.
- **Outline:** "Path outline · 12 lessons", then the lesson titles, numbered, under their section
  labels (`SectionHeader`, open). Titles only; lessons do not open from here.
- **Not started:** "Start path". **Already in Learning:** an "In Learning" chip, its progress
  ("5 of 9 lessons") and "Continue path", which makes it current first if it is not.
- **Teacher link (D9):** on a course or path detail, the byline is a link. It opens Discover filtered
  by that teacher (one removable chip), on the same segment.

### Start (D11)

- "Start course" / "Start path" enrols, makes it the current item and opens My path on lesson 1,
  with a toast "Now on Blues shuffle" and **Undo**. Undo switches back to the item that was current;
  the new one stays in Learning (`overlays.md`: reversible, so no confirm).
- Enrolling in a path always makes it current. Enrolling in a course only does that when nothing is
  current, so the web also sets the current path (`PUT /students/me/current-path`) after enrolling
  in a course.

### Size classes

| Size class | Discover | Filters | Path detail |
|---|---|---|---|
| Compact | Bottom bar; one column of rows. | Bottom sheet; Teacher list replaces its content. | One column. |
| Medium | Rail; one 560 px column of rows (two columns would squeeze the titles). | 480 px dialog. | The Compact order in the 560 px column. |
| Expanded | Sidebar; segmented control and search on top; filter panel (260 px) beside a 3-column grid of `CatalogCard` Layout=Tile (Discover is a shelf to browse; Learning stays a list). | Side panel, applies at once; Teacher as an anchored menu. | A 600 px outline pane and a 320 px side card that stays in view: thumbnail, size, "Start path". |

## Do not

- Put a button on a catalog row; the row opens the detail.
- Give students a skill or concept picker in Discover; the skill filter comes from context.
- Add a sort control while the API orders by title only.
- Start a course or path straight from the catalog without its detail.
- Confirm a start: it is reversible with Undo.

## Spec changes this needs

- None for D1–D11: the catalog endpoints, enrolment, `current-path` and the student's enrolments
  and paths exist.
- **MOT-86:** let catalog search also match skill and concept names (today it matches the title and
  summary only).
- **D7 option B** ("Newest first") was not chosen; it would need a sort parameter on both catalog
  endpoints.
