# ADR-072: Progression drills ask minor progressions in minor keys

**Status:** Proposed
**Date:** 2026-11-08
**Deciders:** Gilson (Product Owner)
**Input:** MOT-187 (epic MOT-182). PO decisions, 2026-11-08: the catalog gains a few common minor
progressions; a minor key is set by `i–iv–V–i`; a minor chord with no written seventh takes the key's
own seventh; minor single-chord drills are a separate item (MOT-190); drills keep today's fixed root
names in minor keys too, and key-aware spelling for both modes is a separate item (MOT-191).
**Refines:** ADR-070 decisions 3 and 9 (the mode the drills support).
**Amends:** ADR-070 decision 8 (the catalog takes no new rows), once, for four minor rows.

---

## Context

ADR-070 lets admins create minor progressions for song charts, but core refuses to add one to the
drills (`unsupported_mode`): every progression drill assumes a major key. ADR-070 left drill support
for minor keys to MOT-187.

Four drill families ask a progression: reading its chart (`chart_progression`, both ways), hearing it
(`heard_progression`), playing it through the keys (`progression_keys`) and tapping its guide tones
(`guide_tone`). Each picks a key from the 12 major keys (`MusicKey`) and spells the chart by turning
each numeral into a chord above the key's tonic. The numeral grammar already gives minor numerals
their chords from any tonic: `i–♭VI–♭III–♭VII` above A is Am–F–C–G. The guide-tone rule for a chord
with no written seventh is a major-key rule: the major seventh on I and IV, the minor seventh
elsewhere.

Drills choose a created progression's wrong answers among drill progressions of the same length,
same mode first (ADR-070 decision 3). The catalog's 10 progressions are all major, so a first minor
progression would get only major wrong answers. After a minor key has sounded, those are easy to rule
out.

Drills spell every chord root from one fixed set of names, whatever the key: C, Db, D, Eb, E, F, F#,
G, Ab, A, Bb, B. So B major's ii shows as Dbm, not C#m.

No admin-created progression exists in production: none of MOT-182 has been released. The epic ships
in one release (PO, 2026-11-06).

## Decision

**1. Minor progressions enter the drills.** Core adds a minor progression to the drills under the same
rules as a major one: 4 or 12 bars, at least one knowledge node, at least one other drill progression
of the same length. Core no longer returns `unsupported_mode`. The value stays in the contract's enum
so that existing clients keep validating, and its description says it is no longer used.

**2. A minor progression is asked in minor keys, a major one in major keys.** `MusicKey` gains the 12
minor keys. Each is written as its tonic chord, with the drills' fixed root names: `Cm Dbm Dm Ebm Em Fm
F#m Gm Abm Am Bbm Bm`. A minor progression's chart is spelled from that tonic, with the same fixed
names as major charts. In A minor, `i–♭VII–♭VI–V` is Am–G–F–E. Apps show a minor key as its name,
"A minor" ("Lá menor"). A key tour goes through the minor keys in the major tour's order, each major
key replaced by its relative minor: `Am Dm Gm Cm Fm Bbm Ebm Abm Dbm F#m Bm Em`. The guide-tone drill
never repeats the last key, in minor keys too.

**3. The catalog gains four minor progressions.** `catalogs/progressions.yaml` takes these rows once,
each practising `common-progressions` and `minor-key-harmony`. Each lists the other three as its
confusable partners.

| Key | Bars | Name (en / pt-BR) |
|---|---|---|
| `i-bVI-bIII-bVII` | `i ♭VI ♭III ♭VII` | i–♭VI–♭III–♭VII |
| `i-bVII-bVI-V` | `i ♭VII ♭VI V` | i–♭VII–♭VI–V (Andalusian) / (andaluza) |
| `i-iv-bVII-bIII` | `i iv ♭VII ♭III` | i–iv–♭VII–♭III |
| `i-iv-v-i` | `i iv v i` | i–iv–v–i |

The catalog file gains a mode per row: a row without one is major, as all 10 rows are today. The
generator writes the four rows as a delta migration and then refuses any new key again, as ADR-070
decision 8 requires.

**4. Wrong answers keep ADR-070's ranking.** Drill progressions of the same length, same mode first,
then those that share the most chords. With the four minor rows, a 4-bar minor progression always has
three minor wrong answers. A 12-bar minor progression takes the major 12-bar blues forms as its
wrong answers until a 12-bar minor progression is in the drills.

