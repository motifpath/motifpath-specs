# Song charts in lesson content (MOT-45, Phase 3; ADR-050 §4, as amended).
#
# A songChart node embeds a published song chart in an article's body or in rich_text expanded
# content. It always shows the chart's latest published revision. How a learner sees it, a card
# that opens the reader, is client behaviour in features/web/song-chart-embeds.feature.

@wip
Feature: Embed song charts in lesson content
  As a teacher
  I want to find published song charts and embed them in my lessons
  So that my students can play the songs a lesson is about

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the chord catalog has the chords "G" and "C", each with an active voicing
    And the song chart "Asa Branca" is published at revision 1
    And "Ciranda" is a song chart that has never been published
    And the song chart "Oh! Susanna" was published at revision 1 and then withdrawn
    And "bob" is authenticated as a teacher

  # ── Finding charts ───────────────────────────────────────────────────────────

  Scenario: A teacher finds the published charts
    When "bob" lists the published song charts
    Then the list holds "Asa Branca" only, at revision 1

  Scenario: A teacher searches the published charts by title or artist
    When "bob" searches the published song charts for "gonzaga"
    Then the list holds "Asa Branca" only, at revision 1

  Scenario: A student can't list the published charts
    Given "alice" is authenticated as a student
    When "alice" lists the published song charts
    Then the request is refused because students can't browse content to embed

  # ── Embedding ────────────────────────────────────────────────────────────────

  Scenario: A published chart is embedded in an article's body
    When "bob" creates an article whose body embeds the song chart "Asa Branca"
    Then the article is saved with the song chart "Asa Branca" in its body

  Scenario: A published chart is embedded in rich expanded content
    Given "bob" has a video content node "Forró rhythm"
    When "bob" adds rich expanded content to "Forró rhythm" that embeds the song chart "Asa Branca"
    Then the expanded content is saved with the song chart "Asa Branca"

  Scenario: A chart that was never published can't be embedded
    When "bob" creates an article whose body embeds the song chart "Ciranda"
    Then the content is refused as invalid
    And the rejection identifies the song chart node's songChartId as the source of the error

  Scenario: A chart that doesn't exist can't be embedded
    When "bob" creates an article whose body embeds a song chart that doesn't exist
    Then the content is refused as invalid
    And the rejection identifies the song chart node's songChartId as the source of the error

  Scenario: A song chart can't be embedded in an exercise prompt
    When "bob" creates an exercise whose prompt embeds the song chart "Asa Branca"
    Then the exercise is refused as invalid

  Scenario: Content that embeds a chart withdrawn since can still be saved
    Given "bob" has an article "Forró songs" whose body embeds the song chart "Asa Branca"
    And the song chart "Asa Branca" has been withdrawn
    When "bob" changes the title of "Forró songs" to "Forró classics"
    Then the article is saved with the song chart "Asa Branca" still in its body
