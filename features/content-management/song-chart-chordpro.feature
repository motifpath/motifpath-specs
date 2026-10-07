# ChordPro import and export of a song chart's draft (ADR-050 §3).
#
# ChordPro is an exchange format: a chart stores the document an import produces, never the text.
# How text becomes a document, and a document text, is pinned by the shared golden cases in
# golden/chordpro/, which core runs; these scenarios cover what the operations do with a chart.

Feature: Import and export a song chart as ChordPro
  As an admin of the concierge team
  I want to bring a chart in from ChordPro and take it out again
  So that I can start from charts written elsewhere and share ours with other tools

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the chord catalog has the chords "G" and "C", each with an active voicing
    And "ana" is authenticated as an admin
    And "ana" has a song chart "Draft" in "pt_BR" with a capo on fret 3

  Scenario: Importing ChordPro replaces the draft's body and the metadata it sets
    When "ana" imports into "Draft" the ChordPro:
      """
      {title: Asa Branca}
      {artist: Luiz Gonzaga}
      {start_of_verse}
      [G]Quando olhei a [C]terra ardendo
      {end_of_verse}
      """
    Then the draft is titled "Asa Branca" by "Luiz Gonzaga"
    And the draft has one verse with the line "Quando olhei a terra ardendo"
    And the import reported no warnings

  Scenario: Metadata the text doesn't set keeps its draft value
    When "ana" imports into "Draft" ChordPro that has no capo directive
    Then the draft still has a capo on fret 3
    And the draft's language is still "pt_BR"

  Scenario: Imported chord symbols are resolved against the catalog
    When "ana" imports into "Draft" a line "[G]Quando olhei a [C]terra ardendo"
    Then the anchors resolve to the catalog chords "G" and "C"

  Scenario: What the import skips is reported with its line
    When "ana" imports into "Draft" ChordPro whose line 2 is "{define: G base-fret 1 frets 3 2 0 0 0 3}"
    Then the import reported the warning "unsupported_directive" on line 2

  Scenario: ChordPro with no lyric line is refused
    When "ana" imports into "Draft" ChordPro that has only directives
    Then the import is refused as invalid
    And the draft is unchanged

  Scenario: Importing doesn't change the draft's rights confirmation
    Given the rights of "Draft" are confirmed by "ana"
    When "ana" imports into "Draft" a line "[G]La la"
    Then the draft's rights are still confirmed by "ana"

  Scenario: An admin exports the draft as ChordPro
    Given the draft of "Draft" is titled "Asa Branca" by "Luiz Gonzaga", with one verse "[G]Quando olhei a [C]terra ardendo"
    When "ana" exports "Draft" as ChordPro
    Then the ChordPro is:
      """
      {title: Asa Branca}
      {artist: Luiz Gonzaga}
      {capo: 3}

      {start_of_verse}
      [G]Quando olhei a [C]terra ardendo
      {end_of_verse}
      """

  Scenario: A teacher can't import or export ChordPro
    Given "bob" is authenticated as a teacher
    When "bob" exports "Draft" as ChordPro
    Then the request is refused because only admins author song charts
