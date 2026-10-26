# ADR-064: Core precomputes the practice subject catalog, invalidated by a content version stamp

**Status:** Proposed
**Date:** 2026-10-26
**Deciders:** Gilson (Product Owner)
**Input:** MOT-166 (practice subjects slowness), MOT-167. PO direction, 2026-10-26: content
changes are rare, so the catalog needn't be rebuilt asynchronously. Rebuild it on the first read
after a change, invalidated by a version stamp.

---

## Context

`GET /students/me/practice-subjects` lists what a student can choose to practise with an instrument,
or in the head. To build the list, core walks every item on the student's knowledge maps. It works
out whether each item suits the session (in hand or in the head), which rung it trains and which
nodes' subtrees hold it. Then it tallies those per node, with the student's levels.

Before MOT-166, this read each item separately: about 16,500 transactions and 12 s on the setup page.
The first fix (core#181) reads what a request needs in batches and keeps it for the request, which
brings it to 93 statements and about 170 ms. Most of that time is spent loading and evaluating
every item on every request, for every student: about 1,100 on guitar, including every official
diagram in full. Only two inputs are the student's own: their practice item states (MongoDB,
written by the Aggregation Worker) and the skills on their path.

That shared part changes only when content changes. That can be an admin authoring a diagram, an
exercise, a song chart or an instrument, or a migration installing reference data such as drill
templates and the chord, progression and drill catalogs. Changes are rare next to students opening
the practice setup.

The alternatives considered:
- keep computing per request (core#181 as is);
- an in-memory cache per process, with a time-to-live;
- a catalog rebuilt in the background from a queue of change signals, deduplicated by the
  consumer;
- a catalog rebuilt inside every authoring write;
- a catalog rebuilt on the first read after a change, found out of date by a content version stamp.

## Decision

**Core will keep a precomputed practice subject catalog in PostgreSQL, one row per instrument
scope. Each row records the content version it was built from. A content change adds one to the
version. A list that finds its row behind the current version rebuilds it, answers from it and
stores it.**

- **The catalog** (`practice_subject_catalogs`) has one row per scope. A scope is an instrument id,
  or the empty scope used for a student with no instruments. Each row holds:
  - the scope's classified items, each with its key, the knowledge nodes it is classified under,
    and the facts its subjects are tallied from that don't depend on the student:
    - whether it suits an in-hand session and whether it suits a session in the head;
    - its rung: one fixed rung, or, for a drill item, its ways in order with the rung of each. At
      request time the rung is the one for the way the student would be asked next, which depends
      on their state;
  - the `content_version` it was built from, a `format_version` and `built_at`.

  Only items. The knowledge nodes are read live at request time, in one query, and each node's
  subtree is worked out from them and the items' node ids. A node renamed, added, moved or retired
  shows at once, and knowledge graph edits don't touch the catalog. No names, prompts or media.
- **The content version** (`practice_content_versions`) is a single counter. It is raised by one
  after each content change commits, at the points that already upsert the practice reference
  snapshot (ADR-047):
  - Every diagram, exercise, instrument and published song chart has its reference written there,
    so the writer core uses for those upserts also raises the version. A new write path that keeps
    the snapshot current keeps the catalog current too.
  - A song chart's withdrawal writes no reference, so it raises the version itself.
  - Core raises it once on start, for reference data installed by migrations.

  Raising it is one statement. A failure is logged, not returned, because the change is already
  committed. The next start raises it again.
- **Reading:** `ListSubjects` reads the catalog rows for the session's scopes and the current
  version. It reads the knowledge nodes, the student's states for the items (one MongoDB query per
  scope) and the skills on their path, then tallies in memory. A row is used only when its
  `content_version` is the current one and its `format_version` is the code's.
- **Rebuilding:** a scope with no usable row is built from the content as it is, with the batched
  reads of core#181, and the list answers from it. It is then stored for the version read before
  building, unless the version has moved on meanwhile: the store reads the version under a share
  lock in its own transaction. A catalog built from content that changed while it was being built
  is never stored, and the next list builds it again. Two lists rebuilding the same scope at once
  store the same catalog, and the later write wins.
