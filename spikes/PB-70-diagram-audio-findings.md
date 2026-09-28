# Spike Findings: PB-70 — Diagram audio playback

**Task:** PB-70 (Notion Research Task, unblocks PB-71 "Diagram sound")
**Date:** 2026-09-28
**Author:** Gilson
**ADR:** input to the follow-up ADR amending ADR-028 (prebuilt diagram content model); revisits a
note in ADR-027/ADR-028
**Spike branch:** `motifpath-web@spike/PB-70/diagram-audio` (throwaway, not for merge; delete once
the ADR lands)

---

## Summary

I built a scratch page (a separate Vite entry, `spike-audio.html`) that plays a fretted diagram
through four engines and rings each marker of the **real `FrettedDiagramView`** while it sounds.
The only change to that component is one spike-only `activePositionIds` prop. The four engines:

- Tone.js 15.1.22 `Sampler`
- smplr 1.0.1 `Sampler`
- a ~60-line plain Web Audio sampler
- Tone's Karplus-Strong `PluckSynth`, the zero-download option

Test material: two fixture diagrams (A minor pentatonic box, open A minor), played as eighth-note
runs, mixed rhythms (dotted, triplets, sixteenths, rests), down/up strums followed by an arpeggio,
and an 8-bar sixteenth-note run for drift. I drove it with Playwright in headless Chrome, with CPU
throttling (4×, 6×) and network throttling (4G, 3G). The samples are tonejs-instruments' acoustic
guitar (fully chromatic E2–D5, so every repitched note can be compared with a real recording of
that note) and piano (octaves 2–5).

**Recommendations:**

1. **Adopt smplr** (1.0.1, pinned exactly), behind one small adapter of our own that applies its
   three workarounds (Finding 4) and is loaded only when a diagram plays. It sounded best in
   Gilson's listening test and is 21 kB gzip, against 60 kB for Tone.js. Use it only to *play*
   notes: never use its `onStart` callback for visuals (Finding 1).
2. **Drive highlights from the audio output clock in a `requestAnimationFrame` loop.** Never use
   `setTimeout` or library callbacks. Measured error: 0 to +17 ms (within one frame), p95 ≤ 29 ms
   under 6× CPU throttling, and no drift.
3. **SVG is enough.** The real `FrettedDiagramView` held 60 fps with zero long frames during
   playback. The Canvas note in ADR-027/028 for audio-synced highlighting can be dropped.
4. **Sample every 3 semitones.** With nearest-sample choice, a repitch is then never more than
   **±1 semitone**. Store samples **trimmed to about 3 s, mono, MP3 96 kbps**, keyed by MIDI pitch:
   a guitar voice is 12 files and 430 kB, ready in 0.5 s on 4G and 2.5 s on 3G.
5. **Data model:** the tempo math holds. But one `sequence_index` per position can't express a
   chord that is strummed and then arpeggiated, and `Instrument.tuning` has no octaves (Finding 7).

Listening and iPhone results are in "Manual check results" at the end.

| Question (from the PB-70 card) | Answer |
|---|---|
| 1. Library | smplr, pinned, behind an adapter that applies its three workarounds. Best sound by ear; 21 kB, loaded on demand |
| 2. Sample grid | Every 3 semitones means at most ±1 of repitch. Every 4 (±2) is objectively close; decide by ear |
| 3. Storage & size | Trimmed 3 s mono MP3 96k: guitar 430 kB (12 files), piano 574 kB (16). Key by MIDI pitch; load the whole voice on first play |
| 4. Source & license | tonejs-instruments, CC-BY 3.0 (attribution required). Provenance of each voice still to confirm |
| 5. Sync | Audio-clock rAF: 0–17 ms typical, no drift. Callbacks are 33–230 ms early. SVG is fine |
| 6. Polyphony & strum | 5-voice strums at 200 BPM under 6× throttle: fine. Played well on an iPhone |
| 7. Tempo model | Validated. It needs explicit steps (reuse of positions), rests, a beat unit and a gate |
| 8. Mobile | Resume the context inside the Play tap (done). No Karplus-Strong fallback; show a loading state instead. iOS still to check |

---

## Finding 1 — Highlight sync: use the audio clock; library callbacks are early

Every run scheduled all notes up front at `startAt + note.time` (context seconds). The page then
recorded when each marker's ring first appeared and compared it with when the note became
**audible**: context time mapped through `AudioContext.getOutputTimestamp()`, which includes
output latency.

**Error of the highlight against the audible note** (positive = ring appears after the sound):