**5. A minor chord with no written seventh takes the key's seventh.** In a minor progression,
the guide-tone drill gives a chord with no written seventh the seventh that natural minor gives it:

| Numeral | i | ii° | ♭III | iv | v | ♭VI | ♭VII |
|---|---|---|---|---|---|---|---|
| Seventh chord | m7 | ø7 | maj7 | m7 | m7 | maj7 | 7 |

Harmonic minor's `V` takes `7` and `vii°` takes `°7`. Any other numeral takes the seventh its quality
suggests: maj7 on a major chord, m7 on a minor one, ø7 on a diminished one. A written seventh still
wins, as `guide-tones.feature` says for major keys.

**6. The minor cadence is `i–iv–V–i`.** Heard-progression questions play no cadence, in either mode:
the progression sets its own key. The cadence applies to minor heard single chords, which MOT-190
adds.

## Rationale

**Minor keys as their own values.** A key value with the mode in it, such as `Am`, tells every reader
of an event (ingestion, the worker, the summary) how to spell and grade a take without looking the
progression up. *Rejected: keep the 12 tonic names and take the mode from the progression*: every
grader would need the progression's mode, and `Db` would mean D-flat major for one progression and a
theoretical D-flat minor for another.

**Fixed root names in minor too** (PO, 2026-11-08). The key's name and the chart's first chord always
agree, and minor charts follow the same rule as major ones. *Rejected: key-aware spelling now*. It
changes every chart, grader and golden case in both modes; MOT-191 does that for both modes at once.
*Rejected: naming the keys C#m and G#m while chords keep fixed names*: the key would say C#m and its
`i` chord Dbm.

**Seed the catalog** (PO, 2026-11-08). A minor drill needs minor wrong answers, which ADR-070's
ranking can only find among minor drill progressions. *Rejected: major wrong answers until admins
add minor progressions*: after a minor key, a learner rules them out by the chord quality alone.
*Rejected: only same-mode wrong answers*: then the first minor progression could never be added.
ADR-070 closed the catalog because a migration doesn't know about admins' rows: an `INSERT` that
repeats a created mode and bars aborts the deploy. That can't happen here, because no environment
with real users has created progressions. The four rows ship in the same release as the create
endpoint.

**The key's own seventh** (PO, 2026-11-08). The major rule already gives each chord its key's
seventh (maj7 on I and IV), so this rule does the same for minor keys and teaches the same thing.
*Rejected: a seventh from the chord's quality alone*: it would give `♭VII` a maj7 instead of the 7
that minor-key songs play.

**`i–iv–V–i` sets a minor key** (PO, 2026-11-08). Harmonic minor's major V has the leading tone,
which makes the tonic unmistakable. *Rejected: `i–iv–v–i`*: it sounds Aeolian, as many songs do, but
the tonic is less firmly set. *Rejected: `i–V–i`*: shorter, but without the subdominant.

## Consequences

### Positive

- Admins add minor progressions to the drills, and learners practise minor-key harmony in the same
  four drills as major.
- Every 4-bar minor progression has three minor wrong answers from day one.
- Events say the key with its mode, so graders and summaries don't need a lookup.

### Negative / Trade-offs

- `MusicKey` grows from 12 to 24 values. Core, ingestion, the worker and web must ship together; an
  older client fails to validate a minor key.
- Learners see enharmonic names in some minor keys, `Dbm` and `Eb°` (E minor's `vii°`), as they
  already do in major. MOT-191 fixes both modes.
- The catalog breaks ADR-070's closure once. A later catalog row would need the same proof that no
  environment has a created twin, which only holds before the first release of MOT-182.
- Scenarios and the dev seed that create `minor/i-bVI-bIII-bVII` move to other numerals, because the
  catalog now has those bars. A local database seeded before this change must be reset.
- A 12-bar minor progression takes major wrong answers.

### Neutral

- Item keys don't change: `i-bVI-bIII-bVII` matches the catalog key pattern.
- Minor single-chord drills (MOT-190) and key-aware spelling (MOT-191) are separate items.

## Related ADRs

- ADR-070: Admins create progressions for song charts; an in-drills flag gates what drills use.
- ADR-047: Practice reference snapshot.
- ADR-064: Practice subjects and the content version stamp.

---

*This ADR was proposed on 2026-11-08. To revise, create a new ADR with Status: Supersedes ADR-072.*
