# Chord catalog

The chords MotifPath knows and the fingerings it offers for them, on standard six-string guitar
(strings numbered 1, E4, through 6, E2; tuning E2 A2 D3 G3 B3 E4). The contents are
`chord-voicings.yaml`: chord formulas, movable shape templates and hand-authored open voicings.
How a chord symbol is read is pinned separately, by the parser golden cases in
`golden/chord-symbols/`.

Generation is deterministic, offline and validated, as for the basic guitar catalog
(`basic-guitar-diagrams.md`). The generator in motifpath-core reads the YAML, materializes every
voicing as a concrete diagram, runs the musical validator on each one, and writes frozen SQL into
the reference-data migration. A voicing that fails validation aborts the build. Nothing is
skipped silently, and no voicing is transposed at render time.

## Chords

- **Definitions.** Every quality in `formulas` is defined on each of the 12 `roots`, spelled as
  listed (C, Db, D, Eb, E, F, F#, G, Ab, A, Bb, B): 28 qualities × 12 roots = 336 chords. Each
  slash chord that an open voicing plays (`D/F#`, `C/G`, `G/B`, `Am/G`, `C/E`) is also defined. No
  other slash chord exists in v1. A search for one offers the chord without its bass
  (`searchChords`).
- **Canonical symbol** is the root, the quality's canonical suffix (`golden/chord-symbols/README.md`)
  and, for a slash chord, `/` and the bass. **Aliases** are the parser's other accepted suffixes
  on the same root, with `♭`/`♯` spellings of the root.
- **Formula.** The quality's `intervals`, in order. Compound tones keep their compound code (`9`,
  `11`, `13`), even though they share a pitch class with `2`, `4` and `6`.
- **Omittable** lists the tones a voicing may leave out. Triads, power chords, sus chords,
  add chords and chords defined by an altered fifth omit nothing.

## The musical validator

A voicing enters the catalog only if all of these hold. The same rules run in the generator and
in the Go domain constructor, so a payload the domain refuses never ships.

1. **Tuning.** The voicing's tuning is its diagram's layout instrument tuning: `E2-A2-D3-G3-B3-E4`.
2. **Pitch classes.** Each sounded string sounds its open pitch raised by its fret. The set of
   sounded pitch classes, with doubled tones allowed, must equal the formula's pitch classes less
   the voicing's omitted intervals. For a slash chord, the bass's pitch class is also allowed.
3. **Root.** The root is always sounded. It is never omittable.
4. **Omissions.** The omitted intervals are exactly the formula tones the voicing doesn't sound,
   and every one of them is in the quality's `omittable` list. A hand-authored voicing declares
   them (`omits`), and the declaration must match. A template voicing has them computed.
5. **Slash bass.** For a slash chord, the lowest sounded string sounds the bass.
6. **Playable range.** Every fret is between 0 and 15, and a template voicing has no open
   strings.
7. **Distinct.** No two voicings of one chord sound the same frets on the same strings.

An "Am" voicing that sounds an F# fails rule 2 and never reaches a learner.

## Templates

A template is a movable shape: frets as offsets from the root fret on its `root_string`, which
holds the root at offset 0.

- **Transposition.** For each of the 12 roots, the root fret is the lowest fret, at least 1, where
  the root string sounds the root and every other offset lands on fret 1 or above. If the shape's
  highest fret is then above 15, the template is not materialized for that root. In v1 this
  happens only to `add-9-5th-string` and `minor-add-9-5th-string` on A, whose chords have open
  voicings instead.
- A template never produces a fret-0 copy of itself. The open version of a shape is a
  hand-authored open voicing, which can use open strings the barre shape can't.
- `is_movable` is true for every template voicing and false for every open voicing.
- `technique_tags` are the template's own tags. `fret_window` is the lowest and highest fretted
  fret.

## Open voicings

Written one by one, at absolute frets. `chord` is a canonical symbol of a defined chord. An open
voicing's `shape_family` is `open`, and its `technique_tags` are `open` plus any listed.

## Generated diagrams

Each voicing is one basic diagram with purpose `chord_voicing`, owned by the `system:catalog`
profile, available on `guitar` and `electric-guitar` (layout instrument `guitar`), as for the basic
guitar catalog.

- **Names**, in `en` and `pt_BR`: the canonical symbol, then the shape.
  - Open voicings: "Am — open" / "Am — aberto".
  - E-, A- and D-shape templates: "Bbmaj7 — A shape, fret 1" / "Bbmaj7 — forma de Lá, casa 1";
    "F — D shape, fret 3" / "F — forma de Ré, casa 3".
  - Other templates: "Cm7b5 — root on string 5, fret 3" / "Cm7b5 — tônica na 5ª corda, casa 3".
