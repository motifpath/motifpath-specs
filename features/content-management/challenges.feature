Feature: Manage challenges
  As the MotifPath platform
  I want teachers and admins to create challenges attached to content nodes
  So that the recommendation engine has subject tags and thresholds to act on

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a content node "intro-to-triads" exists in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher creates a challenge with a subject tag and pass threshold
    Given "bob" is authenticated as a teacher
    When "bob" creates a challenge for "intro-to-triads" with subject tag "triad-shapes" and pass threshold 70
    Then the challenge is created and assigned a stable identifier
    And the challenge records "intro-to-triads" as its parent content node

  Scenario: A teacher creates a challenge with a remediation target
    Given "bob" is authenticated as a teacher
    And a content node "triad-remediation" exists in the system
    When "bob" creates a challenge for "intro-to-triads" with subject tag "triad-shapes", pass threshold 70, and remediation target "triad-remediation"
    Then the challenge is created with the remediation target recorded

  Scenario: An admin creates a challenge
    Given "admin" is authenticated as an admin
    When "admin" creates a challenge for "intro-to-triads" with subject tag "chord-theory" and pass threshold 80
    Then the challenge is created and assigned a stable identifier

  Scenario: A teacher creates a challenge with shuffled exercises and options
    Given "bob" is authenticated as a teacher
    When "bob" creates a challenge for "intro-to-triads" with subject tag "triad-shapes", pass threshold 70, shuffled exercises, and shuffled options
    Then the challenge is created with exercise shuffling and option shuffling both enabled

  Scenario: A teacher creates a challenge without specifying shuffling
    Given "bob" is authenticated as a teacher
    When "bob" creates a challenge for "intro-to-triads" with subject tag "triad-shapes" and pass threshold 70
    Then the challenge is created with exercise shuffling and option shuffling both disabled

  Scenario: Any authenticated user retrieves a challenge by ID
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" retrieves the challenge "triad-challenge"
    Then the response returns the challenge's subject tag, threshold, and parent content node

  # ── Happy path — listing a node's challenges ─────────────────────────────────

  Scenario: A student lists the challenges for a node that has one
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" lists the challenges for content node "intro-to-triads"
    Then the response includes "triad-challenge"

  Scenario: A student lists the challenges for a node that has none
    Given a content node "silent-node" exists in the system
    And "alice" is authenticated as a student
    When "alice" lists the challenges for content node "silent-node"
    Then the response is an empty list

  # ── Happy path — updating a challenge ─────────────────────────────────────────

  Scenario: A teacher updates a challenge's subject tag and pass threshold
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" updates challenge "triad-challenge" with subject tag "triad-shapes-revised" and pass threshold 85
    Then the challenge's subject tag is "triad-shapes-revised"
    And the challenge's pass threshold is 85

  Scenario: A teacher sets a remediation target on an existing challenge
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And a content node "triad-remediation" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" updates challenge "triad-challenge" with subject tag "triad-shapes" and pass threshold 70 and remediation target "triad-remediation"
    Then the challenge's remediation target is "triad-remediation"

  Scenario: A teacher enables shuffling on an existing challenge
    Given a challenge "ordered-challenge" exists for content node "intro-to-triads" with exercise shuffling disabled
    And "bob" is authenticated as a teacher
    When "bob" updates challenge "ordered-challenge" with subject tag "triad-shapes", pass threshold 70, shuffled exercises, and shuffled options
    Then the challenge is created with exercise shuffling and option shuffling both enabled

  Scenario: Updating a challenge does not change its linked exercises
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    When "bob" updates challenge "triad-challenge" with subject tag "triad-shapes-revised" and pass threshold 70
    Then the exercise records "triad-challenge" among its linked challenges

  # ── Validation failures — updating ────────────────────────────────────────────

  Scenario: Updating a challenge without a subject tag is rejected
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" submits an update challenge request for "triad-challenge" with the subject_tag field omitted
    Then the request is rejected as invalid
    And the rejection identifies "subject_tag" as the source of the error

  Scenario: Updating a challenge with a pass threshold above 100 is rejected
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" submits an update challenge request for "triad-challenge" with pass_threshold 101
    Then the request is rejected as invalid
    And the rejection identifies "pass_threshold" as the source of the error

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a challenge without a subject tag is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create challenge request with the subject_tag field omitted
    Then the request is rejected as invalid
    And the rejection identifies "subject_tag" as the source of the error

  Scenario: Creating a challenge without a pass threshold is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create challenge request with the pass_threshold field omitted
    Then the request is rejected as invalid
    And the rejection identifies "pass_threshold" as the source of the error

  Scenario: Creating a challenge with a pass threshold of zero is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create challenge request with pass_threshold 0
    Then the request is rejected as invalid
    And the rejection identifies "pass_threshold" as the source of the error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Creating a challenge for a non-existent content node returns not found
    Given "bob" is authenticated as a teacher
    When "bob" creates a challenge for a content node ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Retrieving a challenge that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves a challenge with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Listing challenges for a content node that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" lists the challenges for a content node ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Updating a challenge that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to update a challenge with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a challenge
    Given "alice" is authenticated as a student
    When "alice" attempts to create a challenge for "intro-to-triads"
    Then the request is refused with a forbidden error

  Scenario: A student cannot update a challenge
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" attempts to update challenge "triad-challenge" with subject tag "hijacked-tag"
    Then the request is refused with a forbidden error

  Scenario: Creating a challenge without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a challenge
    Then the request is refused with an authentication error

  Scenario: Listing a node's challenges without an authentication token is refused
    Given a content node "intro-to-triads" exists in the system
    And no authentication token is provided
    When an unauthenticated request attempts to list the challenges for content node "intro-to-triads"
    Then the request is refused with an authentication error

  Scenario: Updating a challenge without an authentication token is refused
    Given a challenge "triad-challenge" exists for content node "intro-to-triads"
    And no authentication token is provided
    When an unauthenticated request attempts to update challenge "triad-challenge" with subject tag "hijacked-tag"
    Then the request is refused with an authentication error
