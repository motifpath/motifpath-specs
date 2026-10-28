# ADR-067: Two commercial products — a platform subscription and teacher purchases

**Status:** Proposed
**Date:** 2026-10-28
**Deciders:** Gilson Yamada (Product Owner and engineering lead)
**Task:** MOT-116, under MOT-107 / MOT-108

## Context

The monetization contracts written for MOT-117 offer learners and teachers four commercial
concepts: a platform-wide subscription (Plus), course- and path-scoped subscriptions, permanent
teacher-path purchases and a permanent per-path embedding license that a teacher buys before
selling a path containing MotifPath premium exercises. Each concept carries its own offers,
prices, refund history, Figma journeys and rollout flags.

The MOT-116 Figma review showed the cost of that breadth. Learners had to tell apart Free,
Subscription, Included and Buy once, and teachers had a license purchase before their first sale.
Most of the design and contract effort went to combinations of the four concepts rather than to
the two questions that matter at launch: does the platform alone earn a subscription, and can a
teacher sell their own work?

The open question is how teachers fit a subscription. Teacher items are simple: the teacher sets
a price and earns from each sale. A subscription that also covered teacher content would need a
way to share recurring revenue among teachers. The options considered were:

1. The subscription covers only MotifPath's own content; teacher content is sold per item.
2. A revenue pool: teachers opt content into the subscription and share a fixed part of
   subscription revenue in proportion to usage (practice time, completed lessons).
3. Per-teacher subscriptions: each teacher sells a recurring subscription to their catalog.

The platform-first premise (revised 2026-09-08) requires the MVP to show standalone value without
depending on external teacher supply.

## Decision

MotifPath will sell exactly **two kinds of commercial product**:

1. **Platform subscription** — one platform-wide scope, monthly or annual, priced by MotifPath.
   It covers MotifPath-owned content: team-authored courses and paths, premium exercises and
   premium tools. It never covers teacher-priced content. Course- and path-scoped subscriptions
   are removed.
2. **Individual purchase** — one teacher course or path, bought once and kept permanently. The
   teacher sets the price within administrator-configured bounds. MotifPath keeps one configured
   platform commission per sale; the teacher earns the remainder after allocated fees, as already
   specified in the commerce contract.

The commission covers MotifPath premium exercises embedded in a teacher's paid path. A purchase
grants the buyer access to every exercise the purchased path contains, premium ones included,
for that path only. The teacher embedding license is removed as a product. A premium exercise
in a **free** teacher path stays locked for learners without the platform subscription.

MotifPath-owned content is not sold individually, and subscribers get no discount on teacher
purchases. Free content remains free and unmarked.

## Rationale

**Option 1 keeps the subscription independent of teacher supply.** Its value is MotifPath's own
catalog and tools, which the team controls. That is the platform-first premise applied to pricing.

**Option 2 (revenue pool) is rejected for the MVP.** It needs a usage metric that is fair and
hard to game, per-teacher metering, monthly pool settlement, and payouts teachers cannot predict.
It also undercuts individual sales, since a learner will not buy what the subscription includes.
It cannot be calibrated before real engagement data exists, and product analytics (MOT-30) is
paused. It may be reconsidered later as a teacher opt-in, through a new ADR.

**Option 3 (per-teacher subscriptions) is rejected.** It brings back a third product, needs
recurring billing per seller through Stripe Connect, and gives a small catalog little reason to
recur.

**Removing the embedding license** removes a purchase the teacher must make before earning
anything, along with its offers, refunds and dependency checks. The commission already pays
MotifPath on every paid sale, so it can pay for the embedded exercises too. Charging a surcharge
per premium exercise was rejected: it makes teacher prices hard to explain and adds the
dependency accounting the license needed.

## Consequences

### Positive

- Learners see one recurring offer and one kind of permanent purchase. Each piece of content has
  one access rule: free, included in the subscription, or bought.
- Teachers can sell with no up-front cost, consistent with free creation tools.
- The MOT-116 Figma scope shrinks: scoped subscription offers, the Subscription-scoped course
  story and every license flow are removed.
- Contracts, flags and runtime work shrink with them (see Neutral).

### Negative / Trade-offs

- Teachers get no share of subscription revenue, so subscribers have no incentive to buy teacher
  content beyond its own value.
- MotifPath cannot charge more for teacher paths that rely heavily on premium exercises; one
  commission applies to every sale.
- A buyer can use premium exercises inside a purchased path without subscribing, which can reduce
  subscription conversion for learners who mainly follow one teacher.
- A teacher wanting recurring income has no product for it until a pool or per-teacher
  subscription is decided.

### Neutral

- The MOT-117 contracts on the monetization branch need a follow-up spec change:
  `SubscriptionScope` reduces to `platform`; `embedding_license`, `License`, `premium_license`
  and the license offer, acquisition and refund scenarios are removed; scenarios with course- or
  path-scoped subscriptions are rewritten or dropped.
- MOT-132 (embedding licenses) closes, and the `premium_embedding_license` flag leaves the MOT-115
  registry. MOT-126, MOT-127, MOT-130, MOT-131 and MOT-133 are re-scoped.
- These MOT-108 fixed decisions still hold: permanent purchases are independent of the
  subscription, cancellation keeps progress, and creation tools are free. The decision that
  embedding requires an explicit license is replaced by this ADR.
- ADR-058 still applies (Stripe), with its context narrowed to one subscription scope and
  no license.
- The commission rate and teacher price bounds remain configuration inputs, not part of this
  decision.

## Related ADRs

- [ADR-017: Student path copied instance](ADR-017-student-path-copied-instance.md): purchased
  paths are learned through the learner's copy.
- [ADR-055: Update a copy to latest](ADR-055-update-a-copy-to-latest.md): updates to purchased
  content follow the existing copy semantics.
- [ADR-058: Stripe as the payment provider](ADR-058-stripe-payment-provider.md): provider choice
  stands; content-specific subscriptions and licenses leave its scope.
- [ADR-059: Commercial authority, audit and idempotency](ADR-059-commercial-authority-audit-and-idempotency.md)
  and [ADR-060: Commercial records and recovery](ADR-060-commercial-records-and-recovery.md):
  unchanged; they apply to fewer operation kinds.

---

*Proposed on 2026-10-28. To revise, create a new ADR with Status: Supersedes ADR-067.*
