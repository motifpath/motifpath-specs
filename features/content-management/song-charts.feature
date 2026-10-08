# Song charts: authoring and publication (ADR-050 §3, §5, §6, as amended on 2026-10-07).
#
# A song chart is lyrics with chords anchored to the words they fall on. Only admins author and
# publish charts, with no second reviewer. A song's rights are cleared outside MotifPath; a chart
# only records that an admin confirmed they were checked, and can't be published without it.
# Publishing makes an immutable revision; a correction is published as a new revision, and
# learners keep reading the previous one until then. What a learner reads is in
# song-chart-reader.feature.

Feature: Author and publish song charts
  As an admin of the concierge team
  I want to write a song chart and publish it once its chords and rights are checked
  So that every chart a learner reads plays the right chords and was cleared to be shown

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the chord catalog has the chords "G", "C", "D", "Em" and "D/F#", each with an active voicing
    And "ana" is authenticated as an admin

  # ── Authoring ────────────────────────────────────────────────────────────────

  Scenario: An admin starts a song chart
    When "ana" creates a song chart "Asa Branca" in "pt_BR" with the line "[G]Quando olhei a [C]terra ardendo"
    Then the chart is a draft that has never been published
    And the anchor on "Quando olhei a " has the written symbol "G" and resolves to the catalog chord "G"

  Scenario: A chord spelled another way resolves to the catalog chord and keeps its spelling
    When "ana" creates a song chart with a chord anchor written "Gmaj"
    Then the anchor resolves to the catalog chord "G"
    And the anchor's written symbol is still "Gmaj"

  Scenario: A symbol that can't be parsed is saved as written, with a warning
    Given "ana" has a song chart "Asa Branca"
    When "ana" changes a chord anchor of "Asa Branca" to "H7"
    Then the draft is saved
    And the anchor keeps the written symbol "H7" and resolves to no chord
    And the draft has the warning "unparsed_symbol" on that anchor, which blocks publication

  Scenario: A chord the catalog doesn't have is saved with a warning
    Given "ana" has a song chart "Asa Branca"
    When "ana" changes a chord anchor of "Asa Branca" to "C#7"
    Then the draft has the warning "chord_not_in_catalog" on that anchor, which blocks publication

  Scenario: A slash chord the catalog doesn't have resolves to the chord without its bass
    Given "ana" has a song chart "Asa Branca"
    When "ana" changes a chord anchor of "Asa Branca" to "C/G"
    Then the anchor resolves to the catalog chord "C"
    And the draft has the warning "bass_not_in_catalog" on that anchor, which doesn't block publication

  Scenario: A no-chord marking is not a warning
    Given "ana" has a song chart "Asa Branca"
    When "ana" changes a chord anchor of "Asa Branca" to "N.C."
    Then the anchor resolves to no chord
    And the draft has no warnings

  Scenario: A picked voicing must belong to the anchor's chord
    Given "ana" has a song chart "Asa Branca"
    When "ana" picks a voicing of "D" for an anchor written "G" in "Asa Branca"
    Then the draft is refused as invalid
    And the rejection identifies the anchor's chordVoicingId as the source of the error

  Scenario: A resolved chord sent by the client is ignored
    When "ana" creates a song chart with a chord anchor written "G" that claims the catalog chord "C"
    Then the anchor resolves to the catalog chord "G"

  Scenario: A teacher cannot author song charts
    Given "bob" is authenticated as a teacher
    When "bob" tries to create a song chart "Asa Branca"
    Then the request is refused because only admins author song charts

  Scenario: A student cannot author song charts
    Given "alice" is authenticated as a student
    When "alice" tries to create a song chart "Asa Branca"
    Then the request is refused because only admins author song charts

  # ── Rights confirmation ──────────────────────────────────────────────────────

  Scenario: Confirming a chart's rights records who confirmed and when
    Given "ana" has a song chart "Asa Branca"
    When "ana" confirms that the rights of "Asa Branca" were checked
    Then the draft's rights are confirmed by "ana", with the time of confirming

  Scenario: Clearing the confirmation removes who confirmed it
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    When "ana" clears the rights confirmation of "Asa Branca"
    Then the draft's rights are not confirmed

  # ── Publishing ───────────────────────────────────────────────────────────────

  Scenario: An admin publishes a chart with confirmed rights and resolved chords, as revision 1
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    When "ana" publishes "Asa Branca"
    Then the chart is published at revision 1, published by "ana"
    And revision 1 keeps the rights confirmation by "ana"
    And learners can read "Asa Branca"

  Scenario: Another admin can publish a chart they didn't write
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    And "rui" is authenticated as an admin
    When "rui" publishes "Asa Branca"
    Then the chart is published at revision 1, published by "rui"

  Scenario: A chart whose rights aren't confirmed cannot be published
    Given "ana" has a song chart "Asa Branca" whose rights are not confirmed
    When "ana" publishes "Asa Branca"
    Then publishing is refused as not publishable, because "rights_not_confirmed"
    And the chart is still a draft that has never been published

  Scenario: A chart with a chord that blocks publication cannot be published, and every such chord is listed
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    And the chart has chord anchors written "H7" and "C#7"
    When "ana" publishes "Asa Branca"
    Then publishing is refused as not publishable, because "unresolved_chords"
    And the refusal lists the anchors written "H7" and "C#7"

  Scenario: A chart whose picked voicing was withdrawn cannot be published
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed, with voicing "g-open" picked for an anchor
    And voicing "g-open" has been withdrawn from the chord catalog
    When "ana" publishes "Asa Branca"
    Then publishing is refused as not publishable, because "unresolved_chords"
    And the refusal lists the anchor with the warning "voicing_unavailable"

  Scenario: A chart with a slash chord missing from the catalog can be published
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    And the chart has a chord anchor written "C/G"
    When "ana" publishes "Asa Branca"
    Then the chart is published at revision 1

  Scenario: A teacher cannot publish a song chart
    Given "ana" has a song chart "Asa Branca" whose rights are confirmed
    And "bob" is authenticated as a teacher
    When "bob" publishes "Asa Branca"
    Then the request is refused because only admins author song charts

  # ── Corrections and revisions ────────────────────────────────────────────────

  Scenario: A correction is published as a new revision and the old one never changes
    Given the song chart "Asa Branca" is published at revision 1
    And "ana" has changed the chord on "terra" in the draft of "Asa Branca" from "C" to "Em"
    When "ana" publishes "Asa Branca"
    Then the chart is published at revision 2
    And revision 1 still has the chord "C" on "terra"
    And the chart's revisions are listed as 2 then 1

  Scenario: Editing the draft of a published chart doesn't change what learners read
    Given the song chart "Asa Branca" is published at revision 1
    When "ana" changes the title of the draft of "Asa Branca" to "Asa Branca (Luiz Gonzaga)"
    Then learners still read "Asa Branca" at revision 1, titled "Asa Branca"

  Scenario: Clearing the rights confirmation of a published chart doesn't take it down
    Given the song chart "Asa Branca" is published at revision 1
    When "ana" clears the rights confirmation of "Asa Branca"
    Then learners still read "Asa Branca" at revision 1

  Scenario: A chart that was never published has no revisions
    Given "ana" has a song chart "Asa Branca"
    When "ana" lists the revisions of "Asa Branca"
    Then no revisions are listed

  # ── Withdrawal ───────────────────────────────────────────────────────────────

  Scenario: An admin withdraws a published chart
    Given the song chart "Asa Branca" is published at revision 1
    When "ana" withdraws "Asa Branca" because "Rights disputed"
    Then the chart is withdrawn by "ana" because "Rights disputed"
    And learners can't read "Asa Branca"
    And revision 1 is still listed

  Scenario: Publishing a withdrawn chart serves it again
    Given the song chart "Asa Branca" was published at revision 1 and then withdrawn
    When "ana" publishes "Asa Branca"
    Then the chart is published at revision 2
    And learners can read "Asa Branca"

  Scenario: A chart that isn't published cannot be withdrawn
    Given "ana" has a song chart "Asa Branca"
    When "ana" withdraws "Asa Branca" because "Not ready"
    Then the request is refused because the chart is not published

  # ── Listing ──────────────────────────────────────────────────────────────────

  Scenario: An admin lists the published charts
    Given the song chart "Asa Branca" is published at revision 1
    And "ana" has a song chart "Carinhoso"
    When "ana" lists song charts that are published
    Then the list holds "Asa Branca" only

  Scenario: A teacher cannot list song charts without asking for the published ones
    Given "bob" is authenticated as a teacher
    When "bob" lists song charts
    Then the request is refused because only admins author song charts

  # ── Preview ──────────────────────────────────────────────────────────────────

  Scenario: An admin previews a draft as a learner would read it
    Given "ana" has a song chart "Asa Branca"
    When "ana" previews "Asa Branca"
    Then the preview holds the draft's lyrics and chords, with no revision number
    And it includes the catalog chords "G" and "C" with their voicings and diagrams
