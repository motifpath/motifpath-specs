# Commercial activation registry — MOT-115

**Revision:** MOT-115-r4 · **Status:** Proposed; explicit PO registry approval pending. r4 removes the premium embedding license and content-scoped subscriptions (ADR-067).

This is the durable activation contract for new commercial capabilities. It does not enable flags, approve Figma revisions or prove runtime readiness. All defaults are OFF in local, test, staging and production; every environment starts with empty subject allowlists. No environment inherits another environment’s activation or cohort.

## Authority and admission

Core evaluates protected operations. UI mirrors core decisions; CMS, caller fields and cached UI state cannot authorize commercial effects. Each new action requires approved M0 gates and applicable UX revision, complete trusted configuration, its environment flag and subject allowlist, all applicable prerequisites and domain authorization. Missing, unknown or unavailable activation decisions deny new commercial effects.

Production user acquisitions additionally require private_beta admission for the requested action actor. Beta is admission rather than a dependency on both commerce tracks: Plus and teacher sales have independent readiness. Foundational service activation does not recursively require buyer admission.

Cohorts use authenticated core identities: buyer for subscription/purchase, owning teacher for sale actions, authenticated integration for CMS/provider onboarding. Resource rollout uses its trusted owner. Core resolves prerequisite subjects explicitly: foundation/provider readiness is evaluated for the trusted service/resource, buyer capabilities for the buyer and seller readiness for the offer’s verified seller. It must not reuse a buyer identity as a seller or service identity. Missing subject mappings deny the new action. Percentage targeting is not approved.

The authority commits an audited activation revision before it governs new intent. A new commercial operation must be fenced against a concurrent OFF change: after OFF commits, no new durable intent may authorize under an older revision. Intent durably authorized before OFF remains recoverable even if provider handoff or callback finishes later. Stale UI hints never permit the direct operation. Known same-intent replays preserve their recorded result after caller authorization; conflicting reuse is refused.

## Registry

Gilson Yamada is the accountable owner for every flag, as assigned for commercial rollout, reconciliation and editorial approval in the accepted contract index. Steward roles below describe proposed delegation, not separately assigned people. Core remains the decision authority for every row. Names retain the existing ticket mappings; plus_* covers the one platform subscription scope.

| Flag suffix (`monetization.`) | Runtime task | Steward role | OFF behavior |
|---|---|---|---|
| content_ownership | MOT-118 | Content provenance steward | Stop new commercial ownership classification; retain existing ownership and provenance history. |
| content_versions | MOT-119 | Content version steward | Stop new commercial manifests; preserve immutable evidence and references, existing path/course lifecycle, buyer copies and learner-pulled updates. |
| strapi_rights | MOT-120 | CMS integration steward | Stop CMS-driven commercial publication; continue authenticated ingestion/reconciliation of existing references without trusting CMS as rights authority. |
| commercial_validation | MOT-121 | Commercial publication steward | Stop new paid publication and commercial updates; retain existing dependency enforcement and purchased-content delivery. |
| entitlement_resolution | MOT-122 | Access policy steward | Stop activation on additional surfaces; keep access resolution active for any already commercialized resource. |
| access_grants | MOT-123 | Grant lifecycle steward | Stop new discretionary grants; continue existing-grant resolution and idempotent fulfillment/adjustments for already-authorized transactions. |
| progress_retention | MOT-124 | Learning continuity steward | Hide new commercial recovery UX; retain all progress and history and allow existing learning continuity. Retention is unconditional. |
| authorization_enforcement | MOT-125 | Protected resource steward | Stop activation on additional surfaces; never bypass authorization or make existing protected resources free. |
| plus_catalog | MOT-127 | Plus catalog steward | Hide new platform subscription sales surfaces; preserve current offers for authorized administrators and existing subscription rights/status. |
| plus_webhooks | MOT-128 | Payment integration steward | Stop onboarding new provider integrations; continue verified callbacks, durable receipt, fulfillment and reconciliation for all existing payment obligations. |
| plus_billing | MOT-129 | Billing lifecycle steward | Hide new acquisition-related billing UI; preserve existing subscription status, cancellation and required billing support. |
| plus_checkout | MOT-127, MOT-128 | Checkout steward | Reject new Plus checkout sessions; fulfill authorized in-flight sessions and process their verified outcomes. |
| teacher_paid_paths | MOT-131 | Teacher commerce steward | Stop new paid sale-state activation/offers; preserve free authoring, existing path lifecycle, retained buyer copies and permanent rights. |
| path_purchase | MOT-131 | Purchase fulfillment steward | Reject new path checkout sessions; fulfill authorized in-flight purchases and retain permanent grants. |
| teacher_settlement | MOT-133 | Financial operations steward | Stop onboarding new sellers/settlement programs; continue accounting, refunds, chargebacks, reconciliation and existing settlement obligations under approved policy. |
| private_beta | MOT-137 | Release steward | Stop admitting new commercial participants/actions; honor existing grants and service existing billing/payment obligations for removed cohorts. |

Flag names never switch off the invariant they resemble: progress retention, existing-resource authorization and established provider processing are always enforced. OFF stops new activation/onboarding, not existing protection, evidence or obligations.

## Prerequisites for new actions

Edges point from a prerequisite to its dependent. These are activation dependencies, not instructions to stop background obligations. Enabling an upstream flag never enables a dependent automatically. A disabled prerequisite refuses dependent new actions even when the dependent’s configured value is ON.

