Feature: Answer a practice item the way it can be graded honestly
  As a student
  I want each item to take my answer in a way that fits what it asks
  So that a lucky guess, a replayed clip or a missing sound never counts as what I know

  # Client behaviour: what the Practice Shell offers, when an answer commits and what it sends.
  # Grading and levels are core's (grade-practice-response, knowledge-state, timed-thresholds).

  Background:
    Given student "alice" plays "guitar" in standard tuning E2 A2 D3 G3 B3 E4
    And "alice" is practising in a session

  # ── Name the note among four choices ───────────────────────────────────────

  @web
  Scenario: Name the note offers the note, a semitone either side and the same fret on the next string
    When "alice" is asked to name the note of the guitar cell on string 5 at fret 3
    Then the choices are "C", "B", "C#" and "F", in random order

  @web
  Scenario: A cell on string 1 takes its string neighbour from string 2
    When "alice" is asked to name the note of the guitar cell on string 1 at fret 3
    Then the choices are "G", "F#", "G#" and "D", in random order

  @web
  Scenario: The answer sends the four choices as shown
    Given "alice" is shown the choices "B", "F", "C" and "C#" for the guitar cell on string 5 at fret 3
    When "alice" taps "C"
    Then the practice.item_answered response names the note "C" with the choices "B", "F", "C" and "C#"

  # ── Fretboard drills in a fret window ──────────────────────────────────────
  # The plan gives each fretboard cell its drill's window: five frets, plus the open string when
  # it starts at the nut. Sizes are CSS pixels; a phone is a 390 px wide viewport.

  @web
  Scenario: On a phone a drill draws only its window and never scrolls sideways
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 5, in the fret window 3 to 7
    When the drill is shown on a phone
    Then the board shows frets 3 to 7 and no other fret
    And the board doesn't scroll sideways

  @web
  Scenario: Every place in a window at the nut is at least 48 px wide, the open string included
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 0, in the fret window 0 to 5
    When the drill is shown on a phone
    Then the open-string place and frets 1 to 5 are each at least 48 px wide
    And the board shows a nut, with the open-string place left of it

  @web
  Scenario: A tap on the open string is answered as the open string, not fret 1
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 0, in the fret window 0 to 5
    When "alice" taps the open-string place on string 6
    Then the practice.item_answered response names string 6, fret 0

  @web
  Scenario: The question names the window
    Given "alice" is asked to find the note "C" on string 5, in the fret window 0 to 5
    When the drill is shown
    Then the question names frets 0 to 5

  @web
  Scenario: On a wider screen the places outside the window are dimmed and can't be tapped
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 8, in the fret window 6 to 10
    When the drill is shown on a 1024 px wide screen
    Then frets 6 to 10 can be tapped
    And the other frets are dimmed and can't be tapped

  @web
  Scenario: Name the note draws its cell in the window too
    Given "alice" is asked to name the note of the guitar cell on string 4 at fret 9, in the fret window 7 to 11
    When the drill is shown on a phone
    Then the board shows frets 7 to 11 with the cell on string 4 at fret 9 marked
    And the board doesn't scroll sideways

  # ── Sound options commit with Check ────────────────────────────────────────

  @web
  Scenario: A sound-choice exercise with one right option waits for Check
    Given an audio_selection exercise with 3 sound options, one of them right
    When "alice" taps the second option
    Then the second option is selected
    And no answer is sent until "alice" taps Check

  @web
  Scenario: Playing a sound option doesn't select it
    Given an audio_selection exercise with 3 sound options, one of them right
    When "alice" taps the play button of the first option
    Then the first option's clip plays
    And no option is selected

  @web
  Scenario: A sound-choice answer's latency runs from the end of the last clip played
    Given an audio_selection exercise with 3 sound options, one of them right
    And the last clip "alice" played ended 8000 milliseconds after the exercise was shown
    When "alice" taps Check 11000 milliseconds after the exercise was shown
    Then the answer is sent with a latency of 3000 milliseconds and no audio length

  @web
  Scenario: Checking while a clip still plays sends a latency of 0
    Given an audio_selection exercise with 3 sound options, one of them right
    And a selected option's clip is still playing
    When "alice" taps Check
    Then the clip stops
    And the answer is sent with a latency of 0 milliseconds and no audio length

  # ── Not answered ───────────────────────────────────────────────────────────

  @web
  Scenario: Options stay locked while the stimulus failed to load
    Given an audio_recognition exercise whose sound failed to load
    When "alice" taps an option
    Then no option is selected
    And the item offers Try again and Skip

  @web
  Scenario: Skipping an item whose sound failed to load sends it as not answered
    Given an audio_recognition exercise whose sound failed to load
    When "alice" taps Skip
    Then a practice.item_answered event is sent with a not_answered response, reason "failed_to_load"
    And the session moves on to the next item

  @web
  Scenario: An item that can't be shown is skipped as unavailable
    Given an exercise whose diagram can't be shown on this device
    When "alice" taps Skip
    Then a practice.item_answered event is sent with a not_answered response, reason "unavailable"

  @web
  Scenario: A not-answered item is left out of the session's answered count
    Given "alice" answered 4 items and skipped 1 that failed to load
    When the session ends
    Then practice.session_ended carries an answered count of 4

  @web
  Scenario: Skip is never offered while the stimulus is there
    Given an audio_recognition exercise whose sound has loaded
    Then the item offers no Skip
