Feature: Derive a student's knowledge of an item from evidence
  As the MotifPath platform
  I want each item's level and review schedule derived from the student's evidence alone
  So that progress can be explained, recomputed when a rule improves, and never drifts

  # Rules: counted evidence becomes a hit, a miss or a hold. Sources weigh auto-graded 0.3,
  # self-assessed 0.3, teacher-reviewed 0.6. Leitner boxes wait 1, 2, 4, 8, 16, 32 days.
  # accurate = 3+ counted attempts and accuracy >= 0.8; fluent = 5+ attempts, accuracy >= 0.9
  # and fluency >= 0.8; retained = fluent in box 5 or higher. A pick among choices counts like
  # any answer: right 1, wrong 0 (the -1/(k-1) guess rule of 2026-10-08 was withdrawn on 2026-10-14).

  Background:
    Given student "alice" practises the guitar fretboard cell on string 5 at fret 3
    And the fluent time for naming a note is 2000 milliseconds net of tap time

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: An item never practised is new
    Then "alice"'s level for the cell is "new"

  Scenario: Three right answers make an item accurate
    When "alice" answers the cell correctly 3 times on 3 different days
    Then "alice"'s level for the cell is "accurate"

  Scenario: Five right answers within the fluent time make an item fluent
    Given "alice"'s tap time is 300 milliseconds
    When "alice" answers the cell correctly 5 times, each in 1900 milliseconds
    Then "alice"'s level for the cell is "fluent"

  Scenario: Answers given while reviewing a finished course count like any other
    When "alice" answers the cell correctly 3 times on 3 different days, each marked as review
    Then "alice"'s level for the cell is "accurate"

  Scenario: A fluent item that holds up in long reviews is retained
    Given "alice" is fluent on the cell and the cell is in box 4
    When "alice" answers the cell correctly when it falls due
    Then the cell moves to box 5
    And "alice"'s level for the cell is "retained"

  # ── Spaced repetition ──────────────────────────────────────────────────────

  Scenario: A right answer on a due item moves it up one box
    Given the cell is in box 2 and due today
    When "alice" answers the cell correctly
    Then the cell moves to box 3 and is next due in 4 days

  Scenario: A right answer before the item is due doesn't move it
    Given the cell is in box 2 and due in 1 day
    When "alice" answers the cell correctly
    Then the cell stays in box 2

  Scenario: A wrong answer sends the item back to box 1
    Given the cell is in box 4
    When "alice" answers the cell wrongly
    Then the cell moves to box 1 and is next due in 1 day

  # ── Picks among choices ────────────────────────────────────────────────────
  # No guess correction (ADR-057, withdrawing ADR-046's 1/(k-1) rule before it shipped): a wrong
  # pick among choices counts 0 like any wrong answer. A lucky guess is caught by asking the item
  # again, the other way or later in the session.

  Scenario: A wrong pick among four note choices counts as a plain miss
    When "alice" names the cell among four choices, right 3 times and then wrong once
    Then "alice"'s accuracy on the cell is 0.7, as after any wrong answer
    And "alice"'s level for the cell is "learning"

  # ── Find every instance (MOT-153) ──────────────────────────────────────────
  # One find every instance answer gives evidence on every cell of its window, for accuracy only:
  # its time covers several taps, so it never counts toward a cell's fluency.

  Scenario: Right answers from finding every instance make a cell accurate, never fluent
    When "alice" finds every instance of the cell's note correctly 5 times on 5 different days, each in 1500 milliseconds
    Then "alice"'s level for the cell is "accurate"

  Scenario: A cell is fluent from timed answers, whatever finding every instance adds
    Given "alice"'s tap time is 300 milliseconds
    And "alice" has found every instance of the cell's note correctly 3 times
    When "alice" answers the cell correctly 5 times, each in 1900 milliseconds
    Then "alice"'s level for the cell is "fluent"

  # ── Self-rated and teacher-reviewed takes ──────────────────────────────────

  Scenario: A self-rating of almost changes nothing
    Given "alice" practises the play-along "pentatonic-run" and it is in box 2
    When "alice" rates a take of "pentatonic-run" as "almost" at 90 BPM
    Then "pentatonic-run" stays in box 2

  Scenario: A take that isn't clean above the best clean tempo doesn't count against the student
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "struggled" at 115 BPM
    Then the take is not counted as a miss

  Scenario: A take that isn't clean at or below the best clean tempo is a real miss
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "struggled" at 100 BPM
    Then the take is counted as a miss

  # A take's tempo is compared at effective speed: its BPM times its note value's factor
  # (quarters x1, eighths x2, triplets x3, sixteenths x4; no note value = quarters; ADR-061).
  Scenario: A clean take in eighths beats a faster-looking tempo in quarters
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "clean" at 60 BPM in eighths
    Then "alice"'s best clean tempo on "pentatonic-run" is 60 BPM in eighths

  Scenario: A take in eighths that isn't clean above the best clean tempo's effective speed doesn't count
    Given "alice"'s best clean tempo on "pentatonic-run" is 110 BPM
    When "alice" rates a take of "pentatonic-run" as "struggled" at 60 BPM in eighths
    Then the take is not counted as a miss

  Scenario: A take in quarters slower than a best clean tempo in eighths is a real miss
    Given "alice"'s best clean tempo on "pentatonic-run" is 60 BPM in eighths
    When "alice" rates a take of "pentatonic-run" as "struggled" at 110 BPM
    Then the take is counted as a miss

  # A chord change's fluency is its clean count over the catalog's change target, 60 clean changes
  # a minute; a single chord has no measure, so a clean take is fully fluent (MOT-79).
  Scenario: Five clean minutes near the target make a chord change fluent
    Given "alice" practises the chord change "a-minor-open" to "c-open"
    When "alice" plays 5 clean minutes of it on 5 different days, each 54 clean changes at 60 BPM
    Then "alice"'s level for the chord change is "fluent"

  Scenario: Clean minutes far below the target leave a chord change accurate, not fluent
    Given "alice" practises the chord change "a-minor-open" to "c-open"
    When "alice" plays 5 clean minutes of it on 5 different days, each 30 clean changes at 30 BPM
    Then "alice"'s level for the chord change is "accurate"

  Scenario: A struggled minute above the best clean count doesn't count against the student
    Given "alice"'s best clean count on the chord change "a-minor-open" to "c-open" is 40
    When "alice" plays a minute of it with 45 clean changes at 90 BPM
    Then the minute is not counted as a miss

  Scenario: A struggled minute at or below the best clean count is a real miss
    Given "alice"'s best clean count on the chord change "a-minor-open" to "c-open" is 40
    When "alice" plays a minute of it with 30 clean changes at 60 BPM
    Then the minute is counted as a miss

  Scenario: Five clean takes make a single chord fluent
    Given "alice" practises the single chord "a-minor-open"
    When "alice" rates 5 takes of it "clean" on 5 different days
    Then "alice"'s level for the single chord is "fluent"

  # A song has no measure either: a clean rating is fully fluent (MOT-152).
  Scenario: Five clean ratings make a song fluent
    Given "alice" practises the song "Amazing Grace" on guitar
    When "alice" rates it "clean" on 5 different days
    Then "alice"'s level for the song is "fluent"

  # Parked until ADR-046 follow-up slice 5 (teacher notes): no teacher review exists yet.
  @wip
  Scenario: A teacher review resets the student's own best clean tempo
    Given "alice" rated "pentatonic-run" clean at 120 BPM
    When a teacher reviews "alice"'s "pentatonic-run" as clean at 100 BPM and verified
    Then "alice"'s best clean tempo on "pentatonic-run" is 100 BPM
    And "pentatonic-run" is verified for "alice"

  # A progression key tour's fluency is a take's effective speed over the tour target, 100 BPM, as
  # for a play-along's tempo over its target (MOT-150).
  Scenario: Five clean takes at the target make a progression key tour fluent
    Given "alice" practises the progression key tour of "I-V-vi-IV" on guitar
    When "alice" rates 5 takes of it "clean" at 100 BPM on 5 different days, each in another key
    Then "alice"'s level for the progression key tour is "fluent"

  Scenario: Clean takes far below the target leave a progression key tour accurate, not fluent
    Given "alice" practises the progression key tour of "I-V-vi-IV" on guitar
    When "alice" rates 5 takes of it "clean" at 60 BPM on 5 different days, each in another key
    Then "alice"'s level for the progression key tour is "accurate"

  # A guide tone's fluency is a right take's effective speed over 90 BPM, as for a play-along's
  # tempo over its target; its latency is kept but never judged (MOT-151).
  Scenario: Five right guide-tone takes at 72 BPM make the guide tone fluent
    Given "alice" practises the guide tone of "ii-V-I" on guitar
    When "alice" makes 5 right takes of it at 72 BPM on 5 different days
    Then "alice"'s level for the guide tone is "fluent"

  Scenario: Right guide-tone takes at 60 BPM leave the guide tone accurate, not fluent
    Given "alice" practises the guide tone of "ii-V-I" on guitar
    When "alice" makes 5 right takes of it at 60 BPM on 5 different days
    Then "alice"'s level for the guide tone is "accurate"

  Scenario: A guide-tone take in eighths counts at its effective speed
    Given "alice" practises the guide tone of "ii-V-I" on guitar
    When "alice" makes 5 right takes of it at 45 BPM in eighths on 5 different days
    Then "alice"'s level for the guide tone is "fluent"

  Scenario: A slow right take with a late hit is not held against the student
    Given "alice" practises the guide tone of "ii-V-I" on guitar
    When "alice" makes 5 right takes of it at 90 BPM on 5 different days, each hitting a bar 2000 milliseconds after its downbeat
    Then "alice"'s level for the guide tone is "fluent"

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The same answer delivered twice counts once
    When the same practice.item_answered event for the cell arrives twice
    Then "alice" has one piece of evidence for the cell

  Scenario: An answer that arrives late is placed in time order
    Given "alice" answered the cell correctly on Monday and Wednesday
    When "alice"'s wrong answer from Tuesday arrives after Wednesday's
    Then "alice"'s state for the cell is the same as if the three answers had arrived in order

  Scenario: A timed answer is judged by the fluent time in force when it was given
    Given "alice" answered the cell correctly in 2200 milliseconds when the fluent time was 2500 milliseconds
    When the fluent time for naming a note changes to 1800 milliseconds
    Then that answer still counts as within the fluent time

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A rejected answer leaves the item's state unchanged
    Given "alice" is accurate on the cell
    When "alice" sends an answer to the cell that the grader rejects
    Then "alice"'s level for the cell is still "accurate"
    And "alice" has no new evidence for the cell

  Scenario: A felt rating never counts toward mastery
    Given "alice" is accurate on the cell
    When "alice" says naming notes felt "easy" at the end of a session
    Then "alice"'s level for the cell is still "accurate"
