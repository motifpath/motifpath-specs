Feature: Keep each user's email address in their user record
  As the MotifPath platform
  I want to hold the current email address of every user
  So that the platform can send its own emails without asking the identity provider at send time

  # ADR-065: the address comes from the "email" claim of the session token, the same way the
  # name comes from the "name" claim (ADR-035). It is stored once, in the user record, and is
  # never accepted from a request body. On every signed-in request it is refreshed when the
  # claim differs. Users registered before this change have no address until their next
  # signed-in request.
  #
  # The address is shown to its owner only. A UserRef never carries it.

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Registration records the email address carried by the identity token
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    And "alice"'s email address is "alice@example.com"
    When "alice" registers with role "student"
    Then the response includes the email address "alice@example.com"

  Scenario: A registered user's profile includes their email address
    Given "alice" has already registered as a student
    And "alice"'s email address is "alice@example.com"
    When "alice" requests their own profile
    Then the response includes the email address "alice@example.com"

  # ── Keeping the address current ────────────────────────────────────────────

  Scenario: An email address changed at the identity provider is stored on the user's next request
    Given "alice" has already registered as a student
    And "alice"'s email address is "alice@example.com"
    And "alice"'s email address is now "alice.martins@example.com"
    When "alice" requests their own profile
    Then the response includes the email address "alice.martins@example.com"

  Scenario: A user registered before addresses were stored gets one on their next request
    Given "alice" registered as a student before email addresses were stored
    And "alice"'s identity token carries the email address "alice@example.com"
    When "alice" requests their own profile
    Then the response includes the email address "alice@example.com"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Surrounding whitespace is trimmed from the email address
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    And "alice"'s email address is "  alice@example.com  "
    When "alice" registers with role "student"
    Then the response includes the email address "alice@example.com"

  Scenario: An identity token without an email address leaves the stored address unchanged
    Given "alice" has already registered as a student
    And "alice"'s email address is "alice@example.com"
    And the identity token of "alice" now carries no email address
    When "alice" requests their own profile
    Then the response includes the email address "alice@example.com"

  Scenario: An identity token whose email is not a valid address leaves the stored address unchanged
    Given "alice" has already registered as a student
    And "alice"'s email address is "alice@example.com"
    And the identity token of "alice" now carries the email "not-an-address"
    When "alice" requests their own profile
    Then the response includes the email address "alice@example.com"

  Scenario: A user registered before addresses were stored and still without one shows no address
    Given "alice" registered as a student before email addresses were stored
    And the identity token of "alice" now carries no email address
    When "alice" requests their own profile
    Then the response shows no email address

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Registration without an email address in the identity token is rejected
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    And the identity token of "alice" carries no email address
    When "alice" registers with role "student"
    Then the request is rejected as invalid
    And the rejection identifies "email" as the source of the error

  Scenario: Registration with an email that is not a valid address is rejected
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    And the identity token of "alice" carries the email "not-an-address"
    When "alice" registers with role "student"
    Then the request is rejected as invalid
    And the rejection identifies "email" as the source of the error
