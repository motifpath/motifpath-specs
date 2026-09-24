# ADR-028: Diagram becomes a first-class, reusable content entity — polymorphic per-instrument-family positions, and render-time layer, styling, and playback config

**Status:** Accepted (partially superseded by ADR-030, ADR-032 and ADR-033; extended by ADR-034)
**Date:** 2026-09-20
**Deciders:** Gilson (Product Owner)

> **2026-09-22:** This ADR's "`ContentNode` and `Exercise` both gain diagram linkage" decision
> (the `ContentNode.body` third variant specifically) is superseded by
> [ADR-030](./ADR-030-diagram-embedded-resource.md) — a diagram embeds into a `ContentNode` via
> `PromptNode`/`ExpandedContent`, not as a body content type. Everything else in this ADR (the
> `Instrument`/`Diagram` entity model, render-time `diagram_ref` config, and `diagram_stack_ref`
> stacking) is unchanged and still Accepted, as is `Exercise`/`Option`'s diagram linkage below.

> **2026-09-24:** [ADR-032](./ADR-032-diagram-templates-and-copies.md) (Accepted) gives every
> `Diagram` a `kind` (`basic` admin-curated template / `custom`) and an owner. It adds "Save as"
> copies and allows a stack to be flattened into a new `Diagram`, relaxing this ADR's "can't be
> merged into one `Diagram` row" rule for flattened diagrams only.
> [ADR-033](./ADR-033-diagram-localization.md) (Accepted) turns `DiagramPosition.interval` into a
> fixed list of codes displayed per locale, and `Diagram.name` into one name per language.
> [ADR-034](./ADR-034-diagram-annotations.md) (Accepted) adds per-language custom marker labels,
> marker notes and highlighted regions.
> `diagram_stack_ref` render-time compositing is unchanged.

> **2026-09-24:** [ADR-036](./ADR-036-localized-catalog-names.md) (Proposed) turns `Instrument.name`
> into one name per language and adds an admin-only endpoint to update an instrument's names.
> `family` and the string/key shape stay immutable.

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

Four concrete problems follow from that:

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
4. **A single, fretted-only position shape doesn't cover the instruments MotifPath actually
   needs.** A first draft of this ADR modeled `positions` as a flat `{string, fret, interval,
   note_name}` list — a shape that fits guitar and bass, but has nothing corresponding to a piano
   key. Review surfaced two more requirements that shape has no room for: an author choosing
   which colors mark which interval for a given usage, and a diagram that plays back as a
   sequence over time rather than only being shown as a static shape. Both a keyboard instrument
   and these two capabilities need to be designed in from the start — retrofitting them after
   `motifpath-core`/`motifpath-web` implement a fretted-only, unstyled, static model would be a
   breaking schema change on top of a schema change.

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

**Alternatives considered for multi-instrument position data:**

1. One fixed position shape (`{string, fret, ...}`) with fields left null for instruments that
   don't use them. Rejected: a piano key has no string or fret at all, so every field would be
   null for that family — the shape would be lying about what a keyboard diagram actually is, and
   a client would have to guess which nulls are "not applicable" versus "not yet authored."
2. A polymorphic position shape, discriminated by the `Instrument`'s `family`, where each family
   defines its own coordinate fields. Accepted.

**Alternatives considered for layer selection, styling, and playback:**

1. Store one asset per layer/color/playback combination a teacher wants. Rejected: the same
   combinatorial-growth problem ADR-027 was written to avoid, now multiplied across three
   independent axes of variation instead of one.
2. A render-time configuration object, carried wherever a `Diagram` is used, covering layers,
   styling, and playback together, applied against the single stored `Diagram`. Accepted.
3. (Styling specifically) A fixed, platform-wide interval-to-color mapping, defined once in
   `motifpath-web`'s design system, with no per-usage override. Rejected: doesn't meet the actual
   need — an author distinguishing root from other intervals with colors that fit a specific
   lesson or exercise's intent (e.g., a "spot the blue notes" exercise) needs to choose those
   colors per usage, not inherit one fixed scheme everywhere.
