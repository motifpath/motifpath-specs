Feature: List known skills
  As the MotifPath platform
  I want any authenticated user to browse the catalog of known skills
  So that content authoring can suggest and reuse skill names instead of forking near-duplicates

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  Scenario: A teacher lists all known skills
    Given a content node exists in the system with skills "triad-shapes, sweep-picking"
    And "bob" is authenticated as a teacher
    When "bob" lists all known skills
    Then the response includes skills "triad-shapes, sweep-picking"

  Scenario: A student lists all known skills
    Given a content node exists in the system with skills "triad-shapes"
    And "alice" is authenticated as a student
    When "alice" lists all known skills
    Then the response includes skills "triad-shapes"

  Scenario: Listing skills when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known skills
    Then the response is an empty list

  Scenario: A skill used by more than one content node appears only once in the list
    Given a content node exists in the system with skills "triad-shapes"
    And a content node exists in the system with skills "triad-shapes"
    And "bob" is authenticated as a teacher
    When "bob" lists all known skills
    Then the response includes exactly one skill named "triad-shapes"

  Scenario: Listing skills without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all known skills
    Then the request is refused with an authentication error
