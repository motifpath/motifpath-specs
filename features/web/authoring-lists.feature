# The authoring lists at volume (MOT-61 D4, D5, D24–D28; MOT-95 slice 2).
#
# Every Teach section (courses, paths, lessons, exercises, diagrams) lists its items with one pattern:
# title + New, status chips where the section has a publish state, search and Filters, the applied
# filters as removable chips, a count line with the sort, then the items, 20 at a time.
# design/patterns/authoring.md, "Lists"; the Figma page is "Authoring", rows 2, 13 and 17 (row 17,
# approved 2026-10-12, brings row 13 up to the API MOT-93 shipped).
#
# What each filter matches — any of several skills or concepts, an area with its sub-skills, the
# lesson statuses, creator counts, sort=title|updated and an exact PageMeta.total — is the server's:
# features/content-management/authoring-lists.feature (ADR-053). These scenarios cover only what
# the screens offer and remember.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite.

@web
Feature: Find an item in the authoring lists
  As a teacher or an admin with thousands of diagrams and hundreds of lessons and exercises
  I want every Teach list to search, filter, sort and count the way the API can
  So that I open the item I need instead of building it again

  Background:
    Given "bob" is signed in as a teacher
    And "ana" is signed in as an admin

  # ── One pattern ──────────────────────────────────────────────────────────────

  Rule: Every list shows its items with what tells them apart

    Scenario Outline: A section with a publish state offers status chips
      When "bob" opens the <section> list
      Then the list offers the status chips <chips>, with "All" chosen

      Examples:
        | section | chips                                                |
        | Courses | "All", "Drafts", "Published", "Retired"              |
        | Paths   | "All", "Drafts", "Published"                         |
        | Lessons | "All", "Drafts", "Published", "Unpublished changes"  |

    Scenario Outline: A section without a publish state has no status chips
      When "bob" opens the <section> list
      Then the list shows no status chips and no status on its items

      Examples:
        | section   |
        | Exercises |
        | Diagrams  |

    Scenario: A status chip narrows the list
      Given "bob" has the lessons "Open chords" (published) and "Barre chords" (a draft)
      When "bob" chooses the "Drafts" chip on the Lessons list
      Then the list shows "Barre chords" only

    Scenario: Courses, paths, lessons and exercises are rows; diagrams are a grid of thumbnails
      When "bob" opens the Exercises list and then the Diagrams list
      Then each exercise is a row with its type in the meta line
      And each diagram is a thumbnail of its board, with "Template" on the templates

    Scenario: Tapping an item opens its editor
      When "bob" taps the exercise "Which interval did you hear?" on the Exercises list
      Then "bob" is in the editor of "Which interval did you hear?"

  # ── Filters ──────────────────────────────────────────────────────────────────

  Rule: Each section offers exactly the filters its API takes

    Scenario Outline: The filters of a section
      When "bob" opens the filters of the <section> list
      Then the filters are <filters>, in that order

      Examples:
        | section   | filters                                                                    |
        | Diagrams  | Instrument, Kind, Shows, Root note, Language, Skill, Concept, Author       |
        | Exercises | Type, Instrument, Language, Skill, Concept, Author                         |
        | Lessons   | Type, Level, Instrument, Language, Skill, Concept, Author                  |
        | Paths     | Level, Instrument, Language, Skill, Concept, Author                        |
        | Courses   | Level, Instrument, Language, Skill, Concept, Author                        |

    Scenario: Exercises have no diagram-only filters
      When "bob" opens the filters of the Exercises list
      Then there is no Kind, Shows or Root note filter

    Scenario: Kind and Shows on Diagrams
      When "bob" opens the filters of the Diagrams list
      Then Kind offers "All", "Templates" and "Custom"
      And Shows offers "Diagrams", "Chord voicings" and "Both"

    Scenario: Root note takes one note
      Given "bob" has chosen the root note "A" in the Diagrams filters
      When "bob" chooses the root note "E"
      Then the root note is "E" only

    Scenario: Any clears the root note
      Given "bob" has chosen the root note "A" in the Diagrams filters
      When "bob" chooses the root note "Any"
      Then the Diagrams filters have no root note

  Rule: Filters open as a layer on Compact, a dialog on Medium and a side panel on Expanded

    Scenario: On Compact the filters are a full-screen layer with the live total
      Given "bob" is on a phone
      When "bob" opens the filters of the Diagrams list
      Then the filters fill the screen, with "Clear all" at the top
      And the button at the foot shows the total for the current choice, like "Show 46 diagrams"

    Scenario: The layer's total follows each choice before it is applied
      Given "bob" has the filters of the Diagrams list open on a phone
      When "bob" chooses the instrument "Guitar"
      Then the button shows the total of guitar diagrams
      And the list behind the layer is unchanged until "bob" taps the button

    Scenario: Closing the layer without applying keeps the list as it was
      Given "bob" has chosen "Custom" in the Diagrams filters on a phone without applying it
      When "bob" closes the layer
      Then the list's filters are unchanged

    Scenario: On Expanded the filters are a side panel that applies at once
      Given "bob" is on a computer
      When "bob" opens the Diagrams list
      Then the filters are a panel beside the list
      And choosing "Custom" narrows the list at once

  Rule: Applied filters show as removable chips with Clear all

    Scenario: Each applied filter is a chip
      Given "bob" has filtered the Diagrams list by "Guitar", "Custom" and the root note "A"
      Then the list shows the chips "Guitar", "Custom" and "Root A", and "Clear all"

    Scenario: Removing a chip removes that filter only
      Given "bob" has filtered the Diagrams list by "Guitar" and "Custom"
      When "bob" removes the "Custom" chip
      Then the list is filtered by "Guitar" only

    Scenario: Clear all removes every filter but keeps the search and the sort
      Given "bob" has searched the Diagrams list for "pentatonic", sorted it by recently changed and filtered it by "Guitar"
      When "bob" taps "Clear all"
      Then the list has no filters
      And the search is still "pentatonic" and the sort still "Recently changed"

  # ── Skills, concepts and authors ─────────────────────────────────────────────

  Rule: Skill and Concept take several, and an area brings its sub-skills

    Scenario: Choosing two skills keeps both
      Given "bob" has the Skills picker open from the Diagrams filters
      When "bob" chooses "Pentatonic shapes" and "Modes"
      Then both show as chosen and as chips at the top of the picker
      And "Done · 2 skills" goes back to the filters, where Skill reads "2 skills"

    Scenario: One chosen skill is named in the filters
      Given "bob" has chosen only "Pentatonic shapes" in the Skills picker
      When "bob" taps Done
      Then Skill reads "Pentatonic shapes" in the filters

    Scenario: Tapping an area chooses it
      Given "bob" has the Skills picker open at "Scales"
      When "bob" taps the area "Modes"
      Then "Modes" is chosen

    Scenario: An area's skill count opens it
      Given "bob" has the Skills picker open at "Scales"
      When "bob" taps "7 skills ›" on "Modes"
      Then the picker shows the skills under "Modes", with the path "Skills › Scales › Modes"
      And "Modes" is not chosen

    Scenario: The picker says an area brings its sub-skills
      When "bob" opens the Skills picker
      Then it says that choosing an area matches it and every skill under it

    Scenario: A chosen skill is removed from its chip
      Given "bob" has chosen "Pentatonic shapes" and "Modes" in the Skills picker
      When "bob" removes the "Modes" chip
      Then only "Pentatonic shapes" is chosen

    Scenario: The skill tree is scoped to the filtered instrument
      Given "bob" has filtered the Diagrams list by "Guitar"
      When "bob" opens the Skills picker
      Then it shows the guitar skills, with "All instruments" to widen it

    Scenario: The skills picker lists recent choices first
      Given "bob" chose "Pentatonic shapes" in an earlier search
      When "bob" opens the Skills picker
      Then "Pentatonic shapes" is under Recent

    Scenario: Concepts use the same picker
      When "bob" opens the Concepts picker from the Exercises filters
      Then "bob" can choose several concepts, and an area brings its sub-concepts

    Scenario: On Expanded the tree is inline in the panel
      Given "bob" is on a computer on the Diagrams list
      When "bob" chooses "Pentatonic shapes" and "Modes" in the panel's skill tree
      Then both are marked in the tree and show as chips above the grid

  Rule: Author is Me first, then any teacher, with how many items each has

    Scenario: The author picker shows Me first and counts per author
      When "bob" opens the Author picker from the Diagrams filters
      Then "Anyone" comes first, then "Me — Bob", then the other authors
      And each author shows how many diagrams they have, like "214 diagrams"

    Scenario: Authors are searched by name
      Given "bob" has the Author picker open from the Exercises filters
      When "bob" searches for "ana"
      Then the picker lists the exercise authors whose name matches "ana", ignoring case and accents

    Scenario: Anyone clears the author
      Given "bob" has filtered the Exercises list by the author "Ana Souza"
      When "bob" chooses "Anyone" in the Author picker
      Then the list has no author filter

    Scenario: An admin sees the same author list
      When "ana" opens the Author picker from the Courses filters
      Then "ana" sees "Me — Ana" first, then the other authors with their counts

  # ── Search, count and sort ───────────────────────────────────────────────────

  Rule: The count line says how many match, and the sort is beside it

    Scenario: With no filters the count is the section's total
      Given "bob" can see 1,284 diagrams
      When "bob" opens the Diagrams list
      Then the count line reads "1,284 diagrams"

    Scenario: With a search or filters the count is out of the section's total
      Given "bob" can see 1,284 diagrams, 46 of them custom guitar diagrams with the root A
      When "bob" filters the Diagrams list by "Guitar", "Custom" and the root note "A"
      Then the count line reads "46 of 1,284 diagrams"

    Scenario: Searching narrows the list by name
      When "bob" searches the Diagrams list for "pentatonic"
      Then the list shows only diagrams whose name matches "pentatonic"

    Scenario Outline: Every list sorts by name or by what changed last
      When "bob" opens the sort of the <section> list
      Then the sort offers "Name A–Z" and "Recently changed", with "Name A–Z" chosen

      Examples:
        | section   |
        | Courses   |
        | Paths     |
        | Lessons   |
        | Exercises |
        | Diagrams  |

    Scenario: Recently changed puts the last edited item first
      Given "bob" edited the exercise "Name the chord" after "Which interval did you hear?"
      When "bob" sorts the Exercises list by "Recently changed"
      Then "Name the chord" is listed before "Which interval did you hear?"

  # ── Remembered ───────────────────────────────────────────────────────────────

  Rule: Search, filters and sort are remembered per section

    Scenario: The choice is in the address, so a link reopens it
      Given "bob" has searched the Diagrams list for "pentatonic", filtered it by "Guitar" and sorted it by "Recently changed"
      When "bob" opens the same address in a new tab
      Then the Diagrams list has the same search, filter and sort

    Scenario: Coming back from an editor restores the list and the scroll position
      Given "bob" has filtered the Exercises list, scrolled to its 45th item and opened it
      When "bob" goes back from the editor
      Then the Exercises list has the same filters and shows the 45th item where it was

    Scenario: Each section remembers its own choice on this device
      Given "bob" filtered the Diagrams list by "Guitar" and the Exercises list by "Audio recognition"
      When "bob" opens the Diagrams list from Teach
      Then it is filtered by "Guitar"
      And the Exercises list is still filtered by "Audio recognition"

    Scenario: An address with a filter the section doesn't take ignores it
      When "bob" opens the Exercises list at an address that asks for the root note "A"
      Then the Exercises list has no filters

  # ── Long lists and states ────────────────────────────────────────────────────

  Rule: Long lists load 20 at a time, and every state keeps the search and filters

    Scenario: The next page loads at the end of the list
      Given "bob" can see 1,284 diagrams
      When "bob" opens the Diagrams list
      Then 20 diagrams are shown
      When "bob" scrolls to the end of them
      Then the next 20 load below

    Scenario: A failed page offers Try again in place
      Given "bob" has 40 diagrams shown and loading the next page fails
      Then the 40 diagrams stay and "Try again" shows below them
      When "bob" taps "Try again"
      Then the next page loads

    Scenario: A section with nothing yet says what it is for
      Given "bob" has authored no paths and none are shared with them
      When "bob" opens the Paths list
      Then it says "No paths yet", what a path is for, and offers "New path"

    Scenario: No matches keeps the title, search and filters, with Clear filters
      Given no diagram matches "zzz" with the filter "Custom"
      When "bob" searches the Diagrams list for "zzz"
      Then the list says nothing matches and offers "Clear filters"
      And the title, the search and the chips stay

    Scenario: A list that can't load says so and offers Try again
      Given the Lessons list can't be loaded
      When "bob" opens the Lessons list
      Then it says "Couldn't load your lessons" and offers "Try again"
      And the title, the search and the filters stay
