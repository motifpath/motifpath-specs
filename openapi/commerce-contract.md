# Commercial architecture and integration contracts — MOT-117

Status: consolidated specification for review, 2026-10-15. Business bundle approved by Gilson
in chat on this date. ADR-060 was approved by Gilson on 2026-10-15; API additions still require PR review. This is a durable contract,
not an implementation plan. No runtime readiness or Figma/flag approval is implied.
Revised 2026-10-29 for ADR-067: two commercial products; course/path-scoped subscriptions and
the teacher embedding license are removed.

## Authority and identifiers

Core-domain owns commercial content provenance, immutable sale manifests, product/offer revisions,
accepted terms, customer mappings, operations, receipts, money, grants, purchases and
settlement. Aggregation-worker owns derived progress; core reads its authoritative completion
records. Vue and CMS mirror backend decisions. Neither a Stripe email nor editable metadata
proves ownership. Each environment maps authenticated core users to verified provider customers.

All internal business identities are server UUIDs except caller command UUIDs, which remain
qualified by environment, authenticated actor/integration, action and resource. Audit-entry,
receipt and decision IDs are globally unique server IDs. External IDs are always qualified by
trusted environment/account. Never match by a bare provider ID across accounts or modes.

There are exactly two commercial products: the platform subscription and the permanent
teacher-path purchase. The platform subscription has one platform-wide scope and covers
MotifPath-owned content (team-authored courses and paths, premium exercises and premium tools);
it never covers teacher-priced content. There are no course- or path-scoped subscriptions and no
teacher embedding license. Subscription periods are monthly and annual, both automatically
renewing. Prices, annual discounts, teacher bounds, commission and fee allocation are
configurable. MotifPath-owned content is not sold individually, and subscribers get no discount
on teacher purchases. New sales require complete validated configuration and
eligible offers. Free-to-paid changes must explicitly preserve previously granted free access
through durable grandfather grants; an existing learner is never silently charged or converted. Initial activation is **BRL only**; USD requires a separate explicit market/cost
approval. Currency syntax alone enables nothing. A yearly offer must be cheaper than twelve
monthly periods in the same currency. No launch prices are invented by example values.

Offer IDs name immutable accepted price revisions. Admin configuration promotion is revision-checked and serialized; concurrent stale changes are
rejected. Subscription price promotion additionally requires expected_offer_id for the exact
billing period/currency, including explicit null before the first offer. A shared platform
configuration_id is not an offer-version precondition. Admin GET /admin/subscription-offers
returns the promoted offer even when acquisition is OFF; 404 means no offer has been promoted.
Serialize promotion by currency, compare-and-replace the observed offer, validate discount
relationships and append evidence atomically. Two distinct commands observing the same old offer
cannot both replace it: after the first promotion, the second returns conflict. Known same-intent
replays return their original result before the stale-offer check. Changing a monthly baseline
revalidates new annual offers against the discount rule;
existing accepted snapshots stay unchanged. Changing a price creates a new ID; history,
in-flight checkout snapshots and ledger allocations retain the original terms. Existing
subscriptions adopt changes at next renewal only. The platform subscription never covers
independent teacher commerce; eligible product/dependency manifests define actual coverage.

## Ownership, commercial manifests and learner copies

Each content resource has a trusted rights holder, original creator when known and provenance
evidence. Ownership has its own monotonic revision, distinct from content edits and offer prices. Browser/CMS declarations cannot transfer ownership. Corrections are admin-reviewed,
revision-checked and append evidence; prior creator and financial obligations remain intact.
Legacy nullable creators do not imply platform ownership: unresolved owner_kind has null owner_id;
unresolved records are quarantined
from new paid publication until reviewed, with deterministic migration mappings and audit.
Existing free rights are backfilled explicitly before new enforcement; no blanket paid ownership
or new charge is inferred. Backfill is restartable, uniquely keyed by source/resource/holder and
never deletes progress. Rollback stops new acquisition but does not revert paid records.

