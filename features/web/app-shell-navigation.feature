# App Shell navigation (MOT-43).
#
# The learner destinations, in this order, on every size class: Home · Practice · My path ·
# Learning · Discover. Only the container changes:
#   Compact  (< 600 px)     a bottom navigation bar, label always visible, touch targets ≥ 48 px;
#   Medium   (600–839 px)   a navigation rail on the left;
#   Expanded (≥ 840 px)     a sidebar with icon and label, and "Teach" under a divider for authors.
# On Compact, the account menu (behind the avatar) holds theme, language, sign out and, for
# authors, "Teach". Authoring stays desktop-first and keeps its own app bar.
# Discover joins "Find a course" and "Find a path" behind a Courses | Paths segmented control.
# A practice run uses the Practice Shell: no global navigation.
#
# Designs: Figma "MotifPath — Experience Language", page "App Shell" (Option A, decided 2026-10-07).
# These scenarios are verified by motifpath-web's component tests and manual browser checks, not by
# the core-domain BDD suite.

Feature: Navigate the app from the App Shell
  As a student on a phone
  I want every main place one tap away, in the same order everywhere
  So that switching between practising and learning never costs a menu

  Background:
    Given student "alice" is signed in

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: On a phone the destinations are a bottom navigation bar
    When "alice" opens the app on a screen 390 px wide
    Then a bottom navigation bar shows Home, Practice, My path, Learning and Discover, in that order
    And there is no menu button for navigation

  Scenario: The current destination is marked
    Given "alice" is on My path
    Then My path is marked as current in the navigation, by more than colour alone

  Scenario: Every destination is one tap away
    Given "alice" is on the home
    When "alice" taps Learning
    Then "alice"'s courses open

  Scenario: Practice opens the session setup
    When "alice" taps Practice
    Then the practice session setup opens, without a page in between

  Scenario: Discover shows courses and paths behind one control
    When "alice" taps Discover
    Then the course catalog shows with a Courses | Paths control
    When "alice" chooses Paths
    Then the path catalog shows, still under Discover

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: On a tablet the destinations are a navigation rail
    When "alice" opens the app on a screen 720 px wide
    Then a navigation rail on the left shows the same five destinations in the same order

  Scenario: On a desktop the destinations are a sidebar
    When "alice" opens the app on a screen 1280 px wide
    Then a sidebar shows the same five destinations, each with its label

  Scenario: An author reaches authoring from the account menu on a phone
    Given "alice" is a teacher
    When "alice" opens the account menu on a screen 390 px wide
    Then the account menu offers "Teach"

  Scenario: An author reaches authoring from the sidebar on a desktop
    Given "alice" is a teacher
    When "alice" opens the app on a screen 1280 px wide
    Then the sidebar shows "Teach" under the learner destinations, apart from them

  Scenario: A student is never offered Teach
    Given "alice" is a student
    When "alice" opens the account menu
    Then the account menu does not offer "Teach"

  Scenario: A practice run hides the navigation
    When "alice" starts a practice session
    Then no navigation bar, rail or sidebar shows until the session ends

  Scenario: The bottom bar clears the phone's home indicator
    When "alice" opens the app on a phone with a home indicator
    Then the bottom navigation bar sits above the home indicator's safe area

  Scenario: Portuguese labels fit the bottom bar
    Given "alice"'s language is Portuguese (Brazil)
    When "alice" opens the app on a screen 360 px wide
    Then the bottom bar shows Início, Praticar, Trilha, Aprender and Explorar on one line each

  Scenario: Back closes an open layer before leaving the destination
    Given "alice" opened the account menu on Learning
    When "alice" goes back
    Then the account menu closes and Learning still shows

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A signed-out visitor sees no learner navigation
    Given a visitor who is not signed in
    When the visitor opens the app
    Then no bottom navigation bar, rail or sidebar shows
    And the visitor is offered to sign in
