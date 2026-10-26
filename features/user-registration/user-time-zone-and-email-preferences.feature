Feature: Set a user's time zone and email preferences
  As a registered MotifPath user
  I want the platform to know my time zone and which of its emails I want
  So that its emails arrive at a sensible local time, and only the ones I asked for

  # ADR-065. Both are set through the same profile update as the locale. A request may change
  # any of locale, time zone and email preferences, and must change at least one. A field that
  # is left out keeps its value.
  #
  # Time zone: an IANA name, such as "America/Sao_Paulo". A user without one has none in their
  # profile. The platform's emails then use "America/Sao_Paulo".
  #
  # Email preferences: one switch per kind of email a student can get, "progress_report" and
  # "reminders". Both are on for every new user. The concierge's weekly summary goes to the
  # team, not to the student, so it has no switch.

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Time zone ──────────────────────────────────────────────────────────────

  @wip
  Scenario: A registered user sets their time zone for the first time
    Given "alice" has already registered as a student
    And "alice" has no time zone set
    When "alice" sets their time zone to "America/Sao_Paulo"
    Then the response returns "alice"'s time zone "America/Sao_Paulo"

  @wip
  Scenario: A registered user replaces their time zone
    Given "alice" has already registered as a student
    And "alice"'s time zone is "America/Sao_Paulo"
    When "alice" sets their time zone to "Europe/Lisbon"
    Then the response returns "alice"'s time zone "Europe/Lisbon"

  @wip
  Scenario: A user with no time zone set shows none in their profile
    Given "alice" has already registered as a student
    And "alice" has no time zone set
    When "alice" requests their own profile
    Then the response shows no time zone

  @wip
  Scenario: Setting the time zone leaves the locale unchanged
    Given "alice" has already registered as a student
    And "alice" has locale "pt_BR"
    When "alice" sets their time zone to "Europe/Lisbon"
    Then the response returns "alice"'s locale "pt_BR"

  @wip
  Scenario: A user sets their locale and time zone in one update
    Given "alice" has already registered as a student
    When "alice" sets their locale to "en" and their time zone to "Europe/Lisbon" in one update
    Then the response returns "alice"'s locale "en" and time zone "Europe/Lisbon"

  @wip
  Scenario: Setting an unknown time zone is rejected
    Given "alice" has already registered as a student
    When "alice" submits a profile update with time zone "Mars/Olympus_Mons"
    Then the request is rejected as invalid
    And the rejection identifies "time_zone" as the source of the error

  # ── Email preferences ──────────────────────────────────────────────────────

  @wip
  Scenario: A new user gets progress reports and reminders
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    And "alice"'s email address is "alice@example.com"
    When "alice" registers with role "student"
    Then the response shows the email preference "progress_report" on
    And the response shows the email preference "reminders" on

  @wip
  Scenario: A student turns progress reports off
    Given "alice" has already registered as a student
    When "alice" turns the email preference "progress_report" off
    Then the response shows the email preference "progress_report" off

  @wip
  Scenario: Turning one email preference off leaves the other unchanged
    Given "alice" has already registered as a student
    When "alice" turns the email preference "progress_report" off
    Then the response shows the email preference "reminders" on

  @wip
  Scenario: A student turns reminders back on
    Given "alice" has already registered as a student
    And "alice" has the email preference "reminders" off
    When "alice" turns the email preference "reminders" on
    Then the response shows the email preference "reminders" on

  @wip
  Scenario: An unknown email preference is rejected
    Given "alice" has already registered as a student
    When "alice" submits a profile update with the email preference "newsletter" off
    Then the request is rejected as invalid
    And the rejection identifies "email_preferences" as the source of the error

  # ── Failures ───────────────────────────────────────────────────────────────

  @wip
  Scenario: A profile update that changes nothing is rejected
    Given "alice" has already registered as a student
    When "alice" submits a profile update with no fields
    Then the request is rejected as invalid

  @wip
  Scenario: Updating the profile before registering returns not found
    Given a Clerk identity "charlie" has not yet been registered
    When "charlie" attempts to set their time zone to "America/Sao_Paulo"
    Then the request is refused with a not-found error

  @wip
  Scenario: Updating the profile without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to set the time zone to "America/Sao_Paulo"
    Then the request is refused with an authentication error

  # ── The web reports the browser's time zone ────────────────────────────────

  @web
  Scenario: The web stores the browser's time zone when it differs from the profile's
    Given "alice" has already registered as a student
    And "alice"'s time zone is "America/Sao_Paulo"
    And "alice"'s browser is in time zone "Europe/Lisbon"
    When "alice" opens the app
    Then the web sets "alice"'s time zone to "Europe/Lisbon"

  @web
  Scenario: The web leaves the time zone alone when the browser's matches the profile's
    Given "alice" has already registered as a student
    And "alice"'s time zone is "America/Sao_Paulo"
    And "alice"'s browser is in time zone "America/Sao_Paulo"
    When "alice" opens the app
    Then the web sends no time zone update
