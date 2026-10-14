# Progression catalog

The common chord progressions, by number, that every MotifPath environment starts with,
production included. Harmony and ear drills (`practice-drills.md`, drill families v2) ask about
them, and take their distractors from them. The data lives in `progressions.yaml`; this page
holds the rules it follows and what an installation must guarantee.

## Progressions

- **By number, never by key.** A progression is a list of numerals, one bar each, in a major key:
  `I ii iii IV V vi vii°`, with a `7` for a dominant seventh (`I7`). A drill picks the key; the
  chords come from the chord catalog (`chord-voicings.md`).
- **Four bars or a full form.** The pop and cadence progressions are four bars (a three-chord
  cadence holds its last chord: `ii–V–I–I`). The blues is its 12 bars.
- **Nodes.** Every progression practises `common-progressions`; cadences add `cadences`, and the
  blues adds `blues-form`. A progression drill rolls up to its template's nodes and to these.
- **Names** say the numbers, with a common nickname when there is one ("I–V–vi–IV (pop)"). A name
  never says a key, so a name shown as an option never gives a chord away.
- v1 holds 10 progressions, major keys only. Minor-key progressions come with
  `minor-key-harmony`.

## Confusable progressions

- Each progression lists the progressions a learner mistakes it for: the same chords in another
  order (`I–V–vi–IV` and `I–vi–IV–V`), or one chord swapped for its neighbour with the same
  function (`ii–V–I` and `IV–V–I`).
- **Symmetric:** when A lists B, B lists A.
- **Distinguishable:** a confusable pair never sounds the same in some key. A rotation that is the
  same chords in its relative minor (`vi–IV–I–V` against a minor `i–VI–III–VII`) is not listed.
- A progression question offers the asked progression and its confusable ones first, then others
  of the same length, so no option can be ruled out by its length.
- Drills interleave confusable progressions within a session on purpose (ADR-057).

## Acceptance

- Installing on an empty database twice gives identical IDs.
- Every numeral is one of the major key's numerals, with an optional `7`.
- Every `confusable` key exists, and every pair is listed both ways.
- Every `nodes` key exists in the knowledge map.
- Installing aborts if a row with a fixed ID already exists with different data.
