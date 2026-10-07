Feature: Practise diagram shapes in the head
  As a student
  I want to recall the shapes I'm learning (CAGED grips, pentatonic boxes, triads, scale windows)
  So that I memorise them without anyone authoring an exercise for each one

  # Shapes come from the diagram catalog: each family of the practice drill catalog takes the
  # catalog diagrams whose key matches its pattern, and every matched diagram is one practice
  # item, keyed diagram_shape:<diagram id>. A shape is asked two ways: name the shape (shown
  # without its name, picked among every member of its family) and find the degree (shown with
  # its root marked and its other positions unlabelled; tap the asked degree). Grading rules are
  # pinned case by case in golden/practice-graders/diagram_shape.v1.json.

  Background:
    Given the practice drill catalog is installed
    And the basic guitar diagram catalog is installed

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: Every CAGED major grip in the catalog is a shape of the caged-grip family
    When the shapes of family "caged-grip" are listed
    Then there are 52 shapes, one per catalog diagram "caged/{root}/{shape}/{shift}"
    And each shape's item key names its diagram
    And the diagram "C major — CAGED A, shift 3" is the member "A"

  @wip
  Scenario: Every shape can be asked both ways
    When a shape of family "minor-pentatonic-box" is picked for practice
    Then it can be asked through "diagram_shape:name_the_shape" or "diagram_shape:find_the_degree"

  @wip
  Scenario: Naming a shape offers every member of its family
    When the shape "C major — CAGED A, shift 3" is asked as name_the_shape
    Then the options are "C shape", "A shape", "G shape", "E shape" and "D shape", in that order

  @wip
  Scenario: Finding a degree asks one of the shape's degrees other than its root
    When the shape "A minor pentatonic — Box 1, fret 5" is asked as find_the_degree
    Then the asked degree is one of "b3", "4", "5" and "b7"

  @wip
  Scenario: A shape counts toward its diagram's skill
    Given student "alice" plays "guitar"
    And the only practice items of skill "map-fretboard-caged" on guitar are 5 shapes
    And "alice" is fluent on 4 of those shapes
    When "alice"'s level for "map-fretboard-caged" on guitar is derived
    Then it is "fluent"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: The options include a member that doesn't fit at this root
    When the shape "B major — CAGED A, shift 2" is asked as name_the_shape
    Then the options include "C shape", although B has no C-shape grip inside frets 0–12

  @wip
  Scenario: The same shape at another root is another item
    When the shapes "C major — CAGED A, shift 3" and "D major — CAGED A, shift 5" are listed
    Then they have different item keys

  @wip
  Scenario: A catalog map that belongs to no family is not a shape
    When the shapes of every family are listed
    Then the diagram "C Chromatic map — Frets 0–12" is not among them

  @wip
  Scenario: A shape suits the instruments its diagram is linked to
    When the shape "C major — CAGED A, shift 3" is listed
    Then it suits "guitar" and "electric-guitar" and no other instrument

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: A family that matches no catalog diagram fails to install
    Given a drill catalog listing the family "lydian-window" with the pattern "caged-window/lydian/{root}/{shape}/{shift}"
    When the drill catalog is installed
    Then the installation fails, naming the family "lydian-window"

  @wip
  Scenario: A catalog diagram whose shape isn't a member of its family fails to install
    Given a drill catalog listing the family "caged-grip" with only the members "C", "A", "G" and "E"
    When the drill catalog is installed
    Then the installation fails, naming the family "caged-grip" and the member "D"

  # ── The drill screen ───────────────────────────────────────────────────────

  @web
  Scenario: A shape to name is shown without its name or its labels
    Given "alice"'s session asks to name the shape "C major — CAGED A, shift 3"
    When the shape is shown
    Then its markers show no interval or note
    And the diagram's name is not shown

  @web
  Scenario: A wrongly named shape reveals the right one
    Given "alice"'s session asks to name the shape "C major — CAGED A, shift 3"
    When "alice" picks "E shape"
    Then "A shape" is shown as the right answer
    And practice.item_answered is sent with the shape "E"

  @web
  Scenario: A degree to find is asked on the shape with its root marked
    Given "alice"'s session asks to find the degree "3" on "C major — CAGED A, shift 3"
    When the shape is shown
    Then its roots are marked and its other positions show no label
    And the question asks for the "3"

  @web
  Scenario: A wrong tap reveals where the degree is
    Given "alice"'s session asks to find the degree "3" on "C major — CAGED A, shift 3"
    When "alice" taps string 3 at fret 5
    Then the position on string 2 at fret 5 is shown as the right answer
    And practice.item_answered is sent with the degree "3", string 3 and fret 5
