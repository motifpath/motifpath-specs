@wip
Feature: Subscription checkout and verified payment ingestion
  A recorded checkout intent uses an authoritative offer and the authenticated learner.
  Financial notifications are verified and durably received before fulfillment.
  # MOT-117; ADR-058 selects Stripe, ADR-057 requires audit and idempotency.

  Scenario: Subscription checkout uses the authoritative offer
    Given Alice can acquire annual platform offer "offer-1" for 400 BRL
    When Alice requests checkout for "offer-1" using operation "checkout-1"
    Then a traceable checkout intent for Alice records that offer and its authoritative monetary terms

  Scenario: Checkout refuses customer-controlled price overrides
    Given Alice can acquire offer "offer-1"
    When Alice submits a checkout request with a replacement price
    Then the invalid request is refused without creating a payment session

  Scenario: New checkout is blocked outside the acquisition cohort
    Given Alice is not admitted to subscription acquisition
    When Alice requests a new subscription checkout
    Then no new checkout session is initiated

  Scenario: A stale offer cannot start a new checkout
    Given offer "offer-1" was replaced by a new price revision
    When Alice requests a new checkout using "offer-1"
    Then the stale offer request is refused

  Scenario: Retrying a known checkout does not create another session
    Given operation "checkout-1" already records Alice's checkout for "offer-1"
    And the service has restarted
    When Alice repeats "checkout-1" with the same intent
    Then the original checkout is returned without another payment session

  Scenario: Reusing checkout identity with another offer is refused
    Given operation "checkout-1" records Alice's checkout for "offer-1"
    When Alice reuses "checkout-1" with "offer-2"
    Then the conflicting intent is refused

  Scenario: Concurrent requests cannot create two open checkouts for the same scope
    Given Alice has no subscription for course "First chords"
    When two new checkout operations for that course arrive concurrently
    Then at most one open checkout is authorized for Alice and that scope

  Scenario: A current subscription uses plan change rather than another acquisition
    Given Alice has a paid monthly platform-wide subscription
    When Alice requests a new platform-wide checkout using an annual offer
    Then the duplicate acquisition is refused without charging Alice again

  Scenario: An uncertain session creation is reconciled before another attempt
    Given checkout operation "checkout-1" has an unknown external session-creation outcome
    When Alice repeats that checkout operation
    Then the original checkout remains pending reconciliation without initiating another session

  Scenario: A browser return cannot grant access
    Given Alice returned from checkout without verified successful payment
    When Alice views the checkout result
    Then no subscription grant is created from the browser return

  Scenario: Another learner cannot read a checkout
    Given checkout "checkout-1" belongs to Bea
    When Alice attempts to view that checkout
    Then no checkout or payment details are disclosed

  Scenario: Invalid notification authentication cannot affect money or access
    When a financial notification cannot be authenticated as coming from the payment provider
    Then it is refused without committing a financial or entitlement effect

  Scenario: Receipt acknowledgement requires durable evidence
    Given a verified payment notification has arrived
    And durable receipt and audit evidence cannot be recorded
    When receipt is attempted
    Then successful receipt is not acknowledged

  Scenario: A duplicate notification does not create a duplicate financial effect
    Given provider event "event-1" has already been durably received
    When the same verified event arrives again
    Then its existing receipt is reused without another financial or entitlement effect

  Scenario: Different event identities cannot fulfill the same paid invoice twice
    Given paid invoice "invoice-1" has already produced its subscription-period grant
    When a different verified notification reports that same invoice payment
    Then no second financial record or subscription-period grant is created

  Scenario: Early notifications await their authoritative checkout mapping
    Given a verified payment notification arrives before its checkout mapping is available
    When the notification is durably received
    Then it waits for reconciliation without issuing an uncorrelated access grant

  Scenario: Old payment failures do not overwrite a verified newer paid period
    Given Alice's latest subscription period is verified paid
    When an older failure notification arrives out of order
    Then that old failure does not replace the newer authoritative paid state

  Scenario: A completed checkout without verified payment cannot grant access
    Given checkout completion is reported before successful payment can be established
    When the notification is handled
    Then subscription access is not granted solely from checkout completion

  Scenario: Verified payment can await grant fulfillment
    Given Alice's checkout payment is verified against its recorded offer
    And access fulfillment is still pending
    When Alice views her checkout
    Then it shows verified payment with fulfillment pending rather than claiming usable access

  Scenario: Rollback does not strand an already authorized checkout
    Given Alice's checkout was authorized before acquisition was disabled
    When its verified successful payment arrives afterward
    Then its financial and fulfillment obligations remain processable

  Scenario: Reconciliation recovers a lost notification
    Given Alice's recorded checkout was paid at the provider
    And its payment notification was not received
    When reconciliation verifies that payment and its authoritative mapping
    Then fulfillment proceeds once using the original checkout operation

  Scenario: A payment from another environment cannot fulfill a live checkout
    Given Alice's checkout belongs to the live environment
    When a verified test-environment payment is presented for it
    Then no live financial or entitlement effect is committed

  Scenario: An unfamiliar verified event is retained without granting access
    Given a verified provider event has an unfamiliar kind or unsupported delivery version
    When it is durably received
    Then it is retained for reconciliation without creating an unverified grant

  Scenario: An invalid provider envelope cannot be acknowledged as received
    Given a notification has no provider event identity
    When its financial receipt is attempted
    Then it is refused as malformed without a successful financial receipt
