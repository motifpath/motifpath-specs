# ADR-052: A Key/JSON App Config with a Generic Admin API, First Used for Starting Points

**Status:** Proposed
**Date:** 2026-10-11
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-88

---

## Context

The first run on Home (MOT-59 D6–D9, `design/patterns/landing-and-first-run.md`) asks a new student
two questions — what they want to play and how much they have played it — and then shows **Where to
start**: the paths and courses to begin with. The first spec answered it from the catalog: published
paths, then courses, filtered by instrument, level and language. The catalog orders results by title,
so which items a student saw first was simply alphabetical.

That is not good enough even for the alpha. The alpha already has several paths and courses per
instrument and level, and which ones a brand-new student sees — and in which order — is the most
important editorial choice in the product: it decides their first lesson. Nothing in the content
model says "start here", and a catalog author's level tag says who a path suits, not whether it is a
good first step.

The team (the concierge, see ADR-017's premise) needs to choose those items, per instrument,
experience and language, and change them without a deploy. It does not need a screen for it yet.
MotifPath also has no place for this kind of editorial or operational setting: everything persistent
today is a domain entity with its own table. More settings of the same shape are likely (a featured
song, a concierge message, limits tuned during the alpha), and a table and an admin endpoint for each
would be heavy for what is a small JSON value the team edits now and then.

## Decision

**1. A config table.** core-domain gets an `app_config` table: `key` (text, primary key), `value`
(JSON), `updated_at`, `updated_by` (the user who last wrote it). It holds editorial and operational
settings the team changes at runtime — never secrets, never per-user data, never anything a domain
entity should own.

**2. A registry of keys, each with a validator.** A key exists only if core-domain registers it in
code, with a schema for its value and a validator that runs on every write: first the value's
structure (required fields, types, enums, counts), then the rules that need data (for example, that
an id names a published path). A value that fails is refused with every problem listed; nothing is
stored. Reads decode into the key's Go type. The schema of each key is also published in the OpenAPI
spec, so whoever writes a value can check it before sending.

**3. A generic admin API.** Admins read and write any registered key through one API:
`GET /admin/config` lists the registered keys with when and by whom each was last changed;
`GET /admin/config/{key}` returns a key's value; `PUT /admin/config/{key}` replaces it after
validation. An unregistered key is not found. Only admins may call it. There is no screen yet; the
team calls it with curl or a make target, from a JSON file kept per environment.

**4. Typed reads for everyone else.** Clients other than the admin API never read `app_config` by key.
Each use case exposes its own typed endpoint, with its own role rules, that turns the stored value into
what that screen needs.

**5. First key: `starting_points`.** Its value is one document holding every list:

- `lists`: an array; each list has `instrument_id`, `experience` (`never_played`, `plays_a_bit`,
  `plays_well` — the first-run answer, not a catalog level) and `language` (a Language code), all
  required, and `items`: at least one entry, each `{kind: path | course, id}`, in the order shown. The
  team decides how many; there is no upper limit.
- The validator refuses: a missing field; an unknown experience or language; an instrument that does
  not exist; two lists for the same instrument, experience and language; an empty `items`; a repeated
  entry within a list; an entry that does not name a published path or course.
- The typed read is `GET /catalog/starting-points?instrument_id=&experience=&language=`. It returns the
  matching list's entries as catalog entries, in order, skipping any that is no longer published
  (`source: curated`). With no matching list, or none of its entries still published, it answers from
  the catalog (`source: catalog`): published paths, then courses, for that instrument and language at
  the levels the experience maps to — `never_played` = beginner; `plays_a_bit` = early intermediate or
  intermediate; `plays_well` = advanced or expert — each by title, at most five in all.

The web's own fallbacks (the instrument's other levels, nothing for the instrument) stay in the web and
keep using the catalog endpoints.

## Rationale

**Why curated, not ranked.** Sorting by title is arbitrary; ranking by popularity needs enrolment data
the alpha does not have; a recommender is far beyond the MVP (ADR-049 keeps the first run simple). A
hand-picked list per instrument, experience and language is what a concierge team can actually
maintain and reason about.

**Why a generic table rather than a `starting_points` table.** A dedicated table would give foreign
keys and column types for free. It was rejected because this is the first of several small settings
of the same shape, and a table, migration, repository and admin endpoints per setting cost more than
the setting is worth. The per-key validator (decision 2) recovers most of what a dedicated table would
give: a value is checked on write and decoded into a type on read.

**Why a generic admin API rather than admin endpoints per key.** The team edits these values as
documents, often from a file per environment; one GET/PUT pair for every key means a new setting needs
a validator, not new endpoints, and the admin always has one way to see what is set and who set it.
The safety that typed endpoints would give comes from the registry: only registered keys exist, and
every write is validated.

**Why typed reads rather than letting clients read keys.** A generic read would hand clients untyped
JSON, push id resolution and retired-content handling into every client, and make the stored shape a
public contract the web depends on. A typed read keeps that in core, lets the catalog fallback live in
one place, and leaves the stored shape free to change.

**Why one document for all starting points rather than a key per list.** The team edits the lists
together and keeps them in one file per environment; one document is read and written in one call,
and the validator can check that no two lists overlap. A key per list would scatter one setting across
many keys whose names repeat the fields inside them.

**Why not a "start here" flag on paths and courses.** It can't express order, can't differ per
experience or language, and needs authoring UI to set. Rejected.

**Why not a JSON file in a repo or an environment variable.** Path and course ids are created when
content is authored in each environment, so one file can't hold them for every environment, and every
change would need a deploy. Rejected.

## Consequences

### Positive
- The team decides the starting points per instrument, experience and language — which and how many,
  in order — and changes them at runtime without a deploy.
- A new editorial or operational setting needs a registered key, its schema and validator, and a typed
  read where a screen needs one — no table, no admin endpoints.
- A retired or unpublished entry never reaches a student: it is refused on write and skipped on read.
- A missing configuration still works: the catalog fallback answers.

### Negative / Trade-offs
- No foreign keys: an entry can point at a path or course that is later retired or deleted. Reads must
  keep skipping such entries, and nothing tells the team that a list has become short.
- A generic table and API invite misuse — settings that should be domain entities, or keys registered
  with a weak validator. Decisions 1 and 2 are the guard; a reviewer must hold the line on them.
- Writing `starting_points` replaces every list at once: two admins editing at the same time can
  overwrite each other's change. Acceptable while the team is small; a version check can be added to
  the PUT later.
- Without a screen, changing a value needs an admin token and an HTTP call.
- Until production exists, the dev databases are dropped and reseeded from empty; configured values
  are lost with them and must be set again from the team's files.

### Neutral
- The experience → level mapping moves from the web into core, where the catalog fallback runs.
- The OpenAPI spec documents each key's value schema; the admin API's body is that schema, chosen by
  the key.

## Related ADRs

- ADR-005: Atlas + ent migrations — the `app_config` table is added the same way.
- ADR-017: Student path copied instance — the premise that the team is the concierge.
- ADR-046: Instruments come from enrolments — why a new student needs a starting point at all.
- ADR-049: Practice-first experience language — the first run this list feeds.

---

*This ADR was proposed on 2026-10-11. To revise, create a new ADR with Status: Supersedes ADR-052.*
