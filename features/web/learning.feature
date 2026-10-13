# Learning (MOT-57 design, implemented in MOT-83).
#
# Everything the student has started — course enrolments and standalone paths — in one list, the
# learner view of a course, and the screen shown when a course is finished. The pattern is
# design/patterns/learning.md; the Figma page is "Learning" (rows 1–5, and row 6 for updating a
# copy, MOT-36). Switching, abandoning and archiving, and why the current item cannot be left while
# another is in progress, are in features/learning-paths/current-path-lifecycle.feature. What an
# update does to a copy is in features/learning-paths/update-a-copy.feature. Opening a lesson of a
# finished course or path for review (MOT-106) is in features/web/lesson-review.feature.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite.

@web
Feature: See everything I started and pick up where I left off
  As a student with more than one course or path
  I want them all in one list, with one tap to continue
  So that I come back to what I started instead of losing track of it

  Background:
    Given "alice" is signed in as a student

  # ── The list ──────────────────────────────────────────────────────────────

  Scenario: Courses and paths are listed together, grouped by where the student is
    Given "alice" is enrolled in the courses "Guitar foundations" and "Reading rhythm"
    And "alice" has the standalone path "Open chords"
    And "alice" finished the course "First songs"
    And "alice" left the course "Blues basics"
    When "alice" opens Learning
    Then "In progress" lists "Guitar foundations", "Reading rhythm" and "Open chords"
    And "Finished" lists "First songs"
    And "Left" lists "Blues basics"

  Scenario: The current item comes first, then the most recently started
    Given "alice" started "Guitar foundations", then "Open chords", then "Reading rhythm"
    And "Guitar foundations" is her current course
    When "alice" opens Learning
    Then "In progress" lists "Guitar foundations", "Reading rhythm", "Open chords", in that order

  Scenario: The left group is folded
    Given "alice" left the courses "Blues basics" and "Slide guitar"
    When "alice" opens Learning
    Then the "Left" group shows as one row reading "Left · 2"
    And its rows are hidden until "alice" taps it

  Scenario: The current item is marked on its row
    Given "Guitar foundations" is "alice"'s current course
    When "alice" opens Learning
    Then the "Guitar foundations" row has a "Current" badge on its thumbnail and an accent border

  Scenario: A course row counts parts
    Given "alice" is on part 2 of the 4 parts of "Guitar foundations"
    When "alice" opens Learning
    Then the "Guitar foundations" row reads "Course · Part 2 of 4" above its title
    And its progress bar reads "1 of 4 parts"

  Scenario: A path row counts lessons
    Given "alice" has completed 5 of the 9 lessons of the standalone path "Open chords"
    When "alice" opens Learning
    Then the "Open chords" row reads "Path" above its title
    And its progress bar reads "5 of 9 lessons"

  Scenario: A path assigned by a teacher names the teacher
    Given the teacher "Ana" assigned "alice" the standalone path "Open chords"
    When "alice" opens Learning
    Then the "Open chords" row reads "Path · Assigned by Ana" above its title

  Scenario: A row shows no level, author or button
    When "alice" opens Learning
    Then no row shows a level, an author or a button

  Scenario: A row without a thumbnail shows its kind's icon instead
    Given the course "Reading rhythm" has no thumbnail
    When "alice" opens Learning
    Then the "Reading rhythm" row shows the course icon on a tinted tile of the thumbnail's size

  # ── Tapping a row ─────────────────────────────────────────────────────────

  Scenario: Tapping the current item opens My path
    Given "Guitar foundations" is "alice"'s current course
    When "alice" taps the "Guitar foundations" row
    Then My path opens on "Guitar foundations"
    And no toast is shown

  Scenario: Tapping another item in progress makes it current and opens My path
    Given "Guitar foundations" is "alice"'s current course
    And "alice" is enrolled in "Reading rhythm"
    When "alice" taps the "Reading rhythm" row
    Then "Reading rhythm" becomes "alice"'s current course
    And My path opens on "Reading rhythm"
    And a toast says "Now on Reading rhythm" with "Undo"

  Scenario: Undo switches back
    Given "alice" tapped "Reading rhythm" while "Guitar foundations" was her current course
    When "alice" taps "Undo" on the "Now on Reading rhythm" toast
    Then "Guitar foundations" is "alice"'s current course again

  Scenario: Tapping a finished item opens its detail
    Given "alice" finished the course "First songs"
    When "alice" taps the "First songs" row
    Then the course detail of "First songs" opens

  Scenario: Tapping a left course opens its detail to start again
    Given "alice" left the course "Blues basics"
    When "alice" taps the "Blues basics" row
    Then the course detail of "Blues basics" opens with "Start course"

  Scenario: A failed switch keeps the current item
    Given "Guitar foundations" is "alice"'s current course
    And switching to "Reading rhythm" fails
    When "alice" taps the "Reading rhythm" row
    Then an error toast is shown
    And "Guitar foundations" is still "alice"'s current course
    And Learning stays open

  # ── The ⋯ menu and leaving ────────────────────────────────────────────────

  Scenario: The ⋯ menu of a course offers its details and leaving it
    When "alice" taps ⋯ on the "Reading rhythm" row
    Then a menu offers "Course details" and "Leave course"

  Scenario: The ⋯ menu of a standalone path offers removing it
    When "alice" taps ⋯ on the "Open chords" row
    Then a menu offers "Path details" and "Remove from Learning"

  Scenario: Leaving always asks first
    When "alice" chooses "Leave course" for "Reading rhythm"
    Then a confirm asks "Leave Reading rhythm?"
    And it says she loses her place, starting again begins at part 1, and her practice and skill levels stay
    And "Reading rhythm" is still in progress

  Scenario: Confirming leaves the course
    Given "Guitar foundations" is "alice"'s current course
    When "alice" confirms leaving "Reading rhythm"
    Then "Reading rhythm" moves to "Left"
    And "Guitar foundations" is still "alice"'s current course
    And no Undo is offered

  Scenario: Leaving the current item names the item that becomes current
    Given "Guitar foundations" is "alice"'s current course
    And "Reading rhythm" is the next item in progress
    When "alice" chooses "Leave course" for "Guitar foundations"
    Then the confirm says she will continue with "Reading rhythm"

  Scenario: Leaving the current item while another is in progress moves on to the next one first
    Given "Guitar foundations" is "alice"'s current course
    And "Reading rhythm" is the next item in progress
    When "alice" confirms leaving "Guitar foundations"
    Then "Reading rhythm" becomes "alice"'s current course
    And "Guitar foundations" moves to "Left"

  Scenario: Leaving the only item in progress leaves nothing current
    Given "Guitar foundations" is the only thing "alice" has in progress
    When "alice" confirms leaving "Guitar foundations"
    Then "Guitar foundations" moves to "Left"
    And "alice" has no current course or path

  Scenario: A leave that fails after the switch says so
    Given "Guitar foundations" is "alice"'s current course and "Reading rhythm" is the next in progress
    And leaving "Guitar foundations" fails after the switch to "Reading rhythm"
    When "alice" confirms leaving "Guitar foundations"
    Then "Reading rhythm" is "alice"'s current course
    And "Guitar foundations" is still in progress
    And an error toast says she is now on "Reading rhythm" but "Guitar foundations" was not left

  # ── States ────────────────────────────────────────────────────────────────

  Scenario: Nothing started yet
    Given "alice" has no course enrolment and no standalone path
    When "alice" opens Learning
    Then it says "Nothing here yet" with "Explore courses and paths", which opens Discover

  Scenario: Everything finished
    Given every course and path "alice" has is finished or left
    When "alice" opens Learning
    Then a "Nothing in progress" card with "Find your next course" shows above "Finished"

  Scenario: Learning fails to load
    Given "alice"'s courses and paths fail to load
    When "alice" opens Learning
    Then a notice in place of the list offers "Try again"
    And the navigation stays

  # ── Course detail (learner view) ──────────────────────────────────────────

  Scenario: A course opened from Learning goes back to Learning
    When "alice" opens the course detail of "Reading rhythm" from Learning
    Then its back arrow reads "Learning"
    And Learning is the highlighted destination

  Scenario: The detail of an enrolled course offers to continue its part
    Given "alice" is on part 2 of the 4 parts of "Guitar foundations"
    When "alice" opens the course detail of "Guitar foundations"
    Then it shows "Part 2 of 4" and one primary action, "Continue part 2"

  Scenario: Continue part makes the course current and opens My path
    Given "Reading rhythm" is "alice"'s current course
    When "alice" taps "Continue part 2" on the course detail of "Guitar foundations"
    Then "Guitar foundations" becomes "alice"'s current course
    And My path opens on "Guitar foundations"

  Scenario: The outline marks each part done, current or upcoming
    Given "alice" is on part 2 of the 4 parts of "Guitar foundations"
    When "alice" opens the course detail of "Guitar foundations"
    Then part 1 is marked done, part 2 is highlighted as current, and parts 3 and 4 are muted

  Scenario: The current part opens unfolded with its lessons
    Given "alice" is on part 2 of "Guitar foundations"
    When "alice" opens the course detail of "Guitar foundations"
    Then part 2 shows its lesson titles and "Open in My path"
    And the other parts show their titles only until tapped

  Scenario: The current part counts its lessons when the course is current
    Given "Guitar foundations" is "alice"'s current course
    And "alice" has completed 7 of the 14 lessons of part 2
    When "alice" opens the course detail of "Guitar foundations"
    Then part 2 reads "7 of 14 lessons done"

  Scenario: The current part shows no lesson count when the course is not current
    Given "alice" is enrolled in "Guitar foundations", which is not her current course
    When "alice" opens the course detail of "Guitar foundations"
    Then part 2 is highlighted as current without a lesson count

  Scenario: A left course offers to start again from part 1
    Given "alice" left the course "Blues basics"
    When "alice" opens the course detail of "Blues basics"
    Then it offers "Start course"
    And it says "You left this course before. Starting again begins at part 1."

  Scenario: A finished course shows every part done and offers practice
    Given "alice" finished the course "First songs"
    When "alice" opens the course detail of "First songs"
    Then it shows a "Finished" chip and every part done
    And it offers "Practise what you learned", which opens the practice setup

  # ── Reviewing a finished course or path (MOT-106) ─────────────────────────

  Scenario: Every part of a finished course unfolds to lessons that open for review
    Given "alice" finished the course "First songs", 3 parts
    When "alice" taps part 2 on the course detail of "First songs"
    Then part 2 unfolds to its lessons, each one a row that opens it
    And there is no "Open in My path"

  Scenario: A finished course shows the lessons of the version the student took
    Given "alice" finished version 1 of "First songs"
    And version 2 of "First songs" adds a lesson to part 1
    When "alice" unfolds part 1 on the course detail of "First songs"
    Then it lists the lessons of version 1

  Scenario: Opening a lesson of a finished course changes nothing
    Given "alice" finished the course "First songs"
    And "Reading rhythm" is "alice"'s current course
    When "alice" opens lesson 1 of part 1 from the course detail of "First songs"
    Then the lesson opens for review
    And "Reading rhythm" is still "alice"'s current course
    And Learning still lists "First songs" under "Finished"

  Scenario: Tapping a finished standalone path opens its detail
    Given "alice" finished the standalone path "Open chords"
    When "alice" taps the "Open chords" row
    Then the path detail of "Open chords" opens, with a "Finished" chip

  Scenario: A finished standalone path lists its lessons to open for review
    Given "alice" finished the standalone path "Open chords", 9 lessons
    When "alice" opens the path detail of "Open chords" from Learning
    Then it lists the 9 lessons under their section labels, each done and each a row that opens it

  Scenario: The lessons of a course in progress still open from My path
    Given "alice" is on part 2 of "Guitar foundations"
    When "alice" opens the course detail of "Guitar foundations"
    Then part 1's lessons are titles only, and do not open

  Scenario: Lessons that fail to load on a finished course offer Try again in place
    Given "alice" finished the course "First songs"
    And the lessons of "First songs" fail to load
    When "alice" opens the course detail of "First songs"
    Then the outline shows a notice with "Try again" in place of the parts
    And "Practise what you learned" is still offered

  Scenario: Leave this course sits at the end of the detail
    Given "alice" is enrolled in "Reading rhythm"
    When "alice" opens the course detail of "Reading rhythm"
    Then "Leave this course" is the last thing on the page, in the danger colour
    And tapping it asks first, as from the ⋯ menu

  # ── Course completed ──────────────────────────────────────────────────────

  Scenario: Finishing a course celebrates it
    Given "alice" has just finished the last lesson of "Guitar foundations", 4 parts and 44 lessons
    When the course completed screen opens
    Then it says "You finished Guitar foundations" and "4 parts · 44 lessons"
    And it shows no completion date

  Scenario: Another item in progress is the way on
    Given "alice" has just finished "Guitar foundations"
    And "Reading rhythm" is in progress
    When the course completed screen opens
    Then the primary action is "Continue Reading rhythm"
    And "Find your next course" is the quiet action

  Scenario: Continue on the completed screen makes that item current
    Given "alice" has just finished "Guitar foundations" and "Reading rhythm" is in progress
    When "alice" taps "Continue Reading rhythm"
    Then "Reading rhythm" becomes "alice"'s current course
    And My path opens on "Reading rhythm"

  Scenario: With nothing else in progress, the way on is a new course
    Given "alice" has just finished "Guitar foundations" and has nothing else in progress
    When the course completed screen opens
    Then the primary action is "Find your next course", which opens Discover on courses
    And "Practise what you learned" is the quiet action

  Scenario: A course not finished is not celebrated
    Given "alice" is still on part 2 of "Guitar foundations"
    When "alice" opens the course completed screen of "Guitar foundations"
    Then it says the course was not found among her finished courses

  # ── Updating to the latest version (MOT-36, ADR-055) ─────────────────────

  Scenario: A row that is behind shows a new-version icon
    Given "alice" is on part 2 of the 4 parts of "Guitar foundations"
    And a newer version of "Guitar foundations" is available to her
    When "alice" opens Learning
    Then the "Guitar foundations" row shows a refresh icon before "Course · Part 2 of 4", named "New version available"
    And its progress bar still reads "1 of 4 parts"

  Scenario: The row menu offers the update first, only while one is available
    Given a newer version of "Guitar foundations" is available to "alice"
    When "alice" opens the ⋯ menu of the "Guitar foundations" row
    Then the first item is "Update to the latest version"
    And "Course details" and "Leave course" follow

  Scenario: A row that is up to date has no update in its menu
    Given "Guitar foundations" is up to date for "alice"
    When "alice" opens the ⋯ menu of the "Guitar foundations" row
    Then there is no "Update to the latest version" item

  Scenario: Finished and left items are never offered the update
    Given "alice" finished the course "First songs" and left the course "Blues basics"
    When "alice" opens Learning
    Then neither row shows the new-version icon
    And neither row's ⋯ menu offers "Update to the latest version"

  Scenario: The course detail offers the same update under Continue
    Given a newer version of "Guitar foundations" is available to "alice"
    When "alice" opens the course detail of "Guitar foundations"
    Then a card under "Continue part 2" reads "A newer version is available"
    And its "Update course" button opens the update confirm

  Scenario: A held path's detail offers the same update
    Given a newer version of the standalone path "Fingerstyle warm-ups" is available to "alice"
    When "alice" opens the detail of "Fingerstyle warm-ups" from Learning
    Then a card under "Continue" reads "A newer version is available"
    And its "Update path" button opens the update confirm

  Scenario: A path's detail opened from Learning leads back to Learning
    Given "alice" has the standalone path "Open chords"
    When "alice" opens the detail of "Open chords" from Learning
    Then Learning stays highlighted in the navigation
    And the way back reads "Back to Learning" and returns to Learning

  Scenario: The update always confirms first, with the same text
    Given a newer version of "Guitar foundations" is available to "alice"
    When "alice" chooses "Update to the latest version" on the "Guitar foundations" row
    Then a confirm titled "Update Guitar foundations?" opens
    And it says finished lessons stay finished, a removed current lesson moves her to the next unfinished one, and the update can't be undone
    And its actions are "Update course" and "Not now"

  Scenario: Not now leaves the course as it was
    Given the update confirm for "Guitar foundations" is open
    When "alice" taps "Not now"
    Then the confirm closes
    And the "Guitar foundations" row still shows the new-version icon

  Scenario: While updating, the confirm stays and shows progress
    Given the update confirm for "Guitar foundations" is open
    When "alice" taps "Update course"
    Then "Update course" shows it is busy and "Not now" is disabled until the update finishes

  Scenario: A successful update closes the confirm and refreshes the row
    Given the update confirm for "Guitar foundations" is open
    And the latest version of "Guitar foundations" has a new picture
    When "alice" taps "Update course" and the update succeeds
    Then the confirm closes
    And a success toast reads "Guitar foundations is up to date", with no Undo
    And the "Guitar foundations" row shows the new picture and no new-version icon

  Scenario: A failed update keeps the confirm open and changes nothing
    Given the update confirm for "Guitar foundations" is open
    When "alice" taps "Update course" and the update fails
    Then the confirm stays open with an error notice saying nothing changed
    And its primary action reads "Try again"
    And the "Guitar foundations" row still shows the new-version icon

  Scenario: Updating a path uses the path's wording
    Given a newer version of the standalone path "Fingerstyle warm-ups" is available to "alice"
    When "alice" chooses "Update to the latest version" on the "Fingerstyle warm-ups" row
    Then a confirm titled "Update Fingerstyle warm-ups?" opens with the action "Update path"

  Scenario: Updating does not switch the current item
    Given "Reading rhythm" is "alice"'s current course
    And a newer version of "Guitar foundations" is available to her
    When "alice" updates "Guitar foundations"
    Then "Reading rhythm" is still her current course
