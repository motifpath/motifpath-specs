# First-notes pilot — MOT-159

**Status:** PO-approved subject and initial scope, 2026-10-18; production brief for
MOT-160. Individual content, assets and publication remain subject to review.

Gilson selected musical notes, tones/semitones and finding notes on instruments,
then approved a narrow first unit with shared foundations and one-string guitar
application. This replaces the proposed tablature/rhythm pair, which was not selected.
The two editorial working keys below identify packets, not installed content IDs.

## Superseding calibration — 2026-10-18

The product owner has restarted both units at Plan. The previous one-string-only
scope and required generated audio are superseded by
[first-notes-proposal-v2.md](first-notes-proposal-v2.md). All detailed v1 requirements
below remain historical context, not the current production authorization.
MOT-160/PR #366 contains the earlier production experiment; it is not approved for
continuation or publication. Review a short draft and diagram proposals before
producing complete units or media. Do not generate audio without an explicit request.

## Source basis and curriculum participation

Baseline: motifpath-specs `75c894818519002c2d56c0c8e6578ee2e29055c3`, including
content-production v1.2.0 and the approved 47-slide presentation library. Curriculum
and knowledge-map basis: `1ba3947`. Source review includes curriculum README,
principles, shared/electric-guitar paths, foundation courses, generated tree,
knowledge-map catalog and ADR-019/020/043/046/049.

| Unit | Participation and source | Locale, instrument, difficulty |
|---|---|---|
| notes-foundation | Curriculum article. Exact source: `sh-ear-first`, section `Notas`, lesson 1, “Os nomes das notas: dó, ré, mi e C, D, E”. The path is planned, used by ac-foundation, el-foundation and ba-foundation in the foundation track. Working learner title: “Conheça as notas musicais”. | pt_BR; all instruments (empty instrument scope); beginner |
| notes-one-string | Standalone unit with a short video demonstration and portable diagram/reference. Working title: “Encontre suas primeiras notas na guitarra”. Related catalog skill and the idea-stage `el-rock-power-chords` lesson “As notas nas cordas Mi e Lá” supply provenance only. This pilot does not claim that lesson/path is planned, place new content in it, or promote it. | pt_BR; electric-guitar; beginner |

The shared article's concept classification is extended in the plan to include
`tones-and-semitones` and `octaves`, because the approved scope uses those ideas.
Its identity, type and sequence stay the same. The generated tree must reflect that
source change. Lessons have no independent YAML keys, so locators use path key,
exact source title and 1-based lesson index. Standalone placement is not required.

## Unit A — Conheça as notas musicais

**Observable outcome:** with an audible reference and visual note sequence, the
learner names a target note, identifies its neighboring semitone and selects a
matching reference pitch. No absolute-pitch identification is expected.

Classification:
- Skill: `match-pitch` — “Achar uma nota de ouvido”, instruments `all`.
- Concepts: `note-names`, `sharps-and-flats`, `tones-and-semitones`, `octaves`, all `all`.
- Installed classification IDs and curated map reconciliation: pending authoring.

Prerequisites: none. Explain higher/lower pitch with an audible comparison and a
text alternative; distinguish pitch from loudness. Names are labels for sounds,
not a request to identify arbitrary pitches without a reference.

Required learning sequence:
1. Hear a short original three-note phrase and identify a higher/lower movement.
2. Connect Dó–Ré–Mi–Fá–Sol–Lá–Si to C–D–E–F–G–A–B. Give both complete sequences.
3. Introduce the octave as the repeating note-name cycle at a higher/lower register.
4. Show the usual Western 12-semitone octave with audio and a readable sequence.
   Explain one semitone and two-semitone whole tones through neighboring examples.
   Mi–Fá and Si–Dó are semitone pairs. Neighboring natural names are not equally spaced.
5. Introduce sharp/flat as one-semitone changes and show a shared-pitch example
   (Dó♯ / Ré♭ in the tuning used). Do not imply that every spelling is interchangeable
   in every musical context, or introduce key-signature rules in this first unit.
6. Ask for an active response: choose the same pitch as a named reference, locate
   a neighboring semitone on the visual, and explain one whole-tone movement.
7. Give answer/rationale, a specific correction and retry. End by following the
   original three-note phrase with the reference and naming its notes.

Keep labels away from an audio-only answer stimulus when they would reveal the
answer. Voice matching is optional self-assessment, never microphone grading.
An instrument-free route uses listening, visual selection and comfortable-range
vocal imitation if desired; it does not depend on owning an instrument.

## Unit B — Encontre suas primeiras notas na guitarra

**Observable outcome:** starting from the open sixth string in standard tuning,
the learner locates and plays Mi, Fá, Sol and Lá within frets 0–5, and uses fret
steps to find Fá♯ and Sol♯ when prompted.

Classification:
- Skill: `find-notes-root-strings` — “Localizar notas nas cordas Mi e Lá”, alias
  `fretted` includes electric-guitar. This pilot practises only the Mi-string subset;
  completion cannot establish mastery across both Mi and Lá strings.
