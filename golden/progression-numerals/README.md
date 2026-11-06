# Progression numeral parser golden cases

Language-neutral cases that pin how a progression numeral, as an admin writes it, is read in a
mode. The server (Go, in motifpath-core: `createProgression`) and the web client (TypeScript, in
motifpath-web: the create form's instant feedback and its *borrowed* marks) both run every case
here, so an admin never sees a numeral the server reads differently.

## Files

- `<parser>.v<version>.json`: one file per parser version, for example `progression_numeral.v1.json`.
  A file is never edited once a consumer ships that version, except to add cases. A rule change
  is a new version in a new file.
- `schema.json`: the JSON Schema every case file follows.

Each case is an `input`, the `mode` it is read in, and the `expected` result: `parsed` with the
stored `numeral`, its `root_semitones`, `quality` and whether it is `borrowed`, or `unparsed`.

## Rules

A numeral is read exactly as sent. Nothing is trimmed, and any other character makes it
`unparsed`.

1. **Accidental.** At most one, first: `♭` or `b`, `♯` or `#`.
2. **Root.** `I`, `II`, `III`, `IV`, `V`, `VI` or `VII`, all upper case or all lower case.
3. **Quality.** The case and the suffix give it:

   | Root written | Suffix | Quality |
   |---|---|---|
   | upper case | none | major |
   | upper case | `7` | dominant_7 |
   | upper case | `maj7` | major_7 |
   | lower case | none | minor |
   | lower case | `7` | minor_7 |
   | lower case | `°` or `o` | diminished |
   | lower case | `ø7` or `h7` | half_diminished_7 |
   | lower case | `°7` or `o7` | diminished_7 |

   Any other suffix, or `°` after an upper-case root, is `unparsed`.
4. **Stored numeral.** The input with `♭`, `♯`, `°` and `ø` in place of `b`, `#`, `o` and `h`.
5. **Root semitones.** The root's degree of the major scale above the tonic (I = 0, II = 2,
   III = 4, IV = 5, V = 7, VI = 9, VII = 11), one lower for `♭` and one higher for `♯`, wrapping
   around 12. The mode doesn't change it: `♭III` is 3 in both modes.
6. **Borrowed.** A numeral is borrowed when its root and triad are not among its mode's diatonic
   chords. A seventh doesn't change the triad: `V7` and `I7` count as `V` and `I`, `viiø7` and
   `vii°7` as `vii°`. The diatonic chords are:

   | Mode | Diatonic |
   |---|---|
   | major | `I ii iii IV V vi vii°` |
   | minor | `i ii° ♭III iv v ♭VI ♭VII`, plus harmonic minor's `V vii°` |

`o` and `h` are safe as aliases here, unlike in chord symbols, because a numeral never starts
with a note name.
