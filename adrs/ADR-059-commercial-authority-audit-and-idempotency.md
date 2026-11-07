# ADR-059: Commercial authority, durable audit and idempotent operations

**Status:** Accepted — approved by Gilson Yamada on 2026-10-13 in review of specs PR #315
**Date:** 2026-10-13
**Deciders:** Gilson Yamada (Product Owner and engineering lead)
**Task:** [MOT-117](https://linear.app/motif-path/issue/MOT-117/m0-finalize-architecture-and-api-contracts), under MOT-107 / MOT-108

## Context

The monetization MVP introduces Plus subscriptions, permanently purchased teacher paths and
commercial embedding licenses. Existing authoring, content copies and progress records do not
constitute a financial ledger or an entitlement system. Strapi is not provisioned; its future
editorial role must not create another authority for money or access.

Commercial consequences arise beyond payment endpoints. Changing a path from free to paid,
altering an offer, publishing or withdrawing licensed content, and changing rollout cohorts can
affect what users may buy or access. Gilson explicitly requires traceability for these indirect
operations as well as financial transactions, and idempotency across repeated operations.

Requests, provider notifications and background jobs can be retried, delivered out of order or
interrupted after an effect commits but before a reply arrives. Acquisition can also be disabled
while payments are in flight. Logging individual requests and deduplicating notification IDs
alone cannot establish who caused a commercial change or prevent duplicated business effects.

We considered client/CMS-controlled access, request logs as the audit record, event-ID-only
deduplication, and disabling the entire commercial subsystem during rollback. This ADR records
the proposed architecture addressing those risks. It does not approve the flag registry,
financial policies or designs, or authorize implementation before M0 gates pass.

## Decision

MotifPath will use its backend as the authoritative boundary for commercial ownership, licenses,
offers and authoritative monetary terms, purchases, subscriptions, grants and financial records.
Strapi may own editorial and commercial presentation metadata; browser and CMS fields cannot
bypass backend validation. Existing backend progress ownership remains intact: aggregation-worker
owns derived progress records and core-domain reads them. Commercial access changes do not delete
learning evidence or history.

MotifPath will require durable audit evidence and idempotent business effects for every operation
with direct or indirect commercial consequences. These controls and existing-resource access
enforcement remain active independently of acquisition flags. The following invariants define
the contract boundary; storage, provider and API mechanisms are settled in subsequent approved specs.

### Rights and rollout invariants

- Purchased teacher paths grant permanent access independent of student Plus or teacher
  subscription status. Refund, chargeback, license expiry and withdrawal treatment require an
  explicit approved policy; flags and CMS deletion cannot silently invent revocation rules.
- Subscription cancellation retains all progress. Its access effective date remains a policy
  decision. Teacher creation tools remain free.
- Embedding platform premium exercises in a paid teacher path requires a distinct teacher
  commercial license; student Plus is insufficient.
- Flags default OFF. Protected new actions require backend evaluation and approved targeting;
  UI mirrors the decision. OFF stops new acquisition/publication while preserving existing
  rights, records and required cancellation/support flows.
- Already-authorized payment outcomes, fulfillment, refunds, reconciliation and existing
  settlement obligations continue through rollback. Unknown/unverified provider input cannot
  create rights. Existing protected content must never fall through to unrestricted access.

### Durable traceability

Audit coverage includes payment, fulfillment, grants, subscriptions, refunds, chargebacks,
commissions and settlement, plus ownership, free/paid transitions, prices/offers, commercial
publication/withdrawal and content updates, license changes, CMS synchronization, commercial
flags/cohorts and administrative overrides.

Each record identifies the logical operation and attempt, authenticated actor or service,
environment, time, action/resource, reason, before/after commercial state, outcome, applicable
policy/configuration revision and relevant transaction/provider references. Correlation and
causation link asynchronous effects back to their initiating operation and actor. Failed,
denied, duplicate and uncertain attempts remain attributable without creating duplicate effects.
Evidence must be protected from unauthorized alteration/deletion; secrets and raw payment
credentials must not appear in it. Financial corrections append compensating records instead
of replacing history.

Committed commercial state and its audit evidence must be durably coupled. An audit failure
cannot silently commit an untraceable state change. External provider calls cannot be covered
by a local atomic transaction; durable operation state and reconciliation must preserve the
causal chain across that boundary. Exact coupling, recovery and tamper-evidence mechanisms,
retention and access permissions require approved MOT-117 contracts.

### Idempotent business effects

One logical operation produces its intended business effects once despite repeated delivery,
concurrent attempts, process restarts and replay. Durable operation identity is scoped by
environment, actor/integration, action and business operation, with a request fingerprint.
Repeating the same identity and intent returns the existing result/status; reusing an identity
with different intent is rejected. A new intentional change uses a new operation identity.

Provider-event deduplication is combined with business-transition uniqueness: two different
notifications about the same transaction cannot create two receipts, grants, refunds or
settlements. Operation identity propagates through jobs, callbacks and reconciliation. Where
supported, provider idempotency keys reinforce this boundary. An uncertain provider outcome is
reconciled before retrying an external charge; a timeout is not proof of failure. Deduplication
retention must cover approved replay and financial lifecycle requirements.

For example, a free-to-paid transition records the actor, resource/version, prior and resulting
state, offer reference, reason and operation identity. A duplicate attempt remains traceable,
but creates no second transition or downstream commercial effect. Existing learner treatment
follows approved policy, rather than being inferred from the new paid state.

## Rationale

Central backend authority avoids conflicting rights decisions across CMS, browser, API and
media delivery. Keeping presentation separate allows editorial changes without granting an
editor the power to issue purchases or alter the ledger. Public asset delivery still requires
an approved protection design; an authenticated API alone cannot protect a known public URL.

Ordinary request logs are rejected as the sole audit record: they can omit asynchronous effects,
before/after state or durable linkage to the committed change. Durable evidence makes financial
and indirect commercial operations reconstructable without depending on transient diagnostics.

Event-ID-only deduplication and in-memory retry caches are rejected as sufficient protection.
Different messages can describe one transaction, and retries survive process lifetimes.
Durable business-operation identity and transition uniqueness address those cases. This is an
at-least-once delivery system with idempotent effects, not a claim of globally exactly-once
execution across independent systems.

Disabling all commercial processing during rollback is rejected because it strands authorized
payments and existing rights. Acquisition switches therefore stop new exposure while obligation
handling and protection remain active. Flags cannot replace contracts or permanent grants.

## Consequences

### Positive

- Direct and indirect commercial changes have attributable, reconstructable histories.
- Retries and callback replay cannot duplicate the intended financial or entitlement effects.
- Rollback preserves permanent purchases, progress and already-authorized obligations.
- Editorial changes cannot bypass access controls or become financial authority.

### Negative / Trade-offs

- Durable operation/audit records, retention and access controls add storage and operational cost.
- Every affected authoring, CMS, administrative and financial path needs coverage; payment-only
  instrumentation is insufficient.
- External uncertainty requires pending states, reconciliation and support tooling.
- Rollback binaries must remain compatible with existing commercial records and obligations.

### Neutral

- No provider, audit database, flag platform or Strapi version is chosen here.
- Existing learner-copy update semantics remain governed by ADR-055. Commercial snapshots and
  purchased-content updates require explicit reconciliation with that decision before code.
- Feature scenarios remain proposed/unimplemented until approvals and TDD implementation.

## Remaining contracts and validation

MOT-117 must resolve prices/currencies and offer eligibility; cancellation timing; license
scope/expiry; content withdrawal/updates; refund/chargeback entitlement effects; commissions,
rounding and settlement; stable commercial references; audit schemas/retention/protection;
idempotency key scopes, atomicity, out-of-order handling and recovery; CMS authority/sync;
protected-media delivery and flag propagation. Proposed registry names and combined-beta
dependencies still require MOT-115 review. Commercial Figma approval remains required.

Before implementation, approved behavior scenarios and failing tests must cover sequential and
concurrent duplicates, conflicting intent, restart after commit/before reply, distinct provider
events for one transaction, out-of-order delivery, uncertain provider outcomes, free-to-paid
retries, audit failure, causal reconstruction and callbacks during rollback. Verify persistence
and provider recovery behavior with real integration evidence. No runtime tests are claimed by
this ADR. Initial proposed scenarios are in [specs PR #311](https://github.com/motifpath/motifpath-specs/pull/311).

## Related ADRs

- [ADR-002: Spec-driven development](ADR-002-spec-driven-development.md): approved contracts precede implementation.
- [ADR-012: Idempotency and delivery strategy](ADR-012-idempotency-delivery-strategy.md): learning-event delivery precedent; its convergent progress folds do not substitute for financial uniqueness.
- [ADR-022: Local-only plans](ADR-022-drop-notion-project-tracking.md): durable architecture decisions belong here; plans remain local.
- [ADR-055: Update a copy to latest](ADR-055-update-a-copy-to-latest.md): commercial references must reconcile learner update and retained-progress semantics.

---

*Accepted on 2026-10-13. To revise, create a superseding ADR.*

Identifier corrected from ADR-057 to ADR-059 in MOT-117: ADR-057 is already assigned to
the drill model on main. The accepted commercial decision, approval and history are unchanged.
