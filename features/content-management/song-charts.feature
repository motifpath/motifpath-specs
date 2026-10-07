# Song charts: authoring, review and publication (ADR-050 §3, §5, §6).
#
# A song chart is lyrics with chords anchored to the words they fall on. Only admins author
# charts, and a second admin approves each publication. Publishing makes an immutable revision;
# a correction is a new revision with its own review, and learners keep reading the previous one
# until it is approved. Rights records and their review are in rights-records.feature; what a
# learner reads, and when, is in song-chart-reader.feature.

@wip
Feature: Author, review and publish song charts
  As an admin of the concierge team
  I want to write a song chart and have a second admin approve it before learners see it
  So that every chart a learner reads has had its chords and rights checked by two people

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the chord catalog has the chords "G", "C", "D", "Em" and "D/F#", each with an active voicing
    And "ana" is authenticated as an admin
    And "rui" is an admin
    And an approved public-domain rights record "asa-branca-rights" covers the language "pt_BR"

  # ── Authoring ────────────────────────────────────────────────────────────────

  Scenario: An admin starts a song chart
    When "ana" creates a song chart "Asa Branca" in "pt_BR" with the line "[G]Quando olhei a [C]terra ardendo"
    Then the chart is a draft that has never been published
    And its draft is being edited
    And the anchor on "Quando olhei a " has the written symbol "G" and resolves to the catalog chord "G"

  Scenario: A chord spelled another way resolves to the catalog chord and keeps its spelling
    When "ana" creates a song chart with a chord anchor written "Gmaj"
    Then the anchor resolves to the catalog chord "G"
    And the anchor's written symbol is still "Gmaj"

  Scenario: A symbol that can't be parsed is saved as written, with a warning
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" changes a chord anchor of "Asa Branca" to "H7"
    Then the draft is saved
    And the anchor keeps the written symbol "H7" and resolves to no chord
    And the draft has the warning "unparsed_symbol" on that anchor, which blocks publication

  Scenario: A chord the catalog doesn't have is saved with a warning
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" changes a chord anchor of "Asa Branca" to "C#7"
    Then the draft has the warning "chord_not_in_catalog" on that anchor, which blocks publication

  Scenario: A slash chord the catalog doesn't have resolves to the chord without its bass
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" changes a chord anchor of "Asa Branca" to "C/G"
    Then the anchor resolves to the catalog chord "C"
    And the draft has the warning "bass_not_in_catalog" on that anchor, which doesn't block publication

  Scenario: A no-chord marking is not a warning
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" changes a chord anchor of "Asa Branca" to "N.C."
    Then the anchor resolves to no chord
    And the draft has no warnings

  Scenario: A picked voicing must belong to the anchor's chord
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
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

  # ── Submitting for review ────────────────────────────────────────────────────

  Scenario: An admin submits a draft with resolved chords and an approved rights record
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" submits "Asa Branca" for review
    Then the draft is in review, submitted by "ana"

  Scenario: A draft in review cannot be edited
    Given "ana" has submitted the song chart "Asa Branca" for review
    When "ana" tries to change the title of "Asa Branca"
    Then the request is refused because the draft is in review

  Scenario: A draft without a rights record cannot be submitted
    Given "ana" has a song chart "Asa Branca" with no rights record
    When "ana" submits "Asa Branca" for review
    Then the submission is refused as not publishable, because "missing_rights_record"

  Scenario: A draft whose language its rights record doesn't cover cannot be submitted
    Given "ana" has a song chart "Asa Branca" in "en" with rights record "asa-branca-rights"
    When "ana" submits "Asa Branca" for review
    Then the submission is refused as not publishable, because "language_not_covered"

  Scenario: A draft with a chord that blocks publication cannot be submitted, and every such chord is listed
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    And the chart has chord anchors written "H7" and "C#7"
    When "ana" submits "Asa Branca" for review
    Then the submission is refused as not publishable, because "unresolved_chords"
    And the refusal lists the anchors written "H7" and "C#7"

  Scenario: A draft under a licensed rights record cannot be submitted yet
    Given an approved licensed rights record "licensed-song-rights" covers the language "pt_BR"
    And "ana" has a song chart "Licensed Song" with rights record "licensed-song-rights"
    When "ana" submits "Licensed Song" for review
    Then the submission is refused as not publishable, because "licensed_basis_not_enabled"

  # ── Review ───────────────────────────────────────────────────────────────────

  Scenario: A second admin approves a submission, publishing revision 1
    Given "ana" has submitted the song chart "Asa Branca" for review
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the chart is published at revision 1, submitted by "ana" and approved by "rui"
    And its draft is being edited again, holding the published content
    And learners can read "Asa Branca"

  Scenario: The submitter cannot approve their own submission
    Given "ana" has submitted the song chart "Asa Branca" for review
    When "ana" approves "Asa Branca"
    Then the request is refused because the submitter cannot review their own submission
    And the draft is still in review

  Scenario: A reviewer sends a submission back with notes
    Given "ana" has submitted the song chart "Asa Branca" for review
    And "rui" is authenticated as an admin
    When "rui" requests changes to "Asa Branca" with the notes "The chord on 'terra' is C, not G"
    Then the draft is being edited again
    And its last review is "changes_requested" by "rui" with the notes "The chord on 'terra' is C, not G"
    And the chart is still a draft that has never been published

  Scenario: Requesting changes without notes is refused
    Given "ana" has submitted the song chart "Asa Branca" for review
    And "rui" is authenticated as an admin
    When "rui" requests changes to "Asa Branca" with no notes
    Then the review is refused as invalid
    And the rejection identifies "notes" as the source of the error

  Scenario: Approval is refused when the rights record is no longer approved
    Given "ana" has submitted the song chart "Asa Branca" for review
    And the rights record "asa-branca-rights" has since been changed and is pending review
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the approval is refused as not publishable, because "rights_record_not_approved"
    And the draft is still in review

  Scenario: Approval is refused when a picked voicing was withdrawn after submission
    Given "ana" has submitted the song chart "Asa Branca" with voicing "g-open" picked for an anchor
    And voicing "g-open" has been withdrawn from the chord catalog
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the approval is refused as not publishable, because "unresolved_chords"
    And the refusal lists the anchor with the warning "voicing_unavailable"

  Scenario: Reviewing a draft that isn't in review is refused
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the request is refused because the draft is not in review

  # ── Corrections and revisions ────────────────────────────────────────────────

  Scenario: A correction is published as a new revision and the old one never changes
    Given the song chart "Asa Branca" is published at revision 1
    And "ana" has changed the chord on "terra" in the draft of "Asa Branca" from "C" to "Em"
    And "ana" has submitted "Asa Branca" for review
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the chart is published at revision 2
    And revision 1 still has the chord "C" on "terra"
    And the chart's revisions are listed as 2 then 1

  Scenario: Editing the draft of a published chart doesn't change what learners read
    Given the song chart "Asa Branca" is published at revision 1
    When "ana" changes the title of the draft of "Asa Branca" to "Asa Branca (Luiz Gonzaga)"
    Then learners still read "Asa Branca" at revision 1, titled "Asa Branca"

  Scenario: A correction waiting for review doesn't change what learners read
    Given the song chart "Asa Branca" is published at revision 1
    And "ana" has changed the draft of "Asa Branca"
    When "ana" submits "Asa Branca" for review
    Then learners still read "Asa Branca" at revision 1

  Scenario: A chart that was never published has no revisions
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" lists the revisions of "Asa Branca"
    Then no revisions are listed

  # ── Withdrawal ───────────────────────────────────────────────────────────────

  Scenario: An admin withdraws a published chart without a second reviewer
    Given the song chart "Asa Branca" is published at revision 1
    When "ana" withdraws "Asa Branca" because "Lyric source disputed"
    Then the chart is withdrawn by "ana" because "Lyric source disputed"
    And learners can't read "Asa Branca"
    And revision 1 is still listed

  Scenario: Approving a new submission republishes a withdrawn chart
    Given the song chart "Asa Branca" was published at revision 1 and then withdrawn
    And "ana" has submitted "Asa Branca" for review
    And "rui" is authenticated as an admin
    When "rui" approves "Asa Branca"
    Then the chart is published at revision 2
    And learners can read "Asa Branca"

  Scenario: A chart that isn't published cannot be withdrawn
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" withdraws "Asa Branca" because "Not ready"
    Then the request is refused because the chart is not published

  # ── Listing ──────────────────────────────────────────────────────────────────

  Scenario: An admin lists the charts waiting for review
    Given "ana" has submitted the song chart "Asa Branca" for review
    And "ana" has a song chart "Carinhoso" with rights record "asa-branca-rights"
    When "ana" lists song charts whose draft is in review
    Then the list holds "Asa Branca" only

  Scenario: A teacher cannot list song charts
    Given "bob" is authenticated as a teacher
    When "bob" lists song charts
    Then the request is refused because only admins author song charts

  # ── Preview ──────────────────────────────────────────────────────────────────

  Scenario: An admin previews a draft as a learner would read it
    Given "ana" has a song chart "Asa Branca" with rights record "asa-branca-rights"
    When "ana" previews "Asa Branca"
    Then the preview holds the draft's lyrics and chords, with no revision number
    And it includes the catalog chords "G" and "C" with their voicings and diagrams
