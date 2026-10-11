# The song chart reader (MOT-45, redesigned in MOT-73 / MOT-96): chords over words, the song's
# chords in a strip, a chord card per chord, a metronome to practise at, and "I played it" for the
# whole song (ADR-050 §3, §4, as amended; design/patterns/song-chart.md and chord-card.md).
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite. What the read returns, and when a chart is available, is in
# features/content-management/song-charts.feature; how the events are stored is in
# features/event-ingestion/ingest-song-chart-event.feature.
#
# A learner opens a published chart from a link or from a song chart card in a lesson
# (song-chart-embeds.feature). Admins see the same reader as a preview of a draft, which sends
# nothing. Sizes follow ADR-049: Compact and Medium float the chord card over the chart; Expanded
# docks it in a side pane.

@web
Feature: Read a song chart and look up its chords
  As a learner
  I want to read the lyrics with their chords, tap a chord to see how to play it, and practise at my own tempo
  So that I can play the song without leaving MotifPath

  Background:
    Given the song chart "Amazing Grace" by "John Newton" is published at revision 2 in the key of G, with no capo, in 3/4 at 72 BPM
    And its first section is a verse labelled "Verse 1" with the line "[G]Amazing [C]grace, how [G]sweet the sound"
    And the chart uses the chords "G", "C" and "D"
    And "alice" is signed in as a student

  # ── Opening and leaving ──────────────────────────────────────────────────────

  Rule: A chart opens as a full-screen layer with only a close control

    Scenario: A student opens a published chart
      When "alice" opens the link to "Amazing Grace"
      Then the chart "Amazing Grace" is shown, with a close control and no navigation around it

    Scenario: The title moves into the bar once the header scrolls away
      Given "alice" has opened "Amazing Grace"
      When "alice" scrolls past the chart's header
      Then the bar shows the title "Amazing Grace" next to the close control

    Scenario: Opening a chart sends song_chart.opened
      When "alice" opens the link to "Amazing Grace"
      Then song_chart.opened is sent for revision 2 of "Amazing Grace"

    Scenario: Closing the chart returns to where the student came from
      Given "alice" opened the link to "Amazing Grace" from their practice home
      When "alice" closes the chart
      Then "alice" is back on their practice home

    Scenario: Closing a chart opened directly goes home
      Given "alice" opened the link to "Amazing Grace" in a new tab
      When "alice" closes the chart
      Then "alice" is on their home

  Rule: Loading, an unavailable chart and a failed load each say what happened

    Scenario: The chart shows its shell while it loads
      Given the chart "Amazing Grace" is still loading
      When "alice" opens the link to "Amazing Grace"
      Then the close control and placeholder lines are shown

    Scenario Outline: A chart that can't be read says it isn't available
      Given the song chart "Amazing Grace" <state>
      When "alice" opens the link to "Amazing Grace"
      Then the page says the song chart isn't available, without saying why
      And it offers "Go home"
      And nothing is sent

      Examples:
        | state                    |
        | has been withdrawn       |
        | has never been published |
        | doesn't exist            |

    Scenario: A chart that fails to load can be tried again
      Given loading "Amazing Grace" fails
      When "alice" opens the link to "Amazing Grace"
      Then the page says the chart couldn't be loaded and offers "Try again"
      When loading succeeds and "alice" chooses "Try again"
      Then the chart "Amazing Grace" is shown

  # ── Reading ──────────────────────────────────────────────────────────────────

  Rule: The header shows the song's details as chips

    Scenario: The header shows the key, capo, meter and tempo
      When "alice" opens the link to "Amazing Grace"
      Then the header shows "Amazing Grace" by "John Newton"
      And the chips "Key G", "No capo", "3/4" and "72 BPM"

    Scenario: A chart without a tempo shows no tempo chip
      Given "Amazing Grace" has no tempo
      When "alice" opens the link to "Amazing Grace"
      Then the header shows no tempo chip

  Rule: Chords sit over the words they fall on, in labelled sections

    Scenario: Chords are shown over the words they fall on
      When "alice" opens the link to "Amazing Grace"
      Then "G" is shown over "Amazing" and "C" over "grace,"
      And the section is headed "VERSE 1"

    Scenario: A section without a label is headed by its kind
      Given the second section of "Amazing Grace" is a chorus without a label
      When "alice" opens the link to "Amazing Grace"
      Then the second section is headed "CHORUS"

    Scenario: Chords stay over their words when a long line wraps on a phone
      Given the screen is 430 pixels wide
      And the first section has a line too long to fit on one row
      When "alice" opens the link to "Amazing Grace"
      Then every chord is still shown over the word it falls on

  # ── The chords in this song ──────────────────────────────────────────────────

  Rule: The chords in this song sit under the header, and open the chord card

    Scenario: The song's chords are shown once each, under the header
      When "alice" opens the link to "Amazing Grace"
      Then "Chords in this song" shows the chord boxes "G", "C" and "D", once each, in the order they first appear

    Scenario: Tapping a chord in the strip opens its card and sends song_chart.chord_viewed from the strip
      Given "alice" has opened "Amazing Grace"
      When "alice" taps "C" in the chords in this song
      Then the chord card for "C" opens
      And no chord is highlighted in the lyrics
      And song_chart.chord_viewed is sent from the strip for chord "C" and the voicing the card opened on, with no anchor

    Scenario: The strip scrolls away with the header
      Given "alice" has opened "Amazing Grace"
      When "alice" scrolls past the chart's header
      Then the chords in this song are no longer shown

  # ── The chord card ───────────────────────────────────────────────────────────

  Rule: Tapping a chord in the lyrics opens its chord card without leaving the chart

    Scenario: Tapping a chord opens its card on the author's pick and sends song_chart.chord_viewed from the lyrics
      Given the author picked the voicing "g-e-shape-3" for "G"
      And "alice" has opened "Amazing Grace"
      When "alice" taps "G" over "Amazing"
      Then that "G" is highlighted in the lyrics
      And the chord card for "G" opens on "g-e-shape-3"
      And song_chart.chord_viewed is sent from the lyrics for that anchor, chord "G" and voicing "g-e-shape-3"

    Scenario: Without a pick, the card opens on the chord's best voicing
      Given "alice" has opened "Amazing Grace"
      When "alice" taps "C"
      Then the card for "C" opens on its top-ranked voicing

    Scenario: The chart keeps scrolling and stays tappable while the card is open
      Given "alice" has opened the card for "G"
      When "alice" scrolls the chart and taps "C"
      Then the chart scrolled
      And the card shows "C"

    Scenario: Tapping another chord moves the card to it
      Given "alice" has opened the card for "G"
      When "alice" taps "C"
      Then the card shows "C" and "C" is highlighted
      And song_chart.chord_viewed is sent from the lyrics for "C"

    Scenario: A slash chord the catalog doesn't have shows the chord without its bass
      Given the chart has the anchor written "C/B", resolving to "C"
      And "alice" has opened "Amazing Grace"
      When "alice" taps "C/B"
      Then the card is titled "C/B" and shows the voicings of "C", noting "Shows C — the bass note B isn't shown"

    Scenario: A no-chord marking can't be tapped
      Given the chart has the anchor written "N.C."
      When "alice" opens the link to "Amazing Grace"
      Then "N.C." is shown as text with no card

  Rule: The card floats over the chart on a phone or tablet, and is docked in a side pane on a wide screen

    Scenario Outline: On a phone or a tablet the card floats over the chart
      Given the screen is <size>
      And "alice" has opened "Amazing Grace"
      When "alice" taps "G"
      Then the chord card floats over the chart
      And the chart's last lines can still scroll above it

      Examples:
        | size                   |
        | Compact, 390 px wide   |
        | Medium, 768 px wide    |

    Scenario: The student drags the floating card to another corner
      Given the screen is Compact
      And "alice" has opened the card for "G"
      When "alice" drags the card to the top-left corner
      Then the card sits in the top-left corner

    Scenario: Scrolling the chart minimises the floating card, and tapping it expands it
      Given the screen is Compact
      And "alice" has opened the card for "G"
      When "alice" scrolls the chart
      Then the card shows only a chip with "G"
      When "alice" taps the chip
      Then the card for "G" is expanded

    Scenario: On a wide screen the card is docked in a side pane
      Given the screen is Expanded, 1280 px wide
      And "alice" has opened "Amazing Grace"
      When "alice" taps "G"
      Then a side pane opens next to the chart with the metronome, the chords in this song and the chord card for "G", top to bottom

    Scenario: Closing the side pane re-centres the chart
      Given the screen is Expanded
      And "alice" has the side pane open
      When "alice" closes the side pane
      Then no chord is highlighted and the chart is centred

    Scenario: The card is closed and nothing stays highlighted
      Given the screen is Compact
      And "alice" has opened the card for "G"
      When "alice" closes the card
      Then no chord card is shown and no chord is highlighted

  Rule: The card shows a voicing as a chord box or on the neck, named by where it sits

    Scenario: The card shows the voicing as a chord box
      Given "alice" has opened the card for "G" on its open voicing
      Then the card shows a chord box with each finger's number on its dot
      And an open string is marked "o" above the box and a muted string "x"

    Scenario: A voicing up the neck shows the fret it starts on
      Given "alice" has opened the card for "G" on the voicing that starts at the 3rd fret
      Then the chord box is labelled "3fr"

    Scenario: A voicing with open strings starts at the nut, however high its fingers sit
      Given "alice" has opened the card for "A" on its open voicing, fingered at the 2nd fret
      Then the chord box starts at the nut and shows frets 1 to 4
      And it is labelled with no fret

    Scenario: A chord box always shows at least four frets
      Given "alice" has opened the card for "G" on the voicing that starts at the 3rd fret
      Then the chord box shows 4 frets, from the 3rd to the 6th

    Scenario: A voicing that spans more than four frets shows them all
      Given "alice" has opened the card for "C" on a voicing with open strings that reaches the 5th fret
      Then the chord box starts at the nut and shows frets 1 to 5

    Scenario: The card switches to the voicing on the neck, at a readable size
      Given the screen is Compact, 390 px wide
      And "alice" has opened the card for "G" on the voicing that starts at the 3rd fret
      When "alice" chooses "Neck"
      Then the neck is drawn across the card's full width at the size lesson diagrams use, scrolled to the voicing's frets
      And an overview strip under it shows which part of the neck is in view

    Scenario: The chosen view is remembered for the next chord
      Given "alice" has chosen "Neck" on the card for "G"
      When "alice" taps "C"
      Then the card for "C" shows the neck

    Scenario: The voicings are named by where they sit on the neck
      Given "G" has voicings starting open, at the 3rd fret and at the 10th fret
      When "alice" taps "G"
      Then the card offers the voicings "Open", "3fr" and "10fr"

    Scenario: The voicing chosen for a chord is remembered in this song
      Given "alice" has switched the card for "G" to "3fr"
      When "alice" taps "C" and then taps "G" again
      Then the card for "G" opens on "3fr"

    Scenario: The card plays the voicing
      Given "alice" has opened the card for "G", whose voicing's default playback is "Strum"
      When "alice" plays it
      Then the voicing sounds as a strum

    Scenario: Switching voicings, views or playing sends nothing more
      Given "alice" has opened the card for "G"
      When "alice" switches to "3fr", chooses "Neck" and plays it
      Then no further song_chart.chord_viewed is sent

  # ── The metronome ────────────────────────────────────────────────────────────

  Rule: The metronome is a practice aid that starts slower than the song and is never tracked

    Scenario: The song's tempo is the target, marked on the tempo control
      Given "alice" has opened "Amazing Grace"
      When "alice" turns the metronome on
      Then the metronome clicks in 3/4 at 72 BPM
      And the tempo control marks 72 BPM as the song's tempo

    Scenario: The student slows the metronome down below the song's tempo
      Given "alice" has the metronome on for "Amazing Grace"
      When "alice" sets the tempo to 56 BPM
      Then the metronome clicks at 56 BPM
      And the tempo control says "Song tempo 72 BPM · you're at 56"

    Scenario: A chart without a tempo starts at 80 BPM with no target
      Given "Amazing Grace" has no tempo
      And "alice" has opened "Amazing Grace"
      When "alice" turns the metronome on
      Then the metronome clicks at 80 BPM
      And the tempo control marks no song tempo

    Scenario: The tempo is remembered per song on this device
      Given "alice" set the tempo of "Amazing Grace" to 56 BPM and closed it
      When "alice" opens "Amazing Grace" again on the same device
      Then the tempo control is at 56 BPM

    Scenario: A remembered tempo for one song doesn't change another
      Given "alice" set the tempo of "Amazing Grace" to 56 BPM
      When "alice" opens "Oh! Susanna", whose tempo is 96 BPM
      Then the tempo control is at 96 BPM

    Scenario: The metronome sends nothing
      Given "alice" has opened "Amazing Grace"
      When "alice" turns the metronome on, changes the tempo and turns it off
      Then nothing is sent

    Scenario Outline: The metronome sits where the student's hands aren't
      Given the screen is <size>
      When "alice" turns the metronome on in "Amazing Grace"
      Then the tempo control is shown <place>

      Examples:
        | size     | place                                       |
        | Compact  | in a bar docked above "I played it"         |
        | Medium   | in a bar at the bottom, under the chart     |
        | Expanded | at the top of the side pane                 |

    Scenario: On a wide screen the metronome is driven from the keyboard
      Given the screen is Expanded
      And "alice" has opened "Amazing Grace"
      When "alice" presses "M"
      Then the metronome is on
      When "alice" presses "-"
      Then the tempo goes down one step
      When "alice" presses "+"
      Then the tempo goes up one step

  # ── I played it ──────────────────────────────────────────────────────────────

  Rule: "I played it" marks the whole song as played, once per opening

    Scenario: Marking the song as played sends song_chart.completed
      Given "alice" has opened "Amazing Grace"
      When "alice" taps "I played it"
      Then song_chart.completed is sent for revision 2 of "Amazing Grace"
      And the button becomes a quiet "Played ✓"
      And a success message confirms the song is marked as played

    Scenario: Marking it again sends nothing more
      Given "alice" has marked "Amazing Grace" as played
      When "alice" taps "Played ✓"
      Then no further song_chart.completed is sent

    Scenario: A new opening starts fresh
      Given "alice" marked "Amazing Grace" as played and closed it
      When "alice" opens "Amazing Grace" again
      Then the button says "I played it"

    Scenario: "I played it" stays at the bottom when the side pane opens
      Given the screen is Expanded
      And "alice" has opened "Amazing Grace"
      When "alice" taps "G"
      Then "I played it" is still at the bottom, aligned to the chart's column

  # ── The admin preview ────────────────────────────────────────────────────────

  Rule: An admin's preview of a draft is the same reader under a banner, and sends nothing

    Scenario: The preview says it is a draft and that nothing is recorded
      Given "ana" is signed in as an admin
      When "ana" previews the draft of "Amazing Grace"
      Then a banner says "Preview of the draft · nothing is recorded"

    Scenario: The preview sends no events
      Given "ana" is signed in as an admin
      When "ana" previews the draft of "Amazing Grace", taps "G", taps "D" in the chords in this song, turns the metronome on and taps "I played it"
      Then nothing is sent

    Scenario: Closing the preview returns to the editor
      Given "ana" is previewing the draft of "Amazing Grace" from its editor
      When "ana" closes the preview
      Then "ana" is back in the editor of "Amazing Grace"
