# Knowledge map editor (PB-85, Phase 4).
#
# The admin screen for growing and correcting the knowledge graph (ADR-043): create, edit,
# move and delete skills and concepts, and add, remove or re-level their applies and
# requires links. The screen and its decisions are described in
# design/PB-85-knowledge-map-editor/README.md.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser
# checks, not by the core-domain BDD suite. The API rules behind them (validation, 409s,
# admin-only writes) are covered by features/content-management/knowledge-nodes.feature and
# knowledge-edges.feature.
#
# Out of scope: teacher proposals, bulk import/export, a graph visualisation, sibling order.

Feature: Edit the knowledge map
  As an admin
  I want one screen to add and correct skills, concepts and the links between them
  So that the map grows without data migrations or raw API calls

  Background:
    Given the concept tree has "Technique terms" with the child "Bending"
    And the skill tree has "Lead techniques" for "Electric guitar" and "Acoustic guitar"
    And "Lead techniques" has the child "Bends" for "Electric guitar" and "Acoustic guitar"
    And "Bends" has the child "Unison bends"
    And "Lead techniques" has the child "Vibrato" for "Electric guitar" and "Acoustic guitar"
    And the skill tree has the root "Expressive techniques" for every instrument
    And "Bends" applies "Bending"
    And "Vibrato" requires "Bends" at the level "fluent"

  # ── Access ───────────────────────────────────────────────────────────────────

  Rule: Only admins reach the editor

    Scenario: An admin sees the Knowledge map section
      Given the signed-in user is an admin
      Then the navigation offers "Knowledge map"

    Scenario Outline: Other roles neither see nor open the editor
      Given the signed-in user is a <role>
      Then the navigation does not offer "Knowledge map"
      And opening "/admin/knowledge-map" sends the user away like any other role-gated page

      Examples:
        | role    |
        | teacher |
        | student |

  # ── Browsing ─────────────────────────────────────────────────────────────────

  Rule: The tree works like the picker's, concepts first

    Scenario: The editor opens on the concept tree with nothing selected
      When the admin opens the knowledge map
      Then the "Concepts" tab is shown before the "Skills" tab
      And the right pane says "Pick a node, or create one."

    Scenario: Selecting a node shows it and records it in the URL
      When the admin selects the skill "Bends"
      Then the right pane shows "Bends", its key and the breadcrumb "Lead techniques"
      And the URL carries the node's id
      And reloading the page shows "Bends" selected, with "Lead techniques" expanded

    Scenario: An instrument filter greys out nodes for other instruments but keeps them selectable
      When the admin filters the tree by "Electric bass"
      Then "Bends" is shown greyed out
      And the admin can still select "Bends"

    Scenario: A link to a node that no longer exists
      When the admin opens the knowledge map for a node id that doesn't exist
      Then the right pane says "This node no longer exists."

  # ── Creating ─────────────────────────────────────────────────────────────────

  Rule: A new node needs a key and a name in every language

    Scenario: The key is suggested from the English name until the admin edits it
      When the admin starts a new skill under "Bends"
      And types the English name "Pre-bends & releases"
      Then the key field shows "pre-bends-releases"
      When the admin edits the key to "pre-bend-release"
      And changes the English name to "Pre-bends"
      Then the key field still shows "pre-bend-release"

    Scenario: A key already used by another node is caught before saving
      When the admin starts a new concept with the key "bending"
      Then the key field says the key is already in use
      And Save is disabled

    Scenario: Save waits for a name in every language
      When the admin starts a new concept with only an English name
      Then Save is disabled

    Scenario: A child's instruments default to its parent's, and cannot be wider
      When the admin starts a new skill under "Bends"
      Then the instruments are "Electric guitar" and "Acoustic guitar"
      And "Every instrument" and "Electric bass" are disabled, explained as wider than the parent

    Scenario: Creating a node selects it
      When the admin creates the skill "Pre-bends" under "Bends"
      Then "Pre-bends" is selected under "Bends" in the tree

  # ── Editing ──────────────────────────────────────────────────────────────────

  Rule: Names, descriptions and instruments save with the form; the key never changes

    Scenario: The key is read-only on an existing node
      When the admin selects the skill "Bends"
      Then the key is shown read-only with the note "Keys never change."

    Scenario: Clearing both descriptions removes the description
      Given "Bends" has a description in every language
      When the admin clears both descriptions and saves
      Then the node is saved with no description

    Scenario: A narrowing the server refuses is explained under the field
      Given a lesson for "Acoustic guitar" is classified under "Bends"
      When the admin removes "Acoustic guitar" from "Bends" and saves
      Then the server's reason is shown under the instruments field
      And the form keeps the admin's changes

    Scenario: Leaving a changed form asks before discarding
      When the admin renames "Bends" without saving
      And selects the skill "Lead techniques"
      Then the admin is asked "Discard your changes?"

  # ── Moving and deleting (modals) ─────────────────────────────────────────────

  Rule: Moving and deleting are confirmed in a modal

    Scenario: The move modal disables impossible parents
      When the admin opens Move for "Bends"
      Then "Bends" and "Unison bends" are disabled as inside the node being moved
      And parents narrower than "Bends"'s instruments are disabled as narrower than this node
      And "No parent — make it a root" is offered

    Scenario: The move confirmation counts the subtree
      When the admin moves "Bends" under "Expressive techniques"
      Then the modal asks "Move Bends and its 1 descendant under Expressive techniques?"
      When the admin confirms
      Then "Bends" and "Unison bends" appear under "Expressive techniques"

    Scenario: A node with children or links cannot be deleted
      When the admin opens Delete for "Bends"
      Then the modal names the child "Unison bends" and the links to "Bending" and "Vibrato"
      And it offers only Close

    Scenario: Deleting an unused node selects its parent
      When the admin deletes "Unison bends"
      Then "Unison bends" is gone from the tree
      And "Bends" is selected

    Scenario: A delete the server refuses shows its reason in the modal
      Given an exercise is classified under the unlinked skill "Double-stop bends"
      When the admin deletes "Double-stop bends"
      Then the modal shows the server's reason and the node stays

  # ── Links ────────────────────────────────────────────────────────────────────

  Rule: Links are edited from the node they leave and save at once

    Scenario: A skill lists what it applies and requires, and what requires it
      When the admin selects the skill "Bends"
      Then "Applies" lists "Bending" with a remove control
      And "Required by" lists "Vibrato" at "Fluent", read-only, as a link

    Scenario: A concept shows the skills that apply it, read-only
      When the admin selects the concept "Bending"
      Then "Applied by" lists "Bends", read-only, as a link
      And the concept offers no "Applies" list

    Scenario: Adding a requires link starts at Accurate
      When the admin adds "Bending" to the requires of "Unison bends"
      Then "Requires" lists "Bending" at "Accurate"

    Scenario: Changing a level saves immediately
      When the admin selects "Vibrato"
      And changes the level of "Bends" to "Retained"
      Then the link is saved with the level "retained" without pressing Save

    Scenario: A link that would close a loop is explained inline
      When the admin adds "Vibrato" to the requires of "Bends"
      Then the "Requires" list says "Vibrato already requires Bends — this link would close a loop."
      And no link is added

  # ── Authoring pickers ────────────────────────────────────────────────────────

  Rule: Authoring pickers send admins to the editor

    Scenario: An admin's picker links to the editor in a new tab
      Given the signed-in user is an admin
      When the admin opens the skill picker in the exercise editor
      Then the picker says "Missing one? Add it in the knowledge map"
      And the link opens the editor's new-skill form in a new tab

    Scenario: A teacher's picker still asks the team
      Given the signed-in user is a teacher
      When the teacher opens the skill picker in the exercise editor
      Then the picker says "Missing one? Ask the team."

    Scenario: The picker shows a node created in another tab
      Given the admin has the exercise editor open
      When the admin creates the skill "Pre-bends" in the knowledge map tab
      And returns to the exercise editor's tab
      Then the skill picker offers "Pre-bends"