| Highlight driven by | Tone.js | smplr | Plain Web Audio |
|---|---|---|---|
| **Audio clock, read each frame (rAF)** | **p50 0–16 ms, p95 ≤ 29 ms** | **p50 0.5–11 ms, p95 ≤ 27 ms** | **p50 7–12 ms, p95 ≤ 28 ms** |
| Library callback (`Tone.Draw` / smplr `onStart`) | −33 to −44 ms (early) | **−166 to −242 ms (early)** | none: it has no callback |

- `Tone.Draw` fires when `currentTime` reaches the note, which ignores output latency. The ring
  therefore always appears one output latency early: ~30–45 ms here, and far more over Bluetooth.
- smplr's scheduler dispatches (and fires `onStart`) up to its 200 ms lookahead before the note.
  That is documented behavior, and it makes the callback unusable for visuals.
- The audio-clock approach needs neither. Each frame reads
  `ctx.getOutputTimestamp()` → "context time now audible", and rings whichever notes span it.
  The design is library-agnostic and works identically for every engine above.
- **No drift.** Over an 8-bar sixteenth-note run (128 notes, 180–200 BPM, ~10 s), the error stayed
  flat from the first note to the last: p5–p95 spread under 1 ms at 1×, and within one frame under
  throttling.
- The audio itself is exact. A probe on `AudioBufferSourceNode.prototype.start` confirmed that
  every engine passed the scheduled times through unchanged (**0.0 ms** error, all runs).
- **Gotcha:** `getOutputTimestamp()` is stale for the first few frames after a context resumes.
  Mapping audio time to screen time once at start gave a false 23–200 ms offset. Read it every
  frame instead.

For scale: broadcast guidance (ITU-R BT.1359) puts the detectability threshold for sound leading
picture at about 45 ms. A ring at most one frame late (sound leading by ≤ 17 ms, ≤ 29 ms at p95)
is inside it.

**SVG is enough.** With the real `FrettedDiagramView` re-rendering its rings every frame, frame
time stayed at 16.7 ms: zero long frames (> 25 ms) at 1× and 4× CPU throttling, and one per run at
6× (at scheduling time, not during playback). This revisits the ADR-027/028 note that routed
audio-synced highlighting to Canvas. We generate the audio, so we own the clock, and SVG keeps up.

## Finding 2 — Sample grid: "every N semitones" means a repitch of at most ⌊N/2⌋

Both libraries and the in-house sampler pick the **nearest** recorded sample. A grid step of 3
therefore never repitches more than ±1 semitone, and a step of 4 never more than ±2.

Because the guitar set is fully chromatic, I could repitch each recording onto its neighbours and
compare the result with the real recording of that note (offline render, first second after the
attack, 80 Hz–8 kHz):

| Shift (semitones) | Guitar: spectral distance to real | Guitar: brightness | Guitar: decay | Piano: spectral distance | Piano: brightness |
|---|---|---|---|---|---|
| ±1 | 8.4–8.5 dB | 1.00–1.02× | 1.07–1.09× | 8.6–8.7 dB | 0.98–1.05× |
| ±2 | 9.7–10.0 dB | 1.01–1.05× | 1.07–1.14× | 10.6–10.8 dB | 0.96–1.10× |
| ±3 | 10.3–10.7 dB | 1.01–1.06× | 1.08–1.15× | 11.3–11.9 dB | 0.93–1.14× |
| ±4 | 10.9–11.5 dB | 1.02–1.08× | 1.09–1.19× | 11.9–12.5 dB | 0.91–1.18× |

How to read this:

- Even a ±1 shift is 8.5 dB from the real note. That baseline is **take-to-take variation**: every
  recorded note is a separate pluck. Repitching adds only about 1.3 dB more at ±2, so the curve
  has no cliff.
- Guitar timbre barely moves (≤ 6% brighter at +3). Piano brightness shifts about 5% per semitone,
  the "chipmunk" effect. That makes piano the more sensitive voice.
- **Recommendation:** a 3-semitone grid (±1) for both voices, which is conservative. A 4-semitone
  grid (±2) saves 25% of the download and is objectively close for guitar. Let the blind A/B on
  the spike page decide (see "Manual checks left").

## Finding 3 — Storage & size: trim the samples; the originals are too long

The tonejs-instruments files are 192 kbps mono and last 4.5–11.5 s. Trimming to 3 s plus a 0.6 s
fade and re-encoding gives:

| Guitar, E2–D5 | Files | Original MP3 192k | Trimmed MP3 96k | Trimmed Opus 48k |
|---|---|---|---|---|
| every semitone | 35 | 6.3 MB | 1.26 MB | 723 kB |
| every 2 | 18 | 3.2 MB | 645 kB | 371 kB |
| **every 3** | **12** | 2.1 MB | **430 kB** | 249 kB |
| every 4 | 9 | 1.5 MB | 323 kB | 185 kB |

