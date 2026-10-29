@wip
Feature: Financial journal, refunds, disputes and settlement
  Consolidated MOT-117 behavior contracts; runtime implementation remains gated.

  Scenario: Refund eligibility includes the exact deadline
    Given Alice first paid for her platform subscription at "2026-10-01T10:00:00Z"
    And usable access first became available at "2026-10-01T12:00:00Z"
    When her refund request is durably received at "2026-10-08T12:00:00Z"
    Then it is commercially eligible at the inclusive 168-hour deadline

  Scenario: A request after the deadline requires review
    Given Alice's commercial refund deadline is "2026-10-08T12:00:00Z"
    When her request is durably received at "2026-10-08T12:00:01Z"
    Then the request remains recorded for administrator review rather than automatic eligibility

  Scenario: An approved statutory review permits full execution
    Given Alice has a refund case requiring review
    When an administrator approves a full refund with documented statutory basis and current revision
    Then the case becomes approved for full execution without claiming the money has already returned

  Scenario: A declined review preserves the case
    Given Alice has a refund case requiring review
    When an administrator declines it with recorded evidence
    Then the case and original request remain visible without a financial refund

  Scenario: Partial refund requests are not executed as full refunds
    Given an administrator reviews a request for a partial refund
    When the administrator considers automatic refund execution
    Then no partial amount is silently submitted through the full-refund command

  Scenario: A definitively failed refund may be retried safely
    Given a refund execution definitively failed
    And authoritative reconciliation proves no successful or pending financial return exists
    When an administrator retries the case at its current revision
    Then a new attributable attempt retains the same case and original execution history

  Scenario: An uncertain refund cannot be retried as failed
    Given a provider refund result is still unknown after a timeout
    When an administrator attempts failed-case retry with a new operation identity
    Then the retry is refused pending reconciliation

  Scenario: A won dispute preserves only remaining valid access
    Given Alice's paid period and grace have expired while a dispute is open
    When a verified final won decision is reconciled
    Then no new paid period or grant is created by that outcome

  Scenario: A lost dispute ends only its payment grant
    Given Alice has a paid subscription grant and a separate permanent purchase covering a lesson
    When a verified final lost dispute is recorded for the subscription payment
    Then that payment grant ends immediately and the permanent purchase remains valid

  Scenario: Old dispute updates do not revive a lost grant
    Given a verified final lost dispute already ended its payment grant
    When an older pending dispute notification is replayed
    Then that grant remains ended and its final outcome evidence remains intact

  Scenario: Commission rounding preserves exact allocation
    Given a 101-minor-unit sale has a platform commission of 2500 basis points and no sale fee
    When the sale allocation is posted
    Then platform commission is 25 minor units and teacher earnings are 76 minor units

  Scenario: Half-unit commission rounds upward
    Given a 102-minor-unit sale has a platform commission of 2500 basis points and no sale fee
    When the sale allocation is posted
    Then platform commission is 26 minor units and teacher earnings are 76 minor units

  Scenario: Unbalanced financial postings cannot commit
    Given a journal proposes 100 BRL of debits and 99 BRL of credits
    When that journal is submitted for posting
    Then the journal and its related commercial state change are refused

  Scenario: Available earnings are settled without a voluntary reserve
    Given Bea has settled available earnings and a verified connected account
    And no recovery offset is due
    When the next five-minute settlement sweep runs
    Then those available earnings become a settlement obligation without a voluntary reserve

  Scenario: Transfer success is distinct from bank payout
    Given Bea's settlement transfer succeeded
    And its connected-account bank payout remains pending
    When Bea reads settlement history
    Then the transfer is recorded without claiming a completed bank payout

  Scenario: Refund recovery cannot exceed original teacher earnings
    Given Bea received 76 BRL in earnings from a sale that is later fully refunded
    When recovery is allocated against her future earnings
    Then no more than the original 76 BRL earnings are recovered for that sale

  Scenario: Provider refund fees do not reduce the customer return
    Given Alice paid 100 BRL and the provider charges an additional refund fee
    When her approved full refund succeeds
    Then Alice receives 100 BRL and MotifPath records the refund fee separately

  Scenario: Unknown transfer outcomes cannot create another transfer
    Given a teacher transfer timed out after submission
    When the settlement sweep resumes
    Then it reconciles the existing transfer before any further financial attempt
