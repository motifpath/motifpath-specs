# ADR-035: User display names and UserRef user references

**Status:** Proposed
**Date:** 2026-09-24
**Deciders:** Gilson (Product Owner)

---

## Context

MotifPath stores no user names. The core `User` record holds only `clerk_user_id`, `role`,
`locale_id` and `registered_at`; neither `RegisterUserRequest` nor `UserProfile` carries a name.
The web app only knows the *signed-in* user's name, read from the Clerk session on the client.
No earlier ADR decided against storing names. No feature had needed them until now.

PB-32's student course catalog needs them now. Students need to find courses by teacher, but
`CourseCatalogEntry.created_by` is an opaque `user_id`. The web can't show "Courses by Ana
Souza" or offer a teacher dropdown. The gap isn't limited to the catalog. Every response schema
that points at a user carries only a bare id:

| Schema | Field | Who it points at |
|---|---|---|
| `ContentNode` | `teacher_id` | author |
| `LearningPath` | `teacher_id` | author |
| `StudentPath` | `student_id` | owning student |
| `StudentPath` | `assigned_by` | assigning teacher/admin |
| `Course` | `created_by` | author |
| `CourseCatalogEntry` | `created_by` | author |
| `CourseEnrollment` | `student_id` | enrolled student |
| `Diagram` | `created_by` | author (the bootstrap admin for migrated diagrams, per ADR-032) |

Fixing only the catalog would leave seven other schemas with the same gap and invite a different
ad-hoc fix each time. The decision has to cover every user reference at once.

Clerk is the identity provider (ADR-007), so Clerk already holds each user's first and last
name. Google OAuth, the only MVP login method, supplies both. Sign-up is the only way into the
platform, and Clerk can make first and last name required fields in its sign-up form. The open
questions are:

- how core gets that name and keeps it current,
- how names reach API responses,
- what happens when a name changes, for example after marriage.

Names can change, so storing a copy of the name on each course, path or content node would
leave stale copies everywhere. We considered three ways for core to get the name:

1. Read it from a custom claim in the Clerk session token (JWT) that every request already
   carries.
2. Fetch it from the Clerk Backend API at registration, then keep it in sync with a signed
   `user.updated` webhook.
3. Re-fetch it from the Clerk Backend API each time the web calls `GET /users/me`.

A name is personal data under LGPD, so the ADR also has to decide who may see whose name.

## Decision

**Source and storage: one copy per user, owned by Clerk**

- **Clerk configuration (every instance, dev and prod):** first and last name are required at
  sign-up. The session-token template adds `"name": "{{user.full_name}}"`.
- **Storage:** core stores the name in `users.display_name`, which is **NOT NULL**. This column
  is the only place in MotifPath's database where a user's name is stored. No other table ever
  gets a copy of it.
- **Registration:** `POST /users` stores the claim's value, trimmed and capped at 200
  characters. It rejects with 422 when the claim is missing or empty, so no user row can exist
  without a name. The name is never accepted from a request body. It comes only from the
  Clerk-signed, already-verified JWT.
- **Updates:** on every authenticated request, the caller-resolution step (`resolveCaller`)
  compares the claim with the stored value. It writes when they differ. A rename in Clerk, such
  as a new surname after marriage, updates that single row. Every response that references the
  user shows the new name from then on. A missing or empty claim on a later request is ignored,
  so it never overwrites a stored name.
- **Users created outside Clerk's sign-up form:** seed scripts give every user they create a
  name. The admin setup step (`ensureAdmin`) fetches the real name from the Clerk Backend API,
  using the `CLERK_SECRET_KEY` core already holds. The migration that adds the column fills in
  names for existing rows before it adds the NOT NULL constraint. Only dev databases exist
  today, so a reset followed by the seed scripts is enough.

**API exposure: a shared `UserRef` object**

- A new component schema, `UserRef { user_id: uuid, display_name: string }`, both fields
  required. It's the only way a response refers to another user.
- All eight fields in the table above become `UserRef` objects and are renamed to drop the
  `_id` suffix:
  - `ContentNode.teacher_id` → `teacher`
  - `LearningPath.teacher_id` → `teacher`
  - `StudentPath.student_id` → `student`
  - `StudentPath.assigned_by` → `assigned_by`
  - `Course.created_by` → `created_by`
  - `CourseCatalogEntry.created_by` → `created_by`
  - `CourseEnrollment.student_id` → `student`
  - `Diagram.created_by` → `created_by`
- `display_name` is resolved **at read time** by joining to `users`. It is never copied onto
  the referencing entity.
- `UserProfile` gains `display_name`, so users can see what the platform shows about them.
- Request bodies and query parameters keep plain ids (`created_by`, `student_id`, and so on).
  Only responses change.

**Visibility**

- A `UserRef` appears only in responses the caller is already authorized to receive. Each
  endpoint's existing access checks apply.
