@wip
Feature: Teacher commercial rights and retained purchases
  Teacher creation tools remain free, licenses are permanent per path,
  and existing buyers retain content when new sales are withdrawn.
  # MOT-117; ADR-059. Consolidated contracts define license coverage and immutable commercial manifests.

  Scenario: Teacher creation tools do not require a paid teacher subscription
    Given Bea is a teacher without a paid subscription
    When Bea creates a path draft
    Then she can use the creation tools without buying a subscription

  Scenario: A configured teacher price limit is enforced
    Given the configured teacher-path price range is 10 to 500 BRL
    When Bea sets a paid path price to 5 BRL
    Then that price is refused

  Scenario: A valid configured teacher price is accepted
    Given the configured teacher-path price range is 10 to 500 BRL
    When Bea sets a paid path price to 50 BRL
    Then the price passes the configured range check

  Scenario: A teacher embedding license remains valid over time
    Given Bea holds a permanent premium embedding license for path "Guitar foundations"
    When a year passes without another license payment
    Then that license does not expire merely because time passed

  Scenario: A license for one path does not authorize another
    Given Bea holds an embedding license only for path "Guitar foundations"
    When Bea tries to sell path "Jazz foundations" embedding platform premium exercises
    Then the operation is refused for lack of that path's embedding license

  Scenario: Student Plus does not replace a teacher embedding license
    Given Bea has a student Plus subscription but no commercial embedding license
    When Bea tries to sell a path embedding platform premium exercises
    Then the operation is refused for lack of a commercial embedding license

  Scenario: Permanent purchases survive teacher subscription cancellation
    Given Alice permanently purchased Bea's path "Guitar foundations"
    When Bea's paid subscription ends
    Then Alice's purchased path remains accessible

  Scenario: Course withdrawal preserves the buyer's last published copy
    Given Alice permanently purchased course "First chords"
    And her accessible copy uses published course revision 3
    When that course is withdrawn from new sales
    Then Alice can still access that retained published copy including unfinished lessons

  Scenario: Path withdrawal preserves the buyer's existing copy
    Given Alice permanently purchased path "Guitar foundations"
    When that path is withdrawn from new sales
    Then Alice retains access to her existing path copy including unfinished lessons

  Scenario: A free update waits for the buyer to request it
    Given Alice has a purchased course copy eligible for the existing learner update process
    When a newer course revision becomes available
    Then her copy is unchanged until she requests the update

  Scenario: A requested update does not charge the buyer again
    Given a free update is available for Alice's purchased path through the existing learner update process
    When Alice requests that update
    Then no additional purchase charge is created

  Scenario: A requested update preserves the existing progress rules
    Given Alice completed lesson "First chord" in her purchased course
    And her course copy is eligible for a free update
    When Alice requests the update through the existing learner update process
    Then her completion of "First chord" remains recorded

  Scenario: Configured commission shares determine the sale allocation
    Given a sale of 100 BRL has a configured platform commission of 20 percent
    And payment processing costs are recorded separately
    When that sale's commission is allocated
    Then the platform commission is recorded as 20 BRL

  Scenario: Available teacher earnings are not subject to a voluntary reserve
    Given a teacher's earnings are available for payout under the payment provider's settlement rules
    When a payout is prepared
    Then no voluntary platform reserve is withheld from those earnings

  Scenario: A refund after teacher payout is recovered from future earnings
    Given Bea already received earnings from a sale that is later refunded
    And a recoverable adjustment is recorded against her future earnings
    When Bea earns proceeds from another sale
    Then the outstanding adjustment is applied to those future earnings

  Scenario: MotifPath bears refund loss that future earnings cannot recover
    Given a refunded teacher sale was already paid out
    And the teacher has no future earnings from which to recover it
    When the unrecovered refund loss is accounted for
    Then MotifPath bears that loss
