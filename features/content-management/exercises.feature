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
      | audio_selection   | Pick the pentatonic lick       | Which of these recordings is a minor pentatonic lick? |

  Scenario: A teacher creates an exercise with skills and concepts
    Given "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Alternate picking — descending run" with prompt "Play the descending run cleanly" and one correct option and skills "alternate_picking, technique" and concepts "right-hand-technique"
    Then the exercise is created and assigned a stable identifier
    And the exercise carries skills "alternate_picking, technique"
    And the exercise carries concepts "right-hand-technique"

  # ── Happy path — diagram-driven exercises ─────────────────────────────────────

  Scenario: A teacher creates an image_recognition exercise from a diagram, with no hand-drawn regions
    Given a diagram "minor-pentatonic-guitar" exists on instrument "guitar" with positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
      | R        | A         | 4      | 7    |
      | b3       | C         | 6      | 8    |
    And "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Tap every root note" with prompt "Tap every root note in this pattern" from diagram "minor-pentatonic-guitar" showing only interval "R" as the correct answer
    Then the exercise is created and assigned a stable identifier
    And the exercise's options are derived from diagram "minor-pentatonic-guitar"
    And the exercise has 2 options, one per visible root position
    And every option derived from the diagram is marked correct

  Scenario: A teacher creates an image_choice exercise whose options are diagram thumbnails
    Given a diagram "c-major-scale-guitar" exists on instrument "guitar"
    And a diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" creates an image_choice exercise titled "Which diagram is the minor pentatonic scale?" with prompt "Pick the minor pentatonic scale" and options rendered from diagrams "c-major-scale-guitar, minor-pentatonic-guitar" with "minor-pentatonic-guitar" correct
    Then the exercise is created and assigned a stable identifier
    And the exercise has 2 options
    And the option rendered from diagram "minor-pentatonic-guitar" is marked correct

  Scenario: A teacher creates an exercise with a richly formatted prompt
    Given "bob" is authenticated as a teacher
    When "bob" creates a text_response exercise titled "Circle of fifths" with a prompt formatted as a heading, a bulleted list, a table, and an image, and one correct option
    Then the exercise is created and assigned a stable identifier
    And the exercise's prompt preserves its heading, bulleted list, table, and image structure

  Scenario: A teacher creates an exercise with a prompt using a custom font color and background color
    Given "bob" is authenticated as a teacher
    When "bob" creates a text_response exercise titled "Circle of fifths" with a prompt whose text has a custom font color and background color, and one correct option
    Then the exercise is created and assigned a stable identifier
    And the exercise's prompt preserves its font color and background color

  Scenario: A teacher creates an exercise with a plain, unformatted prompt
    Given "bob" is authenticated as a teacher
    When "bob" creates a text_response exercise titled "Name the note" with a prompt containing a single unformatted paragraph and one correct option
    Then the exercise is created and assigned a stable identifier

  Scenario: Any authenticated user retrieves an exercise by ID
    Given an exercise "triad-exercise-01" exists
    And "alice" is authenticated as a student
    When "alice" retrieves the exercise "triad-exercise-01"
    Then the response returns the exercise's title, prompt, type, options, and linked challenges

  # ── Happy path — listing exercises for authoring ─────────────────────────────

  Scenario: A teacher lists all exercises in the reusable pool
    Given an exercise "triad-exercise-01" exists
    And an exercise "picking-drill-01" exists
    And "bob" is authenticated as a teacher
    When "bob" lists all exercises
    Then the response includes "triad-exercise-01" and "picking-drill-01"

  Scenario: An admin lists all exercises in the reusable pool
    Given an exercise "triad-exercise-01" exists
    And "admin" is authenticated as an admin
    When "admin" lists all exercises
    Then the response includes "triad-exercise-01"

  Scenario: A teacher filters the exercise list by skill
    Given an exercise "triad-exercise-01" exists with skills "triad-shapes"
    And an exercise "picking-drill-01" exists with skills "alternate_picking"
    And "bob" is authenticated as a teacher
    When "bob" lists exercises filtered by skill "alternate_picking"
    Then the response includes "picking-drill-01"
    And the response does not include "triad-exercise-01"

  Scenario: A teacher filters the exercise list by exercise type
    Given an exercise "triad-exercise-01" exists with type image_recognition
    And an exercise "chord-name-01" exists with type text_response
    And "bob" is authenticated as a teacher
    When "bob" lists exercises filtered by exercise_type "text_response"
    Then the response includes "chord-name-01"
    And the response does not include "triad-exercise-01"

  Scenario: Listing exercises when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all exercises
    Then the response is an empty list

  # ── Happy path — updating an exercise ─────────────────────────────────────────

  Scenario: A teacher updates an exercise's title, prompt, and options
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" updates exercise "triad-exercise-01" with title "Root position, revised" and prompt "Identify the root position, now with a cleaner prompt" and one correct option
    Then the exercise's title is "Root position, revised"
    And the exercise's prompt is "Identify the root position, now with a cleaner prompt"

  Scenario: A teacher updates an exercise's prompt to add formatting it previously lacked
    Given an exercise "triad-exercise-01" exists with a plain, unformatted prompt
    And "bob" is authenticated as a teacher
    When "bob" updates exercise "triad-exercise-01" with a prompt formatted as bold text and a bulleted list, and one correct option
    Then the exercise's prompt preserves its bold text and bulleted list structure

  Scenario: A teacher replaces an exercise's skills
    Given an exercise "picking-drill-01" exists with skills "alternate_picking"
    And "bob" is authenticated as a teacher
    When "bob" updates exercise "picking-drill-01" with skills "hybrid_picking, technique"
    Then the exercise carries skills "hybrid_picking, technique"
    And the exercise no longer carries skill "alternate_picking"

  Scenario: Updating an exercise does not change its links to challenges or content nodes
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    And "bob" has linked exercise "triad-exercise-01" to "triad-challenge"
    When "bob" updates exercise "triad-exercise-01" with title "Root position, revised"
    Then the exercise records "triad-challenge" among its linked challenges

  # ── Happy path — remediation targets ──────────────────────────────────────────

  Scenario: A teacher creates an exercise with an internal remediation target
    Given a content node "triad-remediation" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Root position of a C major triad" with prompt "Identify the root position of a C major triad" and one correct option and a remediation target that is content node "triad-remediation"
    Then the exercise records one remediation target
    And that remediation target is content node "triad-remediation"

  Scenario: A teacher creates an exercise with inline rich-content remediation
    Given "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Root position of a C major triad" with prompt "Identify the root position of a C major triad" and one correct option and a remediation target with rich content and caption "Watch this if the shape felt unfamiliar"
    Then the exercise records one remediation target
    And that remediation target carries rich content with caption "Watch this if the shape felt unfamiliar"

  Scenario: A teacher creates an exercise with multiple remediation targets in priority order
    Given a content node "triad-remediation" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" creates an image_recognition exercise titled "Root position of a C major triad" with prompt "Identify the root position of a C major triad" and one correct option and remediation targets in order: content node "triad-remediation", then rich content with caption "Or read this instead"
    Then the exercise records 2 remediation targets in that order

  Scenario: A teacher replaces an exercise's remediation targets
    Given an exercise "triad-exercise-01" exists with a remediation target that is content node "triad-remediation"
    And a content node "picking-fundamentals" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" updates exercise "triad-exercise-01" with a remediation target that is content node "picking-fundamentals"
    Then the exercise records one remediation target
    And that remediation target is content node "picking-fundamentals"

  Scenario: A teacher clears an exercise's remediation targets
    Given an exercise "triad-exercise-01" exists with a remediation target that is content node "triad-remediation"
    And "bob" is authenticated as a teacher
    When "bob" updates exercise "triad-exercise-01" with the remediation_targets field omitted
    Then the exercise records no remediation targets

  # ── Validation failures — remediation targets ─────────────────────────────────

  Scenario: Creating an exercise with a remediation target carrying both a content node and rich content is rejected
    Given a content node "triad-remediation" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with a remediation target carrying both content_node_id and rich_content
    Then the request is rejected as invalid
    And the rejection identifies "remediation_targets" as the source of the error

  Scenario: Creating an exercise with a remediation target carrying neither a content node nor rich content is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with a remediation target carrying neither content_node_id nor rich_content
    Then the request is rejected as invalid
    And the rejection identifies "remediation_targets" as the source of the error

  Scenario: Creating an exercise with a remediation target referencing a non-existent content node is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates an exercise with a remediation target referencing a content node ID that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "remediation_targets" as the source of the error

  # ── Validation failures — updating ────────────────────────────────────────────

  Scenario: Updating an exercise without a title is rejected
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" submits an update exercise request for "triad-exercise-01" with the title field omitted
    Then the request is rejected as invalid
    And the rejection identifies "title" as the source of the error

  Scenario: Updating an exercise with zero correct options is rejected
    Given an exercise "triad-exercise-01" exists
    And "bob" is authenticated as a teacher
    When "bob" submits an update exercise request for "triad-exercise-01" whose options have no option marked correct
    Then the request is rejected as invalid
    And the rejection identifies "options" as the source of the error

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

  Scenario: Creating an exercise with no skills is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with an empty skills list
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating an exercise with no concepts is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with an empty concepts list
    Then the request is rejected as invalid
    And the rejection identifies "concept_ids" as the source of the error

  Scenario: Creating an exercise with a skill id that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request with a skill id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating an exercise with an unstructured prompt is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request whose prompt is a plain string instead of a structured document
    Then the request is rejected as invalid
    And the rejection identifies "prompt" as the source of the error

  Scenario: Creating an exercise with a prompt using an unsupported node type is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create exercise request whose prompt document contains a footnote node
    Then the request is rejected as invalid
    And the rejection identifies "prompt" as the source of the error

  # ── Not found — creation and retrieval ───────────────────────────────────────

  Scenario: Retrieving an exercise that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves an exercise with an ID that does not exist
    Then the request is refused with a not-found error

  Scenario: Updating an exercise that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" attempts to update an exercise with an ID that does not exist
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

  Scenario: A student starts a practice session for a skill with enough linked exercises
    Given 12 exercises linked to skill "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill "alternate_picking" with count 10
    Then the practice session contains 10 exercises
    And every exercise in the practice session is linked to skill "alternate_picking"
    And the practice session is assigned a stable practice_session_id

  Scenario: A practice session returns fewer exercises when the linked pool is smaller than requested
    Given 3 exercises linked to skill "hybrid_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill "hybrid_picking" with count 10
    Then the practice session contains 3 exercises

  Scenario: A practice session defaults its count when none is given
    Given 12 exercises linked to skill "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts a practice session for skill "alternate_picking" without specifying a count
    Then the practice session contains 10 exercises

  Scenario: Two practice sessions for the same skill may differ in composition and order
    Given 12 exercises linked to skill "alternate_picking" exist in the system
    And "alice" is authenticated as a student
    When "alice" starts two practice sessions for skill "alternate_picking" with count 10
    Then the two practice sessions are assigned different practice_session_ids

  # ── Validation failures — practice sessions ───────────────────────────────────

  Scenario: Starting a practice session without a skill is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a start practice session request with the skill_id field omitted
    Then the request is rejected as invalid
    And the rejection identifies "skill_id" as the source of the error

  Scenario: Starting a practice session with a count above the maximum is rejected
    Given "alice" is authenticated as a student
    When "alice" submits a start practice session request with skill "alternate_picking" and count 51
    Then the request is rejected as invalid
    And the rejection identifies "count" as the source of the error

  Scenario: Starting a practice session for a skill with no matching exercises returns an empty session
    Given "alice" is authenticated as a student
    When "alice" starts a practice session for skill "nonexistent-skill" with count 10
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

  Scenario: A student cannot list all exercises
    Given "alice" is authenticated as a student
    When "alice" attempts to list all exercises
    Then the request is refused with a forbidden error

  Scenario: A student cannot update an exercise
    Given an exercise "triad-exercise-01" exists
    And "alice" is authenticated as a student
    When "alice" attempts to update exercise "triad-exercise-01" with title "Hijacked title"
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
    When an unauthenticated request attempts to start a practice session for skill "alternate_picking"
    Then the request is refused with an authentication error

  Scenario: Listing exercises without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all exercises
    Then the request is refused with an authentication error

  Scenario: Updating an exercise without an authentication token is refused
    Given an exercise "triad-exercise-01" exists
    And no authentication token is provided
    When an unauthenticated request attempts to update exercise "triad-exercise-01" with title "Hijacked title"
    Then the request is refused with an authentication error
