# ADR-026: Content classification becomes a knowledge graph — Skill/Concept entities, a 5-level difficulty rubric, and a decided remediation rule

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
- **(A)** Skill/Concept as first-class, many-to-many entities instead of single strings.
- **(B)** Difficulty expands from 3 to 5 levels — needs a rubric, a content decision, not just an
  enum change.
- **(C)** How classification drives path-building (prerequisite sequencing) and remediation
  (a failed challenge on skill X recommending content that teaches skill X).

**Alternatives considered for (A):**
1. Widen `skill`/`concept` to `string[]` in place — keep them freeform, no new entities, same
   shape as `Exercise.skill_tags`.
2. Make `Skill`/`Concept` first-class many-to-many entities, with `ContentNode` requests carrying
   plain name arrays that the server resolves (find-or-create) rather than requiring the client
   to manage entity IDs.
3. Make `Skill`/`Concept` first-class many-to-many entities with explicit CRUD
   (`POST /skills`, `POST /concepts`) and `ContentNode` requests referencing them by ID.

**Alternatives considered for (C)'s remediation rule:**
1. Recommend any `ContentNode` linked to the failed challenge's subject skill/concept, excluding
   nodes the student has already completed, ordered by difficulty ascending.
2. Leave classification-driven remediation undecided; keep `Exercise.remediation_targets`
   (ADR-023) as the only remediation mechanism.

## Decision

### (A) Skill and Concept become first-class entities

Each `{skill_id/concept_id: uuid, name: string}`, `name` unique and validated as short
kebab-case (the same shape kebab-case tags already take today). `ContentNode` moves from single
`skill`/`concept` strings to many-to-many relations: `ContentNode ↔ Skill` and
`ContentNode ↔ Concept`, each requiring at least one entry — a content node classified under
zero skills or zero concepts is exactly as analytically useless as one with an empty string
today.

**The API stays name-based, not ID-based** (alternative 2, not 3). `CreateContentNodeRequest`
and `UpdateContentNodeRequest` carry `classification.skills: string[]` and
`classification.concepts: string[]` — plain names, not entity IDs. The server resolves each name
to an existing `Skill`/`Concept` or creates it on the fly (find-or-create by name, case- and
whitespace-normalized before comparison) and links it to the node. Responses denormalize back to
`skills: string[]` / `concepts: string[]` (sorted, for stable output) rather than embedding full
`Skill`/`Concept` objects — nothing downstream needs more than the name yet.

Two new read endpoints support this without new write surfaces: `GET /skills` and
`GET /concepts`, each an unpaginated list of `{skill_id, name}` / `{concept_id, name}` sorted by
name — the picker-suggestion catalog `useSkillTagSuggestions` today derives from scanning the
exercise pool, now a real, purpose-built list instead of a workaround. No
`POST`/`PATCH`/`DELETE` on either resource — entities are only ever created implicitly via
`ContentNode` authoring; explicit skill/concept management (rename, merge synonyms, delete) is
out of scope until a real need for it shows up.

`Challenge.subject_tag` validation generalizes from "must equal the node's one skill or concept
string" to "must equal one of the node's linked skill or concept names" — same rule, now over a
set instead of a pair.

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
remediation is any `ContentNode` linked (via its new many-to-many `Skill`/`Concept` relations) to
that challenge's `subject_tag`, excluding nodes the student has already completed, ordered by
`difficulty_level` ascending. This ADR records the rule as decided data-model consumption — it
does not itself add a recommendation endpoint; implementing the query is PB-8g's work, unblocked
by (A) rather than done here.

