Feature: Event Ingestion Service health and readiness
  As the EKS cluster
  I want to probe the Event Ingestion Service for liveness and readiness
  So that traffic is only routed to healthy instances

  # ── Liveness ───────────────────────────────────────────────────────────────

  Scenario: Liveness probe confirms the service process is running
    Given the Event Ingestion Service process is running
    When the liveness probe is checked
    Then the service reports itself as alive

  # ── Readiness ──────────────────────────────────────────────────────────────

  Scenario: Readiness probe confirms the service is ready when all dependencies are connected
    Given the Event Ingestion Service has an active MongoDB connection
    And the Kafka producer is initialised and connected to the broker
    When the readiness probe is checked
    Then the service reports itself as ready
    And all dependency checks report "ok"

  Scenario: Readiness probe reports not ready when MongoDB is unavailable
    Given the MongoDB connection is unavailable
    And the Kafka producer is initialised and connected to the broker
    When the readiness probe is checked
    Then the service reports itself as not ready
    And the "mongodb" dependency check reports "fail"

  Scenario: Readiness probe reports not ready when the Kafka producer is not yet initialised
    Given the Event Ingestion Service has an active MongoDB connection
    And the Kafka producer has not yet completed initialisation
    When the readiness probe is checked
    Then the service reports itself as not ready
    And the "kafka_producer" dependency check reports "fail"
