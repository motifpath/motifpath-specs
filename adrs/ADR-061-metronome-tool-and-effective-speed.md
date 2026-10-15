# ADR-061: One metronome component, note values as a speed factor, progress at effective speed

**Status:** Accepted
**Date:** 2026-10-15 (Proposed) · 2026-10-15 (Accepted, in review of specs#347)
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-156
**Amends:**
- ADR-041: a playback can be played at a note value, as a speed factor on its written note
  values.
- ADR-046: a play-along's best clean tempo and its tempo ladder compare effective speed.

---

## Context

Students speed up a play-along by raising the BPM on the tempo ladder (ADR-046). Past about
160 BPM, that stops matching how musicians practise. Nobody sets a metronome to 240. They keep
the click comfortable and play eighths, then triplets, then sixteenths over it. A student
pushing the slider to high values hears a click too fast to follow, and the ladder stalls.

The Product Owner also wants a metronome students can use outside a session. Until now the
metronome existed only inside things: `TempoControl` on a play-along take and on chord changes,
the song chart reader's tempo, and the lesson diagram player. Each of those offered a subset of
controls, and there was no single place to set a tempo, a time signature and a subdivision.

Two questions follow:
- What does choosing a note value change in the music, and in the evidence?
- How do the standalone tool and the embedded metronomes stay one experience as either one
  changes?

Alternatives were considered for both: a separate tool UI next to the embedded control, and a
note value that rewrites each note's rhythm literally.

## Decision

**1. One metronome component, compact first.**
- `TempoControl` is the metronome everywhere: the toggle, the tempo slider and the BPM (tap to
  type). When a surface allows it, the current **note value** shows as an icon beside the BPM.
- Its choices appear only on demand. A tap on the icon opens a popover of note-value icons:
  - quarters, eighths, triplets and sixteenths in exercises and drills;
  - every value in the Metronome tool.
- The **Metronome tool** reuses the same row and adds the bar: a time-signature button (the
  fraction) beside the beat dots. A tap on the fraction shows the presets (2/4, 3/4, 4/4, 6/8,
  12/8) plus − / + for the beats (1–12) and the beat note (/2, /4, /8).
- A change to the component reaches every place it is used.

**2. The Metronome is a tool in a Tools area of the Practice Shell.**
- Tools open from the shell header's reserved options slot (a wrench), on the session setup
  only, never during a run.
- Tools is a sheet on Compact and an anchored menu on Medium and Expanded. The Metronome is its
  first and only tool for now.
- The Metronome page stops when the student leaves it, and nothing in it is tracked.

**3. A note value is a speed factor on the music as written.**
- The factors relative to the written values are: halves ×½, quarters ×1 (as written, the
  default), eighths ×2, triplets ×3, sixteenths ×4, quintuplets ×5, sextuplets ×6 and 32nds ×8.
- A playback played at a note value plays every step's written duration divided by the factor,
  while the click stays on the beat at the BPM.
- The same rule holds for licks and for progressions. A progression played in eighths changes
  chord twice a bar.
- In the Metronome tool, which has no notes, the factor is the number of clicks per beat. The
  beat's click is louder, and halves click every other beat.

**4. Progress is measured at effective speed.**
- Effective speed is BPM × factor, expressed in quarter-note BPM.
- A rated play-along take records the `note_value` it was played at. Absent means quarters.
- Takes are compared at effective speed:
  - the best clean tempo;
  - "a take that isn't clean above the best clean tempo";
  - the ladder's target and its 60% floor;
  - improvements reported in the overview.
- Tempos are shown and stored **as played**. "80 BPM in eighths" stays 80 BPM with
  `note_value: eighths` and counts as 160.
- A session starts a play-along in the note value of the student's best clean take, at its
  tempo, so the student resumes where they left off.
- The ladder's steps (+5 / −5 BPM) are steps of the played BPM, within the current note value.
- When the student picks another note value, the next take's tempo keeps the effective speed
  (160 in quarters → 80 in eighths), rounded down to the 5 BPM grid.

**5. Where note values are offered.**
- Play-alongs and lesson licks: tempo + the suggested values.
- Progression playback (hear drills, guide tones): tempo set by the level and changeable, plus
  the suggested values.
- Chord and root changes, and the song chart reader: tempo only.
- Single-chord playbacks: no metronome controls.
- The time signature is set by the content everywhere except the tool.

## Rationale

**One component over a tool UI of its own.** A first design gave the tool a large tempo readout
and chips for every control. The Product Owner rejected it. Two metronome UIs drift apart, and a
student who learns one must relearn the other. Starting from the compact row and adding only
what the tool needs (the bar) keeps one interaction everywhere.

**Choices on demand, not always visible.** Note-value chips under every tempo control took
space a practice screen needs for the music. The current value, as an icon beside the tempo,
says what is playing. The popover is one tap away when the student wants to change it.

**A speed factor over a literal rhythm.** Replacing every note's written value with the chosen
one (every note becomes a sixteenth) is exact for a lick in one rhythm. It has no meaning for
dotted notes, mixed values, tuplets or rests, which ADR-041 playbacks carry. A factor applies
to any playback and keeps its rhythm. It is also what a musician means by "play it in eighths":
the same music at double speed over the same click.

**Progressions follow licks.** The alternative kept one chord a bar and only subdivided the
strums. It would give the note value two meanings, one for licks and one for progressions. The
Product Owner chose the single rule. Changing chord faster is a real skill to drill, and a
student who wants the slower harmonic rhythm keeps quarters.

**Store as played, compare at effective speed.** Converting takes to quarter BPM before storing
would lose what the student did, so "80 in eighths" could no longer be shown, and halves would
produce fractional BPM. Keeping BPM and note value as given, and deriving effective speed when
comparing, keeps evidence raw, as ADR-046 requires, and lets the rule change later without
migrating evidence.

## Consequences

### Positive

- A student can keep a comfortable click and still climb in speed, which matches how musicians
  practise.
- One component carries every metronome. A fix or a change to it reaches the tool, play-alongs,
  drills and lessons together.
- Evidence keeps exactly what was played, and old evidence stays valid: no note value means
  quarters.

### Negative / Trade-offs

- **Every comparison of tempos must use effective speed.** The worker's best clean tempo, the
  composer's start tempo, the ladder, the knowledge-state rules and the overview all change.
  A missed one would compare 80 in eighths with 100 in quarters as if 80 were slower.
- **A factor can produce very fast playback.** At 32nds ×8, 150 BPM is 1,200 notes a minute.
  The tool caps nothing beyond the BPM range, so absurd settings are possible.
- **Progressions in fast values change the harmonic rhythm.** A hear drill in sixteenths
  changes chord every beat. That is harder than the drill's level intends, and the student
  chooses it knowingly.
- **More controls to explain.** The popover needs clear names next to the icons ("Eighths ·
  2 notes a beat") for students who don't read rhythm.

### Neutral

- Guide-tone takes (`timed_taps`) will need the same `note_value` when that drill is built
  (MOT-151). Bar timing then divides by the factor. It is not specified here.
- The song chart reader keeps tempo only. A chart has no timing to scale.
- Hear drills' answers are never graded on tempo, so their note value affects only what is
  played.

## Related ADRs

- ADR-041: Diagram audio playback — amended: a playback can be played at a note value (a speed
  factor).
- ADR-046: Evidence-based practice model — amended: best clean tempo and ladder at effective
  speed.
- ADR-049: Practice-first experience language — the Practice Shell, whose options slot holds
  Tools.
- ADR-057: Drill model v2 — progression playback in hear drills and guide tones.

---

*This ADR was proposed and accepted on 2026-10-15. To revise, create a new ADR with Status: Supersedes ADR-061.*
