Feature: Manage exercises
  As the MotifPath platform
  I want teachers and admins to author standalone, reusable exercises and link
  them into challenges
  So that the same exercise can be practiced from any number of challenges,
  students can complete practice interactions, and the SPA can reference
  exercises by their stable IDs in tracking events

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a content node "intro-to-triads" exists in the system
    And a challenge "triad-challenge" exists for content node "intro-to-triads"

  # ── Happy path — creation ────────────────────────────────────────────────────

  Scenario: A teacher creates a standalone image_recognition exercise
    Given "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Root position of a C major triad" with prompt "Identify the root position of a C major triad" and one correct option
    Then the exercise is created and assigned a stable identifier
    And the exercise is not linked to any challenge

  Scenario: An admin creates an exercise
    Given "admin" is authenticated as an admin
    When "admin" creates a text_response exercise titled "Name the interval" with prompt "Name the interval between the open low E and the 5th fret" and one correct option
    Then the exercise is created and assigned a stable identifier

  Scenario Outline: A teacher creates an exercise of each committed type
    Given "bob" is authenticated as a teacher
    When "bob" creates a <exercise_type> exercise titled "<title>" with prompt "<prompt>" and one correct option
    Then the exercise is created and assigned a stable identifier
    And the exercise's type is recorded as <exercise_type>

    Examples:
      | exercise_type     | title                          | prompt                                                |
      | text_response     | Name the chord                 | Name this chord shape                                 |
      | audio_recognition | Identify the interval by ear   | Listen and identify the interval                      |
      | image_recognition | Root position of a C triad     | Identify the root position of a C major triad         |
      | image_choice      | Pick the E minor chord diagram | Which of these chord-shape diagrams is E minor?       |

  Scenario: A teacher creates an exercise with skill tags
    Given "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Alternate picking — descending run" with prompt "Play the descending run cleanly" and one correct option and skill tags "alternate_picking, technique"
    Then the exercise is created and assigned a stable identifier
    And the exercise carries skill tags "alternate_picking, technique"

  Scenario: Any authenticated user retrieves an exercise by ID
    Given an exercise "triad-exercise-01" exists
    And "alice" is authenticated as a student
    When "alice" retrieves the exercise "triad-exercise-01"
    Then the response returns the exercise's title, prompt, type, options, and linked challenges

  # ── Validation failures — creation ───────────────────────────────────────────

  Scenario: Creating an exercise without a title is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Creating an exercise without a prompt is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with the prompt field omitted
    Then the request is rejected as invalid
    And the rejection identifies "prompt" as the source of the error

  Scenario: Creating an exercise without an exercise type is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with the exercise_type field omitted
    Then the request is rejected as invalid
    And the rejection identifies "exercise_type" as the source of the error

  Scenario: Creating an exercise with an unrecognised type is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with exercise_type "multiple_choice"
    Then the request is rejected as invalid
    And the rejection identifies "exercise_type" as the source of the error

  Scenario: Creating an exercise with zero correct options is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request whose options have no option marked correct
    Then the request is rejected as invalid
    And the rejection identifies "options" as the source of the error

  Scenario: Creating an exercise with an empty-string skill tag is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with an empty-string skill tag
    Then the request is rejected as invalid
    And the rejection identifies "skill_tags" as the source of the error

  # ── Not found — creation and retrieval ───────────────────────────────────────

  Scenario: Retrieving an exercise that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves an exercise with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Happy path — linking and unlinking ───────────────────────────────────────

  Scenario: A teacher links an existing exercise into a challenge
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" links exercise "triad-exercise-01" to "triad-challenge"
    Then the exercise records "triad-challenge" among its linked challenges

  Scenario: The same exercise is linked into a second challenge without duplication
    Given an exercise "triad-exercise-01" exists
    And a challenge "inversions-challenge" exists for content node "intro-to-triads"
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    When "bob" links exercise "triad-exercise-01" to "inversions-challenge"
    Then the exercise records both "triad-challenge" and "inversions-challenge" among its linked challenges
    And exactly one exercise "triad-exercise-01" exists in the system

  Scenario: A teacher unlinks an exercise from a challenge
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    When "bob" unlinks exercise "triad-exercise-01" from "triad-challenge"
    Then the exercise no longer records "triad-challenge" among its linked challenges

  # ── Happy path — listing a challenge's exercises ─────────────────────────────

  Scenario: A student lists the exercises linked to a challenge
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    And "alice" is authenticated as a student
    When "alice" lists the exercises for challenge "triad-challenge"
    Then the response includes "triad-exercise-01"
    And each returned exercise's options report whether they are correct

  Scenario: A student lists the exercises for a challenge with none linked
    Given "alice" is authenticated as a student
    When "alice" lists the exercises for challenge "triad-challenge"
    Then the response is an empty list

  Scenario: A challenge with shuffling disabled always returns exercises in link order
    Given a challenge "ordered-challenge" exists for content node "intro-to-triads" with exercise shuffling disabled
    And 3 exercises are linked to "ordered-challenge" in a known order
    And "alice" is authenticated as a student
    When "alice" lists the exercises for challenge "ordered-challenge" twice
    Then both responses return the exercises in the same, link order

  Scenario: A challenge with shuffling enabled may vary exercise and option order across requests
    Given a challenge "shuffled-challenge" exists for content node "intro-to-triads" with exercise shuffling and option shuffling enabled
    And 5 exercises are linked to "shuffled-challenge" in a known order
    And "alice" is authenticated as a student
    When "alice" lists the exercises for challenge "shuffled-challenge" twice
    Then both responses return the same set of exercises
    But the two responses are not required to return them in the same order

  # ── Happy path — path exercises (content node linking) ───────────────────────

  Scenario: A teacher links an existing exercise into a content node as a path exercise
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" links exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    Then the exercise records "intro-to-triads" among its linked content nodes

  Scenario: An exercise can be a path exercise on a node and linked to a challenge at the same time
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    When "bob" links exercise "triad-exercise-01" to "triad-challenge"
    Then the exercise records "intro-to-triads" among its linked content nodes
    And the exercise records "triad-challenge" among its linked challenges

  Scenario: A teacher unlinks a path exercise from a content node
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    When "bob" unlinks exercise "triad-exercise-01" from content node "intro-to-triads"
    Then the exercise no longer records "intro-to-triads" among its linked content nodes

  Scenario: A student lists the path exercises for a node that has some, always in link order
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    And "alice" is authenticated as a student
    When "alice" lists the path exercises for content node "intro-to-triads" twice
    Then both responses include "triad-exercise-01"
    And both responses return the path exercises in the same, link order

  Scenario: A student lists the path exercises for a node that has none
    Given "alice" is authenticated as a student
    When "alice" lists the path exercises for content node "intro-to-triads"
    Then the response is an empty list

  # ── Conflict — path-exercise linking ──────────────────────────────────────────

  Scenario: Linking an exercise that is already a path exercise on the node is rejected
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    When "bob" links exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    Then the request is refused with a conflict error

  # ── Not found — path-exercise linking and unlinking ───────────────────────────

  Scenario: Linking a non-existent exercise to a content node as a path exercise returns not found
    Given "bob" is authenticated as a teacher
    When "bob" links an exercise ID that does not exist to content node "intro-to-triads" as a path exercise
    Then the request is refused with a not-found error

  Scenario: Linking an exercise as a path exercise to a non-existent content node returns not found
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" links exercise "triad-exercise-01" to a content node ID that does not exist as a path exercise
    Then the request is refused with a not-found error

  Scenario: Unlinking a path exercise that is not linked to the node returns not found
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" unlinks exercise "triad-exercise-01" from content node "intro-to-triads"
    Then the request is refused with a not-found error

  Scenario: Listing path exercises for a content node that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" lists the path exercises for a content node ID that does not exist
    Then the request is refused with a not-found error

  # ── Happy path — practice sessions ────────────────────────────────────────────

  Scenario: A student starts a practice session for a skill with enough tagged exercises
    Given 12 exercises tagged "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill tag "alternate_picking" with count 10
    Then the practice session contains 10 exercises
    And every exercise in the practice session is tagged "alternate_picking"
    And the practice session is assigned a stable practice_session_id

  Scenario: A practice session returns fewer exercises when the tagged pool is smaller than requested
    Given 3 exercises tagged "hybrid_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill tag "hybrid_picking" with count 10
    Then the practice session contains 3 exercises

  Scenario: A practice session defaults its count when none is given
    Given 12 exercises tagged "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill tag "alternate_picking" without specifying a count
    Then the practice session contains 10 exercises

  Scenario: Two practice sessions for the same skill tag may differ in composition and order
    Given 12 exercises tagged "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts two practice sessions for skill tag "alternate_picking" with count 10
    Then the two practice sessions are assigned different practice_session_ids

  # ── Validation failures — practice sessions ───────────────────────────────────

  Scenario: Starting a practice session without a skill tag is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a start practice session request with the skill_tag field omitted
    Then the request is rejected as invalid
    And the rejection identifies "skill_tag" as the source of the error

  Scenario: Starting a practice session with a count above the maximum is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a start practice session request with skill_tag "alternate_picking" and count 51
    Then the request is rejected as invalid
    And the rejection identifies "count" as the source of the error

  Scenario: Starting a practice session for a skill tag with no matching exercises returns an empty session
    Given "alice" is authenticated as a student
    When "alice" starts a practice session for skill tag "nonexistent-skill" with count 10
    Then the practice session contains 0 exercises

  # ── Conflict — linking ───────────────────────────────────────────────────────

  Scenario: Linking an exercise that is already linked to the challenge is rejected
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    When "bob" links exercise "triad-exercise-01" to "triad-challenge"
    Then the request is refused with a conflict error

  # ── Not found — linking and unlinking ────────────────────────────────────────

  Scenario: Linking a non-existent exercise to a challenge returns not found
    Given "bob" is authenticated as a teacher
    When "bob" links an exercise ID that does not exist to "triad-challenge"
    Then the request is refused with a not-found error

  Scenario: Linking an exercise to a non-existent challenge returns not found
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" links exercise "triad-exercise-01" to a challenge ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Unlinking an exercise that is not linked to the challenge returns not found
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" unlinks exercise "triad-exercise-01" from "triad-challenge"
    Then the request is refused with a not-found error

  Scenario: Listing exercises for a challenge that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" lists the exercises for a challenge ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ────────────────────────────────────────────────────

  Scenario: A student cannot create an exercise
    Given "alice" is authenticated as a student
    When "alice" attempts to create an exercise
    Then the request is refused with a forbidden error

  Scenario: A student cannot link an exercise to a challenge
    Given an exercise "triad-exercise-01" exists
    And "alice" is authenticated as a student
    When "alice" attempts to link exercise "triad-exercise-01" to "triad-challenge"
    Then the request is refused with a forbidden error

  Scenario: A student cannot unlink an exercise from a challenge
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    And "alice" is authenticated as a student
    When "alice" attempts to unlink exercise "triad-exercise-01" from "triad-challenge"
    Then the request is refused with a forbidden error

  Scenario: A student cannot link an exercise to a content node as a path exercise
    Given an exercise "triad-exercise-01" exists
    And "alice" is authenticated as a student
    When "alice" attempts to link exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    Then the request is refused with a forbidden error

  Scenario: A student cannot unlink a path exercise from a content node
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to content node "intro-to-triads" as a path exercise
    And "alice" is authenticated as a student
    When "alice" attempts to unlink exercise "triad-exercise-01" from content node "intro-to-triads"
    Then the request is refused with a forbidden error

  Scenario: Creating an exercise without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create an exercise
    Then the request is refused with an authentication error

  Scenario: Listing a challenge's exercises without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list the exercises for challenge "triad-challenge"
    Then the request is refused with an authentication error

  Scenario: Linking a path exercise without an authentication token is refused
    Given a content node "intro-to-triads" exists in the system
    And no authentication token is provided
    When an unauthenticated request attempts to link an exercise to content node "intro-to-triads" as a path exercise
    Then the request is refused with an authentication error

  Scenario: Listing a node's path exercises without an authentication token is refused
    Given a content node "intro-to-triads" exists in the system
    And no authentication token is provided
    When an unauthenticated request attempts to list the path exercises for content node "intro-to-triads"
    Then the request is refused with an authentication error

  Scenario: Starting a practice session without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to start a practice session for skill tag "alternate_picking"
    Then the request is refused with an authentication error
