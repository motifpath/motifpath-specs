# Alpha observation (MOT-8, PB-8h): the measurement behind PB-8's success metric.
#
# PB-8 succeeds when alpha students practise at least 3 times a week and complete more than 70% of
# their first path. This read is how an admin checks both, a week at a time and one student at a
# time. It changes nothing. Design: design/patterns/authoring.md ("Alpha observation") and the
# "Authoring" Figma page, row 19 (decisions D1–D9, approved 2026-10-14; D10–D12, for an alpha of
# thousands, approved 2026-10-15).
#
# Terms used below:
# - The alpha: every user with the student role who has been given at least one path. Teachers and
#   admins who also learn are not in it (D2).
# - First path: the student's earliest-given path, kept even if a later one replaced it (D5).
# - Completion: the first path's nodes with status completed, divided by all of its nodes. Shown
#   rounded down to a whole percent; "over the target" compares the exact share, so it is strictly
#   more than 70% (D5).
# - A week: Monday 00:00 to Sunday 24:00, São Paulo time, for everyone (D4). The running week is
#   the one that contains now.
# - A session counts only when it is finished (D3). Ended early, abandoned and in progress are
#   reported but never counted. Session states: features/practice/practice-sessions.feature.
# - A student is at the target in a week with 3 or more counted sessions.
# - Weeks so far: the finished weeks from the week the student's first path was given; the running
#   week is never one of them.
# - Quiet: the student's last activity of any kind is 7 days or more before now; a student with no
#   activity at all is quiet once their first path is 7 days old (D6).
# - The raw events behind these numbers are read from the event log:
#   features/event-ingestion/read-event-log.feature.

