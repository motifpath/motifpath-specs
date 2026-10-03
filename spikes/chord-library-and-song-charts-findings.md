# Spike Findings: Chord library and song charts

**Date:** 2026-10-03
**Status:** Recommendation — no implementation decision yet
**Scope:** Guitar first, consistent with [ADR-045](../adrs/ADR-045-catalog-guitar-instrument-scope.md).

---

## Recommendation

Treat this as two capabilities plus an explicit scope boundary:

1. **Chord vocabulary:** a small, curated internal catalog of *harmonic chord definitions* and
   their playable *voicings*. A voicing reuses the existing `Diagram` resource and SVG renderer;
   it is not an image or a second fretboard implementation. It is authoring infrastructure, not a
   public Cifra Club-style directory.
2. **Song chart:** a structured chord-and-lyric document authored by the MotifPath team and shown
   read-only to learners. It uses a ChordPro-compatible abstract syntax tree (AST) and resolves
   each written chord to a preferred catalog voicing at render time.
3. **Scope boundary:** charts are manually authored by the content team from rights-cleared
   material. Audio-to-chart generation—including YouTube—is deferred and is not part of this
   validation.

This gives beginners a polished, song-first learning surface while keeping the musical facts,
the visual diagrams, and copyrighted song text from being conflated.

## Product hypothesis and validation

**Persona:** informal guitar student.

> We believe a student who can read a song chart, tap an unfamiliar chord, and immediately see
> one playable fingering will practice a chosen song more consistently than a student who has to
> leave MotifPath to search for each chord. We will know this is promising when a concierge test
> shows that learners complete a first song section and return to it without external help.

Before building a song experience, validate with 5–8 students using 3–5 rights-cleared songs
authored by the concierge team. Measure: time to first playable section, diagram-open rate,
chord-change attempts, completion of one section, and seven-day return. The longer-term outcome is
contribution to MotifPath's 90-day active-learning North Star; the experience must remain useful
without a teacher or an AI import.

## 1. Best UI: a song-first learning view

The benchmark is the *behaviour*, not Cifra Club's visual treatment: its current chart view puts
diagrams where they are easy to consult, offers editable personal versions, columns, capo/notation
controls, and movable practice tools. MotifPath should use the same "keep playing, do not leave the
chart" principle, but make the visual language calmer and lesson-oriented.

### Learner view

The learner sees the song, not a chord-library product. The recommended view is a responsive,
read-only **chart-first reader**:

```
┌────────────────────────────────────────────────────────────────────┐
│ Amazing Grace                         Key G · 72 BPM                │
├────────────────────────────────────────────────────────────────────┤
│ Verse 1                                                            │
│  G                         C                                      │
│  Amazing grace, how sweet  the sound that saved a                  │
│  G                                                                 │
│  wretch like me                                                   │
└────────────────────────────────────────────────────────────────────┘
```

- **Desktop:** lyrics/chords own the reading column. A persistent side panel shows the currently
  selected chord's polished diagram: chord name, mute/open strings, fingering and highlighted root
  notes. It is contextual help, never a library browser or editor.
- **Mobile:** the chart remains full-width with comfortable line spacing and compact, tappable chord
  symbols. Tapping a chord opens its diagram in a bottom sheet. The sheet follows the existing
  diagram UI language: compact rail-style actions, understated controls, and a clear SVG diagram.
  Where more than one playable voicing exists, a small tab switcher (for example, “Open” and
  “Barre · fret 3”) changes the fingering in place. The header collapses before the lyrics do; the
  user does not see a catalog browser or any creation/sharing control. The prototype includes a
  light/dark preview toggle; production should follow the app's selected appearance.
- **Visual hierarchy:** use one strong root-colour marker, neutral frets, and small interval labels;
  avoid rainbow markers. Show difficulty, required barre, muted/open strings, root strings, and
  a short fingering hint next to—not inside—the board. The existing SVG system already protects
  label readability and touch targets.
- **Progressive disclosure:** the chart shows one selected-chord diagram, not a catalog. Explanatory
  diagrams outside the song reader still belong in surrounding lesson content, authored with the
  existing diagram embed.
