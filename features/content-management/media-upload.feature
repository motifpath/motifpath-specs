Feature: Request a presigned media upload URL
  As the MotifPath platform
  I want teachers and admins to request a presigned URL for uploading
  content-authoring media
  So that exercise/prompt images and audio, the shared image-picker
  library, thumbnails and lesson videos can be stored without proxying file
  bytes through this service

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # File sizes: 1 MB = 1,048,576 bytes, so 1024 MB is the 1 GB (1,073,741,824-byte) video limit.

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

  @wip
  Scenario: A teacher requests an upload URL for a lesson's video
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "open-chords-lesson.mp4" and file size 980 MB
    Then a presigned upload URL is returned
    And the response includes the object's read URL and an expiry time
    And the upload URL only accepts a file of exactly 980 MB

  @wip
  Scenario: A video of exactly 1 GB is accepted
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "long-lesson.mp4" and file size 1024 MB
    Then a presigned upload URL is returned

  @wip
  Scenario: The .mp4 extension is matched in any case
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "OPEN-CHORDS.MP4" and file size 300 MB
    Then a presigned upload URL is returned

  # ── Validation failures ────────────────────────────────────────────────────

  @wip
  Scenario: A video over 1 GB is rejected before anything is uploaded
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "long-lesson.mp4" and file size 1025 MB
    Then the request is rejected as invalid
    And the rejection identifies "file_size" as the source of the error

  @wip
  Scenario: A video without a declared file size is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "open-chords-lesson.mp4" and no file size
    Then the request is rejected as invalid
    And the rejection identifies "file_size" as the source of the error

  @wip
  Scenario Outline: A video that is not an MP4 is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "video", file name "<file_name>" and file size 300 MB
    Then the request is rejected as invalid
    And the rejection identifies "file_name" as the source of the error

    Examples:
      | file_name        |
      | lesson.mov       |
      | lesson.webm      |
      | lesson.mp4.zip   |

  @wip
  Scenario: A video for any purpose other than lesson_video is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "library_asset" with content type "video", file name "open-chords-lesson.mp4" and file size 300 MB
    Then the request is rejected as invalid
    And the rejection identifies "content_type" as the source of the error

  @wip
  Scenario: A lesson_video upload that is not a video is rejected
    Given "bob" is authenticated as a teacher
    When "bob" requests a media upload URL for purpose "lesson_video" with content type "image" and file name "poster.png"
    Then the request is rejected as invalid
    And the rejection identifies "content_type" as the source of the error

  @wip
  Scenario: Requesting a lesson_video upload URL with an exercise_id is rejected
    Given "bob" is authenticated as a teacher
    And an exercise "triad-exercise-01" exists
    When "bob" requests a media upload URL for purpose "lesson_video" on exercise "triad-exercise-01" with content type "video", file name "clip.mp4" and file size 50 MB
    Then the request is rejected as invalid
    And the rejection identifies "exercise_id" as the source of the error


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
