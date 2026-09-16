# ADR-019: Exercise is a first-class, reusable entity classified by skill, independent of Challenge

**Status:** Accepted
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
   - Rhythmic exercises are explicitly deferred from this ADR's committed typology. A feasibility
     spike is tracked as its own backlog item, **PB-43**, since capture and scoring difficulty
     (real-time timing accuracy) is unknown and needs its own investigation before a type is
     committed.

4. **Every exercise, regardless of type, is checked the same way: option selection.** An
   exercise offers a set of options and marks one or more of them correct; checking is always
   "does the student's selected option ID (or set of IDs) match the correct option ID(s)" — never
   free-text matching or signal analysis. This generalizes the pattern `image_recognition`
   already uses (a region is one kind of option):
   - `image_recognition` — options are regions on the image; selecting a region is selecting an
     option. This is exactly the existing `fretboard_region` behavior, unchanged.
   - `text_response` — options are a fixed set of textual choices; the student picks one (or
     more, for select-all-that-apply), not free-form input.
   - `audio_recognition` — audio is the stimulus (what's played), and options are a fixed set of
     labeled choices (e.g. note/chord/interval names) the student selects from after listening.
     No audio signal analysis is performed.

   An exercise's options and correct-option marking are authored data, not computed — the same
   shape PB-40's authoring UI needs to expose regardless of type.

5. **Cross-path suggestion of a standalone exercise is not decided here.** This ADR makes
   exercises classifiable and queryable by skill tag; the decision of when and to whom a
   standalone exercise is surfaced outside its authored context belongs to PB-8g (remediation
   recommendation).

6. **The OpenAPI/Go discrepancy on Challenge is not addressed by this ADR.** `challenge.yaml`
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
Naming all three committed types, plus a dedicated spike (PB-43) for the deferred rhythmic case,
lets PB-40 scope its authoring forms honestly instead of guessing.

An exercise that can't be checked has no product value — a practice item the platform can't
grade isn't practice, it's just content. Unifying every type onto the same option-selection
checking model, rather than deferring grading per type, means this ADR actually settles what
PB-40's authoring UI must capture (options + correct-option marking) and what PB-41's runtime
must submit and score, for all three committed types at once — not a partial model that still
blocks implementation on type-by-type follow-up decisions. Option selection was chosen over
free-text or signal-based matching because it is gradable deterministically with no NLP or audio
analysis investment, which MVP scope doesn't have room for, and because `image_recognition`
already proves the pattern works for a real exercise type today.

Deferring the OpenAPI/Go reconciliation (but not answer-checking) keeps this ADR to the content
model PB-41/PB-40 actually need; the spec-vs-code discrepancy on Challenge is a separate,
unrelated cleanup with no bearing on the Exercise decisions above.

## Consequences

### Positive

- An exercise can be authored once and reused across any number of challenges/paths, matching
  real content-authoring intent.
- PB-41 and PB-40 are unblocked: both now have a settled shape (Exercise entity, its
  classification, its typology) to design against.
- The exercise typology is honest about what's committed (three types) versus deferred (rhythm,
  tracked as PB-43), so PB-40's authoring UI scope is not built against a single-type assumption.
- The classification mechanism is minimal now and has a clear upgrade path into PB-33 once that
  epic delivers, informed by real tags instead of speculative ones.
- Every committed type is checkable the same way (option selection), so no exercise ships
  without a defined way to grade it — PB-40 and PB-41 both have a complete model to build
  against for all three types, not just `image_recognition`.

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
- Constraining every type to option selection is a real scope limit: `text_response` cannot
  express genuinely open-ended free-text questions, and `audio_recognition` cannot do fine-
  grained pitch/timing evaluation — both would need a different (and more expensive) checking
  model than this ADR commits to. Revisit as a superseding ADR if the product needs that later.

### Neutral

- PB-8g's remediation logic is unaffected in scope by this ADR — it gains a new capability
  (querying exercises by skill tag) but its own decision-making (when/whom to suggest to) is
  untouched.
- ADR-015's node/challenge/S7-route structure is unchanged; only the Exercise-Challenge
  cardinality and Exercise's own classification change.

## Amendment (2026-09-13) — a 4th committed type: `image_choice`

PB-40's exercise-authoring prototype (`design/PB-40-exercise-authoring-builder/`) added a
fourth type live, from review feedback: **`image_choice`** — an exercise whose options are
images rather than text (e.g. "which of these four chord-shape diagrams is E minor?"), sharing
one image picker (predefined library or custom upload) with `image_recognition`'s canvas so
authors have a single, consistent way to attach images across both types.

This is not a new checking model — it is decision point 4's option-selection pattern with the
option's rendered content being an image instead of text or a region:

- `image_recognition` — options are regions on one image.
- `image_choice` — options are a fixed set of separate images; the student selects one (or
  more, for select-all-that-apply), exactly like `text_response`'s fixed-choice options except
  each option renders as an image instead of a text label.