- **Accessibility:** chord symbols stay visually distinct from lyric text without relying on colour;
  the reader preserves high contrast, zoom and keyboard navigation.

### Song chart reading behaviour

The chart and its selected-chord diagram are the entire learner-facing surface.

- Render chord symbols directly above their lyric anchor; keep their horizontal relationship when
  the layout reflows.
- Show only title, artist, key, meter and tempo around the lyrics/chords, plus the selected chord's
  diagram. Section navigation is optional for long songs; no library, sharing or editing control
  appears in the learner view.
- Font-size and autoscroll controls may be added after the reading test proves they are needed.
  Transpose, capo and notation changes belong to the internal authoring workflow for this scope.

## 2. Data model: reuse diagrams; add musical meaning around them

### What we already have

ADR-027/ADR-028 already establish the right visual primitive: structured, polymorphic positions
rendered by one SVG system, with render-time configuration rather than generated image variants.
ADR-041 further allows a diagram sequence to sound all its positions as a chord or a strum.
The catalog should reuse those decisions unchanged.

The missing abstraction is not SVG. It is the distinction between a chord's **identity** (the notes
it contains) and a guitar **voicing** (one physical way to play it).

### Proposed catalog entities

```
ChordDefinition (harmonic identity)
  id, display_symbol, canonical_symbol
  root: spelled pitch class          // e.g. Bb, not only pitch-class 10
  formula: intervals                 // e.g. [P1, m3, P5, m7]
  bass: optional spelled pitch class // slash chord, e.g. C/E
  aliases: string[]                  // "Cmin7", localized names

ChordVoicing (playable choice)
  id, chord_definition_id, diagram_id
  instrument_id, tuning_fingerprint
  fret_window, fingering, muted_strings
  difficulty, technique_tags         // open, barre, CAGED shape, inversion
  is_movable, recommended_rank
  source/provenance, catalog_status

Diagram (existing reusable resource)
  positions: string/fret + interval + note metadata
  sequence: optional chord/strum playback
```

This is deliberately one `ChordDefinition` to many `ChordVoicing` records. The same C-major
identity can offer an open shape, a barre shape, a higher-register inversion, or another curated
playable shape without duplicating the chord identity or pretending one fingering is canonical.
The learner switches among available voicings from the selected chord's sheet; the chart itself
continues to show only the chord symbol.

`ChordVoicing.diagram_id` references the existing `Diagram`; it must not duplicate `positions`,
SVG, or audio data. A catalog voicing validates that its sounded pitch classes match the associated
`ChordDefinition.formula` (allowing duplicated tones and intentional omitted tones when explicitly
declared). It also validates the diagram's tuning against the voicing. This makes a bad label such
as an "Am" diagram containing F# a rejected catalog entry rather than a learner-facing mistake.

Use a **structured descriptor plus the original spelling**, rather than treating a chord name as a
free string. The parser normalizes `Bbmaj7`, `B♭M7`, and allowed aliases to one definition while
preserving the author's displayed spelling. The first catalog should support the quality vocabulary
it actually curates (major/minor, 5, sus2/sus4, dim/aug, 6, 7, maj7, m7, m7♭5, add9, 9, 11, 13,
alterations and slash bass). Unknown symbols remain editable text with a validation warning; they
are not silently reinterpreted.

**Important transposition rule:** a `root_override` can relabel and transpose a genuinely movable
shape, but cannot make an open C shape physically playable as an arbitrary key. `is_movable` is
therefore explicit, and each selected diagram remains a real, validated voicing for the rendered
chord. This prevents a mathematically neat but unplayable diagram.

### Catalog ownership and lifecycle

- The initial chord library is platform-curated, owned by the fixed catalog profile from ADR-044.
- Only content-team authors can create or revise voicings and charts. Learners read song
  lyrics/chords and consult the selected-chord diagram; they cannot browse, create, share or edit
  charts.
- A correction is reviewed and versioned before it changes published learning content.
- Start with standard-tuning guitar as ADR-045 requires. The model supports other compatible
  fretted instruments later, but an instrument-specific voicing must never be shown as if it fits
  another tuning.

