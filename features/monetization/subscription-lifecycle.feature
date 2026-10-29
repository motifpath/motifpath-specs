@wip
Feature: Platform subscription and paid-period lifecycle
  One platform subscription covers MotifPath-owned content; it never covers teacher-priced content.
  Cancellation preserves paid-period access; commercial expiry preserves learning history.
  # MOT-117; ADR-059, ADR-067. Stripe is selected; monetary values are configured through approved offer revisions.

  Scenario: Both billing periods are available for the platform subscription
    Given a monthly offer and a discounted annual offer are configured for the platform subscription
    When a learner views platform subscription offers
    Then both configured billing periods and their prices are shown

  Scenario: The platform subscription covers MotifPath-owned content
    Given Alice has a paid platform subscription
    When she opens an unfinished lesson in MotifPath-owned course "First chords"
    Then the lesson is accessible through her subscription

  Scenario: The platform subscription does not cover a teacher-priced path
    Given Alice has a paid platform subscription
    And she has not bought Bea's paid path "Jazz foundations"
    When she opens an unfinished lesson in "Jazz foundations"
    Then that lesson is blocked until she buys the path

  Scenario: Subscribers pay the full teacher price
    Given Alice has a paid platform subscription
    And Bea's path "Jazz foundations" is offered at 50 BRL
    When Alice starts a purchase of "Jazz foundations"
    Then the checkout uses the full 50 BRL offer price without a subscriber discount

  Scenario Outline: Both billing periods renew automatically
    Given Alice has a <period> subscription with automatic renewal enabled
    And its next renewal is due
    When payment for the next period succeeds
    Then Alice has access for the newly paid <period> period
    Examples:
      | period  |
      | monthly |
      | annual  |

  Scenario: Cancellation preserves access through the paid period
    Given Alice's subscription is paid until "2026-12-01T12:00:00Z"
    When Alice cancels renewal on "2026-11-15T12:00:00Z"
    Then her subscription access remains valid until "2026-12-01T12:00:00Z"

  Scenario: A cancelled subscription is not renewed
    Given Alice cancelled renewal before the end of her paid period
    When the next renewal becomes due
    Then no renewal charge is initiated for that subscription

  Scenario: A configured price change waits until renewal
    Given Alice's monthly subscription was paid at 40 BRL
    And its next renewal is due on "2026-12-01T12:00:00Z"
    When the monthly offer price is changed to 45 BRL during her paid period
    Then Alice is not charged an adjustment for the current period

  Scenario: Renewal uses the price applicable at renewal
    Given Alice's subscription renews on "2026-12-01T12:00:00Z"
    And its configured renewal price is 45 BRL
    When the renewal is charged
    Then the renewal amount is 45 BRL

  Scenario Outline: Annual renewal notices precede the renewal
    Given Alice's annual subscription renews on "2027-10-14T12:00:00Z"
    And renewal has not been cancelled
    When the annual renewal is <days> days away
    Then Alice is sent an annual renewal notice
    Examples:
      | days |
      | 7    |
      | 1    |

  Scenario: Failed renewal retains access during the seven-day grace period
    Given Alice's renewal payment failed at the end of her paid period on "2026-12-01T12:00:00Z"
    And that renewal remains unpaid
    When Alice opens an unfinished lesson on "2026-12-07T12:00:00Z"
    Then the lesson remains accessible through the renewal grace period

  Scenario: Unpaid renewal blocks unfinished lessons when grace ends
    Given Alice's renewal failed at the end of her paid period on "2026-12-01T12:00:00Z"
    And that renewal remains unpaid
    When Alice views an unfinished lesson on "2026-12-08T12:00:00Z"
    Then the lesson is visible but blocked unless another valid grant permits access

  Scenario: Subscription expiry preserves completed lesson access
    Given Alice completed lesson "First chord" during her subscription
    And her subscription has expired with no remaining grace period
    When Alice opens "First chord"
    Then the completed lesson remains accessible

  Scenario: Subscription expiry does not remove an independent permanent purchase
    Given Alice permanently purchased path "Guitar foundations"
    And her platform-wide subscription has expired
    When Alice opens an unfinished lesson in her purchased path
    Then the lesson remains accessible through her permanent purchase

  Scenario: Subscription expiry preserves progress
    Given Alice has recorded progress in MotifPath-owned course "First chords"
    When her platform subscription expires
    Then her recorded progress remains intact

  Scenario: Monthly to annual switching waits for the next renewal
    Given Alice's monthly paid period ends on "2026-12-01T12:00:00Z"
    When she requests an annual plan on "2026-11-15T12:00:00Z"
    Then the annual plan is scheduled for "2026-12-01T12:00:00Z" without a mid-period charge or credit

  Scenario: Annual to monthly switching is not offered
    Given Alice has an annual subscription
    When she requests a switch to monthly billing
    Then the switch is refused without changing her paid access

  Scenario: Plus beta does not require teacher commerce beta
    Given Plus rollout prerequisites are satisfied for an approved cohort
    And teacher commerce acquisition remains disabled
    When Plus is enabled for that cohort
    Then eligible cohort members can start Plus subscriptions

  Scenario: Teacher commerce beta has its own readiness gate
    Given teacher commerce rollout prerequisites are satisfied for an approved cohort
    And Plus acquisition remains disabled
    When teacher commerce is enabled for that cohort
    Then eligible cohort members can purchase teacher paths
