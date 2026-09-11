# Plan: PB-34 Phase 2 — Frontend Design System (Real Tokens, Owned Component Library, Restyle)

**Task:** PB-34
**Date:** 2026-09-11
**Author:** Gilson Yamada (with Claude)
**Status:** Draft

---

## Goal

Land the ADR-018 design layer for real in `motifpath-web`: consume the now-resolved
`motifpath-brand/tokens.json` through `tailwind.config.ts`, build the six-component owned
library plus `Icon` and one real Reka UI primitive, and restyle `PathStep`/`PathContent` —
the first migration target ADR-018 names — off the placeholder `motif-*` tokens.

## Scope

**In scope:**
- Porting `motifpath-brand/tokens.json` (real colour/type/space/radius/elevation values) into
  `motifpath-web`, replacing the spike's placeholder `src/design/tokens.json`
- The three config deltas the PB-34 phase-1 spike proved are needed (`resolveJsonModule`, the
  `Icon` eslint ignore, the font-size tuple-narrowing helper)
- `Icon.vue` (role → `lucide-vue-next` glyph) promoted from the spike to a real shared component
- New owned components: `StepRow`, `AppShell`, `ProgressMeter`, `PrimaryButton`,
  `StateLoading`, `StateEmpty`, `StateError`, `StateLocked`
- Restyling `PathStep.vue` / `PathContent.vue` onto tokens + the new components
- Migrating `HomeView`, `PathView`, `AuthenticatedLayout`, `PublicLayout` onto `AppShell` /
  `PrimaryButton` / the `State*` set, retiring the `motif-*` placeholder aliases entirely
- One real Reka UI primitive: a confirm-before-sign-out `Dialog` wrapping `SignOutLink` — a
  genuine caller, not a throwaway (`SpikeDialog`/`SpikeDialogEjected` are not promoted; the
  spike branch stays throwaway and gets deleted per its own follow-up)

**Out of scope:**
- **Dark-mode switching.** `tokens.json`'s colour and elevation roles carry `{ light, dark }`
  pairs, but nothing in the product today requires a dark theme or an OS-preference toggle.
  This plan consumes the **light value only** for every role, flattened to a single hex per
  token. The `dark` values stay in `tokens.json` unused — cheap to wire up later (see Open
  Questions), expensive to invent a CSS-custom-property theming layer for now with no caller.
- The canvas-island pattern (ADR-018 decision 4) — already validated by the spike
  (`PulseEngine.ts` / `SpikeIsland.vue`); no real interactive module needs it until PB-8f.
- Consolidating `RegisteringNotice` / `RegistrationFailedNotice` / `ErrorRetryNotice` into the
  new `State*` set. They overlap in purpose but migrating their call sites is a larger
  behavioural change than this plan's restyle scope; flagged as a follow-up.
- Any change to `motifpath-core` or `motifpath-specs` beyond this plan file — ADR-018 is
  already Accepted; no spec change is needed to build the layer it describes.
- Deleting `motifpath-web@spike/PB-34/frontend-architecture` — tracked in the spike findings'
  own follow-up list, not this plan.

## Prerequisites

- [x] ADR-018 Accepted (`motifpath-specs` `adrs/ADR-018-frontend-ui-architecture-design-system.md`)
- [x] `motifpath-brand/tokens.json` merged (`motifpath-brand#1`, commit `77c1202`)
- [x] PB-34 phase-1 spike findings merged (`spikes/PB-34-phase-1-findings.md`)
- [x] `motifpath-web#9` (PB-8d progress & unlock) merged to `dev` — restyle target exists

---

## Implementation Steps

All phases are in `motifpath-web`, branched from `dev`. No `motifpath-specs` or
`motifpath-core` changes are needed. TDD applies throughout: for every new component or util,
write the failing `@vue/test-utils` / Vitest test first, then implement.

### Phase 1 — Token pipeline & config deltas

**Branch:** `feat/PB-34/phase-2-design-tokens`

