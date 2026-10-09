Feature: Show the student's practice overview across instruments
  As a student
  I want to see at a glance that I've been practising and learning, whatever I played
  So that every session counts toward my sense of progress, before I pick an instrument

  # The overview is the first view of the app's home, for every signed-in user. Practice days here count finished sessions
  # on any instrument; each instrument's card and summary count only that instrument. Learning
  # days count completed content nodes and appear only here.

  Background:
    Given student "alice" plays "guitar" and "electric-bass" in time zone "America/Sao_Paulo"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Practice days count finished sessions on any instrument
    Given "alice" finished a session with "guitar" in hand on Monday and with "electric-bass" in hand on Tuesday
    When "alice" reads their practice overview
    Then the overview shows 2 practice days in the last 7

  Scenario: Learning days count the days a content node was completed
    Given "alice" completed content nodes on 3 of the last 7 days
    When "alice" reads their practice overview
    Then the overview shows 3 learning days in the last 7

  Scenario: Each instrument has a card with its own practice days and top next step
    Given "alice" finished sessions with "guitar" in hand on 2 days and with "electric-bass" in hand on 1 day
    And "alice"'s first next step on guitar is to strengthen "notes-on-low-strings"
    When "alice" reads their practice overview
    Then the "guitar" card shows 2 practice days and the next step to strengthen "notes-on-low-strings"
    And the "electric-bass" card shows 1 practice day

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Two instruments practised on the same day count as one practice day
    Given "alice" finished a session with "guitar" in hand and another with "electric-bass" in hand on Monday
    When "alice" reads their practice overview
    Then the overview shows 1 practice day in the last 7

  Scenario: A session left early is not a practice day on the overview either
    Given "alice"'s only session yesterday, with "guitar" in hand, ended early
    When "alice" reads their practice overview
    Then the overview shows 0 practice days in the last 7

  Scenario: An instrument with nothing to do next has a card without a next step
    Given "alice" has no next step on "electric-bass"
    When "alice" reads their practice overview
    Then the "electric-bass" card has no next step

  Scenario: A student enrolled in nothing for an instrument has no cards, and still sees their days
    Given student "bruno" is enrolled only in a music-theory path for every instrument
    And "bruno" completed a content node yesterday
    When "bruno" reads their practice overview
    Then the overview has no instrument cards
    And the overview shows 1 learning day in the last 7

  Scenario: Days follow the student's time zone
    Given "alice" completed a content node at 23:30 on Monday in "America/Sao_Paulo", which is Tuesday in UTC
    When "alice" reads their practice overview in time zone "America/Sao_Paulo"
    Then that completion counts on Monday

  # ── Minutes, day streak and skills up ──────────────────────────────────────
  # Effort, consistency and improvement for the home's "This week" tiles. All three come from the
  # activity already kept: session starts, answers and ends, and the daily item snapshots.

  @wip
  Scenario: Minutes practised add up every session this week
    Given "alice" practised from 18:00 to 18:12 on Monday and from 19:00 to 19:20 on Wednesday
    When "alice" reads their practice overview
    Then the overview shows 32 minutes practised in the last 7 days

  @wip
  Scenario: Minutes practised the week before are shown for comparison
    Given "alice" practised 20 minutes 9 days ago and 15 minutes 12 days ago
    When "alice" reads their practice overview
    Then the overview shows 35 minutes practised in the previous 7 days

  @wip
  Scenario: A session left early still counts its minutes
    Given "alice" started a session at 18:00 yesterday, answered until 18:06 and left early
    When "alice" reads their practice overview
    Then the overview shows 6 minutes practised in the last 7 days
    And the overview shows 0 practice days in the last 7

  @wip
  Scenario: An abandoned session counts up to its last answer
    Given "alice" started a 10-minute session at 18:00 yesterday and sent nothing for it after an answer at 18:04
    When "alice" reads their practice overview
    Then the overview shows 4 minutes practised in the last 7 days

  @wip
  Scenario: Minutes round down to whole minutes
    Given "alice" practised for 7 minutes and 50 seconds yesterday
    When "alice" reads their practice overview
    Then the overview shows 7 minutes practised in the last 7 days

  @wip
  Scenario: The day streak counts consecutive practice days up to today
    Given "alice" finished a session on each of the last 3 days, today included
    When "alice" reads their practice overview
    Then the overview shows a day streak of 3

  @wip
  Scenario: Today without practice yet doesn't break the streak
    Given "alice" finished a session on each of the 4 days before today
    And "alice" has not practised today
    When "alice" reads their practice overview
    Then the overview shows a day streak of 4

  @wip
  Scenario: A missed day ends the current streak and keeps the best one
    Given "alice" finished a session on 9 consecutive days, missed the next day, and has finished a session on each of the 2 days since, today included
    When "alice" reads their practice overview
    Then the overview shows a day streak of 2
    And the overview shows a best day streak of 9

  @wip
  Scenario: Neither today nor yesterday practised means no current streak
    Given "alice" last finished a session 2 days ago
    When "alice" reads their practice overview
    Then the overview shows a day streak of 0

  @wip
  Scenario: A day left early is not a streak day
    Given "alice" finished a session 2 days ago and today, and their only session yesterday ended early
    When "alice" reads their practice overview
    Then the overview shows a day streak of 1

  @wip
  Scenario: Two instruments on the same day are one streak day
    Given "alice" finished a session with "guitar" in hand and another with "electric-bass" in hand today
    And "alice" finished no session before today
    When "alice" reads their practice overview
    Then the overview shows a day streak of 1

  @wip
  Scenario: The streak follows the student's time zone
    Given "alice" finished a session at 23:30 yesterday in "America/Sao_Paulo", which is today in UTC
    And "alice" finished a session today
    When "alice" reads their practice overview in time zone "America/Sao_Paulo"
    Then the overview shows a day streak of 2

  @wip
  Scenario: Skills up counts each improved skill once per instrument
    Given "alice"'s accuracy and fluency on "notes-on-low-strings" on guitar both improved this week
    And "alice"'s best clean tempo on "root-fifth-groove" on electric-bass improved this week
    When "alice" reads their practice overview
    Then the overview shows 2 skills up in the last 7 days

  @wip
  Scenario: A concept that improved is not a skill up
    Given "alice"'s accuracy on the concept "intervals" improved this week
    And no skill of "alice" improved this week
    When "alice" reads their practice overview
    Then the overview shows 0 skills up in the last 7 days

  # Songs played (ADR-051 amendment 2026-10-09): distinct song charts marked as played with the
  # reader's "I played it" (song_chart.completed). Across instruments: charts have none.

  Scenario: Songs played counts each chart the student marked as played
    Given "alice" marked the song charts "Asa Branca" and "Amazing Grace" as played
    When "alice" reads their practice overview
    Then the overview shows 2 songs played

  Scenario: A song first played this week counts in this week's songs
    Given "alice" first marked "Asa Branca" as played 10 days ago
    And "alice" first marked "Amazing Grace" as played yesterday
    When "alice" reads their practice overview
    Then the overview shows 2 songs played
    And the overview shows 1 song played in the last 7 days

  Scenario: Marking the same chart as played again counts it once
    Given "alice" first marked "Asa Branca" as played 10 days ago
    And "alice" marked "Asa Branca" as played again today
    When "alice" reads their practice overview
    Then the overview shows 1 song played
    And the overview shows 0 songs played in the last 7 days

  Scenario: A chart withdrawn after it was played still counts
    Given "alice" marked the song chart "Asa Branca" as played
    And "Asa Branca" was withdrawn afterwards
    When "alice" reads their practice overview
    Then the overview shows 1 song played

  Scenario: A played mark for a song chart that doesn't exist is not counted
    Given a song_chart.completed event from "alice" names a song chart that doesn't exist
    When "alice" reads their practice overview
    Then the overview shows 0 songs played

  @wip
  Scenario: A student who has never practised starts at zero
    Given student "bruno" has never practised
    When "bruno" reads their practice overview
    Then the overview shows 0 minutes practised in the last 7 days
    And the overview shows a day streak of 0
    And the overview shows a best day streak of 0
    And the overview shows 0 songs played

  # ── Where it shows ─────────────────────────────────────────────────────────

  @web
  Scenario: Signing in opens the home on the practice overview
    When "alice" signs in
    Then "alice" sees their practice overview first

  @web
  Scenario: Practice in the navigation opens the session setup
    When "alice" chooses Practice in the navigation
    Then the practice session setup opens, without a page in between

  @web
  Scenario: Starting today's practice chooses its instrument
    Given the home's today's practice is "alice"'s top next step on "electric-bass"
    When "alice" starts today's practice from the home
    Then the session setup opens with "electric-bass" in hand chosen

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: An overview in an unknown time zone is rejected
    When "alice" reads their practice overview in time zone "Mars/Olympus_Mons"
    Then the request is rejected as invalid
    And the rejection identifies "time_zone" as the source of the error
