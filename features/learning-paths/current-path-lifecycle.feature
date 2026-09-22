Feature: Switch, abandon, and archive a student's courses and paths
  As the MotifPath platform
  I want a student to run multiple courses and paths in parallel, switch between them, and leave one behind
  So that a student is never forced to lose progress on one journey to start another

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And student "alice" is registered in the system

  # ── Switching current ──────────────────────────────────────────────────────

  Scenario: A student switches their current course to one they are already enrolled in
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "rhythm-mastery" exists, published, with checkpoints "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" as her current course
    And "alice" is enrolled in "rhythm-mastery"
    When "alice" switches her current path to her "rhythm-mastery" enrollment
    Then "alice"'s current path is now checkpoint 1 of "rhythm-mastery"

  Scenario: Switching back to a course resumes exactly where its checkpoint was left
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And a course "rhythm-mastery" exists, published, with checkpoints "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active as her current path
    And "alice" is enrolled in "rhythm-mastery"
    And "alice" switches her current path to her "rhythm-mastery" enrollment
    When "alice" switches her current path back to her "fingerstyle-journey" enrollment
    Then "alice"'s current path is checkpoint 2 of "fingerstyle-journey", unchanged from where she left it

  Scenario: A student switches their current path to a standalone path
    Given "alice" is authenticated as a student
    And a learning path "open-chords-path" exists in the system
    And "alice" has "open-chords-path" assigned as a standalone path, not current
    And "alice" has a course enrollment as her current course
    When "alice" switches her current path to that standalone path
    Then "alice"'s current path is now the standalone path

  # ── Abandoning a course enrollment ────────────────────────────────────────

  Scenario: Abandoning a course enrollment that is current, while another course enrollment is available, requires switching first
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "rhythm-mastery" exists, published, with checkpoints "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" as her current course
    And "alice" is enrolled in "rhythm-mastery"
    When "alice" attempts to abandon her "fingerstyle-journey" enrollment
    Then the request is refused with a conflict error

  Scenario: Abandoning the only current course is allowed once the student truly has nothing else
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is enrolled in "fingerstyle-journey" as her only current course
    And "alice" has no other active enrollment or standalone path
    When "alice" abandons her "fingerstyle-journey" enrollment
    Then the enrollment status becomes "abandoned"
    And "alice" has no current course or path

  Scenario: Abandoning a course enrollment that is current, while a standalone path is available, requires switching first
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a learning path "strumming-path" exists in the system
    And "alice" is enrolled in "fingerstyle-journey" as her current course
    And "alice" has "strumming-path" assigned as a standalone path, not current
    When "alice" attempts to abandon her "fingerstyle-journey" enrollment
    Then the request is refused with a conflict error

  # ── Archiving a standalone path ────────────────────────────────────────────

  Scenario: A student archives a standalone path while another is available
    Given "alice" is authenticated as a student
    And a learning path "open-chords-path" exists in the system
    And a learning path "strumming-path" exists in the system
    And "alice" has "open-chords-path" assigned as her current path
    And "alice" has "strumming-path" assigned as a standalone path, not current
    When "alice" archives her standalone "strumming-path" copy
    Then that student path becomes archived

  Scenario: Archiving the only current standalone path is allowed once the student truly has nothing else
    Given "alice" is authenticated as a student
    And a learning path "open-chords-path" exists in the system
    And "alice" has "open-chords-path" assigned as her only current path
    When "alice" archives her current standalone path
    Then that student path becomes archived
    And "alice" has no current course or path

  Scenario: A student cannot archive a course checkpoint's student path via the standalone archive action
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is enrolled in "fingerstyle-journey" as her current course
    When "alice" attempts to archive her "fingerstyle-journey" checkpoint's student path via the standalone archive action
    Then the request is refused with a not-found error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Switching to a course enrollment that does not belong to the caller returns not found
    Given "alice" is authenticated as a student
    And another student "carol" has a course enrollment
    When "alice" attempts to switch her current path to "carol"'s enrollment
    Then the request is refused with a not-found error

  Scenario: Switching to an abandoned enrollment returns not found
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" enrolled in "fingerstyle-journey" and then abandoned it
    When "alice" attempts to switch her current path to the abandoned "fingerstyle-journey" enrollment
    Then the request is refused with a not-found error

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Switching current path without specifying a target is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a switch current path request with neither course_enrollment_id nor student_path_id
    Then the request is rejected as invalid

  Scenario: Switching current path with both a course enrollment and a standalone path is rejected
    Given "alice" is authenticated as a student
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is enrolled in "fingerstyle-journey"
    And a learning path "strumming-path" exists in the system
    And "alice" has "strumming-path" assigned as a standalone path
    When "alice" submits a switch current path request with both course_enrollment_id and student_path_id set
    Then the request is rejected as invalid

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: Switching current path without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to switch current path
    Then the request is refused with an authentication error
