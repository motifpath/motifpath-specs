@wip
Feature: Resolve commercial lesson access in a learner's copy
  Commercial rights are evaluated together without changing progress or copied content.
  An access indication does not bypass the existing learning prerequisites.

  Scenario: The platform subscription covers a lesson in a MotifPath course
    Given Alice holds a copy of MotifPath-owned course "First chords"
    And she has a paid platform subscription
    When Alice checks commercial access to a lesson in that copy
    Then the result allows commercial access through the paid subscription

  Scenario: The platform subscription does not cover a teacher-priced path
    Given Alice has a paid platform subscription
    And an unfinished lesson belongs to her copy of Bea's paid path "Jazz foundations"
    And Alice has not bought "Jazz foundations"
    When Alice checks commercial access to that lesson
    Then commercial access is blocked for lack of a valid grant

  Scenario: A purchase covers the premium exercises its path embeds
    Given Bea's paid path "Guitar foundations" embeds platform premium exercise "Shell voicings"
    And Alice bought "Guitar foundations" and has no platform subscription
    When Alice checks commercial access to "Shell voicings" in her copy of that path
    Then the result allows commercial access through the path purchase

  Scenario: A purchase does not cover the same premium exercise elsewhere
    Given Alice bought Bea's path "Guitar foundations", which embeds premium exercise "Shell voicings"
    And Alice has no platform subscription
    When Alice checks commercial access to "Shell voicings" in her copy of another path
    Then commercial access is blocked for lack of a valid grant

  Scenario: A premium exercise in a free teacher path needs the platform subscription
    Given Bea's free path "Open strings" embeds platform premium exercise "Shell voicings"
    And Alice has no platform subscription
    When Alice checks commercial access to "Shell voicings" in her copy of that path
    Then commercial access is blocked for lack of a valid grant

  Scenario: The platform subscription covers a premium exercise in a free teacher path
    Given Bea's free path "Open strings" embeds platform premium exercise "Shell voicings"
    And Alice has a paid platform subscription
    When Alice checks commercial access to "Shell voicings" in her copy of that path
    Then the result allows commercial access through the paid subscription

  Scenario: Cancelling renewal preserves the paid grant
    Given Alice cancelled renewal but her current paid period has not ended
    When Alice checks commercial access to a lesson covered by that period
    Then the paid subscription still permits commercial access

  Scenario: Unpaid renewal grace permits unfinished lessons
    Given Alice's paid period ended six days ago with a failed renewal
    And its seven-day renewal grace is still active
    When Alice checks commercial access to an unfinished covered lesson
    Then renewal grace permits commercial access

  Scenario: Grace expiry blocks an unfinished lesson without another right
    Given Alice's unpaid renewal grace has ended
    And an unfinished restricted lesson has no independent valid grant
    When Alice checks commercial access to that lesson
    Then commercial access is blocked
    And its outline and recorded progress remain intact

  Scenario: Expiry retains access to a completed lesson
    Given Alice completed a lesson during a paid subscription that later expired
    And its payment has not been successfully refunded
    When Alice checks commercial access to that lesson
    Then completed-lesson retention permits commercial access

  Scenario: Refund does not remove an independent permanent purchase
    Given Alice has a subscription and a permanent purchase covering a lesson
    And the subscription payment was successfully refunded
    When Alice checks commercial access to that lesson
    Then her independent permanent purchase permits commercial access

  Scenario: Completion alone cannot revive a refunded grant
    Given Alice completed a lesson using her only payment-linked grant
    And that payment has been successfully refunded
    And she has no independent right to the restricted lesson
    When Alice checks commercial access to that lesson
    Then commercial access is blocked without deleting her completion history

  Scenario Outline: Pending financial cases preserve otherwise valid access
    Given Alice has a valid paid grant for a restricted lesson
    And its payment has a "<case>" awaiting resolution
    When Alice checks commercial access to that lesson
    Then that pending case does not remove the valid grant

    Examples:
      | case    |
      | refund  |
      | dispute |

  Scenario: A pending dispute does not extend an expired grant
    Given Alice's subscription and renewal grace have ended
    And its payment dispute is still pending
    And an unfinished restricted lesson has no independent valid grant
    When Alice checks commercial access to that lesson
    Then commercial access is blocked due to expiry

  Scenario: Acquisition rollback preserves existing rights
    Given new subscription acquisition is disabled
    And Alice has an existing valid permanent purchase
    When Alice checks commercial access to a lesson in her purchased copy
    Then the permanent purchase still permits commercial access

  Scenario: Another learner's copy remains private
    Given Alice knows the identity of Bob's learner copy
    When Alice checks commercial access to a lesson using Bob's copy
    Then the copy is reported as unavailable to her
    And Bob's commercial state is not disclosed

  Scenario: A lesson outside the copy is not evaluated using that copy
    Given a restricted lesson is not a member of Alice's selected learner copy
    When Alice checks commercial access to that lesson using the selected copy
    Then that lesson is reported as unavailable in the selected copy

  Scenario: Commercial permission does not unlock learning prerequisites
    Given Alice has a valid paid grant for a lesson whose prerequisites are unfinished
    When Alice checks commercial access to that lesson
    Then commercial access is allowed
    And the existing prerequisite restriction remains unchanged

  Scenario: Missing authoritative evidence is not a denial or permission
    Given the required authoritative commercial state cannot be read
    When Alice checks commercial access to a restricted lesson
    Then the result reports evaluation unavailable
    And it does not claim commercial permission or lack of a valid grant

  Scenario: Checking access preserves the learner's copy
    Given a newer template is available for Alice's learner copy
    When Alice checks commercial access to a lesson in her existing copy
    Then no update is applied to her copy
    And the decision identifies its evidence and applicable policy revision

  Scenario: A prior decision cannot authorize later delivery
    Given Alice previously received commercial permission for a restricted lesson
    And the payment supporting her only grant has since been successfully refunded
    When Alice requests the protected lesson using the prior decision identity
    Then current rights are enforced rather than the prior permission
