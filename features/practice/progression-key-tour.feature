Feature: Play a progression in every key
  As a student
  I want a progression I play along with to move to the next key after each clean take
  So that I learn it by number, in every key, not by one fingering

  # A progression key tour (MOT-150, rung move) plays one progression of the progression catalog,
  # key after key around the cycle of fourths from C: C F Bb Eb Ab Db F# B E A D G. The tour keeps
  # one tempo per item: keys first, then tempo.
  # - A key is clean when a take in it is rated clean at an effective speed at or above the tour
  #   tempo.
  # - After a clean take, the next take is in the next key of the cycle not yet clean, at the same
  #   tempo. After an almost or a struggle, it stays in the key; a struggle lowers the tour tempo
  #   by 5 BPM, never below 60% of the target, and keys already clean stay clean.
  # - When all 12 keys are clean, the tour starts again at C, 5 BPM faster, never past the target
  #   by itself, with no key clean.
  # - The target is 100 BPM in quarters for every progression. A tour never played starts at C at
  #   60 BPM.
  # The plan carries the whole tour, so the client moves on between takes of a session (@web), and
  # the next session's plan starts where the last take left the tour.

  Background:
    Given student "alice" plays "guitar"
    And "alice" practises the progression key tour of "I-V-vi-IV" on guitar

  # ── The tour across sessions ───────────────────────────────────────────────

  @wip
  Scenario: A tour never played starts at C at 60 BPM in quarters
    Given "alice" has never played the tour
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 60 BPM in quarters, with a target of 100 BPM
    And no key of the tour is clean

  @wip
  Scenario: The next session starts at the first key not yet clean
    Given "alice" rated takes of the tour clean in C and in F at 60 BPM
    When the tour is picked for "alice"'s session
    Then it starts in Bb at a tour tempo of 60 BPM
    And the keys C and F are clean

  @wip
  Scenario: A clean take slower than the tour tempo doesn't make its key clean
    Given the tour's tempo is 70 BPM
    And "alice" rated a take of the tour clean in C at 65 BPM
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 70 BPM
    And no key of the tour is clean

  @wip
  Scenario: A clean take faster than the tour tempo makes its key clean
    Given the tour's tempo is 70 BPM
    And "alice" rated a take of the tour clean in C at 80 BPM
    When the tour is picked for "alice"'s session
    Then it starts in F at a tour tempo of 70 BPM

  @wip
  Scenario: A clean take in eighths counts at its effective speed
    Given the tour's tempo is 70 BPM
    And "alice" rated a take of the tour clean in C at 40 BPM in eighths
    When the tour is picked for "alice"'s session
    Then it starts in F at a tour tempo of 70 BPM

  @wip
  Scenario: A struggled take lowers the tour tempo by 5 BPM and keeps the clean keys
    Given "alice" rated takes of the tour clean in C and in F at 70 BPM
    And "alice" rated a take of the tour struggled in Bb at 70 BPM
    When the tour is picked for "alice"'s session
    Then it starts in Bb at a tour tempo of 65 BPM
    And the keys C and F are clean

  @wip
  Scenario: An almost take keeps the key and the tempo
    Given "alice" rated a take of the tour almost in C at 70 BPM
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 70 BPM

  @wip
  Scenario: A struggle never lowers the tour below 60% of the target
    Given the tour's tempo is 60 BPM
    And "alice" rated a take of the tour struggled in C at 60 BPM
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 60 BPM

  @wip
  Scenario: When every key is clean, the tour starts again at C, 5 BPM faster
    Given "alice" rated takes of the tour clean in all 12 keys at 70 BPM
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 75 BPM
    And no key of the tour is clean

  @wip
  Scenario: A finished tour never climbs past the target by itself
    Given "alice" rated takes of the tour clean in all 12 keys at 100 BPM
    When the tour is picked for "alice"'s session
    Then it starts in C at a tour tempo of 100 BPM

  @wip
  Scenario: The tour starts in the note value of the last clean take
    Given "alice" rated a take of the tour clean in C at 40 BPM in eighths
    When the tour is picked for "alice"'s session
    Then its start note value is eighths

  # ── Within a session ───────────────────────────────────────────────────────

  @web
  Scenario: A clean take moves the next take to the next key at the same tempo
    Given "alice"'s session plans the tour starting in D at 80 BPM, with C, F, Bb, Eb, Ab, Db, F#, B, E and A clean
    When "alice" rates the take in D "clean" at 80 BPM
    Then the next take is in G at 80 BPM

  @web
  Scenario: The next key skips the keys already clean
    Given "alice"'s session plans the tour starting in C at 60 BPM, with F and Bb clean
    When "alice" rates the take in C "clean" at 60 BPM
    Then the next take is in Eb at 60 BPM

  @web
  Scenario: An almost take stays in the key at the same tempo
    Given "alice"'s session plans the tour starting in C at 60 BPM
    When "alice" rates the take in C "almost" at 60 BPM
    Then the next take is in C at 60 BPM

  @web
  Scenario: A struggled take stays in the key, 5 BPM slower
    Given "alice"'s session plans the tour starting in C at 70 BPM
    When "alice" rates the take in C "struggled" at 70 BPM
    Then the next take is in C at 65 BPM

  @web
  Scenario: A clean take below the tour tempo stays in the key
    Given "alice"'s session plans the tour starting in C at 70 BPM
    And "alice" chooses 60 BPM for the take
    When "alice" rates the take in C "clean" at 60 BPM
    Then the next take is in C at 70 BPM

  @web
  Scenario: The last key made clean starts the tour again at C, 5 BPM faster
    Given "alice"'s session plans the tour starting in G at 70 BPM, with every other key clean
    When "alice" rates the take in G "clean" at 70 BPM
    Then the next take is in C at 75 BPM
    And no key of the tour is shown clean

  @web
  Scenario: The session stops the tour after its planned takes
    Given "alice"'s session plans the tour with 3 takes
    When "alice" rates 3 takes of the tour
    Then the session moves on to its next item
