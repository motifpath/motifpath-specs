@wip
Feature: Teacher selling terms, sales, payout account and sale blockers
  What a teacher reads and does to sell their own courses and paths. MotifPath keeps one
  commission and the teacher buys nothing first; buyers never lose what they bought.
  # MOT-130 (Figma "Teacher sales r1"); ADR-067, ADR-059. Runtime: MOT-131, MOT-133.

  Scenario: A teacher reads the current selling terms
    Given the current configuration sets teacher prices from 10 to 500 BRL
    And a platform commission of 2000 basis points
    When Bea reads her selling terms
    Then she sees the price range, the commission and her share of payment fees
    And she does not see the configuration reason or its history

  Scenario: Selling terms are not available before configuration
    Given no commercial configuration has been promoted
    When Bea reads her selling terms
    Then the terms are not found and new sales stay disabled

  Scenario: A student cannot read teacher selling terms
    Given Alice is a student
    When Alice reads teacher selling terms
    Then the request is forbidden

  Scenario: A teacher lists her own sales without buyer details
    Given Alice bought Bea's path "Blues shuffle"
    When Bea lists her sales
    Then she sees that sale with its price, her earnings and its status
    And the sale does not identify Alice or her payment method

  Scenario: A refunded sale stays listed as refunded
    Given Bea's sale of "Blues shuffle" was fully refunded
    When Bea lists her sales
    Then that sale is listed as refunded with the time of the refund

  Scenario: A teacher cannot list another teacher's sales
    Given Carl sold his path "Funk rhythm"
    When Bea lists her sales
    Then "Funk rhythm" is not listed

  Scenario: A new teacher has no payout account yet
    Given Bea has never set up payouts
    When Bea reads her payout account
    Then its status is not started

  Scenario: Payout onboarding happens on the provider's page
    Given Bea has never set up payouts
    When Bea asks for a payout onboarding link
    Then she receives a short-lived link to the provider-hosted onboarding
    And MotifPath never receives her bank details

  Scenario: A returning teacher stays checking until the provider verifies her
    Given Bea finished the provider-hosted onboarding
    And the provider has not yet verified her account
    When Bea reads her payout account
    Then its status is checking

  Scenario: Payout onboarding paused does not hide existing earnings
    Given teacher_settlement is OFF
    And Bea has available earnings from earlier sales
    When Bea asks for a payout onboarding link
    Then the request is refused
    And her balances and settlement history remain readable

  Scenario: A teacher cannot sell content that is not published
    Given Bea's path "Blues shuffle" has never been published by an admin
    When Bea changes its sale state to paid
    Then the change is refused
    And the content lists the blocker "unpublished"

  Scenario: A teacher needs a verified payout account to sell
    Given Bea's published path "Blues shuffle" passes commercial validation
    And Bea's payout account is checking
    When Bea changes its sale state to paid
    Then the change is refused
    And the content lists the blocker "payout_account_not_verified"

  Scenario: Each dependency that cannot be resold is listed
    Given Bea's path embeds a lesson whose exercise Bea has no right to resell
    When Bea reads the path's commercial state
    Then the blockers name that exercise with the code "dependency_rights"
    And no license or purchase is offered as a way to resolve it

  Scenario: Paused new sales are visible without changing existing rights
    Given Bea's path "Blues shuffle" is on sale
    And Alice permanently purchased it
    When teacher_paid_paths is turned OFF
    Then the path's commercial state lists the blocker "new_sales_paused"
    And its sale state remains paid
    And Alice keeps her access

  Scenario: A teacher reads her sales for a chosen period
    Given Bea sold "Blues shuffle" 12 times in October and once in September
    When Bea lists her sales from 1 October to 1 November in her time zone
    Then she sees the 12 October sales
    And the summary counts all 12 sales, not just the page she reads

  Scenario: A refund before transfer leaves nothing to recover
    Given Bea's sale of "Blues shuffle" was refunded before its earnings were transferred
    When Bea lists her sales
    Then that sale shows nothing due, because its earnings were cancelled

  Scenario: A refund after transfer shows what is still to recover
    Given Bea's earnings from a sale of "Blues shuffle" were transferred
    And the sale was then fully refunded
    And a later transfer deducted part of those earnings
    When Bea lists her sales
    Then that sale shows the amount already deducted and the amount still to recover
    And it names the transfer that deducted it

  Scenario: A teacher reads her transfers for a chosen period
    Given Bea received transfers in September and October
    When Bea lists her transfers from 1 October to 1 November
    Then she sees only the October transfers, each with its creation time

  Scenario: A verified teacher manages her payout account on the provider's page
    Given Bea's payout account is verified
    When Bea asks for a payout dashboard link
    Then she receives a short-lived link to the provider-hosted dashboard
    And MotifPath shows none of her bank details

  Scenario: There is no dashboard before payout setup
    Given Bea has never set up payouts
    When Bea asks for a payout dashboard link
    Then the request is refused as a conflict
