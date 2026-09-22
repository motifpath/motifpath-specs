Feature: Assign learning paths to students
  As the MotifPath platform
  I want teachers and admins to assign a learning path to a student
  So that the student has a personal, independently-editable copy of that path to follow

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a learning path "beginner-guitar-path" exists in the system
    And student "alice" is registered in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher assigns a learning path to a student
    Given "bob" is authenticated as a teacher
    When "bob" assigns "beginner-guitar-path" to student "alice"
    Then a student path is created and returned, copied from "beginner-guitar-path"
    And the student path records "bob" as the assigner and "alice" as the owner
    And the student path becomes "alice"'s current path

  Scenario: An admin assigns a learning path to a student
    Given "admin" is authenticated as an admin
    When "admin" assigns "beginner-guitar-path" to student "alice"
    Then a student path is created and returned, copied from "beginner-guitar-path"

  Scenario: Assigning a new path to a student who already has a current path is additive
    Given "bob" is authenticated as a teacher
    And "alice" already has "beginner-guitar-path" assigned as her current path
    And a second learning path "fingerstyle-basics-path" exists in the system
    When "bob" assigns "fingerstyle-basics-path" to student "alice"
    Then a new student path is returned, copied from "fingerstyle-basics-path"
    And "alice"'s current path is now the new copy of "fingerstyle-basics-path"
    And "alice"'s earlier copy of "beginner-guitar-path" still exists and is not archived

  Scenario: Editing a student's copy of a path does not affect the template it was copied from
    Given "bob" is authenticated as a teacher
    And "bob" assigns "beginner-guitar-path" to student "alice"
    When "bob" edits "alice"'s copy of the path
    Then "beginner-guitar-path" and any other student's copy of it are unchanged

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Assigning a path to a non-existent student returns not found
    Given "bob" is authenticated as a teacher
    When "bob" assigns "beginner-guitar-path" to a student ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Assigning a non-existent path to a student returns not found
    Given "bob" is authenticated as a teacher
    When "bob" assigns a learning path ID that does not exist to student "alice"
    Then the request is refused with a not-found error

  Scenario: Assigning a path to a user with role teacher returns not found
    Given "bob" is authenticated as a teacher
    And "carol" is registered as a teacher
    When "bob" assigns "beginner-guitar-path" to "carol"
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot assign a learning path
    Given "alice" is authenticated as a student
    When "alice" attempts to assign "beginner-guitar-path" to herself
    Then the request is refused with a forbidden error

  Scenario: Assigning a path without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to assign a learning path
    Then the request is refused with an authentication error
