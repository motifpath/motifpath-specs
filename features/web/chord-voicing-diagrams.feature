# Chord voicing diagrams in the diagram editor (MOT-45, Phase 1.5).
#
# The chord catalog installs each voicing's fingering as a basic diagram with purpose
# "chord_voicing" (ADR-050 §2a). Only the catalog's own workflow changes it, so the general diagram
# editor shows it read-only and offers a copy instead. The copy is an ordinary "general" diagram
# its creator can edit.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by the core-domain BDD suite. The API rules behind them (the updateDiagram refusal, a
# duplicate's purpose, the list's default purpose filter) are covered by
# features/content-management/diagrams.feature, section "Purpose — chord voicings".
#
# Out of scope: finding chords by symbol in the editor, and the catalog's review workflow.

Feature: Chord voicing diagrams in the diagram editor
  As a teacher or admin
  I want a chord catalog fingering to open read-only, with a way to make my own copy
  So that I can build on a known-good fingering without changing the one every chart relies on

  Background:
    Given the chord catalog has a voicing "a-minor-open" on instrument "guitar"

  Scenario: An admin opens a chord voicing diagram read-only
    Given an admin is signed in
    When the admin opens the diagram of voicing "a-minor-open" in the diagram editor
    Then no Save button is offered
    And a notice says the diagram comes from the chord catalog and can be copied with Save as
    And Save as is offered

  Scenario: A teacher opens a chord voicing diagram read-only
    Given a teacher is signed in
    When the teacher opens the diagram of voicing "a-minor-open" in the diagram editor
    Then no Save button is offered
    And a notice says the diagram comes from the chord catalog and can be copied with Save as

  Scenario: A copy saved from a chord voicing diagram opens editable
    Given a teacher is signed in
    And the teacher has opened the diagram of voicing "a-minor-open" in the diagram editor
    When the teacher saves it as "My A minor"
    Then the editor shows "My A minor"
    And the Save button is offered
    And no read-only notice is shown

  Scenario: An admin's template saved from a chord voicing diagram opens editable
    Given an admin is signed in
    And the admin has opened the diagram of voicing "a-minor-open" in the diagram editor
    When the admin saves it as a template named "A minor (open)" in every offered language
    Then the editor shows "A minor (open)"
    And the Save button is offered
    And no read-only notice is shown

  Scenario: A copy that fails to save leaves the chord voicing diagram open read-only
    Given a teacher is signed in
    And the teacher has opened the diagram of voicing "a-minor-open" in the diagram editor
    And saving a diagram fails
    When the teacher saves it as "My A minor"
    Then an error says the diagram couldn't be saved
    And the editor still shows the diagram of voicing "a-minor-open" read-only
