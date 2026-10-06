Feature: Ask for a tap check before fretboard drills
  As a student
  I want my answer times judged on what I know, not on how fast I tap
  So that "fluent" means the same for me as for everyone else

  # A tap check is about 20 seconds of tapping a highlighted fret as soon as it lights up. Its
  # median becomes the student's tap time, taken off every later timed answer. A plan asks for
  # one when it has a fretboard cell and the student has done none in the last 30 days, or never.

  Background:
    Given student "alice" plays "guitar"
    And "alice" is enrolled in a path with the skill "find-notes-root-strings"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A first session with fretboard cells asks for a tap check
    Given "alice" has never done a tap check
    When "alice" composes a 5-minute session with no instrument in hand
    Then the plan asks for a tap check

  @web
  Scenario: A completed tap check is sent with its median and its number of taps
    Given "alice"'s plan asks for a tap check
    When "alice" taps 24 highlighted frets with a median of 320 milliseconds
    Then practice.tap_check_completed is sent with a median tap time of 320 milliseconds over 24 taps

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A tap check within the last 30 days isn't asked for again
    Given "alice" did a tap check 12 days ago
    When "alice" composes a 5-minute session with no instrument in hand
    Then the plan doesn't ask for a tap check

  Scenario: A tap check older than 30 days is asked for again
    Given "alice" did a tap check 31 days ago
    When "alice" composes a 5-minute session with no instrument in hand
    Then the plan asks for a tap check

  @web
  Scenario: A skipped tap check doesn't hold up the session
    Given "alice"'s plan asks for a tap check
    When "alice" skips it
    Then the session's first item is shown
    And practice.tap_check_completed is not sent

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A session without fretboard cells never asks for a tap check
    Given "alice" has never done a tap check
    And "alice"'s next session will practise only play-alongs and exercises
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the plan doesn't ask for a tap check
