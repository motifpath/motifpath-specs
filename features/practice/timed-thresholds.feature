@wip
Feature: Judge timed drills against versioned fluent times
  As the MotifPath platform
  I want each timed drill's fluent time to be versioned reference data, calibrated from how drills felt
  So that "fluent" means the same for every student and only ever improves

  Background:
    Given the drill template "fretboard_cell:name_the_note" has version 1 with a fluent time of 2000 milliseconds net of tap time
    And student "alice" has a tap time of 300 milliseconds

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: An answer's time is judged net of the student's tap time
    When "alice" names the note of a cell correctly in 2200 milliseconds
    Then the answer took 1900 milliseconds net of tap time
    And it counts as within the fluent time

  Scenario: Calibration adds a version once the template has enough felt-rated sessions
    Given "fretboard_cell:name_the_note" has 120 felt-rated sessions from 25 students
    When calibration runs for "fretboard_cell:name_the_note"
    Then version 2 is added with source "calibrated", 120 sessions and 25 students
    And version 1 stays as it was

  Scenario: A new version applies from its start date on
    Given version 2 of "fretboard_cell:name_the_note" has a fluent time of 1700 milliseconds from 2026-11-01
    When "alice" names the note of a cell correctly on 2026-11-02 in 2100 milliseconds
    Then the answer is judged against 1700 milliseconds and counts as slower than fluent

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A new version never takes back a level
    Given "alice" became fluent on a cell with answers judged against version 1
    When version 2 lowers the fluent time to 1700 milliseconds
    Then "alice" is still fluent on that cell

  Scenario: A student who never did a tap check is judged on the whole latency
    Given student "bruno" has never done a tap check
    When "bruno" names the note of a cell correctly in 2200 milliseconds
    Then the answer took 2200 milliseconds net of tap time
    And it counts as slower than fluent

  Scenario: Calibration waits until at least 100 sessions from 20 students
    Given "fretboard_cell:name_the_note" has 150 felt-rated sessions from 12 students
    When calibration runs for "fretboard_cell:name_the_note"
    Then no new version is added

  Scenario: One calibration step changes the fluent time by at most 25 percent
    Given "fretboard_cell:name_the_note" has 200 felt-rated sessions from 40 students that point to 1200 milliseconds
    When calibration runs for "fretboard_cell:name_the_note"
    Then version 2 has a fluent time of 1500 milliseconds

  Scenario: Authored exercises of one type share one fluent time
    Given the drill template "exercise:audio_recognition" has version 1 with a fluent time of 6000 milliseconds
    When "alice" answers two different listening exercises correctly
    Then both answers are judged against the fluent time of "exercise:audio_recognition"

  Scenario: Every exercise family starts from a default fluent time
    Given the drill template "exercise:text_response" has version 1 from source "default" with a fluent time of 6000 milliseconds
    When "alice" answers a text exercise correctly in 5500 milliseconds
    Then the answer took 5200 milliseconds net of tap time
    And it counts as within the fluent time

  Scenario: A listening exercise is judged on the time after its audio
    Given the drill template "exercise:audio_recognition" has version 1 from source "default" with a fluent time of 4000 milliseconds
    When "alice" answers a listening exercise whose sound lasts 5000 milliseconds correctly in 9000 milliseconds
    Then the answer took 3700 milliseconds net of tap time and audio
    And it counts as within the fluent time

  Scenario: A sound-choice exercise is judged on the time after all its sound options
    Given the drill template "exercise:audio_selection" has version 1 from source "default" with a fluent time of 4000 milliseconds
    When "alice" answers a sound-choice exercise with 3 sound options of 2000 milliseconds each correctly in 11000 milliseconds
    Then the answer took 4700 milliseconds net of tap time and audio
    And it counts as slower than fluent

  Scenario: A benchmark added after a default applies from its start date on
    Given the drill template "exercise:image_choice" has version 1 from source "default" with a fluent time of 5000 milliseconds
    And version 2 from source "benchmark" with a fluent time of 4000 milliseconds from 2026-11-01
    When "alice" answers an image-choice exercise correctly on 2026-11-02 in 4800 milliseconds
    Then the answer is judged against 4000 milliseconds and counts as slower than fluent

  Scenario: The felt questions go to the session's least-calibrated timed drills, two at most
    Given "alice"'s session practised "fretboard_cell:name_the_note", "fretboard_cell:find_the_note" and "exercise:text_response"
    And "fretboard_cell:find_the_note" and "exercise:text_response" have the fewest felt-rated sessions
    When the session ends
    Then "alice" is asked how "fretboard_cell:find_the_note" and "exercise:text_response" felt
    And "alice" is not asked about "fretboard_cell:name_the_note"

  Scenario: Play-alongs are never asked how they felt
    Given "alice"'s session practised only play-alongs
    When the session ends
    Then "alice" is asked no felt questions

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: An answer given before a template has any version counts for accuracy only
    Given the drill template "fretboard_cell:find_the_note" has no version yet
    When "alice" finds a note correctly in 900 milliseconds
    Then the answer counts toward "alice"'s accuracy
    And it never counts toward fluency, even after version 1 is installed

  Scenario: A felt rating for a drill the session didn't practise is ignored
    Given "alice"'s session practised only "fretboard_cell:name_the_note"
    When the session ends with "exercise:image_choice" rated "hard"
    Then the rating is not used to calibrate "exercise:image_choice"
