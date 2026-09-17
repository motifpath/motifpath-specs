# Plan: Tiptap rich-text prompt editor for exercise authoring

**Task:** PB-46
**Date:** 2026-09-17
**Author:** Gilson (Product Owner) + Claude
**Status:** Ready

---

## Goal

Wire real Tiptap rich-text editing into `ExerciseAuthoringView`'s prompt field (currently a
plain `<textarea>`), and render the resulting structured content correctly on the student-facing
Practice view — implementing the contract already merged in motifpath-specs (PR #67 ADR-020
amendment, PR #68 `PromptDocument` OpenAPI schema + Gherkin coverage).

## Scope

**In scope:**
- motifpath-core: `Exercise.prompt` becomes a structured JSON document (`ent` `field.JSON`),
  validated against the `PromptDocument`/`PromptNode`/`PromptMark` node/mark allowlist from
  the OpenAPI contract, across create/update/get.
- motifpath-web: Tiptap wired into `ExerciseAuthoringView`'s prompt field with the full
  toolbar (H1–H3/Paragraph, Bold/Italic/Strike/Highlight, alignment, Bullet/Ordered List,
  Link, Table, Image), teacher-route-only (lazy chunk).
- motifpath-web: `ExerciseView.vue` (the student-facing Practice renderer) renders the
  `PromptDocument` JSON via a small hand-written node-walker — no Tiptap/`@tiptap/pm` on that
  route.
- Back-compat handling for exercises whose `prompt` predates this change (plain string, not a
  valid `PromptDocument`).

**Out of scope:**
- PB-8i's lesson-content editor (callout node, audio/video media, drag-handle reordering,
  tables/paste-upload beyond what's already ADR-020-validated) — separate backlog item, noted
  on the PB-25/PB-8i card, not touched here.
- Any change to `exercise_type`, `options`, or other `Exercise`/`CreateExerciseRequest` fields.

## Prerequisites

- [x] ADR-020 amendment merged (motifpath-specs PR #67, commit 148e9dc)
- [x] `PromptDocument` OpenAPI schema + Gherkin scenarios merged (motifpath-specs PR #68,
      commit 0f5ee63)
- [ ] Local `motifpath-core` and `motifpath-web` checkouts moved off the leftover
      `feat/PB-52/audio-selection-exercise-type` branch onto `dev` before branching

---

## Implementation Steps

### Phase 1 — Spec (motifpath-specs)

Already done — PR #67 and PR #68, merged to `main` as commits 148e9dc / 0f5ee63.

**Definition of Ready check:**
- [x] OpenAPI schema defined (`PromptDocument`/`PromptNode`/`PromptMark`,
      `openapi/core-domain-service.yaml`)
- [x] Gherkin: happy path (richly formatted prompt) + 2 edge cases (plain single-paragraph
      prompt; updating a prompt to add formatting) + 2 failure cases (unstructured prompt;
      unsupported node type) — `features/content-management/exercises.feature`
- [x] ADR exists (ADR-020, amended)

---

### Phase 2 — Backend (motifpath-core)

**Branch:** `feat/PB-46/exercise-prompt-rich-text` (from `dev`, not the stale PB-52 branch)

- [ ] Step 1: `make generate` to regenerate `internal/adapters/http/generated/api.gen.go`
      from the merged OpenAPI spec — `CreateExerciseRequest.Prompt` /
      `UpdateExerciseRequest.Prompt` / `Exercise.Prompt` become the generated `PromptDocument`
      struct type instead of `string`.
- [ ] Step 2 (TDD — test first): in `internal/domain/exercise_test.go` (create if it doesn't
      exist as a domain-level test file; otherwise extend the existing one), add failing
      table-driven cases for `validateExerciseContent` / prompt validation:
      - accepts a `PromptDocument` using every allowed node type (heading, paragraph, text,
        bulletList, orderedList, listItem, table, tableRow, tableHeader, tableCell, image) and
        every allowed mark (bold, italic, strike, highlight, link)
      - accepts a minimal single-paragraph document
      - rejects a document containing a node type outside the allowlist (e.g. `"video"`),
        producing a `FieldError{Field: "prompt", ...}`
      - rejects a `prompt` that isn't a well-formed document (missing `type: "doc"` root,
        missing `content`)
      - rejects an empty `prompt` (existing case — keep passing)
- [ ] Step 3: implement the change to make Step 2 pass — update
      `services/core-domain/internal/adapters/repo/ent/schema/exercise.go`'s `prompt` field
      from `field.Text("prompt")` to `field.JSON("prompt", PromptDocument{})` (following the
      existing `field.JSON("skill_tags", []string{})` pattern), define the
      `PromptDocument`/`PromptNode`/`PromptMark` Go types in `internal/domain` (or reuse the
      generated OpenAPI types if their shape is suitable for direct persistence — decide during
      implementation, see Open Questions), and implement the node/mark allowlist check in
      `validateExerciseContent`.
- [ ] Step 4: run `go run entc.go` / ent codegen (whatever this repo's Makefile target is) to
      regenerate the ent client for the new field type.
- [ ] Step 5 (TDD — test first): in `internal/application/exercise_service_test.go`, add
      failing cases for `CreateExercise`/`UpdateExercise`/`GetExercise` covering the same
      accept/reject matrix at the service layer (confirms the HTTP-generated type flows
      correctly through to the domain validation, not just unit-level domain logic).
- [ ] Step 6: implement/adjust `internal/application/exercise_service.go` so Step 5 passes.
- [ ] Step 7 (TDD — test first): add godog step definitions in
      `internal/bdd/steps_exercises_test.go` for the five new/changed Gherkin steps that don't
      yet have Go implementations:
      - `creates a <type> exercise titled "..." with a prompt formatted as a heading, a
        bulleted list, a table, and an image, and one correct option`
      - `the exercise's prompt preserves its heading, bulleted list, table, and image
        structure`
      - `creates a <type> exercise titled "..." with a prompt containing a single unformatted
        paragraph and one correct option`
      - `exists with a plain, unformatted prompt` / `updates exercise "..." with a prompt
        formatted as bold text and a bulleted list, and one correct option` / `the exercise's
        prompt preserves its bold text and bulleted list structure`
      - `submits a create exercise request whose prompt is a plain string instead of a
        structured document`
      - `submits a create exercise request whose prompt document contains a video node`
      Run `godog` and confirm these scenarios fail for the right reason (undefined steps)
      before Step 3/6 land, per this org's strict-mode BDD discipline (see the BDD
      strict-mode-gap incident this project already hit once — `Strict:true` must stay on,
      undefined steps must fail the build, not silently pass).
- [ ] Step 8: implement the step bodies, run the full godog suite green.
- [ ] Step 9: back-compat — **decision (2026-09-17, Gilson): read-time shim only, no backfill
      migration.** `GetExercise`/`ListExercises` wrap a stored `prompt` that isn't valid
      `PromptDocument` JSON (i.e. legacy plain text) into a single-paragraph document
      (`{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":
      "<legacy value>"}]}]}`) at read time, so every response shape is consistent regardless
      of when the row was written. No database migration script, no backfill job. Add a
      dedicated test case for this in Step 5 (service-layer test): seed a row with a
      plain-string `prompt` (bypassing domain validation, as legacy data would have),
      `GetExercise` it, assert the shim'd document shape comes back.

**Coverage gate:** 80% on `internal/application/` and `internal/domain/` — CI fails below this
(existing project gate, unchanged by this plan).

---

### Phase 3 — Frontend (motifpath-web)

**Branch:** `feat/PB-46/exercise-prompt-rich-text` (from `dev`, not the stale PB-52 branch;
depends on Phase 2 merging to `dev` first so the regenerated API client is available)

- [ ] Step 1: `npm run generate:api` to regenerate `src/api/generated/core-domain.ts` —
      `CreateExerciseRequest.prompt` / `UpdateExerciseRequest.prompt` / `Exercise.prompt`
      become the generated `PromptDocument` type.
- [ ] Step 2: install Tiptap packages per ADR-020's decision points 1/4/6/7 plus this
      amendment's added marks: `@tiptap/vue-3`, `@tiptap/pm`, `@tiptap/extension-heading`,
      `@tiptap/extension-bold`, `@tiptap/extension-italic`, `@tiptap/extension-strike`,
      `@tiptap/extension-highlight`, `@tiptap/extension-text-align`,
      `@tiptap/extension-bullet-list`, `@tiptap/extension-ordered-list`,
      `@tiptap/extension-list-item`, `@tiptap/extension-link`, `@tiptap/extension-table` (+
      its bundled `TableRow`/`TableHeader`/`TableCell`), `@tiptap/extension-image`,
      `@tiptap/extension-document`, `@tiptap/extension-paragraph`, `@tiptap/extension-text` —
      hand-picked per decision point 1, not `@tiptap/starter-kit`.
- [ ] Step 3 (TDD — test first): in
      `src/features/teacher/views/__tests__/ExerciseAuthoringView.spec.ts`, add failing tests:
      - the prompt field mounts a Tiptap editor, not a `<textarea>`
      - the toolbar exposes all required commands (H1/H2/H3/Paragraph,
        Bold/Italic/Strike/Highlight, alignment × 4, Bullet/Ordered List, Link, Table, Image)
        and each toggles/applies correctly
      - submitting the form sends `prompt` as a `PromptDocument` object (`editor.getJSON()`
        shape), not a string
      - loading the view to edit an existing exercise whose `prompt` is legacy plain text
        loads it into the editor as a single-paragraph document (see Phase 2 Step 9's decision
        — this test encodes whatever that decision is)
- [ ] Step 4: implement the Tiptap integration in `ExerciseAuthoringView.vue` to pass Step 3 —
      editor mounted behind the existing form field, hand-built toolbar component (new, e.g.
      `PromptToolbar.vue`), paste-to-insert image upload reusing PB-45's presigned-PUT upload
      flow (ADR-021).
- [ ] Step 5 (TDD — test first): in
      `src/shared/components/__tests__/ExerciseView.spec.ts`, add failing tests for a new
      prompt-rendering path:
      - a `PromptDocument` with headings/bold/italic/strike/highlight/alignment/lists/link
        renders the expected DOM structure (not raw JSON, not `[object Object]`)
      - a document containing a `table` node renders a table
      - a document containing an `image` node renders an `<img>` with `src`/`alt` from
        `attrs`
      - confirm via bundle/import assertions (or a lint rule) that this component does not
        import `@tiptap/vue-3` or `@tiptap/pm` — the architectural constraint from the ADR-020
        amendment
- [ ] Step 6: implement a small hand-written `PromptDocument` → Vue-renderable structure
      (e.g. a recursive functional component or render function walking `PromptNode[]`) in
      `src/shared/components/` (new file, e.g. `PromptRenderer.vue`), replace `ExerciseView.vue`'s
      `{{ prompt }}` interpolation with it, passing Step 5.
- [ ] Step 7: run `vue-tsc --build --strict` and `eslint --max-warnings 0` — both must pass
      clean per this repo's existing gate (ADR-020's spike already established this bar).
