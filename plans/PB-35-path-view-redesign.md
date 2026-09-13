# Plan: PB-35 — Path View Redesign (PathStep/PathContent Visual Redesign)

**Task:** PB-35 (Phase 1 sketches landed as child item PB-36 — see `design/PB-36-path-view-directions/`)
**Date:** 2026-09-12
**Author:** Gilson Yamada (with Claude)
**Status:** Ready — Phase 2 decision made 2026-09-13; Phase 3 (real implementation, TDD) not yet started

---

## Goal

Give the student path view (`PathStep.vue` / `PathContent.vue`) a real, mobile-first visual
redesign — built on PB-34 Phase 2's owned component library and token system — that goes beyond
PB-34's deliberately "tokens only, same markup" restyle and sets the base UI pattern the rest of
the student-facing screens (PB-8e onward) will follow.

## Scope

**In scope:**
- 2–3 distinct mobile-first layout directions for the path list (step marker, title, status,
  affordance), each a throwaway prototype composed from the existing owned library
  (`StepRow`, `Icon`, `ProgressMeter`, `PrimaryButton`, `AppShell`, the `State*` set) — no new
  shared primitives invented for the sketches
- A responsive scale-up pass (tablet/desktop) for whichever direction is chosen
- A decision checkpoint with Gilson before any direction becomes the real implementation
- Implementing the chosen direction into `PathStep.vue`/`PathContent.vue` for real, with tests
  written first per TDD
- Verifying the result in both light and dark theme

**Out of scope:**
- PB-8j's structural/IA/state-blueprint work — that item is explicitly navigation/IA scope, not
  visual design; this plan does not touch routing or page composition beyond the path view itself
