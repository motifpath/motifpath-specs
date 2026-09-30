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

  # ── Presentation ───────────────────────────────────────────────────────────

  Scenario: A standalone path shows the presentation recorded when it was copied
    Given a learning path "open-chords-path" exists, created by "bob", with a summary, level "beginner" and a thumbnail
    And "alice" holds a standalone path copied from "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "open-chords-path" reports the summary, level "beginner", thumbnail and creator "bob" it was copied with

  Scenario: A copy's presentation does not change when the template is edited
    Given a learning path "open-chords-path" exists with summary "Your first chords"
    And "alice" holds a standalone path copied from "open-chords-path"
    And "bob" replaces learning path "open-chords-path" with summary "Open chords, reworked"
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "open-chords-path" still reports summary "Your first chords"

  Scenario: A copy keeps its presentation after the template is deleted
    Given a learning path "open-chords-path" exists with summary "Your first chords"
    And "alice" holds a standalone path copied from "open-chords-path"
    And learning path "open-chords-path" has been deleted
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "open-chords-path" still reports summary "Your first chords"

  Scenario: A path copied before presentations were recorded shows only its title
    Given "alice" holds a standalone path "strumming-path" copied before presentations were recorded
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "strumming-path" reports its title and no summary, level, thumbnail or creator

  Scenario: A standalone path reports how many of its lessons the student has completed
    Given "alice" holds a standalone path "open-chords-path" with 4 lessons
    And "alice" has completed 3 of those lessons
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "open-chords-path" reports 4 lessons and 3 completed

  Scenario: A lesson completed in another path counts toward a standalone path
    Given "alice" holds a standalone path "open-chords-path" whose first lesson also appears in course "fingerstyle-journey"
    And "alice" has completed that lesson in "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then her copy of "open-chords-path" reports 1 completed

  # ── Empty ──────────────────────────────────────────────────────────────────

  Scenario: A student with no standalone paths gets an empty list
    Given "alice" is authenticated as a student
    When "alice" lists their standalone paths
    Then the response is an empty list

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A teacher lists their own standalone paths, like any learner
    Given "bob" is authenticated as a teacher
    When "bob" attempts to list their standalone paths
    Then the response is an empty list

  Scenario: Listing standalone paths without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list standalone paths
    Then the request is refused with an authentication error
