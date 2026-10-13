# Reviewing a lesson of a finished course or standalone path (MOT-106).
#
# A lesson opened from the detail of a finished course or standalone path (features/web/learning.feature)
# opens for review. Nothing is locked, nothing moves the student's progress or current path, and
# the way back and the way on stay inside that course or path. The reads behind it are in
# features/learning-paths/review-finished-learning.feature. The lesson screen itself is
# features/web/lesson.feature. Opening a completed step of the current path is a different review,
# covered there. Design: design/patterns/learning.md and the "Learning" Figma page, row 7
# (decisions R1–R6, approved 2026-10-13).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: Review a lesson of a finished course or path
  As a student who finished a course or a path
  I want to watch, read and practise any of its lessons again
  So that I can review what I learned without losing my place elsewhere

  Background:
    Given "alice" is signed in as a student
    And "alice" finished the course "First songs", 3 parts of 6 lessons each
    And "Reading rhythm" is "alice"'s current course

  # ── Opening and moving through ────────────────────────────────────────────

  Scenario: Any lesson of a finished course opens, in any order
    When "alice" opens lesson 5 of part 3 from the course detail of "First songs"
    Then the lesson plays or reads in full
    And nothing on the screen says it is locked

  Scenario: The back arrow returns to the finished course
    When "alice" opens lesson 2 of part 1 from the course detail of "First songs"
    Then a back arrow and "First songs" lead back to its course detail

  Scenario: The title block names the part, not a step of My path
    When "alice" opens lesson 2 of part 1, a video, from the course detail of "First songs"
    Then the title block shows "Part 1 · Lesson 2 of 6 · Video · Done"

  Scenario: The way on is the next lesson of the course
    Given "alice" is reviewing lesson 2 of part 1 of "First songs"
    When the lesson ends
    Then the screen offers the next lesson's card, "Up next · Part 1 · Lesson 3 of 6", with "Back to First songs"
    And there is no "Step done" and no "Back to My path"

  Scenario: The last lesson of a part leads to the first lesson of the next part
    Given "alice" is reviewing lesson 6 of part 1 of "First songs"
    When the lesson ends
    Then the screen offers the next lesson's card for lesson 1 of part 2

  Scenario: The last lesson of the course leads to Learning
    Given "alice" is reviewing lesson 6 of part 3 of "First songs"
    When the lesson ends
    Then the screen says "That was the last lesson of First songs." with "Go to Learning" and no next lesson
    And the course completed screen does not open

  Scenario: The end of a review does not leave the lesson by itself
    Given "alice" is reviewing lesson 6 of part 3 of "First songs"
    When the lesson ends
    Then the lesson stays open until "alice" taps "Go to Learning"

  Scenario: The last lesson of a finished path leads to Learning
    Given "alice" finished the standalone path "Open chords", 9 lessons
    And "alice" is reviewing lesson 9 of "Open chords"
    When the lesson ends
    Then the screen says "That was the last lesson of Open chords." with "Go to Learning"

  Scenario: A lesson of a finished standalone path goes back to its path detail
    Given "alice" finished the standalone path "Open chords"
    When "alice" opens lesson 4 from the path detail of "Open chords"
    Then a back arrow and "Open chords" lead back to its path detail
    And when the lesson ends the next lesson's card is for lesson 5 of "Open chords"

  # ── Exercises and challenge ───────────────────────────────────────────────

  Scenario: A lesson's challenge can be done again
    Given lesson 3 of part 2 of "First songs" has a challenge
    When "alice" reviews lesson 3 of part 2
    Then "Practise again" is offered, which starts the challenge
    And finishing the challenge returns to the lesson, not to My path

  Scenario: A failed challenge in review does not undo the lesson
    Given lesson 3 of part 2 of "First songs" has a challenge
    When "alice" scores under the threshold on it in review
    Then the lesson still shows as done on the course detail of "First songs"

  # ── Nothing moves ─────────────────────────────────────────────────────────

  Scenario: Reviewing does not change the current course
    When "alice" reviews lesson 1 of part 1 of "First songs" to the end
    Then "Reading rhythm" is still "alice"'s current course
    And "alice"'s current course is never switched while she reviews

  Scenario: Reviewing a lesson sends no lesson.completed
    When "alice" reviews lesson 1 of part 1 of "First songs" to the end
    Then lesson.started is sent for it, marked as review
    And lesson.completed is not sent

  Scenario: Exercise events in review are marked as review
    Given lesson 3 of part 2 of "First songs" has a challenge
    When "alice" answers its first exercise in review
    Then exercise.started, practice.item_answered and exercise.ended are sent for it, each marked as review

  Scenario: Reopening a completed step of the current path is not marked as review
    Given "alice" has completed step 3 of "Reading rhythm"
    When "alice" opens step 3 from My path
    Then the lesson events it sends are not marked as review

  # ── States, in place ──────────────────────────────────────────────────────

  Scenario: A lesson that fails to load in review offers Try again in place
    Given lesson 2 of part 1 of "First songs" fails to load
    When "alice" opens it from the course detail of "First songs"
    Then an inline notice with "Try again" shows where the lesson would be
    And the back arrow still leads to "First songs"

  Scenario: A lesson of a course the student did not finish does not open for review
    Given "alice" is on part 2 of "Guitar foundations"
    When "alice" opens a review link to lesson 1 of part 3 of "Guitar foundations"
    Then the lesson says it opens once the course reaches it, with "Go to My path"
