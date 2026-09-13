# PB-40 — Exercise authoring builder (prototype)

High-fidelity, clickable prototype of the exercise-authoring page: the internal tool (desktop
only, team/teacher use, not student-facing) where an Exercise is built per ADR-019's content
model.

**Published prototype:** https://claude.ai/code/artifact/00906887-d6be-4bc4-8171-9c8411b77b01

## Scope

- Four exercise types, all sharing ADR-019's unified option-selection answer-checking:
  `image_recognition` (click/drag regions — circle or rectangle, independently resizable —
  onto an image), `text_response` (fixed-choice options), `audio_recognition` (audio stimulus +
  fixed-choice options), and `image_choice` (options are images, not text).
- A single shared image picker (predefined library or custom upload) used identically by the
  `image_recognition` canvas and every `image_choice` option — not two separate patterns.
- Skill tags (freeform), a "used in challenges" reuse indicator reflecting ADR-019's
  many-to-many Exercise↔Challenge relationship, and a "preview as student" modal with a
  Portrait/Landscape toggle matching ADR-015's actual S7 (Practice) responsive spec.
- Light/dark theme, built entirely from `motifpath-brand/tokens.json` (no hardcoded colors).

## Open item this prototype surfaced

`image_choice` is a 4th exercise type beyond the three ADR-019 committed
(`text_response`/`audio_recognition`/`image_recognition`). **ADR-019 needs a follow-up
amendment** to add it formally once the shape here is confirmed — not yet written.

## Process note

Built directly to high fidelity (not the usual 2-3 low-fi directions first) at Gilson's
explicit request. Iterated through several rounds of comments left directly on the published
Artifact (design tokens/theming, region shape+resize+drag, predefined-image picker modal,
image_choice type, unifying the two image-picking flows) — each addressed on the artboard and
republished; this commit captures the converged state as of 2026-09-13.
