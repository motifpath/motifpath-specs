# Song chart reading events (ADR-050 Follow-up 1, as amended on 2026-10-07).
#
# The song chart reader emits song_chart.opened, song_chart.chord_viewed and
# song_chart.completed, so the song-first hypothesis is checked against real use. When the
# reader emits each one is client behaviour, in features/web/song-chart-reader.feature.

Feature: Ingest song chart reading events
  As the MotifPath platform
  I want to store what students do in a song chart
  So that we can tell whether students use charts and the chord sheets in them

  Background:
    Given the Event Ingestion Service is operational and ready to accept events
    And student "alice" is authenticated with a valid session

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A song_chart.opened event is accepted
    When "alice" submits a song_chart.opened event for revision 2 of song chart "asa-branca"
    Then the event is accepted and stored in the event log

  Scenario: A song_chart.chord_viewed event is accepted
    When "alice" submits a song_chart.chord_viewed event for anchor "a3" of revision 2 of song chart "asa-branca", resolving to chord "G" and opening on voicing "g-open"
    Then the event is accepted and stored in the event log

  @wip
  Scenario: A song_chart.completed event is accepted
    When "alice" submits a song_chart.completed event for revision 2 of song chart "asa-branca"
    Then the event is accepted and stored in the event log

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Resubmitting a song_chart.opened event is accepted without error
    Given "alice" has already submitted a song_chart.opened event with identifier "evt-chart-001"
    When "alice" submits the same song_chart.opened event again with identifier "evt-chart-001"
    Then the event is accepted without error

  @wip
  Scenario: A song_chart.section_completed event is no longer accepted
    When "alice" submits an event with event type "song_chart.section_completed"
    Then the submission is rejected as invalid

  # ── Validation failures ─────────────────────────────────────────────────────

  Scenario: A song_chart event without a song chart context is rejected
    When "alice" submits a song_chart.opened event with the song chart context omitted
    Then the submission is rejected as invalid
    And the rejection identifies "song_chart_context" as the source of the error

  Scenario: A song_chart.chord_viewed event without the voicing it opened on is rejected
    When "alice" submits a song_chart.chord_viewed event with the voicing omitted
    Then the submission is rejected as invalid
    And the rejection identifies "chord_voicing_id" as the source of the error

  @wip
  Scenario: A song_chart.completed event without a song chart context is rejected
    When "alice" submits a song_chart.completed event with the song chart context omitted
    Then the submission is rejected as invalid
    And the rejection identifies "song_chart_context" as the source of the error
