# The home and Your progress (MOT-43).
#
# The home answers "what should I do now?" first, then shows two motivating blocks. Everything else
# about progress lives on Your progress, opened on demand. Designs: Figma "MotifPath — Experience
# Language", page "Home — exploration" (H3, revised 2026-10-07).
#
# Order on the home, top to bottom:
#   1. Today's practice — the top next step across instruments, with the only primary action.
#   2. Your path — the path's progress and its next step; the whole card opens that step.
#   3. This week — three tiles: minutes practised (with the change against the week before), day
#      streak (with the best), skills up.
#   4. Your skills — how many skills sit at each knowledge level on today's practice instrument,
#      and how many are fading.
#
# Data: the practice overview (getPracticeOverview) for today's practice and This week; the practice
# summary (getPracticeSummary) of today's practice instrument for Your skills; the student path for
# Your path. Nothing on the home is summed across instruments except This week.
#
# These scenarios are verified by motifpath-web's component tests and manual browser checks, not by
# the core-domain BDD suite.

Feature: The home and Your progress
  As a student
  I want the home to tell me what to do now and show me that I'm getting better
  So that I start practising quickly and keep coming back

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And "alice"'s top next step is to refresh "major-triads" on "guitar"
    And "alice" follows the path "Guitar fundamentals" and has completed 8 of its 14 steps

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: The home leads with today's practice and its only primary action
    When "alice" opens the home
    Then the first block is today's practice: refresh "major-triads" on "guitar"
    And "Start practice" is the home's only primary action

  Scenario: Your path shows its progress and the next step
    Given "alice"'s next step on "Guitar fundamentals" is the lesson "Inversions"
    When "alice" opens the home
    Then the path card shows "Guitar fundamentals", 8 of 14, and "Inversions" as up next

  Scenario: Tapping the path card opens the next step
    Given "alice"'s next step on "Guitar fundamentals" is the lesson "Inversions"
    When "alice" taps the path card
    Then the lesson "Inversions" opens

  Scenario: This week shows minutes, day streak and skills up
    Given "alice" practised 48 minutes this week and 33 minutes the week before
    And "alice"'s day streak is 3 and their best is 9
    And 3 of "alice"'s skills went up this week
    When "alice" opens the home
    Then This week shows 48 minutes, 15 more than the week before
    And This week shows a day streak of 3, best 9
    And This week shows 3 skills up

  Scenario: Your skills counts the skills at each level on today's practice instrument
    Given on "guitar" "alice" has 5 skills learning, 7 accurate, 4 fluent and 2 retained, and 2 of them are fading
    When "alice" opens the home
    Then Your skills on "guitar" shows 5 learning, 7 accurate, 4 fluent and 2 retained
    And Your skills says 2 are fading

  Scenario: See all opens Your progress
    When "alice" chooses "See all" on Your skills
    Then Your progress opens on "guitar"

  Scenario: Tapping a This week tile opens Your progress
    When "alice" taps the minutes tile
    Then Your progress opens on "guitar"

  Scenario: Your progress switches between the student's instruments
    Given "alice" is on Your progress for "guitar"
    When "alice" chooses "electric-bass"
    Then Your progress shows "electric-bass"'s practice days, skills and what moved this week

  Scenario: Back from Your progress returns to the home
    Given "alice" opened Your progress from the home
    When "alice" goes back
    Then the home shows again, where "alice" left it

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: No current streak invites the student to start one
    Given "alice"'s day streak is 0 and their best is 9
    When "alice" opens the home
    Then the streak tile invites "alice" to start a streak today and still shows the best, 9
    And the streak tile never says a streak was lost

  Scenario: A streak is never shown in a warning colour
    Given "alice"'s day streak is 0
    When "alice" opens the home
    Then the streak tile uses the same colours as the other tiles

  Scenario: Fewer minutes than the week before are shown without alarm
    Given "alice" practised 20 minutes this week and 45 minutes the week before
    When "alice" opens the home
    Then the minutes tile shows 20 and the change in a neutral colour

  Scenario: Your progress offers only the student's own instruments and "Any instrument"
    When "alice" opens Your progress
    Then the instrument choices are "guitar", "electric-bass" and "Any instrument"
    And there is no choice that sums every instrument

  Scenario: A student with no path has no path card
    Given student "bruno" follows no path
    When "bruno" opens the home
    Then the home has no path card
    And the home invites "bruno" to find a path

  Scenario: A student with no instruments sees This week and no Your skills
    Given student "bruno" is enrolled in nothing for any instrument
    When "bruno" opens the home
    Then the home shows This week
    And the home has no Your skills block

  Scenario: The home reads in pt-BR without truncating its labels
    Given "alice"'s language is Portuguese (Brazil)
    When "alice" opens the home on a phone
    Then every tile label and the path card's step are shown in full

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: An overview that fails to load offers a retry and keeps the rest of the home
    Given "alice"'s practice overview fails to load
    When "alice" opens the home
    Then today's practice and This week say they couldn't load and offer a retry
    And Your path still shows

  Scenario: A summary that fails to load hides only Your skills
    Given "alice"'s practice summary for "guitar" fails to load
    When "alice" opens the home
    Then Your skills says it couldn't load and offers a retry
    And today's practice, Your path and This week still show
