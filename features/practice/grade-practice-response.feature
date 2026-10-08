Feature: Grade a practice answer into evidence
  As the MotifPath platform
  I want to grade every practice answer from the student's raw response
  So that what the platform knows about a student rests on answers it checked itself

  # The grading rules are pinned case by case in golden/practice-graders/, which both the
  # server and the web client run. These scenarios state the behaviour in domain terms.

  Background:
    Given the instrument "guitar" in standard tuning E2 A2 D3 G3 B3 E4
    And student "alice" is practising in practice session "morning-session"

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Naming the right note of a fretboard cell is evidence of a correct answer
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" after 1800 milliseconds
    Then "alice" has auto-graded evidence for that cell that is correct with a latency of 1800 milliseconds

  Scenario: Naming a wrong note of a fretboard cell is evidence of a wrong answer
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" after 2500 milliseconds
    Then "alice" has auto-graded evidence for that cell that is wrong with a latency of 2500 milliseconds

  Scenario: Selecting exactly the correct options of an exercise is a correct answer
    Given the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" answers exercise "c-major-triad" by selecting "E" and "C"
    Then "alice" has auto-graded evidence for exercise "c-major-triad" that is correct

  Scenario: A self-rated play-along take is kept with its rating and tempo
    Given the play-along diagram "pentatonic-run"
    When "alice" rates a take of play-along "pentatonic-run" as "clean" at 90 BPM
    Then "alice" has self-assessed evidence for play-along "pentatonic-run" rated "clean" at 90 BPM

  Scenario: Evidence keeps the raw response and the event that sent it
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" after 1800 milliseconds
    Then the evidence keeps the response exactly as "alice" sent it
    And the evidence is identified by the identifier of the practice.item_answered event

  @wip
  Scenario: A fretboard cell answer is graded by fretboard_cell.v2
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" among "B", "F", "C" and "C#" after 1500 milliseconds
    Then the evidence names the grader "fretboard_cell.v2"

  Scenario: Evidence keeps what a right answer was for a fretboard cell
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" after 2500 milliseconds
    Then the evidence's answer key is string 5, fret 3, note "C"

  @wip
  Scenario: Naming the note among four choices keeps the choices in the answer key
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C#" among "B", "F", "C" and "C#" after 1700 milliseconds
    Then "alice" has auto-graded evidence for that cell that is wrong with a latency of 1700 milliseconds
    And the evidence's answer key is string 5, fret 3, note "C", with the choices "B", "F", "C" and "C#"

  Scenario: Naming the right member of a diagram shape's family is a correct answer
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by naming the shape "A" after 2600 milliseconds
    Then "alice" has auto-graded evidence for that shape that is correct with a latency of 2600 milliseconds
    And the evidence names the grader "diagram_shape.v1"
    And the evidence's answer key is the family "caged-grip", member "A"

  Scenario: Tapping a position of the asked degree is a correct answer
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by finding the degree "3" on string 2 at fret 5 after 2400 milliseconds
    Then "alice" has auto-graded evidence for that shape that is correct with a latency of 2400 milliseconds
    And the evidence's answer key is the degree "3" at string 2, fret 5

  Scenario: Evidence keeps an exercise's options as the student saw them
    Given the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" answers exercise "c-major-triad" by selecting "D"
    And the exercise's options are later edited to "C", "E", "G" and "B", with "G" correct as well
    Then the evidence's answer key shows the options "C", "D", "E" and "F", with "C" and "E" correct

  Scenario: An answer in a node's challenge is evidence like an answer in a practice session
    Given "alice" is taking the challenge "open-chords-assessment" of the content node "open-chords"
    When "alice" answers the exercise "minor-third-from-a" in the challenge by selecting its correct option after 3500 milliseconds
    Then "alice" has auto-graded evidence for "minor-third-from-a" that is correct with a latency of 3500 milliseconds
    And the evidence names the challenge "open-chords-assessment" instead of a practice session

  Scenario: An exercise with audio keeps the audio's length with its evidence
    When "alice" answers a listening exercise whose sound lasts 5000 milliseconds by selecting its correct option after 9500 milliseconds
    Then "alice" has auto-graded evidence for that exercise with a latency of 9500 milliseconds and 5000 milliseconds of audio

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: Another spelling of the right pitch is a correct answer
    When "alice" answers the guitar cell on string 6 at fret 2 by naming the note "Gb" after 2100 milliseconds
    Then "alice" has auto-graded evidence for that cell that is correct with a latency of 2100 milliseconds

  Scenario: Finding the asked note an octave up on the asked string is a correct answer
    When "alice" is asked for the guitar cell on string 6 at fret 1 and taps string 6 at fret 13
    Then "alice" has auto-graded evidence for that cell that is correct

  Scenario: Finding the asked pitch on another string is a wrong answer
    When "alice" is asked for the guitar cell on string 6 at fret 1 and taps string 4 at fret 3
    Then "alice" has auto-graded evidence for that cell that is wrong

  Scenario: Selecting only some of an exercise's correct options is a wrong answer
    Given the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" answers exercise "c-major-triad" by selecting "C"
    Then "alice" has auto-graded evidence for exercise "c-major-triad" that is wrong

  Scenario: A timed answer's evidence carries the student's tap time
    Given "alice" completed a tap check with a median tap of 350 milliseconds
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" after 1800 milliseconds
    Then the evidence for that cell records a tap time of 350 milliseconds

  @web
  Scenario: A challenge exercise's answer is the selection the student moves on with
    Given "alice" is taking the challenge "open-chords-assessment" of the content node "open-chords"
    And the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" selects "C", then also "E", and moves on to the next exercise
    Then "alice" has one piece of evidence for "c-major-triad", and it is correct

  @web
  Scenario: Changing a challenge answer after going back is not a new answer
    Given "alice" is taking the challenge "open-chords-assessment" of the content node "open-chords"
    And "alice" moved on from the exercise "minor-third-from-a" with a wrong option selected
    When "alice" goes back to "minor-third-from-a", selects its correct option and moves on again
    Then "alice"'s only evidence for "minor-third-from-a" is the wrong answer

  Scenario: Working through a challenge again gives new answers
    Given "alice" took the challenge "open-chords-assessment" yesterday and answered "minor-third-from-a" wrong
    When "alice" takes "open-chords-assessment" again and moves on from "minor-third-from-a" with its correct option selected
    Then "alice" has two pieces of evidence for "minor-third-from-a", the second one correct

  Scenario: Naming another member of a diagram shape's family is a wrong answer
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by naming the shape "E" after 3100 milliseconds
    Then "alice" has auto-graded evidence for that shape that is wrong with a latency of 3100 milliseconds

  Scenario: Any position of the asked degree in the shape is a correct answer
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by finding the degree "5" on string 1 at fret 3 after 2200 milliseconds
    Then "alice" has auto-graded evidence for that shape that is correct with a latency of 2200 milliseconds

  Scenario: Tapping the asked degree's pitch outside the shape is a wrong answer
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by finding the degree "3" on string 4 at fret 2 after 3000 milliseconds
    Then "alice" has auto-graded evidence for that shape that is wrong with a latency of 3000 milliseconds

  # ── Failure cases ──────────────────────────────────────────────────────────

  @wip
  Scenario: Choices that leave out the cell's note yield no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" among "B", "C#", "D" and "F" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  @wip
  Scenario: A note named that isn't among the choices yields no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" among "B", "F", "C" and "C#" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  @wip
  Scenario: Two choices spelling the same pitch yield no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" among "C", "B#", "C#" and "F" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  @wip
  Scenario: An item skipped because its sound failed to load yields no evidence
    Given the exercise "hear-the-fifth" whose correct option is "Perfect fifth" out of "Perfect fourth" and "Perfect fifth"
    When "alice" sends exercise "hear-the-fifth" as not answered because its stimulus failed to load
    Then the practice.item_answered event is kept with the reason "failed_to_load"
    And "alice" has no evidence for exercise "hear-the-fifth"

  @wip
  Scenario: An item that can't be shown leaves its level and review as they were
    Given "alice" is accurate on the guitar cell on string 5 at fret 3, in box 2 and due today
    When "alice" sends that cell as not answered because it is unavailable
    Then "alice"'s level for that cell is still "accurate"
    And the cell stays in box 2 and due today

  Scenario: A response that doesn't fit the item yields no evidence
    Given the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" answers the guitar cell on string 5 at fret 3 by selecting option "C" of exercise "c-major-triad"
    Then the answer is rejected because the response does not fit the item
    And "alice" has no evidence for that cell

  Scenario: Selecting an option the exercise doesn't have yields no evidence
    Given the exercise "c-major-triad" whose correct options are "C" and "E" out of "C", "D", "E" and "F"
    When "alice" answers exercise "c-major-triad" by selecting an option of another exercise
    Then the answer is rejected because the option is unknown
    And "alice" has no evidence for exercise "c-major-triad"

  Scenario: A play-along rating without its tempo yields no evidence
    Given the play-along diagram "pentatonic-run"
    When "alice" rates a take of play-along "pentatonic-run" as "clean" without a tempo
    Then the answer is rejected because its measure is missing
    And "alice" has no evidence for play-along "pentatonic-run"

  Scenario: A cell on a string the instrument doesn't have yields no evidence
    When "alice" answers the guitar cell on string 7 at fret 3 by naming the note "C" after 1800 milliseconds
    Then the answer is rejected because the cell is not on the instrument
    And "alice" has no evidence for that cell

  Scenario: Naming a shape its family doesn't have yields no evidence
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by naming the shape "3" after 2000 milliseconds
    Then the answer is rejected because the option is unknown
    And "alice" has no evidence for that shape

  Scenario: Finding the root of a shape yields no evidence, since the root is shown
    Given the catalog shape "C major — CAGED A, shift 3"
    When "alice" answers that shape by finding the degree "R" on string 5 at fret 3 after 1500 milliseconds
    Then the answer is rejected because the degree is not in the shape
    And "alice" has no evidence for that shape

  Scenario: A diagram that isn't a drill shape yields no evidence
    Given the catalog diagram "C Chromatic map — Frets 0–12"
    When "alice" answers that diagram as a shape by naming the shape "A" after 2000 milliseconds
    Then the answer is rejected because the reference is unknown
    And "alice" has no evidence for that diagram