## 3. Rich-text-editor integration

ADR-020 has already selected Tiptap and ADR-030 already makes `PromptNode.type: diagram` the
standard inline diagram embed. Reuse that established vocabulary for a chord voicing: the catalog
picker selects the `ChordVoicing`, then inserts its backing `diagram_ref` and optional render
configuration. It is never a pasted SVG or an image snapshot.

Add only one purpose-built node for an authoring surface:

1. **`song_chart` atom:** an atomic reference to a separate `SongChart` revision. Its Tiptap node
   view displays a compact, read-only preview with "Open chart" and "Edit chart" actions. The chart
   editor opens as its own focused workspace rather than attempting to make chord alignment a
   generic inline-text experience.

Use a dedicated `SongChartEditor` built on Tiptap for the lyric-and-chord authoring workflow. The
author selects a word or syllable and applies a custom `chordAnchor` mark; the mark carries the
written symbol, normalized chord identity and optional chart-selected voicing. The editor renders
the symbol above the marked text, so it stays associated with that lyric as the line reflows. This
is deliberately scoped to the song-chart document schema—not added to generic lesson or exercise
paragraphs. Tiptap supports custom marks with attributes and HTML rendering; the layout and editing
behavior still need a narrow prototype test for wrapping, cursor edits and serialization round trips.

Keep the chart editor as its own focused workspace. The standard rich-text editor can embed a
purpose-built `song_chart` atom that references a chart revision; it does not need to own lyric
alignment, chord-anchor commands or chart lifecycle. A custom inline anchor node remains a fallback
if marks prove brittle under word/syllable editing.

### Authoring-slice feasibility check

The current repositories make reuse plausible, but do not yet establish end-to-end song-chart
viability:

- **Verified existing capability:** `motifpath-web` has a Tiptap `PromptDiagramNode`, an insert/edit
  flow through `PromptEditor` and `DiagramEmbedPickerModal`, and a dedicated `DiagramAuthoringView`.
  The web client already renders the same `DiagramRef` vocabulary used by lessons.
- **Verified existing capability:** `motifpath-core` has diagram CRUD and authorization, and its
  `PromptDocument` validation accepts a diagram node with a valid diagram reference.
- **Schema boundary:** the existing generic `PromptDocument` only accepts its current fixed mark
  vocabulary. Keep `chordAnchor` in a chart-specific document/validator rather than silently adding
  it to ordinary lesson and exercise text.
- **Not present in the code searched:** a `SongChart` resource/AST, chord identity and voicing
  entities, chart draft/review/publish lifecycle, or a `song_chart` Tiptap atom. Current support
  therefore proves that diagrams can be reused; it does not prove chart persistence, lyric-anchor
  integrity, chord-to-voicing musical validation, or immutable publication.
- **Boundary to preserve:** the chart editor should own structured lyric lines and chord anchors;
  the existing diagram editor should own the physical fingering. Selecting a voicing links these
  models rather than copying SVG or embedding fingering data into lyric text.

**Validation status:** the first pass was partial technical feasibility from source inspection.
The authoring-slice spike now runs against the installed Tiptap 3.31.3 and demonstrates that the
selected-word workflow is technically viable. The learner reader and YouTube/audio generation
remain out of scope.

**Tiptap authoring-slice acceptance criteria:**

- In an isolated spike surface, an author can select lyric text and apply a chord anchor using the
  real Tiptap editor and ProseMirror selection/transaction APIs.
- The anchor displays its chord symbol above the selected text, remains associated with that text
  when the line wraps, and does not prevent ordinary lyric edits.
- The chart-specific JSON stores the written symbol and optional chord/voicing references; loading
  and saving through Tiptap preserves those attributes. Removing an anchor preserves the lyric.
- A second voicing for the same written chord can be selected as chart metadata without changing
  the lyric or the chord's displayed spelling. It is not necessary to implement a full catalog or
  a production diagram picker in this spike.
- The custom mark is not added to the generic `PromptDocument` schema or `PromptEditor`.
- Tests exercise actual Tiptap commands, selection and JSON round trips—not mocked editor APIs.
  Browser inspection at mobile width is additionally required for visual line wrapping and usable
  chord insertion.

