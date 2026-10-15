@wip
Feature: Refund eligibility and disputed payment access
  Full refunds are handled by an admin and return the full customer payment.
  Refund eligibility is remembered per learner and subscription scope.
  # MOT-117; ADR-057. Examples describe the commercial policy, not exceptions to statutory rights.

  Scenario: First subscription refund eligibility begins when paid access becomes available
    Given Alice's first subscription payment succeeded on "2026-10-01T12:00:00Z"
    And subscription access became available on "2026-10-03T12:00:00Z"
    When Alice requests a refund on "2026-10-09T12:00:00Z"
    Then the request is within the seven-day commercial refund window

  Scenario: A teacher-path purchase has a seven-day refund window
    Given Alice paid for path "Guitar foundations" and received access on "2026-10-01T12:00:00Z"
    When she requests a refund on "2026-10-06T12:00:00Z"
    Then the request is within the seven-day commercial refund window

  Scenario: Automatic renewal does not restart refund eligibility
    Given Alice's first subscription refund window has ended
    When that subscription renews successfully
    Then the renewal does not create another seven-day commercial refund window

  Scenario: Rejoining the same subscription scope does not restart refund eligibility
    Given Alice previously subscribed to course "First chords"
    And its first-subscription refund window ended before she cancelled
    When Alice subscribes to "First chords" again
    Then no new seven-day commercial refund window is created

  Scenario: Changing billing period does not restart refund eligibility
    Given Alice's first platform-wide subscription refund window has ended
    When her monthly platform-wide subscription changes to annual at renewal
    Then no new seven-day commercial refund window is created

  Scenario: First subscriptions to different scopes have independent eligibility
    Given Alice previously subscribed to the platform
    And she has never subscribed to course "First chords"
    When her first paid subscription access to "First chords" becomes available
    Then that course subscription receives its own seven-day commercial refund window

  Scenario: A request outside the window is not automatically eligible
    Given Alice's first paid subscription access became available on "2026-10-01T12:00:00Z"
    When she requests a commercial-policy refund on "2026-10-09T12:00:00Z"
    Then the request is outside the seven-day commercial refund window

  Scenario: Submitting a refund request does not itself issue a refund
    Given Alice has an eligible paid purchase
    When she submits a refund request
    Then the request awaits admin handling without issuing a refund

  Scenario: A learner cannot execute a refund
    Given Alice has an eligible refund request
    When Alice attempts to execute the refund as a learner
    Then execution is refused

  Scenario: The customer receives the full payment without fee deduction
    Given Alice paid 100 BRL for a purchase eligible for a full refund
    And its processing fee was 4 BRL
    When an admin executes the full refund successfully
    Then Alice receives 100 BRL and MotifPath bears the 4 BRL processing cost

  Scenario: A successful refund immediately ends its payment-linked access
    Given Alice's only grant for path "Guitar foundations" came from payment "payment-1"
    When the full refund of "payment-1" succeeds
    Then access granted by "payment-1" ends immediately

  Scenario: Pending refunds do not prematurely remove access
    Given Alice has valid access from payment "payment-1"
    When its refund is pending rather than successful
    Then access from "payment-1" is not removed because of that pending refund

  Scenario: Refund preserves independent access grants
    Given Alice can access a lesson through both a subscription and a separate permanent purchase
    When the subscription payment is successfully refunded
    Then the lesson remains accessible through the permanent purchase

  Scenario: Refund preserves progress and financial history
    Given Alice has recorded learning progress and a purchase receipt
    When that purchase is successfully refunded
    Then her progress and receipt remain with the auditable refund history

  Scenario: Duplicate refund completion cannot issue another refund
    Given refund operation "refund-1" already succeeded for payment "payment-1"
    When completion of "refund-1" is received again
    Then no second refund is issued and no additional grant removal is performed

  Scenario: Opening a chargeback does not block otherwise valid access
    Given a dispute for Alice's payment opened on "2026-10-01T12:00:00Z"
    And that dispute remains open
    When Alice opens its restricted content on "2026-10-07T12:00:00Z"
    Then the otherwise valid payment-linked access remains available while the dispute awaits a final decision

  Scenario: An unresolved chargeback does not block access after seven days
    Given a dispute for Alice's payment opened on "2026-10-01T12:00:00Z"
    And that dispute remains open
    When Alice opens its restricted content on "2026-10-08T12:00:00Z"
    Then the otherwise valid payment-linked access is not blocked because of the unresolved dispute

  Scenario: Duplicate dispute notification does not cause premature blocking
    Given dispute "dispute-1" opened on "2026-10-01T12:00:00Z"
    When another notification for the same dispute arrives on "2026-10-05T12:00:00Z"
    And the dispute has no final decision
    Then no duplicate financial effect or dispute-based access block occurs

  Scenario: An unresolved dispute does not affect an unrelated valid grant
    Given a payment dispute is awaiting a final decision
    And Alice has an independent valid grant for the same content
    When Alice opens that content
    Then the content remains accessible through the independent grant

  Scenario: A pending dispute does not extend an expired subscription
    Given Alice's paid subscription period and unpaid-renewal grace have ended
    And its payment dispute still awaits a final decision
    When Alice opens an unfinished lesson without an independent valid grant
    Then the lesson remains blocked due to subscription expiry rather than the pending dispute

  Scenario: A successful subscription refund does not cancel future renewals
    Given Alice's subscription is configured to renew automatically
    When its eligible first payment is successfully refunded
    Then future automatic renewal remains enabled until separately cancelled