- [ ] Replace `src/design/tokens.json` with the real values from
  `motifpath-brand/tokens.json`, flattened to light-only: each `color`/`elevation` role's
  `$value.light` becomes the token's value (drop the `light`/`dark` wrapper); `brand`, `font`,
  `space`, `radius` copy across as-is (already theme-independent)
- [ ] `tsconfig.node.json`: add `"resolveJsonModule": true`
- [ ] `tailwind.config.ts`: spread the flattened tokens onto `theme.extend` (`colors`, `fontSize`
  via the tuple-narrowing helper the spike wrote, `spacing`, `borderRadius`, `boxShadow` for
  elevation); keep the `motif-*` aliases pointed at the new values for now (removed in Phase 4)
- [ ] `eslint.config.js`: add `'vue/multi-word-component-names': ['error', { ignores: ['Icon'] }]`
- [ ] Test: a Vitest assertion that `tailwind.config.ts`'s resolved `theme.extend.colors.accent`
  equals the token file's value (catches drift if either file changes without the other)
- [ ] Gate: `vue-tsc --build`, `eslint --max-warnings 0`, `vitest run`, `vite build` all clean

### Phase 2 — `Icon` + `PathStep`/`PathContent` restyle

**Branch:** `feat/PB-34/phase-2-icon-path-restyle`

- [ ] Write `Icon.vue` test first (role → glyph mapping; `label` prop → accessible name +
  `role="img"`; no `label` → decorative + `aria-hidden`), then port `Icon.vue` from the spike
  into `src/shared/components/`
- [ ] `PathStep.vue`: replace the emoji/glyph markers and `motif-*` classes with `<Icon>` +
  token classes (`bg-surface`, `text-ink`, `text-ink-subtle` for locked, `text-success` for
  completed); status word becomes `<Icon>` + `sr-only` text exactly as the spike proved —
  existing `[data-test="step-status"]` text assertions keep passing unchanged
- [ ] `PathContent.vue`: token classes for the heading/section/progress-line markup
- [ ] Gate: existing `PathStep.spec.ts` / `PathContent.spec.ts` pass unmodified (behaviour is
  identical; only classes/markup for the marker change)

### Phase 3 — Owned component library: `StepRow`, `AppShell`, `ProgressMeter`, `PrimaryButton`

**Branch:** `feat/PB-34/phase-2-component-library`

- [ ] `StepRow.vue` — generic row primitive (position slot, marker slot, title, trailing-status
  slot, trailing-action slot); write its test first, then extract `PathStep.vue` to compose it
  instead of hand-rolling the `<li>` layout. `StepRow` takes no student-path-specific props —
  it is reusable by PB-8f/PB-8h later.
- [ ] `PrimaryButton.vue` — wraps the `rounded bg-accent px-4 py-2 text-sm text-accent-fg`
  pattern duplicated today in `HomeView` and `ErrorRetryNotice`; accepts `as="RouterLink"` or
  renders a native `<button>` with a `type` prop
- [ ] `ProgressMeter.vue` — renders `pathProgress()`'s `{ completed, total }` as a labelled bar
  (`role="progressbar"`, `aria-valuenow`/`aria-valuemax`); `PathContent.vue` replaces its plain
  progress line with it
- [ ] `AppShell.vue` — extracts the shared header/nav/main scaffold out of
  `AuthenticatedLayout.vue` and `PublicLayout.vue`; nav links passed as a prop/slot so the
  public shell renders none
- [ ] Gate: `AuthenticatedLayout.spec.ts` (existing) still passes against the `AppShell`-based
  implementation; new component specs for each of the four

### Phase 4 — `State*` set + view migration + retire `motif-*`

**Branch:** `feat/PB-34/phase-2-state-components-migration`

- [ ] `StateLoading.vue`, `StateEmpty.vue`, `StateError.vue`, `StateLocked.vue` per the PB-8j
  table (`design/PB-8j-student-alpha-ux-foundation.md` lines 251–260) — same `data-test` hooks
  (`loading`, `no-path`, `error`, `retry`, `locked`) so existing view-level assertions hold
