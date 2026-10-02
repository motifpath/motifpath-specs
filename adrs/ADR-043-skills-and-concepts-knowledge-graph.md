# ADR-043: Skills and concepts form one localized knowledge graph

**Status:** Accepted
**Date:** 2026-10-01
**Deciders:** Gilson (Product Owner)
**Revised:** 2026-10-01, in review. `prerequisite_of` ("learn this first") is replaced by `requires`
with a mastery level, between any two nodes, skills and concepts alike. One vertical relation can't
express that improvising needs fluency in scale positions; a leveled, cross-branch dependency can.
**Revised:** 2026-10-02, decided by Gilson after challenging the spec with the electric-guitar
research map. Three changes:
- Nodes carry an instrument scope.
- The reviewed map is production reference data installed by migration, replacing "no migration".
- `applies` stays independent of `requires`.

Same day, after a second research pass on electric bass and acoustic guitar/violão:
- The map covers three instruments.
- A `requires` edge counts per instrument.
- The reference data is installed in a fixed order on a database recreated from empty.
**Partially supersedes:** ADR-026's model of Skill and Concept as two separate trees with a single
`name` string, and its rule that no prerequisite relation exists. Everything else in ADR-026 stands:
content, exercises and diagrams referencing nodes by id; a challenge's subject; the five difficulty
levels; and the remediation rule.
**Retires:** the unused `TaxonomyNode` and `TaxonomyEdge` schemas in `openapi/components/schemas/`.

---

## Context

ADR-026 made Skill and Concept first-class entities: two trees (`parent_id`), each node with a single
`name` described as a "short kebab-case tag". Lessons, exercises and diagrams link to any number of
skills and concepts. Practice-session discovery (PB-22) and the skill-centred home dashboard it
calls for exposed four problems with that model:

1. **Names can't be translated.** A node has one `name` string. ADR-036 set the rule for
   platform-wide catalog data (a `names` map with every language required on write), but left
   skills and concepts for later. The convention isn't followed either: the spec says kebab-case
   tags, and the seed data uses Title Case ("Scales", "Open chord shapes"). Students would see
   whichever string an author typed, in one language.
2. **Skills and concepts aren't linked.** "Improvise over a blues" uses the minor pentatonic scale
   and the blues form, but nothing records it. Each piece of content tags skills and concepts
   independently, so the platform can't explain why a student is learning a concept, roll concept
   knowledge up from skill practice, or find practice for a concept.
3. **Nothing records what a skill or concept depends on.** To improvise over a blues, a student
   needs to be fluent in pentatonic positions, hear licks and phrase. Those live in other branches,
   and the dependency carries a level ("fluent", not just "seen"). One vertical relation can't hold
   that, and forcing it into the tree leads to placement questions with no right answer (does
   "Arpeggios" belong under Fretboard or Improvisation?). The practice-session composer needs
   these dependencies for "stretch" items (PB-22), and recommendations (PB-8g) need the same
   backbone. ADR-026 deliberately added no such relation.
4. **Nodes can't be corrected.** There is no update or delete endpoint, so a misplaced or misnamed
   node is permanent.

The specs also carry an earlier knowledge-graph design, `TaxonomyNode` and `TaxonomyEdge`. It has
five node types (concept, skill, shape, resource, repertoire) and six edge types, with an AI-review
lifecycle. Nothing implements or references it. It treats content (resources, repertoire) as graph
nodes, which would duplicate every content table inside the graph.

The data is small: about 7 skills and 10 concepts, all roots, in seed data only, and there is no
production database. Changing the model now costs a reseed. Changing it after content authoring at
scale would mean migrating every classification.

Alternatives considered:

1. **Keep two trees and add a skill–concept join table, plus a `names` map.** Fixes problems 1 and
   2, but each new relation (prerequisites first) needs another bespoke table, and a later "order of
   learning" across kinds (a concept that must come before a skill) has nowhere to live.
2. **Adopt the old `TaxonomyNode`/`TaxonomyEdge` design as written.** Expressive, but it makes
   content into graph nodes (duplicating lessons, exercises and songs as nodes kept in sync with
   their own tables), and its free `part_of` edge allows several parents.
