---
name: content-production
version: 1.0.0
description: Produce, adapt or review MotifPath lessons, exercises and practice resources with practical outcomes, knowledge-map classification and locale-specific language. Use for editorial content production and content presentation storyboards; software implementation and curriculum redesign remain separate tasks.
---

# Content production

Produce a small usable learning outcome, not an exposition of a topic. Write the skill's
instructions in English; write each learner-facing unit in its declared language.
Use [the content template](references/content-template.md) for the production packet and
[the presentation proposal](references/presentation-proposal.md) when storyboarding or
considering Google Slides.

## Read the living sources first

Find the current motifpath-specs checkout. Paths below are relative to its root; do not
resolve them against this plugin's installed cache. Read repository instructions and record
source revision/date before drafting:

- `curriculum/README.md`, `curriculum/principles.md`, relevant `curriculum/plan/` YAML and
  `curriculum/tree.html`. The YAML is the editable plan; the tree is generated, never hand-edited.
- `catalogs/knowledge-map.md` and `.yaml`; relevant diagram/drill/chord catalogs.
- ADR-019 (authored exercises), ADR-020 (article authoring), ADR-043 (classification),
  ADR-046 (practice evidence) and ADR-049 (practice-first experience language), including amendments.
- Relevant `features/content-management/`, `features/practice/` and OpenAPI contracts for
  each proposed interaction. Verify actual app support separately; a spec is not runtime evidence.

Inspect existing content and references to avoid duplicates. Resolve material source conflicts
explicitly. Do not treat old Notion snapshots, generated views or draft hypotheses as overriding
current contracts. If sources are unavailable, state the missing source and keep affected work
as a draft. Do not fabricate plan entries, catalog nodes, asset URLs or runtime capabilities.

## Define the unit

Establish target learner, instrument, language/locale, one observable outcome and a real
musical use. Ask one focused question if a missing choice materially changes the content;
continue independent work. Declare curriculum participation explicitly:

- **Curriculum unit:** name the course/path/lesson keys, relevant principles, sequence,
  assumptions and closing application. Follow the current content plan. If a change is needed,
  propose the source edit for review before claiming alignment; regenerate the tree from YAML.
- **Standalone unit:** classification and all quality rules still apply; course/path placement
  is not required. Read principles for context without inventing a curriculum obligation.

## Author for practical value

1. Open with something the learner can hear, play, recognize or solve, and explain why it helps.
2. Give the complete useful method now. Remove padding, teasers and withheld steps. Keep scope
   narrow rather than deleting necessary explanation. A shorter unit is not better if unusable.
3. Demonstrate the method, then ask for an active attempt and provide actionable feedback,
   common-error correction and a way to try again. Every element states its learning purpose.
   A warm-up must explain what it develops, such as alternate picking or hand synchronization.
4. Make prerequisites reachable: explain what is assumed, link the exact internal unit or
   external section, why it matters and how to use it. Check availability/language/access.
   Add a brief inline bridge or accessible alternative when an essential dependency fails.
   References complete the unit; they must not hide its central technique elsewhere.
5. Apply it to a musical phrase, groove, lick or repertoire fragment. Finish with an observable
   success check and a useful next practice action, without withholding today's payoff.

## Choose modalities by learning purpose

Assess perception, shapes/visualization, lick vocabulary and repertoire, plus technique/time
where relevant. Record why each is included or omitted; do not add every modality mechanically.
Connect useful modalities around the same outcome. Prefer portable instrument-free practice
when it teaches something real, alongside instrument application when appropriate.

Use image, audio and clickable regions as composable resources, plus supported article/video,
diagram, exercise and practice-item capabilities. Specify stimulus, response, answer/rationale,
feedback, retry, instrument context and accessible alternative. Separate media playback from
answer submission and avoid visual labels leaking an ear-training answer. Do not promise
microphone grading, arbitrary hotspots or automated technique assessment without verified support.
Describe performance self-assessment honestly; a completed slide or lesson is not mastery.

## Classify and localize before readiness

Every unit needs existing knowledge-map skill and concept keys, difficulty and instrument scope.
Use skills as actions, concepts as knowledge. Validate keys, kind and instrument compatibility;
resolve keys to installed IDs when authoring in the app. The installed map may have curated
changes after its migration: reconcile it with the catalog before publication. If a fit is
missing, request curator review and keep the unit blocked for publication; never invent a node
or use a vague tag to disguise a gap. Style is content metadata, not a new graph branch.
`applies` does not imply `requires`; graph readiness never locks practice (ADR-043).

Use the declared locale's musician vocabulary, note names, chord symbols, rhythmic notation,
fingering conventions and dialect consistently. Explain unavoidable borrowed terms. Catalog
names follow the catalog's language keys (`pt_BR`, `en`); display locale codes may differ.
A translation is another language-specific unit, reviewed for meaning and musical convention,
not a mixed-language field. Keep English terms musicians actually use where appropriate.

## Review and deliver

Return the filled template, asset/interaction inventory, classification evidence, references,
curriculum applicability and unresolved gaps. Include a short quality verdict with pass,
revise or blocked and reasons for each criterion:

- Practical outcome and value per element; complete method without withholding.
- Sufficient context and usable prerequisite references.
- Musical/answer accuracy, localization, classification and instrument compatibility.
- Purposeful modalities, active attempt, feedback and application.
- Accessible media/interaction alternatives and documented rights/attribution.
- Conditional curriculum conformity and verified delivery capability.

Separate editorial readiness, runtime verification and publication approval. Generated content
and classifications require human musical/editorial review; AI output is not evidence of truth.
Do not publish content, change shared catalogs or send external messages without task authority.
Record observations and available lesson/practice evidence for later revision; never invent
learning metrics or treat content completion as accurate/fluent/retained mastery.
