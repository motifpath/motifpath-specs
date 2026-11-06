@wip
Feature: Administer and evaluate commercial activation
  Administrators change monetization flags and rollout groups through an audited admin API.
  Core decides whether a flag allows an operation's subject; the default answer is no.

  Background:
    Given Ada is an admin
    And Bea is a teacher
    And Cleo is a student

  # ── Defaults and reads ─────────────────────────────────────────────────────

  Scenario: Every flag starts OFF with an empty allowlist
    Given no activation change has been made in this environment
    When Ada reads the commercial rollout
    Then the activation revision is 0
    And every one of the 17 registered flags is disabled, not effective, not open to all users and has no subjects
    And there are no rollout groups

  Scenario: A non-admin cannot read the commercial rollout
    When Bea reads the commercial rollout
    Then the response is 403

  Scenario: Unreadable activation storage is an error, not OFF
    Given activation storage is unavailable
    When Ada reads the commercial rollout
    Then the response is 503

  # ── Changing a flag ────────────────────────────────────────────────────────

  Scenario: An admin enables a flag for one subject
    When Ada sets "content_ownership" to enabled for "user:Bea" at revision 0 with reason "Foundation rehearsal"
    Then the change is applied with activation revision 1 and an evidence entry
    And "content_ownership" is enabled and effective with subjects "user:Bea"
    And the evidence records Ada, the reason, and "content_ownership" disabled before and enabled after

  Scenario: A stale revision is refused
    Given the activation revision is 3
    When Ada sets "content_ownership" to enabled for "user:Bea" at revision 2
    Then the response is 409
    And the activation revision is still 3

  Scenario: Replaying the same change returns the original receipt
    Given Ada set "content_ownership" to enabled for "user:Bea" at revision 0 with idempotency key K
    When Ada sends the same change again with idempotency key K
    Then the response repeats the original receipt with activation revision 1
    And the activation revision is still 1

  Scenario: Reusing a key for a different change is refused
    Given Ada set "content_ownership" to enabled for "user:Bea" at revision 0 with idempotency key K
    When Ada sets "content_ownership" to disabled at revision 1 with idempotency key K
    Then the response is 409
    And "content_ownership" is still enabled

  Scenario: A non-admin cannot change a flag
    When Bea sets "content_ownership" to enabled for "user:Bea" at revision 0
    Then the response is 403
    And the activation revision is still 0

  Scenario: An unregistered flag is not found
    When Ada sets "free_money" to enabled at revision 0
    Then the response is 404

  Scenario: Audit failure prevents an activation change
    Given audit evidence cannot be written
    When Ada sets "content_ownership" to enabled for "user:Bea" at revision 0
    Then the response is 503
    And the activation revision is still 0 and "content_ownership" is still disabled

  # ── Evaluation ─────────────────────────────────────────────────────────────

  Scenario: An enabled flag allows only its listed subjects
    Given "content_ownership" is enabled for "user:Bea"
    Then "content_ownership" allows "user:Bea"
    And "content_ownership" does not allow "user:Cleo"

  Scenario: An enabled flag with no subjects allows no one
    Given "content_ownership" is enabled with no subjects
    Then "content_ownership" does not allow "user:Bea"

  Scenario: A flag open to all users allows every user but no unlisted service
    When Ada sets "plus_catalog" to enabled for all users at revision 0
    Then "plus_catalog" allows "user:Bea"
    And "plus_catalog" allows "user:Cleo"
    And "plus_catalog" does not allow "service:core-domain"

  Scenario: A flag open to all users still allows a listed service
    When Ada sets "plus_webhooks" to enabled for all users and "service:core-domain" at revision 0
    Then "plus_webhooks" allows "user:Cleo"
    And "plus_webhooks" allows "service:core-domain"

  Scenario: Opening a flag to all users is recorded like any other change
    When Ada sets "plus_catalog" to enabled for all users at revision 0 with reason "General availability"
    Then the change is applied with activation revision 1 and an evidence entry
    And the evidence records Ada, the reason, and "plus_catalog" not open to all users before and open after

  Scenario: A disabled prerequisite denies a dependent that is ON
    Given "content_versions" is enabled for "user:Bea"
    And "content_ownership" is disabled
    Then "content_versions" does not allow "user:Bea"
    And the rollout shows "content_versions" as enabled but not effective

  Scenario: Enabling a flag does not enable its prerequisites
    When Ada sets "content_versions" to enabled for "user:Bea" at revision 0
    Then "content_ownership" is still disabled

  Scenario: An unreadable activation decision denies
    Given "content_ownership" is enabled for "user:Bea"
    And activation storage is unavailable
    Then "content_ownership" does not allow "user:Bea"

  # ── Groups ────────────────────────────────────────────────────────────────

  Scenario: An admin creates a group with no members
    When Ada saves group "beta" named "Private beta" with reason "Beta cohort"
    Then the change is applied with activation revision 1 and an evidence entry
    And group "beta" is named "Private beta" and has no members

  Scenario: Renaming a group keeps its members
    Given group "beta" has members Bea and Cleo
    When Ada saves group "beta" named "Closed beta"
    Then group "beta" is named "Closed beta" and has members Bea and Cleo

  Scenario: A group entry allows its members and no one else
    Given group "beta" has member Cleo
    And "plus_checkout" is enabled for "group:beta"
    Then "plus_checkout" allows "user:Cleo"
    And "plus_checkout" does not allow "user:Bea"

  Scenario: Adding a member admits them to every flag that lists the group
    Given group "friends-and-family" exists with no members
    And "plus_catalog" is enabled for "group:friends-and-family"
    And "plus_checkout" is enabled for "group:friends-and-family"
    When Ada adds Cleo to group "friends-and-family" with reason "Invited"
    Then the change is applied with a new activation revision and an evidence entry
    And "plus_catalog" allows "user:Cleo"
    And "plus_checkout" allows "user:Cleo"

  Scenario: A membership change needs no expected revision
    Given group "beta" has member Cleo
    And Ada last read the groups at revision 1
    And the activation revision is now 4
    When Ada removes Cleo from group "beta"
    Then the change is applied with activation revision 5

  Scenario: Adding a current member or removing a non-member is not an error
    Given group "beta" has member Cleo
    When Ada adds Cleo and removes Bea in group "beta"
    Then the change is applied with a new activation revision
    And group "beta" has members Cleo

  Scenario: Replaying a membership change returns the original receipt
    Given Ada added Cleo to group "beta" with idempotency key K
    When Ada sends the same membership change again with idempotency key K
    Then the response repeats the original receipt
    And the activation revision is unchanged

  Scenario: A membership change for an unknown user is refused
    When Ada adds an unknown user to group "beta"
    Then the response is 400
    And group "beta" is unchanged

  Scenario: A user cannot be added and removed in the same change
    When Ada adds Cleo and removes Cleo in group "beta"
    Then the response is 400

  Scenario: A membership change for an unknown group is not found
    When Ada adds Cleo to group "staff"
    Then the response is 404

  Scenario: A flag cannot list a group that does not exist
    When Ada sets "plus_checkout" to enabled for "group:staff" at revision 0
    Then the response is 400
    And the activation revision is still 0

  Scenario: A non-admin cannot change groups
    When Bea saves group "beta" named "Mine"
    Then the response is 403
    When Bea adds Bea to group "beta"
    Then the response is 403

  Scenario: Audit failure prevents a membership change
    Given group "beta" exists with no members
    And audit evidence cannot be written
    When Ada adds Cleo to group "beta"
    Then the response is 503
    And group "beta" has no members

  Scenario: Removing a member fences their new intents and keeps earlier ones
    Given group "beta" has member Cleo
    And "plus_checkout" is enabled for "group:beta" at activation revision 2
    And a commercial intent for "plus_checkout" and "user:Cleo" was authorized at revision 2
    When Ada removes Cleo from group "beta"
    Then a new commercial intent for "plus_checkout" and "user:Cleo" is refused
    And the earlier intent still records activation revision 2 and can be completed

  # ── Kill switch and fencing ────────────────────────────────────────────────

  Scenario: The kill switch turns every flag OFF and keeps audiences
    Given "content_ownership" is enabled for "user:Bea"
    And "plus_catalog" is enabled for all users
    And "private_beta" is enabled for "group:beta"
    When Ada turns off all commercial flags with reason "Incident"
    Then the change is applied with a new activation revision and an evidence entry
    And every flag is disabled
    And "content_ownership" still lists subject "user:Bea"
    And "plus_catalog" is still open to all users
    And "private_beta" still lists subject "group:beta"
    And "plus_catalog" does not allow "user:Cleo"

  Scenario: The kill switch works from a stale view
    Given Ada last read the rollout at revision 1
    And the activation revision is now 4
    When Ada turns off all commercial flags with reason "Incident"
    Then the change is applied with activation revision 5

  Scenario: An intent started after OFF commits is refused
    Given "content_ownership" is enabled for "user:Bea"
    When Ada turns off all commercial flags
    And a new commercial intent for "content_ownership" and "user:Bea" is then authorized
    Then the intent is refused

  Scenario: An intent authorized before OFF keeps its revision
    Given "content_ownership" is enabled for "user:Bea" at activation revision 1
    And a commercial intent for "content_ownership" and "user:Bea" was authorized at revision 1
    When Ada turns off all commercial flags
    Then that intent still records activation revision 1 and can be completed

  Scenario: An OFF change and a new intent racing never authorize under the old revision
    Given "content_ownership" is enabled for "user:Bea"
    When Ada turns off all commercial flags while a new intent for "content_ownership" and "user:Bea" is being authorized
    Then either the intent records the revision before OFF and committed before it, or it is refused
