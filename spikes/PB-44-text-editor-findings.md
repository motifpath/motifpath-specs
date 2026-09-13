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
`callout` node, `audio`/`video`/`image` media nodes, drag-handle block reordering, a toolbar,
paste-to-insert for clipboard images, and tables. All prototype steps validated; the gate ran
clean (**219 tests**, `vue-tsc --build`, `eslint --max-warnings 0`, `vite build`). The one
substantial finding is bundle cost: the editor's route chunk is **583 kB raw / 185 kB gzip**,
of which **~283 kB raw / ~87 kB gzip is an irreducible ProseMirror-core floor** (present even
with zero formatting extensions), not something Tiptap-specific trimming can remove.

**Recommendation: accept Tiptap**, gated on confirming the 185 kB gzip lazy-chunk cost is
acceptable for an internal concierge tool (not a student-facing chunk) — see Decision point 5.

**Manual round-trip note (2026-09-13, post-initial-note):** Gilson tried the first prototype
by hand and found three gaps the initial four decision points didn't cover: no visible
formatting menu, pasting an image from the clipboard did nothing, and no way to add a table.
None were Tiptap dealbreakers — they were simply not built into the first prototype pass, which
only wired the editor engine and drag-handle. Decision points 6–8 below close those gaps.

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

## Decision point 6 — Formatting menu (toolbar)

**Result: validated — but Tiptap ships zero UI, by design.**

- Tiptap is headless: there is no built-in toolbar, bubble menu, or button of any kind. The
  first prototype pass exposed the editor engine only, which is why nothing was visible to
  click.
- `SpikeToolbar.vue` (~50 lines) demonstrates the minimum: six buttons (Bold, Italic, H2,
  Bullet list, Callout, Table) each calling `editor.chain().focus().<command>().run()`
  directly, with active-state styling via `editor.isActive(...)` and only token utility
  classes (`bg-accent-muted`, `text-accent-text`) per ADR-018.
- **This is genuine assembly cost, not a bug.** Every button, icon, and active/inactive state
  has to be hand-built — there's no toolbar extension to install. A real implementation needs
  a fuller toolbar (more marks/nodes, keyboard shortcuts surfaced, a bubble menu for
  selection-based formatting) — budget for it as real UI work, not configuration.

