# Where a new student should start (ADR-052, MOT-88).
#
# The team chooses, per instrument, experience and language, up to five published paths and courses
# a student who has never started anything sees first, in order. Without a list, the catalog answers:
# published paths, then courses, for the instrument and language at the levels the experience maps
# to — never_played → beginner; plays_a_bit → early intermediate or intermediate; plays_well →
# advanced or expert — each ordered by title, at most five in all.

@wip
Feature: Curate where a new student should start
  As the MotifPath team
  I want to choose the paths and courses a new student sees first, in order
  So that a student's first lesson is one we picked, not the first title alphabetically

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And an instrument "electric-guitar" exists
    And a learning path "eg-from-zero" exists, published, level "beginner", language "en", for "electric-guitar"
    And a learning path "eg-first-chords" exists, published, level "beginner", language "en", for "electric-guitar"
    And a course "eg-basics" exists, published, level "beginner", language "en", for "electric-guitar"
    And user "ana" is registered as an admin
    And student "carla" is registered in the system

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: An admin sets the starting points and a student sees them in that order
    Given "ana" is authenticated as an admin
    And "ana" sets the starting points for "electric-guitar", "never_played", "en" to course "eg-basics" then path "eg-from-zero"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are course "eg-basics" then path "eg-from-zero"
    And the source is "curated"

  Scenario: Setting the starting points replaces the list before
    Given "ana" is authenticated as an admin
    And the starting points for "electric-guitar", "never_played", "en" are path "eg-from-zero"
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to path "eg-first-chords"
    Then the starting points for "electric-guitar", "never_played", "en" are path "eg-first-chords" only

  Scenario: Setting the starting points records who set them
    Given "ana" is authenticated as an admin
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to path "eg-from-zero"
    Then the starting points for "electric-guitar", "never_played", "en" record "ana" as the last to change them

  Scenario: Without a list the catalog answers, paths first, at the experience's levels
    Given no starting points are set for "electric-guitar", "never_played", "en"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are path "eg-first-chords", path "eg-from-zero", then course "eg-basics"
    And the source is "catalog"

  Scenario: Clearing the list brings back the catalog answer
    Given "ana" is authenticated as an admin
    And the starting points for "electric-guitar", "never_played", "en" are path "eg-from-zero"
    When "ana" clears the starting points for "electric-guitar", "never_played", "en"
    Then asking where to start on "electric-guitar", "never_played", "en" answers from the catalog

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A curated entry that is no longer published is skipped
    Given the starting points for "electric-guitar", "never_played", "en" are path "eg-from-zero" then course "eg-basics"
    And the course "eg-basics" is retired
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are path "eg-from-zero" only
    And the source is "curated"

  Scenario: A curated list with nothing still published falls back to the catalog
    Given the starting points for "electric-guitar", "never_played", "en" are course "eg-basics"
    And the course "eg-basics" is retired
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the source is "catalog"

  Scenario: A list is only for its own instrument, experience and language
    Given the starting points for "electric-guitar", "never_played", "en" are course "eg-basics"
    When "carla" asks where to start on "electric-guitar", "never_played", "pt-BR"
    Then the source is "catalog"

  Scenario: The catalog answer maps "plays a bit" to early intermediate and intermediate
    Given a learning path "eg-riffs" exists, published, level "early_intermediate", language "en", for "electric-guitar"
    And a course "eg-solos" exists, published, level "intermediate", language "en", for "electric-guitar"
    And no starting points are set for "electric-guitar", "plays_a_bit", "en"
    When "carla" asks where to start on "electric-guitar", "plays_a_bit", "en"
    Then the starting points are path "eg-riffs" then course "eg-solos"

  Scenario: The catalog answer shows at most five
    Given 4 more published beginner paths in "en" exist for "electric-guitar"
    And no starting points are set for "electric-guitar", "never_played", "en"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then 5 starting points are returned, all of them paths

  Scenario: A curated entry may be at another level than the experience
    Given "ana" is authenticated as an admin
    And a course "eg-solos" exists, published, level "intermediate", language "en", for "electric-guitar"
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to course "eg-solos"
    Then the starting points for "electric-guitar", "never_played", "en" are course "eg-solos" only

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: More than five entries are refused
    Given "ana" is authenticated as an admin
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to 6 entries
    Then the request is rejected with a validation error
    And the starting points for "electric-guitar", "never_played", "en" are unchanged

  Scenario: A repeated entry is refused
    Given "ana" is authenticated as an admin
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to path "eg-from-zero" twice
    Then the request is rejected with a validation error

  Scenario: An entry that is not a published path or course is refused
    Given "ana" is authenticated as an admin
    And a learning path "eg-draft" exists as a draft
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to path "eg-draft"
    Then the request is rejected with a validation error naming the entry

  Scenario: An entry whose kind does not match its id is refused
    Given "ana" is authenticated as an admin
    When "ana" sets the starting points for "electric-guitar", "never_played", "en" to a course with the id of path "eg-from-zero"
    Then the request is rejected with a validation error naming the entry

  Scenario: A teacher cannot set the starting points
    Given teacher "bob" is registered and authenticated as a teacher
    When "bob" sets the starting points for "electric-guitar", "never_played", "en" to path "eg-from-zero"
    Then the request is forbidden

  Scenario: A student cannot clear the starting points
    Given "carla" is authenticated as a student
    When "carla" clears the starting points for "electric-guitar", "never_played", "en"
    Then the request is forbidden

  Scenario: Setting starting points for an unknown instrument is refused
    Given "ana" is authenticated as an admin
    When "ana" sets the starting points for an instrument that does not exist
    Then the request is rejected as not found

  Scenario: Asking where to start with an unknown experience is rejected
    When "carla" asks where to start on "electric-guitar", "expert_player", "en"
    Then the request is rejected with a validation error
