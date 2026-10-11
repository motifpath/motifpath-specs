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

  Scenario: A student who has left everything they started sees This week and no Your skills
    Given student "bruno" abandoned every course and archived every path they started
    When "bruno" opens the home
    Then the home shows This week
    And the home has no Your skills block
    And the home is not the first run

  Scenario: The home reads in pt-BR without truncating its labels
    Given "alice"'s language is Portuguese (Brazil)
    When "alice" opens the home on a phone
    Then every tile label and the path card's step are shown in full

  # ── First run (MOT-59 D6–D9, implemented by MOT-88) ──────────────────────────
  #
  # A student's instruments come only from what they have started (ADR-046), so a student who has
  # never started a course or a path has nothing to practise. For them the home is the first run:
  # two questions, then Where to start. There is no "seen" flag and no stored answer — it shows
  # until a course or path is started. "Never started" means the student holds no course enrolment
  # and no standalone path at all, active or not.
  #
  # The answers are never stored. With the app's language, they ask core for the starting points
  # (ADR-052): the paths and courses the team picked for that instrument, experience and language,
  # in the team's order, at most 5 — or, when the team picked none, the catalog's paths then courses
  # at the experience's levels. The web shows them as they come. Tapping one opens its detail, whose
  # Start follows Discover (current, My path on lesson 1, toast with Undo).
  # Pattern: design/patterns/landing-and-first-run.md.

  Scenario: A student who has never started anything sees the first run
    Given student "carla" has never started a course or a path
    When "carla" opens the home
    Then the home says "Welcome, Carla" and asks "What do you want to play?" and "How much have you played it?"
    And the home has no today's practice, no path card, no This week and no Your skills

  Scenario: The instrument question offers every catalog instrument, none chosen
    Given student "carla" has never started a course or a path
    And the catalog's instruments are acoustic guitar, electric guitar and electric bass
    When "carla" opens the home
    Then "What do you want to play?" offers acoustic guitar, electric guitar and electric bass, none chosen
    And "How much have you played it?" has "Never played" chosen
    And "Show me where to start" waits until an instrument is chosen

  Scenario: Where to start asks for the starting points of the answers
    Given student "carla" has never started a course or a path
    And "carla"'s app language is English
    When "carla" chooses electric guitar and "Never played" and "Show me where to start"
    Then the starting points are asked for electric guitar, never played, in English

  Scenario: Where to start shows the starting points in their order
    Given the starting points for electric guitar, never played, in English are course "Electric guitar basics", then path "Electric guitar from zero"
    When "carla" asks where to start on electric guitar as "Never played"
    Then Where to start shows "1 path · 1 course"
    And course "Electric guitar basics" comes first, then path "Electric guitar from zero"
    And each says its kind, level and language, like "Path · Beginner · English"

  Scenario: The answers are never stored
    Given "carla" asked where to start on electric guitar as "Never played"
    When "carla" opens the home again later without having started anything
    Then the home asks the two questions again with nothing chosen but "Never played"

  Scenario: Change goes back to the questions with the answers kept
    Given "carla" is on Where to start for electric guitar, "Never played"
    When "carla" chooses Change
    Then the two questions show with electric guitar and "Never played" chosen

  Scenario: Tapping a result opens its detail, which leads back to Where to start
    Given "carla" is on Where to start for electric guitar, "Never played"
    When "carla" taps the path "Electric guitar from zero"
    Then the detail of "Electric guitar from zero" shows
    And going back shows Where to start with the same results

  Scenario: Starting a path from Where to start ends the first run
    Given "carla" is on the detail of the path "Electric guitar from zero" from Where to start
    When "carla" starts the path
    Then "Electric guitar from zero" is "carla"'s current path
    And the next time "carla" opens the home it shows today's practice and the path card

  Scenario: The WhatsApp concierge is a quiet link under the questions and the results
    Given student "carla" has never started a course or a path
    When "carla" opens the home
    Then "Not sure? Ask us on WhatsApp" and "Browse everything in Discover" show under the questions

  Scenario: Find where to start on the Practice tab opens the first run
    Given student "carla" has never started a course or a path
    And "carla" opened the Practice tab and there is nothing to practise
    When "carla" chooses "Find where to start"
    Then the home shows the first run

  Scenario: Nothing at the chosen level shows the instrument's other levels
    Given there are no starting points for electric bass, never played, in "carla"'s language
    And for electric bass at other levels the catalog has 1 course
    When "carla" asks where to start on electric bass as "Never played"
    Then Where to start says "Nothing for beginners on electric bass yet. These are the closest:"
    And it shows the electric bass course

  Scenario: Nothing for the instrument offers WhatsApp and Change
    Given the catalog has nothing on electric bass in "carla"'s language
    When "carla" asks where to start on electric bass as "Never played"
    Then Where to start says "No electric bass courses yet" and offers "Ask us on WhatsApp"
    And Change is still offered

  Scenario: Where to start loading slowly shows skeleton rows
    Given the starting points take 2 seconds to load
    When "carla" asks where to start on electric guitar as "Never played"
    Then after 300 ms Where to start shows skeleton rows

  Scenario: The first run reads in pt-BR
    Given student "carla" has never started a course or a path
    And "carla"'s app language is Portuguese (Brazil)
    When "carla" asks where to start on electric guitar as "Never played"
    Then the starting points are asked for in Portuguese (Brazil)

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: Where to start that fails to load offers a retry in place
    Given the starting points fail to load
    When "carla" asks where to start on electric guitar as "Never played"
    Then Where to start says it couldn't load and offers Try again
    And Change is still offered

  Scenario: The home that can't tell whether anything was started offers a retry
    Given "carla"'s course enrolments fail to load
    When "carla" opens the home
    Then the home says it couldn't load and offers a retry
    And the home shows neither the first run nor This week

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
