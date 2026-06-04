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

  # ── Authentication failures ────────────────────────────────────────────────

  Scenario: Registration without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to register with role "student"
    Then the request is refused with an authentication error

  Scenario: Profile retrieval without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to retrieve a user profile
    Then the request is refused with an authentication error
