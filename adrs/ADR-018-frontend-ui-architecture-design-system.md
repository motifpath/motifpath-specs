# ADR-018: Frontend UI Architecture — Headless Primitives, a Token Layer, and an Owned Component Library on Vue 3 + Tailwind

**Status:** Proposed
**Date:** 2026-09-10
**Deciders:** Gilson Yamada (solo engineering at MVP)

---

## Context

`motifpath-web` is a running Vue 3 SPA — Vite, TypeScript-strict, Pinia, Tailwind, Clerk auth
(ADR-007), with PB-8b/8c/8d shipped. Its styling is Tailwind utility classes hand-written per
component against placeholder `motif-*` color tokens. There is no type scale, no spacing rhythm,
no elevation system, and no icon set. Each vertical slice re-solves layout and state rendering
from scratch. PB-8j delivered the *information architecture* — screen inventory, navigation
model, page anatomy, standard-state components, semantic token roles — but not a *visual system*
or a component layer to realise it.

Four forces make a deliberate decision necessary now rather than after the alpha:

1. **The UI will not scale as-is.** Every screen still to build — PB-8e (lesson consumption),
   PB-8f (practice & assessment), PB-8h (admin observation view) — currently means another
   round of ad-hoc Tailwind, and inconsistency compounds with each one. Under the platform-first
   premise, student retention is a platform responsibility, and first-impression quality feeds
   it directly.

2. **Mobile is not handled.** The current app-shell navigation and the `PathStep` row place
   several elements on a single baseline line with fixed gaps; they wrap badly below ~380px
   viewport width. There is no mobile-first layout discipline anywhere in the component set.

3. **A hard architectural constraint from the product.** Several core modules — the fretboard
   diagram renderer, and the real-time practice runner (PB-8f) — depend on fine-grained
   DOM / SVG / Canvas control and 60 fps rendering. The PB-28 spike already concluded the
   rendering technology for these: SVG hand-built for teaching diagrams, Canvas for the
   real-time practice surface, with a content-computation / renderer / layer-state split. No
   component framework may sit between that code and the DOM, and no UI decision may hinder the
   evolution of those modules — even though the MVP versions are simpler, the finished product
   must carry a very consistent UI.

4. **Brand tokens are unresolved.** `motifpath-brand` exists, but `colors.json` has been `TBD`
   since 2026-08-25. The `motif-*` values in `tailwind.config.ts` are placeholders with no
   single source of truth.

Alternatives considered:

- **(a) Build a full bespoke design system now** — tokens, primitives, components, documentation
  site, visual-regression tests, token governance. Rejected: it is weeks of work, effectively
  needs a dedicated designer, and it is the wrong stage — the product hypotheses are unvalidated
  and polishing a design system ahead of them is misplaced effort.
- **(b) Adopt an opinionated Vue component framework** (PrimeVue, Vuetify, Quasar) **or a
  purchased admin / UI template.** Rejected: these are dashboard-shaped, and the student alpha
  is a focused consumer learning flow, not an admin panel; their opinionated DOM structure and
  CSS specificity fight the custom SVG / Canvas modules in force 3; restyling one to a finished
  brand is frequently a rewrite; and they impose runtime weight, bundle size, and an update
  cadence the team would carry as lock-in, on code it does not own.
- **(c) Switch the frontend framework** to Svelte or SolidJS for lower virtual-DOM overhead.
  Rejected: the interactive runners bypass the virtual DOM in any framework (Canvas +
  `requestAnimationFrame` + non-reactive state), so the runtime gain is marginal, while the cost
  is discarding a working SPA — auth, router guards, generated API client, ~150 tests, four
  merged PRs — at a stage where the stack is not the risk.
- **(d) Headless behavioural primitives plus a thin, owned design layer on the existing
  stack.** Chosen.

## Decision

MotifPath will build its frontend UI as **an owned, thin design layer on Vue 3 + Tailwind**, and
will **not** adopt an opinionated component framework. The layer has four parts:

1. **Design tokens are defined once in `motifpath-brand`.** Color roles, a type scale, a spacing
   scale, radius, and elevation are published there as a machine-readable file (extending
   `colors.json` or a sibling `tokens.json`) and consumed by `motifpath-web`'s
   `tailwind.config.ts`. Components reference token names only — never raw hex, px, or ad-hoc
   values. This is the single lever for a consistent UI and it replaces the placeholder
   `motif-*` hexes.

2. **Behavioural primitives come from Reka UI** (headless: focus management, ARIA wiring,
   keyboard interaction; no visual opinion). Used only where a primitive genuinely earns it —
   dialog, popover, tabs, disclosure, tooltip, progress. Any Reka component may be ejected to a
   hand-rolled equivalent without disturbing the rest of the app. No other component dependency
   is taken.

3. **A small, hand-owned MotifPath component library** lives in `motifpath-web`: `AppShell`,
   `StepRow`, the PB-8j standard-state set (`StateLoading` / `StateEmpty` / `StateError` /
   `StateLocked`), `ProgressMeter`, `PrimaryButton`, and an `Icon` wrapper over
   **`lucide-vue-next`**. Every screen composes these components; a screen does not hand-write
   layout scaffolding or state primitives.

