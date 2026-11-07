# First-notes production packet

MOT-160 · cycle 2 · phase **Do** · draft/packet version 1 · 2026-11-03.

## Authorization and disposition

The product owner explicitly accepted the 18-slide sequence and diagram direction and
selected “Accept the direction; produce full lesson drafts” on 2026-11-03. This supersedes
the earlier short-proposal-only production gate. Audio generation, publication and deployment
remain outside this authorization.

This packet delivers two complete **pt_BR article drafts**, an offline visual reader,
reusable question metadata and original diagram assets. The approved 18-slide storyboard is
the sequence reference; it is not presented as the final lesson deck. The Do phase is complete
when these artifacts are reviewable. Human Check/MOT-161 and native-environment checks remain
pending. There is no learner baseline or measured learning improvement.

## Sources and identity

- Specs baseline: `6a7f79aac330f29ac7c0471f7c3435530626f6b1`, the content-production epic after
  PRs #425, #366, #426 and #427. Source paths: `curriculum/README.md`, `curriculum/principles.md`,
  `curriculum/plan/paths/shared.yaml`, `curriculum/plan/courses/foundation.yaml`,
  `catalogs/knowledge-map.yaml` and `catalogs/reference-data.md`.
- Contracts: ADR-019 authored exercises, ADR-020 article content, ADR-043 classification,
  ADR-046 evidence and ADR-049 practice-first experience language; content-management
  exercises, diagrams, expanded content and web listening/authoring contracts.
- Capability source inspection: web `d3123e60c7c5e2ee3ececc81cf6f9f1a6639289f` and core
  `43ca1e1e29cfdec724a2a444ba8dd8c6f7dbcc00`, whose task PRs #207 and #212 were verified merged
  into their epics. These are source identities, not deployed-environment evidence.
- Content-production 1.3.0 and its draft-review guidelines govern these drafts.
- Author/self-review: AI-assisted drafting and deterministic checks. Human musical educator,
  pt_BR reviewer and learner walkthrough: not yet performed.

| Unit | Artifact | Outcome | Participation |
|---|---|---|---|
| A | [lesson-a.pt-BR.md](lesson-a.pt-BR.md) | Interpret natural note names/letters, use a labelled position reference and distinguish name from octave/register | Existing `sh-ear-first`, Notas, first planned article “Os nomes das notas: dó, ré, mi e C, D, E”; working draft title “Conheça as notas: nomes que você pode encontrar”; learner title “C, D, E…: o código que todo músico usa” (PO, 2026-11-07) |
| B | [lesson-b.pt-BR.md](lesson-b.pt-BR.md) | Count one/two semitone transitions on a reference and apply them to C major | Standalone; A is preparatory reading with an inline bridge; learner title “Nem todo passo é igual: o padrão da escala maior” (PO, 2026-11-07) |

Both are beginner and universal (`instruments: []`). Keyboard, guitar and bass are examples.
No new course/path is created. Their exact source-slot/standalone disposition was approved
in PR #426. No curriculum YAML is changed by this production packet.

## Complete learning flow

Each article begins with a separate application section: a practical situation, immediate
outcome and concrete connection to later subjects. Later subjects are motivation, not skills
silently added to classification.

A proceeds through the two name systems, a keyboard reference, octaves, the fretted references
and the study phrase Mi–Fá–Sol–Fá–Mi. B repeats the naming essentials, defines the counting
unit, compares E–F/C–D, teaches a reusable counting method, transfers it to a single string,
compares B–C, and reconstructs the C-major distance pattern. Both give the complete useful
method now, with feedback and a concrete next practice action.

Elapsed lesson/practice time is not estimated until a learner walkthrough provides evidence.
Any success statement describes a supported naming/counting task, not accurate/fluent/retained
mastery, absolute pitch or physical instrument proficiency.

## Classification and ID provenance

| Unit | Skill | Concepts actually taught | Scope and difficulty | Installed evidence |
|---|---|---|---|---|
| A | `interpret-note-names` | `note-names`, `octaves` | Universal; beginner | Expected skill ID `b172ca6a-311a-5ad6-ae5c-f249e7ecd55c` from core migration; destination installation unverified |
| B | `count-semitone-steps` | `tones-and-semitones`, `sharps-and-flats`, plus `major-scale` for the application | Universal; beginner | Expected skill ID `e63e430c-3569-5916-8ad5-850a4380a79d` from core migration; destination installation unverified |

