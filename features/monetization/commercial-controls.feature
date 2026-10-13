@wip
Feature: Commercial rollout preserves rights and records each operation
  Commercial activation controls new actions without removing existing rights.
  Every direct or indirect commercial operation is traceable.
  Repeated delivery of one logical operation produces its business effects once.

  Scenario: Commercial capabilities are disabled by default
    Given no commercial activation has been configured for an environment
    When a learner attempts to start a Plus checkout in that environment
    Then no checkout is created

  Scenario: An enabled checkout requires its prerequisites
    Given Plus checkout is enabled for learner "Alice"
    And payment processing readiness is disabled
    When Alice attempts to start a Plus checkout
    Then no checkout is created

  Scenario: A learner outside the approved cohort cannot start a purchase
    Given new path purchases are enabled for the approved private beta cohort
    And learner "Alice" is not in that cohort
    When Alice attempts to purchase path "Guitar foundations"
    Then no checkout is created

  Scenario: Disabling purchases preserves an existing permanent purchase
    Given learner "Alice" has permanently purchased path "Guitar foundations"
    And Alice has no Plus subscription
    And new path purchases have been disabled
    When Alice opens her purchased path
    Then Alice retains access to the purchased content

  Scenario: Rollback retains learning progress
    Given learner "Alice" has completed lesson "First chords"
    When commercial acquisition is disabled
    Then Alice's completion of "First chords" remains recorded

  Scenario: An authorized payment is fulfilled after checkout is disabled
    Given checkout "checkout-1" was authorized for Alice's purchase of "Guitar foundations"
    And new path purchases have since been disabled
    When the verified successful payment for "checkout-1" is received
    Then Alice's permanent purchase is fulfilled once

  Scenario: Changing free content to paid records the commercial transition
    Given path "Guitar foundations" is free
    And teacher "Bea" is authorized to change its commercial status
    When Bea changes the path to paid using operation "change-1" with reason "Introduce paid offer"
    Then durable audit evidence identifies Bea and operation "change-1"
    And the evidence records the path's free and paid states, reason, time and outcome

  Scenario: Audit failure prevents an untraceable commercial change
    Given path "Guitar foundations" is free
    And durable audit evidence cannot be recorded
    When an authorized teacher attempts to change the path to paid
    Then the path remains free

  Scenario: Repeating a commercial change does not repeat its effects
    Given operation "change-1" changed "Guitar foundations" from free to paid
    When the same operation is submitted again with the same intent
    Then the recorded result of "change-1" is returned
    And no second commercial transition occurs
    And the repeated attempt is traceable

  Scenario: Reusing an operation identity with different intent is refused
    Given operation "change-1" changed "Guitar foundations" from free to paid
    When operation "change-1" is submitted to change the path from paid to free
    Then the conflicting operation is refused
    And the path remains paid

  Scenario: Concurrent purchase retries fulfill one purchase
    Given purchase operation "purchase-1" is authorized for Alice and "Guitar foundations"
    When two attempts to fulfill "purchase-1" arrive concurrently
    Then one purchase receipt and one permanent grant are recorded

  Scenario: Retrying after a restart returns the completed operation
    Given purchase operation "purchase-1" was fulfilled durably
    And its reply did not reach Alice
    And the service has restarted
    When Alice retries "purchase-1" with the same intent
    Then the completed result is returned without another purchase or grant

  Scenario: Different payment notifications do not duplicate one purchase
    Given verified notification "event-1" fulfilled payment "payment-1"
    When verified notification "event-2" reports the same successful payment
    Then no additional purchase receipt or grant is created
    And both notification attempts are traceable to "payment-1"

  Scenario: An uncertain payment outcome is reconciled before another charge
    Given charge operation "charge-1" has an unknown provider outcome
    When the operation is retried
    Then its existing pending status is retained until reconciliation establishes the outcome
    And no second charge is initiated while the outcome is unknown

  Scenario: Commercial evidence connects an indirect change to its effects
    Given operation "change-1" authorized a free-to-paid transition for "Guitar foundations"
    When its resulting commercial update is applied asynchronously
    Then the update's audit evidence identifies "change-1" as its cause
    And the original actor and resulting outcome can be reconstructed
