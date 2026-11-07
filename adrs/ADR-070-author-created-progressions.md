# ADR-070: Admins create progressions for song charts; an in-drills flag gates what drills use

**Status:** Accepted (2026-11-06; Figma MOT-184 signed off, specs#432 merged)
**Date:** 2026-11-04
**Deciders:** Gilson (Product Owner)
**Input:** MOT-182 (epic), MOT-183. PO direction, 2026-11-04: progressions are created from the
song chart editor's progression picker when a search finds nothing; created progressions are for
charts only until an admin promotes them to the drills; promotion ships now (MOT-188); major and
minor keys, with the numerals validated for consistency; drills support minor keys too (MOT-187). PO direction, 2026-11-05: borrowed chords are accepted
and marked, not refused; a "Use in drills" switch when creating; no confusable list and no
checklist; no retiring: a progression is removed once no chart's current revision tags it.
**Amends:** `catalogs/progressions.md` (who adds progressions, modes, bar counts),
`catalogs/reference-data.md` (the progression catalog takes no new rows).

---

## Context

A song chart's sections are tagged with the progressions they play (MOT-152). The tags come from
the progression catalog (`catalogs/progressions.yaml`): 10 progressions, major keys only, 4 or 12
bars each, installed as reference data by migration. Real songs often play progressions outside
it: 2-, 8- or 16-bar progressions, borrowed chords such as `I–♭VII–IV`, and minor keys. An admin
authoring a chart who finds nothing in the picker can only leave the section untagged. Adding a
progression takes a specs change, a generated migration and a deploy.

The same catalog is also the drill catalog. Every row of `progressions` feeds the harmony, hear,
tour and guide-tone drills, as an answer and as a distractor for its confusable partners. A drill
progression needs more than its numerals: knowledge nodes, confusable partners listed both ways, a
name that never gives a partner's answer away, and a bar count the drill families accept (4 or 12;
hear drills only 4). Today drills also assume a major key.

Since the first production install (2026-10-20), reference-data migrations are append-only, and a
catalog change ships as a delta migration written by its generator (`reference-data.md`). The
generator only sees the catalog files, never the rows users created in production.

Song charts are authored by admins only (`song-charts.feature`), so the people who would add a
progression are the same admins who decide what drills use.

## Decision

**1. Admins create progressions from the song chart picker.** We will add a create endpoint for
admins only, the same role that authors song charts. A created progression is a row of the same
`progressions` table, with an ordinary random ID (`reference-data.md`: rows created through the
API are never fixed-ID rows). It is shared: every admin sees and tags it, in every chart.

**2. An `in_drills` flag decides what drills use.** Every progression carries `in_drills`. The
catalog's rows are `true`; created rows start `false`. Drill families, the practice reference
snapshot (ADR-047), the practice subject catalog (ADR-064) and the song use rung (MOT-152) read
only `in_drills` progressions. A chart can be tagged with any progression. A chart-only
progression is never a practice subject.

**3. Adding to the drills is admin-only and one-way.** An admin adds a progression to the drills
either when creating it (a "Use in drills" switch, off by default) or later from the admin
progression list. Either way the admin gives only the knowledge nodes it practises, and core
refuses, saying why, unless all of these hold:

- at least one knowledge node, each one existing in the knowledge map;
- a bar count drill families accept (4 or 12);
- a mode the drills support: major now; minor once MOT-187 ships;
- at least one other `in_drills` progression with the same bar count, so drills have a wrong
  answer to offer.

Admins don't list confusable partners for a created progression. Drills choose its wrong answers:
the `in_drills` progressions with the same bar count that share the most chords with it, bar by
bar, those in the same mode first. The catalog's 10 progressions keep the partners listed in
`progressions.yaml`. The confusable rules of `progressions.md` hold without a check: `(mode, bars)`
uniqueness means two progressions in the drills never have the same numerals, and two names of the
same bar count can't contain each other as whole words.

Adding bumps the content version stamp (ADR-064) and refreshes the practice snapshot. There is no
way back: practice states and evidence point at a drill progression's items.

**4. Major and minor keys; any root, validated as a chord.** Every progression has a `mode`,
`major` or `minor`, and one numeral per bar. A numeral is a root, `I` to `VII` optionally preceded
by `♭` or `♯`, and a quality given by its case and suffix. Core refuses only input that isn't a
numeral by this grammar:

| Root written as | Suffixes allowed | Chord quality |
|---|---|---|
| upper case (`IV`) | none, `7`, `maj7` | major, dominant 7, major 7 |
| lower case (`ii`) | none, `7` | minor, minor 7 |
| with `°` (`vii°`) | none, `ø7`, `°7` (in place of `°`) | diminished, half-diminished 7, diminished 7 |

