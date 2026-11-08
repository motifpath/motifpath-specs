# ADR-072: Progression drills take any created progression, in any length and in minor keys

**Status:** Accepted
**Date:** 2026-11-08
**Deciders:** Gilson (Product Owner)
**Input:** MOT-187 (epic MOT-182). PO decisions, 2026-11-08:
- drills take any length a created progression has;
- core makes up wrong answers when the drills have too few, so the catalog takes no minor rows;
- a minor key is set by `i–iv–V–i`;
- a minor chord with no written seventh takes the key's own seventh;
- drills keep today's fixed root names in minor keys too;
- everything ships with the rest of MOT-182 in one release.

Minor single-chord drills (MOT-190) and key-aware spelling for both modes (MOT-191) are separate
items.

**Refines:** ADR-070 decisions 3 and 9: which progressions the drills take, and their wrong answers.

---

## Context

ADR-070 lets admins create progressions of 1 to 16 bars, in major or minor, for song charts. Core
adds one to the drills only when four conditions hold:

- it has 4 or 12 bars;
- it is major;
- it practises at least one knowledge node;
- the drills already have another progression of the same length.

Real songs play 2-, 8- and 16-bar progressions and minor keys, and an admin who tags them gets
nothing for the drills.

Four drill families ask a progression:

- **chart:** reading its chart, both ways (`chart_progression`);
- **hear:** hearing it (`heard_progression`, 4 bars only);
- **tour:** playing it through the keys (`progression_keys`);
- **guide tones:** tapping its guide tones (`guide_tone`).

Each family picks a key from the 12 major keys (`MusicKey`) and spells the chart by turning each
numeral into a chord above the key's tonic.

The numeral grammar already spells minor numerals from any tonic: `i–♭VI–♭III–♭VII` above A is
Am–F–C–G. The guide-tone rule for a chord with no written seventh is a major-key rule: the major
seventh on I and IV, the minor seventh elsewhere.

The bar limit comes from the wrong answers, not from music:

- a question offers the progression among wrong answers of its own length, since otherwise a learner
  could rule one out by counting bars;
- the drills take wrong answers only from other drill progressions;
- the catalog has only 4- and 12-bar progressions, all major.

So a first 8-bar or minor progression has no fitting wrong answer. The worker grades a
progression question only when every option is a known progression, by key or by its chart in the
key.

Every chord a progression can spell has a voicing in every root (a check runs on the migrated
chord catalog). So any chart drills spell can be drawn and played.

Drills spell every chord root from one fixed set of names, whatever the key: C, Db, D, Eb, E, F,
F#, G, Ab, A, Bb, B. So B major's ii shows as Dbm, not C#m.

No admin-created progression exists in production, since none of MOT-182 has been released.

## Decision

**1. Drills take any created progression of 2 to 16 bars, major or minor.** Core adds a
progression to the drills only when two conditions hold:

- it has at least 2 bars;
- it practises at least one knowledge node, each one in the knowledge map.

A 1-bar progression is a single chord, which the diatonic chord drills already ask. It is refused
with `unsupported_bar_count`.

Core no longer returns `unsupported_mode` or `no_other_drill_progression`. Both values stay in the
contract's enum so that existing clients keep validating, and their descriptions say they are no
longer used.

**2. Each family asks the lengths it can hold.**

- **Chart questions** ask any length. A chart of more than four bars is drawn as chord symbols, in
  lines of four bars, as the 12-bar blues is today.
- **Heard questions** ask a progression of 2 to 4 bars. Longer ones are never heard, for the reason
  the drill catalog gives the 12-bar forms: they are too long to hold before answering.
- **A tour take** repeats the progression as many whole times as fit in 16 bars, and at least once:
  - a 2-bar progression plays 8 times;
  - a 4-bar progression plays 4 times, as today;
  - a 12-bar progression plays once, as today.
- **Guide tones** come in every length. A progression of more than four bars is planned only once
  the student is accurate on `target-chord-tones`, as the 12-bar blues is today.

**3. A question offers four progressions up to four bars and two beyond.** That is the count today
for 4- and 12-bar questions, now set by length.

**4. Wrong answers come from the drills first, then are made up.**

