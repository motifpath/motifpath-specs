Feature: Derive a student's knowledge of an item from evidence
  As the MotifPath platform
  I want each item's level and review schedule derived from the student's evidence alone
  So that progress can be explained, recomputed when a rule improves, and never drifts

  # Rules: counted evidence becomes a hit, a miss or a hold. Sources weigh auto-graded 0.3,
  # self-assessed 0.3, teacher-reviewed 0.6. Leitner boxes wait 1, 2, 4, 8, 16, 32 days.
  # accurate = 3+ counted attempts and accuracy >= 0.8; fluent = 5+ attempts, accuracy >= 0.9
  # and fluency >= 0.8; retained = fluent in box 5 or higher. A wrong note picked among k
  # choices counts -1/(k-1) toward accuracy (amended 2026-10-08).

  Background:
    Given student "alice" practises the guitar fretboard cell on string 5 at fret 3
    And the fluent time for naming a note is 2000 milliseconds net of tap time

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: An item never practised is new
    Then "alice"'s level for the cell is "new"

  Scenario: Three right answers make an item accurate
    When "alice" answers the cell correctly 3 times on 3 different days
    Then "alice"'s level for the cell is "accurate"

  Scenario: Five right answers within the fluent time make an item fluent
    Given "alice"'s tap time is 300 milliseconds
    When "alice" answers the cell correctly 5 times, each in 1900 milliseconds
    Then "alice"'s level for the cell is "fluent"

  Scenario: A fluent item that holds up in long reviews is retained
    Given "alice" is fluent on the cell and the cell is in box 4
    When "alice" answers the cell correctly when it falls due
    Then the cell moves to box 5
    And "alice"'s level for the cell is "retained"

  # ── Spaced repetition ──────────────────────────────────────────────────────

  Scenario: A right answer on a due item moves it up one box
    Given the cell is in box 2 and due today
    When "alice" answers the cell correctly
    Then the cell moves to box 3 and is next due in 4 days

  Scenario: A right answer before the item is due doesn't move it
    Given the cell is in box 2 and due in 1 day
    When "alice" answers the cell correctly
    Then the cell stays in box 2

  Scenario: A wrong answer sends the item back to box 1
    Given the cell is in box 4
    When "alice" answers the cell wrongly
    Then the cell moves to box 1 and is next due in 1 day

  # ── Guessing among choices ─────────────────────────────────────────────────
  # A wrong pick among k recorded choices counts -1/(k-1) toward accuracy instead of 0, so
  # guessing among four averages 0. Accuracy is floored at 0. Name the note only, for now.

  @wip
  Scenario: Six right picks of seven among four note choices make a cell accurate
    When "alice" names the cell among four choices, right 6 times and wrong once
    Then "alice"'s accuracy on the cell is 0.81
    And "alice"'s level for the cell is "accurate"

  @wip
  Scenario: Four right picks of five among four note choices are not yet accurate
    When "alice" names the cell among four choices, right 4 times and wrong once
    Then "alice"'s accuracy on the cell is 0.73
    And "alice"'s level for the cell is "learning"

  @wip
  Scenario: Picking no better than chance among four note choices reads as no accuracy
    When "alice" names the cell among four choices, right once and wrong 5 times
    Then "alice"'s accuracy on the cell is 0
    And "alice"'s level for the cell is "learning"

  @wip
  Scenario: A wrong tap finding the note counts as a plain miss
    When "alice" finds the cell's note, right 4 times and wrong once
    Then "alice"'s accuracy on the cell is 0.8
    And "alice"'s level for the cell is "accurate"

  @wip
  Scenario: A note named on the twelve-note keypad counts as a plain miss
    When "alice" names the cell on the twelve-note keypad, right 4 times and wrong once
    Then "alice"'s accuracy on the cell is 0.8
    And "alice"'s level for the cell is "accurate"

  @wip
  Scenario: A wrong pick among four note choices still sends the cell back to box 1
    Given the cell is in box 3
    When "alice" names the cell among four choices wrongly
    Then the cell moves to box 1 and is next due in 1 day

  # ── Self-rated and teacher-reviewed takes ──────────────────────────────────

  Scenario: A self-rating of almost changes nothing
    Given "alice" practises the play-along "pentatonic-run" and it is in box 2
    When "alice" rates a take of "pentatonic-run" as "almost" at 90 BPM
    Then "pentatonic-run" stays in box 2

  Scenario: A take that isn't clean above the best clean tempo doesn't count against the student
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "struggled" at 115 BPM
    Then the take is not counted as a miss

  Scenario: A take that isn't clean at or below the best clean tempo is a real miss
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "struggled" at 100 BPM
    Then the take is counted as a miss

  # Parked until ADR-046 follow-up slice 5 (teacher notes): no teacher review exists yet.
  @wip
  Scenario: A teacher review resets the student's own best clean tempo
    Given "alice" rated "pentatonic-run" clean at 120 BPM
    When a teacher reviews "alice"'s "pentatonic-run" as clean at 100 BPM and verified
    Then "alice"'s best clean tempo on "pentatonic-run" is 100 BPM
    And "pentatonic-run" is verified for "alice"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The same answer delivered twice counts once
    When the same practice.item_answered event for the cell arrives twice
    Then "alice" has one piece of evidence for the cell

  Scenario: An answer that arrives late is placed in time order
    Given "alice" answered the cell correctly on Monday and Wednesday
    When "alice"'s wrong answer from Tuesday arrives after Wednesday's
    Then "alice"'s state for the cell is the same as if the three answers had arrived in order

  Scenario: A timed answer is judged by the fluent time in force when it was given
    Given "alice" answered the cell correctly in 2200 milliseconds when the fluent time was 2500 milliseconds
    When the fluent time for naming a note changes to 1800 milliseconds
    Then that answer still counts as within the fluent time

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A rejected answer leaves the item's state unchanged
    Given "alice" is accurate on the cell
    When "alice" sends an answer to the cell that the grader rejects
    Then "alice"'s level for the cell is still "accurate"
    And "alice" has no new evidence for the cell

  Scenario: A felt rating never counts toward mastery
    Given "alice" is accurate on the cell
    When "alice" says naming notes felt "easy" at the end of a session
    Then "alice"'s level for the cell is still "accurate"
