Feature: Manage learning paths
  As the MotifPath platform
  I want teachers and admins to create ordered sequences of content nodes
  So that students have a structured curriculum to follow

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And content nodes "node-01", "node-02", and "node-03" exist in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher creates a learning path with multiple content nodes
    Given "bob" is authenticated as a teacher
    When "bob" creates a learning path titled "Beginner Guitar" with items in order: "node-01", "node-02", "node-03"
    Then the learning path is created and assigned a stable identifier
    And the items are returned with positions 1, 2, and 3 respectively
    And the path records "bob" as the owner

  Scenario: An admin creates a learning path
    Given "admin" is authenticated as an admin
    When "admin" creates a learning path titled "Advanced Techniques" with items in order: "node-01", "node-02"
    Then the learning path is created and assigned a stable identifier

  Scenario: A teacher retrieves a learning path by ID
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    When "bob" retrieves the learning path "beginner-guitar-path"
    Then the response returns the path title, owner, and ordered items

  # ── Section labels ─────────────────────────────────────────────────────────

  Scenario: A teacher creates a learning path with items grouped into sections
    Given "bob" is authenticated as a teacher
    When "bob" creates a learning path titled "Rhythm Foundations" with items in order: "node-01" in section "Open chords", "node-02" in section "Open chords", "node-03" in section "Strumming patterns"
    Then the learning path is created and assigned a stable identifier
    And "node-01" and "node-02" are returned with section_label "Open chords"
    And "node-03" is returned with section_label "Strumming patterns"

  # ── Happy path — listing learning paths for authoring ─────────────────────────

  Scenario: A teacher lists all learning paths in the library
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And a learning path "advanced-path" exists with items "node-01", "node-02"
    And "bob" is authenticated as a teacher
    When "bob" lists all learning paths
    Then the response includes "beginner-guitar-path" and "advanced-path"

  Scenario: An admin lists all learning paths in the library
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "admin" is authenticated as an admin
    When "admin" lists all learning paths
    Then the response includes "beginner-guitar-path"

  Scenario: Listing learning paths when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all learning paths
    Then the response is an empty list

  # ── Happy path — replacing a learning path ────────────────────────────────────

  Scenario: A teacher reorders a learning path's items
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "beginner-guitar-path" with items in order: "node-02", "node-01", "node-03"
    Then the items are returned with positions 1, 2, and 3 in the order "node-02", "node-01", "node-03"

  Scenario: A teacher adds an item to an existing learning path
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02"
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "beginner-guitar-path" with items in order: "node-01", "node-02", "node-03"
    Then the learning path has 3 items

  Scenario: A teacher removes an item from an existing learning path
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "beginner-guitar-path" with items in order: "node-01", "node-03"
    Then the learning path has 2 items

  Scenario: A teacher relabels a learning path's sections
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "beginner-guitar-path" with items in order: "node-01" in section "Open chords, revised", "node-02" in section "Open chords, revised", "node-03"
    Then "node-01" and "node-02" are returned with section_label "Open chords, revised"

  # ── Validation failures — replacing ───────────────────────────────────────────

  Scenario: Replacing a learning path with no items is rejected
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "bob" is authenticated as a teacher
    When "bob" submits a replace learning path request for "beginner-guitar-path" with an empty items array
    Then the request is rejected as invalid
    And the rejection identifies "items" as the source of the error

  Scenario: Replacing a learning path that references a non-existent content node is rejected
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "bob" is authenticated as a teacher
    When "bob" replaces learning path "beginner-guitar-path" with an item referencing a content node ID that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "content_node_id" as the source of the error

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a learning path without a title is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create learning path request with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Creating a learning path with no items is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create learning path request with an empty items array
    Then the request is rejected as invalid
    And the rejection identifies "items" as the source of the error

  Scenario: Creating a learning path that references a non-existent content node is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a learning path with an item referencing a content node ID that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "content_node_id" as the source of the error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a learning path
    Given "alice" is authenticated as a student
    When "alice" attempts to create a learning path
    Then the request is refused with a forbidden error

  Scenario: A student cannot retrieve a learning path directly
    Given "alice" is authenticated as a student
    And a learning path "beginner-guitar-path" exists in the system
    When "alice" attempts to retrieve the learning path "beginner-guitar-path"
    Then the request is refused with a forbidden error

  Scenario: A student cannot list learning paths
    Given "alice" is authenticated as a student
    When "alice" attempts to list all learning paths
    Then the request is refused with a forbidden error

  Scenario: A student cannot replace a learning path
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "alice" is authenticated as a student
    When "alice" attempts to replace learning path "beginner-guitar-path" with items in order: "node-01"
    Then the request is refused with a forbidden error

  Scenario: Creating a learning path without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a learning path
    Then the request is refused with an authentication error

  Scenario: Listing learning paths without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all learning paths
    Then the request is refused with an authentication error

  Scenario: Replacing a learning path without an authentication token is refused
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And no authentication token is provided
    When an unauthenticated request attempts to replace learning path "beginner-guitar-path" with items in order: "node-01"
    Then the request is refused with an authentication error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Retrieving a learning path that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" retrieves a learning path with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Replacing a learning path that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to replace a learning path with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Deleting a learning path ────────────────────────────────────────────────

  Scenario: A teacher deletes a learning path that is not used by any course
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    When "bob" deletes the learning path "beginner-guitar-path"
    Then the learning path is deleted

  Scenario: Deleting a learning path does not affect students who already copied it
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And student "alice" has "beginner-guitar-path" assigned as a standalone path
    When "bob" deletes the learning path "beginner-guitar-path"
    Then the learning path is deleted
    And "alice"'s copy of the path is unaffected

  Scenario: An admin deletes a learning path created by a teacher
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And "admin" is authenticated as an admin
    When "admin" deletes the learning path "beginner-guitar-path"
    Then the learning path is deleted

  Scenario: A teacher cannot delete a learning path they do not own
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03", owned by a different teacher
    When "bob" attempts to delete the learning path "beginner-guitar-path"
    Then the request is refused with a forbidden error

  Scenario: Deleting a learning path referenced by a published course's checkpoint is refused
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And a course "fingerstyle-journey" exists, published, with checkpoints "beginner-guitar-path"
    When "bob" attempts to delete the learning path "beginner-guitar-path"
    Then the request is refused with a conflict error

  Scenario: Deleting a learning path referenced only by a retired course's published checkpoint is still refused
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And a course "fingerstyle-journey" exists, published, with checkpoints "beginner-guitar-path"
    And "fingerstyle-journey" has since been retired
    When "bob" attempts to delete the learning path "beginner-guitar-path"
    Then the request is refused with a conflict error

  Scenario: Deleting a learning path referenced only by an unpublished course draft is allowed
    Given "bob" is authenticated as a teacher
    And a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And a course "fingerstyle-journey" exists as a draft with checkpoints "beginner-guitar-path"
    When "bob" deletes the learning path "beginner-guitar-path"
    Then the learning path is deleted

  Scenario: Deleting a learning path that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to delete a learning path with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Deleting a learning path without an authentication token is refused
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03"
    And no authentication token is provided
    When an unauthenticated request attempts to delete learning path "beginner-guitar-path"
    Then the request is refused with an authentication error
