# ADR-026: Content classification becomes a knowledge graph — hierarchical Skill/Concept entities, a 5-level difficulty rubric, and a decided remediation rule

**Status:** Accepted
**Date:** 2026-09-19
**Deciders:** Gilson (Product Owner)

---

## Context

This is PB-33 ("content classification as a knowledge graph"), raised as Discovery-stage work on
2026-09-10 and pulled forward now: while authoring a `ContentNode` for real in `motifpath-web`
(PB-40's Phase 3), Gilson hit a concrete gap the current model can't express — a single lesson
routinely teaches more than one skill and touches more than one concept (e.g. a video that covers
both `alternate-picking` and `string-muting`, under the concept of `right-hand-technique`), but
`ContentNode.classification` today allows exactly one of each.

**Current state (verified against the merged spec and `motifpath-core`'s ent schema):**
`ClassificationInput` is three scalars — `skill: string`, `concept: string`,
`difficulty_level: enum(beginner|intermediate|advanced)` — embedded directly on `ContentNode`,
not a separate entity, per an explicit "deliberate MVP cut" noted in the original ent schema.
`Challenge.subject_tag` is validated against exactly that one skill or concept string on the
node it belongs to (`core-domain-service.yaml`: "Must match a skill or concept tag on the parent
content node's classification"). `Exercise.skill_tags` (ADR-019/PB-42) is a separate, deliberately
freeform `string[]` with no backing entity — PB-42 explicitly deferred to PB-33 for the eventual
graph, on the understanding that PB-42's real tag usage would inform this design once it started.
No production data exists in either table yet.

**PB-33's full original scope is three coupled changes**, all decided together in this ADR
rather than splitting change A off on its own:
- **(A)** Skill/Concept as first-class entities instead of single strings.
- **(B)** Difficulty expands from 3 to 5 levels — needs a rubric, a content decision, not just an
  enum change.
- **(C)** How classification drives path-building (prerequisite sequencing) and remediation
  (a failed challenge on skill X recommending content that teaches skill X).

**Revised during PR review (2026-09-20), before merge.** The first draft of this ADR modeled
Skill/Concept as a flat set of uniquely-named tags. Reviewing that draft, Gilson identified two
problems a flat model can't express:

1. **Real skill/concept taxonomies are hierarchical, not flat.** A piece of content can be
   classified at whatever specificity actually fits it — a broad root concept
   (`right-hand-technique`) for a survey lesson, or a specific leaf (`alternate-picking` under
   `right-hand-technique` under `guitar-technique`) for a focused one. A flat set of tags has no
   way to express that `alternate-picking` is a kind of `right-hand-technique`, or to classify a
   node at whichever level of the tree actually matches its scope.
2. **A tree means names are no longer globally unique.** Two different branches can legitimately
   have a same-named node (e.g. `technique` under `picking` vs. `technique` under `rhythm`) —
   they are different entities that happen to share a label. The first draft's name-based
   find-or-create API (a teacher types "technique", the server resolves or creates a `Skill`
   named "technique") silently breaks the moment two such nodes exist: a name no longer
   identifies one entity. This section's Decision and Rationale below replace that draft's design
   entirely — the alternatives list is retained for the record, but alternative 2 (name-based,
   which the first draft chose) is now rejected, not accepted.

**Alternatives considered for (A):**
1. Widen `skill`/`concept` to `string[]` in place — keep them freeform, no new entities, same
   shape as `Exercise.skill_tags`. (Rejected in the first draft, still rejected.)
2. Make `Skill`/`Concept` first-class entities, flat (not a tree), with `ContentNode` requests
   carrying plain name arrays that the server resolves via find-or-create. (The first draft's
   choice — rejected on revision; retained here only for the record.)
3. Make `Skill`/`Concept` first-class **tree** entities (self-referential `parent_id`), with
   explicit CRUD (`POST /skills`, `POST /concepts`) and `ContentNode` requests referencing
   existing nodes by ID, not name.

**Alternatives considered for (C)'s remediation rule:**
1. Recommend any `ContentNode` linked to the failed challenge's subject skill/concept, excluding
   nodes the student has already completed, ordered by difficulty ascending.
2. Leave classification-driven remediation undecided; keep `Exercise.remediation_targets`
   (ADR-023) as the only remediation mechanism.

## Decision

### (A) Skill and Concept become first-class, hierarchical entities, referenced by ID

Each `{skill_id/concept_id: uuid, name: string, parent_id: uuid | null}` — `parent_id` null means
a root node; any node may have children, to any depth (open-ended, no fixed number of levels).
`name` is unique among siblings sharing the same `parent_id` (including among other roots, for
`parent_id = null`), not globally — two nodes in different branches may share a name.
`ContentNode` moves from single `skill`/`concept` strings to many-to-many relations:
`ContentNode ↔ Skill` and `ContentNode ↔ Concept`, each requiring at least one entry. A node may
be classified at whatever depth actually fits its scope — linking a root, a leaf, or several
nodes at different depths in the same request is all valid; nothing about "how deep" is enforced.

**The API is ID-based, not name-based** (alternative 3, reversing the first draft's alternative
2). `CreateContentNodeRequest` and `UpdateContentNodeRequest` carry `classification.skill_ids:
uuid[]` and `classification.concept_ids: uuid[]` — existing `Skill`/`Concept` ids, not names.
Referencing an id that doesn't exist is rejected with 400. Responses embed the full `Skill`/
`Concept` objects (id, name, and parent_id) rather than bare ids, so a client can render each
one's position in the tree (breadcrumb/path) without a follow-up lookup per id.

**Explicit CRUD replaces find-or-create.** `POST /skills` and `POST /concepts` each take
`{name, parent_id?}` and create one node — a teacher (or the authoring UI on their behalf)
explicitly picks an existing node from the tree or creates a new one under a chosen parent (or
as a new root, omitting `parent_id`). There is no implicit creation via `ContentNode` authoring
any more; a name typed into a search box can no longer be assumed to identify (or safely mint) a
specific entity, once the same name can legitimately exist in more than one branch.
`GET /skills` and `GET /concepts` return the full flat list (`id`, `name`, `parent_id`) — the
shape a client needs both to render the tree for browsing/creation and to resolve any node's
breadcrumb by walking `parent_id` — sorted by name within their level. No `PATCH`/`DELETE` yet;
re-parenting or deleting a node with existing links is a real question (what happens to content
already classified under it?) deliberately left for whenever a concrete need for it shows up.

**`Challenge.subject_tag` (a name string) is replaced by an id reference.** `Challenge` gains
`subject_skill_id: uuid | null` and `subject_concept_id: uuid | null` — exactly one must be set.
Validation checks that id appears in the parent `ContentNode`'s `classification.skill_ids` (or
`.concept_ids`, matching which field is set) — the same membership rule as before, now against a
set of ids instead of a set of names, which is what makes it unambiguous even when the tree has
two same-named nodes in different branches.

**`Exercise.skill_tags` stays freeform, unconnected to `Skill`**, in this same pass — see
Rationale.

### (B) Difficulty widens from 3 to 5 levels

`difficulty_level` becomes `beginner | early_intermediate | intermediate | advanced | expert` —
each existing tier split once at its midpoint, keeping the same three anchor points a teacher
already knows rather than introducing an unfamiliar scale. No numeric/scoring meaning is
attached beyond ordering (`beginner < early_intermediate < intermediate < advanced < expert`);
per-skill proficiency scoring is not part of this decision. This is a straight enum widen, not a
new entity — `difficulty_level` stays a scalar on `ContentNode.classification`.

### (C) Classification-driven remediation is decided; path prerequisites are not

**Remediation (decided, alternative 1):** when a student fails a `Challenge`, the recommended
remediation is any `ContentNode` linked to the same `Skill`/`Concept` id the challenge's
`subject_skill_id`/`subject_concept_id` names, excluding nodes the student has already completed,
ordered by `difficulty_level` ascending. This is an exact-node match, not a tree-wide one — failing
a challenge on a specific leaf does not (yet) also pull in content classified only under that
leaf's parent or siblings; widening the match to nearby tree nodes is a real possibility the tree
structure now enables, but isn't decided here. This ADR records the rule as decided data-model
consumption — it does not itself add a recommendation endpoint; implementing the query is PB-8g's
work, unblocked by (A) rather than done here.

**Path-building prerequisites (decided against, for now):** no separate prerequisite relation is
added — the parent/child tree itself is not read as "must complete the parent before the child."
Sequencing within a `LearningPath` remains an explicit, manual teacher decision (PB-40's
`SectionedPathList`), not something the graph infers or validates. Revisit if PB-27 ("derive
path sections from the knowledge graph") reaches implementation and finds this insufficient.

## Rationale

**Alternative 1 for (A) (widen to `string[]` in place) is rejected**, on revision for the same
reason it was rejected in the first draft plus one more: a flat string array has no way to
express that one skill is a specialization of another, which is the whole problem this revision
exists to fix.

**Alternative 2 for (A) (flat entities, name-based find-or-create — the first draft's choice) is
rejected on revision.** It solved "more than one skill per node" but not the deeper problem: real
classification is hierarchical, and once it is, names stop being unique identifiers. Find-or-create
resolves a typed name to *some* entity, but which one, when two branches both have a node named
"technique"? There is no correct answer without asking the teacher to disambiguate — at which
point the interaction is no longer "find-or-create by name," it's "pick from the tree," making
the ID-based API (alternative 3) the honest shape of what the interaction actually is.

**Alternative 3 for (A) (ID-based, explicit CRUD, hierarchical) is accepted** because it's the
only option that lets a node be classified at the specificity that actually fits it, keeps
same-named nodes in different branches unambiguous, and doesn't ask the server to silently guess
which of several same-named entities a teacher meant. The authoring cost — pick from a tree, or
explicitly create a new node under a chosen parent, instead of typing free text — is a real,
accepted trade-off (see Consequences), not an oversight.

**Not linking `Exercise.skill_tags` to `Skill` in this same pass** is deliberate, not an
oversight: ADR-019/PB-42 already made the explicit call that exercise tags are freeform and
decoupled from PB-33's eventual graph, precisely so PB-42's real usage could inform this design
rather than the reverse. This ADR's remediation rule (C) is defined at the `Challenge`/
`ContentNode` level specifically because that link already exists — extending the same graph
down to `Exercise.skill_tags` is a second, separable decision to make once real usage shows
whether exercise-level remediation targeting (already covered by ADR-023's
`Exercise.remediation_targets`) needs it too.

**The 5-level split (B) keeps the existing three anchor points** rather than inventing a new
scale, so every already-classified mental model (a teacher who already thinks in
beginner/intermediate/advanced) still maps directly onto the new scale — `early_intermediate`
and `expert` are the only genuinely new judgment calls a teacher has to make, not a full
re-classification.

**Alternative 2 for (C) (leave remediation undecided) is rejected** because the whole reason to
build (A) now, ahead of PB-8g starting, is so PB-8g doesn't re-derive the same query design from
scratch — deciding the rule here, even without implementing the endpoint, is what makes (A)
"foundational to recommendation" rather than just a data cleanup. Difficulty-ascending ordering
is chosen over any other ordering (e.g. by tag-relevance score) because no proficiency-scoring
mechanism exists yet to rank relevance any other way. The exact-node (not tree-wide) match keeps
this decision's scope to what's actually settled — widening it to ancestors/siblings is a real
follow-up question, deliberately left open rather than guessed at.

## Consequences

### Positive

- A `ContentNode` can be classified at whatever specificity actually fits it — a broad root or a
  specific leaf — and under more than one skill/concept at once, closing the exact gap that
  blocked PB-40's content authoring UI.
- Same-named nodes in different branches (e.g. two `technique`s) are unambiguous, because every
  reference is by id, never by name.
- `Skill`/`Concept` are real, queryable, hierarchical entities with stable ids, and the
  remediation rule PB-8g needs is already decided — both blockers PB-8g/PB-27 would have hit are
  cleared ahead of time. The tree itself is exactly the structure PB-27 ("derive path sections
  from the knowledge graph") needs to exist before it can do anything.
- The 5-level difficulty rubric gives the decided remediation ordering (difficulty ascending)
  actual granularity to work with, instead of only 3 coarse buckets.
- `GET /skills`/`GET /concepts` replace `useSkillTagSuggestions`'s workaround (scanning the whole
  exercise pool to approximate a tag catalog) with a real, purpose-built, hierarchy-aware list.
- No migration/backfill risk: no production data exists in `ContentNode.classification`,
  `Skill`, `Concept`, or against the old 3-value enum yet, so this is a clean schema replacement,
  consistent with how ADR-019 and ADR-023 handled the same situation.

### Negative / Trade-offs

- Authoring is no longer "type a name" — a teacher must pick an existing tree node or explicitly
  create a new one under a chosen parent, a real UI cost (a tree browser/picker, not a plain text
  input) compared to the first draft's freeform tag input.
- Two new entities, each self-referential, plus two new join tables where there were previously
  two string columns — more schema surface than either prior draft.
- `POST /skills`/`POST /concepts` are new write surfaces with no update/delete counterpart yet —
  a node created under the wrong parent, or with a typo, cannot be fixed without a follow-up ADR
  deciding what re-parenting or renaming should do to existing links.
- `Challenge.subject_skill_id`/`subject_concept_id`'s validation is a membership check against a
  set of ids fetched via the many-to-many relation, same cost shape as the rejected name-based
  version — no regression, but no improvement either.
- The decided remediation rule (C) is not yet implemented as a real endpoint — a future PB-8g
  session still has to build the actual query, and until then this ADR's rule is documentation,
  not behavior. It is also deliberately narrower than the tree now allows (exact node, not
  ancestors/siblings) — a real follow-up question, not an oversight.
- Deliberately leaves `Exercise.skill_tags` unconnected to `Skill`, which means "show me all
  content that teaches the skill a student just failed on an exercise-level basis" cannot be
  answered by a straight join yet — only challenge-level remediation is covered.
- Five difficulty levels is one more judgment call per content node at authoring time than three
  was, with no tooling (yet) to help a teacher place a node consistently between adjacent levels.

### Neutral

- No fixed depth limit on the tree — simplest model, but nothing stops a teacher from building an
  impractically deep hierarchy; revisit if that turns out to be a real problem in practice.
- No prerequisite semantics are attached to the parent/child relationship itself — `LearningPath`
  ordering stays a manual teacher decision.
- **Revisit trigger:** once PB-27 (knowledge-graph-derived path sections) reaches implementation
  and finds the current model insufficient, once real usage shows `Exercise.skill_tags` needs
  connecting to `Skill`, or once a real need for renaming/re-parenting/deleting a `Skill`/
  `Concept` node shows up, any of those is a new ADR — not an amendment to this one.

## Related ADRs

- **ADR-019** (Practice content model) — introduced `Exercise.skill_tags` as freeform strings and
  explicitly deferred the Skill/Concept graph to PB-33 (this ADR), on the understanding that
  PB-42's real tag usage would inform it.
- **ADR-023** (Challenge timebox and exercise remediation) — `Exercise.remediation_targets`
  remains the exercise-level remediation mechanism, untouched by this ADR's challenge-level rule;
  also the most recent precedent for a clean schema replacement with no migration, for the same
  reason (no production data yet).
- **ADR-018** (Frontend UI architecture) — the `motifpath-web` authoring UI for picking/creating
  tree nodes is new interaction ADR-018 hasn't covered before (a tree browser, not a freeform tag
  input like `SkillTagsInput`) — its own component/interaction decisions are this ADR's
  implementation work, not decided here.

---

*This ADR was proposed on 2026-09-19, revised on 2026-09-20 before merge (see the Context note
above), and accepted as revised. To revise further after merge, create a new ADR with
Status: Supersedes ADR-026.*
