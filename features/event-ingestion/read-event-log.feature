# Reading the event log (MOT-8, PB-8h).
#
# The alpha observation (features/core-domain/alpha-observation.feature) shows numbers; this read
# shows the raw events behind them, exactly as they were received, so an admin can check a number
# or see what a student actually did. It changes nothing. Design: the "Authoring" Figma page,
# row 19c (decision D7, approved 2026-10-14).
#
# Type groups, as the admin filters them:
# - practice_sessions: practice.session_started, practice.session_ended
# - answers: practice.item_answered, practice.tap_check_completed
# - lessons: lesson.started, lesson.resumed, lesson.completed
# - exercises: exercise.started, exercise.progress, exercise.ended
# - song_charts: song_chart.opened, song_chart.chord_viewed,
#   song_chart.completed

Feature: Read the event log
  As an admin running the alpha
  I want to read the tracking events exactly as they were received
  So that I can check what the alpha's numbers are made of

  Background:
    Given the Event Ingestion Service is operational and ready to accept events
    And the event log holds 30 events of student "alice" and 10 of student "bruno"

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: An administrator reads the newest events first
    Given the caller is authenticated and the platform recognises them as an administrator
    When the caller reads the event log, 12 at a time
    Then the 12 most recently received events are returned, newest first
    And the total is 40

  @wip
  Scenario: Each event is returned as it was received, with when it was received
    Given the caller is authenticated and the platform recognises them as an administrator
    And "alice"'s practice.session_ended event "evt-end-001", not left early with 9 items answered, was received at 07:51:12
    When the caller reads the event log
    Then event "evt-end-001" is returned with its event type, student, occurred_at and every field it was submitted with
    And it shows it was received at 07:51:12

  @wip
  Scenario: The next page continues where the last one ended
    Given the caller is authenticated and the platform recognises them as an administrator
    When the caller reads the event log, 12 at a time, from the 13th event
    Then the 13th to 24th most recently received events are returned

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: Filtering by student returns only that student's events
    Given the caller is authenticated and the platform recognises them as an administrator
    When the caller reads the event log for student "bruno"
    Then only "bruno"'s events are returned
    And the total is 10

  @wip
  Scenario: Filtering by type group returns only events of those types
    Given the caller is authenticated and the platform recognises them as an administrator
    And "alice" has practice.session_started, practice.item_answered, practice.session_ended and lesson.started events in the log
    When the caller reads the event log for student "alice" in the type group practice_sessions
    Then only "alice"'s practice.session_started and practice.session_ended events are returned

  @wip
  Scenario: Events received at the same moment keep a stable order
    Given the caller is authenticated and the platform recognises them as an administrator
    And events "evt-a" and "evt-b" were received at the same instant
    When the caller reads the event log twice
    Then "evt-a" and "evt-b" are in the same order both times

  @wip
  Scenario: A student with no events returns an empty page
    Given the caller is authenticated and the platform recognises them as an administrator
    When the caller reads the event log for student "carla", who has no events
    Then no events are returned
    And the total is 0

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: A student may not read the event log
    Given the caller is authenticated and the platform recognises them as a student
    When the caller reads the event log
    Then the request is refused for lacking permission

  @wip
  Scenario: Reading is unavailable when the caller's role cannot be established
    Given the caller is authenticated
    And the platform cannot be reached to establish the caller's role
    When the caller reads the event log
    Then the request is refused as temporarily unavailable

  @wip
  Scenario: An unknown type group is rejected
    Given the caller is authenticated and the platform recognises them as an administrator
    When the caller reads the event log in the type group "videos"
    Then the request is rejected as invalid
    And the rejection identifies "type_group" as the source of the error
