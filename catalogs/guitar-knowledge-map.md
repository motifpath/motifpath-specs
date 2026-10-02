# Guitar knowledge map catalog

The reviewed skill and concept graph that every MotifPath environment starts with,
production included. The data lives in `guitar-knowledge-map.yaml`; this page holds
the rules it follows and what an installation must guarantee.

## Scope

- **Electric and acoustic guitar, beginner to solid intermediate.** Blues/rock core;
  style is a tag on content, never a branch of the tree.
- **239 nodes: 142 skills under 15 roots, 97 concepts under 11 roots.** Built from the
  2026-10-02 research map (RSL, Trinity, RGT@LCM, Berklee Online, MI, JustinGuitar, Guitar
  Tricks, Fender Play, Pickup Music, EM&T). It keeps every key from map v2.
- **Advanced placeholders are left out**: Tapping, Sweep picking, Harmonic minor, Melodic
  minor, Extensions and Secondary dominants. Modal interchange stays, as the one advanced node
  that existing content already uses.
- **Edges: 240 `applies` and 90 `requires`.**
  - `requires` comes only from the research's sourced dependencies (syllabus order, research
    or stated synthesis), with each multi-target row split into one edge per target.
  - Not encoded:
    - the research's low-confidence edges #15, #30, #45 and #52;
    - "Recognise licks by ear requires Recognise intervals by ear" (#28, unsupported);
    - #63, whose node is out of scope.

## Rules

- **Keys** are lowercase kebab-case, unique across both kinds, and never change. Code, seed
  content and generated drills refer to nodes by key.
- **Names stand alone.** Chips and filters show a node's name without its breadcrumb, so a
  child says "Find notes on strings 6 and 5", not "Strings 6 and 5".
  - Skills are named as actions and concepts as things known. Root skills name an area.
  - pt_BR names follow Brazilian course usage. Terms Brazilian guitarists say in English
    (bend, palm mute, shuffle, playback) stay in English.
- **Every node has an `en` and a `pt_BR` name.** Descriptions are optional, and none ship in v1.
- **Instrument scope:**
  - `all` means every instrument (empty `instrument_ids`), `guitars` means Guitar and
    Electric guitar, and `electric` means Electric guitar only.
  - A child is never scoped wider than its parent.
  - Instruments are the two the basic guitar diagram catalog installs.
- **`level`** (B, EI, I, A) is a calibration note for authors and reviewers. It is not
  installed.
- **`applies` and `requires` are independent.**
  - An `applies` link records that a skill uses or illustrates a concept, and never implies
    a requirement.
  - `requires` records what a node needs and at what level, and the same pair may carry both.

## Delivery

- **Installed by a frozen data migration** that runs after the schema migrations, like the
  basic guitar diagram catalog.
  - Node and edge IDs are deterministic, derived from the key, so every environment holds the
    same IDs.
  - Published migration files are append-only.
- **The legacy section maps old nodes to the map.** It lists the skill and concept rows the
  basic guitar diagram catalog created before this map existed. The migration moves their
  diagram links to the mapped node, then removes the old rows. Links to any other old node
  exist only in development data, which is reseeded.
- **After the first installation, the database is the source of truth.**
  - Admins edit the graph through the API.
  - A later change to this catalog ships as a new migration that applies only that change,
    never as a reinstall.

## Acceptance

- Installing on an empty database yields exactly the nodes, parents, names, instrument
  scopes, `applies` and `requires` edges in the YAML, each with the same ID everywhere.
- Every name has non-blank `en` and `pt_BR` text. Every parent has the same kind as its
  child, `applies` runs only skill → concept, and `requires` has no cycle.
- Installation aborts if a node's key already exists with a different kind or parent, or if
  either catalog instrument is missing. It never invents or silently skips a node.
- Every basic catalog diagram keeps at least one skill and one concept after its links move.
