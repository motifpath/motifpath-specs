Feature: List known concepts
  As the MotifPath platform
  I want any authenticated user to browse the catalog of known concepts
  So that content authoring can suggest and reuse concept names instead of forking near-duplicates

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  Scenario: A teacher lists all known concepts
    Given a content node exists in the system with concepts "chord-theory, technique"
    And "bob" is authenticated as a teacher
    When "bob" lists all known concepts
    Then the response includes concepts "chord-theory, technique"

  Scenario: A student lists all known concepts
    Given a content node exists in the system with concepts "chord-theory"
    And "alice" is authenticated as a student
    When "alice" lists all known concepts
    Then the response includes concepts "chord-theory"

  Scenario: Listing concepts when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known concepts
    Then the response is an empty list

  Scenario: A concept used by more than one content node appears only once in the list
    Given a content node exists in the system with concepts "chord-theory"
    And a content node exists in the system with concepts "chord-theory"
    And "bob" is authenticated as a teacher
    When "bob" lists all known concepts
    Then the response includes exactly one concept named "chord-theory"

  Scenario: Listing concepts without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all known concepts
    Then the request is refused with an authentication error
