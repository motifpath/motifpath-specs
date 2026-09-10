# Plan: PB-34 Phase 1 — Frontend Architecture De-risking Spike

**Task:** PB-34
**Date:** 2026-09-10
**Author:** Gilson
**Status:** Ready

---

## Goal

Prove ADR-018's four decision points against `motifpath-web`'s real toolchain on a throwaway
branch, so ADR-018 can move from *Proposed — pending a de-risking spike* to *Accepted* (or be
amended). This is the validation the ADR's own "Validation" section calls for.

## Scope

**In scope (`motifpath-web` only, throwaway branch — nothing merges):**
- A `tokens.json` → `tailwind.config.ts` pipeline with placeholder values (colour roles, one
  type scale, one spacing scale).
- One real Reka UI primitive wired end to end and styled only through tokens.
- `lucide-vue-next` added, tree-shaking confirmed, and `PathStep`'s "Completed" / "Locked" text
  labels replaced by icons behind an `Icon` wrapper.
- A trivial `<canvas>` engine mounted behind a ~20-line Vue wrapper, to prove island isolation.
- A findings note committed to `motifpath-specs` (PB-28 style) plus a recommendation.

**Out of scope:**
- Real brand token values — those are `motifpath-brand` / PB-34 Phase 2, gated on
  `colors.json`.
- The full component library (`AppShell`, `StepRow`, `State*`, `ProgressMeter`, `PrimaryButton`)
  — Phase 2.
- Restyling any screen beyond the single `PathStep` icon swap.
- Merging anything to `motifpath-web` `dev`. The spike branch is deleted after the findings
  note lands.
- Any backend, spec-contract, or infra change.

## Prerequisites

- [x] ADR-018 open for review (`motifpath-specs#35`)
- [x] `motifpath-web` `dev` green, PB-8d `PathStep` present (`motifpath-web#9` — may still be
      open; branch the spike from `dev` and cherry-pick or rebase on `#9` if `PathStep` is not
      yet merged)
- [ ] ~1–2 focused days available; this is a spike, not a feature — timebox it

---

## Implementation Steps

### Phase 1 — Spec (motifpath-specs)

**No spec-contract change.** This spike validates an architecture decision; it touches no
OpenAPI, event, or Gherkin file. The only `motifpath-specs` artifact is the findings note
(Phase 3, Step 6).

### Phase 2 — Backend (motifpath-core)

Not applicable — no backend change.

### Phase 3 — Frontend (motifpath-web)

**Branch:** `spike/PB-34/frontend-architecture` (from `dev`; throwaway, never merged)

- [ ] Step 1 — **Token pipeline.** Add `src/design/tokens.json` with placeholder values:
      colour roles (`surface`, `ink`, `accent`, `success`, `danger`, `muted`), a type scale
      (`xs`–`2xl` with size + line-height), a spacing scale. Import it into
      `tailwind.config.ts` and map it onto `theme.extend`. Verify: `npm run typecheck`
      (`vue-tsc --build`) passes; a component can use `text-ink`, `bg-surface`, `text-ink/60`
      (opacity modifier), and `p-[var(--…)]`-style arbitrary values resolve. Record any
      friction (e.g. JSON import needing `resolveJsonModule`, or a Tailwind v3 vs v4 config
      shape mismatch).
- [ ] Step 2 — **Reka UI primitive.** `npm i reka-ui`. Build a `SpikeDialog.vue` (or Tabs)
      composing Reka UI primitives, styled only with token utilities. Add a component test with
      the existing Vitest + `@vue/test-utils` setup asserting open/close and focus trap. Verify
      by hand: `Esc` closes, focus returns to the trigger, tab order is contained. Then delete
      the Reka imports from a copy and re-implement the same surface by hand to confirm an eject
      path exists without touching callers. Record: install size, `dist` bundle delta from
      `npm run build` (before/after), and any TS-strict or SSR-guard issues.
- [ ] Step 3 — **Icons.** `npm i lucide-vue-next`. Add `src/shared/components/Icon.vue`
      wrapping a lucide icon by name. Replace `PathStep`'s `step-status` text ("Completed",
      "Locked", "In progress", "Not started") with an icon + visually-hidden text for a11y.
      Verify: `npm run build` output shows only the imported icons in the bundle (inspect the
      chunk or use `rollup-plugin-visualizer` ad hoc) — not the full set.
