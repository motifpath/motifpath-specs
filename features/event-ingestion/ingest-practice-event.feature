Feature: Ingest practice events
  As the MotifPath platform
  I want to receive and durably store the practice.* events a practice session produces
  So that every answer can be graded into evidence and every session's plan can be reviewed

  Background:
    Given the Event Ingestion Service is operational and ready to accept events
    And student "alice" is authenticated with a valid session

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A practice.session_started event with its plan is accepted
    When "alice" submits a practice.session_started event for a 10-minute session with guitar in hand and 6 planned items, each with a reason
    Then the event is accepted and stored in the event log
    And the server returns the submitted event identifier and a receipt timestamp

  Scenario: A practice.item_answered event with a raw response is accepted
    When "alice" submits a practice.item_answered event naming the note "C" for the guitar cell on string 5 at fret 3
    Then the event is accepted and stored in the event log
    And the server returns the submitted event identifier and a receipt timestamp

  Scenario: A practice.item_answered event from a challenge exercise is accepted
    When "alice" submits a practice.item_answered event selecting options of exercise "chord-recognition-01" in challenge "open-chords-assessment"
    Then the event is accepted and stored in the event log
    And the server returns the submitted event identifier and a receipt timestamp

  Scenario: A note named among four choices is accepted with its choices
    When "alice" submits a practice.item_answered event naming the note "C" among "B", "F", "C" and "C#" for the guitar cell on string 5 at fret 3
    Then the event is accepted and stored in the event log
    And the stored and published practice.item_answered event keeps the choices "B", "F", "C" and "C#"

  Scenario: An item skipped because its sound failed to load is accepted as not answered
    When "alice" submits a practice.item_answered event skipping exercise "hear-the-fifth" because its sound failed to load
    Then the event is accepted and stored in the event log
    And the stored and published practice.item_answered event is not answered, with the reason "failed_to_load"

  Scenario: A generated question's answer is accepted with the options it was asked among
    When "alice" submits a practice.item_answered event picking "Em" among "Em", "C", "Am" and "Bm" for the chord on vi in G
    Then the event is accepted and stored in the event log

  @wip
  Scenario: A play-along take rated with its note value keeps it
    When "alice" submits a practice.item_answered event rating a take of a play-along "clean" at 60 BPM in eighths
    Then the event is accepted and stored in the event log
    And the stored and published practice.item_answered event keeps the tempo of 60 BPM and the note value eighths

  Scenario: A guide-tone take with no taps keeps its empty list of taps
    When "alice" submits a practice.item_answered event for a guide-tone take of "ii-V-I" in C at 120 BPM with no taps
    Then the event is accepted and stored in the event log
    And the stored and published practice.item_answered event keeps an empty list of taps

  Scenario: Every place of a note tapped in a fret window is accepted
    When "alice" submits a practice.item_answered event tapping string 6 at fret 3, string 4 at fret 5 and string 1 at fret 3 for the note "G" in the window from fret 3
    Then the event is accepted and stored in the event log

  Scenario: A practice.session_ended event with how a drill felt is accepted
    When "alice" submits a practice.session_ended event with 6 items answered, not left early, and "fretboard_cell:name_the_note" felt "about_right"
    Then the event is accepted and stored in the event log

  Scenario: A practice.tap_check_completed event is accepted
    When "alice" submits a practice.tap_check_completed event with a median tap of 350 milliseconds over 24 taps
    Then the event is accepted and stored in the event log

  Scenario: A timed answer is stamped with the student's latest tap time
    Given "alice" has submitted a practice.tap_check_completed event with a median tap of 420 milliseconds
    And "alice" has later submitted a practice.tap_check_completed event with a median tap of 350 milliseconds
    When "alice" submits a practice.item_answered event naming the note "C" for the guitar cell on string 5 at fret 3
    Then the stored and published practice.item_answered event carries a tap time of 350 milliseconds

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A timed answer from a student who never did a tap check carries no tap time
    Given "alice" has never submitted a practice.tap_check_completed event
    When "alice" submits a practice.item_answered event naming the note "C" for the guitar cell on string 5 at fret 3
    Then the stored and published practice.item_answered event carries no tap time

  Scenario: A self-rated take is never stamped with a tap time
    Given "alice" has submitted a practice.tap_check_completed event with a median tap of 350 milliseconds
    When "alice" submits a practice.item_answered event rating a take of a play-along "clean" at 90 BPM
    Then the stored and published practice.item_answered event carries no tap time

  Scenario: A tap time sent by the client is replaced by the server's
    Given "alice" has submitted a practice.tap_check_completed event with a median tap of 350 milliseconds
    When "alice" submits a practice.item_answered event naming a note that claims a tap time of 5 milliseconds
    Then the stored and published practice.item_answered event carries a tap time of 350 milliseconds

  Scenario: A session left early with no felt ratings is accepted
    When "alice" submits a practice.session_ended event with 2 items answered, left early, and no felt ratings
    Then the event is accepted and stored in the event log

  Scenario: A session practised in the head, without an instrument, is accepted
    When "alice" submits a practice.session_started event for a 5-minute session with no instrument in hand and 4 planned items, each with a reason
    Then the event is accepted and stored in the event log

  # ── Validation failures ─────────────────────────────────────────────────────

  Scenario: A practice.item_answered event whose item key matches no item kind is rejected
    When "alice" submits a practice.item_answered event for the item key "fretboard:guitar:5:3"
    Then the submission is rejected as invalid
    And the rejection identifies "item_key" as the source of the error

  Scenario: A practice.item_answered event naming a note that isn't a note is rejected
    When "alice" submits a practice.item_answered event naming the note "H" for the guitar cell on string 5 at fret 3
    Then the submission is rejected as invalid
    And the rejection identifies "response" as the source of the error

  Scenario: A practice.item_answered event whose response says it is correct is rejected
    When "alice" submits a practice.item_answered event whose response also claims it is correct
    Then the submission is rejected as invalid
    And the rejection identifies "response" as the source of the error

  Scenario: A practice.session_started event with no planned items is rejected
    When "alice" submits a practice.session_started event for a 10-minute session with no planned items
    Then the submission is rejected as invalid
    And the rejection identifies "planned_items" as the source of the error

  Scenario: A practice.session_ended event with more than two felt ratings is rejected
    When "alice" submits a practice.session_ended event with 3 felt ratings
    Then the submission is rejected as invalid
    And the rejection identifies "felt_ratings" as the source of the error

  Scenario: A practice.item_answered event with both a practice session and a trigger context is rejected
    When "alice" submits a practice.item_answered event carrying both a practice session and a challenge trigger context
    Then the submission is rejected as invalid
    And the rejection identifies "trigger_context" as the source of the error

  Scenario: A practice.item_answered event with neither a practice session nor a trigger context is rejected
    When "alice" submits a practice.item_answered event with neither a practice session nor a trigger context
    Then the submission is rejected as invalid
    And the rejection identifies "practice_session_id" as the source of the error

  Scenario: A note named among three choices is rejected
    When "alice" submits a practice.item_answered event naming the note "C" among "B", "C" and "C#" for the guitar cell on string 5 at fret 3
    Then the submission is rejected as invalid
    And the rejection identifies "response" as the source of the error

  @wip
  Scenario: A take rated with a note value that isn't one is rejected
    When "alice" submits a practice.item_answered event rating a take of a play-along "clean" at 60 BPM in the note value "fifths"
    Then the submission is rejected as invalid
    And the rejection identifies "note_value" as the source of the error

  Scenario: A generated question's answer offering a single option is rejected
    When "alice" submits a practice.item_answered event picking "Em" among "Em" for the chord on vi in G
    Then the submission is rejected as invalid
    And the rejection identifies "response" as the source of the error
