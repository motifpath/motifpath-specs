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

  # A chord change is one minute at a tempo, one change on every beat; the student counts the
  # changes that rang clean, and the share of the beats that did rates the minute (MOT-79).
  Scenario: A minute of chord changes is rated by the share of beats that changed cleanly
    Given the chord voicing diagrams "a-minor-open" and "c-open"
    When "alice" sends a minute of changes between "a-minor-open" and "c-open" at 60 BPM with 42 clean changes
    Then "alice" has self-assessed evidence for that chord change rated "almost" at 60 BPM with 42 clean changes

  # A progression key tour take is rated like a play-along, and also sends the key it was played
  # in (MOT-150).
  Scenario: A self-rated take of a progression key tour is kept with its rating, tempo and key
    When "alice" rates a take of the progression key tour of "I-V-vi-IV" on guitar as "clean" at 85 BPM in A
    Then "alice" has self-assessed evidence for that tour rated "clean" at 85 BPM in A

  Scenario: Evidence keeps the raw response and the event that sent it
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" after 1800 milliseconds
    Then the evidence keeps the response exactly as "alice" sent it
    And the evidence is identified by the identifier of the practice.item_answered event

  Scenario: A fretboard cell answer is graded by fretboard_cell.v2
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" among "B", "F", "C" and "C#" after 1500 milliseconds
    Then the evidence names the grader "fretboard_cell.v2"

  Scenario: Evidence keeps what a right answer was for a fretboard cell
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" after 2500 milliseconds
    Then the evidence's answer key is string 5, fret 3, note "C"

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

  Scenario: A chord change's rating follows its count, whatever rating was sent
    Given the chord voicing diagrams "a-minor-open" and "c-open"
    When "alice" sends a minute of changes between "a-minor-open" and "c-open" rated "clean" at 60 BPM with 20 clean changes
    Then "alice" has self-assessed evidence for that chord change rated "struggled" at 60 BPM with 20 clean changes

  Scenario: Nine clean changes in ten beats is a clean minute
    Given the chord voicing diagrams "a-minor-open" and "c-open"
    When "alice" sends a minute of changes between "a-minor-open" and "c-open" at 60 BPM with 54 clean changes
    Then "alice" has self-assessed evidence for that chord change rated "clean" at 60 BPM with 54 clean changes

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: Choices that leave out the cell's note yield no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" among "B", "C#", "D" and "F" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  Scenario: A note named that isn't among the choices yields no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "D" among "B", "F", "C" and "C#" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  Scenario: Two choices spelling the same pitch yield no evidence
    When "alice" answers the guitar cell on string 5 at fret 3 by naming the note "C" among "C", "B#", "C#" and "F" after 1600 milliseconds
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that cell

  Scenario: An item skipped because its sound failed to load yields no evidence
    Given the exercise "hear-the-fifth" whose correct option is "Perfect fifth" out of "Perfect fourth" and "Perfect fifth"
    When "alice" sends exercise "hear-the-fifth" as not answered because its stimulus failed to load
    Then the practice.item_answered event is kept with the reason "failed_to_load"
    And "alice" has no evidence for exercise "hear-the-fifth"

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

  Scenario: A progression key tour take without its key yields no evidence
    When "alice" rates a take of the progression key tour of "I-V-vi-IV" on guitar as "clean" at 85 BPM without a key
    Then the answer is rejected because the response does not fit the item
    And "alice" has no evidence for that tour

  Scenario: A progression key tour take of a progression the catalog doesn't have yields no evidence
    When "alice" rates a take of the progression key tour of "I-II-III" on guitar as "clean" at 85 BPM in C
    Then the answer is rejected because the reference is unknown
    And "alice" has no evidence for that tour

  # A guide-tone take is graded bar by bar against its tempo and note value (timed_taps.v1, MOT-151).
  @wip
  Scenario: A guide-tone take with every third hit is right
    When "alice" taps the third of each bar of "ii-V-I" in C at 120 BPM within its bar
    Then "alice" has auto-graded evidence for that guide tone that is right
    And the evidence's answer key marks all 4 bars hit

  @wip
  Scenario: A guide-tone take in eighths is graded with bars half as long
    When "alice" taps the third of "Dm" at 100 milliseconds and of "G" at 2300 milliseconds in a take of "ii-V-I" in C at 120 BPM in eighths
    Then "alice" has auto-graded evidence for that guide tone that is wrong
    And the evidence's answer key marks only the first bar hit

  # A song is rated once, whole, with no measure (MOT-152).
  @wip
  Scenario: A self-rated song is kept with its rating alone
    When "alice" rates the song "Amazing Grace" on guitar as "almost"
    Then "alice" has self-assessed evidence for that song rated "almost", with no tempo

  @wip
  Scenario: A song rated with a tempo yields no evidence
    When "alice" rates the song "Amazing Grace" on guitar as "clean" at 80 BPM
    Then the answer is rejected because the response does not fit the item
    And "alice" has no evidence for that song

  @wip
  Scenario: A song whose chart doesn't exist yields no evidence
    When "alice" rates the song of a song chart that doesn't exist on guitar as "clean"
    Then the answer is rejected because the reference is unknown
    And "alice" has no evidence for that song

  Scenario: A play-along rating with a key yields no evidence
    Given the play-along diagram "pentatonic-run"
    When "alice" rates a take of play-along "pentatonic-run" as "clean" at 90 BPM in G
    Then the answer is rejected because the response does not fit the item
    And "alice" has no evidence for play-along "pentatonic-run"

  Scenario: A play-along rating without its tempo yields no evidence
    Given the play-along diagram "pentatonic-run"
    When "alice" rates a take of play-along "pentatonic-run" as "clean" without a tempo
    Then the answer is rejected because its measure is missing
    And "alice" has no evidence for play-along "pentatonic-run"

  Scenario: A minute of chord changes without its tempo yields no evidence
    Given the chord voicing diagrams "a-minor-open" and "c-open"
    When "alice" sends a minute of changes between "a-minor-open" and "c-open" with 40 clean changes and no tempo
    Then the answer is rejected because its measure is missing
    And "alice" has no evidence for that chord change

  Scenario: More clean changes than beats in the minute yields no evidence
    Given the chord voicing diagrams "a-minor-open" and "c-open"
    When "alice" sends a minute of changes between "a-minor-open" and "c-open" at 40 BPM with 41 clean changes
    Then the answer is rejected because the response does not fit the item
    And "alice" has no evidence for that chord change

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

  Scenario: A heard chord named by sight among options that aren't all numerals yields no evidence
    When "alice" answers the heard chord vi in G, asked see_then_name, by picking "vi" among "vi", "IV", "Em" and "iii"
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that question

  Scenario: A chord picked that isn't among a generated question's options yields no evidence
    When "alice" answers the diatonic chord vi in G, asked numeral_to_chord, by picking "D" among "Em", "C", "Am" and "Bm"
    Then the answer is rejected because the choices are invalid
    And "alice" has no evidence for that question

  # ── Find every instance (MOT-153) ──────────────────────────────────────────
  # A fretboard cell asked to find every instance names the cell's note; the student taps every
  # place of it in the fret window. One answer is graded by multi_tap.v2 on every cell it covers,
  # and counts for accuracy only. In frets 3 to 7 on guitar, G is at string 6 fret 3, string 4
  # fret 5 and string 1 fret 3.

  Scenario: Tapping every place of the note is right evidence on each of its cells
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3, string 1 fret 3 and string 4 fret 5 in frets 3 to 7
    Then "alice" has auto-graded evidence that is correct for each of the guitar cells string 1 fret 3, string 4 fret 5 and string 6 fret 3
    And each of them names the grader "multi_tap.v2"

  Scenario: A place missed is wrong evidence on its cell
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3 and string 1 fret 3 in frets 3 to 7
    Then "alice" has auto-graded evidence that is wrong for the guitar cell on string 4 at fret 5
    And "alice" has auto-graded evidence that is correct for the guitar cells string 6 fret 3 and string 1 fret 3

  Scenario: An extra tap is wrong evidence on the cell tapped
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3, string 1 fret 3, string 4 fret 5 and string 5 fret 5 in frets 3 to 7
    Then "alice" has auto-graded evidence that is wrong for the guitar cell on string 5 at fret 5
    And its answer key names the note "G", which is not that cell's note

  Scenario: A window across root and top strings gives evidence to cells of both skills
    When "alice" answers the guitar cell on string 5 at fret 7 by tapping string 5 fret 7 and string 2 fret 5 in frets 3 to 7
    Then "alice" has evidence for the guitar cell on string 5 at fret 7, of skill "find-notes-root-strings"
    And "alice" has evidence for the guitar cell on string 2 at fret 5, of skill "find-notes-top-strings"

  Scenario: Finding every instance counts for accuracy, never for fluency
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3, string 1 fret 3 and string 4 fret 5 in frets 3 to 7 after 5200 milliseconds
    Then none of "alice"'s evidence from that answer has a latency

  Scenario: Each cell's evidence from one answer has its own identifier
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3, string 1 fret 3 and string 4 fret 5 in frets 3 to 7
    Then each cell's evidence is identified by the name-based UUID of its item key under the practice.item_answered event's identifier

  Scenario: A redelivered find every instance answer adds no evidence
    Given "alice" answered the guitar cell on string 6 at fret 3 by tapping every G in frets 3 to 7
    When the same practice.item_answered event is delivered again
    Then "alice" still has one piece of evidence for each of the three cells

  Scenario: A tap outside the window yields no evidence on any cell
    When "alice" answers the guitar cell on string 6 at fret 3 by tapping string 6 fret 3 and string 2 fret 8 in frets 3 to 7
    Then the answer is rejected because a cell is invalid
    And "alice" has no evidence for any guitar cell

  Scenario: A planned cell outside its window yields no evidence
    When "alice" answers the guitar cell on string 6 at fret 10 by tapping string 6 fret 3 in frets 3 to 7
    Then the answer is rejected because a cell is invalid
    And "alice" has no evidence for any guitar cell