4. (Playback specifically) Infer play order from position layout (e.g., left-to-right,
   low-string-to-high-string). Rejected: this only works for a strictly ascending run. A chord
   voicing, an arpeggio, or any pattern played in an order that doesn't match its visual layout
   has no correct inferred order — the order has to be authored data, not derived geometry.

**Alternatives considered for showing more than one scale/chord pattern together:**

1. Author one `Diagram` covering both patterns, with each position tagged which pattern(s) it
   belongs to. Rejected: `interval` is only meaningful relative to its own `Diagram`'s root — A
   minor pentatonic's `b3` and C major scale's `b3` are different notes, because the two patterns
   have different roots. Merging them into one `Diagram` would force one pattern's positions to
   carry an `interval` value that's wrong relative to its own scale, just to share a row with the
   other pattern's data.
2. No support for showing more than one `Diagram` at once — a teacher who wants to compare two
   patterns exports/screenshots two separate renders. Rejected: relative major/minor comparison
   (and comparing two chord voicings sharing a root) is a common, real teaching pattern, and the
   underlying model already has everything needed to support it — refusing to composite two
   already-correct `diagram_ref`s would be leaving a nearly-free capability on the table.
3. A `diagram_stack_ref` — an ordered list of independently-configured `diagram_ref`s, each
   correct on its own terms, composited at render time. Accepted.

**Alternatives considered for Exercise linkage:**

1. Leave `image_recognition`/`image_choice` as-is (flat `image_url` + hand-drawn `region`) and
   treat `Diagram` as a `ContentNode`-only feature. Rejected: this throws away the strongest
   product win available — a diagram's positions and an `image_recognition` option's region are
   the same shape (a located point/area with a semantic meaning), so building `Diagram` without
   connecting it to `Exercise` options means re-solving "mark a fretboard position" twice, once
   per resource, with two independently-drifting representations.
2. Give `Exercise` options a `diagram_ref` (a `Diagram` id + render config), usable as an
   alternative to `image_url`/`region`, so a diagram-driven option's clickable region is read
   directly from the diagram's own position data — regardless of instrument family. Accepted.

## Decision

### `Instrument` has a `family`, and `Diagram.positions` is polymorphic per family

```
Instrument {
  id: uuid
  name: string                  // "6-string guitar (standard tuning)", "4-string bass", "piano"
  family: "fretted" | "keyboard" // open-ended: a third family is a new value, not a schema change
  // fretted-only: string_count, tuning: string[]   (open-string note per string)
  // keyboard-only: key_range: { lowest: string, highest: string }  (note names, e.g. "A0".."C8")
}

Diagram {
  id: uuid
  instrument_id: uuid
  name: string
  positions: [
    {
      interval: string           // shared by every family: "R", "b3", "4", "5", "b7", ...
      note_name: string
      sequence_index: int | null // authored play order; null = no defined order (see Playback below)
      coordinate: FrettedCoordinate | KeyboardCoordinate   // shape is decided by instrument.family
    }
  ]
  skill_ids: uuid[]              // at least one entry, same tree as ContentNode/Exercise
  concept_ids: uuid[]            // at least one entry, same tree as ContentNode/Exercise
}

FrettedCoordinate { string: int, fret: int }
KeyboardCoordinate { key: string }   // a note name relative to the instrument's key_range, e.g. "C4"
```

`instrument_id` references the `Instrument` a `Diagram` is authored against; `Diagram.positions`'
`coordinate` shape is decided entirely by that instrument's `family`, not repeated per position —
a single `Diagram` cannot mix coordinate shapes internally. Bass and guitar share the `fretted`
family (they differ only in `string_count`/`tuning` on their respective `Instrument` rows, not in
coordinate shape); piano is `keyboard`. `family` is an open enum specifically so a genuinely new
coordinate shape (e.g., a valved brass instrument, if MotifPath ever needs one) is a new family
value plus a new coordinate type, not a schema migration of every existing `Diagram`.

