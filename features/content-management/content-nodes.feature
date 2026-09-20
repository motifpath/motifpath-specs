Feature: Manage content nodes
  As the MotifPath platform
  I want teachers and admins to create content nodes with classification
  So that students have structured lessons to follow on their learning path

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher creates a video content node with classification
    Given "bob" is authenticated as a teacher
    When "bob" creates a video content node titled "Introduction to Triad Shapes" with media url "https://cdn.motifpath.io/videos/triad-shapes-intro.mp4", skill "triad-shapes", concept "chord-theory", and difficulty "beginner"
    Then the content node is created and assigned a stable identifier
    And the classification review state is "pending"
    And the content node records "bob" as the owner
    And the content node's media url is "https://cdn.motifpath.io/videos/triad-shapes-intro.mp4"

  Scenario: A teacher creates an article content node
    Given "bob" is authenticated as a teacher
    When "bob" creates an article content node titled "Understanding Chord Theory" with article body "Chord theory explains how notes combine into triads.", skill "chord-transitions", concept "chord-theory", and difficulty "intermediate"
    Then the content node is created and assigned a stable identifier

  Scenario: An admin creates a content node
    Given "admin" is authenticated as an admin
    When "admin" creates a video content node titled "Sweep Picking Fundamentals" with media url "https://cdn.motifpath.io/videos/sweep-picking.mp4", skill "sweep-picking", concept "technique", and difficulty "advanced"
    Then the content node is created and assigned a stable identifier

  Scenario: Any authenticated user retrieves a content node by ID
    Given a content node "intro-to-triads" exists in the system
    And "alice" is authenticated as a student
    When "alice" retrieves the content node "intro-to-triads"
    Then the response returns the content node's title, type, and classification

  # ── Happy path — listing content nodes for authoring ─────────────────────────

  Scenario: A teacher lists all content nodes in the library
    Given a content node "intro-to-triads" exists in the system
    And a content node "sweep-picking-basics" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists all content nodes
    Then the response includes "intro-to-triads" and "sweep-picking-basics"

  Scenario: An admin lists all content nodes in the library
    Given a content node "intro-to-triads" exists in the system
    And "admin" is authenticated as an admin
    When "admin" lists all content nodes
    Then the response includes "intro-to-triads"

  Scenario: A teacher filters the content node list by content type
    Given a video content node "intro-to-triads" exists in the system
    And an article content node "chord-theory-article" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists content nodes filtered by content_type "article"
    Then the response includes "chord-theory-article"
    And the response does not include "intro-to-triads"

  Scenario: A teacher filters the content node list by skill
    Given a content node "intro-to-triads" exists in the system with skill "triad-shapes"
    And a content node "sweep-picking-basics" exists in the system with skill "sweep-picking"
    And "bob" is authenticated as a teacher
    When "bob" lists content nodes filtered by skill "sweep-picking"
    Then the response includes "sweep-picking-basics"
    And the response does not include "intro-to-triads"

  Scenario: Listing content nodes when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all content nodes
    Then the response is an empty list

  # ── Happy path — updating a content node ──────────────────────────────────────

  Scenario: A teacher updates a content node's title and classification
    Given a content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" updates content node "intro-to-triads" with title "Introduction to Triad Shapes, revised" and skill "triad-shapes", concept "chord-theory", and difficulty "intermediate"
    Then the content node's title is "Introduction to Triad Shapes, revised"
    And the content node's classification difficulty is "intermediate"

  Scenario: Updating a content node does not change its content type
    Given a video content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" updates content node "intro-to-triads" with title "Introduction to Triad Shapes, revised"
    Then the content node's type is still "video"

  Scenario: Updating a content node does not reset an admin-confirmed review state
    Given a content node "intro-to-triads" exists in the system
    And an admin has confirmed the classification of content node "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" updates content node "intro-to-triads" with title "Introduction to Triad Shapes, revised"
    Then the classification review state is still "confirmed"

  # ── Validation failures — updating ────────────────────────────────────────────

  Scenario: Updating a content node without a title is rejected
    Given a content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" submits an update content node request for "intro-to-triads" with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Updating a content node without classification is rejected
    Given a content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" submits an update content node request for "intro-to-triads" with the classification field omitted
    Then the request is rejected as invalid
    And the rejection identifies "classification" as the source of the error

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a content node without a title is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Creating a content node without classification is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with the classification field omitted
    Then the request is rejected as invalid
    And the rejection identifies "classification" as the source of the error

  Scenario: Creating a content node with an unrecognised difficulty level is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with difficulty level "expert"
    Then the request is rejected as invalid
    And the rejection identifies "difficulty_level" as the source of the error

  Scenario: Creating a video content node without a media url is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create video content node request with the media_url field omitted
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  Scenario: Creating an article content node without an article body is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create article content node request with the rich_content field omitted
    Then the request is rejected as invalid
    And the rejection identifies "rich_content" as the source of the error

  Scenario: Creating a video content node with an article body is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create video content node request carrying rich_content
    Then the request is rejected as invalid
    And the rejection identifies "rich_content" as the source of the error

  Scenario: Creating an article content node with a media url is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create article content node request carrying media_url
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  # ── Not found ──────────────────────────────────────────────────────────────

  Scenario: Retrieving a content node that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves a content node with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Updating a content node that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to update a content node with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a content node
    Given "alice" is authenticated as a student
    When "alice" attempts to create a content node
    Then the request is refused with a forbidden error

  Scenario: A student cannot list all content nodes
    Given "alice" is authenticated as a student
    When "alice" attempts to list all content nodes
    Then the request is refused with a forbidden error

  Scenario: A student cannot update a content node
    Given a content node "intro-to-triads" exists in the system
    And "alice" is authenticated as a student
    When "alice" attempts to update content node "intro-to-triads" with title "Hijacked title"
    Then the request is refused with a forbidden error

  Scenario: Creating a content node without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a content node
    Then the request is refused with an authentication error

  Scenario: Listing content nodes without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all content nodes
    Then the request is refused with an authentication error

  Scenario: Updating a content node without an authentication token is refused
    Given a content node "intro-to-triads" exists in the system
    And no authentication token is provided
    When an unauthenticated request attempts to update content node "intro-to-triads" with title "Hijacked title"
    Then the request is refused with an authentication error
