# First notes: classification and placement decision

MOT-160 · Accepted by the product owner in this session · 2026-11-02.
Source: merged pilot checkpoint PR #366, epic revision `99a6d30`.
The product owner explicitly approved the recommended skills and placement. This branch
implements the catalog and lesson A plan changes. Installed IDs, the complete lesson direction
and publication are separate decisions.

## Accepted decision

1. Add two beginner universal skill definitions under the existing `reading` skill root:
   **Interpret note names** and **Count semitone steps from a visual reference**.
2. Keep lesson A as the first article in the existing `sh-ear-first` / Notas section.
   Replace its current auditory skill classification with the approved naming skill.
3. Keep lesson B standalone for this pilot, with the approved distance-counting skill.
   Reference A as a prerequisite with an inline bridge. Do not create a new path or promote
   an idea-stage path merely to place B.

This preserves the MOT-159 requirement to exercise a curriculum route and a standalone
route while respecting the later PO decision that both lessons teach universal knowledge.
Keyboard, bass and guitar remain examples, not restrictions on the universal parent.

## Proposed skill definitions

The keys below are now defined in this branch's catalog under the approved universal
`reading` parent. They still require environment installation before app authoring can
resolve them to installed IDs. The names stand alone in filters and chips.

| Field | Lesson A skill | Lesson B skill |
|---|---|---|
| Catalog key | `interpret-note-names` | `count-semitone-steps` |
| en | Interpret note names | Count semitone steps from a visual reference |
| pt_BR | Interpretar os nomes das notas | Contar semitons com uma referência visual |
| Parent | Existing `reading` skill | Existing `reading` skill |
| Instruments | `all` | `all` |
| Editorial calibration | B / beginner | B / beginner |
| Core concepts applied | `note-names`, `octaves` | `tones-and-semitones`, `sharps-and-flats` |
| Observable action | Relate Dó–Si to C–B and distinguish a repeated name from its octave/register indicator in supplied references | Count transitions in a complete ordered pitch reference and distinguish one semitone from two |
| Excluded claims | Absolute pitch, auditory matching, staff reading, physical fretboard fluency | Auditory interval identification, interval quality naming, scale transposition, chord construction or physical performance |

`major-scale` belongs to B's specific C-major application, not every distance-counting
activity. Physical string/tuning/fret concepts belong only to the relevant instrument
examples. Future subjects mentioned in an opening are motivation, not automatically
classified skills or assessed concepts.

Why `reading`: these actions interpret written pitch names or an ordered visual reference.
They do not require hearing a stimulus or executing a physical technique. A new root is
unnecessary for two bounded skills; reject this parent if curatorial semantics reserve
`reading` strictly for notation systems and select a compatible universal parent instead.

No new `requires` edges are proposed. Editorial order A before B does not automatically
establish a measured graph prerequisite. `applies` does not imply `requires`, and readiness
must never lock practice (ADR-043).

## Why existing skills do not fit

| Existing skill | Scope/action | Reason not to reuse for the universal unit |
|---|---|---|
| `match-pitch` | Universal auditory pitch matching | Matching F to Fá on a reference does not demonstrate hearing or reproducing a pitch |
| `hear-intervals` | Universal interval recognition by ear, EI | Counting keys/cases visually is not auditory interval recognition |
| `find-notes-root-strings` | Fretted location on Mi and Lá strings | Cannot classify keyboard examples or a universal parent; the current Mi-only examples also do not establish both-string fluency |
| `read-standard-notation` | Guitar staff reading in open position | The pilot does not teach staff reading, and the scope is instrument-specific |
| `play-major-scale-open` | Guitar scale performance | Reading the C-major distance pattern does not demonstrate performing a scale |

Evidence: [knowledge-map catalog](../../../catalogs/knowledge-map.yaml),
[catalog rules](../../../catalogs/knowledge-map.md),
[ADR-043](../../../adrs/ADR-043-skills-and-concepts-knowledge-graph.md).
No existing key is renamed or broadened, which would silently change historical evidence.

