Feature: Generated drill questions challenge the student
  As a student
  I want every generated question to need the skill it names
  So that a right answer means I know it, never that the screen told me

  # Rules (ADR-057, practice-drills.md "Challenge rules"): no marked answer; plausible
  # distractors; the answer is never in the wording; every item asked among options is asked a
  # second way or comes back later in the session; variants harden as the student's level on the
  # item rises. They bind generated drills only: authored exercises are their author's
  # responsibility. The drill families v2 are built slice by slice (P1–P7), so their scenarios
  # stay @wip until core implements them.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: No generated question marks its answer
    When every item of every installed drill family is planned, in every way and every variant
    Then no planned question sets a right answer apart from the other places or options by a label, marker shape, colour, highlight or size

  Scenario: Find the degree marks only the root it gives
    When the shape "C major — CAGED A, shift 3" is planned as find_the_degree for the 3rd
    Then the root's places are marked as the root
    And every other place of the shape is drawn the same, the 3rd's included

  @wip
  Scenario: A numeral question offers only chords of the asked key
    When the diatonic chord vi in G is planned as numeral_to_chord
    Then it offers four chords, all of them chords of G major
    And one of them is E minor

  @wip
  Scenario: A progression question offers its confusable progressions first
    When the progression "I-V-vi-IV" is planned as progression_by_number
    Then its options include "I-vi-IV-V" and "vi-IV-I-V"
    And every option has four bars

  @wip
  Scenario: A function question offers exactly one chord with the asked function
    When the chord function V in G is planned as function_to_chord
    Then it offers four chords of G major
    And "D" is the only one of them that is dominant in G

  @wip
  Scenario: A chord function question gives the key's triad, never a seventh
    When the chord function V in G is planned as chord_to_function
    Then the chord it gives is "D"
    And it offers tonic, subdominant and dominant

  @wip
  Scenario: A chart question offers the charts of the progression's confusables in the asked key
    When the progression "I-V-vi-IV" is planned as numbers_to_chart in G
    Then its options are the charts "G D Em C", "G Em C D", "Em C G D" and "G Em Am D"
    And the question names "I-V-vi-IV" and G, and no chart

  @wip
  Scenario: A numeral question's wording never names the chord asked for
    When the diatonic chord vi in G is planned as numeral_to_chord
    Then the question names the key and the numeral, and no chord

  @wip
  Scenario: A diatonic chord picked right is next asked the other way
    Given "alice" has picked the chord for vi in G correctly twice and has never named its numeral
    When the diatonic chord vi in G is picked for "alice"'s session in the head
    Then it is asked as chord_to_numeral

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A drill with no second way brings its item back later in the session
    Given "alice" has new heard chords of G major
    When "alice" composes a 10-minute session with no instrument in hand
    Then every heard chord in the session is asked again later in the same session
    And at least three other items come between the two times it is asked

  @wip
  Scenario: A chart question is asked in an easy key while the student is learning it
    Given "alice" is learning the chart progression "I-V-vi-IV"
    When it is planned for "alice"
    Then it is asked in one of C, G, D, F and A

  @wip
  Scenario: New diatonic chords come key by key around the circle of fifths
    Given "alice" has never practised a diatonic chord
    When "alice" composes a session in the head whose new items include diatonic chords
    Then every new diatonic chord in the session is in C major

  @wip
  Scenario: A heard chord is played after a cadence until the student is accurate on it
    Given "alice" is learning the heard chord vi in G
    When it is planned for "alice"
    Then a cadence in G plays before the chord

  @wip
  Scenario: A heard chord is played with no cadence once the student is accurate on it
    Given "alice" is accurate on the heard chord vi in G
    When it is planned for "alice"
    Then the chord plays with no cadence before it

  @wip
  Scenario: On bass, a numeral is answered by picking a chord symbol
    When the diatonic chord vi in G is planned as numeral_to_chord for a session that reads chords on "electric-bass"
    Then it offers four chord symbols, all of them chords of G major
    And no chord is drawn as a chord box

  @wip
  Scenario: On guitar, a chord is drawn as its open voicing's box, unnamed
    When the diatonic chord vi in G is planned as numeral_to_chord for a session that reads chords on "guitar"
    Then every option is drawn as a chord box with no chord name
    And the box of "Em" is the chord catalog's open voicing of Em

  @wip
  Scenario: A student who plays guitar and bass reads chord boxes on an even turn in the head
    Given "alice" has started 2 sessions in the head so far
    When "alice" composes a session in the head with diatonic chords in it
    Then every diatonic chord in the session is drawn as chord boxes

  @wip
  Scenario: A student who plays guitar and bass reads chord symbols on an odd turn in the head
    Given "alice" has started 3 sessions in the head so far
    When "alice" composes a session in the head with diatonic chords in it
    Then every diatonic chord in the session is drawn as chord symbols

  @wip
  Scenario: A 12-bar chart is read as chord symbols, three lines of four
    When the progression "12-bar-blues" is planned as chart_to_numbers in G for a session that reads chords on "guitar"
    Then its chart is drawn as chord symbols in three lines of four bars
    And it offers "12-bar-blues" and "12-bar-blues-quick-change"

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A template whose second way asks another kind of item fails the installation
    Given a drill template "diatonic_chord:numeral_to_chord" whose second way is "fretboard_cell:find_the_note"
    When the practice drill catalog is installed
    Then the installation aborts, naming "diatonic_chord:numeral_to_chord"

  @wip
  Scenario: An answer among options the plan didn't offer is rejected
    Given the diatonic chord vi in G was planned as numeral_to_chord with four chord options
    When "alice" answers it with a chord that was not one of the four
    Then the answer is rejected as invalid_choices
    And no evidence is stored
