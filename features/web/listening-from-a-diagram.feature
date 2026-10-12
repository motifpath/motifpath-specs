Feature: Hear a diagram in a listening exercise, then see what made the sound
  As a student
  I want a listening exercise to play the shape without showing it, and to show it once I've answered
  So that I train my ear honestly, and then learn which shape and positions made the sound

  # Client behaviour for listening exercises whose sound is a diagram's playback (MOT-74, Figma
  # "Practice Shell flows" row 9, 9a–9d; authoring: design/patterns/authoring.md, Sound sources).
  # The board is never drawn before the answer is committed. Afterwards "What you heard" reveals it.
  # The play button only plays, the row selects, Check commits (ADR-049 P4). Core validates the
  # sound itself (content-management/exercise-sounds.feature).
  # These scenarios are verified by motifpath-web's component tests, not by the core-domain BDD suite.

  Background:
    Given student "alice" plays "guitar" in standard tuning E2 A2 D3 G3 B3 E4
    And a diagram "A minor" exists with playbacks "Strum" at 72 BPM and "Arpeggio" at 60 BPM

  # ── audio_recognition: the sound plays, the board stays hidden ──────────────

  Rule: Before the answer, a diagram sound shows only a Listen control

    @web
    Scenario: A diagram sound shows Listen with the playback's name and tempo, and no board
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      When the exercise is shown
      Then a Listen control shows "Strum · 72 BPM"
      And no board, chord box or diagram name is shown

    @web
    Scenario: Listen plays the diagram's playback without drawing it
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      When "alice" taps Listen
      Then playback "Strum" of "A minor" plays at 72 BPM
      And no board is drawn

    @web
    Scenario: The student can slow the sound down before answering
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      When "alice" sets the tempo to 50 BPM and taps Listen
      Then playback "Strum" of "A minor" plays at 50 BPM

    @web
    Scenario: The audio length is the playback's length at the exercise's tempo
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum", whose steps last 3000 milliseconds at 72 BPM
      And "alice" slowed the tempo to 50 BPM
      When "alice" answers "Minor" and taps Check
      Then the answer is sent with an audio length of 3000 milliseconds

    @web
    Scenario: A diagram sound whose voice fails to load can be skipped
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      And the voice of "A minor" failed to load
      When "alice" taps an option
      Then no option is selected
      And the item offers Try again and Skip

  # ── After the answer: "What you heard" ─────────────────────────────────────

  Rule: Once the answer is committed, "What you heard" reveals the diagram

    @web
    Scenario: After Check, "What you heard" names and draws the diagram
      Given "alice" is practising in a session
      And an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      When "alice" answers "Minor" and taps Check
      Then the feedback shows "What you heard: A minor"
      And the board of "A minor" is drawn

    @web
    Scenario: Play again lights the positions as they sound
      Given "alice" checked the answer to an audio_recognition exercise that sounds diagram "A minor" playing playback "Strum"
      When "alice" taps Play again under "What you heard"
      Then playback "Strum" of "A minor" plays
      And each position lights up while it sounds

    @web
    Scenario: The reveal shows only the playback the exercise used
      Given "alice" checked the answer to an audio_recognition exercise that sounds diagram "A minor" playing playback "Arpeggio"
      Then "What you heard" plays "Arpeggio" and offers no other playback

    @web
    Scenario: An uploaded clip has nothing to reveal
      Given "alice" is practising in a session
      And an audio_recognition exercise "Interval by ear" whose sound is an uploaded clip
      When "alice" answers "Perfect fifth" and taps Check
      Then the feedback shows no "What you heard"

  # ── audio_selection ────────────────────────────────────────────────────────

  Rule: Sound options stay neutral until the answer, then each reveals its own diagram

    @web
    Scenario: Diagram sound options show neutral labels and no boards
      Given "alice" is practising in a session
      And an audio_selection exercise "Which one is minor?" whose options "Sound 1, Sound 2, Sound 3" sound diagrams "G major, A minor, C major"
      When the exercise is shown
      Then the options are labelled "Sound 1", "Sound 2" and "Sound 3"
      And no board or diagram name is shown

    @web
    Scenario: After Check, the chosen and the right sound show their diagrams
      Given "alice" is practising in a session
      And an audio_selection exercise "Which one is minor?" whose options "Sound 1, Sound 2, Sound 3" sound diagrams "G major, C major, A minor", with "Sound 3" right
      When "alice" selects "Sound 2" and taps Check
      Then "Sound 2 · your answer" shows the board of "C major"
      And "Sound 3 · right answer" shows the board of "A minor"
      And "Sound 1" collapses to one line, "Sound 1 · G major", that expands to its board

    @web
    Scenario: A right answer reveals its own diagram once
      Given "alice" is practising in a session
      And an audio_selection exercise "Which one is minor?" whose options "Sound 1, Sound 2, Sound 3" sound diagrams "G major, C major, A minor", with "Sound 3" right
      When "alice" selects "Sound 3" and taps Check
      Then "Sound 3 · your answer" shows the board of "A minor"
      And "Sound 1" and "Sound 2" collapse to one line each

  # ── S7 challenge run ───────────────────────────────────────────────────────

  Rule: In a challenge, the reveal waits for the review

    @web
    Scenario: A challenge gives no "What you heard" before the review
      Given "alice" is running a challenge whose exercise 2 sounds diagram "A minor" playing playback "Strum"
      When "alice" chooses "Minor" on exercise 2 and taps Next
      Then no board of "A minor" has been shown

    @web
    Scenario: The challenge review reveals what each diagram sound was
      Given "alice" finished a challenge whose exercise 2 sounds diagram "A minor" playing playback "Strum"
      When "alice" opens exercise 2 in the review
      Then it shows "What you heard: A minor" with its board and Play again

  # ── Authoring: the Sound source picker ─────────────────────────────────────

  Rule: Every sound is uploaded or taken from a diagram

    @web
    Scenario: A sound offers Upload audio and From a diagram
      Given teacher "bob" is editing an audio_recognition exercise
      When "bob" opens the exercise's Sound
      Then it offers "Upload audio" and "From a diagram"

    @web
    Scenario: From a diagram lists only diagrams that have a playback
      Given a diagram "Silent shape" exists with no playbacks
      And teacher "bob" is choosing a sound from a diagram
      When "bob" searches for "shape"
      Then "Silent shape" is not listed

    @web
    Scenario: A diagram sound is set by playback, tempo, sound and direction, without loop
      Given teacher "bob" chose diagram "A minor" as a sound
      Then the settings offer a playback, a tempo, a sound and a direction
      And no loop setting is offered
      And playback "Strum" is chosen, because it is the diagram's default

    @web
    Scenario: Hear it plays the sound and shows its length
      Given teacher "bob" chose diagram "A minor" playing playback "Strum" as a sound, whose steps last 3000 milliseconds at 72 BPM
      When "bob" taps Hear it
      Then playback "Strum" of "A minor" plays at 72 BPM
      And the sound's length shows "0:03"

    @web
    Scenario: Saving a diagram sound stores the chosen playback by name
      Given teacher "bob" chose diagram "A minor" playing playback "Strum" as a sound, keeping the default choice
      When "bob" saves the exercise
      Then the exercise is saved with its sound naming playback "Strum"

    @web
    Scenario: New audio_selection options are labelled neutrally
      Given teacher "bob" is editing an audio_selection exercise with 2 options
      When "bob" adds an option
      Then the new option is labelled "Sound 3"

    @web
    Scenario: The student preview hides the board until the answer
      Given teacher "bob" is editing an audio_recognition exercise that sounds diagram "A minor" playing playback "Strum"
      When "bob" opens the student preview
      Then the preview shows a Listen control and no board
      And after "bob" answers, the preview shows "What you heard: A minor"

  Rule: A diagram's playback that an exercise plays can't be removed

    @web
    Scenario: Removing a playback in use says which exercises use it
      Given an audio_recognition exercise "Major or minor?" sounds diagram "A minor" playing playback "Strum"
      And teacher "bob" removed playback "Strum" from "A minor" in the diagram editor
      When "bob" saves the diagram
      Then the diagram is not saved
      And the editor says "Strum" can't be removed because "Major or minor?" plays it
