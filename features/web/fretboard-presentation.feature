# Presentation behavior of fretted diagrams in the web application.
#
# These scenarios describe what a student or teacher sees and does on screen. They are
# verified by motifpath-web's component tests and by manual browser checks, not by the
# core-domain BDD suite, which runs only the domain directories under features/.
#
# The domain rules they rely on are specified elsewhere and are not restated here:
#   - authored positions, labels, shapes, colors, notes and regions:
#       features/content-management/diagrams.feature (ADR-028, ADR-034)
#   - per-use labels, hidden positions and answer cells: ADR-040
#   - sequences, voices, tempo precedence and playback eligibility:
#       features/content-management/diagrams.feature, voices.feature (ADR-041)
#
# Sizes are CSS pixels. "Narrow screen" means a 360 px wide viewport.

Feature: Fretboard presentation
  As a student reading a fretted diagram on any screen
  I want a legible, instrument-like board whose highlighted areas explain themselves on demand
  So that I can read, hear and answer a diagram on a phone as easily as on a desktop

  Background:
    Given a six-string fretted instrument "guitar"

  # ── Board window ─────────────────────────────────────────────────────────────

  Rule: The board shows exactly the frets the diagram uses

    Scenario: The window spans the used frets with no empty fret space beyond them
      Given a diagram with drawn positions on frets 5 and 8
      When the student views the diagram
      Then the board shows fret spaces 5 to 8
      And no empty fret space is drawn after fret 8

    Scenario: Regions and answer cells widen the window
      Given a diagram with a drawn position on fret 5
      And a region spanning frets 5 to 9
      And an answer cell on fret 10
      When the student views the diagram
      Then the board shows fret spaces 5 to 10

    Scenario: A short diagram still shows a minimum span
      Given a diagram with a single drawn position on fret 7
      When the student views the diagram
      Then the board shows 3 fret spaces including fret 7

    Scenario: An empty diagram shows an open-position board
      Given a diagram with no positions and no regions
      When the student views the diagram
      Then the board starts at the nut and shows 3 fret spaces

    Scenario: A hidden position neither widens nor reveals the window for a student
      Given a diagram with drawn positions on frets 5 to 8 and a hidden position on fret 12
      When the student views the diagram
      Then the board shows fret spaces 5 to 8

    Scenario: An author's preview widens the window to reveal hidden positions
      Given a diagram with drawn positions on frets 5 to 8 and a hidden position on fret 12
      When the teacher previews the diagram with hidden positions revealed
      Then the board shows fret spaces 5 to 12
      And the hidden position is drawn faded

  # ── Readable geometry ────────────────────────────────────────────────────────

  Rule: The board stays readable on a narrow screen

    Scenario: Fret numbers and marker text keep a readable size on a phone
      Given a diagram spanning 5 fret spaces
      When the student views it on a narrow screen
      Then fret numbers and marker text are at least 14 px tall

    Scenario: Every fret space has the same width
      Given a diagram spanning 5 fret spaces
      When the student views it at any screen width
      Then every fret space on the board has the same width

    Scenario: A board that fits the screen fills its width without scrolling
      Given a diagram spanning 4 fret spaces
      When the student views it on a 1280 px wide screen
      Then the board fills the available width
      And the board does not scroll

    Scenario: A board wider than the screen scrolls on its own
      Given a diagram spanning 12 fret spaces
      When the student views it on a narrow screen
      Then only the board scrolls horizontally
      And the page itself does not scroll horizontally

    Scenario: Keyboard focus brings an off-screen answer into view
      Given a diagram spanning 12 fret spaces with a selectable position on fret 12
      And the student views it on a narrow screen with the board scrolled to the nut
      When the student moves keyboard focus to that position
      Then the board scrolls until that position is fully visible

    Scenario: Adjacent answer targets do not overlap
      Given an exercise diagram with selectable positions on frets 5 and 6 of the same string
      When the student views it on a narrow screen
      Then each position's touch target is at least 44 px wide
      And tapping either position selects only that position

    Scenario: Open-string markers on the nut are fully visible
      Given a diagram with drawn positions on fret 0 of every string
      When the student views it on a narrow screen
      Then every open-string marker and its label is fully visible
      And an open-string marker's touch target does not overlap a fret-1 marker's target

  # ── Instrument materials ─────────────────────────────────────────────────────

  Rule: The board looks like a real fretboard without changing what it means

    Scenario: Only an open-position board displays a nut
      Given a diagram whose window starts at fret 0
      When the student views the diagram
      Then a nut is drawn at the left edge of the board

    Scenario: A board above the open position shows a cropped neck
      Given a diagram whose window starts above fret 0
      When the student views the diagram
      Then no nut is drawn
      And the left edge of the board is a plain fret

    Scenario Outline: Fret inlays mark the conventional frets
      Given a diagram whose window includes fret <fret>
      When the student views the diagram
      Then <inlay> is drawn in fret space <fret>

      Examples:
        | fret | inlay           |
        | 3    | a single inlay  |
        | 5    | a single inlay  |
        | 12   | a double inlay  |

    Scenario: Strings are drawn thicker as their open pitch gets lower
      Given "guitar" is tuned E2 A2 D3 G3 B3 E4 from its lowest to its highest string
      When the student views a diagram on "guitar"
      Then the E2 string is drawn thickest and the E4 string thinnest
      And no string is drawn thinner than a string with a higher open pitch

    Scenario: A re-entrant tuning is drawn by pitch, not by string order
      Given a four-string fretted instrument tuned G4 C4 E4 A4 in string order
      When the student views a diagram on that instrument
      Then the C4 string is drawn thickest
      And the G4 string is not drawn thicker than the C4 string

    Scenario: An instrument without a tuning uses a uniform string thickness
      Given a fretted instrument that has a string count but no tuning
      When the student views a diagram on that instrument
      Then every string is drawn at the same thickness

    Scenario: The board uses wood, metal fret and string materials in both themes
      Given a diagram
      When the student views it in the light theme and in the dark theme
      Then the board has a wood surface, metallic frets and visible strings in each theme
      And markers, labels and fret numbers keep sufficient contrast against the board

    Scenario: The board remains complete without its decorative texture
      Given the board's decorative wood grain is unavailable
      When the student views the diagram
      Then the plain board still shows frets, strings, inlays, markers, labels, regions and answer targets

    Scenario: Several diagrams on one page keep their own appearance
      Given a page showing three diagrams with different regions and marker colors
      When the student views the page
      Then each diagram renders with its own colors and board materials

  # ── Markers ──────────────────────────────────────────────────────────────────

  Rule: Markers render exactly as the author saved them

    Scenario Outline: Each authored marker shape is drawn as that shape
      Given a diagram with a position whose shape is "<shape>"
      When the student views the diagram
      Then that position is drawn as a <shape>

      Examples:
        | shape  |
        | dot    |
        | square |
        | star   |

    Scenario: A root position keeps its authored shape
      Given a diagram whose root position is authored as a dot
      When the student views the diagram
      Then the root position is drawn as a dot, not a star

    Scenario: An authored color and custom label are preserved
      Given a diagram with a position colored "#22C55E" whose custom label is "T"
      When the student views the diagram
      Then that position is drawn in "#22C55E" with the label "T"

    Scenario: Selected, focused and sounding markers remain distinguishable
      Given an exercise diagram with a selectable position that is also in the playback sequence
      When that position is selected, keyboard-focused and sounding at the same time
      Then each of the three states is visible without hiding the others
      And the marker keeps its authored shape, color and label

    Scenario: A low-contrast authored color stays legible
      Given a diagram with a position colored close to the board's wood color
      When the student views the diagram
      Then the marker remains distinguishable from the board
      And the stored color is not changed

  # ── Regions ──────────────────────────────────────────────────────────────────

  Rule: Every region is filled, outlined and identifiable

    Scenario: A region is drawn as a translucent fill with a matching boundary
      Given a diagram with a region colored "#22C55E" spanning frets 5 to 8
      When the student views the diagram
      Then the region is filled with translucent "#22C55E"
      And its boundary is drawn in "#22C55E"
      And the markers inside the region remain visible through the fill

    Scenario: Overlapping regions keep separate parallel boundaries
      Given a diagram with two regions that both span frets 5 to 8
      When the student views the diagram
      Then both regions keep their complete translucent fill
      And both boundaries are visible as parallel lines

    Scenario: A nested region stays visible inside a larger one
      Given a diagram with a region spanning frets 5 to 10 and a region spanning frets 6 to 8
      When the student views the diagram
      Then both regions' fills and boundaries are visible

    Scenario: The range badge and permanent description are no longer shown
      Given a diagram with a described region
      When the student views the diagram
      Then no fret-range badge or permanently visible description is drawn for the region

  Rule: Each region offers one information control near its last fret

    Scenario: A region's information control sits near its last fret
      Given a diagram with a region spanning frets 5 to 8 described as "Box 1"
      When the student views the diagram
      Then one information control in the region's color appears above the board near fret 8
      And the control's accessible name is "Box 1"
      And the control's touch target is at least 44 px square

    Scenario: Regions ending on the same fret place their controls side by side
      Given a diagram with three regions that all end on fret 8
      When the student views the diagram
      Then their three information controls appear side by side near fret 8
      And no control covers another control or a marker

    Scenario: Many regions widen the board instead of overlapping controls
      Given a diagram with more regions than information controls fit across the screen
      When the student views it on a narrow screen
      Then the board widens so every region keeps its own information control
      And every region keeps its boundary

    Scenario: Information controls move with the board
      Given a region within a diagram wider than the screen
      When the student scrolls the board horizontally
      Then the region's information control moves with the region

  Rule: Region descriptions open on demand next to their region

    Scenario: Opening a region's information shows its description
      Given a diagram with a region described as "Box 1"
      When the student activates the region's information control
      Then a description reading "Box 1" opens next to that control
      And the control reports that it is expanded

    Scenario: Tapping the region itself opens its description
      Given a diagram with a region described as "Box 1"
      When the student taps inside the region away from any marker
      Then the description reading "Box 1" opens

    Scenario: Opening another region replaces the open description
      Given the description of one region is open
      When the student activates another region's information control
      Then only the second region's description is open

    Scenario: A long Portuguese description wraps within the visible board
      Given the student's language is Portuguese
      And a region described with 60 characters in Portuguese
      When the student opens its description on a narrow screen
      Then the complete description is visible, wrapped within the visible board width
      And its text is vertically centered beside its close control

    Scenario: A description stays on screen at either scroll extreme
      Given a region at the far end of a diagram wider than the screen
      When the student scrolls the board to the end and opens the region's description
      Then the whole description is visible within the board

    Scenario: A description follows its region when the board scrolls or resizes
      Given a region's description is open
      When the student scrolls the board or resizes the window
      Then the description stays anchored next to its information control

    Scenario Outline: A region description can be dismissed
      Given a region's description is open
      When the student <dismissal>
      Then the description closes

      Examples:
        | dismissal                                    |
        | activates the description's close control    |
        | activates the same information control again |
        | presses Escape                               |
        | taps outside the description and its control |

    Scenario: Closing with the keyboard returns focus to the information control
      Given the student opened a region's description with the keyboard
      When the student presses Escape or activates the close control
      Then keyboard focus returns to that region's information control

    Scenario: Tapping a note outside the description still selects it
      Given an exercise diagram with a region's description open
      When the student taps a selectable position outside the description
      Then the description closes
      And that position becomes selected

    Scenario: A marker note tooltip still opens beside its marker
      Given a diagram with a position that has an authored note, on a board scrolled horizontally
      When the student opens the position's note
      Then the note appears beside that marker

  # ── Playback presentation ────────────────────────────────────────────────────

  Rule: Playback controls belong to the diagram's control rail

    Scenario: A playable diagram shows compact Play and tempo controls in its rail
      Given a diagram used with playback enabled and a sequence that sounds at least one position
      When the student views the diagram
      Then a Play control and a tempo control showing the effective BPM appear in the diagram's control rail
      And they sit beside the region information controls without overlapping them
      And each has a touch target of at least 44 px square
      And no separate playback footer is shown

    Scenario: A diagram without sounding steps offers no player
      Given a diagram whose sequence contains only rests
      When the student views the diagram
      Then no Play or tempo control is shown

    Scenario: Pressing Play plays the sequence and highlights sounding positions
      Given a playable diagram
      When the student presses Play
      Then the diagram's sequence plays with its configured voice
      And each visible position is highlighted while it sounds
      And the Play control becomes a Stop control

    Scenario: Stop ends playback and clears the highlights
      Given a playable diagram that is playing
      When the student presses Stop
      Then playback stops
      And no position is highlighted as sounding

    Scenario: A hidden position may sound but is never revealed
      Given a playable diagram whose sequence includes a position this use hides
      When that position sounds
      Then no marker, label, highlight or note is drawn for it
      And the board does not scroll toward it

    Scenario: Loading shows progress and can be cancelled
      Given a playable diagram whose samples are still loading after Play was pressed
      When the student views the Play control
      Then it shows a loading state and announces it to assistive technology
      And pressing it again cancels playback

    Scenario: Unavailable samples show a Retry action
      Given a playable diagram whose samples could not be loaded
      When the student pressed Play
      Then an error message and a Retry action are shown
      And no sound is faked with a substitute instrument
      And the diagram's markers, regions and answers remain usable

    Scenario: Retry recovers after samples become available
      Given a playable diagram showing the Retry action
      And its samples can now be loaded
      When the student presses Retry
      Then the sequence plays

  Rule: Tempo is adjusted in a panel opened on demand

    Scenario: Opening the tempo control shows a slider and numeric input
      Given a playable diagram on a narrow screen
      When the student opens the tempo control
      Then a panel with a slider and a numeric input from 20 to 300 BPM opens within the diagram

    Scenario: A new tempo applies from the next step without saving
      Given a playable diagram that is playing at 80 BPM
      When the student sets the tempo to 120 BPM
      Then the following steps play at 120 BPM
      And the diagram and its usage keep their stored tempo

    Scenario Outline: An invalid tempo entry is ignored
      Given a playable diagram at 80 BPM with its tempo panel open
      When the student types "<entry>" into the tempo input and leaves it
      Then the tempo remains 80 BPM
      And the input shows 80

      Examples:
        | entry |
        | 19    |
        | 301   |
        | 90.5  |

    Scenario: The tempo panel closes by outside press or Escape
      Given a playable diagram with its tempo panel open
      When the student presses Escape
      Then the panel closes
      And keyboard focus returns to the tempo control

    Scenario: Two players on one page keep separate tempo panels
      Given a page with two playable diagrams
      When the student opens the tempo panel of the second diagram
      Then only the second diagram's panel opens
      And each panel's label refers to its own numeric input

  Rule: Only one diagram plays at a time

    Scenario: Starting a second diagram stops the first
      Given two playable diagrams on one page and the first is playing
      When the student presses Play on the second diagram
      Then the first diagram stops and clears its highlights
      And the second diagram plays

    Scenario: Leaving the page stops playback
      Given a playable diagram that is playing
      When the student navigates away from the page
      Then playback stops

  # ── Exercise options ─────────────────────────────────────────────────────────

  Rule: Exploring a diagram answer option never selects it

    Scenario: Playing an option does not select it
      Given an image-choice exercise whose options are playable diagrams
      When the student plays an option, adjusts its tempo or opens one of its region descriptions
      Then no option becomes selected

    Scenario: Choosing an option still selects it
      Given an image-choice exercise whose options are playable diagrams
      When the student activates an option's drawing or selection control
      Then that option becomes selected

    Scenario: An option without playback shows no player but keeps its region information
      Given an image-choice exercise whose option diagram has playback disabled and a described region
      When the student views the options
      Then the option shows no Play or tempo control
      And the option still offers the region's information control

  Rule: Catalog thumbnails are compact, static drawings

    Scenario: A diagram thumbnail in a picker is static
      Given the teacher browses diagrams in a diagram picker
      When the thumbnails are shown
      Then each thumbnail is a compact board without Play, tempo or region information controls
      And a thumbnail does not scroll or take a full-size board's minimum width

  # ── Teacher consistency ──────────────────────────────────────────────────────

  Rule: Authors see what students will see

    Scenario: The editor and the student view agree on the board
      Given a diagram with positions, regions and authored shapes
      When the teacher edits it and then previews it as a student
      Then both show the same fret window, fret positions, materials and marker shapes

    Scenario: Sequence recording keeps its step highlights on the new board
      Given the teacher is recording a sequence in the diagram editor
      When the teacher selects a recorded step
      Then the positions of that step are highlighted on the board
      And tapping a position still records it into the sequence
