@wip
Feature: Show the student's practice summary on the home
  As a student
  I want to see that I'm practising, what improved, and what to do next
  So that I keep coming back because I can see myself getting better

  Background:
    Given student "alice" plays "guitar" and "electric-bass" in time zone "America/Sao_Paulo"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Practice days count the days practised in the last week
    Given "alice" practised on 4 of the last 7 days
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 4 practice days in the last 7

  Scenario: Progress this week shows where a skill started and where it is now
    Given "alice"'s accuracy on "notes-on-low-strings" was 0.72 at the start of the week and is 0.86 now
    When "alice" reads their practice summary for "guitar"
    Then the progress this week shows "notes-on-low-strings" accuracy from 0.72 to 0.86

  Scenario: Next steps show the top three and how many there are in all
    Given "alice" has 5 skills to refresh, strengthen or start on guitar
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 3 next steps and a total of 5

  Scenario: The summary lists the student's instruments
    When "alice" reads their practice summary for "guitar"
    Then the summary lists "guitar" and "electric-bass" as their instruments

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A missed day never resets anything
    Given "alice" practised on 6 consecutive days and then missed a day
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 6 practice days in the last 7

  Scenario: Practice days follow the student's time zone
    Given "alice" practised at 23:30 on Monday in "America/Sao_Paulo", which is Tuesday in UTC
    When "alice" reads their practice summary for "guitar" in time zone "America/Sao_Paulo"
    Then that practice counts on Monday

  Scenario: Nodes that suit any instrument get their own group
    Given the concept "intervals" has exercises for every instrument
    When "alice" reads their practice summary for "guitar"
    Then "intervals" is in the "Any instrument" group, not in a guitar area

  Scenario: Concepts are not progress lines
    Given "alice"'s accuracy on the concept "intervals" improved this week
    When "alice" reads their practice summary for "guitar"
    Then the progress this week has no line for "intervals"

  Scenario: A student with nothing practised yet sees no progress and their next steps
    Given "alice" has never practised
    When "alice" reads their practice summary for "guitar"
    Then the progress this week is empty
    And the next steps start with skills they are ready to start

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A summary for an instrument that doesn't exist is refused
    When "alice" reads their practice summary for an instrument that doesn't exist
    Then the request is refused with a not-found error

  Scenario: A summary in an unknown time zone is rejected
    When "alice" reads their practice summary for "guitar" in time zone "Mars/Olympus_Mons"
    Then the request is rejected as invalid
    And the rejection identifies "time_zone" as the source of the error