**No amendment needed** — this is expected headless-library behavior (consistent with
ADR-018's chosen direction generally), just worth stating plainly: "no toolbar" was correct
per the architecture, but it means a toolbar is *build*, not *install*.

## Decision point 7 — Paste-to-insert images from the clipboard

**Result: validated (with one caveat) after adding a ~30-line extension.**

- `@tiptap/extension-image` renders `<img>` nodes but does **not** intercept paste/drop of
  image *files* — that's the browser Clipboard API, and every editor (headless or not) has to
  wire it up itself. `src/spike/imagePasteHandler.ts` adds a ProseMirror plugin
  (`handlePaste`) that reads any image files off the paste event, converts each to a data URL
  via `FileReader`, and calls `editor.chain().focus().setImage({ src }).run()`.
- Verified by test (`SpikeEditor.spec.ts` — *"inserts an image from a pasted clipboard
  file"*): dispatching a `paste` event carrying an `image/png` `File` results in an `image`
  node in `getJSON()`.
- **Caveat — production readiness.** The spike inserts a base64 data URL directly, which is
  fine for a throwaway prototype but not for real lesson content (bloats the stored JSON
  document with embedded binary data). A real implementation needs to intercept the same
  paste event, **upload** the file to storage, and insert the resulting URL instead —
  `imagePasteHandler.ts`'s `reader.onload` callback is exactly where that upload call would
  go. Drag-and-drop of image files would need the equivalent `handleDrop` prop on the same
  plugin (not built in this spike — same pattern, not spiked separately since it's
  mechanically identical to paste).

**Amendment:** the follow-up ADR/implementation should note that paste-to-insert requires a
custom handler either way (spiked or not) and that it must upload rather than inline
base64-encode in a real implementation.

## Decision point 8 — Tables

**Result: validated (with one caveat).**

- `@tiptap/extension-table` v3 bundles `Table`, `TableRow`, `TableHeader`, and `TableCell` as
  named exports from a **single package** — the separately-published
  `@tiptap/extension-table-row`/`-cell`/`-header` packages exist but are redundant with the
  bundle; installing them separately was a false start, corrected during the spike (removed
  again via `npm uninstall`).
- `editor.chain().focus().insertTable({ rows, cols, withHeaderRow }).run()` inserts a table
  whose JSON serializes as `table > tableRow[] > (tableHeader | tableCell)[]` — verified by
  test (*"inserts a table with a header row via insertTable()"*).
- **Caveat — zero built-in visual style.** Like the toolbar, the table extension renders bare
  `<table>`/`<td>`/`<th>` elements with no borders or spacing; Tailwind's `preflight` reset
  strips default browser table borders same as any element. `SpikeEditor.vue`'s `<style
  scoped>` block (border-collapse, cell borders/padding, header background) is the minimum
  hand-written CSS any real implementation needs — about 12 lines, not a blocker, but another
  data point that Tiptap gives you the document model and interaction logic, never visual
  presentation.

**No amendment needed** beyond noting the same "you own all the CSS" pattern already true of
callout/media nodes.

---

## Updated bundle cost (toolbar + paste handler + tables added)

| Chunk | First pass (rich text + media + drag-handle only) | With toolbar + paste + tables | Delta |
|---|---|---|---|
| Entry (`index.js`) | 147.40 kB raw / 53.18 kB gzip | 147.49 kB raw / 53.23 kB gzip | +0.09 kB raw / +0.05 kB gzip — noise |
| `SpikeEditor` chunk | 533.66 kB raw / 169.93 kB gzip | **583.00 kB raw / 184.99 kB gzip** | +49.34 kB raw / +15.06 kB gzip for the table extension + toolbar + paste handler combined |

Isolation still holds — the additional feature surface cost stays entirely inside the lazy
chunk. The table extension is the bulk of that +15 kB gzip; the toolbar and paste handler are
hand-written app code and add negligible weight themselves.

---

## Gate on the spike branch

| Check | Result |
|---|---|
| `vitest run` | **219 passed** (39 files) — +6 spike tests over the `dev` baseline of 213 |
| `vue-tsc --build` | clean |
| `eslint . --max-warnings 0` | clean |
| `vite build` | clean; numbers above |

## Recommendation

**Accept Tiptap** as the content-authoring editor for PB-8i, subject to the bundle-cost
trade-off in decision point 5 being acceptable for an internal, non-student-facing tool
(recommend: yes, accept). No need to spike the Editor.js fallback — none of the eight
prototype steps failed or revealed a Tiptap-specific dealbreaker. Every gap found (toolbar,
paste-to-insert, tables) was closed with focused, small additions (~50, ~30, and ~12 lines
respectively) — consistent with "headless, ejectable, you build the UI" being Tiptap's actual
model rather than a limitation specific to this use case.

**Amendment for whoever writes the follow-up ADR:**
1. Hand-pick Tiptap extensions instead of `@tiptap/starter-kit` wholesale, to shave the
   trimmable ~83 kB gzip portion down to only what lesson content actually needs.
2. Persist content via `setContent()`/`getJSON()` round-trips only — never diff a
   freshly-mounted document's JSON against a reloaded one (decision point 1's caveat).
3. If this editor is ever considered for a student-facing surface (not currently planned),
   re-open the Editor.js comparison — the ProseMirror floor is a real, non-negotiable cost
   class Editor.js's architecture avoids.
4. Budget real UI design/build time for the toolbar (and likely a bubble menu) — it is not
   "configure a toolbar extension," it is "build a toolbar component" (decision point 6).
5. The paste-to-insert image handler must upload to storage, not inline a base64 data URL as
   the spike does — extend the same handler with a `handleDrop` prop for drag-and-drop of
   image files (decision point 7).
6. Table (and callout, and media node) visual styling is entirely hand-written CSS — budget a
   small design pass for it, it does not come from the extension (decision points 2 and 8).

## Follow-up

- [ ] Draft the follow-up ADR (next number after ADR-019) recording this decision.
- [ ] Delete `motifpath-web@spike/PB-44/text-editor`.
- [ ] PB-44 → Validated once the ADR is accepted; feeds PB-8i's authoring-UI implementation.
