@wip
Feature: Refund requests and admin execution preserve payment integrity
  A learner requests a refund of their own payment; an admin executes it.
  Duplicate delivery and concurrent admins cannot refund the same payment twice.
  # MOT-117; ADR-057. Partial refunds and statutory exceptions remain separate contract work.

  Scenario: A paid learner can request a full refund without choosing its amount
    Given Alice owns successful payment "payment-1" for 100 BRL
    When Alice requests its full refund with reason "Not suitable for me" using operation "request-1"
    Then one refund request is recorded with its authoritative amount of 100 BRL

  Scenario: A caller cannot request a refund of another learner's payment
    Given payment "payment-1" belongs to Bea
    When Alice requests its refund
    Then no payment is disclosed and no refund request is created

  Scenario: An unsuccessful payment cannot be refunded
    Given payment "payment-1" has never succeeded
    When its owner requests a refund
    Then the request is refused because no successful payment exists to refund

  Scenario: Customer-supplied refund amount is refused
    Given Alice owns successful payment "payment-1" for 100 BRL
    When she submits a refund request with a chosen amount of 200 BRL
    Then the invalid request is refused

  Scenario: Repeated request delivery returns the same request
    Given operation "request-1" already created a refund request for Alice's payment
    When Alice repeats "request-1" with the same payment and reason
    Then the same request is returned without creating another refund request

  Scenario: Changed intent cannot reuse a request identity
    Given operation "request-1" recorded refund reason "Not suitable for me"
    When Alice repeats "request-1" with a different reason
    Then the conflicting intent is refused without changing the recorded request

  Scenario: A new operation cannot create a second request for one payment
    Given a refund request already exists for Alice's payment "payment-1"
    When Alice requests another full refund of "payment-1" with a new operation identity
    Then the existing request is returned with its original reason intact

  Scenario: Admin delay does not invalidate a timely refund request
    Given Alice requested an eligible refund within the seven-day window
    When an admin handles the unchanged request after the window ends
    Then eligibility is evaluated at its original request time rather than the handling time

  Scenario: A late request is retained for admin review without inventing an exception
    Given Alice's commercial refund window has ended
    When Alice requests a refund
    Then the request is retained for admin review without being marked commercially eligible

  Scenario: Another learner cannot read a refund request
    Given a refund request belongs to Bea
    When Alice attempts to view it
    Then no refund request is disclosed

  Scenario: An admin can view a request for handling
    Given Alice has submitted a refund request
    When a registered admin views the request
    Then its payment amount, eligibility and current processing state are available

  Scenario: A learner cannot execute an eligible refund
    Given Alice has a commercially eligible refund request
    When Alice attempts to execute the refund as a learner
    Then the operation is refused without initiating a financial effect

  Scenario: An admin execution records its operator and reason
    Given Alice has an eligible refund request at revision 1
    When admin Gilson executes it with reason "Eligible first-subscription refund" using operation "execute-1"
    Then a durable execution operation identifies Gilson, the request and that reason

  Scenario: Concurrent admins cannot refund one payment twice
    Given an eligible refund request is ready for handling
    When two admins execute it concurrently using different operation identities
    Then at most one financial refund operation is initiated for its payment

  Scenario: Unknown provider outcome remains processing
    Given execution "execute-1" was sent for refunding Alice's payment
    And its financial outcome cannot yet be established
    When the admin views the request
    Then it remains processing rather than failed or successfully refunded

  Scenario: A processing execution is returned before stale-revision validation
    Given execution "execute-1" accepted request revision 1
    And the request is now revision 2 and processing
    When the admin repeats "execute-1" with the original intent and observed revision 1
    Then the existing execution is returned without another provider attempt

  Scenario: A different execution cannot bypass an uncertain operation
    Given a refund execution has an unknown financial outcome
    When an admin submits a new execution identity for that payment
    Then the conflicting request is refused pending reconciliation

  Scenario: A stale new admin command is refused
    Given an admin observed refund request revision 1
    And the request is now revision 2
    When the admin submits a new execution based on revision 1
    Then the stale command is refused

  Scenario: Audit storage failure prevents an untraceable refund
    Given durable commercial audit evidence cannot be recorded
    When an admin attempts to execute an eligible refund
    Then no untraceable financial refund is initiated

  Scenario: Acquisition rollback does not prevent handling existing obligations
    Given Alice has an eligible refund request
    And new commercial acquisition is disabled
    When a registered admin executes that request
    Then the request can enter processing without requiring acquisition to be re-enabled

  Scenario: Competing uncertain financial settlement prevents another refund
    Given an eligible refund case has an unresolved competing chargeback settlement
    When an admin attempts to execute its refund
    Then execution is refused pending reconciliation rather than initiating another financial return
