# ADR-041: Diagram audio playback — a rhythmic step sequence on the Diagram, sampled voices, and audio-clock highlighting

**Status:** Proposed
**Date:** 2026-09-28
**Deciders:** Gilson (Product Owner)
**Partially supersedes:** ADR-028's `DiagramPosition.sequence_index` and `diagram_ref.playback`
(`direction`, `step_ms`), and the ADR-027/ADR-028 note that sends audio-synced highlighting to
Canvas. Everything else in ADR-028 stands.

---

## Context

PB-71 ("Diagram sound") makes a diagram *audible*. A student presses Play and hears the scale run,
chord or lick, and each marker lights up while its note sounds. ADR-028 anticipated playback, but
only as a visual animation: each position gets an optional `sequence_index`, and a `diagram_ref`
steps through those indices every `step_ms` milliseconds. Nothing in the model produces sound, and
the PB-70 spike (`spikes/PB-70-diagram-audio-findings.md`) showed that the model can't carry music
either:

1. **No rhythm.** `step_ms` is one fixed gap between every note. Real material needs mixed note
   values (a dotted quarter then an eighth, triplets), rests, and a tempo that musicians think of
   in BPM, not milliseconds.
2. **A position can sound only once.** `sequence_index` is one number per position. A chord that
   is strummed and then arpeggiated uses the same five positions twice. Chords (several positions
   at once) are only implied by duplicate indices, which the spec never defined.
3. **No pitch for fretted positions.** `Instrument.tuning` is `["E","A","D","G","B","E"]`, with no
   octaves, so the pitch of string 6 fret 5 can't be computed. Keyboard positions already carry
   octaves (`key: "C4"`).
4. **No sound source.** The instrument decides the *layout* (strings, frets, keys), but not the
   *timbre*. Acoustic and electric guitar share every diagram but sound different, and the same
   is true of piano and electric piano.

The spike also answered the engineering questions: which audio library, how many samples, how to
keep highlights in sync, and whether SVG keeps up.

**Alternatives considered for the sequence:**

1. Keep `sequence_index` and add a note value per position. Rejected: it still can't reuse a
   position, and a chord's shared value would be repeated on every one of its positions.
2. Store the sequence on each `diagram_ref`. Rejected: the rhythm of a lick is part of the
   content, not of one usage. Every lesson and exercise that embeds the lick would re-author it.
3. An ordered list of **steps on the Diagram**, each naming the positions it sounds, its note
   value, and an optional strum. Accepted.

**Alternatives considered for producing sound:**

1. Synthesis (Karplus-Strong or oscillators). Rejected: no download, but it sounds nothing like a
   guitar or piano.
2. Tone.js `Sampler`. Rejected: 61 kB gzip, doesn't tree-shake, and we'd use about 2% of it.
3. Our own ~60-line Web Audio sampler. Rejected: 0.5 kB, but the spike's version clipped and mixed
   voices — mixing and envelopes are the part we'd get wrong.
4. **smplr**, pinned, behind our own adapter. Accepted: the best sound in the listening test and
   21 kB gzip, loaded on demand.

**Alternatives considered for highlight sync:**

1. `setTimeout`, or a library callback (`Tone.Draw`, smplr `onStart`). Rejected: measured 33–240
   ms early, because callbacks ignore output latency or fire at scheduling lookahead.
2. **Read the audio output clock every animation frame.** Accepted: 0–17 ms error, no drift.

## Decision

### The sequence is a list of steps on the Diagram

```
Diagram {
  ...                                   // unchanged
  tempo_bpm: int | null                 // default tempo; null = no playback authored
  time_signature: TimeSignature         // default 4/4
  sequence: SequenceStep[]              // ordered; empty = the diagram doesn't play
}

TimeSignature { beats: int 1..16, beat_value: 1 | 2 | 4 | 8 | 16 | 32 }   // 4/4, 3/4, 6/8, 7/8, ...

SequenceStep {
  position_ids: uuid[]                  // positions that sound together; empty = a rest
  value: NoteValue                      // the step's length
  strum: "none" | "down" | "up"         // only meaningful with 2+ positions; default "none"
}

NoteValue { num: int >= 1, den: int >= 1 }   // a fraction of a whole note
```

