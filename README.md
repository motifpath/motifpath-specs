# motifpath-specs

Single source of truth for all contracts in the MotifPath platform. **Specs are written here before any implementation begins** in other repositories.

## Repository Structure

```
openapi/      REST API specs (OpenAPI 3.1 YAML)
events/       Domain event schemas (JSON Schema)
features/     Business rule specs (Gherkin .feature files)
adr/          Architecture Decision Records
prompts/      Versioned AI task prompts
evals/        Golden sets for PromptFoo evaluation
```

## Definition of Ready

A feature spec is ready for development when **all** of the following are true:

- [ ] OpenAPI endpoint(s) defined (if the feature has an HTTP surface)
- [ ] Gherkin scenarios cover: happy path + at least 2 edge cases + at least 1 failure case
- [ ] PO has reviewed and approved business rule accuracy
- [ ] ADR exists if the feature introduces an architectural change

## Domain Events

Seven domain events are defined in `/events/` and referenced across all services:

| Event | Description |
|-------|-------------|
| `lesson.started` | Student begins a new lesson session |
| `lesson.resumed` | Student returns to an in-progress lesson |
| `lesson.completed` | Lesson session ends |
| `exercise.started` | Student begins an exercise |
| `exercise.answer_sent` | Student submits an answer |
| `exercise.ended` | Exercise session ends |
| `node.unlocked` | Student meets the accuracy threshold for a node |

## Standards at a Glance

**OpenAPI** — `operationId` in camelCase, all properties snake_case with descriptions, minimum responses: 200/400/401, enums for status fields.

**Gherkin** — domain language only (no HTTP codes, SQL, or framework names), one scenario per behavior, concrete steps.

**ADRs** — `/adr/NNN-short-kebab-title.md`, required sections: Context / Decision / Consequences. Never deleted; superseded ADRs reference the replacing ADR.

**Prompts** — version field bumped on every change, `promptfoo eval` must pass before merge.

## Tooling

| Tool | Purpose |
|------|---------|
| [Redocly CLI](https://redocly.com/docs/cli/) | OpenAPI validation |
| [PromptFoo](https://promptfoo.dev/) | AI prompt evaluation |
| JSON Schema validator | Event schema validation |
| Gherkin parser | Feature file syntax check |

## Contributing

1. Open a PR with the spec change
2. All CI checks must pass (see CI badge above)
3. PO approval required on Gherkin scenarios before merge
4. Implementation PRs in other repos must link back to the spec PR
