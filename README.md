# motifpath-specs

Contract repository for the MotifPath platform. All API contracts, domain events,
business rules, architecture decisions, AI prompts, evaluation sets, and Claude
skills live here.

No feature is ready for implementation until its spec exists in this repository.

## What Lives Here

| Directory | Contents |
|---|---|
| `/openapi` | REST API specs (OpenAPI 3.1 YAML), including domain event schemas at `openapi/components/schemas/events.yaml` |
| `/features` | Business rule specs (Gherkin `.feature` files, nested per domain) |
| `/adrs` | Architecture Decision Records |
| `/prompts` | Versioned AI task prompts |
| `/evals` | Golden sets for PromptFoo evaluation |
| `/plugins` | Claude Code skills for the whole team, distributed as a plugin marketplace |

## Onboarding

Run this once when setting up a new machine. It installs the global Claude Code
context and all team skills — applies to every MotifPath repository.

```bash
# 1. Clone all repositories, side by side in one parent directory — motifpath-core
#    and motifpath-web read ../motifpath-specs and each other by relative path
mkdir -p ~/repos/motifpath && cd ~/repos/motifpath
git clone git@github.com:motifpath/motifpath-specs.git
git clone git@github.com:motifpath/motifpath-core.git
git clone git@github.com:motifpath/motifpath-web.git
git clone git@github.com:motifpath/motifpath-infra.git

# 2. Install global CLAUDE.md (first time only — machine-level, not committed)
mkdir -p ~/.claude
cp motifpath-specs/global-CLAUDE.md ~/.claude/CLAUDE.md

# 3. Add the MotifPath skills marketplace (one-time per machine)
claude plugin marketplace add git@github.com:motifpath/motifpath-specs.git

# 4. Install each skill
claude plugin install git@motifpath-skills
claude plugin install adr-writer@motifpath-skills
claude plugin install ai-consultant@motifpath-skills
claude plugin install plan-writer@motifpath-skills
claude plugin install product-discovery@motifpath-skills
claude plugin install pr-review@motifpath-skills

# 5. Turn on background auto-update for this marketplace (off by default for
#    non-Anthropic sources): run `/plugin` inside a Claude Code session,
#    open the Marketplaces tab, select motifpath-skills, and enable auto-update.

# 6. Verify
claude plugin list
```

Skills each version independently — check `plugins/<name>/CHANGELOG.md` for what
changed. With auto-update on, Claude Code checks for newer versions shortly after
each session starts and updates them on disk; run `/reload-plugins` (or start a
new session) to pick up the update. Without auto-update, run
`/plugin marketplace update motifpath-skills` manually after a `git pull`.

**Next:** set up the local development stack — follow
[motifpath-core README → Getting Started](../motifpath-core/README.md#getting-started-first-time-on-this-machine)
(Docker, mise, Atlas, env files, Clerk keys, seed data), which also walks through
`motifpath-web`. For this repository, see [Prerequisites](#prerequisites) below.

## Branching Model

```
main  (protected — the only long-lived branch in this repository)
```

Unlike `motifpath-core` and `motifpath-web`, this repository has no `dev` branch: all
feature, fix, ADR, and spec work branches from `main` and targets `main`.

Branch naming — task code is mandatory:

```
feat/MTP-001/short-description
fix/BUG-042/short-description
spec/MTP-007/short-description
adr/MTP-008/003-short-decision-title
```

The `sync-main-to-dev` reusable workflow defined here (see below) is for the repositories
that do have a `dev` branch.

## Shared Workflows

This repository defines reusable GitHub Actions workflows consumed by all other repos:

| Workflow | File | Purpose |
|---|---|---|
| Sync main → dev | `.github/workflows/reusable-sync-main-to-dev.yml` | Auto-opens PR to sync `main` back to `dev` after any merge |

> **GitHub Actions permission required:** Enable *"Allow motifpath repositories to
> call reusable workflows"* in the org's Actions settings, or callers will fail.

## Prerequisites

- [mise](https://mise.jdx.dev), activated in your shell — installs the Node.js version pinned in
  `mise.toml` (npm comes with it). If you set up `motifpath-core` first, you already have it.

```bash
mise trust && mise install   # Node.js, at the version in mise.toml
npm install
```

This installs: `@redocly/cli`, `@cucumber/gherkin-streams`, and the golden-case validator's
`ajv`/`yaml`. PromptFoo is added together with the first prompt in `/prompts` (ADR-002).

## Commands

```bash
# Validate all OpenAPI specs (this also validates the referenced event
# schemas in openapi/components/schemas/events.yaml)
npm run validate:openapi

# Validate all Gherkin feature files (searched recursively under features/)
npm run validate:features

# Validate grader golden cases against their schema
npm run validate:golden

# Run all validations at once
npm run validate
```

## Workflow

1. A product requirement arrives in the backlog
2. PO uses the Gherkin generator prompt (`/prompts/gherkin-generator.md`) to draft scenarios
3. PO reviews and approves — business rule accuracy is the gate, not just syntax
4. Developer raises a PR with the spec changes
5. CI validates all artifacts
6. PR merges — the feature is now ready for implementation in consuming repos

## Definition of Ready

A feature is ready for development when ALL of the following are true:

- [ ] OpenAPI endpoint(s) defined (if the feature has an HTTP surface)
- [ ] Gherkin scenarios cover: happy path + at least 2 edge cases + at least 1 failure case
- [ ] PO has approved business rule accuracy
- [ ] ADR exists if the feature introduces an architectural change

## Domain Events

These events form the core behavioral contract of MotifPath:

```
lesson.started              lesson.resumed            lesson.completed
exercise.started            exercise.progress         exercise.ended
practice.session_started    practice.item_answered    practice.session_ended
practice.tap_check_completed
song_chart.opened           song_chart.chord_viewed   song_chart.section_completed
```

Event schemas live in `openapi/components/schemas/events.yaml`, referenced via
`$ref` from `openapi/event-ingestion-service.yaml`.

## Related Repositories

| Repository | Purpose |
|---|---|
| [motifpath-core](../motifpath-core) | Go backend — consumes OpenAPI + event schemas |
| [motifpath-web](../motifpath-web) | Vue 3 frontend — consumes OpenAPI |
| [motifpath-infra](../motifpath-infra) | Terraform infrastructure |