# ADR-028: Diagram becomes a first-class, reusable content entity — structured position data, render-time layer config, and shared linkage into ContentNode and Exercise

**Status:** Proposed
**Date:** 2026-09-20
**Deciders:** Gilson (Product Owner)

---

## Context

This is PB-57 ("define and implement the base for creating predefined content"), the next step
after ADR-027 decided SVG as the rendering approach for layered instrument diagrams (scale/chord
patterns, and similar). ADR-027 settled *how* a diagram is rendered; it deliberately did not
decide how diagram content is *stored*, *selected*, or *reused* across the platform — that's this
ADR's scope.

Today, `ContentNode`'s body is `media_url` (video) or `rich_content` (article) — no diagram
variant exists. `Exercise`'s `image_recognition` and `image_choice` types (ADR-019) take a
teacher-uploaded static `image_url`, with `image_recognition` additionally requiring the teacher
to hand-draw pixel regions on that image to mark clickable areas. Every fretboard diagram a
teacher wants to teach or quiz today has to be authored as a flat image, with no reuse: the same
A minor pentatonic pattern used in a lesson and in three different exercises would be uploaded as
four independent, unconnected images, and any clickable region on it hand-drawn once per image
with no guarantee the coordinates agree with each other.

Three concrete problems follow from that:

1. **No reuse.** A canonical pattern (e.g., "minor pentatonic, position 1") has no single source
   of truth — it's re-drawn as a new image asset every time a teacher wants to use it.
