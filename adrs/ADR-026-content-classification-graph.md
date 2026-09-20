# ADR-026: Content classification becomes a knowledge graph — hierarchical Skill/Concept entities, Exercise linkage, a 5-level difficulty rubric, and a decided remediation rule

**Status:** Accepted
**Date:** 2026-09-19
**Deciders:** Gilson (Product Owner)

---

## Context

This is PB-33 ("content classification as a knowledge graph"). Today, `ContentNode.classification`
is three scalars — `skill: string`, `concept: string`, `difficulty_level:
enum(beginner|intermediate|advanced)` — embedded directly on the node, not a separate entity.
`Challenge.subject_tag` is validated against exactly that one skill or concept string on the
node it belongs to. `Exercise.skill_tags` (ADR-019/PB-42) is a separate, freeform `string[]` with
no backing entity. No production data exists in any of these tables yet.

This model has three concrete gaps:

1. **A `ContentNode` can express only one skill and one concept.** Real lesson content routinely
   teaches more than one — a video covering both `alternate-picking` and `string-muting` under
   the concept `right-hand-technique` has nowhere to record the second skill.
2. **Classification is flat, but real skill/concept taxonomies are hierarchical.** Content should
   be classifiable at whatever specificity actually fits it — a broad root concept for a survey
   lesson, or a specific leaf (`alternate-picking` under `right-hand-technique` under
   `guitar-technique`) for a focused one. A flat set of tags cannot express that one skill is a
   specialization of another.
3. **`Exercise` is classified only by freeform tags, disconnected from `ContentNode`'s
   classification entirely.** A student's practice pool (via skill-targeted practice sessions)
   and a `ContentNode`'s classification currently have no shared vocabulary — an exercise tagged
   `alternate_picking` and a content node classified under a skill also named `alternate-picking`
   are two unrelated strings that happen to look similar.

**A hierarchy also means names are no longer globally unique.** Two different branches can
legitimately have a same-named node (e.g. `technique` under `picking` vs. `technique` under
`rhythm`) — different entities that happen to share a label. Any API design for this has to keep
those two unambiguous.

**Alternatives considered for the classification model:**
1. Widen `skill`/`concept` to `string[]` in place — keep them freeform, no new entities.
2. Make `Skill`/`Concept` first-class entities, flat (not a tree), with `ContentNode` requests
   carrying plain name arrays the server resolves via find-or-create.
3. Make `Skill`/`Concept` first-class **tree** entities (self-referential `parent_id`), with
   explicit CRUD (`POST /skills`, `POST /concepts`) and `ContentNode`/`Exercise` requests
   referencing existing nodes by ID, not name.

**Alternatives considered for linking `Exercise` to the tree:**
1. Leave `Exercise.skill_tags` freeform and unconnected, as ADR-019/PB-42 originally chose.
2. Replace `Exercise.skill_tags` with `skill_ids`/`concept_ids` referencing the same `Skill`/
   `Concept` tree `ContentNode` uses — one shared classification vocabulary across both resources.

**Alternatives considered for the remediation rule:**
1. Recommend any `ContentNode` linked to the failed challenge's subject skill/concept, excluding
   nodes the student has already completed, ordered by difficulty ascending.
2. Leave classification-driven remediation undecided; keep `Exercise.remediation_targets`
   (ADR-023) as the only remediation mechanism.

## Decision

### Skill and Concept are first-class, hierarchical entities, referenced by ID

Each `{skill_id/concept_id: uuid, name: string, parent_id: uuid | null}` — `parent_id` null means
a root node; any node may have children, to any depth (open-ended, no fixed number of levels).
`name` is unique among siblings sharing the same `parent_id` (including among other roots, for
`parent_id = null`), not globally — two nodes in different branches may share a name.

`POST /skills` and `POST /concepts` each take `{name, parent_id?}` and create one node — a
teacher (or the authoring UI on their behalf) picks an existing node from the tree or creates a
new one under a chosen parent (or as a new root, omitting `parent_id`). `GET /skills` and
`GET /concepts` return the full flat list (`id`, `name`, `parent_id`) — the shape a client needs
both to render the tree for browsing/creation and to resolve any node's breadcrumb by walking
`parent_id`, sorted by name within their level. There is no update or delete endpoint yet;
re-parenting or deleting a node with existing links is a real question left for whenever a
concrete need for it shows up.

### ContentNode and Exercise both reference Skill/Concept by ID, not name

`ContentNode` moves from single `skill`/`concept` strings to many-to-many relations:
`ContentNode ↔ Skill` and `ContentNode ↔ Concept`, each requiring at least one entry. A node may
be classified at whatever depth actually fits its scope — a root, a leaf, or several nodes at
different depths in the same request.

