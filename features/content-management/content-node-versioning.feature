Feature: Content node versioning
  As the MotifPath platform
  I want a content node's published state to be versioned and non-retroactive
  So that editing a node never silently alters or un-completes work a student has already done

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a content node "node-01" exists in the system
    And student "alice" is registered in the system

  # ── Happy path — publishing ───────────────────────────────────────────────

  Scenario: A teacher publishes a content node's draft for the first time
    Given "bob" is authenticated as a teacher
    When "bob" publishes content node "node-01"
    Then a new content node version 1 is created, snapshotting its title, classification, media, and languages
    And "node-01"'s latest_published_version becomes 1

  Scenario: An admin publishes a content node
    Given "admin" is authenticated as an admin
    When "admin" publishes content node "node-01"
    Then a new content node version 1 is created

  Scenario: Publishing a content node again creates a new version
    Given "bob" is authenticated as a teacher
    And "bob" published content node "node-01" as version 1
    And "bob" edited "node-01"'s title
    When "bob" publishes content node "node-01"
    Then a new content node version 2 is created
    And "node-01"'s latest_published_version becomes 2

  # ── Copy-time resolution ──────────────────────────────────────────────────

  Scenario: Assigning a path whose content node has never been published is refused
    Given a learning path "beginner-guitar-path" exists with items "node-01"
    And "node-01" has never been published
    And "bob" is authenticated as a teacher
    When "bob" assigns "beginner-guitar-path" to student "alice"
    Then the request is refused with a not-found error

  Scenario: A newly copied student path item resolves to the node's latest published version at copy time
    Given a learning path "beginner-guitar-path" exists with items "node-01"
    And "bob" published content node "node-01" as version 1
    And "bob" is authenticated as a teacher
    When "bob" assigns "beginner-guitar-path" to student "alice"
    Then "alice"'s copy of "node-01" is pinned to content node version 1

  Scenario: A later publish does not retarget an already-copied item
    Given a learning path "beginner-guitar-path" exists with items "node-01"
    And "bob" published content node "node-01" as version 1
    And "bob" is authenticated as a teacher
    And "bob" assigns "beginner-guitar-path" to student "alice"
    And "bob" published content node "node-01" as version 2
    When "alice" retrieves her current path
    Then "alice"'s copy of "node-01" is still pinned to content node version 1

  Scenario: Two students copying the same template a version apart land on different concrete node versions
    Given a learning path "beginner-guitar-path" exists with items "node-01"
    And "bob" published content node "node-01" as version 1
    And "bob" is authenticated as a teacher
    And "bob" assigns "beginner-guitar-path" to student "alice"
    And "bob" published content node "node-01" as version 2
    And student "carol" is registered in the system
    When "bob" assigns "beginner-guitar-path" to student "carol"
    Then "alice"'s copy of "node-01" is pinned to content node version 1
    And "carol"'s copy of "node-01" is pinned to content node version 2

  # ── Completion generalises across versions ────────────────────────────────

  Scenario: A node completed at one version shows completed when it later reappears at a newer version
    Given a learning path "beginner-guitar-path" exists with items "node-01"
    And "bob" published content node "node-01" as version 1
    And "bob" is authenticated as a teacher
    And "bob" assigns "beginner-guitar-path" to student "alice"
    And "alice" has completed "node-01"
    And "bob" published content node "node-01" as version 2
    And a second learning path "advanced-path" exists with items "node-01"
    When "bob" assigns "advanced-path" to student "alice"
    Then "alice"'s new copy of "node-01" shows status "completed"

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot publish a content node
    Given "alice" is authenticated as a student
    When "alice" attempts to publish content node "node-01"
    Then the request is refused with a forbidden error

  Scenario: A teacher who did not create the content node, and is not an admin, cannot publish it
    Given content node "node-02" exists, created by "bob"
    And "carol" is authenticated as a teacher
    When "carol" attempts to publish content node "node-02"
    Then the request is refused with a forbidden error

  Scenario: Publishing a content node without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to publish a content node
    Then the request is refused with an authentication error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Publishing a content node that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to publish a content node with an ID that does not exist
    Then the request is refused with a not-found error
