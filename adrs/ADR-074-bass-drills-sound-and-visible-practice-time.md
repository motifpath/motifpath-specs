# ADR-074: Bass Drills Sound the Asked Notes, Changes Run Ten Cycles, Minutes Count Visible Time

**Status:** Accepted
**Date:** 2026-11-12
**Deciders:** Product Owner (Gilson Yamada)
**Input:** MOT-197 — PO review of the bass drills, the in-the-head drills and the home minutes; approved by the PO (Gilson Yamada) in session on 2026-11-12
**Amends:** ADR-046 (the chord-change rules), ADR-051 (how minutes practised are measured)

---

## Context

A PO review of practice on bass, after the drills reached production, found that the bass drills
work against the student:

- **They are silent or sound like a guitar.** A root and fifth has no sound and no metronome. A
  bass key tour strums the guitar voicing of each chord, while the student is asked to play roots.
  The drills that keep a beat each build their own tempo row, instead of the metronome the
  Metronome tool uses.
- **A chord change is too long and hard to rate.** It is a full minute, one change on every beat,
  and the student then counts the clean changes. Nobody counts while playing, and a first-time
  student doesn't know they must.
- **They don't climb.** A bass key tour asks for roots only, at every level. A teacher would move
  from roots to root and fifth, then to triads, then to sevenths.
- **They always start at the open string.** Every bass place is the lowest one in the first frets
  (`bassPlace`), so a student never leaves the bottom of the neck.
- **The board shows one 3rd and one 5th.** On bass, the 5th below the root and the 3rd above are
  both under the hand; showing one of each hides half of the chord's shape.

Two problems sit outside bass. In the head, a heard progression such as IV–V–I plays four bars
(IV V I I) while its option names three numerals. And the home's **minutes practised** showed 473
minutes for a student with a few short sessions: ADR-051 counts each session from its start to its
last practice event, so a session left open in the background, then answered later, counts every
minute in between. ADR-051 named this trade-off; production shows it is not acceptable.

## Decision

MotifPath will change the bass drills, the chord change and the minutes as follows.

### 1. One metronome

Every drill that keeps a beat uses **one shared metronome row**: the beat dots and the tempo control
with its note values, as on the Metronome tool page. The Metronome tool uses the same component.

### 2. A chord change is ten cycles, rated by the share of clean changes

On guitar and on bass (`chord_change`, `root_change`), a take is **ten cycles** at a tempo, one
change on every beat: one cycle is from → to → from, so a take is **20 changes**, after a bar of
count-in. When the take ends the student picks the **share of changes that rang clean** from four
buttons: **25 %, 50 %, 75 % or 100 %**. The take sends the tempo and the share.

- The rating follows from the share: **100 % is clean, 75 % is almost, 50 % or less is struggled.**
- The change ladder across sessions is unchanged: 5 BPM up after two clean takes in a row, 5 down
  after a struggle, never below 20, the first take at 40.
- The target becomes a **tempo**: the catalog's 60 BPM, all changes clean. `target_changes_per_minute`
  and `best_clean_changes_per_minute` give way to `target_tempo_bpm` and `best_clean_tempo_bpm`;
  `last_changes_per_minute` is dropped.
- Evidence already kept from a minute is read as a share: changes per minute ÷ tempo, rounded down
  to the nearest button (so 54 of 60 reads as 75 %; below 25 % reads as 25 %).

### 3. Bass drills sound the bass notes asked, and only those

On bass, playback sounds **only the notes the drill asks for, in the bass's voice**: never a guitar
chord. Chord tones that are not asked stay on the board, unplayed, so the student sees what kind of
chord they play under.

- **A root and fifth** plays the root then the fifth, **a half note each**, under the metronome. It
  stays self-rated; the take sends the tempo it was played at.
- **A root change** sounds the two roots on the beat it asks for them.
- **A bass key tour** plays its pattern (below) on every bar, with the metronome; no chords.

### 4. The bass board marks both 3rds and both 5ths

Where a bass drill shows a chord's tones, the board marks the root, **the 3rd and the 5th above it,
and the 3rd and the 5th below it**, wherever they fall on the layout within the drill's frets.

### 5. Bass key tours climb by pattern

A bass key tour plays one pattern on every bar, chosen by the student's level on the tour:

