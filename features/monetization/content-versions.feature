@MOT-119
Feature: Publish immutable commercial releases
  A commercial release is the evidence of exactly what an owner offered for sale at one moment: the
  item's learner-visible state, its rights holder and every item it depends on. Publishing one never
  changes how learners read content or update their copies, and a release never changes afterwards.

  Background:
    Given Ada is an admin
    And Bea is a teacher

  # ── Publishing a release ───────────────────────────────────────────────────

  Scenario: Releasing a published path records its content, owner and lessons
    Given Bea created and published the path "Jazz foundations" with the lessons "Shells" and "Guide tones"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then "Jazz foundations" has release revision 1 with Bea as the recorded owner
    And the release lists "Shells" and "Guide tones" as dependencies Bea owns
    And the commercial revision of "Jazz foundations" is 2

  Scenario: A release also releases the exercises a lesson contains
    Given Bea created and published the path "Jazz foundations" with the lesson "Shells" containing her exercise "Shell voicings in C"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then "Shells" and "Shell voicings in C" each have release revision 1
    And the release of "Jazz foundations" lists both of those releases

  Scenario: Releasing a course records its published version and its paths
    Given Ada created a course "Guitar from zero" whose published version 2 names the path "First chords"
    When Ada publishes a commercial release of "Guitar from zero" at commercial revision 1
    Then the release of "Guitar from zero" names published version 2
    And the release lists "First chords" as a dependency the platform owns

  # ── Releases never change ──────────────────────────────────────────────────

  Scenario: Editing a released path leaves its release unchanged
    Given Bea released the path "Jazz foundations"
    When Bea renames "Jazz foundations" to "Jazz foundations I"
    Then release revision 1 of "Jazz foundations I" still has the title "Jazz foundations"

  Scenario: Releasing an edited path adds a revision and keeps the earlier one
    Given Bea released the path "Jazz foundations"
    And Bea renamed "Jazz foundations" to "Jazz foundations I"
    When Bea publishes a commercial release of "Jazz foundations I" at commercial revision 2
    Then "Jazz foundations I" has release revision 2 with the title "Jazz foundations I"
    And release revision 1 can still be read with the title "Jazz foundations"

  Scenario: Releasing unchanged content creates no new release
    Given Bea released the path "Jazz foundations"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 2
    Then the response returns release revision 1
    And the commercial revision of "Jazz foundations" is still 2

  Scenario: Concurrent identical releases converge on one release
    Given Bea created and published the path "Jazz foundations"
    When Bea and Ada publish a commercial release of "Jazz foundations" at the same time with different idempotency keys
    Then "Jazz foundations" has exactly one release, revision 1

  Scenario: Replaying the same release request returns its original result
    Given Bea released the path "Jazz foundations" with idempotency key K
    When Bea sends the same release request again with idempotency key K
    Then the response repeats the original command result

  Scenario: A release keeps the owner it recorded after an ownership correction
    Given Ada released the path "Guest masterclass"
    When Ada corrects the ownership of "Guest masterclass" to teacher Bea
    Then release revision 1 of "Guest masterclass" still records the platform as owner
    And Bea can read that release

  Scenario: A release stays readable after its path is deleted
    Given Bea released the path "Jazz foundations"
    And Bea unpublished and deleted "Jazz foundations"
    When Ada reads release revision 1 of "Jazz foundations"
    Then the release is returned unchanged

  # ── Learner copies are not affected ───────────────────────────────────────

  Scenario: Publishing a release does not change a learner's copy
    Given Bea created and published the path "Jazz foundations"
    And Carl holds a copy of "Jazz foundations"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then Carl's copy of "Jazz foundations" is unchanged and has no update available

  # ── Refusals ───────────────────────────────────────────────────────────────

  Scenario: A draft path cannot be released
    Given Bea created the path "Jazz foundations" without publishing it
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then the release is refused because the path is not published
    And "Jazz foundations" has no release

  Scenario: Content with unresolved ownership cannot be released
    Given a published path with no recorded creator exists with unresolved ownership
    When Ada publishes a commercial release of that path at commercial revision 1
    Then the release is refused because the ownership is unresolved

  Scenario: A dependency with another rights holder blocks the release
    Given Ada created the exercise "Open C chord"
    And Bea created and published the path "Jazz foundations" with the lesson "Shells" containing "Open C chord"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then the release is refused naming "Open C chord" as a dependency Bea does not own
    And neither "Jazz foundations", "Shells" nor "Open C chord" has a release

  Scenario: A stale commercial revision is refused
    Given Bea released the path "Jazz foundations"
    And Bea renamed "Jazz foundations" to "Jazz foundations I"
    When Bea publishes a commercial release of "Jazz foundations I" at commercial revision 1
    Then the response is 409
    And "Jazz foundations I" still has only release revision 1

  Scenario: Another teacher cannot release a teacher's path
    Given Bea created and published the path "Jazz foundations"
    And Dan is a teacher
    When Dan publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then the response is 403
    And "Jazz foundations" has no release

  Scenario: Another teacher cannot read a teacher's release
    Given Bea released the path "Jazz foundations"
    And Dan is a teacher
    When Dan reads release revision 1 of "Jazz foundations"
    Then the response is 404

  Scenario: Releases are refused while the rollout is OFF
    Given the content-versions rollout is OFF
    And Bea created and published the path "Jazz foundations"
    When Bea publishes a commercial release of "Jazz foundations" at commercial revision 1
    Then the response is 403
    And "Jazz foundations" has no release

  Scenario: Existing releases stay readable while the rollout is OFF
    Given Bea released the path "Jazz foundations"
    And the content-versions rollout is OFF
    When Bea reads release revision 1 of "Jazz foundations"
    Then the release is returned unchanged
