# Rights records: why MotifPath may show a song (ADR-050 §5, as amended on 2026-10-07).
#
# A rights record belongs to a song and states its basis (public domain, original or licensed),
# the evidence that basis needs, and the languages it covers. Evidence is recorded as references:
# citations, document identifiers or links. MotifPath stores no evidence files. No territory is
# recorded. A second admin approves every record, and any change sends it back to review.

@wip
Feature: Record and review the rights to show a song
  As an admin of the concierge team
  I want every song's rights recorded with evidence and checked by a second admin
  So that no chart reaches a learner without a defensible reason to show it

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "ana" is authenticated as an admin
    And "rui" is an admin

  # ── Recording ────────────────────────────────────────────────────────────────

  Scenario: An admin records a public-domain song with its creators' dates
    When "ana" records the rights to "Asa Branca" as public domain in "pt_BR", with:
      | creator           | role     | death year |
      | Luiz Gonzaga      | composer | 1989       |
      | Humberto Teixeira | lyricist | 1979       |
    And the lyric source "Songbook, 1947 edition"
    Then the rights record is pending review, last changed by "ana"

  Scenario: An admin records an original song with the creator's permission
    When "ana" records the rights to "Canção da Turma" as original in "pt_BR", with the creator "Marina Alves" and the permission "drive:permissions/marina-alves-2026.pdf" covering lyric display and chord transcription
    Then the rights record is pending review

  Scenario: A public-domain creator without a death year needs a source for the status
    When "ana" records the rights to "Folk Tune" as public domain in "en", with a creator with no death year and no status source
    Then the record is refused as invalid
    And the rejection identifies "public_domain.status_source" as the source of the error

  Scenario: An original song's permission must cover both lyric display and chord transcription
    When "ana" records the rights to "Canção da Turma" as original, with a permission covering lyric display only
    Then the record is refused as invalid
    And the rejection identifies "original.permitted_uses" as the source of the error

  Scenario: Evidence for a basis other than the one stated is refused
    When "ana" records the rights to "Asa Branca" as original, with public-domain evidence
    Then the record is refused as invalid
    And the rejection identifies "public_domain" as the source of the error

  Scenario: A license without translation covers exactly one language
    When "ana" records the rights to "Licensed Song" as licensed in "pt_BR" and "en", with a license that doesn't permit translation
    Then the record is refused as invalid
    And the rejection identifies "languages" as the source of the error

  Scenario: A teacher cannot read or write rights records
    Given "bob" is authenticated as a teacher
    When "bob" lists rights records
    Then the request is refused because only admins manage rights records

  # ── Review ───────────────────────────────────────────────────────────────────

  Scenario: A second admin approves a rights record
    Given "ana" has recorded the rights to "Asa Branca" as public domain in "pt_BR"
    And "rui" is authenticated as an admin
    When "rui" approves the rights record of "Asa Branca"
    Then the rights record is approved, with its last review "approved" by "rui"

  Scenario: The admin who last changed a record cannot approve it
    Given "ana" has recorded the rights to "Asa Branca" as public domain in "pt_BR"
    When "ana" approves the rights record of "Asa Branca"
    Then the request is refused because the admin who last changed a record cannot review it

  Scenario: A reviewer sends a record back with notes
    Given "ana" has recorded the rights to "Asa Branca" as public domain in "pt_BR"
    And "rui" is authenticated as an admin
    When "rui" requests changes to the rights record of "Asa Branca" with the notes "Cite the 1947 edition's publisher"
    Then the rights record needs changes, with the notes "Cite the 1947 edition's publisher"

  Scenario: Changing an approved record sends it back to review
    Given the rights record of "Asa Branca" is approved
    When "ana" adds the language "en" to the rights record of "Asa Branca"
    Then the rights record is pending review, last changed by "ana"

  Scenario: Reviewing a record that isn't pending review is refused
    Given the rights record of "Asa Branca" is approved
    And "rui" is authenticated as an admin
    When "rui" approves the rights record of "Asa Branca"
    Then the request is refused because the record is not pending review

  # ── Listing ──────────────────────────────────────────────────────────────────

  Scenario: An admin lists the records waiting for review
    Given "ana" has recorded the rights to "Asa Branca" as public domain in "pt_BR"
    And the rights record of "Carinhoso" is approved
    When "ana" lists rights records pending review
    Then the list holds the record of "Asa Branca" only
