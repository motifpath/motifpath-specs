# ADR-058: Stripe as the payment provider

**Status:** Accepted — Gilson confirmed approval after merging specs PR #338 on 2026-10-14
**Date:** 2026-10-14
**Deciders:** Gilson Yamada (Product Owner and engineering lead)
**Task:** MOT-117, under MOT-107 / MOT-108

## Context

MotifPath requires recurring monthly and annual subscriptions, both platform-wide and
content-specific, plus permanent teacher-path purchases and teacher commercial embedding
licenses. Plus launches first; teacher commerce has independent readiness. The receiving
business/account will be Brazilian. Prices, discounts, commissions and teacher price bounds
are configurable; USD remains conditional on feasibility and incremental cost.

The provider must support verified payment outcomes, refunds, reconciliation and traceable
external references. Provider deduplication must complement durable MotifPath operation
identity and business-level uniqueness. MotifPath absorbs customer refund processing fees
and unrecoverable teacher refund losses, recovers teacher adjustments from future earnings,
and does not impose a voluntary teacher settlement reserve.

We compared Stripe, Asaas and Mercado Pago using official documentation. Gilson selected
Stripe on 2026-10-14. This records that choice; it does not establish that a live account,
marketplace configuration, fee quote or production integration has been approved by Stripe.

## Decision

MotifPath will use **Stripe as its payment provider**. Use Stripe Payments and Billing for
the subscription/checkout integration, and evaluate Stripe Connect for the later teacher
marketplace configuration. Connect onboarding, charge/transfer model and Brazilian account
eligibility are implementation-readiness gates within the selected provider, not approved
facts or reasons to silently substitute a second provider.

Stripe is the financial processing integration; MotifPath's backend remains authoritative
for offers, recorded monetary terms, purchases, licenses, grants and access decisions.
Stripe subscription status or a browser checkout return cannot by itself authorize content.
Maintain durable mappings to Stripe customer, price, subscription, payment, refund, dispute
and transfer/payout references as applicable; exact fields and event contracts follow before code.

Strapi and Stripe are different products. Strapi, if used for editorial content, is a CMS;
it does not replace Stripe or become financial authority. This provider decision does not
authorize provisioning a CMS or decide its necessity based on the earlier naming confusion.

### Integration invariants

- Use backend-verified Stripe outcomes, authenticated callbacks and reconciliation. Browser
  redirects and client/CMS amounts never prove a payment or override authoritative terms.
- Keep permanent operation identity and per-business-effect uniqueness in MotifPath, across
  provider retries, distinct event IDs, concurrent actors and restarts. Reconcile uncertain
  outcomes before issuing another charge/refund; provider keys alone are insufficient.
- Record every direct/indirect commercial operation with attributable durable audit evidence.
- A successful refund removes only its payment-linked grant immediately and does not cancel
  future automatic renewal. Cancellation remains a separate explicit operation.
- The latest PO policy retains otherwise valid access while a dispute awaits its final
  decision; a provider funds hold is not itself an access-blocking instruction. Final
  won/lost entitlement treatment remains to be specified. No extra paid time is implied.
- Acquisition OFF does not stop existing obligation handling, refunds, reconciliation or
  protected-resource enforcement. Preserve progress, financial history and independent grants.

## Rationale

Stripe provides subscription management and marketplace-oriented payment primitives suitable
for the Plus-first sequence, along with documented idempotency, webhooks and reconciliation
interfaces. A selected provider with separate application-owned rights avoids making editorial
content, provider product objects or browser behavior the commercial source of truth.

Asaas was considered for Brazilian recurring payments and documented subscription splits.
It was not selected after the comparison; its subscription timeout/duplication guidance and
refund funding after teacher withdrawals would also require explicit validation. Mercado
Pago was considered for subscriptions and marketplace split payments, but its documented
seller-balance dependency for full split refunds conflicts with the intended platform-funded
refund policy after teacher payouts. Choosing Stripe does not remove its own liquidity gates.

Using Strapi alone was not a payment-processing alternative: a CMS still needs a payment
processor. No second processor or multi-provider routing is introduced by this decision.

## Consequences

### Positive

- Provider-specific contracts can now be designed without keeping competing integrations open.
- Plus and teacher commerce share a chosen financial integration while retaining separate rollout gates.
- Audit, access and idempotency remain under application control rather than depending on provider defaults.

### Negative / Trade-offs

- Processing, Billing, Connect, payout/anticipation, dispute and currency costs require a
  complete Brazilian account quote; a base card fee is not the total integration cost.
- Earliest teacher payout depends on settled funds and approved account terms. No voluntary
  teacher reserve does not eliminate Stripe holds or MotifPath's working-capital requirement.
- Stripe Connect availability/configuration for the actual platform and teachers requires
  confirmation. Unsupported capabilities must be escalated before changing product promises.
- USD acceptance/settlement and extra cost remain unapproved. Generic currency support must
  not be treated as confirmation for this Brazilian business.

### Neutral

- This is a specification decision, not account creation, credential access or activation.
- No particular Stripe charge/transfer type, SDK version, checkout UI or payment method is selected here.
- M0 design, registry and remaining contract approvals still precede TDD implementation.

## Related ADRs and primary evidence

- [Commercial authority, audit and idempotency](ADR-059-commercial-authority-audit-and-idempotency.md): application invariants remain binding.
- [ADR-012](ADR-012-idempotency-delivery-strategy.md): delivery/reconciliation precedent; financial effects need their own uniqueness.
- [ADR-022](ADR-022-drop-notion-project-tracking.md): research/plans remain local; this durable provider decision is versioned.
- [Stripe Billing](https://stripe.com/br/billing/pricing), [Connect account configuration](https://docs.stripe.com/connect/accounts), [marketplace refunds/disputes](https://docs.stripe.com/connect/marketplace/tasks/refunds-disputes), [idempotency](https://docs.stripe.com/api/idempotent_requests).
- [Asaas subscription splits](https://docs.asaas.com/docs/split-em-assinaturas), [subscription timeout guidance](https://docs.asaas.com/reference/criar-assinatura-com-cartao-de-credito).
- [Mercado Pago marketplace split/refund constraints](https://www.mercadopago.com.br/developers/pt/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace).

---

*Accepted on 2026-10-14. Record future architectural changes in a superseding ADR.*
