# ADR-019: Exercise is a first-class, reusable entity classified by skill, independent of Challenge

**Status:** Proposed
**Date:** 2026-09-13
**Deciders:** Gilson (Product Owner)

---

## Context

PB-41 (Practice / exercises view, S7) was blocked on PB-42 (practice content model discovery):
the screen's real design depends on how practice content itself gets built and modeled, which
was undecided. PB-40 (path content authoring UI) has the same dependency — an authoring tool
cannot be built against an unsettled content model.

ADR-015 decided that "the challenge is part of its path node" and framed the challenge as the
node's single practice step. The implementation that followed took that further than ADR-015's
text requires: `motifpath-core`'s ent schema gives `Exercise` a direct, required
`challenge_id` foreign key (`services/core-domain/internal/adapters/repo/ent/schema/exercise.go`
and `challenge.go`), so today an exercise cannot exist without exactly one owning challenge, and
a challenge's exercises cannot be reused anywhere else.

That coupling does not hold for a real product case. A technique like alternate picking is
exercised the same way regardless of which path surfaces it: a path called "Technical
improvements" may include it directly, and a student working through an unrelated path who
struggles with picking accuracy should be able to receive the same exercise as a remediation
suggestion, without the exercise being duplicated or the target path being modified to include
a foreign challenge. This requires an exercise to be classifiable and discoverable on its own
terms, independent of any single challenge.

Today's exercise typology is also narrower than the product needs: the only implemented type is
`fretboard_region` (`ExerciseType` is a single-literal union, not an open enum), and the type
name conflates an interaction pattern (clickable regions on an image) with the general case
(image recognition). Textual question/response and audio recognition exercises have no type at
all yet.

Separately, `motifpath-specs`'s `openapi/components/schemas/challenge.yaml` describes a
different Challenge shape (`content_expansion_settings_id`, many-to-many
`ChallengeClassification`) than the one actually implemented in Go (`content_node_id`,
`subject_tag` directly on Challenge). This ADR does not resolve that discrepancy — the OpenAPI
spec update is tracked as follow-up work, not a precondition for this decision.

This decision also intersects PB-33 (content classification as a knowledge graph — Skill/Concept
as first-class many-to-many entities). PB-33 is still in Discovery with no implemented model.
Rather than block PB-42 on PB-33, the product decision is to let PB-42 define a lightweight
classification mechanism now, driven by the concrete reuse case above, and let that real usage
inform PB-33's eventual graph design — not the reverse.

Alternatives considered:

- **Keep `challenge_id` required, add a "shared challenge" concept instead.** Rejected: makes
  reuse indirect — a path would need to reference another path's challenge to borrow its
  exercises, entangling path composition with content reuse. The exercise itself, not the
  challenge, is the reusable unit.
- **Block PB-42 on PB-33's knowledge graph landing first.** Rejected: PB-33 is Discovery-stage
  with no committed timeline, and would leave PB-41/PB-40 blocked indefinitely on an unrelated
  epic. The classification need here is narrow (tag an exercise with the skill it targets) and
  does not require PB-33's full many-to-many graph to be useful.
- **Scope cross-path suggestion logic inside PB-42.** Rejected: recommending an exercise outside
  its authored path is a remediation decision, which is PB-8g's domain. PB-42 only needs to make
  exercises classifiable and queryable by skill; PB-8g decides when and to whom a standalone
  exercise gets suggested.

## Decision

**MotifPath will model Exercise as a first-class entity, linked to Challenge through a
many-to-many relationship, and classified by one or more lightweight skill tags independent of
any challenge or path.**

1. **Exercise no longer requires a Challenge.** The direct `challenge_id` foreign key on
   `Exercise` is replaced with a many-to-many join (`exercise` ↔ `challenge`). An exercise may be
   linked to zero, one, or many challenges, and a challenge may reference the same exercise as
   another challenge in a different path. `GET /content-nodes/{id}/challenges` and its exercise
   listing are unaffected in shape, only in how the underlying link is stored.

2. **Exercise gains one or more skill tags.** Each exercise carries a small set of freeform
   string tags naming the skill or technique it targets (for example `alternate_picking`). This
   is deliberately the lightest mechanism that unblocks PB-41/PB-40: no new entity, no graph, no
   dependency on PB-33. Tags are exercise-level metadata, queryable by exact match.

3. **Exercise type is generalized to a real, open enum**, replacing the single-literal
   `fretboard_region` union. The typology is:
   - `text_response` — textual question/response
   - `audio_recognition` — audio-based recognition
   - `image_recognition` — image-based recognition, of which clickable-region-on-image (today's
     `fretboard_region`) is one interaction pattern, not a separate type
   - Rhythmic exercises are explicitly deferred — not part of this ADR's committed typology,
     revisited only once feasibility is assessed.

   Per-type answer-checking / grading schema is explicitly out of scope for this ADR and is
   decided incrementally as each type beyond `image_recognition` is implemented.