| Level | Pattern (each bar of 4/4) |
|---|---|
| new, learning | root, a whole note |
| accurate | root and 5th, a half note each |
| fluent | root, 3rd, 5th, 3rd, quarters |
| retained | root, 3rd, 5th, 7th, quarters (the chord's own 7th: ♭7 on a 7 chord, 7 on a maj7, the scale's 7th on a triad) |

The pattern is planned by core like the tour's key and tempo, and named on the item, so the take and
the board agree. The tour's ladder and key cycle are unchanged.

### 6. Bass positions vary

A bass drill's places are no longer always the lowest in the first frets. The plan picks a
**starting fret from 0 to 9** for the item's first root, by the session's pick, and places every
other note in a **five-fret window** from there (the root on the lowest string that holds it in the
window, with the fifth above it there too for a root and fifth; a five-fret window always allows
this on a four-string bass). A tone no string reaches in the window is left off the board. A tour
keeps one window for a whole take; the next key may move it.

### 7. A heard progression's option names every bar heard

A heard progression's options are named by **every bar's numeral, in order** (IV–V–I–I), so the
numerals shown always match the chords heard. The catalog and its names are unchanged; drills only.

### 8. A simpler chord-quality ear drill

The `hear-chord-quality` node gets a new in-the-head drill, **heard chord quality**: one chord plays
alone, on a root picked each time and in no key, and the student picks its quality. Options are major,
minor and dominant 7 until the student is fluent on the item, then diminished and augmented too.
It joins the node's existing drills and doesn't replace them.

### 9. Minutes practised count visible time

**Minutes practised** become the sum of the time each session was **visible to the student**: the
practice screen in the foreground, the app not hidden or in the background. The client measures it
and every practice event of a session (practice.item_answered, practice.session_ended) carries
`visible_ms`: the visible time since the session's previous practice event, or since its start.

- A session counts the sum of its events' `visible_ms`, never more than its start-to-last-event span.
- An event without `visible_ms` (sent before this change, or by an older app) counts the gap since
  the previous event, **capped at 2 minutes**. This also corrects the minutes already counted.

## Rationale

- **Ten cycles over a minute**: 20 changes is long enough to show whether a change is clean, and
  short enough that a student finishes it. A minute at 60 BPM is 60 changes.
- **Four share buttons over counting**: a student can tell "all clean" from "about half" without
  counting while playing. *Rejected:* ranges (< 50 / 50–75 / 75–99 / 100 %), as they read as
  precise numbers the student never measured; a free count, which is today's problem.
- **Only the asked notes over the guitar chord**: the sound should be what the student plays, so
  they can play along and hear a wrong note. The board, not the sound, carries the chord's quality.
- **Level-chosen patterns over a separate pattern ladder**: the level already drives other drills
  (the key setting of a heard chord, the options of a fluent student), and needs no new state.
  *Rejected:* climbing a pattern only after a clean lap of all twelve keys, which takes weeks.
- **Visible time measured by the client over a server-side cap alone**: only the client knows when
  the screen is hidden. A cap alone would also cut real time on a long take. The 2-minute cap is
  kept only for events that can't say.
- **Bar-by-bar names over renaming the catalog**: the catalog names are also the song charts' and
  the authors'; the drill is the only place where the bars are heard.

## Consequences

### Positive

- Every bass drill has sound, a metronome and a pattern that grows with the student.
- A chord change takes about 30 seconds instead of 90, so a session holds more variety.
- The home's minutes become believable, and the minutes already counted are corrected.

### Negative / Trade-offs

- The chord-change contract breaks (`changes_per_minute` → `clean_share_percent`, new best and
  target fields): core, the worker and the app ship together.
- A share in quarters is coarser than a count: two takes at 80 % and 95 % both read as 75 %.
- Visible time still measures time on screen, not attention.
- Old events without `visible_ms` are capped, so a real long take in an older session may count
  short.

### Neutral

- The guitar drills keep their chord sound; only bass changes.
- The fluent times, session caps and the rest of ADR-046 stay as they are.

## Related ADRs

- ADR-046: Evidence-based practice model — its chord-change rules are amended by §2.
- ADR-051: Minutes practised and a day streak on the home — its measure of minutes is amended by §9.
- ADR-057: Drill model v2 — the rung and level rules §5 and §8 build on.
- ADR-061: Metronome tool and effective speed — the shared row of §1 is that tool's.
- ADR-073: One spec PR per ticket — this ADR ships in MOT-197's spec PR.

---

*This ADR was proposed and accepted on 2026-11-12. To revise, create a new ADR with Status: Supersedes ADR-074.*