- Any new shared component beyond the existing six (`StepRow`, `AppShell`, `ProgressMeter`,
  `PrimaryButton`, `Icon`, `State*`) — if a sketch seems to need one, that's an open question for
  Gilson, not something to build unilaterally (ADR-018's architecture is not being reopened)
- Pixel-matching the reference mock Gilson was shown when this item was created — explicit
  instruction was "we must do better," not "copy this"
- Any `motifpath-core` or `motifpath-specs` (contract) change — `StudentPathView`'s shape is
  unchanged; this is presentation-only

## Prerequisites

- [x] PB-34 Phase 2 merged — owned component library + real tokens + dark mode
  (`motifpath-web` dev, PRs #10–#13)
- [x] ADR-018 Accepted (`adrs/ADR-018-frontend-ui-architecture-design-system.md`)
- [x] PB-35 backlog item created in Notion (Discovery, P1, Persona Student)

---

## Implementation Steps

All phases are in `motifpath-web`, branched from `dev`. No `motifpath-specs` or
`motifpath-core` changes are needed — this is a frontend presentation change only.

### Phase 1 — Layout direction sketches (mobile-first)

**Branch:** `design/PB-35/layout-sketches`

- [ ] Re-read current `PathStep.vue`/`PathContent.vue` and the six owned components to confirm
  what's already composable without new primitives (`StepRow`'s position/status/action slots,
  `Icon`'s four roles, `ProgressMeter`, `PrimaryButton`)
- [ ] Build 2–3 throwaway prototype variants at mobile viewport (~375px), each a variant of
  `PathContent`/`PathStep` composition only — e.g. (a) current list-row density with stronger
  current-step emphasis, (b) card-per-step with icon badge and status pill, (c) grouped/collapsed
  sections with a compact current-step focus row. Each variant reuses only the six existing
  components; do not add new ones to make a sketch work — note the gap as an open question
  instead
- [ ] Render sketches behind a temporary route/story (not merged into the real path view yet) so
  they're viewable in the running app, in both light and dark theme
- [ ] Gate: no new shared component added; `vue-tsc --build`/`eslint` clean on the sketch branch
  (sketches don't need test coverage — they're thrown away after the decision)

### Phase 2 — Decision checkpoint

- [ ] Walk Gilson through the 2–3 directions (mobile view first, then how each would scale to
  tablet/desktop)
- [ ] Record the chosen direction and why, plus any explicitly rejected elements, in this plan's
  Open Questions table below
- [ ] Confirm whether the choice needs anything beyond the existing six components — if yes, that
  becomes its own small ADR-018 amendment discussion before Phase 3 starts, not a silent addition

### Phase 3 — Real implementation (TDD)

**Branch:** `feat/PB-35/path-view-redesign`

- [ ] Write failing tests first for `PathStep.spec.ts`/`PathContent.spec.ts` against the chosen
  direction's new markup/behavior (existing `data-test` hooks — `path`, `path-progress`,
  `path-section`, `section-heading`, `path-step`, `step-status`, `step-affordance` — stay unless
  the chosen direction genuinely changes what they mean; note any hook rename explicitly here)
- [ ] Implement `PathStep.vue`/`PathContent.vue` against the chosen direction, composing only the
  existing owned library
- [ ] Responsive scale-up: verify the chosen direction at tablet/desktop breakpoints, adjusting
  only spacing/layout via Tailwind responsive classes — no direction change at wider viewports
- [ ] Delete the Phase 1 sketch branch/route once the real implementation lands
- [ ] Gate: `vitest run`, `vue-tsc --build`, `eslint --max-warnings 0`, `vite build` all clean;
  manual check in both themes at mobile, tablet, and desktop widths

---

## Rollback Plan

Phase 1 sketches never merge to `dev`, so there is nothing to roll back there. Phase 3 is a
single PR to `dev` touching only `PathStep.vue`/`PathContent.vue` (and their specs) — a bad
merge reverts cleanly with `git revert` on the merge commit, since no other component or API
depends on the new markup.

## Validation

- [ ] 2–3 mobile-first layout directions were actually built and shown (not just described) at
  the Phase 2 checkpoint
- [ ] Gilson explicitly signed off on one direction before Phase 3 implementation started
- [ ] Chosen direction reuses only the existing six owned components (or an explicit,
  Gilson-approved exception is recorded in Open Questions)
- [ ] `PathStep`/`PathContent` render correctly — locked, current, completed, and not-started
  steps all legible — in both light and dark theme, at mobile (~375px), tablet, and desktop widths
- [ ] Full test suite (existing + updated specs) passes; no regression in `path` view manual
  smoke (`devbox services up ... web`)

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Which of the 2–3 sketched directions is chosen, and why? | Gilson | **Direction D — Cards + focus** (2026-09-13). Phase 1 actually produced 4 directions, not 2–3 (Direction D was added live during review, blending B and C after feedback that C's always-auto-expanding current step next to a bare completed row read oddly). Collapsed steps are exactly Direction B's card; the current step gets Direction C's focus card; no connecting rail. |
| Does the chosen direction require anything beyond the existing six owned components? | Gilson | **Yes — one new component, `FocusCard`**, promoted to the shared library rather than kept as local `PathContent.vue` markup, anticipating reuse in PB-8e/PB-38. Recorded as an amendment to ADR-018 decision point 3 (`adrs/ADR-018-frontend-ui-architecture-design-system.md`, "Amendment (2026-09-13)" section). |
| Do any `data-test` hooks change meaning/name under the chosen direction? | Claude (flag), Gilson (approve) | Pending Phase 3 |

## Related

- **ADR:** [ADR-018](../adrs/ADR-018-frontend-ui-architecture-design-system.md), amended
  2026-09-13 to add `FocusCard` as a 7th owned component per this plan's Phase 2 decision
- **Plan:** [PB-34 Phase 2](PB-34-phase-2-frontend-design-system.md) (owned component library this
  plan builds on)
- **Design:** [`design/PB-36-path-view-directions/`](../design/PB-36-path-view-directions/) —
  the Phase 1 sketches (4 directions, not the originally-scoped 2–3) this plan's Phase 2
  decision was made against
- **Backlog item:** PB-35 (Notion, Discovery, P1); Phase 1 sketches tracked as child item PB-36
