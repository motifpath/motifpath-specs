Feature: Listening exercises that play a diagram
  As a teacher
  I want a listening exercise's sound to be a diagram's playback instead of an uploaded clip
  So that ear-training exercises need no recording, and students can see the shape they heard

  # A listening exercise's sound is exactly one of an uploaded clip (audio_url) or a diagram that
  # plays (diagram_ref with a playback): the audio_recognition stimulus, and each audio_selection
  # option. A diagram used as a sound names its playback, doesn't loop, and keeps that playback:
  # it can't be removed from the diagram while an exercise plays it. Grading is unchanged.

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a diagram "a-minor-chord" exists on instrument "guitar" with playbacks "Strum, Arpeggio"
    And a diagram "a-major-chord" exists on instrument "guitar" with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher

  # ── Happy path — audio_recognition ───────────────────────────────────────────

  Scenario: A teacher creates an audio_recognition exercise that plays a diagram
    When "bob" creates an audio_recognition exercise titled "Major or minor?" with options "Major, Minor" and "Minor" correct, sounding diagram "a-minor-chord" playing playback "Strum"
    Then the exercise is created and assigned a stable identifier
    And the exercise's sound is diagram "a-minor-chord" playing playback "Strum"
    And the exercise has no audio_url

  Scenario: A diagram sound keeps its tempo, voice and direction
    When "bob" creates an audio_recognition exercise titled "Major or minor?" with options "Major, Minor" and "Minor" correct, sounding diagram "a-minor-chord" playing playback "Arpeggio" at 60 BPM, reversed
    Then the exercise's sound is diagram "a-minor-chord" playing playback "Arpeggio" at 60 BPM, reversed

  Scenario: A teacher switches an exercise's sound from an uploaded clip to a diagram
    Given "bob" has an audio_recognition exercise "Major or minor?" whose sound is an uploaded clip
    When "bob" updates the exercise's sound to diagram "a-minor-chord" playing playback "Strum", with no audio_url
    Then the exercise's sound is diagram "a-minor-chord" playing playback "Strum"
    And the exercise has no audio_url

  # ── Happy path — audio_selection ─────────────────────────────────────────────

  Scenario: A teacher creates an audio_selection exercise whose options play diagrams
    When "bob" creates an audio_selection exercise titled "Which one is minor?" with options:
      | label   | sound                    | correct |
      | Sound 1 | a-major-chord · Strum    | no      |
      | Sound 2 | a-minor-chord · Strum    | yes     |
    Then the exercise is created and assigned a stable identifier
    And option "Sound 2" sounds diagram "a-minor-chord" playing playback "Strum"
    And option "Sound 2" is marked correct

  Scenario: An audio_selection exercise may mix uploaded clips and diagram sounds
    When "bob" creates an audio_selection exercise titled "Which one is minor?" with options:
      | label   | sound                    | correct |
      | Sound 1 | uploaded clip            | no      |
      | Sound 2 | a-minor-chord · Strum    | yes     |
    Then the exercise is created and assigned a stable identifier
    And option "Sound 1" has an audio_url and no diagram
    And option "Sound 2" sounds diagram "a-minor-chord" playing playback "Strum"

  # ── Validation failures ──────────────────────────────────────────────────────

  Scenario: An audio_recognition exercise with both an uploaded clip and a diagram sound is rejected
    When "bob" creates an audio_recognition exercise titled "Major or minor?" with options "Major, Minor" and "Minor" correct, an uploaded clip and diagram "a-minor-chord" playing playback "Strum"
    Then the request is rejected as invalid
    And the rejection identifies "diagram_ref" as the source of the error

  Scenario: An audio_recognition exercise with no sound is rejected
    When "bob" creates an audio_recognition exercise titled "Major or minor?" with options "Major, Minor" and "Minor" correct, and no sound
    Then the request is rejected as invalid
    And the rejection identifies "audio_url" as the source of the error

  Scenario: An audio_selection option with both an uploaded clip and a diagram sound is rejected
    When "bob" creates an audio_selection exercise titled "Which one is minor?" with options:
      | label   | sound                                   | correct |
      | Sound 1 | a-major-chord · Strum                   | no      |
      | Sound 2 | uploaded clip + a-minor-chord · Strum   | yes     |
    Then the request is rejected as invalid
    And the rejection identifies "options" as the source of the error

  Scenario Outline: A diagram sound that can't play exactly once is rejected
    Given a diagram "silent-shape" exists on instrument "guitar" with no playbacks
    When "bob" creates an audio_recognition exercise titled "Major or minor?" with options "Major, Minor" and "Minor" correct, sounding <sound>
    Then the request is rejected as invalid
    And the rejection identifies "diagram_ref" as the source of the error

    Examples:
      | sound                                                       |
      | diagram "silent-shape" with no playback                     |
      | diagram "a-minor-chord" with no playback                    |
      | diagram "a-minor-chord" playing its default playback        |
      | diagram "a-minor-chord" playing playback "Fingerstyle"      |
      | diagram "a-minor-chord" playing playback "Strum", looping   |

  # ── A playback in use as a sound can't be removed ────────────────────────────

  Scenario: Removing a playback an exercise plays as its sound is refused
    Given an audio_recognition exercise "Major or minor?" sounds diagram "a-minor-chord" playing playback "Strum"
    When the playback "Strum" is removed from diagram "a-minor-chord"
    Then the request is refused with a conflict error
    And the error names playback "Strum" and the exercise "Major or minor?"
    And diagram "a-minor-chord" still has playbacks "Strum, Arpeggio"

  Scenario: Removing a playback an audio_selection option plays is refused
    Given an audio_selection exercise "Which one is minor?" has an option that sounds diagram "a-minor-chord" playing playback "Arpeggio"
    When the playback "Arpeggio" is removed from diagram "a-minor-chord"
    Then the request is refused with a conflict error
    And the error names playback "Arpeggio" and the exercise "Which one is minor?"

  Scenario: A playback in use as a sound can still be changed
    Given an audio_recognition exercise "Major or minor?" sounds diagram "a-minor-chord" playing playback "Strum"
    When the playback "Strum" of diagram "a-minor-chord" is changed to 80 BPM
    Then playback "Strum" is at 80 BPM in "4/4"
    And the exercise's sound is diagram "a-minor-chord" playing playback "Strum"

  Scenario: A playback no exercise plays can be removed
    Given an audio_recognition exercise "Major or minor?" sounds diagram "a-minor-chord" playing playback "Strum"
    When the playback "Arpeggio" is removed from diagram "a-minor-chord"
    Then diagram "a-minor-chord" has playbacks "Strum"

  Scenario: Changing the default playback doesn't change an exercise's sound
    Given an audio_recognition exercise "Major or minor?" sounds diagram "a-minor-chord" playing playback "Strum"
    When the default playback of diagram "a-minor-chord" is changed to "Arpeggio"
    Then the exercise's sound is diagram "a-minor-chord" playing playback "Strum"
