# Plan: PB-41 — Practice View (S7), motifpath-web implementation

**Task:** PB-41
**Date:** 2026-09-15
**Author:** Gilson (with Claude)
**Status:** Draft

---

## Goal

Build the student-facing Practice screen (wireframe S7, `design/PB-8j-wireframes/Practice.dc.html`)
at `/path/nodes/:nodeId/practice`: a student works through a content node's challenge exercises
one at a time using the existing `ExerciseView` component, can step back to revisit an answered
exercise, and sees a score summary on completion. Spec and backend are already merged
(`motifpath-specs` PR #59, `motifpath-core` PR #21) — this plan covers only the `motifpath-web`
slice.

## Scope

**In scope:**
- Regenerating the `motifpath-web` API client (`npm run generate:api`) against `motifpath-specs`
  `main`, which currently lacks `listContentNodeChallenges`, `listChallengeExercises`, and the
  other PR #59 endpoints entirely.
- Extending `ExerciseView.vue` with a selection emit — today it is read-only (teacher preview
  only), and a practice flow needs to know what the student picked.
- A first client-side event-tracking module (`src/shared/services/` — no such thing exists in
  `motifpath-web` yet) that builds envelopes for `exercise.started` / `exercise.progress` /
  `exercise.answer_sent` / `exercise.ended` and posts them via the generated `event-ingestion`
  client, including per-page-load `session_id` generation. This is required, not optional:
  per the PR #59 merge commit, there is no submit-answer REST endpoint by design — scoring and
  node completion flow entirely through these events and the Aggregation Worker (ADR-011).
- The `PracticeView.vue` page: fetch the node's challenge via `GET
  /content-nodes/{id}/challenges`, then its exercises via `GET
  /challenges/{challenge_id}/exercises`; loading/error/in-progress/result states; slim progress
  bar (no "N of M" text per the wireframe); Back/Next navigation with revisable answers; help
  "?" affordance; result screen with score and "Finish".
- New route `path/nodes/:nodeId/practice`, `requiresAuth: true`, no role restriction, alongside
  the existing `node` route.
- A minimal entry point into Practice from `NodeView.vue` (currently a placeholder body) so the
  route isn't orphaned before PB-8e builds the real S6 lesson screen — not the full S6 screen
  itself.

**Out of scope:**
- `NodeView.vue`'s real S6 lesson content — that's PB-8e. This plan only adds enough of a link
  for Practice to be reachable.
- `GET /practice-sessions` (spontaneous/random practice by skill tag) — a separate feature,
  likely PB-8g (recommendation-driven practice), not the lesson-node challenge flow this plan
  builds.
- `GET /content-nodes/{id}/exercises` (unassessed "path exercises") — different concept from
  challenge exercises; not part of the S7 wireframe.
- Landscape side-by-side / portrait-stacked responsive layout polish beyond a reasonable first
  pass — flag as follow-up if it needs a dedicated pass.
- Any change to `motifpath-core` or `motifpath-specs` — both already merged for this feature.

## Prerequisites

- [x] `motifpath-specs` PR #59 merged to `main` (practice/exercise read endpoints, event schema).
- [x] `motifpath-core` PR #21 merged (endpoints live).
- [x] ADR-019 accepted (practice content model — Exercise/Challenge/Option shapes).
- [ ] `motifpath-web` API client regenerated from current `motifpath-specs` `main`.

---

## Implementation Steps

### Phase 3 — Frontend (motifpath-web)

**Branch:** `feat/PB-41/practice-view`

- [ ] Step 1: `npm run generate:api` — regenerate `src/api/generated/core-domain.ts` and
      `event-ingestion.ts`. Confirm `listContentNodeChallenges`, `listChallengeExercises`, and
      the `exercise.*` / `lesson.*` event schemas appear.
- [ ] Step 2 (TDD): write a failing test in `ExerciseView.spec.ts` for a new selection emit
      (e.g. `@select="(optionId) => ..."`), then implement it. Keep the component still
      correctness-blind — it emits the chosen option id, not whether it's right; the page layer
      checks `is_correct` against the already-fetched `Option[]`.
- [ ] Step 3 (TDD): `useEventTracking` composable — a `session_id` (generated once, held for the page's
  lifetime — no persistence across reload per the event schema's own doc comment), and a
  `track(event)` wrapper around `POST /events`. Write failing tests first (envelope shape,
  required fields, one call per event) against a mocked `event-ingestion` client.
- [ ] Step 4 (TDD): `usePracticeSession` composable (or inline in the page) — fetches challenge
      + exercises for a `content_node_id`, holds `currentIndex`, per-exercise answered state
      (selected option id, correctness, revisable via Back), and derives progress/result. Tests
      first: loading → success → error paths; Back/Next index math including revisiting an
      answered exercise without re-scoring it twice; last-exercise Next becomes "See result".
- [ ] Step 5: `PracticeView.vue` page composing `ExerciseView` with the header/progress
      bar/Back-Next/result markup from the wireframe. Emits `exercise.started` on mount per
      exercise, `exercise.answer_sent` on selection, `exercise.ended` on leaving an exercise
      (Next/Back), `lesson.started`/`lesson.completed`-equivalent bookkeeping only if in scope
      per Step's event list — confirm against `events.yaml` before wiring lesson-family events;
      if node-level lesson events belong to PB-8e's lesson screen instead, emit only the
      `exercise.*` family here.
- [ ] Step 6: route registration in `src/router/index.ts` — `nodes/:nodeId/practice` nested
      under the existing `path` parent, `requiresAuth: true`.
- [ ] Step 7: minimal link from `NodeView.vue`'s placeholder body into Practice (button or
      link, not a full lesson screen).
- [ ] Step 8: manual Clerk smoke — start a practice session, answer through to result, confirm
      no console errors and events post successfully (check Network tab / event-ingestion logs).

---

## Rollback Plan

Frontend-only change behind a route not linked from primary nav until Step 7; reverting is a
plain `git revert` of the merge commit. No data migration, no backend change to roll back.

## Validation

- [ ] `npm run test` and `npm run type-check` pass in `motifpath-web`.
- [ ] Visiting `/path/nodes/:nodeId/practice` for a node with a challenge renders exercises one
      at a time, matches the wireframe's states (loading/error/in-progress/result).
- [ ] Selecting an option, then Back, then Next preserves the prior selection (revisable, not
      re-randomized, not re-scored).
- [ ] Last exercise's "Next ›" reads "See result"; Finish returns to the node.
- [ ] `exercise.started` / `exercise.answer_sent` / `exercise.ended` events are observed posting
      to `POST /events` with correct `student_id`, `session_id`, `challenge_id`, `exercise_id`.
- [ ] A node with no challenge (empty `listContentNodeChallenges` result) shows a sane empty
      state rather than an error.

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Does `lesson.started`/`lesson.completed` belong to this page or to PB-8e's future S6 screen? | Gilson | Default: PB-8e, since Practice is entered from a lesson already "started" — confirm against `events.yaml` lesson-event semantics in Step 5. |
| Multiple challenges per content node — wireframe assumes one. If `listContentNodeChallenges` returns >1, which do we run? | Gilson | Default: first returned; revisit if backend ordering isn't meaningful. |

---

## Related

- **ADR:** ADR-019 (practice content model), ADR-011 (Aggregation Worker / event-driven
  completion — referenced by PR #59's merge commit).
- **Spec files:** `openapi/core-domain-service.yaml` (`listContentNodeChallenges`,
  `listChallengeExercises`), `openapi/components/schemas/events.yaml` (`exercise.*` family).
- **Wireframe:** `design/PB-8j-wireframes/Practice.dc.html` (S7).
- **Backlog item:** PB-41 (epic PB-35 UI design; unblocked by PB-42/ADR-019, PB-49).
