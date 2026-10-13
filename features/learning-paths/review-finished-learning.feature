# Reading a finished course or standalone path again, to review it (MOT-106).
#
# A student who finished a course or a standalone path can read its parts and lessons again. The
# reads never change the current course or path, an enrolment or any status. Progress stays put
# because a completed node stays completed whatever arrives for it later (ADR-011). Events sent
# during review carry a review marker for analytics. Accepting it is in
# features/event-ingestion/ingest-tracking-event.feature. What the student sees is in
# features/web/learning.feature and features/web/lesson-review.feature.

@wip
Feature: Read a finished course or path again
  As a student who finished a course or a standalone path
  I want to read its parts and lessons again without moving my progress
  So that I can review what I learned

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And student "alice" is registered in the system

  # ── Parts of a course enrollment ───────────────────────────────────────────

  Scenario: A finished course lists every part with its lessons, in course order
    Given "alice" is authenticated as a student
    And "alice" has completed course "fingerstyle-journey"
    When "alice" lists the parts of her "fingerstyle-journey" enrollment
    Then the response holds the student paths of "open-chords-path" and "strumming-path", in that order
    And every item of both parts has status "completed"

  Scenario: The parts of a finished course are the version the student took
    Given "alice" is authenticated as a student
    And "alice" has completed course "fingerstyle-journey"
    And a newer version of "fingerstyle-journey" with a third checkpoint "fingerpicking-path" has since been published
    When "alice" lists the parts of her "fingerstyle-journey" enrollment
    Then the response holds only "open-chords-path" and "strumming-path"

  Scenario: An enrollment still in progress lists only the parts reached so far
    Given "alice" is authenticated as a student
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    When "alice" lists the parts of her "fingerstyle-journey" enrollment
    Then the response holds only the student path of "open-chords-path"

  Scenario: Listing the parts of a finished course changes nothing
    Given "alice" is authenticated as a student
    And "alice" has completed course "fingerstyle-journey"
    And "alice"'s current path is the standalone path "blues-path"
    When "alice" lists the parts of her "fingerstyle-journey" enrollment
    Then no part reports course_completed
    And "alice"'s current path is still "blues-path"
    And the enrollment status is still "completed"

  Scenario: Another student's enrollment is not found
    Given "alice" is authenticated as a student
    And student "bob" has completed course "fingerstyle-journey"
    When "alice" lists the parts of "bob"'s "fingerstyle-journey" enrollment
    Then the request is rejected as not found

  Scenario: Listing parts without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request lists the parts of an enrollment
    Then the request is refused with an authentication error

  # ── One held path ──────────────────────────────────────────────────────────

  Scenario: A finished standalone path is read with its lessons
    Given "alice" is authenticated as a student
    And "alice" holds a standalone path "open-chords-path" and has completed every item in it
    When "alice" reads her "open-chords-path" student path
    Then the response holds every item of "open-chords-path" in order, each with status "completed"

  Scenario: A part of a finished course is read by its own id
    Given "alice" is authenticated as a student
    And "alice" has completed course "fingerstyle-journey"
    When "alice" reads the student path of part 2 of her "fingerstyle-journey" enrollment
    Then the response is "strumming-path" with course checkpoint position 2

  Scenario: An archived standalone path can still be read
    Given "alice" is authenticated as a student
    And "alice" holds a standalone path "open-chords-path" that is archived
    When "alice" reads her "open-chords-path" student path
    Then the response holds every item of "open-chords-path" in order

  Scenario: Reading a path that is not current leaves the current path as it is
    Given "alice" is authenticated as a student
    And "alice" holds a standalone path "open-chords-path" and has completed every item in it
    And "alice"'s current path is the standalone path "blues-path"
    When "alice" reads her "open-chords-path" student path
    Then the response does not report course_completed
    And "alice"'s current path is still "blues-path"

  Scenario: Another student's path is not found
    Given "alice" is authenticated as a student
    And student "bob" holds a standalone path "open-chords-path"
    When "alice" reads "bob"'s "open-chords-path" student path
    Then the request is rejected as not found

  Scenario: A path id that is not a valid identifier is rejected
    Given "alice" is authenticated as a student
    When "alice" reads the student path "not-a-uuid"
    Then the request is rejected as invalid

  # ── Progress during review ─────────────────────────────────────────────────

  Scenario: A lesson reviewed in a finished course keeps its status
    Given "alice" has completed course "fingerstyle-journey"
    When "alice"'s lesson.started for the first item of "open-chords-path", marked as review, is processed
    Then that item's status for "alice" is still "completed"
    And the enrollment status is still "completed"

  Scenario: A challenge answered in review counts as practice evidence
    Given "alice" has completed course "fingerstyle-journey"
    When "alice" answers an exercise of a challenge in "open-chords-path", marked as review
    Then the answer is graded and counted in "alice"'s practice evidence like any other
