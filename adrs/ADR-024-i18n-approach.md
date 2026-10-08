# ADR-024: Internationalization approach — vue-i18n, locale preference, and content-language modeling

**Status:** Accepted
**Date:** 2026-09-18
**Deciders:** Gilson (Product Owner)
**Amended:** 2026-10-08, by Gilson, from the My path design (MOT-56, D3 option A; written in
MOT-39): a language-locked path step is no longer a dead end. The student can open it in the
language it has, and finishing it completes the step. The path says why a step is locked
(`lock_reason`). See "Amendment — 2026-10-08".

---

## Context

MotifPath needs to support two languages at launch — English and Portuguese (Brazil) — with the
explicit expectation that more languages will be added later. Neither `motifpath-web` nor
`motifpath-core` has any i18n infrastructure today: no i18n library is installed, and no
`locale`/`language` field exists anywhere in the `ent` schema (verified directly against
`services/core-domain/internal/adapters/repo/ent/schema/`). This is greenfield, not a retrofit.

The requirement splits into three forces that don't share a solution:

1. **UI chrome** — labels, buttons, menus, and other static strings must be translatable, and a
   user must be able to select their preferred language.
2. **Locale preference** — the selected language has to be stored somewhere and resolved
   consistently for both anonymous and authenticated users.
3. **Content-language filtering** — a `ContentNode` (video or article, per ADR-015's node model,
   and by extension `Exercise` per ADR-019) is authored content, not a UI string, and different
   node instances may exist only in one language, or may be usable regardless of language (e.g. an
   image with no embedded text). This needs a data model, not a translation library.

Conflating these three would produce the wrong architecture — a UI string library doesn't solve
content filtering, and a content-language field doesn't solve button labels. Constraints in scope:
Vue 3.5 + TypeScript strict + Tailwind on the frontend (ADR-018), route-level code splitting
already established as the norm (ADR-018/ADR-020), Go + `ent` + Postgres on `core-domain`
(ADR-005, migrated via Atlas per ADR-010), and the existing join-table pattern already used for
many-to-many relationships in that schema (`content_node_exercises`, `challenge_exercises`).

### UI library candidates considered

- **vue-i18n** — official Vue 3 library, first-party Composition API support (`useI18n()`),
  MIT-licensed, the de facto standard in the Vue ecosystem.
- **Paraglide JS** — compiler-based, tree-shaken per-message output; benchmarks show
  significantly smaller bundles at scale (e.g. ~47KB vs. 205KB+ for i18next at 5 locales/200
  messages). However, Vue is not a first-class target — it has official adapters for Svelte and
  Solid, with Vue support only through a community package.
- **typesafe-i18n** — pioneered compile-time type safety for translation keys, but is no longer
  actively maintained.

### Content-language field candidates considered

- **Single `language` enum on `ContentNode`** — matches the existing style of `difficulty_level`/
  `review_state`, but cannot express a content item valid for more than one language (e.g. an
  image or audio asset with no embedded text), short of adding an awkward `"any"` enum value that
  still can't express "available in English AND Portuguese but not Spanish." Every new language
  also requires a Postgres `ALTER TYPE ... ADD VALUE` migration.
- **JSON/array-of-codes field on `ContentNode`** — expresses multi-language content and avoids
  enum migrations, but isn't indexable or joinable the way the rest of this schema's relationships
  are, has no referential integrity against a canonical list of supported languages, and diverges
  from the join-table pattern already used elsewhere in this schema.
- **`Language` lookup entity + many-to-many edge** — a new small entity (`code`, `name`) with
  `ContentNode` edged to it many-to-many, mirroring `content_node_exercises`/
  `challenge_exercises`. Adding a language becomes a data insert, not a schema migration.

## Decision

MotifPath will use **vue-i18n** for UI chrome translation, a **`locale` edge on `User`**
pointing at a new **`Language` lookup entity** for locale preference, and a **many-to-many edge
from `ContentNode` to that same `Language` entity** for content-language filtering.

