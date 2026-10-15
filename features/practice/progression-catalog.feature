Feature: List the progression catalog
  As a student
  I want the app to know the common progressions by number
  So that a chart I pick for a progression is graded on the spot exactly as the record grades it

  # The catalog is reference data (catalogs/progressions.yaml), the same for every user and
  # language. The app reads it to grade the progression drills' questions instantly.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A student lists every progression of the catalog with its numerals
    When "alice" lists the progression catalog
    Then it lists 10 progressions, in catalog order
    And "I-V-vi-IV" has the bars I, V, vi and IV and the name "I–V–vi–IV (pop)"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: A 12-bar form lists its twelve bars of dominant sevenths
    When "alice" lists the progression catalog
    Then "12-bar-blues" has 12 bars, starting I7, I7, I7, I7, IV7
    And its name is "12-bar blues, slow change"

  @wip
  Scenario: Confusable progressions list each other
    When "alice" lists the progression catalog
    Then "I-V-vi-IV" lists "I-vi-IV-V" and "vi-IV-I-V" as confusable
    And "vi-IV-I-V" lists "I-V-vi-IV" as confusable

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: Listing the progression catalog without signing in is refused
    When someone who is not signed in lists the progression catalog
    Then the request is refused as unauthenticated