**Spike result (2026-10-03):** five tests use actual Tiptap editor instances, selections, commands,
transactions and JSON. They verify that a chord is applied only to selected text; voicing metadata
survives `getJSON`/`setContent`; removing the mark preserves lyrics; typing after a marked word does
not inherit the chord; and the extension remains separate from generic prompt marks. The isolated
browser page was also exercised at a 430px phone-preview width: selecting “grace” and applying C
with the barre-fret-3 option places the label above the word, keeps the lyric editable and wraps the
line without moving the association. The saved JSON visibly contains `symbol: "C"`,
`chordDefinitionId: "c-major"` and `voicingId: "c-barre-3"`. Typecheck, targeted lint and production
build pass.

This confirms the authoring interaction and storage primitive, not the full authoring product. The
spike does not test draft/review/publish lifecycle, a production API, learner reading, rights
management, catalog completeness, musical chord/voicing validation, or a real diagram picker tied
to existing `Diagram` records. Its two voicing cards are fixtures, not persisted catalog options.
A later content-author walkthrough should test whether an author can create a rights-cleared draft,
place/change a chord anchor, choose an actual alternate diagram, preview the learner chart, and
identify publish checks.

### SongChart storage

Adopt a ChordPro-compatible AST as the canonical chart body, with import/export of plain
ChordPro. ChordPro is a mature open format expressly designed for chord-and-lyric sheets, supports
inline chord anchors, sections, capo, key, tempo, time signatures and instrument-specific chord
definitions. It gives MotifPath interoperability without making an external text file its database
schema.

```
SongChart
  id, created_by, status, title, artist, language
  concert_key, capo_fret, tuning_fingerprint
  source: { kind, url?, rights_basis, imported_at? }
  body: SongChartDocument              // versioned Tiptap/ProseMirror JSON, never HTML

SongChartDocument
  blocks: Section | LyricParagraph | Comment

chordAnchor mark on selected lyric text
  written_symbol                        // author-visible spelling
  normalized_chord_id?                  // linked after parser/catalog resolution
  voicing_id?                           // chart's preferred playable shape for this anchor
```

The learner renderer derives its layout from the marked text; it never persists spaces inserted
only to make a monospace text chart line up. Import/export can translate to ChordPro at the boundary
without making that format a second canonical representation. A chart revision is immutable once
published, so a later correction has traceable provenance and does not quietly rewrite a lesson.

## 4. Deferred research: can a YouTube link generate lyrics and a chord chart?

**Not in the current scope.** The notes below are retained as background only; this validation
covers manual authoring from rights-cleared material and will not evaluate or build any
audio-to-chart generation.

**Technically, an authorized-audio draft can be generated. A public YouTube URL must not be our
input contract.** This is a product, rights and quality boundary—not a missing model capability.

YouTube's terms prohibit reproducing, downloading or otherwise using service content except as
authorized. Its captions API requires authorization, and the official API documents caption-track
access separately from the caption data itself. A public URL therefore cannot safely authorize us
to download audio, extract subtitles, store lyrics, or produce a redistributable chart. Existing
MotifPath video policy already reaches the same conclusion: YouTube content stays embedded through
YouTube's player.

### Safe v1: content-team source → reviewed internal draft

The content team accepts one of these inputs only:

- an audio/video file uploaded by its rights holder;
- an original song uploaded by its creator; or
- a YouTube video the platform's connected account owns or manages, after OAuth confirmation and
  an explicit rights declaration.

Process it as an asynchronous, internal job:

1. Record source URL/file hash, owner, license/permission and retention policy.
2. Extract speech/lyrics with ASR only when the user has supplied that right; retain only the draft
   necessary for editing.
3. Run chord recognition to produce timestamped candidate harmony; normalize candidates with the
   deterministic chord parser and available musical context (key, meter, tempo).
4. Use an LLM, if needed, only to segment sections and format the already-derived candidates into
   the chart AST. It must return a schema-validated draft, never claim confidence it does not have.