- **Stored wrong answers:** when a progression enters the drills, its wrong answers are the drill
  progressions of its length and its mode. They rank by how many bars they share with it, then by
  key, and are kept to one fewer than the question offers.
- **No other mode:** a progression of the other mode is never a wrong answer. The first chord
  already tells the modes apart.
- **When a question has too few options**, core makes up the rest each time it plans the
  question:
  - **One bar changes.** A generated wrong answer is the asked progression with one bar changed.
    The new chord comes from the chords the progression already plays, so the option keeps its
    style: a blues stays in dominant sevenths.
  - **Fallback chords.** When those give too few, the bar takes a triad of the mode instead:
    `I ii iii IV V vi vii°` in major, `i ii° ♭III iv v ♭VI ♭VII` in minor.
  - **Never a twin.** A generated wrong answer's chart is never the answer's, another option's,
    or any drill progression's.
  - **How the bar is chosen.** The changed bar and its chord are picked at random. A learner meets
    new wrong answers instead of learning the four by heart.
- **What clients see.** A generated wrong answer is shown and sent back as the progression it would
  be if an admin created it:
  - its key is its mode and numerals (`major/I-ii-IV-V`, as ADR-070 decision 6 builds keys);
  - its name is its numerals ("I – ii – IV – V");
  - in numbers to chart, its option is its chart in the question's key.
- **No practice item.** A generated progression is never a practice item and never asked
  next to its progression in a session.

**5. The worker grades a progression question against its length and mode.** An option counts as a
possible answer when either holds:

- it is a known progression of the asked length;
- it is a well-formed generated one: a progression key, or a chart in the question's key, of the
  asked length and mode.

In both cases the options are different from one another and the right one is among them. The
right answer is still worked out from the progression the item asks.

**6. A minor progression is asked in minor keys, a major one in major keys.**

- **New key values.** `MusicKey` gains the 12 minor keys. Each is written as its tonic chord, with
  the drills' fixed root names: `Cm Dbm Dm Ebm Em Fm F#m Gm Abm Am Bbm Bm`.
- **Spelling.** A minor progression's chart is spelled from that tonic, with the same fixed names as
  major charts. In A minor, `i–♭VII–♭VI–V` is Am–G–F–E.
- **Display.** Apps show a minor key as its name, "A minor" ("Lá menor").
- **Tours.** A key tour goes through the minor keys in the major tour's order, each major key
  replaced by its relative minor: `Am Dm Gm Cm Fm Bbm Ebm Abm Dbm F#m Bm Em`.
- **Guide tones.** The guide-tone drill never repeats the last key, in minor keys too.

**7. A minor chord with no written seventh takes the key's seventh.** In a minor progression, the
guide-tone drill gives a chord with no written seventh the seventh that natural minor gives it:

| Numeral | i | ii° | ♭III | iv | v | ♭VI | ♭VII |
|---|---|---|---|---|---|---|---|
| Seventh chord | m7 | ø7 | maj7 | m7 | m7 | maj7 | 7 |

Harmonic minor's `V` takes `7` and `vii°` takes `°7`.

Any other numeral takes the seventh its quality suggests:

- maj7 on a major chord;
- m7 on a minor chord;
- ø7 on a diminished chord.

A written seventh still wins, as `guide-tones.feature` says for major keys.

**8. The minor cadence is `i–iv–V–i`.** Heard progression questions play no cadence, in either mode,
because the progression sets its own key. The cadence applies to minor heard single chords, which
MOT-190 adds.

## Rationale

**Make up wrong answers instead of needing other progressions** (PO, 2026-11-08):

- With them, a progression's length and mode stop being a gate, and the drills take whatever
  admins tag.
- A changed bar is the closest a wrong answer can be. The catalog already picks its confusable
  partners this way, for example "12-bar blues, slow change" next to "quick change".
- Since every chord has a voicing, a made-up chart can always be drawn and heard.

Two alternatives were rejected:

- *Store made-up wrong answers when a progression enters the drills.* Their keys would point at
  progressions that don't exist, every reader would have to tell them from real ones, and a
  learner would meet the same three every time.
- *Wrong answers built from random chords.* A chart with chords from outside its style, such as a
  triad among dominant sevenths, is ruled out at a glance.

