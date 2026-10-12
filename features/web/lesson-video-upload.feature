# Uploading a video lesson's video (MOT-19, ADR-054).
#
# The lesson editor's Video field: a VideoSource card above the link field. The pattern is
# design/patterns/authoring.md ("Lesson video"); the Figma page is "Authoring", row 15 (15a–15f).
# What the server accepts (purpose lesson_video, MP4 only, at most 1 GB) is in
# features/content-management/media-upload.feature.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: Upload the video of a video lesson
  As a teacher authoring a video lesson
  I want to upload the lesson's MP4 from the editor
  So that I don't have to host it anywhere else first

  Background:
    Given "bob" is signed in as a teacher
    And "bob" is editing the video lesson "Open chords: G, C, D"

  # ── Choosing a file ───────────────────────────────────────────────────────

  Scenario: A lesson without a video offers an upload and a link
    Given the lesson has no video yet
    Then the Video field shows "Upload a video" with "MP4 (H.264) · up to 1 GB"
    And a field labelled "Or paste a link" is shown under it

  Scenario: A file that is not an MP4 is refused before anything is sent
    When "bob" chooses the file "lesson.mov"
    Then the card says "lesson.mov can’t be uploaded" and asks for an MP4 (H.264) of up to 1 GB
    And nothing is uploaded

  Scenario: A file over 1 GB is refused before anything is sent
    When "bob" chooses the file "long-lesson.mp4" of 1.4 GB
    Then the card says the file is 1.4 GB and the limit is 1 GB
    And nothing is uploaded

  # ── Uploading ─────────────────────────────────────────────────────────────

  Scenario: The upload shows its progress
    When "bob" chooses the file "open-chords-lesson.mp4" of 980 MB
    And 490 MB have been sent
    Then the card shows "open-chords-lesson.mp4", "490 of 980 MB · 50%" and a progress bar at half
    And the link field is hidden

  Scenario: Cancelling an upload goes back to choosing a file
    Given "open-chords-lesson.mp4" is uploading
    When "bob" cancels the upload
    Then the upload stops
    And the Video field shows "Upload a video" and the link field again

  Scenario: Save waits for the upload to finish
    Given "open-chords-lesson.mp4" is uploading
    When "bob" saves the lesson
    Then the lesson is saved once the upload has finished
    And its video is the uploaded file

  Scenario: Leaving during an upload asks first
    Given "open-chords-lesson.mp4" is uploading
    When "bob" goes back to the lesson list
    Then "bob" is asked whether to leave and cancel the upload

  # ── After the upload ──────────────────────────────────────────────────────

  Scenario: An uploaded video stands in for the link
    When the upload of "open-chords-lesson.mp4" finishes
    Then the card shows "open-chords-lesson.mp4" and "MP4 · 980 MB · uploaded"
    And its menu offers Play, Replace, Use a link instead and Remove

  Scenario: A failed upload can be tried again
    Given "open-chords-lesson.mp4" is uploading
    When the connection drops
    Then the card says "Upload stopped. Check your connection and try again."
    And "bob" can try again, which starts the upload from the beginning
    And the link field is shown again

  Scenario: Pasting a link still works
    Given the lesson has no video yet
    When "bob" pastes "https://youtu.be/abc123" into "Or paste a link" and saves
    Then the lesson's video is "https://youtu.be/abc123"
