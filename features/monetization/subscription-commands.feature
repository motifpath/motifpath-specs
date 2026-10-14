@wip
Feature: Caller-owned subscription commands are auditable and repeatable
  Cancellation remains available during acquisition rollback.
  Annual switching uses authoritative offers and does not charge mid-period.
  # MOT-117; supplements the subscription lifecycle and ADR-057 constraints.

  Scenario: Existing subscriptions remain visible after cohort removal
    Given Alice has an existing paid subscription
    And Alice is removed from the commercial acquisition cohort
    When Alice lists her subscriptions
    Then her existing subscription and its billing state remain visible

  Scenario: A caller cannot cancel another learner's subscription
    Given subscription "subscription-1" belongs to Bea
    When Alice attempts to cancel renewal for "subscription-1"
    Then no subscription is disclosed or changed by that request

  Scenario: Unregistered callers cannot issue a commercial command
    Given the caller has no registered MotifPath identity
    When the caller requests a subscription cancellation
    Then no cancellation command is accepted

  Scenario: New offers are hidden while acquisition is disabled
    Given new subscription acquisition is disabled
    When Alice requests offers for the platform in an enabled currency
    Then no new subscription offers are returned

  Scenario: Currency format does not enable a currency
    Given USD has not been enabled for commercial offers
    When Alice requests platform-wide offers priced in USD
    Then the request is refused rather than converting a configured BRL price

  Scenario: Platform-wide offers cannot be requested for a content identity
    When Alice requests platform-wide offers with a specific course identity
    Then the inconsistent scope request is refused

  Scenario: Cancellation remains available during acquisition rollback
    Given Alice has a subscription scheduled to renew
    And new subscription acquisition is disabled
    When Alice requests cancellation using operation "cancel-1"
    Then a durable cancellation command with traceable actor Alice is recorded

  Scenario: A pending cancellation is not reported as externally applied
    Given cancellation operation "cancel-1" is durably recorded
    And confirmation of the external renewal change is still pending
    When Alice retrieves the recorded result by repeating "cancel-1"
    Then the same operation is returned as pending without claiming external completion

  Scenario: Cancellation requires an operation identity
    Given Alice has a subscription scheduled to renew
    When Alice requests cancellation without a logical operation identity
    Then the request is refused without initiating a cancellation

  Scenario: A successful cancellation retry survives revision changes
    Given operation "cancel-1" applied cancellation observed at subscription revision 2
    And the subscription is now revision 3
    When Alice repeats "cancel-1" with the original intent and observed revision 2
    Then the recorded operation result is returned without a stale-revision refusal

  Scenario: Reusing an operation identity with different intent is refused
    Given operation "schedule-1" recorded annual offer "offer-1" for Alice's subscription
    When Alice repeats "schedule-1" using annual offer "offer-2" instead
    Then the conflicting intent is refused without replacing the original command

  Scenario: Concurrent cancellation retries produce one command
    Given Alice's subscription is revision 2 and scheduled to renew
    When two copies of cancellation operation "cancel-1" for revision 2 arrive concurrently
    Then exactly one durable cancellation command is recorded

  Scenario: New commands based on stale subscription state are refused
    Given Alice observed subscription revision 2
    And the subscription has since changed to revision 3
    When Alice submits a new cancellation operation based on revision 2
    Then the new command is refused as conflicting with current subscription state

  Scenario: An already cancelled renewal does not cause another external cancellation
    Given Alice's subscription already has renewal disabled
    When Alice submits a new cancellation operation using its current revision
    Then an applied no-op command is recorded without another external cancellation

  Scenario: A course offer cannot be used to switch a platform subscription
    Given Alice has a monthly platform-wide subscription
    When she requests annual switching using an offer for course "First chords"
    Then the scope mismatch is refused without scheduling the change

  Scenario: Switching cannot change the subscription currency
    Given Alice has a monthly subscription priced in BRL
    And an annual offer for the same scope is priced in another enabled currency
    When Alice requests switching to that annual offer
    Then the currency mismatch is refused

  Scenario: A retired offer cannot be used to schedule annual switching
    Given Alice has a paid monthly subscription
    And annual offer "offer-1" has been replaced by a new offer revision
    When Alice schedules annual switching using "offer-1"
    Then the stale offer is refused

  Scenario: Acquisition rollback prevents a new annual switch
    Given Alice has a paid monthly subscription
    And new annual switching is disabled for her cohort
    When Alice requests a new annual switch
    Then no annual switch is scheduled

  Scenario: Audit failure cannot leave an accepted untraceable command
    Given durable audit evidence cannot be recorded
    When Alice submits a subscription cancellation operation
    Then no untraceable commercial command or external effect is committed

  Scenario: A known operation survives a restart before its reply
    Given operation "cancel-1" was durably accepted before its reply was lost
    And the service has restarted
    When Alice repeats "cancel-1" with the same intent
    Then the existing operation is returned without initiating another external action

  Scenario: Rollback does not hide an already accepted annual-switch operation
    Given operation "schedule-1" was durably accepted for Alice's annual switch
    And new annual switching is subsequently disabled for her cohort
    When Alice repeats "schedule-1" with the same intent
    Then the existing operation is returned without initiating another external action
