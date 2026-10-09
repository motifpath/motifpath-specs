# The lesson screen (MOT-56 design, implemented in MOT-97; folds in MOT-24).
#
# A step opened from My path, Home's path card or a link: a video lesson or an article lesson. A
# "diagram lesson" is an article whose body starts with a diagram. The pattern is
# design/patterns/lesson.md; the Figma page is "My path & lessons" (rows 2–7). The events a lesson
# sends (lesson.started, lesson.resumed, lesson.completed) are in
# features/event-ingestion/ingest-lesson-event.feature.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: Take a lesson and move on to the next step
  As a student with my instrument nearby
  I want the lesson to have the room, its extras in place, and the next step one tap away
  So that I keep moving through my path

  Background:
    Given "alice" is signed in as a student
    And "alice"'s current path is "Open chords", 14 steps, and "alice" has completed steps 1 to 7

  # ── The page ──────────────────────────────────────────────────────────────

  Scenario: A lesson is a page pushed onto My path
    When "alice" opens step 8 "The G chord" on a screen 390 px wide
    Then a back arrow and "Open chords" lead back to My path
    And the bottom navigation bar is hidden

  Scenario: From a tablet up, the navigation stays beside the lesson
    When "alice" opens step 8 on a screen 768 px wide
    Then the navigation rail stays on screen

  Scenario: The title block says where the step is, with no length
    When "alice" opens step 8, a video
    Then the title block shows "The G chord" and "Step 8 of 14 · Video"
    And no duration is shown before the video loads

  # ── Video ─────────────────────────────────────────────────────────────────

  Scenario: A cue shows in place under the video while it is active
    Given step 8's video has a diagram cue from 0:40 to 1:10
    When the video reaches 0:45
    Then the diagram shows under the video, without covering it

  Scenario: A video with a challenge offers Practise this when it ends
    Given step 8 has a challenge
    When step 8's video ends
    Then lesson.completed is sent for step 8
    And the screen offers "Practise this", which starts the challenge
    And step 8 is not done until the challenge is

  Scenario: A video without a challenge completes the step when it ends
    Given step 8 has no challenge
    When step 8's video ends
    Then lesson.completed is sent for step 8
    And the screen shows "Step done" and the next step's card for step 9, with "Start lesson"
    And "Back to My path" is the quiet way out

  Scenario: Start lesson after a step goes straight to the next step
    Given the screen shows "Step done" for step 8
    When "alice" taps "Start lesson"
    Then the lesson for step 9 opens

  # ── Article ───────────────────────────────────────────────────────────────

  Scenario: An article lesson shows its text in a readable column
    Given step 9 "Reading chord boxes" is an article
    When "alice" opens step 9
    Then the article's text shows in one readable column, with its diagrams embedded in it
    And the title block shows "Step 9 of 14 · Article"

  Scenario: A paragraph cue sits under its paragraph and stays
    Given step 9's article has an image cue at paragraph 3
    When "alice" scrolls past paragraph 3
    Then the image shows under paragraph 3
    And it is still there after any time has passed

  Scenario: The article's hand-off is at the end of the text
    Given step 9 is an article with no challenge
    When "alice" opens step 9
    Then there is no completion button while "alice" reads
    And "Mark as done" shows at the end of the text

  Scenario: Mark as done completes the step and opens the next one
    Given step 9 is an article with no challenge
    When "alice" taps "Mark as done" at the end of the text
    Then lesson.completed is sent for step 9
    And the lesson for step 10 opens

  Scenario: An article with a challenge ends with Practise this
    Given step 9 is an article with a challenge
    When "alice" reaches the end of the text
    Then "Practise this" shows there instead of "Mark as done"

  Scenario: A diagram lesson is an article that starts with a diagram
    Given step 11 is an article whose body starts with a diagram
    When "alice" opens step 11
    Then the diagram shows at the top of the text
    And the title block says "Article"

  # ── Review ────────────────────────────────────────────────────────────────

  Scenario: A done step opens as a review that never gates
    Given "alice" has completed step 3, which has a challenge
    When "alice" opens step 3
    Then the lesson plays or reads with no completion action
    And "Practise again" is offered as a secondary action
    And lesson.completed is not sent again

  # ── Watch in English ──────────────────────────────────────────────────────

  Scenario: A language-locked step opened directly explains itself in place
    Given "alice"'s locale is pt-BR
    And step 8 is locked for language and available in English only
    When "alice" opens step 8 from a link
    Then the lesson explains it isn't in Portuguese yet, with "Watch in English"
    And the video does not load until "alice" chooses

  Scenario: A language-locked step completes like any other once opened
    Given "alice"'s locale is pt-BR
    And step 8 is locked for language, available in English only, and has no challenge
    When "alice" chooses "Watch in English" and the video ends
    Then lesson.completed is sent for step 8
    And the next step's card is for step 9

  # ── States, in place ──────────────────────────────────────────────────────

  Scenario: A lesson shows a skeleton in its shape while it loads
    When "alice" opens step 8 and the lesson is still loading
    Then a skeleton in the shape of a video lesson shows

  Scenario: A video that fails to load offers Try again where the video was
    Given step 8's video fails to load
    When "alice" opens step 8
    Then an inline notice with "Try again" shows where the video would be
    And the title block stays readable

  Scenario: A diagram that fails to load leaves the rest of the article readable
    Given a diagram embedded in step 9's article fails to load
    When "alice" opens step 9
    Then an inline notice with "Try again" shows where the diagram would be
    And the rest of the text shows

  Scenario: A step locked behind an earlier one explains itself in place
    Given step 10 is locked because step 8 isn't completed
    When "alice" opens step 10 from a link
    Then the lesson says it opens once the steps before it are done, with "Go to step 8"

  Scenario: A step no longer on the path sends the student back to My path
    Given a content node that is not on "alice"'s current path
    When "alice" opens it from an old link
    Then the lesson says it is no longer on "alice"'s path, with "Go to My path"

  # ── Size classes ──────────────────────────────────────────────────────────

  Scenario: On a large screen an aside holds the cue and the section's steps
    Given step 8's video has an active cue
    When "alice" watches step 8 on a screen 1280 px wide
    Then an aside beside the video shows the cue on top and the steps of "First chords" below

  Scenario: On a large screen the next step moves to the top of the aside when a video ends
    Given step 8 has no challenge
    When step 8's video ends on a screen 1280 px wide
    Then the next step's card shows at the top of the aside
