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

  Scenario: A premium-containing draft can acquire its first license
    Given Bea owns a draft path already containing a platform premium exercise
    And that path has no embedding license or validated sale manifest
    When an administrator creates a configured license offer for Bea's current path ownership
    Then Bea can start that license acquisition without a pre-existing licensed manifest

  Scenario: Creating a license offer does not authorize a path sale
    Given Bea has an unpaid embedding-license offer for her path
    And the path embeds a platform premium exercise without another license
    When Bea requests paid availability for that path
    Then paid availability is refused until a license is fulfilled and the dependency graph is validated

  Scenario: First-license fulfillment permits later sale validation
    Given Bea paid for an ownership-bound embedding-license offer without a sale manifest
    When its verified payment fulfills the permanent teacher-path license
    Then that license can be used to validate a subsequent commercial sale manifest

  Scenario: A license offer cannot follow an ownership change
    Given Bea's license offer binds her path ownership revision 1
    And a reviewed ownership correction changed the path to another teacher at revision 2
    When Bea starts a new acquisition using her old offer
    Then the stale ownership-bound offer is refused before a charge is initiated

  Scenario: A stale subscription price edit cannot replace a newer offer
    Given two administrators observed the same promoted monthly offer for course "First chords"
    And the first administrator replaced it with a new offer
    When the second administrator submits a different price using the original observed offer identity
    Then the second promotion is refused and the first replacement remains current

  Scenario: Concurrent first subscription offers cannot both become current
    Given no monthly offer exists for course "First chords" in BRL
    When two administrators create different first offers each explicitly observing no current offer
    Then one offer becomes current and the competing creation is refused

  Scenario: A subscription price replay returns its original replacement
    Given an administrator replaced an observed offer through a durable operation
    And that original offer is no longer current
    When the administrator repeats the same operation and intent
    Then the original replacement is returned without another offer promotion

  Scenario: Admin current-offer reads remain available during acquisition rollback
    Given a monthly subscription offer is promoted for course "First chords"
    And new subscription acquisition is disabled
    When an administrator reads its current offer before changing its price
    Then the promoted offer identity remains available as the replacement precondition
