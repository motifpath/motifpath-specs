# PR Review — Changelog

## [1.5.2] — 2026-10-05

### Fixed
- `profiles/motifpath-specs.md`: the exact event names no longer include the retired
  `exercise.answer_sent`, and now list the four `practice.*` events (specs#181).
- `SKILL.md` version brought in line with `plugin.json`; it had stayed at 1.4.1.

## [1.5.1] — 2026-10-04

### Fixed
- `profiles/motifpath-specs.md`: PromptFoo is no longer listed as an automatic CI gate or a test
  layer. It was never wired up (no prompts, no config, and its CI trigger read a field GitHub
  doesn't provide) and was removed from the repo; the golden-case validation job is listed instead.

## [1.5.0] — 2026-10-02

### Changed
- `HEURISTICS.md` item 7 (absence) now asks whether "empty" means "not set yet" or a deliberate
  value, and whether code that fills in a default tells the two apart. From the motifpath-web#75
  review: picking a diagram filled in its instruments over an exercise saved for every instrument.
- `HEURISTICS.md` item 13 (same rule, two sides) now asks whether both sides get the same inputs.
  From the same review: the challenge picker applied the server's fit rule to the lesson's unsaved
  instruments, while the server checked the saved lesson.

## [1.4.1] — 2026-09-30

### Fixed
- `profiles/motifpath-specs.md` Delivery: spec, ADR and chore branches are cut from and target
  `main`, because motifpath-specs has no `dev` branch. The profile had said they target `dev`,
  which would have turned every correctly targeted spec PR into a false finding. Found during the
  specs#147 review.

## [1.4.0] — 2026-09-29

### Added
- New Axis A / item 23 in `HEURISTICS.md`: flags state that points into a collection by
  position (a selection, cursor, focus, pagination offset) while other code can reorder, insert
  or remove items, which leaves the pointer on a different item. Activated for changes that touch
  ordering and for user-facing changes. It came from the motifpath-web#61 review, where a
  sequence editor's selected-step index drifted when another step moved or when the form dropped
  a step.
- New Axis B / item 24 in `HEURISTICS.md`: flags a tick-driven loop (animation frame, timer,
  poller, scheduled job) that assumes its ticks arrive on time, so after a long gap it schedules
  work into the past or replays every missed tick at once. Activated for changes that run on a
  tick. It came from the PB-71 diagram player review, where a looping run replayed every missed
  pass in one burst after a background tab. The checklist is now at its 24-item cap.
## [1.3.1] — 2026-09-29

### Changed
- `HEURISTICS.md` item 18 (Test the real path): the smell now also covers tests that fire only part
  of a gesture the platform delivers as several events, e.g. a scroll without the press a swipe
  starts with. A review of a region-description popover found that tests dispatching only a
  `scroll` let a close-on-press bug through: a real swipe begins with a `pointerdown` the tests never
  sent.

## [1.3.0] — 2026-09-13

### Added
- New Axis F / item 22 in `HEURISTICS.md`: flags code comments that name an ADR, PBI/backlog
  item, ticket, or spec file instead of explaining the code's own invariant or reason. Added to
  the always-on activation set. Doc references still belong in commit messages and PR
  descriptions — this only applies to the comment text itself, which should read correctly even
  after the referenced document is archived or renumbered.

## [1.2.0] — 2026-09-07

### Changed
- Updated every reference to the ADR directory from `motifpath-specs/adr/` to
  `motifpath-specs/adrs/` (SKILL.md Phase 2, `motifpath-infra` and `_TEMPLATE`
  profiles), and rewrote the `motifpath-specs` profile's ADR-format row to match
  the reconciled `CLAUDE.md` (location `adrs/ADR-NNN-...`, Status line + Context/
  Decision/Consequences/Rationale, `adr-writer` skill as the authoring source of
  truth). `adr/ADR-001`–`014` were physically moved into `adrs/` alongside
  ADR-015; the split directory and the stale `CLAUDE.md` rule were the
  inconsistency.
- Bumped `SKILL.md` `version` to 1.2.0 to match `plugin.json` (it had been left
  at 1.0.0 when the plugin moved to 1.1.0).

## [1.1.0] — 2026-08-25

### Changed
- Widened `PLATFORM.md`'s pagination invariant (#3) to explicitly cover
  `list_files`, not just `list_discussion`. Caught live on motifpath-core#2:
  `mcp__github__get_pull_request_files` silently returned only the first 30
  of 40 changed files (GitHub's API default page size), which omitted the
  new `internal/domain/` and `internal/ports/` packages and nearly produced
  a false "this doesn't compile" blocking finding before a `per_page=100`
  re-fetch showed the full file list was fine.

## [1.0.0] — 2026-08-25

### Added
- Initial release of the MotifPath PR review skill, adapted from an external
  generic code-review skill and rebuilt for MotifPath's four-repo layout.
- Phase-based core (SKILL.md): scope detection, intent collection, systemic
  heuristics, per-repo profile norms, cross-repo coherence checks, dedup
  against existing PR discussion, mandatory approval gate before publishing,
  single-review GitHub publishing, and a mandatory learning-loop close.
- 21-item systemic checklist (`HEURISTICS.md`) with a trigger-based activation
  table and a 24-item cap.
- Finding format and tone rules (`FINDING.md`): inline-only, empty review
  body, business-effect-first, severity levels, reproduce-before-asserting.
- Guideline capture (`LEARNING.md`) with a single filter (Section 1): a
  guideline is written down because it generalizes (survives without this
  repo's stack, phrases as a question, is falsifiable), never because it
  recurred. This is a deliberate departure from the reference skill's
  five-trigger, recurrence-tracked capture pipeline (candidate lessons,
  hit counts, promotion after a second occurrence) — for a small team
  sharing one `motifpath-specs` repo, tracking specific use cases waiting
  to "graduate" is ceremony nobody will maintain. Only durable guidelines
  are recorded, straight into `HEURISTICS.md` or a profile, on first sight.
- Git-sharing mechanism: Phase 8 stages `HEURISTICS.md`/profile changes and
  drafts a Conventional Commit, but always stops for explicit user
  confirmation before committing or pushing — never automatic.
- GitHub platform adapter (`PLATFORM.md`) using the `gh` CLI as primary, with
  `mcp__github__*` tools as fallback.
- Profiles for all four MotifPath repos (`motifpath-core`, `motifpath-web`,
  `motifpath-infra`, `motifpath-specs`), seeded with evidence from each
  repo's own `CLAUDE.md`, plus `profiles/ROUTING.md` and `_TEMPLATE.md` for
  bootstrapping new scopes.
- `--dry-run` mode for reviewing a proposal or spec before code exists,
  intended to pair with `plan-writer` output and with `motifpath-specs`
  spec PRs.
