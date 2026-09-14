# Plan: PB-40 — Exercise Authoring, Real Implementation

**Task:** PB-40
**Date:** 2026-09-13
**Author:** Gilson (with Claude)
**Status:** In progress — Phase 1 & 2 Done (specs#50, core#17 merged). Phase 3 restarting on a
fresh branch: the first `feat/PB-40/exercise-authoring-ui` attempt (web#16) was closed unmerged
2026-09-14, superseded by the PB-48 app-shell work (specs#54) which extracted shared `AppBar`
and `ExerciseView` components after web#16 had already started — Phase 3 now composes from
those instead of one-off markup.

---

## Goal

Turn PB-40's merged high-fidelity prototype (`design/PB-40-exercise-authoring-builder/`) and
ADR-019's practice content model (Exercise first-class, many-to-many with Challenge, skill
tags, 4-type enum incl. `image_choice` per the 2026-09-13 amendment, unified option-selection
answer-checking) into a real, working exercise-authoring tool: `motifpath-specs` contract →
`motifpath-core` backend → `motifpath-web` authoring UI.

## Hold lifted (2026-09-13)

This plan was on hold pending **PB-45** (content media storage strategy — dev & production).
Scoping it originally surfaced that nobody had decided where exercise/prompt images, audio
stimuli, or the predefined image-picker library are stored, in either environment. PB-45
resolved this via **ADR-021**: S3 + CloudFront in production, MinIO locally, a presigned-PUT
upload flow (`POST /media/upload-url`, added to `core-domain-service.yaml` and
`features/content-management/media-upload.feature` ahead of this plan's Phase 1), and
`image_url`/`audio_url` populated from the resulting `object_url` rather than pasted by hand.
As ADR-021 anticipated, this changed nothing about the OpenAPI schema shape drafted below
(`Exercise`/`Option` still carry plain `image_url`/`audio_url` strings) — only how Phase 3's
authoring UI populates those fields.

## Scope

**In scope:**
- Rewriting the Exercise/Challenge OpenAPI contract in `openapi/core-domain-service.yaml` to
  match ADR-019 (many-to-many linkage, skill tags, 4-type enum, options/correct-option shape).
- Deleting the orphaned, stale `openapi/components/schemas/challenge.yaml` and
  `challenge_classification.yaml` (confirmed unreferenced by any `$ref` — see Open Questions).
- Gherkin scenarios for the new create/link/query behavior.
- `motifpath-core` rebuild: ent schema (Exercise ↔ Challenge M2M, `skill_tags`, 4-type enum,
  options), domain layer, application services, repository, generated HTTP handlers, tests
  (table-driven + godog + testcontainers per this repo's testing discipline).
- `motifpath-web` authoring UI implementing the merged prototype: exercise type picker, prompt/
  title fields, per-type option editors (text/audio/image_choice lists, image_recognition's
  region canvas), the shared image picker (predefined library, or upload a new image via
  `POST /media/upload-url` per ADR-021), skill tags input, a reuse indicator (challenge count),
  and the student-preview modal.

**Out of scope:**
- The presigned upload URL endpoint itself and its underlying S3/MinIO infrastructure. This
  was resolved by **PB-45 / ADR-021** and shipped as a standalone spec change
  (`POST /media/upload-url` in `core-domain-service.yaml`, `MediaUploadUrl` /
  `CreateMediaUploadUrlRequest` schemas, `features/content-management/media-upload.feature`) —
  Phase 3's authoring UI *consumes* that endpoint (request an upload URL, PUT the file, store
  the returned `object_url`), it does not build it. `image_url` / `audio_url` on
  `Exercise`/`Option` remain plain URL strings, per ADR-021's confirmation that this required
  no schema shape change.
- PB-41 (Practice / exercises view, S7) — the student-facing runtime that consumes exercises.
  This plan only builds the authoring side and the data model; PB-41 is a separate backlog item
  and plan, unblocked by this one but not implemented here.
- PB-33 (knowledge graph) — skill tags stay freeform strings, per ADR-019 point 2.
- PB-43 (rhythmic exercises) — explicitly deferred, not part of the 4-type enum this plan ships.
- Any change to `StudentPath`, `LearningPath`, or the tracking-event schemas.

## Prerequisites

- [x] ADR-019 Accepted & merged (`motifpath-specs#40`)
- [x] ADR-019 amendment (`image_choice` 4th type) merged (`motifpath-specs#47`)
- [x] ADR-021 (content media storage strategy) Accepted & merged (`motifpath-specs#49`);
      `POST /media/upload-url` merged ahead of Phase 1
- [x] Open Questions below resolved with Gilson

---

## Open Questions

All resolved with Gilson on 2026-09-13 (confirmed via a decision checkpoint before Phase 1
began — not inferred):

| Question | Resolution |
|---|---|
| **Standalone creation vs. challenge-scoped creation.** | **Split.** `POST /exercises` creates an exercise standalone; `POST /challenges/{challenge_id}/exercises/{exercise_id}` links an existing exercise; `DELETE` on the same path unlinks. The old combined `POST /challenges/{challenge_id}/exercises` is replaced. |
| **`title` field**, distinct from `prompt`. | **Add it.** Required, authoring-only name (e.g. "Alternate picking — descending run"), separate from the student-facing `prompt`. |
| **Per-type option modeling** (region geometry vs. text vs. image). | **One flat `Option` schema** — `option_id`, `is_correct`, plus optional `label` / `image_url` / `region {x, y, width, height, shape}` — validated per-`exercise_type` in the Go domain constructor. No `oneOf`. |
| **Challenge → exercise listing shape.** | **No listing endpoint exists yet (checked: only `POST /content-nodes/{id}/challenges` and `GET /challenges/{challenge_id}` exist; there is no `GET` that lists a content node's challenges or a challenge's linked exercises). Not added by this plan — deferred until a real caller needs it. When it is added, it stays IDs only: full exercise bodies (options, tags, media) are fetched per-exercise via `GET /exercises/{id}`, never embedded in a listing.** In the meantime, `Exercise.challenge_ids` (added in Phase 1) is the only way to query the exercise↔challenge link, from the exercise side. |

---

## Implementation Steps

### Phase 1 — Spec (motifpath-specs)

**Branch:** `feat/PB-40/spec-exercise-authoring`

- [x] Step 1 — Open Questions resolved with Gilson (see above).
- [x] Step 2 — Delete `openapi/components/schemas/challenge.yaml` and
      `challenge_classification.yaml` (confirmed unreferenced by `$ref` anywhere in `openapi/`).
      The real, accurate `Challenge` schema already lives inline in
      `openapi/core-domain-service.yaml` and needs no revision — ADR-019 §6's "stale
      `challenge.yaml`" concern was about these orphaned files, not the inline schema actually
      backing the live endpoints.
- [x] Step 3 — Rewrite `CreateExerciseRequest` / `Exercise` inline in
      `core-domain-service.yaml`: `title`, `prompt`, `exercise_type` (4-value enum), `skill_tags`
      (array of strings), `image_url` / `audio_url` (optional, per-type), `options` (array of the
      new flat `Option` schema: `option_id`, `is_correct`, optional `label`, `image_url`,
      `region {x, y, width, height, shape}`), `challenge_ids` (array, many-to-many).
- [x] Step 4 — Add/modify paths per the Open Questions' resolution: `POST /exercises` (standalone
      create), `GET /exercises/{exercise_id}` (existing, response shape updated),
      `POST /challenges/{challenge_id}/exercises/{exercise_id}` (link),
      `DELETE /challenges/{challenge_id}/exercises/{exercise_id}` (unlink). Update or remove the
      old combined `POST /challenges/{challenge_id}/exercises` per the resolved question.
- [x] Step 5 — Update `features/content-management/exercises.feature`: rewrite existing
      scenarios for the new create/link split and 4-type enum; add scenarios for skill tags
      (create with tags, reject empty-string tag), options (create with correct-option marking,
      reject an exercise with zero correct options — the prototype's own guardrail: "Mark at
      least one option correct"), and the many-to-many link/unlink endpoints (link an existing
      exercise into a second challenge, unlink, link a non-existent exercise → not found).
- [x] Step 6 — Definition of Ready check: OpenAPI endpoints defined, Gherkin covers happy path +
      edge cases + failure cases, no HTTP/SQL/framework language in scenarios (per this repo's
      Gherkin standards).
- [x] Step 7 — `redocly lint` clean; Gherkin syntax valid. Open PR, get it merged before Phase 2.
      PR `motifpath-specs#50` merged 2026-09-13. **Phase 1 is Done.**

### Phase 2 — Backend (motifpath-core)

**Branch:** `feat/PB-40/exercise-authoring-backend`

- [x] Step 1 — `make generate` against the merged Phase 1 spec to regenerate `oapi-codegen`
      stubs; confirm the new types compile.
- [x] Step 2 — Ent schema: rewrite `services/core-domain/internal/adapters/repo/ent/schema/exercise.go`
      — drop `challenge_id` FK, add an `ent.Edge` M2M to `Challenge`, add `title`,
      `skill_tags` ([]string via a JSON field per ent convention), `image_url`/`audio_url`
      (optional strings), expand `exercise_type` enum to 4 values. Add a new `ExerciseOption`
      ent schema (own entity, not embedded JSON, so options are queryable/updatable
      individually): `exercise_id` FK, `is_correct`, optional `label`, `image_url`, and region
      fields (`region_x`, `region_y`, `region_width`, `region_height`, `region_shape`
      nullable). No production data exists yet, so this was a clean schema replacement, not a
      migration/backfill.
- [x] Step 3 — `make migrate:diff` for the Atlas migration.
- [x] Step 4 — Domain layer (`internal/domain/exercise.go`): rewrite `Exercise` struct and
      `NewExercise` — validate `title`/`prompt` non-empty, `exercise_type` against the 4-value
      enum, at least one option with `is_correct: true`, and per-type option shape (e.g.
      `image_recognition` options must carry `region`, `text_response`/`audio_recognition`
      options must carry `label`, `image_choice` options must carry `image_url`). Added an
      `ExerciseOption` domain type.
- [x] Step 5 — Ports/repository: update `internal/ports/exercise_repository.go` and
      `internal/adapters/repo/ent_exercise_repository.go` for the M2M edge and the new
      `ExerciseOption` child entity (create/query exercise with its options in one round trip).
      Added `LinkChallenge` / `UnlinkChallenge` repository methods.
- [x] Step 6 — Application service: split `CreateExercise` (standalone) from `LinkExerciseToChallenge`
      / `UnlinkExerciseFromChallenge`, per the Open Questions' resolved endpoint split.
- [x] Step 7 — HTTP handlers wired to the new application methods (handlers call services only,
      no business logic per this repo's layering rule).
- [x] Step 8 — Tests: table-driven testify tests in `internal/application/` (92.2% coverage,
      above the 80% gate), godog step definitions for the rewritten `exercises.feature`
      (`make test:bdd`), testcontainers integration tests for the new ent schema (`make
      test:int`) — real Postgres, no mocked repository.
- [x] Step 9 — `make lint` clean; no `//nolint` without an inline reason; no bare `interface{}`/`any`.

**Also landed in Phase 2** (unplanned, but required to unblock BDD CI — see below): the
`POST /media/upload-url` endpoint itself. It was left unimplemented at the start of Phase 2 (out
of this plan's original scope, per ADR-021's own note that its implementation was tracked
separately), but the specs merge that shipped its contract ahead of this plan meant every
`motifpath-core` PR's BDD job started failing on undefined `media-upload.feature` steps,
regardless of whether that PR touched exercises at all. Implemented for real: `MediaService`,
domain validation, an S3-compatible storage adapter (works against real S3 in production and
MinIO in local dev via the same client, differing only in construction), MinIO added to
`docker-compose.yml`/`process-compose.yaml` for local dev, and BDD steps for all 7
`media-upload.feature` scenarios. Verified against a real MinIO instance (presign → PUT → GET
round-trip), not just the unit-test fakes. PR `motifpath-core#17` merged 2026-09-14 (dev).
**Phase 2 is Done.**

### Phase 3 — Frontend (motifpath-web)

**Branch:** `feat/PB-40/exercise-authoring-ui`

- [ ] Step 1 — `npm run generate:api` against the merged Phase 1 spec.
- [ ] Step 2 — TDD: write failing component tests first (per this repo's TDD-mandatory rule)
      for each new piece, then implement:
      - `ExerciseAuthoringView.vue` (or similar — a route under a teacher/admin area; this repo
        has no existing teacher-facing route yet, so this plan also adds the first one) with
        title/prompt fields and an exercise-type picker.
      - Per-type option editors: `TextOptionsEditor.vue`, `AudioOptionsEditor.vue`,
        `ImageChoiceOptionsEditor.vue`, `ImageRegionEditor.vue` (canvas-based region
        draw/resize/drag, matching the prototype) — composed from the owned component library
        (`PrimaryButton`, `Icon`, tokens) per ADR-018, new components only where the prototype's
        interaction genuinely has no existing primitive (the region canvas is a strong
        candidate for ADR-018's "framework-agnostic island" pattern, like the fretboard
        renderer — decide during implementation, not pre-committed here).
      - A shared image picker component (predefined library, or upload a new image via
        `POST /media/upload-url` per ADR-021) reused identically by `image_recognition` and
        `image_choice`, matching the prototype's explicit design goal.
      - Skill tags input (add/remove, matching the prototype's `tags`/`tagInput` state shape).
      - A reuse indicator showing `challenge_ids.length` from the API response.
      - A student-preview modal with the Portrait/Landscape toggle matching ADR-015's S7 spec,
        reusing the prototype's `previewOrientation` state pattern.
- [ ] Step 3 — Gate: `npm run test`, `npm run typecheck`, `npm run lint`, `npm run build` clean.
- [ ] Step 4 — Manual browser smoke against a real `devbox services up ... web` stack, creating
      one exercise of each of the 4 types end to end.

### Phase 4 — Infrastructure (motifpath-infra)

Not applicable — no infra change.

---

## Rollback Plan

Phase 1 (spec) and Phase 2 (backend) ship together — a bad Phase 2 merge reverts via
`git revert` on `motifpath-core`'s merge commit; no production data exists yet, so no
migration rollback/backfill is needed (same reasoning ADR-019 already relies on). Phase 3
(frontend) is additive (a new route + new components) and can be reverted independently
without affecting Phase 1/2's contract or backend.

## Validation

- [ ] All 4 exercise types can be created, retrieved, and linked/unlinked from a challenge via
      the real API (not just the design prototype).
- [ ] An exercise with zero correct options is rejected at creation (ADR-019's own stated
      requirement: "an exercise that can't be checked can't be practiced").
- [ ] The same exercise can be linked to two different challenges without duplication —
      the concrete reuse case ADR-019's Context section describes.
- [ ] `motifpath-web`'s authoring UI produces exercises visually and structurally matching the
      merged prototype (`design/PB-40-exercise-authoring-builder/Main.dc.html`) for all 4 types.
- [ ] Full gate green in all three repos (godog + testify + testcontainers in core; Vitest +
      typecheck + lint + build in web; Redocly + Gherkin lint in specs).

## Related

- **ADR:** [ADR-019](../adrs/ADR-019-practice-content-model.md) (+ 2026-09-13 `image_choice`
  amendment, `motifpath-specs#47`)
- **Design:** [`design/PB-40-exercise-authoring-builder/`](../design/PB-40-exercise-authoring-builder/)
  — the merged prototype this plan implements for real
- **ADR:** [ADR-021](../adrs/ADR-021-content-media-storage-strategy.md) (content media storage
  strategy) — resolves PB-45, unblocking this plan's Phase 3 upload flow (see "Hold lifted"
  above)
- **Backlog item:** PB-40 (Exercise-authoring builder)
- **Downstream:** PB-41 (Practice / exercises view) — consumes this plan's data model but is a
  separate plan
