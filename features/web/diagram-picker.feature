# The diagram picker in authoring (MOT-61 D16, MOT-95; Figma "Authoring" row 14, approved 2026-10-11).
#
# One picker wherever a diagram goes: a prompt or article embed, an image-recognition stimulus, an
# image-choice option. Two steps at every size: choose a diagram or a chord, then set how it shows.
# Chords are found by a root and a quality, or by typing a symbol in any case; diagrams by name, root,
# author and type. design/patterns/authoring.md, "Diagrams in authoring".
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite. Reading a chord symbol and the catalog's voicings are in
# golden/chord-symbols and features/content-management/chord-catalog.feature.

@web
Feature: Pick a diagram or a chord to show in content
  As a teacher
  I want one picker that finds a diagram or a chord quickly and lets me set how it shows
  So that every exercise and lesson can show the diagram or chord I mean

  Background:
    Given "bia" is signed in as a teacher
    And the chord catalog has "Am" with voicings starting open, at the 5th, 7th and 12th fret
    And the chord catalog has "Am7" and "A"
    And the diagram library has 126 diagrams, among them "A minor pentatonic — open" with root A

  # ── One picker ───────────────────────────────────────────────────────────────

  Rule: Every place that takes a diagram opens the same picker, with Diagrams and Chords

    Scenario Outline: The picker offers diagrams and chords wherever a diagram goes
      When "bia" picks a diagram for <place>
      Then the picker offers Diagrams and Chords

      Examples:
        | place                               |
        | an image-recognition stimulus       |
        | an image-choice option              |
        | an embed in an article lesson       |

    Scenario: A chord is picked as an image-recognition stimulus
      Given "bia" is picking a diagram for an image-recognition stimulus
      When "bia" picks the open voicing of "Am" and inserts it
      Then the stimulus shows "Am" as its chord box

  # ── Choosing a chord ─────────────────────────────────────────────────────────

  Rule: A chord is found by its root and its quality, or by typing it in any case

    Scenario: Choosing a root and a quality lists that chord's voicings
      Given "bia" is on the Chords tab
      When "bia" chooses the root "A" and the quality "m"
      Then the voicings of "Am" are listed, each named by its chord and where it sits: "Am · Open", "Am · 5fr", "Am · 7fr" and "Am · 12fr"

    Scenario: Only one quality is chosen at a time
      Given "bia" has chosen the root "A" and the quality "m"
      When "bia" chooses the quality "m7"
      Then only "m7" is chosen
      And the voicings of "Am7" are listed

    Scenario: The major quality lists the plain chord
      When "bia" chooses the root "A" and the quality "Major"
      Then the voicings of "A" are listed

    Scenario Outline: A typed symbol is read in any case
      Given "bia" is on the Chords tab
      When "bia" types "<typed>"
      Then the voicings of "<chord>" are listed

      Examples:
        | typed | chord |
        | am    | Am    |
        | AM7   | Am7   |
        | a     | A     |

    Scenario: A symbol that isn't a chord says so in words
      Given "bia" is on the Chords tab
      When "bia" types "h7"
      Then the picker says "h7" isn't a chord it can read
      And no message key is shown

    Scenario: A chord the catalog lacks says so
      Given "bia" is on the Chords tab
      When "bia" types "C#13b9"
      Then the picker says the chord catalog doesn't have "C#13b9"

  # ── Choosing a diagram ───────────────────────────────────────────────────────

  Rule: Diagrams are found by name, root, author and type, all shown at once

    Scenario: The filters are shown with the number of diagrams they leave
      Given "bia" is on the Diagrams tab
      Then the search, Root, Author and Type are shown without opening anything
      And the picker says "126 diagrams"

    Scenario: A filter narrows the list and can be cleared
      Given "bia" is on the Diagrams tab
      When "bia" chooses the root "A"
      Then only diagrams with root A are listed, with their number
      And Clear filters is offered
      When "bia" clears the filters
      Then the picker says "126 diagrams" again

    Scenario: The filters stay in place while the results scroll
      Given "bia" is on the Diagrams tab
      When "bia" scrolls the diagrams
      Then the search and the filters are still shown

  # ── Setting how it shows ─────────────────────────────────────────────────────

  Rule: A pick opens its settings, and Insert puts it in place

    Scenario: A chord's settings show it as its chord box
      Given "bia" is on the Chords tab with the voicings of "Am" listed
      When "bia" picks "Am · Open"
      Then the chord shows as its chord box, with Box | Neck, not on the fretboard
      And its labels, positions shown and playback can be set
      And Cancel and Insert are offered

    Scenario: A diagram's settings show it on its board
      Given "bia" is on the Diagrams tab
      When "bia" picks "A minor pentatonic — open"
      Then the diagram shows on its board
      And its labels, positions shown and playback can be set
      And Cancel and Insert are offered

    Scenario: Going back from the settings keeps the pick marked
      Given "bia" has picked "Am · Open" and its settings are shown
      When "bia" chooses Change chord
      Then the voicings of "Am" are listed again, with "Am · Open" marked as picked

    Scenario: Cancel inserts nothing
      Given "bia" has picked "Am · Open" and its settings are shown
      When "bia" cancels
      Then the picker closes and nothing is inserted
