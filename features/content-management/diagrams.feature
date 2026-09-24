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

  Scenario: A teacher records a general color and a custom color on one position
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" with color "#3B82F6" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | color   |
      | R        | A         | 6      | 5    | #EF4444 |
      | b3       | C         | 6      | 8    |         |
    Then the diagram is created and assigned a stable identifier
    And the diagram's color is "#3B82F6"
    And position 1 has color "#EF4444"
    And position 2 has no color of its own

  Scenario: Omitting colors leaves them unrecorded
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "No Colors" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no general color
    And position 1 has no color of its own

  # ── Kind and ownership — creating ──────────────────────────────────────────

  @wip
  Scenario: A teacher's new diagram is a custom diagram they own
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "My Pentatonic" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's kind is "custom"
    And the diagram records "bob" as the creator

  @wip
  Scenario: An admin creates a basic diagram
    Given "admin" is authenticated as an admin
    When "admin" creates a basic diagram named "C Major Scale" on instrument "guitar" classified under skills "major-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's kind is "basic"
    And the diagram records "admin" as the creator

  @wip
  Scenario: A teacher cannot create a basic diagram
    Given "bob" is authenticated as a teacher
    When "bob" attempts to create a basic diagram
    Then the request is refused with a forbidden error

  @wip
  Scenario: Creating a diagram with an unrecognised kind is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad kind" on instrument "guitar" with kind "shared" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "kind" as the source of the error

  # ── Saving a copy ──────────────────────────────────────────────────────────

  @wip
  Scenario: A teacher saves a copy of a basic diagram as their own custom diagram
    Given a basic diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" saves a copy of diagram "minor-pentatonic-guitar" named "My Pentatonic"
    Then a new diagram is created with the same positions as "minor-pentatonic-guitar"
    And the new diagram's kind is "custom"
    And the new diagram records "bob" as the creator
    And diagram "minor-pentatonic-guitar" is unchanged

  @wip
  Scenario: An admin saves a copy of a teacher's custom diagram as a basic diagram
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "admin" is authenticated as an admin
    When "admin" saves a copy of diagram "bobs-pentatonic" as a basic diagram named "Pentatonic Template"
    Then a new diagram is created with the same positions as "bobs-pentatonic"
    And the new diagram's kind is "basic"
    And the new diagram records "admin" as the creator
    And diagram "bobs-pentatonic" is unchanged

  # ── Happy path — updating ────────────────────────────────────────────────────

  @wip
  Scenario: A teacher updates their own diagram's root note and label display
    Given a custom diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" setting root note "A" and label display "hidden"
    Then the diagram's root note is "A"
    And the diagram's label display is "hidden"

  @wip
  Scenario: A teacher updates their own diagram's general color and a position's color
    Given a custom diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" setting color "#22C55E" and position 1 color "#F59E0B"
    Then the diagram's color is "#22C55E"
    And position 1 has color "#F59E0B"

  @wip
  Scenario: An admin updates a basic diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "admin" is authenticated as an admin
    When "admin" updates diagram "major-scale-guitar" setting root note "G" and label display "note"
    Then the diagram's root note is "G"
    And the diagram's label display is "note"

  @wip
  Scenario: An admin's update leaves a teacher's custom diagram owned by that teacher
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "admin" is authenticated as an admin
    When "admin" updates diagram "bobs-pentatonic" setting root note "E" and label display "interval"
    Then the diagram's root note is "E"
    And the diagram's kind is "custom"
    And the diagram records "bob" as the creator

  # ── Listing — role scoping ────────────────────────────────────────────────

  @wip
  Scenario: A teacher's diagram list has every basic diagram and only their own custom diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response includes "major-scale-guitar" and "bobs-pentatonic"
    And the response does not include "carols-arpeggio"

  @wip
  Scenario: A teacher narrows the diagram list to basic diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of kind "basic"
    Then the response includes "major-scale-guitar"
    And the response does not include "bobs-pentatonic"

  @wip
  Scenario: A teacher narrows the diagram list to their own custom diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of kind "custom"
    Then the response includes "bobs-pentatonic"
    And the response does not include "major-scale-guitar" or "carols-arpeggio"

  @wip
  Scenario: An admin's diagram list has every diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists all diagrams
    Then the response includes "major-scale-guitar", "bobs-pentatonic" and "carols-arpeggio"

  @wip
  Scenario: An admin narrows the diagram list to one creator
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists diagrams filtered by creator "carol"
    Then the response includes "carols-arpeggio"
    And the response does not include "bobs-pentatonic"

  # ── Listing — filtering and pagination ────────────────────────────────────

  @wip
  Scenario: A teacher filters diagrams by instrument
    Given a basic diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And a basic diagram "minor-pentatonic-piano" exists on instrument "piano"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by instrument "guitar"
    Then the response includes "minor-pentatonic-guitar"
    And the response does not include "minor-pentatonic-piano"

  @wip
  Scenario: Listing diagrams when none exist returns an empty page
    Given "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response contains 0 items
    And the response reports a total of 0

  @wip
  Scenario: The diagram list is paginated
    Given "bob" is authenticated as a teacher
    And 45 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with no paging parameters
    Then the response contains 20 items ordered by name
    And the response reports a total of 45, a limit of 20, and an offset of 0

  @wip
  Scenario: A teacher requests a later page of diagrams
    Given "bob" is authenticated as a teacher
    And 45 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with limit 20 and offset 40
    Then the response contains 5 items
    And the response reports a total of 45

  @wip
  Scenario: An offset past the end of the diagram list returns an empty page
    Given "bob" is authenticated as a teacher
    And 3 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with limit 20 and offset 100
    Then the response contains 0 items
    And the response reports a total of 3

  @wip
  Scenario Outline: An out-of-range diagram page size or offset is rejected
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams with limit <limit> and offset <offset>
    Then the request is refused with a validation error

    Examples:
      | limit | offset |
      | 0     | 0      |
      | 101   | 0      |
      | 20    | -1     |

  # ── Retrieving ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A student retrieves a teacher's custom diagram by its id
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "alice" is authenticated as a student
    When "alice" retrieves diagram "bobs-pentatonic"
    Then the response is diagram "bobs-pentatonic"

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a diagram with an unrecognised label display is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad label display" on instrument "guitar" with root note "A", label display "loud" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "label_display" as the source of the error

  Scenario: Creating a diagram with a malformed general color is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad color" on instrument "guitar" with color "blue" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "color" as the source of the error

  Scenario: Creating a diagram with a malformed position color is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad position color" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | color |
      | R        | A         | 6      | 5    | #GGG  |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

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

  @wip
  Scenario: A teacher cannot update a basic diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "major-scale-guitar" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  @wip
  Scenario: A teacher cannot update another teacher's custom diagram
    Given a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "carols-arpeggio" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  @wip
  Scenario: A student cannot update a diagram
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "alice" is authenticated as a student
    When "alice" updates diagram "bobs-pentatonic" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  @wip
  Scenario: A student cannot list diagrams
    Given "alice" is authenticated as a student
    When "alice" lists all diagrams
    Then the request is refused with a forbidden error

  @wip
  Scenario: A teacher cannot list another teacher's diagrams
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by creator "carol"
    Then the request is refused with a forbidden error

  Scenario: Creating a diagram without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a diagram
    Then the request is refused with an authentication error
