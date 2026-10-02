# Knowledge map catalog

The reviewed skill and concept graph that every MotifPath environment starts with,
production included. The data lives in `knowledge-map.yaml`; this page holds the rules it
follows and what an installation must guarantee.

## Scope

- **Three instruments, beginner to solid intermediate:** electric guitar, acoustic guitar
  (steel-string and nylon violão, in popular styles) and 4-string electric bass. The core is
  blues/rock plus Brazilian popular music. Style is a tag on content, never a branch of the tree.
- **340 nodes: 216 skills under 16 roots, 124 concepts under 11 roots.**
  - Built from two 2026-10-02 research maps:
    - electric guitar: RSL, Trinity, RGT@LCM, Berklee Online, MI, JustinGuitar, Guitar
      Tricks, Fender Play, Pickup Music, EM&T;
    - bass and acoustic: RSL, Trinity, RGT@LCM, StudyBass, Hal Leonard, BassBuzz, Giffoni,
      Shearer, NEOJIBA, Fejuca, Marco Pereira and Brazilian levada courses.
  - It keeps every key from map v2.
- **Advanced placeholders (level A) are included.** There are 14, so paths and
  recommendations can point to what comes after solid intermediate:
  - electric: Tapping, Sweep picking;
  - concepts: Harmonic minor, Melodic minor, Extensions, Secondary dominants, Modal
    interchange;
  - bass: 5-string, Fretless, Double thumb, Walking over ii–V–I;
  - acoustic: 7-string violão, Body percussion;
  - plus Use modal interchange.
- **Edges: 335 `applies` and 136 `requires`.**
  - `requires` comes only from the research's sourced dependencies (syllabus or method
    order, research or stated synthesis), one edge per target.
  - Not encoded:
    - the low-confidence edges, electric #15, #30, #45, #52 and bass/acoustic #78, #94, #96;
    - edges the research found unsupported or contradicted: licks require intervals, rest
      stroke requires free stroke, fills require chart-building, MPB shapes require barre
      chords.

## Rules

- **Keys** are lowercase kebab-case, unique across both kinds, and never change. Code, seed
  content and generated drills refer to nodes by key.
- **Names stand alone.** Chips and filters show a node's name without its breadcrumb, so a
  child says "Find notes on the E and A strings", not "Strings 6 and 5".
  - Names hold on every instrument the node is for. That is why "E and A strings" replaces
    "strings 6 and 5", which on bass are strings 4 and 3.
  - Skills are named as actions and concepts as things known. Root skills name an area.
  - pt_BR names follow Brazilian course usage. Terms Brazilian musicians say in English
    (bend, palm mute, slap, ghost notes, walking bass) stay in English.
- **Every node has an `en` and a `pt_BR` name.** Descriptions are optional, and none ship in v1.
- **Instrument scope:**
  - **`all` means every instrument, including ones added later** (piano, voice). It is
    reserved for nodes that don't depend on the instrument: theory, ear, time, reading,
    repertoire, practice craft.
  - **Every other value lists instruments explicitly**, through the aliases at the top of the
    YAML. A physical technique shared by guitars and bass is `fretted`, never `all`.
  - **Concepts are `all` unless they are physical:** strings, tunings, picking-hand fingers,
    fretboard shapes, gear.
  - A child is never scoped wider than its parent.
- **`level`** (B, EI, I, A) is a calibration note for authors and reviewers, with
  per-instrument overrides in `levels` (hammer-ons are B on guitar, EI on bass). It is not
  installed. Level varies by instrument, so it is not a node property.
- **`applies` and `requires` are independent.**
  - An `applies` link records that a skill uses or illustrates a concept, and never implies
    a requirement.
  - `requires` records what a node needs and at what level, and the same pair may carry both.
- **A `requires` edge counts for an instrument only when both nodes are for that
  instrument.** "Improvise over a blues" requires "Play minor pentatonic position 1" for a
  guitarist, not for a bassist. Every edge shares at least one instrument.

## Delivery

- **Installed by frozen reference-data migrations**, which run after the schema migrations in
  this order:
  1. catalog instruments: Acoustic guitar, Electric guitar, Electric bass;
  2. this knowledge map;
  3. the basic guitar diagram catalog, whose diagrams are classified by map key.
- Node, edge and instrument IDs are deterministic, derived from their keys, so every
  environment holds the same IDs.
- **Seeds run only after every migration** and never create reference rows: no instruments,
  voices, nodes, edges or catalog diagrams. Seed content links to map nodes by key.
- **Until production exists**, reference-data migrations may be regenerated in place, and
  development databases are recreated from empty. **From the first production install**,
  migration files are append-only:
  - the database is the source of truth, edited by admins through the API;
  - a later catalog change ships as a new migration that applies only that change.

## Acceptance

- **A fresh install matches the catalog.** Migrating an empty database yields exactly the
  nodes, parents, names, instrument scopes, `applies` and `requires` edges in the YAML, each
  with the same ID everywhere. This runs with no seed.
- **The data holds the map's invariants:**
  - every name has non-blank `en` and `pt_BR` text;
  - every parent has the same kind as its child, and no child is scoped wider than its
    parent;
  - `applies` runs only skill → concept;
  - `requires` has no cycle, and the two ends of every `requires` edge share an instrument.
- **Installation fails loudly.** It aborts if a catalog instrument or a node key already
  exists with different data. It never invents or silently skips a row.
- **Every basic catalog diagram has at least one skill and one concept** from the map.
- **Seeds work on top.** Running every seed after a fresh install succeeds and creates no
  reference rows.
