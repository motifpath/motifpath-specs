# ADR-052: A Key/JSON App Config Table, First Used for Curated Starting Points

**Status:** Proposed
**Date:** 2026-10-11
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-88

---

## Context

The first run on Home (MOT-59 D6–D9, `design/patterns/landing-and-first-run.md`) asks a new student
two questions — what they want to play and how much they have played it — and then shows **Where to
start**: at most five paths and courses. The first spec answered it from the catalog: the published
paths, then courses, filtered by instrument, level and language. The catalog orders results by title,
so when more than five match, the five shown are simply the first in alphabetical order.

That is not good enough even for the alpha. The alpha already needs several paths and courses per
instrument and level, and which five a brand-new student sees — and in which order — is the most
important editorial choice in the product: it decides their first lesson. Nothing in the content
model says "start here", and a catalog author's level tag says who a path suits, not whether it is a
good first step.

The team (the concierge, see ADR-017's premise) needs to choose those five, per instrument, level and
language, and change them without a deploy. It does not need a screen for it yet. MotifPath also has
no place for this kind of editorial or operational setting: everything persistent today is a domain
entity with its own table. More settings of the same shape are likely (a featured song, a concierge
message, limits tuned during the alpha), and a new table for each would be heavy for what is a small
JSON value read on a few screens.

## Decision

**1. A generic config table.** core-domain gets an `app_config` table: `key` (text, primary key),
`value` (JSON), `updated_at`, `updated_by` (the user who last wrote it). It holds editorial and
operational settings that the team changes at runtime — never secrets, never per-user data, never
anything a domain entity should own.

**2. Every key is typed in code.** A key is not free-form. Each use case registers a key prefix and a
Go type for its value, with validation that runs on every write; a value that fails validation is
refused. Reads decode into that type. The JSON column is storage, not a contract.

**3. No generic config API.** Clients never read or write `app_config` by key. Each use case exposes
its own typed endpoints in the OpenAPI spec, with its own role rules. The table is an implementation
detail of core-domain.

**4. First use: curated starting points.** The key `starting_points/{instrument_id}/{experience}/{language}`
holds an ordered list of at most five entries, each `{kind: path | course, id}`. `experience` is the
first-run answer (`never_played`, `plays_a_bit`, `plays_well`), not a catalog level; `language` is a
Language code.

- **Write:** `PUT /admin/starting-points/{instrument_id}/{experience}/{language}` replaces the list
  and `DELETE` on the same path removes it. Admins only. A write is refused unless every entry names
  a published path or course, the list has no duplicates, and it has at most five entries. There is
  no screen; the team calls the endpoint (curl or a make target).
- **Read:** `GET /catalog/starting-points?instrument_id=&experience=&language=` returns the entries
  as catalog entries, in the configured order, skipping any that are no longer published. With no
  entry configured, or none left after skipping, it falls back to the catalog: published paths, then
  courses, for that instrument and language at the levels the experience maps to — `never_played` =
  beginner; `plays_a_bit` = early intermediate or intermediate; `plays_well` = advanced or expert —
  at most five. The response says which source answered (`curated` or `catalog`).

The web's own fallbacks (the instrument's other levels, nothing for the instrument) stay in the web
and keep using the catalog endpoints.

## Rationale

**Why curated, not ranked.** Sorting by title is arbitrary; ranking by popularity needs enrolment
data the alpha does not have; a recommender is far beyond the MVP (ADR-049 keeps the first run
simple). A short, hand-picked list per instrument, experience and language is what a concierge team
can actually maintain and reason about.

**Why a generic table rather than a `starting_points` table.** A dedicated table would give foreign
keys and column types for free. It was rejected because this is the first of several small settings
of the same shape, and a table, migration and repository per setting costs more than the setting is
worth. Typing each key in code (decision 2) recovers most of what the dedicated table would give:
the value is validated on write and decoded into a type on read.

**Why not a "start here" flag on paths and courses.** It can't express order, can't differ per
experience level or language, and needs authoring UI to set. Rejected.

**Why not a JSON file in a repo or an environment variable.** Path and course IDs are created when
content is authored in each environment, so one file can't hold them for every environment, and every
change would need a deploy. Rejected.

**Why an admin endpoint rather than SQL or a migration.** The endpoint validates that each ID is a
published path or course; raw SQL validates nothing, and a migration can't know IDs authored after it
was written. The endpoint also records who changed it.

**Why typed endpoints rather than `GET /config/{key}`.** A generic read would hand the web untyped
JSON, push ID resolution and retired-content handling into every client, and make the config table a
public contract. A typed read keeps that in core and lets the fallback live in one place.

## Consequences

### Positive
- The team decides the five starting points per instrument, experience and language, in order, and
  changes them at runtime without a deploy.
- A retired or unpublished entry never reaches a student: it is skipped on read, and refused on write.
- A missing configuration still works: the catalog fallback answers.
- The next editorial or operational setting needs a key type and its endpoints, not a new table.

### Negative / Trade-offs
- No foreign keys: an entry can point at a path or course that is later retired or deleted. Reads
  must keep skipping such entries, and nothing tells the team that a list has become short.
- A generic table invites misuse — settings that should be domain entities, or a growing pile of
  untyped keys. Decisions 2 and 3 are the guard; a reviewer must hold the line on them.
- Without a screen, setting the lists needs an admin token and an HTTP call; the team must keep the
  lists' source somewhere (a JSON file per environment) to set them again.
- Until production exists, the dev databases are dropped and reseeded from empty; configured lists
  are lost with them and must be set again.

### Neutral
- The experience → level mapping moves from the web into core, where the fallback runs.
- The first-run spec's Where to start scenarios now read from the starting points, and say which
  source answered only where it changes behaviour.

## Related ADRs

- ADR-005: Atlas + ent migrations — the `app_config` table is added the same way.
- ADR-017: Student path copied instance — the premise that the team is the concierge.
- ADR-046: Instruments come from enrolments — why a new student needs a starting point at all.
- ADR-049: Practice-first experience language — the first run this list feeds.

---

*This ADR was proposed on 2026-10-11. To revise, create a new ADR with Status: Supersedes ADR-052.*