**Never another mode as a wrong answer.** Once a key has sounded, or a chart shows its first chord,
a progression of the other mode is ruled out by chord quality alone. A made-up wrong answer in the
right mode is always the better option.

**No minor catalog rows** (PO, 2026-11-08). Minor rows would only have given minor progressions
minor wrong answers, and made-up ones do that. ADR-070 decision 8 keeps the catalog closed, so no
migration can collide with an admin's progression, and no scenario has to move.

**Show a made-up wrong answer as the progression it would be:**

- clients already show a progression option by its name, and the key and name follow ADR-070's
  rules, so no new value format enters the contract;
- answers stored with a generated key read like any other.

One alternative was rejected: *a separate field marking an option as made up*. Clients have no use
for it, and the worker can recognise one without it.

**Four options up to four bars, two beyond.** That's the count today: four for 4-bar questions, two
for the 12-bar forms. Comparing four 16-bar charts on a phone takes longer than the drill's time.

**Minor keys as their own values.** A key value with the mode in it, such as `Am`, tells every
reader of an event how to spell and grade a take without looking the progression up: ingestion,
the worker and the summary. Two alternatives were rejected:

- *Keep the 12 tonic names and take the mode from the progression.* Every grader would need the
  progression's mode, and `Db` would mean D-flat major for one progression and a theoretical D-flat
  minor for another.
- *Name the keys C#m and G#m while chords keep fixed names.* The key would say C#m and its `i`
  chord Dbm.

**Fixed root names in minor too** (PO, 2026-11-08). The key's name and the chart's first chord
always agree, and minor charts follow the same rule as major ones.

One alternative was rejected: *key-aware spelling now*. It changes every chart, grader and expected
answer in both modes. MOT-191 does that for both modes at once.

**The key's own seventh** (PO, 2026-11-08). The major rule already gives each chord its key's
seventh (maj7 on I and IV), and this rule does the same for minor keys.

One alternative was rejected: *a seventh from the chord's quality alone*. It would give `♭VII` a
maj7 instead of the 7 that minor-key songs play.

**`i–iv–V–i` sets a minor key** (PO, 2026-11-08). Harmonic minor's major V has the leading tone,
which makes the tonic unmistakable. Two alternatives were rejected:

- *`i–iv–v–i`*: it sounds Aeolian, as many songs do, but the tonic is less firmly set.
- *`i–V–i`*: shorter, but without the subdominant.

## Consequences

### Positive

- Admins add any progression they tag to the drills, of 2 to 16 bars, major or minor.
- Learners practise minor-key harmony in the same four drills as major.
- Every question has its full set of wrong answers, and the wrong answers change from one time to
  the next.
- The catalog stays closed: no migration and no scenario move.
- Events say the key with its mode, so graders and summaries don't need a lookup.

### Negative / Trade-offs

- The worker no longer checks a progression question's wrong answers against known progressions,
  only their shape: length, mode, and numerals or chords that parse. A client could send made-up
  options a server never offered. It still can't make a wrong pick count as right.
- `MusicKey` grows from 12 to 24 values. Core, ingestion, the worker and web must ship together,
  because an older client fails to validate a minor key.
- Core and the worker both decide the length rules and what a well-formed generated wrong answer
  is. Shared scenarios and the worker's expected answers keep the two in step.
- Learners see enharmonic names in some minor keys, as they already do in major: `Dbm`, or `Eb°`
  for E minor's `vii°`. MOT-191 fixes both modes.
- Stored wrong answers of an 8-bar progression added before another 8-bar one stay as they were.
  Made-up ones fill its options until an admin adds the other.

### Neutral

- Drill progressions of today keep their wrong answers, all major and of their own length.
- Web's admin dialog stops warning about length and mode, and refuses only a 1-bar progression.
- Minor single-chord drills (MOT-190) and key-aware spelling (MOT-191) are separate items.

## Related ADRs

- ADR-070: Admins create progressions for song charts; an in-drills flag gates what drills use.
- ADR-047: Practice reference snapshot.
- ADR-064: Practice subjects and the content version stamp.

---

*This ADR was decided on 2026-11-08. To revise, create a new ADR with Status: Supersedes ADR-072.*
