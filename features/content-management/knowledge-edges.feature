Feature: Link knowledge nodes
  As the MotifPath team
  I want admins to record which concepts a skill uses and what each node needs, and how well
  So that practice, recommendations and readiness can follow the knowledge graph without ever locking a student out

  # applies: a skill uses a concept (skill → concept only, no level).
  # requires: a node needs another at a mastery level — accurate, fluent or
  # retained — between any two nodes, skills and concepts alike. requires edges
  # never form a cycle. They inform practice and recommendations; they never
  # gate content. applies never implies requires.

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a root skill "improvise-over-a-blues" exists in the system
    And a root skill "play-pentatonic-positions" exists in the system
    And a root concept "blues-form" exists in the system
    And a root concept "minor-pentatonic-scale" exists in the system

  # ── Happy path ───────────────────────────────────────────────────────────────

  Scenario: An admin records that a skill applies a concept
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to concept "blues-form" with "applies"
    Then the knowledge edge is created and assigned a stable identifier
    And the knowledge edge's type is "applies"
    And the knowledge edge has no level

  Scenario: An admin records that a skill requires another skill at a level
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to skill "play-pentatonic-positions" with "requires" at level "fluent"
    Then the knowledge edge is created and assigned a stable identifier
    And the knowledge edge's type is "requires"
    And the knowledge edge's level is "fluent"

  Scenario Outline: requires links any kind of node to any kind
    Given "admin" is authenticated as an admin
    When "admin" links <from> to <to> with "requires" at level "accurate"
    Then the knowledge edge is created and assigned a stable identifier

    Examples:
      | from                             | to                                  |
      | skill "improvise-over-a-blues"   | concept "blues-form"                |
      | concept "blues-form"             | concept "minor-pentatonic-scale"    |
      | concept "minor-pentatonic-scale" | skill "play-pentatonic-positions"   |

  Scenario: A skill may both apply a concept and require it at a level
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to concept "blues-form" with "requires" at level "fluent"
    Then the knowledge edge is created and assigned a stable identifier

  Scenario: An admin changes the level a requires edge asks for
    Given skill "improvise-over-a-blues" requires skill "play-pentatonic-positions" at level "accurate"
    And "admin" is authenticated as an admin
    When "admin" changes that requires edge to level "fluent"
    Then the knowledge edge's level is "fluent"

  Scenario: An admin deletes an edge
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "admin" is authenticated as an admin
    When "admin" deletes that knowledge edge
    Then the knowledge edge is deleted
    And concept "blues-form" can now be deleted

  Scenario: A student lists the requires edges leaving a node
    Given skill "improvise-over-a-blues" requires skill "play-pentatonic-positions" at level "fluent"
    And skill "improvise-over-a-blues" applies concept "blues-form"
    And "alice" is authenticated as a student
    When "alice" lists the "requires" edges from skill "improvise-over-a-blues"
    Then the response includes a "requires" edge to skill "play-pentatonic-positions" at level "fluent"
    And the response does not include an "applies" edge

  Scenario: A teacher lists the edges arriving at a node
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "bob" is authenticated as a teacher
    When "bob" lists the edges to concept "blues-form"
    Then the response includes an "applies" edge from skill "improvise-over-a-blues"

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: applies from a concept to a skill is rejected
    Given "admin" is authenticated as an admin
    When "admin" links concept "blues-form" to skill "improvise-over-a-blues" with "applies"
    Then the request is rejected as invalid
    And the rejection identifies "type" as the source of the error

  Scenario: applies between two skills is rejected
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to skill "play-pentatonic-positions" with "applies"
    Then the request is rejected as invalid
    And the rejection identifies "type" as the source of the error

  Scenario: applies with a level is rejected
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to concept "blues-form" with "applies" at level "fluent"
    Then the request is rejected as invalid
    And the rejection identifies "level" as the source of the error

  Scenario: requires without a level is rejected
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to skill "play-pentatonic-positions" with "requires"
    Then the request is rejected as invalid
    And the rejection identifies "level" as the source of the error

  Scenario: A node cannot be linked to itself
    Given "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to skill "improvise-over-a-blues" with "requires" at level "accurate"
    Then the request is rejected as invalid
    And the rejection identifies "to_id" as the source of the error

  Scenario: Linking to a node that does not exist is rejected
    Given "admin" is authenticated as an admin
    When "admin" submits a create knowledge edge request whose to_id does not exist
    Then the request is rejected as invalid
    And the rejection identifies "to_id" as the source of the error

  Scenario: Giving an applies edge a level is rejected
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "admin" is authenticated as an admin
    When "admin" changes that applies edge to level "fluent"
    Then the request is rejected as invalid
    And the rejection identifies "level" as the source of the error

  # ── Conflicts ──────────────────────────────────────────────────────────────

  Scenario: Creating the same edge twice is refused
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "admin" is authenticated as an admin
    When "admin" links skill "improvise-over-a-blues" to concept "blues-form" with "applies"
    Then the request is refused with a conflict error

  Scenario: A requires edge that closes a direct cycle is refused
    Given skill "improvise-over-a-blues" requires skill "play-pentatonic-positions" at level "fluent"
    And "admin" is authenticated as an admin
    When "admin" links skill "play-pentatonic-positions" to skill "improvise-over-a-blues" with "requires" at level "accurate"
    Then the request is refused with a conflict error

  Scenario: A requires edge that closes a longer cycle across kinds is refused
    Given skill "improvise-over-a-blues" requires skill "play-pentatonic-positions" at level "fluent"
    And skill "play-pentatonic-positions" requires concept "minor-pentatonic-scale" at level "accurate"
    And "admin" is authenticated as an admin
    When "admin" links concept "minor-pentatonic-scale" to skill "improvise-over-a-blues" with "requires" at level "accurate"
    Then the request is refused with a conflict error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A teacher cannot create a knowledge edge
    Given "bob" is authenticated as a teacher
    When "bob" links skill "improvise-over-a-blues" to concept "blues-form" with "applies"
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot change a requires edge's level
    Given skill "improvise-over-a-blues" requires skill "play-pentatonic-positions" at level "accurate"
    And "bob" is authenticated as a teacher
    When "bob" changes that requires edge to level "fluent"
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot delete a knowledge edge
    Given skill "improvise-over-a-blues" applies concept "blues-form"
    And "bob" is authenticated as a teacher
    When "bob" deletes that knowledge edge
    Then the request is refused with a forbidden error

  Scenario: Listing knowledge edges without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list knowledge edges
    Then the request is refused with an authentication error
