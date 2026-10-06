# ADR-050: Chord library and song charts — chord identity, voicings, chart documents and a rights gate

**Status:** Proposed
**Date:** 2026-10-06
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-44 (follows the MOT-40 / PB-87 spike)
**Amends:** ADR-041 (a diagram has a list of named playbacks instead of one `sequence`; see §1a);
ADR-005 (a one-time squash of the migration history before the first production deploy; see §7)

---

## Context

The informal guitar student wants to play songs, not study a chord dictionary (H2, repertoire
first). Today a student who meets an unfamiliar chord in a song has to leave MotifPath to find a
fingering, typically on Cifra Club or YouTube. The spike
([findings](../spikes/chord-library-and-song-charts-findings.md)) proposed a song-first reader:
the student reads a chord-and-lyric chart, taps a chord, and sees one playable fingering without
leaving the chart.

MotifPath can already draw a fingering. ADR-027/ADR-028 give one SVG renderer over structured
`Diagram` positions, ADR-030 makes `diagram` the standard inline embed, and ADR-041 sounds a diagram
as a chord or strum. What is missing is musical meaning around the picture. A `Diagram` titled
"Am" is only a drawing, and nothing checks that it contains A, C and E. Nothing in the platform
represents a song chart either: lyrics with chords anchored to particular words, a key, a capo, and
a draft → review → publish lifecycle.

The spike also verified, against Tiptap 3.31.3, that an author can select a lyric word and apply a
`chordAnchor` mark carrying the written symbol and an optional voicing. The mark survives JSON round
trips, wraps correctly at 430px, and stays out of the generic `PromptDocument`. It did not test
persistence, musical validation or publication.

Three product questions blocked an architectural decision: which songs may be published, how broad
the first chord catalog is, and who may author and publish. The Product Owner decided all three on
2026-10-06 (MOT-44): publish public-domain, original **and licensed** songs; curate a **broad**
chord catalog; and keep authoring with the **concierge team**, with a second-person review.

