# ADR-022: Drop Notion as project-tracking system of record

**Status:** Accepted
**Date:** 2026-09-17
**Deciders:** Gilson (with Claude Code ai-consultant review)

---

## Context

`project-index-maintenance` fetches and reconciles a Notion "Project Index" page and the
Product Backlog database every time it's invoked, and `product-discovery`'s Notion Backlog
Integration performs live create/update/query calls against the same database mid-conversation.
Each of these round-trips costs tokens: a fetch, reasoning to diff the fetched state against
session history, then one or more writes — for state that is largely already recoverable from
git (merged PRs, commit history) or already tracked for free by Claude Code's session-persistent
auto-memory.

This surfaced as a real failure, not a hypothetical one: in the session that produced this ADR,
the Notion MCP connection was unavailable, so the documented "MotifPath Session Start Protocol"
(fetch the Project Index page first) could not run at all. Actual project state — open PRs,
recently merged work, stray uncommitted files — was reconstructed faster and more reliably
directly from `git log` and the GitHub API than the Notion-based protocol would have delivered,
even when Notion is reachable.

Separately, `plan-writer` commits every implementation plan to `motifpath-specs/plans/` as a
reviewed PR. A plan is used once, by whoever is implementing that feature, for the few days the
feature takes to build — but committing it triggers a full branch → PR → review → merge cycle and
permanent git history for a document with no long-term audience. The durable content a plan
touches on (an architectural choice, a contract) belongs in an ADR or the specs themselves; the
day-by-day task checklist does not need to outlive the feature branch.

Alternatives considered:
- **Keep Notion, but batch writes to session-close only** — rejected. Still requires an
  LLM-driven reconciliation step every session, and does nothing about the reliability problem:
  this session's failure was that the fetch itself couldn't run, not that writes were too
  frequent.
- **Keep plans versioned, but delete the file after the feature merges** — rejected. Still pays
  the full PR-and-review cost during the plan's short life; the only cost avoided is long-term
  storage, which was never the expensive part.

## Decision

MotifPath project state (current focus, backlog status, decided ADRs) is tracked exclusively
through:

1. **Git and GitHub** as the system of record for what shipped — branches, PRs, merges, commit
   messages.
2. **Claude Code's auto-memory system** (session-persistent `MEMORY.md` plus topic files) as the
   system of record for session-to-session continuity — current focus, in-flight blockers,
   non-obvious context. Claude reads and updates this directly, at effectively zero token cost,
   with no external API round-trip.

No MotifPath skill reads or writes Notion automatically for project tracking.
`project-index-maintenance` is deleted outright — its full definition and history remain
recoverable from git, so there is no separate "keep it around, unused, forever" step. This also
retires this repo's blanket "never delete a skill" policy: a skill with no remaining use can be
removed in the same commit as its `marketplace.json` entry, with the reason captured in the
commit message (or, as here, an ADR) rather than in a file that's being deleted along with it.
`product-discovery`'s "Notion Backlog Integration" section and workspace IDs are removed;
hypothesis and backlog tracking in product-discovery conversations now happens through
auto-memory, promoting anything durable into an ADR or a git-tracked spec, not a live Notion
database.

Implementation plans (`plan-writer` output) are written to a local, `.gitignore`d `plans/`
directory inside whichever repo the work is happening in — never committed, never opened as a
PR. A plan's job ends when its feature merges. Anything worth keeping permanently (an
architectural decision, a contract) is promoted into an ADR or into the OpenAPI/Gherkin specs
themselves, both of which remain fully versioned as before.

## Rationale

Every one of these Notion touchpoints was a second system of record duplicating information
git or Claude's own memory already held for free — and the LLM was the sync mechanism between
the two, which is the expensive part of the pattern, not the information itself. The plan-writer
PR cycle paid the same tax in a different shape: full review overhead for a document with a
lifespan of days. Removing the Notion round-trips and the plan PR cycle doesn't lose information
that wasn't already recoverable elsewhere — merged work is provable from git regardless of
whether Notion agrees, and decisions worth keeping permanently are the ADR's job, not the plan's
or the Notion page's.

The rejected "batch Notion writes to session-close" alternative would have reduced call *count*
but not eliminated the failure mode demonstrated this session: a fetch-first protocol that
depends on an external system being reachable, when the reachable-and-free alternative (memory
plus git) was sitting right there.

## Consequences

### Positive
- Eliminates the per-session Notion fetch/reconcile/write cycle in `project-index-maintenance`
  and the mid-conversation Notion calls in `product-discovery` — direct token savings on every
  MotifPath session.
- Removes a documented single point of failure: session bootstrap no longer depends on Notion
  MCP availability.
- Plans no longer trigger a PR-and-review cycle for a short-lived artifact — faster iteration
  from spec to code.
- No dead, unused skill file sitting in the plugin marketplace description list forever —
  `plugins/` only lists what's actually in play.

### Negative / Trade-offs
- Loses a browser-viewable, shareable project board. If a non-Claude-Code collaborator (a
  co-founder, a contracted teacher) ever needs to see project status without a terminal, this
  decision needs revisiting.
- Auto-memory is scoped to this Claude Code account's session history — it is not multi-user,
  and lacks Notion's structured querying (filtering all backlog items by status/priority at
  once).
- Plans already committed to `motifpath-specs/plans/` remain there (nothing is deleted, per
  this repo's policy on specs), but new plans won't be discoverable the same way — auditing "what
  was the plan for PB-NNN" after this ADR only works if the plan predates this decision or its
  durable content was promoted into an ADR.
- Retiring "never delete a skill" removes a safety net, not just for this one skill: a future
  deletion that turns out to be premature has no automatic soft-landing (a deprecated-but-present
  file to resurrect) — recovery now depends on someone remembering to check git history. This
  repo's separate "never delete an ADR" policy is unaffected by this decision.

### Neutral
- `motifpath-specs/plans/` stays as a directory with its existing history; it simply stops
  receiving new content going forward.
- `english-fluency-coach`'s Notion logging is unaffected — that is a personal writing-coaching
  system, unrelated to project tracking, and out of scope for this decision.

## Related ADRs

None directly — this is a tooling/process decision rather than a runtime system decision, but it
changes how work on every future ADR, spec, and backlog item gets tracked from here on.

---

*This ADR was decided on 2026-09-17. To revise, create a new ADR with Status: Supersedes ADR-022.*
