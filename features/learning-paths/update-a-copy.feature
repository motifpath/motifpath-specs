# Updating a learner's copy to the latest published course or path (MOT-36, ADR-055).
#
# A copy keeps the content it had when it was made. When the author publishes changes, the learner
# can choose to take them. Progress is kept per lesson, so finished lessons stay finished. The
# screens are in features/web/learning.feature.

@wip
Feature: Update a course or path I started to its latest version
  As a learner who started a course or path before its author changed it
  I want to take the latest version without losing my place
  So that corrected and improved lessons reach me too

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And student "alice" is registered in the system
    And "alice" is authenticated as a student

  # ── Knowing a copy is behind ──────────────────────────────────────────────

  Scenario: A standalone path is behind once its published template's lessons change
    Given "alice" has enrolled in learning path "open-chords-path"
    And the author adds a lesson to "open-chords-path"
    When "alice" lists her standalone paths
    Then her copy of "open-chords-path" shows that an update is available

  Scenario: A standalone path is behind once its published template gets a new thumbnail
    Given "alice" has enrolled in learning path "open-chords-path"
    And the author changes the thumbnail of "open-chords-path"
    When "alice" lists her standalone paths
    Then her copy of "open-chords-path" shows that an update is available

  Scenario: A standalone path that matches its template is not behind
    Given "alice" has enrolled in learning path "open-chords-path"
    When "alice" lists her standalone paths
    Then her copy of "open-chords-path" shows no update available

  Scenario: A path whose template is no longer published is not offered an update
    Given "alice" has enrolled in learning path "open-chords-path"
    And the author adds a lesson to "open-chords-path"
    And an admin unpublishes "open-chords-path"
    When "alice" lists her standalone paths
    Then her copy of "open-chords-path" shows no update available

  Scenario: A finished path is not offered an update
    Given "alice" has enrolled in learning path "open-chords-path"
    And "alice" has completed every lesson of her copy of "open-chords-path"
    And the author adds a lesson to "open-chords-path"
    When "alice" lists her standalone paths
    Then her copy of "open-chords-path" shows no update available

  Scenario: A course enrollment is behind once a newer course version is published
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And an admin publishes a new version of "fingerstyle-journey"
    When "alice" lists her course enrollments
    Then her enrollment in "fingerstyle-journey" shows that an update is available

  Scenario: A course enrollment is behind once its active part's path changes
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And the author adds a lesson to "open-chords-path"
    When "alice" lists her course enrollments
    Then her enrollment in "fingerstyle-journey" shows that an update is available

  Scenario: A course checkpoint's own path copy is never offered an update on its own
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And the author adds a lesson to "open-chords-path"
    When "alice" opens checkpoint 1's student path
    Then that student path shows no update available

  # ── Updating a standalone path ────────────────────────────────────────────

  Scenario: Updating a path gives the learner the template's current lessons
    Given "alice" has enrolled in learning path "open-chords-path"
    And the author adds the lesson "Barre basics" to "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then her copy of "open-chords-path" contains "Barre basics"
    And her copy of "open-chords-path" shows no update available

  Scenario: Updating a path refreshes its title, summary, level and thumbnail
    Given "alice" has enrolled in learning path "open-chords-path"
    And the author changes the title, summary, level and thumbnail of "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then her copy of "open-chords-path" records the template's new title, summary, level and thumbnail

  Scenario: Lessons finished before the update stay finished
    Given "alice" has enrolled in learning path "open-chords-path"
    And "alice" has completed the first lesson of her copy of "open-chords-path"
    And the author adds a lesson to "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then the first lesson of her copy of "open-chords-path" shows as completed

  Scenario: When the lesson the learner was on is removed, they continue at the next unfinished one
    Given "alice" has enrolled in learning path "open-chords-path" with lessons "G chord", "C chord", "D chord"
    And "alice" has completed "G chord"
    And the author removes "C chord" from "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then the next lesson of her copy of "open-chords-path" is "D chord"

  Scenario: Updating a path keeps it the same copy, and current if it was current
    Given "alice" has enrolled in learning path "open-chords-path" and it is her current path
    And the author adds a lesson to "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then the updated copy keeps its id
    And it is still "alice"'s current path

  Scenario: Updating a path that is not behind changes nothing
    Given "alice" has enrolled in learning path "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then her copy of "open-chords-path" is returned unchanged

  Scenario: A path the learner was assigned by staff can be updated too
    Given "bob" has assigned "open-chords-path" to student "alice"
    And the author adds a lesson to "open-chords-path"
    When "alice" updates her copy of "open-chords-path"
    Then her copy of "open-chords-path" contains the new lesson
    And her copy still records "bob" as the assigner

  # ── Updating a course enrollment ──────────────────────────────────────────

  Scenario: Updating a course pins the enrollment to the latest version
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And an admin publishes a new version of "fingerstyle-journey" with a new title and thumbnail
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then her enrollment is pinned to the course's latest published version
    And her enrollment shows the new title and thumbnail
    And her enrollment shows no update available

  Scenario: Updating a course keeps the learner on their part when it still exists
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active
    And an admin publishes a new version of "fingerstyle-journey" with checkpoints "warm-up-path", "open-chords-path", "strumming-path"
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then her active checkpoint is "strumming-path" at position 3
    And her student path for "strumming-path" is the same copy as before

  Scenario: Updating a course also updates the active part's path
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And the author adds the lesson "Barre basics" to "open-chords-path"
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then her student path for checkpoint 1 contains "Barre basics"

  Scenario: When the active part is removed, the learner continues at the first part they haven't finished
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path", "rhythm-basics-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active
    And an admin publishes a new version of "fingerstyle-journey" with checkpoints "open-chords-path", "rhythm-basics-path"
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then her student path for "strumming-path" is archived
    And a student path for "rhythm-basics-path" is created and becomes her active checkpoint at position 2

  Scenario: When every part of the new version is already finished, the course completes
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 2 active
    And "alice" has completed every lesson of "open-chords-path"
    And an admin publishes a new version of "fingerstyle-journey" with checkpoints "open-chords-path"
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then her enrollment in "fingerstyle-journey" is completed

  Scenario: Updating a course never changes which item is current
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path", "strumming-path"
    And "alice" is enrolled in "fingerstyle-journey" with checkpoint 1 active
    And "alice"'s current path is the standalone path "rhythm-basics-path"
    And an admin publishes a new version of "fingerstyle-journey"
    When "alice" updates her enrollment in "fingerstyle-journey"
    Then "alice"'s current path is still "rhythm-basics-path"

  # ── Refusals ──────────────────────────────────────────────────────────────

  Scenario: An archived path cannot be updated
    Given "alice" has archived her copy of "open-chords-path"
    When "alice" tries to update her copy of "open-chords-path"
    Then the update is refused because no active standalone path was found

  Scenario: A path whose template is no longer published cannot be updated
    Given "alice" has enrolled in learning path "open-chords-path"
    And an admin unpublishes "open-chords-path"
    When "alice" tries to update her copy of "open-chords-path"
    Then the update is refused because the path is no longer published

  Scenario: A finished path cannot be updated
    Given "alice" has enrolled in learning path "open-chords-path"
    And "alice" has completed every lesson of her copy of "open-chords-path"
    When "alice" tries to update her copy of "open-chords-path"
    Then the update is refused because the path is finished

  Scenario: An abandoned course enrollment cannot be updated
    Given a course "fingerstyle-journey" exists, published, with checkpoints "open-chords-path"
    And "alice" has abandoned her enrollment in "fingerstyle-journey"
    When "alice" tries to update her enrollment in "fingerstyle-journey"
    Then the update is refused because no active enrollment was found

  Scenario: A learner cannot update another learner's copy
    Given student "dave" has enrolled in learning path "open-chords-path"
    When "alice" tries to update "dave"'s copy of "open-chords-path"
    Then the update is refused because no active standalone path was found
