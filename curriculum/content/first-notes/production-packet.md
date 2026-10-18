# First-notes pilot — production packet v1

**MOT-160 · Do · 1.0.0-draft · 2026-10-18.** Reviewable content and reference
assets, not published native lessons. Author: Codex. Human musical/locale reviewer:
pending (MOT-161). No learner evidence or baseline is available.

## Source and cycle record

Input: PO-approved `curriculum/pilots/first-notes.md`, merged epic revision
`5dd5707a9983ebda1f6c0f42bf8f880da7e314ab`, content-production v1.2.0 and its
approved 47-slide template. Curriculum/knowledge-map basis `1ba3947`.
Existing content checked: planned note-name article in sh-ear-first and idea-stage
root-string guitar lessons. No live installed content inventory could be established;
check duplication against the destination environment before authoring.

Plan: create useful note-name/distance knowledge, then one-string guitar application.
Do: full pt_BR copy, two editable storyboards, question/answer/rationale/retry data,
22 original synthesized audio references, two SVG diagrams, offline reader and a
captioned schematic guitar video preview. Narration script and timings accompany it.
Check: deterministic audio/assets/answer checks and presentation inspection. These
are AI/deterministic checks, distinct from human review and app runtime verification.
Act: propose editorial review, with unresolved gates listed below. No learner
improvement, retention or mastery has been inferred. Publication approval: absent.

## Unit identities and classification

| Field | notes-foundation | notes-one-string |
|---|---|---|
| Learner title | Conheça as notas musicais | Encontre suas primeiras notas na guitarra |
| Delivery | Curriculum article; storyboard as optional support | Standalone video/diagram reference plus complete written alternative |
| Placement | foundation; shared sh-ear-first, section Notas, lesson 1; ac/el/ba-foundation | None required; related idea-stage el-rock-power-chords is provenance only |
| Locale | pt_BR | pt_BR |
| Difficulty | beginner | beginner |
| Instrument scope | all (empty list) | electric-guitar |
| Skill | match-pitch / Achar uma nota de ouvido | find-notes-root-strings / Localizar notas nas cordas Mi e Lá |
| Concepts | note-names; sharps-and-flats; tones-and-semitones; octaves | note-names; sharps-and-flats; fretboard-landmarks; tones-and-semitones; string-names; standard-tuning |
| Installed ID evidence | Unresolved; resolve keys in target map | Unresolved; resolve keys in target map |
| Scope limit | Matching a supplied pitch; no absolute pitch | Only sixth string, frets 0–5; not the whole root-string skill |

Keys, kind and instrument compatibility passed against the source catalog in
MOT-159; recheck on content changes and reconcile with the installed map. Native
content has not been created, so do not substitute planning keys for installed IDs.
`applies` is not a prerequisite requirement. Practice remains accessible.

## Complete learner content and sequence

- [Unit A complete article](notes-foundation.pt-BR.md): opening phrase, names/letters,
  octave, semitone/tone, accidentals, reference matching, correction/retry and application.
- [Unit B complete text/script basis](notes-one-string.pt-BR.md): phrase, inline
  preparation bridge, positions, demonstration, location attempts, correction and application.
- [Audio and answer metadata](practice.json): six questions with feedback for every
  option, two pitch-matching references and an honest performance rubric.
- [Offline reader](preview.html): both units with local audio controls and diagrams.
  This is a portable editorial review surface, not a deployed MotifPath integration.
- Storyboard JSON and PPTX per unit: exact slide text, producer notes and audio order.
  Audio files are supplied separately, not embedded in the PPTX.
- [Guitar recording script](guitar-recording-script.pt-BR.md): timed narration and
  shot requirements. The supplied schematic preview has tones and text, not recorded speech.

The source brief defines outcomes and acceptance criteria. Unit A's tasks exercise
pitch comparison and explicit distances; Unit B applies the same method to positions
and an original phrase. No central method or necessary explanation is withheld.

## Prerequisites, modalities and alternatives

Unit A requires no instrument or theory. It includes all note names, an inline
semitone explanation and a visual path. Unit B assumes safe holding and standard
tuning, repeats open-string/fret vocabulary and links Unit A sections 2–4 for names
and distances. Its body contains a usable bridge even if that local reference fails.
The optional external source is English, open on production review, and unnecessary
to complete the Portuguese lesson. Review its availability at release.

