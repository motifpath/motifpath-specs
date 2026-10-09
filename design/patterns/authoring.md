# Pattern: authoring (Teach)

**Source:** ADR-049 §6 (authoring is desktop-first, with minimal responsiveness) · MOT-61 (Figma
"Authoring", rows 1–13; decisions D1–D29, decided 2026-10-09: all A except D15 = B) · API gaps in
MOT-93 · the chord-progression idea in MOT-94

## When

Use it for every screen a teacher or an admin uses to build content: the Teach home, the section
lists (courses, paths, lessons, exercises, diagrams; knowledge map and song charts for admins), every
editor, the rich-text editor, the diagram picker, sound sources and the student previews.

## Why

Teachers do their heavy work at a computer, but they fix a typo, publish a lesson or reorder a course
from their phone between classes. ADR-049 §6 sets three tiers: maintenance is fully usable on
Compact, heavy editing may wait for a larger screen, and no screen is ever broken. With thousands of
diagrams and hundreds of exercises, finding the right item matters as much as editing it.

## How

### Teach is a separate mode (D1, D2)

- **In:** "Teach" in the account sheet or menu (teachers and admins; `navigation.md`), or the Teach
  item in the Expanded sidebar. **Out:** "Back to learning" in the same place, which lands on Home.
- Teach has **no learner navigation**. On Compact and Medium, **Teach home** is a hub: a title, one
  line on what Teach is for, and one `MenuRow` per section; each section is a pushed page with
  ← Teach. On Expanded a **Teach sidebar** lists the sections, then Back to learning and Account.
- **Sections, in composition order (D3):** Courses · Paths · Lessons · Exercises · Diagrams; for
  admins an Admin group: Knowledge map · Song charts. "Content" is renamed **Lessons**, the word
  learners see.

### Lists (D4, D24, D25–D28)

- **One pattern:** title + New · status (or scope) chips · `SearchField` + `FilterButton` ·
  applied filters as removable `FilterChip`s + Clear all · a count line · the items.
- **Rows:** `AuthoringRow` (thumbnail or kind icon, title, one meta line, a status chip, chevron) for
  courses, paths, lessons and exercises, in one column at every size (max 880 px on Expanded).
  **Diagrams** are a grid of `DiagramTile` thumbnails — a diagram is recognised by its shape: two per
  row on Compact, four on Expanded (D24).
- **Status words (D5):** Draft · Published · v N · Unpublished changes · Retired. Exercises and
  diagrams have no publish state; diagrams show a Template badge.
- **Count:** the API's `PageMeta.total` for the current filters ("46 of 1,284 diagrams").
- **Filters show exactly what the section's API takes (D25):**

  | Section | Filters |
  |---|---|
  | Diagrams | instrument · kind (all, templates, custom) · shows (diagrams, chord voicings, both) · root note · language · skill · concept · author |
  | Exercises | type · instrument · language · skill · concept · author |
  | Lessons | type (video, article) · level · instrument · skill · concept |
  | Paths, courses | status · level · instrument · language · skill · concept · author |

  On Compact they open as a **full-screen layer** (too many groups for a sheet) whose button shows
  the live total ("Show 46 diagrams"). On Expanded they are a **280 px side panel** that applies at
  once (the Discover pattern).
