Feature: Request a presigned media upload URL
  As the MotifPath platform
  I want teachers and admins to request a presigned URL for uploading
  content-authoring media
  So that exercise/prompt images and audio, and the shared image-picker
  library, can be stored without proxying file bytes through this service

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A teacher requests an upload URL for an exercise asset
    Given "bob" is authenticated as a teacher
    And an exercise "triad-exercise-01" exists
    When "bob" requests a media upload URL for purpose "exercise_asset" on exercise "triad-exercise-01" with content type "image" and file name "diagram.png"
    Then a presigned upload URL is returned
    And the response includes the object's read URL and an expiry time

  Scenario: An admin requests an upload URL for the predefined image library
    Given "admin" is authenticated as an admin
    When "admin" requests a media upload URL for purpose "library_asset" with content type "image" and file name "c-major-scale.png"
    Then a presigned upload URL is returned
    And the response includes the object's read URL and an expiry time

  Scenario: A teacher requests an upload URL for a thumbnail
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "thumbnail" with content type "image" and file name "open-chords.png"
    Then a presigned upload URL is returned
    And the response includes the object's read URL and an expiry time

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Requesting a thumbnail upload URL for audio is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "thumbnail" with content type "audio" and file name "intro.mp3"
    Then the request is refused with a validation error

  Scenario: Requesting a thumbnail upload URL with an exercise_id is rejected
    Given "bob" is authenticated as a teacher
    And an exercise "triad-exercise-01" exists
    When "bob" requests a media upload URL for purpose "thumbnail" on exercise "triad-exercise-01" with content type "image" and file name "cover.png"
    Then the request is refused with a validation error

  Scenario: Requesting an exercise_asset upload URL without an exercise_id is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "exercise_asset" with content type "image" and file name "diagram.png" and no exercise ID
    Then the request is rejected as invalid
    And the rejection identifies "exercise_id" as the source of the error

  Scenario: Requesting an upload URL without a content type is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a media upload URL request with the content_type field omitted
    Then the request is rejected as invalid
    And the rejection identifies "content_type" as the source of the error

  # ── Not found ─────────────────────────────────────────────────────────────

  Scenario: Requesting an exercise_asset upload URL for a non-existent exercise returns not found
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "exercise_asset" on an exercise ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot request a media upload URL
    Given "alice" is authenticated as a student
    When "alice" attempts to request a media upload URL for purpose "library_asset"
    Then the request is refused with a forbidden error

  Scenario: Requesting a media upload URL without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to request a media upload URL
    Then the request is refused with an authentication error
