# Pattern: selection (options in a practice item)

**Source:** ADR-049 §2 (Choice, MultipleChoice, Region) and §5 (Selection) · MOT-55 (Figma
"Practice Shell — flows", rows 2, 6, 7, 10; decisions D9, D10, D16, D21; phone prototypes P2, P4)

## When

Use it whenever a practice item asks the student to pick: one answer or several, as text, a note
name, a picture, a diagram, a sound, an image region or a diagram cell.

## Why

Every exercise type should look like the same thing to do: only the stimulus changes. The student
learns one way to answer and can answer with a pedal or a keyboard as well as a thumb.

## How

- **One option language, `OptionTile`.** States: Default · Selected · Right · Wrong · Locked. Right
  and Wrong carry an icon, never colour alone. Each option shows its key (1–9) for the keyboard and
  the pedal.
- **Layout by option kind:**

  | Option kind | Component | Compact layout |
  |---|---|---|
  | Text (exercise options, chord names) | `OptionTile` | one column |
  | Note names (name the note) | `OptionTile` | **four** choices in a 2 × 2 grid: the right note and three near distractors (D9) |
  | Picture or diagram (image_choice, chord boxes) | `ImageOption` | two-column grid |
  | Sound (audio_selection) | `AudioOption` | one column |
  | Image region / diagram cell | the stimulus itself | numbered, outlined regions or markers, each at least 48 px |

  On Medium and Expanded the same layouts sit in the 560 px column; image regions, diagram cells and
  song charts get their own pane on Expanded (`session.md`, D26).
- **Several right options (MultipleChoice) say how many** (P2): the prompt ends with "Choose N"
  and the item still commits with **Check**. Committing at the Nth pick was rejected: one mis-tap
  would commit an answer the student can't take back.
- **Up to about five options** show as tiles. More (the focus picker, a long list) become a searchable
  list (ADR-049 §5).
- **Sound options (AudioOption):** the play button only plays; tapping the rest of the row selects.
  The item commits with **Check**, even with one right option, because listening is not answering
  (D10, P4).
- **Diagram options on audio exercises:** a sound stimulus may have chord-box or diagram options
  ("hear a chord, pick its box", D16) — same `ImageOption` grid. Needs the content-model change in
  MOT-75.
- **Locked until the stimulus is there:** when an item's sound or image didn't load, its options are
  Locked and the item can only be retried or skipped (D21, `unavailable-and-errors.md`).
- **Commit and feedback** follow `feedback.md`: the tap is the answer for one right option, Check for
  several, and the right options are revealed after a wrong answer.

## Do not

- Draw a twelve-note keypad for a name-the-note item (D9).
- Select an audio option when its play button is tapped.
- Give a different look to options of different exercise types.
- Accept an answer while the stimulus is missing.

Open in spec: the four-choice guess rate needs ADR-046's accuracy rule amended (MOT-78).
