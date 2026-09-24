# ADR-031: Offset pagination and server-side search for content list endpoints

**Status:** Accepted
**Date:** 2026-09-23
**Deciders:** Gilson (Product Owner)

---

## Context

Every list endpoint in `core-domain-service.yaml` was specced as an unpaginated array with the
explicit assumption that the collection would "stay small". That assumption held while MotifPath
had a handful of seeded courses. It does not hold for launch: the course catalog, learning-path
library, content-node library and exercise pool are all expected to grow into the hundreds or
thousands, and students browse the course catalog directly.

PB-32's frontend plan had also deferred `level` and text search to client-side filtering on the
same assumption. Client-side filtering is incompatible with paging — a filter applied to one page
of results silently hides matches on other pages — so search and filtering must move to the
server together with pagination.

`GET /content-nodes/{id}/expanded-content` already returns an `{items, total}` envelope, so an
envelope with a total is an existing precedent in this contract.

**Alternatives considered:**

1. **Cursor (keyset) pagination.** Scales better for very deep pages and tolerates concurrent
   inserts without skipping rows. Rejected for now: the catalog and libraries are browsed with
   filters and a "page N of M" style UI, need a `total`, and are not high-write; depth beyond a
   few hundred pages is unrealistic.
2. **Keep arrays, add `limit`/`offset` params only.** Rejected: without a `total` the UI cannot
   render page controls or an empty state reliably.
3. **Client-side filtering over a large fetched page.** Rejected as above.

## Decision

MotifPath will paginate `GET /courses`, `GET /learning-paths`, `GET /content-nodes` and
`GET /exercises` with shared `limit` (1–100, default 20) and `offset` (≥ 0, default 0) query
parameters, and return `{items, total, limit, offset}` (`PageMeta` plus `items`) instead of a bare
array. `total` counts all items matching the request's filters. An out-of-range `limit`/`offset`
is a 400; an offset past the end is a 200 with empty `items`. Results have a documented, stable
order: title then id for courses, learning paths and content nodes; id for exercises.

Search and filtering are server-side and always combine with AND. `GET /courses` gains `q`
(title/summary), `levels`, `created_by`, `skill_ids` and `concept_ids` (multi-valued, any-of
within each parameter); `GET /learning-paths` and `GET /content-nodes` gain `q` (title). Existing
single-valued filters on content nodes and exercises are unchanged.

Small, bounded reference lists (skills, concepts, instruments, diagrams, a student's own
enrollments and standalone paths) stay unpaginated.

## Rationale

Offset pagination with a total is the simplest contract that supports filtered browsing with page
controls, which is what both the student catalog and the authoring libraries need. Its known
weakness — rows shifting under concurrent writes and slow very deep offsets — matters little for
low-write, human-browsed collections capped at 100 per page. Cursor pagination stays available
as a later, additive change if a list ever becomes high-write or machine-consumed.

Doing this before launch, while the web client is the only consumer and it is still being
reworked (PB-32), is far cheaper than retrofitting a breaking response-shape change afterwards.

## Consequences

### Positive
- Catalog and libraries stay fast and bounded as they grow.
- Filters, search and paging compose correctly; `total` reflects the filtered set.
- One shared parameter/envelope convention for all future list endpoints.

### Negative / Trade-offs
- **Breaking response shape** (array → envelope) for four endpoints; core and every web
  composable that lists them must change together.
- `COUNT(*)` per request plus title search (`ILIKE`) needs indexes to stay fast; plain
  substring search is not relevance-ranked and is not full-text search.
- Offset paging can show a row twice or skip one if data changes between page requests.

### Neutral
- Multi-skill/concept filtering on content nodes and exercises is left single-valued for now.

## Related ADRs

- [ADR-029: Course catalog and multi-path lifecycle — its "catalog stays small" assumption is
  superseded by this ADR for `GET /courses`](ADR-029-course-catalog-and-multi-path-lifecycle.md)
- [ADR-026: Content classification graph — source of the skill/concept ids filtered on](ADR-026-content-classification-graph.md)

---

*This ADR was decided on 2026-09-23. To revise, create a new ADR with Status: Supersedes ADR-031.*
