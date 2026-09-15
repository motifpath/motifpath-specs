# Project Index Maintenance — Changelog

## [1.2.0] — 2026-09-15

### Changed
- Collapsed the backlog status vocabulary from an ad hoc, growing set of
  free-text values down to five: Ready, In Progress, Blocked, Done, Archived.
  "Discovery" is retired (it's just Ready or In Progress depending on whether
  work has started); "Validated" is retired (folded into Done, which already
  implies validation); "Ready to Build" → Ready; "On hold" → Blocked.
- Reconciliation is now six checks, not five — added a status-vocabulary check
  that normalizes any row still carrying a retired status, opportunistically,
  every run, not as a one-time migration.
- Added a page-trimming step (new Step 4, workflow renumbered 1-6): Current
  Focus must read as a short present-tense status, not an accumulating
  session-by-session chronicle, and changelog-style Backlog Snapshot rows get
  compressed to a short clause. This is now a normal part of every run, not
  scope creep — the index had grown large enough to make session bootstrap
  slow, which this directly targets.
- "What NOT to Update" now calls out this one exception explicitly, and adds
  priority values (P0-P3) as an explicit no-touch (this skill normalizes
  status, not priority).

## [1.1.0] — 2026-09-10

### Changed
- Removed the "present the plan and request confirmation" step. Invoking the
  skill is now the go-ahead to write: the skill reconciles and writes to Notion
  directly, then reports the writes it made (Step 5). Workflow is now five steps,
  not six.
- Ambiguities a write depends on (e.g. two active backlog items) are still
  resolved with Gilson before that specific write; everything unambiguous is
  written without waiting.
- Added an edge case: pause and check with Gilson if a write turns out larger
  than the session inventory justifies.

## [1.0.0] — 2026-08-25

### Added
- Initial versioned release, migrated from `skills/project-index-maintenance/`
  into the `motifpath-skills` plugin marketplace. No behavioral change from
  the pre-marketplace version.
