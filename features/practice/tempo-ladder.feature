Feature: Climb the tempo ladder of a play-along
  As a student
  I want each take of a play-along at a tempo that follows how my last takes went
  So that I build speed without being pushed past what I can play cleanly

  # The ladder starts at the plan's start tempo: +5 BPM after two clean takes in a row at a tempo,
  # −5 after a struggle, holding otherwise. By itself it never climbs past the target, nor drops
  # below 60% of it. The student may choose the next take's tempo, past the target too, and the
  # ladder never goes below a tempo the student chose for the item: only the student lowers it.

  Background:
    Given student "alice" plays "guitar"
    And "alice"'s session has the play-along "pentatonic-run" starting at 90 BPM with a target of 120 BPM

  # ── Happy path ─────────────────────────────────────────────────────────────

  @web
  Scenario: Two clean takes in a row at a tempo move the ladder up
    When "alice" rates two takes of "pentatonic-run" at 90 BPM as "clean"
    Then the next take of "pentatonic-run" is at 95 BPM

  @web
  Scenario: A struggle moves the ladder down
    When "alice" rates a take of "pentatonic-run" at 90 BPM as "struggled"
    Then the next take of "pentatonic-run" is at 85 BPM

  @web
  Scenario: A tempo the student chooses is the next take's, past the target too
    When "alice" chooses 180 BPM for the next take of "pentatonic-run"
    Then the next take of "pentatonic-run" is at 180 BPM

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @web
  Scenario: The ladder never climbs past the target by itself
    Given "alice" is at 120 BPM on "pentatonic-run"
    When "alice" rates two takes of "pentatonic-run" at 120 BPM as "clean"
    Then the next take of "pentatonic-run" is at 120 BPM

  @web
  Scenario: A tempo the student chose is never lowered by a struggle
    Given "alice" chose 180 BPM for "pentatonic-run"
    When "alice" rates two takes of "pentatonic-run" at 180 BPM as "struggled"
    Then the next take of "pentatonic-run" is at 180 BPM

  @web
  Scenario: Above a tempo the student chose, the ladder still steps down to it
    Given "alice" chose 100 BPM for "pentatonic-run"
    And "alice" rated two takes of "pentatonic-run" at 100 BPM as "clean"
    When "alice" rates a take of "pentatonic-run" at 105 BPM as "struggled"
    Then the next take of "pentatonic-run" is at 100 BPM

  @web
  Scenario: The student can still lower a tempo they chose
    Given "alice" chose 180 BPM for "pentatonic-run"
    When "alice" chooses 150 BPM for the next take of "pentatonic-run"
    Then the next take of "pentatonic-run" is at 150 BPM