Perception: named reference comparison, direction and octave examples in A; pitch
references in B. Visualization: semitone sequence and one-string map. Lick vocabulary:
only the short original phrases, no separate memorization catalogue. Repertoire:
original phrase application instead of copyrighted song excerpts. Technique/time:
comfortable playing cues only, no timing or technique grade. Each choice supports
the narrow outcome. Instrument-free routes use map decisions and audio comparison;
these never count as observed physical performance.

All audio is speech-free sine synthesis in 12-TET, A4=440. Descriptions and exact
pitch sequences are in `assets/manifest.json`; use neutral labels for blind options.
Do not present electronic references as guitar recordings. Reference matching is
not accessible through a text transcript alone; the alternative visual tasks assess
a different competency and must not receive an auditory score.

## Assets, rights and delivery mapping

| Asset | Source / rights | Accessible alternative | Native destination / evidence |
|---|---|---|---|
| 22 WAV clips | Original deterministic synthesis; no samples; generator included | Sequence descriptions in manifest; visually equivalent tasks with distinct evidence limits | Audio stimuli/options under existing authored-exercise model; exact app path unverified |
| semitones.svg | Original editable teaching diagram using brand tokens | Full written sequence in A section 4; SVG title/description | Article image or supported diagram mechanism after destination verification |
| one-string.svg | Original editable schematic, sixth string only | Table and textual positions in B section 3; SVG title/description | Article/video image; never claim arbitrary click-region grading |
| PPTX storyboards | Derived from approved MotifPath library, brand tokens and original mark | Complete article/script text | Recording/editorial support; PowerPoint/Slides import still needs native check |
| Schematic MP4 + VTT | Original slide frames and synthesized pitches | Written B; narration script; text captions | Review preview; not human performance footage or narrated final lesson |
| Manrope font files | Project @fontsource assets, SIL Open Font License supplied | System-font fallback may alter wrapping | Offline reader/presentation editing |

Original material is for the internal MotifPath pilot; publication rights clearance
remains a human editorial check. No external image, song recording, learner data or
person's performance is included. Source citations support facts and are not copied
course text. Generated template artwork is decorative, not technique evidence.

## Readiness record

| Criterion | Verdict | Evidence / open work |
|---|---|---|
| Useful outcome and complete method | Provisional pass | Complete drafts, active task, application and retry |
| Prerequisites / reference access | Provisional pass | Inline bridges and local links; external source optional |
| Musical correctness and answer keys | Human check pending | Deterministic frequencies/answer identity pass; musical/pedagogical judgment not replaced |
| pt_BR language and notation | Human check pending | Full Portuguese drafts; consistent Dó=C conventions; locale editor required |
| Classification and instrument compatibility | Catalog pass / installed blocked | Valid source keys; installed IDs unresolved |
| Modalities and feedback | Provisional pass | Choices, explicit omissions, alternative routes and option feedback |
| Accessibility and rights | Partial | Text/diagram/audio alternatives and provenance; actual device and human clearance pending |
| Curriculum alignment | Pass for A; N/A for B | Existing planned lesson; B standalone, no path promotion |
| Native delivery | Blocked for release | Article/media/exercise app test, correct pt_BR metadata and ID reconciliation pending |
| Physical demonstration / narration | Pending | Schematic preview only. Record/review actual hands footage if required and voiceover before describing either as supplied |

Notable app gap: `useContentNodeForm` defaults `language_codes` to `['any']` and
has no locale selector. Confirm a supported route that preserves pt_BR before
readiness. No application changes are included in this production packet.

## Observation and revision

Record chosen answers and recurring confusions only through supported evidence or
manual observation. Baseline unknown. Correct matching/location answers establish
those specific attempts, not physical fluency or retention. If semitone spacing,
counting positions, string orientation or fret/finger confusion persists, revise
that explanation and retry task. Next phase: MOT-161 Check on this exact revision.
Human musical/locale, performance media, metadata, accessibility and runtime findings
route back to Do; changed learning scope routes to Plan. No content is published.
