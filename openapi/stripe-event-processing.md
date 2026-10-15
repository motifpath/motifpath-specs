# Stripe event processing and reconciliation — MOT-117

Status: Proposed contract, 2026-10-15. Applies to the financial receipt endpoint in
[Core Domain OpenAPI](core-domain-service.yaml), not the learning-event ingestion service.
[ADR-058](../adrs/ADR-058-stripe-payment-provider.md) selects the provider; application
commercial authority, traceability and durable business idempotency remain mandatory.

## Delivery profile

Target **API v1 snapshot events, version `2026-09-30.endive`**, for the platform and explicitly registered connected-account
financial destinations. Pin outgoing object reads/commands and the registered snapshot destination
to that version. Do not inherit a changing account default. Before implementation, select
and pin a Go SDK release whose generated types match this version; an incompatible SDK is
a readiness failure, not permission to override strong types. Accounts v2 and thin
event delivery are not introduced by this contract.

Each environment has an expected account identity, test/live mode, endpoint signing-secret
set and version manifest. Verify the original raw request bytes, native signature and signed
timestamp with a proposed **300-second tolerance** before parsing trusted business fields.
Reject a missing, expired, invalid or wrong-environment signature. Test deliveries never
affect live records. Secret rotation records activation/expiry and operator; overlapping
keys are accepted only during the explicitly bounded rotation window. Never log secret values
or raw payment credentials. Native envelopes are kept only in restricted storage under the
approved retention policy; general logs contain safe correlation references.

After verification, preserve account/mode/event identity, event kind/version, relevant object
references, source occurrence time and local receipt time. Persist receipt and audit evidence
before acknowledgement. Repeated delivery records another attributable attempt but reuses
the original receipt. Unsupported versions/kinds remain reviewable without producing rights.
The configured version is a proposed contract target, not a claim that an account is configured.

## Enabled notification map

All rows trigger correlation and authoritative object checks. An event name or object snapshot
alone cannot issue a grant. Notifications outside the allowlist are retained without business effects.

| Stripe notification | Required verification / business meaning |
|---|---|
| `checkout.session.completed` | Bind the recorded checkout to the verified session/customer/subscription/invoice. Completion alone does not prove payment or access. |
| `checkout.session.async_payment_succeeded` | Reconcile the associated invoice/payment; do not create a second fulfillment path. |
| `checkout.session.async_payment_failed` | Reconcile the unsuccessful payment without overriding a newer verified paid fact. |
| `checkout.session.expired` | Confirm the session's state and payment outcome before closing its open acquisition reservation. Unknown money state stays pending. |
| `invoice.paid` | Reconcile a paid subscription invoice and the approved offer, amount/currency, customer, scope and billing period; apply the single period entitlement if eligible. |
| `invoice.payment_failed` | Reconcile the relevant renewal. First-payment failure creates no paid grant; renewal grace is anchored to the prior paid-period end, not notification arrival. |
| `invoice.payment_action_required` | Record a payment requiring customer action; do not infer success or invent a new grace period. |
| `invoice.upcoming` | Refresh authoritative renewal information. It does not replace both application-owned annual renewal notices. |
| `customer.subscription.created` | Correlate external subscription identity; creation/active status alone does not establish payment. |
| `customer.subscription.updated` | Reconcile billing period, renewal and scheduled changes without truncating previously paid rights or duplicating grants. |
| `customer.subscription.deleted` | Reconcile external termination against paid periods and explicit cancellation history; never delete learning/financial history. |
| `refund.created`, `refund.updated`, `refund.failed` | Read the individual refund and correlated admin operation. Only confirmed full success applies the approved refund/access rule. Unknown outcomes remain processing. |
| `charge.refunded` | Reconcile individual refund objects and totals; a charge-level or partial-refund notification alone is not a second full refund or automatic full-access removal. |
| `charge.dispute.created`, `charge.dispute.updated` | Record/reconcile the dispute. Pending disputes and provider holds never themselves block otherwise valid access. |
| `charge.dispute.closed` | Verify the actual final outcome. Closed is not synonymous with lost or won. Apply verified won/lost outcomes under the consolidated commercial contract; no expired or refunded grant is revived. |
| `charge.dispute.funds_withdrawn`, `charge.dispute.funds_reinstated` | Record financial movements with their own provider references. They neither refund automatically nor decide content access by themselves. |

One-time path/license checkouts use payment mode with the same durable receipt/operation
boundary. Verify PaymentIntent/captured charge against the accepted offer/customer and apply
one purchase/license grant. Add `payment_intent.succeeded` and `payment_intent.payment_failed`
as reconciliation triggers, never independent fulfillment paths. `transfer.created`,
`transfer.updated` and `transfer.reversed` reconcile the recorded settlement obligation;
`payout.created`, `payout.updated`, `payout.paid`, `payout.failed` and `payout.canceled` reconcile
connected-account bank payout state. Verify the owning account, original source payment and
recorded beneficiary. A transfer reversal never independently revokes customer access.

