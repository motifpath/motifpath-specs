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

  Scenario: Creating an exercise without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create an exercise
    Then the request is refused with an authentication error
