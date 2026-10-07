# Reading a published song chart (ADR-050 §3, §5).
#
# A learner reads a chart's latest published revision with every chord it uses and that chord's
# voicings, in one response. A chart that was never published, or was withdrawn, answers exactly
# like one that doesn't exist. Learners reach charts through the lessons that embed them
# (Phase 3); this feature covers the read itself.

@wip
Feature: Read a published song chart
  As a learner
  I want to read a song's lyrics with its chords and see how to play each chord
  So that I can play the song without leaving MotifPath to look up fingerings

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the chord catalog has the chord "G" with active voicings ranked:
      | voicing      | rank |
      | g-open       | 1    |
      | g-e-shape-3  | 2    |
    And the chord catalog has the chord "C" with active voicings ranked:
      | voicing      | rank |
      | c-open       | 1    |
    And the song chart "Asa Branca" in "pt_BR" is published at revision 1 with the line "[G]Quando olhei a [C]terra ardendo"
    And "alice" is authenticated as a student

  # ── Reading ──────────────────────────────────────────────────────────────────

  Scenario: A learner reads a published chart with its chords' voicings
    When "alice" reads the song chart "Asa Branca"
    Then "alice" gets revision 1 of "Asa Branca", with the line "Quando olhei a terra ardendo"
    And the chord anchors are written "G" on "Quando olhei a " and "C" on "terra ardendo"
    And the chords included are "G" with voicings "g-open" then "g-e-shape-3", and "C" with voicing "c-open"
    And the diagram of every included voicing is included

  Scenario: A voicing the author picked is included even after it is withdrawn
    Given the anchor written "G" in "Asa Branca" picks the voicing "g-e-shape-3"
    And voicing "g-e-shape-3" has been withdrawn from the chord catalog
    When "alice" reads the song chart "Asa Branca"
    Then the chord "G" is included with voicings "g-open" then "g-e-shape-3"

  Scenario: The learner's chart carries nothing about its rights or its authors
    When "alice" reads the song chart "Asa Branca"
    Then the chart "alice" gets holds no rights confirmation and no author or publisher

  # ── Charts that aren't published ─────────────────────────────────────────────

  Scenario: A withdrawn chart can't be read
    Given "Asa Branca" has been withdrawn
    When "alice" reads the song chart "Asa Branca"
    Then the chart is not found

  Scenario: A withdrawn chart is readable again once it is published again
    Given "Asa Branca" was withdrawn and then published again at revision 2
    When "alice" reads the song chart "Asa Branca"
    Then "alice" gets revision 2 of "Asa Branca"

  Scenario: A chart that was never published can't be read
    Given the song chart "Carinhoso" has never been published
    When "alice" reads the song chart "Carinhoso"
    Then the chart is not found

  Scenario: Reading a chart without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request reads the song chart "Asa Branca"
    Then the request is refused with an authentication error
