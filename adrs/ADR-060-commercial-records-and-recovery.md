# ADR-060: Transactional commercial records and recoverable integrations

**Status:** Proposed
**Date:** 2026-10-15
**Deciders:** Gilson Yamada
**Task:** MOT-117

## Context

Commercial rights, money, provider requests and CMS updates cross process boundaries. An audit
read API alone cannot guarantee that a paid grant, refund or free-to-paid transition has durable
evidence. Stripe may complete a command before the caller receives its response. CMS updates
can be duplicated or reordered. MotifPath must preserve learning progress and independent rights.

Existing core Postgres, the aggregation worker's progress ownership and learner-pulled updates
must remain usable. Strapi is not provisioned. A second financial authority in CMS, browser or
provider metadata would make paid access ambiguous. Provider idempotency caches are temporary.

## Decision

MotifPath will store authoritative commercial operations, immutable accepted offers/manifests,
payment facts, grants, license/purchase records, balanced journal entries, audit evidence and
outbox work in core-domain Postgres. Commit each internal state transition, its audit evidence
and outbox messages in one database transaction. Enforce both operation-key uniqueness and
business-effect uniqueness in durable constraints. Use optimistic revisions for human commands;
serialize conflicting financial transitions before applying them. Progress remains worker-owned.

External commands execute only after durable intent exists, with a stable provider key derived
from the trusted operation namespace. Persist outbound intent and attempt before sending. The
provider cannot join the database transaction: uncertain outcomes remain pending and are read
back/reconciled before any further financial attempt. Durable inbox/outbox delivery is at least
once; consumers deduplicate message identity and business effect. No message broker is required
for these commercial obligations, and no new event family is sent to learning-event ingestion.

Teacher marketplace payments will use Stripe platform charges with separate Connect transfers
as the proposed implementation profile. MotifPath is responsible for customer refunds and
provider fees under its configured rules; teacher recovery uses future earnings. No refund waits
for a transfer reversal or available teacher balance. Reserve each earning allocation once,
transfer only settled available funds, then independently reconcile connected-account bank
payouts. The actual Brazilian platform/connected-account capabilities, fee quote and liquidity
must be validated before teacher acquisition is enabled. Unsupported capability keeps that
track OFF; it does not select a second provider or weaken permanent ownership.

CMS integration will use an environment-isolated adapter credential and registered document/core
ID mappings. Native notifications are hints, not commercial commands. Workers pull authoritative
editorial data, compare revisions and apply only permitted presentation fields. Authenticated
CMS input cannot issue grants, transfer ownership or change ledger/offer terms. Core authoring
and learner update semantics remain unchanged.

## Rationale

A local transaction couples audit to the commercial mutation and gives durable uniqueness across
restarts. Ordinary request logs and a timed retry cache are rejected: neither protects asynchronous
effects or keeps identity after expiry. A distributed transaction with Stripe is unavailable;
durable intent plus authoritative recovery addresses the uncertainty explicitly.

Separate charges/transfers keeps customer refund funding independent of seller withdrawals and
allows future-earnings recovery without automatic seller-bank debits. Destination charges with
implicit transfer reversal are rejected for this profile because successful customer refunds
must not depend on the seller returning funds. Account-specific restrictions remain a launch
check, rather than an invented guarantee about a Brazilian Stripe account.

Replacing the current authoring system with Strapi is rejected. It would introduce a new content
lifecycle contrary to existing copies and user-pulled updates. A narrow adapter separates editorial
availability from authoritative commercial rights and makes a CMS outage survivable.

## Consequences

### Positive

- Audit failure rolls back internal commercial effects; uncertain external effects remain recoverable.
- Distinct provider events cannot duplicate one payment, grant, refund or teacher allocation.
- Existing learner copies/progress and valid rights survive rollback and CMS outages.

### Negative / Trade-offs

- Outbox/inbox, journal balancing, durable tombstones and backup recovery add operational work.
- MotifPath needs refund liquidity after seller payouts and bears unrecoverable losses.
- Teacher activation requires real Connect/account/settlement evidence; Plus can proceed independently.

### Neutral

- This PR defines contracts only. M0 registry/Figma approval and TDD remain implementation gates.
- Security, retention, dependency validation, delivery and replay contracts are specified in
  [commercial architecture](../openapi/commerce-contract.md).
- ADR-059 is the renumbered accepted commercial authority decision; its policy is unchanged.

## Related ADRs and primary evidence

- [ADR-059](ADR-059-commercial-authority-audit-and-idempotency.md): authority, traceability and idempotency.
- [ADR-058](ADR-058-stripe-payment-provider.md): Stripe selection and account-readiness checks.
- [ADR-055](ADR-055-update-a-copy-to-latest.md): existing user-pulled content updates.
- [ADR-022](ADR-022-drop-notion-project-tracking.md): local-only implementation plans.
- [Stripe separate charges and transfers](https://docs.stripe.com/connect/separate-charges-and-transfers),
  [transfer reversals](https://docs.stripe.com/api/transfer_reversals),
  [idempotent requests](https://docs.stripe.com/api/idempotent_requests).
- [Strapi webhook configuration](https://docs.strapi.io/cms/configurations/server): configurable
  headers do not establish a native signed canonical event protocol.

*Proposed for review; no infrastructure or provider account is configured by this ADR.*
