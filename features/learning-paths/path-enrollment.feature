Feature: Enroll in a published learning path
  As a learner
  I want to start a published path myself, straight from the path catalog
  So that I can follow the path that interests me without waiting for a teacher

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a learning path "open-chords-path" exists, published, created by "bob", with a summary, level "beginner" and a thumbnail
    And student "alice" is registered in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A learner enrolls in a published path
    Given "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then a new student path is created and returned, copied from "open-chords-path"
    And the student path records "alice" as both the owner and the assigner
    And the student path becomes "alice"'s current path

  @wip
  Scenario: A learner's copy records the path's presentation at enrollment
    Given "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then the student path records the summary, level "beginner", thumbnail and creator "bob" of "open-chords-path"

  @wip
  Scenario: Enrolling in a path makes it current even while a course is current
    Given a course "fingerstyle-journey" exists, published, with checkpoints "strumming-path"
    And student "alice" is enrolled in "fingerstyle-journey" and it is her current course
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then the new copy of "open-chords-path" becomes "alice"'s current path
    And "alice"'s enrollment in "fingerstyle-journey" is still active at the same checkpoint

  @wip
  Scenario: Enrolling in a path makes it current even while another standalone path is current
    Given "alice" holds a standalone path "strumming-path" that is her current path
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then the new copy of "open-chords-path" becomes "alice"'s current path
    And "alice"'s copy of "strumming-path" still exists and is not archived

  @wip
  Scenario: A teacher enrolls in a published path, like any learner
    Given "carol" is authenticated as a teacher
    When "carol" enrolls in learning path "open-chords-path"
    Then a new student path is created and returned, copied from "open-chords-path"

  # ── Overlap with what the learner already holds ────────────────────────────

  @wip
  Scenario: A learner can enroll in a path that is also a checkpoint of their course
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then a new standalone student path is created, copied from "open-chords-path"

  @wip
  Scenario: Lessons already completed in a course show as completed in the new copy
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "alice" has completed the first lesson of "open-chords-path" in that course
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then the first lesson of her new copy of "open-chords-path" shows as completed

  @wip
  Scenario: Re-enrolling in a path the learner already holds reuses the active copy
    Given "alice" has enrolled in learning path "open-chords-path"
    And "alice" has since switched her current path to another path
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then her existing copy of "open-chords-path" is returned and no new copy is created
    And her existing copy of "open-chords-path" becomes her current path

  @wip
  Scenario: A path the learner was assigned by staff is also reused on enrollment
    Given "bob" has assigned "open-chords-path" to student "alice"
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then her existing copy of "open-chords-path" is returned and no new copy is created

  @wip
  Scenario: A learner never ends up with two active copies of the same path
    Given "alice" has enrolled in learning path "open-chords-path"
    And "bob" has assigned "open-chords-path" to student "alice"
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    And "alice" lists their standalone paths
    Then exactly one active copy of "open-chords-path" is listed

  @wip
  Scenario: Archiving a copy and enrolling again picks up the path's latest version
    Given "alice" has enrolled in learning path "open-chords-path"
    And "bob" has since added a published lesson "node-04" to learning path "open-chords-path"
    And "alice" has archived her copy of "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then her new copy of "open-chords-path" includes "node-04"

  @wip
  Scenario: Enrolling again after archiving a path creates a fresh copy
    Given "alice" has enrolled in learning path "open-chords-path"
    And "alice" has archived her copy of "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "open-chords-path"
    Then a new student path is created and returned, copied from "open-chords-path"
    And her archived copy of "open-chords-path" stays archived

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: Enrolling in a draft path returns not found
    Given a learning path "strumming-path" exists as a draft
    And "alice" is authenticated as a student
    When "alice" enrolls in learning path "strumming-path"
    Then the request is refused with a not-found error

  @wip
  Scenario: Enrolling in a path that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" enrolls in a learning path ID that does not exist
    Then the request is refused with a not-found error

  @wip
  Scenario: Enrolling without naming a path is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a path enrollment request with the learning_path_id field omitted
    Then the request is refused with a validation error

  @wip
  Scenario: Enrolling in a path without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to enroll in learning path "open-chords-path"
    Then the request is refused with an authentication error
