Feature: Generated drill questions challenge the student
  As a student
  I want every generated question to need the skill it names
  So that a right answer means I know it, never that the screen told me

  # Rules (ADR-057, practice-drills.md "Challenge rules"): no marked answer; plausible
  # distractors; the answer is never in the wording; every item asked among options is asked a
  # second way or comes back later in the session; variants harden as the student's level on the
  # item rises. They bind generated drills only: authored exercises are their author's
  # responsibility. The drill families v2 are built slice by slice (P1–P7); a scenario core
  # doesn't run yet carries its ticket's tag until core lists that ticket as implemented.

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

  Scenario: A numeral question offers only chords of the asked key
    When the diatonic chord vi in G is planned as numeral_to_chord
    Then it offers four chords, all of them chords of G major
    And one of them is E minor

  Scenario: A progression question offers its confusable progressions first
    When the progression "I-V-vi-IV" is planned as progression_by_number
    Then its options include "I-vi-IV-V" and "vi-IV-I-V"
    And every option has four bars

  Scenario: The tonic is never a numeral item, since the key names its chord
    When every diatonic chord and chord function item of G major is listed
    Then there is one for each of ii, iii, IV, V, vi and viio
    And none is for I

  Scenario: A function question offers exactly one chord with the asked function
    When the chord function V in G is planned as function_to_chord
    Then it offers four chords of G major
    And "D" is the only one of them that is dominant in G

  Scenario: A chord function question gives the key's triad, never a seventh
    When the chord function V in G is planned as chord_to_function
    Then the chord it gives is "D"
    And it offers tonic, subdominant and dominant

  Scenario: A chart question offers the charts of the progression's confusables in the asked key
    When the progression "I-V-vi-IV" is planned as numbers_to_chart in G
    Then its options are the charts "G D Em C", "G Em C D", "Em C G D" and "G Em Am D"
    And the question names "I-V-vi-IV" and G, and no chart

  Scenario: A numeral question's wording never names the chord asked for
    When the diatonic chord vi in G is planned as numeral_to_chord
    Then the question names the key and the numeral, and no chord

  Scenario: A diatonic chord picked right is next asked the other way
    Given "alice" has picked the chord for vi in G correctly twice and has never named its numeral
    When the diatonic chord vi in G is picked for "alice"'s session in the head
    Then it is asked as chord_to_numeral

  Scenario: A heard chord named right by ear is next asked by sight
    Given "alice" has named the heard chord vi by ear correctly twice and has never named it by sight
    When the heard chord vi is picked for "alice"'s session in the head
    Then it is asked as see_then_name

  Scenario: A heard chord asked by sight shows the chord and names the key
    When the heard chord vi is planned as see_then_name in G for a session that reads chords on "guitar"
    Then the question names G and draws the box of "Em", unnamed
    And it offers numerals, one of them vi
    And it plays nothing

  Scenario: A cadence's bars show their numerals, and the asked chord's bar shows none
    Given "alice" is learning the heard chord vi in G
    When it is planned for "alice"
    Then the bars play "G", "C", "D", "G" and then "Em"
    And the first four bars show I, IV, V and I, and the last shows no numeral

  Scenario: A heard progression's bars show no numeral
    When the heard progression "I-V-vi-IV" is planned as progression_by_number in G
    Then the bars play "G", "D", "Em" and "C"
    And no bar shows a numeral

  # A heard progression's options name every bar heard, in order, so the numerals shown always
  # match the chords played (MOT-197, ADR-074). The catalog names are unchanged elsewhere.
  @MOT-197
  Scenario: A heard progression's options are named by every bar heard
    When the heard progression "IV-V-I" is planned as progression_by_number in G
    Then the bars play "C", "D", "G" and "G"
    And its own option is named "IV–V–I–I"
    And every option's name has four numerals

  @MOT-197
  Scenario: A read chart keeps the catalog's name for its progression
    When the progression "IV-V-I" is planned as chart_to_numbers in G
    Then its own option is named "IV–V–I"

  # A heard chord quality: one chord alone, on a root picked each time, its quality picked
  # (MOT-197, ADR-074).
  @MOT-197
  Scenario: A heard chord quality plays one chord alone and offers three qualities
    Given "alice" is learning the heard chord quality "minor"
    When it is planned for "alice"
    Then its playback has one bar, a minor triad, with no numeral
    And it is asked in no key
    And it offers major, minor and dominant7, in that order

  @MOT-197
  Scenario: A heard chord quality offers five qualities once the student is fluent on it
    Given "alice" is fluent on the heard chord quality "minor"
    When it is planned for "alice"
    Then it offers major, minor, dominant7, diminished and augmented, in that order

  @MOT-197
  Scenario: A heard chord quality's root changes from one time to the next
    When the heard chord quality "major" is planned 20 times
    Then its chord is played on more than one root

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A drill with no second way brings its item back later in the session
    Given "alice" has new heard chords of G major
    When "alice" composes a 10-minute session with no instrument in hand
    Then every heard chord in the session is asked again later in the same session
    And at least three other items come between the two times it is asked
    And the second time it is asked by ear, as cadence_then_chord

  Scenario: A chart question is asked in an easy key while the student is learning it
    Given "alice" is learning the chart progression "I-V-vi-IV"
    When it is planned for "alice"
    Then it is asked in one of C, G, D, F and A

  Scenario: New diatonic chords come key by key around the circle of fifths
    Given "alice" has never practised a diatonic chord
    When "alice" composes a session in the head whose new items include diatonic chords
    Then every new diatonic chord in the session is in C major

  Scenario: A heard chord is played after a cadence until the student is accurate on it
    Given "alice" is learning the heard chord vi in G
    When it is planned for "alice"
    Then a cadence in G plays before the chord

  Scenario: A heard chord is played after the tonic alone once the student is accurate on it
    Given "alice" is accurate on the heard chord vi in G
    When it is planned for "alice"
    Then only the tonic chord of G plays, for one bar, before the chord

  Scenario: A heard chord offers four numerals until the student is fluent on it
    Given "alice" is accurate on the heard chord vi
    When it is planned for "alice"
    Then it offers vi and the three numerals nearest it

  Scenario: A heard chord offers all seven numerals once the student is fluent on it
    Given "alice" is fluent on the heard chord vi
    When it is planned for "alice"
    Then it offers I, ii, iii, IV, V, vi and viio

  # A heard question's tempo is never graded, so it starts at the same speed at every level:
  # 70 BPM in eighths, two chords a bar. The level hardens what is asked instead.
  @MOT-195
  Scenario: A heard progression never answered starts at 70 BPM in eighths
    When the heard progression "I-V-vi-IV" is planned as progression_by_number in G
    Then its playback starts at 70 BPM in eighths

  @MOT-195
  Scenario Outline: A heard progression starts at 70 BPM in eighths at every level
    Given "alice" is <level> on the heard progression "I-V-vi-IV"
    When it is planned for "alice"
    Then its playback starts at 70 BPM in eighths

    Examples:
      | level    |
      | learning |
      | accurate |
      | fluent   |

  @MOT-195
  Scenario Outline: A heard chord starts at 70 BPM in eighths at every level
    Given "alice" is <level> on the heard chord vi in G
    When it is planned for "alice"
    Then its playback starts at 70 BPM in eighths

    Examples:
      | level    |
      | learning |
      | accurate |
      | fluent   |

  @web @MOT-197
  Scenario: A heard chord quality plays its chord and offers the qualities by name
    Given "alice"'s session in the head plans the heard chord quality "minor"
    When the item is shown
    Then "Which kind of chord is it?" is asked, with no chord name and no key shown
    And the chord plays once, and can be played again
    And the options read "Major", "Minor" and "With a seventh (7)"

  @web @MOT-197
  Scenario: A heard progression's options read every bar heard
    Given "alice"'s session in the head plans the heard progression "IV-V-I" in G
    When the item is shown
    Then four chords play, and every option shows four numerals, one of them "IV–V–I–I"

  @web
  Scenario: A heard question's tempo and note value can be changed without changing the grade
    Given the heard progression "I-V-vi-IV" was planned for "alice" at 70 BPM in eighths
    When "alice" plays it at 120 BPM in eighths and picks "I-V-vi-IV"
    Then the answer is graded right
    And the answer carries the sound it played at that speed as its audio time

  Scenario: Heard progressions are four bars only
    When every heard progression item is listed
    Then there is one for each 4-bar progression of the progression catalog
    And none is for "12-bar-blues" or "12-bar-blues-quick-change"

  Scenario: A heard progression has 2 to 4 bars
    Given the drills have the created progression "major/I-V" with the bars I V
    And the drills have the created progression "major/I-vi-IV-V-I-vi-IV-V" with the bars I vi IV V I vi IV V
    When every heard progression item is listed
    Then there is one for "major/I-V"
    And none is for "major/I-vi-IV-V-I-vi-IV-V"

  # Made-up wrong answers (ADR-072): when too few drill progressions share the asked one's length
  # and mode, the rest change one of its bars, to a chord it already plays, then to a triad of its
  # mode. Each is offered as the progression it would be if an admin created it.
  Scenario: A progression question fills its options with made-up wrong answers
    Given the drills have the created progression "major/I-IV-V" with the bars I IV V
    When the progression "major/I-IV-V" is planned as chart_to_numbers in C
    Then it offers four progressions of three bars, all major
    And every option but "major/I-IV-V" differs from it in exactly one bar
    And every option is named by its numerals

  Scenario: A made-up chart question offers made-up charts in the key
    Given the drills have the created progression "major/I-IV-V" with the bars I IV V
    When the progression "major/I-IV-V" is planned as numbers_to_chart in G
    Then it offers four charts of three chords, one of them "G C D"

  Scenario: A made-up wrong answer keeps the progression's chords
    Given the drills have the created progression "major/I7-IV7-I7-V7-IV7-I7-V7-I7" with the bars I7 IV7 I7 V7 IV7 I7 V7 I7
    When the progression "major/I7-IV7-I7-V7-IV7-I7-V7-I7" is planned as chart_to_numbers in C
    Then it offers two progressions of eight bars
    And every bar of the other option is one of I7, IV7 and V7

  Scenario: A made-up wrong answer is never a drill progression
    Given the drills have the created progression "major/I-IV-V" with the bars I IV V
    And the drills have the created progression "major/I-IV-I" with the bars I IV I
    When the progression "major/I-IV-V" is planned as chart_to_numbers 20 times
    Then every option but "major/I-IV-V" and "major/I-IV-I" is a progression no drill has

  Scenario: A chart of eight bars is read as chord symbols, two lines of four
    Given the drills have the created progression "major/I-vi-IV-V-I-vi-IV-V" with the bars I vi IV V I vi IV V
    When the progression "major/I-vi-IV-V-I-vi-IV-V" is planned as chart_to_numbers in G for a session that reads chords on "guitar"
    Then its chart is drawn as chord symbols in two lines of four bars

  Scenario: A minor progression is asked in a minor key, spelled from its tonic
    Given the drills have the created progression "minor/i-bVII-bVI-V" with the bars i ♭VII ♭VI V
    When the progression "minor/i-bVII-bVI-V" is planned as chart_to_numbers in Am
    Then its chart is "Am G F E"

  Scenario: A minor key keeps the catalog's root names
    Given the drills have the created progression "minor/i-bVII-bVI-V" with the bars i ♭VII ♭VI V
    When the progression "minor/i-bVII-bVI-V" is planned as chart_to_numbers in Dbm
    Then its chart is "Dbm B A Ab"

  Scenario: A heard minor progression is only ever asked in minor keys, with no cadence
    Given the drills have the created progression "minor/i-bVII-bVI-V" with the bars i ♭VII ♭VI V
    When the heard progression "minor/i-bVII-bVI-V" is planned as progression_by_number 20 times
    Then every key it is planned in is a minor key
    And every time it plays only its four bars

  Scenario: A minor chart question is asked in an easy minor key while the student is learning it
    Given the drills have the created progression "minor/i-bVII-bVI-V" with the bars i ♭VII ♭VI V
    And "alice" is learning the chart progression "minor/i-bVII-bVI-V"
    When it is planned for "alice"
    Then it is asked in one of Am, Em, Bm, Dm and F#m

  @MOT-197
  Scenario: A heard chord quality is never planned for a session with an instrument in hand
    Given "alice" has the heard chord quality "minor" due
    When "alice" composes a session with "guitar" in hand
    Then no heard chord quality is in the session

  Scenario: On bass, a root line plays under a heard question's chords
    When the heard progression "I-V-vi-IV" is planned as progression_by_number in G for a session that reads chords on "electric-bass"
    Then its playback has a bass line
    And its bars still play the chords "G", "D", "Em" and "C"

  Scenario: On bass, a numeral is answered by picking a chord symbol
    When the diatonic chord vi in G is planned as numeral_to_chord for a session that reads chords on "electric-bass"
    Then it offers four chord symbols, all of them chords of G major
    And no chord is drawn as a chord box

  Scenario: On guitar, a chord is drawn as its open voicing's box, unnamed
    When the diatonic chord vi in G is planned as numeral_to_chord for a session that reads chords on "guitar"
    Then every option is drawn as a chord box with no chord name
    And the box of "Em" is the chord catalog's open voicing of Em

  Scenario: A student who plays guitar and bass reads chord boxes on an even turn in the head
    Given "alice" has started 2 sessions in the head so far
    When "alice" composes a session in the head with diatonic chords in it
    Then every diatonic chord in the session is drawn as chord boxes

  Scenario: A student who plays guitar and bass reads chord symbols on an odd turn in the head
    Given "alice" has started 3 sessions in the head so far
    When "alice" composes a session in the head with diatonic chords in it
    Then every diatonic chord in the session is drawn as chord symbols

  Scenario: A 12-bar chart is read as chord symbols, three lines of four
    When the progression "12-bar-blues" is planned as chart_to_numbers in G for a session that reads chords on "guitar"
    Then its chart is drawn as chord symbols in three lines of four bars
    And it offers "12-bar-blues" and "12-bar-blues-quick-change"

  @web
  Scenario: Finding every instance never shows how many places the note has
    Given the guitar cell on string 6 at fret 3 is planned for "alice" as find_every_instance in frets 3 to 7
    When "alice" is asked to tap every G
    Then the board marks no place before "alice" taps it
    And the question doesn't say how many G's are in the window

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A template whose second way asks another kind of item fails the installation
    Given a drill template "diatonic_chord:numeral_to_chord" whose second way is "fretboard_cell:find_the_note"
    When the practice drill catalog is installed
    Then the installation aborts, naming "diatonic_chord:numeral_to_chord"

  # Answers that don't fit their question's options are graded in
  # grade-practice-response.feature.