Every root is a fixed interval above the tonic and every quality exists in the chord catalog, so
playback and the unplayed-progression check can spell every chord in any key. A numeral outside
its mode's diatonic chords is accepted and marked *borrowed*: modal mixture (`♭VII`, `iv` in
major; `♭II` in minor), Lydian `II`, or secondary dominants written as their chord (`II7` for
V/V). The diatonic chords are:

| Mode | Diatonic |
|---|---|
| major | `I ii iii IV V vi vii°` |
| minor | `i ii° ♭III iv v ♭VI ♭VII`, plus harmonic minor's `V vii°` |

A progression has 1 to 16 bars. Input accepts `b` for `♭`, `#` for `♯`, `o` for `°` and `h` for
`ø`, and core stores the symbols.

**5. One progression per mode and numerals.** `(mode, bars)` is unique across the table. Creating
a progression whose mode and bars match an existing one is refused with that progression, so the
picker can tag it instead.

**6. A created progression's key is its numerals.** Its key is the mode and its numerals in ASCII,
for example `major/I-bVII-IV-I` or `minor/i-bVI-bIII-bVII` (`b` for `♭`, `o` for `°`, `h` for `ø`).
Catalog keys (`I-V-vi-IV`, `12-bar-blues`) have no `/`, so the two never collide. Mode, bars and
key never change after creation: a progression created with the wrong numerals is removed and
created again.

**6a. Admins remove progressions created by mistake.** Removing a progression from a song chart
only takes the tag off that section; the progression itself stays. A progression is removed only
from the admin progression list (Admin › Progressions), never from the song chart editor. There, an
admin removes a created progression that is not `in_drills`:

- **Still in use:** while any chart's draft or latest published revision tags it, core refuses
  the removal and lists those charts and sections. The admin untags them, saving the draft or
  publishing a new revision, and then removes it.
  Core also answers which sections tag a progression without removing anything, so the app shows
  them when the admin chooses Remove and never tries a removal just to find out.
- **Not in use:** it is deleted. Its mode and numerals are free to be created again.
- **Older published revisions** don't count. They never change and keep the tag's key, and a
  key that no longer matches a progression is shown as the numerals it spells
  (`major/I-bVII-IV-I` → `I–♭VII–IV–I`), without the nickname. Creating the same numerals
  again gives the same key, so those revisions link to it again.
- **In drills:** a progression added to the drills and the 10 catalog progressions are never
  removed, because practice states and evidence point at their items.

**7. Names come from the numerals.** A created progression's name is its numerals joined by `–`,
the same in every language (`i–♭VI–♭III–♭VII`). An admin can give it an optional nickname per
language, shown after the numerals in parentheses, as the catalog does (`I–V–vi–IV (pop)`), and
can change the nickname later. A name never says a key.

**8. The progression catalog takes no new rows.** The 10 progressions in `progressions.yaml` stay,
and the generator still writes updates to them, but it refuses a new key. A new drill progression
is created and promoted in production instead.

**9. Minor keys in song charts.** The unplayed-progression check spells a progression in the
chart's stated key when their modes match, and in the relative key when they don't: a minor
progression in a C major chart is spelled in A minor, and a major progression in an A minor chart
in C major. Progression playback spells minor numerals the same way. Drill support for minor keys,
including the cadence a hear drill plays first, is specified with MOT-187.

## Rationale

**Chart only unless the admin says otherwise.** A drill progression reaches every learner who
practises its node, while a chart tag only affects the chart. So creating defaults to chart only,
and putting a progression in the drills is an explicit switch that asks for its knowledge nodes.
*Rejected: created progressions go straight to the drills* (PO, 2026-11-04): an author tagging a
chart is not always deciding what to drill. *Rejected: adding to the drills only from the
progression list* (PO, 2026-11-05): an admin who already knows it belongs in the drills would
have to leave the chart to finish the job.

**Drills choose the wrong answers.** A wrong answer works when it sounds close, and progressions
of the same length that share most of their chords are the close ones, so core can rank them
without an admin. *Rejected: admins list confusable partners* (PO, 2026-11-05), which asked a
music judgement of every admin, needed a partner already in the drills in the same mode (none
exists for the first minor progression), and had to update both sides. *Rejected: a checklist of
every drill rule in the dialog*: one disabled button with the reason says the same with less to
read.

**One table with a flag.** Charts tag progressions by key, so a promoted progression keeps its
key and every chart tagged with it stays valid. *Rejected: a separate table of chart progressions*,
copied into the catalog on promotion. The picker would search two lists, and promotion would have
to re-key every chart tagged with the copy.

