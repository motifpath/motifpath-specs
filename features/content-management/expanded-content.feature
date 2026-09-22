Feature: Manage expanded content
  As the MotifPath platform
  I want teachers and admins to attach expositive media items to content nodes
  So that students see supporting images and GIFs at the right moment during
  video lessons and article reading

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Video content node — happy path ────────────────────────────────────────

  Scenario: A teacher adds an image to a video lesson at a specific timestamp
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds an image to "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    Then the expanded content item is created and assigned a stable identifier
    And the item records "intro-to-triads" as its parent content node

  Scenario: A teacher adds a GIF to a video lesson
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds a GIF to "intro-to-triads" with trigger_at_seconds 90 and hide_at_seconds 100
    Then the expanded content item is created and assigned a stable identifier

  Scenario: A teacher adds multiple expanded content items to a video lesson
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds three images to "intro-to-triads" at different timestamps
    Then three distinct expanded content identifiers are returned

  Scenario: Listing expanded content for a video node returns items ordered by trigger timestamp
    Given a video content node "intro-to-triads" has expanded content items at seconds 90, 150, and 210
    And "alice" is authenticated as a student
    When "alice" lists the expanded content for "intro-to-triads"
    Then the items are returned ordered by trigger_at_seconds ascending

  # ── Article content node — happy path ──────────────────────────────────────

  Scenario: A teacher adds an image to an article at a specific paragraph
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" adds an image to "chord-theory-explained" with trigger_at_paragraph 3 and duration_ms 8000
    Then the expanded content item is created and assigned a stable identifier

  Scenario: A teacher adds a GIF to an article at the first paragraph
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" adds a GIF to "chord-theory-explained" with trigger_at_paragraph 1 and duration_ms 5000
    Then the expanded content item is created and assigned a stable identifier

  Scenario: Listing expanded content for an article returns items ordered by paragraph
    Given an article content node "chord-theory-explained" has expanded content at paragraphs 1, 3, and 7
    And "alice" is authenticated as a student
    When "alice" lists the expanded content for "chord-theory-explained"
    Then the items are returned ordered by trigger_at_paragraph ascending

  Scenario: Any authenticated user retrieves a specific expanded content item by ID
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" retrieves the expanded content item "triad-diagram"
    Then the response returns the item's type, media URL, trigger, and hide fields

  # ── Rich text content — happy path ────────────────────────────────────────────

  Scenario: A teacher adds rich text content to a video lesson at a specific timestamp
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds rich text content to "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    Then the expanded content item is created and assigned a stable identifier
    And the item's content_type is "rich_text"

  Scenario: A teacher adds rich text content to an article at a specific paragraph
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" adds rich text content to "chord-theory-explained" with trigger_at_paragraph 2 and duration_ms 6000
    Then the expanded content item is created and assigned a stable identifier
    And the item's content_type is "rich_text"

  Scenario: Rich text expanded content may embed a video or audio track
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds rich text content containing an embedded video to "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    Then the expanded content item is created and assigned a stable identifier
    And the item's rich content contains a video node

  # ── Diagram content — happy path ──────────────────────────────────────────────

  @wip

  Scenario: A teacher adds a diagram to a video lesson at a specific timestamp
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds diagram "minor-pentatonic-guitar" to "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    Then the expanded content item is created and assigned a stable identifier
    And the item's content_type is "diagram"

  @wip

  Scenario: A teacher adds a stack of two diagrams to an article at a specific paragraph
    Given a diagram "c-major-scale-guitar" exists on instrument "guitar"
    And a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" adds a stack of diagrams "c-major-scale-guitar, minor-pentatonic-guitar" to "chord-theory-explained" with trigger_at_paragraph 3 and duration_ms 8000
    Then the expanded content item is created and assigned a stable identifier
    And the item's diagram stack has 2 layers

  # ── Diagram content — validation failures ─────────────────────────────────────

  @wip

  Scenario: Adding a diagram stack from two different instruments is rejected
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And a diagram "minor-pentatonic-piano" exists on instrument "piano"
    And "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" adds a stack of diagrams "minor-pentatonic-guitar, minor-pentatonic-piano" to "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    Then the request is rejected as invalid
    And the rejection identifies "diagram_stack_ref" as the source of the error

  @wip

  Scenario: Creating a diagram expanded content item without a diagram reference is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with content_type "diagram" and both diagram_ref and diagram_stack_ref omitted
    Then the request is rejected as invalid
    And the rejection identifies "diagram_ref" as the source of the error

  @wip

  Scenario: Creating a diagram expanded content item that also carries a media URL is rejected
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with content_type "diagram" carrying both media_url and a diagram_ref to "minor-pentatonic-guitar"
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  # ── Happy path — updating and deleting ────────────────────────────────────────

  Scenario: A teacher updates an expanded content item's timing and caption
    Given an expanded content item "triad-diagram" exists for "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    And "bob" is authenticated as a teacher
    When "bob" updates expanded content item "triad-diagram" with trigger_at_seconds 160 and hide_at_seconds 180 and caption "Updated timing"
    Then the item's trigger_at_seconds is 160
    And the item's hide_at_seconds is 180
    And the item's caption is "Updated timing"

  Scenario: A teacher updates an article expanded content item's paragraph and duration
    Given an expanded content item "tuning-diagram" exists for "chord-theory-explained" at paragraph 1
    And "bob" is authenticated as a teacher
    When "bob" updates expanded content item "tuning-diagram" with trigger_at_paragraph 2 and duration_ms 6000
    Then the item's trigger_at_paragraph is 2
    And the item's duration_ms is 6000

  Scenario: A teacher deletes an expanded content item
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" deletes expanded content item "triad-diagram"
    Then retrieving expanded content item "triad-diagram" returns not found

  # ── Validation failures — updating ────────────────────────────────────────────

  Scenario: Updating a video expanded content item with an inconsistent hide time is rejected
    Given an expanded content item "triad-diagram" exists for "intro-to-triads" with trigger_at_seconds 150 and hide_at_seconds 165
    And "bob" is authenticated as a teacher
    When "bob" submits an update expanded content request for "triad-diagram" with trigger_at_seconds 150 and hide_at_seconds 150
    Then the request is rejected as invalid
    And the rejection identifies "hide_at_seconds" as the source of the error

  Scenario: Updating an expanded content item without a media URL is rejected
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And "bob" is authenticated as a teacher
    When "bob" submits an update expanded content request for "triad-diagram" with the media_url field omitted
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  # ── Validation failures — missing required fields ──────────────────────────

  Scenario: Creating an expanded content item without a content type is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with the content_type field omitted
    Then the request is rejected as invalid
    And the rejection identifies "content_type" as the source of the error

  Scenario: Creating an image expanded content item without a media URL is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with the media_url field omitted
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  Scenario: Creating a rich_text expanded content item without rich content is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with content_type "rich_text" and the rich_content field omitted
    Then the request is rejected as invalid
    And the rejection identifies "rich_content" as the source of the error

  Scenario: Creating an image expanded content item that also carries rich content is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with content_type "image" carrying both media_url and rich_content
    Then the request is rejected as invalid
    And the rejection identifies "rich_content" as the source of the error

  Scenario: Creating a rich_text expanded content item that also carries a media URL is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with content_type "rich_text" carrying both media_url and rich_content
    Then the request is rejected as invalid
    And the rejection identifies "media_url" as the source of the error

  # ── Validation failures — video trigger/hide rules ─────────────────────────

  Scenario: Adding expanded content to a video node without trigger_at_seconds is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with trigger_at_paragraph 3 and duration_ms 5000 for a video content node
    Then the request is rejected as invalid
    And the rejection identifies "trigger_at_seconds" as the source of the error

  Scenario: Adding expanded content to a video node where hide_at_seconds is not greater than trigger_at_seconds is rejected
    Given "bob" is authenticated as a teacher
    And a video content node "intro-to-triads" exists in the system
    When "bob" submits a create expanded content request with trigger_at_seconds 150 and hide_at_seconds 150
    Then the request is rejected as invalid
    And the rejection identifies "hide_at_seconds" as the source of the error

  # ── Validation failures — article trigger/hide rules ──────────────────────

  Scenario: Adding expanded content to an article node without trigger_at_paragraph is rejected
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" submits a create expanded content request with trigger_at_seconds 90 and hide_at_seconds 100 for an article content node
    Then the request is rejected as invalid
    And the rejection identifies "trigger_at_paragraph" as the source of the error

  Scenario: Adding expanded content to an article node with trigger_at_paragraph zero is rejected
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" submits a create expanded content request with trigger_at_paragraph 0
    Then the request is rejected as invalid
    And the rejection identifies "trigger_at_paragraph" as the source of the error

  Scenario: Adding expanded content to an article node without duration_ms is rejected
    Given "bob" is authenticated as a teacher
    And an article content node "chord-theory-explained" exists in the system
    When "bob" submits a create expanded content request with trigger_at_paragraph 3 and duration_ms omitted
    Then the request is rejected as invalid
    And the rejection identifies "duration_ms" as the source of the error

  # ── Not found ──────────────────────────────────────────────────────────────

  Scenario: Adding expanded content to a non-existent content node returns not found
    Given "bob" is authenticated as a teacher
    When "bob" adds expanded content to a content node ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Retrieving an expanded content item that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves an expanded content item with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Updating an expanded content item that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to update an expanded content item with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Deleting an expanded content item that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to delete an expanded content item with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot add expanded content to a content node
    Given "alice" is authenticated as a student
    And a video content node "intro-to-triads" exists in the system
    When "alice" attempts to add expanded content to "intro-to-triads"
    Then the request is refused with a forbidden error

  Scenario: A student cannot update an expanded content item
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" attempts to update expanded content item "triad-diagram" with caption "Hijacked caption"
    Then the request is refused with a forbidden error

  Scenario: A student cannot delete an expanded content item
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And "alice" is authenticated as a student
    When "alice" attempts to delete expanded content item "triad-diagram"
    Then the request is refused with a forbidden error

  Scenario: Adding expanded content without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to add expanded content
    Then the request is refused with an authentication error

  Scenario: Updating expanded content without an authentication token is refused
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And no authentication token is provided
    When an unauthenticated request attempts to update expanded content item "triad-diagram" with caption "Hijacked caption"
    Then the request is refused with an authentication error

  Scenario: Deleting expanded content without an authentication token is refused
    Given an expanded content item "triad-diagram" exists for "intro-to-triads"
    And no authentication token is provided
    When an unauthenticated request attempts to delete expanded content item "triad-diagram"
    Then the request is refused with an authentication error
