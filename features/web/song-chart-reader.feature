# The song chart reader (MOT-45, Phase 2): chords over words, a voicing sheet per chord, and a
# "played it" control per section (ADR-050 §3, §4, as amended on 2026-10-07).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite. What the read returns, and when a chart is available, is in
# features/content-management/song-chart-reader.feature; how the events are stored is in
# features/event-ingestion/ingest-song-chart-event.feature.
#
# Learners reach the reader through the lessons that embed a chart (Phase 3). Admins see the same
# reader as a preview of a draft, which emits no events.

@web
Feature: Read a song chart and look up its chords
  As a learner
  I want to read the lyrics with their chords and tap a chord to see how to play it
  So that I can play the song without leaving MotifPath

  Background:
    Given the song chart "Asa Branca" is published at revision 2 with the line "[G]Quando olhei a [C]terra ardendo" in its first section
    And "alice" is signed in as a student

  # ── Reading ──────────────────────────────────────────────────────────────────

  Scenario: Chords are shown over the words they fall on
    When "alice" opens "Asa Branca"
    Then "G" is shown over "Quando" and "C" over "terra"

  Scenario: Opening a chart sends song_chart.opened
    When "alice" opens "Asa Branca"
    Then song_chart.opened is sent for revision 2 of "Asa Branca"

  Scenario: Chords stay over their words when a long line wraps on a phone
    Given the screen is 430 pixels wide
    And the first section has a line too long to fit on one row
    When "alice" opens "Asa Branca"
    Then every chord is still shown over the word it falls on

  # ── The voicing sheet ────────────────────────────────────────────────────────

  Scenario: Tapping a chord opens its voicing sheet on the author's pick
    Given the author picked the voicing "g-e-shape-3" for "G"
    And "alice" has opened "Asa Branca"
    When "alice" taps "G"
    Then the voicing sheet for "G" opens on "g-e-shape-3"
    And song_chart.chord_viewed is sent for that anchor, chord "G" and voicing "g-e-shape-3"

  Scenario: Without a pick, the sheet opens on the chord's best voicing
    Given "alice" has opened "Asa Branca"
    When "alice" taps "C"
    Then the voicing sheet for "C" opens on its top-ranked voicing

  Scenario: Switching voicings or playbacks in the sheet sends nothing more
    Given "alice" has opened the voicing sheet for "G"
    When "alice" switches to another voicing and then to the arpeggio playback
    Then no further song_chart.chord_viewed is sent

  Scenario: A slash chord the catalog doesn't have shows the chord without its bass
    Given the chart has the anchor written "C/G", resolving to "C"
    And "alice" has opened "Asa Branca"
    When "alice" taps "C/G"
    Then the sheet is titled "C/G" and shows the voicings of "C", noting that the bass G isn't shown

  Scenario: A no-chord marking can't be tapped
    Given the chart has the anchor written "N.C."
    When "alice" opens "Asa Branca"
    Then "N.C." is shown as text with no voicing sheet

  # ── Sections played ──────────────────────────────────────────────────────────

  Scenario: Marking a section as played sends song_chart.section_completed
    Given "alice" has opened "Asa Branca"
    When "alice" marks the first section as played
    Then song_chart.section_completed is sent for section 0 of revision 2
    And the first section shows as played

  Scenario: Marking a section as played again sends nothing more
    Given "alice" has marked the first section of "Asa Branca" as played
    When "alice" marks it as played again
    Then no further song_chart.section_completed is sent

  # ── Not available ────────────────────────────────────────────────────────────

  Scenario: A chart that isn't available shows a neutral message
    Given "Asa Branca" has been withdrawn
    When "alice" opens "Asa Branca"
    Then a "This song isn't available right now" message is shown
    And no event is sent

  # ── Admin preview ────────────────────────────────────────────────────────────

  Scenario: An admin's preview of a draft sends no events
    Given "ana" is signed in as an admin
    When "ana" previews the draft of "Asa Branca" and taps "G"
    Then no song_chart event is sent
