Feature: Manage knowledge nodes
  As the MotifPath team
  I want admins to curate one localized graph of skills and concepts, and any authenticated user to read it
  So that content is classified against shared, translatable nodes that can be corrected as the curriculum matures

  # A skill is something a student can do ("Play open chords"); a concept is
  # something true or known ("Open chord shapes"). Each kind forms its own
  # tree: a node has at most one parent, of the same kind. A node's key is its
  # stable handle for code and seed scripts and never changes.

  Background:
    Given the Core Domain Service is operational and ready to accept requests

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: An admin creates a root skill, named in every language
    Given "admin" is authenticated as an admin
    When "admin" creates a skill with key "play-open-chords" named "Play open chords" in English and "Tocar acordes abertos" in Portuguese
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node's kind is "skill"
    And the knowledge node's key is "play-open-chords"
    And the knowledge node's name in "en" is "Play open chords"
    And the knowledge node's name in "pt_BR" is "Tocar acordes abertos"
    And the knowledge node's languages are "en, pt_BR"
    And the knowledge node has no parent

  Scenario: An admin creates a concept under an existing concept
    Given a root concept "chords" exists in the system
    And "admin" is authenticated as an admin
    When "admin" creates a concept with key "open-chord-shapes" named "Open chord shapes" in English and "Formas de acordes abertos" in Portuguese under concept "chords"
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node's kind is "concept"
    And the knowledge node's parent is "chords"

  Scenario: An admin creates a node with a description in every language
    Given "admin" is authenticated as an admin
    When "admin" creates a concept with key "blues-form" named "Blues form" in English and "Forma do blues" in Portuguese, described as "A 12-bar progression" in English and "Uma progressão de 12 compassos" in Portuguese
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node's description in "en" is "A 12-bar progression"
    And the knowledge node's description in "pt_BR" is "Uma progressão de 12 compassos"

  Scenario: A node created without a description has none
    Given "admin" is authenticated as an admin
    When "admin" creates a skill with key "play-open-chords" named "Play open chords" in English and "Tocar acordes abertos" in Portuguese
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node has no description

  Scenario: A node created without instruments is for every instrument
    Given "admin" is authenticated as an admin
    When "admin" creates a concept with key "major-scale" named "Major scale" in English and "Escala maior" in Portuguese
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node is for every instrument

  Scenario: An admin creates a skill for specific instruments
    Given a fretted instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" creates a skill with key "palm-muting" named "Palm mute" in English and "Palm mute (abafamento com a palma)" in Portuguese for instrument "guitar"
    Then the knowledge node is created and assigned a stable identifier
    And the knowledge node's instruments are "guitar"

  Scenario: Two nodes may share a name when their keys differ
    Given a root skill "picking" exists in the system
    And "admin" is authenticated as an admin
    When "admin" creates a skill with key "picking-basics" named "picking" in English and "picking" in Portuguese
    Then the knowledge node is created and assigned a stable identifier

  # ── Happy path — reading ─────────────────────────────────────────────────────

  Scenario: A teacher lists every knowledge node
    Given a root skill "fretting" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And a root concept "chords" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists all knowledge nodes
    Then the response includes skill "fretting" with no parent
    And the response includes skill "barre-chords" with parent "fretting"
    And the response includes concept "chords" with no parent

  Scenario: A student lists only the skills
    Given a root skill "fretting" exists in the system
    And a root concept "chords" exists in the system
    And "alice" is authenticated as a student
    When "alice" lists the knowledge nodes of kind "skill"
    Then the response includes skill "fretting" with no parent
    And the response does not include concept "chords"

  Scenario: Listing the nodes for an instrument includes nodes for every instrument
    Given a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system
    And a root skill "palm-muting" for instrument "guitar" exists in the system
    And a root skill "pedal-sustain" for instrument "piano" exists in the system
    And a root concept "major-scale" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists the knowledge nodes for instrument "piano"
    Then the response includes skill "pedal-sustain" with no parent
    And the response includes concept "major-scale" with no parent
    And the response does not include skill "palm-muting"

  Scenario: Listing the nodes for several instruments includes the nodes for any of them
    Given a fretted instrument "guitar" exists in the system
    And a fretted instrument "bass" exists in the system
    And a keyboard instrument "piano" exists in the system
    And a root skill "palm-muting" for instrument "guitar" exists in the system
    And a root skill "slap" for instrument "bass" exists in the system
    And a root skill "pedal-sustain" for instrument "piano" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" lists the knowledge nodes for instruments "guitar" and "bass"
    Then the response includes skill "palm-muting" with no parent
    And the response includes skill "slap" with no parent
    And the response does not include skill "pedal-sustain"

  Scenario: Listing knowledge nodes when none exist returns an empty list
    Given "bob" is authenticated as a teacher
    When "bob" lists all knowledge nodes
    Then the response is an empty list

  Scenario: A student retrieves one knowledge node
    Given a root concept "chords" exists in the system
    And "alice" is authenticated as a student
    When "alice" retrieves concept "chords"
    Then the knowledge node's key is "chords"
    And the knowledge node's kind is "concept"

  Scenario: Retrieving a knowledge node that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" attempts to retrieve a knowledge node with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Happy path — updating ────────────────────────────────────────────────────

  Scenario: An admin renames a node
    Given a root skill "fretting" exists in the system
    And "admin" is authenticated as an admin
    When "admin" renames skill "fretting" to "Fret notes cleanly" in English and "Pressionar notas com clareza" in Portuguese
    Then the knowledge node's name in "en" is "Fret notes cleanly"
    And the knowledge node's name in "pt_BR" is "Pressionar notas com clareza"
    And the knowledge node's key is "fretting"

  Scenario: An admin moves a node under another parent of the same kind
    Given a root skill "fretting" exists in the system
    And a root skill "chord-playing" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And "admin" is authenticated as an admin
    When "admin" moves skill "barre-chords" under skill "chord-playing"
    Then the knowledge node's parent is "chord-playing"

  Scenario: Moving a node takes its subtree with it
    Given a root skill "fretting" exists in the system
    And a root skill "chord-playing" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And a skill "e-shape-barre" exists under skill "barre-chords"
    And "admin" is authenticated as an admin
    When "admin" moves skill "barre-chords" under skill "chord-playing"
    Then skill "e-shape-barre" still has parent "barre-chords"

  Scenario: An admin makes a node a root
    Given a root skill "fretting" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And "admin" is authenticated as an admin
    When "admin" moves skill "barre-chords" to the root
    Then the knowledge node has no parent

  Scenario: An admin changes a node's instruments
    Given a fretted instrument "guitar" exists in the system
    And a root skill "read-chord-charts" for instrument "guitar" exists in the system
    And "admin" is authenticated as an admin
    When "admin" makes skill "read-chord-charts" for every instrument
    Then the knowledge node is for every instrument

  Scenario: An admin cannot narrow a node's instruments while content outside them uses it
    Given a fretted instrument "guitar" exists in the system
    And a fretted instrument "bass" exists in the system
    And a root skill "hammer-ons" for instruments "guitar" and "bass" exists in the system
    And a content node "Bass Hammer-ons" for instruments "bass" classified under skill "hammer-ons" exists in the system
    And "admin" is authenticated as an admin
    When "admin" makes skill "hammer-ons" for instrument "guitar" only
    Then the request is refused with a conflict error

  Scenario: An admin narrows a node's instruments when no content outside them uses it
    Given a fretted instrument "guitar" exists in the system
    And a fretted instrument "bass" exists in the system
    And a root skill "hammer-ons" for instruments "guitar" and "bass" exists in the system
    And "admin" is authenticated as an admin
    When "admin" makes skill "hammer-ons" for instrument "guitar" only
    Then the knowledge node's instruments are "guitar"

  Scenario: An admin removes a node's description
    Given a root concept "blues-form" with a description exists in the system
    And "admin" is authenticated as an admin
    When "admin" removes the description of concept "blues-form"
    Then the knowledge node has no description

  # ── Happy path — deleting ────────────────────────────────────────────────────

  Scenario: An admin deletes a node nothing depends on
    Given a root skill "fretting" exists in the system
    And "admin" is authenticated as an admin
    When "admin" deletes skill "fretting"
    Then the knowledge node is deleted
    And retrieving skill "fretting" returns not found

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a node named in only one language is rejected
    Given "admin" is authenticated as an admin
    When "admin" creates a skill with key "play-open-chords" named only "Play open chords" in English
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Creating a node with a name in an unknown language is rejected
    Given "admin" is authenticated as an admin
    When "admin" creates a skill with key "play-open-chords" and names "en" "Play open chords", "pt_BR" "Tocar acordes abertos" and "fr" "Jouer des accords ouverts"
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: Creating a node with a description in only one language is rejected
    Given "admin" is authenticated as an admin
    When "admin" creates a concept with key "blues-form" named "Blues form" in English and "Forma do blues" in Portuguese, described only as "A 12-bar progression" in English
    Then the request is rejected as invalid
    And the rejection identifies "descriptions" as the source of the error

  Scenario Outline: Creating a node with a key that is not lowercase kebab-case is rejected
    Given "admin" is authenticated as an admin
    When "admin" creates a skill with key "<key>" named "Play open chords" in English and "Tocar acordes abertos" in Portuguese
    Then the request is rejected as invalid
    And the rejection identifies "key" as the source of the error

    Examples:
      | key              |
      | Play-Open-Chords |
      | play open chords |
      | play--open       |
      | -play            |

  Scenario: Creating a node for an instrument that does not exist is rejected
    Given "admin" is authenticated as an admin
    When "admin" submits a create knowledge node request with an instrument id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "instrument_ids" as the source of the error

  Scenario: Creating a node without a kind is rejected
    Given "admin" is authenticated as an admin
    When "admin" submits a create knowledge node request with the kind field omitted
    Then the request is rejected as invalid
    And the rejection identifies "kind" as the source of the error

  Scenario: Creating a node under a parent that does not exist is rejected
    Given "admin" is authenticated as an admin
    When "admin" submits a create knowledge node request with a parent_id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "parent_id" as the source of the error

  Scenario: Creating a skill under a concept is rejected
    Given a root concept "chords" exists in the system
    And "admin" is authenticated as an admin
    When "admin" creates a skill with key "play-open-chords" named "Play open chords" in English and "Tocar acordes abertos" in Portuguese under concept "chords"
    Then the request is rejected as invalid
    And the rejection identifies "parent_id" as the source of the error

  Scenario: Moving a node under a node of the other kind is rejected
    Given a root skill "barre-chords" exists in the system
    And a root concept "chords" exists in the system
    And "admin" is authenticated as an admin
    When "admin" moves skill "barre-chords" under concept "chords"
    Then the request is rejected as invalid
    And the rejection identifies "parent_id" as the source of the error

  # ── Conflicts ──────────────────────────────────────────────────────────────

  Scenario: Creating a node with a key already in use is refused
    Given a root concept "chords" exists in the system
    And "admin" is authenticated as an admin
    When "admin" creates a skill with key "chords" named "Play chords" in English and "Tocar acordes" in Portuguese
    Then the request is refused with a conflict error

  Scenario: Moving a node under itself is refused
    Given a root skill "fretting" exists in the system
    And "admin" is authenticated as an admin
    When "admin" moves skill "fretting" under skill "fretting"
    Then the request is refused with a conflict error

  Scenario: Moving a node under one of its descendants is refused
    Given a root skill "fretting" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And a skill "e-shape-barre" exists under skill "barre-chords"
    And "admin" is authenticated as an admin
    When "admin" moves skill "fretting" under skill "e-shape-barre"
    Then the request is refused with a conflict error

  Scenario: Deleting a node that has children is refused
    Given a root skill "fretting" exists in the system
    And a skill "barre-chords" exists under skill "fretting"
    And "admin" is authenticated as an admin
    When "admin" deletes skill "fretting"
    Then the request is refused with a conflict error

  Scenario: Deleting a node that takes part in a knowledge edge is refused
    Given a root skill "improvise-over-a-blues" exists in the system
    And a root concept "blues-form" exists in the system
    And skill "improvise-over-a-blues" applies concept "blues-form"
    And "admin" is authenticated as an admin
    When "admin" deletes concept "blues-form"
    Then the request is refused with a conflict error

  Scenario: Deleting a node that classifies content is refused
    Given a root skill "fretting" exists in the system
    And a content node "Fretting basics" exists in the system with skills "fretting"
    And "admin" is authenticated as an admin
    When "admin" deletes skill "fretting"
    Then the request is refused with a conflict error

  Scenario: Deleting a node that classifies an exercise is refused
    Given a root skill "fretting" exists in the system
    And an exercise "Fret check" exists with skills "fretting"
    And "admin" is authenticated as an admin
    When "admin" deletes skill "fretting"
    Then the request is refused with a conflict error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A teacher cannot create a knowledge node
    Given "bob" is authenticated as a teacher
    When "bob" attempts to create a knowledge node
    Then the request is refused with a forbidden error

  Scenario: A student cannot create a knowledge node
    Given "alice" is authenticated as a student
    When "alice" attempts to create a knowledge node
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot update a knowledge node
    Given a root skill "fretting" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" renames skill "fretting" to "Fret notes cleanly" in English and "Pressionar notas com clareza" in Portuguese
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot delete a knowledge node
    Given a root skill "fretting" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" deletes skill "fretting"
    Then the request is refused with a forbidden error

  Scenario: Listing knowledge nodes without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to list all knowledge nodes
    Then the request is refused with an authentication error
