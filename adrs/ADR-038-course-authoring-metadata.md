# ADR-038: Course language and reactivation, instruments and thumbnails, and a filterable path library

**Status:** Proposed
**Date:** 2026-09-25
**Deciders:** Gilson (Product Owner)
**Amends:** ADR-029 (course model and lifecycle) and ADR-026's content node model. It extends
the learning path library listing that ADR-031 paginated, and ADR-021's media uploads.

---

## Context

PB-65 adds the web pages where teachers and admins build courses. Reviewing that UI spec
surfaced five things the API can't do yet.

- **A course has no language.** Content nodes carry `languages`, and a learner whose locale
  matches none of a node's languages sees that node locked. A learner can therefore enroll in a
  course they can't actually follow, and nothing in the catalog helps them avoid it. Courses
  aren't localized (one title, one summary), so a course is written in exactly one language.
- **Retiring is final.** ADR-029's lifecycle is `draft → published → retired`, with no way
  back. An admin who retires a course by mistake, or wants to offer a seasonal course again,
  has to rebuild it from scratch. Rebuilding also loses its version history and its link to
  the people already enrolled.
- **Picking a learning path doesn't scale.** A checkpoint points at a learning path from the
  library, but `GET /learning-paths` only searches titles. Authors need to narrow the library
  by who made a path, how hard it is, and which skills and concepts it teaches. They also want
  to see recently changed paths first. A path has no difficulty level of its own, and no
  record of when it last changed.
- **Nothing says which instrument something is for.** A guitar course, an electric guitar path
  and a music theory lesson all look alike. Learners can't find material for their instrument,
  and authors can't find paths and content for the course they're building. Some material
  (music theory, for example) suits every instrument.
- **Nothing has a picture.** Courses, paths and content nodes appear in lists and cards as
  text only, which makes a catalog hard to browse.

## Decision

**1. Every course has exactly one language.** `Course.language` is a required
`Language.code`, never `"any"`, since a course has a written title and summary. Create and
replace both require it. The authoring list (`GET /courses`) and the learner catalog
(`GET /catalog/courses`) accept a `language` filter. It narrows the list to courses in that
language, evaluated against the live draft for authoring and against the published version for
the catalog, like every other filter. Publishing snapshots the language along with the title,
summary and level. Existing courses are backfilled to `"en"`, and admins correct them in the
builder.

**2. An admin can reactivate a retired course.** `POST /courses/{course_id}/reactivate` moves
a `retired` course back to `published`, back in the catalog with its latest published version.
It is admin-only, like publish and retire. It is refused for a course that isn't retired, and
it never creates a version. Retiring never changes or removes published versions, so there is
always one to return to. Unpublished draft edits stay unpublished: learners get the latest
published version, and the course keeps showing that it has unpublished changes until an
admin publishes them. The lifecycle becomes `draft → published ⇄ retired`.

**3. Learning paths gain an authored level and a last-updated time, and the library can be
filtered and sorted.**
- `LearningPath.level` uses the same five-value difficulty rubric as courses and content
  nodes. Create and replace require it. Paths created before this change have no level (the
  field is absent) until they're next saved, and they never match a level filter.
- `LearningPath.updated_at` is set when a path is created and whenever it's replaced.
- `GET /learning-paths` gains these parameters, all combining with AND:
  - `created_by`: paths created by that user;
  - `levels`: any of the given levels (repeatable);
  - `skill_ids` and `concept_ids`: a path matches when any of its content nodes is classified
    with any of the given skills, and, if both parameters are given, also with any of the given
    concepts. This is the same rule the course filters use.
- `sort` orders the results: `title` (the default: title, then id) or `updated` (most recently
  updated first, then id).

**4. Courses, learning paths and content nodes say which instruments they're for.** Each gains
`instrument_ids`: the instruments it suits, by `Instrument.instrument_id`. An empty list means it
suits **every** instrument (music theory, for example). Create, replace and update requests
require the field (it may be empty), every id must reference an existing instrument, and none
may repeat. Existing rows are backfilled with an empty list. The course, path and content node
lists (`GET /catalog/courses`, `GET /courses`, `GET /learning-paths`, `GET /content-nodes`)
accept an `instrument_id` filter. It matches items for that instrument **and** items for every
instrument, so a guitarist still finds music theory. Course and content node versions snapshot
the list (`instrument_ids_snapshot`), and the catalog filters on the published version.

