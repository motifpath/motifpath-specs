Feature: Manage the concept tree
  As the MotifPath platform
  I want teachers and admins to build a hierarchy of concepts, and any authenticated user to browse it
  So that content can be classified at whatever specificity actually fits it, and duplicate names across branches stay unambiguous

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a root concept
    Given "bob" is authenticated as a teacher
    When "bob" creates a concept named "music-theory" with no parent
    Then the concept is created and assigned a stable identifier
    And the concept has no parent

  Scenario: A teacher creates a concept under an existing parent
    Given a root concept "music-theory" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" creates a concept named "chord-theory" under concept "music-theory"
    Then the concept is created and assigned a stable identifier
    And the concept's parent is "music-theory"

  Scenario: An admin creates a concept
    Given "admin" is authenticated as an admin
    When "admin" creates a concept named "rhythm-theory" with no parent
    Then the concept is created and assigned a stable identifier

  Scenario: Two different branches may each contain a same-named concept
    Given a root concept "harmony" exists in the system
    And a root concept "rhythm" exists in the system
    And a concept "fundamentals" exists under concept "harmony"
    And "bob" is authenticated as a teacher
    When "bob" creates a concept named "fundamentals" under concept "rhythm"
    Then the concept is created and assigned a stable identifier
    And the two concepts named "fundamentals" are different entities

  # ── Happy path — listing ─────────────────────────────────────────────────────

  Scenario: A teacher lists all known concepts
    Given a root concept "music-theory" exists in the system
    And a concept "chord-theory" exists under concept "music-theory"
    And "bob" is authenticated as a teacher
    When "bob" lists all known concepts
    Then the response includes concept "music-theory" with no parent
    And the response includes concept "chord-theory" with parent "music-theory"

  Scenario: A student lists all known concepts
    Given a root concept "music-theory" exists in the system
    And "alice" is authenticated as a student
    When "alice" lists all known concepts
    Then the response includes concept "music-theory" with no parent

  Scenario: Listing concepts when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known concepts
    Then the response is an empty list

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a concept without a name is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create concept request with the name field omitted
    Then the request is rejected as invalid
    And the rejection identifies "name" as the source of the error

  Scenario: Creating a concept under a parent that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create concept request with a parent_id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "parent_id" as the source of the error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a concept
    Given "alice" is authenticated as a student
    When "alice" attempts to create a concept
    Then the request is refused with a forbidden error

  Scenario: Creating a concept without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a concept
    Then the request is refused with an authentication error

  Scenario: Listing concepts without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all known concepts
    Then the request is refused with an authentication error