- **A change to how subjects are tallied bumps `format_version`.** That covers suitability, rung
  rules and drill ways. Rows built by older code are rebuilt on their next read.
- **Out of scope:** composing a session (`ComposePlan`) still reads live with the batched reads,
  since it needs full items to plan. The practice reference snapshot (ADR-047) keeps its upsert on
  commit, because graders reject an answer whose reference is missing.
- **Which diagrams:** the catalog only holds what practice already offers, the official `basic`
  diagrams that only admins create and edit. Teachers' `custom` diagrams are never offered.

## Rationale

- **Precomputing, over computing per request.** Per request, the shared content is re-derived for
  every student every time. The catalog turns 93 statements and about 170 ms into about 20 and
  about 30 ms. The cost moves to the first list after a rare change.
- **A persisted catalog, over an in-memory cache with a time-to-live.**
  - A time-to-live is either stale for its whole length or rebuilt often for nothing.
  - Every process would rebuild its own copy, and each restart would start cold.
  - A row in PostgreSQL is built once, survives restarts and is read in one query.
- **Rebuilding on read, over a background queue.**
  - A queue (a signals table, a consumer loop with a settle delay and a poll, and an advisory lock
    so one instance rebuilds) answers a burst of frequent changes. Changes here are rare, so that
    machinery buys nothing.
  - The queued catalog is also stale for a few seconds after every change. Rebuilding on read is
    never stale: the first list after a change sees it.
  - The cost is one slower list after each change, about as fast as before the catalog.
- **Rebuilding on read, over rebuilding inside the authoring write.**
  - The author would wait for a rebuild of the whole catalog on every save.
  - A crash between the commit and the rebuild would leave it stale until a restart.
  - Concurrent saves would need a lock to keep their rebuilds in order.
  - With the stamp, the write is one statement, and a lost raise only delays freshness until the
    next start or change.
- **A version read under a share lock at store time, over trusting the rebuild.** Without it, a list
  that read the content just before a change and stored just after would leave an old catalog
  marked current until the next change. The share lock makes a concurrent raise wait for the store,
  or makes the store see the raise and skip.
- **Items only, with nodes read live, over precomputing the nodes too.** Nodes are one cheap query.
  Reading them live keeps names and structure current without raising the version on knowledge
  graph edits.
- **Per-scope rows with student-independent facts, over precomputing per student.** States change
  with every answer, so a per-student list would be stale the moment a student practises. Only the
  shared part is precomputed. The rung for the next way, the levels and on-path are applied at
  request time from the student's own data.

## Consequences

### Positive

- The practice setup lists subjects in about 20 statements and 30 ms, however much content exists,
  for every student.
- The list is never stale: the first list after a change rebuilds.
- No background work, no queue and no timers. An authoring write adds one statement.

### Negative / Trade-offs

- **A second derivation to keep correct.** The live and catalog paths share one tally over catalog
  items, and tests compare the lists from both for the same content.
- **Every content write path must raise the version.** Missing one is a silent bug: the list keeps
  showing the old content until the next change or start. Tying the raise to the practice
  reference writer covers every path that already keeps that snapshot. A path that changes items
  without writing a reference, like a withdrawal, needs its own raise and a test asserting it.
- **The first list after a change is slower,** about 170 ms. While a scope is rebuilt, concurrent
  lists for it each rebuild too.
- **Two new tables.**

### Neutral

- Rows for an instrument that no longer exists are never read and do no harm.
- A session in the head reads the rows of each of the student's instruments in the same single
  query.

## Related ADRs

- **ADR-047** (practice reference snapshot): the same "core derives a read model from its own
  content" pattern. The version is raised at the same write points, and that snapshot keeps its
  synchronous upsert.
- **ADR-057** (drill model v2): drill items, their ways and rungs, which the catalog records per
  item.
- **ADR-005** (ent migrations): reference data installed by migrations reaches the catalog through
  the raise on start.

---

*This ADR was proposed on 2026-10-26. To revise, create a new ADR with Status: Supersedes ADR-064.*