**5. Courses, learning paths and content nodes can have a thumbnail.** Each gains an optional
`thumbnail_url` (an absolute http or https URL). Create, replace and update requests accept it,
and a replace or update that omits it removes the current one, as with `media_url`. It is
uploaded like other media: `POST /media/upload-url` gains the purpose `thumbnail`, which only
accepts images. Course and content node versions snapshot it (`thumbnail_url_snapshot`), so the
catalog shows the published picture, not a draft one.

## Rationale

**Reactivation is its own action endpoint, not a status field on `PUT /courses/{id}`.** `PUT`
replaces the draft's content, and the creating teacher may call it. Retiring and reactivating
are admin-only lifecycle changes. A writable status on `PUT` would give one request two
permission rules, depending on which fields changed. It would also have to reject most values:
`published` means "a version exists", which only publishing creates. `POST /publish` and
`POST /retire` are already action endpoints, so `POST /reactivate` follows the same pattern.

**One language per course, not a list and not `"any"`.** The course text is written once, so
it is in one language. A per-language course would need ADR-033-style localized fields, which
nobody has asked for. `"any"` suits content with no words, such as a diagram image, but never
a course, which always has a written title and summary.

**The path level is authored rather than derived from the content nodes.** Deriving it (a path
matches a level if any of its nodes has it) would need no new data. But a path mixing beginner
and advanced nodes would match both, which is the wrong answer for someone choosing a course
stage. The author knows what level the path as a whole is aimed at.

**Skill and concept filters stay derived.** A path's skills and concepts really are the union
of what its nodes teach, and that's how the course filters already work. Authoring them again
on the path would only let the two drift apart.

**Instruments are a list where empty means "every instrument", not an explicit "all"
marker.** A separate `all_instruments` flag would allow contradictory states (a flag plus a
list) that every writer and reader would have to reconcile. An empty list can only mean one
thing. The filter treats "every instrument" as a match, because that's what an author choosing
it intends.

**Instruments are authored on each level independently, not inherited.** A guitar course can
include a theory path that suits every instrument, so a course's instruments can't be derived
from its paths, and a path's can't be derived from its nodes. The builders can suggest values,
but the stored list is the author's.

**Thumbnails are URLs to uploaded images, not image data in the record.** This reuses ADR-021's
presigned uploads and object storage, like every other image in the platform.

**Existing courses are backfilled to `"en"` rather than to their creator's locale.** It's
predictable, and the few courses that exist so far were created by the team. Admins fix any
that are wrong.

## Consequences

### Positive

- Learners can find courses in their language, and the builder makes an author choose one.
- A retired course can come back without losing its versions or its enrolled learners.
- The checkpoint picker can narrow a large library quickly and show recent work first.
- Learners and authors can narrow courses, paths and content to their instrument without
  losing material that suits every instrument.
- Catalog cards and pickers can show a picture for each item.

### Negative / Trade-offs

- **Breaking request changes.** The course, learning path and content node create, replace
  and update requests all gain required fields. The web path builder and content authoring
  page must send them from now on, not just the new course builder.
- **Every existing item starts as "for every instrument"** until an author tags it. Until then
  an instrument filter shows everything old, which is noisier than it will be.
- **Authors do more per item**: instruments and a thumbnail on courses, paths and content
  nodes alike.
- **Existing paths have no level** until someone opens and saves them, so they're invisible to
  a level filter in the meantime.
- **The `"en"` backfill can be wrong** for a course written in Portuguese, until an admin
  corrects it.
- **Reactivation allows retire/reactivate churn.** Learners browsing the catalog may see a
  course disappear and come back. It stays admin-only to limit that.

### Neutral

- `sort` is the API's first sort parameter. Other lists can adopt the same shape later.
- Enrollments and existing published versions are unaffected. New course versions capture the
  language, instruments and thumbnail, and new content node versions capture the instruments
  and thumbnail.

## Related ADRs

- **ADR-029** (Course catalog and multi-path lifecycle): the course model and lifecycle this
  ADR amends (language, reactivation).
- **ADR-026** (Content classification graph): the difficulty rubric and the skill/concept
  classification the path filters reuse, and the content node model this ADR extends.
- **ADR-021** (Media storage strategy): the presigned uploads thumbnails reuse.
- **ADR-031** (Offset pagination for content lists): the paginated library listing gaining
  filters and sorting.
- **ADR-037** (Every user can learn): the learner catalog that gains the language filter.

---

*This ADR was proposed on 2026-09-25. To revise, create a new ADR with Status: Supersedes
ADR-038.*
