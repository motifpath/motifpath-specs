# Song chart authoring (MOT-45, Phase 2): the list of song charts, and one editor for starting
# and changing a chart, where ChordPro can be imported, lyrics and chords edited in place, a
# voicing picked per chord, and the chart's rights, publication and revisions managed.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite. The rules behind them are in
# features/content-management/song-charts.feature and song-chart-chordpro.feature.
#
# ChordPro is read by the server; the editor loads what it describes and nothing is saved until
# the author saves. Chord symbols are read in the editor the same way the server reads them
# (golden/chord-symbols), and the catalog is asked for each chord's voicings. The screens are
# functional only until their design pass (MOT-73).

@web
Feature: Author song charts
  As an admin of the concierge team
  I want one editor to bring charts in, fix their lyrics and chords, and publish them
  So that learners get charts whose chords and rights have been checked

  Background:
    Given "ana" is signed in as an admin
    And the chord catalog has "G", "C", "D" and "Em", each with voicings
    And the song charts are:
      | title               | artist         | status    | revision |
      | Amazing Grace       | John Newton    | published | 1        |
      | Oh! Susanna         | Stephen Foster | withdrawn | 1        |
      | Ciranda, Cirandinha | Tradicional    | draft     |          |

  # ── Access ───────────────────────────────────────────────────────────────────

  Rule: Only admins reach song charts

    Scenario: An admin sees the Song charts section
      Then the navigation offers "Song charts"

    Scenario Outline: Other roles neither see nor open song charts
      Given the signed-in user is a <role>
      Then the navigation does not offer "Song charts"
      And opening the song chart list sends the user away like any other role-gated page

      Examples:
        | role    |
        | teacher |
        | student |

  # ── The list ─────────────────────────────────────────────────────────────────

  Rule: The list shows every chart with its status

    Scenario: Every chart is listed with its artist and status
      When "ana" opens the song chart list
      Then the list shows "Amazing Grace" as published at revision 1, "Oh! Susanna" as withdrawn and "Ciranda, Cirandinha" as a draft

    Scenario: The list can show only the charts in one status
      When "ana" shows only the published song charts
      Then the list shows "Amazing Grace" only

    Scenario: The list can be searched by title or artist
      When "ana" searches the song charts for "foster"
      Then the list shows "Oh! Susanna" only

    Scenario: A search with no match says so
      When "ana" searches the song charts for "beethoven"
      Then the list says no song chart matches

  # ── Starting and saving ──────────────────────────────────────────────────────

  Rule: A new chart starts as an empty editor and exists once it is saved

    Scenario: A new chart is saved as a draft
      Given "ana" starts a new song chart
      When "ana" writes the title "Asa Branca", the artist "Luiz Gonzaga", the language "Português (Brasil)" and the line "[G]Quando olhei a terra ardendo"
      And "ana" saves
      Then "Asa Branca" is saved as a draft whose rights are not confirmed
      And the editor now edits "Asa Branca"

    Scenario: A chart can't be saved without its title, artist, language and a lyric line
      Given "ana" starts a new song chart
      When "ana" saves
      Then nothing is saved
      And the title, the artist, the language and the lyrics are each marked as needed

    Scenario: Leaving with unsaved changes asks first
      Given "ana" has changed the lyrics of "Ciranda, Cirandinha" without saving
      When "ana" goes back to the list
      Then "ana" is asked whether to discard the changes

  # ── Importing and exporting ChordPro ─────────────────────────────────────────

  Rule: Importing ChordPro fills the editor, and only saving keeps it

    Scenario: Importing fills the lyrics and the details the text sets
      Given "ana" starts a new song chart
      When "ana" imports ChordPro titled "Asa Branca" by "Luiz Gonzaga" with a capo on fret 2
      Then the editor holds the imported lyrics with their chords
      And the title is "Asa Branca", the artist "Luiz Gonzaga" and the capo fret 2
      And nothing is saved yet

    Scenario: Details the text doesn't set keep what the author wrote
      Given "ana" starts a new song chart and writes the artist "Luiz Gonzaga"
      When "ana" imports ChordPro that has no artist directive
      Then the artist is still "Luiz Gonzaga"

    Scenario: What the import skipped is listed with its line
      When "ana" imports ChordPro whose line 3 is "{define: G base-fret 1 frets 3 2 0 0 0 3}"
      Then the editor lists "{define: G base-fret 1 frets 3 2 0 0 0 3}" as skipped on line 3

    Scenario: Importing over lyrics already in the editor asks first
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" imports ChordPro
      Then "ana" is asked whether to replace the lyrics in the editor

    Scenario: The draft is exported as ChordPro
      When "ana" exports "Amazing Grace" as ChordPro
      Then a file "amazing-grace.cho" is downloaded with the draft's ChordPro

  # ── Editing lyrics and chords ────────────────────────────────────────────────

  Rule: Lyrics, sections and comments are edited in place

    Scenario: A section is added with its kind and label
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" adds a chorus section labelled "Refrão" after the verse
      Then the chart has a verse and then a chorus labelled "Refrão"

    Scenario: A comment line is added to a section
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" adds the comment "Mais devagar" at the start of the verse
      Then the verse starts with the comment "Mais devagar"

  Rule: A chord is put on a word or syllable, and checked as it is written

    Scenario: A chord is added on a selected word
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" selects "vamos" and writes the chord "D"
      Then "D" is shown over "vamos"

    Scenario: A chord on part of a word sits on that syllable
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" selects "dinha" in "cirandinha" and writes the chord "Em"
      Then "Em" is shown over "dinha"

    Scenario: A symbol that isn't a chord is marked as it is written
      When "ana" writes the chord "H7" on a word
      Then the chord "H7" is marked as not a chord, which blocks publishing

    Scenario: A chord the catalog doesn't have is marked
      When "ana" writes the chord "C#7" on a word
      Then the chord "C#7" is marked as not in the chord catalog, which blocks publishing

    Scenario: A no-chord marking is not marked
      When "ana" writes the chord "N.C." on a word
      Then the chord "N.C." is not marked

    Scenario: A chord is changed or removed
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" changes the chord on "Ciranda" to "D" and removes the chord on "todos"
      Then "D" is shown over "Ciranda" and no chord over "todos"

  Rule: A voicing is picked per chord from the catalog's voicings

    Scenario: Without a pick, the chord uses its best voicing
      When "ana" writes the chord "G" on a word
      Then the chord "G" shows that learners will see its best voicing first

    Scenario: The author picks a voicing for a chord
      Given "ana" has written the chord "G" on a word
      When "ana" opens the chord's voicings and picks the second one
      Then learners will see that voicing first for that chord

  # ── Rights, publishing and withdrawing ───────────────────────────────────────

  Rule: Rights are confirmed in the editor, and who confirmed them is shown

    Scenario: Confirming the rights shows who confirmed them and when
      Given "ana" opens "Ciranda, Cirandinha" in the editor
      When "ana" confirms that the rights were checked and saves
      Then the editor shows the rights confirmed by "ana" with the date

  Rule: Publishing makes the saved draft the next revision, or says what stops it

    Scenario: Publishing a draft that is ready shows its new revision
      Given the draft of "Amazing Grace" has a corrected second verse
      When "ana" publishes "Amazing Grace"
      Then the editor shows "Amazing Grace" as published at revision 2

    Scenario: Unsaved changes are saved before publishing
      Given "ana" has changed the lyrics of "Amazing Grace" without saving
      When "ana" publishes "Amazing Grace"
      Then the changes are saved and then published

    Scenario: Publishing a draft that isn't ready lists every reason
      Given the draft of "Ciranda, Cirandinha" has the chord "H7" and its rights aren't confirmed
      When "ana" publishes "Ciranda, Cirandinha"
      Then publishing is refused, saying the rights aren't confirmed and listing the chord "H7"
      And "Ciranda, Cirandinha" is still a draft

    Scenario: A withdrawn chart can be published again
      When "ana" publishes "Oh! Susanna"
      Then the editor shows "Oh! Susanna" as published at revision 2

    Scenario: The draft is previewed as a learner would read it
      When "ana" opens the preview from the editor of "Ciranda, Cirandinha"
      Then the saved draft is shown as a learner would read it

  Rule: A published chart is withdrawn with a reason, after a confirmation

    Scenario: Withdrawing a chart asks for a reason and shows it
      When "ana" withdraws "Amazing Grace" because "The rights holder asked us to"
      Then the editor shows "Amazing Grace" as withdrawn by "ana" because "The rights holder asked us to"

    Scenario: A chart that isn't published offers no withdrawal
      When "ana" opens "Ciranda, Cirandinha" in the editor
      Then the editor offers no way to withdraw it

    Scenario: The published revisions are listed, newest first
      Given "Amazing Grace" has been published at revisions 1 and 2
      When "ana" opens "Amazing Grace" in the editor
      Then the editor lists revision 2 then revision 1, each with who published it and when
