Feature: Manage content nodes
  As the MotifPath platform
  I want teachers and admins to create content nodes with classification
  So that students have structured lessons to follow on their learning path

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher creates a video content node with classification
    Given "bob" is authenticated as a teacher
    When "bob" creates a video content node titled "Introduction to Triad Shapes" with media url "https://cdn.motifpath.io/videos/triad-shapes-intro.mp4", skills "triad-shapes", concepts "chord-theory", and difficulty "beginner"
    Then the content node is created and assigned a stable identifier
    And the classification review state is "pending"
    And the content node records "bob" as the owner
    And the content node's media url is "https://cdn.motifpath.io/videos/triad-shapes-intro.mp4"

  Scenario: A teacher creates a content node classified under multiple skills and concepts
    Given "bob" is authenticated as a teacher
    When "bob" creates a video content node titled "Right-Hand Technique Basics" with skills "alternate-picking, string-muting", concepts "right-hand-technique", and difficulty "beginner"
    Then the content node is created and assigned a stable identifier
    And the content node's classification carries skills "alternate-picking, string-muting"

  Scenario: A teacher creates an article content node
    Given "bob" is authenticated as a teacher
    When "bob" creates an article content node titled "Understanding Chord Theory" with article body "Chord theory explains how notes combine into triads.", skills "chord-transitions", concepts "chord-theory", and difficulty "intermediate"
    Then the content node is created and assigned a stable identifier

  Scenario: An admin creates a content node
    Given "admin" is authenticated as an admin
    When "admin" creates a video content node titled "Sweep Picking Fundamentals" with media url "https://cdn.motifpath.io/videos/sweep-picking.mp4", skills "sweep-picking", concepts "technique", and difficulty "advanced"
    Then the content node is created and assigned a stable identifier

  Scenario: Any authenticated user retrieves a content node by ID
    Given a content node "intro-to-triads" exists in the system
    And "alice" is authenticated as a student
    When "alice" retrieves the content node "intro-to-triads"
    Then the response returns the content node's title, type, and classification

  # ── Happy path — inline diagram embeds ────────────────────────────────────────

  Scenario: A teacher creates an article content node with an inline diagram embed
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" creates an article content node titled "Understanding the Minor Pentatonic" with article body containing an inline diagram embed of "minor-pentatonic-guitar", skills "minor-pentatonic-scale", concepts "scale-construction", and difficulty "beginner"
    Then the content node is created and assigned a stable identifier
    And the content node's rich content contains a diagram node

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
    Given a content node "intro-to-triads" exists in the system with skills "triad-shapes"
    And a content node "sweep-picking-basics" exists in the system with skills "sweep-picking"
    And "bob" is authenticated as a teacher
    When "bob" lists content nodes filtered by skill "sweep-picking"
    Then the response includes "sweep-picking-basics"
    And the response does not include "intro-to-triads"

  Scenario: A teacher filters the content node list by concept
    Given a content node "intro-to-triads" exists in the system with concepts "chord-theory"
    And a content node "sweep-picking-basics" exists in the system with concepts "technique"
    And "bob" is authenticated as a teacher
    When "bob" lists content nodes filtered by concept "technique"
    Then the response includes "sweep-picking-basics"
    And the response does not include "intro-to-triads"

  Scenario: A content node with multiple skills is returned by a filter matching any one of them
    Given a content node "right-hand-basics" exists in the system with skills "alternate-picking, string-muting"
    And "bob" is authenticated as a teacher
    When "bob" lists content nodes filtered by skill "string-muting"
    Then the response includes "right-hand-basics"

  Scenario: Listing content nodes when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all content nodes
    Then the response is an empty list

  # ── Happy path — updating a content node ──────────────────────────────────────

  Scenario: A teacher updates a content node's title and classification
    Given a content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" updates content node "intro-to-triads" with title "Introduction to Triad Shapes, revised" and skills "triad-shapes", concepts "chord-theory", and difficulty "intermediate"
    Then the content node's title is "Introduction to Triad Shapes, revised"
    And the content node's classification difficulty is "intermediate"

  Scenario: A teacher adds a second skill to a content node's classification
    Given a content node "intro-to-triads" exists in the system with skills "triad-shapes"
    And "bob" is authenticated as a teacher
    When "bob" updates content node "intro-to-triads" with skills "triad-shapes, chord-transitions"
    Then the content node's classification carries skills "triad-shapes, chord-transitions"

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

  Scenario: Updating a video content node with a media url that is not an http or https URL is rejected
    Given a video content node "intro-to-triads" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" submits an update content node request for "intro-to-triads" with media url "javascript:alert(1)"
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

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
    When "bob" submits a create content node request with difficulty level "master"
    Then the request is rejected as invalid
    And the rejection identifies "difficulty_level" as the source of the error

  @wip

  Scenario: Creating a content node with content_type "diagram" is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with content_type "diagram"
    Then the request is rejected as invalid
    And the rejection identifies "content_type" as the source of the error

  Scenario: Creating a video content node without a media url is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create video content node request with the media_url field omitted
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  Scenario Outline: Creating a video content node with a media url that is not an http or https URL is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create video content node request with media url "<media_url>"
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

    Examples:
      | media_url                        |
      | not a url                        |
      | /videos/lesson.mp4               |
      | javascript:alert(1)              |
      | ftp://cdn.example.com/lesson.mp4 |

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

  Scenario: Creating a content node with no skills is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with an empty skills list
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating a content node with no concepts is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with an empty concepts list
    Then the request is rejected as invalid
    And the rejection identifies "concept_ids" as the source of the error

  Scenario: Creating a content node with a skill id that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with a skill id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating a content node with a concept id that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create content node request with a concept id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "concept_ids" as the source of the error

  Scenario: A content node can be classified at a specific leaf skill rather than its root
    Given a root skill "guitar-technique" exists in the system
    And a skill "alternate-picking" exists under skill "guitar-technique"
    And "bob" is authenticated as a teacher
    When "bob" creates a video content node titled "Alternate Picking Drills" with skills "alternate-picking", concepts "chord-theory", and difficulty "intermediate"
    Then the content node is created and assigned a stable identifier
    And the content node's classification carries skills "alternate-picking"

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

  # ── Pagination and search ─────────────────────────────────────────────────

  Scenario: The content node list is paginated
    Given "bob" is authenticated as a teacher
    And 45 content nodes exist in the library
    When "bob" lists content nodes with no paging parameters
    Then the response contains 20 items ordered by title
    And the response reports a total of 45, a limit of 20, and an offset of 0

  Scenario: A teacher requests a later page of content nodes
    Given "bob" is authenticated as a teacher
    And 45 content nodes exist in the library
    When "bob" lists content nodes with limit 20 and offset 40
    Then the response contains 5 items
    And the response reports a total of 45

  Scenario: An offset past the end returns an empty page
    Given "bob" is authenticated as a teacher
    And 3 content nodes exist in the library
    When "bob" lists content nodes with limit 20 and offset 100
    Then the response contains 0 items
    And the response reports a total of 3

  Scenario: A teacher searches content nodes by title text
    Given "bob" is authenticated as a teacher
    And content nodes titled "Open Chords", "Barre Chords" and "Scales" exist
    When "bob" lists content nodes matching text "chords"
    Then the response includes "Open Chords" and "Barre Chords"
    And the response does not include "Scales"

  Scenario: Search and filters combine with paging
    Given "bob" is authenticated as a teacher
    And 30 article content nodes and 30 video content nodes titled "Chords N" exist
    When "bob" lists content nodes of type "article" matching text "chords" with limit 10
    Then the response contains 10 items
    And the response reports a total of 30

  Scenario Outline: An out-of-range page size or offset is rejected
    Given "bob" is authenticated as a teacher
    When "bob" lists content nodes with limit <limit> and offset <offset>
    Then the request is refused with a validation error

    Examples:
      | limit | offset |
      | 0     | 0      |
      | 101   | 0      |
      | 20    | -1     |