## Proposed evidence and exercise mapping

Use the existing authored-exercise route, subject to destination verification, rather than
inventing a new practice item kind. ADR-046 already includes authored exercises in the
practice model. [Exercise contracts](../../../features/content-management/exercises.feature)
include text and image recognition/choice; they do not prove arbitrary keyboard-answer cells.

| Task | Stimulus and response | Answer/rationale | Evidence boundary |
|---|---|---|---|
| A1: translate a name | Written prompt “Qual letra representa Fá?”; select F among named text choices | F; the naming systems refer to the same note name | Classifies name interpretation, not sound recognition |
| A2: distinguish register | C4 and C5 labelled on an image; choose same note name / different octave | Both are Dó; octave numbers differ | Classifies symbolic register interpretation, not an absolute-pitch test |
| B1: one step | Ordered E4, F4 reference; choose one or two semitones | One; a single transition connects the adjacent pitches | Count transitions rather than displayed endpoints |
| B2: two steps | C4, C♯4, D4 reference; choose one or two semitones | Two; the intermediate key contributes a second transition | An available reference supports reasoning; it does not establish memorized recall |
| B3: transfer | F, F♯, G on the same illustrated guitar or bass string; choose distance | Two semitones / one tone | The answer does not establish physical playing skill |

Use labelled references during teaching. If measuring recall later, remove only the answer
being assessed while retaining orientation. Do not let an answer printed on the same
learner screen masquerade as independent retrieval evidence. Static author review pages
can show the complete prompt/hint/feedback sequence together.

Do not invent a fluency threshold, mastery score or new grader. Confirm the native authored
exercise response/options, evidence linking, feedback and retry behavior before installation.
Text/image-choice fallbacks can avoid reliance on unverified keyboard hit regions. Optional
playback adds perception support without changing what these questions assess.

## Approved placement

- **A:** use the existing `sh-ear-first` lesson titled “Os nomes das notas: dó, ré, mi e C,
  D, E”, section Notas, as the source slot. Keep the path's main ear-training outcome;
  this visual foundation prepares vocabulary rather than granting auditory progress.
  Classify A with the naming skill plus only the concepts its resources actually teach.
  Keep the planned status. The foundation courses already reference this shared path.
- **B:** standalone, universal, beginner, pt_BR. No new course/path key is required.
  Explicitly reference A's naming table/section as preparatory reading. Repeat Dó=C through
  Si=B and the meaning of octave labels locally when needed, so access to A is not essential.
  Its C-major example is a transfer task, not approval to teach the complete harmony curriculum.

This branch changes the catalog and A's YAML classification together and regenerates the
curriculum tree. Validate scope/keys/graph and inspect resulting flags. Reconcile installed
IDs separately. B's standalone packet must still have a valid skill and concept classification.

## Alternatives considered and accepted disposition

- **Accepted and implemented in this branch:** the two narrowly observable skills and
  A-curriculum/B-standalone placement. Source validation confirms the catalog change only
  adds these two skills and their four `applies` links; the tree regenerates with zero flags.
- **Retain existing catalog:** keep this as an unclassified editorial draft. Publication stays
  blocked; do not attach auditory skills merely to make validation pass.
- **Change the learning outcomes:** redesign around auditory matching or instrument-specific
  performance. This reopens the accepted universal visual draft and needs a new PO decision.

Acceptance evidence: the product owner selected “Approve the recommended skills and
placement” in response to the explicit two-skill and A-curriculum/B-standalone decision.
This supersedes the earlier proposal-only status; merging documentation alone was not approval.
Reference-data delivery must reconcile the new catalog with the core installation and its
frozen-catalog test counts (previously 219 skills / 366 applies; now 221 / 370). No core
migration or tests are changed by this source-spec PR. The full Python compiler was not run
in this session because PyYAML is unavailable; the targeted Node/YAML validation checks the
approved nodes, compatibility, unchanged baseline graph and curriculum scope.

Final musical/locale review, native support, pt_BR persistence, final branded production and
publication remain separate gates.
