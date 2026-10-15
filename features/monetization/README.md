# Monetization behavior contracts — MOT-117

These proposed `@wip` scenarios record PO decisions from 2026-10-13 and 2026-10-14.
They are not runtime test results or completion of M0. Architectural constraints are in
[ADR-057](../../adrs/ADR-057-commercial-authority-audit-and-idempotency.md).

| Contract | Behavior |
|---|---|
| [Subscription lifecycle](subscription-lifecycle.feature) | Platform-wide/course/path offers, billing periods, renewal, cancellation, grace, switching, retention and independent beta readiness |
| [Refunds and chargebacks](refunds-and-chargebacks.feature) | First subscription per scope, access-based eligibility start, admin handling, full refunds, retained records and dispute grace |
| [Teacher commercial rights](teacher-commercial-rights.feature) | Price bounds, permanent per-path licenses, permanent purchases, withdrawal, user-pulled free updates and earnings adjustments |
| [Stripe payment ingestion](stripe-payment-ingestion.feature) | Authoritative subscription checkout, verified durable receipts, business deduplication and reconciliation |
| [Refund commands](refund-commands.feature) | Caller-owned full-refund cases, admin-only execution, cross-actor payment uniqueness and pending reconciliation |
| [Subscription commands](subscription-commands.feature) | Caller ownership, durable receipts, rollback-safe idempotency, revision conflicts and authoritative offer validation |

## Subscription API slice

[Core-domain OpenAPI](../../openapi/core-domain-service.yaml) defines proposed offer and
caller-owned subscription reads, renewal cancellation and scheduled annual switching.
Payloads and error/operation semantics are in its referenced subscription schemas and paths.
The slice accepts no caller-owned price or actor field. Cancellation does not create a refund;
pending operation receipts do not assert external billing success. Existing acquisitions,
checkout, refund execution, grants, CMS sync and provider callbacks are separate contract work.

Amounts and dates in scenarios are examples, not launch prices. Configurability does not
authorize the browser or editorial metadata to override authoritative prices, rights or ledger
records. All direct and indirect commercial changes retain ADR-057 audit and idempotency rules.
No changes to CI, ignore rules or the existing learner update process are part of this slice.

## Unresolved contract boundaries

- Payment provider and supported markets; USD remains conditional on additional cost assessment.
- Initial prices, discounts, teacher price bounds, commission shares and fee allocations.
- Provider-supported payout timing and the allocation of partial refunds/chargeback costs.
- Final dispute outcomes, restoration after successful defense and early dispute resolution.
- Exact seven-day refund deadline inclusivity and time/calendar conventions.
- Notice delivery failures, payment retries, recovery during grace, and simultaneous cancellation,
  switching, renewal or refund requests.
- Stable entitlement/product/version identifiers and premium dependency/license coverage.
- Existing `learning-paths/path-publishing.feature` specifies path publish/unpublish, whereas
  the PO's commercial model says paths expose their latest version without a publishing process.
  Reconcile that lifecycle separately; this slice adds no path publication workflow and removes none.
- Withdrawal preserves purchased copies. The exact retained path reference must reconcile the
  latest-version requirement with [ADR-055](../../adrs/ADR-055-update-a-copy-to-latest.md)'s
  user-initiated updates. These scenarios preserve its eligibility and progress rules.
- Remaining commercial API and event contracts still need definition. The subscription API
  slice above covers only its stated reads and lifecycle commands, not checkout or callbacks.

Gilson owns commercial rollout, financial reconciliation and editorial approvals. Plus is the
first rollout priority; teacher commerce has independent readiness. Registry approval, the
commercial Figma approval record and complete approved contracts remain required before code.

## Refund API slice

Core-domain OpenAPI additionally defines caller refund request creation, owner/admin case
reads and admin-only execution of commercially eligible full refunds. Amount/currency are
backend-derived; uncertain external outcomes remain processing. Eligibility is evaluated at
original request time so admin delay cannot invalidate a timely request. This slice does not
choose statutory exceptions, reject/review overrides, partial refunds, definitive-failure
retry policy, admin queues, provider callbacks or settlement recovery mechanisms. Those remain
contract work; none is implicitly granted by a new operation identity.
Whether refunding a subscription also cancels future renewal requires an explicit contract;
access removal alone is not a billing-cancellation instruction. Competing uncertain dispute
settlements must be reconciled before another financial return is attempted.

## Stripe checkout and receipt slice

Core-domain OpenAPI defines caller-owned subscription checkout creation/read and a separate
Stripe-signature-authenticated financial receipt endpoint. Native provider envelopes are
not client learning events. Receipt is durable transport acknowledgement; fulfillment
requires verified payment and business-level uniqueness. Unknown outcomes are reconciled,
not retried as new operations. Snapshot versus thin delivery and the exact Stripe API version,
event allowlist, secret-rotation/tolerance settings, replay schedules and financial schema
mappings still require implementation-ready contracts. Persistent inbox payloads require
restricted access, data minimization and approved retention; raw provider data is not a public log.

Teacher-path purchase checkout remains gated by commercial version and Connect contracts.
No Connect charge type, payment-method rollout, provider account, CMS or infrastructure is
created by these specs. This slice preserves acquisition rollback safety and approved
user-pulled content updates. Primary references checked 2026-10-14:
[Stripe session creation](https://docs.stripe.com/api/checkout/sessions/create),
[webhook verification/delivery](https://docs.stripe.com/webhooks), and
[subscription notifications](https://docs.stripe.com/billing/subscriptions/webhooks).