`Exercise.skill_tags` (freeform strings) is removed and replaced the same way: `Exercise ↔ Skill`
and `Exercise ↔ Concept`, each requiring at least one entry, using the same tree `ContentNode`
uses. An exercise and the content node(s) it's linked to as a path exercise, or the challenge(s)
it's part of, can now share real classification, not three independent, uncoordinated tagging
schemes.

`CreateContentNodeRequest`/`UpdateContentNodeRequest` carry `classification.skill_ids: uuid[]`
and `classification.concept_ids: uuid[]`; `CreateExerciseRequest`/`UpdateExerciseRequest` carry
`skill_ids: uuid[]` and `concept_ids: uuid[]` directly. All four require at least one entry and
reject an id that doesn't reference an existing node. Responses (on both `ContentNode` and
`Exercise`) embed the full `Skill`/`Concept` objects (id, name, and parent_id) rather than bare
ids, so a client can render each one's position in the tree without a follow-up lookup per id.

`GET /exercises` and `GET /practice-sessions` move their skill filter from a name string
(`skill_tag`) to an id (`skill_id`), matching exactly one `Skill` node — the practice-session
selection query, and the `skill_tag` field on `exercise.*` tracking events, follow the same
rename to `skill_id`.

### Challenge's subject references a Skill or Concept by ID

`Challenge.subject_tag` (a name string) is replaced by `subject_skill_id: uuid | null` and
`subject_concept_id: uuid | null` — exactly one must be set. Validation checks that id appears in
the parent `ContentNode`'s `classification.skill_ids` (or `.concept_ids`, matching which field is
set) — the same membership rule as before, now against a set of ids instead of a set of names,
which is what makes it unambiguous even when the tree has two same-named nodes in different
branches.

### Difficulty widens from 3 to 5 levels

`difficulty_level` becomes `beginner | early_intermediate | intermediate | advanced | expert` —
each existing tier split once at its midpoint, keeping the same three anchor points a teacher
already knows rather than introducing an unfamiliar scale. No numeric/scoring meaning is
attached beyond ordering (`beginner < early_intermediate < intermediate < advanced < expert`).
This is a straight enum widen — `difficulty_level` stays a scalar on `ContentNode.classification`.

### Classification-driven remediation is decided; path prerequisites are not

When a student fails a `Challenge`, the recommended remediation is any `ContentNode` linked to
the same `Skill`/`Concept` id the challenge's `subject_skill_id`/`subject_concept_id` names,
excluding nodes the student has already completed, ordered by `difficulty_level` ascending. This
is an exact-node match, not a tree-wide one — failing a challenge on a specific leaf does not
(yet) also pull in content classified only under that leaf's parent or siblings; widening the
match to nearby tree nodes is a real possibility the tree structure now enables, but isn't
decided here. This ADR records the rule as decided data-model consumption — it does not itself
add a recommendation endpoint; implementing the query is PB-8g's work, unblocked by this ADR
rather than done here.

