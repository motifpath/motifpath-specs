# Pattern: Plus and buying content (learner)

**Source:** ADR-067 (two commercial products) · ADR-068 (buy once or Plus on MotifPath content) ·
MOT-116 (Figma "Monetization — two products r5", PO approval 2026-11-01) · MOT-126 (row H, Plus
states r1, PO approval 2026-11-02) · [commerce contract](../../openapi/commerce-contract.md)

## When

Use it wherever a learner meets something that costs money: a course or path detail in Discover,
a locked lesson or premium exercise, the Plus plan picker, the payment return, and Your
subscriptions in Account. Teacher sales screens are MOT-130 (Figma "Teacher sales r1").

## Why

The learner must always know three things without reading terms: what this item costs, what Plus
covers, and what they keep. Two products only (ADR-067): **Plus**, one platform subscription for
everything by MotifPath, and **buy once**, permanent access to one course or path. Nothing about
money may erase progress, and nothing is ever shown as free or included when it is not.

## How

### Detail page (C1, B2)

- **No commercial labels on catalog rows.** Only the existing lock icon when the learner needs new
  access; free and accessible items have no marker (MOT-116 2026-10-17). The detail explains.
- **MotifPath item with a purchase offer (C1):** one row, two buttons, no prices: **Get Plus**
  (Primary) → C2 and **Buy once** (Secondary) → C7. Prices and savings live only in the sheets.
  Without a purchase offer the item shows Get Plus alone.
- **Teacher item (B2):** one action, **Review purchase**, and the sentence "Plus does not include
  this path, and you don't need Plus to buy it". A teacher item is never shown as included in Plus
  and subscribers pay the full price.
- **Active Plus subscriber on a MotifPath item (C4):** "Included in Plus" and Start. No Buy once
  (ADR-068: a subscriber is not offered the purchase).

### Plus plan picker (C2) and buy-once sheet (C7)

- C2 opens with a compact sunken panel worded like the byline: ✓ This course and everything by
  MotifPath · ✓ Premium exercises and practice tools · ✗ Courses by other teachers, sold
  separately. No chips or tags (PO 2026-10-31).
- Two plan cards, both priced per month for comparison. **Yearly is preselected** and adds
  "R$ — billed once a year", an "[X]% off" chip and "You save R$ — a year". Button: **Continue**.
- C7 states the one price and the scope: this course with its premium exercises; other MotifPath
  content and premium tools need Plus. Button: **Continue to payment**.

### Payment return (C3, H1)

- **Pending (C3):** StateBlock "Confirming your payment"; returning resumes the same payment and
  never starts another charge. The browser return proves nothing.
- **Failed (H1):** StateBlock "Payment didn't go through": no charge, Plus not active, lessons and
  progress untouched. **Try again** → C2 with the same plan; **Back to course** (Tertiary). A first
  payment has no grace.

### Your subscriptions (F5, F6, H2–H4)

- **Active (F5):** Plan, Billing, Current price, the yearly switch (monthly only; starts at the next
  renewal; nothing charged or credited now), Paid through and **Cancel next renewal**.
- **Stopping renewal (F6):** a bottom sheet over a 40% scrim: the rest of the paid period and all
  progress stay. Stopping renewal is not a refund (refunds: rows E/F).
- **Renewal stopped (H2):** "Ends on [date]" replaces the price; the yearly switch is hidden.
  **Keep Plus** turns renewal back on with no charge now (resume renewal, PO 2026-11-01). After
  the end date the subscription row is gone and the learner subscribes again from a detail page.
- **Renewal failed (H3):** an Error InlineNotice with the failed date and the grace end (exactly
  7 days). **Update payment method** opens the provider-hosted page, limited to that action (PO
  2026-11-01). Unfinished lessons stay open during grace.
- **Back from the provider page (H4):** a success toast and a notice that the retry is running;
  grace still applies until the payment is verified. No extra days are added.

### When Plus ends (D1, H5, H6)

- **Learning (D1)** keeps every row and its progress.
- **Detail (H5):** the C1 layout plus a notice: progress and finished lessons stay; Get Plus or
  Buy once to continue (the purchase offer returns when Plus ends).
- **Locked lesson (H6):** an unfinished lesson in a MotifPath course stays visible and opens the
  locked-step sheet ("Locked lesson") with Get Plus and Buy once. Finished lessons keep opening.
  A bought item never locks.

### Premium exercises in a free teacher path (G1–G3)

The outline shows a lock and a Plus chip on the premium step; opening it shows the locked-step
sheet with Get Plus. With Plus it opens in place. Buying a teacher path unlocks its premium
exercises there only.

### Feature flag OFF (H7)

`monetization.plus_catalog`/`plus_checkout` (and `motifpath_purchase`) OFF: the detail drops the
buttons and prices and shows "Not available to join right now" with an Unavailable notice. Existing
subscribers still see Included and Start, existing purchases stay, cancellation and payment-method
updates stay available. Content is never shown as free.

## Strapi responsibilities

Strapi supplies editorial copy only: the Plus benefit lines in C2, the item summary and localized
plan names. Core supplies every price, discount, saving, offer identity, access state and date.
When Strapi copy is missing or stale, use the built-in en/pt-BR strings above; when core offers
are missing, show the H7 state. A Strapi field can never show an offer core did not return.

## Decisions

| ID | Decision | Date |
|---|---|---|
| D1 | Two buttons on a MotifPath detail, no prices on the page | PO 2026-10-30 |
| D2 | C2 benefit panel worded like the byline, no chips/tags | PO 2026-10-31 |
| D3 | Both plans priced per month; Yearly preselected with saving and "% off" | PO 2026-10-31, 2026-11-01 |
| D4 | Subscribers are not offered Buy once on MotifPath items | ADR-068 |
| D5 | A stopped renewal can be resumed before it ends (Keep Plus) | PO 2026-11-01 |
| D6 | Failed renewal: update the payment method on the provider-hosted page | PO 2026-11-01 |
| D7 | Flag OFF hides new acquisition, never existing rights or servicing | ADR-067, registry r5 |

## Frames

Figma file "MotifPath Experience Language", page "Monetization — two products r5 (ADR-067 +
ADR-068)" (`722:2325`), Compact Light English:

- C1 `722:2754` · C2 `722:2785` · C3 `722:2824` · C4 `722:2844` · C7 `729:2566`
- B2 `722:2479` · D1 `722:2721` · F5 `722:3148` · F6 `722:3171` · G1–G3 `723:2751`, `723:2855`, `723:2923`
- Row H (MOT-126 r1): H1 `773:2564` · H2 `773:2601` · H3 `773:2662` · H4 `773:2733` · H5 `773:2933` ·
  H6 `773:3009` · H7 `773:3063`

Medium and Expanded follow the shell rules in `navigation.md`, sheets become dialogs per
`overlays.md`; dark mode and pt-BR use the existing tokens and strings.
