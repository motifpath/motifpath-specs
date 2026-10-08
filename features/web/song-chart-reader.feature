# The song chart reader (MOT-45): chords over words, a voicing card per chord, and "I played it"
# for the whole song (ADR-050 §3, §4, as amended).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite. What the read returns, and when a chart is available, is in
# features/content-management/song-charts.feature; how the events are stored is in
# features/event-ingestion/ingest-song-chart-event.feature.
#
# Until the lesson atom (Phase 3), a learner opens a published chart on its own page, from a link.
# Admins see the same reader as a preview of a draft, which emits no events.

@web
Feature: Read a song chart and look up its chords
  As a learner
  I want to read the lyrics with their chords and tap a chord to see how to play it
  So that I can play the song without leaving MotifPath

  Background:
    Given the song chart "Asa Branca" is published at revision 2 with the line "[G]Quando olhei a [C]terra ardendo" in its first section, a verse labelled "Verse 1"
    And "alice" is signed in as a student

  # ── Opening and leaving ──────────────────────────────────────────────────────

  Rule: A published chart opens on its own page, from a link

    Scenario: A student opens a published chart
      When "alice" opens the link to "Asa Branca"
      Then the chart "Asa Branca" is shown, with a close control and no navigation around it

    Scenario: Opening a chart sends song_chart.opened
      When "alice" opens the link to "Asa Branca"
      Then song_chart.opened is sent for revision 2 of "Asa Branca"

    Scenario: Closing the chart returns to where the student came from
      Given "alice" opened the link to "Asa Branca" from their practice home
      When "alice" closes the chart
      Then "alice" is back on their practice home

    Scenario: Closing a chart opened directly goes home
      Given "alice" opened the link to "Asa Branca" in a new tab
      When "alice" closes the chart
      Then "alice" is on their home

    Scenario Outline: A chart that can't be read says it isn't available
      Given the song chart "Asa Branca" <state>
      When "alice" opens the link to "Asa Branca"
      Then the page says the song chart isn't available, without saying why
      And nothing is sent

      Examples:
        | state                    |
        | has been withdrawn       |
        | has never been published |
        | doesn't exist            |

  # ── Reading ──────────────────────────────────────────────────────────────────

  Rule: Chords sit over the words they fall on, in labelled sections

    Scenario: Chords are shown over the words they fall on
      When "alice" opens the link to "Asa Branca"
      Then "G" is shown over "Quando" and "C" over "terra"
      And the section is headed "VERSE 1"

    Scenario: A section without a label is headed by its kind
      Given the second section of "Asa Branca" is a chorus without a label
      When "alice" opens the link to "Asa Branca"
      Then the second section is headed "CHORUS"

    Scenario: Chords stay over their words when a long line wraps on a phone
      Given the screen is 430 pixels wide
      And the first section has a line too long to fit on one row
      When "alice" opens the link to "Asa Branca"
      Then every chord is still shown over the word it falls on

  # ── The voicing card ─────────────────────────────────────────────────────────

  Rule: Tapping a chord opens its voicing card over the chart

    Scenario: Tapping a chord opens its card on the author's pick and sends song_chart.chord_viewed
      Given the author picked the voicing "g-e-shape-3" for "G"
      And "alice" has opened "Asa Branca"
      When "alice" taps "G"
      Then the chord "G" is highlighted in the lyrics
      And a card for "G" opens over the chart on "g-e-shape-3"
      And song_chart.chord_viewed is sent for that anchor, chord "G" and voicing "g-e-shape-3"

    Scenario: Without a pick, the card opens on the chord's best voicing
      Given "alice" has opened "Asa Branca"
      When "alice" taps "C"
      Then the card for "C" opens on its top-ranked voicing

    Scenario: The card shows the voicing as a chord box
      Given "alice" has opened the card for "G" on its open voicing
      Then the card shows a chord box with each finger's number on its dot
      And an open string is marked "o" above the box and a muted string "x"

    Scenario: A voicing up the neck shows the fret it starts on
      Given "alice" has opened the card for "G" on the voicing that starts at the 3rd fret
      Then the chord box is labelled "3fr"

    Scenario: The card switches to the voicing on the neck
      Given "alice" has opened the card for "G"
      When "alice" chooses "Neck"
      Then the voicing is shown on the guitar neck

    Scenario: The voicings are named by where they sit on the neck
      Given "G" has voicings starting open, at the 3rd fret and at the 10th fret
      When "alice" taps "G"
      Then the card offers the voicings "Open", "3fr" and "10fr"

    Scenario: The card plays the voicing
      Given "alice" has opened the card for "G", whose voicing's default playback is "Strum"
      When "alice" plays it
      Then the voicing sounds as a strum

    Scenario: Switching voicings, views or playing sends nothing more
      Given "alice" has opened the card for "G"
      When "alice" switches to "3fr", chooses "Neck" and plays it
      Then no further song_chart.chord_viewed is sent

    Scenario: Tapping another chord moves the card to it
      Given "alice" has opened the card for "G"
      When "alice" taps "C"
      Then the card shows "C" and "C" is highlighted
      And song_chart.chord_viewed is sent for "C"

    Scenario: The card can be folded down and closed
      Given "alice" has opened the card for "G"
      When "alice" folds the card
      Then only the card's title "G" stays over the chart
      When "alice" closes the card
      Then no chord is highlighted

    Scenario: A slash chord the catalog doesn't have shows the chord without its bass
      Given the chart has the anchor written "C/B", resolving to "C"
      And "alice" has opened "Asa Branca"
      When "alice" taps "C/B"
      Then the card is titled "C/B" and shows the voicings of "C", noting that the bass B isn't shown

    Scenario: A no-chord marking can't be tapped
      Given the chart has the anchor written "N.C."
      When "alice" opens the link to "Asa Branca"
      Then "N.C." is shown as text with no card

  # ── I played it ──────────────────────────────────────────────────────────────

  Rule: "I played it" marks the whole song as played, once per opening

    Scenario: Marking the song as played sends song_chart.completed
      Given "alice" has opened "Asa Branca"
      When "alice" taps "I played it"
      Then song_chart.completed is sent for revision 2 of "Asa Branca"
      And the song shows as played

    Scenario: Marking it again sends nothing more
      Given "alice" has marked "Asa Branca" as played
      When "alice" taps "I played it" again
      Then no further song_chart.completed is sent

  # ── The admin preview ────────────────────────────────────────────────────────

  Rule: An admin's preview of a draft is the same reader, and sends nothing

    Scenario: The preview sends no events
      Given "ana" is signed in as an admin
      When "ana" previews the draft of "Asa Branca", taps "G" and taps "I played it"
      Then nothing is sent
