# Progressions admins create (ADR-070). An admin creates a progression from the song chart editor's
# progression picker when a search finds nothing. It is for song charts only unless the admin adds
# it to the drills, when creating it or later from Admin › Progressions; adding is one-way. Numerals
# follow the grammar pinned by golden/progression-numerals: any root, with chords outside the mode
# marked borrowed. A progression is removed only from Admin › Progressions, and only while no
# chart's draft or latest published revision tags it. What the app shows is in
# web/progression-authoring.feature.

Feature: Admins create progressions for song charts
  As an admin of the concierge team
  I want to create the progression a song plays when the catalog doesn't have it
  So that every chart can name its progressions, and only the ones I choose reach the drills

  Background:
    Given the Core Domain Service is operational and ready to accept requests
    And "ana" is authenticated as an admin

  # ── Creating ───────────────────────────────────────────────────────────────

  Scenario: An admin creates a progression for song charts
    When "ana" creates a major progression with the bars "I", "♭VII", "IV" and "I"
    Then the progression "major/I-bVII-IV-I" exists with the bars "I", "♭VII", "IV" and "I"
    And it is not in the drills
    And its name is "I–♭VII–IV–I" in every language

  Scenario: ASCII accidentals and symbols are stored as music symbols
    When "ana" creates a minor progression with the bars "i", "bVI", "bIII" and "bVII"
    Then the progression "minor/i-bVI-bIII-bVII" has the bars "i", "♭VI", "♭III" and "♭VII"

  Scenario: A chord outside the mode is accepted and marked borrowed
    When "ana" creates a major progression with the bars "I", "iv", "I" and "V"
    Then the progression "major/I-iv-I-V" is created
    And its bar 2 is borrowed and no other bar is

  Scenario: A nickname follows the numerals in the name
    When "ana" creates a major progression with the bars "I", "♭VII", "IV" and "I" and the nicknames "Mixolydian rock" in "en" and "rock mixolídio" in "pt_BR"
    Then its name is "I–♭VII–IV–I (Mixolydian rock)" in "en" and "I–♭VII–IV–I (rock mixolídio)" in "pt_BR"

  Scenario: An admin changes a created progression's nickname
    Given "ana" has created the major progression "I-bVII-IV-I" with the nickname "Mixolydian rock" in "en"
    When "ana" changes its nickname to "Rock cadence" in "en"
    Then its name is "I–♭VII–IV–I (Rock cadence)" in "en"
    And its key is still "major/I-bVII-IV-I"

  Scenario: A created progression is listed with the catalog's
    Given "ana" has created the major progression "I-bVII-IV-I"
    When a student lists the progressions
    Then the list has the catalog's 10 progressions in the drills
    And it has "major/I-bVII-IV-I", not in the drills, with no wrong answers

  Scenario: Only an admin sees who created a progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    When "ana" lists the progression catalog
    Then "major/I-bVII-IV-I" was created by "ana"
    When a student lists the progressions
    Then "major/I-bVII-IV-I" names no creator

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: The same mode and numerals give back the existing progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    When "ana" creates a major progression with the bars "I", "bVII", "IV" and "I"
    Then the creation is refused because the progression exists
    And the refusal returns the progression "major/I-bVII-IV-I"

  Scenario: Numerals the catalog already has give back the catalog's progression
    When "ana" creates a major progression with the bars "I", "V", "vi" and "IV"
    Then the creation is refused because the progression exists
    And the refusal returns the progression "I-V-vi-IV"

  Scenario: The same numerals in the other mode are another progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    When "ana" creates a minor progression with the bars "I", "♭VII", "IV" and "I"
    Then the progression "minor/I-bVII-IV-I" is created

  Scenario: The same chords spelled differently are another progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    When "ana" creates a major progression with the bars "I", "♯VI", "IV" and "I"
    Then the progression "major/I-#VI-IV-I" is created

  Scenario: A progression may have up to sixteen bars
    When "ana" creates a major progression of 16 bars of "I"
    Then the progression is created with 16 bars

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: A bar that isn't a numeral is refused, naming the bar
    When "ana" creates a major progression with the bars "I", "V9", "IV" and "I"
    Then the creation is refused as invalid, naming bar 2
    And no progression is created

  Scenario: More than sixteen bars are refused
    When "ana" creates a major progression of 17 bars of "I"
    Then the creation is refused as invalid
    And no progression is created

  Scenario: Only admins create progressions
    Given "bob" is authenticated as a teacher
    When "bob" creates a major progression with the bars "I", "♭VII", "IV" and "I"
    Then the request is refused because only admins create progressions

  Scenario: The catalog's names can't be changed
    When "ana" changes the nickname of "I-V-vi-IV" to "Axis" in "en"
    Then the change is refused because the progression is the catalog's

  # ── Adding to the drills ───────────────────────────────────────────────────

  Scenario: An admin adds a progression to the drills as it is created
    When "ana" creates a major progression with the bars "I", "iii", "IV" and "V", in the drills, practising the concept "common-progressions"
    Then the progression "major/I-iii-IV-V" is in the drills
    And it practises the concept "common-progressions"

  Scenario: An admin adds a chart-only progression to the drills later
    Given "ana" has created the major progression "I-iii-IV-V"
    When "ana" adds it to the drills, practising the concept "common-progressions"
    Then the progression "major/I-iii-IV-V" is in the drills
    And practice offers it as a subject on the concept "common-progressions"

  Scenario: Drills offer as wrong answers the drill progressions sharing the most chords
    Given "ana" has created the major progression "I-iii-IV-V"
    When "ana" adds it to the drills, practising the concept "common-progressions"
    Then its wrong answers start with "I-vi-IV-V", which shares three bars with it
    And every one of its wrong answers has four bars

  Scenario: Drills never offer as a wrong answer a progression with the same chords
    Given "ana" has added the major progression "I-bVII-IV-V" to the drills
    And "ana" has added the major progression "I-#VI-IV-V" to the drills
    When a student lists the progressions
    Then "major/I-bVII-IV-V" doesn't list "major/I-#VI-IV-V" as a wrong answer
    And "major/I-#VI-IV-V" doesn't list "major/I-bVII-IV-V" as a wrong answer

  Scenario: The catalog's progressions keep their curated wrong answers
    Given "ana" has added the major progression "I-iii-IV-V" to the drills
    When a student lists the progressions
    Then "I-V-vi-IV" still lists "I-vi-IV-V" and "vi-IV-I-V" as its wrong answers

  Scenario: A chart-only progression is never a practice subject
    Given "ana" has created the major progression "I-bVII-IV-I"
    And a published song chart "Sweet Home" whose verse is tagged with "major/I-bVII-IV-I"
    When student "alice" starts a practice session
    Then no practice subject or song is on "major/I-bVII-IV-I"

  # Drills take 2 to 16 bars in either mode (ADR-072). When too few drill progressions share a
  # progression's length and mode, drills make up its wrong answers (drill-challenge.feature).
  Scenario: A single bar is refused, since it is a chord
    Given "ana" has created the major progression "I"
    When "ana" adds it to the drills, practising the concept "common-progressions"
    Then adding is refused because "unsupported_bar_count"
    And "major/I" is still not in the drills

  Scenario: A progression of a length no other drill progression has enters the drills
    Given "ana" has created the major progression "I-IV-V"
    When "ana" adds it to the drills, practising the concept "common-progressions"
    Then the progression "major/I-IV-V" is in the drills
    And practice offers it as a subject on the concept "common-progressions"

  Scenario: A minor progression enters the drills
    Given "ana" has created the minor progression "i-bVI-bIII-bVII"
    When "ana" adds it to the drills, practising the concept "common-progressions"
    Then the progression "minor/i-bVI-bIII-bVII" is in the drills

  Scenario: Drills never offer as a wrong answer a progression of the other mode
    Given "ana" has added the minor progression "i-bVI-bIII-bVII" to the drills
    And "ana" has added the minor progression "i-iv-v-i" to the drills
    When a student lists the progressions
    Then the wrong answers of "minor/i-iv-v-i" are only "minor/i-bVI-bIII-bVII"

  Scenario: With no drill progression of its length and mode, a progression lists no wrong answer
    Given "ana" has added the major progression "I-IV-V" to the drills
    When a student lists the progressions
    Then "major/I-IV-V" lists no wrong answer

  Scenario: Adding to the drills needs a skill or a concept
    Given "ana" has created the major progression "I-iii-IV-V"
    When "ana" adds it to the drills with no skill and no concept
    Then adding is refused as invalid

  Scenario: Creating in the drills creates nothing when it can't be added
    When "ana" creates a major progression with the bars "I", in the drills, practising the concept "common-progressions"
    Then the creation is refused because "unsupported_bar_count"
    And no progression is created

  Scenario: A drill progression can't be added again
    When "ana" adds "I-V-vi-IV" to the drills, practising the concept "common-progressions"
    Then adding is refused because "already_in_drills"

  # ── Removing ───────────────────────────────────────────────────────────────

  Scenario: An admin removes a progression no chart uses
    Given "ana" has created the major progression "I-IV-I-V-vi"
    When "ana" removes the progression "major/I-IV-I-V-vi"
    Then it is no longer listed
    And "ana" can create a major progression with the bars "I", "IV", "I", "V" and "vi" again

  Scenario: Untagging a section never removes the progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    And the verse of the draft of "Sweet Home" is tagged with "major/I-bVII-IV-I"
    When "ana" untags the verse of "Sweet Home"
    Then the progression "major/I-bVII-IV-I" is still listed

  Scenario: A progression a draft tags can't be removed, and the sections are listed
    Given "ana" has created the major progression "I-bVII-IV-I"
    And the verse and the chorus of the draft of "Sweet Home" are tagged with "major/I-bVII-IV-I"
    When "ana" removes the progression "major/I-bVII-IV-I"
    Then removing is refused because it is in use
    And the refusal lists the verse and the chorus of the draft of "Sweet Home"

  Scenario: A progression the latest published revision tags can't be removed
    Given "ana" has created the major progression "I-bVII-IV-I"
    And the latest published revision of "Sweet Home" tags its verse with "major/I-bVII-IV-I"
    And the draft of "Sweet Home" no longer tags it
    When "ana" removes the progression "major/I-bVII-IV-I"
    Then removing is refused because it is in use
    And the refusal lists the verse of the published revision of "Sweet Home"

  Scenario: Older published revisions don't stop a removal and keep the key
    Given "ana" has created the major progression "I-bVII-IV-I"
    And revision 1 of "Sweet Home" tags its verse with "major/I-bVII-IV-I"
    And revision 2, the latest, and the draft of "Sweet Home" don't tag it
    When "ana" removes the progression "major/I-bVII-IV-I"
    Then the progression is removed
    And revision 1 of "Sweet Home" still tags its verse with "major/I-bVII-IV-I"

  Scenario: A drill progression is never removed
    Given "ana" has added the major progression "I-iii-IV-V" to the drills
    When "ana" removes the progression "major/I-iii-IV-V"
    Then removing is refused because it is in the drills

  Scenario: The catalog's progressions are never removed
    When "ana" removes the progression "I-V-vi-IV"
    Then removing is refused because it is in the drills

  Scenario: An admin reads which sections tag a progression, and nothing is removed
    Given "ana" has created the major progression "I-bVII-IV-I"
    And the verse of the draft of "Sweet Home" is tagged with "major/I-bVII-IV-I"
    And the latest published revision of "Sweet Home" tags its chorus with "major/I-bVII-IV-I"
    When "ana" reads which sections tag the progression "major/I-bVII-IV-I"
    Then they are the verse of the draft and the chorus of the published revision of "Sweet Home"
    And the progression "major/I-bVII-IV-I" is still listed

  Scenario: Older published revisions aren't among the sections that tag a progression
    Given "ana" has created the major progression "I-bVII-IV-I"
    And revision 1 of "Sweet Home" tags its verse with "major/I-bVII-IV-I"
    And revision 2, the latest, and the draft of "Sweet Home" don't tag it
    When "ana" reads which sections tag the progression "major/I-bVII-IV-I"
    Then no section tags it

  Scenario: Reading the sections of a progression that doesn't exist finds nothing
    When "ana" reads which sections tag a progression that doesn't exist
    Then the progression is not found

  Scenario: Only admins read which sections tag a progression
    Given "ana" has created the major progression "I-IV-I-V-vi"
    When a teacher reads which sections tag the progression "major/I-IV-I-V-vi"
    Then reading is refused because only admins may

  Scenario: Only admins remove progressions
    Given "ana" has created the major progression "I-IV-I-V-vi"
    And "bob" is authenticated as a teacher
    When "bob" removes the progression "major/I-IV-I-V-vi"
    Then the request is refused because only admins remove progressions
