# Spike Findings: PB-44 — Content-Authoring Text Editor

**Task:** PB-44
**Date:** 2026-09-13
**Author:** Gilson
**Plan:** `plans/PB-44-text-editor-spike.md`
**Spike branch:** `motifpath-web@spike/PB-44/text-editor` (throwaway — not for merge; delete after this note lands)

---

## Summary

Built a throwaway Tiptap (`@tiptap/vue-3`) prototype against `motifpath-web`'s real toolchain
(Vue 3.5 · Vite 6 · TypeScript strict · Tailwind 3.4 · Vitest 3): rich text, a custom
`callout` node, `audio`/`video`/`image` media nodes, and drag-handle block reordering. All
four prototype steps validated; the gate ran clean (**217 tests**, `vue-tsc --build`,
`eslint --max-warnings 0`, `vite build`). The one substantial finding is bundle cost: the
editor's route chunk is **534 kB raw / 170 kB gzip**, of which **~283 kB raw / ~87 kB gzip is
an irreducible ProseMirror-core floor** (present even with zero formatting extensions), not
something Tiptap-specific trimming can remove.

**Recommendation: accept Tiptap**, gated on confirming the 170 kB gzip lazy-chunk cost is
acceptable for an internal concierge tool (not a student-facing chunk) — see Decision point 5.

---

## Decision point 1 — Rich text + structure (round-trip via JSON)

**Result: validated (with one caveat).**

- Headings, bold/italic, lists, links (via `@tiptap/starter-kit`) and a custom `Callout` node
  (`src/spike/calloutNode.ts`, a `Node.create()` with a `variant: 'info' | 'warning'`
  attribute and a `setCallout()` command) all serialize as distinct ProseMirror JSON node
  types via `editor.getJSON()`.
- **Caveat — trailing-node asymmetry.** StarterKit's `trailingNode` extension appends an
  empty paragraph after trailing block/atom content so there's always a cursor position. The
  *very first* `getJSON()` call right after mount-time `content` initialization does **not**
  yet include that trailing paragraph — the appendTransaction plugin hasn't run against the
  initial content string yet — but every subsequent `setContent()`/`getJSON()` cycle does.
  Round-tripping is lossless from the **second** cycle onward (a stable fixed point), which
  matches the real save/reload flow: a reload always goes through `setContent(savedJson)`,
  never the raw HTML content string. Test: `SpikeEditor.spec.ts` — *"round-trips a document
  through setContent/getJSON with a stable fixed point."*
- **No amendment needed** — document this asymmetry for whoever implements the real
  authoring/persistence layer (PB-8i) so they don't compare a freshly-mounted document's JSON
  against a reloaded one and read the fixed paragraph as a bug.

## Decision point 2 — Media embeds (image/audio/video as distinct node types)

**Result: validated.**

- `@tiptap/extension-image` used as-is for images. `Audio` and `Video` are two ~20-line
  custom atomic nodes (`src/spike/mediaNodes.ts`) sharing one factory function, each with a
  `src` attribute, rendering to a real `<audio>`/`<video controls>` element.
- Verified: a document containing an `audio` node followed by a `video` node serializes as
  `['audio', 'video', 'paragraph']` — the trailing paragraph is the same StarterKit behavior
  from decision point 1, not new to media nodes.

**No amendment needed.**

## Decision point 3 — Drag-handle block reordering

**Result: validated.**

- `@tiptap/extension-drag-handle-vue-3` (now MIT-licensed, part of Tiptap's 2026
  de-Pro-ification) wraps the editor with zero extra config beyond passing it the `editor`
  instance. Verified by hand in the dev server (`/spike/text-editor`, unlinked from nav): drag
  handle appears next to paragraphs, the callout block, and media nodes; dragging reorders
  blocks; drop targets highlight correctly.
- **No hand-rolled drag layer needed** — resolves the plan's open question about whether the
  extension alone covers the reorder UX. It does.

**No amendment needed.**

## Decision point 4 — License & Vue-fit confirmed in practice

**Result: validated.**

- `npm ls` + per-package `license` field confirm **MIT** for `@tiptap/vue-3`,
  `@tiptap/starter-kit`, and `@tiptap/extension-drag-handle-vue-3` (and their `@tiptap/pm`,
  `@tiptap/core` dependencies) — matches the research pass, now checked against the actually
  installed tree rather than docs/changelog claims.
- `npm audit` reported 5 vulnerabilities (3 moderate, 2 high) — all in **pre-existing
  dev-tool transitive dependencies** (`@vitest/mocker` via `vitest`, `js-yaml` via
  `@redocly/openapi-core`), unrelated to Tiptap. Confirmed by installing only the Tiptap
  packages and diffing `npm ls` — none of the flagged packages are Tiptap dependents.
