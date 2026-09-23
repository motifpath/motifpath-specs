Feature: List a student's standalone paths
  As a student
  I want to see the standalone paths I hold
  So that I can browse them and switch to one without going through a course

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And student "alice" is registered in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A student lists their standalone paths, active and archived
    Given "alice" is authenticated as a student
    And "alice" holds a standalone path "open-chords-path" that is active
    And "alice" holds a standalone path "strumming-path" that is archived
    When "alice" lists their standalone paths
    Then the response includes "open-chords-path" and "strumming-path"

  Scenario: Paths belonging to a course enrollment are not listed
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then the response does not include checkpoint 1 of "fingerstyle-journey"

  Scenario: Another student's standalone paths are never listed
    Given student "bruno" is registered in the system
    And "bruno" holds a standalone path "strumming-path" that is active
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then the response does not include "strumming-path"

  # ── Empty ──────────────────────────────────────────────────────────────────

  Scenario: A student with no standalone paths gets an empty list
    Given "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then the response is an empty list

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A teacher cannot list student paths
    Given "bob" is authenticated as a teacher
    When "bob" attempts to list their standalone paths
    Then the request is refused with a forbidden error

  Scenario: Listing standalone paths without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list standalone paths
    Then the request is refused with an authentication error