Piano, C2–B5, every 3: 16 files, 574 kB MP3, 374 kB Opus.

**Time until the whole voice is ready** (all files fetched in parallel, cache disabled):

| Voice (every 3) | 4G | 3G |
|---|---|---|
| Guitar, Opus | 0.34 s | 1.5 s |
| **Guitar, MP3** | **0.51 s** | **2.5 s** |
| Piano, MP3 | 0.69 s | 3.3 s |
| Guitar, original MP3 | 2.0 s | 11.0 s |

Recommendations for the ADR:

- **Key samples by MIDI pitch** under a voice, e.g. `/audio/voices/{voice_id}/{midi}.mp3`, plus a
  small manifest listing the pitches available. Host them on the ADR-021 stack (S3/MinIO +
  CloudFront) with immutable caching.
- **Load the whole voice on first play; don't load per diagram.** A pentatonic box already needs
  10 of the 12 guitar samples, so loading per diagram saves little and complicates caching.
  Prefetch when a diagram with playback scrolls into view.
- **MP3 is the baseline:** it decodes everywhere. Opus is 40% smaller but has to be verified on
  iOS Safari first (manual check).
- **Trade-off of trimming:** a note longer than the sample stops early. At 60 BPM a whole note
  lasts 4 s, longer than a 3 s sample. Either trim to ~4 s (about +30% size) or cap note length.
  Decide in the ADR.

## Finding 4 — Library comparison

| | Tone.js 15.1.22 | smplr 1.0.1 | In-house (plain Web Audio) |
|---|---|---|---|
| Bundle (min + gzip) | 61 kB. **Doesn't tree-shake:** `Sampler` alone is still 59.5 kB | 20.7 kB | **0.5 kB** |
| Scheduling accuracy | exact | exact | exact |
| Main thread to schedule 128 notes, 6× throttle | **100 ms** (blocks a frame) | 2.6 ms | 23 ms |
| Usable note callback for visuals | No (ignores output latency) | No (200 ms early) | Not needed |
| Traps found | its `rawContext` is a wrapper without `getOutputTimestamp`; the spike gives it a native `AudioContext` | three, all **silent** (below) | none |
| License | MIT | MIT | ours |

The smplr 1.0.1 traps, each of which makes it play **nothing, with no error surfaced**, because
the throw happens inside its scheduler:

1. Without an explicit `detune: 0`, every note throws "non-finite AudioParam value".
2. Numeric MIDI keys (`{ 45: url }`) load but never sound, and so do AudioBuffer values under
   numeric keys. Only note-name keys (`{ A2: url }`) work.
3. A note given a `duration` throws in `Voice.stop` unless `ampRelease` is passed explicitly.

smplr 1.0 is a recent major rewrite, and these traps are a maturity signal. That is why the
recommendation is an exact version pin and an adapter: the adapter always passes `detune: 0`,
note-name keys and `ampRelease`, and a test that plays one note offline catches a regression when
we bump the version. Tone is mature but large, and we'd use about 2% of it.

**The in-house sampler was not a fair comparison, so its ear test result doesn't count against
the approach.** After the listening test I traced its two faults to the spike's own code:

- **Guitar and piano mixed:** its `load()` never cleared previously loaded buffers. After a voice
  switch, notes played whichever recording was nearest in pitch, whether guitar or piano.
- **Poor timbre:** every voice played at full gain, with no master volume. Rendered offline, a
  5-string strum peaked at **1.28, clipping 109 samples**. smplr's peak for the same strum is
  **0.35**, about 9 dB of headroom.

Both faults are fixable, but we'd then own mixing and envelopes, the very part the spike just got
wrong. For about 20 kB (loaded on demand), smplr is the better trade.

## Finding 5 — Polyphony and strum

- 5-voice strums (down, up, down) at 200 BPM with a 15 ms strum, under 4× and 6× CPU throttling:
  highlight error stayed at p95 ≤ 28 ms, with no long frames during playback, on every engine.
- A strum is just per-voice onset offsets in the timeline: down = lowest pitch first, up = highest
  first. **15–20 ms per string** sounds natural; confirm by ear.
- Not measurable headless: audio-thread underruns (crackles) on a real mid-range phone. See
  "Manual checks left".

## Finding 6 — Mobile unlock and first play

