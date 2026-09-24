@wip
Feature: User display names stay current and appear wherever a user is referenced
  As a MotifPath user
  I want to see the real, current name of the people behind the content and paths I work with
  So that I can recognise a teacher, an author or a student without deciphering an id

  # ADR-035: a user's name is held once, in their user record, and read from the
  # "name" claim of their Clerk session token. Every response that points at a
  # user carries a UserRef {user_id, display_name}, whose name is read from the
  # user record when the response is built — so a rename shows everywhere at once.

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "bob" is authenticated as a teacher
    And "bob" is named "Bob Ferreira"
    And "alice" is authenticated as a student
    And "alice" is named "Alice Martins"

  # ── Keeping the name current ───────────────────────────────────────────────

  Scenario: A name changed in Clerk is stored on the user's next request
    Given "bob" is now named "Bob Ferreira Lima"
    When "bob" requests their own profile
    Then the response includes the display name "Bob Ferreira Lima"

  Scenario: An identity token without a name leaves the stored name unchanged
    Given the identity token of "bob" now carries no name
    When "bob" requests their own profile
    Then the response includes the display name "Bob Ferreira"

  Scenario: A blank name in the identity token leaves the stored name unchanged
    Given "bob" is now named "   "
    When "bob" requests their own profile
    Then the response includes the display name "Bob Ferreira"

  Scenario: A renamed author's new name appears on content they created before the rename
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "bob" is now named "Bob Ferreira Lima"
    And "bob" requests their own profile
    When "alice" lists the course catalog
    Then catalog entry "fingerstyle-journey" names its creator as "bob", "Bob Ferreira Lima"

  # ── Every user reference carries the user's id and current name ────────────

  Scenario: A course catalog entry names its creator
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    When "alice" lists the course catalog
    Then catalog entry "fingerstyle-journey" names its creator as "bob", "Bob Ferreira"

  Scenario: A course names its creator
    Given a course "fingerstyle-journey" exists as a draft, created by "bob", with checkpoints "open-chords-path"
    When "bob" retrieves course "fingerstyle-journey"
    Then the course names its creator as "bob", "Bob Ferreira"

  Scenario: A content node names its teacher
    Given content node "node-02" exists, created by "bob"
    When "bob" retrieves the content node "node-02"
    Then the content node names its teacher as "bob", "Bob Ferreira"

  Scenario: A learning path names its teacher
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03", created by "bob"
    When "bob" retrieves the learning path "beginner-guitar-path"
    Then the learning path names its teacher as "bob", "Bob Ferreira"

  Scenario: A diagram names its creator
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    When "bob" retrieves diagram "bobs-pentatonic"
    Then the diagram names its creator as "bob", "Bob Ferreira"

  Scenario: An assigned student path names its student and the teacher who assigned it
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03", created by "bob"
    When "bob" assigns "beginner-guitar-path" to student "alice"
    Then the student path names its student as "alice", "Alice Martins"
    And the student path names its assigner as "bob", "Bob Ferreira"

  Scenario: A student sees who assigned each of their standalone paths
    Given a learning path "beginner-guitar-path" exists with items "node-01", "node-02", "node-03", created by "bob"
    And "bob" assigns "beginner-guitar-path" to student "alice"
    When "alice" lists their standalone paths
    Then standalone path "beginner-guitar-path" names its assigner as "bob", "Bob Ferreira"

  Scenario: A course enrollment names its student
    Given a course "fingerstyle-journey" exists, published, created by "bob", with checkpoints "open-chords-path"
    And "alice" enrolls in course "fingerstyle-journey"
    When "alice" lists her course enrollments
    Then enrollment "fingerstyle-journey" names its student as "alice", "Alice Martins"
