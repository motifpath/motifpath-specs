@wip
Feature: Manage instruments
  As the MotifPath platform
  I want teachers and admins to define the instruments a prebuilt diagram can be authored against
  So that a Diagram's positions always use the coordinate shape that actually matches its instrument

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a fretted instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "6-string guitar, standard tuning" with 6 strings tuned "E, A, D, G, B, E"
    Then the instrument is created and assigned a stable identifier
    And the instrument's family is "fretted"

  Scenario: A teacher creates a keyboard instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a keyboard instrument named "Piano" with key range "A0" to "C8"
    Then the instrument is created and assigned a stable identifier
    And the instrument's family is "keyboard"

  Scenario: An admin creates an instrument
    Given "admin" is authenticated as an admin
    When "admin" creates a fretted instrument named "4-string bass" with 4 strings tuned "E, A, D, G"
    Then the instrument is created and assigned a stable identifier

  # ── Happy path — listing ─────────────────────────────────────────────────────

  Scenario: A teacher lists all known instruments
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists all known instruments
    Then the response includes instrument "guitar" and instrument "piano"

  Scenario: Listing instruments when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known instruments
    Then the response is an empty list

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a fretted instrument without tuning is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request for a fretted instrument with the tuning field omitted
    Then the request is rejected as invalid
    And the rejection identifies "tuning" as the source of the error

  Scenario: Creating a keyboard instrument with tuning is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request for a keyboard instrument carrying tuning
    Then the request is rejected as invalid
    And the rejection identifies "tuning" as the source of the error

  Scenario: Creating an instrument with an unrecognised family is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request with family "strummed"
    Then the request is rejected as invalid
    And the rejection identifies "family" as the source of the error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create an instrument
    Given "alice" is authenticated as a student
    When "alice" attempts to create an instrument
    Then the request is refused with a forbidden error

  Scenario: Creating an instrument without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create an instrument
    Then the request is refused with an authentication error
