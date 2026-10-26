Feature: Unsubscribe from an email kind with one click
  As a student who gets MotifPath emails
  I want to stop one kind of email straight from the email itself
  So that I don't have to sign in to stop emails I don't want

  # ADR-065, LGPD. Every progress report and reminder carries an unsubscribe link for its own
  # kind. The link holds a token that the platform issued for one user and one kind. It cannot
  # be altered or made up, and it doesn't expire. Using it needs no sign-in and turns off only
  # that kind. The mail client's one-click unsubscribe (the List-Unsubscribe header) and the
  # link in the email's footer use the same token. The footer link opens a web page that
  # confirms the change and links to the settings, where the student can turn the kind back on.

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "alice" has already registered as a student
    And "alice" has the email preferences "progress_report" on and "reminders" on

  # ── Happy path ─────────────────────────────────────────────────────────────

  @wip
  Scenario: An unsubscribe link from a progress report turns progress reports off
    Given "alice" holds the unsubscribe link from their progress report
    When the unsubscribe link is used without signing in
    Then "alice" has the email preference "progress_report" off

  @wip
  Scenario: An unsubscribe link turns off only its own kind of email
    Given "alice" holds the unsubscribe link from their progress report
    When the unsubscribe link is used without signing in
    Then "alice" has the email preference "reminders" on

  @wip
  Scenario: An unsubscribe link from a reminder turns reminders off
    Given "alice" holds the unsubscribe link from their inactivity reminder
    When the unsubscribe link is used without signing in
    Then "alice" has the email preference "reminders" off

  # ── Edge cases ─────────────────────────────────────────────────────────────

  @wip
  Scenario: Using an unsubscribe link again still succeeds
    Given "alice" holds the unsubscribe link from their progress report
    And the unsubscribe link has already been used
    When the unsubscribe link is used without signing in
    Then the unsubscribe succeeds
    And "alice" has the email preference "progress_report" off

  @wip
  Scenario: An old unsubscribe link still works after the kind was turned back on
    Given "alice" holds the unsubscribe link from a progress report sent 6 months ago
    And "alice" used it to turn progress reports off, then turned them back on in settings
    When the unsubscribe link is used without signing in
    Then "alice" has the email preference "progress_report" off

  # ── Failures ───────────────────────────────────────────────────────────────

  @wip
  Scenario: An altered unsubscribe token is refused and changes nothing
    Given "alice" holds the unsubscribe link from their progress report
    When the unsubscribe link is used with one character of its token changed
    Then the request is rejected as invalid
    And "alice" has the email preference "progress_report" on

  @wip
  Scenario: An unsubscribe request without a token is refused
    When an unsubscribe request is sent with no token
    Then the request is rejected as invalid

  # ── The web confirms the change ────────────────────────────────────────────

  @web
  Scenario: Opening the footer link shows which emails stopped and links to the settings
    Given "alice" holds the unsubscribe link from their progress report
    When "alice" opens the unsubscribe link in a browser without signing in
    Then the page says they will no longer get progress reports
    And the page links to their email settings

  @web
  Scenario: Opening a broken footer link explains that it didn't work
    When someone opens an unsubscribe link whose token was altered
    Then the page says the link didn't work and nothing was changed
    And the page links to the email settings
