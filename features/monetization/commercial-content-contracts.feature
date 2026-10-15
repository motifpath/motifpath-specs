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

  Scenario: A nested premium dependency requires a license
    Given Bea owns a path containing a lesson that embeds a platform premium exercise
    And Bea has student Plus but no embedding license for that path
    When Bea requests paid availability for that path
    Then the new paid availability is refused for the unlicensed nested dependency

  Scenario: A permanent path license covers revalidated additions
    Given Bea holds a permanent embedding license for her path
    When she adds a platform premium exercise and requests a new validated commercial manifest
    Then the path license permits that premium dependency after revalidation without a recurring license fee

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

  Scenario: Refunding a teacher license preserves prior buyer obligations
    Given Bea sold a path while holding a valid embedding license
    And Alice permanently bought that path
    When the license payment is successfully refunded
    Then new paid publication requiring that license is blocked while Alice retains her purchased rights

  Scenario: Free-to-paid conversion preserves previously granted access
    Given Alice already holds an explicit free grant for a path
    When Bea changes that path from free to paid
    Then Alice retains that grandfathered grant without an unrequested charge
    And new acquisitions require the paid offer
