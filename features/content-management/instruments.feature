Feature: Manage instruments
  As the MotifPath platform
  I want teachers and admins to define the instruments a prebuilt diagram can be authored against
  So that a Diagram's positions always use the coordinate shape that actually matches its instrument

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a fretted instrument, named in every language
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the instrument is created and assigned a stable identifier
    And the instrument's family is "fretted"
    And the instrument's name in "en" is "Guitar"
    And the instrument's name in "pt_BR" is "Violão"
    And the instrument's languages are "en, pt_BR"

  Scenario: A teacher creates a keyboard instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a keyboard instrument named "Piano" in English and "Piano" in Portuguese with key range "A0" to "C8"
    Then the instrument is created and assigned a stable identifier
    And the instrument's family is "keyboard"

  Scenario: An admin creates an instrument
    Given "admin" is authenticated as an admin
    When "admin" creates a fretted instrument named "4-string bass" in English and "Contrabaixo de 4 cordas" in Portuguese with 4 strings tuned "E1, A1, D2, G2"
    Then the instrument is created and assigned a stable identifier

  # ── Happy path — listing ─────────────────────────────────────────────────────

  Scenario: A teacher lists all known instruments
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists all known instruments
    Then the response includes instrument "guitar" and instrument "piano"

  Scenario: Listing instruments when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all known instruments
    Then the response is an empty list

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a fretted instrument without tuning is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request for a fretted instrument with the tuning field omitted
    Then the request is rejected as invalid
    And the rejection identifies "tuning" as the source of the error

  Scenario: Creating a keyboard instrument with tuning is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request for a keyboard instrument carrying tuning
    Then the request is rejected as invalid
    And the rejection identifies "tuning" as the source of the error

  Scenario: Creating an instrument with an unrecognised family is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request with family "strummed"
    Then the request is rejected as invalid
    And the rejection identifies "family" as the source of the error

  Scenario: Creating an instrument named in only one language is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named only "Guitar" in English with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Creating an instrument with a name for "any" language is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument with names "en" "Guitar", "pt_BR" "Violão" and "any" "Guitar" with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Creating an instrument with a name in an unknown language is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument with names "en" "Guitar", "pt_BR" "Violão" and "fr" "Guitare" with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Creating an instrument with a blank name is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "   " in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  # ── Tuning and default voice ───────────────────────────────────────────────

  Scenario: A teacher creates a fretted instrument with a default voice
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4" and default voice "acoustic-guitar"
    Then the instrument is created and assigned a stable identifier
    And the instrument's tuning is "E2, A2, D3, G3, B3, E4"
    And the instrument's default voice is "acoustic-guitar"

  Scenario: Creating a fretted instrument whose tuning has no octaves is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E, A, D, G, B, E"
    Then the request is rejected as invalid
    And the rejection identifies "tuning" as the source of the error

  Scenario: Creating an instrument without a default voice is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create instrument request for a fretted instrument with the default_voice_id field omitted
    Then the request is rejected as invalid
    And the rejection identifies "default_voice_id" as the source of the error

  Scenario: Creating an instrument whose default voice plays another family is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4" and default voice "piano"
    Then the request is rejected as invalid
    And the rejection identifies "default_voice_id" as the source of the error

  Scenario: Creating an instrument with a default voice that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4" and default voice "banjo"
    Then the request is rejected as invalid
    And the rejection identifies "default_voice_id" as the source of the error

  Scenario: An admin changes an instrument's default voice
    Given a fretted instrument "guitar" exists in the system
    And the platform provides a fretted voice "nylon-guitar"
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese with default voice "nylon-guitar"
    Then the instrument's default voice is "nylon-guitar"
    And the instrument's tuning is unchanged

  Scenario: Changing an instrument's default voice to another family's voice is rejected
    Given a fretted instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese with default voice "piano"
    Then the request is rejected as invalid
    And the rejection identifies "default_voice_id" as the source of the error

  # ── Updating names ─────────────────────────────────────────────────────────

  Scenario: An admin replaces an instrument's names
    Given a fretted instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese
    Then the instrument's name in "en" is "Guitar"
    And the instrument's name in "pt_BR" is "Violão"
    And the instrument's family is "fretted"

  Scenario: Renaming an instrument without every language is rejected
    Given a fretted instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to only "Guitar" in English
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Renaming an instrument that does not exist returns not found
    Given "admin" is authenticated as an admin
    When "admin" renames an instrument with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Icon ───────────────────────────────────────────────────────────────────

  @wip
  Scenario: A teacher creates an instrument with its icon
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "4-string bass" in English and "Contrabaixo de 4 cordas" in Portuguese with 4 strings tuned "E1, A1, D2, G2" and icon "electric_bass"
    Then the instrument is created and assigned a stable identifier
    And the instrument's icon is "electric_bass"

  @wip
  Scenario: An instrument created without an icon gets its family's icon
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4"
    Then the instrument's icon is "fretted"

  @wip
  Scenario: Creating an instrument with an icon that is not a key is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a fretted instrument named "Guitar" in English and "Violão" in Portuguese with 6 strings tuned "E2, A2, D3, G3, B3, E4" and icon "Electric Bass!"
    Then the request is rejected as invalid
    And the rejection identifies "icon" as the source of the error

  @wip
  Scenario: An admin changes an instrument's icon
    Given a fretted instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese with icon "acoustic_guitar"
    Then the instrument's icon is "acoustic_guitar"

  @wip
  Scenario: Renaming an instrument without an icon leaves its icon unchanged
    Given a fretted instrument "guitar" with icon "electric_guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese
    Then the instrument's icon is "electric_guitar"

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create an instrument
    Given "alice" is authenticated as a student
    When "alice" attempts to create an instrument
    Then the request is refused with a forbidden error

  Scenario: Creating an instrument without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create an instrument
    Then the request is refused with an authentication error

  Scenario: A teacher cannot rename an instrument
    Given a fretted instrument "guitar" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese
    Then the request is refused with a forbidden error

  Scenario: A student cannot rename an instrument
    Given a fretted instrument "guitar" exists in the system
    And "alice" is authenticated as a student
    When "alice" renames instrument "guitar" to "Guitar" in English and "Violão" in Portuguese
    Then the request is refused with a forbidden error

  Scenario: Renaming an instrument without an authentication token is refused
    Given a fretted instrument "guitar" exists in the system
    And no authentication token is provided
    When an unauthenticated request attempts to rename instrument "guitar"
    Then the request is refused with an authentication error
