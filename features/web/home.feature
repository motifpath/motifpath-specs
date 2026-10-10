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
#      streak (with the best), songs played (with this week's). Songs replaced skills up on
#      2026-10-09 (ADR-051 amendment, MOT-63 D6); skills up moved to Your progress.
#   4. Your skills — how many skills sit at each knowledge level on today's practice instrument,
#      and how many are fading.
#
# Data: the practice overview (getPracticeOverview) for today's practice and This week; the practice
# summary (getPracticeSummary) of today's practice instrument for Your skills; the student path for
# Your path. Nothing on the home is summed across instruments except This week.
#
# Order on Your progress, top to bottom (revised 2026-10-10, MOT-67):
#   1. This week — four tiles across instruments: minutes, day streak, songs and skills up.
#   2. Learning days — the last 7 days with the days a content node was completed, across
#      instruments.
#   3. The instrument choice: the student's instruments and "Any instrument".
#   4. For the chosen instrument: practice days, Your skills, and Moved this week.
# What is summed across instruments sits above the choice, so changing instrument never seems to
# leave numbers behind. Day rows show the last 7 days with today last and marked, and say only
# which days something happened. They are never a streak and never mark a day as missed.
#
# Data on Your progress: the practice overview (getPracticeOverview) above the choice; the
# practice summary (getPracticeSummary) of the chosen instrument below it, or the any-instrument
# summary for "Any instrument".
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

  Scenario: This week shows minutes, day streak and songs played
    Given "alice" practised 48 minutes this week and 33 minutes the week before
    And "alice"'s day streak is 3 and their best is 9
    And "alice" has played 5 songs, 1 of them first this week
    When "alice" opens the home
    Then This week shows 48 minutes, 15 more than the week before
    And This week shows a day streak of 3, best 9
    And This week shows 5 songs, 1 more this week

  Scenario: Your progress shows skills up with the other This week tiles
    Given 3 of "alice"'s skills went up this week
    When "alice" opens Your progress
    Then This week on Your progress shows minutes, the day streak, songs and 3 skills up

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

  Scenario: This week and learning days on Your progress stay put when the instrument changes
    Given "alice" is on Your progress for "guitar"
    When "alice" chooses "electric-bass"
    Then This week and learning days still show the same numbers, above the instrument choice

  Scenario: Day rows show the last 7 days with today last and marked
    Given today is Wednesday for "alice"
    And "alice" practised guitar on Thursday, Saturday and today
    When "alice" opens Your progress on "guitar"
    Then the practice days row shows the days Thursday to Wednesday, with today marked
    And Thursday, Saturday and Wednesday are filled and the row says 3 of 7

  Scenario: Moved this week shows each improved skill from where it started
    Given "alice"'s accuracy on "major-triads" on guitar went from 62% to 85% this week
    When "alice" opens Your progress on "guitar"
    Then Moved this week shows "major-triads", accuracy 62% → 85%

  Scenario: Any instrument shows the skills that suit every instrument
    Given "alice" is on Your progress for "guitar"
    When "alice" chooses "Any instrument"
    Then Your progress shows the practice days, skills and what moved this week of the skills that suit every instrument

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

  Scenario: A day without practice is never shown as missed
    Given "alice" practised on Monday and not on Tuesday
    When "alice" opens Your progress on "guitar"
    Then Tuesday is shown unfilled, in the same colours as any other day not yet practised
    And Your progress never calls the practice days a streak

  Scenario: A week where nothing moved says so kindly
    Given none of "alice"'s skills on guitar improved this week
    When "alice" opens Your progress on "guitar"
    Then Moved this week says nothing moved yet and invites "alice" to practise

  Scenario: Your progress opened without an instrument opens on the student's first
    When "alice" opens Your progress without choosing an instrument
    Then Your progress opens on "guitar"

  Scenario: Your progress offers only the student's own instruments and "Any instrument"
    When "alice" opens Your progress
    Then the instrument choices are "guitar", "electric-bass" and "Any instrument"
    And there is no choice that sums every instrument

  Scenario: A student who has played no song yet sees 0 songs without alarm
    Given "bruno" has never marked a song chart as played
    When "bruno" opens the home
    Then the songs tile shows 0 in the same colours as the other tiles

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

  Scenario: A summary that fails to load on Your progress keeps This week and learning days
    Given "alice"'s practice summary for "guitar" fails to load
    When "alice" opens Your progress on "guitar"
    Then practice days, Your skills and Moved this week say they couldn't load and offer a retry
    And This week and learning days still show
