Feature: Compose a practice session
  As a student
  I want a session built for the time I have and the instrument in my hands
  So that every minute goes to what helps me most, and I always know why

  # Rules: teacher suggestions first; then due 60%, weak 25%, new 15% of the focus time (the
  # session minus its warm-up and its application ending), the new share being a ceiling
  # balanced across the student's instruments. Due and weak take over
  # each other's unused time; whatever is still left is split 50/50 between review ahead and
  # stretch, as for a caught-up student. Weak = practised, not due, not yet fluent. Stretch reaches
  # only nodes connected to what the student is learning: path skills, their applies and part_of
  # neighbours, and nodes that build on something the student has met. Every pick carries a reason.
  # Focus (ADR-057): a session practises at most three subjects (knowledge nodes), main first, and
  # names them; due items of other nodes come in a review block of at most 20% of the focus time or
  # 5 items. New and stretch items come from each subject's current rung and the next one.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And "alice" is enrolled in a path whose skills have practice items for both instruments

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: Every item in a session carries the reason it was picked
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item in the session has one of the reasons teacher_suggested, due, weak, new, warm_up, application, review_ahead or stretch

  Scenario: Due, weak and new items share the time 60, 25 and 15
    Given "alice" has plenty of due, weak and new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 60% of the focus time goes to due items, 25% to weak items and 15% to new items

  # Parked until ADR-046 follow-up slice 5 (teacher notes): no teacher note exists yet to suggest from.
  @wip
  Scenario: A teacher's suggestion comes before everything else
    Given a teacher suggested the play-along "pentatonic-run" to "alice"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the first item after the warm-up is "pentatonic-run" with the reason teacher_suggested

  Scenario: A session with the instrument in hand starts with a warm-up on something known
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session starts with "c-major-scale" with the reason warm_up at 80 BPM

  Scenario: A session of 10 minutes or more ends by applying a skill to music
    Given "alice"'s path skill "chord-tones" has exercises and the play-along "chord-tone-riff" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the last item is a play-along with the reason application
    And it applies a skill that the session's focus items practise

  Scenario: The application ending is one play-along, outside the focus time
    When "alice" composes a 20-minute session with "guitar" in hand
    Then exactly one item has the reason application
    And the focus time is the 20 minutes less the warm-up and that play-along's estimated time

  Scenario: With no play-along on any of its subjects, Today's mix has no application ending
    Given "alice" has due items only on "diatonic-chords", "chord-tones" and "change-chords" on guitar, and none of them has a play-along
    And "alice"'s path skill "notes-on-high-strings" has the play-along "high-strings-riff" on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then no item in the session has the reason application

  Scenario: With no play-along on the instrument at all, the session has no ending and keeps the time for focus
    Given none of "alice"'s path skills has a play-along on "electric-bass"
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then no item in the session has the reason application
    And the focus time is the 10 minutes less the warm-up

  Scenario: Authored exercises on the student's path are focus items
    Given "alice"'s path skill "chord-tones" has the exercise "name-the-third" for every instrument
    And "alice" has never answered "name-the-third"
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes "name-the-third" with the reason new

  Scenario: A session under 10 minutes has no application ending
    When "alice" composes a 9-minute session with "guitar" in hand
    Then no item in the session has the reason application

  # ── Weak items and leftover time ───────────────────────────────────────────

  Scenario: An item practised, not due and not yet fluent is weak
    Given "alice" is accurate but not fluent on "pentatonic-run", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the session includes "pentatonic-run" with the reason weak

  Scenario: A fluent item that isn't due is never weak
    Given "alice" is fluent on "c-major-scale", and its review isn't due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then "c-major-scale" is not in the session with the reason weak

  Scenario: Due items take over the time weak items don't use
    Given "alice" has plenty of due items, no weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 85% of the focus time goes to due items and 15% to new items

  Scenario: Weak items take over the time due items don't use
    Given "alice" has no due items, plenty of weak items and plenty of new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then about 85% of the focus time goes to weak items and 15% to new items

  Scenario: Time left after due, weak and new goes to review ahead and stretch
    Given "alice" has 4 minutes of due items, nothing weak and 1 minute of new items on guitar, well under their shares of the focus time
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the focus time left after the due and new items is split about evenly between review_ahead and stretch items

  # ── Instruments ────────────────────────────────────────────────────────────

  Scenario: With an instrument in hand, only items that suit it are picked
    When "alice" composes a 10-minute session with "electric-bass" in hand
    Then every item in the session suits "electric-bass" or every instrument

  # In hand is for playing, in the head for recall on the screen: fretboard cells and diagram shapes
  # suit the instrument, but are only ever recalled in the head.

  Scenario: With an instrument in hand, no fretboard cell or diagram shape is picked
    Given "alice" has nothing due or weak, and 40 new fretboard cells and 20 new shapes on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then no item in the session is a fretboard cell or a diagram shape

  Scenario: An in-hand session with nothing to play is not found
    Given student "bob"'s only path skill is "find-notes-root-strings", practised by fretboard cells on guitar
    When "bob" composes a 10-minute session with "guitar" in hand
    Then the request is refused with a not-found error

  @web
  Scenario: With nothing to play in hand, a session in the head is offered instead
    Given "alice"'s session with "guitar" in hand can't be composed, since there is nothing to play
    When the session setup says there is nothing to play on guitar yet
    Then it offers a session in the head
    And choosing it composes a session with no instrument in hand

  Scenario: A session in the head picks only items that need no instrument in hand
    When "alice" composes a 5-minute session with no instrument in hand
    Then no item in the session is a play-along
    And the session may include fretboard cells of both "guitar" and "electric-bass"

  Scenario: A session in the head has no warm-up and no application ending
    When "alice" composes a 15-minute session with no instrument in hand
    Then no item in the session has the reason warm_up or application

  Scenario: A fretboard cell is asked the way it has fewer right answers
    Given "alice" has named the note of the "guitar" cell on string 6, fret 3 correctly 4 times and found it correctly once
    When the cell is picked for "alice"'s session in the head
    Then it is asked as find_the_note

  Scenario: A fretboard cell never answered right is asked to name its note
    Given "alice" has never answered the "guitar" cell on string 5, fret 7 correctly
    When the cell is picked for "alice"'s session in the head
    Then it is asked as name_the_note

  Scenario: A fretboard cell takes about 8 seconds of the session
    When "alice" composes a 5-minute session with no instrument in hand
    Then every fretboard cell in the session is estimated at 8 seconds

  # ── Fret windows ───────────────────────────────────────────────────────────
  # A fretboard drill never scrolls sideways: each drill of each layout is asked inside one window
  # of five frets the composer picks, plus the open string when it starts at the nut (frets 0–5).
  # The window holds the most of the drill's due cells, then weak, then new, nearest the nut on a
  # tie. On a new-cell turn (the student has started an odd number of sessions in the head so far)
  # a drill with new cells takes the window with the most new cells instead. Cells are frets 0 to
  # 11, so the windows are 0–5, 2–6, 3–7 and so on up to 7–11. A guitar cell nobody has answered
  # is new, and new cells are asked as name_the_note.

  Scenario: Every cell of a drill comes from one window of five frets
    Given "alice" has nothing due on guitar
    And 20 weak "guitar" cells across frets 0 to 11, to be asked as find_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the session has "guitar" cells asked as find_the_note and as name_the_note
    And every "guitar" find_the_note cell in the session carries the same fret window
    And every "guitar" name_the_note cell in the session carries the same fret window
    And every fretboard cell's fret is inside its window

  Scenario: A window at the nut includes the open string
    Given "alice" has nothing due or weak, and 40 new fretboard cells on guitar
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 0 to 5

  Scenario: The window holds the most due cells, nearest the nut on a tie
    Given "alice" has started 4 sessions in the head
    And 6 "guitar" cells due at frets 7 to 9, to be asked as name_the_note
    And 2 "guitar" cells due at frets 1 and 2, to be asked as name_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 5 to 9

  Scenario: With nothing due, the window holds the most weak cells
    Given "alice" has nothing due on guitar
    And 5 weak "guitar" cells at frets 8 to 10, to be asked as find_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" find_the_note cells carry the fret window 6 to 10

  Scenario: A due cell outside the drill's window is not picked
    Given "alice" has started 4 sessions in the head
    And 6 "guitar" cells due at frets 7 to 9 and 1 due at fret 0, all to be asked as name_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the session has no "guitar" name_the_note cell at fret 0

  Scenario: On a new-cell turn, name the note moves to the window with the most new cells
    Given "alice" has started 5 sessions in the head
    And every "guitar" cell at frets 0 to 5 has been answered, 6 of them due, to be asked as name_the_note
    And the "guitar" cells at frets 6 to 11 are new
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 6 to 10

  Scenario: On the next session, name the note goes back to the due cells
    Given "alice" has started 6 sessions in the head
    And every "guitar" cell at frets 0 to 5 has been answered, 6 of them due, to be asked as name_the_note
    And the "guitar" cells at frets 6 to 11 are new
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 0 to 5

  Scenario: On a new-cell turn, a drill with no new cells keeps its due cells
    Given "alice" has started 5 sessions in the head
    And 6 "guitar" cells due at frets 1 to 3, to be asked as find_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" find_the_note cells carry the fret window 0 to 5

  Scenario: Each drill has its own window
    Given "alice" has started 4 sessions in the head
    And 6 "guitar" cells due at frets 8 to 10, to be asked as name_the_note
    And 6 "guitar" cells due at frets 1 to 3, to be asked as find_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 6 to 10
    And the "guitar" find_the_note cells carry the fret window 0 to 5

  Scenario: In a session mixing layouts, each layout's drill has its own window
    Given "alice" has started 4 sessions in the head
    And 6 "guitar" cells due at frets 7 to 9, to be asked as name_the_note
    And 6 "electric-bass" cells due at frets 1 to 3, to be asked as name_the_note
    When "alice" composes a 10-minute session with no instrument in hand
    Then the "guitar" name_the_note cells carry the fret window 5 to 9
    And the "electric-bass" name_the_note cells carry the fret window 0 to 5

  Scenario: A session in the head picks diagram shapes of the student's instruments
    Given "alice" has new shapes of skill "map-fretboard-caged" on guitar
    When "alice" composes a 10-minute session with no instrument in hand
    Then the session may include diagram shapes linked to "guitar"
    And no diagram shape in the session is linked only to instruments "alice" doesn't play

  Scenario: A diagram shape is asked the way it has fewer right answers
    Given "alice" has named the shape "C major — CAGED A, shift 3" correctly 3 times and found its degrees correctly once
    When the shape is picked for "alice"'s session in the head
    Then it is asked as find_the_degree

  Scenario: A diagram shape never answered right is asked to name the shape
    Given "alice" has never answered the shape "C major — CAGED A, shift 3" correctly
    When the shape is picked for "alice"'s session in the head
    Then it is asked as name_the_shape

  Scenario: A diagram shape takes about 10 seconds of the session
    Given "alice" has new shapes of skill "map-fretboard-caged" on guitar
    When "alice" composes a 5-minute session with no instrument in hand
    Then every diagram shape in the session is estimated at 10 seconds

  @web
  Scenario: In a session mixing layouts, each fretboard question names its instrument
    Given "alice"'s session in the head has cells of both "guitar" and "electric-bass"
    When a fretboard cell is shown
    Then the question names the instrument whose fretboard the cell is on

  Scenario: New items are balanced across the student's instruments
    Given "alice" has 40 new items on guitar and 40 new items on electric bass
    When "alice" composes a 10-minute session with no instrument in hand
    Then the new items in the session are split evenly between guitar and electric bass

  # ── Felt questions ─────────────────────────────────────────────────────────
  # How a drill felt calibrates its fluent time, so the plan asks about the timed drills with the
  # fewest felt-rated sessions so far, across all students, two at most, fewest first.

  Scenario: The plan's felt questions go to its least-calibrated timed drills, two at most
    Given "alice"'s next session will practise "fretboard_cell:name_the_note", "fretboard_cell:find_the_note" and "exercise:text_response"
    And "fretboard_cell:find_the_note" and "exercise:text_response" have the fewest felt-rated sessions
    When "alice" composes a 10-minute session with no instrument in hand
    Then the plan asks how "fretboard_cell:find_the_note" and "exercise:text_response" felt
    And the plan doesn't ask about "fretboard_cell:name_the_note"

  Scenario: Play-alongs are never asked how they felt
    Given "alice"'s next session will practise only play-alongs
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the plan asks no felt questions

  # ── Short and shuffled ─────────────────────────────────────────────────────
  # A generated drill asks the same kind of question over and over, so a session asks at most 10 of
  # each, and its minutes are a ceiling. Equally urgent items come in random order, the drills take
  # turns, and two fretboard cells in a row are never on the same string.

  Scenario: A session asks at most 10 items of each generated drill, and may end early
    Given "alice" has nothing due or weak, and 40 new fretboard cells and 20 new shapes on guitar
    When "alice" composes a 30-minute session with no instrument in hand
    Then no drill has more than 10 items in the session
    And the session's items take less than 30 minutes

  Scenario: Authored exercises are not capped
    Given "alice" has plenty of due, weak and new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the session has more than 10 exercises of one type

  Scenario: New fretboard cells come in random order, not string by string
    Given "alice" has nothing due or weak on guitar and new fretboard cells on the E and A strings
    When "alice" composes a 10-minute session with no instrument in hand
    Then the session's fretboard cells are not in string and fret order

  Scenario: Due items are taken most overdue day first, at random within a day
    Given "alice" has 4 fretboard cells due since 3 days ago and 30 due since yesterday on guitar
    When "alice" composes a 5-minute session with no instrument in hand
    Then the 4 cells due since 3 days ago are in the session
    And its other due cells are some of those due since yesterday

  Scenario: The drills take turns
    Given "alice" has nothing due or weak, and 40 new fretboard cells and 20 new shapes on guitar
    When "alice" composes a 10-minute session with no instrument in hand
    Then no two items in a row are of the same drill while another drill has items left

  Scenario: Two fretboard cells in a row are never on the same string while another string is left
    Given "alice" has nothing due or weak on guitar and new fretboard cells on the E and A strings
    When "alice" composes a 10-minute session with no instrument in hand
    Then no two fretboard cells in a row are on the same string while a cell on another string is left

  # ── Focus: subjects and rungs ──────────────────────────────────────────────
  # A subject is one knowledge node. Today's mix takes its subjects in this order until it has
  # three: a teacher's suggestion; the nodes with the most due and weak time; the nodes its new
  # items come from, path skills first; the nodes with items coming due within the week, soonest
  # first; the stretch nodes. Only its subjects' items fill the session, so it may end short.
  # Due items of other nodes form the review block: it is filled first, from the due share, and
  # comes right after the warm-up. The application ending plays a subject, main first, or there
  # is none. A subject's current rung is the lowest rung on the ladder (know, hear, play_clean,
  # play_in_time, move, target, use) with material for the session whose items on that subject
  # are not yet accurate.

  Scenario: Today's mix practises at most three subjects and names them
    Given "alice" has due and weak items on 6 skills of their path on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the plan names at most 3 focus nodes
    And every item other than the warm-up and the review block practises one of them

  Scenario: The main subject is the node with the most due and weak time
    Given "alice" has 4 minutes of due and weak items on "diatonic-chords" and 2 minutes on "chord-tones" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the plan's first focus node is "diatonic-chords"

  Scenario: Due items of other nodes come in a review block of at most 5 items
    Given "alice" has due items on 6 skills of their path on guitar, 12 of them outside the session's focus nodes
    When "alice" composes a 30-minute session with "guitar" in hand
    Then exactly 5 items with the reason due practise none of the plan's focus nodes
    And they are the most overdue of those 12

  Scenario: The review block never takes more than a fifth of the focus time
    Given "alice" has due items outside the session's focus nodes, each estimated at 30 seconds
    When "alice" composes a 5-minute session with "guitar" in hand
    Then the due items outside the focus nodes take at most a fifth of the focus time

  Scenario: The review block comes right after the warm-up
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 100 BPM
    And "alice" has due items on 6 skills of their path on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the due items that practise none of the plan's focus nodes come right after the warm-up, before any other item

  Scenario: With few nodes due or weak, the nodes of new items complete the subjects
    Given "alice" has due items only on "chord-tones" on guitar
    And "alice"'s path skills "diatonic-chords" and "change-chords" have new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the plan's focus nodes are "chord-tones", "diatonic-chords" and "change-chords", in that order

  Scenario: A caught-up session's subjects are the nodes it reviews ahead, then those it stretches to
    Given "alice" has nothing due, weak or new on their path for guitar
    And "alice" has known items of "chord-tones" coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the plan's focus nodes are "chord-tones" and "notes-on-high-strings", in that order

  @wip
  Scenario: A student new to a subject gets new items from its first two rungs
    Given "alice" has never practised "diatonic-chords", which has items at the know, hear and play_clean rungs on guitar
    When "alice" composes a 10-minute session with "guitar" in hand and "diatonic-chords" is a focus node
    Then every new item of "diatonic-chords" in the session is at the know or hear rung

  @wip
  Scenario: Once a rung is accurate, new items climb to the next two rungs
    Given "alice" is accurate on every know item of "diatonic-chords" on guitar
    And "diatonic-chords" has items at the know, hear and play_clean rungs on guitar
    When "alice" composes a 10-minute session with "guitar" in hand and "diatonic-chords" is a focus node
    Then every new item of "diatonic-chords" in the session is at the hear or play_clean rung

  Scenario: Due items are reviewed whatever their rung
    Given "alice" is accurate on every know and hear item of "diatonic-chords" on guitar
    And 3 know items of "diatonic-chords" are due
    When "alice" composes a 10-minute session with "guitar" in hand and "diatonic-chords" is a focus node
    Then the 3 due know items are in the session with the reason due

  @wip
  Scenario: Rungs with no material for the session are skipped
    Given "alice" is accurate on every know item of "diatonic-chords" on guitar
    And "diatonic-chords" has items at the know, hear and play_clean rungs, and only its know and hear items need no instrument in hand
    When "alice" composes a 10-minute session with no instrument in hand and "diatonic-chords" is a focus node
    Then every new item of "diatonic-chords" in the session is at the hear rung

  Scenario: A subject accurate on every rung it has takes new items from its top rung
    Given "find-notes-top-strings" has items only at the know rung
    And "alice" is accurate on 80% of its cells on guitar, and 10 of them are new
    When "alice" composes a 10-minute session with no instrument in hand and "find-notes-top-strings" is a focus node
    Then the session may include new know items of "find-notes-top-strings"

  Scenario: Every item carries its rung
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item in the session carries one of the rungs know, hear, play_clean, play_in_time, move, target or use

  Scenario: Confusable progressions are asked next to each other
    Given "alice" has new heard progressions "I-V-vi-IV" and "I-vi-IV-V", and other new heard progressions
    When "alice" composes a 10-minute session with no instrument in hand and "hear-progressions" is a focus node
    Then "I-V-vi-IV" and "I-vi-IV-V" are asked with no other heard progression between them

  # ── Chords played in hand ──────────────────────────────────────────────────
  # Single chords (play clean) and minutes of changes between two chords (play in time) are focus
  # items of an in-hand session: at most 4 single chords and 2 changes, 20 and 90 seconds each. On
  # bass they are a chord's root and fifth, and changes between two roots. A change is one minute
  # at a tempo, one change on every beat; its ladder runs across sessions: the tempo of its last
  # minute, 5 BPM up after two clean minutes in a row, 5 down after a struggled one, never below
  # 20, and 40 for a change never played. Its target is the catalog's: 60 clean changes a minute.

  Scenario: An in-hand guitar session plays single chords of a path skill
    Given "alice"'s path skill "play-open-chords" has new single chords on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes single chords of "play-open-chords" with the reason new
    And every single chord in the session is at the play_clean rung

  Scenario: A single chord is planned with its chord box and name
    Given "alice"'s path skill "play-open-chords" has new single chords on guitar
    When the single chord "a-minor-open" is picked for "alice"'s session with "guitar" in hand
    Then it names the voicing diagram of "a-minor-open" and the chord "Am"

  Scenario: A chord change is planned with both chords and its minute
    Given "alice"'s path skill "change-chords" has new chord changes on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session includes a chord change of "change-chords" at the play_in_time rung
    And it names both chords' voicing diagrams and symbols, and a target of 60 clean changes a minute

  Scenario: An in-hand bass session plays a chord's root and fifth, both marked
    Given "alice"'s path skill "play-root-fifth-lines" has new root and fifth items on electric bass
    When the root and fifth of "Am" is picked for "alice"'s session with "electric-bass" in hand
    Then its root is on string 3 at fret 0 and its fifth on string 4 at fret 0 of the "electric-bass" layout

  Scenario: A session with the instrument in hand plays at most 4 single chords and 2 changes
    Given "alice" has 8 new single chords and 10 new chord changes on guitar, and nothing else
    When "alice" composes a 30-minute session with "guitar" in hand
    Then the session has at most 4 single chords and at most 2 chord changes
    And the session's items take less than 30 minutes

  Scenario: On guitar, a single chord comes before a change that uses it
    Given "alice" has the new single chord "a-minor-open" and the new chord change "a-minor-open" to "c-open" on guitar
    When both are picked for "alice"'s session with "guitar" in hand
    Then the single chord "a-minor-open" comes before the chord change

  Scenario: A single chord takes 20 seconds of the session and a change 90
    Given "alice" has new single chords and new chord changes on guitar
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every single chord in the session is estimated at 20 seconds
    And every chord change in the session is estimated at 90 seconds

  Scenario: A chord change never played starts at 40 BPM
    Given "alice" has never played the chord change "a-minor-open" to "c-open"
    When the chord change is picked as a new item
    Then its minute starts at 40 BPM, with no best clean count and no last count

  Scenario: A chord change starts at the tempo of its last minute
    Given "alice"'s last minute of "a-minor-open" to "c-open" was almost, 40 clean changes at 55 BPM
    When the chord change is picked as a due item
    Then its minute starts at 55 BPM, and its last count is 40

  Scenario: Two clean minutes in a row raise the next minute by 5 BPM
    Given "alice"'s last two minutes of "a-minor-open" to "c-open" were clean, the last at 50 BPM
    When the chord change is picked as a due item
    Then its minute starts at 55 BPM

  Scenario: A single clean minute keeps the tempo
    Given "alice"'s minutes of "a-minor-open" to "c-open" were struggled, then clean at 50 BPM
    When the chord change is picked as a due item
    Then its minute starts at 50 BPM

  Scenario: A struggled minute lowers the next minute by 5 BPM
    Given "alice"'s last minute of "a-minor-open" to "c-open" was struggled at 50 BPM
    When the chord change is picked as a due item
    Then its minute starts at 45 BPM

  Scenario: The change ladder never goes below 20 BPM
    Given "alice"'s last minute of "a-minor-open" to "c-open" was struggled at 20 BPM
    When the chord change is picked as a due item
    Then its minute starts at 20 BPM

  Scenario: A chord change carries the best clean count since the latest teacher review
    Given "alice" counted 30, then 38, then 34 clean changes of "a-minor-open" to "c-open", each minute clean
    When the chord change is picked as a due item
    Then its best clean count is 38 and its last count is 34

  Scenario: A session in the head never plays chords
    Given "alice" has new single chords and new chord changes on guitar
    When "alice" composes a 10-minute session with no instrument in hand
    Then no item in the session is a single chord, a chord change, a root and fifth or a root change

  Scenario: A chord item is never the warm-up or the application ending
    Given "alice" is fluent on every single chord of "play-open-chords" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no single chord or chord change has the reason warm_up or application

  Scenario: An in-hand session with only chords to play is composed
    Given student "bob"'s only path skill is "play-open-chords", practised by single chords on guitar
    When "bob" composes a 10-minute session with "guitar" in hand
    Then the session has at least one single chord with the reason new

  # ── Progression key tours ──────────────────────────────────────────────────
  # A progression key tour plays one progression of the progression catalog along with its
  # backing, key after key around the cycle of fourths (rung move, MOT-150). It is a focus item of
  # an in-hand session only, at most one a session, sized like a play-along over 3 takes. On
  # guitar the chart is in chord symbols, with a voicing per chord; on bass the board marks each
  # chord's root, third and fifth. A tour takes about 4 minutes, so a session shorter than about
  # 30 minutes has no room for one in its new share. The tour itself is in
  # progression-key-tour.feature.

  Scenario: An in-hand guitar session plays a progression key tour of a path skill
    Given "alice"'s path skill "common-progressions" has new progression key tours on guitar
    When "alice" composes a 30-minute session with "guitar" in hand
    Then the session includes a progression key tour of "common-progressions" with the reason new
    And the progression key tour is at the move rung

  Scenario: A session plays at most one progression key tour
    Given "alice" has 10 new progression key tours on guitar, and nothing else
    When "alice" composes a 30-minute session with "guitar" in hand
    Then the session has exactly one progression key tour

  Scenario: A progression key tour is sized like a play-along over 3 takes
    Given "alice" has never played the progression key tour of "I-V-vi-IV" on guitar
    When the progression key tour is picked for "alice"'s session with "guitar" in hand
    Then it plays 4 times through in each of at most 3 takes
    And it is estimated at 3 takes of a bar of count-in and 16 bars at 60 BPM, each followed by 10 seconds to rate it

  Scenario: A 12-bar blues tour plays the form once a take
    Given "alice" has never played the progression key tour of "12-bar-blues" on guitar
    When the progression key tour is picked for "alice"'s session with "guitar" in hand
    Then it plays 1 time through in each of at most 3 takes

  Scenario: On guitar, the tour lists each key's chart in chord symbols with a voicing per chord
    Given "alice" has never played the progression key tour of "I-V-vi-IV" on guitar
    When the progression key tour is picked for "alice"'s session with "guitar" in hand
    Then its keys are C F Bb Eb Ab Db F# B E A D G, in that order
    And the key of A has the chart "A E F#m D" and a voicing for each of its chords
    And no key has chord tones

  Scenario: On bass, the tour marks each chord's root, third and fifth
    Given "alice" has never played the progression key tour of "I-V-vi-IV" on electric bass
    When the progression key tour is picked for "alice"'s session with "electric-bass" in hand
    Then in the key of G, the chord "Em" has its root on string 4 at fret 0, its third on string 1 at fret 0 and its fifth on string 3 at fret 2
    And in the key of G, the chord "G" has its root on string 1 at fret 0, its third on string 3 at fret 2 and its fifth on string 2 at fret 0

  Scenario: A session in the head never plays a progression key tour
    Given "alice" has new progression key tours on guitar
    When "alice" composes a 10-minute session with no instrument in hand
    Then no item in the session is a progression key tour

  Scenario: A progression key tour is never the warm-up or the application ending
    Given "alice" has clean takes of the progression key tour of "I-V-vi-IV" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no progression key tour has the reason warm_up or application

  # ── Guide tones ────────────────────────────────────────────────────────────
  # A guide tone taps the third (later the seventh) of each chord of a catalog progression on the
  # screen, in time with its playback (rung target, MOT-151). Nothing is played on the instrument,
  # so it is a focus item of a session in the head only, at most one a session, sized by its 3
  # takes at the start tempo. What it asks is in guide-tones.feature.

  Scenario: A session in the head plans a guide tone of a path skill
    Given "alice"'s path skill "target-chord-tones" has new guide tones on guitar
    When "alice" composes a 20-minute session with no instrument in hand
    Then the session includes a guide tone of "target-chord-tones" with the reason new
    And the guide tone is at the target rung

  Scenario: A session plans at most one guide tone
    Given "alice" has 10 new guide tones on guitar, and nothing else
    When "alice" composes a 30-minute session with no instrument in hand
    Then the session has exactly one guide tone

  Scenario: A guide tone is sized by its 3 takes at its start tempo
    Given "alice" has never practised the guide tone of "ii-V-I" on guitar
    When the guide tone is picked for "alice"'s session with no instrument in hand
    Then it is estimated at 3 takes of a bar of count-in and 4 bars at 60 BPM, each followed by 5 seconds to see the result

  Scenario: A bass student's guide tones are on the electric-bass layout
    Given "bob" plays only "electric-bass" and has new guide tones
    When "bob" composes a 20-minute session with no instrument in hand
    Then every guide tone in the session is on the "electric-bass" layout

  Scenario: An in-hand session never plans a guide tone
    Given "alice" has new guide tones on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no item in the session is a guide tone

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The new share is a ceiling, never filled past it
    Given "alice" has 2 due items and 200 new items on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no more than 3 minutes go to new items

  Scenario: A caught-up student reviews ahead and stretches, half and half
    Given "alice" has nothing due, weak or new on their path for guitar
    And "alice" has known items coming due within the week
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 10-minute session with "guitar" in hand
    Then about half the session is items with the reason review_ahead
    And about half the session is items of "notes-on-high-strings" with the reason stretch

  Scenario: When nothing is coming due, stretch takes the whole session
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    When "alice" composes a 10-minute session with "guitar" in hand
    Then every item after the warm-up has the reason stretch

  Scenario: Stretch starts first with nodes that build on what the student has met
    Given "alice" is ready to start "notes-on-high-strings", which requires a skill they have met
    And "alice" is ready to start the concept "chord-tones", which requires nothing and a skill on their path applies
    When "alice" composes a caught-up 10-minute session with "guitar" in hand
    Then the stretch items are of "notes-on-high-strings" before "chord-tones"

  Scenario: Stretch reaches a node that a path skill is part of
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "lead-guitar", which requires nothing and a skill on their path is part of
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session has items of "lead-guitar" with the reason stretch

  Scenario: Stretch never reaches a node unconnected to what the student is learning
    Given "alice" has nothing due, weak, new or coming due on their path for guitar
    And "alice" is ready to start the skill "notes-on-high-strings", which builds on a skill they have met
    And "alice" is ready to start the skill "slide-technique", which requires nothing and has no link to their path
    When "alice" composes a 10-minute session with "guitar" in hand
    Then no item in the session is of "slide-technique"

  Scenario: A short session skips the warm-up
    When "alice" composes a 3-minute session with "guitar" in hand
    Then no item in the session has the reason warm_up

  Scenario: A play-along starts on the student's tempo ladder
    Given "alice"'s best clean tempo on "pentatonic-run" is 90 BPM and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 90 BPM with a target of 120 BPM

  Scenario: A play-along played clean past its target starts at that tempo
    Given "alice"'s best clean tempo on "pentatonic-run" is 150 BPM and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 150 BPM with a target of 120 BPM

  Scenario: A play-along starts in the note value of the best clean take
    Given "alice"'s best clean tempo on "pentatonic-run" is 50 BPM in eighths and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 50 BPM in eighths with a target of 120 BPM

  Scenario: A best clean take past the target in eighths keeps its tempo and note value
    Given "alice"'s best clean tempo on "pentatonic-run" is 80 BPM in eighths and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a due item
    Then it starts at 80 BPM in eighths with a target of 120 BPM

  Scenario: A warm-up on a play-along played clean past its target is 80% of that tempo
    Given "alice" has a clean play-along "c-major-scale" with a best clean tempo of 150 BPM and a default playback at 120 BPM
    When "alice" composes a 10-minute session with "guitar" in hand
    Then the session starts with "c-major-scale" with the reason warm_up at 120 BPM

  Scenario: A play-along with no clean take yet starts at 60% of the default playback's tempo
    Given "alice" has never rated "pentatonic-run" clean and the diagram's default playback is at 120 BPM
    When "pentatonic-run" is picked as a new item
    Then it starts at 70 BPM with a target of 120 BPM

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A session in the head always has an item for a student learning the fretboard
    Given "alice" has no practice history and their path has the skill "find-notes-root-strings"
    When "alice" composes a 5-minute session with no instrument in hand
    Then the session has at least one fretboard cell with the reason new

  Scenario: A student with nothing connected to what they're learning gets no session
    Given student "bob" is enrolled in nothing and has no practice history
    When "bob" composes a 5-minute session with no instrument in hand
    Then the request is refused with a not-found error

  Scenario: A session longer than an hour is refused
    When "alice" composes a 61-minute session with "guitar" in hand
    Then the request is rejected as invalid
    And the rejection identifies "minutes" as the source of the error

  Scenario: A session for an instrument that doesn't exist is refused
    When "alice" composes a 10-minute session with an instrument that doesn't exist in hand
    Then the request is refused with a not-found error
