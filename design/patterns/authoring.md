# Pattern: authoring (Teach)

**Source:** ADR-049 §6 (authoring is desktop-first, with minimal responsiveness) · MOT-61 (Figma
"Authoring", rows 1–13; decisions D1–D29, decided 2026-10-09: all A except D15 = B) · Figma row 17
(lists after MOT-93, approved 2026-10-12) · MOT-93 (the API for lists at volume, ADR-053) · the chord-progression idea in MOT-94

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
  admins an Admin group: Knowledge map · Song charts (`song-chart.md`). "Content" is renamed **Lessons**, the word
  learners see.

### Lists (D4, D24, D25–D28)

- **One pattern:** title + New · status (or scope) chips · `SearchField` + `FilterButton` ·
  applied filters as removable `FilterChip`s + Clear all · a count line · the items.
- **Rows:** `AuthoringRow` (thumbnail or kind icon, title, one meta line, a status chip, chevron) for
  courses, paths, lessons and exercises, in one column at every size (max 880 px on Expanded).
  **Diagrams** are a grid of `DiagramTile` thumbnails — a diagram is recognised by its shape: two per
  row on Compact; wider, as many boards of at least 168 px as the list's width holds (three at
  1024 px, five at 1280) (D24, Figma row 18).
- **Status words (D5):** Draft · Published · v N · Unpublished changes · Retired. Exercises and
  diagrams have no publish state; diagrams show a Template badge.
- **Count:** the API's `PageMeta.total` for the current filters ("46 of 1,284 diagrams").
- **Filters show exactly what the section's API takes (D25):**

  | Section | Filters |
  |---|---|
  | Diagrams | instrument · kind (all, templates, custom) · shows (diagrams, chord voicings, both) · root note · language · skill · concept · author |
  | Exercises | type · instrument · language · skill · concept · author |
  | Lessons | type (video, article) · level · instrument · language · skill · concept · author |
  | Paths, courses | status · level · instrument · language · skill · concept · author |

  On Compact they open as a **full-screen layer** (too many groups for a sheet) whose button shows
  the live total ("Show 46 diagrams"); on Medium and Expanded the same fields open as a **dialog**
  from a Filters button beside the search, with the same live total, and the list always takes the
  full width (Figma row 18). There is no side panel: beside the Teach sidebar it left the list too
  little room. Every size shows the same fields, one tap per choice; never selectors that hide what
  is chosen.
  Status (courses, paths, lessons) is the status chips, not a filter. **Root note** takes one note:
  a selector with Any, as in the diagram picker (row 14).
- **Skill and concept picker (D26, row 17):** teachers keep the tree picker (students don't —
  `discover.md`): search by name or area, scoped to the filtered instrument with "All instruments",
  Recent first. It takes **several**: tapping a skill or an area chooses it (✓), and an area brings
  its sub-skills; "N skills ›" opens an area, with a path back up. The chosen
  ones show as removable chips, and the filter row sums them up ("2 skills"). Items matching any
  of them show.
- **Author:** Me first, then a search over the section's `…/creators?q=` endpoint, each author with
  how many items they have in the section; Anyone clears it.
- **Sort:** Name A–Z or Recently changed, on every list.
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
  option, no skill or concept, a playback tempo outside 20–300), each item jumping to its field.
- **Reordering (D8):** `OrderedRow` — drag by the handle on every size, and ⋮ → Move up · Move down ·
  Rename here · Open · Remove, the way to reorder on a phone, with a keyboard or a screen reader.
  Lists in time order (video pop-ups) don't drag.
- **New exercise (D21):** a type chooser comes first (`TypeRow` × 5, each saying what the student
  does); the type is locked after the first save.
- **Previews (D12):** "See what learners see" / "Preview as student" opens the real learner component
  in a full-screen layer with a Preview bar (accent fill, ×). It grades but records nothing; nothing
  can be started for real.

### Lesson video (MOT-19, ADR-054)

- The Video field of a video lesson is a `VideoSource` card above the link field, which reads
  "Or paste a link". Either one sets the lesson's video (Figma "Authoring", row 15).
- **Upload:** tapping the card picks a file. Only an MP4 (H.264) of up to 1 GB is accepted; anything
  else is refused on the card before a byte is sent (Refused), with the iPhone hint (Camera ›
  Formats › Most Compatible).
- **Uploading:** name, "490 of 980 MB · 50%", a `ProgressBar` and × to cancel; the link field hides.
  Save waits for the upload, and leaving asks first.
