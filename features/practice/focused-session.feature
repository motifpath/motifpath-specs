Feature: Practise a subject the student chooses
  As a student
  I want to choose what to practise and get a session made only of it
  So that I can work on my own goal, like progressions, and know what I worked on

  # Rules (ADR-057, MOT-77 D22–D25): a subject is one knowledge node. Any node with practice
  # material for the session (an instrument in hand, or in the head) can be chosen, on the
  # student's paths or not; requirements never gate it. A chosen session holds only items of the
  # node and its part_of subtree: its due items, then weak, then new, at the usual shares, then
  # review ahead and more new items of the subtree, never anything else. It has no warm-up, and an
  # application ending only with a play-along in the subtree. New items come from the subject's
  # current rung and the next one. Evidence counts like in any other session: an answer never
  # says how its session was chosen, so knowledge-state.feature covers it for every session.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And the skill "common-progressions" has items on guitar, and its part_of child "blues-form" has items too

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A chosen session holds only items of the chosen node and its subtree
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "common-progressions"
    Then every item in the session practises "common-progressions" or "blues-form"

  Scenario: A chosen session names its subject and says it was chosen
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "common-progressions"
    Then the plan's only focus node is "common-progressions"
    And the plan says its focus was chosen by the student

  Scenario: The chosen node's due items come first
    Given "alice" has due, weak and new items on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then about 60% of the focus time goes to due items, 25% to weak items and 15% to new items

  Scenario: Due items of other nodes are not in a chosen session
    Given "alice" has due items on "chord-tones" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "common-progressions"
    Then no item in the session practises "chord-tones"

  Scenario: A chosen session has no warm-up
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "common-progressions"
    Then no item in the session has the reason warm_up

  Scenario: A chosen session ends with a play-along of its subject
    Given "common-progressions" has the play-along "pop-progression" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is "pop-progression" with the reason application

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A node off the student's paths can be chosen
    Given none of "alice"'s paths includes "hear-progressions", which has items in the head
    When "alice" composes a 10-minute session with no instrument in hand, choosing "hear-progressions"
    Then every item in the session practises "hear-progressions"

  Scenario: A node whose requirements aren't met can be chosen
    Given "chord-function" requires "diatonic-chords" at level "accurate", and "alice" is new on "diatonic-chords"
    When "alice" composes a 10-minute session with no instrument in hand, choosing "chord-function"
    Then every item in the session practises "chord-function"

  Scenario: A chosen session with no play-along in its subject has no application ending
    Given no item of "hear-progressions" or its subtree is a play-along on guitar
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "hear-progressions"
    Then no item in the session has the reason application

  Scenario: When its subject runs out, a chosen session ends early rather than leave it
    Given "find-notes-root-strings" has 24 cells on guitar, all fluent for "alice" and none due within the week
    When "alice" composes a 30-minute session with no instrument in hand, choosing "find-notes-root-strings"
    Then every item in the session practises "find-notes-root-strings"
    And the session's items take less than 30 minutes

  Scenario: Time left in a chosen session goes to reviewing the subject ahead, then to more of its new items
    Given "alice" has 1 minute of due items, nothing weak and 20 new items on "common-progressions" on guitar
    And "alice" has known items of "common-progressions" coming due within the week
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the session has items of "common-progressions" with the reason review_ahead
    And more than 3 minutes go to new items of "common-progressions"

  # ── Subjects to choose from ────────────────────────────────────────────────

  Scenario: The subjects list offers every node with material for the instrument, grouped by area
    When "alice" lists the subjects they can practise with "guitar" in hand
    Then "common-progressions" is listed in the area "harmony"
    And every listed node has at least one item that suits "guitar" and can be played in hand

  Scenario: A subject shows the student's level and current rung
    Given "alice" is accurate on every know item of "diatonic-chords" on guitar
    When "alice" lists the subjects they can practise with "guitar" in hand
    Then "diatonic-chords" shows "alice"'s level on guitar and the current rung hear

  Scenario: The subjects list in the head offers only nodes with recall material
    Given "play-open-chords" has only self-rated chord items, played in hand
    And "find-notes-root-strings" is practised only by fretboard cells, recalled in the head
    When "alice" lists the subjects they can practise with no instrument in hand
    Then "play-open-chords" is not listed
    And "find-notes-root-strings" is listed

  @web
  Scenario: Choosing what to practise is always offered
    Given "alice"'s Today's mix can be composed
    When the session setup is shown
    Then it offers both "Today's mix" and "I'll choose"

  @web
  Scenario: With nothing to mix, setup leads to choosing what to practise
    Given "alice"'s Today's mix can't be composed, since nothing is recommended
    When the session setup is shown
    Then it offers to choose what to practise instead

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A chosen node with nothing to practise in hand is not found
    Given "find-notes-root-strings" is practised only by fretboard cells, recalled in the head
    When "alice" composes a 10-minute session with "guitar" in hand, choosing "find-notes-root-strings"
    Then the request is refused with a not-found error

  Scenario: A chosen node that doesn't exist is not found
    When "alice" composes a 10-minute session with no instrument in hand, choosing a node that doesn't exist
    Then the request is refused with a not-found error

  @wip
  Scenario: A chosen node that isn't an identifier is rejected
    When "alice" composes a 10-minute session with no instrument in hand, choosing the node "progressions"
    Then the request is rejected as invalid
    And the rejection identifies "focus_node_id" as the source of the error
