@wip
Feature: Keep a record of practice sessions and learning activity
  As the MotifPath platform
  I want every practice session's start, answers and end, and every completed content node, kept with its time
  So that practice days and learning days can be counted now, and other measures such as a streak can be evaluated later

  # A session is finished when practice.session_ended says it wasn't left early. A session
  # with no practice.session_ended is abandoned once no practice.* event for it has arrived
  # for its planned minutes + 15; it ended early, at its last event. Abandonment is decided
  # when the record is read, never written, so a late event can reopen the session.

  Background:
    Given student "alice" is authenticated with a valid session

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A session ended without leaving early is finished
    Given "alice" started a 10-minute practice session at 18:00
    When "alice"'s practice.session_ended for it arrives at 18:11, not left early, with 6 items answered
    Then the session is finished at 18:11 with 6 items answered

  Scenario: A completed content node is kept with when it was completed
    When "alice"'s lesson.completed for the content node "intro-to-chords" arrives, completed at 19:30
    Then "alice"'s learning activity shows "intro-to-chords" completed at 19:30

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A session the student left early is not finished
    Given "alice" started a 10-minute practice session at 18:00
    When "alice"'s practice.session_ended for it arrives at 18:04, left early, with 2 items answered
    Then the session ended early at 18:04

  Scenario: A session silent for its planned minutes plus 15 is abandoned
    Given "alice" started a 10-minute practice session at 18:00
    And "alice"'s last practice.item_answered for it arrived at 18:03
    When the session is read at 18:19
    Then the session is abandoned, ended early at 18:03

  Scenario: A session still within its planned minutes plus 15 is in progress
    Given "alice" started a 10-minute practice session at 18:00
    And "alice"'s last practice.item_answered for it arrived at 18:03
    When the session is read at 18:17
    Then the session is in progress

  Scenario: A late event reopens an abandoned session
    Given "alice"'s 10-minute session started at 18:00 was abandoned after its last answer at 18:03
    When "alice"'s practice.item_answered for it arrives at 18:30 and practice.session_ended arrives at 18:35, not left early
    Then the session is finished at 18:35

  Scenario: Answers outside a practice session belong to no session
    When "alice" answers a challenge exercise of the content node "open-chords"
    Then no practice session gains an answer

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: The same practice.session_ended delivered twice counts once
    Given "alice" started a 10-minute practice session at 18:00
    When "alice"'s practice.session_ended for it arrives twice
    Then the session is finished once, with its first delivery's end

  Scenario: The same lesson.completed delivered twice is kept once
    When "alice"'s lesson.completed for "intro-to-chords" arrives twice
    Then "alice"'s learning activity shows "intro-to-chords" completed once