The per-question/retry concept lists in [activities.json](activities.json) narrow classification
to the actual activity. For example, naming F does not assess octave knowledge, and a Mi–Fá
retry does not claim major-scale coverage. Instrument diagrams illustrate the universal
outcome; visual reading of the Mi string does not establish `find-notes-root-strings` mastery
across both Mi and Lá strings. No auditory skill is substituted for the visual outcomes.

`key` values in the articles and activities are local editorial handles, **not installed
content/exercise IDs**. `activities.json` is editorial metadata, **not an API payload**.
Before app authoring, resolve knowledge keys against the installed map, create ordinary
content/option IDs through supported authoring and persist `language_codes: [pt_BR]` on
both lessons and their independently reusable exercises.

## Activity inventory and evidence

Nine primary questions each have three single-choice answers, exactly one correct option,
a purpose-specific hint, rationale, distractor explanations and a complete follow-up question.
The nine follow-ups also have answers/hints/rationales. Stable local keys support revision
without conflating them with platform identities.

| Local key | What the learner does | Evidence boundary |
|---|---|---|
| `a-name-f` | Match Fá to F using the name table | Naming with a reference, not auditory identification |
| `a-octaves` | Compare C4/C5, then E1/E2 | Read the note name and octave indicator |
| `a-position-g` | Locate G in supplied labelled instrument diagrams | Reference interpretation, not unassisted whole-neck recall or performance |
| `a-phrase` | Read E–F–G–F–E in Portuguese | Interpret a short written musical indication |
| `b-ef` | Count E4→F4 | One transition rather than two displayed endpoints |
| `b-cd` | Count C4→C♯4→D4 | Two transitions, including the intermediate pitch |
| `b-transfer` | Transfer F→G counting to the same string | Same interval size in different registers; no physical proficiency claim |
| `b-bc` | Count B3→C4 | Adjacent pitches across a name/octave boundary |
| `b-major-pattern` | Reconstruct the seven distances of C major | Supported visual counting, not scale execution or transposition |

The offline reader uses ordinary radio inputs and keyboard-accessible disclosures for local
practice/self-check. It saves no responses and submits nothing to MotifPath. It has no score,
mastery calculation, automated playing assessment or audio controls. Closed feedback and
follow-up questions respect the proposed timing; the editable source contains all review states.

## Modalities and prerequisites

| Modality | A | B | Instrument-free route |
|---|---|---|---|
| Perception | Optional future diagram playback; omitted from required tasks because naming does not require auditory matching | Optional future playback of the counted steps; no auditory grading | Every required response uses text and labelled references |
| Visualization | Keyboard names, octave labels and full guitar/bass context | Keyboard/fret steps and proportional chromatic ruler | Point, read and count on the diagrams; text alternatives repeat essential coordinates |
| Lick vocabulary | No separate lick catalogue; one short study phrase is sufficient for the naming outcome | No separate lick catalogue | Read the phrase/step sequence without playing |
| Repertoire/application | Newly authored five-note study sequence, not a borrowed song/recording | C-major pattern and a four-note application | Read/translate/count with the supplied reference |
| Technique/time | Optional playing only after standard tuning/basic sound production is familiar | Optional slow movement on the same string | No physical action or speed threshold required |

A assumes no pitch recognition. It defines open string, nut, fret and octave notation locally.
Playing is optional; learners who do not yet tune/play use the complete visual route. B links
A's naming and octave sections and repeats the entire essential table/notation bridge inline.
Complements never hide the central method elsewhere.

## Assets, rights and accessibility

[assets/manifest.json](assets/manifest.json) records eight original SVG diagrams with source,
rights, precise text descriptions and fretted pitch/coordinate data. The views are technical
schematics, not photographs or demonstrations of hand technique. All fretted marks are
alternative positions on a named string; an open circle precedes the nut, and stopped markers
fall between fret wires. Guitar uses E2 and bass E1. The keyboard keeps all intermediate keys.

The C-major practice figure removes the answer-distance row while retaining orientation and
chromatic steps. The explanatory version retains the complete pattern. No auditory task
leaks an answer because no auditory assessment is claimed.

Every SVG has a title/description and each article supplies figure descriptions and text
references/tables. Color is reinforced with string names, line thickness, position labels and
open/filled marker forms. At phone width, diagrams scroll in their own figure while nearby
text alternatives remain readable. Human accessibility review and native app screen-reader
behavior remain pending.

