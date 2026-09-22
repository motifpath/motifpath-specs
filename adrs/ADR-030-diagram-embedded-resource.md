# ADR-030: Diagram is an embedded resource, not a ContentNode content type — revises ADR-028's linkage decision

**Status:** Accepted
**Date:** 2026-09-22
**Deciders:** Gilson (Product Owner)
**Supersedes:** ADR-028's `ContentNode`/`Exercise` linkage decision only (the "`ContentNode` and `Exercise`
both gain diagram linkage" subsection). ADR-028's `Instrument`/`Diagram`/`DiagramRef`/`DiagramStackRef`
entity model — polymorphic per-family coordinates, render-time layer/styling/playback config, and
`diagram_stack_ref` compositing — is unchanged and remains Accepted.

---

## Context

ADR-028 gave `ContentNode.body` a third variant, `diagram`, mutually exclusive with `media_url`
(video) and `rich_content` (article): a content node was either a video, an article, or a diagram,
never a mix. It also gave `Exercise` a top-level `diagram_ref`/`diagram_stack_ref` for
`image_recognition`. This was implemented in `motifpath-specs` (PR #83 ADR, #85 spec, #88 un-`@wip`)
and `motifpath-core` (PR #33, `Instrument`/`Diagram`/`Position` entities and CRUD — `ContentNode`/
`Exercise` linkage itself, "Phase 2 step 5," was never built).

Reviewing the model against how a teacher actually authors content surfaced the mistake: a diagram
is not a content *format* alongside video and article — it is a reusable *resource* an author drops
into content that already has a format. A teacher writing an article about the minor pentatonic
scale wants to embed the scale diagram partway through the article text, the same way they'd embed
an image — not create a fourth, diagram-only node that can't also contain the surrounding
explanation. The one-of-three model forced a false choice ADR-028 didn't intend: a content node
teaching a scale pattern with prose *around* it had nowhere to put both at once.

This repo already has the right shape for "embed a resource into content that has its own format,"
and diagram should have used it from the start: `PromptDocument`/`PromptNode` (ADR-020's Tiptap-based
rich-text model) already lets `rich_content` "embed video or audio alongside text and images — no
separate video/audio content_type is needed" (existing schema description, `ExpandedContentRequest`).
Separately, `ExpandedContent` already models "an image, GIF, or rich-text item shown at a specific
point" (a video timestamp or an article paragraph) as one of three interchangeable `content_type`
values, not a property of the parent node.

**Alternatives considered for where a diagram attaches to a `ContentNode`:**

1. Keep ADR-028's `ContentNode.body` third variant as-is. Rejected: doesn't solve the actual authoring
   need (a diagram *within* an article, not *instead of* one), and creates two independently-drifting
   mechanisms for referencing a `Diagram` from a content node once `ExpandedContent` also needs one.
2. Add `diagram` only as a new `ExpandedContent` `content_type`. Rejected: covers a diagram shown at a
   video timestamp or between article paragraphs, but not a diagram embedded inline mid-paragraph in
   an article's own prose — arguably the most common case for "here's the pattern I just described."
3. Add `diagram` only as a new `PromptNode.type` (inline in any `PromptDocument`). Rejected: covers the
   inline-in-article case, but not attaching a diagram to a *video* node without wrapping it in a
   `rich_text` `ExpandedContent` item just to carry one diagram — an unnecessary extra layer for that
   case, which `ExpandedContent`'s `image`/`gif` types don't need either.
4. Both: `PromptNode.type: diagram` for inline embedding, and `ExpandedContent.content_type: diagram`
   for the triggered-overlay case. Accepted.

**Exercise side:** reviewed against Gilson's own exercise-authoring design (a Claude Design canvas,
`Authoring.dc.html`/`ExerciseView.dc.html`), which already shows a single "choose an image" picker
with a *Predefined* tab (a catalog of prebuilt diagram assets) alongside a *Custom* tab (upload),
both feeding the same slot — for both `image_recognition`'s whole-exercise stimulus and
`image_choice`'s per-option image. This is exactly where ADR-028 already put `diagram_ref`
(`Exercise`-level for `image_recognition`, `Option`-level for `image_choice`) — that placement was
correct and is unchanged by this ADR. The one addition, not a correction: a diagram should also be
insertable inline into a `text_response`/`audio_recognition` exercise's `prompt`, which is itself a
`PromptDocument` — the same `PromptNode.type: diagram` mechanism this ADR adds for `ContentNode`,
reused, not a second exercise-specific mechanism.

