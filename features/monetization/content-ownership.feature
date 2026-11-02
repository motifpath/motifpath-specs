@wip
Feature: Record and protect content ownership
  Every course, path, content node and exercise has one authoritative rights holder in core.
  Ownership is recorded when content is created, survives edits and learner copies, and only an
  administrator can correct it. Platform-owned content uses the MotifPath Catalog profile as owner.

  Background:
    Given Ada is an admin
    And Bea is a teacher

  # ── Recording ownership at creation ────────────────────────────────────────

  Scenario: A path an admin creates is owned by the platform
    When Ada creates the path "First chords"
    Then the ownership of "First chords" has owner kind "platform" and the MotifPath Catalog as owner
    And its creator is Ada, its source is "native" and its ownership revision is 1

  Scenario: A path a teacher creates is owned by that teacher
    When Bea creates the path "Jazz foundations"
    Then the ownership of "Jazz foundations" has owner kind "teacher" and Bea as owner
    And its creator is Bea, its source is "native" and its ownership revision is 1

  Scenario: An exercise a teacher creates is owned by that teacher
    When Bea creates the exercise "Shell voicings in C"
    Then the ownership of "Shell voicings in C" has owner kind "teacher" and Bea as owner

  # ── Ownership persists ─────────────────────────────────────────────────────

  Scenario: Editing a path does not change its ownership
    Given Bea created the path "Jazz foundations"
    When Bea renames "Jazz foundations" to "Jazz foundations I" and replaces its items
    Then the ownership of "Jazz foundations I" still has Bea as owner and ownership revision 1

  Scenario: Ownership does not follow a later role change
    Given Bea created the path "Jazz foundations"
    When Bea is promoted to admin
    Then the ownership of "Jazz foundations" still has owner kind "teacher" and Bea as owner

  Scenario: A learner's copy resolves to the template's ownership
    Given Bea created and published the path "Jazz foundations"
    And Carl holds a copy of "Jazz foundations"
    When Bea reads the commercial content of "Jazz foundations"
    Then there is one ownership record for "Jazz foundations" and none for Carl's copy

  # ── Mixed platform and teacher content ─────────────────────────────────────

  Scenario: A teacher path embedding a platform exercise keeps both owners distinct
    Given Ada created the exercise "Open C chord"
    And Bea created the path "Jazz foundations" containing a lesson that embeds "Open C chord"
    When Ada reads the commercial content of "Jazz foundations" and of "Open C chord"
    Then "Jazz foundations" has owner kind "teacher" and "Open C chord" has owner kind "platform"

  # ── Who can read ───────────────────────────────────────────────────────────

  Scenario: Another teacher cannot read a teacher's commercial content
    Given Bea created the path "Jazz foundations"
    And Dan is a teacher
    When Dan reads the commercial content of "Jazz foundations"
    Then the response is 404

  # ── Corrections ────────────────────────────────────────────────────────────

  Scenario: An admin corrects ownership and history is kept
    Given Ada created the path "Guest masterclass"
    When Ada corrects the ownership of "Guest masterclass" to teacher Bea at ownership revision 1 with reason "Bea licensed this content to MotifPath"
    Then the command is applied with an evidence entry
    And the ownership of "Guest masterclass" has owner kind "teacher", Bea as owner and ownership revision 2
    And its creator is still Ada
    And the ownership history of "Guest masterclass" still shows platform ownership at revision 1

  Scenario: The owning teacher cannot transfer ownership
    Given Bea created the path "Jazz foundations"
    And Dan is a teacher
    When Bea corrects the ownership of "Jazz foundations" to teacher Dan at ownership revision 1
    Then the response is 403
    And the ownership of "Jazz foundations" still has Bea as owner and ownership revision 1

  Scenario: A stale ownership revision is refused
    Given Bea created the path "Jazz foundations"
    And Ada has already corrected the ownership of "Jazz foundations" once
    When Ada corrects the ownership of "Jazz foundations" to the platform at ownership revision 1
    Then the response is 409
    And the ownership revision of "Jazz foundations" is still 2

  Scenario: Replaying the same correction returns its original result
    Given Bea created the path "Jazz foundations"
    And Ada corrected the ownership of "Jazz foundations" to the platform with idempotency key K
    When Ada sends the same correction again with idempotency key K
    Then the response repeats the original command result
    And the ownership revision of "Jazz foundations" is still 2

  Scenario: Request fields cannot set ownership when creating content
    When Bea creates the path "Jazz foundations" with an extra field naming the platform as owner
    Then the ownership of "Jazz foundations" has owner kind "teacher" and Bea as owner

  Scenario: Corrections are refused while the rollout is OFF
    Given the content-ownership rollout is OFF
    And Bea created the path "Jazz foundations"
    When Ada corrects the ownership of "Jazz foundations" to the platform at ownership revision 1
    Then the response is 403
    And the ownership of "Jazz foundations" still has Bea as owner and ownership revision 1

  Scenario: Ownership is still recorded while the rollout is OFF
    Given the content-ownership rollout is OFF
    When Bea creates the path "Jazz foundations"
    Then the ownership of "Jazz foundations" has owner kind "teacher" and Bea as owner

  # ── Backfill of existing content ───────────────────────────────────────────

  Scenario: Backfill attributes admin-made content to the platform
    Given a course created by Ada exists without an ownership record
    When the ownership backfill runs
    Then that course has owner kind "platform", the MotifPath Catalog as owner, Ada as creator and source "reviewed_legacy"

  Scenario: Backfill attributes the catalog profile's content to the platform
    Given an exercise created by the MotifPath Catalog profile exists without an ownership record
    When the ownership backfill runs
    Then that exercise has owner kind "platform" and the MotifPath Catalog as owner

  Scenario: Backfill attributes a teacher's content to that teacher
    Given a path whose teacher is Bea exists without an ownership record
    When the ownership backfill runs
    Then that path has owner kind "teacher", Bea as owner and source "reviewed_legacy"

  Scenario: Backfill leaves content without a recorded creator unresolved
    Given an exercise with no recorded creator exists without an ownership record
    When the ownership backfill runs
    Then that exercise has owner kind "unresolved", no owner and no creator
    And learners can still practise that exercise

  Scenario: Rerunning the backfill changes nothing already recorded
    Given the ownership backfill has run
    And Ada has corrected the ownership of one backfilled path to teacher Bea
    When the ownership backfill runs again
    Then no ownership record or evidence entry is added or changed