- The name of a teacher or admin is visible wherever their content is visible.
- A student's name is visible only to that student and to teachers and admins who already have
  a relationship with the student through the API (the assigner of their path, the owner of a
  course they're enrolled in). It is never visible to other students.

## Rationale

**One stored name, joined at read time, instead of copies on each entity.** A per-entity copy
(a snapshot) would have to be updated on every course, path and node a user touched whenever
the user changed their name. Any update that got missed would leave the old name in place. With
one row per user, a rename is a single update, and consistency comes for free. Joining one
indexed primary key per referenced user is cheap at MotifPath's scale.

**NOT NULL instead of nullable.** A nullable name would force every consumer to handle "no
name" forever, just to cover edge cases we control: seed data, users created in the dashboard,
and rows that existed before this change. Rejecting registration without a name and filling in
names during the migration costs a little work once, and it keeps the invariant "every user
has a name" true everywhere.

**The `UserRef` object won over sibling `*_name` fields and a lookup endpoint.** Sibling fields
(`created_by` plus `created_by_name`) would double the fields for each reference. They would
also look like stored snapshots, which is the misreading this ADR wants to rule out. A
`GET /users?ids=…` lookup would add a round-trip to every list view. It would also need its own
authorization logic to enforce the visibility rule. With one shared `UserRef` schema, each
reference is one field, looks the same everywhere, and has one generated type in the web
client. It can also take new fields later, such as an avatar. The cost is a breaking change
(see Consequences). We accept it for the same reason as ADR-031's pagination envelope: the
platform is pre-launch, and core and web ship together.

**The session-token claim won over the Backend API with a webhook** because it needs no new
infrastructure. A webhook needs a publicly reachable endpoint, Svix signature verification, a
secret per environment, retry and ordering handling, and a tunnel for local development. That
is a lot of moving parts for one string. The claim rides on a token core already verifies on
every request, so it costs no extra network call. Name edits made through Clerk's profile UI
reach core within one token refresh (about 60 seconds, per ADR-007) on the user's next request.
The webhook would not deliver them much faster in practice.

**The claim also won over a Backend API call on `GET /users/me`.** That option adds a
synchronous call to a third party on the app-start path. It exposes us to Clerk's Backend API
rate limits. It only refreshes when that one endpoint is called. The claim refreshes on every
request at no cost.

**This does not contradict ADR-013.** ADR-013 moved *role* off a Clerk JWT claim because a
misconfigured or stale claim, maintained by hand in the Clerk template, is an
authorization-correctness risk. A display name is never used for authorization. If the claim is
misconfigured, the worst case is that registration fails loudly with a 422, which is easy to
spot and fix. Wrong permissions would not be. Clerk is also the real owner of the name, whereas
core owns role.

**Full name, not first name only,** because the teacher filter has to tell apart teachers who
share a first name. Teachers author public-facing content, so a full name is expected. The
visibility rule, not a shorter name, protects students.

## Consequences

### Positive
- Every screen that shows a user reference (catalog, authoring lists, path assignment,
  enrollments) can show a name. There's one rule and one schema, not a fix per screen.
- A rename in Clerk is reflected everywhere after one row update. There are no stale copies.
- Every user always has a name, so consumers need no fallback handling.
- No new endpoint, webhook, secret or tunnel. The sync logic is one comparison in the existing
  caller-resolution step.
- MotifPath doesn't need its own name-editing screen, because Clerk's profile UI is the editor.

### Negative / Trade-offs
- **Breaking API change** across seven response schemas (eight fields). Core and every web
  consumer must change in the same release. The open web branches (PB-32 catalog, PB-57
  diagrams) must be rebased onto the new client.
- The session-token template and the required-name setting live in the Clerk dashboard, not in
  code. They must be set by hand in every Clerk instance and can drift. If they drift, new
  registrations fail with 422. This must be listed in the environment setup documentation.
- A stored name is only as fresh as the user's last request. A teacher who renames themselves
  in Clerk and never logs in again keeps the old name in MotifPath.
- List queries gain a join to `users`. Repositories must load the names in bulk (one query or
  an eager-loaded edge per page), not one query per row.
- A display name is user-controlled text. Every consumer must treat it as untrusted: escape it
  when rendering, and never use it as an identifier or for authorization.
- Storing names adds personal data to core's database. Any future account-deletion or
  data-export flow (LGPD) must include `display_name`.

### Neutral
- A write happens only when the name changes, so the per-request cost is one in-memory string
  comparison on a user row that is already loaded.
- Custom claims count toward Clerk's session-token size limit. One name claim is well within
  it.
- Event payloads (event-ingestion) keep plain `student_id`s. Events are a write-side record and
  don't render names.

## Related ADRs

- [ADR-007: Clerk authentication and JWT local validation — the identity provider and the verified token the claim rides on](ADR-007-auth-clerk-jwt.md)
- [ADR-013: Admin role authorization source — why role must not come from a JWT claim, and why a display-only name may](ADR-013-admin-role-authorization-source.md)
- [ADR-029: Course catalog and multi-path lifecycle — `Course`/`CourseCatalogEntry.created_by`, the first consumer](ADR-029-course-catalog-and-multi-path-lifecycle.md)
- [ADR-031: Offset pagination — precedent for a coordinated breaking response-shape change](ADR-031-offset-pagination-for-content-lists.md)

---

*This ADR was decided on 2026-09-24. To revise, create a new ADR with Status: Supersedes ADR-035.*
