# Plan: PB-44 — Content-Authoring Text Editor Spike

**Task:** PB-44
**Date:** 2026-09-13
**Author:** Gilson
**Status:** Ready

---

## Goal

Determine which structured-block content editor library MotifPath should adopt for lesson
authoring (concierge/content-team tooling, feeding PB-8i), by building a throwaway prototype
against `motifpath-web`'s real toolchain, so the choice is backed by evidence — not research
alone — before an ADR is written.

## Scope

**In scope (`motifpath-web` only, throwaway branch — nothing merges):**
- A minimal block-editing prototype built with **Tiptap** (`@tiptap/vue-3`), the library
  research (see Related) recommends as the primary candidate: rich text (headings, bold/
  italic, lists, links), a custom `callout` node, embedded video/audio/image nodes, and
  drag-handle block reordering (`@tiptap/extension-drag-handle-vue-3`).
- Serialize/deserialize the document as ProseMirror JSON (not HTML) to confirm the
  JSON-block persistence model works end to end.
- Bundle-size measurement (before/after, gzip + raw), following PB-34's pattern.
- **Conditional fallback:** if Tiptap's assembly cost for block UX (callout node,
  drag-handle, media nodes) proves too high within the timebox, spike **Editor.js** instead
  (framework-agnostic core, no Vue wrapper needed, native JSON block-array output) and record
  why the switch was made.
- A findings note committed to `motifpath-specs/spikes/`, recommending accept/amend/reject.

