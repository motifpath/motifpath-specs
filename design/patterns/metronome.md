# Pattern: the metronome (TempoControl) and the Tools area

**Source:** ADR-061 · ADR-046 (tempo ladder) · MOT-156 (Figma "Practice Shell — flows", row 19
and its Dark · pt-BR copy; decisions M1–M11)

## When

Use it wherever a student plays along with a click: a play-along take, chord or root changes,
the song chart reader, a lesson's diagram player, a drill that plays a progression, and the
Metronome tool itself. A surface hides the controls it doesn't need; it never builds another
metronome.

## Why

One component everywhere means one interaction to learn. A change to it reaches every place it
is used (M5). Its choices stay out of the way until the student asks for them, because a
practice screen needs its space for the music (M6).

## How

```text
compact row (every surface):
┌──────────────────────────────────────────┐
│ (♪̸) ──●──────────────  96 BPM   (♪)     │  toggle · slider · BPM · note value
└──────────────────────────────────────────┘
                                   │ tap
                                   ▼
                     ┌─────────────────────────┐
                     │ NOTES                   │  popover: icons, the chosen one ringed
                     │ ♩  [♫]  ♫³  ♬           │
                     │ Eighths · 2 notes a beat│
                     └─────────────────────────┘

Metronome tool page (inside the Practice Shell):
┌──────────────────────────────────────────┐
│ ←  Metronome                             │
│        [4/4 ▾]   ●  ○  ○  ○              │  the bar: tap the fraction for presets + − / +
│ (♪̸) ──●──────────────  96 BPM   (♩)     │  the same compact row
├──────────────────────────────────────────┤
│                 Start                    │
└──────────────────────────────────────────┘
```

- **The row (TempoControl):**
  - the metronome toggle;
  - the slider in 5 BPM steps up to 300 BPM;
  - the BPM, where a tap types an exact value;
  - when the surface allows it, the current **note value** as an icon (Show note value).
  The best clean and goal ticks show only where a ladder exists (play-alongs).
- **Note values are icons:** halves, quarters, eighths, triplets, sixteenths, quintuplets,
  sextuplets and 32nds.
  - A tap on the current value opens a popover anchored to it.
  - Exercises and drills offer quarters, eighths, triplets and sixteenths. The tool offers
    every value.
  - The chosen one is ringed and named in words ("Eighths · 2 notes a beat"), and each icon's
    accessible name is that word.
  - Quarters is the default.
- **A note value is a speed factor** on the music as written (ADR-061): quarters ×1, eighths ×2,
  triplets ×3, sixteenths ×4, halves ×½. The click stays on the beat.
  - A lick or a progression in eighths plays twice as fast. A progression changes chord twice
    a bar.
  - In the tool, the factor is the clicks per beat, with the beat's click louder.
- **Popovers:**
  - a choice applies at once and closes the popover;
  - a tap outside, or Esc, closes it unchanged;
  - it never covers the button that opened it;
  - it is the same on every size class (M11).
- **The Metronome tool:**
  - **Tools** sits in the Practice Shell header's options slot: a wrench with the accessible
    name "Tools", on the session setup only, never during a run (M1, M2).
  - It opens a sheet on Compact and an anchored menu on Medium and Expanded. There is one row
    per tool, and no placeholder rows (M3).
  - The Metronome page is pushed inside the shell, with a back arrow. Leaving the page stops
    the click, and nothing on it is tracked (M4).
  - Under the header sits **the bar**: the time signature as a button (the fraction) beside the
    beat dots. The downbeat is the larger dot, so the bar reads without colour, and the
    sounding beat is lit.
  - A tap on the fraction shows the presets (2/4, 3/4, 4/4, 6/8, 12/8) plus − / + for the beats
    (1–12) and the beat note (/2, /4, /8). There is no "Other": the steppers reach every bar
    (M7). Compound bars (6/8, 12/8) accent each dotted-quarter group.
  - Every control stays live while it plays, and a change applies from the next beat.
- **What each surface shows (M10):**

  | Surface | Tempo | Note value | Time signature |
  |---|---|---|---|
  | Metronome tool | yes | every value | yes, on demand |
  | Play-along take, lesson diagram player | yes | the four suggested | set by the diagram (shown locked) |
  | Progression playback (hear drills, guide tones) | the level's tempo, changeable | the four suggested | 4/4, one chord a bar (locked) |
  | Chord / root changes, song chart reader | yes | — | — |
  | Single-chord playback | — | — | — |

- **Tempos read as played:** "Best clean: 80 BPM in eighths". The ladder compares effective
  speed, so that take counts as 160 in quarters (ADR-061). Choosing another note value keeps
  the effective speed for the next take, rounded down to the 5 BPM grid.

### Size classes

The Metronome page follows the shell: one centred column, 560 px at most, on Medium and
Expanded, with the action bar at the bottom (`session.md`). Popovers stay anchored to their
button. Tools is an anchored menu like the account menu (`overlays.md`).

## Do not

- Build a second metronome UI for a surface. Hide controls of `TempoControl` instead.
- Keep note values or time signatures always visible on a practice screen.
- Name a note value only by its icon. The chosen value is also named in words.
- Track anything from the Metronome tool, or keep it clicking after the student leaves it.
- Show Tools during a run.
