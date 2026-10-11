@wip
Feature: Find items in the authoring lists at volume
  As a teacher or an admin with thousands of diagrams and hundreds of lessons and exercises
  I want every authoring list sorted by what changed last, filtered by a skill area including its
  sub-skills, and lessons filtered by author, language and status like the other sections
  So that I find the item I need instead of building it again

  # ADR-053 (extends ADR-031) · MOT-93 · design/patterns/authoring.md (D25–D28)
  # Remove @wip per scenario as motifpath-core implements it.

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "bob" is authenticated as a teacher

  # ── Sort ──────────────────────────────────────────────────────────────────

  Scenario: The exercise list is ordered by title unless another order is asked for
    Given an exercise "zz-first-created" exists titled "Triads on the top strings", created by "bob"
    And an exercise "aa-later-created" exists titled "Arpeggio sweep", created by "bob"
    When "bob" lists exercises
    Then the response lists "Arpeggio sweep" before "Triads on the top strings"

  Scenario: A teacher lists the most recently changed exercises first
    Given an exercise "Arpeggio sweep" exists, last changed on "2026-09-01"
    And an exercise "Triads on the top strings" exists, last changed on "2026-09-20"
    When "bob" lists exercises sorted by most recently changed
    Then the response lists "Triads on the top strings" before "Arpeggio sweep"

  Scenario: A teacher lists the most recently changed lessons first
    Given a content node "Open Chords" exists, last changed on "2026-09-01"
    And a content node "Barre Chords" exists, last changed on "2026-09-20"
    When "bob" lists content nodes sorted by most recently changed
    Then the response lists "Barre Chords" before "Open Chords"

  Scenario: A teacher lists the most recently changed diagrams first
    Given a basic diagram "A minor pentatonic" exists on instrument "guitar", last changed on "2026-09-01"
    And a basic diagram "C major scale" exists on instrument "guitar", last changed on "2026-09-20"
    When "bob" lists diagrams sorted by most recently changed
    Then the response lists "C major scale" before "A minor pentatonic"

  Scenario: A teacher lists the courses they manage most recently changed first
    Given a course "Blues Basics" exists as a draft, created by "bob", last changed on "2026-09-01"
    And a course "Acoustic Start" exists as a draft, created by "bob", last changed on "2026-09-20"
    When "bob" lists the courses they manage sorted by most recently changed
    Then the response lists "Acoustic Start" before "Blues Basics"

  Scenario: Editing a lesson records when it last changed
    Given a content node "Open Chords" exists, last changed on "2026-09-01"
    When "bob" updates content node "Open Chords" with title "Open Chords in First Position"
    Then the content node's last change is later than "2026-09-01"

  Scenario: Editing a diagram records when it last changed
    Given a custom diagram "My shape" exists on instrument "guitar", created by "bob", last changed on "2026-09-01"
    When "bob" renames diagram "My shape" to "My E shape"
    Then the diagram's last change is later than "2026-09-01"

  Scenario: An unknown sort order is rejected
    When "bob" lists exercises sorted by "popularity"
    Then the request is refused with a validation error

  # ── Several skills or concepts ────────────────────────────────────────────

  Scenario: Lessons filtered by two skills include lessons with either
    Given a content node "intro-to-triads" exists in the system with skills "triad-shapes"
    And a content node "sweep-picking-basics" exists in the system with skills "sweep-picking"
    And a content node "scale-basics" exists in the system with skills "major-scale"
    When "bob" lists content nodes filtered by skills "triad-shapes" and "sweep-picking"
    Then the response includes "intro-to-triads" and "sweep-picking-basics"
    And the response does not include "scale-basics"

  Scenario: Exercises filtered by two concepts include exercises with either
    Given an exercise "triad-drill" exists with concepts "chord-theory"
    And an exercise "muting-drill" exists with concepts "technique"
    And an exercise "reading-drill" exists with concepts "notation"
    When "bob" lists exercises filtered by concepts "chord-theory" and "technique"
    Then the response includes "triad-drill" and "muting-drill"
    And the response does not include "reading-drill"

  Scenario: Diagrams filtered by a skill and a concept must match both
    Given a basic diagram "Am pentatonic" exists on instrument "guitar", classified under skills "minor-pentatonic-scale", concepts "scale-construction"
    And a basic diagram "Am arpeggio" exists on instrument "guitar", classified under skills "minor-pentatonic-scale", concepts "chord-theory"
    When "bob" lists diagrams filtered by skill "minor-pentatonic-scale" and concept "scale-construction"
    Then the response includes "Am pentatonic"
    And the response does not include "Am arpeggio"

  Scenario: A skill id that is not a valid identifier is rejected
    When "bob" lists content nodes filtered by skill id "not-a-uuid"
    Then the request is refused with a validation error

  Scenario: A skill that does not exist matches nothing
    Given a content node "intro-to-triads" exists in the system with skills "triad-shapes"
    When "bob" lists content nodes filtered by a skill that does not exist
    Then the response is an empty list
    And the response reports a total of 0

  # ── A skill or concept matches its whole subtree ──────────────────────────

  Scenario: Choosing a skill area finds lessons classified with its sub-skills at any depth
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And a skill "outside-picking" exists under skill "alternate-picking"
    And a content node "outside-picking-drills" exists in the system with skills "outside-picking"
    When "bob" lists content nodes filtered by skill "picking"
    Then the response includes "outside-picking-drills"

  Scenario: Choosing a sub-skill does not find items classified only with its parent
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And an exercise "picking-overview" exists with skills "picking"
    When "bob" lists exercises filtered by skill "alternate-picking"
    Then the response does not include "picking-overview"

  Scenario: A sub-skill does not match its siblings
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And a skill "sweep-picking" exists under skill "picking"
    And an exercise "sweep-drill" exists with skills "sweep-picking"
    When "bob" lists exercises filtered by skill "alternate-picking"
    Then the response does not include "sweep-drill"

  Scenario: Choosing a concept area finds diagrams classified with its sub-concepts
    Given a root concept "chords" exists in the system
    And a concept "triads" exists under concept "chords"
    And a basic diagram "C triad shapes" exists on instrument "guitar", classified under skills "triad-shapes", concepts "triads"
    When "bob" lists diagrams filtered by concept "chords"
    Then the response includes "C triad shapes"

  Scenario: Moving a skill under an area makes its items match that area
    Given a root skill "picking" exists in the system
    And a root skill "hybrid-picking" exists in the system
    And an exercise "hybrid-drill" exists with skills "hybrid-picking"
    And "admin" is authenticated as an admin
    When "admin" moves skill "hybrid-picking" under skill "picking"
    And "bob" lists exercises filtered by skill "picking"
    Then the response includes "hybrid-drill"

  Scenario: Choosing a skill area finds learning paths with a lesson on a sub-skill
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And a content node "alternate-picking-basics" exists in the system with skills "alternate-picking"
    And a learning path "picking-path" exists with items "alternate-picking-basics", created by "bob"
    When "bob" lists learning paths filtered by skill "picking"
    Then the response includes "picking-path"

  Scenario: Choosing a skill area finds courses whose paths teach a sub-skill
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And a course "picking-course" exists as a draft, created by "bob", classified with skill "alternate-picking"
    When "bob" lists the courses they manage filtered by skill "picking"
    Then the response includes "picking-course"

  Scenario: The course catalog matches a skill area the same way
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And a course "picking-course" exists, published, created by "bob", at level "beginner", titled "Picking Basics", classified with skill "alternate-picking"
    And "alice" is authenticated as a student
    When "alice" lists the course catalog filtered by skill "picking"
    Then the response includes "picking-course"

  Scenario: The total counts every item in the area, not just this page
    Given a root skill "picking" exists in the system
    And a skill "alternate-picking" exists under skill "picking"
    And 15 content nodes exist in the system with skills "picking"
    And 15 content nodes exist in the system with skills "alternate-picking"
    When "bob" lists content nodes filtered by skill "picking" with limit 10
    Then the response contains 10 items
    And the response reports a total of 30

  # ── Lesson filters: author, language, status ─────────────────────────────

  Scenario: A teacher filters lessons by author
    Given a content node "bobs-lesson" exists, created by "bob"
    And a content node "carols-lesson" exists, created by "carol"
    When "bob" lists content nodes filtered by creator "carol"
    Then the response includes "carols-lesson"
    And the response does not include "bobs-lesson"

  Scenario: A teacher filters lessons by language
    Given a content node "triads-en" exists in languages "en"
    And a content node "triades-pt" exists in languages "pt"
    And a content node "triads-both" exists in languages "en" and "pt"
    When "bob" lists content nodes filtered by language "pt"
    Then the response includes "triades-pt" and "triads-both"
    And the response does not include "triads-en"

  Scenario: A language-agnostic lesson does not match a language filter
    Given a content node "fretboard-map" exists in languages "any"
    When "bob" lists content nodes filtered by language "pt"
    Then the response does not include "fretboard-map"

  Scenario: A lesson never published is a draft
    Given a content node "new-lesson" exists in the system
    And a content node "old-lesson" exists in the system
    And "bob" published content node "old-lesson" as version 1
    When "bob" lists content nodes filtered by status "draft"
    Then the response includes "new-lesson"
    And the response does not include "old-lesson"

  Scenario: A published lesson with no edits since is published
    Given "bob" published content node "open-chords" as version 1
    When "bob" lists content nodes filtered by status "published"
    Then the response includes "open-chords"
    And content node "open-chords" has no unpublished changes

  Scenario: Editing a published lesson gives it unpublished changes
    Given "bob" published content node "open-chords" as version 1
    When "bob" updates content node "open-chords" with title "Open Chords, Revised"
    And "bob" lists content nodes filtered by status "unpublished_changes"
    Then the response includes "open-chords"
    And content node "open-chords" has unpublished changes

  Scenario: A lesson with unpublished changes is not listed as published
    Given "bob" published content node "open-chords" as version 1
    And "bob" updated content node "open-chords" with title "Open Chords, Revised"
    When "bob" lists content nodes filtered by status "published"
    Then the response does not include "open-chords"

  Scenario: Saving a published lesson without changing anything keeps it published
    Given "bob" published content node "open-chords" as version 1
    When "bob" saves content node "open-chords" with the values it already has
    Then content node "open-chords" has no unpublished changes

  Scenario: Publishing a lesson with unpublished changes clears them
    Given "bob" published content node "open-chords" as version 1
    And "bob" updated content node "open-chords" with title "Open Chords, Revised"
    When "bob" publishes content node "open-chords"
    Then content node "open-chords" has no unpublished changes

  Scenario: An unknown lesson status is rejected
    When "bob" lists content nodes filtered by status "archived"
    Then the request is refused with a validation error

  # ── Creators carry how many items each one made ───────────────────────────

  Scenario: A teacher lists the lesson creators with how many lessons each made
    Given "bob" is named "Bob Ferreira"
    And "carol" is named "Carol Souza"
    And 3 content nodes exist, created by "bob"
    And 1 content node exists, created by "carol"
    When "bob" lists the content node creators
    Then the creators returned are "bob" with 3 items and "carol" with 1 item, in that order

  Scenario: Lesson creators are searched by display name, ignoring case and accents
    Given "bob" is named "Bob Ferreira"
    And "carol" is named "Carol Souza"
    And a content node "bobs-lesson" exists, created by "bob"
    And a content node "carols-lesson" exists, created by "carol"
    When "bob" lists the content node creators matching "FÉRR"
    Then the creators returned are "bob", each with their display name

  Scenario: A student cannot list lesson creators
    Given "alice" is authenticated as a student
    When "alice" lists the content node creators
    Then the request is refused with a forbidden error

  Scenario: Exercise creators carry how many exercises each made
    Given 2 exercises exist, created by "bob"
    And 5 exercises exist, created by "carol"
    When "bob" lists the exercise creators
    Then the creators returned are "bob" with 2 items and "carol" with 5 items, in that order

  Scenario: A diagram creator's count leaves out diagrams the caller cannot see
    Given 2 basic diagrams exist on instrument "guitar", created by "carol"
    And 4 custom diagrams exist on instrument "guitar", created by "carol"
    When "bob" lists the diagram creators
    Then the creators returned are "carol" with 2 items, in that order

  Scenario: A teacher's own course count covers every status
    Given a course "draft-course" exists as a draft, created by "bob", with checkpoints "path-a"
    And a course "live-course" exists, published, created by "bob", with checkpoints "path-b"
    When "bob" lists the course creators
    Then the creators returned are "bob" with 2 items, in that order
