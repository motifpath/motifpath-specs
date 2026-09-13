# Project Index Maintenance — Changelog

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
