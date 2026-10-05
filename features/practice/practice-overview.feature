@wip
Feature: Show the student's practice overview across instruments
  As a student
  I want to see at a glance that I've been practising and learning, whatever I played
  So that every session counts toward my sense of progress, before I pick an instrument

  # The overview is the practice home's first view. Practice days here count finished sessions
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

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: An overview in an unknown time zone is rejected
    When "alice" reads their practice overview in time zone "Mars/Olympus_Mons"
    Then the request is rejected as invalid
    And the rejection identifies "time_zone" as the source of the error