- **Root note** is the chord's root as the catalog spells it, and `mode` is null.
- **Positions**, one per sounded string, each with the formula interval it sounds, or for a slash
  bass outside the formula, the interval code of its distance above the root (the bass of `Am/G`
  is `b7`).
  - Note names are spelled from the root by interval number, so the third of F#maj7 is A# and
    its seventh is E#.
  - A muted string has no position.
  - Labels show intervals.
- **Playbacks**, as for CAGED grips: "Strum down" / "Batida para baixo", the default (one
  whole-note step of every position, strummed down), and "Arpeggio" / "Arpejo" (quarter notes
  from the lowest pitch to the highest), both at 60 BPM in 4/4.
- **Classification:** concept `chords`, skill `chord-diagrams`, plus:

  | Qualities | Skill |
  |---|---|
  | major | `major-triads` |
  | minor | `minor-triads` |
  | power | `power-chord` |
  | diminished, augmented | `diminished-augmented-triads` |
  | sus2, sus4, dominant_7_sus4, add_9, minor_add_9 | `sus-add-chords` |
  | major_6, minor_6 | `sixth-ninth-chords` |
  | dominant_7, dominant_7_flat_5, dominant_7_sharp_5, dominant_7_flat_9, dominant_7_sharp_9 | `dominant-seventh` |
  | major_7, minor_7, minor_major_7, half_diminished_7 | `seventh-chords` |
  | diminished_7 | `diminished-seventh` |
  | dominant_9, major_9, minor_9, dominant_11, minor_11, dominant_13 | `extensions` |

  Open voicings also take `open-chord-shapes`, voicings tagged `barre` take
  `barre-chord-shapes`, and slash chords take `slash-chords`.

## Practice

A voicing's diagram plays like a play-along but is not a practice item of its own.
- Knowledge levels and coverage don't count it.
- Practice sessions don't offer it.
- It is practised only where content embeds it.

Any change to this needs a decision of its own, since counting 538 unpractised voicings would lower
every student's standing on the chord skills.

## Ranking

Within a chord, `recommended_rank` orders voicings by:
1. open voicings first;
2. then by difficulty, beginner first;
3. then by lowest fret of the window;
4. then by key.

Ranks run 1, 2, 3… with no gaps.

## IDs

UUID v5 under the catalog namespace (`reference-data.md`):

| Rows | Name hashed |
|---|---|
| Chord definition | `chord-definition/<canonical symbol>` |
| Chord voicing (template) | `chord-voicing/<template key>/<root>`; the template key is also the voicing's `template_key`. Templates aren't rows of their own. |
| Chord voicing (open) | `chord-voicing/<open voicing key>` |
| Voicing diagram | `chord-diagram/<voicing name hashed above>` |
| Voicing position | `chord-diagram/<voicing name hashed above>/string-<n>` |
| Voicing playback | `chord-diagram/<voicing name hashed above>/playback/<strum-down \| arpeggio>`, as for CAGED grips |

## Changing the catalog

- **Review.** Every change to `chord-voicings.yaml` needs approval from an admin other than its
  author, who checks the formulas, each new template or open voicing, and the generated diagrams.
- **Before production,** the migration is regenerated in place.
- **From the first production install,** migrations are append-only. A voicing is never deleted:
  withdrawing it sets `catalog_status` to `withdrawn`, which keeps every embed of its diagram
  working while the catalog stops offering it. A corrected fingering is a new voicing, and the old
  one is withdrawn.

## Coverage in v1

v1 has 42 templates and 36 open voicings, which give 538 voicings across 341 chords. Every one of
the 336 non-slash chords has at least one voicing.

- The E-shape (root on string 6) and A-shape (root on string 5) families cover the common triads
  and sevenths.
- The D-shape family (root on string 4) covers major, minor, 7, maj7, m7, sus2 and sus4.
- The other qualities have one root-on-string-5 grip each.

Shell and drop-2/drop-3 families for the seventh, extended and altered chords, and more inversions,
are later additions.

## Acceptance

- Every chord in `formulas` × `roots` exists and has at least one active voicing.
- Every voicing passes the musical validator. A fixture "Am" that sounds F# fails the build.
- IDs and serialized output repeat exactly across runs and environments.
- `listDiagrams` without `purpose` returns the same diagrams and total as before the catalog is
  installed.
- The generated payload passes the Go domain constructors before release.
