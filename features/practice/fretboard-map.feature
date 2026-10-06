Feature: Show how well the student knows each fretboard cell
  As a student
  I want to see my fretboard coloured by how well I know each note
  So that I can see at a glance which strings and frets I still need

  # The map shows every cell the practice catalog generates for the instrument's fretboard
  # layout. Instruments sharing a layout share its cells. Both ways of asking about a cell build
  # one level for it. It sits on the instrument's tab of the home.

  Background:
    Given the practice drill catalog is installed
    And student "alice" plays "guitar"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A practised cell shows the student's level on it
    Given "alice" has made the "guitar" cell on string 6, fret 3 accurate
    When "alice" reads their fretboard map for "guitar"
    Then the cell on string 6, fret 3 is accurate

  Scenario: The map has every generated cell of the layout, practised or not
    Given "alice" has practised no fretboard cell
    When "alice" reads their fretboard map for "guitar"
    Then the map has 72 cells, on strings 1 to 6 at frets 0 to 11
    And every cell is new

  Scenario: Naming and finding a note build one level for its cell
    Given "alice" has named the note of the "guitar" cell on string 5, fret 2 correctly on 2 different days
    And found it correctly on a third day
    When "alice" reads their fretboard map for "guitar"
    Then the cell on string 5, fret 2 is accurate

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A cell whose review is due is marked fading
    Given "alice"'s "guitar" cell on string 6, fret 5 is fluent and its review was due yesterday
    When "alice" reads their fretboard map for "guitar"
    Then the cell on string 6, fret 5 is fluent and fading

  Scenario: Instruments that share a fretboard layout share the map
    Given "alice" has made the "guitar" cell on string 6, fret 3 accurate
    When "alice" reads their fretboard map for "electric-guitar"
    Then the cell on string 6, fret 3 is accurate

  Scenario: An instrument without generated cells has an empty map
    When "alice" reads their fretboard map for "piano"
    Then the map has no cells

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A map for an instrument that doesn't exist is refused
    When "alice" reads their fretboard map for an instrument that doesn't exist
    Then the request is refused with a not-found error
