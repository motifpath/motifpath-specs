Feature: Browse the path catalog
  As a learner
  I want to find published learning paths by what they teach and who made them
  So that I can go straight to a path that interests me, without taking a whole course

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And student "alice" is registered in the system

  # ── Listing ────────────────────────────────────────────────────────────────

  @wip
  Scenario: The path catalog only includes published paths
    Given a learning path "open-chords-path" exists, published
    And a learning path "strumming-path" exists as a draft
    And "alice" is authenticated as a student
    When "alice" lists the path catalog
    Then the response includes "open-chords-path"
    And the response does not include "strumming-path"

  @wip
  Scenario: A teacher browses the path catalog like any learner, without their own drafts
    Given a learning path "open-chords-path" exists as a draft, created by "bob"
    And a learning path "strumming-path" exists, published, created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists the path catalog
    Then the response includes "strumming-path"
    And the response does not include "open-chords-path"

  @wip
  Scenario: A catalog entry tells a learner what the path is and how much it contains
    Given a learning path "open-chords-path" exists, published, created by "bob", with 3 lessons, a summary, language "en" and level "beginner"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog
    Then the entry for "open-chords-path" reports its title, summary, language "en", level "beginner" and 3 lessons
    And the entry for "open-chords-path" records "bob" as the creator
    And the entry for "open-chords-path" does not include any item's content_node_id

  @wip
  Scenario: The path catalog is paginated
    Given 45 learning paths exist, published
    And "alice" is authenticated as a student
    When "alice" lists the path catalog with limit 20 and offset 40
    Then the response contains 5 items ordered by title
    And the response reports a total of 45, a limit of 20, and an offset of 40

  @wip
  Scenario: A learner with nothing published to browse gets an empty catalog
    Given a learning path "open-chords-path" exists as a draft
    And "alice" is authenticated as a student
    When "alice" lists the path catalog
    Then the response is an empty page with a total of 0

  # ── Filtering ──────────────────────────────────────────────────────────────

  @wip
  Scenario: A learner searches the path catalog by title or summary text
    Given a learning path "open-chords-path" exists, published, titled "Open Chords"
    And a learning path "strumming-path" exists, published, titled "Strumming Patterns"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog matching text "chords"
    Then the response includes "open-chords-path"
    And the response does not include "strumming-path"

  @wip
  Scenario: A learner filters the path catalog by several levels
    Given learning paths exist, published, at levels "beginner", "intermediate" and "expert"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by levels "beginner", "intermediate"
    Then the response includes the "beginner" and "intermediate" paths
    And the response does not include the "expert" path

  @wip
  Scenario: A learner narrows the path catalog to paths in one language
    Given a learning path "open-chords-path" exists, published in language "en"
    And a learning path "acordes-abertos" exists, published in language "pt_BR"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by language "pt_BR"
    Then the response includes "acordes-abertos"
    And the response does not include "open-chords-path"

  @wip
  Scenario: A learner filters the path catalog by creator
    Given a learning path "open-chords-path" exists, published, created by "bob"
    And a learning path "strumming-path" exists, published, created by "carol"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by creator "bob"
    Then the response includes "open-chords-path"
    And the response does not include "strumming-path"

  @wip
  Scenario: A learner filters the path catalog by skill
    Given a learning path "open-chords-path" exists, published, with a content node classified with skill "fingerpicking"
    And a learning path "strumming-path" exists, published
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by skill "fingerpicking"
    Then the response includes "open-chords-path"
    And the response does not include "strumming-path"

  @wip
  Scenario: A path matches a skill and concept filter only when one of its nodes has both
    Given a learning path "open-chords-path" exists, published, with a content node classified with skill "fingerpicking" and concept "triads"
    And a learning path "strumming-path" exists, published, with one content node classified with skill "fingerpicking" and another with concept "triads"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by skill "fingerpicking" and concept "triads"
    Then the response includes "open-chords-path"
    And the response does not include "strumming-path"

  @wip
  Scenario: The path catalog's instrument filter keeps paths that suit every instrument
    Given a learning path "guitar-path" exists, published, for instrument "guitar"
    And a learning path "ukulele-path" exists, published, for instrument "ukulele"
    And a learning path "theory-path" exists, published, for every instrument
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by instrument "guitar"
    Then the response includes "guitar-path" and "theory-path"
    And the response does not include "ukulele-path"

  @wip
  Scenario: Path catalog filters narrow the total, not just the page
    Given 30 learning paths exist, published, at level "beginner" and 30 at level "expert"
    And "alice" is authenticated as a student
    When "alice" lists the path catalog filtered by level "beginner" with limit 10
    Then the response contains 10 items
    And the response reports a total of 30

  @wip
  Scenario: An out-of-range path catalog page size is rejected
    Given "alice" is authenticated as a student
    When "alice" lists the path catalog with limit 101
    Then the request is refused with a validation error

  # ── Detail ─────────────────────────────────────────────────────────────────

  @wip
  Scenario: A learner sees a published path as a title-only outline grouped by section
    Given a learning path "open-chords-path" exists, published, with lessons "E major" and "A major" in section "Open chords" and "Strum in 4/4" in section "Strumming"
    And "alice" is authenticated as a student
    When "alice" retrieves catalog path "open-chords-path"
    Then the response lists the lesson titles "E major", "A major" and "Strum in 4/4" in order, each with its section
    And the response does not include any item's lesson content or content_node_id

  @wip
  Scenario: A published path's detail names its creator and reports its scope
    Given a learning path "open-chords-path" exists, published, created by "bob", with 3 lessons
    And "alice" is authenticated as a student
    When "alice" retrieves catalog path "open-chords-path"
    Then the response identifies "bob" as the path creator
    And the response reports 3 lessons

  @wip
  Scenario: A draft path's catalog detail is not found, even for its author
    Given a learning path "open-chords-path" exists as a draft, created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" retrieves catalog path "open-chords-path"
    Then the request is refused with a not-found error

  @wip
  Scenario: Retrieving a catalog path that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves a catalog path ID that does not exist
    Then the request is refused with a not-found error

  # ── Creators ───────────────────────────────────────────────────────────────

  @wip
  Scenario: A learner lists the creators of published paths only
    Given a learning path "open-chords-path" exists, published, created by "bob"
    And a learning path "strumming-path" exists, published, created by "carol"
    And a learning path "theory-path" exists as a draft, created by "dave"
    And "alice" is authenticated as a student
    When "alice" lists the path creators
    Then the creators returned are "bob" and "carol", each with their display name
    And the creators returned do not include "dave"

  @wip
  Scenario: A creator with several published paths is listed once
    Given a learning path "open-chords-path" exists, published, created by "bob"
    And a learning path "strumming-path" exists, published, created by "bob"
    And "alice" is authenticated as a student
    When "alice" lists the path creators
    Then the creators returned are "bob", each with their display name

  @wip
  Scenario: Path creators are ordered by name ignoring case and accents
    Given learning paths exist, published, created by "Zé", "álvaro" and "Bruna"
    And "alice" is authenticated as a student
    When "alice" lists the path creators
    Then the creators returned are "álvaro", "Bruna" and "Zé", in that order

  @wip
  Scenario: A learner narrows the path creators by name, ignoring case and accents
    Given learning paths exist, published, created by "José" and "Bruna"
    And "alice" is authenticated as a student
    When "alice" lists the path creators matching "jose"
    Then the creators returned are "José", each with their display name

  # ── Authentication ─────────────────────────────────────────────────────────

  @wip
  Scenario: Browsing the path catalog without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list the path catalog
    Then the request is refused with an authentication error

  @wip
  Scenario: Listing path creators without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list the path creators
    Then the request is refused with an authentication error
