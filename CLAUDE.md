# motifpath-specs

This repo holds all product specifications, ADRs, and design documents for Motifpath.

## What lives here

- `specs/` — feature specs (problem, goals, non-goals, user stories, open questions)
- `adr/` — Architecture Decision Records using the MADR format
- `design/` — system design diagrams and write-ups
- `api/` — OpenAPI/AsyncAPI contracts

## Conventions

- Every spec has a status: Draft | Review | Accepted | Superseded
- ADRs are numbered sequentially: `adr/0001-title.md`
- Link from specs to the ADRs that inform them, and vice versa
- Keep specs implementation-agnostic; implementation detail belongs in the relevant code repo's CLAUDE.md

## How to help

- When drafting a new spec, ask about problem statement and constraints before writing
- Flag when a spec decision implies an ADR that hasn't been written
- Suggest open questions the spec should address before moving to Review
