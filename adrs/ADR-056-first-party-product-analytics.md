# ADR-056: First-Party Learning Events with PostHog and Hotjar

**Status:** Proposed
**Date:** 2026-10-12, revised 2026-11-08
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-30 (PB-73). Builds on the MOT-8 alpha observation view.

## Context

MotifPath needs to decide each week whether to improve onboarding, navigation, exercise content,
practice composition, or reliability. ADR-049 calls for a friction baseline covering interactions
per item, time to the first item, and early exits or abandonment. The current events can answer more
than the original proposal assumed. They also have limits that can make a technical failure look
like a hard exercise or a missing event look like a student leaving.

The baseline below is a source audit of motifpath-specs `origin/main` (0558381), motifpath-core
`origin/dev` (800f3c4), and motifpath-web `origin/dev` (e481a73). Availability in these revisions
does not establish deployment, event coverage in production, or enough data to draw conclusions.

| Question and decision it supports | Existing evidence | Remaining work |
| --- | --- | --- |
| Q1. Where do students leave practice, and should we shorten or reorder sessions? | `practice.session_started` records the ordered plan and pick reasons. `practice.session_ended` records answered count and explicit early exit. Missing ends can be inferred under the planned minutes plus 15 rule, and late events can reopen the session. | Report finished, explicitly ended early, inferred abandoned, and still open separately. Last recorded answer can locate a stopping region, but the plan alone cannot establish which item was shown. |
| Q2. Are students reaching three finished sessions per week? | MOT-8 counts finished sessions by their start week in São Paulo time and shows cohort and student results. | Reuse its metric and cohort. Show starts and early exits alongside it to distinguish getting students into practice from helping them finish. |
| Q3. Where does first-path progress stall? | MOT-8 shows completed nodes over all first-path nodes, including locked nodes, and preserves the original path when a later path replaces it. | Use node status and exposure to distinguish blocked access from poor completion after a start. Keep the original PB-8 metric as its own measure. |
| Q4. Are students returning to learn? | MOT-8 reports last activity and quiet students. ADR-051 defines practice days and streaks. | Define signup or first eligible signed-in visit as the cohort anchor before reporting D7/D30/D90. Use qualifying learning activity for learning return and report app return separately. Include only cohorts old enough to reach each milestone. Measure return after a streak break separately. |
| Q5. Is it slow to get to the first usable item? | Session start, lesson start, and first committed answer are available milestones. They include different amounts of setup and learning time. | Measure signed-in app ready to first usable item shown, with the share reaching it in the same visit. Also measure start to first item separately to distinguish navigation from loading. |
| Q6. Which exercises or drills should we fix, and why? | `practice.item_answered` includes a committed response or a `not_answered` reason. Grading results and folded progress add learning evidence. The event can belong to a composed practice session or an exercise reached through `trigger_context`. | Compare exposure, answerability, incorrect outcomes, and interaction effort separately by exercise or drill and context. The current stream omits exposures with no answer, and does not count general UI interactions. |
| Q7. Where does first-run activation stall? | Lesson and practice starts provide downstream milestones. Onboarding, starting points and enrollment have their own product state and contracts. MOT-8's first-path cohort misses students who never receive a path. | Start with all eligible new signed-in students. Verify which successful starting-point and enrollment milestones have durable, timestamped records. Instrument only missing steps. Treat direct entry and resumed students separately. |
| Q8. Which screens are worth improving? | `song_chart.opened`, `song_chart.chord_viewed`, and `song_chart.completed` provide chart-specific evidence. Lesson and exercise lifecycle events cover some actions. | Define meaningful actions for each selected screen. Measure visits without an observed action separately from exits, deliberate reading or browsing, and unknown outcomes. |
| Q9. Is friction concentrated in a particular app surface? | ADR-063 adds native iOS and Android shells to browser and installed PWA. | Capture coarse runtime surface and viewport class on eligible visits. Use these to explain differences in activation, load failure, or abandonment. Viewport class cannot identify physical device type. |

Exercise lifecycle events and item evidence represent different units. `exercise.ended` describes
an exercise lifecycle outcome. An option answer is committed when the student moves on or finishes.
Selections changed before commit and later revisions after going back do not create additional
evidence. The current `tap_ms` field is a server-enriched motor baseline from a tap check. Response
`latency_ms` has type-specific timing, including a different start point for audio options.
Timed musical taps are part of the task itself. Warm-up takes intentionally omit answer evidence.
One multi-cell drill response can produce several evidence records under ADR-057. Use a committed
item attempt for interaction metrics and graded evidence for learning metrics. For results after
practice, use the folded state and the catch-up signal in ADR-066 rather than inferring progress
from raw arrival order or the immediate session summary.