A commercial release is an immutable rights/dependency manifest keyed separately from existing
CourseVersion, live LearningPath and ContentNodeVersion identities. It captures exact core
references, content revisions/digests, ownership, permissions and transitive premium dependencies.
An unvalidated free resource has release=null; paid state always requires a validated manifest.
Canonical digests use UTF-8 JSON with recursively sorted object keys, array order preserved,
integers represented exactly, no duplicate keys and unchanged string content. Hash the manifest
payload before adding its manifest_sha256 field; source bytes have their own content_sha256.
It does **not** create a new path publication process or silently switch learner copies to a
new version. Paths retain their existing publish/edit behavior and courses retain published
version/enrollment pins. This explicitly resolves the earlier lifecycle ambiguity: commercial
withdrawal is a sale-state change, not deletion or an automatic learner update.

Validate the complete dependency graph when creating/changing a paid offer, commercial release
or affected update. Reject cycles, missing resources, stale/unresolved rights, unsupported third-
party rights. A direct API call has the same boundary as the UI. Own and explicitly reusable free
content is permitted; free visibility alone is not redistribution permission. MotifPath premium
exercises embedded in a paid teacher path, directly or nested through lessons, are recorded as
platform_premium dependencies. The single platform commission on each sale covers them; there
is no separate license, surcharge or prerequisite purchase for the teacher. Updating dependencies
invalidates new-sale validation until rechecked.

A purchase grants the buyer every exercise the purchased path contains, premium ones included,
for that path only; it never unlocks those exercises elsewhere. A premium exercise in a free
teacher path stays locked for learners without the platform subscription.

Permanent buyers retain existing copies after sale withdrawal, including unfinished lessons.
Course copies keep their existing published version reference; path copies keep their current
item/reference set. Existing lesson rendering/version behavior is not replaced. Updates are
free, explicit learner pulls through existing update rules; never auto-push or staff-update.
Release history remains resolvable after withdrawal through authorized manifest reads.
Persist the manifest source snapshot in protected immutable storage indexed by release/digest;
never resolve an old commercial manifest by reconstructing it from a mutable current template.
This archived rights/source evidence does not change existing live lesson rendering or copy updates. Removed media cannot be deleted while
retained buyer obligations reference it; legal takedowns require a separately reviewed case.

## Grants, access and time

Store separate grants rather than one user-wide entitlement flag. Each grant names holder,
scope, basis/source, validity and evidence. Permanent purchase grants have no time expiry;
subscription-period grants derive from a verified paid invoice/period. A free allocation is an
explicit backend record, not inferred from a missing price. Completed-lesson retention derives
from authoritative completion and an expired, non-refunded prior subscription grant. It does
not revive a successfully refunded or lost-dispute grant. Independent free/paid/permanent rights
are evaluated together. Refund/chargeback transitions never delete completion evidence.

Use trusted UTC instants and half-open paid/grace intervals: valid_from <= now < valid_until.
Cancellation only disables the next renewal, preserving the paid interval. A failed renewal
gets exactly 168 hours of grace from prior paid_until; initial payment failure gets none. An
unpaid lesson blocks at grace_until, remains visible and keeps progress. Payment recovered
later grants only its verified billed interval; no extra days arise from delayed notification.
Monthly-to-annual switching is next-renewal only, without midperiod credits; annual-to-monthly
is not offered. Serialize racing renewal/cancellation/switch commands by subscription revision;
a committed cancellation before the renewal authorization prevents that charge. A previously
authorized external charge cannot be undone by assuming cancellation was a refund.

A pending dispute preserves otherwise valid access and never extends an expired subscription.
A verified final won outcome preserves any still-valid grant; final lost ends only the disputed
payment's grants immediately. Replayed or older statuses cannot override a later established
final result or successful refund. Provider funds withdrawn/reinstated are accounting facts,
not sufficient grant instructions. Conflicting authoritative final states enter review; an
independent proven grant still permits access. No won outcome restarts a paid interval.

Access decisions are attributable reads, not bearer tokens. A backend resolver is required at
all protected lesson/content, exercise, media, export and download boundaries. Validate caller,
copy membership, commercial coverage and existing learning prerequisites. Do not expose paid
payloads in catalog/outline/search, expanded-content helpers, previews or alternate endpoints.
A valid subscription does not unlock prerequisites or grant authoring rights. Staff/author
preview remains explicitly role/ownership-authorized, never a learner bypass.