- Native `@tiptap/vue-3` integration required zero Vue-specific workarounds: `useEditor()` +
  `<EditorContent>` composed directly in a `<script setup lang="ts">` component, passed
  `vue-tsc --build` and `eslint --max-warnings 0` with no `any` and no type-silencing casts.

**No amendment needed.**

## Decision point 5 — Bundle cost (the one real finding)

**Result: validated, with a genuine caveat worth flagging before acceptance.**

Measured via `vite build`, comparing the spike branch against the same build on `dev`
(baseline stashed/restored, not merged):

| Chunk | Baseline (`dev`) | With full Tiptap spike | Delta |
|---|---|---|---|
| Entry (`index.js`) | 146.96 kB raw / 53.05 kB gzip | 147.40 kB raw / 53.18 kB gzip | **+0.44 kB raw / +0.13 kB gzip** — the new route record only, per PB-34's established pattern |
| `SpikeEditor` chunk (lazy, own route) | — | **533.66 kB raw / 169.93 kB gzip** | new lazy chunk, isolated |

**Isolation holds** — same conclusion as PB-34: with route-level code splitting (already the
app's norm), the editor costs the entry bundle nothing. It only costs its own route ~170 kB
gzip.

**But that per-route number is an order of magnitude above PB-34's Reka `Dialog` baseline**
(~32 kB raw / ~10.5 kB gzip). To find out why, a second throwaway build swapped the full
StarterKit + drag-handle + image extensions for the three unavoidable ProseMirror primitives
(`Document`, `Paragraph`, `Text`) with no formatting features at all:

| Variant | Chunk size |
|---|---|
| Minimal core (`Document`+`Paragraph`+`Text` only) | **282.93 kB raw / 87.14 kB gzip** |
| Full spike (StarterKit + drag-handle + image + callout + media nodes) | **533.66 kB raw / 169.93 kB gzip** |
| **Attributable to StarterKit's extra nodes + drag-handle + image** | ~251 kB raw / ~83 kB gzip |

**Conclusion:** roughly **half the cost (87 kB gzip) is an irreducible ProseMirror-core
floor** — `@tiptap/core` + `@tiptap/pm`'s model/state/view/transform modules, present even
with zero formatting extensions. This is not a Tiptap-specific inefficiency; any
ProseMirror-based editor pays it. The other half is genuinely trimmable (StarterKit currently
pulls in blockquote, code-block, horizontal-rule, and list extensions this spike's use case
may not need — a real implementation should hand-pick extensions instead of taking the full
`starter-kit` bundle).

This is a real trade-off, not a blocker: PB-44's use case is an **internal concierge/content-
authoring tool**, not a student-facing screen, so a 170 kB gzip lazy chunk loaded only by
content authors is a materially different cost than the same weight on a student learning
path route. If this editor were ever needed on a student-facing surface, the ProseMirror
floor would be worth re-litigating against Editor.js's lighter, non-ProseMirror architecture.

---

## Gate on the spike branch

| Check | Result |
|---|---|
| `vitest run` | **217 passed** (39 files) — +4 spike tests over the `dev` baseline of 213 |
| `vue-tsc --build` | clean |
| `eslint . --max-warnings 0` | clean |
| `vite build` | clean; numbers above |

## Recommendation

**Accept Tiptap** as the content-authoring editor for PB-8i, subject to the bundle-cost
trade-off in decision point 5 being acceptable for an internal, non-student-facing tool
(recommend: yes, accept). No need to spike the Editor.js fallback — none of the four
prototype steps failed or revealed a Tiptap-specific dealbreaker.

**Amendment for whoever writes the follow-up ADR:**
1. Hand-pick Tiptap extensions instead of `@tiptap/starter-kit` wholesale, to shave the
   trimmable ~83 kB gzip portion down to only what lesson content actually needs.
2. Persist content via `setContent()`/`getJSON()` round-trips only — never diff a
   freshly-mounted document's JSON against a reloaded one (decision point 1's caveat).
3. If this editor is ever considered for a student-facing surface (not currently planned),
   re-open the Editor.js comparison — the ProseMirror floor is a real, non-negotiable cost
   class Editor.js's architecture avoids.

## Follow-up

- [ ] Draft the follow-up ADR (next number after ADR-019) recording this decision.
- [ ] Delete `motifpath-web@spike/PB-44/text-editor`.
- [ ] PB-44 → Validated once the ADR is accepted; feeds PB-8i's authoring-UI implementation.