## Decision

MotifPath will keep authoritative learning events and derived outcomes in its own pipeline and use
**PostHog for quantitative product analytics** and **Hotjar for targeted web UX research**. MOT-30
owns the measurement definitions and vendor integrations. MOT-8 continues to provide the existing
alpha observation metrics and access to authoritative learning records.

### 1. Start with decisions the existing evidence supports

Use MOT-8 for weekly finished-session and first-path targets. Derive session outcomes and exercise
and drill diagnostics from existing events and folded state. Join planned items
to practice activity using student and practice session IDs and the planned item identity. Where
the same identity recurs, preserve occurrence and order when the data supports that attribution.
Keep ambiguously matched items in an explicit unknown bucket. Preserve attempt context, exercise or
drill kind, subject, and relevant rung when available. Keep missing dimensions visible.

Show `not_answered` reasons independently of grading failures and incorrect answers. Compare
results by modality and content or plan revision when identifiable. Separate authored exercises
from generated drills, warm-ups, and self-rated or instrument work. Do not count a multi-cell
response as several attempts or use the number of stored evidence rows as a denominator for UX
rates. Verify the coverage of each active client path before publishing comparable rates.

### 2. Instrument the missing journey milestones

Use the existing authenticated ingestion boundary and idempotent event identity. Define a small
allowlist of usage milestones in the follow-up spec:

- Signed-in app ready, once per authenticated app instance, with coarse runtime surface
  (browser, installed PWA, native iOS, native Android, or unknown) and viewport class.
- Entry into selected screens, using a stable route category and a typed subject reference where
  needed. Record initial entry and meaningful screen or subject changes. Assign a visit identity
  so repeated visits to the same screen can be distinguished.
- First usable presentation of an eligible item attempt. Link it to the screen visit and, when
  available, the practice session or exercise context. Distinguish presented, failed to render,
  and unknown when calculating exposure-based rates.
- Successful onboarding or starting-point milestones only where a timestamped authoritative
  record cannot answer the funnel question.

Define the join between a presentation and a committed answer in the contract. The current
`session_id` is scoped to an SPA load and changes on reload. `practice_session_id` identifies the
practice run. Neither identifies a screen visit or a repeated item exposure. Keep the initial
measurement bounded to a single authenticated app instance and define what happens on reload,
backgrounding, and account changes. Use authenticated student identity for cohort return.

Pilot interaction counting only on comparable authored choice items where it can inform a design
change. Count deliberate UI actions from usable presentation to commit, including explicit
submission when applicable. Define keyboard, touch, and pointer treatment and separate audio
playback controls and musical input. Keep this optional usage data outside grading and learning
evidence. Compare only instrumented item types and show the measured share. Extend collection to
uncommitted attempts only when an exit can be observed reliably and the data changes a decision.

### 3. Make the weekly view useful for prioritization

For each actionable rate, show the count, denominator, cohort, observation window, data coverage,
and comparison period. Report median and a tail percentile for latency only when volume supports
it. Use event occurrence time for behavior and ingestion time for lag and completeness checks.
Deduplicate retries by event ID, allow a reporting grace window, and revise recent periods when
late data changes outcomes. Keep ambiguous joins, open visits, and missing observations visible.
The current web emitter retries briefly and can lose pending events on close. An offline delivery
guarantee needs its own contract and verification.

Use the following interpretation in weekly review:

| Pattern | Decision it informs |
| --- | --- |
| Many eligible students stall before the first usable item, while students who reach it finish | Prioritize the entry or setup step with the largest observed loss. |
| Render or media failures cluster by surface or exercise | Prioritize the affected reliability or compatibility fix. |
| Comparable exposures produce many wrong answers with little technical failure | Inspect the prompt, answer options and prerequisite material before revising content. |
| Early exits cluster at a plan position, pick reason, or session duration | Inspect composition and session pacing. Compare similar cohorts and modalities. |
| A flow is slow or interaction-heavy, but completion and return are stable | Estimate affected students and compare against higher-impact work before prioritizing it. |

For a priority decision, record the affected students, severity, confidence in the measurement,
and a candidate change with a metric to check afterward. Use aggregate drill-down and small
samples of sessions to investigate. Report small cohorts with counts and avoid causal claims
from observational comparisons. Validate with scripted journeys including retries, skipped items,
opt-out, and reloads, then reconcile a sample of real observations against source records.
Success means the team can answer the weekly questions and document a priority decision from the
saved reports and MOT-8 without custom SQL.

