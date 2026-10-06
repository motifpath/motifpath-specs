Feature: Know what a practice session holds while practising it
  As a student
  I want to see what today's session holds, what each item is, and when the next one starts
  So that I always know what I am practising, and a new item never looks like the last one

  # Client behaviour: the plan comes from core; what is shown of it, and when, is the web's.

  Background:
    Given student "alice" plays "guitar"
    And "alice"'s session holds, in order:
      | item                                   | reason          |
      | exercise "Name the interval"           | weak            |
      | play-along "A Major pentatonic — Box 4" | stretch         |
      | play-along "Ab Major pentatonic — Box 1" | stretch        |
      | 3 fretboard cells to name the note     | new             |

  # ── Today's plan ───────────────────────────────────────────────────────────

  @web
  Scenario: Today's plan lists what the session holds before it starts
    When "alice" starts a session
    Then "alice" sees today's plan before the first item
    And it lists "Name the interval", "A Major pentatonic — Box 4", "Ab Major pentatonic — Box 1" and "Name the note · 3 notes", in that order, each with why it was picked

  @web
  Scenario: The session starts from today's plan
    Given "alice" sees today's plan
    When "alice" chooses "Let's go"
    Then practice.session_started is sent
    And the first item is shown

  @web
  Scenario: Leaving from today's plan starts nothing
    Given "alice" sees today's plan
    When "alice" leaves with ×
    Then no practice event is sent

  # ── Item titles ────────────────────────────────────────────────────────────

  @web
  Scenario: A play-along is named by its diagram
    When "alice" reaches the play-along "A Major pentatonic — Box 4"
    Then its title is "A Major pentatonic — Box 4", with why it was picked

  @web
  Scenario: An exercise is named by its title
    When "alice" reaches the exercise "Name the interval"
    Then its title is "Name the interval", with why it was picked

  # ── Next up ────────────────────────────────────────────────────────────────

  @web
  Scenario: A play-along hands over to the next item
    Given "alice" played "A Major pentatonic — Box 4" up to 300 BPM
    When "alice" rates its last take
    Then "alice" sees that she played "A Major pentatonic — Box 4" up to 300 BPM
    And next up is "Ab Major pentatonic — Box 1", with why it was picked
    And the next item starts only when "alice" chooses Continue

  @web
  Scenario: The last item of a session goes straight to its end
    Given "alice"'s last item is a play-along
    When "alice" rates its last take
    Then no Next up card is shown