4. **Cross-path suggestion of a standalone exercise is not decided here.** This ADR makes
   exercises classifiable and queryable by skill tag; the decision of when and to whom a
   standalone exercise is surfaced outside its authored context belongs to PB-8g (remediation
   recommendation).

5. **The OpenAPI/Go discrepancy on Challenge is not addressed by this ADR.** `challenge.yaml`
   will need a follow-up spec revision to match implementation reality, tracked separately.

## Rationale

Making Exercise first-class and many-to-many with Challenge matches how exercises are actually
authored and reused in practice: the same alternate-picking drill is the same exercise whether a
teacher assigns it inside "Technical improvements" or the recommendation engine surfaces it into
an unrelated path. A required, single-owner `challenge_id` cannot express that without either
duplicating content or coupling unrelated paths together through a shared challenge reference —
both worse than letting the exercise itself be the shared unit.

Lightweight tags now, rather than waiting on PB-33, keep PB-41 and PB-40 moving without
inventing a throwaway classification scheme in isolation — the tags this ADR introduces are real
usage that PB-33 can generalize into its Skill/Concept graph later, rather than a spec written
without any implemented consumer.

Generalizing the exercise typology now, even though only `image_recognition` (as
`fretboard_region`'s successor) is implemented, prevents PB-40's authoring UI from being
designed against a single-type model that would need a rework the moment a second type ships.
Naming all four types (three committed, one explicitly deferred) lets PB-40 scope its authoring
forms honestly instead of guessing.

Deferring per-type grading logic and the OpenAPI/Go reconciliation keeps this ADR to the
structural decision PB-41/PB-40 actually need, rather than growing into a full content-authoring
spec that isn't ready yet.

## Consequences

### Positive

- An exercise can be authored once and reused across any number of challenges/paths, matching
  real content-authoring intent.
- PB-41 and PB-40 are unblocked: both now have a settled shape (Exercise entity, its
  classification, its typology) to design against.
- The exercise typology is honest about what's committed (three types) versus deferred (rhythm),
  so PB-40's authoring UI scope is not built against a single-type assumption.
- The classification mechanism is minimal now and has a clear upgrade path into PB-33 once that
  epic delivers, informed by real tags instead of speculative ones.

### Negative / Trade-offs

- `motifpath-core`'s ent schema changes: `Exercise.ChallengeID` (required FK) is replaced by a
  join table, and `ExerciseType` moves from a single-literal union to a real enum. This is a
  breaking schema change with no production data yet, so no migration/backfill is needed, but it
  does require regenerating ent code and the OpenAPI-generated web client.
- Skill tags are freeform strings with no validation or canonical vocabulary; until PB-33 lands,
  nothing prevents tag drift (e.g. `alternate_picking` vs `alt-picking` vs `Alternate Picking`)
  across independently authored exercises. Authoring guidance must call this out.
- `openapi/components/schemas/challenge.yaml` remains stale relative to implementation after
  this ADR — a second, separate spec PR is required before PB-40 can be built against an
  accurate contract.
- Per-type answer-checking schema is still undefined for `text_response` and
  `audio_recognition`; PB-40's authoring UI cannot yet cover those types end-to-end until that
  follow-up work lands.

### Neutral

- PB-8g's remediation logic is unaffected in scope by this ADR — it gains a new capability
  (querying exercises by skill tag) but its own decision-making (when/whom to suggest to) is
  untouched.
- ADR-015's node/challenge/S7-route structure is unchanged; only the Exercise-Challenge
  cardinality and Exercise's own classification change.

## Related ADRs

- **ADR-015** — Challenge belongs to the path node; this ADR narrows ADR-015's implicit
  challenge-owns-exercise coupling (as implemented, not as ADR-015's text required) to a
  many-to-many relationship.
- **PB-33** (not yet an ADR) — Content classification as a knowledge graph. This ADR's skill tags
  are a deliberate precursor, expected to be superseded or absorbed once PB-33 is decided.

## Follow-up work (not part of this ADR)

- Revise `openapi/components/schemas/challenge.yaml` to match the implemented Go model
  (`content_node_id`, `subject_tag`, `pass_threshold` directly on Challenge) — separate spec PR.
- Add OpenAPI schema and Gherkin scenarios for the Exercise entity: many-to-many
  challenge linkage, skill tags, and the generalized `exercise_type` enum.
- Define per-type answer-checking / grading schema for `text_response` and `audio_recognition`
  as each is implemented; `image_recognition` inherits the existing `fretboard_region` checking
  logic.
- PB-33: use this ADR's skill tags as real input when designing the Skill/Concept knowledge
  graph.
- PB-8g: design how standalone/cross-path exercise suggestion queries exercises by skill tag.

---

*This ADR was decided on 2026-09-13. To revise, create a new ADR with Status: Supersedes ADR-019.*
