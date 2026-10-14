# Alpha observation in Teach (MOT-8, PB-8h).
#
# An admin-only, read-only section of Teach that shows the alpha against PB-8's success metric.
# The section is labelled "Engagement" (pt-BR "Engajamento"); "alpha observation" stays the name of
# the API and of these files.
# The rules behind every number are in features/core-domain/alpha-observation.feature, and the raw
# events in features/event-ingestion/read-event-log.feature. Design: design/patterns/authoring.md
# ("Alpha observation") and the "Authoring" Figma page, row 19 (decisions D1–D9, approved
# 2026-10-14).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: Observe the alpha in Teach
  As an admin running the alpha
  I want the alpha's measures, each student's detail and the raw events in one place in Teach
  So that I can judge PB-8's success metric and see who needs a hand

  Background:
    Given "ana" is signed in as an admin
    And now is Wednesday 14 Oct 2026, São Paulo time
    And the alpha has 7 students

  # ── Where it lives ───────────────────────────────────────────────────────

  Scenario: Admins find "Engagement" in Teach's Admin group
    When "ana" opens Teach
    Then the Admin group lists "Knowledge map", "Song charts" and "Engagement", in that order

  Scenario: Teachers do not see "Engagement"
    Given "tina" is signed in as a teacher
    When "tina" opens Teach
    Then there is no "Engagement" entry

  Scenario: A teacher who opens the Engagement address is turned away
    Given "tina" is signed in as a teacher
    When "tina" opens the Engagement address directly
    Then "tina" is taken to Teach home

  Scenario: Nothing in Engagement can be changed
    When "ana" opens Engagement
    Then the overview, student and events screens offer no way to edit, add or delete anything

  # ── Overview ─────────────────────────────────────────────────────────────

  Scenario: The overview opens on the running week
    When "ana" opens Engagement
    Then the week stepper shows "This week · 12–18 Oct"
    And the page says the week is still running
    And the stepper's "next week" control is disabled

  Scenario: Stepping back shows an earlier week
    Given "ana" is on the Engagement overview for the week of 12 Oct
    When "ana" steps back one week
    Then the overview shows the week of 5–11 Oct, with no "still running" note

  Scenario: The four tiles show both targets
    When "ana" opens Engagement
    Then the tiles read "3+ sessions this week", "3+ every week so far", "First path over 70%" and "Median first path"
    And the first three show a count out of 7 and the last a percentage

  Scenario: Each student's row shows the week, the weeks so far and the first path
    Given "camila" has 2 counted sessions this week, was at the target in 3 of 3 weeks so far and has completed 11 of 18 nodes of "Guitar foundations"
    When "ana" opens Engagement
    Then "camila"'s row shows "2 sessions" with a "1 to go" chip
    And it shows a bar for each of the 3 weeks so far against a line at 3, captioned "3 of 3 weeks at 3+"
    And it shows "Guitar foundations", a bar filled to 61% with a mark at 70%, and "11 of 18 nodes · 61%"

  Scenario Outline: The week chip says how far a student is from 3
    Given "<student>" has <count> counted sessions this week
    When "ana" opens Engagement
    Then "<student>"'s row shows the chip "<chip>"

    Examples:
      | student | count | chip      |
      | lucas   | 0     | None yet  |
      | rafael  | 1     | 2 to go   |
      | camila  | 2     | 1 to go   |
      | marina  | 3     | On target |
      | thiago  | 4     | On target |

  Scenario: A quiet student's last activity is shown as a warning
    Given "lucas"'s last activity was 9 days ago
    When "ana" opens Engagement
    Then "lucas"'s row shows "9 days ago" in the danger colour

  Scenario: Filter chips narrow the list and keep their counts
    Given 4 students are below 3 this week and 1 is quiet
    When "ana" picks the chip "Below 3 this week · 4"
    Then only those 4 students are listed
    And the chips still read "All · 7", "Below 3 this week · 4" and "Quiet 7+ days · 1"

  Scenario: Searching narrows the list by name
    When "ana" searches students for "rocha"
    Then only "Beatriz Rocha" is listed

  Scenario: A row opens the student
    When "ana" picks "camila"'s row
    Then the student screen for "camila" opens, for the same week

  # ── One student ──────────────────────────────────────────────────────────

  Scenario: The student screen lists sessions by week, with the ones that don't count
    Given "camila" finished 2 sessions and ended 1 early this week
    When "ana" opens "camila"'s student screen
    Then the sessions are grouped "This week · 12–18 Oct · 2 finished" and "Last week · 5–11 Oct"
    And the ended-early session shows the chip "Ended early" and the others "Finished"
    And a note says only finished sessions count toward 3+

  Scenario: "Earlier weeks" moves the session list two weeks back
    Given "ana" is on "camila"'s student screen for the week of 12 Oct
    When "ana" picks "Earlier weeks"
    Then the sessions of the weeks of 28 Sep and 21 Sep are listed

  Scenario: The first path is shown node by node
    When "ana" opens "camila"'s student screen
    Then the first path card lists every node of "Guitar foundations" in order
    And completed nodes show their completion date, the node in progress shows when it started, and nodes not started show no date

  Scenario: "See events" opens the events filtered to the student
    When "ana" picks "See events" on "camila"'s student screen
    Then the events screen opens with the student chip "Camila Duarte" selected

  # ── Events ───────────────────────────────────────────────────────────────

  Scenario: Events are listed newest first, 12 at a time
    When "ana" opens the events screen
    Then the 12 most recently received events are listed with when they were received, the student's name, the event type and its details
    And "Load 12 more" adds the next 12 below them

  Scenario: Every student has a chip of their own
    When "ana" opens the events screen
    Then the student chips are "All students" and one chip for each of the 7 students

  Scenario: The type chips filter by group
    When "ana" picks the type chip "Practice sessions"
    Then only practice.session_started and practice.session_ended events are listed

  Scenario: The count says how many events match
    Given "camila" has 46 events
    When "ana" picks the student chip "Camila Duarte"
    Then the count reads "46 events for Camila Duarte · showing the latest 12"

  # ── Sizes and states ─────────────────────────────────────────────────────

  Scenario: On Compact the student screen uses tabs
    Given the screen is 390 px wide
    When "ana" opens "camila"'s student screen
    Then a summary shows the week's sessions, the weeks at 3+ and the first path's percentage
    And "Sessions", "First path" and "Events" are tabs

  Scenario: The overview says when the alpha has no students yet
    Given no student has been given a path
    When "ana" opens Engagement
    Then the page says no student is in the alpha yet, in place of the tiles and the list

  Scenario: A failed load offers a retry
    Given the alpha observation cannot be loaded
    When "ana" opens Engagement
    Then the page says it could not load the alpha and offers "Try again"

  Scenario: The section reads in Portuguese
    Given "ana"'s interface language is Portuguese (Brazil)
    When "ana" opens Engagement
    Then the titles, tiles, chips and column labels are in Portuguese
    And event types stay as their exact names
