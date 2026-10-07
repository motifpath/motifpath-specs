# Reading a published song chart (ADR-050 §3, §5).
#
# A learner reads a chart's latest published revision with every chord it uses and that chord's
# voicings, in one response. Whether a chart can be read is checked on every read, from its status
# and its rights record as they stand then. A chart that can't be read answers exactly like one
# that doesn't exist; admins see why in the chart's availability. Learners reach charts through
# the lessons that embed them (Phase 3); this feature covers the read itself.

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
    And its rights record "asa-branca-rights" is approved and covers "pt_BR"
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
    Then the chart "alice" gets holds no rights record, evidence, submitter or reviewer

  # ── Availability, checked on every read ──────────────────────────────────────

  Scenario: A withdrawn chart can't be read
    Given "Asa Branca" has been withdrawn
    When "alice" reads the song chart "Asa Branca"
    Then the chart is not found

  Scenario: A chart whose rights record was changed and awaits review can't be read
    Given the rights record "asa-branca-rights" has been changed and is pending review
    When "alice" reads the song chart "Asa Branca"
    Then the chart is not found

  Scenario: An admin sees why a chart can't be read
    Given the rights record "asa-branca-rights" has been changed and is pending review
    And "ana" is authenticated as an admin
    When "ana" gets the song chart "Asa Branca"
    Then its availability is unavailable, because "rights_record_not_approved"

  Scenario: A chart is readable again once its changed rights record is approved
    Given the rights record "asa-branca-rights" was changed and then approved by a second admin
    When "alice" reads the song chart "Asa Branca"
    Then "alice" gets revision 1 of "Asa Branca"

  Scenario: A chart that was never published can't be read
    Given the song chart "Carinhoso" has never been published
    When "alice" reads the song chart "Carinhoso"
    Then the chart is not found

  Scenario: Reading a chart without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request reads the song chart "Asa Branca"
    Then the request is refused with an authentication error
