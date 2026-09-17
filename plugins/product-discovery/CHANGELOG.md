# Product Discovery — Changelog

## [1.2.0] — 2026-09-17

### Removed
- "Notion Backlog Integration" section, including the fixed workspace IDs (Product HQ page,
  Product Backlog database/data source) and all "Claude handles this on request" Notion
  read/write operations. Per [ADR-022](../../adrs/ADR-022-drop-notion-project-tracking.md),
  no MotifPath skill automatically integrates with Notion anymore.

### Changed
- Replaced with a "Backlog Tracking" section: in-session reasoning uses the same schema as
  before, but persistence across sessions goes through Claude Code's auto-memory (a `project`
  memory) instead of a live Notion database. Durable decisions (validated hypotheses,
  architectural commitments) get promoted into an ADR or a spec update instead.
- "Chat Discipline Model" example and step 8 of the product-topic sequence now say "save to
  memory" instead of "log to Notion"/"log to the backlog".
- "Output Formats" → "Backlog proposal" now targets a memory/ADR/spec, not a Notion item.

## [1.1.0] — 2026-09-08

### Changed
- **Premise revision.** MVP validation and student retention no longer depend on external
  teacher supply — the team is the concierge and the platform must show standalone value
  first. Teacher leverage is reframed as the scaling thesis, not an MVP dependency.
  - Added a premise-revision callout to "Primary Personas".
  - "Persona A — The Music Teacher" retitled from "Most Critical Partner" to "scaling partner"
    and rewritten to drop "the platform fails without teachers".
  - Business Risk Radar: "Dependency on teacher acquisition" 🔴 downgraded to 🟡
    "Teacher-supply dependency"; added 🔴 "Retention is now the platform's problem".
- Aligns with ADR-017 (student path as a copied template instance) and the global project
  instructions.

## [1.0.0] — 2026-08-25

### Added
- Initial versioned release, migrated from `skills/product-discovery/` into the
  `motifpath-skills` plugin marketplace. No behavioral change from the
  pre-marketplace version.
