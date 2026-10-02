Feature: List voices
  As the MotifPath platform
  I want every user to see the sampled sounds diagrams can be played with
  So that a diagram's sequence can be heard with a real instrument's sound

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And the platform provides a fretted voice "acoustic-guitar" and a keyboard voice "piano"

  Scenario: A student lists the voices
    Given "alice" is authenticated as a student
    When "alice" lists the voices
    Then the voices include "acoustic-guitar" for fretted instruments
    And the voices include "piano" for keyboard instruments

  @wip
  Scenario: Voices are listed in order of their identifiers
    Given "bob" is authenticated as a teacher
    When "bob" lists the voices
    Then the voices are ordered "acoustic-guitar, electric-bass, piano"

  Scenario: A voice's samples are listed from lowest to highest pitch
    Given "alice" is authenticated as a student
    When "alice" lists the voices
    Then every sample of voice "acoustic-guitar" has a download address
    And the samples of voice "acoustic-guitar" are in ascending pitch

  Scenario: Every voice carries the credit its license requires
    Given "alice" is authenticated as a student
    When "alice" lists the voices
    Then every voice has a non-empty attribution

  @wip
  Scenario: The electric bass voice reaches the bass's lowest string
    Given "alice" is authenticated as a student
    When "alice" lists the voices
    Then the voices include "electric-bass" for fretted instruments
    And the lowest sample of voice "electric-bass" is at or below "E1"

  Scenario: Every voice is named in every language
    Given "alice" is authenticated as a student
    When "alice" lists the voices
    Then every voice has a name in "en" and in "pt_BR"

  Scenario: Listing voices without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list the voices
    Then the request is refused with an authentication error
