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
    Given "alice"'s accuracy on "notes-on-low-strings" was 0.72 seven days ago and is 0.86 now
    When "alice" reads their practice summary for "guitar"
    Then the progress this week shows "notes-on-low-strings" accuracy from 0.72 to 0.86

  Scenario: Next steps show the top three and how many there are in all
    Given "alice" has 5 skills to refresh, strengthen or start on guitar
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 3 next steps and a total of 5

  Scenario: The summary lists the student's instruments
    When "alice" reads their practice summary for "guitar"
    Then the summary lists "guitar" and "electric-bass" as their instruments

  Scenario: Fading skills come first in the next steps, as refresh
    Given "alice"'s skill "notes-on-low-strings" on guitar rests on items whose review is due
    And "alice" has a skill to strengthen and a skill ready to start on guitar
    When "alice" reads their practice summary for "guitar"
    Then the next steps are "notes-on-low-strings" to refresh, then the skill to strengthen, then the skill ready to start

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A missed day never resets anything
    Given "alice" practised on 6 consecutive days and then missed a day
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 6 practice days in the last 7

  Scenario: A session the student left early is not a practice day
    Given "alice"'s only session yesterday ended early
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 0 practice days in the last 7

  Scenario: An abandoned session is not a practice day
    Given "alice" started a 10-minute session yesterday and sent nothing for it after the first 5 minutes
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 0 practice days in the last 7

  Scenario: A session finished on another instrument is not a practice day for this one
    Given "alice" finished a session with "electric-bass" in hand yesterday
    When "alice" reads their practice summary for "guitar"
    Then the summary shows 0 practice days in the last 7

  Scenario: A skill first practised this week starts its progress from 0
    Given "alice" first practised "notes-on-low-strings" 3 days ago and their accuracy on it is 0.8 now
    When "alice" reads their practice summary for "guitar"
    Then the progress this week shows "notes-on-low-strings" accuracy from 0 to 0.8

  Scenario: A tempo improvement needs a clean take 7 days ago
    Given "alice" had no clean take on "pentatonic-run" seven days ago and their best clean tempo on it is 105 BPM now
    When "alice" reads their practice summary for "guitar"
    Then the progress this week has no tempo line for the skill of "pentatonic-run"

  Scenario: A path for every instrument adds no instrument
    Given "alice" is also enrolled in a music-theory path for every instrument
    When "alice" reads their practice summary for "guitar"
    Then the summary lists only "guitar" and "electric-bass" as their instruments

  Scenario: A skill unconnected to what the student is learning is not a next step
    Given "alice" is ready to start the skill "slide-technique", which requires nothing and has no link to their path
    When "alice" reads their practice summary for "guitar"
    Then "slide-technique" is not among the next steps

  Scenario: A skill that builds on what the student has met is ready to start
    Given "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" reads their practice summary for "guitar"
    Then the next steps include "notes-on-high-strings" as ready to start

  Scenario: A skill with nothing to practise on the instrument is not a next step
    Given the skill "slap-technique" has practice items only for "electric-bass"
    And "alice" is ready to start "slap-technique"
    When "alice" reads their practice summary for "guitar"
    Then "slap-technique" is not among the next steps

  Scenario: Practice days follow the student's time zone
    Given "alice" practised at 23:30 on Monday in "America/Sao_Paulo", which is Tuesday in UTC
    When "alice" reads their practice summary for "guitar" in time zone "America/Sao_Paulo"
    Then that practice counts on Monday

  Scenario: Nodes that suit any instrument get their own group
    Given the concept "intervals" has exercises for every instrument
    When "alice" reads their practice summary for "guitar"
    Then "intervals" is in the "Any instrument" group, not in a guitar area

  Scenario: A summary without an instrument covers only what suits any instrument
    Given the concept "intervals" has exercises for every instrument
    And the skill "slap-technique" has practice items only for "electric-bass"
    When "alice" reads their practice summary without an instrument
    Then "intervals" is in the "Any instrument" group, not in a guitar area
    And "slap-technique" is in no group

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
