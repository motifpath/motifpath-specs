# Curriculum

The pedagogical area: what MotifPath teaches, in what order, and why. Read it before you plan
or build learning content: a course, a path, a lesson, an exercise or a play-along. It keeps
those decisions consistent and grounded in research and evidence, not in one person's
preferences.

The rest of this repo says what the platform does. This area says what we teach with it.

## What lives here

| File | Contents |
|---|---|
| [principles.md](principles.md) | The why: the premises every curriculum decision follows, each with its evidence |
| [plan/](plan/) | The what: learner tracks, and the courses and paths we intend to build, with their lessons |
| [tree.html](tree.html) | The plan as a browsable tree, generated from `plan/`. Never edit it by hand |

## How we plan content

1. **Start from a principle.** A new path answers a premise in `principles.md`: a first win,
   a style learners look for, a quitting point. If no premise covers it, write the premise
   first, with its evidence, or mark it *hypothesis* and name the events that will test it.
2. **Add it to `plan/` as an `idea`.** Give it a title that promises something playable,
   its level and instruments, and its `intent`: one anchor skill, 2–5 supporting skills, what
   it assumes, and the play-along that closes it.
3. **Plan its lessons and mark it `planned`.** Each lesson names the skills and concepts it
   will be classified under. The tree shows any intended skill that no lesson teaches yet.
4. **Put it in a course of a track**, as a checkpoint. A path works on its own too
   (principle 15), and a shared path can sit in every instrument's courses.
5. **Author it in the app.** A planned path maps field by field onto a learning path and its
   content nodes. Set its status to `draft`, then `published`, as the app does.
6. **Learn from the evidence.** When events confirm or refute a premise, change
   `principles.md` first, then the plan.

Every step is a pull request, so each curriculum decision is reviewed like any other spec.

## How the plan is organised

```
plan/
  tracks.yaml               what learners come to play: Fundamentos (the base), Louvor,
                            Rock nacional, and MPB, bossa e samba
  paths/shared.yaml         paths for every instrument: rhythm, ear, charts, harmony in use,
                            practice habits, playing for others
  paths/<instrument>.yaml   paths that depend on the hands and the gear
  courses/<track>.yaml      each track's courses, per instrument, mixing shared and
                            instrument paths
```

- **Write a path once.** A skill that doesn't depend on the instrument (counting, reading a
  chart, finding the key by ear) goes in a shared path. Courses on every instrument reuse it.
- **Keep paths style-neutral unless they belong to one track.** Barre chords or root–fifth
  lines serve several tracks. A bossa levada or a worship band part belongs to one.
- **Tracks keep learners in their music.** A church musician follows Louvor and never meets a
  path from another track's style. Every track starts on its instrument after Fundamentos.

## Plan format

Keys are unique across all files. Courses, paths and lessons mirror the core-domain data
model, so a planned entry can be authored field by field:

| Entity | Fields |
|---|---|
| Track | `key`, `title`, `description`, `styles`, `base` (true for the track every other one builds on) |
| Course | `key`, `track`, `title`, `language`, `level`, `instruments`, `status`, `checkpoints` (path keys, in order) |
| Path | `key`, `title`, `language`, `level`, `instruments`, `status`, `intent`, `lessons` (in order) |
| Lesson | `title`, `type` (`video` or `article`), `section` (the path item's section label), `skills` and `concepts` (its classification, at least one of each), optional `level` (defaults to the path's) |

- **`key`** is a planning handle. It is never installed; the app gives each entity its own id.
  Prefixes say where a path belongs: `sh-` shared, `ac-` violão, `el-` guitarra, `ba-` baixo.
- **`language`**: one per course or path. A translation is another course or path.
- **`level`**: `beginner`, `early_intermediate`, `intermediate`, `advanced` or `expert`.
- **`instruments`**: catalog instrument keys (`guitar`, `electric-guitar`, `electric-bass`).
  An empty list means every instrument, as for shared paths.
- **`status`**: `idea`, `planned`, `draft` or `published`. The last two are the app's.
- **Skills and concepts** are knowledge-map keys. As in the app, each must be for every
  instrument or for one of the path's instruments, so a shared path uses only nodes for
  every instrument.

`intent` holds the path's planning decisions (principles 12–15): `anchor` (its main skill),
`supporting` (2–5 more), `assumes` (skills it takes for granted at `accurate`), `ends_with`
(the skill of the play-along that closes it) and `styles` (style tags). Lessons carry the
intent out: the tree shows any intended skill that no lesson teaches yet.

## The tree

```bash
npm run curriculum:tree
```

This regenerates `tree.html` from `plan/` and the knowledge map. Commit it with the plan
change, then open it in a browser (GitHub shows its source, not the page). It has two views:

- **Plan:** instrument → track → course → path → intent and lessons, each with its status.
  Filter by instrument and track.
- **Coverage:** for each instrument, the knowledge-map skills the plan teaches, only intends,
  or doesn't reach yet, by level.

It flags, without failing:
- a skill or concept that isn't in the knowledge map, or isn't for the path's instruments
  (the same rule the app applies to content);
- a lesson without a skill or a concept;
- a path whose shape breaks principle 12, or whose intended skills no lesson teaches;
- a course checkpoint that isn't in the plan, is in another language, or isn't for the
  course's instrument;
- a skill taught before a skill it requires in the knowledge map, along the track's order
  (Fundamentos first, then the track's courses). Requirements never lock anything (ADR-043),
  but a plan should teach in order.

A flag is something to look at, not an error: it may mean the plan needs a change, or the
knowledge map does.

## Where the plan goes beyond the data model

`plan/` mirrors the app's courses, learning paths and content nodes, so planned content
can be authored as written. Some planning decisions have no field in the app yet. They live
under `intent`, and each is a question for the product:

- **`assumes`:** a path can't state the skills it takes for granted (principle 15), apart
  from its summary text.
- **`ends_with`:** a path's items are lessons only. The closing play-along (principle 12)
  can't be a path item yet.
- **`styles`:** courses and paths have no style tags. Principle 3 needs them to compare
  enrolment by style.
- **Anchor and supporting skills:** a path's skills are whatever its lessons are classified
  under. Nothing marks one as the anchor.
- **Tracks:** the app has courses, not tracks. A learner can't pick "Louvor" and be shown
  only its courses.
- **A shared path's play-along:** a play-along belongs to an instrument (its diagram), so a
  path for every instrument needs one per instrument, or ends without one.

## Related decisions

- ADR-043: skills and concepts knowledge graph
- ADR-046: evidence-based practice model (item kinds, levels, session composer)
- ADR-049: practice-first experience language
- ADR-029 and ADR-042: course catalog and paths
