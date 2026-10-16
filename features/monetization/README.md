# Monetization contracts — MOT-117

This directory is the consolidated contract index for the monetization epic. Business decisions
from 2026-10-13 through 2026-10-15 are incorporated; scenarios remain `@wip` until runtime
implementation passes TDD. PR approval accepts proposed API details, not a deployment.

## Decisions and source contracts

- [ADR-059: commercial authority, audit and idempotency](../../adrs/ADR-059-commercial-authority-audit-and-idempotency.md), accepted; renumbered from the colliding ADR-057 without changing the decision.
- [ADR-058: Stripe](../../adrs/ADR-058-stripe-payment-provider.md), accepted.
- [ADR-060: transactional records and recovery](../../adrs/ADR-060-commercial-records-and-recovery.md), accepted by Gilson Yamada on 2026-10-15.
- [Commercial architecture and policies](../../openapi/commerce-contract.md): ownership, manifests, licenses, grants, ledger/rounding, settlement, refunds/disputes, CMS, delivery, retention and recovery.
- [Core-domain API](../../openapi/core-domain-service.yaml): existing subscription/refund/Stripe/audit/access operations plus consolidated commerce operations.
- [Commercial domain schemas](../../openapi/components/schemas/commerce.yaml) and [private message schemas](../../openapi/components/schemas/commercial-messages.yaml).
- [Stripe processing profile](../../openapi/stripe-event-processing.md): verified receipts, account/mode isolation, uniqueness and recovery.

## Behavior coverage

| Contract | Coverage |
|---|---|
| [Subscription lifecycle](subscription-lifecycle.feature) | Platform/course/path monthly and annual billing, renewal, cancellation, grace and retained completion |
| [Subscription commands](subscription-commands.feature) | Caller ownership, revisions, rollback and durable idempotency |
| [Refunds and chargebacks](refunds-and-chargebacks.feature) | Refund scope, paid-access window, independent grants and pending disputes |
| [Refund commands](refund-commands.feature) | Caller cases, admin execution and per-payment uniqueness |
| [Teacher commercial rights](teacher-commercial-rights.feature) | Permanent purchases/licenses, retained copies, free updates and future-earnings recovery |
| [Stripe ingestion](stripe-payment-ingestion.feature) | Verified payment receipts and acquisition intent |
| [Payment reconciliation](payment-reconciliation.feature) | Duplicate/out-of-order recovery, unknown outcomes and notices |
| [Commercial audit](commercial-audit.feature) | Immutable evidence, attempts, causality and admin inspection |
| [Commercial access](commercial-access.feature) | Caller copy, independent rights, privacy and delivery-time checks |
| [Content contracts](commercial-content-contracts.feature) | Provenance, immutable manifests, dependency licensing and withdrawal |
| [Acquisition contracts](commercial-acquisition-contracts.feature) | Configured offers, path/license checkout and holdings |
| [Financial contracts](commercial-financial-contracts.feature) | Exact refund deadline, admin review/retry, final disputes, rounding and settlement |
| [Integration contracts](commercial-integration-contracts.feature) | CMS hints, private messages, audit coupling, media bypass and restore fencing |

## Rollout controls

[Commercial activation registry](../../openapi/commercial-rollout-contract.md) defines proposed
MOT-115-r3 names, ownership, default-OFF targeting, independent readiness tracks and audited
rollback. [Commercial control scenarios](commercial-controls.feature) cover activation boundaries;
registry and Figma approvals remain separate from contract integration.

## Deliverable and flag mapping

Flag names below match the proposed MOT-115 registry; registry approval is tracked in MOT-115,
not asserted here. Every default is OFF. New actions require backend evaluation and cohort
approval; OFF never disables existing rights, progress, audit, cancellation, refund, reconciliation
or settlement obligations. UI mirrors decisions. Plus and teacher commerce have separate readiness.

