# Heavy editing on a phone (MOT-61 D9–D11, as revised by D14 and D17; MOT-95 slice 5).
#
# Three things need a pointer and wait for a larger screen: drawing or moving image regions, placing
# or moving positions in the Diagrams library, and placing chords over song-chart lyrics. On Compact
# (< 600 px) each is shown read-only — never hidden — with a note right under it naming what waits and
# that the rest can be changed here. Everything around it stays editable, and Medium and Expanded,
# tablets included, get the full editors. design/patterns/authoring.md, "What is heavy"; the Figma page
# is "Authoring", row 4 (4b, 4d, 4g) and its dark pt-BR copy.
#
# Marking which region or position is correct is a tap, so it is not heavy (D17).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite.

@web
Feature: Keep heavy editing for a larger screen, and the rest usable on a phone
  As a teacher fixing content from a phone
  I want to see every part of what I am editing and change all but the pointer-only parts
  So that a quick fix never waits for a computer, and nothing breaks on a small screen

  Background:
    Given "bob" is signed in as a teacher

  # ── Image regions ────────────────────────────────────────────────────────────

  Rule: On a phone an image's regions are shown, not drawn; which is correct is still a tap

    Scenario: The regions are shown read-only, with the note under them
      Given "bob" uses a phone
      When "bob" opens their image-recognition exercise "Find the A on string 5"
      Then the stimulus image shows its 3 regions, numbered 1 to 3
      And no region can be drawn, moved or resized
      And a note under the image says "Drawing or moving regions is best done on a larger screen. Which region is correct can be changed here."

    Scenario: Marking which region is correct is a tap
      Given "bob" uses a phone
      And "bob" is editing "Find the A on string 5", whose region 1 is correct
      Then each region is listed under "Answer — which regions are correct", region 1 as "Correct"
      When "bob" taps "Mark correct" on region 2
      Then region 2 is correct
      And the app bar shows the Save button

    Scenario: Unmarking the only correct region blocks the save
      Given "bob" uses a phone
      And "bob" is editing "Find the A on string 5", whose only correct region is region 1
      When "bob" taps "Correct" on region 1
      Then region 1 shows "Mark correct"
      And Save is blocked by "Mark at least one option correct"

    Scenario: A new image on a phone has no regions to mark
      Given "bob" uses a phone
      And "bob" is creating an image-recognition exercise
      When "bob" uploads the stimulus image
      Then the image is shown with the larger-screen note
      And the answer list says no regions have been drawn yet
      And Save is blocked by "Mark at least one option correct"

    Scenario Outline: A tablet and a computer draw regions as today
      Given "bob" uses a <device>
      When "bob" opens their image-recognition exercise "Find the A on string 5"
      Then "bob" can draw, move and resize regions on the image
      And no larger-screen note is shown

      Examples:
        | device   |
        | tablet   |
        | computer |

  # ── Positions in the Diagrams library ────────────────────────────────────────

  Rule: On a phone a library diagram's board is a preview; the rest of the diagram stays editable

    Scenario: The board is a preview, with the note under it
      Given "bob" uses a phone
      When "bob" opens their diagram "A minor pentatonic — box 1"
      Then the board shows the diagram as students see it
      And no position can be placed, moved or removed
      And a note under the board says "Placing and moving positions is best done on a larger screen. The rest of this diagram can be changed here."

    Scenario: The name, the marker labels and the skills stay editable
      Given "bob" uses a phone
      And "bob" is editing their diagram "A minor pentatonic — box 1"
      When "bob" changes its marker labels from Interval to Note
      Then the preview board labels the markers with their notes
      And the app bar shows the Save button

    Scenario: Save as… works from a phone
      Given "bob" uses a phone
      And "bob" is editing the template "A minor pentatonic — box 1"
      When "bob" saves it as "A minor pentatonic — my fingering"
      Then a copy named "A minor pentatonic — my fingering" is created with the same positions

    Scenario: A new diagram on a phone says where its positions get placed
      Given "bob" uses a phone
      When "bob" creates a new diagram
      Then the board is empty
      And the larger-screen note is shown under it

    Scenario Outline: A tablet and a computer place positions as today
      Given "bob" uses a <device>
      When "bob" opens their diagram "A minor pentatonic — box 1"
      Then "bob" can place, move and remove positions on the board
      And no larger-screen note is shown

      Examples:
        | device   |
        | tablet   |
        | computer |

  # ── Chords over song-chart lyrics ────────────────────────────────────────────

  Rule: On a phone a song chart's lyrics are shown as students see them

    Scenario: Placing chords waits for a larger screen; the details don't
      Given "ana" is signed in as an admin
      And "ana" uses a phone
      When "ana" opens the song chart "Amazing Grace"
      Then the lyrics and chords are shown as students see them, read-only
      And a note under them says "Placing chords needs a larger screen. Status, details and rights work here."
      And the title, key, capo, meter and sections stay editable

  # ── The limit is the size class ──────────────────────────────────────────────

  Rule: Turning a phone or widening a window past Compact unlocks the heavy parts at once

    Scenario: Widening the window unlocks placing positions
      Given "bob" is editing their diagram "A minor pentatonic — box 1" in a window 390 px wide
      When the window is widened to 768 px
      Then "bob" can place, move and remove positions on the board
      And the larger-screen note is gone
