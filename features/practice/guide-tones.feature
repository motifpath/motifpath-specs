Feature: Tap the guide tones of a progression in time
  As a student
  I want to tap the third, later the seventh, of each chord as a progression plays
  So that I connect the harmony to the neck before I improvise over changes

  # A guide tone (MOT-151, rung target) plays one progression of the progression catalog once in
  # a key, one chord a bar after a bar of count-in. While each chord sounds, the student taps the
  # asked tone of it on an empty fretboard of frets 0–5, graded by timed_taps.v1. Each time the
  # item is planned:
  # - the tone is each chord's third until the student is accurate on the item, then its seventh;
  # - the key is one of the 12 major keys at random, never the key of the item's last take;
  # - the tempo starts at 60 BPM while new or learning, 72 once accurate, 90 once fluent;
  # - a 12-bar blues is planned only once the student is accurate on target-chord-tones.
  # A right take's fluency is its effective speed over 90 BPM (knowledge-state.feature).

  Background:
    Given the progression catalog has "ii-V-I" with the bars ii V I I
    And the progression catalog has "12-bar-blues" with 12 bars

  # ── What the plan asks ─────────────────────────────────────────────────────

  @wip
  Scenario: A guide tone never practised asks the third at 60 BPM
    Given "alice" has never practised the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session
    Then it asks the tone 3 at a start tempo of 60 BPM, with a target of 90 BPM
    And it plays over at most 3 takes

  @wip
  Scenario: Once accurate on the item, the guide tone asks the seventh at 72 BPM
    Given "alice" is accurate on the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session
    Then it asks the tone 7 at a start tempo of 72 BPM

  @wip
  Scenario: Once fluent on the item, the guide tone starts at 90 BPM
    Given "alice" is fluent on the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session
    Then it asks the tone 7 at a start tempo of 90 BPM

  @wip
  Scenario: The key is never the key of the item's last take
    Given "alice"'s last take of the guide tone of "ii-V-I" on guitar was in G
    When the guide tone is picked for "alice"'s session 20 times
    Then it is never planned in G
    And every key it is planned in is a major key

  @wip
  Scenario: The plan lists the bars in the key, with a voicing per chord
    Given "alice" has never practised the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session in G
    Then its bars are ii V I I with the chords "Am D G G"
    And it has a voicing for each of "Am", "D" and "G"

  @wip
  Scenario: The plan never gives away the notes to tap
    Given "alice" has never practised the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session
    Then the plan names no note to tap and no place on the fretboard

  @wip
  Scenario: The fretboard window is frets 0–5 on guitar and on bass
    When the guide tone of "ii-V-I" is picked for "alice"'s session on guitar
    And the guide tone of "ii-V-I" is picked for "bob"'s session on electric bass
    Then both are asked within frets 0 to 5, the open string included

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A 12-bar blues isn't planned before the student is accurate on target-chord-tones
    Given "alice" is learning "target-chord-tones"
    And "alice" has new guide tones of every progression on guitar
    When "alice" composes 10 sessions with no instrument in hand
    Then no session plans the guide tone of "12-bar-blues"

  @wip
  Scenario: Once accurate on target-chord-tones, a 12-bar blues can be planned
    Given "alice" is accurate on "target-chord-tones"
    And the only guide tone "alice" has left to practise on guitar is "12-bar-blues"
    When "alice" composes a session with no instrument in hand
    Then the session plans the guide tone of "12-bar-blues" with 12 bars

  @wip
  Scenario: A 12-bar blues keeps its dominant seventh chords in the bars
    Given "alice" is accurate on the guide tone of "12-bar-blues" on guitar
    When the guide tone is picked for "alice"'s session in A
    Then it asks the tone 7 and the bars start with the chord "A7"

  # ── Failure ────────────────────────────────────────────────────────────────

  @wip
  Scenario: A guide tone of a progression the catalog no longer has is never planned
    Given "alice" has evidence for the guide tone of "I-II-III" on guitar
    When "alice" composes a session with no instrument in hand
    Then no session item is the guide tone of "I-II-III"