**1. UI chrome (`motifpath-web`).** Adopt `vue-i18n` with the Composition API
(`createI18n({ legacy: false, ... })`, `useI18n()`). Locale message files are colocated per
feature and lazy-loaded with their route chunk, matching the existing route-level code-splitting
norm:

```
src/features/<feature>/locales/en.json
src/features/<feature>/locales/pt-BR.json
src/shared/locales/en.json      ← nav, buttons, error strings used everywhere
src/shared/locales/pt-BR.json
```

`en.json` is the canonical/reference locale — every key must exist there first. Feature locale
files are merged in via `i18n.mergeLocaleMessage()` when their route/feature chunk loads. Use the
`@intlify/unplugin-vue-i18n` Vite plugin for compile-time message precompilation and TS-typed
translation keys generated from `en.json`, so referencing a missing key is a build-time TypeScript
error, not a silent runtime fallback. Add a Vitest test that asserts key-set parity between each
`en.json`/`pt-BR.json` pair, failing CI on drift. No translation management platform (Locize,
Lokalise, etc.) is adopted at this stage — plain reviewed JSON is proportionate with the team
acting as concierge/content owner at 2 languages.

**2. Locale preference.** Add a `Language` entity (`code`, `name`) to `core-domain`'s `ent`
schema, seeded with `en` and `pt_BR` (plus a literal `any` row — see part 3). `User` gets an edge
to `Language` instead of its own enum, so there is one canonical list of supported languages
shared by user preference and content filtering, rather than two enums that can drift out of
sync. Anonymous/pre-authentication users resolve locale from the `Accept-Language` header, falling
back to a `localStorage` value once set. Authenticated users resolve locale from their `User`
record; it is settable via a small `PATCH /users/me`-style endpoint and hydrated into a Pinia
store at application boot (same pattern as the existing `currentUser` store from PB-8c), which
drives the active `vue-i18n` locale.

**3. Content-language filtering (`motifpath-core`).** Add a many-to-many edge from `ContentNode`
to `Language` (`edge.To("languages", Language.Type)`), the same join-table pattern already used
for `content_node_exercises` and `challenge_exercises`. A content item authored only in Portuguese
carries one edge; an image or audio asset usable regardless of language carries an edge to a
literal `any` row in `Language`, making "works everywhere" an explicit fact rather than something
inferred from "has every language edge." Filtering a student's available content becomes a join
on their resolved locale (or the `any` row) rather than an array-containment query. This same
`Language` entity backs `User.locale` from part 2.

## Rationale

**vue-i18n over Paraglide JS:** Paraglide's bundle-size advantage scales with locale count ×
message count; at 2 languages and a moderate-sized app the absolute gap is small, while the
Vue-support gap is not — Paraglide's Vue path is a community adapter, not an officially maintained
target. ADR-020 already ruled out BlockNote, Plate, and Lexical on exactly this kind of
second-class-framework-support risk (bus factor, no first-party Vue path) even where the
alternative had technical advantages. The same reasoning applies here: an officially-supported,
Composition-API-native library is worth more than a bundle-size win on a library the team would be
first to hit Vue-specific bugs in.