**Out of scope:**
- BlockNote, Plate, Lexical — ruled out by the research pass (see Related) without a code
  spike: BlockNote requires bridging a React runtime into the Vue app via `veaury`
  (contradicts ADR-018's Vue-only/headless direction) and carries GPL/commercial licensing
  risk on advanced features; Plate has no viable Vue path; Lexical's Vue binding is an
  unofficial, small-community wrapper and it ships no ready block/drag UI.
- Any real content-authoring UI, route, or persistence layer — this is a throwaway isolated
  prototype, not PB-8i's actual authoring screen.
- Backend schema for storing authored content (deferred to whichever plan implements PB-8i).
- Merging anything to `motifpath-web` `dev`. The spike branch is deleted after the findings
  note lands.
- Any spec-contract (OpenAPI/Gherkin) or infra change.

## Prerequisites

- [x] PB-44 created in the Product Backlog (Research Task, Discovery, P1)
- [x] Editor-library research pass completed (Tiptap recommended, Editor.js as fallback;
      BlockNote/Plate/Lexical ruled out)
- [x] `motifpath-web` `dev` green (Vue 3.5.13, Vite 6, TypeScript 5.8 strict, Tailwind 3.4.17,
      `reka-ui`/`lucide-vue-next` already integrated per PB-34)
- [ ] ~1–2 focused days available; this is a spike, not a feature — timebox it

---

## Implementation Steps

### Phase 1 — Spec (motifpath-specs)

**No spec-contract change.** This spike validates a library/architecture choice; it touches
no OpenAPI, event, or Gherkin file. The only `motifpath-specs` artifacts are this plan and the
findings note (Phase 3, Step 6).

### Phase 2 — Backend (motifpath-core)

Not applicable — no backend change.

### Phase 3 — Frontend (motifpath-web)

**Branch:** `spike/PB-44/text-editor` (from `dev`; throwaway, never merged)

- [ ] Step 1 — **Install & baseline.** `npm i @tiptap/vue-3 @tiptap/starter-kit`. Add a
      `SpikeEditor.vue` mounting a bare Tiptap instance styled only with token utilities
      (per ADR-018). Verify: `npm run typecheck` passes; content edits produce ProseMirror
      JSON via `editor.getJSON()`.
- [ ] Step 2 — **Callout node.** Implement a custom Tiptap node (`Callout`) rendering a
      styled block with a type variant (info/warning). Verify it round-trips through
      `getJSON()` / `setContent()` without data loss.
- [ ] Step 3 — **Media nodes.** Add node types (or existing extensions) for embedded image,
      audio, and video — inline, block-level, each carrying a URL/src attribute. Verify each
      serializes as a distinct JSON node type.
- [ ] Step 4 — **Drag-handle reordering.** `npm i @tiptap/extension-drag-handle-vue-3`. Wire
      it to the editor and confirm block-level drag reorder works for at least: paragraph,
      heading, callout, media node. Record any friction with TS-strict typing of custom nodes.
- [ ] Step 5 — **Bundle & gate.** Run `npm run test`, `npm run typecheck`, `npm run lint`,
      `npm run build`. Capture bundle-size delta (raw + gzip) for the chunk containing the
      editor, following PB-34's measurement method.
- [ ] Step 6 — **Findings note.** Write
      `motifpath-specs/spikes/PB-44-text-editor-findings.md`: per prototype step —
      *validated* / *validated with caveat* / *problem*, with evidence (bundle numbers, code
      snippets, JSON output samples). If Tiptap's assembly cost made the fallback necessary,
      document the switch and repeat the equivalent findings for Editor.js. End with a
      one-line recommendation (accept Tiptap / accept Editor.js / neither — reopen research).
      Commit on a normal branch (`docs/PB-44/spike-findings` → `main`), open a PR.
- [ ] Step 7 — Delete the `spike/PB-44/text-editor` branch. Nothing from it merges.

### Phase 4 — Infrastructure (motifpath-infra)

Not applicable.

---

## Rollback Plan

Nothing to roll back — the spike branch is never merged and is deleted at Step 7. The only
lasting artifact is a Markdown findings note in `motifpath-specs`. If the spike is abandoned
mid-way, close the branch and note "inconclusive" on the findings-note PR; PB-44 stays in
Discovery.

## Validation

The spike succeeds when the findings note answers, with evidence, for the chosen candidate:

- [ ] **Rich text + structure:** headings, bold/italic, lists, links, and a custom callout
      node all round-trip through JSON serialize/deserialize without data loss.
- [ ] **Media embeds:** image/audio/video nodes are distinct, serializable JSON node types.
- [ ] **Block reordering:** drag-handle reorder works across at least 4 block types.
- [ ] **Bundle cost:** a hard number (raw + gzip) for the editor's route/chunk, not "small" or
      "acceptable."
- [ ] **License & Vue-fit confirmed in practice**, not just from the research pass.
- [ ] A recommendation is written and a follow-up ADR is drafted (accept / amend / reject).

## Open Questions

| Question | Owner | Resolution |
|---|---|---|
| Does Tiptap's now-MIT drag-handle extension (`@tiptap/extension-drag-handle-vue-3`) cover the full reorder UX needed, or is a hand-rolled drag layer still required? | Gilson | Resolve during Step 4 |
| Should authored JSON be rendered back with Tiptap's own renderer on the student-facing side, or transformed into a separate lightweight rendering schema? | Gilson | Out of scope for this spike; note as an open question in the findings note for whichever plan implements PB-8i/PB-38 |
| Is a single flat document schema sufficient, or does lesson content need multiple named "regions" (e.g. intro block vs. main body)? | Gilson | Check against `design/PB-8j-student-alpha-ux-foundation.md` before finalizing the ADR |

---

## Related

- **ADR:** none yet — this spike's findings gate a new ADR (numbering TBD, next after ADR-019)
- **Spec files:** none — no contract change
- **Backlog item:** PB-44 (Content authoring text editor — structured-block editor spike)
- **Research:** editor-library comparison (Tiptap, BlockNote, Editor.js, Lexical, Plate)
  against Vue 3.5/TS-strict/Tailwind 3.4/bundle-size/license constraints — recommended Tiptap,
  fallback Editor.js, ruled out BlockNote/Plate/Lexical; logged in this plan's Scope section
  (no separate research doc committed)
- **Prior art:** PB-34 Phase 1 (`plans/PB-34-phase-1-frontend-architecture-spike.md`,
  `spikes/PB-34-phase-1-findings.md`) — the throwaway-branch + findings-note format this plan
  follows
- **Downstream:** PB-8i (Content & classification concierge tooling) — this spike's outcome
  is a prerequisite for that item's authoring UI
