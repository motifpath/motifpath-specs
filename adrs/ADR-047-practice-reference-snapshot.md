# ADR-047: Core publishes a read-only practice reference snapshot to MongoDB for the graders

**Status:** Accepted
**Date:** 2026-10-04
**Deciders:** Gilson (Product Owner)
**Input:** PB-22 slice 2 plan, question Q1 (decided 2026-10-04)
**Accepted:** 2026-10-04, by Gilson.

---

## Context

ADR-046 puts grading on the server: the Aggregation Worker's evidence processor grades every
`practice.item_answered` from its raw response, through versioned graders, against reference data.
Each grader needs facts that only the Core Domain Service owns, in PostgreSQL:

- `self_rating.v1` needs to know whether a diagram exists, and that a play-along's diagram has a
  playback tempo.
- `exercise_option.v1` needs an exercise's options and which of them are correct.
- `fretboard_cell.v1` needs the layout instrument's tuning and string count.

A rule change regrades stored responses later, so the same facts must still be readable long after
the answer.

The worker can't get them today. It talks only to Kafka and MongoDB (ADR-011). It has no user token,
and core's API authenticates every call as a user. The Event Ingestion Service can call core, but
only on behalf of the student whose bearer token it forwards (ADR-014). It is also the platform's
sole Kafka producer (ADR-006), and its topic carries student events only. The opposite direction
already exists: core reads the worker's derived state from MongoDB (ADR-011's `aggregates`, read
by `mongo_completion_state_reader`).

The alternatives considered:
- an internal, unauthenticated HTTP listener on core for the worker;
- the worker reading core's PostgreSQL tables directly;
- grading at ingestion, with the student's token;
- core announcing reference changes as Kafka events.

## Decision

**The Core Domain Service will keep a read-only reference snapshot in MongoDB, in a
`practice_reference` collection, and the Aggregation Worker will read reference data only from that
snapshot.**

- **Core is the only writer.** The worker and every other reader treat the collection as read-only.
- **One document per reference row a grader can need,** keyed by `{kind, id}`:
  - `instrument`: tuning, string count, and the layout instrument whose cells it shares;
  - `diagram`: linked instrument ids and playback `tempo_bpm` (null when it has no sequence);
  - `exercise`: exercise type, option ids, correct option ids and instrument ids.

  Each document carries `updated_at` and a `snapshot_version` for its shape. Documents are never
  removed. Diagrams and exercises can't be deleted today. If retiring them is ever added, their
  documents gain a `retired` flag instead, so old evidence can still be regraded.
- **On change:** core upserts the row's document after the PostgreSQL transaction that created or
  updated the row commits.
- **On start:** core runs a full sync that upserts every row's document. It repairs any write lost
  between a commit and a crash, and covers rows installed by migrations (ADR-005, reference data).
  The same sync runs from a maintenance command.
- **A grader that finds no document rejects with `unknown_reference`.** The raw event stays in the
  event log, and a later regrade (ADR-046) picks it up once the snapshot has the row.
- The snapshot holds what grading needs and nothing more: no names, prompts or media. Anything shown
  to users still comes from core's API.

## Rationale

- **A MongoDB snapshot, over an internal HTTP listener on core.**
  - With HTTP, the worker could grade only while core is up. A core outage would stall the student
    partitions behind a retry loop, or drop grades.
  - With the snapshot, the worker depends on the store it already uses, and grading survives a
    core restart.
  - An unauthenticated listener is safe only as long as the network keeps it private. That holds on
    the single VM (ADR-039) and needs revisiting on any move off it.
- **A snapshot, over the worker reading PostgreSQL.** Reading core's tables directly would tie the
  worker to core's ent schema and migrations, and would cut across the hexagonal boundary every
  service keeps. The snapshot is a small contract that core shapes on purpose.
- **Grading in the worker, over grading at ingestion with the student's token.**
  - Ingestion could grade synchronously by calling core. But a later regrade has no token, so the
    reference problem comes back as soon as a rule changes.
  - It would also add a core round trip to every answer the student submits.
- **A snapshot, over reference events on Kafka.** ADR-006 makes ingestion the sole producer, on a
  student-partitioned topic. Reference changes aren't student events. A second producer and topic is
  more machinery than one collection that core already has a client for.
- **Upsert on commit plus a sync on start, over an outbox.** A lost write is rare, harmless (the
  answer is rejected, kept, and regradable), and repaired at the next start. An outbox would
  guarantee delivery that this case doesn't need.

## Consequences

### Positive

- The worker grades and regrades with no dependency on core being up and no new authentication.
- Documents are never removed, so evidence can always be replayed under new grader versions.
- The contract is small and explicit: the snapshot's shape is the only reference data the graders
  can use.

### Negative / Trade-offs

- **Two copies of reference facts.** The snapshot can lag PostgreSQL between a commit and its
  upsert, or until the next start after a failed upsert. An answer graded in that window is rejected
  and needs a regrade.
- **Core gains MongoDB writes** next to its existing read-only access, and every create and
  update path for diagrams, exercises and instruments must call the snapshot writer. Missing one is
  a silent bug, so each path needs a test asserting the snapshot changed.
- **The full sync at start grows with the catalog.** It's cheap at today's size, and it can become
  incremental (by `updated_at`) when it isn't.

### Neutral

- The web client keeps grading for instant feedback from the data it already loads, unaffected by
  the snapshot.
- New item kinds add a `kind` to the snapshot when their grader needs reference data.

## Related ADRs

- **ADR-046** (evidence-based practice model): server-side grading, versioned graders and regrading
  are why the worker needs reference data at all.
- **ADR-011** (minimal Aggregation Worker): the worker's MongoDB-only footprint, and the reverse
  path (core reading worker state) this mirrors.
- **ADR-006** (Kafka topology): why reference changes don't go on the event topic.
- **ADR-014** (identity resolution at `POST /events`): ingestion calls core only with a user's
  token.
- **ADR-039** (single-VM hosting): why an internal listener would be private only by network
  placement.
- **ADR-005** (ent migrations): reference rows installed by migrations reach the snapshot through
  the sync on start.

---

*This ADR was accepted on 2026-10-04. To revise, create a new ADR with Status: Supersedes ADR-047.*
