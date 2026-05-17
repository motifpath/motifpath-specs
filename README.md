# motifpath-specs

Contract repository for the MotifPath platform. All API contracts, domain events,
business rules, architecture decisions, AI prompts, evaluation sets, and Claude
skills live here.

No feature is ready for implementation until its spec exists in this repository.

## What Lives Here

| Directory | Contents |
|---|---|
| `/openapi` | REST API specs (OpenAPI 3.1 YAML) |
| `/events` | Domain event schemas (JSON Schema) |
| `/features` | Business rule specs (Gherkin `.feature` files) |
| `/adr` | Architecture Decision Records |
| `/prompts` | Versioned AI task prompts |
| `/evals` | Golden sets for PromptFoo evaluation |
| `/skills` | Claude Code skills for the whole team |

## Onboarding

Run this once when setting up a new machine. It installs the global Claude Code
context and all team skills — applies to every MotifPath repository.

```bash
# 1. Clone all repositories
git clone git@github.com:motifpath/motifpath-specs.git
git clone git@github.com:motifpath/motifpath-core.git
git clone git@github.com:motifpath/motifpath-web.git
git clone git@github.com:motifpath/motifpath-infra.git

# 2. Install global CLAUDE.md (first time only — machine-level, not committed)
mkdir -p ~/.claude
cp motifpath-specs/global-CLAUDE.md ~/.claude/CLAUDE.md

# 3. Install Claude skills
cd motifpath-specs && bash skills/install.sh

# 4. Verify
ls ~/.claude/skills/
# → git/
```

To update skills after pulling new changes:

```bash
cd motifpath-specs && git pull && bash skills/install.sh
```

## Branching Model

```
main  (protected — production releases only)
dev   (protected — integration branch, target for all feature PRs)
```

All feature, fix, chore, and spec work branches from `dev` and targets `dev`.
`main` only receives PRs from `dev` (releases) or `hotfix/*` branches (critical fixes).

Branch naming — task code is mandatory:

```
feat/MTP-001/short-description
fix/BUG-042/short-description
spec/MTP-007/short-description
hotfix/BUG-099/short-description    ← branches from main, not dev
```

After any merge to `main`, the `sync-main-to-dev` reusable workflow opens a PR
from `main` to `dev` automatically. Review and merge it promptly.

## Shared Workflows

This repository defines reusable GitHub Actions workflows consumed by all other repos:

| Workflow | File | Purpose |
|---|---|---|
| Sync main → dev | `.github/workflows/reusable-sync-main-to-dev.yml` | Auto-opens PR to sync `main` back to `dev` after any merge |

> **GitHub Actions permission required:** Enable *"Allow motifpath repositories to
> call reusable workflows"* in the org's Actions settings, or callers will fail.

## Prerequisites

- Node.js 20+
- npm

```bash
npm install
```

This installs: `@redocly/cli`, `ajv-cli`, `@cucumber/gherkin`, `promptfoo`.

## Commands

```bash
# Validate all OpenAPI specs
npm run validate:openapi

# Validate all event JSON schemas
npm run validate:events

# Validate all Gherkin feature files
npm run validate:features

# Run PromptFoo evals against all prompt files
npm run eval:prompts

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

Seven events form the core behavioral contract of MotifPath:

```
lesson.started        lesson.resumed         lesson.completed
exercise.started      exercise.answer_sent   exercise.ended
node.unlocked
```

JSON Schemas for each event live in `/events/`.

## Related Repositories

| Repository | Purpose |
|---|---|
| [motifpath-core](../motifpath-core) | Go backend — consumes OpenAPI + event schemas |
| [motifpath-web](../motifpath-web) | Vue 3 frontend — consumes OpenAPI |
| [motifpath-infra](../motifpath-infra) | Terraform infrastructure |