Feature: Author courses
  As the MotifPath platform
  I want teachers and admins to build a course as an ordered journey of learning-path checkpoints
  So that students have a multi-stage curriculum with a "what's next" answer built in

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a learning path "open-chords-path" exists in the system
    And a learning path "strumming-path" exists in the system
    And a learning path "theory-path" exists in the system

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

  # ── Happy path — fetching the live state for editing ──────────────────────

  Scenario: A teacher retrieves a course's live state to edit it
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" retrieves course "fingerstyle-journey"
    Then the response includes each checkpoint's learning_path_id

  Scenario: A teacher reorders a course by resending its retrieved checkpoints
    Given a course "fingerstyle-journey" exists as a draft with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    And "bob" retrieves course "fingerstyle-journey"
    When "bob" replaces course "fingerstyle-journey" with the retrieved checkpoints reordered to: "strumming-path", "open-chords-path"
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

  Scenario: A teacher's course list includes their own courses of every status
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And a course "draft-only-course" exists as a draft with checkpoints "strumming-path", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" lists the courses they manage
    Then the response includes "fingerstyle-journey" and "draft-only-course"

  Scenario: A teacher browses the published catalog like any learner
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" lists the course catalog
    Then the response includes "strumming-basics"
    And the response does not include "fingerstyle-journey"

  Scenario: An admin browsing the catalog sees only published courses
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "admin" is authenticated as an admin
    When "admin" lists the course catalog
    Then the response includes "fingerstyle-journey"
    And the response does not include "draft-only-course"

  Scenario: A student cannot list the courses teachers manage
    Given "alice" is authenticated as a student
    When "alice" lists the courses they manage
    Then the request is refused with a forbidden error

  # ── Catalog filtering ─────────────────────────────────────────────────────

  Scenario: A student filters the catalog by creator
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by creator "bob"
    Then the response includes "fingerstyle-journey"
    And the response does not include "strumming-basics"

  Scenario: Every catalog entry reports who created the course
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog
    Then the entry for "fingerstyle-journey" records "bob" as the creator

  Scenario: A teacher's course list is always limited to their own courses
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists as a draft, created by "carol", with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" lists the courses they manage with no creator filter
    Then the response includes "fingerstyle-journey"
    And the response does not include "strumming-basics"

  Scenario: A teacher cannot list another teacher's courses
    Given "bob" is authenticated as a teacher
    When "bob" lists the courses they manage filtered by creator "carol"
    Then the request is refused with a forbidden error

  Scenario: An admin lists every creator's courses, or narrows to one
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists as a draft, created by "carol", with checkpoints "strumming-path"
    And "admin" is authenticated as an admin
    When "admin" lists the courses they manage with no creator filter
    Then the response includes "fingerstyle-journey" and "strumming-basics"
    When "admin" lists the courses they manage filtered by creator "carol"
    Then the response includes "strumming-basics"
    And the response does not include "fingerstyle-journey"

  # ── Catalog creators (the creator filter's options) ───────────────────────

  Scenario: A student lists the creators of published courses only
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And a course "draft-only-course" exists as a draft, created by "dave", with checkpoints "theory-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators
    Then the creators returned are "bob" and "carol", each with their display name
    And the creators returned do not include "dave"

  Scenario: A creator with several published courses is listed once
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "bob", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators
    Then the creators returned are "bob", each with their display name

  Scenario: A creator whose only course was retired is no longer listed to students
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" lists the course creators
    Then the creators returned do not include "bob"

  Scenario: The creators of a teacher's managed courses are only themselves
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" lists the creators of the courses they manage
    Then the creators returned are "bob", each with their display name

  Scenario: An admin lists the creator of every course they manage, whatever its status
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "admin" is authenticated as an admin
    When "admin" lists the creators of the courses they manage
    Then the creators returned are "bob" and "carol", each with their display name

  Scenario: A teacher browsing the catalog sees the creator of every published course
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" lists the course creators
    Then the creators returned are "carol", each with their display name

  Scenario: A student cannot list the creators of the courses teachers manage
    Given "alice" is authenticated as a student
    When "alice" lists the creators of the courses they manage
    Then the request is refused with a forbidden error

  Scenario: Course creators are ordered by name, not by their courses' creation order or titles
    Given a course "fingerstyle-journey" exists, published, created by "carol", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "bob", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators
    Then the creators returned are "bob" and "carol", each with their display name

  Scenario: Course creators are ordered by name ignoring case and accents
    Given "bruno" is named "Bruno Lima"
    And "alvaro" is named "álvaro Souza"
    And a course "fingerstyle-journey" exists, published, created by "bruno", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "alvaro", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators
    Then the creators returned are "alvaro" and "bruno", each with their display name

  Scenario: A student narrows the course creators by name
    Given "bob" is named "Bob Martins"
    And "carol" is named "Carol Dias"
    And a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, created by "carol", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators whose name matches "dias"
    Then the creators returned are "carol", each with their display name

  Scenario: The creator name filter ignores case and accents
    Given "jose" is named "José Almeida"
    And a course "fingerstyle-journey" exists, published, created by "jose", with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators whose name matches "JOSE"
    Then the creators returned are "jose", each with their display name

  Scenario: The creator name filter only narrows the creators the caller could already see
    Given "dave" is named "Dave Rocha"
    And a course "draft-only-course" exists as a draft, created by "dave", with checkpoints "theory-path"
    And "alice" is authenticated as a student
    When "alice" lists the course creators whose name matches "dave"
    Then no creators are returned

  Scenario: Listing course creators without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list the course creators
    Then the request is refused with an authentication error

  Scenario: A student filters the catalog by skill
    Given a content node in "open-chords-path" is classified with skill "fingerpicking"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skill "fingerpicking"
    Then the response includes "fingerstyle-journey"
    And the response does not include "strumming-basics"

  Scenario: A student filters the catalog by concept
    Given a content node in "strumming-path" is classified with concept "syncopation"
    And a course "strumming-basics" exists, published, with checkpoints "strumming-path"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by concept "syncopation"
    Then the response includes "strumming-basics"
    And the response does not include "fingerstyle-journey"

  Scenario: Filtering by several skills matches a course with any of them
    Given a content node in "open-chords-path" is classified with skill "fingerpicking"
    And a content node in "strumming-path" is classified with skill "alternate-picking"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, with checkpoints "strumming-path"
    And a course "theory-intro" exists, published, with checkpoints "theory-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skills "fingerpicking", "alternate-picking"
    Then the response includes "fingerstyle-journey" and "strumming-basics"
    And the response does not include "theory-intro"

  Scenario: Filtering by several concepts matches a course with any of them
    Given a content node in "open-chords-path" is classified with concept "syncopation"
    And a content node in "strumming-path" is classified with concept "swing"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, with checkpoints "strumming-path"
    And a course "theory-intro" exists, published, with checkpoints "theory-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by concepts "syncopation", "swing"
    Then the response includes "fingerstyle-journey" and "strumming-basics"
    And the response does not include "theory-intro"

  Scenario: Filtering by both skills and concepts requires a match on each
    Given a content node in "open-chords-path" is classified with skill "fingerpicking" and concept "syncopation"
    And a content node in "strumming-path" is classified with skill "fingerpicking"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And a course "strumming-basics" exists, published, with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skills "fingerpicking" and concepts "syncopation"
    Then the response includes "fingerstyle-journey"
    And the response does not include "strumming-basics"

  Scenario: A classification match in any checkpoint counts
    Given a content node in "strumming-path" is classified with skill "fingerpicking"
    And a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skill "fingerpicking"
    Then the response includes "fingerstyle-journey"

  Scenario: A student's classification filter ignores unpublished draft edits
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" replaces the draft of "fingerstyle-journey" with checkpoints "open-chords-path", "strumming-path"
    And a content node in "strumming-path" is classified with skill "fingerpicking"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skill "fingerpicking"
    Then the response does not include "fingerstyle-journey"

  Scenario: A teacher's classification filter matches the live draft
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "bob" replaces the draft of "fingerstyle-journey" with checkpoints "open-chords-path", "strumming-path"
    And a content node in "strumming-path" is classified with skill "fingerpicking"
    And "bob" is authenticated as a teacher
    When "bob" lists the courses they manage filtered by skill "fingerpicking"
    Then the response includes "fingerstyle-journey"

  Scenario: A student sees a course's checkpoints as a title-only outline, never lesson content
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is authenticated as a student
    When "alice" retrieves the published version of course "fingerstyle-journey"
    Then the response includes each checkpoint's title and its ordered item titles
    And the response does not include any item's lesson content
    And the response does not include any checkpoint's learning_path_id

  Scenario: A teacher or admin previewing the published version never sees unpublished draft edits
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "bob" is authenticated as a teacher
    And "bob" replaces course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    When "bob" retrieves the published version of course "fingerstyle-journey"
    Then the response still shows checkpoints "open-chords-path", "strumming-path" from the last published version

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

  Scenario: A student cannot retrieve a course's live state
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" attempts to retrieve course "fingerstyle-journey"
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

  Scenario: Retrieving the published version of a course that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to retrieve the published version of a course with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: A student retrieving the published version of a course that has never been published gets not found
    Given a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" retrieves the published version of course "draft-only-course"
    Then the request is refused with a not-found error

  Scenario: A teacher retrieving the published version of a course that has never been published also gets not found
    Given a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "bob" is authenticated as a teacher
    When "bob" retrieves the published version of course "draft-only-course"
    Then the request is refused with a not-found error

  # ── Pagination, search, and mixed filters ─────────────────────────────────

  Scenario: The course catalog is paginated
    Given 45 courses exist, published
    And "alice" is authenticated as a student
    When "alice" lists the course catalog with limit 20 and offset 40
    Then the response contains 5 items ordered by title
    And the response reports a total of 45, a limit of 20, and an offset of 40

  Scenario: A student searches the catalog by title or summary text
    Given a course "fingerstyle-journey" exists, published, titled "Fingerstyle Journey"
    And a course "strumming-basics" exists, published, titled "Strumming Basics"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog matching text "fingerstyle"
    Then the response includes "fingerstyle-journey"
    And the response does not include "strumming-basics"

  Scenario: A student filters the catalog by several levels
    Given courses exist, published, at levels "beginner", "intermediate" and "expert"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by levels "beginner", "intermediate"
    Then the response includes the "beginner" and "intermediate" courses
    And the response does not include the "expert" course

  Scenario: A student mixes level, text, skill, and creator filters
    Given a course "fingerstyle-journey" exists, published, created by "bob", at level "beginner", titled "Fingerstyle Journey", classified with skill "fingerpicking"
    And a course "fingerstyle-advanced" exists, published, created by "bob", at level "expert", titled "Fingerstyle Mastery", classified with skill "fingerpicking"
    And a course "strumming-basics" exists, published, created by "carol", at level "beginner", titled "Strumming Basics", classified with skill "fingerpicking"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by level "beginner", text "fingerstyle", skill "fingerpicking", and creator "bob"
    Then the response includes "fingerstyle-journey"
    And the response does not include "fingerstyle-advanced" or "strumming-basics"

  Scenario: Filters narrow the total, not just the page
    Given 30 courses exist, published, at level "beginner" and 30 at level "expert"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by level "beginner" with limit 10
    Then the response contains 10 items
    And the response reports a total of 30

  Scenario: An out-of-range catalog page size is rejected
    Given "alice" is authenticated as a student
    When "alice" lists the course catalog with limit 101
    Then the request is refused with a validation error

  # ── Course language ───────────────────────────────────────────────────────

  Scenario: A teacher creates a course written in one language
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Violão Fingerstyle" in language "pt_BR" with checkpoints in order: "open-chords-path"
    Then the course is created and assigned a stable identifier
    And the course's language is "pt_BR"

  Scenario: Creating a course without a language is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create course request with the language field omitted
    Then the request is refused with a validation error

  Scenario: A course cannot be written in the language-agnostic marker
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Fingerstyle Journey" in language "any" with checkpoints in order: "open-chords-path"
    Then the request is refused with a validation error

  Scenario: Creating a course in a language MotifPath does not offer is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Fingerstyle Journey" in language "xx" with checkpoints in order: "open-chords-path"
    Then the request is refused with a validation error

  Scenario: A learner narrows the catalog to courses in one language
    Given a course "fingerstyle-journey" exists, published in language "en", with checkpoints "open-chords-path"
    And a course "violao-fingerstyle" exists, published in language "pt_BR", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by language "pt_BR"
    Then the response includes "violao-fingerstyle"
    And the response does not include "fingerstyle-journey"

  Scenario: The catalog's language filter ignores an unpublished change of language
    Given a course "fingerstyle-journey" exists, published in language "en", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    And "bob" replaces course "fingerstyle-journey" setting its language to "pt_BR"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by language "pt_BR"
    Then the response does not include "fingerstyle-journey"

  Scenario: A teacher's language filter matches the live draft
    Given a course "fingerstyle-journey" exists, published in language "en", created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    And "bob" replaces course "fingerstyle-journey" setting its language to "pt_BR"
    When "bob" lists the courses they manage filtered by language "pt_BR"
    Then the response includes "fingerstyle-journey"

  Scenario: Publishing records the course's language in the new version
    Given a course "violao-fingerstyle" exists as a draft in language "pt_BR" with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    When "admin" publishes course "violao-fingerstyle"
    Then course version 1 records the language "pt_BR"

  # ── Reactivating a retired course ─────────────────────────────────────────

  Scenario: An admin reactivates a retired course
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    When "admin" reactivates course "fingerstyle-journey"
    Then the course's status becomes "published"

  Scenario: A reactivated course is back in the catalog with its latest published version
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    And "admin" reactivates course "fingerstyle-journey"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog
    Then the response includes "fingerstyle-journey"
    And course "fingerstyle-journey" still has only course version 1

  Scenario: Reactivating a course with unpublished edits brings back its latest published version, not the edits
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    And "bob" replaces course "fingerstyle-journey" with checkpoints in order: "strumming-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    When "admin" reactivates course "fingerstyle-journey"
    Then the course's status becomes "published"
    And the course has unpublished changes
    And the published version of "fingerstyle-journey" still has checkpoints "open-chords-path"

  Scenario: A teacher cannot reactivate a course
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    And "admin" retires course "fingerstyle-journey"
    And "bob" is authenticated as a teacher
    When "bob" attempts to reactivate course "fingerstyle-journey"
    Then the request is refused with a forbidden error

  Scenario: Reactivating a course that is not retired is rejected
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    When "admin" reactivates course "fingerstyle-journey"
    Then the request is refused with a validation error

  Scenario: Reactivating a draft course is rejected
    Given a course "draft-only-course" exists as a draft with checkpoints "strumming-path"
    And "admin" is authenticated as an admin
    When "admin" reactivates course "draft-only-course"
    Then the request is refused with a validation error

  Scenario: Reactivating a course that does not exist returns not found
    Given "admin" is authenticated as an admin
    When "admin" reactivates a course with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Instruments and thumbnail ─────────────────────────────────────────────

  Scenario: A teacher creates a course for specific instruments
    Given a fretted instrument "guitar" exists in the system
    And a fretted instrument "electric-guitar" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" creates a course titled "Blues Rhythm" for instruments "guitar", "electric-guitar" with checkpoints in order: "open-chords-path"
    Then the course is created and assigned a stable identifier
    And the course is for instruments "guitar", "electric-guitar"

  Scenario: A course created with no instruments suits every instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Music Theory Basics" for every instrument with checkpoints in order: "theory-path"
    Then the course is created and assigned a stable identifier
    And the course is for every instrument

  Scenario: Creating a course for an instrument that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Blues Rhythm" for instruments "banjo" with checkpoints in order: "open-chords-path"
    Then the request is refused with a validation error

  Scenario: The catalog's instrument filter keeps courses that suit every instrument
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And a course "blues-rhythm" exists, published for instruments "guitar", with checkpoints "open-chords-path"
    And a course "music-theory-basics" exists, published for every instrument, with checkpoints "theory-path"
    And a course "piano-chords" exists, published for instruments "piano", with checkpoints "strumming-path"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by instrument "guitar"
    Then the response includes "blues-rhythm" and "music-theory-basics"
    And the response does not include "piano-chords"

  Scenario: The catalog's instrument filter ignores unpublished instrument changes
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And a course "blues-rhythm" exists, published for instruments "guitar", created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    And "bob" replaces course "blues-rhythm" setting its instruments to "piano"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by instrument "guitar"
    Then the response includes "blues-rhythm"

  @wip
  Scenario: A course's thumbnail is published with it
    Given a course "fingerstyle-journey" exists as a draft with thumbnail "https://cdn.motifpath.io/thumbnails/fingerstyle.png" and checkpoints "open-chords-path"
    And "admin" is authenticated as an admin
    When "admin" publishes course "fingerstyle-journey"
    Then course version 1 records the thumbnail "https://cdn.motifpath.io/thumbnails/fingerstyle.png"

  @wip
  Scenario: Replacing a course without a thumbnail removes it
    Given a course "fingerstyle-journey" exists as a draft with thumbnail "https://cdn.motifpath.io/thumbnails/fingerstyle.png" and checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "fingerstyle-journey" without a thumbnail
    Then the course has no thumbnail

  # ── Unpublished changes to a course's language, instruments or thumbnail ──

  @wip
  Scenario: Changing only a published course's language leaves it with unpublished changes
    Given a course "fingerstyle-journey" exists, published in language "en", created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "fingerstyle-journey" setting its language to "pt_BR"
    Then the course has unpublished changes

  @wip
  Scenario: Changing only a published course's instruments leaves it with unpublished changes
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And a course "blues-rhythm" exists, published for instruments "guitar", created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "blues-rhythm" setting its instruments to "piano"
    Then the course has unpublished changes

  @wip
  Scenario: Changing only a published course's thumbnail leaves it with unpublished changes
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" replaces course "fingerstyle-journey" setting its thumbnail to "https://cdn.motifpath.io/thumbnails/fingerstyle.png"
    Then the course has unpublished changes

  @wip
  Scenario: A course thumbnail that is not an http or https URL is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a course titled "Fingerstyle Journey" with thumbnail "ftp://files.example/fingerstyle.png" and checkpoints in order: "open-chords-path"
    Then the request is refused with a validation error
