# Landing, sign-in and the bridges while an account is set up (MOT-59, implemented by MOT-88).
#
# Google is the only way in (ADR-007), so the landing has one action: "Continue with Google", which
# starts Google sign-in through Clerk directly — Clerk's own sign-in card, sign-up form and profile
# form are never shown. Every screen before Home keeps the landing's layout, so a visitor never
# sees a blank page, a full-page spinner or someone else's product.
#
# The name step: ADR-035 keeps a first and a last name required, and the name reaches core only
# through the token's name claim. When Google gives no full name, we ask for it on our own screen:
#   - at sign-up, Clerk stops as "missing requirements"; Continue completes the sign-up;
#   - for an existing account whose registration is refused as name-required, Continue updates the
#     Clerk user, refreshes the session token and retries the registration.
#
# Pattern: design/patterns/landing-and-first-run.md. Designs: Figma "MotifPath — Experience
# Language", page "Landing & first run", rows 1, 4 and 5 (D1–D5).
# These scenarios are verified by motifpath-web's component tests and manual browser checks, not by
# the core-domain BDD suite.

@web
Feature: Land, sign in with Google and get an account
  As a visitor who wants to practise
  I want one tap to get in, and my account set up without forms that aren't MotifPath's
  So that I reach my first practice quickly

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: The landing has one action: Continue with Google
    Given a visitor who is not signed in
    When the visitor opens "/"
    Then the landing shows the MotifPath mark, the headline and "Continue with Google"
    And no App Shell navigation and no Clerk sign-in card show

  Scenario: Continue with Google starts Google sign-in directly
    Given a visitor on the landing
    When the visitor chooses "Continue with Google"
    Then the browser goes to Google's sign-in through Clerk, without a Clerk sign-in card first

  Scenario: The old sign-in address leads to the landing
    Given a visitor who is not signed in
    When the visitor opens "/sign-in"
    Then the landing shows

  Scenario: A protected page leads to the landing and comes back after sign-in
    Given a visitor who is not signed in
    When the visitor opens "/progress"
    Then the landing shows
    And after signing in with Google and being registered, the visitor is on Your progress

  Scenario: Back from Google, a fast registration shows no busy state
    Given "dora" signed in with Google for the first time
    And registering "dora" takes 200 ms
    When "dora" comes back to "/welcome"
    Then the landing's layout shows with the Google button unchanged
    And then Home shows

  Scenario: Back from Google, a slow registration says the account is being set up
    Given "dora" signed in with Google for the first time
    And registering "dora" takes 2 seconds
    When "dora" comes back to "/welcome"
    Then after 300 ms the Google button is busy and says "Setting up your account…"
    And there is no full-page spinner

  Scenario: A signed-in, registered visitor at the landing goes straight to Home
    Given student "alice" is signed in
    When "alice" opens "/"
    Then Home shows

  Scenario: The language link switches the landing before sign-in and carries into the app
    Given a visitor whose browser language is English
    When the visitor chooses "Português (Brasil)" on the landing
    Then the landing reads in Portuguese (Brazil) and the link offers "English"
    And after signing in for the first time, the app reads in Portuguese (Brazil)

  Scenario: The landing follows the browser's language
    Given a visitor whose browser language is Portuguese (Brazil)
    When the visitor opens "/"
    Then the headline is "Pratique um pouco todo dia. Veja seu progresso."

  Scenario: Signing out lands on the landing with the sign-out toast
    Given student "alice" is signed in
    When "alice" signs out
    Then the landing shows with "You're signed out. Your practice and progress are saved."

  # ── The name step ──────────────────────────────────────────────────────────

  Scenario: A new account without a last name is asked for it on our own screen
    Given Google gives "dora" a first name "Dora" and no last name
    When "dora" comes back from Google for the first time
    Then the landing's layout shows "What should we call you?"
    And First name holds "Dora" and Last name is empty and focused
    And no Clerk sign-up form shows

  Scenario: Continue completes the sign-up with the name and registers the student
    Given "dora" is on "What should we call you?" at sign-up
    When "dora" enters "Silva" as Last name and chooses Continue
    Then the sign-up completes with first name "Dora" and last name "Silva"
    And "dora" is registered as "Dora Silva" and Home shows

  Scenario: An existing account refused for a missing name is fixed on the same screen
    Given "edu" already has an account whose Google name has no last name
    And registering "edu" is refused because the name is missing
    When "edu" enters "Souza" as Last name and chooses Continue
    Then "edu"'s account name becomes "Edu Souza"
    And the registration is retried with a fresh session token
    And "edu" is registered and Home shows

  Scenario: Both names are needed before Continue
    Given "dora" is on "What should we call you?"
    When "dora" leaves Last name empty and chooses Continue
    Then Last name says it is needed
    And nothing is sent

  Scenario: Sign out is the quiet way back from the name step
    Given "dora" is on "What should we call you?"
    When "dora" chooses Sign out
    Then the landing shows and "dora" is signed out

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: Google sign-in that didn't finish says nothing was saved
    Given a visitor chose "Continue with Google"
    When the visitor cancels or denies the sign-in at Google
    Then the landing shows "Google sign-in didn't finish. Nothing was saved — try again when you're ready."
    And "Continue with Google" is offered again

  Scenario: A failed account setup offers Try again and Sign out
    Given "dora" signed in with Google
    And registering "dora" fails for a reason other than the name
    When "dora" is on "/welcome/error"
    Then the landing's layout shows "We couldn't set up your account. Your Google sign-in worked — try again in a moment."
    And "dora" is offered Try again and Sign out

  Scenario: Try again that succeeds goes on to where the visitor was heading
    Given "dora" is on "/welcome/error" heading to Your progress
    When "dora" chooses Try again and the registration succeeds
    Then Your progress shows

  Scenario: A name step that fails to save keeps what was typed
    Given "dora" is on "What should we call you?"
    And saving the name fails
    When "dora" chooses Continue
    Then an error notice says the name couldn't be saved
    And First name and Last name still hold what "dora" typed