Protected media must use private object storage and backend-authorized delivery, with origin
access restricted to the delivery service. The public upload/CDN URL is not sufficient. Validate
current rights for every delivery request, including range requests; no reusable decision UUID
or public redirect grants access. Do not cache personalized authorization responses; separate
safe object byte caching behind the authorization boundary. Immediate revocation applies to new
requests after committed refund/lost outcome, not already downloaded bytes. Byte-level erasure
from a learner's device is not promised. Protect exports with the same current-rights checks.
Direct public origin and alternate URL bypass tests are mandatory before activation.

## Financial facts, journal and settlement

See [machine schemas](components/schemas/commerce.yaml) for stable domain shapes. Use integer
currency minor units; never binary floating point. Maintain a per-currency balanced append-only
journal. Every posted journal has a unique business source and sums debit == credit. Original
sale facts, provider fees, commissions, seller earnings, customer refunds, disputes, transfers,
bank payouts, recoveries and MotifPath losses remain separate attributable entries. Corrections
reverse/repost with links, never overwrite prior postings. No cross-currency netting. Reject
out-of-range arithmetic before committing; aggregate using checked exact arithmetic.

For gross G and configured platform share B basis points, platform commission is
floor((G * B + 5000) / 10000), using exact intermediate arithmetic. Teacher sale fee share uses
the same half-up rule against actual provider fee F and configured teacher-fee basis points.
Teacher earnings are G - commission - allocated sale fee. Never allow a configuration/offer to
produce negative seller earnings; unexpected late fees enter reconciled platform adjustment
review rather than silently debiting a teacher bank account. Snapshot allocation configuration
at accepted sale; later configuration changes affect only future sales. Refund processing fees
are MotifPath cost, never deducted from customer refund. Return 100% of original captured amount.

Reserve each earning once before a Connect transfer. Eligible earnings become payable at the
first successful scheduled settlement sweep after provider availability, capabilities and
recovery offsets are verified. Run settlement discovery every five minutes; provider delays and
failures remain observable obligations. No voluntary platform reserve. A transfer is not proof
of bank payout; reconcile transfer and connected-account payout references separately. Reconcile
failed/unknown transfers before any new attempt. All earlier obligations continue with flags OFF.
Connected-account/currency mappings must be verified; onboarding/identity collection uses the
provider-hosted flow, never browser-supplied bank details or CMS. No live onboarding is enabled
until sandbox/country/capability evidence exists.

A successful full refund reverses the original commission and seller allocation. If unpaid,
cancel the untransferred earnings reservation. If paid, offset only the teacher's original net
earnings from future earnings in that same currency; MotifPath funds the customer's full refund
without waiting. No automated seller-bank debit or voluntary reserve. When no future earnings
exist, record platform loss; never charge the customer or delete rights/progress to cover it.
A later recovery reverses the corresponding loss rather than double-counting. Lost disputes use
the same original-earnings recovery boundary; provider dispute fees belong to MotifPath in this
initial profile. Pending disputes record actual provider balance movements separately and do
not issue a second customer refund. Track returned amounts per payment across refunds/disputes;
reconcile competing outcomes before initiating any additional financial return.

## Refund review and notifications

Refund eligibility is first platform subscription per holder, never reset by rejoin, renewal or
period switch. Paid path purchase refunds use the original acquisition payment. The commercial
window starts at max(verified paid_at, first access_available_at), only when both exist, and
ends **inclusively 168 hours later in UTC**. Use original durable request time, not admin handling
time; a timely request stays timely. Future renewal remains enabled after refund unless the
learner separately cancels. No partial-refund automatic flow is enabled at launch.

All refunds are handled by administrators. Cases outside the automatic commercial rule are
retained for explicit audited review, including statutory exceptions and partial-refund requests.
The review endpoint can approve a documented full refund or decline with evidence; approval is
not a financial refund. Partial refunds require a future amount/allocation/access contract and
cannot be silently executed by changing the full-refund amount. Do not claim the commercial
window eliminates mandatory legal remedies. Definitive failed executions may be retried only
through an admin revision-checked retry after verified absence of prior success; uncertain
outcomes remain processing. Reuse the logical case and business uniqueness, with new attributable
attempt and provider key only once authoritative failure proves no prior refund effect exists.

Annual notices use distinct subscription/renewal-time/notice-kind identities at seven days and
one day. Freeze intended content per notice and delivery channel. Retry transient delivery via
its durable delivery identity with bounded backoff until renewal, then record missed/failed and
alert; never silently drop a required notice or send it after renewal. Permanent failures remain
visible to support. Delivery cannot guarantee human reading. Schedule changes supersede unsent
notice work without removing already sent evidence. Provider success/response loss requires
provider delivery deduplication or reconciliation; never promise exactly-once email delivery.

