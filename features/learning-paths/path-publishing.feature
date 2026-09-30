Feature: Publish learning paths to the path catalog
  As the MotifPath platform
  I want admins to decide which learning paths learners can find and enroll in
  So that learners never see a half-built path or one that exists only as a course checkpoint

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a learning path "open-chords-path" exists as a draft, created by "bob", with a summary, a language, a level and published lessons

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: Every new learning path starts as a draft
    Given "bob" is authenticated as a teacher
    When "bob" creates a learning path titled "Strumming Basics" with a summary, language "en" and level "beginner"
    Then the learning path's status is "draft"

  @wip
  Scenario: An admin publishes a complete learning path
    Given "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the learning path's status is "published"

  @wip
  Scenario: A published learning path appears in the path catalog
    Given "admin" publishes learning path "open-chords-path"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog
    Then the response includes "open-chords-path"

  @wip
  Scenario: Publishing a learning path that is already published leaves it published
    Given learning path "open-chords-path" is published
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the learning path's status is "published"

  @wip
  Scenario: An admin unpublishes a learning path, removing it from the path catalog
    Given learning path "open-chords-path" is published
    And "admin" is authenticated as an admin
    When "admin" unpublishes learning path "open-chords-path"
    Then the learning path's status is "draft"
    And the path catalog no longer includes "open-chords-path"

  @wip
  Scenario: Unpublishing a learning path leaves learners' copies untouched
    Given learning path "open-chords-path" is published
    And student "alice" has enrolled in "open-chords-path"
    And "admin" is authenticated as an admin
    When "admin" unpublishes learning path "open-chords-path"
    Then "alice"'s copy of "open-chords-path" still exists and is still her current path

  @wip
  Scenario: Editing a published learning path changes what the next learner copies
    Given learning path "open-chords-path" is published
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "open-chords-path" adding a published lesson "node-04"
    Then the learning path's status is still "published"
    And a learner who enrolls in "open-chords-path" afterwards gets a copy that includes "node-04"

  # ── Publishing refused ─────────────────────────────────────────────────────

  @wip
  Scenario: Publishing a learning path without a summary is refused and names what is missing
    Given learning path "open-chords-path" has no summary
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the request is refused with a conflict error
    And the refusal lists "summary" as missing

  @wip
  Scenario: Publishing a learning path without a language is refused
    Given learning path "open-chords-path" has no language
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the request is refused with a conflict error
    And the refusal lists "language" as missing

  @wip
  Scenario: Publishing a learning path recorded without a level is refused
    Given learning path "open-chords-path" was created before levels were recorded
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the request is refused with a conflict error
    And the refusal lists "level" as missing

  @wip
  Scenario: Publishing a learning path with a lesson that was never published is refused
    Given learning path "open-chords-path" includes a content node "draft-node" that has never been published
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the request is refused with a conflict error
    And the refusal lists "unpublished_content" as missing, naming "draft-node"

  @wip
  Scenario: A refused publish lists every missing piece at once
    Given learning path "open-chords-path" has no summary and no language
    And "admin" is authenticated as an admin
    When "admin" publishes learning path "open-chords-path"
    Then the refusal lists "summary" and "language" as missing

  @wip
  Scenario: A refused publish leaves the learning path a draft
    Given learning path "open-chords-path" has no summary
    And "admin" is authenticated as an admin
    When "admin" attempts to publish learning path "open-chords-path"
    Then the learning path's status is still "draft"

  # ── Keeping a published path complete ──────────────────────────────────────

  @wip
  Scenario: Removing the summary of a published learning path is refused
    Given learning path "open-chords-path" is published
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "open-chords-path" leaving out its summary
    Then the request is refused with a conflict error
    And the refusal lists "summary" as missing

  @wip
  Scenario: Adding an unpublished lesson to a published learning path is refused
    Given learning path "open-chords-path" is published
    And a content node "draft-node" exists and has never been published
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "open-chords-path" adding "draft-node"
    Then the request is refused with a conflict error
    And the refusal lists "unpublished_content" as missing, naming "draft-node"

  @wip
  Scenario: A draft learning path can be saved incomplete
    Given "bob" is authenticated as a teacher
    When "bob" replaces learning path "open-chords-path" leaving out its summary
    Then the learning path is saved without a summary
    And the learning path's status is still "draft"

  @wip
  Scenario: Deleting a published learning path is refused
    Given learning path "open-chords-path" is published
    And "bob" is authenticated as a teacher
    When "bob" deletes learning path "open-chords-path"
    Then the request is refused with a conflict error

  @wip
  Scenario: A learning path can be deleted once it is unpublished
    Given learning path "open-chords-path" is published
    And "admin" unpublishes learning path "open-chords-path"
    And "bob" is authenticated as a teacher
    When "bob" deletes learning path "open-chords-path"
    Then the learning path is deleted

  # ── Authorisation failures ─────────────────────────────────────────────────

  @wip
  Scenario: A teacher cannot publish a learning path, even their own
    Given "bob" is authenticated as a teacher
    When "bob" attempts to publish learning path "open-chords-path"
    Then the request is refused with a forbidden error

  @wip
  Scenario: A teacher cannot unpublish a learning path
    Given learning path "open-chords-path" is published
    And "bob" is authenticated as a teacher
    When "bob" attempts to unpublish learning path "open-chords-path"
    Then the request is refused with a forbidden error

  @wip
  Scenario: A student cannot publish a learning path
    Given "alice" is authenticated as a student
    When "alice" attempts to publish learning path "open-chords-path"
    Then the request is refused with a forbidden error

  @wip
  Scenario: Publishing a learning path that does not exist returns not found
    Given "admin" is authenticated as an admin
    When "admin" publishes a learning path ID that does not exist
    Then the request is refused with a not-found error

  @wip
  Scenario: Publishing a learning path without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to publish learning path "open-chords-path"
    Then the request is refused with an authentication error
