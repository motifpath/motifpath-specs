# First-notes review

MOT-161 · Check · review revision 1 · 2026-11-05 · AI editorial self-check.

## Disposition

**Revise**, with the focused findings below. Human music/pt_BR review, learner observations
and installed-map reconciliation are pending. The production draft remains sufficient
for the owner-approved MOT-160 handoff.

Reviewed [lesson A](lesson-a.pt-BR.md), [lesson B](lesson-b.pt-BR.md), all nine primary
questions and nine follow-ups in [activities.json](activities.json), the eight diagram
sources and descriptions, and [the production packet](production-packet.md).

The draft source is `3f83160ea9cff72dea7c831f3248c8f3e5382f1b`, merged in
[PR #431](https://github.com/motifpath/motifpath-specs/pull/431). On 2026-11-05, every file
and subtree SHA in this content directory matched that revision on the epic branch.
Review guidance is content-production 1.4.0, merged in
[PR #433](https://github.com/motifpath/motifpath-specs/pull/433). The proportional-check
clarification in PR #434 is still proposed.

## Selected checks and evidence

| Check | Evidence | Disposition |
|---|---|---|
| Sequence and practical value | A progresses from names to references, register and phrase translation. B bridges names to counted moves, a single-string application and a scale pattern. Each has a separate application opening and explicit future connections. | Pass in AI editorial inspection |
| Musical data and answers | Independently read the answer choices and rationales. Name pairs, same-name octave examples, E–F/B–C single steps, C–D/F–G double steps and the C-major pattern are consistent. Diagram sources use low E2 for guitar and E1 for bass, with stopped markers between fret wires. | Pass in AI source inspection, human music review pending |
| Existing content validator | Ran `node curriculum/content/first-notes/tools/validate.mjs` against the exact draft snapshot. Classification, question structure, MIDI differences, scale pattern, fret coordinates and preview structure passed. | Pass, limited to the implemented checks |
| pt_BR copy | The two articles explain names, accidentals, string/fret vocabulary and octave labels. Review findings include an exact-reference mismatch and a Portuguese complement now available. | Revise, human locale review pending |
| Classification and participation | A matches `interpret-note-names`, `note-names`, `octaves` and the existing `sh-ear-first` / Notas article. B remains standalone with `count-semitone-steps` and its taught concepts. The source catalog and plan support these choices. | Pass at source level, installed map pending |
| Resources and rights | Original SVG descriptions and font license are present. Essential method and naming bridge are inline. Internal complementary courses remain marked planned or idea-stage. | Pass in documented source evidence |
| Preview timing | Source inspection confirms a manual answer disclosure that can open before a choice. The reader tells the learner to respond first. | Record as learner-controlled self-check. Native timing decision pending |
| Desktop, phone and keyboard behavior | Production packet records prior Chromium checks. This review uses the unchanged draft source and retains those results with their original scope. | Prior evidence retained |

The selected checks reuse the existing validator. Human accessibility review and native
screen-reader behavior remain pending. No final PowerPoint exists in this content packet.
When one is produced, exercise proposals must be registered in MotifPath and excluded
from its slides, hidden slides and notes.

## Findings and proposed corrections

Severity reflects the effect on the proposed assessment or navigation. These are editorial
judgments from source inspection. The correction proposals await the next Do revision.

| Finding | Severity and location | Observation | Proposed correction and closure check |
|---|---|---|---|
| R1 | Medium · `a-octaves` follow-up | The original asks about both note name and octave. The follow-up asks only for the name of E1/E2 and explicitly tells the learner to set the numbers aside. Its inherited concepts still include `octaves`. | Ask “E1 e E2 têm o mesmo nome? Qual fica mais aguda?” and provide complete options/rationales. Close when the response distinguishes both name and register. Alternatively record the existing question as naming support and follow it with a register check. |
| R2 | Medium · `b-major-pattern` follow-up | The original reconstructs seven distances. The follow-up checks only Mi–Fá. It is useful as focused support, but gives no subsequent opportunity to retry the pattern. | Retain the local support, then return to the full pattern or a fresh multi-step counting example. Close when the documented flow shows an attempt after correction at the intended scope. |
| R3 | Low · B / “Uma referência rápida para começar” | The link targets A's naming table but the description also promises octave-number explanation, which is in a different section. The inline bridge keeps B usable. | Link the naming and octave sections separately, or narrow the link description. Close by following each reference and finding the promised explanation at its target. |
| R4 | Low · B / optional Ableton reference and packet resource map | The draft selects the English page. A Portuguese version of the same lesson is available and its opening text was checked on 2026-11-05. | Prefer the Portuguese page and label its language accurately. Retain English as an optional alternative if useful. Verify the translated passage with the locale reviewer and test any controls before relying on them. |

The other follow-ups maintain useful naming/counting practice at their stated scope.
A support question can deliberately be simpler. Its role and the return to the outcome
need to be visible in the authoring record.

## External source refresh

The major-scale pattern, adjacent E–F/B–C examples and accidental-spelling discussion
were checked against the publisher's lesson. Its Portuguese page also supplies a
more accessible complement for this pilot. [Ableton, Construindo escalas maiores](https://learningmusic.ableton.com/pt/advanced-topics/building-major-scales.html)

The standard guitar string order was checked against the manufacturer's explanation.
[Fender, Standard Tuning](https://www.fender.com/articles/setup/standard-tuning-how-eadgbe-came-to-be)

The musictheory.net page still requires JavaScript in the text browser. Its lesson text
and controls remain unverified in this review. The local lesson supplies the essential
method. [musictheory.net, Steps and Accidentals](https://www.musictheory.net/lessons/20)

These page checks cover published text. External audio and interactive controls await
runtime inspection.

## Human review session

Use the [offline reader](preview.html). Review its exact draft revision and record any
subsequent corrections before claiming a pass. Leave answers closed on the first pass.
The prompts below can be used for a learner walkthrough after reading each lesson.

| Point | Learner prompt in pt_BR | Observation to record |
|---|---|---|
| A / names | “Use a tabela para encontrar a letra de Lá. Como você encontrou?” | Chosen letter, lookup method, hint or help used |
| A / octaves | “D4 e D5 têm o mesmo nome? Qual indica a nota mais aguda?” | Whether the learner distinguishes the letter and octave number |
| A / diagram | “Encontre Sol na corda Mi grave de um dos desenhos. Aponte a corda e a casa.” | Interpretation of string, fret, open marker and label |
| A / phrase | “Leia G–F–E em português, mantendo a ordem.” | Whether names and sequence are preserved |
| B / counting | “Na régua, conte de Fá♯4 a Sol4. Depois conte de Ré4 a Mi4. Mostre cada mudança.” | Whether the learner counts moves, includes the intermediate position and uses the reference |
| B / transfer | “Na mesma corda, vá da casa 1 à casa 3. Quantas mudanças você contou?” | Whether the same counting rule transfers to a fret reference |
| B / application | “Na régua, explique as distâncias de Ré4–Mi4–Fá4.” | Whether the learner applies the rule to consecutive pairs |

After each response, allow the relevant hint or feedback and record what changes in
the explanation or next attempt. Use the available references. Record actual responses,
points of confusion and help given. The baseline and session duration are unknown.

The educator then inspects every answer and rationale, pitch/register label and diagram.
Check the optional fretting instruction against the illustrated orientation. Audio/caption
checks become applicable if those assets are later introduced. The pt_BR reviewer checks
musician vocabulary, symbols, octave convention and clarity for a beginner. One qualified
person may cover both review roles if their role and actual review are recorded.

| Record | Current value |
|---|---|
| Educator reviewer, date, exact revision and verdict | Pending |
| pt_BR reviewer, date, exact revision and verdict | Pending |
| Learner context, observed responses, support and confusion points | Pending |
| Installed map environment, key-to-ID evidence and discrepancies | Pending |
| Findings disposition and retest evidence | Pending |

## Reusable workflow observations

| Observation | Proposed rule | Evidence type | Check in a later lesson |
|---|---|---|---|
| R1/R2 pass structural checks while leaving part of the original task untested | Review what each response actually demonstrates, and identify the return from focused support to the intended outcome | Editorial judgment from this pilot | Trace one retry from mistake through correction to a fresh attempt |
| R3 points to a valid file but promises more than the linked section contains | Read the target section against the reference's stated purpose | Source inspection | Follow one essential prerequisite link and locate the promised explanation |
| R4 has a same-publisher Portuguese alternative | Check locale alternatives when selecting an external complement | Verified page text | Confirm the selected language before finalizing a resource map |

MOT-161 remains in progress until the correction dispositions, human reviews, learner
observations and installed classification evidence are recorded. MOT-162 follows with
native delivery validation and the release decision.