3. **A graph database.** Unnecessary at thousands of nodes. Recursive queries in Postgres cover
   subtrees, ancestors and paths, with no new infrastructure.
4. **One graph in Postgres: typed nodes, a strict tree, and a small set of typed edges.** Chosen.

## Decision

**MotifPath will model skills and concepts as one knowledge graph in Postgres: `KnowledgeNode`
rows of kind `skill` or `concept`, a strict `part_of` tree within each kind that says where a node
lives, and typed edges that say what it uses (`applies`) and what it needs, and how well
(`requires`, with a mastery level). Content keeps its own tables and links to nodes as it does
today.**

### Nodes

```
KnowledgeNode {
  node_id: uuid
  kind: "skill" | "concept"
  key: string                       // stable, unique platform-wide, lowercase kebab-case, immutable
  names: LocalizedNames             // ADR-036: every language required on write
  descriptions: LocalizedNames|null // optional, same per-language rule when present
  languages: string[]               // derived from names, as ADR-036 defines
  parent_id: uuid | null            // the part_of tree; null for a root
  instrument_ids: uuid[]            // the instruments it is for; empty = every instrument
}
```

- **A node has an instrument scope**, with the same convention content and diagrams use: an
  empty list means every instrument. Most concepts suit every instrument ("Major scale"); many
  skills don't ("Palm mute", "Play E-shape barre chords"). Without a scope, a piano teacher's
  picker would offer palm muting, and practice and recommendations would mix instruments.
  Lists filter by one or more instruments and return nodes for any of them plus nodes for
  every instrument.
  - "Every instrument" (an empty list) includes instruments added later, so it is kept for
    instrument-independent nodes (theory, ear, time).
  - A technique shared by guitars and bass lists those instruments explicitly.
- **Level is not a node property**, because it varies by instrument: hammer-ons are a
  beginner technique on guitar and an early-intermediate one on bass.

- **A skill is something a student can do** and is named as an action ("Play open chords",
  "Change chords smoothly"). **A concept is something true or known** ("Open chord shapes",
  "Minor pentatonic scale"). This is an authoring convention, documented in the spec. The API
  doesn't enforce it.
- **`key` is the identity for code and seed scripts** (a generated drill maps string 6 to
  `find-notes-root-strings`). It replaces sibling-unique names as the unambiguous handle. Names
  carry no uniqueness constraint.
- **Skill and concept names are platform-shared catalog data** under ADR-036: a write must carry a
  name in every language, and clients pick the viewer's locale, then `en`, then any name.

### The tree: `part_of`

- **Each node has at most one parent, of the same kind** (`parent_id`). It is a strict tree, so
  rollups over a subtree count every item once.
- **Re-parenting is allowed**, and is refused if it would create a cycle.

### Edges

```
KnowledgeEdge {
  from_id, to_id: uuid
  type: "applies" | "requires"
  level: "accurate" | "fluent" | "retained" | null   // set for requires, null for applies
}                                                    // unique per (from_id, to_id, type)
```

| Type | Allowed pairs | Level | Meaning |
|---|---|---|---|
| `applies` | skill → concept | none | The skill uses the concept: "Improvise over a blues" applies "Blues form". |
| `requires` | any node → any node: skill → skill, skill → concept, concept → concept, concept → skill | required | `from` needs `to` at that level or above: "Improvise over a blues" requires "Play pentatonic positions" at `fluent`; "Major triads" requires "Interval names" at `accurate`. |

- **The tree says where a node lives; `requires` says what it needs.** Anything cross-branch is a
  `requires` edge, never a second parent.
- **Levels reuse the practice mastery scale** (`accurate < fluent < retained`). "Learn it first"
  is `requires … accurate`.
- **`requires` may not form a cycle**; a write that would create one is refused.
- **A `requires` edge counts for an instrument only when both nodes are for that instrument.**
  "Improvise over a blues" (every instrument) requires "Play minor pentatonic position 1"
  (guitars) for a guitarist's readiness, not a bassist's.