Feature: Observe the alpha against PB-8's success metric
  As an admin running the alpha
  I want each week's practice and each student's first-path progress measured the same way
  So that I can tell whether the alpha meets PB-8's success metric, and who is falling behind

  Background:
    Given "ana" is signed in as an admin
    And now is Wednesday 14 Oct 2026 at 10:00, São Paulo time
    And "alice" is a student who was given the path "Guitar foundations", 18 nodes, on Monday 21 Sep 2026

  # ── Who is in the alpha ──────────────────────────────────────────────────

  Scenario: A student with a path is in the alpha
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice" is one of its students

  Scenario: A student who has never been given a path is not in the alpha
    Given "bruno" is a student who has never been given a path
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "bruno" is not one of its students

  Scenario: A teacher who also learns is not in the alpha
    Given "tina" is a teacher who was given the path "Blues guitar basics"
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "tina" is not one of its students

  # ── Sessions in a week ───────────────────────────────────────────────────

  Scenario: Finished sessions count toward the week
    Given "alice" finished practice sessions on Monday 12 Oct at 18:30 and on Wednesday 14 Oct at 07:40
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice" has 2 counted sessions in that week
    And "alice" is not at the target in that week

  Scenario: Ended-early, abandoned and in-progress sessions do not count
    Given "alice" finished a practice session on Monday 12 Oct at 18:30
    And "alice" ended a practice session early on Monday 12 Oct at 19:09
    And "alice" abandoned a practice session on Tuesday 13 Oct
    And "alice" has a practice session in progress since Wednesday 14 Oct at 09:55
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice" has 1 counted session in that week

  Scenario: Three finished sessions reach the target
    Given "alice" finished practice sessions on Monday 5 Oct, Wednesday 7 Oct and Saturday 10 Oct
    When "ana" observes the alpha for the week of 5 Oct 2026
    Then "alice" has 3 counted sessions in that week
    And "alice" is at the target in that week

  Scenario: A session belongs to the week of its start in São Paulo time
    Given "alice" finished a practice session that started on Sunday 11 Oct at 23:50, São Paulo time, and ended on Monday 12 Oct at 00:05
    When "ana" observes the alpha for the week of 5 Oct 2026
    Then "alice" has 1 counted session in that week

  Scenario: The running week says it is still running
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then the week of 12 Oct 2026 is reported as still running

  Scenario: Observing without a week shows the running week
    When "ana" observes the alpha without choosing a week
    Then the alpha is observed for the week of 12 Oct 2026

  # ── Weeks so far ─────────────────────────────────────────────────────────

  Scenario: Weeks so far start at the week the first path was given and exclude the running week
    Given "alice" finished 3, 4 and 3 practice sessions in the weeks of 21 Sep, 28 Sep and 5 Oct 2026
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice"'s weeks so far are 21 Sep with 3 sessions, 28 Sep with 4 and 5 Oct with 3
    And "alice" is at the target in 3 of 3 weeks so far

  Scenario: A week below the target breaks "every week so far"
    Given "alice" finished 3, 2 and 3 practice sessions in the weeks of 21 Sep, 28 Sep and 5 Oct 2026
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice" is at the target in 2 of 3 weeks so far
    And "alice" is not counted as at the target every week so far

  Scenario: A student with no finished week yet is not counted as at the target every week
    Given "gil" is a student who was given a path on Monday 12 Oct 2026 and finished 3 practice sessions since
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "gil" has no weeks so far
    And "gil" is not counted as at the target every week so far

  Scenario: A locked node of the first path is reported as not started
    Given the 13th node of "Guitar foundations" is locked for "alice"
    When "ana" observes "alice" for the week of 12 Oct 2026
    Then the 13th node is listed as not started

  Scenario: At most the last 8 weeks so far are listed
    Given "carla" is a student who was given a path on Monday 3 Aug 2026
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "carla"'s weeks so far list the 8 weeks from 17 Aug to 5 Oct 2026
    And "carla"'s count of weeks at the target covers all 10 weeks so far

  # ── First path ───────────────────────────────────────────────────────────

  Scenario: Completion is the first path's completed nodes over all its nodes
    Given "alice" has completed 11 of the 18 nodes of "Guitar foundations"
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice"'s first path is "Guitar foundations" at 11 of 18 nodes, 61%
    And "alice"'s first path is not over the target

  Scenario: Exactly 70% is not over the target
    Given "dora" was given a path of 10 nodes and has completed 7 of them
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "dora"'s first path is at 70%
    And "dora"'s first path is not over the target

  Scenario: Just over 70% is over the target and still shown rounded down
    Given "eva" was given a path of 1000 nodes and has completed 701 of them
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "eva"'s first path is at 70%
    And "eva"'s first path is over the target

  Scenario: The first path stays the first after a later path replaces it
    Given "alice" was given the path "Blues guitar basics" on Monday 5 Oct 2026, now "alice"'s current path
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice"'s first path is "Guitar foundations"

  # ── The cohort ───────────────────────────────────────────────────────────

  Scenario: The cohort counts students at each target
    Given the alpha has 4 students
    And 1 of them has 3 or more counted sessions in the week of 12 Oct 2026, and 3 had in the week of 5 Oct
    And 2 of them have been at the target every week so far
    And their first paths are at 17%, 45%, 72% and 78%
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then 1 of 4 students is at the target this week and 3 of 4 were the week before
    And 2 of 4 students have been at the target every week so far
    And 2 of 4 students have a first path over the target
    And the median first path is 58%

  Scenario: Students are listed by fewest counted sessions in the week, then by name
    Given "alice" and "bia" each have 1 counted session in the week of 12 Oct 2026 and "caio" has 0
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then the students are listed as "caio", "alice", "bia"

  # ── Quiet students ───────────────────────────────────────────────────────

  Scenario: A student whose last activity is 7 days old is quiet
    Given "alice"'s last activity was a song_chart.opened on Wednesday 7 Oct at 10:00
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice"'s last activity is Wednesday 7 Oct at 10:00
    And "alice" is quiet

  Scenario: A student active within the last 7 days is not quiet
    Given "alice"'s last activity was a lesson.started on Wednesday 7 Oct at 10:01
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "alice" is not quiet

  Scenario: A student with no activity at all is quiet once the first path is 7 days old
    Given "fabio" is a student who was given a path on Monday 5 Oct 2026 and has no activity
    When "ana" observes the alpha for the week of 12 Oct 2026
    Then "fabio" has no last activity
    And "fabio" is quiet

  # ── One student ──────────────────────────────────────────────────────────

  Scenario: One student's sessions are listed for the chosen week and the week before
    Given "alice" finished a practice session on Monday 12 Oct at 18:30 and ended one early on Saturday 10 Oct
    When "ana" observes "alice" for the week of 12 Oct 2026
    Then the sessions of the weeks of 12 Oct and 5 Oct 2026 are listed, newest first
    And each session shows its start, planned minutes, end, state and items answered

  Scenario: One student's first path is listed node by node
    Given "alice" has completed the first 11 nodes of "Guitar foundations" and started the 12th
    When "ana" observes "alice" for the week of 12 Oct 2026
    Then the 18 nodes of "Guitar foundations" are listed in path order
    And nodes 1 to 11 are completed with their completion dates, node 12 is in progress and nodes 13 to 18 are not started

  # ── Pages, filters and search (D11) ──────────────────────────────────────

  @wip
  Scenario: Students come a page at a time, in the same order
    Given the alpha has 45 students
    When "ana" observes the alpha for the week of 12 Oct 2026, 20 students at a time
    Then 20 students are listed and 45 students match
    And asking for the next 20 lists the 21st to the 40th student in the same order

  @wip
  Scenario: A filter keeps only the students below the target
    Given the alpha has 7 students and 4 of them have fewer than 3 counted sessions in the week of 12 Oct 2026
    When "ana" observes the alpha for the week of 12 Oct 2026, keeping only the students below the target
    Then those 4 students are listed and 4 students match

  @wip
  Scenario: Every filter's count describes the whole alpha, whatever is asked for
    Given the alpha has 7 students, 4 below the target in the week of 12 Oct 2026 and 1 quiet
    When "ana" observes the alpha for the week of 12 Oct 2026, keeping only the quiet students
    Then the filter counts are 7 in all, 4 below the target and 1 quiet
    And the cohort summary still counts all 7 students

  @wip
  Scenario: Searching by name ignores case and accents
    Given "João Araújo" and "Beatriz Rocha" are students in the alpha
    When "ana" observes the alpha for the week of 12 Oct 2026, searching for "joao araujo"
    Then only "João Araújo" is listed

  # ── Students by name (D10, D12) ──────────────────────────────────────────

  @wip
  Scenario: Students of the alpha are found by part of their name
    Given "Camila Duarte", "Camila Rocha" and "Beatriz Rocha" are students in the alpha
    When "ana" looks for students of the alpha named "cami"
    Then "Camila Duarte" and "Camila Rocha" are found, in that order

  @wip
  Scenario: Students are named by their ids, leaving out anyone outside the alpha
    Given "tina" is a teacher who also learns
    When "ana" asks for the names of "alice" and "tina"
    Then only "alice" is named

  @wip
  Scenario: Only admins may look students of the alpha up
    Given "tina" is signed in as a teacher
    When "tina" looks for students of the alpha named "a"
    Then "tina" is refused for lacking permission

  # ── Failure cases ────────────────────────────────────────────────────────

  Scenario: Only admins may observe the alpha
    Given "tina" is signed in as a teacher
    When "tina" observes the alpha for the week of 12 Oct 2026
    Then "tina" is refused for lacking permission

  Scenario: A week must start on a Monday
    When "ana" observes the alpha for the week of 14 Oct 2026
    Then the request is rejected as invalid
    And the rejection identifies "week" as the source of the error

  Scenario: A week after the running one cannot be observed
    When "ana" observes the alpha for the week of 19 Oct 2026
    Then the request is rejected as invalid
    And the rejection identifies "week" as the source of the error

  Scenario: Observing someone outside the alpha finds no student
    Given "bruno" is a student who has never been given a path
    When "ana" observes "bruno" for the week of 12 Oct 2026
    Then no student is found
