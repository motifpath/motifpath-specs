Feature: Author courses
  As the MotifPath platform
  I want teachers and admins to build a course as an ordered journey of learning-path checkpoints
  So that students have a multi-stage curriculum with a "what's next" answer built in

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a learning path "open-chords-path" exists in the system
    And a learning path "strumming-path" exists in the system

  # ── Happy path — creating a course ────────────────────────────────────────

  Scenario: A teacher creates a course with multiple checkpoints
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Fingerstyle Journey" with checkpoints in order: "open-chords-path", "strumming-path"
    Then the course is created and assigned a stable identifier
    And the checkpoints are returned with positions 1 and 2 respectively
    And the course has status "draft"
    And the course records "bob" as the creator

  Scenario: An admin creates a course
    Given "admin" is authenticated as an admin
    When "admin" creates a course titled "Advanced Repertoire" with checkpoints in order: "open-chords-path"
    Then the course is created and assigned a stable identifier

  Scenario: A teacher overrides a checkpoint's title
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Fingerstyle Journey" with checkpoints in order: "open-chords-path" titled "Stage 1: Open chords", "strumming-path"
    Then the first checkpoint's effective title is "Stage 1: Open chords"
    And the second checkpoint's effective title is the title of "strumming-path"

  # ── Happy path — fetching the draft for editing ───────────────────────────

  Scenario: A teacher fetches a course's draft to edit it
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" fetches the draft of course "fingerstyle-journey"
    Then the response includes each checkpoint's learning_path_id

  Scenario: A teacher reorders a course by resending the fetched draft's checkpoints
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    And "bob" fetches the draft of course "fingerstyle-journey"
    When "bob" replaces course "fingerstyle-journey" with the fetched checkpoints reordered to: "strumming-path", "open-chords-path"
    Then the checkpoints are returned with positions 1 and 2 in the order "strumming-path", "open-chords-path"

  # ── Happy path — editing the draft ────────────────────────────────────────

  Scenario: A teacher reorders a course's checkpoints
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "fingerstyle-journey" with checkpoints in order: "strumming-path", "open-chords-path"
    Then the checkpoints are returned with positions 1 and 2 in the order "strumming-path", "open-chords-path"

  Scenario: Editing a published course's draft does not change what already-enrolled students see
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    Then "alice"'s enrollment is still pinned to the version she enrolled under
    And "alice"'s current path is unaffected

  # ── Happy path — publishing ───────────────────────────────────────────────

  Scenario: An admin publishes a course's draft for the first time
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "admin" is authenticated as an admin
    When "admin" publishes course "fingerstyle-journey"
    Then a new course version 1 is created, snapshotting the title, summary, level, and checkpoints
    And the course's status becomes "published"

  Scenario: A teacher cannot publish a course
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" attempts to publish course "fingerstyle-journey"
    Then the request is refused with a forbidden error

  Scenario: Publishing a second time creates a new version without disturbing existing enrollments
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "admin" is authenticated as an admin
    And "bob" is authenticated as a teacher
    And "bob" replaces course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    When "admin" publishes course "fingerstyle-journey"
    Then a new course version 2 is created
    And "alice"'s enrollment is still pinned to course version 1

  # ── Happy path — retiring ─────────────────────────────────────────────────

  Scenario: An admin retires a course
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    When "admin" retires course "fingerstyle-journey"
    Then the course's status becomes "retired"

  Scenario: A retired course no longer appears in a student's catalog
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog
    Then the response does not include "fingerstyle-journey"

  Scenario: Retiring a course does not affect students already enrolled
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And student "alice" is enrolled in "fingerstyle-journey"
    And "admin" is authenticated as an admin
    When "admin" retires course "fingerstyle-journey"
    Then "alice"'s enrollment and current path are unaffected

  # ── Catalog visibility ────────────────────────────────────────────────────

  Scenario: A student's course catalog only includes published courses
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog
    Then the response includes "fingerstyle-journey"
    And the response does not include "draft-only-course"

  Scenario: A teacher's course list includes drafts, published, and retired courses
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" lists the course catalog
    Then the response includes "fingerstyle-journey" and "draft-only-course"

  Scenario: A student sees a course's checkpoints as a title-only outline, never lesson content
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is authenticated as a student
    When "alice" retrieves course "fingerstyle-journey"
    Then the response includes each checkpoint's title and its ordered item titles
    And the response does not include any item's lesson content

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a course without a title is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create course request with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Creating a course with no checkpoints is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create course request with an empty checkpoints array
    Then the request is rejected as invalid
    And the rejection identifies "checkpoints" as the source of the error

  Scenario: Creating a course that references a non-existent learning path is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a course with a checkpoint referencing a learning path ID that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "learning_path_id" as the source of the error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a course
    Given "alice" is authenticated as a student
    When "alice" attempts to create a course
    Then the request is refused with a forbidden error

  Scenario: A student cannot replace a course
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" attempts to replace course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    Then the request is refused with a forbidden error

  Scenario: A teacher who did not create the course, and is not an admin, cannot replace it
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", created by "bob"
    And "carol" is authenticated as a teacher
    When "carol" attempts to replace course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot retire a course
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" attempts to retire course "fingerstyle-journey"
    Then the request is refused with a forbidden error

  Scenario: A student cannot fetch a course's draft
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" attempts to fetch the draft of course "fingerstyle-journey"
    Then the request is refused with a forbidden error

  Scenario: Creating a course without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a course
    Then the request is refused with an authentication error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Retrieving a course that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" retrieves a course with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Fetching the draft of a course that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to fetch the draft of a course with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: A student retrieving a course with no published version gets not found
    Given a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" retrieves course "draft-only-course"
    Then the request is refused with a not-found error
