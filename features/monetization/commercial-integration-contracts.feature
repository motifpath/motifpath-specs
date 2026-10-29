@wip
Feature: CMS, protected delivery and durable commercial recovery
  Consolidated MOT-117 behavior contracts; runtime implementation remains gated.

  Scenario: CMS hints converge through current authoritative reads
    Given a registered CMS document maps to a core path
    When an authenticated duplicate editorial change hint arrives
    Then its original receipt is reused and current allowlisted metadata is synchronized once

  Scenario: Reordered CMS hints cannot regress presentation
    Given newer CMS metadata was already synchronized
    When an older change hint arrives
    Then synchronization reads current source metadata instead of overwriting from the old hint

  Scenario: CMS cannot assign paid rights
    Given a CMS payload claims Alice owns a purchase of path "Guitar foundations"
    When the CMS integration validates that payload
    Then no purchase or commercial access is created from that claim

  Scenario: A missing CMS mapping is quarantined
    Given a CMS document has no registered core identity mapping
    When its change hint is received
    Then synchronization records a mapping problem without inventing ownership or content identity

  Scenario: CMS outage preserves existing paid access
    Given Alice has a valid permanent purchase
    And the CMS is unavailable
    When Alice requests her purchased lesson
    Then the existing authoritative grant remains usable without making unrelated paid content free

  Scenario: An unauthenticated CMS hint cannot enqueue trusted work
    Given a CMS change hint has no valid environment credential
    When it reaches the synchronization boundary
    Then it is refused without creating trusted synchronization work

  Scenario: Audit failure prevents a free-to-paid mutation
    Given durable audit evidence cannot be committed
    When Bea changes a free path to paid
    Then neither the commercial change nor its outgoing work is committed

  Scenario: Provider success before response loss is recovered
    Given a durable checkout operation exists
    And the provider captured payment before its response was lost
    When the worker restarts
    Then it reconciles that payment through the existing operation without a new charge

  Scenario: Different events about one payment cannot duplicate its effects
    Given a verified payment already fulfilled a path purchase
    When a distinct provider event reports the same financial payment
    Then no second payment journal or purchase grant is created

  Scenario: Replay after raw payload expiry remains safe
    Given a successful payment's raw notification expired under retention policy
    And its redacted effect identity remains durable
    When that provider payment is observed again
    Then no second journal, grant or settlement allocation is created

  Scenario: Private financial messages are not learning events
    Given a private payment.verified message exists
    When a caller submits it through the learning-event boundary
    Then it is refused as an unsupported learning event

  Scenario: Public media origin cannot bypass access
    Given Alice has no valid grant for a protected lesson
    When she requests the private media origin directly
    Then no protected lesson bytes are delivered

  Scenario: Range requests enforce current rights
    Given Alice's only payment grant was successfully refunded
    When she requests a later byte range of that lesson video
    Then the delivery boundary refuses that new protected request

  Scenario: An outline never leaks protected lesson content
    Given Alice can see a blocked lesson in her path outline
    When she reads the outline and catalog presentation
    Then protected lesson payloads and usable media destinations are absent

  Scenario: Restored workers remain fenced until reconciliation
    Given commercial records were restored from a backup
    When the restored environment starts
    Then outbound financial workers remain fenced until evidence integrity and provider obligations are reconciled

  Scenario: Failed annual notice remains attributable
    Given an annual renewal notice cannot be delivered before its renewal instant
    When the renewal instant arrives
    Then the missed notice and support alert are recorded without a late duplicate notice