| Dependent suffix | Required suffixes |
|---|---|
| content_ownership | None |
| content_versions | content_ownership |
| strapi_rights | content_ownership |
| commercial_validation | content_versions |
| entitlement_resolution | content_ownership, content_versions |
| access_grants | entitlement_resolution |
| progress_retention | access_grants |
| authorization_enforcement | entitlement_resolution, access_grants, progress_retention |
| plus_catalog | authorization_enforcement |
| plus_webhooks | access_grants, authorization_enforcement |
| plus_billing | plus_webhooks |
| plus_checkout | plus_catalog, plus_webhooks, plus_billing |
| teacher_paid_paths | commercial_validation, authorization_enforcement |
| path_purchase | teacher_paid_paths, plus_webhooks, teacher_settlement |
| teacher_settlement | plus_webhooks |
| private_beta | None |

Conditional checks are distinct from the activation graph:

- Fresh CMS-managed presentation requires strapi_rights readiness only for actions using that integration. Core presentation supports Plus without Strapi. CMS outage blocks a new action that cannot establish required freshness; last validated metadata may support existing rights.
- Publication always validates transitive dependencies. MotifPath premium exercises in a paid teacher path are covered by the platform commission on each sale; the teacher needs no license or other prior purchase.
- New path purchases additionally require validated sale manifests, seller readiness, complete price/allocation configuration and verified Connect capability. Independent Plus activation does not establish these conditions.

## Launch matrix

| Stage/track | Evidence and targeting | Allowed activation |
|---|---|---|
| Baseline | All flags OFF; empty cohorts | Existing free learning/authoring and established rights/obligations continue |
| Foundation rehearsal | Explicit sandbox service/resource subjects; audited backfill and protected-delivery evidence | Ownership, manifests, resolver, grants, progress continuity and enforcement in prerequisite order |
| Subscription rehearsal | Sandbox buyers; approved scoped BRL offers/prices; Payments/Billing, cancellation and recovery evidence | Plus without CMS or settlement activation |
| Teacher-sales rehearsal | Approved sellers/buyers; manifests, bounds/commissions, Connect fees/capability and refund liquidity | Paid sale state and permanent purchases with settlement/recovery readiness |
| Staging | Explicit sandbox cohorts; applicable track dependencies; admission rehearsal | MOT-134 journeys, MOT-135 OFF/concurrency drills and MOT-136 recovery evidence |
| Production beta | Explicit reviewed track/configuration, applicable Figma revision, accountable owner, validated account and operational evidence | Only selected action cohorts; no automatic second-track or cohort expansion |
| Rollback | Audited beta and acquisition/onboarding OFF revision | No new intent; existing rights, callbacks and obligations continue |

Initial market is BRL. Missing approved price/discount/bounds/commission configuration, required provider capabilities, refund liquidity or retention/privacy approval keeps the affected track OFF. No example values authorize launch. MOT-116 and applicable MOT-126/130 UX approvals remain gates. Financial policies follow [commerce contracts](commerce-contract.md); this registry does not replace those decisions.

## Always-active safeguards and rollback

Acquisition controls never disable existing-resource authorization; independent valid grants/permanent purchases; progress/history retention; verified provider receipts and previously authorized fulfillment; subscription cancellation/status support; refunds/disputes; reconciliation and existing settlement; durable audit/export/holds; or idempotency and business-effect uniqueness. A grant caused by an authorized callback is fulfillment, not a new discretionary grant.

1. Record actor, reason, time/environment, operation identity, affected cohorts/flags and prior/new configuration revisions. Commit activation changes and durable evidence together. Denied, duplicate, conflicting and uncertain attempts remain traceable without duplicate financial effects.
2. Turn beta and affected new checkout, sale and seller onboarding OFF. Fence direct operations at durable intent authorization and mirror disabled acquisition in UI. Preserve existing cancellation and support surfaces.
3. Continue verified callbacks and outstanding work even for removed cohorts. Uncorrelated receipts are retained for verification; they do not create grants from untrusted declarations. Reconcile uncertain outcomes before any new financial attempt.
4. Preserve permanent purchases despite seller subscription or cohort changes. Apply approved successful-refund/final-dispute policy only to linked grants, preserve independent rights and progress, and keep pending-dispute access otherwise valid. Never make protected content free as an OFF fallback.
5. Keep core authoring, retained buyer copies and explicit learner-pulled updates intact. CMS unavailability or deletion cannot delete rights, money or learning history. Do not restore a binary incapable of recognizing stored commercial resources and obligations.
6. Keep audit export, archive-aware reads, holds and verified cleanup active under accepted retention rules. Acquisition OFF never permits evidence loss or removal of business uniqueness. Restore/replay must be fenced and verified before outbound effects resume.
7. Check backlog recovery, protected delivery, retained copies/progress, refunds after payout and cancellation against real persistence/provider sandbox evidence. Re-enable only an explicitly reviewed track/configuration in prerequisite order; preserve history and do not auto-expand cohorts.

## Traceability and approval

MOT-118–125, MOT-127–129, MOT-131 and MOT-133 are mapped above; MOT-137 owns controlled admission. MOT-134 journeys and MOT-135 rollout/rollback cover every flag; MOT-136 covers provider, grants, CMS, settlement, admission and evidence recovery. These are all 17 M1–M5 runtime/validation subtasks; MOT-132 (embedding licenses) closed with ADR-067. MOT-114/115/116/117/126/130 are audit, registry, design and contract gates, never switches that disable validation.

Proposed behavior is in [commercial controls](../features/monetization/commercial-controls.feature), complemented by the [contract index](../features/monetization/README.md). Scenarios remain @wip until runtime TDD and real persistence/recovery verification pass. Syntax and graph checks establish only specification consistency.

MOT-117 contracts and accepted ADR-058/059/060 remain authoritative. MOT-115-r4 requires explicit PO approval recording approver, reviewed revision and date before its names/activation decisions become approved. PR creation or integration alone is not that approval. Figma, deployment configuration and runtime evidence remain separate gates. Local implementation plans and JSON review artifacts remain unversioned under ADR-022.