**Decision: commit `image_choice` as the 4th exercise type**, extending decision point 3's
typology to `text_response` / `audio_recognition` / `image_recognition` / `image_choice`. No
other decision point changes — the many-to-many Challenge relationship, skill tags, and
option-selection checking model apply identically to this type. Rhythmic exercises remain
deferred to PB-43, unaffected by this amendment.

## Amendment (2026-09-16) — documenting the two other Exercise usage contexts

PB-52 (exercise-authoring page improvements) needed to change the authoring page's "used in
challenges" display, since an exercise can appear in contexts other than a Challenge. Tracing
that requirement surfaced that `motifpath-core` already implements two more Exercise linkage
contexts beyond the Challenge many-to-many this ADR documented — neither was ever written down
here or anywhere else, a spec-before-code gap this amendment closes without changing behavior.

**What already exists, undocumented until now:**

1. **ContentNode ↔ Exercise ("path exercises"), many-to-many.** A `ContentNodeExercise` join
   entity (`services/core-domain/internal/adapters/repo/ent/schema/content_node_exercise.go`)
   lets an exercise be linked directly to a content node as static, teacher-curated introductory
   practice — separate from, and independent of, any Challenge on that node. It carries no pass
   threshold and is always returned in authored link order, never shuffled
   (`GET /content-nodes/{id}/exercises`, `POST/DELETE /content-nodes/{id}/exercises/{exercise_id}`
   in `openapi/core-domain-service.yaml`). A node may have a Challenge, path exercises, both, or
   neither — this ADR does not constrain that combination, and no code today enforces one.
2. **Practice session ↔ Exercise: deliberately not a persisted link.**
   `POST /practice-sessions` selects up to `count` exercises matching a `skill_tag` from the
   reusable exercise pool at request time, in random order with shuffled options, and returns
   them under a generated `practice_session_id`. Nothing is written to storage — the session
   exists only in the response and the `exercise.*` tracking events the client emits while
   attempting it. An exercise becomes eligible for practice sessions purely by carrying a
   matching skill tag (decision point 2 of this ADR); there is no separate join table to
   maintain, and none is needed.

**Decision: this amendment documents both contexts as-is — no schema, endpoint, or behavior
changes.** The `ChallengeExercise` join (decision point 1), the `ContentNodeExercise` join, and
the unpersisted skill-tag-driven practice-session selection are the complete set of ways an
Exercise is used. A consumer (e.g. an authoring UI's "used in" display) must query all three —
`GET /challenges/{id}/exercises`-derived linkage, `GET /content-nodes/{id}/exercises`-derived
linkage, and the exercise's own `skill_tags` (as a proxy for practice-session eligibility, since
no persisted session list exists to query) — to show where an exercise is actually usable.

This was considered as a candidate for a single polymorphic `exercise_usage(exercise_id,
context_type, context_id)` table generalizing all contexts uniformly, and rejected: ent has no
native polymorphic-association support, so `context_id` couldn't carry a real foreign-key
constraint to more than one table, trading referential integrity for a uniformity the product
doesn't need — path exercises and challenge exercises already have different shapes (no pass
threshold vs. pass threshold, authored order vs. possibly-shuffled order) that a shared table
would just paper over. Two typed join tables, one per genuinely-persisted context, is what the
existing `ChallengeExercise`/`ContentNodeExercise` implementation already does, and this
amendment simply confirms that pattern going forward rather than replacing it.

## Related ADRs

- **ADR-015** — Challenge belongs to the path node; this ADR narrows ADR-015's implicit
  challenge-owns-exercise coupling (as implemented, not as ADR-015's text required) to a
  many-to-many relationship. The 2026-09-16 amendment further confirms a node's Challenge and its
  path exercises are independent, both optional, additions to ADR-015's node content model.
- **PB-33** (not yet an ADR) — Content classification as a knowledge graph. This ADR's skill tags
  are a deliberate precursor, expected to be superseded or absorbed once PB-33 is decided.

## Follow-up work (not part of this ADR)

- Revise `openapi/components/schemas/challenge.yaml` to match the implemented Go model
  (`content_node_id`, `subject_tag`, `pass_threshold` directly on Challenge) — separate spec PR.
- Add OpenAPI schema and Gherkin scenarios for the Exercise entity: many-to-many
  challenge linkage, skill tags, the generalized `exercise_type` enum, and the options /
  correct-option-id answer-checking shape committed in this ADR.
- **PB-43** — rhythmic exercises feasibility spike: capture mechanism (mic/MIDI input timing
  accuracy), scoring tolerance, and whether it fits this ADR's option-selection checking model
  or needs its own.
- PB-33: use this ADR's skill tags as real input when designing the Skill/Concept knowledge
  graph.
- PB-8g: design how standalone/cross-path exercise suggestion queries exercises by skill tag.
- **PB-52**: update the exercise-authoring page's "used in" display to query all three usage
  contexts confirmed in the 2026-09-16 amendment (challenges, path exercises, skill-tag practice
  eligibility), not just Challenge.

---

*This ADR was decided on 2026-09-13. To revise, create a new ADR with Status: Supersedes ADR-019.*