## Persistence, evidence, retention and recovery

Use the transactional boundary in ADR-060. Uniqueness keys include operation namespace/fingerprint,
provider receipt, payment/refund movement, invoice grant, holder/product acquisition reservation,
sale allocation and settlement earning reservation. Review canonical intent
before expected_revision for known same-intent retries; always recheck caller authorization.
Canonicalization uses stable action/version/target/body fields; missing and explicit null remain
distinct unless the endpoint explicitly equates them. Never include secrets in a fingerprint log.

Outbound tasks and internal events carry message_id, operation namespace, correlation/causation,
environment, aggregate identity/revision, type/version, occurred_at and a minimal typed payload.
Supported v1 kinds are payment.verified, grant.changed, purchase.fulfilled,
refund.confirmed, dispute.resolved, settlement.changed, commercial_content.changed and cms.sync_requested.
Consumers use current authoritative aggregate state, not arrival time. The envelope/schema is in
[commercial messages](components/schemas/commercial-messages.yaml). It is private service traffic,
not an accepted POST /events learning payload or a public financial mutation API.

Restrict database roles: runtime may append audit/journal and update permitted operation state;
normal application roles may not update/delete prior evidence. Separate audit-reader, exporter,
cleanup, support and migration roles; admin UI does not imply database superuser. The narrowly
scoped cleanup role may remove only expired, verified-archived, unheld hot audit rows under the
rules below; it cannot rewrite evidence, remove archive objects or delete journal/identity records.
Archive credentials are independent of the application writer and cannot bypass Object Lock.
Verify chained/digested checkpoint completeness on restore and alert on gaps. A database digest
alone is not independent tamper protection. Secrets/raw payment credentials never enter audit evidence. Resource/action state allowlists are: content owner,
creator/provenance, sale state, release/offer/config references; grant scope/source/status/validity;
subscription scope/offer/period/renewal; payment/refund amount/currency/status/provider-safe refs;
settlement allocation/movement/status. All other fields require
explicit schema review; unknown sensitive fields are rejected, not blindly serialized.

### Hot audit TTL and asynchronous archival

**Hot audit TTL: 30 days = 720 hours from immutable server recorded_at in UTC.** It starts when
the evidence is committed, not when a financial operation closes or when export/retry happens.
Retries, reads and export attempts never reset it. A row is eligible for removal at
now >= recorded_at + 720 hours, only with verified archive evidence and no retention hold.
This TTL applies solely to full audit payload rows. It does not expire financial journals,
payment/refund records, operation fingerprints, deduplication tombstones, grants,
purchases, pending inbox/outbox work or archive-catalog metadata. No database-wide TTL is implied.

The **asynchronous audit exporter** is a background worker consuming durable committed work:

1. The business transaction atomically records mutation, immutable audit entry and export work.
   No S3 request runs inside that transaction or on the synchronous request path. Rollback leaves
   no exportable evidence or outgoing work. Export scheduling is independent of acquisition flags.
2. Run hourly, batching pending committed evidence at each scheduled sweep. Do not trigger an
   export for every new entry; recent operational reads use Postgres while independent archival
   is pending. Skip upload when there is no pending evidence. Scan all pending work, including
   older failed batches, rather than a last-hour-only lookback. Claim bounded batches with
   recoverable worker leases.
   Persist batch identity, immutable member set/digest, counts and content checksum before upload.
   Scope batches and object destinations by trusted environment. A batch never changes members
   once upload is attempted. The catalog is worker metadata, not a mutable audit payload.
3. Write compressed canonical evidence and an integrity manifest to a dedicated private S3
   Object Lock archive. Use stable batch/object identity on retries. A timeout leaves export
   pending until that exact object/version is reconciled; it never authorizes a different batch
   body under the same key. Verify object version, full content checksum, exact member set/count,
   readability and the configured lock/retention protection before committing verified status.
   Upload acknowledgement or an ETag alone is insufficient evidence of a verified archive.
4. A crash after upload but before local acknowledgement reconciles the same batch/object.
   Duplicate delivery converges; entry IDs preserve evidence identity even if repair needs a
   replacement archive object. Keep outbox work until verified status and catalog checkpoint
   commit durably together. Failed uploads/verifications retry with bounded backoff and jitter;
   expired worker leases resume existing work rather than abandoning a batch.
