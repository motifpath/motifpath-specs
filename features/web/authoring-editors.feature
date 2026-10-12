# The authoring editors (MOT-61 D6–D9, D12, D20, D21; MOT-95 slice 3).
#
# Every Teach editor (course, path, lesson, exercise, diagram) shares one frame: an app bar with an
# explicit Save, a question before leaving with unsaved changes, the status first with the one
# publishing action, a list of what blocks a save, reordering without dragging, and previews in the
# real learner component. design/patterns/authoring.md, "Editors"; the Figma page is "Authoring",
# rows 3 (3a–3h), 4, 9 (9a, 9h) and 11.
#
# Who may publish what, and what a publish needs, is the server's: features/learning-paths/courses.feature,
# features/learning-paths/path-publishing.feature and
# features/content-management/content-node-versioning.feature. An exercise's type can't change once
# it is created (UpdateExerciseRequest has no exercise_type).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite.

@web
Feature: Edit and publish authored content
  As a teacher or an admin
  I want every editor to save explicitly, say what learners get and say what is missing
  So that I can fix and publish content from any screen without guessing

  Background:
    Given "bob" is signed in as a teacher
    And "ana" is signed in as an admin

  # ── The app bar and saving ───────────────────────────────────────────────────

  Rule: Save is always in the app bar, and saving stays explicit

    Scenario: An editor with nothing to save says so
      Given "bob" opens their course "Guitar foundations" with no edits
      Then the app bar shows "Courses" over "Guitar foundations"
      And the app bar shows "Saved ✓" instead of the Save button

    Scenario: An edit makes Save available
      Given "bob" is editing their course "Guitar foundations"
      When "bob" changes the summary
      Then the app bar shows the Save button

    Scenario: Saving shows its progress, then that it is done
      Given "bob" has changed the summary of "Guitar foundations"
      When "bob" taps Save
      Then the app bar shows "Saving…" until the course is saved
      And then the app bar shows "Saved ✓"

    Scenario: Nothing is saved without Save
      Given "bob" has changed the summary of "Guitar foundations"
      When "bob" waits without tapping Save
      Then the course's saved summary is unchanged

  # ── Leaving with unsaved changes ─────────────────────────────────────────────

  Rule: Leaving an editor with unsaved changes asks first

    Scenario Outline: Back with unsaved changes asks before leaving
      Given "bob" has unsaved changes in <editor>
      When "bob" taps back in the app bar
      Then "bob" is asked "Leave without saving?", with "Keep editing" and "Leave"

      Examples:
        | editor                  |
        | a course                |
        | a learning path         |
        | a lesson                |
        | an exercise             |
        | a diagram               |

    Scenario: Keep editing stays in the editor with the changes
      Given "bob" is asked "Leave without saving?" in their course "Guitar foundations"
      When "bob" chooses "Keep editing"
      Then "bob" is still in the editor with their changes

    Scenario: Leave discards the changes
      Given "bob" is asked "Leave without saving?" in their course "Guitar foundations"
      When "bob" chooses "Leave"
      Then "bob" is on the Courses list
      And the course's saved summary is unchanged

    Scenario: Back with nothing unsaved leaves at once
      Given "bob" opens their course "Guitar foundations" with no edits
      When "bob" taps back in the app bar
      Then "bob" is on the Courses list without being asked

  # ── Status first ─────────────────────────────────────────────────────────────

  Rule: The status panel opens the editor and says what learners get now

    Scenario: A draft says learners can't find it yet
      Given "ana" opens the course "Guitar foundations", which was never published
      Then the status panel shows "Draft" and "Not published yet — learners can't find it."

    Scenario: A published course says which version learners get
      Given the course "Guitar foundations" is published as version 3 with no newer edits
      When "ana" opens it
      Then the status panel shows "Published · v3" and "Learners get version 3."

    Scenario: Saved edits after a publish are unpublished changes
      Given the course "Guitar foundations" is published as version 3
      And "ana" has saved a new summary since
      When "ana" opens it
      Then the status panel shows "Unpublished changes" and "Learners still get version 3. Publish to give them your changes."
      And it offers "Publish changes"

    Scenario: A retired course says it can't be changed
      Given the course "Guitar foundations" is retired
      When "ana" opens it
      Then the status panel shows "Retired" and says an admin can reactivate it

  Rule: Publishing saves first, confirms, and says who gets the new version

    Scenario: Publish asks to confirm, and saves first
      Given "ana" has unsaved changes in the course "Guitar foundations", published as version 3
      When "ana" taps "Publish changes"
      Then "Publish this course?" says the changes are saved first, learners who enroll from now on get this version, and people already enrolled keep theirs
      When "ana" confirms
      Then the course is saved and published as version 4

    Scenario: A publish updates the panel in place
      Given "ana" has published the course "Guitar foundations" as version 4
      Then the status panel shows "Published · v4" and "Learners get version 4."
      And a toast says "Published as version 4"

    Scenario: A course's other action is Retire, a path's is Unpublish
      Given "ana" opens the published course "Guitar foundations" and the published path "Strumming"
      Then the course's status panel offers "Retire"
      And the path's status panel offers "Unpublish"

  Rule: What a publish still needs is listed, never a silently disabled button

    Scenario: A path missing its summary and language lists both
      Given "ana" opens the draft path "Strumming", which has no summary and no language
      Then the status panel says "Before you publish, add:" with "A summary" and "A language"
      And the Publish button can't be used

    Scenario: A path with a lesson that was never published names the lesson
      Given the draft path "Strumming" has the lesson "Down-up strums", which was never published
      When "ana" opens the path
      Then the status panel lists "Down-up strums" as a lesson to publish first

    Scenario: The list empties as the author adds what was missing
      Given the status panel of "Strumming" lists "A summary"
      When "ana" writes a summary
      Then "A summary" is no longer listed

  Rule: Teachers publish their lessons themselves; an admin publishes courses and paths

    Scenario Outline: A teacher sees who publishes a course or a path instead of a button
      Given "bob" opens their <item> "<title>", with saved changes not yet published
      Then the status panel says an admin publishes <items>, and their saved changes reach learners when they do
      And no Publish button is shown

      Examples:
        | item          | title              | items   |
        | course        | Guitar foundations | courses |
        | learning path | Strumming          | paths   |

    Scenario: A teacher publishes their own lesson
      Given "bob" opens their draft lesson "Open chords: G, C, D"
      Then the status panel offers "Publish"

    Scenario: An exercise has no status panel
      When "bob" opens their exercise "Find the G"
      Then no status panel is shown, since exercises are used, not published

  # ── Save blockers ────────────────────────────────────────────────────────────

  Rule: Save stays tappable and says what blocks it

    Scenario Outline: Save with something missing lists what is missing
      Given "bob" is editing an exercise that has <missing>
      When "bob" taps Save
      Then nothing is saved
      And a list "Before you can save:" names "<item>"

      Examples:
        | missing                                    | item                               |
        | no correct option                          | Mark at least one option correct   |
        | no skill                                   | Add a skill                        |
        | no concept                                 | Add a concept                      |
        | a stimulus playback at 20 BPM              | Pick a tempo from 40 to 300 BPM    |

    Scenario: Every missing item is listed at once
      Given "bob" is editing an exercise with no correct option and no skill
      When "bob" taps Save
      Then the list names "Mark at least one option correct" and "Add a skill"

    Scenario: An item in the list jumps to its field
      Given the list "Before you can save:" names "Add a skill"
      When "bob" taps "Add a skill"
      Then the Skills field is scrolled into view and has the focus

    Scenario: The list goes once nothing is missing
      Given the list "Before you can save:" names only "Add a skill"
      When "bob" adds the skill "Strumming"
      Then the list is gone

  # ── Reordering ───────────────────────────────────────────────────────────────

  Rule: Ordered rows reorder by dragging their handle or from their ⋮ menu

    Scenario: Dragging a checkpoint by its handle moves it
      Given "bob"'s course "Guitar foundations" has the checkpoints "First chords", "Strumming", "Changes"
      When "bob" drags "Changes" by its handle above "Strumming"
      Then the checkpoints read "First chords", "Changes", "Strumming"
      And the app bar shows the Save button

    Scenario: ⋮ on a row offers the moves and the row's actions
      When "bob" opens ⋮ on the checkpoint "Strumming"
      Then it offers "Move up", "Move down", "Rename in this course", "Open the path" and "Remove from course"

    Scenario: Move up moves the row one place up
      Given the checkpoints read "First chords", "Strumming", "Changes"
      When "bob" chooses "Move up" on "Changes"
      Then the checkpoints read "First chords", "Changes", "Strumming"

    Scenario: The first row can't move up and the last can't move down
      Given the checkpoints read "First chords", "Strumming", "Changes"
      Then ⋮ on "First chords" doesn't offer "Move up"
      And ⋮ on "Changes" doesn't offer "Move down"

    Scenario: A path's steps reorder the same way
      Given "bob"'s path "Strumming" has the lessons "Down strums" and "Down-up strums"
      When "bob" chooses "Move up" on "Down-up strums"
      Then the lessons read "Down-up strums", "Down strums"

    Scenario: A row says what blocks publishing
      Given the course "Guitar foundations" has the checkpoint "Changes", a path that is a draft
      Then its row says "Draft — publish it first"

    Scenario: Video pop-ups, in time order, don't drag
      Given "bob" is editing a video lesson with two pop-ups
      Then the pop-ups have no drag handle

  # ── A new exercise ───────────────────────────────────────────────────────────

  Rule: A new exercise starts by choosing its type, which is locked after the first save

    Scenario: A new exercise asks for its type first
      When "bob" starts a new exercise
      Then "What will the student do?" offers five types, each saying what the student does:
        | type              | what the student does                            |
        | Image recognition | Taps the right place on an image or a diagram.   |
        | Image choice      | Picks the right image, diagram or chord box.     |
        | Text response     | Picks the right answer from text options.        |
        | Audio recognition | Hears one sound and picks what it is.            |
        | Audio selection   | Hears the options and picks the right sound.     |
      And it says "The type can't be changed after the first save."

    Scenario: Choosing a type opens the editor for that type
      Given "bob" is choosing the type of a new exercise
      When "bob" chooses "Text response"
      Then the editor shows text options

    Scenario: The type can change until the first save
      Given "bob" chose "Text response" for a new exercise and hasn't saved it
      When "bob" changes the type to "Image choice"
      Then the editor shows image options

    Scenario: A saved exercise's type can't change
      Given "bob" has saved their exercise "Find the G" as "Image recognition"
      When "bob" opens it
      Then the type shows "Image recognition" and can't be changed

  # ── Previews ─────────────────────────────────────────────────────────────────

  Rule: A preview is the real learner screen in a layer, and it records nothing

    Scenario: See what learners see shows a course's published version
      Given the course "Guitar foundations" is published as version 3
      When "ana" chooses "See what learners see"
      Then the learner's course page for version 3 opens full screen under a "Preview — what learners see" bar
      And its Start course can't be used in the preview

    Scenario: A course that was never published has nothing to preview
      Given "ana" opens the course "Guitar foundations", which was never published
      Then "See what learners see" isn't offered

    Scenario: Previewing an exercise grades the answer and records nothing
      Given "bob" is previewing their exercise "Find the G" as a student
      When "bob" answers it
      Then the answer is graded as it would be for a student
      And no exercise.started, exercise.progress or exercise.ended event is sent

    Scenario: × closes the preview and returns to the editor
      Given "bob" is previewing their exercise "Find the G"
      When "bob" taps × on the Preview bar
      Then "bob" is back in the editor with their edits