**Lazy-loaded, feature-colocated locale files over a single global message file:** ADR-018 and
ADR-020 already established route-level code splitting as this app's norm specifically to avoid
shipping unused code (and, in ADR-020's case, unused editor weight) into the entry bundle.
Bundling every locale's every string into one file at boot would repeat the mistake those ADRs
were written to avoid, and would only get worse as more languages are added.

**`Language` entity + edge over a `language` enum:** An enum forces a false choice on any content
item that isn't inherently single-language (images, most audio, some video), and treats "support
a new language" as a schema migration event rather than a data event — directly contradicting the
premise that more languages are coming. A JSON/array field solves the multi-language expressivity
problem but not the migration-avoidance or referential-integrity problem, and it diverges from how
this schema already models every other many-to-many relationship. The lookup-entity-plus-edge
approach solves both: expressive (any subset of languages, including "all of them" via the `any`
row), query-efficient (an indexable join, consistent with the rest of the schema), and
migration-free when a new language is added (an `INSERT`, not an `ALTER TYPE`).

**Single `Language` entity shared by `User.locale` and `ContentNode.languages`:** two separate
enums (one for what a user can select, one for what content can be tagged) can drift — a language
a user could select but no content supports, or vice versa. A single source of truth removes that
class of bug entirely.

## Consequences

### Positive
- Adding a new language after launch (e.g. Spanish) is a data change (`INSERT INTO languages`,
  translate the JSON files, seed content) — no schema migration, no Postgres enum alteration.
- Content that is genuinely language-agnostic (images, most audio/video without embedded text) is
  representable without contorting the model or duplicating nodes.
- Missing-translation-key bugs are caught at build time (TS) and in CI (key-parity test) rather
  than surfacing as raw i18n keys or silent English fallback in production.
- Locale files stay out of the entry bundle and out of unrelated feature chunks, consistent with
  this app's existing bundle-size discipline.

### Negative / Trade-offs
- More moving parts than a single enum: a new `Language` entity, a join table, and an edge on two
  existing entities (`User`, `ContentNode`), versus one enum column. This is deliberate — the
  cheaper option (enum) doesn't survive the multi-language-content or future-languages
  requirements — but it is real added surface area to build and test.
- `vue-i18n` ships a larger runtime than a compile-time-only approach like Paraglide would; this
  ADR accepts that cost in exchange for first-party Vue support, matching the precedent ADR-020
  already set (accepting Tiptap's ~87KB gzip ProseMirror floor for the same class of reason).
- Every feature that adds UI copy now has a translation-parity obligation (both locale files, kept
  in sync, enforced by CI) — a small but permanent tax on every future PR touching UI text.

### Neutral
- The `any` language row is a modeling convention (an explicit sentinel row, not a NULL or special
  case in application code) — any future engineer needs to know it exists and what it means before
  writing content-filtering queries.

## Open Question — Resolved 2026-09-18

**Fallback behavior when a student's locale has no matching content for a given node or path
item** was left open at acceptance as a product policy decision, not a technical one. Resolved:
**lock/skip the node** — a node or path item with no `ContentNode`/`Exercise` tagged for the
student's resolved locale (and no `any`-language edge) is treated as unavailable to that student
until a matching-language version exists, rather than silently substituting the other language or
surfacing an opt-in prompt. This guarantees a student never receives content outside their
selected language, at the cost of a path being able to stall on translation lag — an accepted
trade-off given the team controls both authoring and translation pace as concierge.

This resolution governs the content-filtering read path referenced in Decision part 3 and needs a
Gherkin scenario (`motifpath-specs/features/`) covering the lock/skip behavior before that read
path is implemented, per this repo's Definition of Ready.

**Amended 2026-10-08:** "no opt-in prompt" no longer holds for path steps. See "Amendment —
2026-10-08". Content is still never *silently* substituted.

## Amendment — 2026-09-18: `Exercise` gets its own `Language` edge

Decision part 3, as originally written, edged only `ContentNode` to `Language` and treated
`Exercise` as inheriting language availability from whichever `ContentNode` it's attached to.
That doesn't hold: ADR-019 decoupled `Exercise` from `ContentNode`/`Challenge` into a many-to-many
relationship specifically so a single exercise can be reused across multiple content nodes. An
exercise authored only in Portuguese but attached to an English-tagged `ContentNode` (or vice
versa, or attached to several nodes in different languages) has no single parent to inherit a
language from — inheritance is not well-defined once reuse is possible.

**Amended decision:** `Exercise` gets its own many-to-many edge to `Language`, structurally
identical to `ContentNode`'s (a new join entity mirroring `ContentNodeLanguage`, or a shared join
pattern if the two can reasonably share one — an implementation-level choice, not an
architectural one). An exercise's language availability is evaluated independently of its parent
`ContentNode`(s); the locking rule from the previous section applies per-entity — a path item can
be locked because its `ContentNode` lacks the student's locale, because an attached `Exercise`
required by that item does, or both.

This does not change Decision parts 1 or 2, or the `any`-row convention, which apply unchanged to
`Exercise`.

## Amendment — 2026-10-08: a language-locked step opens in the language it has

**Context.** The 2026-09-30 smoke test (pt-BR profile, English-only lessons) showed what the
lock/skip resolution does in practice. `BuildStudentPathItems` locks the step, and since it
can't be completed, the prerequisite rule then locks every later step. `current_position` points at
the locked step. The student is stuck with no way through it, and every lock reads "Complete the
previous step", which is false here. The trade-off accepted above, "a path being able to stall on
translation lag", turned out to be a dead end for the student, not a delay. We can't close the
translation gap faster than students reach those steps.

**Decision.**

- **The student can open a language-locked step in the language it has** ("Watch in English").
  They choose to. Content is still never substituted without asking. Finishing the step completes
  it the usual way (ADR-011), and the next step unlocks. A language lock is never skipped, so the
  path keeps its order.
- **Status stays `locked`**, and a new `lock_reason` on `StudentPathItem` gives the reason:
  - `previous_step`: an earlier step isn't completed.
  - `language`: every earlier step is completed, but this step (its `ContentNode` or a required
    `Exercise`) has no version in the student's locale and no `any` edge.
  - When both apply, the reason is `previous_step`, because that's what the student can act on
    now. A step shows `language` only when it's the next one, at `current_position`.
  - `lock_reason` is present only when status is `locked`.
- **`available_languages` on `StudentPathItem`** lists the languages the student can open the
  step in. It's present only when `lock_reason` is `language`. It holds the `ContentNode`'s
  languages if the node lacks the locale, and otherwise the languages of the first required
  `Exercise` that lacks it.
- **Unchanged:** a completed step is never locked by language. Prerequisite locking, the `any`
  convention, and the per-entity rule from the 2026-09-18 amendment all stay as they are. Lesson
  content was never gated by the lock, so no endpoint changes access.

**Rationale.** We rejected three alternatives:

- **Keep the hard lock and only fix the message.** The student would know why they're stuck, but
  they'd still be stuck.
- **Skip the step.** That breaks the path's order and leaves a gap the student never filled.
- **Fall back silently.** The student never chose a different language, so this would break the
  guarantee the original resolution was protecting.

Opening the step by choice keeps the student moving. The lock still tells them they're leaving
their language.

**Consequences.**

- Positive: no path dead-ends on translation lag. The message on the row and in the sheet is true.
- Negative: a student can finish a step in a language they didn't pick, so a "completed" step no
  longer guarantees the content was in their locale. `StudentPathItem` gains two conditional
  fields, which every client has to handle.
- Neutral: `current_position` still points at the language-locked step, which is now correct
  because that step is the way forward.

## Related ADRs

- [ADR-011: Minimal aggregation worker](./ADR-011-minimal-aggregation-worker.md) — completing a
  step opened in another language records completion like any other step.
- [ADR-017: Student path as a copied instance](./ADR-017-student-path-copied-instance.md) — the
  derived `StudentPathItem` status that `lock_reason` qualifies.
- [ADR-005: Ent migration strategy](./ADR-005-ent-migration-strategy.md) — governs how `Language`
  and the new edges are migrated via Atlas.
- [ADR-010: Ent/Atlas migration workflow](./ADR-010-ent-atlas-migration-workflow.md) — the
  concrete workflow this decision's schema changes will follow.
- [ADR-015: Node, challenge, and path sections](./ADR-015-node-challenge-and-path-sections.md) —
  defines the `ContentNode` model this ADR extends with a `languages` edge.
- [ADR-018: Frontend UI architecture / design system](./ADR-018-frontend-ui-architecture-design-system.md)
  — establishes the Vue-only, route-level code-splitting constraints this decision follows.
- [ADR-019: Practice content model](./ADR-019-practice-content-model.md) — the `Exercise` model
  this decision's content-language filtering extends to.
- [ADR-020: Content-authoring text editor](./ADR-020-content-authoring-text-editor.md) — precedent
  for both the "no second-class framework support" reasoning and accepting a bundle-size cost for
  first-party Vue support.

---

*This ADR was decided on 2026-09-18. To revise, create a new ADR with Status: Supersedes ADR-024.*
