Feature: Manage prebuilt diagrams
  As the MotifPath platform
  I want teachers and admins to author reusable, structured diagrams classified by skill and concept
  So that the same scale or chord pattern can be shown, styled, and played back differently across
  any number of content nodes and exercises, without being redrawn as a new image each time

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a diagram on a fretted instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
      | b3       | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 2 positions

  Scenario: A teacher creates a diagram on a keyboard instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Piano" on instrument "piano" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with keyboard positions:
      | interval | note_name | key |
      | R        | A         | A3  |
      | b3       | C         | C4  |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 2 positions

  Scenario: An admin creates a diagram
    Given "admin" is authenticated as an admin
    When "admin" creates a diagram named "C Major Scale" on instrument "guitar" classified under skills "major-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier

  Scenario: A teacher records a root note, label display, and per-position shapes
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" with root note "A", label display "note" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | shape |
      | R        | A         | 6      | 5    | star  |
      | b3       | C         | 6      | 8    |       |
    Then the diagram is created and assigned a stable identifier
    And the diagram's root note is "A"
    And the diagram's label display is "note"
    And position 1 has shape "star"
    And position 2 has shape "dot"

  Scenario: Omitting root note, label display, and shape leaves them unrecorded or defaulted
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "No Extras" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no recorded root note
    And the diagram's label display is "interval"
    And position 1 has shape "dot"

  # ── Happy path — listing ─────────────────────────────────────────────────────

  Scenario: A teacher filters diagrams by instrument
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And a diagram "minor-pentatonic-piano" exists on instrument "piano"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by instrument "guitar"
    Then the response includes "minor-pentatonic-guitar"
    And the response does not include "minor-pentatonic-piano"

  Scenario: Listing diagrams when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response is an empty list

  # ── Happy path — updating ────────────────────────────────────────────────────

  Scenario: A teacher updates a diagram's root note and label display
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" setting root note "A" and label display "hidden"
    Then the diagram's root note is "A"
    And the diagram's label display is "hidden"

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a diagram with an unrecognised label display is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad label display" on instrument "guitar" with root note "A", label display "loud" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "label_display" as the source of the error

  Scenario: Creating a diagram with keyboard positions on a fretted instrument is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad shape" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with keyboard positions:
      | interval | note_name | key |
      | R        | A         | A3  |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: Creating a diagram without any skill is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "guitar" with the skill_ids field omitted
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating a diagram against an instrument that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request with an instrument id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "instrument_id" as the source of the error

  # ── Not found ──────────────────────────────────────────────────────────────

  Scenario: Retrieving a diagram that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves a diagram with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a diagram
    Given "alice" is authenticated as a student
    When "alice" attempts to create a diagram
    Then the request is refused with a forbidden error

  Scenario: Creating a diagram without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a diagram
    Then the request is refused with an authentication error