5. Alert when the oldest committed unverified entry exceeds two hours from recorded_at.
   Checksum/member/lock mismatches and cleanup verification failures alert immediately,
   independently of backlog age. Record
   backlog count/oldest age, export latency, retries, archive integrity failures and retained
   rows older than TTL. A long outage is observable; it cannot silently discard evidence.

The hourly schedule accepts approximately one scheduled interval, plus processing time, before
recent evidence gains independent archive protection. This is the explicit cost/protection
trade-off; the 30-day hot TTL is not the export interval. Monitor archival lag independently of
export execution so a stalled exporter cannot suppress its own alert. Retries retain their
stable batch identity and bounded backoff. Payment/settlement/CMS reconciliation schedules
remain separate; their more frequent sweeps do not trigger normal audit export batches.

A separate **hourly cleanup** selects eligible expired rows in bounded batches. It must verify
current durable catalog coverage and required archive protection before deleting. Every selected
entry must belong to a verified immutable batch with its exact content digest and complete
verified locator-index coverage. Check holds again
inside the deletion transaction and coordinate hold placement with deletion; a concurrent hold
must not race an unchecked purge. Skip any row lacking proof, pending export, conflicting
checksum, unavailable archive verification or an active hold. Do not drop a whole partition
unless every contained row meets the same rules. Under healthy archival and no holds, rows
leave the hot table at the first successful hourly sweep after TTL (target within one hour).
Archive outage/holds suspend deletion, not retention of the original evidence. Purge only the
hot copy, never its permanent archive or business-effect identity. Record cleanup batch ID,
operator, entry-set digest/count, cutoff and archive proof in new independently exported audit
evidence. Cleanup does not recursively delete its own newly created evidence in that sweep.

Long-term evidence reads must remain complete after hot deletion. The admin audit API resolves
both stores through the same authenticated filters/snapshot fence and deduplicates by immutable
audit_entry_id. Export or cleanup during traversal cannot omit or repeat an entry. Keep a durable
archive catalog with batch ranges/counts, object/version/checksum and member-set digest; it must
remain resolvable for the archive lifetime. A **mandatory compact archive locator index** supports
the API's operation_id and resource_kind/resource_id filters, qualified by trusted environment
and the same immutable order/snapshot key as recent evidence. Keep it in Postgres as derived
lookup metadata, not full audit payloads: entry identity, filter keys, recorded_at/order key,
verified archive batch reference and entry checksum. It has the archive's lifetime rather than
the hot payload's 30-day TTL. This explicit metadata/index cost avoids scanning years of archive
objects on an administrator's request. Full evidence remains solely in the recent/immutable
stores; the index is rebuildable and is never financial authority.

Commit complete locator coverage together with verified batch/catalog status before export work
is acknowledged. Cleanup additionally requires exact verified locator coverage for every selected
entry. An archive upload without indexed coverage cannot permit hot deletion. Query the recent
store and archived locator index in stable order, merge/deduplicate identities, then fetch only
the verified batches containing that page's matched entries. An archive-only page fetches at most
limit distinct batches, plus at most one lookahead candidate to determine continuation; queries
must not scan unrelated objects to locate an operation/resource. Shared batch fetches are reused
within a page. Retain the existing opaque cursor and snapshot fence across export/deletion.
The read path validates each returned entry against locator checksum, identity and requested
filters. Only authorized backend services access locators and archive objects.

If the locator index is unavailable, incomplete or rebuilding, relevant historical queries return
unavailable rather than falling back to an unbounded archive scan or reporting an empty history.
Rebuild offline from verified manifests/evidence and restore complete snapshot coverage before
serving historical reads. If required archive/index data cannot be read, return
unavailable instead of a partial or apparently empty history. Direct S3 access is not granted
to the browser. After backup restore, reconcile catalog/object proofs before exporter/purger
activation; replaying restored old rows must not duplicate financial effects or archive history.

