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

  @wip
  Scenario: No generated question marks its answer
    When every item of every installed drill family is planned, in every way and every variant
    Then no planned question sets a right answer apart from the other places or options by a label, marker shape, colour, highlight or size

  @wip
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
  Scenario: On bass, a numeral is answered by tapping the chord's root
    When the diatonic chord vi in G is planned as numeral_to_chord on "electric-bass"
    Then the student is asked to tap the root of vi in G on the bass fretboard
    And no place on the fretboard is marked

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: A template whose second way asks another kind of item fails the installation
    Given a drill template "diatonic_chord:numeral_to_chord" whose second way is "fretboard_cell:find_the_note"
    When the practice drill catalog is installed
    Then the installation aborts, naming "diatonic_chord:numeral_to_chord"

  @wip
  Scenario: An answer among options the plan didn't offer is rejected
    Given the diatonic chord vi in G was planned as numeral_to_chord with four chord options
    When "alice" answers it with a chord that was not one of the four
    Then the answer is rejected as unknown_option
    And no evidence is stored