No separate prerequisite relation is added — the parent/child tree is not read as "must complete
the parent before the child." Sequencing within a `LearningPath` remains an explicit, manual
teacher decision (PB-40's `SectionedPathList`), not something the graph infers or validates.
Revisit if PB-27 ("derive path sections from the knowledge graph") reaches implementation and
finds this insufficient.

## Rationale

**Widening `skill`/`concept` to `string[]` in place is rejected** because it doesn't fix the
deeper problem: a flat string array has no way to express that one skill is a specialization of
another, which is the actual gap this ADR closes.

**Flat entities with name-based find-or-create are rejected.** They solve "more than one skill
per node" but not hierarchy, and once classification is a tree, names stop being unique
identifiers. Find-or-create resolves a typed name to *some* entity, but which one, when two
branches both have a node named "technique"? There's no correct answer without asking the
teacher to disambiguate — at which point the interaction is no longer "find-or-create by name,"
it's "pick from the tree," making an ID-based API the honest shape of what the interaction
actually is.

**Hierarchical, ID-based, explicit-CRUD entities are accepted** because it's the only option that
lets a node be classified at the specificity that actually fits it, keeps same-named nodes in
different branches unambiguous, and doesn't ask the server to silently guess which of several
same-named entities a teacher meant. The authoring cost — pick from a tree, or explicitly create
a new node under a chosen parent, instead of typing free text — is a real, accepted trade-off
(see Consequences), not an oversight.

**Linking `Exercise` to the same tree, replacing `skill_tags`, is accepted** over leaving it
freeform because the entire value of building this graph now is a shared classification
vocabulary across content and practice — an exercise and a content node teaching the "same"
skill should actually reference the same entity, not two strings that happen to match. Keeping
`skill_tags` as a second, parallel mechanism alongside `skill_ids`/`concept_ids` would mean two
sources of truth for what an exercise teaches, one of which (freeform tags) can drift from the
tree with no way to detect it.

**The 5-level difficulty split keeps the existing three anchor points** rather than inventing a
new scale, so a teacher who already thinks in beginner/intermediate/advanced maps directly onto
the new scale — `early_intermediate` and `expert` are the only genuinely new judgment calls.

**Leaving remediation undecided is rejected** because the whole reason to build this graph is so
PB-8g doesn't re-derive the same query design from scratch — deciding the rule here, even without
implementing the endpoint, is what makes this ADR foundational to recommendation rather than just
a data cleanup. Difficulty-ascending ordering is chosen because no proficiency-scoring mechanism
exists yet to rank relevance any other way — it's the only ordering signal the model actually has
today. The exact-node (not tree-wide) match keeps this decision's scope to what's actually
settled — widening it to ancestors/siblings is a real follow-up question, deliberately left open
rather than guessed at.

## Consequences

### Positive

- A `ContentNode` or `Exercise` can be classified at whatever specificity actually fits it — a
  broad root or a specific leaf — and under more than one skill/concept at once.
- Same-named nodes in different branches (e.g. two `technique`s) are unambiguous, because every
  reference is by id, never by name.
- Content and exercises share one classification vocabulary. "Which exercises teach the same
  skill as this content node" is a direct query on shared `skill_id`s, not a fuzzy string match
  across two independent tagging schemes.
- `Skill`/`Concept` are real, queryable, hierarchical entities with stable ids, and the
  remediation rule PB-8g needs is already decided. The tree itself is exactly the structure PB-27
  ("derive path sections from the knowledge graph") needs to exist before it can do anything.
- The 5-level difficulty rubric gives the decided remediation ordering (difficulty ascending)
  actual granularity to work with, instead of only 3 coarse buckets.
- No migration/backfill risk: no production data exists in `ContentNode.classification`,
  `Exercise.skill_tags`, `Skill`, `Concept`, or against the old 3-value enum yet, so this is a
  clean schema replacement.

### Negative / Trade-offs

- Authoring is no longer "type a name" — a teacher must pick an existing tree node or explicitly
  create a new one under a chosen parent, for both content nodes and exercises. That's a real UI
  cost (a tree browser/picker, not a plain text input) on two authoring surfaces, not one.
- Two new entities, each self-referential, plus join tables against both `ContentNode` and
  `Exercise` — more schema surface than a flat or freeform model.
- `POST /skills`/`POST /concepts` are new write surfaces with no update/delete counterpart yet —
  a node created under the wrong parent, or with a typo, cannot be fixed without a follow-up ADR
  deciding what re-parenting or renaming should do to existing links.
- The decided remediation rule is not yet implemented as a real endpoint — a future PB-8g session
  still has to build the actual query. It is also deliberately narrower than the tree now allows
  (exact node, not ancestors/siblings) — a real follow-up question, not an oversight.
- Five difficulty levels is one more judgment call per content node at authoring time than three
  was, with no tooling (yet) to help a teacher place a node consistently between adjacent levels.

### Neutral

- No fixed depth limit on the tree — simplest model, but nothing stops a teacher from building an
  impractically deep hierarchy; revisit if that turns out to be a real problem in practice.
- No prerequisite semantics are attached to the parent/child relationship itself — `LearningPath`
  ordering stays a manual teacher decision.
- **Revisit trigger:** once PB-27 (knowledge-graph-derived path sections) reaches implementation
  and finds the current model insufficient, or once a real need for renaming/re-parenting/
  deleting a `Skill`/`Concept` node shows up, either is a new ADR — not an amendment to this one.

## Related ADRs

- **ADR-019** (Practice content model) — introduced `Exercise.skill_tags` as freeform strings;
  this ADR supersedes that field with `skill_ids`/`concept_ids` against the shared tree.
- **ADR-023** (Challenge timebox and exercise remediation) — `Exercise.remediation_targets`
  remains the exercise-level remediation mechanism, untouched by this ADR's challenge-level rule;
  also the most recent precedent for a clean schema replacement with no migration.
- **ADR-018** (Frontend UI architecture) — the `motifpath-web` authoring UI for picking/creating
  tree nodes is a new interaction ADR-018 hasn't covered before (a tree browser, not a freeform
  tag input like the existing `SkillTagsInput`) — its own component/interaction decisions are
  this ADR's implementation work, not decided here.

---

*This ADR was decided on 2026-09-19. To revise, create a new ADR with Status: Supersedes
ADR-026.*
