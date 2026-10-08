# Song chart authoring screens (MOT-45, Phase 2): the list of song charts, starting a chart from
# ChordPro, and a chart's page where its details, rights, publication and ChordPro are managed.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser checks,
# not by any service's BDD suite. The rules behind them are in
# features/content-management/song-charts.feature and song-chart-chordpro.feature.
#
# The body of a chart is changed only by importing ChordPro here; editing lyrics and chords in
# place, and picking a voicing per chord, belong to the song chart editor that comes later. The
# screens are functional only until their design pass (MOT-73).

@web
Feature: Author song charts
  As an admin of the concierge team
  I want to bring song charts in, check them, and publish or withdraw them
  So that learners get charts whose chords and rights have been checked

  Background:
    Given "ana" is signed in as an admin
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
      And opening the song chart list shows that the page was not found

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

  # ── Starting a chart ─────────────────────────────────────────────────────────

  Rule: A chart starts from ChordPro text and a language

    Scenario: Starting a chart opens its page
      When "ana" starts a song chart in "Português (Brasil)" from ChordPro titled "Asa Branca" by "Luiz Gonzaga"
      Then the page of "Asa Branca" opens as a draft whose rights are not confirmed

    Scenario: What the import skipped is listed with its line
      When "ana" starts a song chart from ChordPro whose line 3 is "{define: G base-fret 1 frets 3 2 0 0 0 3}"
      Then the chart's page lists "{define: G base-fret 1 frets 3 2 0 0 0 3}" as skipped on line 3

    Scenario: ChordPro that can't start a chart keeps the text and says why
      When "ana" starts a song chart from ChordPro that has no title directive
      Then the start form is still open with the pasted text
      And it says the ChordPro needs a title

  # ── A chart's page ───────────────────────────────────────────────────────────

  Rule: A chart's page shows its draft and what stops it from being published

    Scenario: Chords that didn't fully resolve are listed, each saying whether it blocks publishing
      When "ana" opens the page of "Ciranda, Cirandinha"
      Then "H7" is listed as not a chord, which blocks publishing
      And "C/B" is listed as shown without its bass, which doesn't block publishing

    Scenario: The draft's details are edited without touching its lyrics
      When "ana" changes the capo of "Ciranda, Cirandinha" to fret 3 and saves
      Then the draft has a capo on fret 3
      And the draft's lyrics and chords are unchanged

    Scenario: The draft is previewed as a learner would read it
      When "ana" opens the preview from the page of "Ciranda, Cirandinha"
      Then the draft is shown as a learner would read it

  Rule: The lyrics and chords are replaced by importing ChordPro, after a confirmation

    Scenario: Importing ChordPro replaces the draft
      When "ana" imports ChordPro into "Ciranda, Cirandinha" and confirms replacing the draft
      Then the draft shows the imported lyrics
      And the details the text doesn't set keep their values

    Scenario: Cancelling the import leaves the draft as it was
      When "ana" imports ChordPro into "Ciranda, Cirandinha" and cancels
      Then the draft is unchanged

    Scenario: The draft is exported as ChordPro
      When "ana" exports "Amazing Grace" as ChordPro
      Then a file "amazing-grace.cho" is downloaded with the draft's ChordPro

  Rule: Rights are confirmed on the page, and who confirmed them is shown

    Scenario: Confirming the rights shows who confirmed them and when
      When "ana" confirms that the rights of "Ciranda, Cirandinha" were checked
      Then the page shows the rights confirmed by "ana" with the date

  # ── Publishing and withdrawing ───────────────────────────────────────────────

  Rule: Publishing makes the draft the next revision, or says what stops it

    Scenario: Publishing a draft that is ready shows its new revision
      Given the draft of "Amazing Grace" has a corrected second verse
      When "ana" publishes "Amazing Grace"
      Then the page shows "Amazing Grace" as published at revision 2

    Scenario: Publishing a draft that isn't ready lists every reason
      When "ana" publishes "Ciranda, Cirandinha"
      Then publishing is refused, saying the rights aren't confirmed and listing the chord "H7"
      And "Ciranda, Cirandinha" is still a draft

    Scenario: A withdrawn chart can be published again
      When "ana" publishes "Oh! Susanna"
      Then the page shows "Oh! Susanna" as published at revision 2

  Rule: A published chart is withdrawn with a reason, after a confirmation

    Scenario: Withdrawing a chart asks for a reason and shows it
      When "ana" withdraws "Amazing Grace" because "The rights holder asked us to"
      Then the page shows "Amazing Grace" as withdrawn by "ana" because "The rights holder asked us to"

    Scenario: A chart that isn't published offers no withdrawal
      When "ana" opens the page of "Ciranda, Cirandinha"
      Then the page offers no way to withdraw it

    Scenario: The published revisions are listed, newest first
      Given "Amazing Grace" has been published at revisions 1 and 2
      When "ana" opens the page of "Amazing Grace"
      Then the page lists revision 2 then revision 1, each with who published it and when