`interval`, `note_name`, and `sequence_index` are shared across every family — they describe
*what* a position means and *when* it plays, independent of *where* it's drawn. `positions` is the
base layer ADR-027's layer system decorates; every other layer (interval labels, subset filters,
shape overlays, styling, playback) is computed from this same list, never stored as a separate
copy of it.

`Diagram` is classified through `skill_ids`/`concept_ids` against the exact same `Skill`/`Concept`
tree `ContentNode` and `Exercise` already use (ADR-026) — not a third, parallel tagging scheme. A
diagram of the A minor pentatonic scale and a `ContentNode` teaching it and an `Exercise` quizzing
it all reference the same `Skill` node, making "what teaches/tests/illustrates this skill" one
query across all three resource types, regardless of which instrument any of them is about.

**Root note is not stored on `Diagram`.** A pattern is authored once as a movable shape
(intervals relative to the pattern's own root), and transposed to a concrete key at the point of
use via the render config's `root_override` — storing a separate `Diagram` row per root/key would
duplicate the same shape twelve times over for no data-model benefit. Transposition math is
instrument-family-specific (shifting frets for `fretted`, shifting keys for `keyboard`) and is
`motifpath-web` rendering work, not decided by this ADR (see Consequences).

### Layers, styling, and playback are a render-time config, never a stored variant

Wherever a `Diagram` is referenced, it's referenced as a `diagram_ref`:

```
diagram_ref {
  diagram_id: uuid
  root_override: string | null    // transposes the pattern; null uses the diagram's own root
  layers: {
    intervals: bool
    subset: string[] | null       // interval names to show; null shows all positions
    shape_overlay: string | null  // e.g. a box outline id; null shows no overlay
  }
  styling: {
    root_color: string | null     // hex/CSS color; null uses motifpath-web's default
    interval_color: string | null // color for every non-root visible position; null uses default
  } | null
  playback: {
    direction: "as_authored" | "reversed"
    step_ms: int                  // time between positions when played
  } | null
}
```

`styling` and `playback` are both optional — a `diagram_ref` with neither set renders exactly as
it did before this revision (default colors, static/no animation), so every existing decision
point in this ADR's first draft is unchanged for a usage that doesn't need them. `styling` is a
flat two-color choice (root vs. everything else), matching the same root/non-root distinction
`positions`' `interval` values already carry — not a per-interval color map, which would be
authoring complexity with no corresponding product need identified yet (see Consequences).
`playback` only has an effect on positions that carry a non-null `sequence_index`; positions
without one are simply not part of the sequence and render statically regardless of `playback`.

The same `Diagram` can be referenced by any number of `diagram_ref`s, each with its own render
config — a `ContentNode` teaching the full pattern with intervals labeled and default colors, and
an `Exercise` quizzing only the root notes highlighted in a lesson-chosen accent color and played
back in sequence, both reference the same underlying `Diagram`. No new `Diagram` row, and no new
stored image, is created for either.

### A usage can stack more than one Diagram in the same coordinate space

Wherever a `diagram_ref` is accepted, a `diagram_stack_ref` is accepted as an alternative:

```
diagram_stack_ref {
  stack: diagram_ref[]   // painted in order — later entries render on top of earlier ones
}
```

Every `diagram_ref` in a `stack` must reference `Diagram`s that share the same `instrument_id` —
stacking a `fretted` diagram under a `keyboard` diagram has no shared coordinate space to composite
into. Each entry in the stack keeps its own `root_override`, `layers`, `styling`, and `playback`,
evaluated independently exactly as a standalone `diagram_ref` would be, then composited into one
drawing. This is how a teacher shows, e.g., the A minor pentatonic scale overlaid on its relative
major (C major) at the same fretboard position: two separately-authored `Diagram`s, each correct
on its own terms, drawn into the same view.

### `ContentNode` and `Exercise` both gain diagram linkage, using the same `diagram_ref` shape

**`ContentNode` body** gains a third variant alongside `media_url` (video) and `rich_content`
(article): `diagram_ref`, which accepts either a single `diagram_ref` or a `diagram_stack_ref`. A
node's body is exactly one of the three — video, article, or diagram — unchanged from the existing
one-of-body-types rule PB-40 established for the first two.

**`Exercise` options** (`image_recognition` and `image_choice` types only, per ADR-019) gain
`diagram_ref` (single or stacked) as an alternative to `image_url`. For `image_recognition`
specifically, when an option is diagram-driven, **the option's clickable region is read directly
from the referenced `Diagram`'s `positions`**, regardless of instrument family — a fretted position
and a keyboard position are both just "one addressable, checkable location" from the exercise's
point of view. A diagram-driven `image_recognition` exercise has no hand-drawn `region` field to
author at all; each position in the diagram (filtered by the render config's `subset`, if set)
becomes one clickable, checkable option automatically. When the option is a stack, positions from
every layer in the stack are checkable, distinguished by which `Diagram` they came from.
`image_url`/`region` remain fully supported, unchanged, for teacher-uploaded custom images —
`diagram_ref` is an addition, not a replacement.

`text_response` and `audio_recognition` option types are unaffected — diagrams are a visual
content mechanism and have no bearing on those types' checking model.

## Rationale

**Structured position data over pre-rendered SVG or flat images** is accepted because it's the
only option that gives ADR-027's layer system something to actually decorate, and the only one
that makes a diagram queryable ("which diagrams mark this interval") rather than an opaque blob.
Storing rendered SVG was the closest alternative, but it re-introduces exactly the
one-asset-per-combination growth ADR-027 was written specifically to avoid.

**A polymorphic, family-discriminated coordinate shape** is accepted over one fixed shape with
nullable fields because a null `string`/`fret` on a piano diagram isn't a missing value, it's a
category error — a piano key was never going to have a fret. Discriminating by `Instrument.family`
keeps every `Diagram` honest about what kind of thing its positions actually are, and keeps the
door open to a genuinely new instrument family later without touching every existing `Diagram`
row. This is the direct, structural fix for the gap the first draft of this ADR shipped with: it
satisfied ADR-027's SVG *rendering* decision without satisfying ADR-027's *multi-instrument*
requirement underneath it.

**A render-time config instead of stored variants — extended to cover styling and playback, not
just layers** — is accepted for the same reason ADR-027 rejected per-combination rendering: a
`Diagram`'s reuse value comes from being shown differently in different contexts without being
copied, and that argument doesn't change just because the axis of variation is a color choice or
a play order instead of a label toggle. Bundling all three into one `diagram_ref` object (rather
than a second and third parallel reference mechanism) keeps "how is this diagram being shown here"
answerable by reading one field, not three independently-evolving ones.

**Playback needs authored `sequence_index` data, not inferred order**, because a diagram's visual
layout and its play order are genuinely different facts — a chord voicing has a play order (if any)
that has nothing to do with left-to-right position, and guessing wrong silently produces a
musically incorrect demonstration. Making `sequence_index` nullable per position, rather than
required, keeps this cheap for the common case (a diagram nobody ever plays back leaves every
`sequence_index` null and pays no authoring cost) while making sequenced playback possible exactly
where an author actually wants it.

**Styling as a flat root/non-root choice, not a full per-interval color map**, is accepted as the
narrowest change that meets the actual request — letting an author pick colors that fit a specific
lesson or exercise — without speculatively building a five-color picker (one per committed
interval value, per ADR-026's classification granularity has nothing to do with diagram intervals)
against no concrete case that needs more than two. Widening `styling` to per-interval colors later
is an additive change to this same object, not a breaking one, if a real case for it shows up.

**Root as a render-time transposition, not stored data**, keeps `Diagram` count proportional to
the number of distinct *shapes* MotifPath teaches (a handful of scale/chord patterns), not shapes
× keys. This mirrors ADR-026's reasoning for classifying by shared skill rather than duplicating
content per surface — one canonical asset, applied in multiple contexts, rather than one asset
per context.

**Linking `Exercise` options to `Diagram`, deriving regions from positions**, is accepted because
it's the actual product win this ADR exists to capture: a diagram position and a clickable
exercise region are the same fact (a located, semantically-named point), and treating them as one
thing means a teacher building an `image_recognition` exercise on a `Diagram` never hand-draws a
region again — the diagram's own data already says where the root note is, on any instrument.
Keeping `image_url`/`region` alongside it, rather than replacing it, is necessary because not
every exercise image is a diagram MotifPath's model can express (a photo of a real guitar, an
unusual chord shape not yet authored as a `Diagram`) — the manual path stays available for content
the structured model doesn't yet cover.

**Not extending `text_response`/`audio_recognition`** is a scope discipline: diagrams are visual
content, and stretching the linkage into non-visual exercise types wouldn't serve any real
authoring case, only add unused fields to two option types that already have a settled shape.

**Compositing independently-authored Diagrams, rather than merging their data**, is accepted
because it preserves the one property that makes any of this queryable or reusable in the first
place: every `Diagram`'s `interval` values stay correct relative to its own root. The
same-`instrument_id` constraint on a stack is accepted because overlaying two patterns only makes
pedagogical sense when they occupy the same physical coordinate space — a fretted diagram and a
keyboard diagram have no shared position to align on, so allowing a cross-family stack would only
produce a composite with nothing actually stacked.

## Consequences

### Positive

- Diagram content is authored once per shape and reused across every `ContentNode` and `Exercise`
  that teaches or tests it, instead of being redrawn as a new image per surface, per instrument.
- `Diagram` correctly models guitar, bass, and piano today, and any further fretted or keyboard
  instrument at zero schema cost — a new instrument in an existing family is just a new
  `Instrument` row.
- Layer, styling, and playback combinations are all free to create at usage time — no
  combinatorial growth in stored assets as more contexts want a different view, color treatment,
  or playback of the same pattern.
- `image_recognition` exercises built on a `Diagram` no longer require hand-drawn regions on any
  instrument's diagram — the diagram's positions are the regions, automatically kept in sync with
  the diagram's own data.
- `Diagram` shares the exact classification vocabulary (`Skill`/`Concept`, ADR-026) that
  `ContentNode` and `Exercise` already use, so "what teaches/illustrates/tests this skill" is one
  query across all three resource types, not three independent lookups.
- A diagram can demonstrate motion (a scale run, an arpeggio) without becoming a video — sequenced
  playback is computed from the same structured data everything else in this ADR already stores.
- Comparing two related patterns (relative major/minor, two chord voicings sharing a root) is a
  composition of two already-correct `diagram_ref`s — no new position data, no new `Diagram`
  authoring, to support a real and common teaching case.

### Negative / Trade-offs

- `Diagram` is a new entity with its own CRUD surface, its own authoring UI (a position editor per
  instrument family, not a freeform image upload), and its own `Instrument` dependency — real new
  authoring-surface cost, not a reuse of an existing pattern. Two coordinate shapes to author
  against (fretted, keyboard) is real UI cost twice over, not once.
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
- Author-chosen `styling` colors are unconstrained (any hex/CSS color), so nothing in this ADR
  stops a color choice that fails contrast or is indistinguishable to a colorblind student — this
  ADR does not add validation for that, and it's real accessibility follow-up work, not a solved
  problem.
- A stack says nothing about how two overlapping positions should look when both layers mark the
  same physical spot — that's a rendering convention (e.g., base dimmed/outlined, overlay solid)
  this ADR leaves to ADR-027's layer system, not decided here. A stack also doesn't reduce
  authoring cost: both `Diagram`s in it must already exist, correctly authored, on their own.
- `root_override`'s transposition math (mapping an authored shape's intervals onto a chosen root,
  per instrument family and tuning/key-range) and `playback`'s timing/animation behavior are both
  real logic that has to live somewhere — this ADR assigns both to `motifpath-web`'s render-time
  layer system (ADR-027), not to the stored data model, but neither is yet designed and both are
  real follow-up work, now for two instrument families instead of one.

### Neutral

- `Instrument` as a separate entity from `Diagram` is a small additional schema surface, but
  avoids re-declaring tuning/string-count/key-range on every diagram — a `Diagram` authored
  against the wrong `Instrument` is a possible authoring error this ADR doesn't add validation
  against beyond the foreign-key reference itself.
- This ADR does not decide the position-editor authoring UI (how a teacher actually creates a
  `Diagram`'s `positions` array, for either family) — that's `motifpath-web` implementation work
  informed by ADR-027's rendering model, not a data-model question this ADR needs to settle.
- Real-time audio-synced highlighting (PB-8f) is a different capability from `playback`'s
  authored, fixed-tempo sequence — ADR-027 already routed that use case to Canvas specifically
  because of its different performance profile. `playback` as decided here stays in the SVG/DOM
  model and does not attempt to solve PB-8f's synchronization problem.
- **Revisit trigger:** if a real need emerges for a diagram whose positions vary by root in a way
  simple transposition can't express (e.g., an irregular chord voicing that isn't a fixed interval
  shape), or for per-interval (not just root/non-root) styling, or for a third instrument family,
  either is a new ADR or an additive change to this one's `diagram_ref` shape, evaluated when the
  concrete case shows up.

## Related ADRs

- **ADR-027** (SVG rendering for layered diagrams) — this ADR's `positions` data and `diagram_ref`
  render config are exactly the input ADR-027's rendering/layering approach consumes; ADR-027
  decides *how* a `Diagram` is drawn, this ADR decides *what* a `Diagram` is and how it's stored,
  selected, and linked. ADR-027's multi-instrument requirement (evidenced via `react-chords`
  spanning guitar/ukulele/piano) is what this ADR's polymorphic `family` model exists to satisfy.
