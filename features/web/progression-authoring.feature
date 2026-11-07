# What the app shows when admins create, add to the drills and remove progressions (ADR-070;
# Figma "Song charts" row 9, MOT-184, D1–D10 decided 2026-11-05). What core accepts is in
# content-management/progressions.feature; numerals are read as golden/progression-numerals pins.

@web
Feature: Create and manage progressions in the app
  As an admin of the concierge team
  I want to create a missing progression without leaving the chart I'm tagging
  So that tagging a song never waits on a catalog change

  Background:
    Given "ana" is signed in as an admin
    And "ana" is editing the draft of "Amazing Grace", in G, with the progression picker open on "Verse 1"

  Rule: The picker tags and untags, marks chart-only progressions, and offers to create what it can't find

    Scenario: The picker marks only the progressions drills don't use
      Given "ana" has created the major progression "I-bVII-IV-I"
      When "ana" searches the picker for "I"
      Then "I–♭VII–IV–I" is marked "Chart only"
      And "I–V–vi–IV (pop)" carries no mark

    Scenario: A search that finds nothing offers to create it, read as numerals
      When "ana" searches the picker for "I bVII IV"
      Then the picker says "No progression is I–♭VII–IV yet."
      And its last row is "Create “I–♭VII–IV”"

    Scenario: Unticking a progression only untags the section
      Given "Verse 1" is tagged with "I–IV–I–V"
      When "ana" unticks "I–IV–I–V" in the picker
      Then "Verse 1" is no longer tagged with it
      And "I–IV–I–V" is still in the picker
      And no row of the picker offers to remove a progression

  Rule: The create form reads numerals as they are typed

    Scenario: The form starts from the search, chart only
      When "ana" chooses "Create “I–♭VII–IV”"
      Then the form "New progression" shows "Major" and the numerals "I bVII IV"
      And "Use in drills" is off: "Off: chart only. You can add it to the drills later in Admin › Progressions."

    Scenario: The form spells the progression in the chart's key and marks a borrowed chord
      When "ana" types the numerals "I bVII IV I" in the form
      Then it shows "4 BARS" and "In G, this chart's key: G – F – C – G."
      And it says "♭VII is borrowed: it isn't in G major, and that's fine."
      And "Create and tag Verse 1" is enabled

    Scenario: A minor progression is spelled in the chart's relative key
      When "ana" chooses "Minor" and types the numerals "i bVI bII V" in the form
      Then it says "♭II is borrowed: it isn't in E minor, the relative key of this chart's G, and that's fine."

    Scenario: Input that isn't a chord is an error on its numeral
      When "ana" types the numerals "i bVI bII Vx" in the form
      Then it says "“Vx” isn't a chord."
      And "Create and tag Verse 1" is disabled

    Scenario: Numerals an existing progression has offer to tag it instead
      When "ana" types the numerals "I V vi IV" in the form
      Then it says "Already a progression" and "These numerals are I–V–vi–IV (pop)."
      And its button is "Tag I–V–vi–IV (pop)" in place of "Create and tag Verse 1"

    Scenario: Creating tags the section at once, saved with the chart
      When "ana" creates "I bVII IV I" from the form
      Then "Verse 1" shows the chip "I–♭VII–IV–I"
      And a toast says "Created I–♭VII–IV–I and tagged Verse 1"
      And the draft is unsaved until "ana" saves it

  Rule: "Use in drills" asks only for skills and concepts, and says why when drills can't use it

    Scenario: Turning on "Use in drills" shows the skills and concepts picker
      When "ana" turns on "Use in drills" in the form
      Then the skills and concepts picker of the exercise and diagram editors is shown
      And "Create and tag Verse 1" is disabled until a skill or concept is picked

    Scenario: A minor progression can't use the drills yet
      When "ana" chooses "Minor" in the form
      Then "Use in drills" is disabled and says "Drills don't use minor keys yet, so it stays chart only."

    Scenario: A bar count drills don't ask can't use the drills
      When "ana" types the numerals "I IV V" in the form
      Then "Use in drills" is disabled and says why

  Rule: Admin › Progressions lists every progression and is the only place one is removed

    Scenario: The list says where each progression stands
      Given "ana" created the major progression "I-bVII-IV-I" today, tagged in 2 charts
      When "ana" opens Admin › Progressions
      Then "I–♭VII–IV–I" shows "Major · 4 bars · created by Ana Souza, today · tagged in 2 charts"
      And it offers "Add to drills"
      And "I–V–vi–IV (pop)" shows "catalog" and offers neither "Add to drills" nor "Remove"

    Scenario: Removing a progression a chart still uses lists what to untag
      Given "I–♭VII–IV–I" is tagged in the draft of "Amazing Grace" on "Verse 1"
      When "ana" chooses "Remove" on "I–♭VII–IV–I"
      Then the dialog says "It can't be removed while a chart uses it."
      And it lists "Amazing Grace · Verse 1 — in the draft: untag it and save"
      And its "Remove" button is disabled

    Scenario: Removing a progression no chart uses deletes it after a confirmation
      Given "ana" created the major progression "I-IV-I-V-vi", not tagged in any chart
      When "ana" chooses "Remove" on "I–IV–I–V–vi" and confirms
      Then "I–IV–I–V–vi" is no longer listed

    Scenario: Adding to the drills asks for skills and concepts, and can't be undone
      When "ana" chooses "Add to drills" on "I–♭VII–IV–I"
      Then the dialog "Add I–♭VII–IV–I to the drills" shows the skills and concepts picker
      And it says "A progression in the drills can't be taken out or removed: learners' practice points at it."

  Rule: A tag whose progression was removed shows its numerals

    Scenario: A published revision's removed progression reads as numerals
      Given the revision of "Amazing Grace" a student reads tags "Verse 1" with "major/I-bVII-IV-I", which no progression has
      When the student opens "Amazing Grace"
      Then "Verse 1" shows the progression "I–♭VII–IV–I"

  Rule: On a phone, the same flows open as sheets

    Scenario: The picker and the remove dialog are bottom sheets, the form a full-screen sheet
      Given "ana" is on a phone
      When "ana" opens the picker, the create form and the remove dialog in turn
      Then the picker and the remove dialog open as bottom sheets
      And the create form opens full screen with "Create and tag Verse 1" at the bottom
