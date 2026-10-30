# ADR-068: MotifPath content can be bought once or unlocked with Plus

**Status:** Proposed
**Date:** 2026-10-30
**Deciders:** Gilson Yamada (Product Owner and engineering lead)
**Task:** MOT-116, under MOT-107 / MOT-108
**Supersedes:** the ADR-067 rule "MotifPath-owned content is not sold individually". The rest of
ADR-067 stands.

## Context

ADR-067 reduced monetization to two products: the Plus platform subscription, which covers
MotifPath-owned content, and a permanent individual purchase of a teacher course or path. Each
piece of content had exactly one access rule: free, included in Plus, or bought.

The MOT-116 r4 Figma review found a gap in that model. A learner who wants one MotifPath course
has only one option, a recurring subscription. The product owner wants the learner to choose
between paying once and subscribing, and the r4 storyboard does not show that choice anywhere.
Learners who study one course at a time, or who do not want a recurring charge, have no way in.

The options considered were:

1. Keep ADR-067: MotifPath content stays Plus-only, and the design only explains the two products
   better.
2. Let a MotifPath course or path carry a one-time purchase offer in addition to Plus.
3. Let Plus also cover teacher content, so that teacher items could be bought or subscribed to.

## Decision

A MotifPath-owned course or path **may** carry a one-time purchase offer in addition to being
included in Plus. The learner chooses on the item's detail page: **Buy once** (that item, kept
permanently) or **Get Plus** (every MotifPath course and path, premium exercises and premium
tools, monthly or yearly, while subscribed).

- **Per item, by administrator.** An administrator decides which MotifPath items get a purchase
  offer and sets its price through the same approved offer revisions used for Plus. An item
  without a purchase offer stays Plus-only.
- **What the purchase grants.** Permanent access to that one course or path, including the
  premium exercises it contains, for that item only. It does not grant premium tools, other
  content or Plus. This mirrors the teacher purchase in ADR-067.
- **No commission.** MotifPath is the seller, so no commission or teacher earnings apply.
  Payment, receipts and refunds follow the individual-purchase rules.
- **Active subscribers are not offered the purchase.** While Plus is active, the item shows as
  included and no purchase button appears, so a subscriber is not charged twice for access they
  already have. When Plus ends, the purchase offer returns next to Get Plus.
- **Owned stays owned.** A learner who bought an item and later subscribes, or whose
  subscription ends, keeps the bought item.

Teacher content is unchanged: buy once only, never covered by Plus.

## Rationale

**Option 2 gives every learner a way into one MotifPath course without a recurring charge,**
while Plus remains the better deal for learners who use more than one item. Learners who decide
course by course become customers instead of leaving.

**Option 1 (keep ADR-067) is rejected** because the product owner's review identified the missing
choice as a gap that clearer wording cannot close: the learner still has nothing to buy except a
subscription.

**Option 3 (Plus covers teacher content) is rejected for the same reasons ADR-067 rejected the
revenue pool:** it needs a usage metric and a way to share subscription revenue with teachers,
and the platform-first premise keeps Plus independent of teacher supply.

**Per-item opt-in rather than every MotifPath item** keeps the catalog manageable and lets the
team test one-time pricing on a few items before setting prices for all of them.

**Hiding the purchase from active subscribers** keeps the detail page to one clear action. Selling
"keep it forever" to someone who already has access invites refund requests and confusion. It can
be reconsidered if subscribers ask for it.

## Consequences

### Positive

- The learner sees a real choice on MotifPath content: pay once for this item, or subscribe for
  everything.
- One-time buyers can become Plus subscribers later; the detail page shows both prices together,
  which makes the value of Plus easy to compare.
- The purchase reuses the individual-purchase flow, receipts and refunds already designed for
  teacher items.

### Negative / Trade-offs

- One-time sales can reduce Plus conversion when a learner only wants one course. Purchase prices
  must be set high enough relative to Plus to keep the subscription attractive.
- Each MotifPath item now has up to two access paths, so access checks, the detail page and the
  catalog labels handle the "Plus or buy" case.
- A learner who bought an item and then subscribes has paid for access that Plus would also give.
  No credit or refund is offered for that overlap.
- The ADR-067 statement "each piece of content has one access rule" no longer holds for
  MotifPath items that carry a purchase offer.

### Neutral

- The commercial contracts on the monetization branch need a follow-up spec change: the
  individual-purchase offer, acquisition and refund scenarios apply to MotifPath-owned items as
  well as teacher items, without a commission; access rules add "owned or subscribed" for
  MotifPath items.
- The price of each MotifPath purchase offer is a configuration input, not part of this decision.
- Plus billing rules are unchanged: monthly or annual, the annual offer must be discounted,
  monthly to annual switching takes effect at the next renewal, and annual to monthly is not
  offered.

## Related ADRs

- [ADR-067: Two commercial products](ADR-067-two-commercial-products.md): this ADR replaces its
  rule that MotifPath-owned content is not sold individually; all other ADR-067 decisions stand.
- [ADR-058: Stripe as the payment provider](ADR-058-stripe-payment-provider.md): one-time
  MotifPath purchases use the same provider.
- [ADR-059: Commercial authority, audit and idempotency](ADR-059-commercial-authority-audit-and-idempotency.md)
  and [ADR-060: Commercial records and recovery](ADR-060-commercial-records-and-recovery.md):
  apply unchanged to the new purchase kind.

---

*This ADR was proposed on 2026-10-30. To revise, create a new ADR with Status: Supersedes ADR-068.*
