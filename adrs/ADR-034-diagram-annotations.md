# ADR-034: Diagram annotations — custom marker labels, marker notes, and highlighted regions, all localized

**Status:** Accepted
**Date:** 2026-09-24
**Deciders:** Gilson (Product Owner)
**Amends:** ADR-028's `Diagram`/`DiagramPosition` model (additive only). It builds on ADR-033's
per-language text rules.

---

## Context

A diagram can currently say only two things about a marker: its interval or its note name
(`label_display`), plus its colour and shape. Teaching material regularly needs more:

- **Modal scales mark notes by role, not by interval.** An "avoid note" or a "characteristic"
  (highlighted) note is a teaching category that neither the interval nor the note name expresses.
  Authors want a short custom label *inside* the marker.
- **Some markers deserve an explanation.** Examples: "slide into this note from a fret below",
  "this b5 is the blue note", "pivot finger for the shift". This is a short tip attached to one
  marker, too long to fit inside it.
- **Joined shapes need their parts shown.** When two consecutive pentatonic shapes are joined into
  one diagram (often by flattening a stack, ADR-032), the teacher wants the fret range of each
  original shape highlighted and captioned ("Shape 1", "Shape 2"). Otherwise the student sees one
  undifferentiated cloud of markers.

All three carry words, so all three must work in every language the diagram supports (ADR-033).

## Decision

### Custom marker label

`DiagramPosition` gains `custom_label`: a per-language text map (ADR-033's shape) whose values are
**at most 2 characters**, so they fit inside a marker (for example `{"en": "Av", "pt_BR": "Ev"}`).
When a position has a `custom_label`, the marker shows it **instead of** the interval or note name
chosen by `label_display`. When `label_display` is `hidden`, no label is shown at all, custom
included. Positions without a `custom_label` behave exactly as today.

### Marker note

`DiagramPosition` gains `note`: a per-language text map, each value **at most 280 characters**. In
`motifpath-web`:

- **Pointer devices:** hovering or keyboard-focusing the marker shows the note in a tooltip.
- **Touch devices, and for discoverability everywhere:** a marker with a note shows a small
  indicator badge. Tapping the badge (or the marker) opens the note in a popover, and tapping
  elsewhere closes it.

The note is readable content, not decoration. It is exposed to screen readers as the marker's
description.

### Highlighted regions

`Diagram` gains `regions`: an ordered list of highlighted areas, each with a short caption.
Coordinates follow the instrument family, like positions do:

```
DiagramRegion {
  region_id                // server-assigned when omitted, like position_id
  fret_start, fret_end     // fretted: inclusive fret range, fret_start <= fret_end
  string_start, string_end // fretted, optional: inclusive string range; omitted = all strings
  key_start, key_end       // keyboard: inclusive key range (e.g. "C4".."B4")
  description              // per-language text map, each value at most 60 characters
  color                    // optional #RRGGBB from the fixed palette; null = default tint
}
```

Regions render as translucent bands behind the markers, with each description shown alongside its
band. Regions may overlap, because consecutive shapes share frets. The overlap simply renders both
tints.

**Flattening (ADR-032) carries regions over.** Each layer's regions are copied into the new diagram
unchanged, with the same top-layer-wins order. Coordinates are physical, so nothing needs
recomputing. The flattened diagram takes the **base layer's languages**. Overlay text in a
language the base lacks is dropped. Where an overlay lacks one of the base's languages, the editor
flags that language's tab as incomplete (see below), and the teacher fills it in before saving.
**Flattening offers one region per layer, after confirmation.** When a teacher saves a stack, the
save step asks whether to add a highlighted region for each stacked diagram. The option is
pre-selected and the teacher can decline it. Each generated region:

- spans that layer's own positions: its lowest to highest fret across all strings (fretted), or its
  lowest to highest key (keyboard);
- uses the layer's names as its description, pre-filled per language. A name longer than the
  60-character limit is flagged for the teacher to shorten before saving;
- uses the layer's general colour, or the default tint when the layer has none.

Generated regions are ordinary regions, and the teacher can edit or remove any of them in the
editor before or after saving. They are added alongside any regions the layers already carried
over.

### Every piece of diagram text follows one language rule

ADR-033 derives a diagram's `languages` from its `names`. Every other per-language text on that
diagram (`custom_label`, `note`, region `description`) that is present must have a value for
**exactly those languages**, no more and no fewer. A diagram with an English and a Portuguese name
cannot carry an English-only note. A create or update that breaks this is refused with 400, naming
the offending field. This keeps ADR-033's guarantees (basic templates complete in every language,
custom diagrams complete in their own) true for all diagram text, not just the name.

### Authoring: one form per language

The diagram editor keeps coordinates, shapes, colours and region ranges language-independent. It
edits all per-language text (name, custom labels, notes, region descriptions) in **one tab per
language of the diagram**. A tab with missing text is flagged, and saving is blocked until every
tab is complete, mirroring the server rule. Adding or removing a language adds or removes a tab.

### Amendment (2026-09-25) — the language tab sets the editor's language

