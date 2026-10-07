# The chord catalog: chords and their voicings, found by chord symbol.
#
# A chord is what is played (root, quality, slash bass); a voicing is one fingering of it, whose
# positions and playbacks are those of a chord_voicing diagram. The catalog is installed with the
# platform, not authored through the API. How a symbol is parsed is pinned by the shared golden
# cases in golden/chord-symbols/, which core and web both run; these scenarios cover what the
# catalog does with the result.

Feature: Find chords in the chord catalog
  As a teacher or admin writing content
  I want to type a chord symbol the way I'd write it and get that chord's fingerings
  So that I can show a learner a fingering that is known to be the right chord

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a fretted instrument "guitar" exists in the system
    And the chord catalog has the chord "Bbmaj7" with active voicings ranked:
      | voicing             | rank |
      | bbmaj7-a-shape-1    | 1    |
      | bbmaj7-e-shape-6    | 2    |
    And the chord catalog has the chord "Bbm" with active voicings ranked:
      | voicing             | rank |
      | bbm-a-shape-1       | 1    |
    And the chord catalog has the chord "D" with active voicings ranked:
      | voicing             | rank |
      | d-open              | 1    |
    And the chord catalog has the chord "D/F#" with active voicings ranked:
      | voicing             | rank |
      | d-over-f-sharp-open | 1    |

  # ── Finding a chord ──────────────────────────────────────────────────────────

  Scenario: A teacher finds a chord by its canonical symbol, with its voicings best first
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "Bbmaj7"
    Then the symbol is read as parsed
    And the chord found is "Bbmaj7"
    And its voicings are "bbmaj7-a-shape-1" then "bbmaj7-e-shape-6"

  Scenario Outline: Every supported spelling of a chord finds the same chord
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "<written>"
    Then the chord found is "Bbmaj7"
    And the search result keeps the symbol as written, "<written>"

    Examples:
      | written |
      | Bbmaj7  |
      | B♭M7    |
      | BbΔ7    |

  Scenario: A root spelled differently from the catalog finds the chord by its pitch
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "A#m"
    Then the chord found is "Bbm"
    And the parsed root is "A#"
    And the search result keeps the symbol as written, "A#m"

  Scenario: A slash chord the catalog has is found with its bass
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "D/F#"
    Then the chord found is "D/F#"
    And no chord without the bass is offered

  Scenario: A slash chord the catalog doesn't have offers the chord without its bass
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "D/A"
    Then the symbol is read as parsed
    And no chord is found
    And the chord offered without the bass is "D"

  Scenario: A chord the catalog doesn't have is parsed but not found
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "C#7"
    Then the symbol is read as parsed
    And no chord is found
    And no chord without the bass is offered

  Scenario: A withdrawn voicing is no longer offered
    Given voicing "bbmaj7-e-shape-6" has been withdrawn from the chord catalog
    And "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "Bbmaj7"
    Then its voicings are "bbmaj7-a-shape-1" only

  # ── Symbols that aren't chords ───────────────────────────────────────────────

  Scenario: A symbol that can't be parsed stays text, with a warning
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "H7"
    Then the symbol is read as unparsed, with the warning "unparsed_symbol"
    And no chord is found

  Scenario: A symbol with an unsupported quality is not reinterpreted
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "C7#11"
    Then the symbol is read as unparsed, with the warning "unsupported_quality"
    And no chord is found

  Scenario: A solfège name is not read as a diminished chord
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "Do"
    Then the symbol is read as unparsed, with the warning "unsupported_quality"
    And no chord is found

  Scenario: A no-chord marking is read as no chord
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for "N.C."
    Then the symbol is read as no chord
    And no chord is found

  # ── Reading one chord ────────────────────────────────────────────────────────

  Scenario: An admin reads a chord with its formula and voicings
    Given "admin" is authenticated as an admin
    When "admin" retrieves the chord "Bbmaj7"
    Then the chord's formula is "R", "3", "5", "7"
    And its voicings are "bbmaj7-a-shape-1" then "bbmaj7-e-shape-6"
    And each voicing names its chord_voicing diagram

  Scenario: Retrieving a chord that does not exist returns not found
    Given "bob" is authenticated as a teacher
    When "bob" retrieves a chord with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Failures ─────────────────────────────────────────────────────────────────

  Scenario: A chord symbol longer than 32 characters is rejected
    Given "bob" is authenticated as a teacher
    When "bob" searches the chord catalog for a symbol of 33 characters
    Then the request is refused with a validation error

  Scenario: A student cannot search the chord catalog
    Given "alice" is authenticated as a student
    When "alice" searches the chord catalog for "Bbmaj7"
    Then the request is refused with a forbidden error

  Scenario: A student cannot read a chord from the catalog
    Given "alice" is authenticated as a student
    When "alice" retrieves the chord "Bbmaj7"
    Then the request is refused with a forbidden error

  Scenario: Searching the chord catalog without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request searches the chord catalog for "Bbmaj7"
    Then the request is refused with an authentication error
