# A chord stays a chord box where its notes are answers, and where it is an option
# (MOT-95; Figma "Authoring" row 16, approved 2026-10-11; design/patterns/diagrams.md, Chords).
#
# A diagram with chord data (a chord voicing's) is a chord and shows as its chord box. The author
# marks its answers and hides its notes on the box with the same tool as on the fretboard; the
# student answers on the box; an image-choice option that is a chord is its box. What an answer
# means, and how it is graded, is unchanged: these scenarios only say where it is given and shown.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks, not
# by any service's BDD suite. Hidden positions and answer cells are ADR-040; grading is in
# features/practice.

@web
Feature: Answer and choose chords on their chord box
  As a teacher building chord exercises, and a student answering them
  I want a chord's notes marked and answered on its chord box, and chord options shown as boxes
  So that a chord looks the same to the author and the student, the way guitarists read chords

  Background:
    Given the chord catalog has "Am" with an open voicing: string 5 open, string 4 at fret 2 with finger 2, string 3 at fret 2 with finger 3, string 2 at fret 1 with finger 1, string 1 open, string 6 muted
    And "bia" is signed in as a teacher

  # ── Authoring an image-recognition stimulus ──────────────────────────────────

  Rule: The author marks a chord's answers and hides its notes on its chord box

    Scenario: A chord stimulus is edited on its chord box
      Given "bia" has picked the open voicing of "Am" as an image-recognition stimulus
      Then the stimulus shows as the chord box of "Am", with Box | Neck
      And the tool offers Mark correct and Hide or show

    Scenario: Tapping a note with Mark correct makes it an answer
      Given "bia" is editing the "Am" stimulus with Mark correct
      When "bia" taps the note on string 4 at fret 2
      Then that note is marked as an answer
      And the exercise has 1 correct position

    Scenario: Tapping a note with Hide or show hides it, faded so it can be shown again
      Given "bia" is editing the "Am" stimulus with Hide or show
      When "bia" taps the note on string 3 at fret 2
      Then that note is hidden from the student
      And the author still sees it, faded
      When "bia" taps it again
      Then it is shown to the student again

    Scenario: A hidden note can be an answer
      Given "bia" has hidden the notes on strings 4 and 3 at fret 2 and marked both as answers
      Then both show as hidden answers on the box

    Scenario: Marks made on the box are on the neck too
      Given "bia" has marked the note on string 4 at fret 2 as an answer on the box
      When "bia" switches to Neck
      Then the same position is marked as an answer on the fretboard

  # ── Answering on the box ─────────────────────────────────────────────────────

  Rule: The student answers on the chord box

    Background:
      Given an image-recognition exercise whose stimulus is the open voicing of "Am"
      And its answers are the hidden notes on strings 4 and 3 at fret 2

    Scenario: The box leaves its hidden notes out and takes taps on its cells
      When the student opens the exercise
      Then the chord box of "Am" shows the note on string 2 at fret 1 and the open and muted strings
      And the notes on strings 4 and 3 at fret 2 are not shown
      And every cell of the box, the open strings above the nut included, can be tapped

    Scenario: A tap marks a pick and a second tap takes it back
      Given the student has opened the exercise
      When the student taps string 4 at fret 2
      Then that cell shows as picked
      When the student taps it again
      Then it is no longer picked

    Scenario: Check grades the picks on the box
      Given the student has picked string 4 at fret 2 and string 3 at fret 3
      When the student checks the answer
      Then string 4 at fret 2 shows as right
      And string 3 at fret 3 shows as wrong
      And string 3 at fret 2 shows as a right cell that was not picked
      And the answer is not quite right

    Scenario: The box's places are big enough to tap on a phone
      Given a 360 px wide screen
      When the student opens the exercise
      Then every place on the box is at least 48 px wide and 48 px tall

    Scenario: A chord that can't be loaded says so in place, never as a wrong answer
      Given the stimulus's chord fails to load
      When the student opens the exercise
      Then the exercise says the diagram can't be shown right now, in place
      And nothing is graded as wrong

  # ── Chords as options ────────────────────────────────────────────────────────

  Rule: An option that is a chord shows as its chord box

    Scenario: The author's option tiles show a chord as its box
      Given "bia" is editing an image-choice exercise
      When "bia" picks the open voicing of "Am" as an option and inserts it
      Then the option tile shows the chord box of "Am", not the fretboard

    Scenario: The student's options show chords as boxes
      Given an image-choice exercise whose options are the open voicings of "Am", "C", "G" and "Em"
      When the student opens the exercise
      Then each option shows as its chord box
      And no option offers Box | Neck

    Scenario: An option that is not a chord stays on the fretboard
      Given an image-choice exercise with a scale diagram among its options
      When the student opens the exercise
      Then that option shows on the fretboard
