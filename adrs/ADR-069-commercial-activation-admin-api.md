# ADR-069: Commercial Activation Lives in Core, Changed Through a Dedicated Admin API

**Status:** Proposed
**Date:** 2026-11-02
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-181

---

## Context

The commercial activation registry (MOT-115-r5, approved 2026-11-02) names 17 `monetization.*`
flags. Each one defaults to OFF in every environment and has a subject allowlist and
prerequisites. Core evaluates them server-side, and every activation change must be audited and
revision-checked. A committed OFF must fence new intents, and if the activation decision is
unavailable, new commercial effects are denied. The registry says what an activation change must
record (actor, reason, time, environment, operation identity, affected flags and cohorts, prior
and new revisions, all committed with durable evidence). It does not say where activation is
stored or how an administrator changes it.

MOT-181 builds the shared commercial foundations (audit evidence, idempotent commands, rollout
evaluation), and MOT-118 is the first ticket that depends on a flag. So this has to be decided
before either is implemented.

Core already has one runtime-settings mechanism: the `app_config` key/JSON table with its generic
admin API (ADR-052). It was designed for editorial settings. It has no revision precondition, no
idempotency key and no audit coupling. The alternative to both is deploy-time configuration
(environment variables or infra files per environment).

## Decision

MotifPath will store commercial activation in a dedicated core-domain table: one row per
registered flag, plus one environment-wide **activation revision**. Administrators change it only
through a dedicated admin API that follows the same command rules as every other commercial
mutation:

- `GET /admin/commercial-rollout` returns the activation revision and, for every registered flag,
  its configured state (`enabled`, `subject_ids`), its prerequisites, whether it is effective
  (enabled and every prerequisite effective), and who changed it last and when.
- `PUT /admin/commercial-rollout/{flag}` replaces one flag's `enabled` and `subject_ids`. It
  requires an `Idempotency-Key`, the observed `expected_revision` and a `reason`. A stale revision
  returns 409. A same-intent replay returns the original result; conflicting reuse of a key
  returns 409.
- `POST /admin/commercial-rollout/kill-switch` turns every flag OFF in one change. It requires an
  `Idempotency-Key` and a `reason` but no `expected_revision`, so a stale screen or script can
  never block it. Allowlists are kept, so turning a flag back on is a deliberate per-flag change.

Every applied change increments the activation revision by one and is committed in the same
transaction as its audit evidence (before and after state, actor, reason, revisions). If the
evidence cannot be written, nothing changes. Only an administrator resolved from authoritative
backend identity may call these endpoints. The environment is the trusted deployment's own; each
environment has its own database, so no environment can inherit another's activation.

**Evaluation.** Core answers `allowed(flag, subject)`. The answer is yes only when the flag is
enabled, the subject is in its allowlist, and every prerequisite is allowed for the subject that
the operation names for it. An empty allowlist allows no one; there is no wildcard and no
percentage targeting. Subjects are `user:<core user id>` or `service:<service name>`. Each
operation's contract names its subject: buyer, owning teacher, resource owner or service. For
`content_ownership` corrections, the subject is the content's current owner, which is the
MotifPath Catalog profile for platform content. A missing row, an unknown flag or a failed read
denies, and the operation returns 503 for a read failure and 403 otherwise.

**Fencing.** A new commercial intent is authorized and durably recorded in one transaction that
holds a shared lock on the activation revision and stores the revision it was authorized under.
Activation changes take an exclusive lock. After an OFF change commits, no new intent can be
authorized under the older revision. An intent authorized before it keeps its recorded revision
and stays recoverable.

## Rationale

**Reusing `app_config` (ADR-052) was rejected.** It would have meant less new code, but every flag
change would replace one large JSON document. The admin API would also have needed a revision
precondition, an idempotency key and audit coupling, which none of ADR-052's editorial keys need.
Bolting those onto a generic API would make it carry commercial rules it otherwise never sees.
Concurrent edits to different flags would also conflict on the one document.

**Deploy-time configuration was rejected.** A kill switch that needs a deploy is too slow to stop
an incident in payments. It also has no audited activation revision and no fencing of in-flight
intents, both of which the approved registry requires.

A dedicated table and API cost one more admin surface. In return, activation follows exactly the
same revision, idempotency and evidence rules as every other commercial command, which is easier
to reason about and to test.

## Consequences

### Positive

- The kill switch is a single API call that takes effect without a deploy, and it cannot be
  blocked by a stale revision.
- Every activation change is attributable and reconstructable from the commercial audit trail.
- Fencing makes "OFF means no new intent" hold under concurrency, not just eventually.
- Flags and prerequisites are registered in code. An unregistered flag is not found and cannot be
  enabled by mistake.

### Negative / Trade-offs

- There is no screen yet. The team changes activation with curl or a make target, as with
  ADR-052, so typing mistakes in subject ids are possible. The read shows the effective result,
  which mitigates this.
- Every new commercial intent takes a shared lock on one row. That is negligible at alpha volume,
  but it is a serialization point to watch if write volume grows.
- Two admin config surfaces now exist (`/admin/config` and `/admin/commercial-rollout`), and
  contributors must know which one a setting belongs to. Commercial activation never goes into
  `app_config`.

### Neutral

- The registry's 17 flags and their prerequisite graph become a code-level registry in
  core-domain, and the OpenAPI enum must change with it.
- The admin audit read (`listCommercialAuditEntries`) is built over Postgres in MOT-181. Archive
  export, the locator index and TTL cleanup stay in MOT-136, and no hot evidence is deleted before
  they exist.

## Related ADRs

- ADR-052: A Key/JSON App Config with a Generic Admin API — the general mechanism this deliberately
  does not reuse.
- ADR-059: Commercial authority, audit and idempotency — the command, evidence and replay rules
  this API follows.
- ADR-060: Commercial records and recovery — the transactional coupling of effects and evidence.
- ADR-044: System catalog curator — the platform subject for resource-owner rollout.

---

*This ADR was proposed on 2026-11-02. To revise, create a new ADR with Status: Supersedes ADR-069.*