Accepted architecture retention baseline (ADR-060): seven years after financial/lifecycle closure for
redacted journals, archived commercial evidence and financial operation fingerprints; keep active permanent
rights and minimal business-uniqueness tombstones for the entire obligation lifetime. Restricted,
encrypted provider inbox payloads expire after 30 days once processed/reconciled and free of legal
hold; unresolved cases retain required evidence under reviewed holds. Redacted operation identity
and business uniqueness must survive raw-payload deletion and retry-cache expiry. No deletion of
active rights/uniqueness is permitted by a timer. Separate optional personal contact data from
pseudonymous transaction references. Retention is an engineering baseline, not a statement of
statutory compliance; approve jurisdictional/privacy retention before production activation.
The long-term seven-year rule is independent of the 30-day Postgres audit TTL. Protect archived
active obligations until closure, then retain through the approved post-closure period; extend
locks/holds before expiry, never rely on an already-expired archive object for cleanup proof.

Reconcile outstanding obligations every five minutes and active coverage daily, with durable
paging/checkpoints, bounded rate-limit backoff and no recent-only loss of old pending work. A
restart after provider success/before local commit must read/reconcile the existing operation,
not issue a fresh charge. Restore backups to a fenced environment, verify journals/evidence and
provider state before enabling outbound workers. Provider keys may expire; durable tombstones
and effect uniqueness remain. Alerts: orphan receipt/payment, money mismatch, unbalanced journal,
overdue refund/transfer, repeated recovery failure, stale CMS mapping and audit-export gaps.
Never place credentials or raw envelopes in alerts. Operations runbooks must prove this with real
persistence/provider sandbox failures in M5, not infer runtime correctness from spec validation.

## CMS synchronization

Strapi is not provisioned. No provisioning or authoring migration is approved here. Schema mapping:
core content_id/kind + locale maps to a registered source document; adapter stores source revision,
observed digest, last successful core revision and event receipt. CMS-managed fields are localized
commercial display title/summary/artwork and editorial visibility. Owner/provenance references,
core release/offer IDs and rights declarations are validated references only. Prices, grant state,
payments, teacher allocation and commercial flag decisions are core-owned and reject
CMS writes. Source deletion hides new editorial presentation; it cannot delete financial evidence
or an existing purchased copy. No source fallback may make a paid resource free.

Use TLS and distinct rotating per-environment service credentials with bounded overlap; compare
credentials without logging them. Adapter notifications have durable identities and authenticated
source binding. When native delivery lacks a stable event ID, persist an adapter identity keyed
by registered source/document, event kind and canonical source revision/digest. Repeated delivery
reuses that identity rather than generating a fresh UUID. Never expose this credential in Vue. Native CMS event headers are not assumed to
be HMAC signatures. Pull current metadata with a read-only scoped token, compare core optimistic
revision and canonical source digest, then apply allowlisted fields. Duplicates converge; reordered
hints trigger fresh reads rather than overwrite newer state. Stable mapping belongs to core and
cannot be reassigned by a source ID change. Missing/conflicting mappings enter quarantine.

Five-minute outstanding sync and daily mapping coverage use durable cursors; callback omission
or CMS outage is repaired by polling. Last validated metadata may serve existing rights; stale
critical rights block new commercial publication/acquisition only. When CMS is disabled or absent,
core's existing authoring/presentation remains the source; CMS is not a dependency for Plus.
The Strapi adapter's exact runtime release must be pinned when MOT-120 provisions it; this protocol
does not rely on version-specific document IDs or select a CMS deployment.

## Validation and delivery gates

Business scenarios cover each boundary under features/monetization. Schema validation is evidence
of contract shape only. Runtime work starts with failing behavior tests and real persistence;
require concurrency, restart-after-commit, provider timeout, duplicate/out-of-order/foreign-account
callbacks, missing CMS notifications, public URL bypass, refund-after-payout and flag rollback.
Figma approval in MOT-116 and registry approval in MOT-115 remain separate M0 gates. Current
configuration values, secrets, provider account capability/fees and production retention approval
are deployment inputs; absent values disable acquisition instead of changing this contract.

Primary integration references checked 2026-10-15: [Stripe separate charges/transfers](https://docs.stripe.com/connect/separate-charges-and-transfers),
[idempotency](https://docs.stripe.com/api/idempotent_requests), and
[Strapi configurable webhook headers](https://docs.strapi.io/cms/configurations/server).
The adapter, retention baseline, rounding and authorization boundary above are MotifPath design
choices recorded in accepted ADR-060 and this contract, not promises supplied by those providers.
