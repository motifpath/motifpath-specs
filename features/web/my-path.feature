# My path (MOT-56 design, implemented in MOT-97).
#
# The student's current path, standalone or one part of a course, with every step and its state.
# The pattern is design/patterns/path.md; the Figma page is "My path & lessons" (rows 1, 5–7).
# What the path read returns, including lock_reason and available_languages, is in
# features/learning-paths/student-path-view.feature; why a language-locked step can be opened is
# ADR-024 (amendment 2026-10-08).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: See my path and what to do next
  As a student coming back to my path
  I want the next step on the first screen, and a true reason for every lock
  So that I always know what to do next and never get stuck

  Background:
    Given "alice" is signed in as a student
    And "alice"'s current path is "Open chords", 14 steps in the sections "Getting started", "First chords" and "Changes"

  # ── The next step ─────────────────────────────────────────────────────────

  Scenario: The next step is the first thing on My path
    Given "alice" has completed steps 1 to 7, and step 8 "The G chord" is a video
    When "alice" opens My path
    Then the top of the screen shows "Up next · step 8 of 14", "The G chord", "Video" and "Start lesson"
    And it is the only primary action on the screen

  Scenario: Start lesson opens the next step
    Given "alice" has completed steps 1 to 7
    When "alice" taps "Start lesson" on My path
    Then the lesson for step 8 opens

  Scenario: The header shows where the student is in the path
    Given "alice" has completed steps 1 to 7
    When "alice" opens My path
    Then the header shows the path title "Open chords" and a progress bar with "7 of 14"

  Scenario: A course part names its course above the path title
    Given "Open chords" is part 2 of 3 of the course "Guitar from zero"
    When "alice" opens My path
    Then the header shows "Guitar from zero · Part 2 of 3" above "Open chords"

  Scenario: A step shows its kind, never a length
    When "alice" opens My path
    Then every step's meta line names its kind, "Video" or "Article"
    And no step shows a duration

  # ── Sections ──────────────────────────────────────────────────────────────

  Scenario: A finished section folds into one row
    Given "alice" has completed every step in "Getting started", which has 5 steps
    When "alice" opens My path
    Then "Getting started" shows as one row reading "Getting started · 5 of 5"
    And its steps are hidden

  Scenario: A folded section unfolds on tap
    Given "alice" has completed every step in "Getting started"
    When "alice" taps the "Getting started" row
    Then its 5 steps show, each marked done

  Scenario: The current section and the ones after it stay open
    Given "alice"'s next step is in "First chords"
    When "alice" opens My path
    Then the steps of "First chords" and "Changes" show without a tap

  # ── Step states ───────────────────────────────────────────────────────────

  Scenario: A done step opens for review
    Given "alice" has completed step 3
    When "alice" taps step 3 on My path
    Then the lesson for step 3 opens as a review

  Scenario: A step locked behind an earlier one shows only its kind and a lock
    Given step 9 is locked because step 8 isn't completed
    When "alice" opens My path
    Then step 9 shows a lock icon and the meta line "Video"
    And it does not say "Complete the previous step"

  Scenario: A language-locked step says so in amber, not as an error
    Given "alice"'s locale is pt-BR
    And step 8 is locked for language and available in English only
    When "alice" opens My path
    Then step 8 shows the languages icon and the meta line "Only in English for now" in the warning colour
    And nothing on the row uses the error colour

  # ── Why a step is locked ──────────────────────────────────────────────────

  Scenario: Tapping a step locked behind an earlier one explains it on a phone
    Given step 10 is locked because step 8 isn't completed
    And "alice" is on a screen 390 px wide
    When "alice" taps step 10
    Then a bottom sheet says step 10 opens once the steps before it are done
    And its action is "Go to step 8"

  Scenario: From a tablet up, the explanation is a centred dialog
    Given step 10 is locked because step 8 isn't completed
    And "alice" is on a screen 768 px wide
    When "alice" taps step 10
    Then a centred dialog explains the lock with the action "Go to step 8"

  Scenario: Go to step N opens the step the student can do now
    Given the sheet for step 10 is open with "Go to step 8"
    When "alice" taps "Go to step 8"
    Then the lesson for step 8 opens

  Scenario: Tapping a language-locked step offers it in the language it has
    Given "alice"'s locale is pt-BR
    And step 8 is locked for language and available in English only
    When "alice" taps step 8
    Then the sheet says the lesson isn't in Portuguese yet
    And its action is "Watch in English"
    And there is no way to skip the step

  Scenario: The way through is named from the languages the step has
    Given "alice"'s locale is pt-BR
    And step 8 is an article locked for language and available in Spanish only
    When "alice" taps step 8
    Then the sheet's action is "Read in Spanish"

  Scenario: Watch in English opens the lesson in English
    Given "alice" taps "Watch in English" for step 8
    Then the lesson for step 8 opens and plays in English

  Scenario: Finishing a language-locked step unlocks the next one
    Given "alice" opened step 8 in English from the language sheet
    When "alice" finishes step 8
    And "alice" returns to My path
    Then step 8 is done
    And step 9 is the next step

  Scenario: Changing the interface language updates the path at once
    Given "alice"'s locale is en and step 8 is available in English only
    And "alice" is on My path, with step 8 as the next step
    When "alice" changes the interface language to Português
    Then My path reloads without a page refresh
    And step 8 shows "Only in English for now"

  # ── Path complete and no path ─────────────────────────────────────────────

  Scenario: A completed standalone path celebrates and points to the next path
    Given "Open chords" is a standalone path and "alice" has completed all 14 steps
    When "alice" opens My path
    Then a celebration shows above the folded path
    And the primary action is "Find your next path", which opens Discover on Paths
    And "Practise what you learned" is the quiet action, which opens Practice

  Scenario: A student with no path is told what a path is
    Given "alice" has no current path
    When "alice" opens My path
    Then the screen says what a path is
    And its action is "Explore courses and paths", which opens Discover

  # ── Loading and errors ────────────────────────────────────────────────────

  Scenario: My path shows skeleton rows while it loads
    Given the path is still loading
    When "alice" opens My path
    Then skeleton rows show in place of the steps

  Scenario: A path that fails to load offers Try again and keeps the navigation
    Given the path fails to load
    When "alice" opens My path
    Then an inline notice says the path didn't load, with "Try again"
    And the App Shell navigation stays usable
