# Discover (MOT-58 design, implemented in MOT-87).
#
# The learner catalog of courses and paths behind one Courses | Paths control, its short filters,
# the path detail, and starting a course or a path from its detail. The pattern is
# design/patterns/discover.md; the Figma page is "Discover" (rows 1–5). The course detail itself is
# in features/web/learning.feature; Discover only adds the way in. What enrolling does on the
# server is in features/learning-paths/course-enrollment.feature and path-enrollment.feature.
#
# The catalog orders by title and knows nothing about the student: the In Learning and Finished
# badges come from the student's own enrolments and paths. Search matches the title and summary.
# Filters open the same way from a tablet up: a 480 px dialog with a live count (decided
# 2026-10-12, replacing the signed-off side panel on Expanded, so every size class reuses the
# phone's fields).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: Find a course or a path to start
  As a student looking for something to learn
  I want one place with one search and a few filters for courses and paths
  So that I find something to start in a few taps, without knowing how the content is organised

  Background:
    Given "alice" is signed in as a student
    And the catalog has the courses "Blues basics", "Fingerstyle foundations" and "Reading rhythm"
    And the catalog has the paths "Blues shuffle" and "Open chords"

  # ── The list ──────────────────────────────────────────────────────────────

  Scenario: Discover opens on courses
    When "alice" opens Discover
    Then Courses is chosen in the Courses | Paths control
    And the count line reads "3 courses · A–Z"
    And the courses are listed by title

  Scenario: A course row shows what the course is, without a button
    Given "Blues basics" is a Beginner course in English for guitar, by "Bruno", with 4 parts and 44 lessons
    When "alice" opens Discover
    Then the "Blues basics" row reads "Beginner · English" above its title
    And it reads "by Bruno" and "Guitar · 4 parts · 44 lessons"
    And the row has no button

  Scenario: A path row counts its lessons
    Given "Open chords" is a guitar path with 9 lessons
    When "alice" opens Discover on Paths
    Then the "Open chords" row reads "Guitar · 9 lessons"

  Scenario: Tapping a row opens its detail
    When "alice" taps the "Blues shuffle" row on Paths
    Then the path detail of "Blues shuffle" opens

  Scenario: A course the student has started is marked In Learning
    Given "alice" is enrolled in "Reading rhythm"
    When "alice" opens Discover
    Then the "Reading rhythm" row has an "In Learning" badge on its thumbnail

  Scenario: A course the student finished is marked Finished
    Given "alice" finished "Blues basics"
    When "alice" opens Discover
    Then the "Blues basics" row has a "Finished" badge on its thumbnail

  Scenario: More rows load as the student scrolls
    Given the catalog has 45 courses
    When "alice" opens Discover
    Then 20 courses are listed
    When "alice" scrolls to the end of the list
    Then 40 courses are listed

  Scenario: On a desktop the results are tiles
    When "alice" opens Discover on a screen 1280 px wide
    Then the courses show as tiles in 3 columns

  # ── Search and the address ────────────────────────────────────────────────

  Scenario: Search runs as the student types
    When "alice" types "blues" in the search
    Then after a short pause only "Blues basics" is listed
    And the count line reads "1 course · A–Z"

  Scenario: Search and filters carry over between Courses and Paths
    Given "alice" searched "blues" and chose the level Beginner on Courses
    When "alice" chooses Paths
    Then the search still reads "blues" and the Beginner filter is still on
    And only "Blues shuffle" is listed

  Scenario: Back from a detail returns to the same list
    Given "alice" searched "blues" on Paths
    When "alice" opens "Blues shuffle" and goes back
    Then Discover shows Paths with the search "blues"

  Scenario: A shared Discover address opens the same list
    When "alice" opens a Discover address with Paths, the search "chords" and the level Beginner
    Then Discover shows Paths with the search "chords" and the Beginner filter on

  # ── Filters ───────────────────────────────────────────────────────────────

  Scenario: A student filters by level, instrument, language and teacher only
    When "alice" opens the filters
    Then they offer Level, Instrument and Language as chips, and Teacher as a row
    And there is no skill or concept filter

  Scenario: Several levels can be chosen, one of each other filter
    When "alice" opens the filters
    And "alice" chooses Beginner and Intermediate
    And "alice" chooses Guitar, then Bass
    Then Beginner and Intermediate are both chosen
    And only Bass is chosen as the instrument

  Scenario: The filter sheet counts what it would show
    Given "alice" is on a phone
    When "alice" opens the filters and chooses Beginner
    Then the sheet's primary action reads "Show 2 courses"
    And the list behind it has not changed yet

  Scenario: Showing applies the filters
    Given "alice" chose Beginner in the filter sheet
    When "alice" taps "Show 2 courses"
    Then the sheet closes
    And a removable "Beginner" chip shows under the search
    And the filter button says 1 filter is on

  Scenario: The teacher list replaces the sheet's content
    Given "alice" is on a phone
    When "alice" opens the filters and taps Teacher
    Then the sheet shows a searchable list of teachers with "Any teacher" first, and a back arrow
    And no second sheet opens on top

  Scenario: From a tablet up the filters open as a dialog
    When "alice" opens the filters on a screen 1280 px wide
    Then the same filters open in a dialog with "Clear all" and "Show 3 courses"

  Scenario: Removing a chip removes its filter
    Given "alice" filtered by Beginner and Guitar
    When "alice" removes the "Guitar" chip
    Then only the Beginner filter is on

  Scenario: Clear all removes every filter but keeps the search
    Given "alice" searched "blues" and filtered by Beginner and Guitar
    When "alice" taps "Clear all"
    Then no filter is on
    And the search still reads "blues"

  Scenario: A skill arrives as a context chip
    Given the skill "Shuffle rhythm" is taught by "Blues basics" and "Reading rhythm"
    When "alice" opens Discover from "Find courses for this skill" on "Shuffle rhythm"
    Then a removable "Shuffle rhythm" chip shows under the search
    And "Blues basics" and "Reading rhythm" are listed

  Scenario: The filters still offer no skill picker after a skill arrives
    Given "alice" opened Discover with the skill "Shuffle rhythm"
    When "alice" opens the filters
    Then there is no skill or concept filter in them

  # ── No matches, loading and errors ────────────────────────────────────────

  Scenario: No matches names the search and offers to clear the filters
    When "alice" searches "shuffle" with the level Advanced
    Then it says "No courses match" with the search "shuffle" and the Advanced filter
    And it offers "Clear filters"

  Scenario: No matches points to the other segment when it has some
    Given no course matches "shuffle" but the path "Blues shuffle" does
    When "alice" searches "shuffle" on Courses
    Then it says "1 path matches" with "Show paths"
    When "alice" taps "Show paths"
    Then Discover shows Paths with the search "shuffle"

  Scenario: Rows are shown as skeletons while the catalog loads slowly
    Given the catalog takes more than a moment to answer
    When "alice" opens Discover
    Then skeleton rows show where the courses will be

  Scenario: A catalog that fails to load can be tried again in place
    Given the catalog fails to load
    When "alice" opens Discover
    Then a notice says the courses could not be loaded, with "Try again"
    And the navigation, the search and the filters stay

  # ── Path detail ───────────────────────────────────────────────────────────

  Scenario: The path detail shows the path and its outline under section labels
    Given "Open chords" has 9 lessons in the sections "First shapes" and "Changes"
    When "alice" opens the path detail of "Open chords"
    Then it shows the thumbnail, its level, language and instrument, the title, "by Bruno" and the summary
    And it reads "Path outline · 9 lessons"
    And the lessons are numbered under "First shapes" and "Changes"
    And the lessons do not open from here

  Scenario: The path detail goes back to Discover
    When "alice" opens the path detail of "Open chords"
    Then its back arrow reads "Discover"

  Scenario: A path not started offers Start path
    When "alice" opens the path detail of "Open chords"
    Then the primary action is "Start path"

  Scenario: A path already in Learning shows its progress and Continue path
    Given "alice" has completed 5 of the 9 lessons of "Open chords"
    When "alice" opens the path detail of "Open chords"
    Then it shows an "In Learning" chip and "5 of 9 lessons"
    And the primary action is "Continue path"

  Scenario: Continue path makes the path current first
    Given "alice" has "Open chords" in Learning
    And "Reading rhythm" is "alice"'s current course
    When "alice" taps "Continue path" on "Open chords"
    Then "Open chords" becomes "alice"'s current path
    And My path opens on "Open chords"

  Scenario: The byline opens Discover filtered by that teacher
    When "alice" taps "by Bruno" on the path detail of "Open chords"
    Then Discover opens on Paths with a removable "Bruno" chip

  Scenario: The course detail byline opens Discover on courses
    When "alice" taps "by Bruno" on the course detail of "Blues basics"
    Then Discover opens on Courses with a removable "Bruno" chip

  Scenario: On a desktop the path detail keeps its action in view
    When "alice" opens the path detail of "Open chords" on a screen 1280 px wide
    Then the outline is beside a side card with the thumbnail, "9 lessons" and "Start path"

  # ── Start ─────────────────────────────────────────────────────────────────

  Scenario: Starting a course makes it current and opens My path
    Given "Reading rhythm" is "alice"'s current course
    When "alice" taps "Start course" on "Blues basics"
    Then "alice" is enrolled in "Blues basics"
    And "Blues basics" becomes "alice"'s current course
    And My path opens on lesson 1 of "Blues basics"
    And a toast says "Now on Blues basics" with "Undo"

  Scenario: Starting with nothing current offers no Undo
    Given "alice" has nothing current
    When "alice" taps "Start course" on "Blues basics"
    Then "Blues basics" becomes "alice"'s current course
    And a toast says "Now on Blues basics" with no Undo

  Scenario: Starting a path makes it current and opens My path
    Given "Reading rhythm" is "alice"'s current course
    When "alice" taps "Start path" on "Blues shuffle"
    Then "Blues shuffle" becomes "alice"'s current path
    And My path opens on lesson 1 of "Blues shuffle"
    And a toast says "Now on Blues shuffle" with "Undo"

  Scenario: Starting does not ask first
    When "alice" taps "Start path" on "Blues shuffle"
    Then no confirm is shown

  Scenario: Undo switches back and keeps the new item in Learning
    Given "alice" started "Blues shuffle" while "Reading rhythm" was her current course
    When "alice" taps "Undo" on the "Now on Blues shuffle" toast
    Then "Reading rhythm" is "alice"'s current course again
    And "Blues shuffle" is still in Learning

  Scenario: A failed start keeps the student on the detail
    Given enrolling in "Blues basics" fails
    When "alice" taps "Start course" on "Blues basics"
    Then an error toast is shown
    And the course detail of "Blues basics" stays open
    And "alice"'s current item is unchanged

  Scenario: An enrolment whose switch fails says it is in Learning
    Given "Reading rhythm" is "alice"'s current course
    And enrolling in "Blues basics" works but making it current fails
    When "alice" taps "Start course" on "Blues basics"
    Then an error toast says "Blues basics" is in Learning but "Reading rhythm" is still current
    And the course detail of "Blues basics" stays open
