Feature: Manage prebuilt diagrams
  As the MotifPath platform
  I want teachers and admins to author reusable, structured diagrams classified by skill and concept
  So that the same scale or chord pattern can be shown, styled, and played back differently across
  any number of content nodes and exercises, without being redrawn as a new image each time

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And a fretted instrument "guitar" exists in the system
    And a keyboard instrument "piano" exists in the system

  # ── Happy path — creating ────────────────────────────────────────────────────

  Scenario: A teacher creates a diagram on a fretted instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
      | b3       | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 2 positions

  Scenario: A teacher creates a diagram on a keyboard instrument
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Piano" on instrument "piano" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with keyboard positions:
      | interval | note_name | key |
      | R        | A         | A3  |
      | b3       | C         | C4  |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 2 positions

  Scenario: An admin creates a diagram
    Given "admin" is authenticated as an admin
    When "admin" creates a diagram named "C Major Scale" on instrument "guitar" classified under skills "major-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier

  Scenario: A teacher records a root note, label display, and per-position shapes
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" with root note "A", label display "note" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | shape |
      | R        | A         | 6      | 5    | star  |
      | b3       | C         | 6      | 8    |       |
    Then the diagram is created and assigned a stable identifier
    And the diagram's root note is "A"
    And the diagram's label display is "note"
    And position 1 has shape "star"
    And position 2 has shape "dot"

  Scenario: Omitting root note, label display, and shape leaves them unrecorded or defaulted
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "No Extras" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no recorded root note
    And the diagram's label display is "interval"
    And position 1 has shape "dot"

  Scenario: A teacher records a general color and a custom color on one position
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" with color "#3B82F6" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | color   |
      | R        | A         | 6      | 5    | #EF4444 |
      | b3       | C         | 6      | 8    |         |
    Then the diagram is created and assigned a stable identifier
    And the diagram's color is "#3B82F6"
    And position 1 has color "#EF4444"
    And position 2 has no color of its own

  Scenario: Omitting colors leaves them unrecorded
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "No Colors" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no general color
    And position 1 has no color of its own

  # ── Kind and ownership — creating ──────────────────────────────────────────

  Scenario: A teacher's new diagram is a custom diagram they own
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "My Pentatonic" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's kind is "custom"
    And the diagram records "bob" as the creator

  Scenario: An admin creates a basic diagram
    Given "admin" is authenticated as an admin
    When "admin" creates a basic diagram named "C Major Scale" in English and "Escala de Dó maior" in Portuguese on instrument "guitar" classified under skills "major-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | C         | 6      | 8    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's kind is "basic"
    And the diagram records "admin" as the creator

  Scenario: A teacher cannot create a basic diagram
    Given "bob" is authenticated as a teacher
    When "bob" attempts to create a basic diagram
    Then the request is refused with a forbidden error

  Scenario: Creating a diagram with an unrecognised kind is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad kind" on instrument "guitar" with kind "shared" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "kind" as the source of the error

  # ── Names and languages ────────────────────────────────────────────────────

  Scenario: A teacher names a diagram in English and in Portuguese
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic" in English and "Pentatônica menor" in Portuguese on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's name in "pt_BR" is "Pentatônica menor"
    And the diagram's languages are "en, pt_BR"

  Scenario: A teacher's own diagram may be named in a single language other than English
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named only "Pentatônica menor" in Portuguese on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's languages are "pt_BR"

  Scenario: A basic diagram named in only one language is rejected
    Given "admin" is authenticated as an admin
    When "admin" creates a basic diagram named only "C Major Scale" in English on instrument "guitar" classified under skills "major-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | C         | 6      | 8    |
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: A diagram name for "any" language is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram with names "en" "Minor Pentatonic" and "any" "Minor Pentatonic" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: An admin renames a basic diagram in every language
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "admin" is authenticated as an admin
    When "admin" renames diagram "major-scale-guitar" to "Major Scale" in English and "Escala maior" in Portuguese
    Then the diagram's name in "en" is "Major Scale"
    And the diagram's name in "pt_BR" is "Escala maior"

  Scenario: Renaming a basic diagram without every language is rejected
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "admin" is authenticated as an admin
    When "admin" renames diagram "major-scale-guitar" to only "Major Scale" in English
    Then the request is rejected as invalid
    And the rejection identifies "names" as the source of the error

  Scenario: A teacher lists only the diagrams named in one language
    Given a custom diagram "bobs-english-only" exists on instrument "guitar", created by "bob", named only in "en"
    And a custom diagram "bobs-bilingual" exists on instrument "guitar", created by "bob", named in "en" and "pt_BR"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams in language "pt_BR"
    Then the response includes "bobs-bilingual"
    And the response does not include "bobs-english-only"

  Scenario: The diagram list is ordered by the names the caller reads
    Given a basic diagram "diagram-a" exists on instrument "guitar", named "Zebra" in English and "Arpejo" in Portuguese
    And a basic diagram "diagram-b" exists on instrument "guitar", named "Arpeggio" in English and "Zebra" in Portuguese
    And "bob" is authenticated as a teacher
    And "bob" has locale "pt_BR"
    When "bob" lists all diagrams
    Then the response lists "diagram-a" before "diagram-b"

  # ── Interval and note codes ────────────────────────────────────────────────

  Scenario: A position with an interval outside the canonical codes is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad interval" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | m3       | C         | 6      | 8    |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: A position whose note name is not a letter name is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad note" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | Lá        | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: Enharmonic interval codes are kept as the author spelled them
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Blues" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | #4       | D#        | 5      | 6    |
      | b5       | Eb        | 4      | 1    |
    Then the diagram is created and assigned a stable identifier
    And position 1 has interval "#4"
    And position 2 has interval "b5"

  # ── Marker labels and notes ───────────────────────────────────────────────

  Scenario: A teacher gives a position a custom label and a note
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Avoid Notes" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | custom_label | note                        |
      | R        | A         | 6      | 5    |              |                             |
      | b3       | C         | 6      | 8    | Av           | Avoid holding this over Am7 |
    Then the diagram is created and assigned a stable identifier
    And position 2's custom label in "en" is "Av"
    And position 2's note in "en" is "Avoid holding this over Am7"
    And position 1 has no custom label or note

  Scenario: A custom label longer than two characters is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Long label" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | custom_label |
      | R        | A         | 6      | 5    | Root         |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: A note longer than 280 characters is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Long note" on instrument "guitar" with one position whose note is 281 characters long
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: A note in fewer languages than the diagram's name is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic" in English and "Pentatônica menor" in Portuguese on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | note            |
      | R        | A         | 6      | 5    | Start here      |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  # ── Highlighted regions ────────────────────────────────────────────────────

  Scenario: A teacher highlights fret ranges on a fretted diagram
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Two Boxes" on instrument "guitar" with one position and regions:
      | fret_start | fret_end | string_start | string_end | description | color   |
      | 5          | 8        |              |            | Box 1       |         |
      | 7          | 10       | 1            | 3          | Box 2       | #22C55E |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 2 regions
    And region 1 spans frets 5 to 8 on every string
    And region 2 spans frets 7 to 10 on strings 1 to 3
    And region 2's description in "en" is "Box 2"
    And region 2 has color "#22C55E"

  Scenario: A teacher highlights a key range on a keyboard diagram
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Middle C Octave" on instrument "piano" with one position and keyboard regions:
      | key_start | key_end | description |
      | C4        | B4      | Octave 4    |
    Then the diagram is created and assigned a stable identifier
    And region 1 spans keys "C4" to "B4"

  Scenario Outline: An invalid region is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad region" on instrument "guitar" with one position and regions:
      | fret_start   | fret_end   | string_start   | string_end   | description   |
      | <fret_start> | <fret_end> | <string_start> | <string_end> | <description> |
    Then the request is rejected as invalid
    And the rejection identifies "regions" as the source of the error

    Examples:
      | fret_start | fret_end | string_start | string_end | description                                                   |
      | 8          | 5        |              |            | Backwards                                                     |
      | 5          | 8        | 3            | 1          | Backwards strings                                             |
      | 5          | 8        | 1            | 7          | Past the last string                                          |
      | 5          | 8        | 1            |            | Only one string bound                                         |
      | 5          | 8        |              |            | A caption much longer than the sixty characters a region gets |

  Scenario: A keyboard range on a fretted diagram is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Wrong shape" on instrument "guitar" with one position and keyboard regions:
      | key_start | key_end | description |
      | C4        | B4      | Octave 4    |
    Then the request is rejected as invalid
    And the rejection identifies "regions" as the source of the error

  Scenario: Updating a diagram without regions keeps its regions
    Given a custom diagram "bobs-box" exists on instrument "guitar", created by "bob", with a region spanning frets 5 to 8
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "bobs-box" setting root note "A" and label display "note"
    Then the diagram has 1 region

  Scenario: Updating a diagram with an empty region list removes its regions
    Given a custom diagram "bobs-box" exists on instrument "guitar", created by "bob", with a region spanning frets 5 to 8
    And "bob" is authenticated as a teacher
    When "bob" removes every region from diagram "bobs-box"
    Then the diagram has 0 regions

  # ── Saving a copy ──────────────────────────────────────────────────────────

  Scenario: A teacher saves a copy of a basic diagram as their own custom diagram
    Given a basic diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" saves a copy of diagram "minor-pentatonic-guitar" named "My Pentatonic"
    Then a new diagram is created with the same positions as "minor-pentatonic-guitar"
    And the new diagram's kind is "custom"
    And the new diagram records "bob" as the creator
    And diagram "minor-pentatonic-guitar" is unchanged

  Scenario: An admin saves a copy of a teacher's custom diagram as a basic diagram
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "admin" is authenticated as an admin
    When "admin" saves a copy of diagram "bobs-pentatonic" as a basic diagram named "Pentatonic Template" in English and "Modelo pentatônico" in Portuguese
    Then a new diagram is created with the same positions as "bobs-pentatonic"
    And the new diagram's kind is "basic"
    And the new diagram records "admin" as the creator
    And diagram "bobs-pentatonic" is unchanged

  # ── Key ─────────────────────────────────────────────────────────────────────

  Scenario: A teacher records the key of a diagram
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" with root note "A" and mode "minor" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram's root note is "A"
    And the diagram's mode is "minor"

  Scenario: A diagram created without a mode has no key
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Chromatic Run" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no mode

  Scenario: A mode without a root note is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "guitar" with mode "dorian" and no root note
    Then the request is rejected as invalid
    And the rejection identifies "mode" as the source of the error

  Scenario: An unrecognised mode is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "guitar" with root note "A" and mode "blues"
    Then the request is rejected as invalid
    And the rejection identifies "mode" as the source of the error

  Scenario: A teacher clears the mode of their own diagram
    Given a custom diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "bob", with root note "A" and mode "minor"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" clearing its mode
    Then the diagram has no mode
    And the diagram's root note is "A"

  # ── Playbacks ────────────────────────────────────────────────────────────────

  Scenario: A diagram created without playbacks has no playback and no default
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "No Playback" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram is created and assigned a stable identifier
    And the diagram has no playbacks
    And the diagram has no default playback

  Scenario: A teacher gives a diagram a playback of single notes
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "A5 Arpeggio" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
      | R        | A         | 3      | 2    |
    And a playback "Arpeggio" at 90 BPM in "4/4":
      | positions | value |
      | 1         | 1/8   |
      | 2         | 1/8   |
      | 3         | 1/4   |
    Then the diagram is created and assigned a stable identifier
    And the diagram has 1 playback
    And playback "Arpeggio" is at 90 BPM in "4/4"
    And playback "Arpeggio" has the steps:
      | positions | value | strum |
      | 1         | 1/8   | none  |
      | 2         | 1/8   | none  |
      | 3         | 1/4   | none  |

  Scenario: A playback's time signature defaults to 4/4
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "A5 Arpeggio" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
    And a playback "Arpeggio" at 90 BPM:
      | positions | value |
      | 1         | 1/4   |
      | 2         | 1/4   |
    Then playback "Arpeggio" is at 90 BPM in "4/4"

  Scenario: A diagram can sound its one shape in several playbacks
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "A5 Chord" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
      | R        | A         | 3      | 2    |
    And a playback "Strum" at 90 BPM in "4/4":
      | positions | value | strum |
      | 1, 2, 3   | 1/2   | down  |
      | 1, 2, 3   | 1/2   | up    |
    And a playback "Arpeggio" at 70 BPM in "6/8":
      | positions | value |
      | 1         | 1/8   |
      | 2         | 1/8   |
      | 3         | 1/8   |
    Then the diagram has 2 playbacks, in the order "Strum, Arpeggio"
    And playback "Strum" is at 90 BPM in "4/4"
    And playback "Arpeggio" is at 70 BPM in "6/8"

  Scenario: The first playback is the default when none is chosen
    Given "bob" is authenticated as a teacher
    When "bob" creates diagram "A5 Chord" with playbacks "Strum, Arpeggio" and no default playback
    Then the diagram's default playback is "Strum"

  Scenario: A teacher chooses which playback is the default
    Given "bob" is authenticated as a teacher
    When "bob" creates diagram "A5 Chord" with playbacks "Strum, Arpeggio" and default playback "Arpeggio"
    Then the diagram's default playback is "Arpeggio"

  Scenario: A step with several positions sounds them together as a chord, optionally strummed
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "A5 Chord" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
      | R        | A         | 3      | 2    |
    And a playback "Strum" at 90 BPM in "4/4":
      | positions | value | strum |
      | 1, 2, 3   | 1/4   | down  |
      | 1, 2, 3   | 1/4   | up    |
      | 1, 2, 3   | 1/2   |       |
    Then playback "Strum" has the steps:
      | positions | value | strum |
      | 1, 2, 3   | 1/4   | down  |
      | 1, 2, 3   | 1/4   | up    |
      | 1, 2, 3   | 1/2   | none  |

  Scenario: A position can sound in more than one step
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Strum Then Arpeggiate" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
      | R        | A         | 3      | 2    |
    And a playback "Strum Then Arpeggiate" at 90 BPM in "4/4":
      | positions | value | strum |
      | 1, 2, 3   | 1/2   | down  |
      | 1         | 1/8   |       |
      | 2         | 1/8   |       |
      | 3         | 1/4   |       |
    Then in playback "Strum Then Arpeggiate", position 1 sounds in steps 1 and 2

  Scenario: A step with no positions is a rest
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "With a Rest" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
    And a playback "With a Rest" at 90 BPM in "4/4":
      | positions | value |
      | 1         | 1/4   |
      |           | 1/4   |
      | 2         | 1/2   |
    Then step 2 of playback "With a Rest" is a rest of 1/4

  Scenario: Tuplets are kept as the fractions the author gave
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Triplet Run" on instrument "guitar" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 5      | 0    |
      | 5        | E         | 4      | 2    |
      | R        | A         | 3      | 2    |
    And a playback "Triplet Run" at 90 BPM in "4/4":
      | positions | value |
      | 1         | 1/12  |
      | 2         | 1/12  |
      | 3         | 1/12  |
      | 1         | 1/24  |
      | 2         | 1/24  |
      | 3         | 1/24  |
    Then the step values of playback "Triplet Run" are "1/12, 1/12, 1/12, 1/24, 1/24, 1/24"

  Scenario: Playback names are given in every language of the diagram
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "A5 Chord" in "en" and "Acorde A5" in "pt_BR" with a playback named "Strum" in "en" and "Batida" in "pt_BR"
    Then the diagram's playback is named "Strum" in "en" and "Batida" in "pt_BR"

  Scenario Outline: An invalid playback is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "guitar" with <problem>
    Then the request is rejected as invalid
    And the rejection identifies "<field>" as the source of the error

    Examples:
      | problem                                                              | field               |
      | a playback step naming a position not in the diagram                 | playbacks           |
      | a playback step naming the same position twice                       | playbacks           |
      | a playback step with a note value of 0/4                             | playbacks           |
      | a playback step with a note value of 1/0                             | playbacks           |
      | a playback step with an unrecognised strum "sideways"                | playbacks           |
      | a playback with no steps                                             | playbacks           |
      | a playback with no tempo                                             | playbacks           |
      | a playback at 19 BPM                                                 | playbacks           |
      | a playback at 301 BPM                                                | playbacks           |
      | a playback with a time signature of "4/3"                            | playbacks           |
      | a playback with a time signature of "17/4"                           | playbacks           |
      | a playback with a time signature of "0/4"                            | playbacks           |
      | two playbacks with the same id                                       | playbacks           |
      | two playbacks both named "Strum" in "en"                             | playbacks           |
      | a playback named only in "en" on a diagram named in "en" and "pt_BR" | playbacks           |
      | 17 playbacks                                                         | playbacks           |
      | a default playback id that is none of its playbacks                  | default_playback_id |
      | a default playback id and no playbacks                               | default_playback_id |

  Scenario: A teacher replaces the playbacks of their own diagram
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" with only the playback "Fingerstyle" at 80 BPM in "4/4":
      | positions | value |
      | 1         | 1/8   |
      | 3         | 1/8   |
    Then the diagram has 1 playback
    And the diagram's default playback is "Fingerstyle"

  Scenario: A playback resent with its id keeps that id
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" resending playback "Arpeggio" with its id at 60 BPM, without "Strum"
    Then playback "Arpeggio" keeps its id
    And playback "Arpeggio" is at 60 BPM in "4/4"

  Scenario: Updating the playbacks keeps the default when it is still one of them
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio" and default playback "Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" adding a playback "Fingerstyle" first and resending "Strum, Arpeggio" with their ids
    Then the diagram's default playback is "Arpeggio"

  Scenario: A teacher changes the default playback of their own diagram
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" setting the default playback to "Arpeggio"
    Then the diagram's default playback is "Arpeggio"
    And the diagram has 2 playbacks, in the order "Strum, Arpeggio"

  Scenario: Updating a diagram without playbacks keeps its playbacks
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" setting root note "A" and label display "note"
    Then the diagram has 2 playbacks, in the order "Strum, Arpeggio"
    And the diagram's default playback is "Strum"

  Scenario: A teacher removes every playback of their own diagram
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" with no playbacks
    Then the diagram has no playbacks
    And the diagram has no default playback

  Scenario: Removing a position that plays, without resending the playbacks, is rejected
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "a5-chord" replacing its positions with only positions 1 and 2
    Then the request is rejected as invalid
    And the rejection identifies "playbacks" as the source of the error
    And diagram "a5-chord" is unchanged

  Scenario: A student retrieves a diagram with its playbacks
    Given a custom diagram "a5-chord" exists on instrument "guitar", created by "bob", with playbacks "Strum, Arpeggio"
    And "alice" is authenticated as a student
    When "alice" retrieves diagram "a5-chord"
    Then the diagram has 2 playbacks, in the order "Strum, Arpeggio"
    And the diagram's default playback is "Strum"

  # ── Happy path — updating ────────────────────────────────────────────────────

  Scenario: A teacher updates their own diagram's root note and label display
    Given a custom diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" setting root note "A" and label display "hidden"
    Then the diagram's root note is "A"
    And the diagram's label display is "hidden"

  Scenario: A teacher updates their own diagram's general color and a position's color
    Given a custom diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "minor-pentatonic-guitar" setting color "#22C55E" and position 1 color "#F59E0B"
    Then the diagram's color is "#22C55E"
    And position 1 has color "#F59E0B"

  Scenario: An admin updates a basic diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "admin" is authenticated as an admin
    When "admin" updates diagram "major-scale-guitar" setting root note "G" and label display "note"
    Then the diagram's root note is "G"
    And the diagram's label display is "note"

  Scenario: An admin's update leaves a teacher's custom diagram owned by that teacher
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "admin" is authenticated as an admin
    When "admin" updates diagram "bobs-pentatonic" setting root note "E" and label display "interval"
    Then the diagram's root note is "E"
    And the diagram's kind is "custom"
    And the diagram records "bob" as the creator

  # ── Listing — role scoping ────────────────────────────────────────────────

  Scenario: A teacher's diagram list has every basic diagram and only their own custom diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response includes "major-scale-guitar" and "bobs-pentatonic"
    And the response does not include "carols-arpeggio"

  Scenario: A teacher narrows the diagram list to basic diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of kind "basic"
    Then the response includes "major-scale-guitar"
    And the response does not include "bobs-pentatonic"

  Scenario: A teacher narrows the diagram list to their own custom diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of kind "custom"
    Then the response includes "bobs-pentatonic"
    And the response does not include "major-scale-guitar" or "carols-arpeggio"

  Scenario: An admin's diagram list has every diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists all diagrams
    Then the response includes "major-scale-guitar", "bobs-pentatonic" and "carols-arpeggio"

  Scenario: An admin narrows the diagram list to one creator
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists diagrams filtered by creator "carol"
    Then the response includes "carols-arpeggio"
    And the response does not include "bobs-pentatonic"

  Scenario: A teacher filtering by another teacher gets none of that teacher's custom diagrams
    Given a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by creator "carol"
    Then the response contains 0 items

  Scenario: A teacher narrows the diagram list to the basic diagrams one admin created
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar", created by "admin"
    And a basic diagram "minor-pentatonic-guitar" exists on instrument "guitar", created by "dora"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by creator "admin"
    Then the response includes "major-scale-guitar"
    And the response does not include "minor-pentatonic-guitar"

  # ── Listing — filtering and pagination ────────────────────────────────────

  Scenario: A teacher searches diagrams by a name in any language, ignoring case and accents
    Given a basic diagram "diagram-a" exists on instrument "guitar", named "Ionian Mode" in English and "Modo Jônico" in Portuguese
    And a basic diagram "diagram-b" exists on instrument "guitar", named "Dorian Mode" in English and "Modo Dórico" in Portuguese
    And "bob" is authenticated as a teacher
    And "bob" has locale "en"
    When "bob" lists diagrams whose name contains "jonico"
    Then the response includes "diagram-a"
    And the response does not include "diagram-b"

  Scenario: A teacher filters diagrams by root note
    Given a basic diagram "a-minor-pentatonic" exists on instrument "guitar" with root note "A"
    And a basic diagram "e-minor-pentatonic" exists on instrument "guitar" with root note "E"
    And a basic diagram "unrooted-shape" exists on instrument "guitar" with no root note
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams with root note "A"
    Then the response includes "a-minor-pentatonic"
    And the response does not include "e-minor-pentatonic" or "unrooted-shape"

  Scenario: Diagram filters combine
    Given a basic diagram "a-minor-pentatonic" exists on instrument "guitar", named "Minor Pentatonic" in English and "Pentatônica Menor" in Portuguese, with root note "A"
    And a basic diagram "e-minor-pentatonic" exists on instrument "guitar", named "Minor Pentatonic" in English and "Pentatônica Menor" in Portuguese, with root note "E"
    And a custom diagram "bobs-a-pentatonic" exists on instrument "guitar", created by "bob", named "Minor Pentatonic" in English, with root note "A"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of kind "basic" whose name contains "pentatonic" with root note "A"
    Then the response includes "a-minor-pentatonic"
    And the response does not include "e-minor-pentatonic" or "bobs-a-pentatonic"

  Scenario Outline: An out-of-range diagram name search or root note is rejected
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams with <parameter> set to a value of <length> characters
    Then the request is refused with a validation error

    Examples:
      | parameter | length |
      | name      | 0      |
      | name      | 201    |
      | root_note | 0      |
      | root_note | 4      |


  Scenario: A teacher filters diagrams by instrument
    Given a basic diagram "minor-pentatonic-guitar" exists on instrument "guitar"
    And a basic diagram "minor-pentatonic-piano" exists on instrument "piano"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by instrument "guitar"
    Then the response includes "minor-pentatonic-guitar"
    And the response does not include "minor-pentatonic-piano"

  Scenario: Listing diagrams when none exist returns an empty page
    Given "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response contains 0 items
    And the response reports a total of 0

  Scenario: The diagram list is paginated
    Given "bob" is authenticated as a teacher
    And 45 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with no paging parameters
    Then the response contains 20 items ordered by name
    And the response reports a total of 45, a limit of 20, and an offset of 0

  Scenario: A teacher requests a later page of diagrams
    Given "bob" is authenticated as a teacher
    And 45 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with limit 20 and offset 40
    Then the response contains 5 items
    And the response reports a total of 45

  Scenario: An offset past the end of the diagram list returns an empty page
    Given "bob" is authenticated as a teacher
    And 3 basic diagrams exist on instrument "guitar"
    When "bob" lists diagrams with limit 20 and offset 100
    Then the response contains 0 items
    And the response reports a total of 3

  Scenario Outline: An out-of-range diagram page size or offset is rejected
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams with limit <limit> and offset <offset>
    Then the request is refused with a validation error

    Examples:
      | limit | offset |
      | 0     | 0      |
      | 101   | 0      |
      | 20    | -1     |

  # ── Diagram creators (the creator filter's options) ────────────────────────

  Scenario: A teacher lists the creators of the basic diagrams and their own
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar", created by "admin"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" lists the diagram creators
    Then the creators returned are "admin" and "bob", each with their display name
    And the creators returned do not include "carol"

  Scenario: A teacher with no custom diagram of their own is not a listed creator
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar", created by "admin"
    And "bob" is authenticated as a teacher
    When "bob" lists the diagram creators
    Then the creators returned are "admin", each with their display name

  Scenario: An admin lists the creator of every diagram, each once
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar", created by "admin"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "bobs-arpeggio" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists the diagram creators
    Then the creators returned are "admin", "bob" and "carol", each with their display name

  Scenario: Diagram creators are searched by display name, ignoring case and accents
    Given "bob" is named "Bob Ferreira"
    And "carol" is named "Carol Souza"
    And a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "admin" is authenticated as an admin
    When "admin" lists the diagram creators matching "FÉRR"
    Then the creators returned are "bob", each with their display name

  Scenario: A student cannot list diagram creators
    Given "alice" is authenticated as a student
    When "alice" lists the diagram creators
    Then the request is refused with a forbidden error

  # ── Retrieving ─────────────────────────────────────────────────────────────

  Scenario: A student retrieves a teacher's custom diagram by its id
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "alice" is authenticated as a student
    When "alice" retrieves diagram "bobs-pentatonic"
    Then the response is diagram "bobs-pentatonic"

  # ── Purpose — chord voicings ─────────────────────────────────────────────────
  #
  # The chord catalog installs each voicing's fingering as a basic diagram owned by the catalog
  # profile, with purpose "chord_voicing". Every other diagram is "general". Purpose only affects
  # finding and editing a diagram, never how it renders or plays.

  @wip
  Scenario: A diagram a teacher creates is a general diagram
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Minor Pentatonic — Position 1" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the diagram's purpose is "general"

  @wip
  Scenario: The diagram list leaves chord voicings out by default
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" lists all diagrams
    Then the response includes "major-scale-guitar"
    And the response does not include the diagram of voicing "a-minor-open"
    And the response reports a total of 1

  @wip
  Scenario: A teacher lists only the chord voicing diagrams
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of purpose "chord_voicing"
    Then the response includes the diagram of voicing "a-minor-open"
    And the response does not include "major-scale-guitar"
    And the diagram of voicing "a-minor-open" has purpose "chord_voicing"

  @wip
  Scenario: A teacher lists diagrams of any purpose
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" lists diagrams of purpose "any"
    Then the response includes "major-scale-guitar" and the diagram of voicing "a-minor-open"
    And the response reports a total of 2

  @wip
  Scenario: Listing diagrams of an unrecognised purpose is rejected
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams of purpose "scale"
    Then the request is refused with a validation error

  @wip
  Scenario: An admin cannot update a chord voicing diagram
    Given the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "admin" is authenticated as an admin
    When "admin" updates the diagram of voicing "a-minor-open" setting root note "G" and label display "note"
    Then the request is refused because only the chord catalog can change that diagram
    And the diagram of voicing "a-minor-open" is unchanged

  @wip
  Scenario: A copy of a chord voicing diagram is an ordinary diagram its creator can edit
    Given the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" saves a copy of the diagram of voicing "a-minor-open" named "My A minor"
    Then a new diagram is created with the same positions as the diagram of voicing "a-minor-open"
    And the new diagram's kind is "custom"
    And the new diagram's purpose is "general"
    And "bob" can update the new diagram

  @wip
  Scenario: A student retrieves a chord voicing diagram by its id
    Given the chord catalog has a voicing "a-minor-open" on instrument "guitar"
    And "alice" is authenticated as a student
    When "alice" retrieves the diagram of voicing "a-minor-open"
    Then the response is the diagram of voicing "a-minor-open", with its positions and playbacks

  # ── Validation failures ────────────────────────────────────────────────────

  Scenario: Creating a diagram with an unrecognised label display is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad label display" on instrument "guitar" with root note "A", label display "loud" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "label_display" as the source of the error

  Scenario: Creating a diagram with a malformed general color is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad color" on instrument "guitar" with color "blue" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret |
      | R        | A         | 6      | 5    |
    Then the request is rejected as invalid
    And the rejection identifies "color" as the source of the error

  Scenario: Creating a diagram with a malformed position color is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad position color" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with fretted positions:
      | interval | note_name | string | fret | color |
      | R        | A         | 6      | 5    | #GGG  |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: Creating a diagram with keyboard positions on a fretted instrument is rejected
    Given "bob" is authenticated as a teacher
    When "bob" creates a diagram named "Bad shape" on instrument "guitar" classified under skills "minor-pentatonic-scale", concepts "scale-construction" with keyboard positions:
      | interval | note_name | key |
      | R        | A         | A3  |
    Then the request is rejected as invalid
    And the rejection identifies "positions" as the source of the error

  Scenario: Creating a diagram without any skill is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "guitar" with the skill_ids field omitted
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: A diagram cannot use a skill that is for none of its instruments
    Given a fretted instrument "bass" exists in the system
    And a root skill "palm-muting" for instrument "guitar" exists in the system
    And "bob" is authenticated as a teacher
    When "bob" submits a create diagram request on instrument "bass" classified under skill "palm-muting"
    Then the request is rejected as invalid
    And the rejection identifies "skill_ids" as the source of the error

  Scenario: Creating a diagram against an instrument that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request with an instrument id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "instrument_ids" as the source of the error

  # ── Not found ──────────────────────────────────────────────────────────────

  Scenario: Retrieving a diagram that does not exist returns not found
    Given "alice" is authenticated as a student
    When "alice" retrieves a diagram with an ID that does not exist
    Then the request is refused with a not-found error

  # ── Authorisation failures ─────────────────────────────────────────────────

  Scenario: A student cannot create a diagram
    Given "alice" is authenticated as a student
    When "alice" attempts to create a diagram
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot update a basic diagram
    Given a basic diagram "major-scale-guitar" exists on instrument "guitar"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "major-scale-guitar" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  Scenario: A teacher cannot update another teacher's custom diagram
    Given a custom diagram "carols-arpeggio" exists on instrument "guitar", created by "carol"
    And "bob" is authenticated as a teacher
    When "bob" updates diagram "carols-arpeggio" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  Scenario: A student cannot update a diagram
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "alice" is authenticated as a student
    When "alice" updates diagram "bobs-pentatonic" setting root note "G" and label display "note"
    Then the request is refused with a forbidden error

  Scenario: A student cannot list diagrams
    Given "alice" is authenticated as a student
    When "alice" lists all diagrams
    Then the request is refused with a forbidden error

  Scenario: Creating a diagram without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a diagram
    Then the request is refused with an authentication error