**The catalog closes to new rows.** A new catalog row ships as a migration written without
knowledge of production's rows. If an admin already created the same mode and bars, the
migration's `INSERT` breaks the `(mode, bars)` uniqueness and aborts the install, and the deploy
with it. *Rejected: merging on conflict* (`ON CONFLICT (mode, bars) DO UPDATE`). The migration would
silently take over an admin's row and change its key, breaking the charts tagged with it.
*Rejected: keeping both rows, without the uniqueness*: the same progression twice in the picker
and in the drills, as two subjects with separate progress.

**A grammar of roots and qualities.** Playback, the unplayed-progression check and drills must
turn every numeral into a chord in any key. A root a fixed interval above the tonic, with a
quality from the chord catalog, always can, so "consistent" means "is a chord", not "belongs to
the key". Songs borrow freely (`I–♭VII–IV`, `i–♭II`, `I–II–IV`), and a borrowed chord is a fact
about the song, not a mistake, so the dialog marks it instead of refusing it. *Rejected: free
text*, which can't be played or checked. *Rejected: diatonic numerals plus a fixed list of
borrowed ones* (the first draft of this ADR), which still refused ♭II, Lydian II and secondary
dominants (PO, 2026-11-05).

**Remove only when no current revision uses it.** Making the admin untag first keeps removal a
deliberate, visible act: nothing disappears from a chart an author is working on. Counting only
each chart's draft and latest published revision keeps that possible, because older published
revisions never change, and those still render, since the key spells the numerals. *Rejected:
retiring a progression that charts have tagged* (the first draft of this ADR; PO, 2026-11-05): it
added a third state to the list, the picker and every draft, for a rare mistake. *Rejected:
counting every revision*, which makes removal impossible once a chart has published the tag.
*Rejected: deleting and untagging every chart automatically*, which edits authors' charts behind
their backs. *Rejected: no removal at all*, which leaves mistakes in every admin's picker (PO,
2026-11-04).

**Removal lives in the progression list, not the chart.** A progression is shared by every chart
and every admin, so removing it is a catalog action, not a chart edit. In the chart editor,
removing a progression means untagging the section, which is what an author editing one chart
expects. *Rejected: a Remove action in the song chart picker*, where an author meaning to untag one
section could delete a progression other charts use (PO, 2026-11-04).

**Keys from the numerals.** A readable key in logs and item keys, and identical numerals always
give the same key, which `(mode, bars)` uniqueness already guarantees. *Rejected: a random slug*,
which hides what a tag means in logs, item keys and support questions.

## Consequences

### Positive

- An admin tags any section with what it plays, without a specs change or a deploy.
- Drills keep their curated quality: nothing reaches a learner until an admin adds it to the
  drills with its knowledge nodes, and only in a shape the drill families accept.
- Minor-key charts get the unplayed-progression check and playback.
- The drill catalog grows from progressions found in real songs.

### Negative / Trade-offs

- Promoted progressions exist only in the environment they were promoted in. Dev and staging start
  with the 10 catalog progressions; `seed-full` creates a few chart-only and promoted ones so
  development covers both.
- No edit: fixing a progression's numerals means removing it and creating it again, then
  re-tagging the sections that used it.
- Removing a progression that a published chart uses takes a new published revision of that
  chart first. Older revisions show it by its numerals, without its nickname.
- Wrong answers chosen by shared chords may be weaker than a musician's pick, for example two
  progressions that differ in one chord but sound far apart. The catalog's curated partners stay
  for the original 10.
- The grammar writes secondary dominants as their chord (`II7`, not `V/V`) and leaves out slash
  chords, suspended and extended chords. A section built on them stays untagged until the grammar
  grows.
- Adding to the drills is one-way. Taking a bad progression out of the drills needs a new decision.
- Admins now share a mutable list with drills. Adding to the drills must update the version stamp
  and the snapshot together, which adds a transactional write path that reference data never had.

### Neutral

- The `progressions` table gets an `in_drills` column and the `(mode, bars)` uniqueness, in a new
  migration; existing rows become `in_drills = true`.
- `progressions.yaml` stays the source of the original 10 progressions and their updates.
- Chart revisions keep tags by key, with no foreign key to `progressions`, so a deleted
  progression leaves older revisions intact.

## Related ADRs

- ADR-047: Practice reference snapshot — drills read progressions from it; it now holds only
  `in_drills` progressions and is refreshed on promotion.
- ADR-050: Chord library and song charts — charts and the chord catalog that spells every numeral.
- ADR-057: Drill model v2 — the drill families, rungs and confusable distractors that use
  `in_drills` progressions; created progressions get their distractors by shared chords instead
  of a curated list.
- ADR-064: Precomputed practice subject catalog — promotion bumps its content version stamp.

---

*This ADR was decided on 2026-11-04. To revise, create a new ADR with Status: Supersedes ADR-070.*
