Feature: Compose a practice session
  As a student
  I want a session built for the time I have and the instrument in my hands
  So that every minute goes to what helps me most, and I always know why

  # Rules: teacher suggestions first; then due 60%, weak 25%, new 15% of the focus time (the
  # session minus its warm-up and its application ending), the new share being a ceiling
  # balanced across the student's instruments. Due and weak take over
  # each other's unused time; whatever is still left is split 50/50 between review ahead and
  # stretch, as for a caught-up student. Weak = practised, not due, not yet fluent. Stretch reaches
  # only nodes connected to what the student is learning: path skills, their applies and part_of
  # neighbours, and nodes that build on something the student has met. Every pick carries a reason.

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
    Then about 60% of the focus time goes to due items, 25% to weak items and 15% to new items

  @wip
  Scenario: A teacher's suggestion comes before everything else
    Given a teacher suggested the play-along "pentatonic-run" to "alice"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the first item after the warm-up is "pentatonic-run" with the reason teacher_suggested

  Scenario: A session with the instrument in hand starts with a warm-up on something known
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session starts with "c-major-scale" with the reason warm_up at 80 BPM

  Scenario: A session of 10 minutes or more ends by applying a skill to music
    Given "alice"'s path skill "chord-tones" has exercises and the play-along "chord-tone-riff" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the last item is a play-along with the reason application
    And it applies a skill that the session's focus items practise

  Scenario: The application ending is one play-along, outside the focus time
    When "alice" composes a 20-minute session with "guitar" in hand
    Then exactly one item has the reason application
    And the focus time is the 20 minutes less the warm-up and that play-along's estimated time

  Scenario: With no play-along on a focus skill, the ending applies another skill of the path
    Given no skill of the session's focus items has a play-along on guitar
    And "alice"'s path skill "chord-tones" has the play-along "chord-tone-riff" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the last item is "chord-tone-riff" with the reason application

  Scenario: With no play-along on the instrument at all, the session has no ending and keeps the time for focus
    Given none of "alice"'s path skills has a play-along on "electric-bass"
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then no item in the session has the reason application
    And the focus time is the 10 minutes less the warm-up

  Scenario: Authored exercises on the student's path are focus items
    Given "alice"'s path skill "chord-tones" has the exercise "name-the-third" for every instrument
    And "alice" has never answered "name-the-third"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes "name-the-third" with the reason new

  Scenario: A session under 10 minutes has no application ending
    When "alice" composes a 9-minute session with "guitar" in hand
    Then no item in the session has the reason application

  # ── Weak items and leftover time ───────────────────────────────────────────

  Scenario: An item practised, not due and not yet fluent is weak
    Given "alice" is accurate but not fluent on "pentatonic-run", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the session includes "pentatonic-run" with the reason weak

  Scenario: A fluent item that isn't due is never weak
    Given "alice" is fluent on "c-major-scale", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then "c-major-scale" is not in the session with the reason weak

  Scenario: Due items take over the time weak items don't use
    Given "alice" has plenty of due items, no weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 85% of the focus time goes to due items and 15% to new items

  Scenario: Weak items take over the time due items don't use
    Given "alice" has no due items, plenty of weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 85% of the focus time goes to weak items and 15% to new items

  Scenario: Time left after due, weak and new goes to review ahead and stretch
    Given "alice" has 4 minutes of due items, nothing weak and 1 minute of new items on guitar, well under their shares of the focus time
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the focus time left after the due and new items is split about evenly between review_ahead and stretch items

  # ── Instruments ────────────────────────────────────────────────────────────

  Scenario: With an instrument in hand, only items that suit it are picked
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then every item in the session suits "electric-bass" or every instrument

  Scenario: With an instrument in hand, fretboard cells of its layout can be picked
    Given "alice" has nothing due or weak on guitar and new fretboard cells on the E and A strings
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes fretboard cells of the "guitar" layout

  Scenario: A session in the head picks only items that need no instrument in hand
    When "alice" composes a 5-minute session with no instrument in hand
    Then no item in the session is a play-along
    And the session may include fretboard cells of both "guitar" and "electric-bass"

  Scenario: A session in the head has no warm-up and no application ending
    When "alice" composes a 15-minute session with no instrument in hand
    Then no item in the session has the reason warm_up or application

  Scenario: A fretboard cell is asked the way it has fewer right answers
    Given "alice" has named the note of the "guitar" cell on string 6, fret 3 correctly 4 times and found it correctly once
    When the cell is picked for "alice"'s session in the head
    Then it is asked as find_the_note

  Scenario: A fretboard cell never answered right is asked to name its note
    Given "alice" has never answered the "guitar" cell on string 5, fret 7 correctly
    When the cell is picked for "alice"'s session in the head
    Then it is asked as name_the_note

  Scenario: A fretboard cell takes about 8 seconds of the session
    When "alice" composes a 5-minute session with no instrument in hand
    Then every fretboard cell in the session is estimated at 8 seconds

  @web
  Scenario: In a session mixing layouts, each fretboard question names its instrument
    Given "alice"'s session in the head has cells of both "guitar" and "electric-bass"
    When a fretboard cell is shown
    Then the question names the instrument whose fretboard the cell is on

  Scenario: New items are balanced across the student's instruments
    Given "alice" has 40 new items on guitar and 40 new items on electric bass
    When "alice" composes a 10-minute session with no instrument in hand
    Then the new items in the session are split evenly between guitar and electric bass

  # ── Felt questions ─────────────────────────────────────────────────────────
  # How a drill felt calibrates its fluent time, so the plan asks about the timed drills with the
  # fewest felt-rated sessions so far, across all students, two at most, fewest first.

  @wip
  Scenario: The plan's felt questions go to its least-calibrated timed drills, two at most
    Given "alice"'s next session will practise "fretboard_cell:name_the_note", "fretboard_cell:find_the_note" and "exercise:text_response"
    And "fretboard_cell:find_the_note" and "exercise:text_response" have the fewest felt-rated sessions
    When "alice" composes a 10-minute session with no instrument in hand
    Then the plan asks how "fretboard_cell:find_the_note" and "exercise:text_response" felt
    And the plan doesn't ask about "fretboard_cell:name_the_note"

  @wip
  Scenario: Play-alongs are never asked how they felt
    Given "alice"'s next session will practise only play-alongs
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the plan asks no felt questions

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The new share is a ceiling, never filled past it
    Given "alice" has 2 due items and 200 new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no more than 3 minutes go to new items

  Scenario: A caught-up student reviews ahead and stretches, half and half
    Given "alice" has nothing due, weak or new on their path for guitar
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 10-minute session with "guitar" in hand
    Then about half the session is items with the reason review_ahead
    And about half the session is items of "notes-on-high-strings" with the reason stretch

  Scenario: When nothing is coming due, stretch takes the whole session
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item after the warm-up has the reason stretch

  Scenario: Stretch starts first with nodes that build on what the student has met
    Given "alice" is ready to start "notes-on-high-strings", which requires a skill they have met
    And "alice" is ready to start the concept "chord-tones", which requires nothing and a skill on their path applies
    When "alice" composes a caught-up 10-minute session with "guitar" in hand
    Then the stretch items are of "notes-on-high-strings" before "chord-tones"

  Scenario: Stretch reaches a node that a path skill is part of
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "lead-guitar", which requires nothing and a skill on their path is part of
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session has items of "lead-guitar" with the reason stretch

  Scenario: Stretch never reaches a node unconnected to what the student is learning
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    And "alice" is ready to start the skill "slide-technique", which requires nothing and has no link to their path
    When "alice" composes a 10-minute session with "guitar" in hand
    Then no item in the session is of "slide-technique"

  Scenario: A short session skips the warm-up
    When "alice" composes a 3-minute session with "guitar" in hand
    Then no item in the session has the reason warm_up

  @wip
  Scenario: A play-along starts on the student's tempo ladder
    Given "alice"'s best clean tempo on "pentatonic-run" is 90 BPM and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 90 BPM with a target of 120 BPM

  @wip
  Scenario: A play-along with no clean take yet starts at 60% of the default playback's tempo
    Given "alice" has never rated "pentatonic-run" clean and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a new item
    Then it starts at 70 BPM with a target of 120 BPM

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A session in the head always has an item for a student learning the fretboard
    Given "alice" has no practice history and their path has the skill "find-notes-root-strings"
    When "alice" composes a 5-minute session with no instrument in hand
    Then the session has at least one fretboard cell with the reason new

  Scenario: A student with nothing connected to what they're learning gets no session
    Given student "bob" is enrolled in nothing and has no practice history
    When "bob" composes a 5-minute session with no instrument in hand
    Then the request is refused with a not-found error

  Scenario: A session longer than an hour is refused
    When "alice" composes a 61-minute session with "guitar" in hand
    Then the request is rejected as invalid
    And the rejection identifies "minutes" as the source of the error

  Scenario: A session for an instrument that doesn't exist is refused
    When "alice" composes a 10-minute session with an instrument that doesn't exist in hand
    Then the request is refused with a not-found error
