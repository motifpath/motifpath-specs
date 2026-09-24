# ADR-036: Catalog data carries a name per language — starting with instruments

**Status:** Accepted
**Date:** 2026-09-24
**Deciders:** Gilson (Product Owner)
**Amends:** the `Instrument` entity of ADR-028 (`name`, one string → `names`, one name per
language), and adds an update endpoint for instrument names. ADR-033's per-language name rule for
diagrams is unchanged; this ADR generalizes it.

---

## Context

ADR-024 made MotifPath bilingual, but only for text that ships with the app: vue-i18n translates UI
strings from locale files. Text stored in the database is shown exactly as it was typed. ADR-033
already had to deal with this for diagrams, and decided `Diagram.name` becomes a map with one name
per language.

The same problem showed up in manual testing of the diagram editor: the instrument picker shows
**"Guitar"** to a Brazilian admin. `Instrument.name` is one string, in whatever language its
creator wrote it, and the seed creates it in English. It isn't a missing translation key, so no
locale file can fix it.

Instruments are not the only case. The Skill and Concept trees have the same single-string names,
and a Notion backlog item already asks for them to be localized. Difficulty levels have the same
symptom but a different shape: they are a fixed enum, not rows people create.

There are two established ways to localize database text:

- **A stable code, translated in the app's locale files.** It suits a fixed list that only changes
  with a release (enums, statuses). The database holds no display text.
- **One name per language, stored on the row**, either as a map on the row or in a separate
  translation table. It suits rows that people create while the app is running.

Instruments are the second kind: `POST /instruments` lets teachers and admins create one at any
time. There is also no way to change an instrument once it exists — the spec has no update
endpoint, because instruments were "expected to be created rarely" — so today a wrong or
untranslated name can only be fixed in the database directly.

## Decision

### The rule for catalog data

Text on database rows that people create at runtime and that is shown to users in every language —
**catalog data** — is stored as a **`names` map from `Language.code` to that language's text**, the
shape ADR-033 introduced for diagrams:

- `"any"` is never a key: a name is always words in some language.
- Responses also carry `languages`, derived from the map's keys.
- The API returns the whole map, not one resolved name. Clients pick the text: **the viewer's
  locale, then `en`, then the first name available**, so a label is never empty.
- Where a row is shared by the whole platform, a create or update must carry a name in **every**
  language of the `Language` table (except `any`); missing one is refused with 400. The check runs
  on write only: adding a language doesn't break existing rows, which fall back to `en` until their
  next update.

Fixed lists that change only with a release (such as difficulty levels) keep using a code
translated in the locale files. This ADR does not store them.

### Instruments

- `Instrument.name` is replaced by `Instrument.names` (plus `languages`). Every instrument is shared
  platform-wide, so `CreateInstrumentRequest.names` must cover every language.
- New **`PATCH /instruments/{instrument_id}`**, admin only, replaces `names`. Nothing else about an
  instrument can change: `family` and the string/key shape stay immutable, because every diagram's
  positions depend on them.
- **Migration:** each existing instrument's `name` moves into `names.en`. The migration doesn't
  invent translations, so existing rows show the English name in every locale until an admin adds
  the others through the new endpoint.
- **Seed:** `seed-full` creates its instrument with both names (`en`: "Guitar", `pt_BR`: "Violão").

### Later: Skills and Concepts

Skill and Concept names follow this rule when their backlog item is implemented. That work needs its
own spec slice, not a new decision: the only open choice there is how the tree picker edits several
names, which is a UI concern.

## Rationale

**A names map on the row** was chosen over a **code translated in the locale files** because
instruments are created at runtime. A code would need a release for every new instrument, and an
instrument a teacher creates would have no translation at all until someone edits the locale files.

It was chosen over a **separate translation table** (`instrument_id, language, name`) for
simplicity at MotifPath's size: two languages and one translatable field per row. A table earns its
cost with many languages, several translatable fields per row, or per-language search. If that
changes, moving from the map to a table is a storage change that doesn't alter the API shape.

**Returning the whole map** rather than resolving one name on the server from the request's locale
was chosen because the authoring screens need every language to edit them, and because it matches
ADR-033. Resolving on the server would hide the other languages from the editor, and would make
cached responses depend on the viewer's locale.

**Requiring every language for shared rows** follows ADR-033's rule for basic diagram templates: a
row every user sees must read natively for every user. The cost falls on whoever creates it, once,
instead of on every viewer.

**Not inventing translations in the migration** (for example, copying "Guitar" into `pt_BR`) was
chosen because a copied English word would look like a real translation and hide the gap. Falling
back to `en` shows the same text, but it stays visibly untranslated in the data.

**An update endpoint limited to names** was needed because, without one, the migration's
English-only rows could never be fixed through the API. Limiting it to admins matches who curates
platform-wide data (ADR-032's basic templates). Keeping `family` and the coordinate shape immutable
leaves ADR-028's open question about changing them after diagrams exist exactly where it was.

## Consequences

### Positive

- Instrument names read natively in every supported language.
- One pattern — the names map, the `languages` field, the fallback order and the all-languages rule
  for shared rows — now covers diagrams, instruments and, later, skills and concepts. The web needs
  one name-resolving helper and one multi-language name editor.
- An admin can fix an instrument's names through the API instead of in the database.

### Negative / Trade-offs

- **Breaking API change.** `Instrument.name` becomes `names` in responses and in
  `CreateInstrumentRequest`. The web's instrument picker and diagram editor, and the seed, must
  change together with core.
- **Creating an instrument now takes a name in every language.** A teacher who only speaks one of
  them can't create an instrument alone.
- **Existing instruments stay English-only until an admin updates them.** On a fresh database the
  seed provides both names; on an existing one, someone has to use the new endpoint.
- **The all-languages rule is checked on write only.** When a language is added, every instrument
  stays non-compliant until its next update, as ADR-033 accepted for basic templates.

### Neutral

- Teachers keep the ability to create instruments. Restricting creation to admins was considered —
  it would treat instruments as purely admin-curated — and left for a separate decision, since this
  ADR's rule works either way.
- ADR-033's names map for diagrams is not changed; this ADR only states it as the general rule.

## Related ADRs

- **ADR-024** (i18n approach): translates text that ships with the app. This ADR covers text stored
  in the database.
- **ADR-028** (Prebuilt diagram content model): defines `Instrument`, whose `name` this ADR amends.
- **ADR-033** (Diagram localization): introduced the names map, the fallback order and the
  all-languages rule for shared rows. This ADR generalizes them.
- **ADR-032** (Diagram templates and copies): the admin-curated, platform-wide basic templates
  whose rules this ADR's admin-only instrument update mirrors.

## Follow-up work (not part of this ADR)

- `motifpath-specs`:
  - `Instrument.names` and `languages` replacing `name`, in the schema and in
    `CreateInstrumentRequest`, with the all-languages rule (400).
  - `PATCH /instruments/{instrument_id}` (admin only; names only).
  - Gherkin for each of the above.
- `motifpath-core`:
  - Schema and migration (`name` → `names.en`), validation, the update endpoint.
  - `seed-full` creates the instrument with `en` and `pt_BR` names.
- `motifpath-web`:
  - A shared helper that resolves a names map (locale → `en` → first), used by the instrument
    picker and, with ADR-033, by diagram names.
  - Per-language name inputs where instruments are created, and an admin way to edit them.

---

*This ADR was decided on 2026-09-24. To revise, create a new ADR with Status: Supersedes ADR-036.*
