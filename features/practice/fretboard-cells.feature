Feature: Generate fretboard cells as practice items
  As a student
  I want every note on the strings a skill covers to be something I can practise
  So that I can learn the whole fretboard without anyone authoring each note

  Background:
    Given the practice drill catalog is installed

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: The E and A strings on guitar are strings 6 and 5, frets 0 to 11
    When the cells for skill "find-notes-root-strings" on the "guitar" layout are generated
    Then there are 24 cells, on strings 6 and 5 at frets 0 to 11
    And each cell's item key names the "guitar" layout instrument, its string and its fret

  Scenario: The E and A strings on bass are strings 4 and 3
    When the cells for skill "find-notes-root-strings" on the "electric-bass" layout are generated
    Then there are 24 cells, on strings 4 and 3 at frets 0 to 11

  Scenario: Every cell can be asked both ways
    When a cell of skill "find-notes-root-strings" is picked for practice
    Then it can be asked through "fretboard_cell:name_the_note" or "fretboard_cell:find_the_note"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Electric guitar practises the guitar layout's cells
    When the cells for skill "find-notes-root-strings" are generated for "electric-guitar"
    Then they are the cells of the "guitar" layout, with the same item keys

  Scenario: The whole guitar fretboard is 72 cells across the two skills
    When the cells for skills "find-notes-root-strings" and "find-notes-top-strings" on the "guitar" layout are generated
    Then there are 72 cells and no cell belongs to both skills

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A catalog entry with a string the instrument doesn't have fails to install
    Given a drill catalog listing string 5 for skill "find-notes-top-strings" on the "electric-bass" layout
    When the drill catalog is installed
    Then the installation fails, naming the "electric-bass" layout and string 5

  Scenario: A catalog entry for a skill that doesn't suit the instrument fails to install
    Given a drill catalog listing a guitar-only skill on the "electric-bass" layout
    When the drill catalog is installed
    Then the installation fails, naming the skill and the "electric-bass" layout
