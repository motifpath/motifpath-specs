@wip
Feature: Ownership, manifests and commercial dependencies
  Consolidated MOT-117 behavior contracts; runtime implementation remains gated.

  Scenario: Untrusted ownership cannot create commercial rights
    Given Alice authored a path owned by Alice
    When Bob submits a CMS declaration naming himself as its owner
    Then authoritative ownership remains Alice and the rejected attempt is attributable

  Scenario: Admin provenance correction preserves history
    Given a legacy lesson has reviewed evidence identifying its teacher
    When an administrator corrects its ownership with that evidence
    Then the new ownership revision links to the correction and retains the original provenance history

  Scenario: Unresolved legacy attribution prevents a new paid sale
    Given a legacy path has no reviewed rights holder
    When its author requests paid sale availability
    Then paid availability is refused without making existing free progress disappear

  Scenario: Concurrent manifest publication converges
    Given Bea owns a path with a fully validated dependency graph
    When identical commercial release requests arrive concurrently
    Then one immutable commercial manifest is created with attributable attempts

  Scenario: A nested premium dependency needs no teacher purchase
    Given Bea owns a path containing a lesson that embeds a platform premium exercise
    And Bea has bought nothing from MotifPath
    When Bea requests paid availability for that path
    Then the commercial manifest records that exercise as a platform premium dependency
    And paid availability is not refused for lack of a license

  Scenario: Embedded premium exercises add no charge beyond the commission
    Given Bea's paid path embeds a platform premium exercise
    When Alice buys that path
    Then MotifPath keeps the one configured platform commission on that sale
    And no separate premium charge is added to the price or to Bea's earnings

  Scenario: A changed dependency invalidates new-sale validation
    Given a path offer was validated against dependency revision 3
    When an author changes that dependency to revision 4
    Then new acquisitions require revalidation and prior buyers retain their existing rights

  Scenario: A cyclic dependency cannot be sold
    Given a path dependency graph contains a cycle
    When the author requests paid availability
    Then the commercial validation is refused with attributable evidence

  Scenario: Commercial withdrawal does not change path publication
    Given Bea has a published path with an active paid offer
    When Bea withdraws it from new commercial sales
    Then no new purchase is offered and the existing path publishing lifecycle is unchanged

  Scenario: A retained course copy does not update on withdrawal
    Given Alice bought course revision 3 and still holds that copy
    And published course revision 4 exists
    When the course is withdrawn from new sales
    Then Alice retains her existing published copy without an automatic update

  Scenario: Free-to-paid conversion preserves previously granted access
    Given Alice already holds an explicit free grant for a path
    When Bea changes that path from free to paid
    Then Alice retains that grandfathered grant without an unrequested charge
    And new acquisitions require the paid offer