- **Skill and concept picker (D26):** teachers keep the tree picker (students don't — `discover.md`):
  search by name or area, scoped to the filtered instrument with "All instruments", Recent first,
  areas drill in with a path on Compact and expand inline on Expanded.
- **Author:** Me first, then a search over the section's `…/creators?q=` endpoint; Anyone clears it.
- **Sort:** Name A–Z, and Recently changed where the API supports it (paths today; MOT-93 adds the
  rest).
- **Remembered (D27):** search, filters and sort live in the URL and are remembered per section on
  this device; coming back from an editor restores them and the scroll position.
- **Long lists (D28):** 20 at a time; the next page loads when the end comes into view; a failed page
  shows Try again in place. Empty, no-match and load-failed states follow `states.md`.

### Editors (D6–D9, D20, D21)

- **App bar (Compact, Medium):** `EditorAppBar` — back to the list, section + item title, and Save,
  always visible ("Saved ✓" when nothing is pending). Saving stays explicit; no autosave (D7). Back
  with unsaved changes asks first ("Leave without saving?" · Keep editing · Leave).
- **Status first (D6):** a `StatusPanel` opens the editor (Compact: at the top; Expanded: the top of a
  320 px sticky right column). It says what learners get now and holds the one publishing action,
  which saves first and confirms. Missing requirements are listed ("Before you publish, add: …"),
  never a silently disabled button. A teacher sees "An admin publishes courses" instead of a button
  for courses and paths; teachers publish lessons themselves.
- **Save blockers (D20):** Save stays tappable; with something missing it lists what (no correct
  option, no skill or concept, a playback tempo outside 40–300), each item jumping to its field.
- **Reordering (D8):** `OrderedRow` — drag by the handle on every size, and ⋮ → Move up · Move down ·
  Rename here · Open · Remove, the way to reorder on a phone, with a keyboard or a screen reader.
  Lists in time order (video pop-ups) don't drag.
- **New exercise (D21):** a type chooser comes first (`TypeRow` × 5, each saying what the student
  does); the type is locked after the first save.
- **Previews (D12):** "See what learners see" / "Preview as student" opens the real learner component
  in a full-screen layer with a Preview bar (accent fill, ×). It grades but records nothing; nothing
  can be started for real.

### Exercise types

| Type | Stimulus | Options |
|---|---|---|
| Image recognition | An image with regions, or a diagram (mark-correct tool) | The correct regions / positions |
| Image choice | — | Images, diagrams or chord boxes (D22), two per row; check = correct |
| Text response | — | Text options, Mark correct (one or more) |
| Audio recognition | A `SoundSource` | Text options |
| Audio selection | — | Each option = label + `SoundSource` + Mark correct |

- **Sound sources (D18; MOT-74, MOT-75):** every sound picks Upload audio · From a diagram · From the
  chord catalog. "From a diagram" lists only diagrams with a playback; settings are playback, tempo,
  sound and direction (no loop: the student replays), with ▶ Hear it and the length, which becomes
  `audio_ms`. Students hear it with the board hidden, then "What you heard" reveals it
  (`diagrams.md`).
- **Neutral labels (D19):** audio-selection labels default to "Sound 1, 2, 3…", stay editable, and
  never name the answer.

### Rich text (D14, D15)

- The prompt and the article use the real **TipTap** editor on every size, with every command of
  today's toolbar.
- **Compact:** a `PromptToolbar` docked above the keyboard (Undo · Redo | Aa · Bold · Italic · List |
  context chip | + · hide keyboard) and three sheets: **Format** (style, marks, text and background
  colour, alignment, lists), **Insert** (link, table, image, diagram, song chart) and **Table** (today's
  table icons as `IconButton`s: add/delete column and row, header row/column/cell, merge, split, cell
  border, cell colour, delete table; long-press shows the name). The context chip is Table inside a
  table and Edit on an embedded diagram or song chart.
- **Merging cells (D15 = B):** drag across cells to select several, then Merge — the same model as
  desktop; Split works on a merged cell.
- **Medium, Expanded:** today's one-row toolbar, with the table row while the cursor is in a table.

### Diagrams in authoring (D16, D17, D23)

- **One picker** wherever a diagram goes (prompt embed, stimulus, image-choice option, sound):
  step 1 choose — Diagrams | Chords, search, filters, thumbnails; step 2 set how it shows — labels
  (intervals, notes, custom, none), positions shown, playback (offered, which, tempo, sound,
  direction, loop), and for a stimulus a tool: a tap *marks it correct* or *hides or shows it*.
  A full-screen layer on Compact, a 1040 px two-pane dialog on Expanded (choose left, set right).
- **Taps work on a phone (D17):** marking correct and hiding/showing positions are taps, on the board
  at touch size (48 px places). Only placing and moving positions in the Diagrams library waits for a
  larger screen.
- **The same components and rules as practice (D23; `diagrams.md`):** wide boards scroll with
  `BoardViewport` + `OverviewStrip`; thumbnails are fitted (nothing is tapped there); landscape shows a
  full neck for marking answers; 4, 6 and 7 strings; stacks with `DiagramLegend`; `DiagramPlayer` to
  hear a playback; keyboard diagrams are listed but marked "not in lessons yet".
- **Chord boxes** use `ChordBox` + `ChordDot` + `ChordBarre`; voicings away from the nut have no nut
  and a "5fr" label.

### What is heavy (D9, D10 as revised by D14 and D17)

- **Heavy — read-only on Compact** with an `InlineNotice` (Unavailable, monitor icon) right under the
  block, naming what waits and that the rest can be changed (D11): drawing or moving image regions;
  placing or moving positions in the Diagrams library; placing chords over song-chart lyrics.
- **Not heavy — fully usable on Compact:** text and metadata, rich text including tables and embedded
  diagrams, marking correct options, regions and positions, sound sources, pop-up times (typed),
  the knowledge map (drill-in lists), skills and concepts, publishing, reordering.
- The limit is by **size class only**: Medium and Expanded, tablets included, get the full editors.

### Size classes

| Size class | Shell | Lists | Editors |
|---|---|---|---|
| Compact | Teach home hub; pushed pages with ← Teach. | One column; diagrams 2 per row; filters as a full-screen layer. | `EditorAppBar`; one column, status first; heavy parts read-only; pickers as full-screen layers. |
| Medium | Same as Compact, in a centred 560 px column. | Same; filters as a dialog. | Same, with heavy editing unlocked; stimulus images and boards break out to 720 px. |
| Expanded | Teach sidebar. | One 880 px column; diagrams 4 per row; filters as a 280 px side panel. | Two columns: the form, and a 320 px sticky column (status, preview, thumbnail, where used); pickers as two-pane dialogs. |

## Do not

- Show the learner navigation in Teach, or add Teach as a learner destination.
- Hide content on a small screen: show it read-only and say what waits for a larger one.
- Disable Save or Publish without saying why.
- Offer a filter the section's API doesn't take.
- Draw a board, a chord box or a marker by hand instead of using the shared components.
- Name the answer in an audio-selection label, or show the board of a hidden-board sound before the
  student answers.

## Spec changes this needs

- **MOT-93 (High):** `sort=title|updated` on every authoring list; several `skill_ids` /
  `concept_ids` on diagrams, exercises and lessons, matching an area's sub-skills; author, language
  and status filters on `/content-nodes`; optional counts on `…/creators`.
- **MOT-74 / MOT-75:** sounds from a diagram playback or a catalog voicing (ADR-019 / ADR-041
  amendments); chord-box options and stimuli.
- **D3:** "Content" → "Lessons" is a UI label change only (routes and API keep `content-nodes`).
- **MOT-94 (discovery):** chord progressions by bars — not designed here.