5. Open the chart-review workspace with waveform/video reference, confidence highlights and
   one-click corrections for lyric anchors, chords, key, capo and voicings.
6. Do not publish until a human confirms rights and correctness.

Do **not** use an LLM to parse ordinary pasted chord sheets or to transpose them. Chord parsing,
normalization and transposition are deterministic music-theory operations and should be tested as
such. AI belongs in the ambiguous audio-to-draft step, where it saves review time but cannot be the
source of truth.

### Quality gate

The first experiment needs a licensed/owned evaluation set covering solo acoustic, full-band,
live, distorted guitar, worship, Brazilian popular music and songs with modulations. Measure lyric
word error rate, chord root/quality accuracy, onset error (milliseconds), section-boundary accuracy,
and reviewer correction time. Set a publish gate after baseline review; do not advertise
"automatic charts" on a single anecdotal success. Chord-recognition research identifies
non-chord tones as a persistent source of automatic-chord-estimation error, so a review UX is a
product requirement, not an optional safety net.

## Recommended delivery order

| Phase | Deliverable | Why first |
| --- | --- | --- |
| 0 — validate | Concierge test with rights-cleared, team-authored charts | Tests the learner problem before a wider song catalog or AI work. |
| 1 — catalog | Curated common guitar `ChordDefinition` + `ChordVoicing` entries and internal author picker | Creates reliable content infrastructure without a public directory. |
| 2 — charts | Internal SongChart editor, ChordPro import/export and learner-facing read-only chart | Provides the song-learning value without public chart authoring. |
| 3 — embeds | Existing `diagram` and new `song_chart` Tiptap atoms | Reuses ADR-020/ADR-030 without making charts rich-text blobs. |
| Deferred | Audio-to-chart generation from YouTube or other media | Separate discovery only after manual chart authoring and learner value are validated. |

## Decisions needed before implementation

1. **Rights model:** Which licensed or original songs may the content team publish to learners?
   Recommended: a small rights-cleared curriculum set before any catalog expansion.
2. **Catalog scope:** Confirm standard-tuning guitar and the initial chord-quality set. Recommended:
   30–50 high-frequency beginner/intermediate voicings, not an exhaustive theoretical catalog.
3. **Authoring roles and review:** Confirm who may create, review and publish charts, and what
   evidence is required at the rights gate. Recommended: concierge team only for the first release.

## Architecture radar

**Risk identified:** Publishing a manually authored chart without a clear rights basis or reviewable
source could make otherwise useful content unsafe to distribute.

→ **Impact potential:** takedowns, rework and loss of trust in the curriculum.

**Opportunity identified:** separate canonical chord identity, physical voicing and chart text from
the beginning.

→ **Potential gain:** one corrected voicing improves every lesson and chart; the song editor,
catalog and SVG renderer stay independently evolvable.

**Suggested action:** require a documented rights basis and human review in the manual authoring
workflow. Keep media-generation questions deferred.

Priority: 🟡 Medium.

## Sources consulted

- [Cifra Club: current chart-screen features](https://www.cifraclub.com.br/blog/nova-tela-de-cifras/)
- [Cifra Club: chord-chart formatting guidelines](https://suporte.cifraclub.com.br/pt-BR/support/solutions/articles/64000236814-conheca-o-padr%C3%A3o-para-envio-de-cifras-e-tablaturas)
- [Tiptap: Vue node views](https://tiptap.dev/docs/editor/extensions/custom-extensions/node-views/vue)
- [Tiptap: custom Mark extensions and attributes](https://tiptap.dev/docs/editor/extensions/custom-extensions/create-new/mark)
- [ChordPro: official format overview](https://www.chordpro.org/)
- [ChordPro 6: sections, capo/key/tempo and chord definitions](https://www.chordpro.org/chordpro/chordpro6-relnotes/)
- [YouTube Data API: caption tracks require authorization](https://developers.google.com/youtube/v3/docs/captions/list)
- [YouTube terms of service](https://yt-terms.static.usercontent.goog/pdf/terms/20231215/en_us_20231215.pdf)
- [Research: non-chord tones as a source of automatic chord-estimation error](https://arxiv.org/abs/2105.05385)
