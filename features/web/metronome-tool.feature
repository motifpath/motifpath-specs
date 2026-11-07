# The Metronome tool (MOT-156): the first tool of the Practice Shell's Tools, opened from the
# session setup's header. It is the same metronome as every embedded one (TempoControl) plus the
# bar: tempo, note value and time signature, each choice shown on demand (ADR-061;
# design/patterns/metronome.md).
#
# These scenarios are verified by motifpath-web's component and story tests, not by any
# service's BDD suite: the tool is client-only and sends nothing. A note value is a speed factor:
# in the tool, which has no notes, it is the number of clicks per beat (quarters 1, eighths 2,
# triplets 3, sixteenths 4, quintuplets 5, sextuplets 6, 32nds 8, halves every other beat).

@web
Feature: Keep time with the Metronome tool
  As a student
  I want a metronome where I can set the tempo, the time signature and the note value
  So that I can practise with a click outside a session too

  Background:
    Given "alice" is signed in as a student
    And "alice" is on the practice setup

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Tools on the setup open the Metronome
    When "alice" opens Tools and chooses "Metronome"
    Then the Metronome page opens in the practice shell
    And it is set to 80 BPM in 4/4, in quarters, and silent

  Scenario: The metronome clicks every beat of the bar, the downbeat louder
    Given "alice" is on the Metronome page at 80 BPM in 4/4, in quarters
    When "alice" starts it
    Then it clicks 4 times a bar at 80 BPM, the first click of each bar louder
    And the lit beat dot follows the sounding beat

  Scenario: Eighths click twice a beat, the beat louder
    Given "alice" is on the Metronome page at 80 BPM in 4/4
    When "alice" opens the note value and chooses "Eighths"
    And "alice" starts it
    Then it clicks 8 times a bar, each beat's click louder than the one between beats
    And the note value shows the eighths icon

  Scenario: A preset time signature is one tap away
    Given "alice" is on the Metronome page in 4/4
    When "alice" taps the time signature and chooses "3/4"
    Then the bar shows 3/4 with 3 beat dots

  Scenario: The beats and the beat note change with − and +
    Given "alice" is on the Metronome page in 4/4
    When "alice" taps the time signature, presses + on the beats 3 times and − on the beat note once
    Then the bar shows 7/8 with 7 beat dots

  Scenario: A change while it plays applies from the next beat
    Given the metronome is playing at 80 BPM
    When "alice" sets the tempo to 100 BPM
    Then the clicks after the next beat are at 100 BPM, without stopping

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Every note value is offered in the tool, named in words
    When "alice" opens the Metronome and opens the note value
    Then it offers halves, quarters, eighths, triplets, sixteenths, quintuplets, sextuplets and 32nds as icons
    And the chosen one is ringed and named in words

  Scenario: Halves click every other beat
    Given "alice" is on the Metronome page at 80 BPM in 4/4
    When "alice" chooses "Halves" and starts it
    Then it clicks on beats 1 and 3 of each bar

  Scenario: A compound bar accents each dotted-quarter group
    Given "alice" is on the Metronome page
    When "alice" chooses "6/8" and starts it
    Then it clicks 6 times a bar, the first and the fourth louder

  Scenario Outline: The beats stay between 1 and 12
    Given the bar is <bar>
    When "alice" presses <button> on the beats
    Then the bar is still <bar>

    Examples:
      | bar  | button |
      | 1/4  | −      |
      | 12/8 | +      |

  Scenario: A popover closes unchanged on a tap outside it
    Given "alice" has opened the note value on the Metronome page, in quarters
    When "alice" taps outside the popover
    Then the popover closes and the note value is still quarters

  Scenario: Tools are not offered during a run
    Given "alice" has started practising
    Then the practice shell header offers no Tools

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: Leaving the Metronome stops it
    Given the metronome is playing
    When "alice" goes back to the practice setup
    Then the metronome stops

  Scenario: The Metronome sends nothing
    When "alice" starts the Metronome, changes the tempo, the note value and the time signature, and leaves
    Then nothing is sent
