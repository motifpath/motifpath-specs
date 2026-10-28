# Device edges (MOT-174, ADR-063 §4).
#
# The page draws edge to edge. Each screen edge has one owner (a top bar, a bottom bar, a sheet's
# last row) that pads by the device's inset: the status bar, the notch or Dynamic Island, the home
# indicator, Android's gesture bar, and the sides of a phone in landscape. No control sits inside
# an inset. Android's back closes the top layer first, like the browser's Back. The store apps
# launch on a splash that stays until the first screen can render.
#
# Pattern: design/patterns/device-edges.md.
# Designs: Figma "MotifPath — Experience Language", page "Device edges — MOT-174".
# These scenarios are verified by motifpath-web's component tests and by manual checks on a notched
# iPhone and an Android phone with gesture navigation, not by the core-domain BDD suite.

@web
Feature: Keep every control clear of the device's edges
  As a student holding a guitar, with one thumb free
  I want every control where I can tap it, and Back to behave the way my phone does
  So that the app never hides a button under the clock or the home indicator

  Background:
    Given student "alice" is signed in in the iOS app on an iPhone with a Dynamic Island

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: The top bar starts below the status bar
    When "alice" opens Home
    Then the brand and the avatar sit below the status bar
    And the top bar's background fills the area behind the status bar

  Scenario: The Practice header's × can be tapped
    Given "alice" started a practice run
    When "alice" taps × in the Practice header
    Then the run ends as left early

  Scenario: The bottom bar sits above the home indicator
    When "alice" opens Learning
    Then every bottom navigation item sits above the home indicator

  Scenario: The status bar follows the appearance
    Given "alice" uses the dark appearance
    When "alice" opens Home
    Then the status bar shows light icons
    When "alice" switches Appearance to Light
    Then the status bar shows dark icons

  Scenario: The splash stays until the first screen renders
    When "alice" launches the app
    Then the splash shows the MotifPath mark on the surface colour
    And Home replaces the splash with no blank page in between

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A sheet stops below the status bar
    When "alice" opens a sheet whose content is taller than the screen
    Then the sheet's header and its close control sit below the status bar
    And the sheet's last action sits above the home indicator

  Scenario: Only the lowest bar pads for the home indicator
    Given a toast shows above the bottom navigation bar
    Then the toast sits directly above the bar, not an extra home-indicator gap higher

  Scenario: In landscape the rail clears the notch
    When "alice" turns the phone to landscape with the notch on the left
    Then the navigation rail's items sit right of the notch

  Scenario: Android back closes the top layer first
    Given student "alice" is signed in in the Android app with gesture navigation
    And "alice" opened the account sheet on Learning
    When "alice" swipes back
    Then the account sheet closes and Learning still shows

  Scenario: Android back in a run leaves like ×
    Given student "alice" is signed in in the Android app with gesture navigation
    And "alice" started a practice run
    When "alice" swipes back
    Then the run ends as left early

  Scenario: Android back on Home leaves the app
    Given student "alice" is signed in in the Android app with gesture navigation
    And "alice" is on Home with no layer open
    When "alice" swipes back
    Then the app closes without asking for confirmation

  Scenario: A desktop browser shows no insets
    Given student "alice" is signed in in a desktop browser
    When "alice" opens Home
    Then the top bar and the content keep their usual spacing

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A slow first screen gives way to its loading state
    Given the first screen's data takes longer than 10 seconds to load
    When "alice" launches the app
    Then after 10 seconds the splash gives way to Home's loading state

  Scenario: The first screen fails to load
    Given the first screen's data fails to load
    When "alice" launches the app
    Then the splash gives way to Home's error state, with a way to try again