- [ ] `StateEmpty`'s holding-state copy is fixed to the PB-8j-specified text ("You're all set" /
  "We're building your personalized path...") — this also fixes `PathView.vue`'s current
  "Your teacher is building..." copy, which predates the impersonal-copy decision in ADR-015
- [ ] Migrate `HomeView.vue` and `PathView.vue` onto `StateLoading`/`StateEmpty`/`StateError` and
  `PrimaryButton`; migrate `AuthenticatedLayout.vue`/`PublicLayout.vue` call sites onto
  `AppShell`
- [ ] Remove the `motif-*` alias block from `tailwind.config.ts`; grep the codebase for any
  remaining `motif-` class reference and replace it — CI should fail the build if none remain
  but the grep is a manual gate step here, not an automated check
- [ ] Gate: full `vitest run` (all existing + new specs), `vue-tsc --build`, `eslint`, `vite build`

### Phase 5 — First real Reka UI primitive: confirm-before-sign-out `Dialog`

**Branch:** `feat/PB-34/phase-2-reka-signout-dialog`

- [ ] Add `reka-ui` dependency
- [ ] Write `SignOutLink.spec.ts` cases first: dialog closed by default, opens on click, confirm
  triggers the existing sign-out call, cancel/`Esc` closes without signing out
- [ ] Implement: `SignOutLink.vue` opens a `DialogRoot`/`Trigger`/`Portal`/`Overlay`/`Content`
  styled only with token utilities; confirm action calls the existing sign-out logic unchanged
- [ ] Confirm route-level code splitting keeps this out of the entry bundle per the spike's
  bundle-delta finding (check `vite build` chunk report)
- [ ] Gate: full test suite, `vue-tsc --build`, `eslint`, `vite build`

---

## Rollback Plan

Each phase is an independent PR to `dev`; a bad phase is reverted with `git revert` on its merge
commit without affecting the others, since later phases depend only on earlier phases' *outputs*
(tokens, then components), not on unmerged internals. No database, infra, or API surface is
touched, so no deploy coordination or data migration is involved. If Phase 5's Reka `Dialog`
regresses sign-out, `SignOutLink.vue` reverts to its current plain-link form independently of
Phases 1–4.

## Validation

- [ ] `vitest run`, `vue-tsc --build`, `eslint --max-warnings 0`, `vite build` all clean after
  every phase merges
- [ ] No `motif-*` class or `tailwindcss` color reference remains outside `tailwind.config.ts`
  after Phase 4 (manual grep)
- [ ] `PathStep`/`PathContent` render identically in behaviour (all existing `data-test`
  assertions pass) with entirely token-driven markup
- [ ] `lucide-vue-next` icons appear only in the chunks that import them (repeat the spike's
  bundle-report check) — confirms tree-shaking survives the real component library, not just
  the spike
- [ ] Reka `Dialog` chunk lands in `SignOutLink`'s route/component chunk, not `index.js`
- [ ] Manual smoke via `devbox services up ... web`: sign-in → home → path → a locked, a
  current, and a completed step render correctly; sign-out shows the confirm dialog

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| When (if ever) does the student alpha need dark-mode switching, given tokens already carry dark values? | Gilson | Deferred — revisit if a concrete request appears; no CSS-var theming layer built speculatively |
| Should `RegisteringNotice`/`RegistrationFailedNotice`/`ErrorRetryNotice` be consolidated into the `State*` set? | Gilson | Deferred to a follow-up plan — out of scope here |
| Does PB-8e (lesson consumption) introduce a second real Reka primitive (e.g. `Tabs` for lesson media types)? | Gilson | Decide when PB-8e discovery starts; not blocking this plan |

## Related

- **ADR:** [ADR-018](../adrs/ADR-018-frontend-ui-architecture-design-system.md)
- **Spec/reference files:** `spikes/PB-34-phase-1-findings.md`,
  `design/PB-8j-student-alpha-ux-foundation.md` (State* copy table, semantic token roles),
  `motifpath-brand/tokens.json`
- **Backlog item:** PB-34
