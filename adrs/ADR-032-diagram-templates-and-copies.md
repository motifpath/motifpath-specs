# ADR-032: Diagrams are basic or custom templates with an owner — "Save as" copies, and stacks flatten into a new Diagram

**Status:** Accepted
**Date:** 2026-09-24
**Deciders:** Gilson (Product Owner)
**Supersedes:** two parts of ADR-028: its implicit "any teacher or admin may edit any diagram"
rule, and its rule that a stack "can't be merged into one `Diagram` row". It also relaxes
`DiagramPosition`'s invariant that every position's interval is relative to its parent
`Diagram.root_note`, and only for diagrams produced by flattening a stack. ADR-028's
`diagram_stack_ref` render-time compositing is unchanged and remains Accepted.

---

## Context

ADR-028 made `Diagram` a reusable library entity, but every diagram in the library is equal. It has
no author and no kind, any teacher or admin may update any diagram, and `GET /diagrams` returns the
whole library, unpaginated, to any authenticated user. That was fine while diagrams were only
seeded, but it doesn't fit how diagram authoring is now expected to work:

- **Some diagrams are curated basic templates**: the canonical major scale, the five pentatonic
  positions, and similar. Every teacher should be able to use them, but only an admin should be
  able to change them. Today any teacher can overwrite one for everybody.
- **Teachers adapt templates rather than start from scratch.** A teacher opens a template (or one
  of their own diagrams), edits it, and saves the result as a new diagram, like a word processor's
  "Save as". The source must stay untouched.
- **Teachers compose patterns by stacking.** They overlay one diagram on another (a minor
  pentatonic on its relative major) and keep the composite as a diagram of its own. ADR-028 only
  allows stacks at render time (`diagram_stack_ref`) and rules out merging one into a single
  `Diagram` row, because every position's interval is relative to its own diagram's root.
  `motifpath-web` has no stacking UI at all yet.
- **The diagram selector needs to scale with custom diagrams.** A teacher should see the basic
  templates plus their own custom diagrams, not every other teacher's. An admin sees everything and
  can narrow by author. `GET /courses` already implements this role-scoped `created_by` filter
  (ADR-029/ADR-031).

## Decision

### Every diagram is a basic or a custom template, with an owner