4. **Interactive modules are framework-agnostic islands.** The fretboard diagram renderer and
   the practice runner are plain TypeScript engines — SVG for diagrams, Canvas for the
   real-time practice surface (per PB-28) — each split into content-computation / renderer /
   layer-state, mounted behind a ~20-line Vue wrapper. They read design tokens for color but
   depend on neither the component library, nor Reka UI, nor Vue reactivity in their hot path.
   A restyle of the surrounding app cannot break them.

The **token contents**, the exact **component API surface**, and the **migration order** are the
subject of a design-system spike (PB-34), gated on the brand-token decision landing. PB-8d's
`PathStep` / `PathContent` are the first restyle target; `motifpath-web#9` merges as-is and is
restyled with everything else.

## Rationale

- **Headless over a component framework** because the one capability MotifPath cannot
  compromise — direct, fast DOM / SVG / Canvas control in the teaching modules — is exactly
  what opinionated frameworks remove. Reka UI supplies the genuinely hard, easy-to-get-wrong
  part (accessibility and interaction behaviour) while leaving all rendering to us, and it is
  ejectable, so it is not lock-in.
- **Keep Vue 3 + Tailwind** because the interactive runners bypass the virtual DOM regardless of
  framework, so a switch buys little, while the running SPA is real accrued value at a stage
  where the product hypotheses — not the stack — are what is unproven.
- **Tokens in `motifpath-brand`, not `motifpath-web`,** because "consistent UI" is a
  cross-artifact property — the web app, a future marketing site, the SVG diagrams, and any
  later native shell all draw from one palette and scale — and because putting them there
  forces the long-pending brand decision instead of letting placeholders ossify.
- **An owned component library over a bought one** because at roughly six components the
  authoring cost is a few days, the team understands every line, there is no third-party update
  treadmill and no CSS-specificity war — and PB-8j has already inventoried the set.
- **The island rule is stated explicitly** because it is the load-bearing guarantee for the
  product constraint: it is the boundary that lets the shell evolve freely while the sharp-UX
  modules stay untouched, and it is the same computation / renderer / state split PB-28 already
  recommended.

## Consequences

### Positive
- Every screen built after the spike composes a known set of components; consistency is the
  default rather than a review checkpoint.
- The teaching modules are insulated by contract from any UI or restyle change.
- Accessibility — focus order, ARIA, keyboard — is handled by Reka UI instead of being
  re-implemented, and re-forgotten, per component.
- No runtime lock-in: Reka UI is ejectable, the component library is owned, Tailwind stays.
- The brand-token decision finally gets made and has exactly one home.
- Mobile-first behaviour becomes a property of `AppShell` / `StepRow` / the token scale — fixed
  once, not per screen.

### Negative / Trade-offs
- A dedicated spike (PB-34) lands before more PB-8 slices, plus a restyle pass over PB-8c and
  PB-8d — real calendar cost against the alpha timeline.
- The team owns ~6 components and an icon wrapper indefinitely; their bugs, accessibility edge
  cases, and maintenance are MotifPath's, not a vendor's.
- Reka UI is a dependency with its own release cadence and a smaller ecosystem than
  PrimeVue / Vuetify; a primitive it does not cover must be hand-built.
- Two rendering worlds coexist — Tailwind/Vue components and the vanilla-TS islands — with a
  documented seam between them that every contributor must respect.
- Deferring the full design system means no component-documentation site, no visual-regression
  tests, and no formal token governance yet; each is re-raised when the product justifies it.
- The work is blocked on the `motifpath-brand` token decision, open since 2026-08-25.

### Neutral
- The `motif-success` / `motif-danger` tokens added during PB-8d become the first entries in the
  formal token set rather than standalone placeholders.
- `shadcn-vue` (copy-in components built on Reka UI + Tailwind) is compatible with this decision
  and may be used as a *reference* when authoring the owned components, but is not adopted as a
  dependency or a workflow.
- `lucide-vue-next` lets text labels such as "Completed" be replaced by icons; the `Icon`
  wrapper keeps the icon set swappable.

## Related ADRs

- **ADR-007** (Clerk authentication and JWT local validation) — the SPA this layer sits on;
  unaffected by it.
- **ADR-004** (Deployment pipeline) — restyled screens ship through the same pipeline; the brand
  token file becomes a build input to `motifpath-web`.
- **ADR-015 / ADR-017** (Student path model) — PB-8d's `PathStep` / `PathContent`, restyled
  under this decision, are the first migration target.
- **PB-28** (rendering-technology spike — a research task, not an ADR) — its SVG-for-diagrams /
  Canvas-for-real-time conclusion and its computation / renderer / layer-state split are a
  premise of decision point 4.

---

*This ADR is Proposed as of 2026-09-10. A reviewer sets it to Accepted. To revise once accepted,
create a new ADR with Status: Supersedes ADR-018.*