The offline reader embeds Manrope regular/bold from the versioned presentation font kit.
The SIL Open Font License is retained as [assets/Manrope-OFL.txt](assets/Manrope-OFL.txt).
No third-party diagrams, songs, photographs or recordings are copied. No audio/video was
created. The neutral chromatic/scale examples are original technical renderings for this packet.

## Complementary-resource map

| Resource and exact section | When/purpose | Availability and language | Local alternative |
|---|---|---|---|
| This packet, A / “Um mesmo nome pode aparecer de duas formas” | Before B; translate names/letters | Included pt_BR draft, linked directly from B | Full table/notation bridge repeated at B's opening |
| `sh-read-chart` / A cifra / “Lendo uma cifra” | After A; connect note-name letters to chord names without confusing note/chord | Planned source entry; published course URL/access unverified | A explicitly distinguishes a note from the chord named C |
| `sh-ear-first` / Ouvido / “Achando uma nota de ouvido” | After these visual tasks; add auditory reference matching | Planned source entry; playback/access unverified | Required tasks use text/diagrams and make no auditory claim |
| `ac-foundation`, `el-foundation`, `ba-foundation` in `curriculum/plan/courses/foundation.yaml` | Broader instrument learning and shared checkpoints | Planned, pt_BR; no public/installed URLs claimed; no keyboard course confirmed here | Both lessons are usable without enrollment in another course |
| `el-rock-power-chords` / O braço / “As notas nas cordas Mi e Lá” | Later guitar transfer | Idea-stage, guitar-only; access unverified | A/B guitar reference supplies all positions used here |
| `ba-root-fifth-octave` / O braço / “As notas nas cordas Mi e Lá” | Later bass transfer | Idea-stage, bass-only; access unverified | A/B bass reference supplies all positions used here |
| [musictheory.net / Steps and Accidentals](https://www.musictheory.net/lessons/20), opening definitions | After B's keyboard comparison; reinforce one/two steps | English, public URL checked 2026-11-03; lesson cannot be inspected without JavaScript in the text browser, interactive behavior not verified | Complete E–F/C–D method in B |
| [Ableton Learning Music / Construindo escalas maiores](https://learningmusic.ableton.com/pt/advanced-topics/building-major-scales.html), opening through the whole/half-step pattern | After B's C-major application | Portuguese page text checked 2026-11-05; controls/playback not verified | Complete table, explanatory ruler and practice ruler in B |

Local plan references: `curriculum/plan/paths/shared.yaml`, `electric-guitar.yaml` and
`electric-bass.yaml`; all are inspected at the source revision above. External materials
are linked only. Their site content is not redistributed in this packet.

## Native delivery map and gaps

| Resource | Specified/native route | Current evidence and consequence |
|---|---|---|
| Articles and opening applications | Content nodes with rich content, ADR-020 | Source-supported; target-environment article rendering is unverified |
| Guitar/bass diagrams | Native fretted diagrams, inline diagram embeds, optional playback | Source editor/renderer exists; create/reconcile actual diagrams and positions before referencing app IDs |
| Keyboard diagrams | Article images with descriptions/text alternatives | Current inspected editor/viewer is fretted-only; do not represent the SVG as a working native keyboard diagram or clickable answer grid |
| Questions | Existing `text_response` choices and correct-option metadata, ADR-019 | Source-supported; option IDs, stored language, answer/feedback/retry flow need destination verification |
| Hints/rationales | Essential article paragraphs; optional rich-text expanded content | Reader disclosures are a preview treatment, not a new native PromptDocument node or guaranteed inline exercise-reveal feature |
| Targeted extra help | API `RemediationTarget` supports a published content-node reference or inline rich content | Current exercise form inspected does not expose remediation authoring; keep essential help inline and verify before promising a native recommendation |
| Classification | Source catalog + merged additive migration | Testcontainer installation passed previously; actual selected environment migration/IDs are still unverified |
| Language | Explicit lesson/exercise `language_codes: [pt_BR]` | Merged lesson-language control has request-level tests; actual environment save/reload remains pending |

Convert article copy to supported paragraph/image/diagram content and author questions through
the existing exercise/challenge routes. Do not paste arbitrary reader HTML fieldsets/details
into PromptDocument or add unsupported hint/rationale fields to the exercise API. Full metadata
stays in this packet until a supported native mapping is verified. No software feature is
silently added to make the draft appear installed.

## Final learner decks

MOT-189 · phase Do/Check · deck version 2 · 2026-11-07. Source: revision 2 of both articles
(PR #436), the 18-slide sequence sketch, and the presentation library from content-production
1.4.1. The sketch used placeholder styling (cream, teal, Arial). The decks keep its sequence
and diagram content and rebuild them on the brand library.

Version 2 follows PO feedback: slide copy is reduced to the essentials and the optional-resources
slide is removed. The full explanation stays in the articles, the teacher's sketch and each
slide's speaker notes; the external resources stay in the articles and the sketch.

| Deck | Slides | Sequence |
|---|---|---|
| [A](slides/lesson-a.pt-BR.pptx) | 11 | Cover · application opening · names/letters · keyboard · octave · fretboard vocabulary · guitar/bass E string · locating method · study phrase · success check and MotifPath practice · next lesson |
| [B](slides/lesson-b.pt-BR.pptx) | 13 | Cover · application opening · quick reference bridge · semitone/tone · keyboard distances · sharps/flats · counting method · E-string distances · natural half-step pairs · C-major ruler · Dó–Ré–Mi–Fá check · success check and MotifPath practice · next practice |

Worked demonstrations stay (F4 on the keyboard, Sol on the E string and the counting example);
the common counting error is in the notes. The nine questions and their follow-ups are not in the decks; they stay
in MotifPath practice. In A, fret 2 is left unnamed, as in the article.

| Check | Evidence | Status |
|---|---|---|
| Exercise exclusion | `tools/check-slides.py` compares every slide, table and note with 86 prompt/hint/rationale/feedback fragments and review-state labels, and looks for hidden slides. It fails on the sketch (slides 4, 8, 14) and passes both decks. | Pass |
| Package structure | The pptx skill's OOXML validator, baselined against the library template: all validations passed for both decks | Pass |
| Rendered slides | Every slide rendered with macOS Quick Look and inspected. Overflow, collisions and line breaks were corrected and the changed slides re-rendered. | Pass in AI visual inspection |
| Musical data | Diagrams generated from the article tables: E2/E1 open strings, F/F♯/G at frets 1–3, C4–C5 keyboard with all black keys, C-major positions 0,2,4,5,7,9,11,12 and distances 2-2-1-2-2-2-1 | Pass in AI source inspection; human educator review of the decks pending |
| Accessibility | Text alternatives for every diagram are in the speaker notes. Pictures have alt text. Color is reinforced by labels, line weight and marker shape. | Screen-reader check in PowerPoint pending |
| Native applications | Quick Look substitutes some glyphs and fonts; ♯/♭ may fall back to another font. | Open, edit, save and present in PowerPoint and Google Slides: pending |

Publishing or distributing the decks to learners needs separate PO approval.

## Quality and next phase

| Criterion | Self-check disposition | Evidence / remaining review |
|---|---|---|
| Dedicated application opening and later-subject relevance | Pass for draft | Separate opening sections precede explanation in A/B |
| Complete method and coherent transitions | Pass for draft | Name translation → reference/oitava; names → step count → scale pattern |
| Classification and scope | Pass at source level | Approved catalog keys, universal compatibility, per-question concepts; installed map still pending |
| Answers and numerical music data | Pass in deterministic self-check | Correct-option, MIDI-distance, C-major sum/pattern and fret-coordinate checks; human educator review remains required |
| pt_BR copy and notation | Ready for human review | Complete Portuguese copy and consistent names/letters; no human locale sign-off yet |
| Reference access, modality choice and rights | Pass for documented draft evidence | Exact section/status/alternative map, original diagrams, retained font license; external interactions untested |
| Reader layout and keyboard disclosures | Passed local Chromium checks | Two articles, eight visually inspected diagrams, 18 question groups, 54 options, keyboard feedback/retry, cross-lesson anchor and 390px page width; no page errors. This is not a full accessibility audit or native-platform verification |
| Native delivery and publication | Pending | Environment verification, human review and separate publication authorization |

Next phase: **Check**, led by the MOT-161 music/locale review and a learner walkthrough.
Ask the reviewer to attempt the questions with the provided support, note where naming or
transition counting fails, and record actual observations. The baseline is unknown. Do not
invent success rates, engagement gains, retention or fluent/mastery evidence from this draft.
