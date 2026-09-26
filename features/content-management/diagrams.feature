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

  # ── Listing — filtering and pagination ────────────────────────────────────

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

  # ── Retrieving ─────────────────────────────────────────────────────────────

  Scenario: A student retrieves a teacher's custom diagram by its id
    Given a custom diagram "bobs-pentatonic" exists on instrument "guitar", created by "bob"
    And "alice" is authenticated as a student
    When "alice" retrieves diagram "bobs-pentatonic"
    Then the response is diagram "bobs-pentatonic"

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

  Scenario: Creating a diagram against an instrument that does not exist is rejected
    Given "bob" is authenticated as a teacher
    When "bob" submits a create diagram request with an instrument id that does not exist
    Then the request is rejected as invalid
    And the rejection identifies "instrument_id" as the source of the error

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

  Scenario: A teacher cannot list another teacher's diagrams
    Given "bob" is authenticated as a teacher
    When "bob" lists diagrams filtered by creator "carol"
    Then the request is refused with a forbidden error

  Scenario: Creating a diagram without an authentication token is refused
    Given no authentication token is provided
    When an unauthenticated request attempts to create a diagram
    Then the request is refused with an authentication error
