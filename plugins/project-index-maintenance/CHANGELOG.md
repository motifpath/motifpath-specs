# Project Index Maintenance — Changelog

## [2.0.0] — 2026-09-17

### Deprecated
- This skill is deprecated per [ADR-022](../../adrs/ADR-022-drop-notion-project-tracking.md).
  MotifPath project tracking (current focus, backlog status, decided ADRs) moved from Notion
  to git (what shipped) plus Claude Code's session-persistent auto-memory (continuity between
  sessions) — both free of the per-session Notion fetch/reconcile/write cycle this skill
  performed, and not dependent on Notion MCP availability.
- The skill is retained, unused, only because this repo's policy forbids deleting skills. Its
  frontmatter `description` no longer contains any trigger phrases, so it will not be selected
  for phrases like "update the project index" or "wrap up the session" going forward — those
  now mean "update the relevant memory file(s)" instead.
- The Notion Project Index page (`3679ccc1-102f-8184-83a7-e328e0d8cbfc`) and Product Backlog
  data source (`93826617-2504-4976-9769-d3841dffcafd`) referenced throughout this skill's body
  are no longer written to by any MotifPath skill. They are not deleted from Notion itself —
  that's outside this repo's scope — but nothing in `motifpath-specs` maintains them anymore.

## [1.4.0] — 2026-09-15

### Changed
- Decided ADRs table is now filtered, not exhaustive — added "Decided ADRs
  Relevance": keep a row only if the ADR is cross-cutting (data layer, auth,
  event pipeline, frontend architecture, local dev, deployment) or tied to
  backlog work that isn't Done/Archived; fold out narrow SDK/tooling footnotes
  and closed deferral notes, adding a pointer to a kept row when one is a
  natural home for it.
- Applied this rule for the first time: trimmed the live table from 21 to 16
  rows (removed ADR-001, 009, 010, 013, 014 — all real, accepted decisions
  that stay permanently in `motifpath-specs/adrs/` per repo policy, just not
  worth a row on the bootstrap page). ADR-007 gained a pointer to ADR-014's
  amendment; ADR-012 gained a pointer noting ADR-013 closed its deferral.
- Step 3 check 3 (ADR check) now applies this filter to newly-decided ADRs
  going forward, and updates an already-kept row's pointer when Step 2's
  inventory shows an amendment to it. It does not re-audit existing rows the
  inventory didn't surface — same scoping principle as Step 3 check 5 for
  backlog items.
- "What NOT to Update" gains a matching entry: don't re-litigate an
  already-kept ADR's place in the table absent a session-inventory reason to.

## [1.3.0] — 2026-09-15

### Changed
- Backlog Snapshot on the index page is now a live linked view of the real
  Product Backlog database (`collection://93826617-2504-4976-9769-d3841dffcafd`),
  not a manually copied markdown table — that table was removed. This skill's
  reconciliation target shifts accordingly: Step 3 check 4 ("Backlog snapshot
  check") is now "Backlog database check" against the real database via
  `notion-query-data-sources`, and Step 5's backlog writes are
  `update_properties` calls on individual item pages, not markdown-table edits
  on the index page.
- Discovered mid-rollout that the real database's `Status` options were
  themselves the ad hoc, redundant set this skill was meant to fix on the
  index page — normalized there too (`Discovery`/`Validated`/`Ready to Build`
  removed from the select property's option list via `notion-update-data-source`,
  27 items' stale statuses corrected) as part of the same v1.3.0 rollout.
- Added an edge case: a backlog item can be discussed for months in session
  notes and merged PRs while having no corresponding database row at all (this
  happened for real with PB-40). Step 3 check 4 now catches this; the fix is
  `notion-create-pages` against the data source, not a status write.
- "Backlog Snapshot rows" trimming (old Step 4 bullet) is replaced by
  "Backlog database `Notes` field" trimming — the compression target moved
  from index-page table cells to the database item's own `Notes` property.
- "What NOT to Update" gains two entries: don't audit every backlog item's
  status on every run (only ones the session's inventory touched), and don't
  touch the Active Backlog linked view's filter/sort configuration.
- Page Reference now lists two write targets (index page + Product Backlog
  data source) instead of one, and explicitly excludes the data source's
  schema (property definitions) from this skill's scope — schema changes are
  one-time setup, not session-close maintenance.

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