`Diagram` gains `kind` (`basic` | `custom`) and `created_by` (the creating user's id). Neither can
be changed after creation.

- **basic**: curated, available to everyone. Only an admin may create or update one.
- **custom**: created by a teacher or admin. Only its creator or an admin may update it.

`POST /diagrams` takes `kind`, which defaults to `custom`, and sets `created_by` to the caller. A
non-admin asking for `kind: basic` is refused with 403. `PUT /diagrams/{id}` applies the ownership
rule above and returns 403 otherwise.

`created_by` is required on every diagram. Diagrams that exist before this change are migrated to
`kind: basic` with `created_by` set to the **zero user**: the platform's bootstrap admin, which
`seed-full` creates from `ADMIN_CLERK_USER_ID` (PB-32). That user has no fixed id, so the migration
resolves it as the earliest-created user with the `admin` role. If diagrams exist but no admin does,
the migration fails with a clear error rather than inventing an owner. A fresh database has no
diagrams, so nothing needs backfilling there. `seed-full` creates its seeded diagrams as `basic`,
owned by the zero user.

### "Save as" copies; stacking is "Save as" with overlays

Neither operation ever modifies a source diagram. Both create a new diagram through the existing
`POST /diagrams`, composed on the client from what the editor currently shows. There is no copy
endpoint, and the new diagram records no link to its sources.

- **Save as…** (teachers and admins) creates a `custom` diagram owned by the caller.
- **Save as template…** (admins only) creates a `basic` diagram.
- When the caller may not update the diagram open in the editor (a basic template for a teacher,
  or another teacher's custom diagram for an admin viewing it), in-place Save is unavailable. Only
  Save as and, for admins, Save as template are offered.

**Stacking.** In `DiagramAuthoringView`, an "Overlay diagram…" action adds any diagram the caller
can see with the same `instrument_id` as a read-only layer drawn on top of the one being authored.
Overlays are transient authoring state and are never persisted as a stack. Saving while overlays
are present (Save as, or Save as template) flattens the base and every overlay into one position
list. The layers are applied bottom-to-top: the base first, then overlays in the order they were
added.

- **Positions keep their own `interval`, `note_name` and `shape`**, and their ADR-034 annotations
  (custom label and note). Layers' highlighted regions carry over too (ADR-034). Intervals are not recomputed
  against the new diagram's root.
- **Colour is resolved into each position**: its own `color`, falling back to its layer's general
  `Diagram.color`, and null if both are unset. Each layer keeps its visual identity.
- **Overlaps: the top layer wins.** When two layers mark the same physical location (same `string`
  + `fret` for fretted, same `key` for keyboard), only the position from the layer painted last is
  kept. This matches ADR-028's "later entries render on top".
- **`sequence_index` keeps each layer's authored order.** The base's indices are kept. Each
  overlay's non-null indices are offset past the highest index already present, and null stays
  null.
- **`position_id` is left for the server to assign.**
- **Diagram-level fields default from the base and stay editable before saving.** These are
  `root_note`, `label_display` and the general `color`. `classification` defaults to the union of
  every layer's skills and concepts.

In a flattened diagram, a position's `interval`/`note_name` are therefore relative to the root of
the layer it was authored in. For every other diagram that is still `Diagram.root_note`.

### Amendment (2026-09-26) — overlays flatten on an explicit "Merge layers" step

Planning the web slice showed that flattening inside Save as can't satisfy ADR-034. When an
overlay lacks one of the base's languages, the teacher has to fill that text in before saving,
so the flattened result must be editable first. The product owner refined the stacking flow
above:

- **Overlays stay read-only until an explicit "Merge layers" action.** While overlays are present
  and not merged, every save action is unavailable, so a teacher never saves the base alone while
  looking at a stack. Merging opens a confirmation that carries ADR-034's "add a highlighted region
  for each diagram" option, pre-selected. The merge then applies the flattening rules above and
  loads the result into the editor as ordinary positions and regions, which the teacher can edit
  like any others.
- **Overlays work on any base, saved or not.** After a merge onto a diagram loaded from the
  server, in-place Save is withheld and only Save as (and, for admins, Save as template) is
  offered, so a source diagram is never modified. After a merge onto a new, unsaved diagram, the
  plain Save creates it, since there's no source to protect.
- **A merge can't be undone in the editor.** The source diagrams are untouched, so reopening the
  base recovers it.
- **An explicit root-note change after a merge recomputes every position**, merged ones included.
  This narrows "intervals are not recomputed" above: the merge itself never recomputes, and each
  position keeps its own layer's labels until the teacher deliberately picks a new root for the
  whole diagram. That pick rewrites every interval and note name relative to the new root, as it
  does for any diagram. It was chosen over locking the root after a merge, or recomputing only
  positions placed afterwards, because a root pick has one meaning everywhere in the editor. The
  cost is that one pick can overwrite what an overlay's author meant, and the teacher sees the new
  labels on screen before saving.

This changes no API. Flattening still composes the new diagram on the client and saves through
`POST /diagrams`.

### The diagram selector is role-scoped, filterable and paginated

`GET /diagrams` becomes available to teachers and admins only (403 for students, who never browse
the library). It is paginated in ADR-031's `{items, total, limit, offset}` envelope, ordered by
name, then id.

- A **teacher** sees every `basic` diagram plus their own `custom` diagrams. `kind=basic` narrows
  to templates and `kind=custom` to their own. Passing a `created_by` other than their own user id
  is refused with 403, mirroring `GET /courses`.
- An **admin** sees every diagram. They may filter by `kind` and by any `created_by`.
- The existing `instrument_id`, `skill_id` and `concept_id` filters are unchanged and combine with
  AND.

`GET /diagrams/{id}` stays readable by any authenticated user, because students render diagrams
embedded in content they study. The scoping above governs discovery, not access to a known id.

## Rationale

**`kind` plus `created_by` on `Diagram`**, rather than a separate template library (such as a
`DiagramTemplate` entity copied into a teacher's own `Diagram` rows), keeps one entity that every
consumer (exercises, `PromptNode`, `ExpandedContent`, the editor) already handles. "Basic" and
"custom" differ only in who may change them and who can find them, which are authorization and
query concerns rather than different data shapes. The ownership rule deliberately matches courses
("creator or admin"), so authors meet one mental model across content types.

**Making `kind` immutable and promoting through "Save as template"**, rather than letting an admin
flip a custom diagram to basic in place, keeps a teacher's diagram from changing hands under
them. It also keeps "admin-only" a property of creation, not something a later update can bypass.

**Composing copies and flattened stacks on the client** and saving through `POST /diagrams`, rather
than adding `POST /diagrams/{id}/copy` or `POST /diagrams/stack`, was chosen because
`CreateDiagramRequest` already carries everything the result needs, and every field a flattened
position needs is already per-position. The editor must show the copy or the flattened result
before saving anyway, so the client needs the merge logic regardless. A server endpoint would
duplicate it, not replace it.

**Flattening into an independent diagram** was chosen over persisting the stack (a `DiagramStack`
entity or a stored `diagram_stack_ref` on `Diagram`). A stored stack would preserve ADR-028's
per-root interval invariant. It would also add a second kind of thing to every consumer, and it
could not be edited position by position, which is the point of the feature.

**Top layer wins** was chosen over "bottom layer wins" and over a per-conflict prompt, because it
is what the teacher already sees on screen. **Not recomputing intervals** was accepted because
recomputing them would rewrite what the author meant: a pentatonic layer's "R" on A would become
"6" relative to C.

**Role-scoped listing** copies `GET /courses`' `created_by` rule rather than inventing a
diagram-specific one. **Pagination** was added now, not later, because custom diagrams make the
library grow with every teacher. ADR-031 already made paginated lists the norm for content, so an
unpaginated `GET /diagrams` would be the outlier.

## Consequences

### Positive

- Curated templates can't be overwritten by a teacher, and every teacher still starts from them.
- Adapting and composing diagrams needs no new endpoint. `POST /diagrams` covers new, Save as,
  Save as template and flattened stacks.
- Teachers' selectors stay focused on templates plus their own work. Admins keep full oversight
  with an author filter.
- The overlay action also gives teachers a stack preview they never had before, even when they
  don't save it.

### Negative / Trade-offs

- **Breaking API change.** `GET /diagrams` moves from a bare array to the paginated envelope and
  refuses students. `Diagram` gains required `kind`/`created_by`. The only caller today,
  `motifpath-web`'s `useListDiagrams`, must move with it.
- **A flattened diagram's interval labels are no longer guaranteed to be relative to its
  `root_note`**, and nothing stored marks a diagram as flattened. A `diagram_ref`'s `root_override`
  shifts every position by the same amount but leaves each authored interval label in place.
- **No link from a copy to its source.** Later corrections to a basic template don't reach the
  custom copies made from it, and "which diagrams were built from this template" can't be answered.
- **Top layer wins silently drops the lower layer's position** at every overlap. The teacher has to
  notice it on screen.
- **Copy and flatten rules live only in `motifpath-web`.** A second client would need to
  re-implement them, or the rules would need to move behind an endpoint.
- **Migrated diagrams are attributed to the zero user**, not to whoever actually authored them.
  That matches reality today, since every existing diagram was seeded, but the attribution is a
  convention rather than a record. The migration also depends on an admin row existing wherever
  diagrams already do.

### Neutral

- A custom diagram's id is readable by any authenticated user who has it. That is required for
  students to render embedded content, and it means a custom diagram is private from discovery,
  not secret.
- `diagram_stack_ref` render-time compositing (ADR-028) remains the way to keep a stack live, with
  each layer tracking its source.

## Related ADRs

- **ADR-028** (Prebuilt diagram content model): this ADR adds ownership to its `Diagram`, and
  relaxes its no-merge stack rule and per-root interval invariant for flattened diagrams.
- **ADR-029 / ADR-031** (Course catalog; offset pagination): the `created_by` scoping and the
  pagination envelope reused here.
- **ADR-034** (Diagram annotations): custom labels, notes and regions, which Save as and flattening
  carry over.
- **ADR-033** (Diagram localization): decided alongside this one. It makes interval labels
  language-independent and requires a basic template to carry a name in every language.
- **ADR-027 / ADR-030**: overlays render through ADR-027's SVG layers, and a copy or flattened
  diagram embeds through `PromptNode`/`ExpandedContent` like any other.

## Follow-up work (not part of this ADR)

- `motifpath-specs`:
  - `Diagram.kind`/`created_by`, `CreateDiagramRequest.kind`, and the 403 rules on create and
    update.
  - Pagination, `kind`/`created_by` filters and the student 403 on `GET /diagrams`.
  - Reworded `DiagramPosition.interval`/`note_name` and `Diagram.root_note`.
  - Gherkin coverage for each of the above.
- `motifpath-core`:
  - Schema and migration (existing rows become `basic`, owned by the zero user), and the authorization
    rules.
  - Scoped, paginated list query. Seed data marks the seeded diagrams as `basic`.
- `motifpath-web`:
  - Save as and Save as template, and hiding in-place Save when the caller can't update.
  - The Overlay diagram picker (same instrument), read-only overlay layers in
    `FrettedDiagramEditor`, and a pure `flattenDiagramStack` utility.
  - The paginated, kind/author-filtered selector.

---

*This ADR was decided on 2026-09-24. To revise, create a new ADR with Status: Supersedes ADR-032.*
