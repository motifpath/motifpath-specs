# Knowledge map catalog

The reviewed skill and concept graph that every MotifPath environment starts with,
production included. The data lives in `knowledge-map.yaml`; this page holds the rules it
follows and what an installation must guarantee.

## Scope

- **Three instruments, beginner to solid intermediate:** electric guitar, acoustic guitar
  (steel-string and nylon violão, in popular styles) and 4-string electric bass. The core is
  blues/rock plus Brazilian popular music. Style is a tag on content, never a branch of the tree.
- **344 nodes: 219 skills under 16 roots, 125 concepts under 11 roots.**
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
  - A placeholder concept needn't be applied or required: it marks what comes after solid
    intermediate, and no beginner-to-intermediate skill uses it yet.
- **Edges: 366 `applies` and 144 `requires`.**
  - `requires` comes only from the research's sourced dependencies (syllabus or method
    order, research or stated synthesis), one edge per target.
  - Not encoded:
    - the low-confidence edges, electric #15, #30, #45, #52 and bass/acoustic #78, #94, #96;
    - edges the research found unsupported or contradicted: licks require intervals, rest
      stroke requires free stroke, fills require chart-building, MPB shapes require barre
      chords.
  - Synthesis edges (`basis: Syn`) give an instrument its own prerequisites where the
    sourced ones don't count for it, so its readiness measures something.

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
- **A `requires` edge to a parent asks for the parent's own level.** That level rolls up every
  item in the parent's subtree that suits the instrument, so the requirement is met when the
  group as a whole reaches it, not when any one child does. Point an edge at a leaf when one
  child is what's needed: "Hybrid picking" requires "Place the picking-hand fingers", not all
  of fingerstyle.
- **Every skill is classified with a concept on each of its instruments.** A lesson needs at
  least one skill and one concept that suit its instrument, so a leaf skill applies at least
  one concept valid on every instrument it is for.
  - A skill that no concept describes says why in `unapplied`, an annotation for authors
    that isn't installed. Only "Plan a practice routine" has one: a routine organises other
    skills.
- **Every concept is reachable.** A leaf concept that isn't a placeholder is applied by at
  least one skill or required by a node, so practice and recommendations can get to it.

## Curriculum coverage

How the map serves the curriculum principles (`curriculum/principles.md`). Unlike the rules
above, the compiler doesn't check these. Review them whenever the map changes.

- **Every instrument has a beginner chain that ends in a song,** every link at level B on that
  instrument:
  - acoustic: Sit and hold the acoustic guitar → Tune with a tuner → Play open chords →
    Change chords smoothly → Strum steady rhythms → Play a full song along with the recording;
  - electric: Hold the guitar and pick → Tune with a tuner → Play power chords → Change chords
    smoothly → Strum steady rhythms → Play a full song along with the recording;
  - bass: Hold the bass and place the plucking hand → Tune with a tuner → Play root notes
    through a progression → Play steady eighth notes on the root → Play a full song along with
    the recording.
- **The early physical quitting points each have a skill:** tuning (Tune with a tuner), finger
  pain and calluses (Build finger strength and calluses), posture (Play without tension or
  pain), and barre chords (the E- and A-shape barres, which require finger strength).
- **Theory enters through use.** Diatonic chords and transposition are early intermediate. The
  skills that apply them are the ones learners ask for: Play shapes in any key, Find the key of a
  song by ear and Choose a capo position for a singer's key.
- **Practice craft stays skills.** Practise slowly and build tempo, Loop and slow down a
  recording, Record yourself and self-assess, and Plan a practice routine keep their place on
  the learner's map, since concepts get no progress line. No item kind can grade them yet, so
  the practice session carries them: the tempo ladder for practising slowly, and the session
  composer for planning.
- **The styles learners look for in Brazil need no style branch.** Their beginner skills are
  style-neutral and exist on every instrument they need:
  - strumming recipes (Strum steady rhythms; Play guarânia and toada levadas);
  - power chords and riffs for Brazilian rock;
  - a bass line from the chart (Build a bass line from a chord chart);
  - playing your part with a band, as in a worship band.

  Singing while you play and accompanying a singer stay early intermediate on the acoustic,
  as the plan teaches them.

### Practice coverage

Every leaf skill should name a practice item kind that can measure it. The table gives the kinds
for each area; the skills after it have none yet.

| Area | Item kinds |
|---|---|
| Instrument basics | `play_along` (finger strength, capo and tunings, 5-string, fretless, 7-string, open tunings), `exercise` (choosing a capo for a singer) |
| Fretboard fluency | `fretboard_cell`, `play_along`, `root_fifth` |
| Fretting-hand, picking and muting technique | `play_along` |
| Chords and rhythm | `chord_voicing`, `chord_change`, `diagram_shape`, `chart_progression`, `play_along` |
| Time and groove | `play_along` |
| Reading | `play_along`, `song_chart`, `exercise` |
| Ear | `heard_chord`, `heard_progression`, `exercise` |
| Licks | `play_along` |
| Improvisation | `guide_tone` (Target chord tones over changes) |
| Repertoire | `play_along`, `song_chart` |
| Bass lines | `root_fifth`, `root_change`, `guide_tone`, `play_along` |

No kind can measure these yet. Practice reaches them only through content and the session
itself:

- **posture and tuning,** which need the instrument observed: the three hold skills, Play
  without tension or pain, Tune with a tuner, Tune by ear (relative tuning);
- **singing and echoing,** which need pitch detection: Match a pitch, Sing what you play,
  Echo short phrases by ear;
- **rhythm tapping,** until a tapping kind ships: Repeat rhythms by ear;
- **work with no fixed answer:** Transcribe a riff or solo, Vary a lick, Arrange a song for
  one guitar, every improvisation skill except Target chord tones over changes, and every
  composition skill;
- **gear:** every tone-and-gear skill;
- **practice craft,** as above.

## Delivery

- **Installed by frozen reference-data migrations** after the schema, following the order and
  the fixed-ID rule in `reference-data.md`: instruments (keys `guitar`, `electric-guitar`,
  `electric-bass`) install first, then this map, then the basic guitar diagram catalog, whose
  diagrams are classified by map key.
- **IDs are fixed and identical in every environment:** `knowledge-node/<key>` and
  `knowledge-edge/<type>/<from key>/<to key>` under the catalog namespace.
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
- **Classification and readiness hold on every instrument.** The compiler refuses a map that
  breaks any of these:
  - every leaf skill applies a concept valid on each of its instruments, or says in
    `unapplied` why none fits (and then applies none);
  - every leaf concept below level A is applied by a skill or required by a node;
  - for every instrument a `requires` edge counts for, its target has a leaf for that
    instrument, so the requirement has items to measure;
  - a node whose `requires` edges count for one of its instruments has at least one that
    counts for each of them, so no instrument's readiness is trivially complete.
- **Installation fails loudly.** It aborts if a catalog instrument or a node key already
  exists with different data. It never invents or silently skips a row.
- **Every basic catalog diagram has at least one skill and one concept** from the map.
- **Seeds work on top.** Running every seed after a fresh install succeeds and creates no
  reference rows.
