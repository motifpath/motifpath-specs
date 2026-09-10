# Spike Findings: PB-34 Phase 1 — Frontend Architecture De-risking

**Task:** PB-34 (phase 1)
**Date:** 2026-09-10
**Author:** Gilson
**Plan:** `plans/PB-34-phase-1-frontend-architecture-spike.md`
**ADR under test:** [ADR-018](../adrs/ADR-018-frontend-ui-architecture-design-system.md) — *Proposed, pending this spike*
**Spike branch:** `motifpath-web@spike/PB-34/frontend-architecture` (throwaway — not for merge; delete after this note lands)

---

## Summary

All four ADR-018 decision points validated against `motifpath-web`'s real toolchain
(Vue 3.5 · Vite 6 · TypeScript strict · Tailwind **v3.4** · Vitest 3 · jsdom). Two required a
one-line config change, both documented below. No decision point failed.

**Recommendation: accept ADR-018 as written**, with two non-normative notes folded into PB-34
phase 2 (an `eslint` ignore entry for single-word primitives, and a `tsconfig.node.json`
`resolveJsonModule` flag). The gate ran clean on the spike branch: **159 tests**, `vue-tsc
--build`, `eslint --max-warnings 0`, `vite build` all green.

---

## Toolchain facts established

| Question (from the plan) | Answer |
|---|---|
| Tailwind v3 or v4? | **v3.4.17** — classic `tailwind.config.ts` with `theme.extend`; no `@theme` CSS layer. |
| Reka the right headless lib? | Reka UI **2.10.4** installs and works with no caveats; no second lib sampled (kept in scope). |
| `spikes/` dir in specs, or fold into `plans/`? | **New `spikes/` directory** — this file. Keeps throwaway validation artifacts separate from living plans. |

---

## Decision point 1 — Token pipeline → `tailwind.config.ts`

**Result: validated (with one config flag).**

- `src/design/tokens.json` holds colour roles (`surface`, `surface-raised`, `ink`, `muted`,
  `accent`, `accent-fg`, `success`, `danger`), a 6-step type scale as `[size, lineHeight]`
  tuples, an 8-step spacing scale, and a radius scale. `tailwind.config.ts` imports it and
  spreads it onto `theme.extend`.
- **Friction 1 — `resolveJsonModule`.** `tailwind.config.ts` is type-checked under
  `tsconfig.node.json`, which extends `@tsconfig/node22` and does **not** enable
  `resolveJsonModule`. `vue-tsc --build` fails on the JSON import until
  `"resolveJsonModule": true` is added there (one line). `tsconfig.app.json` already has it via
  `@vue/tsconfig`, so app code is unaffected.
- **Friction 2 — tuple typing.** `tokens.json`'s `font.size` entries type as `string[]`;
  Tailwind's `fontSize` wants `[string, string]`. Narrowed with a 3-line `Object.fromEntries`
  map in the config (`as [string, string]`) — no `any`, passes strict.
- **Verified working:** opacity modifiers (`text-motif-ink/40`, `bg-ink/40`) resolve; arbitrary
  values (`w-[20rem]`, `-translate-x-1/2`) resolve; the generated CSS grew **8.00 → 9.68 kB**
  (raw) / **2.29 → 2.64 kB** (gzip) for the added scales.
- Existing `motif-*` placeholder aliases were re-pointed at the token values so all PB-8c/8d
  markup keeps compiling; the phase-2 restyle migrates references off them.

**No amendment needed.** Add `resolveJsonModule` to `tsconfig.node.json` in phase 2.

## Decision point 2 — Reka UI primitive + eject path

**Result: validated.**

- `reka-ui@2.10.4` added. `SpikeDialog.vue` composes `DialogRoot/Trigger/Portal/Overlay/
  Content/Title/Description/Close`, styled **only** with token utilities (no raw hex/px).
- Works under Vite + TS-strict + the existing Vitest/`@vue/test-utils`/jsdom setup with **zero
  extra config**. Component test asserts: closed by default, opens on trigger click, Reka wires
  `role="dialog"` with no hand-written ARIA, closes on the close control.
- **Eject path demonstrated.** `SpikeDialogEjected.vue` re-implements the same surface by hand
  (open state + `Esc` + focus restoration + a minimal Tab focus-trap) in **~55 lines**,
  exposing an **identical `data-test` surface**. The same behavioural test suite runs against
  both components (parameterised) and passes — a caller swaps the import and changes nothing
  else.