- [ ] Step 8: bundle-size check — confirm `ExerciseAuthoringView`'s route chunk absorbs the
      Tiptap/ProseMirror cost (expect roughly the ADR-020 spike's ~185 kB gzip ballpark) and
      that the student-facing Practice route's bundle is unaffected (the ADR amendment's core
      guarantee) — same measurement method PB-34 established.

---

## Rollback Plan

- motifpath-core: the `prompt` field change is an ent schema migration (`field.Text` →
  `field.JSON`). Roll back via a new migration reverting the column type, redeploying the
  previous service image per ADR-004's blue/green pipeline. No backfill job exists (Phase 2
  Step 9 uses a read-time shim, not a data migration), so this rollback carries no data-loss
  risk beyond the column-type revert itself.
- motifpath-web: revert to the previous `ExerciseAuthoringView`/`ExerciseView` commit;
  no data migration risk on this side (rendering only).

## Validation

- [ ] All new/updated godog scenarios in `exercises.feature` pass against `motifpath-core`
- [ ] `internal/application` and `internal/domain` coverage stays ≥ 80%
- [ ] `ExerciseAuthoringView` and `ExerciseView` Vitest suites pass, including the new
      prompt-specific cases
- [ ] `vue-tsc --build --strict` and `eslint --max-warnings 0` clean on motifpath-web
- [ ] Manual Clerk smoke: a teacher authors an exercise using every toolbar option (headings,
      marks, alignment, lists, link, table, image), saves it, and a student sees it rendered
      correctly on the Practice view
- [ ] Bundle check: Practice route's gzip size is unchanged from its pre-PB-46 baseline;
      `ExerciseAuthoringView`'s lazy chunk absorbs the ProseMirror cost

---

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Should `PromptNode`/`PromptMark` be defined as new hand-written Go types in `internal/domain`, or can the `oapi-codegen`-generated OpenAPI types be persisted directly via `field.JSON`? (Generated types may carry OpenAPI-specific tags/pointers that are awkward to persist directly — needs a quick spike during Phase 2 Step 3, not a full research pass.) | Implementer (Phase 2 Step 3) | — |
| Exact npm versions for the hand-picked Tiptap packages (Phase 3 Step 2) — pin to what ADR-020's PB-44 spike validated, or take latest within the same major? | Implementer (Phase 3 Step 2) | — |

---

## Related

- **ADR:** ADR-020 (Tiptap as content-authoring editor) + its 2026-09-17 amendment
- **Spec files:** `openapi/core-domain-service.yaml` (`PromptDocument`/`PromptNode`/`PromptMark`,
  `CreateExerciseRequest`/`UpdateExerciseRequest`/`Exercise`),
  `features/content-management/exercises.feature`
- **Backlog item:** PB-46
- **Related PRs:** motifpath-specs #67, #68
