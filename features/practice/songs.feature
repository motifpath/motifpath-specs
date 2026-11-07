Feature: End a session on a progression with a song built on it
  As a student
  I want a session on a progression to end with a song that plays it
  So that I use what I practised in music, not only in drills

  # A song (MOT-152, rung use; ADR-057 amendment 2026-10-21) is a published song chart whose sections
  # are tagged with the progressions they play (song-charts.feature; by section since 2026-10-24),
  # played whole on the instrument in hand and rated once, with no measure. Its key is
  # song:<layout id>:<song chart id>, on the guitar and electric-bass layouts; its nodes are the
  # nodes of every progression its sections are tagged with. A chart "tagged with" a progression
  # below has its first section tagged with it.
  # - It is only ever the application ending of an in-hand session of 10 minutes or more. The
  #   ending plays a subject, main first: when the subject takes new items from the use rung (its
  #   current rung, or the next one with material) and a song practises it, the ending is that
  #   song; otherwise it is a play-along, as before. So a session plays at most one song, last.
  # - Which song: one never rated on the layout first, then the one rated longest ago, at random
  #   among equals; the song of the student's last in-hand session only when no other fits.
  # - As written, never transposed. On bass the student plays the root of each chord.
  # - Sized at 2 minutes, then 10 seconds to rate it.
  # Repertoire statuses, keep-alive reviews and songs in challenges are MOT-76's.

  Background:
    Given student "alice" plays "guitar" and "electric-bass"
    And the published song chart "Amazing Grace" is tagged with the progression "I-IV-I-V"
    And "I-IV-I-V" rolls up to "common-progressions" in the progression catalog

  # ── Happy path ─────────────────────────────────────────────────────────────

  Scenario: A subject at the use rung ends the session with a song that plays it
    Given "alice" is accurate on every rung of "common-progressions" with material on guitar below use
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace" on guitar with the reason application
    And the song is at the use rung, for the progression "I-IV-I-V"

  Scenario: A subject whose next rung with material is use can end with a song
    Given "alice"'s current rung on "common-progressions" on guitar is "move", and "common-progressions" has no target items in hand
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace" with the reason application

  Scenario: Today's mix ends with a song of its main subject
    Given "alice"'s main subject in Today's mix is "common-progressions", at the use rung on guitar
    When "alice" composes a 20-minute session with "guitar" in hand
    Then the last item is the song "Amazing Grace" with the reason application

  Scenario: A song's nodes are its progressions' nodes
    Given the published song chart "Oh! Susanna" is tagged with the progression "I-IV-V-I"
    And "I-IV-V-I" rolls up to "common-progressions" and "cadences"
    And "alice" is at the use rung on "cadences" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "cadences"
    Then the last item is the song "Oh! Susanna"
    And "Amazing Grace", whose progression doesn't roll up to "cadences", is not in the session

  Scenario: A song is sized at 2 minutes and 10 seconds to rate it
    Given "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the song is estimated at 130 seconds, outside the focus time

  # ── Edge cases ─────────────────────────────────────────────────────────────

  Scenario: A subject below the use rung ends with a play-along, not a song
    Given "alice"'s current rung on "common-progressions" on guitar is "know", with play_in_time material next
    And "common-progressions" has the play-along "pop-progression" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is "pop-progression" with the reason application
    And no item in the session is a song

  Scenario: A chosen session with a song but no play-along has an application ending
    Given no item of "common-progressions" or its subtree is a play-along on guitar
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace" with the reason application

  Scenario: A session plays at most one song
    Given 5 published song charts are tagged with "I-IV-I-V"
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 30-minute session with "guitar" in hand, choosing "common-progressions"
    Then the session has exactly one song, and it is the last item

  Scenario: A song is never a focus item, the warm-up or in the review block
    Given "alice" rated the song "Amazing Grace" on guitar and it is due
    When "alice" composes a 20-minute session with "guitar" in hand
    Then no song in the session has a reason other than application

  Scenario: A song never rated on the layout comes before one rated before
    Given the published song chart "Oh! Susanna" is tagged with "I-IV-I-V" too
    And "alice" rated "Amazing Grace" on guitar, and never "Oh! Susanna"
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Oh! Susanna"

  Scenario: Among songs rated before, the one rated longest ago comes first
    Given the published song charts "Oh! Susanna" and "Home on the Range" are tagged with "I-IV-I-V" too
    And "alice" rated "Amazing Grace" on guitar 2 days ago, "Oh! Susanna" 9 days ago and "Home on the Range" 5 days ago
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Oh! Susanna"

  Scenario: The song of the last in-hand session is not played again while another fits
    Given the published song chart "Oh! Susanna" is tagged with "I-IV-I-V" too
    And "alice" rated "Amazing Grace" on guitar 3 days ago
    And "alice"'s last in-hand session on guitar ended with "Oh! Susanna", which "alice" left without rating it
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace"

  Scenario: The song of the last in-hand session comes back when it is the only one
    Given "alice"'s last in-hand session ended with "Amazing Grace"
    And no other published song chart plays a progression of "common-progressions"
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace"

  Scenario: On bass, the song is played as the roots of its chords
    Given "alice" is at the use rung on "common-progressions" on electric bass
    When "alice" composes a 20-minute session with "electric-bass" in hand, choosing "common-progressions"
    Then the last item is the song "Amazing Grace" on the electric-bass layout, playing its roots

  Scenario: On guitar, the song is played as its chords
    Given "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the song "Amazing Grace" on guitar plays its chords

  Scenario: The song names the section that plays the progression
    Given the published song chart "Home on the Range" has its chorus tagged with the progression "I-IV-I-V"
    And "alice" rated "Amazing Grace" on guitar 2 days ago
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then the last item is the song "Home on the Range"
    And the song names its chorus as the section that plays "I-IV-I-V"

  # ── Failure cases ──────────────────────────────────────────────────────────

  Scenario: An untagged chart is never a song in a session
    Given the published song chart "Ciranda, Cirandinha" has no progressions
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then no item in the session is the song "Ciranda, Cirandinha"

  Scenario: A withdrawn chart is no longer planned
    Given "Amazing Grace" was withdrawn after "alice" rated it on guitar
    And "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with "guitar" in hand, choosing "common-progressions"
    Then no item in the session is the song "Amazing Grace"
    And "alice" still has the evidence of the song "Amazing Grace" on guitar

  Scenario: A session in the head never plays a song
    Given "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 20-minute session with no instrument in hand, choosing "common-progressions"
    Then no item in the session is a song

  Scenario: A session under 10 minutes has no song
    Given "alice" is at the use rung on "common-progressions" on guitar
    When "alice" composes a 5-minute session with "guitar" in hand, choosing "common-progressions"
    Then no item in the session is a song

  # ── In the Practice Shell (Figma row 11) ───────────────────────────────────

  @web
  Scenario: The song shows its chart as written, with why it was picked
    Given "alice"'s session ends with the song "Amazing Grace" on guitar, for the progression "I-IV-I-V" in its verse
    When the song is shown
    Then the chart of the latest published revision is shown in its concert key, with its capo, never transposed
    And the item reads "Its verse plays I–IV–I–V, the progression you practised today"

  @web
  Scenario: On bass, the song asks for the root of each chord
    Given "alice"'s session ends with the song "Amazing Grace" on the electric-bass layout
    When the song is shown
    Then the item reads "Play the root of each chord" above the chart
    And the song's chords are shown as a chart of chord symbols, each saying the chord's quality

  @web
  Scenario: Rating the song sends the rating alone
    Given "alice" played the song "Amazing Grace" on guitar with the metronome at 70 BPM
    When "alice" rates it "almost"
    Then the practice.item_answered response is a self_rating of "almost" with no tempo, note value or key
