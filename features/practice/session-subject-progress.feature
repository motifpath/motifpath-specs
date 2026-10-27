@wip
Feature: Show how a session moved the student on each of its subjects
  As a student
  I want the session summary to show my level change on the rung I practised, and the next rung once I reach it
  So that I see I moved forward and know what comes next

  # Rules (ADR-066, MOT-163 D32): the plan names each subject's current rung and the student's
  # level on it when composed (the before). After the session, the summary reads each subject's
  # rung levels again (the after), but only once the session is caught up: the Aggregation Worker
  # has recorded its practice.session_ended. A student's events are folded in order, and an answer
  # is folded before it is recorded, so every answer sent before the end is in the levels by then.
  # A rung's level is rolled up like a node's: the highest level at least 80% of the subtree's
  # items at that rung that suit the session reach.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And "diatonic-chords" has items at the know, hear and play_clean rungs on guitar

  # ── The before, in the plan ────────────────────────────────────────────────

  Scenario: The plan names each subject's current rung and the student's level on it
    Given "alice" is learning every know item of "diatonic-chords" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "diatonic-chords"
    Then the plan's focus node "diatonic-chords" is at the know rung, at level learning

  Scenario: A subject new to the student is at its first rung, at level new
    Given "alice" has never practised "diatonic-chords"
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "diatonic-chords"
    Then the plan's focus node "diatonic-chords" is at the know rung, at level new

  Scenario: A subject accurate on its first rung is at the next one
    Given "alice" is accurate on every know item of "diatonic-chords" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "diatonic-chords"
    Then the plan's focus node "diatonic-chords" is at the hear rung, at level new

  # ── The after, once caught up ──────────────────────────────────────────────

  Scenario: Once the session's end is recorded, the subject's rungs show the session's answers
    Given "alice" is learning every know item of "diatonic-chords" on guitar
    And "alice" practised session "s1" with "guitar" in hand, and became accurate on every know item of "diatonic-chords"
    And the session "s1"'s end is recorded
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for "diatonic-chords"
    Then the session is caught up
    And "diatonic-chords" is accurate at the know rung and new at the hear and play_clean rungs
    And "diatonic-chords"'s current rung is hear

  Scenario: Before the session's end is recorded, it is not caught up
    Given "alice" practised session "s1" with "guitar" in hand, and its end has not been recorded yet
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for "diatonic-chords"
    Then the session is not caught up
    And "diatonic-chords" still shows its rungs and current rung as they are now

  Scenario: The subjects come back in the order asked
    Given "find-notes-root-strings" has items at the know rung on guitar
    And the session "s1" of "alice" with "guitar" in hand has its end recorded
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for "find-notes-root-strings" and "diatonic-chords"
    Then the subjects are "find-notes-root-strings" then "diatonic-chords"

  Scenario: In the head, a rung's level is the best of the student's instruments
    Given "find-notes-root-strings" is practised only by fretboard cells, recalled in the head
    And "alice" is accurate on every know item of "find-notes-root-strings" on guitar, and learning on electric-bass
    And the session "s1" of "alice" with no instrument in hand has its end recorded
    When "alice" reads the subject progress of session "s1" with no instrument in hand, for "find-notes-root-strings"
    Then "find-notes-root-strings" is accurate at the know rung

  Scenario: Reading the progress changes nothing
    Given the session "s1" of "alice" with "guitar" in hand has its end recorded
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for "diatonic-chords" twice
    Then both reads are the same

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Another student's session is never caught up
    Given student "bob" plays "guitar"
    And the session "s1" of "bob" with "guitar" in hand has its end recorded
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for "diatonic-chords"
    Then the session is not caught up

  Scenario: A session nobody started is never caught up
    When "alice" reads the subject progress of a session never started, with "guitar" in hand, for "diatonic-chords"
    Then the session is not caught up

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A read with no subject is rejected
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for no node
    Then the request is refused with a validation error

  Scenario: A read with more than three subjects is rejected
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for four nodes
    Then the request is refused with a validation error

  Scenario: A subject that doesn't exist is not found
    When "alice" reads the subject progress of session "s1" with "guitar" in hand, for a node that doesn't exist
    Then the request is refused with a not-found error

  # ── The summary line ───────────────────────────────────────────────────────

  @web
  Scenario: A subject that reached its rung names the next one
    Given the plan had "Diatonic chords" at the know rung, at level learning
    And the progress is caught up, with "Diatonic chords" accurate at the know rung and its current rung hear
    When the session summary is shown
    Then the result of "Diatonic chords" reads "Know it: Learning → Accurate · next: Hear it"

  @web
  Scenario: A subject that moved without reaching its rung names no next rung
    Given the plan had "Hear progressions" at the hear rung, at level new
    And the progress is caught up, with "Hear progressions" learning at the hear rung
    When the session summary is shown
    Then the result of "Hear progressions" reads "Hear it: New → Learning"

  @web
  Scenario: A subject whose level didn't change is steady
    Given the plan had "Find notes on the root strings" at the know rung, at level accurate
    And the progress is caught up, with "Find notes on the root strings" accurate at the know rung
    When the session summary is shown
    Then the result of "Find notes on the root strings" reads "Know it: Accurate · steady"

  @web
  Scenario: A subject that reached its top rung names no next rung
    Given the plan had "Find notes on the root strings" at the know rung, at level learning, its only rung
    And the progress is caught up, with "Find notes on the root strings" accurate at the know rung
    When the session summary is shown
    Then the result of "Find notes on the root strings" reads "Know it: Learning → Accurate"

  @web
  Scenario: While the session catches up, the score shows and the level change waits
    Given the progress is not caught up yet
    When the session summary is shown
    Then each subject shows its score
    And its level change is still to come

  @web
  Scenario: A session that doesn't catch up within 5 seconds keeps the rungs practised
    Given the progress is still not caught up after 5 seconds
    When the session summary is shown
    Then each subject shows its score and the rungs it practised, with no level change
