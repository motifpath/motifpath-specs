Feature: Compose a practice session
  As a student
  I want a session built for the time I have and the instrument in my hands
  So that every minute goes to what helps me most, and I always know why

  # Rules: teacher suggestions first; then due 60%, weak 25%, new 15% of the time, the new
  # share being a ceiling balanced across the student's instruments. Due and weak take over
  # each other's unused time; whatever is still left is split 50/50 between review ahead and
  # stretch, as for a caught-up student. Weak = practised, not due, not yet fluent. Every pick
  # carries a reason.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And "alice" is enrolled in a path whose skills have practice items for both instruments

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: Every item in a session carries the reason it was picked
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item in the session has one of the reasons teacher_suggested, due, weak, new, warm_up, application, review_ahead or stretch

  @wip
  Scenario: Due, weak and new items share the time 60, 25 and 15
    Given "alice" has plenty of due, weak and new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 12 minutes go to due items, 5 to weak items and 3 to new items

  @wip
  Scenario: A teacher's suggestion comes before everything else
    Given a teacher suggested the play-along "pentatonic-run" to "alice"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the first item after the warm-up is "pentatonic-run" with the reason teacher_suggested

  Scenario: A session with the instrument in hand starts with a warm-up on something known
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session starts with "c-major-scale" with the reason warm_up at 80 BPM

  @wip
  Scenario: A session of 10 minutes or more ends by applying a skill to music
    Given "alice"'s path skill "chord-tones" has exercises and the play-along "chord-tone-riff" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the last item is a play-along with the reason application
    And it applies a skill that the session's focus items practise

  @wip
  Scenario: Authored exercises on the student's path are focus items
    Given "alice"'s path skill "chord-tones" has the exercise "name-the-third" for every instrument
    And "alice" has never answered "name-the-third"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes "name-the-third" with the reason new

  @wip
  Scenario: A session under 10 minutes has no application ending
    When "alice" composes a 9-minute session with "guitar" in hand
    Then no item in the session has the reason application

  # ── Weak items and leftover time ───────────────────────────────────────────

  @wip
  Scenario: An item practised, not due and not yet fluent is weak
    Given "alice" is accurate but not fluent on "pentatonic-run", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the session includes "pentatonic-run" with the reason weak

  @wip
  Scenario: A fluent item that isn't due is never weak
    Given "alice" is fluent on "c-major-scale", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then "c-major-scale" is not in the session with the reason weak

  @wip
  Scenario: Due items take over the time weak items don't use
    Given "alice" has plenty of due items, no weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 17 minutes go to due items and 3 to new items

  @wip
  Scenario: Weak items take over the time due items don't use
    Given "alice" has no due items, plenty of weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 17 minutes go to weak items and 3 to new items

  @wip
  Scenario: Time left after due, weak and new goes to review ahead and stretch
    Given "alice" has 4 minutes of due items, nothing weak and 1 minute of new items on guitar
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings"
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the minutes left after the due and new items are split about evenly between review_ahead and stretch items

  # ── Instruments ────────────────────────────────────────────────────────────

  Scenario: With an instrument in hand, only items that suit it are picked
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then every item in the session suits "electric-bass" or every instrument

  @wip
  Scenario: A session in the head picks only items that need no instrument in hand
    When "alice" composes a 5-minute session with no instrument in hand
    Then no item in the session is a play-along
    And the session may include fretboard cells of both "guitar" and "electric-bass"

  @wip
  Scenario: New items are balanced across the student's instruments
    Given "alice" has 40 new items on guitar and 40 new items on electric bass
    When "alice" composes a 10-minute session with no instrument in hand
    Then the new items in the session are split evenly between guitar and electric bass

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: The new share is a ceiling, never filled past it
    Given "alice" has 2 due items and 200 new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no more than 3 minutes go to new items

  @wip
  Scenario: A caught-up student reviews ahead and stretches, half and half
    Given "alice" has nothing due, weak or new on their path for guitar
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then about half the session is items with the reason review_ahead
    And about half the session is items of "notes-on-high-strings" with the reason stretch

  @wip
  Scenario: When nothing is coming due, stretch takes the whole session
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item after the warm-up has the reason stretch

  @wip
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

  @wip
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
