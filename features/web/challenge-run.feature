Feature: Work through a lesson's challenge in the Practice Shell
  As a student who has just finished a lesson
  I want its challenge to feel like the rest of my practice, with my answers reviewed at the end
  So that I focus on the exercises, and learn from the ones I got wrong

  # The S7 challenge run (MOT-55 row 5, D6, D7) uses the Practice Shell (design/patterns/session.md):
  # no app bar, ×, "n / N" and segmented progress. Unlike a practice session, a challenge gives no
  # feedback until the end: Next commits the selection, Back goes back to change it, and the review
  # after the last exercise reveals every answer (ADR-046).
  # The two-pane scenarios cover every run in the shell (MOT-55 row 15, D26).
  # These scenarios are verified by motifpath-web's component tests, not by the core-domain BDD suite.

  Background:
    Given student "alice" is authenticated with a valid session
    And the lesson "Inversions of C major" has a challenge of 9 exercises

  # ── The run ────────────────────────────────────────────────────────────────

  @web
  Scenario: The challenge runs in the Practice Shell
    When "alice" starts the challenge
    Then there is no app bar, navigation bar, rail or sidebar
    And the header shows ×, "1 / 9" and 9 progress segments
    And the item header shows the lesson title with a "Challenge" tag

  @web
  Scenario: Choosing an option gives no feedback
    Given "alice" is on exercise 3
    When "alice" chooses "First inversion"
    Then "First inversion" is selected, neither right nor wrong
    And the screen says no answers are shown until the end

  @web
  Scenario: Next commits the selection and moves on
    Given "alice" has chosen "First inversion" on exercise 3
    When "alice" taps Next
    Then practice.item_answered is sent for exercise 3 with "First inversion"
    And exercise 4 is shown, with "4 / 9" in the header

  @web
  Scenario: Next waits for a selection
    When "alice" is on exercise 3 with nothing chosen
    Then Next is disabled

  @web
  Scenario: Back keeps the earlier answer so it can be changed
    Given "alice" chose "First inversion" on exercise 3 and moved on
    When "alice" taps Back
    Then exercise 3 is shown with "First inversion" selected

  @web
  Scenario: Keys choose options and Enter moves on
    Given "alice" is on exercise 3 with 3 options
    When "alice" presses 2 and then Enter
    Then the second option is the answer to exercise 3
    And exercise 4 is shown

  # ── How to answer and the teacher ──────────────────────────────────────────

  @web
  Scenario: How to answer opens in place, not as a modal
    Given "alice" is on exercise 3
    When "alice" taps "How to answer"
    Then how to answer the exercise shows above the options
    And the options can still be chosen
    And no dialog opens

  @web
  Scenario: Send to your teacher is a tertiary link under the options
    Given a concierge number is configured
    When "alice" is on exercise 3
    Then "Send to your teacher" is a link under the options, never in the action bar

  # ── Review after the last exercise ─────────────────────────────────────────

  @web
  Scenario: The last exercise leads to the result
    Given "alice" has answered the first 8 exercises
    When "alice" chooses an option on exercise 9 and taps "See result"
    Then the result says "7 of 9 correct" with "78%"

  @web
  Scenario: The review lists each exercise with the answer and the right one
    Given "alice" answered exercise 3 "Second inversion" and the right answer is "First inversion"
    When the result is shown
    Then exercise 3 is listed with its prompt
    And "Your answer: Second inversion" is marked wrong
    And "Right answer: First inversion" is marked right

  @web
  Scenario: A right answer is listed once, as right
    Given "alice" answered exercise 1 "Root position", which is right
    When the result is shown
    Then exercise 1 lists "Your answer: Root position" marked right, with no separate right answer

  @web
  Scenario: Finish goes to My path
    When "alice" taps Finish on the result
    Then My path opens

  @web
  Scenario: Back from the result returns to the last exercise
    When "alice" taps Back on the result
    Then exercise 9 is shown with its answer selected

  # ── Leaving ────────────────────────────────────────────────────────────────

  @web
  Scenario Outline: Leaving the run returns to the lesson without asking
    Given "alice" is on exercise 3
    When "alice" <leaves>
    Then the lesson "Inversions of C major" opens
    And no confirmation is asked

    Examples:
      | leaves                          |
      | taps ×                          |
      | presses Esc                     |
      | presses the browser's back button |

  # ── States, in place ───────────────────────────────────────────────────────

  @web
  Scenario: Loading shows a skeleton in the shell
    When the challenge is loading
    Then a skeleton shows in the shell, with × to leave

  @web
  Scenario: A failed load offers Try again in place
    When the challenge fails to load
    Then the shell says it couldn't load the challenge, with Try again as the primary action

  @web
  Scenario: A lesson without a challenge says so in the shell
    Given the lesson "Scales" has no challenge
    When "alice" opens its challenge
    Then the shell says there is no challenge for this lesson yet, with "Back to lesson" as the primary action

  # ── Panes on Expanded ──────────────────────────────────────────────────────

  @web
  Scenario Outline: An exercise answered on its stimulus gets its own pane on Expanded
    Given "alice" is in a run on a screen 1280 px wide
    When "alice" is on <an exercise answered on its stimulus>
    Then the stimulus is in a pane on the left
    And the item header, prompt, feedback and help are in a 400 px pane on the right
    And the action bar stays at the bottom

    Examples:
      | an exercise answered on its stimulus                  |
      | an image_recognition exercise, by tapping its regions |
      | a diagram exercise, by tapping its markers            |

  @web
  Scenario: An exercise with separate options stays in one column on Expanded
    Given "alice" is in a run on a screen 1280 px wide
    When "alice" is on a text_response exercise
    Then the item is in one centred column, 560 px at most

  @web
  Scenario: Medium never has two panes
    Given "alice" is in a run on a screen 700 px wide
    When "alice" is on an image_recognition exercise
    Then the stimulus and the interaction are stacked in one column
