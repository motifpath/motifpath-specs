# ADR-020: Tiptap as MotifPath's content-authoring text editor

**Status:** Accepted
**Date:** 2026-09-13
**Deciders:** Gilson (Product Owner)

---

## Context

PB-8i (Content & classification concierge tooling) needs a way for the concierge/content team
to author lesson content — headings, rich text, callouts, inline video/audio/image, and
reorderable sections — without hand-writing JSON or relying on the team building a bespoke
editor from scratch. No editor existed yet, and no ADR had addressed content authoring; PB-42/
ADR-019 covers the practice/exercise content model, not lesson prose.

PB-44 was opened as a research task to select a structured-block editor. A research pass
compared five candidates against MotifPath's constraints — Vue 3.5 + TypeScript strict +
Tailwind 3.4 (the stack ADR-018 committed to), a permissive license (self-hosted product,
avoid GPL/AGPL or cloud-required libraries), bundle-size discipline (route-level code
splitting is already the app's norm), and a JSON-block persistence model rather than raw
HTML:

- **BlockNote** has the closest data model to "Notion-like blocks" but is React/Mantine-first;
  the only Vue path bridges a React runtime into the app via `veaury`, directly contradicting
  ADR-018's Vue-only, headless-primitives direction. Its advanced (XL) packages are also
  GPL-3.0/commercial dual-licensed.
- **Plate** (Slate-based) has no viable Vue path at all — its plugin system does not port to
  Vue Slate forks.
- **Lexical** has a community Vue wrapper (`lexical-vue`), but it is unofficial and
  small-community (bus-factor risk), and ships no ready block/drag-reorder UI.
- **Editor.js** is genuinely framework-agnostic with the most direct JSON-block-array output,
  but has a slower-paced plugin ecosystem and historically thinner drag-reorder support.
- **Tiptap** has native, first-party Vue 3 support (`@tiptap/vue-3`, maintained by the same
  team as the core), went MIT-licensed across its formerly-Pro extensions (including
  drag-handle) in 2026, and outputs ProseMirror JSON — a structured document/node schema, not
  HTML.

Research alone ruled out BlockNote, Plate, and Lexical; it could not answer how much assembly
effort Tiptap or Editor.js would take to reach the actual "Notion-grade" block UX PB-8i needs
(a callout node, embedded media as first-class nodes, drag-and-drop reordering), so a
throwaway spike (`motifpath-web@spike/PB-44/text-editor`, findings in
`spikes/PB-44-text-editor-findings.md`) built a Tiptap prototype to answer that question with
evidence rather than more research.

The spike validated rich text + a custom `callout` node, `audio`/`video`/`image` media nodes,
drag-handle block reordering, and — after a first round of manual testing surfaced gaps not
covered by the initial four decision points — a hand-built toolbar, paste-to-insert for
clipboard images, and tables (`@tiptap/extension-table`). Every gap was closed with a small,
focused addition (roughly 50, 30, and 12 lines respectively), and none revealed a Tiptap
dealbreaker. The one substantial, quantified cost is bundle size: the editor's lazy route
chunk is 583 kB raw / 185 kB gzip, of which ~283 kB raw / ~87 kB gzip is an irreducible
ProseMirror-core floor present even with zero formatting extensions — not something
Tiptap-specific trimming can remove, and a cost any ProseMirror-based editor pays. Isolation
holds: this cost lands entirely in the editor's own route, not the entry bundle
(+0.05 kB gzip on entry, attributable to the new route record, matching PB-34's established
measurement pattern).

## Decision

MotifPath will use **Tiptap** (`@tiptap/vue-3` + `@tiptap/pm`) as the content-authoring text
editor for PB-8i's concierge tooling, with the following implementation commitments carried
over from the spike:

1. **Hand-pick extensions** instead of installing `@tiptap/starter-kit` wholesale — only the
   nodes/marks lesson content actually needs (this trims the ~83 kB gzip of the ~185 kB gzip
   total that the spike's full StarterKit pulled in but PB-8i may not use).
2. **Persist authored content as ProseMirror JSON** (`editor.getJSON()` /
   `editor.commands.setContent()`), never as serialized HTML, so the model stays structured
   for later rendering.
3. **Custom nodes** for `callout` and for `audio`/`video` media embeds, following the spike's
   `Node.create()` pattern (`src/spike/calloutNode.ts`, `src/spike/mediaNodes.ts` as
   reference implementations, not final code).
4. **Drag-handle block reordering** via `@tiptap/extension-drag-handle-vue-3` (MIT-licensed).
5. **A hand-built toolbar** (and likely a bubble menu) — Tiptap ships no UI, so this is real
   UI design/build work, not extension configuration.
6. **Paste-to-insert for clipboard images**, via a custom `handlePaste` ProseMirror plugin,
   **uploading the file to storage and inserting the resulting URL** — never inlining a
   base64 data URL as the throwaway spike did for expedience. The same plugin should add a
   `handleDrop` prop for drag-and-drop of image files.
7. **Tables** via `@tiptap/extension-table` (which bundles `Table`, `TableRow`, `TableHeader`,
   `TableCell` as named exports from one package — do not additionally install the
   separately-published single-node packages).
8. **Hand-written CSS** for callout, table, and media node presentation — none of these
   extensions ship visual style.

This editor is scoped to **internal, non-student-facing content-authoring tooling** (PB-8i).
It is not currently intended for any student-facing surface.

## Rationale

Tiptap was chosen over the alternatives because:

- It is the only candidate with **first-party, actively-maintained Vue 3 support** — no
  bridging layer, no unofficial community wrapper, consistent with ADR-018's "no full
  component framework, headless primitives, ejectable" direction (the same shape as the
  existing Reka UI integration).
- Its 2026 licensing change made the extensions this decision needs (including drag-handle)
  **MIT**, removing the commercial-tier dependency that made BlockNote's advanced features a
  licensing risk for a self-hosted product.
- It outputs **ProseMirror JSON natively** — no HTML round-trip or intermediate schema
  translation needed to satisfy the "persist as structured JSON" requirement.
- The spike is **evidence**, not projection: every required capability (rich text, custom
  nodes, media, reordering, toolbar, paste, tables) was built and verified working against
  the real toolchain, with a passing test for each. Editor.js remained a viable fallback on
  paper, but nothing in the Tiptap spike failed or came close to failing, so there was no
  reason to spend a second spike proving out the fallback.

**Rejected alternative — Editor.js.** Genuinely framework-agnostic and would have avoided the
ProseMirror-core bundle floor entirely (its vanilla, non-ProseMirror architecture is
meaningfully lighter). It remains the better choice if this editor is ever needed on a
**student-facing** route, where the ~87 kB gzip floor would compete directly with the app's
existing bundle-size discipline (PB-34's Reka `Dialog` baseline was ~10.5 kB gzip by
comparison). It was not spiked because PB-8i's authoring tool is internal-only, and the
`185 kB gzip` lazy-chunk cost is a materially different trade-off for a small concierge team
than for every student's learning-path route.

**Rejected alternatives — BlockNote, Plate, Lexical.** Ruled out at the research stage without
a code spike: BlockNote requires bridging a React runtime into a Vue-only app (a direct
contradiction of ADR-018) and carries GPL/commercial risk on advanced features; Plate has no
viable Vue path; Lexical's Vue binding is an unofficial, small-community wrapper with no
ready block/drag UI.

## Consequences

### Positive

- Concierge/content authors get a real block-editing tool (rich text, callouts, media,
  reordering, tables) instead of hand-writing content JSON.
- Native Vue 3 integration required zero workarounds and passed `vue-tsc --build --strict`
  and `eslint --max-warnings 0` cleanly in the spike, with no `any` and no type-silencing
  casts.
- MIT licensing across every extension used removes any future licensing risk for this
  self-hosted product.
- The editor is fully isolated to its own lazy route chunk — it costs the app's entry bundle
  nothing, consistent with the project's existing code-splitting discipline.

### Negative / Trade-offs

- The editor's own route costs **~185 kB gzip**, of which **~87 kB gzip is an irreducible
  ProseMirror-core floor** no amount of Tiptap configuration can remove. Acceptable for an
  internal tool used by a small concierge team; would need re-litigating (likely in favor of
  Editor.js) if ever proposed for a student-facing route.
- Tiptap is headless: the toolbar, bubble menu, paste-upload handler, and all visual styling
  for custom/table nodes are **real UI and integration work the team must build**, not
  configuration. Budget accordingly — the spike's toolbar/paste/table additions were small
  (~50/~30/~12 lines) individually, but a production-grade authoring UI is more than that.
- A `trailingNode`-related asymmetry exists between a freshly-mounted document's first
  `getJSON()` call and every subsequent `setContent()`/`getJSON()` cycle (an extra trailing
  empty paragraph appears from the second cycle on). Not data loss, but implementers must
  persist/compare via the `setContent()`/`getJSON()` round-trip pattern, not the raw content
  string, to avoid false "drift" reports.

### Neutral

- `@tiptap/extension-table` bundles `Table`/`TableRow`/`TableHeader`/`TableCell` in one
  package; the separately-published single-node table packages exist but should not be
  installed alongside it (redundant, confirmed during the spike).

## Related ADRs

- **ADR-018** (Frontend UI architecture) — this decision follows its headless-primitives,
  ejectable, no-full-component-framework direction; Tiptap composes the same way
  `reka-ui` already does.
- **ADR-019** (Practice content model) — a sibling content-model decision for exercises, not
  lesson prose; this ADR does not change or depend on ADR-019's Exercise/Challenge model.

---

*This ADR was decided on 2026-09-13. To revise, create a new ADR with Status: Supersedes
ADR-020.*