Alternatives considered at a high level: linking out to an external chord site (rejected: it is the
very context switch the hypothesis targets, and we can't control its accuracy); storing charts as
monospace text or as HTML (rejected below); and generating charts from YouTube or audio (deferred,
see Decision §6).

## Decision

### 1. Chord identity and voicing are separate entities; a voicing reuses `Diagram`

MotifPath will add a curated chord catalog of two entities:

```
ChordDefinition                         ChordVoicing
  id                                      id
  canonical_symbol    // "Bbmaj7"         chord_definition_id
  root                // spelled: Bb      diagram_id          → existing Diagram
  formula             // [P1, M3, P5, M7] instrument_id, tuning_fingerprint
  bass?               // slash chord      fret_window, fingering, muted_strings
  aliases[]           // "B♭M7", "BbΔ7"   omitted_intervals[] // declared, e.g. P5
  quality             // enum, below      difficulty, technique_tags[]
                                          shape_family?       // E-shape, A-shape, open…
                                          recommended_rank
                                          catalog_status, provenance
```

One `ChordDefinition` has many `ChordVoicing` records. A voicing references a `Diagram` by id and
never copies its positions, SVG or audio.

**Musical validation is deterministic and blocks catalog entry.** A voicing is accepted only if:

- the pitch classes sounded by its diagram, under its tuning, equal the definition's formula. Doubled
  tones are allowed, and omitted tones are allowed only when listed in `omitted_intervals`;
- for a slash chord, the lowest sounded string is the declared bass;
- its tuning matches the diagram's instrument tuning.

So an "Am" diagram containing F# is a rejected entry, not a mistake a learner sees.

**Chord symbols are parsed, not trusted.** A deterministic parser normalizes the spellings it
supports (`Bbmaj7`, `B♭M7`, `BbΔ7`) to one `ChordDefinition` and keeps the author's written
spelling for display. If a symbol can't be parsed, it stays as the written text with a validation
warning and is never silently reinterpreted. No LLM parses, normalizes or transposes chords.

### 1a. One diagram per chord shape, with several named playbacks

Each voicing is **one** `Diagram` holding just that shape's positions. The ways it can sound, such
as a strum, an arpeggio or a fingerstyle pattern, are **playbacks of that diagram**, not separate
diagrams. This amends ADR-041, which gave a diagram exactly one `sequence`:

```
Diagram
  positions, regions, …                 // unchanged
  playbacks: Playback[]                 // ordered; empty = the diagram doesn't play
  default_playback_id?                  // required when playbacks is non-empty

Playback
  id, names { en, pt_BR }               // "Strum down", "Arpeggio", "Fingerstyle p-i-m-a"
  tempo_bpm, time_signature             // moved here from Diagram
  steps: SequenceStep[]                 // unchanged ADR-041 step: position_ids, value, strum

DiagramRef.playback
  playback_id?                          // which playback this usage plays; null = the default
  tempo_bpm?, voice_id?, direction, loop  // unchanged overrides
```

- The rhythm still belongs to the diagram, as ADR-041 decided. A ref only *chooses* among the
  diagram's playbacks and never defines steps.
- Each step still references the diagram's own positions, so every playback of a voicing sounds
  exactly that shape. One validation covers all of them.
- **No data migration.** `sequence`, `tempo_bpm` and `time_signature` are replaced by `playbacks`
  as part of the one-time migration squash in §7, without converting existing rows.
- "Save as" (ADR-032) copies every playback, remapping position ids.
- The capability is generic. A scale diagram can offer "ascending", "descending" and "in thirds"
  without being duplicated.
- **Catalog voicings** get a standard set of playbacks from the catalog build: a down-strum (the
  default) and a bass-to-treble arpeggio. Further patterns, such as fingerstyle, are templates
  the content team adds and reviews once, then applies to every voicing that fits.
  In the chord sheet, the learner switches playback with the same compact tab control as voicings.
- Practice items that play a diagram (`play_along:<diagram id>`) play its default playback. Picking
  a specific playback for a practice item is out of scope here.

### 2. The first catalog is broad: the full quality vocabulary across positions

The initial catalog covers standard-tuning six-string guitar only (ADR-045). Its quality vocabulary
is:

- triads and power chords: `5`, major, minor, `dim`, `aug`, `sus2`, `sus4`
- sixths and sevenths: `6`, `m6`, `7`, `maj7`, `m7`, `mMaj7`, `m7b5`, `dim7`, `7sus4`
- added and extended tones: `add9`, `madd9`, `9`, `maj9`, `m9`, `11`, `m11`, `13`
- altered dominants: `7b5`, `7#5`, `7b9`, `7#9`
- a slash bass on any of the above

Each quality is offered in all 12 roots, with an open voicing wherever one exists and movable
shapes across the neck (E-, A- and D-shape families, plus the common shell and drop voicings for
the extended and altered qualities).

**Movable voicings are generated, then materialized and validated.** The content team authors a
movable *shape template* once, and the catalog build transposes it into a concrete `Diagram` and
`ChordVoicing` for each root it can be played in. Every generated voicing passes the same validation
as a hand-authored one. Materializing keeps the learner renderer free of runtime transposition, so
the catalog does not depend on `DiagramRef.root_override` (MOT-32) being finished. An open shape is
never transposed into a key it can't be played in; `shape_family` and an explicit `is_movable`
flag control this.

### 2a. Chord-voicing diagrams are kept out of the general diagram library by default

A broad catalog adds hundreds to low thousands of diagrams. Mixed into the library, they would
bury the scales, licks and other diagrams authors actually look for. So:

- `Diagram` gets a `purpose`: `general` or `chord_voicing`. Authors don't set it. A diagram is
  `chord_voicing` exactly when a `ChordVoicing` references it, and the catalog sets it when it
  creates the voicing. Every existing diagram, and every diagram an author creates or duplicates,
  is `general`.
- `listDiagrams` takes a `purpose` filter (`general` | `chord_voicing` | `any`) that **defaults
  to `general`** when omitted. Every existing caller, including the diagram embed picker and the
  diagram library, stops seeing chord voicings with no client change, and `total` and pagination
  count only what is shown.
- Chord voicings are found through the chord catalog, not the diagram list: search by chord symbol
  (the parser accepts any supported spelling), then pick among that chord's voicings. The diagram
  embed picker offers this as a separate "Chords" entry point next to its default diagram list.
- A `chord_voicing` diagram can't be edited through the general diagram editor, because an edit
  there would bypass musical validation and review. Its fingering changes only through the catalog
  workflow (§6). Duplicating one gives the author an ordinary `general` diagram they own.
- A diagram embedded in content renders the same whatever its purpose. `purpose` affects
  discovery and editing only.

The catalog's exact contents are a spec, not code: a `catalogs/chord-voicings.yaml` in
motifpath-specs listing definitions, templates and hand-authored voicings. It is installed through a
migration and owned by the `MotifPath Catalog` system profile (ADR-044), the same way the
basic-guitar diagrams are.

### 3. A song chart is a separate, versioned document; ChordPro is the boundary format

```
SongChart
  id, created_by, status (draft | in_review | published | withdrawn)
  title, artist, language, concert_key, capo_fret, tempo_bpm?, meter?
  tuning_fingerprint
  rights_record_id                     → RightsRecord (§5)
  body: SongChartDocument              // versioned Tiptap/ProseMirror JSON, never HTML

SongChartDocument blocks: section | lyric_paragraph | comment
chordAnchor mark on lyric text:
  written_symbol                       // the author's spelling, shown to the learner
  chord_definition_id?                 // set once the parser resolves the symbol
  voicing_id?                          // this anchor's preferred voicing; else the top-ranked one
```

- The learner reader derives its layout from the marked text. It never stores spaces that exist
  only to line chords up in a monospace font.
- Publishing creates an **immutable revision**. A correction is a new revision with its own review;
  it never rewrites what a learner was shown.
- ChordPro import and export happen at the boundary. ChordPro is not a second canonical
  representation.
- `chordAnchor` lives only in a chart-specific schema and validator. It is **not** added to
  `PromptDocument` or `PromptEditor`. If marks prove brittle under syllable editing in production, a
  custom inline anchor node is the fallback, decided then.

### 4. Editor integration

- A dedicated `SongChartEditor` (Tiptap, ADR-020) owns lyric lines and chord anchors. The existing
  diagram editor keeps ownership of the physical fingering.
- In lesson content, a chord voicing is inserted with the existing `diagram` embed (ADR-030): the
  picker chooses a `ChordVoicing` and inserts its `diagram_ref`.
- One new rich-text node, a `song_chart` atom, references a published `SongChart` revision and
  previews it read-only.

### 5. Rights gate: public domain, original or licensed — evidence recorded for every chart

No chart can be published without a `RightsRecord` that passes the gate:

| `basis` | Required evidence |
| --- | --- |
| `public_domain` | Composer and lyricist with dates, or a cited source establishing public-domain status in the territories served; the specific lyric text used must also be in the public domain (not a later copyrighted arrangement or translation). |
| `original` | The creator's identity and a signed permission covering lyric display and chord transcription on MotifPath. |
| `licensed` | Licensor, license reference and document, permitted uses (lyric display, chord transcription), territories, languages, start date and end date (if any). |

Gate rules:

- Rights evidence documents are stored privately, never in learner-facing media.
- A chart is shown only in the territories, and in the language, that its rights record covers. A
  licensed chart is **not** translated unless the license explicitly allows translation.
- When a license ends, or its territory no longer covers the learner, the chart becomes unavailable
  to learners. The read path checks the rights record at serve time, not only at publish time. Its
  published revisions are kept for audit but not served. A `song_chart` embed whose chart is
  unavailable renders a neutral "not available" state rather than a broken lesson.
- A rights record belongs to the song, not to a chart revision, so a correction does not need new
  evidence. A change of basis or license terms does need a new review.

### 6. Roles and review

- Only `admin` users (the concierge team) create and edit chord definitions, voicings, shape
  templates, song charts and rights records. Teachers and students cannot author or publish any of
  them.
- Publishing a chart, and adding a voicing or template to the catalog, needs a **second admin**
  as reviewer. The reviewer confirms rights, the musical correctness of anchors and voicings, and
  the learner preview. The author can't approve their own submission. The review records reviewer,
  timestamp and outcome.
- Learners read published charts and consult the selected chord's voicings. They can't browse the
  catalog as a directory, create, edit or share charts.
- **Deferred, not decided:** audio-to-chart generation, including from a YouTube URL. A public
  YouTube URL is never an accepted input: YouTube's terms forbid downloading its content, and
  MotifPath's video policy keeps YouTube content inside YouTube's player. Any future generation work
  needs its own ADR.

### 7. One-time squash of the migration history, done together with plural playbacks

MotifPath has no production database yet. Rather than adding a `sequence` → `playbacks` migration
on top of 32 existing ones (8 of which also insert reference or catalog data), core-domain's
migration history is squashed **once**, in the same change that introduces `playbacks`:

- **Two baseline migrations replace the whole history.**
  1. `baseline_schema`: the complete schema, generated by `atlas migrate diff` from an empty
     database against the current `ent` schema, including `playbacks`.
  2. `baseline_reference_data`: all reference and catalog rows currently spread across the history
     (system languages, instruments and their icons, voices, the knowledge map, the basic-guitar
     catalog, the drill catalog), rewritten for the new schema. The basic-guitar diagrams are
     rewritten with `playbacks`. Data stays separate from schema because Atlas can't generate it
     from `ent`.
  `atlas.sum` is regenerated. The old migration files are deleted; git history keeps them.
- **Every existing database is dropped and rebuilt** (local, development and staging). Diagrams
  or content authored there that are worth keeping must be added to the reference data before the
  reset, or they are lost.
- **One-time lint exception.** `atlas migrate lint` compares a PR's migrations with `main`'s
  history, so it will report the rewrite as destructive. That PR alone bypasses the check, with the
  reason given in the PR and in a comment in the CI configuration that is removed afterwards.
- **The squash happens exactly once.** From the first production deploy on, ADR-005 applies
  unchanged: the history is append-only, migrations are never rewritten, and schema changes that
  affect existing rows carry their own data migration. Later chord-catalog work (Phase 1) adds
  ordinary migrations on top of the baseline.

## Rationale

**Identity separate from voicing, instead of named diagrams.** Labelling diagrams is what we have
today, and it is why nothing can tell a wrong "Am" from a right one. With a definition that has a
formula, the label becomes a checkable claim, and one definition can offer open, barre and higher
voicings without picking one as "the" C. Reusing `Diagram` instead of a chord-specific fingering
format keeps one renderer, one audio path and one authoring tool (ADR-027/028/041).

**A broad catalog, made affordable by templates.** The Product Owner chose breadth so that a chart
can use any chord its song needs, including extended and altered harmony common in Brazilian popular
music and jazz-inflected repertoire, without waiting for a catalog addition. The alternatives were
30–50 hand-picked beginner voicings, or adding voicings only when a chart needs them. The first would
force authors to simplify songs, and the second blocks authors at publish time. Neither suits a
catalog that must serve licensed popular repertoire. Breadth is affordable only because movable
shapes are authored once and transposed by a deterministic, validated build. Hand-authoring several
hundred diagrams would be slow and error-prone.

**Several playbacks on one shape diagram, instead of a diagram per playback or per-note map.** Two
alternatives were rejected. One diagram per playback style would multiply the catalog for every
pattern added and duplicate identical fingerings, so a fix to one copy would leave the others
wrong. A single chord-tone map per chord, with voicings as stored refs over it, would cut the
diagram count, but a map of every chord tone isn't useful to a learner. It would also need
per-ref fingering labels, muted-string markers and position-subset playback. Keeping the shape as
the diagram and making playback plural is the smallest change to ADR-041. The rhythm stays on the
diagram, and refs only choose.

**Squash now, once, in the same change as `playbacks`.** Two alternatives were rejected. A
conversion migration for existing sequences would be complex code for data nobody needs to keep.
Squashing in a separate item would rewrite the history twice, once for the squash and once for
`playbacks`, and reset every database twice. Squashing before production is free, because no
database has to be upgraded. It also means a fresh database (every developer setup, every CI run,
the first production deploy) applies 2 migrations instead of 30-plus. After production, the same
move would be unsafe, which is why it is limited to this one time.

**Materialized voicings over runtime `root_override`.** Runtime transposition would save rows, but
it ties the reader to MOT-32 and moves validation from catalog-build time to render time, where a
failure reaches a learner. Materializing costs storage and migration size, which are cheap. Each
voicing a learner sees has been validated as itself.

**A `purpose` the server derives, defaulting to `general`, to separate chord voicings.** Three
other approaches were considered. Storing voicings outside `Diagram` would lose the shared
renderer, audio and embed. Filtering on the client would leave `total` and pagination counting
hidden rows, and every client would have to remember the filter. Tagging voicings with a skill or
concept would let an author's tagging change what the library shows. Deriving `purpose` from the
`ChordVoicing` reference keeps one source of truth. Defaulting the filter to `general` means a new
or forgotten caller fails safe, with an uncluttered list.

**A ChordPro-compatible AST over text or HTML.** A monospace text chart breaks when lines wrap on a
phone, and the anchor positions are only implied by spaces. HTML would lose the musical attributes
and mix presentation with content. ChordPro gives interoperability without becoming our schema.
Tiptap JSON with a typed mark is what the spike proved editable.

**Licensed repertoire with a strict gate, instead of public domain only.** Public domain alone
would leave informal students with mostly hymns and folk songs, which weakens the repertoire-first
bet the feature exists to test. Licensing costs money and legal work. A rights record that is
checked at serve time keeps an expired license from silently leaving content in front of learners.
A self-attested checkbox was rejected because it gives no defence in a takedown.

**Concierge authoring with a second reviewer.** Opening authoring to teachers would support the
scaling thesis earlier, but it multiplies the rights exposure before the gate has been exercised. A
single-step publish was rejected for the same reason, and because one wrong voicing is repeated in
every chart that uses it.

## Consequences

### Positive

- One corrected voicing improves every chart and lesson that uses it. Chord identity, voicing
  and chart text evolve independently.
- A wrong chord label is caught when the catalog is built, before any learner sees it.
- Learners get a song-first surface without leaving MotifPath, which is the behaviour the concierge
  test measures.
- Charts are portable through ChordPro, and published revisions keep an audit trail for rights
  questions.

### Negative / Trade-offs

- **Licensing is a real cost and a legal dependency.** Licensed songs need negotiation, records and
  renewal tracking. Until a license is signed, the concierge test can use only public-domain and
  original songs.
- **A broad catalog is a larger curation and review load.** Shape templates, the transposition
  build and the musical validator have to be built and tested before the catalog exists, and every
  template needs a second admin's review. Phase 1 is bigger than the spike's 30–50-voicing
  recommendation.
- **Materialization means many `Diagram` rows** (an estimated several hundred to low thousands), all
  owned by the catalog profile. They are hidden from the default diagram listing (§2a), so any
  surface that *should* list them has to opt in with `purpose`, and chord voicings need their own
  chord-symbol search.
- **Plural playbacks change a shared contract.** `Diagram`, the create/update requests, the
  diagram editor, the audio player and "Save as" all move from one `sequence` to `playbacks`.
- **The squash resets every database** and loses whatever was authored only in development and
  staging. It also needs a one-time lint bypass, and the rewritten reference data has to be
  reviewed against the 8 data migrations it replaces, because a missed row disappears silently.
- **Serve-time rights checks** add a lookup to every chart read and a learner-visible "not
  available" state that lesson authors must expect.
- **Two-admin review** slows publishing while the concierge team is small, and blocks it outright
  when only one admin is available.
- The concierge team is the only source of charts, so chart supply is limited by its capacity.

### Neutral

- `PromptDocument` and `PromptEditor` are unchanged. Charts reach lessons only through the
  `song_chart` atom.
- `chord_change:<from diagram>:<to diagram>` practice items (ADR-046) keep working. A future item
  may reference voicings, but nothing in this ADR requires it.
- Other fretted instruments and tunings fit the model (`instrument_id`, `tuning_fingerprint`) but
  stay out of scope under ADR-045.

## Follow-up work

1. Phase 0 — concierge test with 5–8 students on 3–5 rights-cleared charts (public domain or
   original until a license is signed).
2. Phase 1a — Gherkin and OpenAPI for plural playbacks (`Diagram.playbacks`,
   `default_playback_id`, `DiagramRef.playback.playback_id`) and the diagram editor's playback
   list; in motifpath-core, the one-time migration squash (§7) with `playbacks` in the baseline.
   This is generic and comes first.
3. Phase 1 — Gherkin and OpenAPI for `ChordDefinition`, `ChordVoicing`, shape templates and the
   musical validator; `catalogs/chord-voicings.yaml`; `Diagram.purpose` and the `listDiagrams`
   `purpose` filter (default `general`); chord-symbol search; the read-only rule for `chord_voicing`
   diagrams in the diagram editor.
4. Phase 2 — Gherkin and OpenAPI for `SongChart`, `RightsRecord`, review and publication, ChordPro
   import and export, and the learner reader.
5. Phase 3 — the `song_chart` rich-text atom and the voicing picker for the `diagram` embed.
6. Legal — a license template and review checklist for licensed songs, before the first licensed
   chart.

## Related ADRs

- ADR-020: Content authoring text editor — Tiptap, which hosts `SongChartEditor` and the
  `song_chart` atom.
- ADR-027: SVG rendering for layered diagrams — the renderer every voicing uses.
- ADR-028: Prebuilt diagram content model — the `Diagram` a voicing references.
- ADR-030: Diagram embedded resource — the `diagram` embed used to insert a voicing.
- ADR-041: Diagram audio playback — amended: a diagram has several named playbacks; a voicing sounds through them.
- ADR-005: Database migration strategy — amended once: the history is squashed before the first
  production deploy (§7), then stays append-only.
- ADR-044: System catalog curator — owns the installed chord catalog.
- ADR-045: Catalog guitar instrument scope — limits the first catalog to standard-tuning guitar.
- ADR-046: Evidence-based practice model — `chord_change` practice items reference diagrams.

---

*This ADR was proposed on 2026-10-06. To revise, create a new ADR with Status: Supersedes ADR-050.*