- **ADR-026** (Content classification graph) — `Diagram.skill_ids`/`.concept_ids` reuse this ADR's
  `Skill`/`Concept` tree directly, rather than introducing a fourth classification mechanism
  alongside `ContentNode`, `Exercise`, and `Challenge`.
- **ADR-019** (Practice content model) — `Exercise`'s `image_recognition`/`image_choice` option
  shape is extended here with `diagram_ref`; the many-to-many Challenge relationship,
  option-selection checking model, and all five committed exercise types are otherwise unchanged.

## Follow-up work (not part of this ADR)

- OpenAPI schema for `Instrument` (with its `fretted`/`keyboard` family discriminator), `Diagram`
  (with its polymorphic `coordinate` shape), and the `diagram_ref` shape (layers/styling/
  playback), plus Gherkin scenarios covering diagram creation for both families, render-config
  selection, and diagram-driven `image_recognition` answer-checking — required before
  `motifpath-core` implementation begins, per this repo's spec-first discipline.
- `motifpath-core`: `Diagram`/`Instrument` ent schemas (including the polymorphic coordinate
  storage), `ContentNode.body` and `Exercise` option schema changes, and the `image_recognition`
  answer-checking path for diagram-derived regions.
- `motifpath-web`: the `Diagram` position-editor authoring UI (per instrument family), the
  ADR-027 layer-system renderer consuming `diagram_ref` (layers, styling, and playback), and the
  root-transposition logic flagged as unresolved above, for both instrument families.
- Accessibility guidance/validation for author-chosen `styling` colors (contrast, colorblind-safe
  defaults) — flagged as a real gap above, not designed here.
- A rendering convention for overlapping positions within a `diagram_stack_ref` (which layer wins
  visually, how a dimmed/outlined base layer is styled by default) — an ADR-027-level rendering
  question, not decided here.
- A first content pass: author the initial library of common scale/chord `Diagram`s per
  instrument (starting with the minor pentatonic guitar pattern used in the ADR-027 spike) once
  the schema and renderer exist.

---

*This ADR was decided on 2026-09-20. To revise, create a new ADR with Status: Supersedes
ADR-028.*
