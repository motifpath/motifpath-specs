# Pattern: lesson

**Source:** ADR-049 §1 and §5 · ADR-019 / ADR-021 (content and media) · ADR-050 §4 (song charts in
lessons) · MOT-56 (Figma "My path & lessons", rows 2–7; decisions D1, D2, D4–D7, D11, D12, D14) ·
designs MOT-14, MOT-24

## When

Use it for a step opened from My path, Home's path card or a link: a video lesson or an article
lesson. A "diagram lesson" is an article whose body starts with a diagram (D7). The API has two
kinds, `video` and `article`, and no third one.

## Why

A lesson is watched or read with an instrument nearby. The content needs the room, extra content
should show up without taking the student out of the lesson, and the end of a lesson should lead
straight to the next thing to do.

## How

- **A pushed page.** A back arrow and the path title return to My path. On Compact the bottom bar is
  hidden so the lesson gets the height (D1). The rail and the sidebar stay on Medium and Expanded
  (D12).
- **Title block:** the lesson title, then "Step N of M · kind". There is no length (D4); the video
  player shows the time once it loads.
- **Video:**
  - The player sits at the top, at full width.
  - Cues (`ExpandedContent`: a diagram, an image, rich text or a song chart card) show in place under
    the video while they're active. On a phone in landscape and in full screen, they sit beside the
    video.
  - When the video ends, the action bar offers the hand-off:
    - With a challenge: "Practise this", which starts the S7 run in the Practice Shell.
    - Without one, the step is done when the video ends (D2). The screen shows "Step done", the next
      step's card with "Start lesson", and "Back to My path" as the quiet way out.
- **Article:**
  - The text sits in a readable column, with diagrams, song chart cards and chord voicings embedded
    in it.
  - A paragraph cue sits under its paragraph and stays; `duration_ms` is ignored for articles (D5).
  - There is no sticky bar while reading. The hand-off is at the end of the text: "Mark as done" (or
    "Practise this"), which also opens the next step (D6).
- **Diagrams in a lesson** follow `diagrams.md` (scroll and overview strip for large ones) and
  `chord-card.md` (Box | Neck, voicings named by position).
- **Song charts in a lesson** show as the `SongChartCard`; tapping it opens the reader as a layer
  over the lesson, and a video pauses and resumes at the same moment (`song-chart.md`).
- **After the S7 challenge** the Practice Shell summary says "Step N done" and shows the next step's
  card. "Back to My path" is the quiet way out.
- **Review:** a done step never gates. There is no completion action, only "Practise again"
  (secondary) when the lesson has a challenge (D11).
- **States, in place:**
  - Loading: a skeleton in the lesson's shape.
  - The video or a diagram didn't load: an `InlineNotice` with "Try again" where it would be; the
    rest of the lesson stays readable.
  - Locked, or language-locked: explains why and offers the way forward (see `path.md`).
  - No longer on the path: "Go to My path".
- **Size classes:**

  | Size class | Layout |
  |---|---|
  | Compact | One column; video at full width. |
  | Medium | Rail; one column (video 620 px, text 560 px). |
  | Expanded | Sidebar; the same one column as Medium (video 620 px, text 560 px), cues under the video (D14, revised 2026-10-10). |

## Do not

- Put a side column beside the lesson on a wide screen: it shrinks the cue to a sliver and leaves
  most of the screen's width empty. The one column keeps the cue as wide as the video (D14,
  revised 2026-10-10 after the first build).
- Show a cue as a pop-up that disappears while the student reads.
- Put a disabled "Mark as done" button on screen until the end.
- Send the student back to the path list after finishing a step when the next step is one tap away.
- Gate a step the student already finished.

## Spec changes this needs

- **D5:** `ExpandedContent.duration_ms` is ignored for article nodes. Deprecated and optional in
  core-domain 0.34.0 (MOT-97); authoring stops asking for it in MOT-95.
