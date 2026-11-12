Feature: Answer a practice item the way it can be graded honestly
  As a student
  I want each item to take my answer in a way that fits what it asks
  So that a lucky guess, a replayed clip or a missing sound never counts as what I know

  # Client behaviour: what the Practice Shell offers, when an answer commits and what it sends.
  # Grading and levels are core's (grade-practice-response, knowledge-state, timed-thresholds).

  Background:
    Given student "alice" plays "guitar" in standard tuning E2 A2 D3 G3 B3 E4
    And "alice" is practising in a session

  # ── Name the note among four choices ───────────────────────────────────────

  @web
  Scenario: Name the note offers the note, a semitone either side and the same fret on the next string
    When "alice" is asked to name the note of the guitar cell on string 5 at fret 3
    Then the choices are "C", "B", "C#" and "F", in random order

  @web
  Scenario: A cell on string 1 takes its string neighbour from string 2
    When "alice" is asked to name the note of the guitar cell on string 1 at fret 3
    Then the choices are "G", "F#", "G#" and "D", in random order

  @web
  Scenario: The answer sends the four choices as shown
    Given "alice" is shown the choices "B", "F", "C" and "C#" for the guitar cell on string 5 at fret 3
    When "alice" taps "C"
    Then the practice.item_answered response names the note "C" with the choices "B", "F", "C" and "C#"

  # ── Fretboard drills in a fret window ──────────────────────────────────────
  # The plan gives each fretboard cell its drill's window: five frets, plus the open string when
  # it starts at the nut. Sizes are CSS pixels; a phone is a 390 px wide viewport.

  @web
  Scenario: On a phone a drill draws only its window and never scrolls sideways
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 5, in the fret window 3 to 7
    When the drill is shown on a phone
    Then the board shows frets 3 to 7 and no other fret
    And the board doesn't scroll sideways

  @web
  Scenario: Every place in a window at the nut is at least 48 px wide, the open string included
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 0, in the fret window 0 to 5
    When the drill is shown on a phone
    Then the open-string place and frets 1 to 5 are each at least 48 px wide
    And the board shows a nut, with the open-string place left of it

  @web
  Scenario: A tap on the open string is answered as the open string, not fret 1
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 0, in the fret window 0 to 5
    When "alice" taps the open-string place on string 6
    Then the practice.item_answered response names string 6, fret 0

  @web
  Scenario: The question names the window
    Given "alice" is asked to find the note "C" on string 5, in the fret window 0 to 5
    When the drill is shown
    Then the question names frets 0 to 5

  @web
  Scenario: On a wider screen the places outside the window are dimmed and can't be tapped
    Given "alice" is asked to find the note of the guitar cell on string 6 at fret 8, in the fret window 6 to 10
    When the drill is shown on a 1024 px wide screen
    Then frets 6 to 10 can be tapped
    And the other frets are dimmed and can't be tapped

  @web
  Scenario: Name the note draws its cell in the window too
    Given "alice" is asked to name the note of the guitar cell on string 4 at fret 9, in the fret window 7 to 11
    When the drill is shown on a phone
    Then the board shows frets 7 to 11 with the cell on string 4 at fret 9 marked
    And the board doesn't scroll sideways

  # ── Sound options commit with Check ────────────────────────────────────────

  @web
  Scenario: A sound-choice exercise with one right option waits for Check
    Given an audio_selection exercise with 3 sound options, one of them right
    When "alice" taps the second option
    Then the second option is selected
    And no answer is sent until "alice" taps Check

  @web
  Scenario: Playing a sound option doesn't select it
    Given an audio_selection exercise with 3 sound options, one of them right
    When "alice" taps the play button of the first option
    Then the first option's clip plays
    And no option is selected

  @web
  Scenario: A sound-choice answer's latency runs from the end of the last clip played
    Given an audio_selection exercise with 3 sound options, one of them right
    And the last clip "alice" played ended 8000 milliseconds after the exercise was shown
    When "alice" taps Check 11000 milliseconds after the exercise was shown
    Then the answer is sent with a latency of 3000 milliseconds and no audio length

  @web
  Scenario: Checking while a clip still plays sends a latency of 0
    Given an audio_selection exercise with 3 sound options, one of them right
    And a selected option's clip is still playing
    When "alice" taps Check
    Then the clip stops
    And the answer is sent with a latency of 0 milliseconds and no audio length

  # ── Chords played in hand ──────────────────────────────────────────────────
  # A single chord is fretted, strummed once and rated (Figma 17h; bass 18h). A chord change is
  # ten cycles at a tempo, one change on every beat (MOT-197, ADR-074): the student picks the share
  # of changes that rang clean from four buttons, and the share rates it. Every drill that keeps a
  # beat shows the same metronome row as the Metronome tool: the beat dots and the tempo control
  # with its note values. On bass, a drill sounds only the notes it asks for, in the bass's voice.

  @web
  Scenario: A single chord shows its chord box, named, and is answered by a self-rating
    Given "alice"'s session plans the single chord "a-minor-open"
    When the item is shown
    Then the chord box of "a-minor-open" is drawn with the name "Am"
    And rating it "almost" sends a self_rating of "almost" with no tempo and no clean share

  @web @MOT-197
  Scenario: On bass, a root and fifth marks the root and both fifths
    Given "alice"'s session plans the root and fifth of "Am" on the "electric-bass" layout
    When the item is shown
    Then the bass board marks the root, the fifth above it and the fifth below it at the places the plan gives
    And the Metronome tool's row is shown at the plan's start tempo

  @web @MOT-197
  Scenario: On bass, a root and fifth sounds the root then the fifth, a half note each
    Given "alice"'s session plans the root and fifth of "Am" on the "electric-bass" layout at 60 BPM
    When "alice" starts the take
    Then the bass voice plays A then E, two beats each, over the metronome
    And no chord sounds

  @web @MOT-197
  Scenario: A root and fifth sends the tempo it was played at with the rating
    Given "alice" set the tempo of a root and fifth to 70 BPM and played it
    When "alice" rates it "clean"
    Then the practice.item_answered response is a self_rating of "clean" at 70 BPM

  @web @MOT-197
  Scenario: A chord change is ready at the plan's tempo, which the student may change first
    Given "alice"'s session plans the chord change "a-minor-open" to "c-open" starting at 45 BPM, with a best clean tempo of 50 BPM
    When the item is shown
    Then both chord boxes are drawn with their names
    And the Metronome tool's row is shown at 45 BPM, ticking while it is tried, with the best clean tempo of 50 BPM marked
    And the line above the chords reads "10 cycles · change on every beat"
    And nothing is sent until the take is over

  @web @MOT-197
  Scenario: Starting the take gives a bar of count-in, then ten cycles with nothing to tap but Restart
    Given "alice" is ready on a chord change at 60 BPM
    When "alice" starts the take
    Then the metronome counts in one bar, then 20 beats follow at 60 BPM, the cycles counted down from 10
    And no control but Restart and leaving the session can be used until the take is over

  @web @MOT-197
  Scenario: Restarting the take throws it away and is ready again at the same tempo
    Given "alice" set the tempo to 50 BPM and started a take of chord changes
    When "alice" restarts it during the take
    Then the metronome stops and the cycles show 10 again
    And the tempo is still 50 BPM and can be changed
    And no practice.item_answered event is sent for the chord change

  @web @MOT-197
  Scenario: When the take is over, four buttons ask how many changes rang clean
    Given "alice" is playing a take of chord changes
    When the tenth cycle ends
    Then the metronome stops
    And four buttons offer 25 %, 50 %, 75 % and 100 % of the changes clean, none picked

  @web @MOT-197
  Scenario: Picking a share sends the tempo, the share and the rating it gives
    Given "alice" played a take of chord changes at 60 BPM
    When "alice" picks 75 %
    Then the practice.item_answered response is a self_rating of "almost" at 60 BPM with 75 percent clean

  @web @MOT-197
  Scenario: The tempo the student set is the one sent, not the plan's
    Given "alice"'s session plans a chord change starting at 45 BPM
    And "alice" sets the tempo to 50 BPM before starting the take
    When "alice" picks 100 % after the take
    Then the practice.item_answered response is a self_rating of "clean" at 50 BPM with 100 percent clean

  @web @MOT-197
  Scenario: Leaving the session during the take sends no answer for the change
    Given "alice"'s take of chord changes is running
    When "alice" leaves the session
    Then no practice.item_answered event is sent for the chord change

  @web @MOT-197
  Scenario: On bass, a root change sounds each root on its beat
    Given "alice"'s session plans the root change "C" to "G" on the "electric-bass" layout at 60 BPM
    When "alice" starts the take
    Then after the count-in, the bass voice plays C and G on alternate beats over the metronome
    And no chord sounds

  # ── Progression key tours ──────────────────────────────────────────────────
  # A progression is played along with, key after key around the cycle of fourths (Figma 17k;
  # bass 18z). Each take is rated; the tour's next key and tempo are in progression-key-tour.feature.

  @web
  Scenario: A tour shows the progression's chart in the take's key, the key line and the tempo
    Given "alice"'s session plans the progression key tour of "I-V-vi-IV" on guitar starting in A at 85 BPM, with C, F, Bb, Eb, Ab, Db, F#, B and E clean
    When the item is shown
    Then the chart reads "A E F#m D" in chord symbols
    And the key line shows five keys around A, with the clean ones ticked
    And the tempo is set to 85 BPM, and the primary action is "Start take in A"

  @web
  Scenario: The line above the chart names the last clean key and tempo and the key to play
    Given "alice" rated the take in E "clean" at 85 BPM
    When the take in A is shown
    Then it reads "Clean in E at 85 BPM · now in A"

  @web
  Scenario: On guitar, a chord's box is shown on demand
    Given the take in A of a tour on guitar is shown
    When "alice" opens the chord card of "F#m"
    Then the box of the voicing the plan gives for "F#m" is drawn

  @web @MOT-197
  Scenario: On bass, the board marks each chord's root and its third and fifth above and below
    Given "alice"'s session plans the progression key tour of "I-V-vi-IV" on the "electric-bass" layout starting in G
    When the item is shown
    Then the chart reads "G D Em C" in chord symbols
    And the bass board marks each chord's root, its third and fifth above, and its third and fifth below, at the places the plan gives
    And the root is marked apart from the other tones, and each third and fifth says whether it is above or below

  @web @MOT-197
  Scenario: On bass, a take sounds the pattern's notes and never a chord
    Given "alice"'s session plans the progression key tour of "12-bar-blues" on the "electric-bass" layout with the pattern root_fifth, in A at 80 BPM
    When "alice" starts the take
    Then after the count-in, the bass voice plays each bar's root then its fifth, a half note each, over the metronome
    And no chord sounds

  @web @MOT-197
  Scenario: On bass, the line above the chart names the pattern to play
    Given "alice"'s session plans the progression key tour of "12-bar-blues" on the "electric-bass" layout with the pattern root_third_fifth_seventh
    When the item is shown
    Then the line above the chart reads "Root, 3rd, 5th and 7th of each chord"

  @web @MOT-197
  Scenario: Every drill that keeps a beat shows the Metronome tool's row
    Given "alice"'s session plans a play-along, a chord change, a root and fifth, a progression key tour and a guide tone
    When each item is shown
    Then each shows the same metronome row as the Metronome tool, with its beat dots and its tempo control

  @web
  Scenario: A take is a bar of count-in, then the progression over its backing
    Given "alice" is about to play a take of a four-bar tour in A at 85 BPM
    When "alice" starts the take
    Then the metronome counts in one bar, then the backing plays the chart 4 times through at 85 BPM

  @web
  Scenario: Rating a take sends its tempo, note value and key
    Given "alice" played a take of the tour in A at 85 BPM in quarters
    When "alice" rates it "clean"
    Then the practice.item_answered response is a self_rating of "clean" at 85 BPM in quarters in A

  @web
  Scenario: The summary says how many keys are clean at the tour tempo
    Given "alice"'s session plans a tour at 85 BPM with 9 keys clean
    When "alice" makes 2 more keys clean and the session ends
    Then the session summary says "Clean in 11 of 12 keys at 85 BPM" for the tour

  @web
  Scenario: A take started at the wrong tempo is restarted without rating it
    Given "alice" started a take of the tour in A at 180 BPM
    When "alice" restarts it
    Then no rating of the take is sent
    And the take doesn't count among the tour's takes

  # ── Guide tones ────────────────────────────────────────────────────────────
  # The student taps the asked tone of each chord on an empty fretboard as the progression plays
  # (Figma 17l; bass 18l). What the plan asks is in guide-tones.feature.

  @web
  Scenario: A guide tone shows the progression in its key, the window and an empty board
    Given "alice"'s session plans the guide tone of "ii-V-I" on guitar in G, tone 3, at 60 BPM
    When the item is shown
    Then it reads "Tap the 3rd of each chord" over "ii – V – I in G" with the chords "Am D G G"
    And the fretboard shows frets 0 to 5 with nothing marked
    And the line under the player reads "Guitar · frets 0–5"

  @web
  Scenario: A tap leaves a dot where it landed, and a bar's result shows once it has passed
    Given "alice" is playing a take of the guide tone of "ii-V-I" in G
    When "alice" taps a place during the first bar
    Then a dot shows where the tap landed, with no sign of right or wrong
    And when the second bar starts, the line reads "1 of 1 in time so far" if the first bar was hit

  @web
  Scenario: A take is a bar of count-in, then the progression once, and is sent when it ends
    Given "alice" starts a take of the guide tone of "ii-V-I" in G at 60 BPM in quarters
    When the count-in bar and the 4 bars have played
    Then a practice.item_answered event is sent with a timed_taps response in G, tone 3, at 60 BPM in quarters
    And each tap's time is counted from the downbeat of the first bar after the count-in

  @web
  Scenario: The result of a take never names the notes to tap
    Given "alice" missed the second bar of a take of the guide tone of "ii-V-I" in G
    When the take's result is shown
    Then the second bar shows as missed and the others as hit
    And no note name or place on the fretboard is shown

  @web
  Scenario: A missed take offers another take in the same key, up to 3
    Given "alice" missed a bar in the first take of the guide tone of "ii-V-I" in G
    When the take's result is shown
    Then "alice" can start a second take, again in G
    And after a third take the item ends, right or not

  @web
  Scenario: A right take ends the item
    Given "alice" hit every bar in the first take of the guide tone of "ii-V-I" in G
    When the take's result is shown
    Then the next action moves on to the next item

  @web
  Scenario: The summary says how many bars the best take hit
    Given "alice"'s takes of the guide tone of "ii-V-I" hit 2, then 4 of its 4 bars
    When the session ends
    Then the session summary says "4 of 4 chords in time" for the guide tone

  @web
  Scenario: Leaving in the middle of a take sends nothing for it
    Given "alice" is playing a take of the guide tone of "ii-V-I" in G
    When "alice" leaves the session
    Then no practice.item_answered event is sent for the take

  # ── Not answered ───────────────────────────────────────────────────────────

  @web
  Scenario: Options stay locked while the stimulus failed to load
    Given an audio_recognition exercise whose sound failed to load
    When "alice" taps an option
    Then no option is selected
    And the item offers Try again and Skip

  @web
  Scenario: Skipping an item whose sound failed to load sends it as not answered
    Given an audio_recognition exercise whose sound failed to load
    When "alice" taps Skip
    Then a practice.item_answered event is sent with a not_answered response, reason "failed_to_load"
    And the session moves on to the next item

  @web
  Scenario: An item that can't be shown is skipped as unavailable
    Given an exercise whose diagram can't be shown on this device
    When "alice" taps Skip
    Then a practice.item_answered event is sent with a not_answered response, reason "unavailable"

  @web
  Scenario: A not-answered item is left out of the session's answered count
    Given "alice" answered 4 items and skipped 1 that failed to load
    When the session ends
    Then practice.session_ended carries an answered count of 4

  @web
  Scenario: Skip is never offered while the stimulus is there
    Given an audio_recognition exercise whose sound has loaded
    Then the item offers no Skip
