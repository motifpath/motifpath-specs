# Pattern: My path

**Source:** ADR-049 §1 and §5 · ADR-017 (the student's copied path) · MOT-56 (Figma "My path &
lessons", rows 1, 5–7; decisions D3, D8–D10, D13, D14) · designs MOT-39 (why a step is locked)

## When

Use it for the My path destination of the App Shell: the student's current path, standalone or one
part of a course, with every step and its state. A lesson opened from it uses the lesson pattern
(`lesson.md`).

## Why

The student comes back to answer one question: what do I do next? The screen should answer it
without scrolling, and show where the student is in the path without a wall of finished steps.

## How

- **One primary action, at the top:** the next step's card (`NextStepCard`): kind badge, "Up next ·
  step N of M", title, kind, and "Start lesson". It is the step at `current_position`.
- **Header:** for a course part, the course and "Part N of M" as an eyebrow; the path title; a
  progress bar with "N of M".
- **Sections** come from `section_label`. A section whose steps are all done folds into one row
  ("Open chords · 5 of 5"), which unfolds on tap. The section with the current step and the ones
  after it stay open, so the current step shows on the first screen with no auto-scroll.
- **Steps (`StepRow`):** a state marker, the title, a meta line and a trailing icon.
  - Done: a check; the meta line says the kind and "Done"; opens the lesson for review.
  - Current: highlighted, with its position number; the meta line says "Up next" and the kind.
  - Locked: muted, with its position number and a lock icon; the meta line says only the kind.
  - Language: the languages icon; the meta line gives the reason in amber ("Only in English for
    now"), never in red.
- **A step shows its kind only** (Video, Article), never a length: lessons carry no duration (D4).
- **Tapping a locked step** explains it in place. On Compact it's a bottom sheet, from Medium up a
  centred dialog: why the step is locked and the way forward ("Go to step 8") (D9, D13).
- **A language-locked step** opens in the language it has ("Watch in English"). Finishing it
  completes the step and unlocks the next one (D3, option A). No skipping.
- **Path complete (standalone):** a celebration above the folded path, with "Find your next path"
  (Discover → Paths) as the primary action and "Practise what you learned" (Practice) as the quiet
  one. A course part that completes moves on to the next part. A completed course uses the Learning
  screen (MOT-57).
- **No path:** says what a path is and offers "Explore courses and paths" (Discover).
- **States:** loading shows skeleton rows. A load error shows an `InlineNotice` with "Try again", and
  the shell stays.
- **Size classes:**

  | Size class | Layout |
  |---|---|
  | Compact | Bottom bar; one column. |
  | Medium | Rail; one 560 px column. |
  | Expanded | Sidebar; the steps in a 600 px list, with a 320 px side column holding the progress card and the next step's card (D14). |

## Do not

- Write "Complete the previous step" on every locked row. The lock icon says it, and a tap explains.
- Show a language lock as an error, or leave the student with no way through it.
- Put a second primary button on the screen.
- Show a lesson length the data doesn't have.

## Spec changes this needs

- **D3:** specified in MOT-39. ADR-024 (amendment 2026-10-08) lets the student open a
  language-locked step in the language it has. `StudentPathItem.lock_reason` (`previous_step` |
  `language`) and `available_languages` give the row and the sheet their wording. Only the step at
  `current_position` can be locked for `language`.
