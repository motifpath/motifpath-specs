Feature: Student self-enrollment in courses
  As the MotifPath platform
  I want students to enroll themselves in a published course
  So that the product itself answers "what's next" without depending on staff availability

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And student "alice" is registered in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A student self-enrolls in a course
    Given "alice" is authenticated as a student
    When "alice" enrolls in course "fingerstyle-journey"
    Then an enrollment is created and returned, pinned to the course's latest published version
    And checkpoint 1's student path is created and becomes the enrollment's active checkpoint
    And the enrollment status is "active"

  Scenario: Self-enrolling sets the new course as current when nothing is currently set
    Given "alice" is authenticated as a student
    And "alice" has no current course or path
    When "alice" enrolls in course "fingerstyle-journey"
    Then "alice"'s current path is now checkpoint 1 of "fingerstyle-journey"

  Scenario: Self-enrolling does not switch a student away from a course they are already running
    Given "alice" is authenticated as a student
    And a second course "rhythm-mastery" exists, published, with checkpoints "rhythm-basics-path"
    And "alice" is already enrolled in "rhythm-mastery" as her current course
    When "alice" enrolls in course "fingerstyle-journey"
    Then a new enrollment for "fingerstyle-journey" is created
    And "alice"'s current course remains "rhythm-mastery"

  Scenario: Completing a checkpoint's items advances the enrollment to the next checkpoint
    Given "alice" is authenticated as a student
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    When "alice" completes every item in checkpoint 1's student path
    Then checkpoint 2's student path is created
    And the enrollment's active checkpoint becomes checkpoint 2

  Scenario: Completing the last checkpoint completes the course and clears the current pointer
    Given "alice" is authenticated as a student
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active as her current path
    And checkpoint 2 is the last checkpoint of "fingerstyle-journey"
    When "alice" completes every item in checkpoint 2's student path
    Then the enrollment status becomes "completed"
    And the completing response signals that the course itself is now complete
    And "alice" has no current course or path

  # ── Congrats page ──────────────────────────────────────────────────────────

  Scenario: The congrats list offers another active enrollment to resume
    Given "alice" is authenticated as a student
    And a second course "rhythm-mastery" exists, published, with checkpoints "rhythm-basics-path"
    And "alice" is enrolled in "rhythm-mastery" with an active checkpoint
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active as her current path
    And checkpoint 2 is the last checkpoint of "fingerstyle-journey"
    When "alice" completes every item in checkpoint 2's student path
    And "alice" lists her course enrollments
    Then the response includes the active "rhythm-mastery" enrollment with its current checkpoint and progress

  Scenario: The congrats list offers only the catalog link when no other enrollment is active
    Given "alice" is authenticated as a student
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active as her current path
    And checkpoint 2 is the last checkpoint of "fingerstyle-journey"
    When "alice" completes every item in checkpoint 2's student path
    And "alice" lists her course enrollments
    Then the response includes no other active enrollment

  Scenario: A student's list of enrollments includes active, completed, and abandoned ones
    Given "alice" is authenticated as a student
    And a second course "rhythm-mastery" exists, published, with checkpoints "rhythm-basics-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active as her current path
    And checkpoint 2 is the last checkpoint of "fingerstyle-journey"
    And "alice" completes every item in checkpoint 2's student path
    And "alice" enrolls in course "rhythm-mastery"
    When "alice" lists her course enrollments
    Then the response includes both the completed "fingerstyle-journey" enrollment and the active "rhythm-mastery" enrollment

  # ── Conflicts ─────────────────────────────────────────────────────────────

  Scenario: A student cannot self-enroll in a course they are already actively enrolled in
    Given "alice" is authenticated as a student
    And "alice" is already enrolled in "fingerstyle-journey" as her current course
    When "alice" attempts to enroll in course "fingerstyle-journey" again
    Then the request is refused with a conflict error

  Scenario: A student may re-enroll in a course they previously abandoned
    Given "alice" is authenticated as a student
    And "alice" enrolled in "fingerstyle-journey" and then abandoned it
    When "alice" enrolls in course "fingerstyle-journey"
    Then a fresh enrollment is created, starting again at checkpoint 1

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Self-enrolling in a course ID that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" attempts to enroll in a course ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Self-enrolling in a course that has never been published returns not found
    Given "alice" is authenticated as a student
    And a course "draft-only-course" exists as a draft with checkpoints "open-chords-path"
    When "alice" attempts to enroll in course "draft-only-course"
    Then the request is refused with a not-found error

  Scenario: Self-enrolling in a course whose latest version is closed to new enrollments returns not found
    Given "alice" is authenticated as a student
    And "fingerstyle-journey"'s latest published version is closed to new enrollments
    When "alice" attempts to enroll in course "fingerstyle-journey"
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A teacher cannot self-enroll in a course
    Given "bob" is authenticated as a teacher
    When "bob" attempts to enroll in course "fingerstyle-journey"
    Then the request is refused with a forbidden error

  Scenario: Self-enrolling without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to enroll in a course
    Then the request is refused with an authentication error