- **`requires` informs; it never gates.** The practice-session composer uses it for "stretch" items,
  recommendations use it for ordering, and it yields a **readiness** measure per node (how many of
  its requirements the student meets at the required level). It doesn't lock content, block
  practice, or validate learning paths. Path order stays a teacher's explicit choice, as ADR-026
  decided.
- **A node has a mastery level of its own, derived from its items.** Checking "requires X at
  `fluent`" needs one. The rule that rolls item states up into a node level belongs to the PB-22
  practice ADR. This ADR only requires that one exists and is derived, never stored by hand.
- **Edges are filled in gradually.** A node with no edges is valid.
- **`applies` never implies `requires`.**
  - We rejected the research map's rule that an applied concept counts as "requires
    (accurate)", because applies links are looser than needs: "Palm mute" applies "Tab
    technique symbols", yet palm muting doesn't need tab.
  - Readiness counts only explicit `requires` edges, which keeps that set sparse and sourced.
  - The same pair may carry both edges, for example "Improvise over a diatonic progression"
    applies "Diatonic chords" and requires it at `fluent`.

### Content links are unchanged in shape

Content nodes, exercises and diagrams keep their `skill_ids` and `concept_ids` arrays, now holding
`KnowledgeNode` ids of the matching kind. A challenge keeps `subject_skill_id` or
`subject_concept_id`. Generated drill templates (PB-22) link the same way. Content never becomes a
graph node, and songs and repertoire stay content.

### API

- **`/knowledge-nodes` replaces `/skills` and `/concepts`:**
  - list (filter by `kind`), create and get
  - `PATCH` for names, descriptions and parent
  - `DELETE`, refused while the node has children, edges or content links
  - edges have their own create, list and delete endpoints
- **Writes are admin-only at MVP:** the team curates the graph as concierge, and teachers classify
  content by picking existing nodes. A teacher proposal flow (proposed nodes awaiting review) is
  deferred until teachers outside the team author content.
- **Reads are open to every signed-in user**, since the student-facing skill map and dashboard
  read the graph.

### The knowledge map is production reference data, installed by migration

The schema change itself has no data to carry: Skill, Concept and the classification tables are
replaced outright, and development databases drop and reseed. **The reviewed knowledge map is
different.** It is the platform's curriculum backbone and must exist in every environment,
production included, so it is not seed data.

- **The map lives in specs as a catalog** (`catalogs/knowledge-map.md` and `.yaml`): the
  2026-10-02 research maps for electric guitar, acoustic guitar and electric bass, reviewed
  with the PO. It includes bilingual names, instrument scopes, the trees, `applies`,
  `requires` and advanced placeholders.
- **Core installs it with a frozen data migration**, the way the basic guitar diagram catalog
  ships.
  - IDs are derived from each key, so every environment holds the same IDs.
  - Reference data installs after the schema, in this order: catalog instruments (including
    Electric bass), the knowledge map, then the diagram catalog, which classifies its
    diagrams by map key.
  - Seeds run only after every migration and never create reference rows.
  - Until production exists, these migrations are regenerated in place and development
    databases are recreated from empty. From the first production install they are
    append-only.
- **After installation the database is the source of truth**, edited by admins through the API.
  A later catalog change ships as a migration that applies only that change.
- **The `TaxonomyNode` and `TaxonomyEdge` schema files are deleted** in the spec slice.

## Rationale

- **One graph rather than two trees plus join tables.** Every relation the product needs is between
  nodes: skill uses concept, X before Y, across or within kinds. With one node table and one edge
  table, a future relation is a new edge type and a validation rule, not a new table with its own
  endpoints. The two kinds still show as separate trees in every UI, because `kind` and the
  same-kind tree keep them apart.
- **A strict tree for `part_of`, cross links as edges.** Several parents would make subtree rollups
  count items twice: "Minor pentatonic scale" under both "Scales" and "Blues" would inflate both,
  and the dashboard reports those rollups to students. Real overlap is expressed with `applies`
  and `requires`, which can cross the tree freely. Keeping the tree as a column (`parent_id`)
  rather than an edge row also makes "one parent" a schema property rather than a validation rule.
