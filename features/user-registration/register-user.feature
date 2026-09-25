Feature: Register a MotifPath user
  As the MotifPath platform
  I want to create a user record that maps a Clerk identity to a stable MotifPath user_id
  So that other services can validate identity claims and students can submit tracking events

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A new student registers successfully
    Given a Clerk identity "alice" has not yet been registered
    When "alice" registers with role "student"
    Then a user record is created for "alice"
    And the response includes a stable user_id and the role "student"
    And the response includes a registration timestamp

  Scenario: A new teacher registers successfully
    Given a Clerk identity "bob" has not yet been registered
    When "bob" registers with role "teacher"
    Then a user record is created for "bob"
    And the response includes a stable user_id and the role "teacher"

  Scenario: A registered user retrieves their own profile
    Given "alice" has already registered as a student
    When "alice" requests their own profile
    Then the response returns "alice"'s user_id, role "student", and registration timestamp

  # ── Display name (ADR-035) ─────────────────────────────────────────────────
  # The name comes from the "name" claim of the Clerk session token, never from
  # the request body.

  Scenario: Registration records the name carried by the identity token
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "Alice Martins"
    When "alice" registers with role "student"
    Then the response includes the display name "Alice Martins"

  Scenario: Surrounding whitespace is trimmed from the registered name
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named "  Alice Martins  "
    When "alice" registers with role "student"
    Then the response includes the display name "Alice Martins"

  Scenario: A name longer than 200 characters is cut to its first 200 characters
    Given a Clerk identity "alice" has not yet been registered
    And "alice" is named with 250 characters
    When "alice" registers with role "student"
    Then the response includes a display name of exactly 200 characters

  Scenario: A registered user's profile includes their display name
    Given "alice" has already registered as a student
    And "alice" is named "Alice Martins"
    When "alice" requests their own profile
    Then the response includes the display name "Alice Martins"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Attempting to register the same Clerk identity twice is refused
    Given "alice" has already registered as a student
    When "alice" attempts to register again with role "student"
    Then the request is refused with a conflict error

  Scenario: Attempting to register the same Clerk identity with a different role is also refused
    Given "alice" has already registered as a student
    When "alice" attempts to register again with role "teacher"
    Then the request is refused with a conflict error

  Scenario: Requesting a profile before registering returns not found
    Given a Clerk identity "charlie" has not yet been registered
    When "charlie" requests their own profile
    Then the request is refused with a not-found error

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Registration without a role is rejected
    Given a Clerk identity "alice" has not yet been registered
    When "alice" submits a registration request with the role field omitted
    Then the request is rejected as invalid
    And the rejection identifies "role" as the source of the error

  Scenario: Registration with an unrecognised role is rejected
    Given a Clerk identity "alice" has not yet been registered
    When "alice" submits a registration request with role "moderator"
    Then the request is rejected as invalid
    And the rejection identifies "role" as the source of the error

  Scenario: Attempting to self-register as admin is rejected
    Given a Clerk identity "alice" has not yet been registered
    When "alice" submits a registration request with role "admin"
    Then the request is rejected as invalid
    And the rejection identifies "role" as the source of the error

  Scenario: Registration from an identity token without a name is rejected
    Given a Clerk identity "dora" has not yet been registered
    And the identity token of "dora" carries no name
    When "dora" registers with role "student"
    Then the request is rejected as invalid
    And the rejection identifies "name" as the source of the error
    And no user record exists for "dora"

  Scenario: Registration from an identity token with a blank name is rejected
    Given a Clerk identity "dora" has not yet been registered
    And "dora" is named "   "
    When "dora" registers with role "student"
    Then the request is rejected as invalid
    And the rejection identifies "name" as the source of the error
    And no user record exists for "dora"

  # ── Authentication failures ────────────────────────────────────────────────

  Scenario: Registration without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to register with role "student"
    Then the request is refused with an authentication error

  Scenario: Profile retrieval without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to retrieve a user profile
    Then the request is refused with an authentication error
