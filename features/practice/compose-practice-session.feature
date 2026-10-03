@wip
Feature: Compose a practice session
  As a student
  I want a session built for the time I have and the instrument in my hands
  So that every minute goes to what helps me most, and I always know why

  # Rules: teacher suggestions first; then due 60%, weak 25%, new 15% of the time, the new
  # share being a ceiling balanced across the student's instruments. When caught up, the rest
  # is split 50/50 between review ahead and stretch. Every pick carries a reason.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And "alice" is enrolled in a path whose skills have practice items for both instruments

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Every item in a session carries the reason it was picked
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item in the session has one of the reasons teacher_suggested, due, weak, new, warm_up, application, review_ahead or stretch

  Scenario: Due, weak and new items share the time 60, 25 and 15
    Given "alice" has plenty of due, weak and new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 12 minutes go to due items, 5 to weak items and 3 to new items

  Scenario: A teacher's suggestion comes before everything else
    Given a teacher suggested the play-along "pentatonic-run" to "alice"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the first item after the warm-up is "pentatonic-run" with the reason teacher_suggested

  Scenario: A session with the instrument in hand starts with a warm-up on something known
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session starts with "c-major-scale" with the reason warm_up at 80 BPM

  Scenario: A session of 10 minutes or more ends by applying a skill to music
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes an item with the reason application

  # ── Instruments ────────────────────────────────────────────────────────────

  Scenario: With an instrument in hand, only items that suit it are picked
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then every item in the session suits "electric-bass" or every instrument

  Scenario: A session in the head picks only items that need no instrument in hand
    When "alice" composes a 5-minute session with no instrument in hand
    Then no item in the session is a play-along
    And the session may include fretboard cells of both "guitar" and "electric-bass"

  Scenario: New items are balanced across the student's instruments
    Given "alice" has 40 new items on guitar and 40 new items on electric bass
    When "alice" composes a 10-minute session with no instrument in hand
    Then the new items in the session are split evenly between guitar and electric bass

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The new share is a ceiling, never filled past it
    Given "alice" has 2 due items and 200 new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no more than 3 minutes go to new items

  Scenario: A caught-up student reviews ahead and stretches, half and half
    Given "alice" has nothing due, weak or new on their path for guitar
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then about half the session is items with the reason review_ahead
    And about half the session is items of "notes-on-high-strings" with the reason stretch

  Scenario: When nothing is coming due, stretch takes the whole session
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item after the warm-up has the reason stretch

  Scenario: Stretch starts first with nodes that build on what the student has met
    Given "alice" is ready to start "notes-on-high-strings", which requires a skill they have met
    And "alice" is ready to start "chord-tones", which requires nothing
    When "alice" composes a caught-up 10-minute session with "guitar" in hand
    Then the stretch items are of "notes-on-high-strings" before "chord-tones"

  Scenario: A short session skips the warm-up
    When "alice" composes a 3-minute session with "guitar" in hand
    Then no item in the session has the reason warm_up

  Scenario: A play-along starts on the student's tempo ladder
    Given "alice"'s best clean tempo on "pentatonic-run" is 90 BPM and the diagram's tempo is 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 90 BPM with a target of 120 BPM

  Scenario: A play-along with no clean take yet starts at 60% of the diagram's tempo
    Given "alice" has never rated "pentatonic-run" clean and the diagram's tempo is 120 BPM
    When "pentatonic-run" is picked as a new item
    Then it starts at 70 BPM with a target of 120 BPM

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A session is never empty
    Given "alice" has no practice history and their path has no practice items
    When "alice" composes a 5-minute session with no instrument in hand
    Then the session has at least one item with the reason stretch

  Scenario: A session longer than an hour is refused
    When "alice" composes a 61-minute session with "guitar" in hand
    Then the request is rejected as invalid
    And the rejection identifies "minutes" as the source of the error

  Scenario: A session for an instrument that doesn't exist is refused
    When "alice" composes a 10-minute session with an instrument that doesn't exist in hand
    Then the request is refused with a not-found error
