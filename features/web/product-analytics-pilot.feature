@wip @web
Feature: Validate product analytics before collecting student usage
  As a product owner
  I want to verify both tools with synthetic journeys
  So that weekly product decisions use trustworthy measurements

  Rule: PostHog reports selected milestones and derived outcomes

    Scenario: Reconcile activation against the source records
      Given 3 synthetic students reach the signed-in app
      And 2 reach the first usable item in the same app visit
      When the product owner opens the saved activation funnel
      Then the funnel shows 2 of 3 students reaching the first usable item
      And the product owner can break down the funnel by app surface without custom SQL

    Scenario: A retry counts once in the activation funnel
      Given a synthetic student's first usable item milestone has been recorded
      When the same milestone is delivered again
      Then the activation funnel counts the student once for that milestone

    Scenario: Practice outcomes distinguish early exit from inferred abandonment
      Given synthetic practice runs include a finished run, an explicit early exit, an inferred abandonment, and an open run
      When the product owner opens the saved practice report
      Then each run is counted only in its own outcome category

    Scenario: A rejected analytics delivery does not interrupt learning
      Given the analytics destination rejects a synthetic milestone
      When the synthetic student commits a practice answer
      Then the practice answer is recorded in the learning pipeline
      And the analytics delivery failure is visible to the pilot operator

  Rule: Hotjar research is limited to approved web screens

    Scenario: A synthetic session records only on an approved screen
      Given a synthetic Hotjar investigation is enabled for a signed-in onboarding screen
      When the synthetic student visits that screen and then an exercise answer screen
      Then only activity on the approved onboarding screen is captured
      And suppressed values cannot be read in the recording

    Scenario: Hotjar capture is disabled outside the investigation window
      Given the approved investigation window has ended
      When a synthetic student visits a previously approved screen
      Then Hotjar does not capture the visit

  Rule: Each vendor requires its own live rollout approval

    Scenario: A synthetic pilot cannot collect real student data
      Given neither vendor has live rollout approval
      When a real student signs in and starts practice
      Then neither vendor receives the student's activity
      And the student's learning events are recorded

    Scenario: One vendor's approval does not enable the other
      Given only PostHog has live rollout approval
      When an eligible student visits a screen selected for UX research
      Then Hotjar does not capture the visit

    Scenario: Usage preference is checked before delivering queued observations
      Given an eligible usage observation is queued for delivery
      When the student disables usage collection before delivery
      Then the observation is not sent to the vendor
      And the student's learning events are recorded
