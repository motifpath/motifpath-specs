Feature: Manage the skill tree
  As the MotifPath platform
  I want teachers and admins to build a hierarchy of skills, and any authenticated user to browse it
  So that content can be classified at whatever specificity actually fits it, and duplicate names across branches stay unambiguous

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a root skill
    Given "bob" is authenticated as a teacher
    When "bob" creates a skill named "guitar-technique" with no parent
    Then the skill is created and assigned a stable identifier
    And the skill has no parent

  Scenario: A teacher creates a skill under an existing parent
    Given a root skill "guitar-technique" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" creates a skill named "right-hand-technique" under skill "guitar-technique"
    Then the skill is created and assigned a stable identifier
    And the skill's parent is "guitar-technique"

  Scenario: An admin creates a skill
    Given "admin" is authenticated as an admin
    When "admin" creates a skill named "left-hand-technique" with no parent
    Then the skill is created and assigned a stable identifier

  Scenario: Two different branches may each contain a same-named skill
    Given a root skill "picking" exists in the system
    And a root skill "rhythm" exists in the system
    And a skill "technique" exists under skill "picking"
    And "bob" is authenticated as a teacher
    When "bob" creates a skill named "technique" under skill "rhythm"
    Then the skill is created and assigned a stable identifier
    And the two skills named "technique" are different entities

  # ── Happy path — listing ─────────────────────────────────────────────────────

  Scenario: A teacher lists all known skills
    Given a root skill "guitar-technique" exists in the system
    And a skill "right-hand-technique" exists under skill "guitar-technique"
    And "bob" is authenticated as a teacher
    When "bob" lists all known skills
    Then the response includes skill "guitar-technique" with no parent
    And the response includes skill "right-hand-technique" with parent "guitar-technique"

  Scenario: A student lists all known skills
    Given a root skill "guitar-technique" exists in the system
    And "alice" is authenticated as a student
    When "alice" lists all known skills
    Then the response includes skill "guitar-technique" with no parent

  Scenario: Listing skills when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known skills
    Then the response is an empty list

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a skill without a name is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create skill request with the name field omitted
    Then the request is rejected as invalid
    And the rejection identifies "name" as the source of the error

  Scenario: Creating a skill under a parent that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create skill request with a parent_id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "parent_id" as the source of the error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a skill
    Given "alice" is authenticated as a student
    When "alice" attempts to create a skill
    Then the request is refused with a forbidden error

  Scenario: Creating a skill without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a skill
    Then the request is refused with an authentication error

  Scenario: Listing skills without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all known skills
    Then the request is refused with an authentication error
