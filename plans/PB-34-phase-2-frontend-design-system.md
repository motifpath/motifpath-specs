# Plan: PB-34 Phase 2 — Frontend Design System (Real Tokens, Owned Component Library, Restyle)

**Task:** PB-34
**Date:** 2026-09-11
**Author:** Gilson Yamada (with Claude)
**Status:** Draft

---

## Goal

Land the ADR-018 design layer for real in `motifpath-web`, in both light and dark theme: consume
the now-resolved `motifpath-brand/tokens.json` through `tailwind.config.ts`, build the
six-component owned library plus `Icon` and one real Reka UI primitive, restyle
`PathStep`/`PathContent` — the first migration target ADR-018 names — off the placeholder
`motif-*` tokens, and define the SPA's basic composition structure so every phase below has an
agreed place to live.

## App Structure

The design layer needs an agreed shape to slot into. `motifpath-web` is a single-page app with
this composition hierarchy (mostly already true today; this section makes it explicit and is
the frame the rest of the plan builds against):

```
main.ts
 └─ App.vue                        mounts <RouterView/>, nothing else
     └─ router (src/router/)       selects a layout per route meta (public vs authenticated)
         ├─ PublicLayout.vue       unauthenticated routes: sign-in
         └─ AuthenticatedLayout.vue authenticated routes: home, path, node
             (Phase 3: both become thin wrappers around the shared `AppShell.vue`)
                 └─ AppShell.vue   header (wordmark, nav slot, ThemeToggle, SignOutLink) + <main>
                     └─ feature views (src/features/<domain>/views/)
                         └─ feature components (e.g. PathContent → PathStep)
                             └─ shared component library (src/shared/components/)
```

