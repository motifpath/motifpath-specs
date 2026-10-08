# Song charts and chord voicings embedded in lesson content (MOT-45, Phase 3; ADR-050 §4, as
# amended).
#
# A song chart shows in content as a card, a shared component that can be placed wherever content
# is shown; tapping it opens the reader. Lessons are its first place: a learner meets it in a
# video's cue. A chord voicing is embedded with the existing diagram embed, picked from the chord
# catalog.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks.
# What may be embedded, and where, is in features/content-management/song-chart-embeds.feature.

@web
Feature: Embed song charts and chord voicings in lessons
  As a teacher
  I want to put a song chart, or a chord's voicing, in my lesson
  So that my students can play along from the lesson

  Background:
    Given the song chart "Asa Branca" by "Luiz Gonzaga" in G is published, starting with the line "[G]Quando olhei a [C]terra ardendo"
    And the chord catalog has "G" with its voicings "Open", "3fr" and "10fr"

  # ── Embedding a song chart ───────────────────────────────────────────────────

  Rule: A teacher picks a published chart and it shows as a card

    Scenario: A teacher inserts a song chart from the editor
      Given "bob" is editing the body of an article
      When "bob" chooses "Song chart", searches for "asa" and picks "Asa Branca"
      Then the body shows the card of "Asa Branca"

    Scenario: The picker lists only published charts
      Given "bob" is editing the body of an article
      When "bob" chooses "Song chart"
      Then the picker lists the published charts by title and artist, and no draft

    Scenario: The card shows the song and how it starts
      Given a lesson's content embeds "Asa Branca"
      Then its card shows "Asa Branca", "Luiz Gonzaga", the key G, and "Quando olhei a terra ardendo" with "G" and "C" over it

    Scenario: The exercise prompt editor doesn't offer song charts
      Given "bob" is editing an exercise prompt
      Then the editor doesn't offer "Song chart"

  # ── A learner in a video lesson ──────────────────────────────────────────────

  Rule: In a video lesson, the card opens the reader and returns to the same moment

    Scenario: The card shows in the video's cue
      Given the video lesson "Forró rhythm" has a cue at 0:30 that embeds "Asa Branca"
      When "alice" watches "Forró rhythm" to 0:30
      Then the cue shows the card of "Asa Branca"

    Scenario: Tapping the card pauses the video and opens the reader
      Given the cue of "Forró rhythm" shows the card of "Asa Branca"
      When "alice" taps the card
      Then the video pauses
      And "Asa Branca" opens in the reader, which sends song_chart.opened

    Scenario: Closing the reader returns to the lesson at the same moment
      Given "alice" opened "Asa Branca" from the cue of "Forró rhythm" at 0:31
      When "alice" closes the reader
      Then "alice" is back on "Forró rhythm", paused at 0:31

    Scenario: Showing the card sends nothing
      When "alice" watches "Forró rhythm" to 0:30
      Then no song_chart event is sent

    Scenario: A chart withdrawn since it was embedded shows nothing
      Given the song chart "Asa Branca" has been withdrawn
      When "alice" watches "Forró rhythm" to 0:30
      Then the cue shows no card for "Asa Branca"

  # ── Embedding a chord voicing ────────────────────────────────────────────────

  Rule: A chord voicing is picked from the catalog and embedded as a diagram

    Scenario: A teacher embeds a voicing of a chord
      Given "bob" is editing the body of an article
      When "bob" chooses "Diagram", then "Chords", searches for "G" and picks the voicing "3fr"
      Then the body embeds the diagram of the "G" voicing "3fr"

    Scenario: The voicings are shown as chord boxes to pick from
      Given "bob" is choosing a chord in the diagram picker
      When "bob" searches for "G"
      Then the voicings "Open", "3fr" and "10fr" are shown as chord boxes

    Scenario: A symbol that isn't a chord says so
      Given "bob" is choosing a chord in the diagram picker
      When "bob" searches for "H7"
      Then the picker says "H7" isn't a chord

    Scenario: A chord the catalog doesn't have says so
      Given "bob" is choosing a chord in the diagram picker
      When "bob" searches for "C#7"
      Then the picker says the chord catalog doesn't have "C#7"

    Scenario: A learner sees the embedded voicing like any embedded diagram
      Given a lesson's content embeds the diagram of the "G" voicing "3fr"
      Then the learner sees that voicing's diagram, with Play