Local testing of ADR-033's first name UI (one large name field for the author's UI language, plus
one smaller "Name (Portuguese)" field for each other language) showed that it hid which languages a
diagram supports and mixed languages in one form. The product owner refined the tabbed editor
above:

- **The author chooses the diagram's languages explicitly.** A language bar at the top of the
  editor holds one tab per language, each shown as a flag plus a short code (🇺🇸 EN, 🇧🇷 PT), and a
  **+** to add a language. A new custom diagram starts with the author's UI language. Removing a
  language from a custom diagram asks for confirmation and drops that language's text. A basic
  template always carries every language, so its tabs can't be removed.
- **The active tab sets the language of the whole editor**, as if the author had changed their
  language setting: the form's labels and hints, the single name field (for that language only),
  the interval notation on the markers and the position list (`R`/`b3` in English, `T`/`3m` in
  Portuguese, ADR-033), and the preview. Each language gets its own complete view of the diagram
  as a student in that language will see it.
- **The switch is scoped to the editor.** The app bar (breadcrumb, Save, Save as) and navigation
  stay in the author's own UI language, because they act on the whole diagram rather than on one
  language, and the author's language setting is never changed.
- A tab with missing text shows a warning dot, and saving stays blocked until every tab is complete,
  as above.

This changes no API: `languages` is still derived from `names` (ADR-033). It lands in
`motifpath-web` with ADR-033's name editing, before the rest of ADR-034's web work.

## Rationale

**The custom label overrides rather than joins the interval/note label**, because a marker only
fits about two characters. Showing both would shrink every label. An author who writes a custom
label has decided that this marker's role matters more than its interval. **Per-language custom
labels**, rather than a single language-neutral symbol set, were chosen because the
abbreviations are words ("Av" for *avoid*, "Ev" for *evitar*). A fixed symbol enum (like ADR-033's
interval codes) was rejected because the useful categories are open-ended and teacher-specific.

**Notes on hover plus a tap badge** was chosen over hover only, which is invisible on phones, the
platform's main student device. It was also chosen over always-visible text, which would clutter a
diagram whose whole point is a clear spatial pattern.

**Regions as fret/key ranges with optional string bounds**, rather than free-form shapes, match
how teachers actually describe positions ("frets 5 to 8"). They also render and validate simply,
and survive flattening untouched because they're physical coordinates. Free-form polygons were
rejected as authoring-heavy for no current need.

**One exact-languages rule for all diagram text**, rather than letting each field choose its own
languages, is what makes "this diagram supports pt-BR" a single, checkable fact. Otherwise a
Portuguese student could open a diagram whose name is translated but whose notes are English.

## Consequences

### Positive

- Modal teaching (avoid and characteristic notes), fingering tips and joined-shape explanations
  can be authored directly on the diagram instead of in surrounding article text.
- All new text is localized under one rule, so a diagram's language support stays one reliable
  property.
- Regions make flattened stacks (ADR-032) readable again. Each original shape is shown and named
  by default, with one confirmation step.

### Negative / Trade-offs

- **More authoring work per language.** Every note and region description must be written in every
  language of the diagram, and for basic templates that means every platform language. That is
  deliberate, but it is real effort.
- **Two-character labels are tight.** Some abbreviations won't fit in some languages, and authors
  will have to invent short forms.
- **Adding a platform language** now also makes every basic template's labels, notes and region
  descriptions incomplete, not just its name (the same write-time-only enforcement as ADR-033).
- **Breaking API change**, bundled with ADR-032/ADR-033's: new fields and new validation on
  `Diagram` and `DiagramPosition`.

### Neutral

- Exercises that derive clickable options from a diagram's positions (ADR-028) are unaffected.
  Notes and regions are presentation, not checkable options.
- A `diagram_ref`'s render-time `layers` config can later toggle notes and regions per embedding,
  but that is not decided here.

## Related ADRs

- **ADR-028** (Prebuilt diagram content model): the entities this ADR extends.
- **ADR-032** (Diagram templates and copies): flattening carries regions over. Save as copies
  annotations like any other field.
- **ADR-033** (Diagram localization): the per-language text shape and the languages-from-names
  rule this ADR extends to every diagram text.

## Follow-up work (not part of this ADR)

- `motifpath-specs`:
  - `DiagramPosition.custom_label`/`note` and `Diagram.regions`/`DiagramRegion`, with length
    limits.
  - The exact-languages 400 rule, and Gherkin coverage for each.
- `motifpath-core`:
  - Storage for position annotations and a regions table, plus validation (lengths, ranges,
    family-matching coordinates, the exact-languages rule).
- `motifpath-web`:
  - Custom-label rendering and override precedence.
  - Note tooltip, badge and popover (accessible).
  - Region bands and captions in `FrettedDiagramView`, and a region editor.
  - Per-language tabs in the diagram editor (delivered early with ADR-033's name editing; see the
    2026-09-25 amendment).
  - `flattenDiagramStack` carrying regions over and generating the optional per-layer regions,
    with the confirmation option in the stack save step.

---

*This ADR was decided on 2026-09-24. To revise, create a new ADR with Status: Supersedes ADR-034.*