- **Bundle delta — a hard number.** Reka's `Dialog` lands entirely in the **lazy route chunk**
  (`SpikeView`, code-split), **not** the entry bundle:
  - `SpikeView` chunk (Reka Dialog + the canvas island + wrappers): **33.46 kB raw / 11.04 kB
    gzip**. The island contributes ~1 kB, so **Reka `Dialog` ≈ 32 kB raw / ~10.5 kB gzip**.
  - Entry bundle (`index.js`): **146.39 → 148.32 kB raw** (+1.93 kB) / **52.82 → 53.64 kB
    gzip** — attributable to the new route record and shared runtime, not Reka itself.
  - **Conclusion:** with per-route code splitting (already the app's pattern), a Reka primitive
    costs first load nothing and its own route ~10 kB gzip. Acceptable.
- **TS-strict / SSR:** no issues. No SSR guard needed — the app is SPA-only.

**No amendment needed.**

## Decision point 3 — `lucide-vue-next` + `Icon` wrapper

**Result: validated (with one lint ignore).**

- `lucide-vue-next` added. `src/shared/components/Icon.vue` maps a MotifPath role
  (`completed | current | locked | todo`) to a lucide glyph and takes an optional `label`
  (accessible name + `role="img"`; decorative + `aria-hidden` otherwise).
- `PathStep.vue`'s status **word** ("Completed" / "In progress" / "Not started" / "Locked") is
  now an `<Icon>` plus an `sr-only` span carrying the same text — visible affordance is an
  icon, screen-reader output is unchanged. Existing `PathStep` tests (which assert
  `[data-test="step-status"]` text) pass untouched.
- **Tree-shaking confirmed — a hard number.** `lucide-vue-next`'s `dist/` is **38 MB**. After
  `vite build`, the string `lucide` appears **17 times, all confined to the `PathView`
  chunk** (which contains `PathStep`). That chunk grew **4.06 → 8.36 kB raw** / **1.86 → 2.88
  kB gzip** — that figure covers the **4 imported icons plus** the token-driven class churn in
  the same chunk. The full icon set does not ship.
- **Friction — lint.** `vue/multi-word-component-names` rejects `Icon.vue`. ADR-018 decision 3
  names the wrapper `Icon` deliberately. Resolved with
  `'vue/multi-word-component-names': ['error', { ignores: ['Icon'] }]` in `eslint.config.js`.

**No amendment needed.** The ignore entry belongs in phase 2's component-library setup.

## Decision point 4 — Interactive island isolation

**Result: validated.**

- `src/spike/PulseEngine.ts` — a plain class: `start()` / `stop()`, a `requestAnimationFrame`
  loop, non-reactive internal state, draws to a `<canvas>`. **Zero `import` statements**
  (asserted by test: `src.match(/^\s*import .+$/gm)` is empty).
- `SpikeIsland.vue` — **19-line** wrapper: a `ref`, `onMounted → new PulseEngine(canvas).
  start()`, `onBeforeUnmount → stop()`.
- **Verified by test:** `start()` schedules exactly one frame; a second `start()` does not
  stack a second loop; `stop()` calls `cancelAnimationFrame` and a captured frame callback
  invoked after `stop()` schedules nothing further (no runaway RAF on HMR/teardown).
- The engine imports nothing from `@/shared/components`, `reka-ui`, or `vue` — the restyle
  boundary ADR-018 depends on holds. Consistent with the PB-28 computation/renderer/state
  split.

**No amendment needed.**

---

## Gate on the spike branch

| Check | Result |
|---|---|
| `vitest run` | **159 passed** (28 files) — +10 spike tests over the `#9` baseline of 149 |
| `vue-tsc --build` | clean |
| `eslint . --max-warnings 0` | clean |
| `vite build` | clean; numbers above |

## Changes the spike proved are needed (for PB-34 phase 2, not this note)

1. `tsconfig.node.json` → `"resolveJsonModule": true`.
2. `eslint.config.js` → `vue/multi-word-component-names` ignores `['Icon']` (extend as the
   library grows).
3. Token-tuple narrowing helper in `tailwind.config.ts` (or emit tuples pre-typed from the
   `motifpath-brand` build).
4. Route-level code splitting must stay the norm so headless primitives never reach the entry
   bundle.

## Recommendation

**Accept ADR-018 as written.** All four decision points hold against the real toolchain; the
only surprises were two one-line config flags and a lint ignore, all folded into phase 2. Flip
ADR-018 Status to **Accepted** once this note merges; PB-34 phase 2 (visual restyle) stays
gated on `motifpath-brand/colors.json`.

## Follow-up

- [ ] Merge this note; flip ADR-018 to Accepted (PR #35).
- [ ] Delete `motifpath-web@spike/PB-34/frontend-architecture`.
- [ ] PB-34 phase 2 blocked on `motifpath-brand/colors.json` (open since 2026-08-25).
