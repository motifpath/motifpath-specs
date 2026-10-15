@wip
Feature: Payment notifications and reconciliation converge on durable commercial facts
  Delayed or repeated financial observations do not duplicate or reverse valid effects.
  Recovery keeps the original operation and never invents a new payment.
  # MOT-117; commercial authority and provider decisions remain in ADR-057/058.

  Scenario: Subscription creation alone cannot grant paid access
    Given a subscription was created at the payment provider
    And successful funding of its first period has not been verified
    When its creation notification is handled
    Then no paid subscription-period grant is issued

  Scenario: Two event kinds describing one paid invoice grant one period
    Given checkout completion and an invoice-paid notification describe the same paid invoice
    When both observations are reconciled to Alice's recorded subscription
    Then that invoice produces at most one subscription-period grant

  Scenario: A manually marked paid invoice does not prove captured money
    Given an invoice is marked paid without an independently verified approved funding source
    When its notification is reconciled
    Then the invoice awaits review without creating an unverified paid grant

  Scenario: First-payment failure does not create unpaid-renewal grace
    Given Alice has never paid for the requested subscription
    When the first payment fails
    Then no paid-period or renewal-grace grant is created

  Scenario: Delayed failure notifications do not restart renewal grace
    Given Alice's previous paid period ended on "2026-10-01T12:00:00Z"
    And its renewal payment remains unsuccessful
    When the failure is received on "2026-10-05T12:00:00Z"
    Then renewal grace still ends on "2026-10-08T12:00:00Z"

  Scenario: A late paid observation does not undo a successful refund
    Given Alice's payment was already successfully refunded
    When an older paid-invoice observation arrives
    Then the refunded payment's access grant is not restored by that observation

  Scenario: A partial refund notification does not imply a successful full refund
    Given a charge-level notification reports that part of a payment was refunded
    When the individual refund facts are reconciled
    Then the full-refund case is not marked successful solely from that notification

  Scenario: Provider funds withdrawal does not decide content access
    Given Alice's disputed payment still awaits a final decision
    When the provider reports funds withdrawn due to that dispute
    Then otherwise valid access is not blocked because of that financial movement

  Scenario: Closed dispute requires its actual outcome to be checked
    Given a dispute-closed notification does not establish whether the dispute was won or lost
    When that observation is handled
    Then it awaits authoritative outcome verification without an assumed access decision

  Scenario: A recovered paid invoice uses the original grant identity
    Given Alice's paid invoice was fulfilled before its notification was lost
    When reconciliation discovers that paid invoice again
    Then no second financial fact or period grant is created

  Scenario: Recovery does not depend on a recent notification lookback
    Given an old refund operation remains unresolved
    And it predates the recent notification search window
    When the outstanding-obligation sweep runs
    Then that refund operation remains eligible for reconciliation

  Scenario: A reconciliation restart does not skip incomplete pages
    Given a coverage sweep stopped before recording completion of its current page
    When reconciliation resumes
    Then unfinished obligations on that page are revisited without duplicating completed effects

  Scenario: Missing provider object does not prove an uncertain refund failed
    Given a refund command has an unknown provider outcome
    When one authoritative lookup cannot find its object
    Then the operation remains pending resolution without another financial refund attempt

  Scenario: Recovered facts retain their actual source
    Given a missing payment notification is recovered through an authenticated provider read
    When that verified fact is recorded
    Then its audit evidence identifies reconciliation rather than a fabricated webhook delivery

  Scenario: Disabling acquisition does not pause reconciliation
    Given Alice has an outstanding authorized payment obligation
    And commercial acquisition is disabled
    When a reconciliation sweep runs
    Then that obligation remains processable

  Scenario: An obsolete notification version cannot change access
    Given a financial notification uses an unsupported delivery version
    When it is durably received
    Then it awaits review without being interpreted as a new access grant

  Scenario: Wrong-account provider objects cannot fulfill an operation
    Given Alice's recorded checkout belongs to the expected provider account
    When reconciliation encounters a payment from a different account
    Then that payment does not fulfill Alice's checkout

  Scenario: Duplicate annual notice triggers do not send another copy
    Given Alice has already received the seven-day notice for her next annual renewal
    When reconciliation and an upcoming-invoice notification schedule that notice again
    Then another copy of that same seven-day notice is not sent

  Scenario: One notice does not suppress the other annual reminder
    Given Alice has received the seven-day notice for her annual renewal
    And renewal remains enabled
    When that renewal is one day away
    Then the distinct one-day notice remains due
