@wip
Feature: Administer and evaluate commercial activation
  Administrators change monetization flags through an audited, revision-checked admin API.
  Core decides whether a flag allows an operation's subject; the default answer is no.

  Background:
    Given Ada is an admin
    And Bea is a teacher

  # ── Defaults and reads ─────────────────────────────────────────────────────

  Scenario: Every flag starts OFF with an empty allowlist
    Given no activation change has been made in this environment
    When Ada reads the commercial rollout
    Then the activation revision is 0
    And every one of the 17 registered flags is disabled, not effective and has no subjects

  Scenario: A non-admin cannot read the commercial rollout
    When Bea reads the commercial rollout
    Then the response is 403

  Scenario: Unreadable activation storage is an error, not OFF
    Given activation storage is unavailable
    When Ada reads the commercial rollout
    Then the response is 503

  # ── Changing a flag ────────────────────────────────────────────────────────

  Scenario: An admin enables a flag for one subject
    When Ada sets "content_ownership" to enabled for "service:core-domain" at revision 0 with reason "Foundation rehearsal"
    Then the change is applied with activation revision 1 and an evidence entry
    And "content_ownership" is enabled and effective with subjects "service:core-domain"
    And the evidence records Ada, the reason, and "content_ownership" disabled before and enabled after

  Scenario: A stale revision is refused
    Given the activation revision is 3
    When Ada sets "content_ownership" to enabled for "service:core-domain" at revision 2
    Then the response is 409
    And the activation revision is still 3

  Scenario: Replaying the same change returns the original receipt
    Given Ada set "content_ownership" to enabled for "service:core-domain" at revision 0 with idempotency key K
    When Ada sends the same change again with idempotency key K
    Then the response repeats the original receipt with activation revision 1
    And the activation revision is still 1

  Scenario: Reusing a key for a different change is refused
    Given Ada set "content_ownership" to enabled for "service:core-domain" at revision 0 with idempotency key K
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
    When Ada sets "content_ownership" to enabled for "service:core-domain" at revision 0
    Then the response is 503
    And the activation revision is still 0 and "content_ownership" is still disabled

  # ── Evaluation ─────────────────────────────────────────────────────────────

  Scenario: An enabled flag allows only its listed subjects
    Given "content_ownership" is enabled for "user:Bea"
    Then "content_ownership" allows "user:Bea"
    And "content_ownership" does not allow "service:core-domain"

  Scenario: An enabled flag with no subjects allows no one
    Given "content_ownership" is enabled with no subjects
    Then "content_ownership" does not allow "user:Bea"

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

  # ── Kill switch and fencing ────────────────────────────────────────────────

  Scenario: The kill switch turns every flag OFF and keeps allowlists
    Given "content_ownership" is enabled for "user:Bea"
    And "private_beta" is enabled for "user:Bea"
    When Ada turns off all commercial flags with reason "Incident"
    Then the change is applied with a new activation revision and an evidence entry
    And every flag is disabled
    And "content_ownership" still lists subject "user:Bea"

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
