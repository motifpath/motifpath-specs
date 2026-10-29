# Google sign-in inside the store apps (MOT-172, ADR-063 §1–2).
#
# Inside the iOS and Android apps, the browser's Google sign-in can't work: Google refuses OAuth in
# an embedded WebView, and the app can't keep the auth provider's cookies. So "Continue with Google"
# opens the platform's own Google account picker, and the Google ID token it returns is handed to
# Clerk. Clerk then runs in native mode: its client token travels in a request header and is kept
# in the device's secure storage (the iOS Keychain or the Android Keystore), never in localStorage.
#
# Everything around the picker is the landing from landing-and-sign-in.feature, unchanged: the same
# layout, the same busy button, the same "didn't finish" notice, the name step and the account
# set-up bridges. In a browser, sign-in stays as that feature describes.
#
# Pattern: design/patterns/landing-and-first-run.md. No new design: the account picker belongs to
# the platform.
# These scenarios are verified by motifpath-web's component and unit tests and by manual checks on
# an iPhone and an Android phone, not by the core-domain BDD suite.

@web
Feature: Sign in with Google inside the iOS and Android apps
  As a student who installed MotifPath on my phone
  I want to sign in with the Google account already on my phone, and stay signed in
  So that I open the app and practise without signing in again

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Continue with Google opens the phone's Google account picker
    Given a visitor on the landing in the iOS app
    When the visitor chooses "Continue with Google"
    Then the phone's Google account picker shows over the landing
    And no browser opens

  Scenario: Picking an account signs in and sets the account up
    Given a visitor on the landing in the Android app
    When the visitor chooses "Continue with Google" and picks "dora@gmail.com"
    Then "dora" is signed in
    And the app goes on to set up the account, then Home shows

  Scenario: A slow sign-in after the picker says the account is being set up
    Given a visitor on the landing in the iOS app
    And signing in with the picked account takes 2 seconds
    When the visitor picks an account
    Then after 300 ms the Google button is busy and says "Setting up your account…"
    And there is no full-page spinner

  Scenario: A protected page leads to the landing and comes back after sign-in in the app
    Given a visitor who is not signed in, in the iOS app
    When the visitor opens Your progress and signs in with Google
    Then Your progress shows once the account is set up

  Scenario: A new account without a last name goes to the name step
    Given Google gives "dora" a first name "Dora" and no last name
    When "dora" picks a Google account in the Android app for the first time
    Then the landing's layout shows "What should we call you?"
    And Continue completes the sign-up as in a browser

  Scenario: The student stays signed in after closing the app
    Given student "alice" signed in in the iOS app
    When "alice" closes the app and opens it again
    Then Home shows without the landing

  Scenario: Signing in again after signing out works on the same phone
    Given student "alice" signed in in the iOS app and then signed out
    When "alice" chooses "Continue with Google" and picks the same account
    Then "alice" is signed in
    # Google's iOS SDK hands back the ID token it cached, and Clerk refuses a token it has seen.
    # Every attempt asks Google for a fresh one.

  # ── Signing out ────────────────────────────────────────────────────────────

  Scenario: Signing out forgets the sign-in on the phone
    Given student "alice" is signed in in the Android app
    When "alice" signs out
    Then the landing shows with "You're signed out. Your practice and progress are saved."
    And the next time "alice" opens the app, the landing shows

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: Closing the account picker says the sign-in didn't finish
    Given a visitor on the landing in the iOS app
    When the visitor chooses "Continue with Google" and closes the account picker
    Then the landing shows "Google sign-in didn't finish. Nothing was saved — try again when you're ready."
    And "Continue with Google" is offered again

  Scenario: A Google token the auth provider refuses says the sign-in didn't finish
    Given a visitor on the landing in the Android app
    And the auth provider refuses the Google token
    When the visitor picks an account
    Then the landing shows "Google sign-in didn't finish. Nothing was saved — try again when you're ready."
    And the visitor is not signed in

  Scenario: A stored sign-in the auth provider no longer accepts is forgotten
    Given student "alice" signed in in the iOS app
    And the auth provider has since ended that sign-in
    When "alice" opens the app
    Then the landing shows
    And "alice" can sign in with Google again
    And the refused sign-in is no longer stored on the phone
