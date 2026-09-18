Feature: Set a user's locale preference
  As a registered MotifPath user
  I want to set my locale preference
  So that the platform's UI and the content I'm shown match a language I understand

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A registered user sets their locale for the first time
    Given "alice" has already registered as a student
    And "alice" has no locale preference set
    When "alice" sets their locale to "pt_BR"
    Then the response returns "alice"'s user_id, role "student", and locale "pt_BR"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A registered user replaces their existing locale preference
    Given "alice" has already registered as a student
    And "alice" has locale "en"
    When "alice" sets their locale to "pt_BR"
    Then the response returns "alice"'s user_id, role "student", and locale "pt_BR"

  Scenario: Setting the locale to the language it is already set to is a no-op success
    Given "alice" has already registered as a student
    And "alice" has locale "pt_BR"
    When "alice" sets their locale to "pt_BR"
    Then the response returns "alice"'s user_id, role "student", and locale "pt_BR"

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Setting the locale to an unrecognised language code is rejected
    Given "alice" has already registered as a student
    When "alice" submits a locale update with locale "xx_YY"
    Then the request is rejected as invalid
    And the rejection identifies "locale" as the source of the error

  Scenario: Setting the locale to "any" is rejected
    Given "alice" has already registered as a student
    When "alice" submits a locale update with locale "any"
    Then the request is rejected as invalid
    And the rejection identifies "locale" as the source of the error

  # ── Not-found and authentication failures ──────────────────────────────────

  Scenario: Setting the locale before registering returns not found
    Given a Clerk identity "charlie" has not yet been registered
    When "charlie" attempts to set their locale to "en"
    Then the request is refused with a not-found error

  Scenario: Setting the locale without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to set the locale to "en"
    Then the request is refused with an authentication error