**State layers**, orthogonal to the view tree, reached via composables/stores rather than
props-drilling: Pinia stores (`currentUser`, and this plan's new `theme` store) and composables
(`useAuth`, `useStudentPath`, `useTheme`).

**Component ownership convention** (new, stated here so Phase 3's library additions have a
home):
- `src/design/` — tokens only (`tokens.json`); no Vue, no logic.
- `src/shared/components/` — the owned cross-feature library: `AppShell`, `StepRow`, `Icon`,
  `ProgressMeter`, `PrimaryButton`, `ThemeToggle`, the `State*` set. Never imports from
  `src/features/*`.
- `src/features/<domain>/components/` — domain composition of the shared library (e.g.
  `PathStep` composes `StepRow` + `Icon`). Never imported by another feature directly.

This is a naming/foldering convention, not a new build boundary — no lint rule enforces the
import direction in this plan; that's a follow-up if violations show up in review.

## Scope

**In scope:**
- Porting `motifpath-brand/tokens.json` (real colour/type/space/radius/elevation values) into
  `motifpath-web`, replacing the spike's placeholder `src/design/tokens.json`
- The three config deltas the PB-34 phase-1 spike proved are needed (`resolveJsonModule`, the
  `Icon` eslint ignore, the font-size tuple-narrowing helper)
- `Icon.vue` (role → `lucide-vue-next` glyph) promoted from the spike to a real shared component
- New owned components: `StepRow`, `AppShell`, `ProgressMeter`, `PrimaryButton`, `ThemeToggle`,
  `StateLoading`, `StateEmpty`, `StateError`, `StateLocked`
- Restyling `PathStep.vue` / `PathContent.vue` onto tokens + the new components
- Migrating `HomeView`, `PathView`, `AuthenticatedLayout`, `PublicLayout` onto `AppShell` /
  `PrimaryButton` / the `State*` set, retiring the `motif-*` placeholder aliases entirely
- One real Reka UI primitive: a confirm-before-sign-out `Dialog` wrapping `SignOutLink` — a
  genuine caller, not a throwaway (`SpikeDialog`/`SpikeDialogEjected` are not promoted; the
  spike branch stays throwaway and gets deleted per its own follow-up)
- **Dark-mode switching, from Phase 1 on.** Every semantic colour/elevation role in
  `motifpath-brand/tokens.json` ships as a `{ light, dark }` pair; the app consumes both from
  the start via Tailwind's `class`-strategy dark mode, so every component built or restyled in
  this plan is verified in both themes before its phase is called done, not retrofitted later.
  A small `theme` Pinia store + `useTheme` composable resolve the active theme (explicit
  user choice, persisted to `localStorage`; falling back to `prefers-color-scheme` when unset)
  and toggle a `dark` class on `<html>`. A minimal `ThemeToggle.vue` ships in Phase 1 so both
  modes are reachable immediately; Phase 3 relocates it into `AppShell` without changing its
  contract.

**Out of scope:**
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

### Phase 1 — Token pipeline, dark-mode wiring & config deltas

**Branch:** `feat/PB-34/phase-2-design-tokens`

- [ ] Copy `motifpath-brand/tokens.json` into `src/design/tokens.json` as-is (keep the
  `{ light, dark }` pairs — do not flatten); `brand`, `font`, `space`, `radius` are already
  theme-independent
- [ ] `src/assets/main.css`: for every `color`/`elevation` token role, emit a CSS custom
  property under `:root` with the `light` value (as an `R G B` channel triplet, e.g.
  `--color-ink: 26 22 51`, so Tailwind's opacity modifiers keep working) and redefine it under
  `:root.dark` with the `dark` value
- [ ] `tailwind.config.ts`: add `darkMode: 'class'`; map each Tailwind colour/`boxShadow` token
  to `rgb(var(--color-x) / <alpha-value>)` (colours) or `var(--elevation-x)` (shadows) instead
  of a static hex, so both themes resolve from the same utility classes; keep `fontSize` via the
  tuple-narrowing helper, `spacing`, `borderRadius` as direct token values (theme-independent);
  keep the `motif-*` aliases pointed at the new roles for now (removed in Phase 4)
- [ ] `tsconfig.node.json`: add `"resolveJsonModule": true`
- [ ] `eslint.config.js`: add `'vue/multi-word-component-names': ['error', { ignores: ['Icon'] }]`
- [ ] `src/stores/theme.ts` — Pinia store holding `'light' | 'dark'`, initialised from
  `localStorage` and falling back to `window.matchMedia('(prefers-color-scheme: dark)')` when
  unset; a `toggle()` action persists the choice and flips the `dark` class on
  `document.documentElement`. Write its test first (initial resolution from each source,
  `toggle()` persists and updates the DOM class).
- [ ] `ThemeToggle.vue` — a minimal button bound to the `theme` store, mounted temporarily in
  `AuthenticatedLayout.vue`/`PublicLayout.vue` headers (Phase 3 relocates it into `AppShell`
  with no behaviour change)
- [ ] Test: a Vitest assertion that `tailwind.config.ts`'s resolved `theme.extend.colors.accent`
  utility references the `--color-accent` custom property (catches drift if either file changes
  without the other)
- [ ] Gate: `vue-tsc --build`, `eslint --max-warnings 0`, `vitest run`, `vite build` all clean;
  manual check that toggling `ThemeToggle` swaps every existing screen's background/text/border
  colours with no unstyled flash

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
  identical; only classes/markup for the marker change); manual check via `ThemeToggle` that
  every status (locked/current/completed/not-started) is legible in both themes

### Phase 3 — Owned component library: `StepRow`, `AppShell`, `ProgressMeter`, `PrimaryButton`, `ThemeToggle` relocation

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
  public shell renders none; hosts `ThemeToggle` (moved in from the layouts, same component,
  same store binding — no new behaviour)
- [ ] Gate: `AuthenticatedLayout.spec.ts` (existing) still passes against the `AppShell`-based
  implementation; new component specs for each of the five (including `ThemeToggle`'s new
  location); manual check in both themes

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
- [ ] Gate: full `vitest run` (all existing + new specs), `vue-tsc --build`, `eslint`,
  `vite build`; manual pass over every migrated screen in both themes

### Phase 5 — First real Reka UI primitive: confirm-before-sign-out `Dialog`

**Branch:** `feat/PB-34/phase-2-reka-signout-dialog`

- [ ] Add `reka-ui` dependency
- [ ] Write `SignOutLink.spec.ts` cases first: dialog closed by default, opens on click, confirm
  triggers the existing sign-out call, cancel/`Esc` closes without signing out
- [ ] Implement: `SignOutLink.vue` opens a `DialogRoot`/`Trigger`/`Portal`/`Overlay`/`Content`
  styled only with token utilities; confirm action calls the existing sign-out logic unchanged
- [ ] Confirm route-level code splitting keeps this out of the entry bundle per the spike's
  bundle-delta finding (check `vite build` chunk report)
- [ ] Gate: full test suite, `vue-tsc --build`, `eslint`, `vite build`; manual check that the
  dialog overlay/content contrast holds in both themes

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
  current, and a completed step render correctly; sign-out shows the confirm dialog — repeated
  once in light and once in dark via `ThemeToggle`
- [ ] Toggling theme persists across a page reload (`localStorage`) and, when no explicit choice
  has been made, follows `prefers-color-scheme`

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Should theme preference sync server-side (per-user), or stay client-only for the alpha? | Gilson | Client-only (`localStorage`) for this plan — no backend field exists for it; revisit if cross-device continuity is requested |
| Should `RegisteringNotice`/`RegistrationFailedNotice`/`ErrorRetryNotice` be consolidated into the `State*` set? | Gilson | Deferred to a follow-up plan — out of scope here |
| Does PB-8e (lesson consumption) introduce a second real Reka primitive (e.g. `Tabs` for lesson media types)? | Gilson | Decide when PB-8e discovery starts; not blocking this plan |

## Related

- **ADR:** [ADR-018](../adrs/ADR-018-frontend-ui-architecture-design-system.md)
- **Spec/reference files:** `spikes/PB-34-phase-1-findings.md`,
  `design/PB-8j-student-alpha-ux-foundation.md` (State* copy table, semantic token roles),
  `motifpath-brand/tokens.json`
- **Backlog item:** PB-34
