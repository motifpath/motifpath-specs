# Plan Writer — Changelog

## [2.0.0] — 2026-09-17

### Changed
- **Breaking change to file location and workflow.** Per
  [ADR-022](../../adrs/ADR-022-drop-notion-project-tracking.md), plans are no longer committed
  to `motifpath-specs/plans/` via a feature branch and PR. They're written to a local,
  gitignored `plans/` folder inside whichever repo the implementation work happens in, and are
  never committed. A plan's job ends when its feature merges; anything durable (an
  architectural decision, a contract change) gets promoted into an ADR or a spec update
  instead.
- "File Location" and "Git Workflow" sections rewritten accordingly; "Git Workflow" renamed
  "Workflow" since there's no git step left.

## [1.0.0] — 2026-08-25

### Added
- Initial versioned release, migrated from `skills/plan-writer/` into the
  `motifpath-skills` plugin marketplace. No behavioral change from the
  pre-marketplace version.
