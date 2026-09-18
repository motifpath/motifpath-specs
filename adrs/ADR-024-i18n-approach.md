# ADR-024: Internationalization approach — vue-i18n, locale preference, and content-language modeling

**Status:** Proposed
**Date:** 2026-09-18
**Deciders:** Gilson (Product Owner)

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

## Open Question — Not Resolved by This ADR

**Fallback behavior when a student's locale has no matching content for a given node or path
item** is a product policy decision, not a technical one, and is explicitly out of scope here.
Options include (non-exhaustively) silently substituting the other available language, skipping
or locking that node/path item until a translation exists, or surfacing it to the student as
"available in English only" with an explicit opt-in. This must be decided — likely via a
follow-up spec or a product-discovery pass — before the content-filtering read path
(part 3 of this decision) is implemented, since it changes what that query actually returns.

## Related ADRs

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