- Concepts: `note-names`, `sharps-and-flats`, `fretboard-landmarks`,
  `tones-and-semitones`, `string-names`, `standard-tuning`.
- Resolve each concept's instrument scope and installed IDs before authoring.

Prerequisites: safe instrument/pick position, standard tuning, and the shared
unit's vocabulary. Provide a brief inline bridge for open string/fret numbering,
standard sixth-string Mi and one-fret semitone movement. Reference exact sections
of Unit A after they exist. Do not invent published URLs for pending units.

Required learning sequence:
1. Demonstrate a short original phrase on one string, then name its notes.
2. Explain that each adjacent fret raises the pitch by one semitone on the same
   string. Demonstrate Mi(0), Fá(1), Fá♯(2), Sol(3), Sol♯(4), Lá(5).
3. Show one semitone and one whole-tone move. Keep diagrams large and editable;
   label string orientation, tuning, fret numbers and the open-string position.
4. Ask the learner to locate a note visually, then play it if an instrument is
   available. Supply reference audio, fingering guidance and an honest self-check.
5. Correct confusion between fret number, finger number and note name. Retry
   from a known note rather than asking the learner to memorize the whole neck.
6. Apply the notes to an original phrase such as Mi–Fá–Sol–Fá–Mi, with a complete
   demonstration. Keep tempo comfortable; speed is outside the learning promise.

Instrument-free route: identify/select positions on the labelled diagram and
compare reference audio. This demonstrates location reasoning, not physical
performance. Acoustic-guitar/bass adaptations are later options, not additional
pilot units or new instrument support promised by this brief.

## Modality choices and asset requirements

| Modality | Shared foundation | Guitar application |
|---|---|---|
| Perception | Pitch direction, octave reference, reference matching | Compare the target note with a reviewed reference |
| Visualization | Note-name cycle and tone/semitone distances | One-string diagram, open string and frets 1–5 |
| Lick vocabulary | Omit a separate vocabulary catalogue | One original phrase only |
| Repertoire/application | Original three-note phrase | Original one-string phrase; no licensed song required |
| Technique/time | No physical technique assessment | Basic safe playing cues; no speed/technique grading |

Produce scripts, complete learner copy, diagrams, audio, video/storyboard, answer
keys, rationale, feedback and retry instructions in the versioned production
packets. Use the approved presentation library where useful. Record every asset's
source, rights, captions/transcript/description and accessible alternative. Generated
instrument artwork may decorate a frame; it cannot demonstrate correct hand motion.

## Delivery capability matrix and known gaps

The following evidence is source inspection, not a running-environment test. Web
revision inspected: `44531e3a9cdad827445e2a8c756825971c161062`; core checkout revision:
`0f71a50a5fcbf198be370b6d8f5c624784faa88d`.

| Capability | Specified | Implemented evidence | Verified / consequence |
|---|---|---|---|
| Article and rich media | `createContentNode`, rich_content, ADR-020 | `ArticleLesson.vue`, `PromptRenderer`, `useContentNodeForm.ts` | Runtime pending; inspect actual diagram/text rendering |
| Video/media URL | `createContentNode`, media_url | `VideoSource.vue`, `useVideoUpload.ts`, content form | Runtime pending; real original recording and playback required |
| Classification and instrument scope | ClassificationInput, ADR-043 | Content form maps IDs, scope, difficulty and missing fields | Installed IDs/map reconciliation pending |
| pt_BR metadata | Inspect content-node language_codes contract before writing | New content form defaults to `['any']`; no language selector | Verify a supported pt_BR authoring path; Portuguese text alone is insufficient |
| Choice/audio exercises | ADR-019 authored options and answer checking; createExercise | ExercisePreview exposes option answers | Verify exact student stimulus/selection/feedback/retry; do not infer audio-option behavior from preview alone |
| Singing/playing assessment | No automatic pitch/technique grader established for this pilot | No implementation evidence asserted | Manual/self-assessment only; no fabricated score or mastery state |
| Presentation application | MOT-158 PPTX/POTX | Structural, render and first-party re-import checks passed | Native PowerPoint/Google Slides import/edit/present pending |
| Curriculum intent/track metadata | README lists intent/app gaps | No new implementation asserted | Keep editorial provenance; do not invent app fields or publish a new curriculum |

## Acceptance, observation and next phase

Success evidence is a correct named-reference match/location decision and an
observable attempt with useful feedback. Record pre-attempt familiarity if available;
otherwise baseline is unknown. Observe recurring errors (Mi–Fá spacing, skipped
accidentals, string direction, fret/finger confusion) to guide revision. No retention,
fluency or motivation claim follows from completing the lesson or deck.

Principles 2, 7, 10 and 15 motivate first-session usefulness, theory through use,
short sessions and standalone value. Research hypotheses in principles remain
hypotheses; this editorial selection supplies no learner results.

Plan selection is complete with the PO's subject approval and this explicit route
mapping. The source concept expansion is reviewable separately. Next: MOT-160 Do,
producing reviewable drafts and assets. Human musical/locale review, valid installed
classification, metadata, rights/accessibility and native delivery verification are
release gates. No content has been published by approving this pilot.