2. **Regions are manual and decoupled from meaning.** An `image_recognition` region is just pixel
   coordinates on a specific uploaded image; it carries no semantic link to which note or interval
   that region represents, so the same logical position (e.g., "the root note on the low E
   string, 5th fret") has to be redrawn and re-marked by hand on every image that includes it.
3. **Layer combinations (ADR-027) require structured data to work at all.** ADR-027's
   attributes-on-existing-elements layering only works if the underlying diagram is described as
   structured position data the renderer can selectively decorate — a flat image has no positions
   to attach layer attributes to. Without a data model, ADR-027's decision has nothing to render.

**Alternatives considered for storage:**

1. Keep diagrams as uploaded images (status quo) and add metadata describing regions separately.
   Rejected: doesn't solve reuse, and still requires hand-authored regions per image — ADR-027's
   layering has no data to work against.
2. Store diagrams as pre-rendered SVG markup (one stored SVG string per diagram).
   Rejected: bakes a specific layer combination into the stored asset, which is exactly the
   combinatorial-growth problem ADR-027's "attributes on existing elements" design avoids. A
   stored SVG string also isn't queryable structured data — you can't ask "which diagrams mark
   the root note on string 6" against a markup blob.
3. Store diagrams as structured position data (a `Diagram` entity: instrument, named positions
   with interval/note metadata), rendered into SVG client-side per ADR-027's layer system.
   Accepted.

**Alternatives considered for layer selection:**

1. Store one asset per layer combination a teacher wants (e.g., a "with intervals" variant and a
   "without intervals" variant of the same diagram). Rejected: this is the same combinatorial
   growth problem in a different guise, and directly contradicts ADR-027's decision that layer
   combinations are computed, not stored.
2. A render-time layer configuration object, carried wherever a `Diagram` is used, applied against
   the single stored `Diagram`. Accepted.

**Alternatives considered for Exercise linkage:**

1. Leave `image_recognition`/`image_choice` as-is (flat `image_url` + hand-drawn `region`) and
   treat `Diagram` as a `ContentNode`-only feature. Rejected: this throws away the strongest
   product win available — a diagram's positions and an `image_recognition` option's region are
   the same shape (a located point/area with a semantic meaning), so building `Diagram` without
   connecting it to `Exercise` options means re-solving "mark a fretboard position" twice, once
   per resource, with two independently-drifting representations.
2. Give `Exercise` options a `diagram_ref` (a `Diagram` id + layer config), usable as an
   alternative to `image_url`/`region`, so a diagram-driven option's clickable region is read
   directly from the diagram's own position data. Accepted.

## Decision

### `Diagram` is a first-class, reusable entity storing structured position data

```
Diagram {
  id: uuid
  instrument_id: uuid          // which instrument this diagram is defined against
  name: string
  positions: [
    { string: int, fret: int, interval: string, note_name: string }
  ]
  skill_ids: uuid[]             // at least one entry, same tree as ContentNode/Exercise
  concept_ids: uuid[]           // at least one entry, same tree as ContentNode/Exercise
}
```

`instrument_id` references an `Instrument` entity (string/course count and open-string tuning),
kept separate from `Diagram` so the same instrument definition is shared across every diagram
written against it, and so a non-fretted instrument (piano) can define its own position shape
without `Diagram` itself assuming frets exist. `positions` is the base layer ADR-027's layer
system decorates — every other layer (interval labels, subset filters, shape overlays) is
computed from this same list, never stored as a separate copy of it.

`Diagram` is classified through `skill_ids`/`concept_ids` against the exact same `Skill`/`Concept`
tree `ContentNode` and `Exercise` already use (ADR-026) — not a third, parallel tagging scheme. A
diagram of the A minor pentatonic scale and a `ContentNode` teaching it and an `Exercise` quizzing
it all reference the same `Skill` node, making "what teaches/tests/illustrates this skill" one
query across all three resource types.

**Root note is not stored on `Diagram`.** A pattern is authored once as a movable shape
(intervals relative to the pattern's own root), and transposed to a concrete key at the point of
use via the layer config's `root_override` — storing a separate `Diagram` row per root/key would
duplicate the same shape twelve times over for no data-model benefit.

### Layer selection is a render-time config, never a stored variant

Wherever a `Diagram` is referenced, it's referenced as a `diagram_ref`:

```
diagram_ref {
  diagram_id: uuid
  root_override: string | null   // transposes the pattern; null uses the diagram's own root
  layers: {
    intervals: bool
    subset: string[] | null      // interval names to show; null shows all positions
    shape_overlay: string | null // e.g. a box outline id; null shows no overlay
  }
}
```

The same `Diagram` can be referenced by any number of `diagram_ref`s, each with its own layer
config — a `ContentNode` teaching the full pattern with intervals labeled, and an `Exercise`
quizzing only the root notes with no labels, both reference the same underlying `Diagram` with
different `layers` values. No new `Diagram` row, and no new stored image, is created for either.

### `ContentNode` and `Exercise` both gain diagram linkage, using the same `diagram_ref` shape

**`ContentNode` body** gains a third variant alongside `media_url` (video) and `rich_content`
(article): `diagram_ref`. A node's body is exactly one of the three — video, article, or diagram —
unchanged from the existing one-of-body-types rule PB-40 established for the first two.

**`Exercise` options** (`image_recognition` and `image_choice` types only, per ADR-019) gain
`diagram_ref` as an alternative to `image_url`. For `image_recognition` specifically, when an
option is diagram-driven, **the option's clickable region is read directly from the referenced
`Diagram`'s `positions`** — a diagram-driven `image_recognition` exercise has no hand-drawn
`region` field to author at all; each position in the diagram (filtered by the layer config's
`subset`, if set) becomes one clickable, checkable option automatically. `image_url`/`region`
remain fully supported, unchanged, for teacher-uploaded custom images — `diagram_ref` is an
addition, not a replacement.

`text_response` and `audio_recognition` option types are unaffected — diagrams are a visual
content mechanism and have no bearing on those types' checking model.

## Rationale

**Structured position data over pre-rendered SVG or flat images** is accepted because it's the
only option that gives ADR-027's layer system something to actually decorate, and the only one
that makes a diagram queryable ("which diagrams mark this interval") rather than an opaque blob.
Storing rendered SVG was the closest alternative, but it re-introduces exactly the
one-asset-per-combination growth ADR-027 was written specifically to avoid.

**A render-time layer config instead of stored variants** is accepted for the same reason ADR-027
rejected per-combination rendering: a `Diagram`'s reuse value comes from being shown differently
in different contexts without being copied. Storing a config object next to each usage is
cheap — it's a small, bounded object per reference, not a new content asset — while storing a
rendered variant per combination is unbounded in the number of layer toggles a teacher might
combine.

**Root as a render-time transposition, not stored data**, keeps `Diagram` count proportional to
the number of distinct *shapes* MotifPath teaches (a handful of scale/chord patterns), not shapes
× keys. This mirrors ADR-026's reasoning for classifying by shared skill rather than duplicating
content per surface — one canonical asset, applied in multiple contexts, rather than one asset
per context.

**Linking `Exercise` options to `Diagram`, deriving regions from positions**, is accepted because
it's the actual product win this ADR exists to capture: a fretboard position and a clickable
exercise region are the same fact (a located, semantically-named point), and treating them as one
thing means a teacher building an `image_recognition` exercise on a `Diagram` never hand-draws a
region again — the diagram's own data already says where the root note is. Keeping `image_url`/
`region` alongside it, rather than replacing it, is necessary because not every exercise image is
a diagram MotifPath's model can express (a photo of a real guitar, an unusual chord shape not yet
authored as a `Diagram`) — the manual path stays available for content the structured model
doesn't yet cover.

**Not extending `text_response`/`audio_recognition`** is a scope discipline: diagrams are visual
content, and stretching the linkage into non-visual exercise types wouldn't serve any real
authoring case, only add unused fields to two option types that already have a settled shape.

## Consequences

### Positive

- Diagram content is authored once per shape and reused across every `ContentNode` and `Exercise`
  that teaches or tests it, instead of being redrawn as a new image per surface.
- Layer combinations (base, intervals, subset, shape overlay) are free to create at usage time —
  no combinatorial growth in stored assets as more contexts want a different view of the same
  pattern.
- `image_recognition` exercises built on a `Diagram` no longer require hand-drawn regions — the
  diagram's positions are the regions, automatically kept in sync with the diagram's own data.
- `Diagram` shares the exact classification vocabulary (`Skill`/`Concept`, ADR-026) that
  `ContentNode` and `Exercise` already use, so "what teaches/illustrates/tests this skill" is one
  query across all three resource types, not three independent lookups.
- One canonical asset per shape (not per key) keeps the content library small and directly
  reusable across every key a teacher wants to transpose into.

### Negative / Trade-offs

- `Diagram` is a new entity with its own CRUD surface, its own authoring UI (a position editor, not
  a freeform image upload), and its own `Instrument` dependency — real new authoring-surface cost,
  not a reuse of an existing pattern.
- `ContentNode.body` and `Exercise` option schemas both grow a third/alternative variant
  (`diagram_ref`), which `motifpath-core`'s ent schema and the generated `motifpath-web` API
  client both need to regenerate against — a breaking-shape change to two already-shipped
  resources, though with no production data to migrate yet (mirroring ADR-026's and ADR-023's
  precedent for a clean replacement).
- A diagram-driven `image_recognition` option's correctness now depends on the referenced
  `Diagram`'s data being accurate — an error in a `Diagram`'s `positions` (e.g., a wrong
  `interval` label) now affects every `ContentNode` and `Exercise` that references it at once,
  rather than being isolated to one hand-authored image. This is the same double-edged reuse
  trade-off ADR-019 accepted for `Exercise` itself (one entity, many consumers) and ADR-026
  accepted for `Skill`/`Concept` (one classification node, many consumers).
- `root_override`'s transposition math (mapping an authored shape's intervals onto a chosen root,
  per instrument tuning) is real logic that has to live somewhere — this ADR assigns it to
  `motifpath-web`'s render-time layer system (ADR-027), not to the stored data model, but it is
  not yet designed and is real follow-up work.

