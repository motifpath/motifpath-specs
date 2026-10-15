@wip
Feature: Authoritative offers and one-time acquisition
  Consolidated MOT-117 behavior contracts; runtime implementation remains gated.

  Scenario: Missing configuration disables new sales
    Given no complete approved commercial configuration exists
    When Alice requests acquisition offers
    Then no new purchasable offer is returned

  Scenario: Annual pricing must include a discount
    Given the monthly course offer is 20 BRL
    When an administrator configures an annual offer of 240 BRL for that course
    Then the annual offer is refused because it has no annual discount

  Scenario: An accepted offer keeps its original terms
    Given Alice accepted an immutable path offer for 50 BRL
    When the teacher changes the price to 60 BRL
    Then Alice's accepted checkout remains bound to the 50 BRL offer

  Scenario: A teacher buys a permanent path license without Plus
    Given Bea owns a path and has no student Plus subscription
    And an enabled embedding-license offer exists for that path
    When Bea acquires and successfully pays for that offer
    Then one permanent license for Bea and that path is fulfilled

  Scenario: Purchase success grants permanent independent access
    Given Alice accepted a teacher path purchase offer
    When its payment is authoritatively confirmed and fulfillment completes
    Then one permanent purchase and independent grant are recorded

  Scenario: Browser payment return is not financial evidence
    Given Alice returned from a path checkout success page
    And its payment remains unverified
    When she reads the checkout status
    Then no permanent purchase is fulfilled from the browser return

  Scenario: Concurrent acquisition does not double-charge the same holding
    Given Alice has no permanent purchase for a path
    When she starts concurrent acquisitions of that path with different operation identities
    Then only one open acquisition reservation is accepted for that holding

  Scenario: An existing permanent holding cannot be bought twice
    Given Alice has an active permanent purchase for a path
    When she requests a new purchase of the same path
    Then the new acquisition is refused without initiating another payment

  Scenario: A license is not transferred with a copied path
    Given Bea has a permanent embedding license for her path
    When another teacher copies that path to a distinct path identity
    Then the copied path does not inherit Bea's embedding license

  Scenario: Unsupported marketplace capability prevents taking money
    Given the required teacher settlement capability is unavailable for the merchant account
    When Alice requests a teacher path checkout
    Then new teacher acquisition is refused before charging her

  Scenario: A learner can find the payment identity needed for a refund
    Given Alice successfully paid for a subscription
    When Alice reads her successful payment history
    Then its authoritative payment identity and original amount remain available for support
    And Bob's payments are not disclosed

  Scenario: Historical manifests remain available to existing holders
    Given Alice bought a path using commercial manifest 3
    And the latest commercial manifest is 4
    When Alice reads her authorized purchase manifest after withdrawal
    Then manifest 3 is returned unchanged without updating her learner copy

  Scenario: Concurrent configuration changes cannot silently overwrite each other
    Given two administrators observed commercial configuration revision 2
    When their distinct configuration changes compete for promotion
    Then one revision is promoted and the stale change is refused with attributable evidence
