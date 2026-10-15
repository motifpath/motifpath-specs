@wip
Feature: Asynchronous audit archival and bounded recent evidence retention
  Commercial evidence is captured durably before independent archival.
  Expiry of the recent copy never destroys unarchived evidence or business identity.

  Scenario: Export does not delay the commercial response
    Given Bea makes an authorized free-to-paid change
    And the independent archive is temporarily unavailable
    When the change and its evidence are durably committed
    Then the change can complete with durable pending export work
    And no synchronous archive response is required

  Scenario: A rolled-back commercial change has no outgoing export
    Given a free-to-paid change cannot commit its audit evidence
    When the attempted change rolls back
    Then neither its commercial effect nor export work is committed

  Scenario: Evidence is archived in the next scheduled hourly batch
    Given a commercial audit entry was committed at "2026-10-15T12:00:00Z"
    And the independent archive is healthy
    When the next scheduled hourly export runs
    Then it exports and verifies that entry in the hourly batch

  Scenario: A recent copy expires at the exact thirty-day boundary
    Given evidence was recorded at "2026-10-01T12:00:00Z"
    And its exact archive membership and protection are verified with no hold
    When the cleanup sweep runs at "2026-10-31T12:00:00Z"
    Then the recent copy is eligible for deletion while the archive remains readable

  Scenario: A recent copy is retained before its deadline
    Given evidence was recorded at "2026-10-01T12:00:00Z"
    And its exact archive membership is verified
    When cleanup runs at "2026-10-31T11:59:59Z"
    Then the recent copy remains available

  Scenario: Reads and retries cannot extend the retention clock
    Given evidence was recorded at "2026-10-01T12:00:00Z"
    When that entry is inspected and its export is retried on "2026-10-30T12:00:00Z"
    Then its recent-copy deadline remains "2026-10-31T12:00:00Z"

  Scenario: An expired copy cannot be removed before verified archival
    Given a recent audit entry is older than thirty days
    And its export is still pending
    When cleanup runs
    Then the original evidence remains and the export backlog is observable

  Scenario: Upload acknowledgement alone cannot permit deletion
    Given an audit batch upload was acknowledged
    And its checksum, exact membership or retention protection is not verified
    When cleanup considers an expired member
    Then the member is retained pending archive verification

  Scenario: A crash after upload reuses the original batch
    Given an export batch reached the archive before its local acknowledgement was lost
    When a new worker resumes the expired export lease
    Then it reconciles the same batch identity and immutable member set
    And no second visible audit entry is created

  Scenario: A retention hold prevents recent-copy deletion
    Given an expired audit entry has a verified archive
    And an active hold covers that evidence
    When cleanup runs
    Then the recent copy remains until the hold is released

  Scenario: A concurrent hold cannot be bypassed by cleanup
    Given cleanup selected an expired archived entry
    When a hold becomes active before deletion commits
    Then cleanup retains that evidence rather than using its earlier hold check

  Scenario: An unavailable archive proof suspends cleanup
    Given an expired entry was previously marked archived
    And its required archive protection cannot currently be verified
    When cleanup runs
    Then the entry remains pending verified deletion

  Scenario: Missing historical evidence is never reported as an empty history
    Given matching historical evidence has left the recent store
    And its required archive cannot be read
    When an administrator inspects that history
    Then the result reports evidence unavailable rather than empty or partial history

  Scenario: Cleanup during pagination cannot lose evidence
    Given an administrator is traversing a snapshot containing a recent audit entry
    When that entry is archived and its expired recent copy is deleted
    Then the snapshot still returns that evidence exactly once

  Scenario: Audit expiry does not remove financial deduplication
    Given a payment's recent audit copy has expired and was safely removed
    When that payment is observed again through provider reconciliation
    Then its durable financial identity prevents a second payment or grant
    And its archived audit history remains traceable

  Scenario: Archival continues while acquisition is disabled
    Given new commercial acquisition is disabled
    When committed evidence awaits asynchronous export
    Then archival and safe cleanup continue independently of acquisition

  Scenario: A growing archive backlog raises an alert
    Given the oldest unverified audit entry is more than two hours old
    When archival monitoring evaluates the backlog
    Then an alert identifies the delayed evidence without exposing its sensitive payload

  Scenario: Restored export metadata is reconciled before cleanup resumes
    Given a backup restored recent evidence and export catalog state
    When the restored service starts
    Then cleanup remains fenced until exact archive proofs and holds are reconciled

  Scenario: An empty hourly sweep does not create archive objects
    Given no committed audit evidence awaits archival
    When the scheduled hourly export runs
    Then no empty archive object is uploaded
