# MOT-30 synthetic pilot

[ADR-056](../../adrs/ADR-056-first-party-product-analytics.md) assigns PostHog to weekly product
analytics and Hotjar to targeted web UX research. This pilot uses fabricated students and content
in isolated vendor projects. Approval of the pilot establishes reporting and capture behavior for
the fixture. Each vendor needs separate approval before any student activity can be sent.

## PostHog

Create two saved reports. Keep autocapture and replay disabled. Use a pilot-only pseudonymous
student key and a stable event key. Include event occurrence time, app visit key and app surface
on activation records. Include a practice run key, outcome and exercise kind where the fixture
supports the breakdown. Send only these fields and the event name. Use synthetic keys throughout.

1. **First usable item.** Count distinct eligible students with an app-ready event as the
   denominator. Count a student in the numerator if a usable item appears after app ready
   within the same visit. Report by surface and show the denominator beside the conversion rate.
2. **Practice outcomes.** Count each started run once in its latest state at the report cutoff.
   Show finished, explicit early exit, inferred abandonment and open separately. The source
   classifies missing ends after planned minutes plus 15 minutes without arriving practice
   activity. A late event can reopen a run. Report open runs separately from the early-exit and
   abandonment rates. Compare like exercise kinds and leave missing kinds visible.

Use the following fixture with a fixed cutoff and include a duplicate delivery of A's item event.
For C, send the item milestone under a different visit key from its eligible app-ready event.

| Synthetic student | Surface | App ready | First usable item |
| --- | --- | --- | --- |
| A | Browser | Visit A1 | Visit A1 |
| B | Native iOS | Visit B1 | Visit B1 |
| C | Browser | Visit C1 | Visit C2 |

Expected activation is 2 of 3 overall, 1 of 2 for browser and 1 of 1 for native iOS.
Add four started runs with one outcome each. Expect four starts and one in each state. Add a late
practice event to the inferred abandonment and repeat the report with a cutoff inside the new
grace period. Expect zero inferred abandoned and two open. Save both report configurations and
record the source totals alongside screenshots of the results.

## Hotjar

Use an approved synthetic signed-in onboarding screen and a test investigation window. Disable
capture by default. Start capture only inside that window and on an allowed route. Verify in the
SPA that navigating from onboarding to an exercise answer screen ends eligible capture, including
any continuing recording from the previous route. Exercise, authentication, account and payment
routes remain outside the pilot. Use a synthetic sentinel string to verify masking in the
recording and captured payload. Test direct entry to an excluded route, navigation into and out of
an allowed route, and expiry of the investigation window. Save the results without real student
identifiers.

## Exit criteria

The product owner can reproduce both saved reports without custom SQL and identify the first
onboarding step to investigate using the synthetic activation result. Hotjar captures only the
approved route and never exposes the sentinel. Verify that vendor failures cannot prevent
learning activity from being recorded. Report mismatches as pilot failures with reproduction
steps.

Before live rollout, the implementation contracts must specify the production event allowlist,
delivery and retry rules, preference enforcement, vendor access, retention, deletion and an
independent disable control for each integration. The pilot does not set the live collection
default or retention period.

## Running the fixture

From this directory, run `node --test posthog-fixture.test.mjs` and
`node posthog-fixture.mjs > /tmp/mot30-posthog-fixture.json`. The generator prints synthetic
data and makes no network requests. It adds a fixture batch key for isolation and reuses the
event UUID for the intentional retry. Submit the `events` array to the isolated project's
[batch capture endpoint](https://posthog.com/docs/getting-started/install) using its project token.
Filter both reports by the generated batch key. Require the same `visit_key` across funnel
steps. Filter the practice report by one `snapshot` at a time and count distinct run keys.
The fixture tests the presentation of source-derived outcome snapshots. It does not exercise the
source abandonment calculation or vendor ingestion.

For Hotjar, use an isolated site and two synthetic SPA routes. Add the sentinel to a masked
element on onboarding and another sentinel to the excluded exercise route. In a fresh session,
check approved entry, excluded navigation, re-entry, direct excluded entry and window expiry.
Review the browser capture requests and resulting recording for both sentinels. Record the
project, route, expected behavior and observed behavior for each check.