- **Content outside the graph**, unlike the old `TaxonomyNode` design. Lessons, exercises, diagrams
  and drill templates already have tables, lifecycles and authors. Making them nodes too would mean
  keeping two copies in sync forever, for no query the link tables can't answer.
- **A stable `key` alongside localized names.** Names change with translation and editorial review.
  Code, seed scripts and generated drills need a handle that never changes.
- **`requires` with a level, rather than an unleveled prerequisite.** "Learn X before Y" can't say
  how well X is needed, and that is the useful part: improvising needs scale positions at
  `fluent`, not merely seen. Reusing the practice mastery levels makes the requirement checkable
  against each student's progress, and yields a readiness measure the dashboard can phrase
  positively ("3 of 4 steps there"). One edge type for both kinds keeps concepts and skills alike:
  a concept can need another concept, and a skill can need a concept at a level.
- **Dependencies that inform rather than gate.** PB-22 decided that practice is never blocked, by
  grades or by waiting on a teacher. A gating requirement would contradict that, and would turn a
  partly filled graph into hard locks. Informational edges are safe to add gradually.
- **Admin-only writes at MVP.** With the team as concierge, a curated graph is worth more than an
  open one: duplicate or ad-hoc nodes would fragment rollups and recommendations. Teachers lose the
  ability to create a node from the tree picker, which they have today. A proposal flow restores it
  when there are outside authors to review.

## Consequences

### Positive

- Skill and concept names are translatable, under the same rule as every other catalog row.
- The platform can explain links ("you're learning this concept because this skill applies it"),
  roll concept knowledge up from skill practice, and find practice for a concept.
- Every node gets a readiness measure from its `requires` edges, which feeds the dashboard, the
  practice composer's "stretch" items and recommendations, without gating anything.
- Nodes can be renamed, re-parented and deleted, so the map can be corrected as the curriculum
  matures.
- A coverage view (lessons and practice items per node) becomes a simple query, which shows
  authoring gaps.
- Content APIs keep `skill_ids`/`concept_ids`, so filters, pickers and classification change little.

### Negative / Trade-offs

- **A breaking API change:** `/skills` and `/concepts` go away, so the SPA's tree picker,
  classification forms and filters must move to `/knowledge-nodes` in the same release, and every
  dev database is dropped and reseeded. This is acceptable only because nothing is in production.
- **The map ships as a migration, not a seed.** Changing the installed map later means
  writing a migration for that change, not editing the catalog and reseeding.
- **Every node needs every language on write,** so adding a node costs a translation. It's
  deliberate, as for instruments, but it slows ad-hoc authoring.
- **Teachers can no longer create nodes from the tree picker** until a proposal flow exists. A
  teacher who needs a missing node asks the team.
- **Cycle checks** on re-parenting and on `requires` writes add a recursive query to those
  writes. It's cheap at this size, but it is per-write validation logic the old trees didn't have.
- **The graph is only as good as its curation.** Wrong `applies` or `requires` edges, or levels set
  too high or too low, mislead rollups, readiness and recommendations silently. The coverage and map views exist so people can review it.

### Neutral

- The skill/concept naming convention (action vs fact) is documented, not enforced.
- Difficulty stays on content, not on nodes: a node like "Play open chords" spans several levels of
  content.
- Readiness depends on node levels, whose rollup rule is decided in the PB-22 practice ADR.
- More edge types (for example "appears in" for repertoire) can be added later, each with its
  allowed pairs, without changing the node model.
- The remediation rule from ADR-026 keeps its exact-node match. The tree and edges now make wider
  matches possible, but this ADR doesn't decide them.

## Related ADRs

- **ADR-026: Content classification graph.** Partly superseded, as stated at the top.
- **ADR-036: Localized catalog names.** The names rule this ADR applies to skills and concepts,
  closing its "Later: Skills and Concepts" section.
- **ADR-033: Diagram localization.** The origin of the `names` map shape.
- **ADR-019: Practice content model.** Exercises classified by skill, now by knowledge node.
- **ADR-040 / ADR-041: Diagram answer cells and audio playback.** The diagrams whose classification
  links stay unchanged.

---

*This ADR was decided on 2026-10-01. To revise, create a new ADR with Status: Supersedes ADR-043.*
