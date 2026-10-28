Feature: Send students a weekly progress report and reminders, and the concierge a weekly summary
  As the MotifPath platform
  I want to remind students of their progress and nudge them kindly when they stop
  So that more of them come back within a week and keep learning past their first months

  # ADR-065. The engagement mailer runs every hour. On each run it checks every student against
  # the rules below, in the student's own time zone. A student with no time zone set is taken
  # to be in "America/Sao_Paulo".
  #
  # Who can get a student email: anyone who is learning, whatever their role. Teachers and
  # admins learn too, so "student" in these rules means any user, of any role, who has started
  # a course or a path (a course enrolment or a standalone path, active or not) and whose user
  # record holds an email address. A user who has never started anything is in the first run,
  # or only authors, and gets no email.
  # Each kind also needs its email preference on: "progress_report" for the report,
  # "reminders" for a reminder.
  #
  # Activity: anything the student does that sends an event counts: practising, working on a
  # lesson or an exercise, or using a song chart. A student's last activity is the time of
  # their latest event of any kind; days without activity are counted from it, in their time
  # zone. A student who reads song charts every day has not stopped, so is never reminded.
  #
  # A week has something to show when, in it, the student started a practice session,
  # completed a lesson, or played a song. Only such a week gets a progress report: a report
  # of zeros would discourage, and the reminders already cover a student who stopped.
  #
  # The figures in a report follow the home overview's rules (ADR-046, ADR-051) for the week
  # that ended on Sunday: practice days, minutes practised that week and the week before, the
  # current and best day streak, skills up and songs played. No email ever says a streak was
  # lost or broken (ADR-051).
  #
  # Reminders: one switch, "reminders", covers two kinds. A daily reminder goes out on the 1st
  # and the 2nd day without activity, so a student who hasn't been active yet that day is
  # reminded in the evening. An inactivity reminder goes out on the 3rd day, and a second one on
  # the 10th. The daily reminders stop once the inactivity reminders start, and nothing goes out
  # after the 10th day, so a student who has stopped isn't emailed every day. A student gets at
  # most one reminder a day.
  #
  # Each email is sent at most once. A report is sent once per student per week. A reminder is
  # sent once per student per day of the same inactive spell. A reminder whose evening the
  # mailer missed is skipped, not sent the next day. If the mailer can't run for a whole Monday,
  # that week's report is skipped, not sent late.
  #
  # Emails are written in the student's locale: "pt_BR" in Portuguese (Brazil), and every other
  # locale in English.
  #
  # PO thresholds: the report from Monday 09:00; every reminder from 18:00, daily reminders on
  # the 1st and the 2nd day without activity and inactivity reminders on the 3rd and the 10th;
  # the concierge summary from Monday 08:00 in "America/Sao_Paulo".

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "alice" has already registered as a student
    And "alice"'s email address is "alice@example.com"
    And "alice"'s time zone is "America/Sao_Paulo"
    And "alice" is enrolled in the course "fingerstyle-journey"
    And "alice" has the email preferences "progress_report" on and "reminders" on

  # ── Weekly progress report ─────────────────────────────────────────────────

  Scenario: A student who learned last week gets a progress report on Monday morning
    Given "alice" practised on 4 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a progress report at "alice@example.com"

  Scenario: The progress report shows the week's figures
    Given "alice" practised on 4 days of the week that ended on Sunday, for 75 minutes in all
    And "alice" practised for 50 minutes the week before
    And "alice"'s current day streak is 2 and their best is 6
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s progress report shows 4 practice days and 75 minutes, up from 50
    And "alice"'s progress report shows a current day streak of 2 and a best of 6

  Scenario: A progress report with no current streak invites the student to start one
    Given "alice" practised on 2 days of the week that ended on Sunday, but not on Saturday or Sunday
    And "alice"'s best day streak is 6
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s progress report invites them to start a day streak and shows their best of 6
    And "alice"'s progress report doesn't say a streak was lost or broken

  Scenario: The progress report arrives on Monday morning in the student's own time zone
    Given "alice"'s time zone is "Europe/Lisbon"
    And "alice" practised on 3 days of the week that ended on Sunday
    And it is Monday 08:00 in "Europe/Lisbon"
    When the engagement mailer runs
    Then "alice" is not sent a progress report
    And at Monday 09:00 in "Europe/Lisbon" the next run sends "alice" a progress report

  Scenario: A student with no time zone gets the progress report on Monday morning in São Paulo
    Given "alice" has no time zone set
    And "alice" practised on 3 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a progress report

  Scenario: A student gets one progress report per week however often the mailer runs
    Given "alice" practised on 3 days of the week that ended on Sunday
    And "alice" was sent a progress report at Monday 09:00 in "America/Sao_Paulo"
    And it is Monday 10:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent another progress report

  Scenario: A week with nothing to show gets no progress report
    Given "alice" started no practice session, completed no lesson and played no song in the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a progress report

  Scenario: A week with only a completed lesson still gets a progress report
    Given "alice" completed a lesson on Wednesday of the week that ended on Sunday and didn't practise
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a progress report

  Scenario: A student who turned progress reports off gets none
    Given "alice" has the email preference "progress_report" off
    And "alice" practised on 3 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a progress report

  Scenario: A week whose Monday the mailer missed gets no late report
    Given "alice" practised on 3 days of the week that ended on Sunday
    And the engagement mailer didn't run on Monday
    And it is Tuesday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a progress report

  Scenario: A progress report is written in the student's locale
    Given "alice" has locale "pt_BR"
    And "alice" practised on 3 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s progress report is written in Portuguese (Brazil)

  Scenario: A progress report offers a one-click unsubscribe from progress reports
    Given "alice" practised on 3 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s progress report carries an unsubscribe link for progress reports

  # ── Daily reminders ────────────────────────────────────────────────────────

  Scenario: A student not yet active today gets a daily reminder that evening
    Given "alice"'s last activity was on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a daily reminder at "alice@example.com"

  Scenario: No daily reminder before 18:00
    Given "alice"'s last activity was on Sunday
    And it is Monday 17:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a daily reminder

  Scenario: A student already active today gets no daily reminder
    Given "alice"'s last activity was on Monday at 12:00
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a daily reminder

  Scenario: A student with 2 days without activity gets a daily reminder
    Given "alice"'s last activity was on Saturday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a daily reminder
    And "alice" is not sent an inactivity reminder

  Scenario: The 3rd day gets an inactivity reminder instead of a daily one
    Given "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent an inactivity reminder
    And "alice" is not sent a daily reminder

  Scenario: No daily reminder between the 3rd and the 10th day
    Given "alice"'s last activity was 5 days ago
    And it is 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a daily reminder
    And "alice" is not sent an inactivity reminder

  Scenario: A student gets one daily reminder a day however often the mailer runs
    Given "alice"'s last activity was on Sunday
    And "alice" was sent a daily reminder at Monday 18:00 in "America/Sao_Paulo"
    And it is Monday 19:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent another daily reminder

  Scenario: A student who turned reminders off gets no daily reminder
    Given "alice" has the email preference "reminders" off
    And "alice"'s last activity was on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent a daily reminder

  Scenario: A daily reminder is written in the student's locale
    Given "alice" has locale "pt_BR"
    And "alice"'s last activity was on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s daily reminder is written in Portuguese (Brazil)

  Scenario: A daily reminder doesn't mention a streak
    Given "alice" had a day streak of 6 that ended on Sunday
    And "alice"'s last activity was on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s daily reminder doesn't mention a day streak

  Scenario: A daily reminder offers a one-click unsubscribe from reminders
    Given "alice"'s last activity was on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s daily reminder carries an unsubscribe link for reminders

  # ── Inactivity reminders ───────────────────────────────────────────────────

  Scenario: A student with 3 days without activity gets a reminder that evening
    Given "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent an inactivity reminder at "alice@example.com"

  Scenario: No reminder before 18:00 on the 3rd day
    Given "alice"'s last activity was on Friday
    And it is Monday 17:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent an inactivity reminder

  Scenario: Using a song chart counts as activity
    Given "alice"'s last practice session was on Friday
    And "alice" opened a song chart on Sunday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent an inactivity reminder

  Scenario: A student still inactive on the 10th day gets a second reminder
    Given "alice"'s last activity was 10 days ago
    And "alice" was sent an inactivity reminder on the 3rd day
    And it is 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent a second inactivity reminder

  Scenario: A student gets no reminder after the 10th day of an inactive spell
    Given "alice"'s last activity was 20 days ago
    And "alice" was sent inactivity reminders on the 3rd and the 10th day
    And it is 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent an inactivity reminder

  Scenario: A student who comes back starts a new spell and can be reminded again
    Given "alice" was sent inactivity reminders on the 3rd and the 10th day of an earlier spell
    And "alice" practised 3 days ago and had no activity since
    And it is 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent an inactivity reminder

  Scenario: A student gets one reminder per threshold however often the mailer runs
    Given "alice"'s last activity was on Friday
    And "alice" was sent an inactivity reminder at Monday 18:00 in "America/Sao_Paulo"
    And it is Monday 19:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent another inactivity reminder

  Scenario: A student who has finished their courses is still reminded
    Given "alice"'s only course enrolment is completed
    And "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is sent an inactivity reminder

  Scenario: A student who has never started a course or a path gets no reminder
    Given "bruno" has already registered as a student
    And "bruno" has never started a course or a path
    And "bruno" registered 5 days ago
    And it is 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "bruno" is not sent an inactivity reminder

  Scenario: A student who turned reminders off gets none
    Given "alice" has the email preference "reminders" off
    And "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice" is not sent an inactivity reminder

  Scenario: A reminder doesn't mention a streak
    Given "alice" had a day streak of 6 that ended on Friday
    And "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s inactivity reminder doesn't mention a day streak

  Scenario: A reminder offers a one-click unsubscribe from reminders
    Given "alice"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "alice"'s inactivity reminder carries an unsubscribe link for reminders

  # ── Students the mailer can't reach ────────────────────────────────────────

  Scenario: A student with no email address on record gets no email
    Given "carla" registered as a student before email addresses were stored and hasn't signed in since
    And "carla" is enrolled in the course "fingerstyle-journey"
    And "carla"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "carla" is not sent an inactivity reminder

  Scenario: A teacher who has never started learning gets no engagement email
    Given "bob" has already registered as a teacher
    And "bob"'s email address is "bob@example.com"
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "bob" is not sent any email

  @wip
  Scenario: A teacher who has started learning gets the same emails as a student
    Given "bob" has already registered as a teacher
    And "bob"'s email address is "bob@example.com"
    And "bob" is enrolled in the course "fingerstyle-journey"
    And "bob"'s last activity was on Friday
    And it is Monday 18:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "bob" is sent an inactivity reminder at "bob@example.com"

  @wip
  Scenario: An admin who has started learning gets the same emails as a student
    Given "marina" has already registered as an admin
    And "marina"'s email address is "marina@example.com"
    And "marina" is enrolled in the course "fingerstyle-journey"
    And "marina" practised on 3 days of the week that ended on Sunday
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then "marina" is sent a progress report at "marina@example.com"

  # ── Weekly summary for the concierge ───────────────────────────────────────

  Scenario: The concierge gets a weekly summary on Monday morning
    Given the concierge's email address is "concierge@motifpath.com"
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then a student summary is sent to "concierge@motifpath.com"

  Scenario: The concierge summary has a row for each student who has started learning
    Given the concierge's email address is "concierge@motifpath.com"
    And "alice" practised on 4 days of the week that ended on Sunday, for 75 minutes in all
    And "alice"'s last activity was on Sunday
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then the student summary's row for "alice" shows their name, 4 practice days, 75 minutes and their last activity on Sunday

  @wip
  Scenario: The concierge summary includes a teacher who has started learning
    Given the concierge's email address is "concierge@motifpath.com"
    And "bob" has already registered as a teacher
    And "bob" is enrolled in the course "fingerstyle-journey"
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then the student summary has a row for "bob"

  Scenario: The concierge summary lists the students inactive longest first
    Given the concierge's email address is "concierge@motifpath.com"
    And "alice"'s last activity was 1 day ago
    And "dani" is a student enrolled in a course, whose last activity was 12 days ago
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then the student summary lists "dani" before "alice"

  Scenario: The concierge summary includes students who turned their own emails off
    Given the concierge's email address is "concierge@motifpath.com"
    And "alice" has the email preferences "progress_report" off and "reminders" off
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then the student summary has a row for "alice"

  Scenario: The concierge gets one summary per week
    Given the concierge's email address is "concierge@motifpath.com"
    And a student summary was sent at Monday 08:00 in "America/Sao_Paulo"
    And it is Monday 09:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then no other student summary is sent

  Scenario: No concierge summary is sent when no concierge address is configured
    Given no concierge email address is configured
    And it is Monday 08:00 in "America/Sao_Paulo"
    When the engagement mailer runs
    Then no student summary is sent
