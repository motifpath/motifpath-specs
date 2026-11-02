# First notes: visual review checkpoint

MOT-160 · pt_BR · beginner · Plan/Check · revision 1 · 2026-11-02.

This packet carries the visual draft revised with the product owner in the MOT-160
session into PR #366. It supersedes the prose-only review format of
[first-notes-proposal-v2.md](../first-notes-proposal-v2.md), while preserving its two
universal outcomes, explicit audio gate. The classification/placement decision below was subsequently approved.
It is a preliminary editorial storyboard, not a complete lesson or installed experience.

## Review artifacts

- [Visual preview](preview.html): self-contained HTML with all 18 slides, accessible
  text transcripts, review notes and a complementary-resource map. Download/open the HTML
  locally; GitHub's source view does not render the preview.
- [Editable slides](first-notes-visual-draft.pptx): the same 18-slide review sequence.
- [Classification and readiness](#classification-and-readiness): evidence and open gates below.

Source baseline: epic merge `a8dcd5e` (PR #425, content-production 1.3.0), pilot proposal
`55d7170`, the local curriculum/catalog files at that baseline, and the product-owner
feedback in this session. The historical full-production experiment at `98905d4`
remains superseded. No historical audio/video is reintroduced.

## Syllabus and transition review

| Slides | Purpose | Connection to the next step |
|---|---|---|
| 1–2 | Author review cover and proposed program | Establish the two outcomes and deliberate exclusions |
| 3 | Lesson A: dedicated application opening | A request to play the **note** F motivates matching the two naming systems |
| 4–5 | Dó–Si / C–B and labelled keyboard reference | Once the learner names a note, compare its occurrence in another octave |
| 6 | Octave repetition | Same name can occur at different registers, including across instruments |
| 7–8 | Recognizable guitar/bass fretboards and practice | Locate named notes with a reference, then distinguish E2 and E1 |
| 9 | Lesson B: dedicated application opening | “Go up a tone” motivates turning distance into a movement |
| 10–11 | Bridge and keyboard distances | Mi–Fá versus Dó–Ré motivates counting every intervening key |
| 12 | Distance on the highlighted E string | Apply one/two-step reasoning on the same string of either instrument |
| 13–14 | C-major distances and practice/feedback | Transfer the same count to a scale and a new pair of notes |
| 15–18 | Author review: cohesion, complements and decisions | Assess the program, resources and remaining gates together |

Author review pages are not learner lesson pages. Dedicated application openings remain
separate slides in learner delivery. Later subjects explain relevance without becoming
prerequisites: note names support chord names, scales and melodies; distances support
intervals, transposition and studying chord/harmonic construction.

## Incorporated product-owner feedback

- Show proposed diagrams in the draft rather than asking the reviewer to imagine them.
- Replace visible production IDs with descriptive titles.
- Use “Prática”, “Sua vez” and “Pratique de novo” for learner prompts.
- Show full guitar/bass string context, highlight and name the low E string, distinguish
  open strings, label nut/frets and place stopped markers between fret wires.
- Separate immediate usefulness from future learning on a dedicated opening per lesson.
- Preserve universal scope with keyboard, bass and guitar examples and a text-based route.
- Explain “play the note F” explicitly to avoid interpreting F as a chord instruction.

## Resource and capability evidence

The HTML resource map names exact internal path/lesson sections and external sections,
when to use them, purpose, language/access limitations and local alternatives. Internal
references are editorial plan locators, not installed course URLs. Foundation courses
are `planned`; the guitar/bass extension paths identified there are `idea`.

External references are optional links to musictheory.net's *Steps and Accidentals*
and Ableton Learning Music's *Building major scales*. Text/section evidence was checked
on 2026-11-02; interactive playback and destination accessibility remain untested.
No third-party images, recordings or exercises are copied into this packet.

The diagrams are original editable schematic objects. The preview includes text
transcripts; native PPTX screen-reader behavior and destination rendering still need
verification. Questions, hints, answers and feedback shown together are review states,
not implemented answer submission or automatic grading. No audio was generated.

Native contract references remain those of proposal v2: diagrams, listening from a
diagram, exercise sounds and reusable exercises. These contracts do not prove that
arbitrary reveal interactions, keyboard answer behavior or clue-content links work.

## Classification and readiness

The product owner approved [the classification and placement decision](classification-proposal.md)
on 2026-11-02. The catalog now defines the two universal skills; lesson A occupies the
existing `sh-ear-first` / Notas slot and lesson B is standalone. Installed-ID reconciliation
remains pending. The 18-slide preview is the earlier review snapshot; use this decision and
the table below for the current classification state.

| Unit/resource | Existing compatible concepts | Skill evidence and disposition |
|---|---|---|
| A: names and octave references | `note-names`, `octaves`, both universal | `interpret-note-names`, universal beginner; auditory matching remains outside these tasks |
| B: distance counting | `tones-and-semitones`; `sharps-and-flats` for the intermediate-key explanation; `major-scale` for the C-major application | `count-semitone-steps`, universal beginner; classify the C-major application with `major-scale` only where taught |
| Instrument-specific location examples | Select only concepts actually taught by each resource | `find-notes-root-strings` is fretted-only and covers Mi and Lá. A Mi-only visual example cannot establish mastery across both strings or classify a universal parent |

Evidence: `catalogs/knowledge-map.yaml`, universal concepts and skill entries
`match-pitch`, `hear-intervals`, `find-notes-root-strings`. The two added skills were explicitly approved by the product owner; no installed ID is
claimed. Beginner is the editorial difficulty. Lesson A's YAML classification is updated;
lesson B remains standalone. Installed classifications remain unverified.

| Gate | Current evidence / next action |
|---|---|
| Visual draft and session corrections | Included; revisions address the specific feedback. Acceptance of the complete sequence remains pending |
| Musical/locale accuracy | AI editorial self-check only; MOT-161 human review still required |
| Brand production baseline | This schematic review draft preserves the session's visual treatment. Final production must use the approved Manrope/brand library and receive a visual check |
| Universal skill classification | PO approved `interpret-note-names` and `count-semitone-steps`; source catalog updated, installed IDs pending |
| Curriculum position | PO approved A in `sh-ear-first` / Notas and B standalone; no new path or idea-stage promotion |
| Native behavior | Verify diagram rendering/playback, answer types, clues, feedback and keyboard/text alternatives in the destination |
| Locale persistence | Verify `pt_BR` metadata and installed IDs; Portuguese copy alone is insufficient |
| Release | No full-production, publication or epic-promotion claim follows from this checkpoint |

Next review: use slides 3–8 for lesson A's purpose, naming method, octave bridge and
instrument examples, then slides 9–14 for lesson B's purpose, distance reasoning and
application. Record changes against slide numbers or resource names. Reconcile the approved classification with installed IDs before readiness; produce final lessons only after draft direction is accepted.
