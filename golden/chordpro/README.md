# ChordPro golden cases

Language-neutral cases that pin how ChordPro text becomes a song chart draft
(`importSongChartChordPro`) and how a draft is written back as ChordPro
(`exportSongChartChordPro`). ChordPro is only an exchange format: a chart stores the
`SongChartDocument` an import produces, never the text. Core-domain runs every case. Web
doesn't parse ChordPro; it calls the two operations.

## Files

- `<format>.v<version>.json`: one file per rule version, for example `chordpro.v1.json`.
  A file is never edited once a consumer ships that version, except to add cases. A rule change
  is a new version in a new file.
- `schema.json`: the JSON Schema every case file follows.

Each case has the ChordPro `input`, the `expected` import (the metadata the text sets, the
document `body` and the `import_warnings`), and the `export` of that imported draft. Every
`body` is a valid `SongChartDocument` and every warning a valid `ChordProImportWarning`
(`openapi/core-domain-service.yaml`). The resolution of chord symbols to catalog chords happens
after the import and isn't part of these cases, so every anchor's `chordDefinitionId` and
`chordVoicingId` are null here.

## Import rules

1. **Lines.** The text is split into lines on LF; a CR before an LF is dropped. Lines are
   numbered from 1. Trailing whitespace on a line is ignored. A blank line separates nothing
   and is skipped. A line starting with `#` is a ChordPro comment for editors and is skipped.
2. **Directives.** A line whose trimmed text starts with `{` and ends with `}` is a directive:
   `{name}` or `{name: value}` (the space after the colon is optional; the value is trimmed).
   Names are case-insensitive. A line starting with `{` that doesn't end with `}` is a
   `malformed_directive` and is skipped. A directive outside the supported set is an
   `unsupported_directive` and is skipped.
3. **Metadata.** `title` (`t`) sets the title and `artist` the artist. `key` sets the concert
   key and must match `^[A-G](b|#)?m?$`. `capo` sets the capo fret, an integer from 0 to 12.
   `tempo` sets the tempo, an integer from 20 to 300. `time` sets the meter, as `beats/value`.
   A value that doesn't fit is a `malformed_directive`, and the field isn't set. A field set
   twice keeps the last value.
4. **Sections.** `start_of_verse` (`sov`), `start_of_chorus` (`soc`) and `start_of_bridge`
   (`sob`) open a section of that kind. Their optional value is the section's label; without
   one the label is null. The matching `end_of_` directive (`eov`, `eoc`, `eob`) closes it.
   Lines outside any open section belong to an unlabelled section of kind `other`, which runs
   until the next `start_of_`. A section with no lines is dropped, with an `empty_section`
   warning on the line of its `start_of_` directive.
5. **Unbalanced sections.** A `start_of_` while a section is open closes the open section first,
   and an `end_of_` of another kind closes the open section. An `end_of_` with no open section
   is skipped. Each of the three is an `unbalanced_section` warning.
6. **Comments.** `comment` (`c`) adds a comment line, with the directive's value as its text,
   to the current section. A comment with no value is a `malformed_directive`.
7. **Lyric lines.** Any other non-blank line is a lyric line. Each `[symbol]` is a chord anchor
   whose written symbol is the text between the brackets, exactly as written (not trimmed,
   not normalized). An empty `[]` is plain text, not a chord. A chord is played at the start of
   the text after its `]`, up to the next chord or the end of the line; when that text is empty,
   the anchor marks a single space. Text before the first chord has no anchor. A `[` with no `]`
   after it on the line is an `unclosed_chord` warning, and the whole line is read as plain text.
8. **Anchor ids.** Anchors get the ids `a1`, `a2`, … in document order.

## Export rules

1. **Metadata** first, one directive per line, in this order: `{title: …}`, `{artist: …}`,
   then `{key: …}`, `{capo: …}`, `{tempo: …}` and `{time: beats/value}` for the fields that
   are set. A capo of 0 isn't written.
2. **Sections** follow, each after one blank line. A verse, chorus or bridge is written in its
   environment, with its label as the value: `{start_of_chorus: Refrão}` … `{end_of_chorus}`, or
   `{start_of_chorus}` without a label. ChordPro has no environment for the other kinds
   (`intro`, `outro`, `instrumental`, `other`), so their lines are written bare, and a label is
   written as a `{comment: …}` line before them.
3. **Lines.** A comment is `{comment: …}`. A lyric line is its runs in order, each anchored
   run preceded by `[written symbol]`; trailing whitespace is then removed from the line, so an
   anchor on a single space at the end of a line is written as just its chord.
4. The text ends with a single LF.

Importing an export gives back the same document, except for anchor ids and for the labels and
kinds of sections ChordPro has no environment for.
