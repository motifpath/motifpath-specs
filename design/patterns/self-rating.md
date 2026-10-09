# Pattern: self-rating and the tempo ladder

**Source:** ADR-049 §2 (SelfRating, TempoLadder) and §3 · ADR-046 (play-along takes, best clean) ·
MOT-55 (Figma "Practice Shell — flows", rows 3, 7, 11; decision D4, D17 and the revised tempo
control)

## When

Use it when the app can't grade what the student played and the student says how it went: a
play-along take, a chord change (MOT-79) and a song from a song chart (MOT-76).

## Why

The rating is the student's answer. Making it a separate step after a Continue button would add a tap
to every take, and a scale with many points makes the student think about the scale instead of the
take.

## How

- **SelfRating replaces the action bar** (D4): three equal tiles in the thumb zone, keys 1–3. The tap
  is the rating and the commit; there is no Continue after it.

  | Tile | Says |
  |---|---|
  | Struggled | Fell apart or had to stop |
  | Almost | Got through with slips |
  | Clean | No slips |

- **The question names what was played:** "How was that take at 72 BPM?", "How did Amazing Grace go?".
  A song's question names no BPM (D17): the chart has no timing to grade the take against.
- **Restart without rating** is a tertiary link above the tiles: it throws the take away and goes
  back to the tempo, recording nothing.
- **TempoControl (the tempo ladder):** one 48 px row — metronome toggle (on by default), a slider
  from 40 to 300 BPM as the main control, ticks for the best clean tempo and the goal, and the value
  at body size; tapping the value lets the student type an exact BPM. The meta line above says
  "Take 1 of 3 · Goal 96 BPM · best clean 68".
- **While playing:** the take ends by itself. **Restart** (back to the tempo, nothing rated) sits
  beside **Stop early**, so a wrong tempo is fixed without rating a bad take.
- **After the last take,** Next up shows what was played and the fastest clean tempo, then the next
  item (`session.md`).
- **Song chart:** no timing in the chart, so no tempo ladder, auto-scroll or "now / next chord": the
  student scrolls (the pedal moves a line), opens chords on the chord card (`chord-card.md`) and rates
  the whole song once. Clean on two separate days puts the song "in your repertoire".
- **Song chart metronome (MOT-73 D2):** the chart's tempo is a practice aid — `TempoControl` with the
  song's tempo as the target tick, so a student can start slower and work up to it. It is never
  tracked or rated (`song-chart.md`).

## Do not

- Add a Continue or Check after the rating.
- Use more than three ratings, or stars or numbers.
- Put a BPM in a song's rating question, or record the metronome tempo for a song.
- Rate a take the student restarted.