## Decision

**`ContentNode.body` reverts to exactly two variants.** Remove `diagram` from `content_type`'s enum
and remove `diagram_ref`/`diagram_stack_ref` from `CreateContentNodeRequest`, `ContentNode`, and
`UpdateContentNodeRequest`. A content node is a video (`media_url`) or an article (`rich_content`),
as it was before ADR-028's Phase 1 spec — never a diagram on its own.

**`PromptNode` gains a `diagram` type**, alongside `image`/`audio`/`video`. Its `attrs` carries a
`diagram_ref` (or `diagram_stack_ref`, for a composited view) exactly as an `image` node's `attrs`
carries `src`/`alt` — validated by the authoring editor and the application layer, not by this
schema's deliberately loose `attrs: { additionalProperties: true }`. Because every `PromptDocument`
surface shares one node vocabulary, this single addition makes a diagram insertable inline in:
`ContentNode.rich_content` (an article's body), a `rich_text` `ExpandedContent` item, and an
`Exercise.prompt` (`text_response`, `audio_recognition`, or any other type) — with no per-surface
special-casing.

**`ExpandedContent` gains a `diagram` `content_type`**, alongside `image`/`gif`/`rich_text`, carrying
a `diagram_ref`/`diagram_stack_ref` in place of `media_url`/`rich_content`. This is the
timestamp-triggered (video node) or paragraph-triggered (article node) attach point — a diagram shown
as an overlay at a specific point, without needing to wrap it in a `rich_text` item first.

**`Exercise`/`Option` diagram linkage is unchanged from ADR-028**: `Exercise`-level
`diagram_ref`/`diagram_stack_ref` for `image_recognition` (the diagram's positions become the
exercise's checkable options automatically), `Option`-level `diagram_ref` for `image_choice`. This
ADR does not modify either.

## Rationale

**One node vocabulary (`PromptNode`) for every embed point** is accepted because it's the pattern
this repo already committed to for exactly this problem — `rich_content`'s own description already
says embedding video/audio needs no separate `content_type`, and diagram is the same kind of thing:
a resource dropped into content that has its own format, not a format of its own. Reusing it means a
diagram-in-an-article and a diagram-in-an-exercise-prompt cost nothing beyond the one `PromptNode`
type addition, instead of a bespoke mechanism per consuming surface.

**Keeping `ExpandedContent.content_type: diagram` alongside the `PromptNode` addition**, rather than
picking one, is accepted because the two solve genuinely different attach problems ADR-028's original,
single `ContentNode.body` slot conflated: *inline*, mid-content placement (`PromptNode`) versus a
*triggered overlay* at a specific video timestamp or article paragraph (`ExpandedContent`) — the same
distinction `image`/`gif` already draw against `rich_content`'s own inline `image` node type, which
this repo already tolerates as two valid ways to place an image depending on intent.

**Reverting `ContentNode.body`'s third variant rather than keeping it as a fourth option alongside the
two new embed points** is accepted because a `diagram`-typed `ContentNode` with no `media_url` and no
`rich_content` was never actually useful on its own — a lone diagram with no surrounding explanation
isn't a lesson; ADR-028's own Consequences never identified a case for a diagram-only node, only for
diagrams reused across nodes. Removing it is a strict simplification, not a lost capability.

**Not touching `Exercise`/`Option`'s existing diagram placement** is accepted because Gilson's own
exercise-authoring design already validates it as correct — the "choose an image" picker's
Predefined/Custom split is precisely ADR-028's `image_url` vs. `diagram_ref` alternative, already
built where it needs to be. Revising something already right, to match a fix needed elsewhere, would
be scope creep.

## Consequences

### Positive

- One embed mechanism (`PromptNode.type: diagram`) covers diagram-in-article,
  diagram-in-exercise-prompt, and diagram-in-rich-text-overlay uniformly — no new attach machinery
  needed as new `PromptDocument`-based surfaces are added later.
- `ContentNode.body` returns to the simple two-variant shape every consumer (motifpath-web's lesson
  rendering, motifpath-core's persistence) already expected before ADR-028 — less special-casing than
  the three-variant model introduced.
- A content node can now include *multiple* diagrams (as many inline `PromptNode`s or `ExpandedContent`
  items as an author wants), not capped at exactly one `diagram_ref`/`diagram_stack_ref` per node as
  ADR-028's model forced.
- Caught before `motifpath-core`'s Phase 2 step 5 (`ContentNode`/`Exercise` linkage implementation)
  was ever built — the entities themselves (`Instrument`/`Diagram`/`Position`) need no rework, only
  the not-yet-written linkage code targets the corrected shape instead.

### Negative / Trade-offs

- This reverts part of an already-merged spec (`motifpath-specs` PR #85/#88) — a real, if contained,
  breaking-shape change to `ContentNode`'s request/response schemas, requiring
  `motifpath-web`/`motifpath-core` to regenerate against the corrected spec.
- `PromptNode.attrs` stays schema-loose (`additionalProperties: true`, validated by the authoring
  editor). A `diagram` node's `attrs.diagram_ref` now carries real structured data into a field this
  schema deliberately doesn't type-check — `motifpath-core`'s application layer, not OpenAPI, is where
  a malformed diagram embed gets caught.
- `ExpandedContent`'s existing trigger/hide timing fields (seconds for video, paragraph index for
  article) now apply to diagrams too, unexamined by this ADR — whether a fixed trigger/hide window
  suits a scale-pattern diagram shown as a demonstration (versus, say, staying visible until dismissed)
  is unresolved, same open question ADR-028 already flagged for playback/accessibility.

### Neutral

- `Instrument`/`Diagram`/`DiagramRef`/`DiagramStackRef`, and `Exercise`/`Option`'s existing
  `diagram_ref` placement, are unchanged — this ADR is scoped exactly to `ContentNode`'s linkage
  mechanism.
- ADR-027's SVG layer-system renderer is unaffected: it consumes a `Diagram` + a `diagram_ref`
  render config regardless of which field on which parent object supplied that `diagram_ref`.

## Related ADRs

- **ADR-028** (Diagram content model) — this ADR supersedes only its `ContentNode`/`Exercise` linkage
  decision; the entity model, render-time config, and stacking decisions are unchanged and remain
  Accepted.
- **ADR-027** (SVG rendering for layered diagrams) — unaffected; still the renderer this ADR's
  `diagram_ref`/`diagram_stack_ref` embeds feed into.
- **ADR-026** (Content classification graph) — unaffected; `Diagram.skill_ids`/`concept_ids` unchanged.
- **ADR-020** (Content authoring text editor) — this ADR extends `PromptNode`, the node type ADR-020
  established for `PromptDocument`.
- **ADR-019** (Practice content model) — `Exercise`/`Option` diagram linkage, decided there and by
  ADR-028, is unchanged by this ADR.

## Follow-up work (not part of this ADR)

- `motifpath-specs`: revert `ContentNode.body`'s `diagram_ref`/`diagram_stack_ref`/`content_type:
  "diagram"`; add `PromptNode.type: diagram` and its `attrs` shape; add `ExpandedContent.content_type:
  diagram`; Gherkin coverage for both embed points plus a failure case (`content_type: "diagram"` on
  `ContentNode` no longer accepted).
- `motifpath-specs` PR #95 (this session, widens `events.yaml`'s tracking-event `content_type` to
  include `diagram`, mirroring `ContentNode.content_type`) is now unnecessary — `ContentNode.
  content_type` no longer has a `diagram` value — and should be closed rather than merged.
- `motifpath-web` PR #39 (this session, draft): the `FrettedDiagramView.vue` renderer and
  `computeFrettedDiagramLayout` utility remain valid as-is — both consume a `Diagram` + `diagram_ref`
  regardless of which field supplied it. The API-client-regeneration commit and its ripple fixes
  assumed the old `ContentNode.body` shape and need redoing once this ADR's spec changes land.
- `motifpath-core`: Phase 2 step 5 (not started) should be scoped against this ADR's `PromptNode`/
  `ExpandedContent` model, not ADR-028's original `ContentNode.body` plan.

---

*This ADR was decided on 2026-09-22. To revise, create a new ADR with Status: Supersedes ADR-030.*
