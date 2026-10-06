Feature: Roll item knowledge up into knowledge-node levels and readiness
  As a student
  I want to see how well I know each skill on each of my instruments
  So that I know where I stand and what I'm ready to start

  # A node's level for an instrument is the highest level that at least 80% of the items in
  # its subtree reach, counting items that suit that instrument plus items for every
  # instrument. Unseen items count as new.

  Background:
    Given the skill "notes-on-low-strings" whose items are the 26 guitar fretboard cells on strings 6 and 5, frets 0 to 12
    And the instruments "guitar" and "electric-guitar" share the guitar fretboard layout
    And the instrument "electric-bass" with its own fretboard layout

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A node is at the level that 80% of its items reach
    Given "alice" is fluent on 21 of the 26 cells and accurate on the other 5
    Then "alice"'s level for "notes-on-low-strings" on guitar is "fluent"

  Scenario: A node falls to the next level when fewer than 80% reach the higher one
    Given "alice" is fluent on 20 of the 26 cells and accurate on the other 6
    Then "alice"'s level for "notes-on-low-strings" on guitar is "accurate"

  Scenario: A requirement is met once its target reaches the required level
    Given the skill "notes-on-all-strings" requires "notes-on-low-strings" at level "accurate"
    And "alice" is accurate on all 26 cells
    Then "alice"'s readiness for "notes-on-all-strings" on guitar is 1 of 1 requirements met

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Unseen items count as new
    Given "alice" is fluent on 10 of the 26 cells and has never practised the rest
    Then "alice"'s level for "notes-on-low-strings" on guitar is "new"

  Scenario: Instruments that share a fretboard layout share their cells
    Given "alice" is accurate on all 26 cells, practised on "guitar"
    Then "alice"'s level for "notes-on-low-strings" on "electric-guitar" is "accurate"

  Scenario: Levels are kept apart for instruments with different layouts
    Given the skill "notes-on-low-strings" also has bass fretboard cells on strings 4 and 3
    And "alice" is fluent on every guitar cell and has never practised a bass cell
    Then "alice"'s level for "notes-on-low-strings" on guitar is "fluent"
    And "alice"'s level for "notes-on-low-strings" on "electric-bass" is "new"

  Scenario: Items for every instrument count toward every instrument's level
    Given the concept "intervals" has 5 exercises for every instrument
    And "alice" is accurate on all 5
    Then "alice"'s level for "intervals" on guitar is "accurate"
    And "alice"'s level for "intervals" on "electric-bass" is "accurate"

  Scenario: A wide node shows coverage and its children, not a level of its own
    Given the skill "fretboard-knowledge" has the children "notes-on-low-strings" and "notes-on-high-strings"
    And the skill "notes-on-high-strings" whose items are the 26 guitar fretboard cells on strings 2 and 1, frets 0 to 12
    And "alice" is accurate on all 26 cells of "notes-on-low-strings"
    Then "alice"'s "fretboard-knowledge" on guitar shows 26 of 52 items met and the levels of its 2 children
    And "alice"'s "fretboard-knowledge" on guitar shows no level of its own

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A node with nothing to practise has no level
    Given the skill "music-reading" has no practice items
    Then "alice" has no level for "music-reading" on guitar

  Scenario: A requirement on a node with nothing to practise is never met
    Given the skill "sight-reading" requires "music-reading" at level "accurate"
    And the skill "music-reading" has no practice items
    Then "alice"'s readiness for "sight-reading" on guitar is 0 of 1 requirements met

  Scenario: An unmet requirement never keeps a skill on the student's path out of practice
    Given the skill "notes-on-all-strings" requires "notes-on-low-strings" at level "accurate"
    And "notes-on-all-strings" is a skill on "alice"'s path
    And "alice" has never practised "notes-on-low-strings"
    When "alice" composes a 10-minute session with guitar in hand
    Then the session includes items of "notes-on-all-strings"
