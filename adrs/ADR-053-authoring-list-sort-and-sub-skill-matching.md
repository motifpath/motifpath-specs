# ADR-053: Authoring List Sort, Any-Of Classification Filters and Sub-Skill Matching

**Status:** Proposed
**Date:** 2026-10-11
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-93 (found while designing MOT-61, decision D29)

---

## Context

ADR-031 paginated the content lists and moved search and filtering to the server. It left the
classification filters on content nodes and exercises single-valued and exact, and gave only
`GET /learning-paths` a choice of order. That was enough while the library held a few dozen items.

The authoring redesign (MOT-61, `design/patterns/authoring.md`, Figma "Authoring" rows 13a–13g)
plans for thousands of diagrams and hundreds of exercises and lessons, and its filters assume four
things the API does not offer:

- **Sort by what changed last** on every list (13f). Only learning paths record when they were last
  updated; content nodes, exercises, diagrams and courses record only when they were created, and
  exercises are even ordered by id, which means nothing to a person.
- **Several skills or concepts at once, matching an area** (13c). A teacher picks "Picking" and
  expects lessons classified "Alternate picking" or "Sweep picking" too. The knowledge map
  (ADR-043) is a strict `part_of` tree, so an area is a node with descendants, but every
  classification filter today matches one exact node only. Courses and paths already take several
  ids, still without descendants.
- **The same filters on lessons as on the other sections** (13e): author, language, and publishing
  status — including "unpublished changes", which the lesson row's status chip shows (D5) but the
  content node response cannot express.
- **An author picker that says how much each author made** (13d). The `…/creators` endpoints return
  bare names, and lessons have no such endpoint at all.

The web client is still the only consumer, and there is no production database yet (reference data
is regenerated, user data is reseeded), so a contract change now costs one coordinated core and web
release, not a migration of live clients.

## Decision

MotifPath will extend the ADR-031 list contract, leaving its paging rules unchanged, as follows.

1. **Sort on every authoring list.** `GET /content-nodes`, `/exercises`, `/diagrams`, `/courses` and
   `/learning-paths` take `sort=title|updated`, default `title`. `title` orders by the title (for
   diagrams, the name the caller reads, as today), then id; `updated` orders by the last change,
   most recent first, then id. Exercises therefore move from id order to title order. Content
   nodes, exercises, diagrams and courses gain an `updated_at` timestamp, set at creation and moved
   by every change to the item (for a course: its details, its live draft, publishing or retiring),
   and returned on each item.
2. **Classification filters are any-of lists.** On `/content-nodes`, `/exercises` and `/diagrams`,
   `skill_id` and `concept_id` are replaced by `skill_ids` and `concept_ids` (repeat the parameter),
   matching an item classified with any of them — the shape courses and paths already use. Both
   given, an item must match both lists, as today.
3. **A skill or concept matches its whole subtree.** Wherever `skill_ids` or `concept_ids` appears —
   the five authoring lists and the two catalog lists — an id matches that node **and every node
   below it** in the `part_of` tree. There is no flag: the parameter has one meaning everywhere.
   Picking a leaf behaves exactly as before.
4. **Lessons get the other sections' filters.** `GET /content-nodes` gains `created_by`, `language`
   (matches any of the node's languages; never "any") and `status`: `draft` (never published),
   `published` (the node matches its latest version) or `unpublished_changes` (published, and now
   differs from its latest version). A content node gains `has_unpublished_changes` with the
   meaning courses already give it: true when the node differs from its latest published version
   in anything a version records, or nothing is published yet. A new
   `GET /content-nodes/creators` lists the authors of lessons, like the other sections.
5. **Creator lists carry counts.** Every `…/creators` endpoint returns, for each author, `item_count`:
   how many items of that section by that author the caller can see, ignoring every other filter.
   It uses a new `CreatorRef` schema so `UserRef` stays as it is.

`total` stays exact under every combination of filters.

## Rationale

- **Replace the singular classification parameters (E2 = A), don't alias them.** Keeping
  `skill_id` beside `skill_ids` would leave two spellings of one filter on three endpoints, with a
  rule for when both are given, forever. The only client changes in the same release, and ADR-031
  made the same call for its envelope change for the same reason.
- **Subtree matching always on (E3 = A), not an `include_descendants` flag.** A flag doubles the
  meaning of every classification filter, and every client would have to remember to set it: a
  teacher picking an area never wants exact-node matching, and a leaf already matches only itself.
  Applying it to the catalogs too keeps one meaning for `skill_ids` across the API; students have no
  skill picker today (MOT-58), so nothing they see changes. Rejected alternative: authoring lists
  only — it saves nothing and leaves the same parameter meaning two things.
- **A per-item `updated_at`, not "updated" derived from versions or events.** Content nodes and
  courses have published versions, but exercises and diagrams do not, and a draft edit is not a
  version. One timestamp per item is the simplest thing every list can sort by.
- **"Unpublished changes" compares content, as for courses, not timestamps.** "Edited after the
  latest version was published" would be cheaper, but it flags a lesson saved twice with the same
  values, and it would give the same field name two meanings across courses and lessons.
- **`unpublished_changes` as a third status value (E4 = A).** A two-value status would hide exactly
  the lessons a teacher most needs to find: published ones with edits learners don't see yet.
- **Counts on creators (E6 = A).** The picker is bounded by the number of authors, and the count is
  one grouped query over what the caller can already see. It ignores the other filters so that an
  author's count doesn't change while the teacher adjusts other filters.

## Consequences

### Positive
- Every filter the MOT-61 screens show has an API behind it, so MOT-95's lists ship complete.
- One meaning for `skill_ids` / `concept_ids` and `sort` across all lists.
- Lessons can be found by status, which surfaces unpublished edits.

### Negative / Trade-offs
- **Breaking change** for three endpoints (`skill_id` / `concept_id` removed) and for the default
  order of exercises; core and web must release together.
- A schema change in core: `updated_at` on four tables, back-filled from `created_at` (reference
  data is regenerated, so no live back-fill), and every write path must move it.
- Subtree matching needs a recursive lookup of the `part_of` tree per filtered request; the tree is
  small (hundreds of nodes), so it is cheap, but it adds a query.
- Every save of a published content node must compare it with its latest version (or keep a flag
  that publishing clears), as course drafts already do.
- A course whose classification comes from its checkpoints' paths does not move its `updated_at` when
  one of those paths is edited; it moves only when the course itself changes.

### Neutral
- `PageMeta`, `limit`, `offset`, `q` and the AND-combination of filters are unchanged.
- Song charts (admin section) keep their own list; they are not part of this change.

## Related ADRs

- [ADR-031: Offset pagination and server-side search for content lists — extended by this ADR;
  its paging rules are unchanged](ADR-031-offset-pagination-for-content-lists.md)
- [ADR-043: Skills and concepts knowledge graph — the `part_of` tree subtree matching walks](ADR-043-skills-and-concepts-knowledge-graph.md)
- [ADR-049: Practice-first experience language — §6 sets the authoring tiers these lists serve](ADR-049-practice-first-experience-language.md)

---

*This ADR was proposed on 2026-10-11. To revise, create a new ADR with Status: Supersedes ADR-053.*
