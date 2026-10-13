# ADR-056: First-Party Product Analytics Through Our Own Event Pipeline

**Status:** Proposed
**Date:** 2026-10-12
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-30 (PB-73). Related: MOT-8 (alpha observation view).

---

## Context

Our domain events (`lesson.*`, `exercise.*`, `practice.*`, `song_chart.*`) record what a student
learned and practised. They do not record how the student moved through the app: when they opened
it, which screens they visited, what they opened and left, or how many taps an item took. ADR-049
§10 needs those numbers for its friction baseline ("taps per item, time from opening the app to the
first item, and the share of sessions left early or abandoned"). Retention is the platform's job
(platform-first premise), so the alpha must find the steps that make students leave before day 90.

MOT-30 asks for the questions first and a tool second. These are the questions the alpha must
answer, and what the current events already cover:

| # | Question | Covered today? |
|---|---|---|
| Q1 | What share of practice sessions are left early or abandoned? (ADR-049 §10) | Yes: `practice.session_ended` and the abandonment rule (ADR-046) |
| Q2 | Do students reach ≥3 practice sessions a week? (PB-8 metric) | Yes, through MOT-8 |
| Q3 | What share of first-path concept nodes is completed? (PB-8 metric) | Yes, through MOT-8 |
| Q4 | Do students come back at day 7, 30 and 90, and after a broken streak? (ADR-051) | Yes: active days come from any event |
| Q5 | How long from opening the app to the first item? (ADR-049 §10) | No: there is no app-open event |
| Q6 | How many taps does an item take? (ADR-049 §10) | No: `tap_ms` measures answer speed, not taps |
| Q7 | Where do students drop between sign-up, starting point and first lesson or practice? | Partly: the first `lesson.started` is known, the steps before it are not |
| Q8 | Which screens are opened and left with nothing done (Discover, a song chart, a lesson)? | Partly: song charts have `opened`/`completed`; other screens have nothing |
| Q9 | Phone, tablet or desktop? Installed PWA or browser tab? (ADR-049 §9, MOT-91) | No |

Four questions are answered already; five need data we do not collect. The gaps are small and
specific. The data concerns identified people, so it falls under the LGPD: we need a legal basis,
a way to opt out, and a retention limit.

Constraints: one engineer; one EC2 VM for staging and production at about $45–65 a month
(ADR-039); an event pipeline that already exists (ingestion → MongoDB + Kafka → worker; ADR-006,
ADR-008, ADR-011). We considered four options: our own usage events in that pipeline; PostHog
Cloud; self-hosted PostHog; and a cookieless page-view tool (Plausible or Umami).

## Decision

**MotifPath will collect product analytics as first-party usage events in its own event pipeline,
limited to questions Q5–Q9 above.** No third-party analytics SDK is added. A usage event is
collected only if it answers a listed question; a new question needs a change to this ADR's list
first.

1. **New event types** in the existing `TrackingEventBase` envelope (same `student_id`,
   `session_id`, `occurred_at`, idempotent `event_id`):
   - `app.opened`: sent once per browser session (`session_id`), when the signed-in app first
     renders. Carries `window_class` (`compact` | `medium` | `expanded`, the ADR-049 size classes,
     taken at open) and `display_mode` (`browser` | `standalone`). This answers Q5 (paired with
     the first item event in the same `session_id`) and Q9.
   - `app.screen_viewed`: sent on each route change. Carries `screen` (the route name, for
     example `discover`, `song-chart`, `lesson`; never the URL, query or free text) and an optional
     `subject_id` (the course, path, node or chart the screen shows). This answers Q7 and Q8: a
     screen counts as "left with nothing done" when no domain event follows it before the next
     `app.screen_viewed`.
   - `screen` is a string with a pattern (`^[a-z][a-z0-9-]{0,63}$`), not an enum, so a new route
     does not need a spec change.
2. **Taps per item (Q6)** is a new optional `taps` integer on `practice.item_answered`: the number
   of pointer-downs inside the Practice Shell from the moment the item is shown until the answer is
   committed (ADR-049 commit rules), including the committing tap.
3. **The funnel starts at sign-in (Q7).** Events need an authenticated `student_id`, so nothing is
   collected before sign-up. Landing visits are counted only in aggregate from the web server's
   access log, never linked to a person. Sign-ups come from Clerk.
4. **The pipeline is unchanged.** Ingestion validates and stores `app.*` events like any other and
   publishes them to the same topic (ADR-006). The Aggregation Worker ignores them, as it already
   ignores event types it has no rule for. `taps` does not change grading or evidence (ADR-046).
5. **Privacy (LGPD):**
   - *Legal basis:* legitimate interest (improving the service the student uses), stated in the
     privacy notice. Domain events stay under contract performance, since the product needs them.
   - *Opt-out:* a "Share usage data" setting, on by default. When it is off, the client sends no
     `app.*` events and leaves out `taps`. Domain events are not affected.
   - *Minimisation:* no IP address, user-agent string, URL, coordinates or free text in usage
     events. Device information is reduced to `window_class` and `display_mode`.
   - *Retention:* `app.*` events are deleted 12 months after `occurred_at` (a TTL index in
     MongoDB); weekly aggregates without identities may be kept. Deleting an account deletes them
     along with the student's other events.
6. **Answers are read in MOT-8.** The alpha observation view shows Q1–Q9 weekly, so the team
   needs no custom SQL (MOT-30's success metric). Building those views is MOT-8's scope; this ADR
   only provides the data.

## Rationale

- **The gaps are five narrow questions, not a general need for analytics.** Two event types and one
  field close them. A full analytics product mostly adds what we said we would not do: "tracking
  everything with no question in mind" (MOT-30 business risk).
- **The answers come from joining usage with learning.** Q5 pairs `app.opened` with the first
  item; Q8 asks whether a domain event followed a screen. In our own store this is a query on one
  collection keyed by `student_id` and `session_id`. With an external tool we would have to send
  learning events there too, or join two systems.
- **No personal data leaves our infrastructure.** This keeps the LGPD position simple: no
  international transfer, no processor agreement, no consent banner for a third-party SDK, and one
  place to delete data from.
- **It fits the budget and the stack.** It uses the ingestion service, envelope, idempotency rules
  and offline outbox (ADR-049 §9, ADR-012) we already have, at no extra cost.

Rejected alternatives:

- **PostHog Cloud.** It has ready-made funnels, retention charts and session replay, so it would
  meet the "no custom SQL" metric with no view work. It was rejected for now because it sends
  student behaviour to a third party outside Brazil (international transfer, processor agreement,
  consent banner), adds an SDK to a PWA that must work offline, and duplicates learning events we
  would need for the joins. **Revisit** if the MOT-8 views become a maintenance burden, or if a
  question needs session replay or heatmaps.
- **Self-hosted PostHog.** It keeps the data in-house, but its stack (ClickHouse, Kafka, PostgreSQL,
  Redis) needs much more memory than the single ADR-039 VM has. That means a second machine and a
  second system to run, for one engineer.
- **Plausible or Umami (cookieless page views).** They are cheap and need no consent, but they are
  anonymous by design. They can count screens, but they cannot answer Q5–Q8, which need to tie a
  screen to the same student's next learning event.
- **Domain events only.** No new data and no privacy work, but it leaves the ADR-049 baseline
  (Q5, Q6) and the funnel (Q7, Q8) without numbers, so the redesign could not be compared before
  and after.

## Consequences

### Positive

- The ADR-049 friction baseline and the first-run funnel become measurable with no new vendor or
  cost.
- Usage and learning data sit in one store and can be joined by `student_id` and `session_id`.
- Personal data stays on our infrastructure. Opt-out, retention and deletion are each implemented
  in one place.
- The question list keeps collection bounded: every event type has a named question.

### Negative / Trade-offs

- We build and maintain the charts ourselves (in MOT-8). There are no ready-made funnels, cohorts,
  session replay or heatmaps.
- Before sign-up we see only aggregate access-log counts, so we cannot follow one visitor from
  the landing page to sign-up.
- Usage events from a student who opted out are missing. Q5–Q9 then describe only the students who
  share data, and the share of students who opt out has to be reported next to them.
- `app.screen_viewed` is the most frequent event. It increases ingestion traffic and MongoDB size
  (bounded by the 12-month TTL).
- Legitimate interest with opt-out is our reading of the LGPD, not legal advice. It should be
  checked with someone qualified before production (PB-8a).

### Neutral

- `TrackingEventBase` gains `app.opened` and `app.screen_viewed` in its closed `event_type` enum
  (with the matching schemas); `practice.item_answered` gains optional `taps`.
- The privacy notice and the settings page gain a "Share usage data" entry.
- ADR-003 observability (traces, logs, metrics) stays separate. It is about the system's health,
  not how students use the app.

## Related ADRs

- ADR-003: Observability stack — operational telemetry, deliberately separate from product analytics.
- ADR-006 / ADR-008 / ADR-011: Kafka topology, MongoDB event storage, aggregation worker — the
  pipeline the usage events reuse; the worker ignores them.
- ADR-012: Idempotency — usage events keep the `event_id` contract.
- ADR-039: Single-VM hosting — the budget that rules out self-hosted PostHog.
- ADR-046: Evidence-based practice — source of Q1; `taps` does not affect evidence.
- ADR-049: Practice-first experience language — §10 baseline (Q5, Q6), §9 offline outbox, size
  classes used by `window_class`.
- ADR-051: Home minutes and day streak — the streak-return question in Q4.

---

*This ADR was proposed on 2026-10-12. To revise, create a new ADR with Status: Supersedes ADR-056.*
