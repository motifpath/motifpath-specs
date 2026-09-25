# ADR-037: Every user can learn, through a role-independent learner catalog

**Status:** Proposed
**Date:** 2026-09-25
**Deciders:** Gilson (PO), Claude Code

---

## Context

ADR-017 made "student" a role and put learner state in a role-scoped table:
`StudentLearningState` "has a row only for users who are students", so a teacher's or admin's
row could never carry path state. ADR-029 built the course catalog on the same premise. `GET
/courses` returns the published catalog to students, and teachers and admins get their authoring
list: every status, and for a teacher only the courses they created. Self-enrollment, course
enrollments, standalone paths and the current-path switch were all refused to non-students. The
one exception came later, in code rather than an ADR: an admin may act as a student, to try the
learner side with their own account.

That premise no longer holds. Every MotifPath user can use the platform as a student (Gilson,
2026-09-25). A teacher takes other teachers' courses, and a staff member can follow a path of
their own. Two things break as a result.

1. **The learner endpoints refuse teachers.** Enrolling, listing enrollments and standalone
   paths, switching the current path, and being assigned a path all return 403, or 404 for an
   assignment target, for a teacher.
2. **`GET /courses` can't serve a teacher as a learner.** For a teacher it is scoped to their own
   courses, drafts included, and it evaluates filters against the live draft. A teacher browsing
   as a learner needs the opposite: every creator's published courses, read from each course's
   latest published version. `GET /courses/creators` has the same split. One endpoint whose
   meaning depends on the caller's role can't give one caller both views.

We considered two ways to give any caller the learner catalog.

- **A `view=catalog` parameter** on `GET /courses` and `GET /courses/creators`, returning the
  learner view to any caller. It's additive and non-breaking, but one path would keep two
  meanings that differ in visibility, source (published version or live draft) and scoping,
  switched by a flag.
- **Separate catalog endpoints**, one resource per audience. This is a breaking change for
  student clients of `GET /courses`.

## Decision

**Learning is a capability of every user, not of the student role.** Any authenticated user,
whatever their role, may:

- self-enroll in a course;
- list and abandon their own course enrollments;
- list and archive their own standalone paths;
- read and switch their current path;
- be assigned a path by a teacher or admin.

The role checks on those operations are removed. `StudentLearningState` becomes "the learner
state of any user who has started learning", created on first use exactly as today. Roles still
decide **authoring** (teachers and admins) and **publishing and retiring** (admins), unchanged.

**The learner catalog gets its own resources, the same for every caller:**

- **`GET /catalog/courses`** lists the published courses only, each rendered from its latest
  published version. It takes the pagination, text, level, creator (a free filter for everyone),
  skill and concept filters `GET /courses` offers students today. Filters are evaluated against
  the latest published version, and results never carry authoring annotations.
- **`GET /catalog/creators`** lists the distinct creators of published courses, with the same
  name filter and name ordering as `GET /courses/creators`.

**`GET /courses` and `GET /courses/creators` become authoring-only.** They serve teachers and
admins with their current scoping: a teacher sees their own courses, an admin sees every course,
of every status. A student caller is refused with 403. `GET /courses/{course_id}/published` is
unchanged; any authenticated user may read a published course's outline.

## Rationale

- **Separate endpoints over a `view` flag.** The catalog and the authoring list differ in who is
  visible, which data they read and how they're scoped. Giving each its own resource makes every
  endpoint mean one thing for every caller. Neither needs a role-dependent reading, and the
  catalog can't leak drafts because a flag was forgotten. The cost is a breaking change for
  student clients of `GET /courses`. Before launch that's acceptable: the web client is the only
  consumer, and it changes in the same release, as ADR-031's envelope change did.
- **Removing the role checks rather than listing more roles.** Widening the check to "student,
  teacher or admin" would still name every role. It would silently exclude any role added later,
  and it would keep suggesting that learning is role-bound. Plain authentication says what's
  actually true.
- **Keeping `StudentLearningState` as its own table.** ADR-017's reason for the table still
  stands, since `User` stays free of learner columns. Only the "students only" invariant goes. No
  schema change is needed, because the table is keyed by `user_id` with no role constraint.

## Consequences

### Positive
- Teachers and admins use exactly the learner experience students get, which makes dogfooding
  and staff onboarding possible.
- Each catalog and authoring endpoint has one meaning for every caller, so no role-dependent
  documentation is needed.
- The learner catalog is always read from published versions, even for an admin.

### Negative / Trade-offs
- **Breaking:** student clients must move from `GET /courses` and `GET /courses/creators` to the
  `/catalog` endpoints before this ships. The web client, core and the BDD suite change together.
- Scenarios that assert a teacher is refused, such as self-enrolling, listing their standalone
  paths, or being assigned a path, are reversed. The behavior shipped in PB-31/PB-32 changes.
- Learner analytics will now include staff activity. Any future learner metric must decide
  whether to exclude staff accounts; the role still says who they are.

### Neutral
- Admin-only publishing is still the only guard on what enters the catalog (ADR-029).
- "Student" stays a role, meaning a user who can't author. It no longer means "the only kind of
  user who can learn".

## Related ADRs

- ADR-017: Student path copied instance. Amended here: `StudentLearningState` is no longer
  restricted to users with role student.
- ADR-029: Course catalog and multi-path lifecycle. Amended here: the catalog read moves to
  `/catalog/*` for every caller, `GET /courses` becomes authoring-only, and self-enrollment is
  open to every user.
- ADR-031: Offset pagination. `GET /catalog/courses` uses the same envelope, and
  `GET /catalog/creators` stays an unpaginated, bounded list.

---

*This ADR was decided on 2026-09-25. To revise, create a new ADR with Status: Supersedes ADR-037.*