- [ ] Step 4 — **Interactive island.** Add `src/spike/PulseEngine.ts` — a plain class with
      `start()` / `stop()`, a `requestAnimationFrame` loop, and internal non-reactive state
      that draws to a `<canvas>`. Wrap it in `SpikeIsland.vue` (~20 lines: a `ref`,
      `onMounted` → `new PulseEngine(canvas).start()`, `onBeforeUnmount` → `stop()`). Verify:
      the engine file imports nothing from `@/shared/components`, `reka-ui`, or `vue`; HMR
      edits to `PulseEngine.ts` don't leak RAF loops (check for runaway callbacks); unmount
      stops the loop.
- [ ] Step 5 — Run the full gate on the spike branch: `npm run test`, `npm run typecheck`,
      `npm run lint`, `npm run build`. Capture the bundle-size numbers and any warnings.
- [ ] Step 6 — **Findings note.** Write `motifpath-specs/spikes/PB-34-phase-1-findings.md`
      (new `spikes/` dir, or append to this plan if the team prefers): per decision point —
      *validated* / *validated with caveat* / *problem*, with evidence (bundle numbers,
      command output, code snippets). End with a one-line recommendation: accept ADR-018 as
      written, accept with listed amendments, or reject a specific decision point. Commit on a
      normal branch (`docs/PB-34/phase-1-spike-findings` → `main`), open a PR, link it on
      ADR-018 PR #35.
- [ ] Step 7 — Delete the `spike/PB-34/frontend-architecture` branch. Nothing from it merges.

### Phase 4 — Infrastructure (motifpath-infra)

Not applicable.

---

## Rollback Plan

Nothing to roll back — the spike branch is never merged and is deleted at Step 7. The only
lasting artifact is a Markdown findings note in `motifpath-specs`. If the spike is abandoned
mid-way, close the branch and note "inconclusive" on ADR-018 PR #35; the ADR stays *Proposed*.

## Validation

The spike succeeds when the findings note answers, with evidence, for each of the four
decision points:

- [ ] **Token pipeline:** `tokens.json` drives `tailwind.config.ts`, `vue-tsc --build` is
      clean, and opacity + arbitrary-value utilities resolve. Friction documented.
- [ ] **Reka UI:** one primitive works under Vite + TS-strict + Vitest; keyboard and focus
      behaviour verified by hand; an eject path is demonstrated; bundle delta recorded (a hard
      number, not "small").
- [ ] **Icons:** `lucide-vue-next` ships only imported icons; `PathStep` renders an icon with
      an accessible label instead of the status word.
- [ ] **Island:** the canvas engine has zero imports from the component library / Reka UI /
      Vue, and mounts + tears down cleanly behind its wrapper.
- [ ] A recommendation is written and ADR-018 PR #35 is updated (accept / amend / reject).

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Is `motifpath-web` on Tailwind v3 or v4? (config shape + token wiring differ) | Gilson | Check `package.json` at spike start |
| Reka UI vs Ark UI vs Headless UI Vue — is Reka the right headless lib, or does the spike also sample one alternative? | Gilson | ADR-018 names Reka; spike may note a second opinion but shouldn't expand to a full bake-off |
| `spikes/` directory in `motifpath-specs` — new convention, or fold findings into `plans/`? | Gilson | Decide at Step 6; PB-28 used only a Notion note + artifact |

---

## Related

- **ADR:** [ADR-018 — Frontend UI Architecture](../adrs/ADR-018-frontend-ui-architecture-design-system.md) (the "Validation" section defines this spike's pass criteria)
- **Spec files:** none — no contract change
- **Backlog item:** PB-34 (Frontend design system & UI architecture) — this is Phase 1;
  Phase 2 (visual restyle) is gated on `motifpath-brand/colors.json`
- **Prior art:** PB-28 (rendering-technology spike) — the findings-note + artifact format to
  follow; its SVG/Canvas + computation/renderer/state conclusion is a premise of ADR-018 point 4
- **Design:** `design/PB-8j-student-alpha-ux-foundation.md` (the component set Phase 2 realises)
