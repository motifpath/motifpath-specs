# MOT-114 — Monetization architecture audit

Date: 2026-10-12 (America/Fortaleza). Parent: [MOT-108](https://linear.app/motif-path/issue/MOT-108/m0-discovery-and-design-foundation). Scope: discovery only; no runtime implementation or approval of new contracts.

## Result and evidence limits

The existing platform supports authenticated learning, teacher authoring, published catalogs, copied paths and durable learning evidence. It has no monetization subsystem or provisioned Strapi instance. Commercial ownership, durable purchased-content delivery, licenses, grants, provider integration and an audited flag system are migration work, not existing capabilities.

Gilson confirmed in the MOT-114 working chat on 2026-10-12: **“Strapi is not provisioned.”** This is the deployment evidence for Strapi. No Strapi source, configuration, dependency or provisioning was found in the inspected repositories. There is consequently no installed version, deployed environment, model inventory, publication/i18n configuration, role configuration, webhook configuration or identifier mapping to audit.

This is a source audit, not a live cloud inventory or security penetration test. Cloud resources, production records and external provider accounts were not inspected. Hosting proposals must not be mistaken for deployed infrastructure. Tests listed below are existing evidence locations, not claims of tests executed in this audit.

### Inspected revisions

| Repository | HEAD | Working tree |
|---|---|---|
| motifpath-core | `ab8f6bf02d04a5c60192fa299e94c447395492dd` | Clean, `dev` |
| motifpath-web | `035a041558cc51bc4776751330fb3ad3ab05b66d` | `feat/MOT-95/heavy-tier-compact`, ongoing uncommitted editor changes; left untouched |
| motifpath-infra | `2c715d6668b18b494a0727e1fbbfd66b06cf3e79` | Clean, `main` |
| motifpath-specs | `9c2acb096aa78e9521e8ae31e0423b4bbb46cebe` | Clean before this report, `main` |

Web observations include its current working tree and are not a release baseline. Specs has no local or cached remote `dev` branch; this audit was initially prepared as a local documentation artifact. It is now shared through the MOT-107 epic task branch per Gilson’s instruction; no protected-branch commit was made.

## Services and datum owners

Paths below are relative to the named sibling repository. Authority means the service that validates/writes the datum, not necessarily a separate physical database.

| Service/system | Existing authoritative data | Storage/boundary | Evidence |
|---|---|---|---|
| Clerk | Sign-in identity and verified session subject; session display name | External identity provider | core: `services/core-domain/internal/adapters/http/auth_middleware.go`; web: `src/api/createApiClient.ts` |
| core-domain | MotifPath user UUID, unique Clerk mapping, role, locale; learning paths, copies, course enrollments/current selection; lessons, exercises, diagrams, songs and published snapshots; editorial settings | PostgreSQL through ent repositories; role is resolved from core records | core: `services/core-domain/internal/adapters/repo/ent/schema/`; `internal/application/identity_service.go`, relative to that service |
| event-ingestion | Durable tracking events and publication outbox | MongoDB; publishes to Kafka-compatible `motifpath.events` | core: `services/event-ingestion/internal/application/ingest_event_service.go` |
| aggregation-worker | Completion aggregates, practice evidence/folds/history, practice sessions, tap checks, learning activity and song completion projections | MongoDB; Kafka consumer, student-partitioned processing | core: `services/aggregation-worker/internal/ports/completion_state_repository.go`, `practice.go`, `activity.go` |
| core-domain reference sync | Practice reference snapshot used by worker graders | Writes MongoDB `practice_reference`; worker reads it | core: `services/core-domain/internal/adapters/repo/mongo_practice_reference_writer.go`; `cmd/sync-practice-reference/main.go` |
| Vue SPA | Presentation, navigation, editor state, event production; no authoritative rights or money | Vue 3, Pinia, Vue Router, i18n; typed openapi-fetch clients for core and events | web: `package.json`, `src/api/`, `src/router/guards.ts`, `src/features/` |
| Object store | Media bytes, not commercial permission | Local SeaweedFS; S3-compatible upload adapter returns public read URLs | core: `docker-compose.yml`; `services/core-domain/internal/adapters/repo/s3_media_storage.go` |
| Strapi | Nothing currently; planned editorial/commercial presentation metadata | Not provisioned | User confirmation above; repository search |
| Payment provider / commercial core | Nothing currently | No provider SDK, payment callbacks, purchase ledger, subscriptions, licenses or grants found | core service/schema inventory; web `package.json`; monetization keyword search |

Learning progress is authoritative within the backend, but today its derived records are owned by **aggregation-worker**, not written into PostgreSQL by core-domain. Core reads those MongoDB projections through `mongo_completion_state_reader.go`, `mongo_practice_item_state_reader.go` and `mongo_practice_activity_reader.go`. M0 contracts must preserve this distinction when saying “core owns progress.”

## Identity and trust boundaries

1. The SPA obtains a fresh Clerk bearer token per API request. Router guards handle registration and role-based navigation; they cannot enforce paid access (`src/api/createApiClient.ts`, `src/router/guards.ts`).
2. Core verifies Clerk tokens and resolves the application user/role from its own records. `User.clerk_user_id` is unique and immutable; role is an immutable student/teacher/admin enum. Roles describe capabilities, not Plus status or a commercial grant (`ent/schema/user.go`, `identity_service.go`).
3. Event ingestion resolves the token's subject through core before storage, then rejects an event whose student UUID differs from the resolved caller (`services/event-ingestion/internal/adapters/http/handler.go`, `internal/application/ingest_event_service.go`). Old middleware comments about unresolved identity and JWT admin roles are stale; actual handler/application behavior takes precedence.
4. Teacher/admin authoring authorization and path-owner checks exist. Exercise creator metadata is nullable for older records. Creator and teacher IDs are attribution/authoring controls; neither proves legal ownership, premium status or an embedding license (`learning_path_service.go`, `exercise_service.go`, `ent/schema/exercise.go`).
5. Core reads worker-owned projections; the worker reads a core-owned practice snapshot. A future commercial event stream needs explicitly defined consumers and ordering/idempotency rules. Learning telemetry must never itself grant a purchase.
6. Media upload authorization exists, but the returned object URL is public. API denial alone cannot protect a known premium image/audio/video URL. Protected assets need a delivery and cache policy before paid content ships (`media_service.go`, `s3_media_storage.go`).
7. Future CMS payloads, prices supplied by clients, checkout-return parameters and unverified provider callbacks are untrusted. Proposed boundary: core validates money, ownership, licenses, grants and purchase state; CMS controls approved presentation fields only. This boundary is required by MOT-108, not implemented yet.

## Copies, versions and retained progress

| Area | Observed behavior | Commercial gap |
|---|---|---|
| LearningPath | Teacher-owned template; draft/published; edits replace the live template; no path-version entity | Purchase fulfillment needs an approved immutable purchased-content reference and update policy |
| StudentPath | Copies item order, source template ID, title and presentation snapshots; item records include content-node version IDs; active standalone uniqueness excludes archived/course copies | A learner copy is not a purchase receipt or an access grant; archive/re-enroll must retain purchase rights |
| Lesson reads | `StudentPathService.composeView` reads live ContentNodes. `ContentService.GetContentNode` reads the current node; published node versions exist separately | Stored version IDs do not establish immutable learner delivery; purchases cannot assume full content is pinned |
| Courses | CourseVersion snapshots and pinned enrollment version numbers exist; part paths are copied as started | `checkpoint_advance.go` currently loads the latest course version, allowing drift despite the enrollment pin |
| Exercises/embeds | Reusable exercises linked to nodes/challenges, structured prompts with diagram/song references; mutable exercise data and nullable creator metadata | Need transitive dependency/version/provenance coverage, not just path-level validation |
| Progress | Completion keyed by student and content node; practice evidence/state/history keyed by student/item; copies and access are separate concepts | Preserve node/item identities and history across cancellation, expired access, withdrawal and rejoining; define content changes that affect item identity |

Evidence: core `services/core-domain/internal/adapters/repo/ent/schema/{learning_path,student_path,student_path_item,course_enrollment,content_node_version,course_version,exercise}.go`; `internal/application/{student_path_service,learning_path_service,content_service,checkpoint_advance}.go`; worker ports above.

[ADR-055](../adrs/ADR-055-update-a-copy-to-latest.md), accepted on 2026-10-12, already identifies live lesson reads, unversioned paths and checkpoint drift, and specifies explicit learner updates with retained progress. Those fixes are **specified, not present in the audited core revision**. MOT-119/MOT-117 must reconcile commercial immutable versions with ADR-055 instead of treating the update feature as implemented or silently changing its policy.

## Integration and migration map

Every runtime deliverable in MOT-108's downstream milestones is mapped below. Names shown are proposed ticket names, not an approved flag registry. All flags default OFF; server-side protection and UI mirroring, environment/cohort targeting and audited kill switches remain to be designed in MOT-115.

| Deliverable | Existing integration point | Required migration / contract work | Proposed flag |
|---|---|---|---|
| MOT-118 ownership/provenance | Author IDs on path/node/course; nullable exercise/diagram creators | Explicit platform/teacher ownership and provenance; classify legacy/seed content with evidence, not inferred from role; retain ownership history | `monetization.content_ownership` |
| MOT-119 published versions | Node/CourseVersion, SongChartRevision, StudentPathItem references | Immutable commercial path/dependency snapshots and purchase references; address live lesson/exercise/media references and ADR-055 | `monetization.content_versions` |
| MOT-120 Strapi metadata | No CMS integration | Provision CMS; map identifiers, editorial fields and rights declarations; authenticated versioned sync, retry/deduplication, reconciliation and withdrawal semantics | `monetization.strapi_rights` |
| MOT-121 commercial validation | Path publish/replace, exercise linking, prompt/diagram/song embeddings | Validate entire dependency graph and teacher embedding licenses on publish/update; prevent bypass through nested content or direct linking | `monetization.commercial_validation` |
| MOT-122 resolver | Path/course catalog, content/exercise/diagram/song reads, challenge/resource delivery, practice composition | One backend access decision, including previews/downloads/exports/remediation and transitive resources; distinguish prerequisites, locale locks and commercial denial | `monetization.entitlement_resolution` |
| MOT-123 grants | User UUID and learning copies/enrollments | Free, time-bounded subscription and permanent purchase grants with source/audit/idempotency; keep teacher licenses separate | `monetization.access_grants` |
| MOT-124 retention | MongoDB progress/evidence, Postgres copies/current selection | Access-independent history, recovery UX and stable identifiers; no cancellation-driven deletes or destructive grant/copy coupling | `monetization.progress_retention` |
| MOT-125 enforcement | Core handlers/application ports and real DB adapters | Apply resolver across all resource/practice paths and protected media; real persistence integration coverage for bypass attempts | `monetization.authorization_enforcement` |
| MOT-127 product/subscription APIs | Published catalogs and core API | Core product/offer/provider mapping, verified amount/currency/eligibility, subscription state and period history; CMS presentation joins | `monetization.plus_catalog`, `monetization.plus_checkout` |
| MOT-128 provider/webhooks | Learning-event outbox is a pattern only | New verified provider boundary; durable receipts, idempotent fulfillment, out-of-order events, retries/reconciliation; do not reuse client tracking as payment authority | `monetization.plus_checkout`, `monetization.plus_webhooks` |
| MOT-129 billing/cancellation | No billing screen or backend lifecycle | Approved effective-date/state transitions; provider billing management; preserve permanent purchases and progress | `monetization.plus_billing` |
| MOT-131 paid paths/purchases | Path owner/publish/catalog/enrollment flows | Offers, checkout, purchase receipts and permanent grants against pinned content; rights survive subscriptions and OFF states | `monetization.teacher_paid_paths`, `monetization.path_purchase` |
| MOT-132 embedding licenses | Shared exercise library and paid publication boundary | Teacher commercial license scope, validity, dependency coverage and audit; expiry/withdrawal policy before implementation | `monetization.premium_embedding_license` |
| MOT-133 commissions/refunds/settlement | No financial persistence | Immutable ledger and provider references, approved rounding/commission rules, refund/chargeback grant effects, settlement timing and reconciliation | `monetization.teacher_settlement` |
| MOT-134 end-to-end validation | Existing service/BDD/DB test infrastructure | Provider sandbox plus real DB journeys covering authoring, subscription, purchases, licensing, refund and settlement | All applicable flags; `monetization.private_beta` |
| MOT-135 rollout/rollback | Only schema-registered editorial AppConfig exists | Approved flag dependencies and cohort evaluation; OFF hides new commercial actions while honoring existing rights and allowing callbacks/reconciliation | Every runtime flag |
| MOT-136 recovery/observability | Health/readiness endpoints, learning outbox retry | Payment/CMS/grant/license audit correlation, reconciliation monitoring, alerts, replay and recovery rehearsals | Beta/webhook/settlement flags |
| MOT-137 private beta | Local Compose and hosting ADR | Provision safe environments, sandbox/live credentials, backups, release/rollback workflow and approved cohort; record readiness evidence | `monetization.private_beta` |

MOT-115 defines the registry/dependency graph; MOT-116, MOT-126 and MOT-130 define/approve commercial UX; MOT-117 defines contracts. None is a runtime flag or a claim of implementation approval. `AppConfigService` currently validates registered editorial settings (starting points) and records the last writer; it is not an audited flag history, cohort system or kill switch (`app_config_service.go`, ADR-052).

Existing API operations live in [core-domain OpenAPI](../openapi/core-domain-service.yaml); tracking contracts live in [event-ingestion OpenAPI](../openapi/event-ingestion-service.yaml). Monetization requires new contracts and updates to those affected reads/writes before handlers are changed. Generated Go/TypeScript clients must be regenerated through their existing scripts after approval.

## Strapi provisioning and responsibility inventory

All items below are **missing** and assigned to M0 contract decisions / MOT-120 execution, not configurations selected by this audit:

| Concern | Provisioning or contract required |
|---|---|
| Version/runtime | Choose and pin supported Strapi version, runtime, plugins and upgrade process; no current version to report |
| Environments | Repo/service ownership, hosting capacity, database, persistent media, staging/production isolation, DNS/TLS, backups/restore and secrets |
| Models | Editorial offer/product descriptions, localized presentation, provenance/rights declarations and availability; define per-field authority with core |
| Publication/i18n | Draft/publish workflow, locales, reviewed revisions and effective publication; relate CMS publication to core commercial availability |
| Roles | Editorial/admin roles, restricted API/service credentials; authenticated sync; no editor may directly issue core grants or alter authoritative prices/ledger |
| Webhooks | Authenticated publication/update/withdrawal notifications, duplicate/out-of-order handling, retries, replay and periodic reconciliation; failure behavior |
| Identifiers | Stable core UUID ↔ CMS document/revision/locale mapping; no assumptions about version-specific Strapi identifier behavior until version is chosen |
| Rights | CMS may store declarations and editorial presentation; core validates authoritative ownership, licenses, money and access; deletion/unpublish cannot silently revoke a permanent purchase |

Do not move existing lesson/exercise authoring into Strapi by assumption. The current Vue/core authoring stack is implemented; contracts must explicitly decide whether CMS metadata attaches to it or replaces any limited presentation fields. Provisioning capacity must account for a new CMS runtime instead of assuming the existing VM proposal can absorb it.

## Hosting and operations

The infra checkout contains README/CLAUDE instructions and CI workflows, but **no Terraform modules/environments or deploy manifests**. Its README describes EKS/RDS/ECR/Secrets Manager and DynamoDB state locking; [ADR-039](../adrs/ADR-039-single-vm-hosting-with-staging.md) supersedes the hosting design with a single EC2 VM, isolated staging/production Compose projects, managed RDS/Atlas, S3/CloudFront, Caddy, SSM and S3-native state locking. This is an accepted target design, not deployment evidence. Core CI has test/image-smoke support; no image-publish/deploy workflow was found.

Before commerce launch: reconcile infra docs with ADR-039, provision application/CMS/provider environments, separate secrets and callback endpoints, add protected media delivery, persistent storage/backup restoration, migration rehearsal, deploy/revert workflows and payment/CMS reconciliation operations. No infrastructure was provisioned by this audit.

## Reuse existing design work

[MOT-63 sign-off](../design/MOT-63-design-sign-off.md) records PO approval on 2026-10-09 for MOT-43 implementation slices. Its [Experience Language Figma file](https://www.figma.com/design/TJmPotheGhPe5npXMZWQEB) supplies reusable design patterns, not approval of new monetization flows.

MOT-116 should extend the existing [discover](../design/patterns/discover.md), [learning](../design/patterns/learning.md), [path](../design/patterns/path.md), [authoring](../design/patterns/authoring.md), [states](../design/patterns/states.md), [overlays](../design/patterns/overlays.md) and [unavailable/error](../design/patterns/unavailable-and-errors.md) patterns. Vue already supplies AppShell, OverlayLayer, authoring rows and state/notice components under `src/shared/components/`, with Storybook and unit coverage. The ongoing MOT-95 editor work must not be duplicated or treated as completed here.

New flow coverage: free/Plus catalog and offers; checkout pending/failed/success/return; subscription management/cancellation; permanent-purchase library; free teacher authoring plus paid publishing/pricing; license denial/expiry; refund/settlement; retained progress when access expires; loading/empty/denied/error/OFF states. Each needs the MOT-116 PO approval record with file/frame links, reviewed revision and date before implementation.

## Decisions handed to MOT-117

- Provider and provider-neutral IDs/events; prices/currencies, eligibility and price changes.
- Cancellation effective date and subscription periods; retries, grace and rejoin behavior.
- Commercial content/version/dependency model, content updates and ADR-055 interaction; policy for withdrawal while keeping permanent purchase obligations.
- Teacher license scope/expiry, existing purchases when licenses expire, and platform premium embedding permission.
- Refund/chargeback effects on grants; commissions/rounding, settlement timing and reconciliation.
- Exact CMS/core per-field authority, authenticated sync semantics and availability during CMS outages.
- Free grants/backfill for existing users/content, provenance correction for nullable creators, and safe expand/backfill/contract migration order.
- Protected media/exports and resolver coverage; approved denial reasons separate from learning prerequisites.

Fixed constraints remain: teacher creation tools are free; purchased teacher paths grant permanent access independent of student Plus or teacher subscription; cancellation never deletes progress; student Plus is not a teacher embedding license. No unresolved financial rule was invented in this audit.

## Acceptance evidence and next gates

| MOT-114 criterion | Evidence/result |
|---|---|
| Actual services and datum owners | Inventory and trust-boundary sections, schema/application/port sources above |
| Monetization integration points and migrations | All runtime deliverables mapped; version/content delivery, media, provenance, persistence, flags, CMS and hosting gaps identified |
| Strapi deployment/provisioning | Explicit user confirmation that it is not provisioned; absent repository artifacts; provisioning inventory above |

Existing validation assets to extend after contract approval: core `services/core-domain/internal/adapters/repo/*integration_test.go` (Postgres/MongoDB); event-ingestion and aggregation-worker application/BDD suites; specs `features/`; Vue feature tests and Storybook. No new behavior tests or runtime changes are part of this documentation audit. Later implementation must start with failing behavior tests, including real persistence coverage for grants and financial idempotency, protected-resource bypass, permanent purchases across cancellation/OFF, content updates/withdrawal, and callback recovery during rollback.

MOT-114 discovery evidence is ready for review. MOT-115 registry approval, MOT-116 new Figma approval and MOT-117 approved business/OpenAPI/event/Gherkin contracts remain required. This report does not close MOT-108 or unblock monetization code.
