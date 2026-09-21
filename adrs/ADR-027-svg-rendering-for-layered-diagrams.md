# ADR-027: SVG as the rendering approach for layered instrument diagrams

**Status:** Accepted
**Date:** 2026-09-20
**Deciders:** Gilson (Product Owner)

---

## Context

This formalizes a decision reached during a PB-8j spike that was never committed as an ADR — the
decision was acted on informally, but no record of it exists anywhere in `motifpath-specs` until
now. PB-57 (prebuilt diagram content architecture, see ADR-028) depends directly on this decision,
which is the reason it's being written down at this point rather than left undocumented any
longer.

The spike's question was how to render instrument diagrams — starting from the concrete case of a
fretboard scale/chord diagram — that need to support **composable layers**: a base pattern (which
strings/frets are marked), interval labels, a subset filter (show only some of the marked
positions), and shape overlays (e.g. a box outlining a scale pattern). The same diagram needs to
render this layer combination differently depending on context (a `ContentNode` teaching the full
pattern vs. an `Exercise` asking the student to identify only the root notes within it), and the
approach needs to generalize beyond guitar to other fretted and non-fretted instruments
(ukulele, piano) without a per-instrument renderer.

The spike built the same diagram (an A minor pentatonic scale, frets 5–8) three separate ways to
evaluate this:

| Approach | Assessment |
|---|---|
| CSS Grid/DOM | Fastest to build initially, but assumes a rectangular grid — breaks for curved instrument bodies or non-fretted layouts (e.g. piano keys). |
| Canvas | Better suited to per-frame redraw performance, but requires hand-rolled layer redrawing logic and a separate accessibility fallback, since a canvas has no addressable DOM structure. |
| SVG | Crisp at any zoom level with no devicePixelRatio scaling workaround; each layer element is individually stylable/animatable via CSS; native DOM elements permit per-note ARIA labels. |

Two existing libraries were reviewed as evidence, not as a build-vs-buy decision: `svguitar`
(MIT, SVG-based) proved out crisp fretboard rendering but is guitar-only with no layering support;
`react-chords` (SVG-based) proved the more important point — that one SVG-based data model can
generalize across fretted and keyboard instruments (guitar, ukulele, piano) from a single
component shape. `alphaTab` (a full notation engine) was reviewed and deferred — it solves a much
larger problem (full music notation) than diagram layering needs, and PB-8f's requirements
(real-time audio-synced highlighting) aren't settled enough yet to justify adopting it now.

## Decision

**SVG is the rendering approach for layered instrument diagrams.** Canvas is reserved for a
separate, later use case — PB-8f's real-time audio-synced highlighting, which has different
performance characteristics (per-frame redraw) than a mostly-static diagram with a few toggleable
layers.

The layer system is built so that base pattern, interval labels, subset filters, and shape
overlays are all **attributes on existing SVG elements**, not separate renderers or separate
rendered outputs per layer combination. A diagram with different layers turned on is the same
underlying markup with different attributes/classes applied — never a distinct asset generated or
stored per combination.

## Rationale

**CSS Grid/DOM is rejected** because its rectangular-grid assumption doesn't survive the
multi-instrument requirement — a curved instrument body or a non-fretted layout (piano) has no
natural grid to lay elements into, which would force a second, incompatible rendering path the
moment a second instrument type is added.

**Canvas is rejected for this use case** (not rejected outright — it's the right tool for PB-8f)
because layer composability and accessibility are the two things this spike actually needs, and
canvas is weak at both: redrawing layers by hand duplicates logic SVG gets from CSS for free, and
a canvas has no DOM nodes to attach ARIA labels to, so accessibility would need a fully separate
fallback rendering.

**SVG is accepted** because it wins on all four dimensions that matter for this use case — visual
quality, layer composability via CSS, accessibility via real DOM elements, and proven
multi-instrument extensibility via `react-chords` — without requiring a different renderer per
instrument type or per layer combination.

Attributes-on-existing-elements (rather than a distinct rendered artifact per layer combination)
is the design choice that makes the "composable layers" requirement actually cheap: a client
toggles a layer by changing which attributes/classes are applied to the same markup, not by
requesting or generating a different asset.

## Consequences

### Positive

- One rendering approach covers fretted and non-fretted instruments alike, with no per-instrument
  special case.
- Layer combinations are free at render time — no combinatorial growth in stored or generated
  assets as more layer types are added.
- Native DOM/ARIA support means diagram accessibility doesn't need separate design work later.

### Negative / Trade-offs

- SVG-in-DOM diagrams are more expensive to redraw at high frequency than canvas would be — this
  is an explicit, accepted limitation for the diagram use case, not a gap: PB-8f's real-time
  audio-synced highlighting is routed to canvas specifically because this trade-off doesn't work
  for it.
- No off-the-shelf library covers this exactly (`svguitar` lacks layering, `react-chords` isn't a
  drop-in for MotifPath's data model) — the layer system itself is custom-built motifpath-web
  work, not adopted wholesale from a dependency.

### Neutral

- `alphaTab` remains a candidate worth revisiting specifically for PB-8f once its requirements are
  settled — this ADR does not rule it out for that separate use case, only defers it.

## Related ADRs

- **ADR-028** (Prebuilt diagram content architecture) — depends directly on this decision: the
  data model ADR-028 defines is designed to be rendered by the layer system this ADR describes,
  and doesn't itself decide anything about rendering technology.

---

*This ADR was decided on 2026-09-20. To revise, create a new ADR with Status: Supersedes
ADR-027.*
