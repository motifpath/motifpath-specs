# Where a new student should start, and the app settings that hold it (ADR-052, MOT-88).
#
# The team keeps editorial and operational settings in the app's config: one value per key, read and
# replaced by admins through one generic API, and checked by that key's own validator on every write.
# The first key, starting_points, holds lists of the paths and courses a student who has never started
# anything sees first — one list per instrument, experience and language, in order, as many entries as
# the team chooses.
#
# Students read the starting points through their own endpoint. Without a matching list, the catalog
# answers: published paths, then courses, for the instrument and language at the levels the experience
# maps to — never_played → beginner; plays_a_bit → early intermediate or intermediate; plays_well →
# advanced or expert — each ordered by title, at most five in all.

Feature: Curate where a new student should start through the app's settings
  As the MotifPath team
  I want to choose the paths and courses a new student sees first, in order, without a deploy
  So that a student's first lesson is one we picked, not the first title alphabetically

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And an instrument "electric-guitar" exists
    And a learning path "eg-from-zero" exists, published, level "beginner", language "en", for "electric-guitar"
    And a learning path "eg-first-chords" exists, published, level "beginner", language "en", for "electric-guitar"
    And a course "eg-basics" exists, published, level "beginner", language "en", for "electric-guitar"
    And user "ana" is registered as an admin
    And student "carla" is registered in the system

  # ── Happy path: the settings API ───────────────────────────────────────────

  Scenario: An admin lists the app's settings
    Given "ana" is authenticated as an admin
    When "ana" lists the app's settings
    Then the settings include "starting_points", not set yet

  Scenario: An admin sets the starting points and reads them back
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with course "eg-basics" then path "eg-from-zero"
    And "ana" reads the setting "starting_points"
    Then the setting holds that list, with course "eg-basics" then path "eg-from-zero"
    And the setting records "ana" as the last to change it

  Scenario: Setting a value replaces the whole value
    Given "starting_points" holds lists for "electric-guitar", "never_played", "en" and "electric-guitar", "plays_well", "en"
    And "ana" is authenticated as an admin
    When "ana" sets "starting_points" to only the list for "electric-guitar", "never_played", "en"
    Then "starting_points" holds only the list for "electric-guitar", "never_played", "en"

  # ── Happy path: where to start ─────────────────────────────────────────────

  Scenario: A student sees the curated starting points in their order
    Given "starting_points" has a list for "electric-guitar", "never_played", "en" with course "eg-basics" then path "eg-from-zero"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are course "eg-basics" then path "eg-from-zero"
    And the source is "curated"

  Scenario: A curated list shows every entry the team chose
    Given 7 published paths in "en" exist for "electric-guitar"
    And "starting_points" has a list for "electric-guitar", "never_played", "en" with those 7 paths
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then 7 starting points are returned, in the list's order

  Scenario: Without a matching list the catalog answers, paths first, at the experience's levels
    Given "starting_points" has no list for "electric-guitar", "never_played", "en"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are path "eg-first-chords", path "eg-from-zero", then course "eg-basics"
    And the source is "catalog"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A curated entry that is no longer published is skipped
    Given "starting_points" has a list for "electric-guitar", "never_played", "en" with path "eg-from-zero" then course "eg-basics"
    And the course "eg-basics" is retired
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the starting points are path "eg-from-zero" only
    And the source is "curated"

  Scenario: A curated list with nothing still published falls back to the catalog
    Given "starting_points" has a list for "electric-guitar", "never_played", "en" with course "eg-basics"
    And the course "eg-basics" is retired
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then the source is "catalog"

  Scenario: A list is only for its own instrument, experience and language
    Given "starting_points" has a list for "electric-guitar", "never_played", "en" with course "eg-basics"
    When "carla" asks where to start on "electric-guitar", "never_played", "pt_BR"
    Then the source is "catalog"

  Scenario: A curated entry may be at another level than the experience
    Given a course "eg-solos" exists, published, level "intermediate", language "en", for "electric-guitar"
    And "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with course "eg-solos"
    Then the setting is stored

  Scenario: The catalog answer maps "plays a bit" to early intermediate and intermediate
    Given a learning path "eg-riffs" exists, published, level "early_intermediate", language "en", for "electric-guitar"
    And a course "eg-solos" exists, published, level "intermediate", language "en", for "electric-guitar"
    And "starting_points" has no list for "electric-guitar", "plays_a_bit", "en"
    When "carla" asks where to start on "electric-guitar", "plays_a_bit", "en"
    Then the starting points are path "eg-riffs" then course "eg-solos"

  Scenario: The catalog answer shows at most five
    Given 4 more published beginner paths in "en" exist for "electric-guitar"
    And "starting_points" has no list for "electric-guitar", "never_played", "en"
    When "carla" asks where to start on "electric-guitar", "never_played", "en"
    Then 5 starting points are returned, all of them paths

  # ── Failure cases: the value's schema ──────────────────────────────────────

  Scenario Outline: A list missing a required field is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list without "<field>"
    Then the request is rejected with a validation error naming "<field>"
    And "starting_points" is unchanged

    Examples:
      | field         |
      | instrument_id |
      | experience    |
      | language      |
      | items         |

  Scenario: A list with no entries is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with no entries
    Then the request is rejected with a validation error naming the list's items

  Scenario: An unknown experience is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "expert_player", "en" with path "eg-from-zero"
    Then the request is rejected with a validation error naming the list's experience

  Scenario: An entry of an unknown kind is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with an entry of kind "song"
    Then the request is rejected with a validation error naming the entry

  # ── Failure cases: the key's checks ────────────────────────────────────────

  Scenario: Two lists for the same instrument, experience and language are refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to two lists for "electric-guitar", "never_played", "en"
    Then the request is rejected with a validation error naming the second list

  Scenario: A repeated entry within a list is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with path "eg-from-zero" twice
    Then the request is rejected with a validation error naming the repeated entry

  Scenario: An entry that is not a published path or course is refused
    Given "ana" is authenticated as an admin
    And a learning path "eg-draft" exists as a draft
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with path "eg-draft"
    Then the request is rejected with a validation error naming the entry

  Scenario: An entry whose kind does not match its id is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with a course carrying the id of path "eg-from-zero"
    Then the request is rejected with a validation error naming the entry

  Scenario: A list for an instrument that does not exist is refused
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to one list for an instrument that does not exist
    Then the request is rejected with a validation error naming the list's instrument_id

  Scenario: Every problem in a value is reported at once
    Given "ana" is authenticated as an admin
    When "ana" sets "starting_points" to two lists, one without "language" and one with no entries
    Then the request is rejected with a validation error naming both problems

  # ── Failure cases: the API ─────────────────────────────────────────────────

  Scenario: A key the service does not know is not found
    Given "ana" is authenticated as an admin
    When "ana" sets "featured_song" to any value
    Then the request is rejected as not found

  Scenario: A teacher cannot read the app's settings
    Given teacher "bob" is registered and authenticated as a teacher
    When "bob" reads the setting "starting_points"
    Then the request is forbidden

  Scenario: A student cannot change the app's settings
    Given "carla" is authenticated as a student
    When "carla" sets "starting_points" to one list for "electric-guitar", "never_played", "en" with path "eg-from-zero"
    Then the request is forbidden

  Scenario: Asking where to start with an unknown experience is rejected
    When "carla" asks where to start on "electric-guitar", "expert_player", "en"
    Then the request is rejected with a validation error