### Neutral

- `Instrument` as a separate entity from `Diagram` is a small additional schema surface, but
  avoids re-declaring tuning/string-count on every diagram — a `Diagram` authored against the
  wrong `Instrument` is a possible authoring error this ADR doesn't add validation against beyond
  the foreign-key reference itself.
- This ADR does not decide the position-editor authoring UI (how a teacher actually creates a
  `Diagram`'s `positions` array) — that's `motifpath-web` implementation work informed by
  ADR-027's rendering model, not a data-model question this ADR needs to settle.
- **Revisit trigger:** if a real need emerges for a diagram whose positions vary by root in a way
  simple transposition can't express (e.g., an irregular chord voicing that isn't a fixed
  interval shape), that's a new ADR, not an amendment to this one.

## Related ADRs

- **ADR-027** (SVG rendering for layered diagrams) — this ADR's `positions` data and `diagram_ref`
  layer config are exactly the input ADR-027's rendering/layering approach consumes; ADR-027
  decides *how* a `Diagram` is drawn, this ADR decides *what* a `Diagram` is and how it's stored,
  selected, and linked.
- **ADR-026** (Content classification graph) — `Diagram.skill_ids`/`.concept_ids` reuse this ADR's
  `Skill`/`Concept` tree directly, rather than introducing a fourth classification mechanism
  alongside `ContentNode`, `Exercise`, and `Challenge`.
- **ADR-019** (Practice content model) — `Exercise`'s `image_recognition`/`image_choice` option
  shape is extended here with `diagram_ref`; the many-to-many Challenge relationship,
  option-selection checking model, and all five committed exercise types are otherwise unchanged.

## Follow-up work (not part of this ADR)

- OpenAPI schema for `Diagram`, `Instrument`, and the `diagram_ref` shape, plus Gherkin scenarios
  covering diagram creation, layer-config selection, and diagram-driven `image_recognition`
  answer-checking — required before `motifpath-core` implementation begins, per this repo's
  spec-first discipline.
- `motifpath-core`: `Diagram`/`Instrument` ent schemas, `ContentNode.body` and `Exercise` option
  schema changes, and the `image_recognition` answer-checking path for diagram-derived regions.
- `motifpath-web`: the `Diagram` position-editor authoring UI, the ADR-027 layer-system renderer
  consuming `diagram_ref`, and the root-transposition logic flagged as unresolved above.
- A first content pass: author the initial library of common scale/chord `Diagram`s (starting
  with the minor pentatonic pattern used in the ADR-027 spike) once the schema and renderer exist.

---

*This ADR was decided on 2026-09-20. To revise, create a new ADR with Status: Supersedes
ADR-028.*