- The author picks the **time signature**. Whether it is simple or compound is derived from it,
  and that decides what one BPM beat (the *pulse*) is:
  - **Compound** when `beats` is 6, 9, 12 or 15 and `beat_value` is 4 or shorter. The pulse is a
    dotted note: `3 / beat_value`. 6/8 counts two dotted quarters per bar, 12/8 four, and 6/4 two
    dotted halves.
  - **Simple** otherwise (2/4, 3/4, 4/4, 2/2, …). The pulse is `1 / beat_value`.
  - **Irregular** meters (5/8, 7/8, …) count in `1 / beat_value` for now. Grouping them (2+3,
    2+2+3) is additive later.
- A step's duration in seconds is `(value / pulse) × 60 / BPM`. 1/4 is a quarter, 3/8 a dotted
  quarter, 1/16 a sixteenth.
- **Tuplets need no extra field.** A tuplet of *n* notes in the time of *m* notes of value 1/*d*
  gives each note the value `m / (n × d)`. An eighth-note triplet is `1/12` (three fill a quarter),
  a quarter-note triplet `1/6`, a sixteenth-note sextuplet `1/24` (six fill a quarter), and a
  quintuplet of sixteenths `1/20`. The editor offers "triplet", "sextuplet", etc. as a modifier on
  the note value and stores the reduced fraction. `den` is limited to 1–128 so exotic values stay
  bounded.
- The editor draws bar lines by adding up step values against the bar length
  (`beats / beat_value`). The sequence doesn't have to fill whole bars, and a note may cross a bar
  line; a pickup (anacrusis) is additive later.
- A position may appear in any number of steps, and any number of positions may share a step (a
  chord). Every `position_id` must belong to the diagram. A step with no positions is a rest.
- `strum: down` sounds the lowest pitch first, `up` the highest first, with a fixed per-note offset
  chosen by `motifpath-web` (starting at 18 ms). The offset is not stored. The first note of the
  strum lands on the beat.
- There is no articulation field (staccato, legato). Every note sounds for its full value and
  releases into the next. It is additive later if real content needs it.
- `tempo_bpm` is required as soon as `sequence` is non-empty, within 20–300.
- `DiagramPosition.sequence_index` is removed. Only seed data uses it today. Existing indices
  migrate into steps: positions with the same index become one step, in index order, each an
  eighth note (1/8) in 4/4 at 90 BPM.
- "Save as" (ADR-032) copies the sequence and time signature with position ids remapped.
- A diagram flattened from a stack is an ordinary diagram and can play. It starts with an empty
  sequence (its sources' rhythms don't combine into one), and its author gives it its own.

### Pitch comes from the instrument, transposed by the usage

- `Instrument.tuning` entries carry octaves, lowest string first, in scientific pitch notation:
  `["E2","A2","D3","G3","B3","E4"]`. A fretted position's pitch is the open-string pitch of its
  string plus `fret` semitones (string 1 = highest). A keyboard position's pitch is its `key`.
- Existing instruments are migrated by adding the octaves of their standard tuning. Creating an
  instrument without octaves is rejected.
- A `diagram_ref`'s `root_override` transposes the sound exactly as it transposes the drawing.

### A voice is the timbre, chosen separately from the instrument's layout

```
Voice {
  voice_id: string                      // stable slug, e.g. "acoustic-guitar"
  names: LocalizedNames
  family: "fretted" | "keyboard"        // voices only play diagrams of this family
  pitches: int[]                        // MIDI pitches that have a sample
  attribution: string                   // license credit, shown on the credits page
}

Instrument { ...; default_voice_id: string }
```

- `Instrument` stays the *layout*. "Electric guitar" is not a new instrument: it is a second voice
  for the same 6-string layout, so every guitar diagram can use it.
- Voices are platform assets, not user content. They are seeded by the platform; there's no
  authoring endpoint in this ADR. `GET /voices` lists them.
- Samples live on the ADR-021 media stack (S3 + CloudFront in production, MinIO in dev) at
  `/audio/voices/{voice_id}/{midi}.mp3`, with immutable caching. `pitches` is the manifest.
- Sampling rules: one sample every 3 semitones across the voice's range, so a note is never
  repitched more than ±1 semitone; mono MP3 at 96 kbps, trimmed to 3 s with a 0.6 s fade. A note
  longer than its sample simply decays to silence, which is natural for plucked and struck
  instruments. A 3 s guitar voice is 12 files and about 430 kB.
- The sample length belongs to the voice's files, not to any schema. Longer notes later need no
  model change: re-export a voice with longer samples (about +30% size per extra second), or, for
  sustaining voices (organ, strings, pads), give the voice loop points so a note holds as long as
  its value.
- The first voices are tonejs-instruments' acoustic guitar and piano, under CC-BY 3.0. Their
  upstream provenance must be confirmed and credited before production.

### `diagram_ref.playback` becomes a per-usage override

```
playback: {
  tempo_bpm: int | null       // overrides the diagram's tempo; null uses it
  voice_id: string | null     // overrides the instrument's default voice; null uses it
  direction: "as_authored" | "reversed"
  loop: bool                  // default false
} | null                      // null: this usage offers no Play control
```

- The effective tempo is: the student's choice > `playback.tempo_bpm` > `Diagram.tempo_bpm`. The
  student's tempo is a local player control (a tempo slider), never saved.
- The effective voice is: `playback.voice_id` > `Instrument.default_voice_id`. The voice's
  `family` must match the diagram's instrument family.
- Students can't switch voices yet. The model already allows it: a later student voice choice is a
  local player control, like the tempo, limited to the voices of the diagram's family, and it
  takes precedence over both.
- `reversed` plays the steps in reverse order. Each step keeps its own value and strum.
- `step_ms` is removed.
- A diagram whose `sequence` is empty has no Play control, whatever its `diagram_ref` says.
- A `diagram_stack_ref` doesn't play in this ADR. Its entries' `playback` is ignored. A stack's
  sequences don't share a tempo or length, and the comparison use case doesn't need sound yet.
- Playback never draws a position the usage hides (`layers.hidden_position_ids`, ADR-040). The
  position still sounds. An `image_recognition` stimulus can therefore play the notes a student
  has to find, without showing them.

### Engine and sync in `motifpath-web`

- **smplr, pinned to an exact version** (1.0.1), used only through one adapter module. The adapter
  always passes `detune: 0`, note-name sample keys and an explicit `ampRelease`. Each of these
  prevents a trap where smplr 1.0.1 plays nothing and reports no error. An offline test that
  renders one note guards every version bump.
- The audio code is **lazy-loaded** when a diagram first plays. The voice is prefetched when a
  playable diagram scrolls into view. Play shows a loading state until the voice is ready. There is
  no synthesized fallback.
- The `AudioContext` is created or resumed **inside the Play tap handler**, as iOS Safari requires.
- All notes of a run are scheduled on the audio clock up front. **Highlights never use timers or
  library callbacks.** Each animation frame reads `AudioContext.getOutputTimestamp()` (falling back
  to `currentTime − baseLatency`) and highlights the steps that are audible at that moment.
- **Highlights are drawn in SVG**, as ADR-027 decided for diagrams. No Canvas layer is added for
  playback.

## Rationale

**Steps on the Diagram, not an index per position.** The spike's first real example (strum a
chord, then arpeggiate it) was impossible with `sequence_index`. A step list stores exactly what a
musician writes: which notes sound, together or in turn, for how long. It lives on the Diagram
because a lick's rhythm is content. A usage only changes *how* it is heard (tempo, voice,
direction, loop). That is the same split ADR-028 already made between stored positions and a
per-use render config.

**Note values as fractions, tempo as BPM.** Musicians and teachers think in BPM and note values,
and the fraction `{num, den}` covers dotted notes and tuplets without special cases. `step_ms`
couldn't express either and had to be re-tuned by hand whenever the tempo changed.

**A time signature the author picks; simple or compound derived from it.** The meter decides
what a "beat" is: a 6/8 lick at 60 BPM means 60 dotted quarters a minute, not 60 eighths. Deriving
simple/compound from the signature (as musicians read it) means an author picks one familiar
thing, "6/8", instead of a signature *and* a separate beat unit that could contradict it. The
signature also gives the editor bar lines and a sensible default note value.

**Tuplets as plain fractions, not a tuplet object.** For sound, a triplet eighth is simply a note
one twelfth of a whole note long, so `{1, 12}` is all the player needs. A bracketed tuplet group
only matters for printed notation, which we don't render. If we ever do, a group marker is an
additive field on steps.

**No articulation, per-step dynamics or pickup bar yet.** The first material (scales, arpeggios,
strummed chords, short licks) doesn't need them, and each is an additive field later. Adding a
whole notation model now would be building ahead of the content.

**Voice separate from Instrument.** Diagram positions depend only on the layout, so guitar-family
voices can share every guitar diagram. Making "electric guitar" an instrument would duplicate every
diagram per timbre. A voice has a `family`, not a list of instruments, so a future 7-string guitar
gets every fretted voice for free.

**smplr over Tone.js and our own sampler.** smplr sounded best, and it is a third of Tone's size.
It is also young: 1.0 is a recent rewrite with three silent failures. The exact pin, the adapter
and the one-note test contain that risk at one small module. Our own sampler would be smaller
still, but the spike showed that gain staging and voice management are easy to get wrong. That is
the part smplr does for us.

**Audio clock, not callbacks.** Callbacks fire when the note is *scheduled* or reaches the context
clock, not when it reaches the speaker. They were 33–240 ms early, which is well past the ~45 ms
at which viewers notice sound and picture drifting apart. The output clock includes output latency
and gave 0–17 ms with no drift over 128 notes. It also works the same with any library, so
swapping smplr later wouldn't touch the highlighting.

**SVG, not Canvas.** ADR-027 sent audio-synced highlighting to Canvas on the assumption that we'd
chase external audio. We generate the audio, so we own the clock, and the real
`FrettedDiagramView` held 60 fps while re-rendering highlights every frame.

**A 3-semitone sample grid and 3 s samples.** A 3-semitone grid keeps every note within ±1
semitone of a real recording, so piano (the more sensitive voice) doesn't audibly shift in
brightness. A 4-semitone grid would save 25% of a download that is already under half a megabyte.
Trimming made the voice about 5× smaller (ready in 0.5 s on 4G instead of 2 s). The cost, a
long note fading early, matches how a plucked string decays.

**Stacks don't play yet.** Playing two sequences at once, or one after the other, is a real design
question (whose tempo? whose voice?) with no concrete content asking for it. Ignoring `playback`
inside a stack keeps the schema unchanged and leaves the choice open.

## Consequences

### Positive

- A diagram can demonstrate a scale, chord, arpeggio or lick with real rhythm and a real instrument
  sound, with highlights in step with what the student hears.
- One rhythm authored per diagram is reused everywhere the diagram is embedded. Each usage can
  still set its own tempo, voice, direction and looping.
- Students can slow a passage down without the author making a slower copy.
- Ear-training exercises become possible: an `image_recognition` stimulus can play hidden notes
  for the student to locate.
- A new timbre is a new voice (a folder of samples plus a seed row), not a new instrument or
  a copy of any diagram.
- Highlight sync doesn't depend on the audio library, and the Canvas layer ADR-027 anticipated is
  no longer needed.

### Negative / Trade-offs

- **Breaking schema change**, on already-shipped resources: `sequence_index` and `step_ms` are
  removed, `tuning` changes format, and `Instrument` gains `default_voice_id`. `motifpath-core`
  needs a migration that converts existing indices into steps and adds octaves to tunings, and
  both clients regenerate. There is no production data yet, so the migration only has to cover
  seeded data.
- **Authoring gets harder.** The diagram editor needs a sequence editor (steps, note values, rests,
  strums) on top of the position editor. The current editor derives `sequence_index` from the
  position order, and that shortcut is gone.
- **A young dependency.** smplr 1.0.1 has already shown three silent failure modes. We accept an
  exact pin, the adapter, and a regression test on every bump.
- **Asset and license upkeep.** Each voice is a set of files on S3/CloudFront plus a seed row, and
  CC-BY samples require visible attribution. Provenance of the first two voices still has to be
  confirmed.
- **Output latency is only compensated if the browser reports it.** Bluetooth outputs that don't
  report their 150–250 ms latency will show highlights early. This hasn't been checked on real
  Bluetooth headphones yet.
- A trimmed sample cuts a note longer than 3 s (a whole note below 80 BPM) short.

### Neutral

- Tempo and voice overrides live in `diagram_ref.playback`, next to `layers` and `styling`, so
  "how this diagram is shown and heard here" is still one object.
- A student's tempo choice is not stored, so it isn't progress data and emits no events.
- The Play control appears only where a diagram has a sequence and its usage sets `playback`.
  Every existing embed stays silent until an author opts in.
- **Revisit trigger:** content that needs grouped irregular meters, a pickup bar, dynamics,
  articulation, stacked playback, or notes longer than a voice's samples; a voice whose
  3-semitone repitch is audibly wrong; or a smplr regression that the adapter can't absorb.

## Related ADRs

- **ADR-028** (Prebuilt diagram content model) — this ADR replaces its `sequence_index` and
  `diagram_ref.playback`, and turns its timbre-less `Instrument` into a layout with a default voice.
- **ADR-027** (SVG rendering for layered diagrams) — playback highlights are one more SVG layer; the
  Canvas carve-out for audio-synced highlighting is dropped.
- **ADR-021** (Media storage) — voice samples use the same S3/MinIO + CloudFront stack.
- **ADR-032** (Diagram templates and copies) — "Save as" copies the sequence; flattening starts an
  empty one.
- **ADR-040** (Per-use labels, hiding and answer cells) — hidden positions sound during playback
  but are never drawn.

## Follow-up work (not part of this ADR)

- **Specs:** OpenAPI changes to `Diagram` (`tempo_bpm`, `time_signature`, `sequence`), `DiagramPosition`
  (drop `sequence_index`), `Instrument` (octave tuning, `default_voice_id`), `DiagramRef.playback`,
  and a new `Voice` schema with `GET /voices`. Gherkin for authoring a sequence (chord, rest,
  strum, tuplet, reused position, invalid position id, missing tempo), for voice/family
  validation, and for the pulse of simple, compound and irregular time signatures.
- **motifpath-core:** schema and migration, validation, voice seed data, and the voice sample
  upload in the seed/dev tooling.
- **motifpath-web (PB-71):** the smplr adapter and one-note test, the timeline (starting from the
  spike's `src/spike/audio/timeline.ts` and its 13 tests), the audio-clock highlight loop, the Play
  control with tempo slider, the sequence editor, and the credits page.
- Confirm sample provenance and attribution before production; check Bluetooth latency reporting.
- Delete the spike branch `spike/PB-70/diagram-audio` and its worktree once this ADR is accepted.

---

*This ADR was decided on 2026-09-28. To revise, create a new ADR with Status: Supersedes ADR-041.*