**Path-building prerequisites (decided against, for now):** `Skill`/`Concept` stay a flat
classification — no self-referential prerequisite relation is added to either entity.
Sequencing within a `LearningPath` remains an explicit, manual teacher decision (PB-40's
`SectionedPathList`), not something the graph infers or validates. Revisit if PB-27 ("derive
path sections from the knowledge graph") reaches implementation and finds the flat model
insufficient.

## Rationale

**Alternative 1 for (A) (widen to `string[]` in place) is rejected** because it doesn't actually
resolve PB-33's stated purpose — "foundational to recommendation (PB-8g) & path-building" — it
only fixes today's immediate authoring complaint. Freeform strings can't be queried ("which
content nodes teach any skill a student is weak in") without a full-table scan and ad hoc string
matching, and (C)'s remediation rule — decided in this same ADR — depends on exactly that query.
Since the underlying entities are needed for (C) regardless, doing the minimal "pluralize the
string" fix now would mean redoing this same modeling work a second time immediately after.

**Alternative 3 for (A) (ID-based API, explicit CRUD) is rejected** as premature ceremony for
what a teacher actually does today: type a skill name while authoring a lesson, the same
interaction `SkillTagsInput`/`useSkillTagSuggestions` already support for exercises. Requiring
the web client to first call `POST /skills` to mint an ID, then include that ID on
`CreateContentNodeRequest`, adds a round trip and a client-side id-management burden for zero
present benefit. Name-based find-or-create (alternative 2) gets the same entities, the same
future queryability, with the exact authoring ergonomics already proven for
`Exercise.skill_tags`.

**Not linking `Exercise.skill_tags` to `Skill` in this same pass** is deliberate, not an
oversight: ADR-019/PB-42 already made the explicit call that exercise tags are freeform and
decoupled from PB-33's eventual graph, precisely so PB-42's real usage could inform this design
rather than the reverse. This ADR's remediation rule (C) is defined at the `Challenge`/
`ContentNode` level specifically because that link already exists (`subject_tag` ↔
classification) — extending the same graph down to `Exercise.skill_tags` is a second, separable
decision to make once real usage shows whether exercise-level remediation targeting (already
covered by ADR-023's `Exercise.remediation_targets`) needs it too.

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
mechanism exists yet to rank relevance any other way — it's the only ordering signal the model
actually has today.

## Consequences

### Positive

- A `ContentNode` can finally be tagged the way real lesson content actually works — more than
  one skill, more than one concept — closing the exact gap that blocked PB-40's content
  authoring UI.
- `Skill`/`Concept` are real, queryable entities with stable ids, and the remediation rule PB-8g
  needs is already decided — both blockers PB-8g/PB-27 would have hit are cleared ahead of time.
- The 5-level difficulty rubric gives the decided remediation ordering (difficulty ascending)
  actual granularity to work with, instead of only 3 coarse buckets.
- `GET /skills`/`GET /concepts` replace `useSkillTagSuggestions`'s workaround (scanning the whole
  exercise pool to approximate a tag catalog) with a real, purpose-built list.
- No migration/backfill risk: no production data exists in `ContentNode.classification`,
  `Skill`, `Concept`, or against the old 3-value enum yet, so this is a clean schema replacement,
  consistent with how ADR-019 and ADR-023 handled the same situation.

### Negative / Trade-offs

- Two new entities and two new join tables where there were previously two string columns —
  more schema surface, two new (read-only) endpoints, and a find-or-create path that has to
  handle name normalization correctly to avoid silently forking near-duplicate skills.
- `Challenge.subject_tag`'s validation gets slightly more expensive (membership check against a
  set fetched via the many-to-many relation, instead of comparing two scalars) — negligible at
  today's scale.
- The decided remediation rule (C) is not yet implemented as a real endpoint — a future PB-8g
  session still has to build the actual query, and until then this ADR's rule is documentation,
  not behavior.
- Deliberately leaves `Exercise.skill_tags` unconnected to `Skill`, which means "show me all
  content that teaches the skill a student just failed on an exercise-level basis" cannot be
  answered by a straight join yet — only challenge-level (`subject_tag`) remediation is covered.
- Five difficulty levels is one more judgment call per content node at authoring time than three
  was, with no tooling (yet) to help a teacher place a node consistently between adjacent levels.

### Neutral

- Prerequisite/sequencing relations between `Skill`/`Concept` entities are explicitly not
  introduced — `LearningPath` ordering stays a manual teacher decision.
- **Revisit trigger:** once PB-27 (knowledge-graph-derived path sections) reaches implementation
  and finds the flat, prerequisite-free model insufficient, or once real usage shows
  `Exercise.skill_tags` needs connecting to `Skill` for exercise-level remediation, either is a
  new ADR — not an amendment to this one.

## Related ADRs

- **ADR-019** (Practice content model) — introduced `Exercise.skill_tags` as freeform strings and
  explicitly deferred the Skill/Concept graph to PB-33 (this ADR), on the understanding that
  PB-42's real tag usage would inform it.
- **ADR-023** (Challenge timebox and exercise remediation) — `Exercise.remediation_targets`
  remains the exercise-level remediation mechanism, untouched by this ADR's challenge-level rule;
  also the most recent precedent for a clean schema replacement with no migration, for the same
  reason (no production data yet).
- **ADR-018** (Frontend UI architecture) — the `motifpath-web` authoring UI for multi-select
  skills/concepts follows the same owned-component, freeform-tag-input pattern
  (`SkillTagsInput`) ADR-018 already established for `Exercise.skill_tags`.

---

*This ADR was proposed on 2026-09-19. To revise, create a new ADR with Status: Supersedes
ADR-026.*