- The spike creates or resumes the `AudioContext` **inside the Play tap handler**, which is the
  pattern iOS Safari and Chrome's autoplay policy require. Headless Chrome ran with autoplay
  allowed, so this still has to be verified on an iPhone.
- **Karplus-Strong fallback: not recommended.** Tone's `PluckSynth` works, sync included, but
  pulls in all 60 kB of Tone, and it sounds nothing like the sampled voice it would stand in for.
  Samples are ready in ~0.5 s on 4G, so a loading state on the Play button (plus prefetch on
  scroll-in) is simpler and more honest. If a zero-download voice is ever wanted, an in-house
  Karplus-Strong is about 20 lines.
- `outputLatency` in headless Chrome is simulated (16–48 ms). Real Bluetooth output adds 150–250
  ms. The audio-clock approach compensates for it **only if the browser reports it** through
  `getOutputTimestamp` / `outputLatency`. The spike falls back to `currentTime − baseLatency`. Check
  both on iOS Safari.

## Finding 7 — Tempo and data model (input for the ADR amending ADR-028)

The timeline math is covered by 13 unit tests on the spike branch
(`src/spike/audio/__tests__/timeline.spec.ts`):

- **Duration = note value × (60 / BPM) / beat unit.** A note value is a fraction of a whole note
  (`{num, den}`): 1/4 quarter, 3/8 dotted quarter, 1/12 eighth-note triplet (three fill exactly
  one beat), 1/16 sixteenth. The beat unit defaults to a quarter; a 3/8 beat unit gives compound
  meters (6/8 counted in two) the right BPM.
- **A rest is a step with a value and no positions.** It takes time and sounds nothing.
- **Gate** (sounding fraction of the value, e.g. 0.95 legato, 0.5 staccato) is separate from the
  note value. It answers the open "legato vs spacing" question.
- **Chords = several positions in one step**, sounding together or strummed.

Two model gaps the ADR has to close:

1. **`sequence_index` per position can't express reuse.** The spike's Am pattern strums the chord,
   then arpeggiates the same five positions. With one index per position, a position can appear in
   only one step. Proposal: the sequence lives on the Diagram as an ordered list of steps, each
   with `position_ids[]` (empty for a rest), a note value, and an optional strum direction. This
   replaces `DiagramPosition.sequence_index`. `DiagramRef.playback` then carries only the BPM
   override (replacing `step_ms`), plus direction and looping.
2. **`Instrument.tuning` has no octaves** (`["E","A","D","G","B","E"]`), so a fretted position's
   pitch can't be computed. Pitch is `tuning[string_count − string] + fret` (string 1 = highest,
   tuning lowest first), so the tuning must carry octaves: `["E2","A2","D3","G3","B3","E4"]`.
   Keyboard positions already do (`key: "C4"`).

The existing proposal still stands: a timbre (sample voice) chosen separately from the instrument
*layout*, so guitar and electric guitar share a diagram, and a BPM default on the diagram that the
DiagramRef and then the student can override.

## Manual check results (Gilson, 2026-09-28)

- **Sound:** smplr sounded best. The in-house sampler sounded poor and sometimes mixed piano and
  guitar, which traces to two spike bugs (Finding 4).
- **Timing:** acceptable on all the engines tested.
- **iPhone (Safari):** everything worked well.

Not reported separately, and to settle in the ADR or during PB-71: 3- vs 4-semitone grid (keep 3
for now), trimmed vs original files, strum width, Bluetooth headphones, and the samples' license
provenance.

## How to rerun the spike

Run the spike locally:

```
git switch spike/PB-70/diagram-audio && src/spike/audio/fetch-samples.sh   # needs ffmpeg (nix shell nixpkgs#ffmpeg-headless)
npm run dev -- --host                                                         # open /spike-audio.html; --host for the phone
```

1. **Blind A/B** (the "Repitch A/B" section): does a sample repitched ±1 and ±2 sound acceptable
   next to the real recording, on guitar and on piano? This decides between a 3- and a 4-semitone
   grid.
2. **Trimmed vs original, Opus vs MP3:** are the 3 s cut and the fade audible on long notes?
3. **Strum feel:** is 15–20 ms per string natural?
4. **iPhone (Safari):** the first tap unlocks audio; whether the ring/silent switch mutes it (if
   so, evaluate the Audio Session API); whether Opus decodes; whether highlights line up (i.e.
   whether `getOutputTimestamp`/`outputLatency` are reported); no crackles on the 200 BPM strum.
5. **Bluetooth headphones:** are the highlights still in sync?
6. **License provenance:** confirm the upstream source of the tonejs-instruments guitar and piano
   samples behind their CC-BY 3.0 label, and plan the attribution (credits page).