- **Uploaded:** the card stands for the video; ⋮ = Play · Replace · Use a link instead · Remove.
- **Failed:** the card turns danger with "Upload stopped. Check your connection and try again." and
  ↻, which restarts the upload from the beginning; the link field is back.
- The lesson's thumbnail is also the poster before the video plays; nothing is taken from the video.

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
  colour, alignment, lists), **Insert** (link, table, image, diagram; song chart in article lessons only, never in an exercise
  prompt — `song-chart.md`) and **Table** (today's
  table icons as `IconButton`s: add/delete column and row, header row/column/cell, merge, split, cell
  border, cell colour, delete table; long-press shows the name). The context chip is Table inside a
  table and Edit on an embedded diagram or song chart.
- **Link** opens a short sheet (a dialog from Medium up) with the address, Apply, and Remove link
  when the selection already has one — never a browser prompt (Figma row 7g). **Table** inserts
  3 × 3 cells with a header row at every size (7c).
- **Merging cells (D15 = B):** drag across cells to select several, then Merge — the same model as
  desktop; Split works on a merged cell.
- **Medium, Expanded:** today's one-row toolbar, with the table row while the cursor is in a table.

### Diagrams in authoring (D16, D17, D23)

- **One picker** wherever a diagram goes (prompt embed, stimulus, image-choice option, sound):
  step 1 choose — Diagrams | Chords, search, filters, thumbnails; step 2 set how it shows — labels
  (intervals, notes, custom, none), positions shown, playback (offered, which, tempo, sound,
  direction, loop), and for a stimulus a tool: a tap *marks it correct* or *hides or shows it*, on the fretboard or on
  a chord's box alike (row 16).
  The same two steps at every size (MOT-95, row 14): a full-screen layer on Compact, a 1040 px
  dialog on Expanded; tapping a result opens its settings, "Change diagram" or "Change chord" goes
  back with the pick marked, and Cancel / Insert sit at the foot of the settings.
- **Finding a chord:** a Root selector and "Or type a chord" on one row, the Quality toggles below
  (one at a time; Major · m · 7 · m7 · maj7 · sus2 · sus4 · dim · aug). A typed symbol is read in any
  case. Each voicing is named by its chord and where it sits ("Am · 5fr"). In the settings a chord
  shows as its chord box (Box | Neck), never the bare fretboard.
- **Finding a diagram:** the search by name, then Root, Author and Type (All · Templates · Custom),
  shown inline — no filters sheet — with a live count and Clear filters once one is set.
- **The search and filters stay put;** only the results scroll.
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
| Expanded | Teach sidebar. | Rows at most 880 px; diagrams fill the width (168 px+ each); filters as a dialog. | Two columns: the form, and a 320 px sticky column (status, preview, thumbnail, where used); pickers as two-pane dialogs. |

## Do not

- Show the learner navigation in Teach, or add Teach as a learner destination.
- Hide content on a small screen: show it read-only and say what waits for a larger one.
- Disable Save or Publish without saying why.
- Offer a filter the section's API doesn't take.
- Draw a board, a chord box or a marker by hand instead of using the shared components.
- Name the answer in an audio-selection label, or show the board of a hidden-board sound before the
  student answers.

## Spec changes this needs

- **Figma row 18 (2026-10-12):** no side panel; the Filters dialog from Medium up, replacing the
  Expanded part of 13g and 17e.
- **MOT-93 (done 2026-10-12, ADR-053):** `sort=title|updated` on every authoring list; several
  `skill_ids` / `concept_ids`, matching an area's sub-skills; author, language and status filters
  on `/content-nodes`; `item_count` on `…/creators`. The screens: `features/web/authoring-lists.feature`.
- **MOT-74 (specified 2026-10-12, ADR-019 / ADR-041 amendments):** a sound is an `audio_url` or a
  `diagram_ref` naming a playback, never looping; a playback in use can't be removed. The rules:
  `features/content-management/exercise-sounds.feature`; the screens:
  `features/web/listening-from-a-diagram.feature`.
- **MOT-75:** sounds from a catalog voicing (a voicing is a diagram, so the MOT-74 source); chord-box
  options and stimuli.
- **MOT-19 / ADR-054:** `lesson_video` uploads (MP4, at most 1 GB, declared `file_size`) on
  `POST /media/upload-url`.
- **D3:** "Content" → "Lessons" is a UI label change only (routes and API keep `content-nodes`).
- **MOT-94 (discovery):** chord progressions by bars — not designed here.
