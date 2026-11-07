@wip
Feature: Reconstruct commercial operations from immutable evidence
  Financial operations and indirect commercial changes must remain attributable.
  Administrators inspect evidence without changing commercial state or history.

  Scenario: Trace a free-to-paid content change
    Given an administrator changed course "Harmony" from free to paid
    When an administrator inspects the commercial history of course "Harmony"
    Then the change identifies the initiating administrator and reason
    And it includes the prior free state and resulting paid offer revision
    And it identifies the operation, attempt, environment and applicable policy revisions

  Scenario: Repeated commands retain attempts without duplicating effects
    Given a free-to-paid change has already been applied
    And the same logical command was submitted again with identical intent
    When an administrator inspects that operation's evidence
    Then the original applied attempt and the duplicate attempt are both visible
    And they identify one logical operation and distinct attempts
    And there is only one resulting free-to-paid transition

  Scenario Outline: Unsuccessful attempts remain attributable
    Given a commercial attempt ended with outcome "<outcome>"
    When an administrator inspects its operation's evidence
    Then its trusted actor, resource, reason and outcome remain visible
    And the evidence does not claim an unverified commercial effect

    Examples:
      | outcome   |
      | failed    |
      | denied    |
      | uncertain |

  Scenario: Follow asynchronous effects back to their cause
    Given a verified payment produced a subscription grant through a background operation
    When an administrator inspects the grant's commercial evidence
    Then it identifies the preceding payment evidence by immutable entry identity
    And the causal chain identifies the initiating checkout actor

  Scenario: Corrections preserve original evidence
    Given an incorrect commercial adjustment has recorded evidence
    When an authorized compensating adjustment corrects it
    Then the original evidence is unchanged
    And a new entry links the correction to the original adjustment

  Scenario: Customers cannot inspect administrator audit records
    Given an authenticated customer without administrator permission
    When the customer requests commercial audit evidence
    Then access is refused without disclosing matching records

  Scenario: Audit records exclude sensitive payment data
    Given a provider notification contains payment instrument data and commercial references
    When an administrator reads the resulting commercial evidence
    Then safe transaction references are available
    And payment instrument data, credentials and the raw notification are absent

  Scenario: Appends do not shift an existing traversal
    Given an administrator has received the first page of a commercial history snapshot
    And new commercial evidence is appended
    When the administrator continues that snapshot to its end
    Then each matching snapshot entry appears exactly once in stable order
    And later entries require a new traversal

  Scenario: A continuation cannot change its evidence scope
    Given an administrator has a continuation for course "Harmony"
    When the administrator uses it to request course "Rhythm"
    Then the continuation is refused

  Scenario: Reused UUIDs in distinct namespaces remain distinguishable
    Given two trusted actors used the same operation UUID for different commercial resources
    When an administrator filters commercial evidence by that UUID
    Then both operations remain distinguishable by actor, action, resource and environment
    And each evidence entry has its own immutable identity

  Scenario: A read creates attributable access evidence
    Given an administrator inspects a commercial history snapshot
    When the inspection is recorded
    Then the access evidence identifies the administrator and requested scope
    And that new entry is outside the inspected snapshot

  Scenario: An empty history is different from unavailable evidence
    Given authoritative audit storage is available
    And no evidence matches the requested commercial resource
    When an administrator inspects its commercial history
    Then the result is an empty completed traversal

  Scenario: Evidence failure cannot masquerade as an empty history
    Given authoritative audit storage is unavailable
    When an administrator inspects a commercial history
    Then the inspection reports that evidence is unavailable
    And it does not return an apparently empty history
