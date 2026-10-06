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
| Any exercise in an S7 challenge | the selection the student moves on with (Next / Finish) | no feedback until the end |
| Play-along take | the self-rating | the next take, or the next item |

The answer's latency is taken at the commit.

### Feedback

- **Right:** a check icon and "Right!" next to the action bar. The chosen option is marked right. The
  session moves on after a short pause (900 ms). When reduced motion is on, Continue shows instead.
- **Wrong:** a cross icon and "Not quite.". The chosen option is marked wrong, **the right option(s)
  are revealed**, and the session waits for **Continue**.
- **Locked:** once committed, the item's options can't be changed.
- **Placement:** feedback renders in place, never in a dialog or a toast. It never depends on colour
  alone: every mark has an icon and an accessible label.

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
