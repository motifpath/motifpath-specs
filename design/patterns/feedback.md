# Pattern: answer feedback and the commit point

**Source:** ADR-049 §2 (Feedback, Flow) and §3, ADR-046 (latency from the prompt) · first used by
PB-22 slice 3 Phase 7

## When

Use it whenever a practice item is answered and graded during a run.

## Why

ADR-046 measures response time from the moment the prompt appears, so a needless tap reads as
slowness. A student who answers wrong needs to see where the mistake is, or the session only tells
them that they failed, not what to learn.

## How

### The commit point, by interaction

| Interaction | Commit | Then |
|---|---|---|
| Choice (one right option) in a session | **the tap is the answer** | feedback in place |
| Region / diagram cell (one right cell) in a session | the tap is the answer | feedback in place |
| MultipleChoice (several right options) | **Check**, once at least one option is chosen | feedback in place |
| audio_selection (options are sounds), even with one right option | **Check** (D10, P4) | feedback in place |
| SelfRating (a play-along take, a chord change, a song) | the rating tap (`self-rating.md`) | the next take, or Next up |
| Any exercise in an S7 challenge | the selection the student moves on with (Next / Finish) | no feedback until the end |

The answer's latency is taken at the commit. For audio_selection, listening is not answering: it is
counted from the end of the last clip played, not from the prompt (exception to ADR-049 §3, to be
written down by MOT-78).

### Feedback

- **Right:** a check icon and "Right!" next to the action bar. The chosen option is marked right. The
  session moves on after a short pause (900 ms). When reduced motion is on, Continue shows instead.
- **Wrong:** a cross icon and "Not quite.". The chosen option is marked wrong, **the right option(s)
  are revealed**, and the session waits for **Continue**.
- **Locked:** once committed, the item's options can't be changed.
- **Placement:** feedback renders in place, never in a dialog or a toast. It never depends on colour
  alone: every mark has an icon and an accessible label.

### Not answered

A skipped or unavailable item is **not answered**, never wrong: no accuracy, no response time, no
level change. While a stimulus is missing (a clip that didn't load), the options stay locked, so a
guess can't become evidence (D21; ADR-046 amendment in MOT-78). See `unavailable-and-errors.md`.

### Challenge review

An S7 challenge shows no feedback during the run. After Finish, the review lists every exercise with
the student's answer and the right one (D7).

### Reveal

The exercise view stays neutral by default: it never reads which options are right, so the authoring
preview and the challenge show no answers. A caller that has graded an answer passes the right
option ids in, and only then does the view mark options right or wrong. This holds for every option
type: text, image, audio and diagram options, and the image regions or diagram cells of a recognition
exercise.

## Do not

- Add a Check step to a single-answer exercise in a session.
- Reveal answers in an S7 challenge before its end.
- Let a changed selection after the commit become a new answer.
- Grade a play tap: an audio option's play button only plays.
- Count a skipped or unavailable item as wrong.