### 4. Give each tool a distinct job

- **PostHog** provides saved activation funnels, paths, retention cohorts, and breakdowns for the
  weekly product review. Feed it an allowlisted projection of milestones and derived outcomes from
  MotifPath's first-party pipeline. Use a vendor-specific pseudonymous identifier where a
  student-level join is necessary. Exclude raw answers and student profile data. Disable
  autocapture and session replay for this integration.
- **Hotjar** supports time-boxed investigations on approved web screens when a funnel shows where
  students stall and the team needs to see the interaction. Use scoped recordings, heatmaps or
  feedback as appropriate. Begin with signed-in onboarding or navigation screens approved for the
  pilot. Exclude authentication forms, account and payment screens, and exercise answer surfaces.
  Verify suppression and collection boundaries before recording real sessions. Use Hotjar findings
  alongside the quantitative reports in the weekly review.

First validate PostHog with synthetic journeys for first usable item and practice abandonment.
Reconcile the saved reports against source events and verify breakdowns by surface and exercise
type. Test Hotjar independently with synthetic web sessions to verify route eligibility,
suppression, and recording behavior. Approve each integration separately before real student data
is collected or transferred. The follow-up spec must define each vendor's data allowlist,
environments, access, preference enforcement, retention, deletion, and disable control.

### 5. Keep usage data separate from learning obligations

Keep usage observations separately identifiable and enforce an independently testable collection,
access, retention, and deletion policy. Reuse the ingestion boundary while choosing the storage
and routing in the follow-up spec. Learning folds must remain independent of optional usage
events. If an optional usage field travels on a domain event, its retention and deletion must be
enforced independently. Prefer separable usage records where mixed retention would make that hard.

Before rollout, approve the legal basis, default and preference behavior, notice, retention, and
processor and region inventory. ADR-062 documents AWS resources in Ohio and use of Atlas. The
original assumption that first-party analytics avoids international transfers cannot be used as
approval evidence. The original 12-month raw-data period is a proposal to evaluate against the
cohort windows, access needs and deletion obligations.

Specify authenticated preference enforcement for new and queued usage data, including opt-out and
account switches. Preserve learning activity when usage collection is disabled. Exclude URLs,
query terms, free text, raw IPs, user agents, and coordinates from the usage payload. Restrict
identifiable drill-down to authorized administrators and show usage coverage next to opt-in or
opt-out affected rates. Define deletion across raw data, derived views and applicable copies before
enabling collection.

## Rationale

- **Existing domain data first.** It answers several prioritization questions at lower
  instrumentation cost and preserves established practice and path semantics. It cannot show
  pre-answer friction or provide reliable denominators for screen and item exposure.
- **Bounded first-party instrumentation.** Authenticated milestones can be joined to learning
  outcomes with a controlled schema. The team owns the reports, validation and retention.
- **PostHog for exploration.** Saved funnels and retention reports let the team change segments
  and compare cohorts without building a bespoke reporting interface for every question.
- **Hotjar for focused investigation.** Recordings and feedback provide context for specific web
  interaction problems. Treat those observations as qualitative evidence alongside funnel counts.
- **Custom reporting only.** This would centralize presentation in MOT-8 and require MotifPath to
  build and maintain exploratory funnels, paths, and cohort reports.
- **Aggregate page-view tools.** Page counts can show traffic distribution. They cannot answer
  whether a particular practice attempt followed an eligible exposure.

## Consequences

- The weekly review combines MOT-8 learning metrics, PostHog reports, and Hotjar findings from
  scoped investigations. Two vendor integrations add access, privacy, and lifecycle work.
- App, visit, practice session, item attempt and evidence identities need separate definitions.
  Correlation coverage will vary by client version, surface and usage preference.
- New events add ingestion, storage and maintenance cost. Bound the event allowlist and validate
  volume before rollout.
- The next spec must define cohort rules, eligible milestones, joins, missingness, privacy and
  admin access, with Gherkin cases before implementation.

## Related ADRs and contracts

- ADR-006, ADR-008, ADR-011, ADR-012 and ADR-014 cover the event pipeline, storage, aggregation,
  idempotency and identity.
- ADR-046, ADR-049, ADR-051, ADR-052 and ADR-057 cover practice evidence, friction, streaks,
  starting points and the current drill model.
- ADR-061, ADR-062, ADR-063 and ADR-066 cover timed practice, hosting, native shells and
  asynchronous practice summary reads.
- Current contracts reviewed include `openapi/components/schemas/events.yaml`,
  `openapi/components/schemas/practice.yaml`, and
  `features/core-domain/alpha-observation.feature`.
