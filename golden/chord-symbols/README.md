# Chord symbol parser golden cases

Language-neutral cases that pin how a chord symbol, as an author writes it, is read. The server
(Go, in motifpath-core: `searchChords` and chart validation) and the web client (TypeScript, in
motifpath-web: the chart editor's instant feedback) both run every case here, so an author never
sees a chord the server reads differently.

## Files

- `<parser>.v<version>.json`: one file per parser version, for example `chord_symbol.v1.json`.
  A file is never edited once a consumer ships that version, except to add cases. A rule change
  is a new version in a new file.
- `schema.json`: the JSON Schema every case file follows.

Each case is an `input` and the `expected` result: `parsed` with a `ParsedChordSymbol`
(`openapi/core-domain-service.yaml`), `unparsed` with a `warning`, or `no_chord`.

## Rules

A symbol is read exactly as sent. Nothing is trimmed, and any whitespace makes it unparsed.

1. **No chord.** `N.C.` and `NC` are `no_chord`. Nothing else is.
2. **Root.** An uppercase letter `A`–`G`, then at most one accidental: `b` or `♭`, `#` or `♯`.
   If an accidental follows the letter, it belongs to the root, so `Cb5` is a C♭ power chord and
   `Bbb` is B♭ followed by an unknown suffix. A lowercase letter, `H` or a missing root makes
   the symbol `unparsed_symbol`.
3. **Slash bass.** Everything after the first `/` is the bass. It must be a note under the same
   rule as the root, with nothing after it, or the symbol is `unparsed_symbol`. A bass with the
   root's own pitch class is dropped (`C/C` reads as `C`).
4. **Quality.** What is left between the root and the slash must be exactly one of the suffixes
   below. `♭` and `♯` count as `b` and `#`. Matching is case-sensitive (`M7` is major seventh,
   `m7` is minor seventh). Anything else is `unsupported_quality`.
5. **Canonical symbol.** The root as written (in ASCII), the quality's canonical suffix, then
   `/` and the bass as written, if there is one.
6. **Pitch classes.** C = 0 through B = 11. The accidental moves the letter's pitch class by one,
   wrapping around (C♭ = 11, E# = 5). The catalog finds a chord by pitch class, so `A#m` finds
   the catalog's `Bbm` and the author's spelling is kept for display.

| Quality | Canonical suffix | Also accepted |
|---|---|---|
| major | (none) | `M`, `maj` |
| minor | `m` | `min`, `-` |
| power | `5` | |
| diminished | `dim` | `°` |
| augmented | `aug` | `+` |
| sus2 | `sus2` | |
| sus4 | `sus4` | `sus` |
| major_6 | `6` | `M6`, `maj6` |
| minor_6 | `m6` | `min6`, `-6` |
| dominant_7 | `7` | |
| major_7 | `maj7` | `M7`, `Δ7`, `Δ`, `ma7` |
| minor_7 | `m7` | `min7`, `-7` |
| minor_major_7 | `mMaj7` | `mM7`, `m(maj7)`, `minMaj7`, `mΔ7`, `-Δ7` |
| half_diminished_7 | `m7b5` | `m7(b5)`, `-7b5`, `ø`, `ø7` |
| diminished_7 | `dim7` | `°7` |
| dominant_7_sus4 | `7sus4` | `7sus` |
| add_9 | `add9` | `(add9)` |
| minor_add_9 | `madd9` | `m(add9)` |
| dominant_9 | `9` | |
| major_9 | `maj9` | `M9`, `Δ9` |
| minor_9 | `m9` | `min9`, `-9` |
| dominant_11 | `11` | |
| minor_11 | `m11` | `min11`, `-11` |
| dominant_13 | `13` | |
| dominant_7_flat_5 | `7b5` | `7(b5)` |
| dominant_7_sharp_5 | `7#5` | `7(#5)`, `7+5`, `+7`, `aug7` |
| dominant_7_flat_9 | `7b9` | `7(b9)` |
| dominant_7_sharp_9 | `7#9` | `7(#9)` |

`o` and `o7` are deliberately not diminished aliases. Brazilian Portuguese authors name notes in
solfège, so `Do` and `Do7` are far more likely to mean C (Dó) and C7 than D diminished. Reading
them as D chords would put a wrong chord in front of a learner, while leaving them unparsed
(`unsupported_quality`) only shows the author a warning.