Connected events require a separately registered signing destination and expected account scope.
Verify the original signed payload, connected account identity and test/live context against
that manifest and registered core mappings. The request cannot choose secrets or a different
environment. Quarantine unmapped accounts. No arbitrary account is trusted because an `account`
field is present. Refund/dispute effects remain payment-specific across both product families.
New payment methods and real account onboarding are deployment work, not activated by this spec.

## Payment verification and effect identity

Provider identity is scoped by trusted environment and account. Verify the mapped customer,
subscription, invoice, offer revision and approved monetary terms against the durable operation.
Do not trust user email or freely editable provider metadata as the sole ownership proof.
Missing mappings, mismatched money, unsupported adjustments or conflicting objects enter review
without creating access. A manually marked-paid invoice, credit-only invoice or zero amount is
not independent proof of a captured payment; verify the funding source against an approved
offer/funding policy or retain it for review. No new free-trial or credit policy is invented here.

Use separate uniqueness boundaries:

- **Transport receipt:** environment + Stripe account + event ID.
- **Financial fact:** environment + account + immutable provider payment/refund/movement identity.
- **Subscription-period grant:** environment + account + invoice identity + correlated subscription
  period/scope. Multiple partial payment facts may fund one invoice, but its entitlement is applied once.
- **Commercial command:** durable MotifPath operation identity and fingerprint. Provider request
  keys reinforce this boundary; provider cache expiry never authorizes another financial attempt.

`invoice.paid`, checkout and payment-object observations converge on those same boundaries.
Replays preserve original causal links and previously completed effects. Do not compare event
delivery timestamps as a substitute for authoritative billing state or monotonic local revisions.
An old failure cannot erase a later paid period; an old paid observation cannot undo its later
successful refund or another established restriction. Resolve current access from independent
grants and restrictions, rather than replacing the whole user's access from one notification.

## Reconciliation contract

Proposed operating cadence: a **five-minute sweep** per environment over outstanding checkout,
subscription-command, invoice, refund, dispute, grant, notice and receipt obligations; a **daily coverage sweep** over
known active subscriptions and incomplete obligations to repair missed notifications. Exact
capacity/rate-limit budgets are deployment-readiness inputs, not permission to skip older work.

Persist cursor/checkpoint progress and paginate without gaps. Outstanding old obligations stay
eligible regardless of a recent-event lookback. Prioritize by next-due time and age, applying
bounded backoff/jitter for provider rate limits or outage. Record start/end, operator/service,
source references, attempted effects and outcome for each reconciliation operation; alert on
overdue/backlogged or repeatedly unresolved work. Commercial acquisition OFF never pauses it.

Read authoritative provider objects linked to recorded operations, using the configured
account/mode/version. Reconciliation does not fabricate a webhook signature or pretend that
a recovered fact arrived via webhook: record verified provider-read provenance instead.
Apply recovered facts through the same business uniqueness and audit boundary as notifications.
Existing paid periods are not extended merely because reconciliation runs late.

Unknown session creation, refund or charge outcomes are not retried as new financial commands.
If an authoritative lookup cannot establish whether a previous attempt succeeded, retain the
pending operation and escalate for resolution. A missing object in one lookup is not proof
that no financial operation occurred. No unattended re-charge or double refund is permitted.

Annual notice scheduling uses each authoritative annual renewal time with distinct seven-day
and one-day notice identities. One `invoice.upcoming` notification cannot stand in for both.
Duplicate scheduling cannot send duplicate copies of the same notice; undeliverable notices
use durable bounded retries until renewal, then record missed delivery and alert support.

## Readiness and remaining decisions

Before implementation: approve this profile, pin the matching SDK, validate the account's
version/notification configuration in sandbox, define durable financial/audit/grant schemas
and retention/access rules, and prove replay/outage recovery with real persistence tests.
Final dispute outcomes, full-refund review and teacher settlement are defined by
[the consolidated commercial contract](commerce-contract.md). Partial-refund automatic execution
and credits are not enabled at launch. All M0 design/registry/spec approvals remain required.

## Primary references

Checked 2026-10-15: [Stripe subscription notifications](https://docs.stripe.com/billing/subscriptions/webhooks),
[event catalog](https://docs.stripe.com/api/events/types),
[version/SDK compatibility](https://docs.stripe.com/upgrades), and
[signature verification and delivery](https://docs.stripe.com/webhooks).
