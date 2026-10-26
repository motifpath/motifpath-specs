# ADR-064: Core precomputes the practice subject catalog, rebuilt asynchronously from a deduplicated queue

**Status:** Proposed
**Date:** 2026-10-26
**Deciders:** Gilson (Product Owner)
**Input:** MOT-166 (practice subjects slowness), MOT-167. PO direction, 2026-10-26: the catalog
doesn't need real-time updates; send a signal to a queue and deduplicate on the consumer.

---

## Context

`GET /students/me/practice-subjects` lists what a student can choose to practise with an instrument,
or in the head. To build the list, core walks every item on the student's knowledge maps. It works
out whether each item suits the session (in hand or in the head), which rung it trains and which
nodes' subtrees hold it. Then it tallies those per node, with the student's levels.

Before MOT-166, this read each item separately: about 16,500 transactions and 12 s on the setup page.
The first fix (core#181) reads what a request needs in batches and keeps it for the request, which
brings it to 93 statements and about 170 ms. That number no longer grows with content, but most of
those statements re-derive the same thing on every request for every student: the classified items,
their diagrams, exercises and drill catalogs. Only two inputs are the student's own: their practice
item states (MongoDB, written by the Aggregation Worker) and the skills on their path.

That shared part changes only when someone authors content: a diagram, an exercise, a song chart,
the knowledge graph or an instrument. It also changes when a migration installs reference data,
such as drill templates or the chord, progression and drill catalogs. Authoring is rare next to
students opening the practice setup, and nobody needs a change on the list the instant it is saved.

The alternatives considered:
- keep computing per request (core#181 as is);
- an in-memory cache per process, with a time-to-live;
- rebuilding synchronously inside every authoring write;
- a Kafka topic for the rebuild signals;
- a precomputed catalog, rebuilt asynchronously from a queue table in PostgreSQL.

## Decision

**Core will keep a precomputed practice subject catalog in PostgreSQL, one row per instrument scope.
Authoring writes will put a rebuild signal on a queue table. An in-process consumer will
deduplicate the pending signals and rebuild the catalog once for all of them.**

- **The catalog** (`practice_subject_catalogs`) has one row per scope. A scope is an instrument id,
  or the empty scope used for a student with no instruments. Each row holds:
  - the scope's classified items, each with its key, the knowledge nodes it is classified under,
    and the facts its subjects are tallied from that don't depend on the student:
    - whether it suits an in-hand session and whether it suits a session in the head;
    - its rung: one fixed rung, or, for a drill item, its ways in order with the rung of each. At
      request time the rung is the one for the way the student would be asked next, which depends
      on their state;
  - `built_at` and a `format_version`.

  Only items. The knowledge nodes are read live at request time, in one query, and each node's
  subtree is worked out from them and the items' node ids. A node renamed, added, moved or retired
  shows at once, and knowledge graph edits don't touch the catalog. No names, prompts or media.
- **The queue** (`practice_catalog_signals`) is a table with one row per signal: an id, a reason
  (`diagram`, `exercise`, `song_chart`, `instrument`, `start`) and `created_at`. A signal is
  queued after the authoring write commits, at the points that already upsert the practice reference
  snapshot (ADR-047):
  - Every diagram, exercise, instrument and published song chart has its reference written there,
    so the writer core uses for those upserts also queues a signal. A new write path that keeps the
    snapshot current keeps the catalog current too.
  - A song chart's withdrawal writes no reference, so it queues its own signal.
- **The consumer** is a goroutine in the Core Domain Service:
  - it wakes on a signal from the same process, or by polling every 30 s;
  - it waits 2 s so a burst of edits settles;
  - it takes the highest pending signal id under a PostgreSQL advisory lock, so only one instance
    rebuilds at a time;
  - it rebuilds every scope in one transaction and deletes the signals up to that id.

  Any number of signals pending at once cause one rebuild. A signal that arrives during a rebuild
  stays queued and causes exactly one more.
- **On start**, core queues a `start` signal. That covers reference data installed by migrations
  and any signal lost between a commit and a crash.
- **Reading:** `ListSubjects` reads the catalog rows for the session's scopes in one query, and the
  knowledge nodes in one more. It reads the student's states for those items in one MongoDB query
  per scope, and the skills on their path, then tallies in memory. A scope with no row, or with a row of an older `format_version`, is computed
  live, as core#181 does, and a rebuild is queued. The list is never missing or wrong, only slower,
  until the catalog is built.
- **A change to how subjects are tallied bumps `format_version`.** That covers suitability, rung
  rules and drill ways. Rows built by the old code are ignored until the start rebuild replaces
  them.
- **Out of scope:** composing a session (`ComposePlan`) still reads live with the batched reads,
  since it needs full items to plan. The practice reference snapshot (ADR-047) keeps its upsert on
  commit, because graders reject an answer whose reference is missing. Moving it onto this queue
  would be a separate decision.

## Rationale

- **Precomputing, over computing per request.** Per request, the shared content is re-derived for
  every student every time. The catalog turns 93 statements into about ten: the user, the
  instrument check, the knowledge nodes, the path, the catalog rows and one MongoDB read. The cost moves from every
  student's request to the rare authoring write.
- **A persisted catalog, over an in-memory cache with a time-to-live.**
  - A time-to-live is either stale for its whole length or rebuilt often for nothing.
  - Every process would rebuild its own copy, and each restart would start cold.
  - A row in PostgreSQL is built once, survives restarts and is read in one query.
- **Asynchronous, over rebuilding inside the authoring write.**
  - A rebuild reads the whole content set, about 90 statements. Doing it per write would slow
    authoring and repeat the work for every edit in a burst.
  - The PO has said a delay of seconds is fine. The queue makes it one rebuild per burst, not one
    per write.
- **A queue table in PostgreSQL, over a Kafka topic.**
  - Core doesn't produce or consume Kafka today. ADR-006 makes Event Ingestion the sole producer, on
    a topic partitioned by student, and these signals aren't student events.
  - A topic would add a Kafka client, a topic to provision and a consumer group to core.
    Deduplication would still have to be built on top, because Kafka delivers every message.
  - A table gives the same queue semantics with the database core already owns. "Take everything up
    to the highest id" is the deduplication.
  - This is the call to revisit if the catalog is ever built outside core.
- **Items only, with nodes read live, over precomputing the nodes too.** Nodes are one cheap query.
  Reading them live keeps names and structure current without signalling on knowledge graph edits.
- **Per-scope rows with student-independent facts, over precomputing per student.** States change
  with every answer, so a per-student list would be stale the moment a student practises. Only the
  shared part is precomputed. The rung for the next way, the levels and on-path are applied at
  request time from the student's own data.
- **A live fallback, over failing or serving nothing.** A fresh database, a new instrument or a
  deploy that changes the format would otherwise show an empty or wrong list until the rebuild
  runs.

## Consequences

### Positive

- The practice setup lists subjects in about ten queries, however much content exists, for every
  student.
- An authoring burst costs one rebuild. Nothing authors more slowly.
- The catalog survives restarts and is shared by every core process on the same database.

### Negative / Trade-offs

- **A second derivation to keep correct.** The tally from the catalog must equal the live tally.
  Tests must build both from the same content and compare them, and the live path stays as the
  fallback.
- **Every authoring write path must queue a signal.** Missing one is a silent bug: the list keeps
  showing the old content until the next start. Tying signals to the practice reference writer
  covers every path that already keeps that snapshot. A path that changes items without writing a
  reference, like a withdrawal, needs its own signal and a test asserting it.
- **The list lags authoring by seconds,** up to the 30 s poll if the in-process wake-up is missed
  (for example, a write handled by another instance).
- **A format change shows slower lists until the start rebuild finishes.** The fallback keeps them
  correct.
- **Two new tables** and a background goroutine in core, which needs a clean shutdown.

### Neutral

- A rebuild reads with the batched reads from core#181, so its cost doesn't grow per item either.
- The empty scope and per-instrument scopes are the same shape. A session in the head reads the
  rows for each of the student's instruments in the same single query.

## Related ADRs

- **ADR-047** (practice reference snapshot): the same "core derives a read model from its own
  content" pattern. Signals are queued at the same write points, and that snapshot is left on its
  synchronous upsert.
- **ADR-006** (Kafka topology): why the signals don't go on Kafka.
- **ADR-057** (drill model v2): drill items, their ways and rungs, which the catalog records per
  item.
- **ADR-005** (ent migrations): reference data installed by migrations reaches the catalog through
  the start signal.
- **ADR-039** (single-VM hosting): one core process today; the advisory lock keeps a rebuild single
  if there are more.

---

*This ADR was proposed on 2026-10-26. To revise, create a new ADR with Status: Supersedes ADR-064.*