| Ticket | Proposed flag(s), prefix `monetization.` | Contract surface and scenarios |
|---|---|---|
| MOT-118 | content_ownership | Commerce ownership read/correction; content contracts |
| MOT-119 | content_versions | Immutable commercial release manifests; preserve existing course/path copies and ADR-055 |
| MOT-120 | strapi_rights | CMS hint API, field authority/mapping/reconciliation; integration contracts |
| MOT-121 | commercial_validation | Release and sale-state commands, transitive dependency/license validation; content contracts |
| MOT-122 | entitlement_resolution | Commercial access API and grant schema; access scenarios |
| MOT-123 | access_grants | Typed grant/payment/purchase/license facts; acquisition, refund and reconciliation scenarios |
| MOT-124 | progress_retention | Existing worker-owned progress, completed-lesson retention; lifecycle/access scenarios |
| MOT-125 | authorization_enforcement | Protected lesson/exercise/media/export boundaries; integration/access failure scenarios |
| MOT-127 | plus_catalog, plus_checkout | Subscription offer configuration/list and checkout; subscription/acquisition scenarios |
| MOT-128 | plus_webhooks, plus_checkout | Stripe receipt and verified payment processing; ingestion/reconciliation scenarios |
| MOT-129 | plus_billing | Cancellation/switch, renewal grace and notices; lifecycle/command/recovery scenarios |
| MOT-131 | teacher_paid_paths, path_purchase | Sale-state/offer, checkout and permanent holdings; acquisition/content scenarios |
| MOT-132 | premium_embedding_license | Path-license offers, acquisition and dependency checks; content/acquisition scenarios |
| MOT-133 | teacher_settlement | Full refund review/retry, journal, balances/settlement history and internal transfer obligations; financial scenarios |
| MOT-134 | each affected flag | End-to-end acquisition, refund, expiry, retained purchase and failed delivery scenarios across this directory |
| MOT-135 | each affected flag | OFF/restart/replay scenarios; no lost existing obligation or unrestricted protected content |
| MOT-136 | plus_webhooks, access_grants, strapi_rights, premium_embedding_license, teacher_settlement, private_beta | Recovery/alerts, journal/inbox/outbox/evidence integrity and CMS reconciliation |
| MOT-137 | private_beta | Independent Plus-first and teacher readiness; scoped cohorts with all existing-right safeguards |

MOT-114/115/116/117 and MOT-126/130 are audit, registry, design or contract gates, not separate
runtime switches. MOT-119 implementation must preserve existing lesson rendering/update behavior;
commercial manifests do not replace live path editing with a new publication/version process.

## Reviewed acquisition and pricing boundaries

License acquisition validates the owning teacher/path and ownership revision without requiring
an already-licensed sale manifest. License offers use release_id=null; the issued license binds
the accepted offer. Buyer path offers still require full manifest/dependency validation.
Subscription price replacements require expected_offer_id (null for first creation), with
atomic comparison/promotion. Admin current-offer reads work even when acquisition is OFF.

## Audit retention and asynchronous export

The recent Postgres audit table has a **30-day (720-hour) TTL from recorded_at**. A separate
asynchronous worker exports hourly batches to S3 Object Lock, with an alert when the oldest
unverified entry exceeds two hours. Hourly cleanup deletes expired hot rows only after exact archival proof
and hold checks. Failed export or verification retains evidence beyond TTL and raises alerts.
Financial/idempotency records have separate lifecycles; the audit TTL cannot erase them.
Long-term archive retention remains seven years after closure. Audit reads span both stores
through a mandatory compact operation/resource locator index, retained with the archive.
Cleanup requires complete verified locator coverage; historical reads fetch only matching
page batches and fail explicitly if the index is unavailable/rebuilding.
See [the export/cleanup contract](../../openapi/commerce-contract.md#hot-audit-ttl-and-asynchronous-archival)
and [retention scenarios](audit-archival.feature).

## Acceptance and remaining external gates

ADR-060 was accepted by Gilson Yamada on 2026-10-15. The consolidated PR completes the
specification surfaces for MOT-117; its review must accept API additions, message schemas and
scenarios before MOT-117 is marked done. No runtime evidence is claimed by syntax/schema checks. MOT-115 registry and
MOT-116 Figma approvals remain separate blockers to implementation; no approval is fabricated.

Deployment inputs remain explicit: approved prices/discounts/bounds/commissions and BRL offers;
Brazilian Stripe/Connect capabilities, fees and refund liquidity; pinned compatible SDK and CMS
runtime when provisioned; credential rotation, retention/privacy approval and tested restore/media
protection. Missing configuration keeps the relevant acquisition OFF. USD, partial-refund automatic
execution, alternative providers and changes to existing learner update semantics are not enabled.
Gilson owns commercial rollout, reconciliation and editorial approval. Plans/research stay local.
