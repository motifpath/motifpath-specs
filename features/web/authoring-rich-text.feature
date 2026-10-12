# The rich-text editor on a phone (MOT-61 D14, D15; MOT-95 slice 4).
#
# An exercise prompt and an article lesson use the same TipTap editor at every size, with every
# command of today's toolbar. On Compact (< 600 px) the commands are regrouped: a bar docked above
# the keyboard while the editor has focus, and three sheets — Format, Insert and Table. Medium and
# Expanded keep today's one-row toolbar, with the table row while the cursor is in a table.
# design/patterns/authoring.md, "Rich text"; the Figma page is "Authoring", row 7 (7a–7g) and its
# dark pt-BR copy.
#
# Where a song chart may be embedded (article lessons only, never an exercise prompt) is
# song-chart.md and features/web/song-chart-authoring.feature. How the diagram picker works is
# features/web/fretboard-presentation.feature and authoring.md, "Diagrams in authoring".
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite.

@web
Feature: Write rich text from a phone
  As a teacher fixing a prompt or an article from a phone
  I want every formatting, insert and table command within reach above the keyboard
  So that I never need a computer to change rich text

  Background:
    Given "bob" is signed in as a teacher
    And "bob" is editing the prompt of their exercise "Find the A on string 5"

  # ── The docked bar ───────────────────────────────────────────────────────────

  Rule: On Compact, a bar docks above the keyboard while the editor has focus

    Scenario: Typing in the prompt shows the docked bar
      Given "bob" uses a phone
      When "bob" taps into the prompt
      Then a bar docks above the on-screen keyboard
      And it offers Undo, Redo, Format, Bold, Italic, List, Insert and Hide keyboard

    Scenario: The bar is gone once the editor loses focus
      Given "bob" uses a phone
      And "bob" is typing in the prompt
      When "bob" taps Hide keyboard
      Then the keyboard closes
      And the docked bar is no longer shown

    Scenario Outline: Bold, Italic and List act on the selection at once
      Given "bob" uses a phone
      And "bob" has selected "string 5" in the prompt
      When "bob" taps <command> in the docked bar
      Then <result>
      And <command> shows as active in the docked bar

      Examples:
        | command | result                                       |
        | Bold    | "string 5" is bold                           |
        | Italic  | "string 5" is italic                         |
        | List    | the paragraph holding "string 5" is a bullet |

    Scenario: Undo and Redo are available only when there is something to undo or redo
      Given "bob" uses a phone
      And "bob" has made no change to the prompt
      When "bob" taps into the prompt
      Then Undo and Redo are disabled

    Scenario Outline: Medium and Expanded keep today's one-row toolbar
      Given "bob" uses a <device>
      When "bob" taps into the prompt
      Then the editor shows today's one-row toolbar above the text
      And no bar docks at the foot of the screen

      Examples:
        | device   |
        | tablet   |
        | computer |

  # ── Format ───────────────────────────────────────────────────────────────────

  Rule: Format holds every style, mark, colour, alignment and list command

    Scenario: Format offers everything that is not an insert
      Given "bob" uses a phone
      And "bob" is typing in the prompt
      When "bob" taps Format in the docked bar
      Then the Format sheet opens over the keyboard
      And it offers the styles Paragraph, Heading 1, Heading 2 and Heading 3
      And it offers the marks Bold, Italic, Strikethrough and Highlight
      And it offers a text colour and a background colour from today's palette
      And it offers the alignments Left, Centre, Right and Justify
      And it offers Bullets and Numbers

    Scenario: A Format choice applies at once and the sheet stays open
      Given "bob" uses a phone
      And "bob" has selected "Find the A" in the prompt
      And the Format sheet is open
      When "bob" taps Heading 1
      Then "Find the A" is a level-1 heading
      And Heading 1 shows as chosen
      And the Format sheet is still open

    Scenario: Closing Format returns to typing
      Given "bob" uses a phone
      And the Format sheet is open
      When "bob" closes the Format sheet
      Then the cursor is back where it was in the prompt
      And the docked bar is shown again

  # ── Insert ───────────────────────────────────────────────────────────────────

  Rule: Insert adds a link, a table, an image, a diagram and, in an article, a song chart

    Scenario: Insert in an exercise prompt
      Given "bob" uses a phone
      And "bob" is typing in the prompt
      When "bob" taps Insert in the docked bar
      Then the Insert sheet offers Link, Table, Image and Diagram
      And it does not offer Song chart

    Scenario: Insert in an article lesson also offers a song chart
      Given "bob" uses a phone
      And "bob" is typing in the article of their lesson "Reading chord charts"
      When "bob" taps Insert in the docked bar
      Then the Insert sheet offers Link, Table, Image, Diagram and Song chart

    Scenario: Inserting a table adds 3 × 3 cells with a header row
      Given "bob" uses a phone
      And the Insert sheet is open
      When "bob" taps Table
      Then a table of 3 rows and 3 columns is inserted at the cursor
      And its first row is a header row

    Scenario: Inserting an image picks one from the phone
      Given "bob" uses a phone
      And the Insert sheet is open
      When "bob" taps Image and picks a photo
      Then the photo is uploaded and inserted at the cursor

    Scenario: An image that fails to upload is not inserted
      Given "bob" uses a phone
      And the Insert sheet is open
      And image uploads are failing
      When "bob" taps Image and picks a photo
      Then nothing is inserted in the prompt
      And a toast says the image could not be uploaded

    Scenario: Inserting a diagram opens the diagram picker
      Given "bob" uses a phone
      And the Insert sheet is open
      When "bob" taps Diagram
      Then the diagram picker opens as a full-screen layer
      And the picked diagram is inserted at the cursor

  # ── Links ────────────────────────────────────────────────────────────────────

  Rule: A link is set in a short sheet, never a browser prompt

    Scenario: Adding a link
      Given "bob" uses a phone
      And "bob" has selected "the open string" in the prompt
      When "bob" taps Link in the Insert sheet
      Then a Link sheet asks for the address
      When "bob" types "https://example.com/open-strings" and taps Apply
      Then "the open string" links to "https://example.com/open-strings"

    Scenario: Apply waits for an address
      Given "bob" uses a phone
      And the Link sheet is open with an empty address
      Then Apply is disabled

    Scenario: The Link sheet is used at every size
      Given "bob" uses a computer
      And "bob" has selected "the open string" in the prompt
      When "bob" clicks Link in the toolbar
      Then a Link dialog asks for the address

    Scenario: Removing a link
      Given "bob" uses a phone
      And the cursor is in a link in the prompt
      When "bob" opens the Link sheet
      Then the address field shows the link's address
      And the sheet offers Remove link
      When "bob" taps Remove link
      Then the text is no longer a link

  # ── Tables ───────────────────────────────────────────────────────────────────

  Rule: Inside a table the bar offers Table, and the Table sheet holds every table command

    Scenario: The Table chip replaces Italic and List inside a table
      Given "bob" uses a phone
      When "bob" taps into a cell of a table in the prompt
      Then the docked bar shows a Table chip in place of Italic and List

    Scenario: The Table sheet offers today's table commands
      Given "bob" uses a phone
      And the cursor is in a table cell
      When "bob" taps the Table chip
      Then the Table sheet offers, as icon buttons, add and delete column, add and delete row
      And header row, header column and header cell
      And merge cells, split cell, cell border and cell colour
      And delete table

    Scenario: A long press names a table command
      Given "bob" uses a phone
      And the Table sheet is open
      When "bob" long-presses the add-column icon
      Then its name "Add column" is shown

    Scenario: Merging cells — drag across them, then Merge
      Given "bob" uses a phone
      And the prompt has a table
      When "bob" drags across two cells of a row
      And "bob" taps Merge cells in the Table sheet
      Then the two cells become one

    Scenario: Split undoes a merge
      Given "bob" uses a phone
      And the cursor is in a merged cell
      When "bob" taps Split cell in the Table sheet
      Then the cell is split back into its cells

  # ── Embedded diagrams and song charts ────────────────────────────────────────

  Rule: On an embedded diagram or song chart the bar offers Edit

    Scenario: Selecting an embedded diagram offers Edit
      Given "bob" uses a phone
      And the prompt embeds the diagram "A on string 5"
      When "bob" taps the embedded diagram
      Then the diagram is selected
      And the docked bar shows an Edit chip
      When "bob" taps Edit
      Then the diagram picker opens on the diagram's settings

    Scenario: Selecting an embedded song chart offers Edit
      Given "bob" uses a phone
      And the article of their lesson "Reading chord charts" embeds a song chart
      When "bob" taps the embedded song chart
      Then the docked bar shows an Edit chip
      When "bob" taps Edit
      Then the song chart picker opens to replace it
