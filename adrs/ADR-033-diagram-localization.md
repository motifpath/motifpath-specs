# ADR-033: Diagram localization — canonical interval codes displayed per locale, and per-language diagram names

**Status:** Proposed
**Date:** 2026-09-24
**Deciders:** Gilson (Product Owner)
**Amends:** ADR-028's `DiagramPosition.interval` (free text → a fixed code list) and `Diagram.name`
(one string → one name per language). Everything else in ADR-028 and ADR-032 is unchanged.

---

## Context

ADR-024 made MotifPath bilingual (English and Brazilian Portuguese). vue-i18n translates UI
strings, and a `languages` tag decides which content a student can open. Diagrams were left out of
that decision, and they are not language-neutral:

- **Interval labels are English notation stored as free text.** A position's `interval` is whatever
  string the author typed. The spec says so explicitly: "MotifPath does not validate interval names
  against a fixed enum". Seeded diagrams use `R`, `b3`, `4`, `5`, `b7`. A Brazilian student expects
  `T` (tônica) for the root and the traditional qualities `3m`, `4J`, `5J`, `7m`. Because the
  stored value is free text, nothing can reliably tell that an `R` means the root, so nothing can
  translate it.
- **A diagram's name is a single string** in whatever language its author wrote it in. A Brazilian
  teacher browsing the selector sees "A Minor Pentatonic — Position 1".
- **Basic templates (ADR-032) are shared across the whole platform**, so they must work in every
  language MotifPath offers. A teacher's custom diagram only needs to work in the language(s) that
  teacher teaches in.

Note names are not a problem. Brazilian guitarists overwhelmingly read letter names (C, D, E), which
are the same in both languages. The product owner decided pt-BR keeps letters rather than switching
to solfège (Dó, Ré, Mi).

## Decision

### Interval: a fixed list of canonical codes, displayed per locale

`DiagramPosition.interval` becomes an enum of canonical codes:

`R`, `b2`, `2`, `#2`, `b3`, `3`, `4`, `#4`, `b5`, `5`, `#5`, `b6`, `6`, `bb7`, `b7`, `7`, `b9`,
`9`, `#9`, `11`, `#11`, `b13`, `13`

The code is a storage identifier, not display text. `motifpath-web` renders it through vue-i18n,
with one translation key per code and ADR-024's key-parity test guaranteeing every code has a
label in every locale:

| Code | en | pt-BR | | Code | en | pt-BR |
|---|---|---|---|---|---|---|
| `R` | R | T | | `b6` | b6 | 6m |
| `b2` | b2 | 2m | | `6` | 6 | 6M |
| `2` | 2 | 2M | | `bb7` | bb7 | 7dim |
| `#2` | #2 | 2aum | | `b7` | b7 | 7m |
| `b3` | b3 | 3m | | `7` | 7 | 7M |
| `3` | 3 | 3M | | `b9` | b9 | 9m |
| `4` | 4 | 4J | | `9` | 9 | 9M |
| `#4` | #4 | 4aum | | `#9` | #9 | 9aum |
| `b5` | b5 | 5dim | | `11` | 11 | 11J |
| `5` | 5 | 5J | | `#11` | #11 | 11aum |
| `#5` | #5 | 5aum | | `b13` | b13 | 13m |
| | | | | `13` | 13 | 13M |

Enharmonic codes stay distinct (`#4` vs `b5`, `#5` vs `b6`) because the author's spelling carries
musical meaning. The editor's interval field becomes a picker over this list instead of a free-text
input.

`DiagramPosition.note_name` stays letter notation in every locale and gains validation to match
it: `^[A-G](bb|b|##|#)?$`. A keyboard position's `key` (e.g. `C4`) is unchanged.

Every diagram's labels are therefore displayable in every language automatically. A diagram's
language support is decided only by its name.

### Name: one per language; basic templates need every language

`Diagram.name` (a string) is replaced by `Diagram.names`, a map from `Language.code` to that
language's name (for example `{"en": "A Minor Pentatonic — Position 1", "pt_BR": "Pentatônica
menor de Lá — Posição 1"}`). `"any"` is not a valid key, because a name is always words. The
response also carries `languages`, derived from the map's keys, like `ContentNode.languages`.

- **basic** diagrams must carry a name for every language in the `Language` table (except `any`).
  A create or update missing one is refused with 400.
- **custom** diagrams must carry at least one name.

`motifpath-web` shows the name for the viewer's locale, falling back to `en`, then to the first
available name. **Save as** (ADR-032) asks for the new diagram's name in the caller's locale. The
source's names in other languages are not carried over, since they would describe the source
rather than the copy. The author can add more names before saving. **Save as template** requires
all languages, as above.

`GET /diagrams` gains a `language` filter (diagrams with a name in that language). When a teacher
embeds a diagram into a content node, the selector pre-filters to the node's languages.

## Rationale

**Canonical codes plus locale-rendered labels** was chosen over storing a label per language on
every position (`{en: "R", pt_BR: "T"}`). Interval notation is a closed, well-known set whose
translation is a property of the language, not of the diagram. Storing it per position would ask
every author to retype the same translations, invite inconsistency (one diagram with `3m`, another
with `b3` in Portuguese), and still leave no way to query "every diagram that marks a minor third".
A fixed list makes intervals queryable and makes a new locale a translation-file change, the same
way ADR-024 treats UI strings.

**Keeping `R` (not `1`) as the root's code** was chosen because every existing position already
uses it. Adopting the list needs no data migration, only validation.

**Traditional Brazilian qualities (`3m`, `5J`, `7m`)** rather than keeping the symbols (`b3`, `5`,
`b7`) with only the root renamed was the product owner's call. It is the notation Brazilian music
education teaches, and it reads as native rather than half-translated.

**A per-language name map** was chosen over tagging the single existing name with a language (the
`ContentNode.languages` approach). A basic template is one diagram that must present itself in
every language. Tagging would force one copy of the same positions per language, and every
correction would have to be made in every copy. `ContentNode` is tagged because its body is
language-specific. A diagram's body (its positions) is not, only its name is.

## Consequences

### Positive

- Every diagram's labels display natively in every supported language, with no per-diagram work.
- Interval data becomes queryable and consistent, so there are no free-text variants like `m3`,
  `min3` or `♭3`.
- Basic templates are guaranteed bilingual. Teachers' custom diagrams stay low-effort, with one
  name.
- Adding a language only means adding interval labels to a locale file and names to basic
  templates. No schema change is needed.

### Negative / Trade-offs

- **Breaking API change.** `Diagram.name` becomes `names`, and `interval`/`note_name` become
  validated. Every client and the seed must move together.
- **Intervals outside the list can't be expressed.** Examples are `#13`, `b11` and compound labels
  like `R/8`. Adding one is a spec change plus a translation per locale.
- **Adding a language makes every basic template non-compliant**, because the "all languages" rule
  is checked on write only. Existing basics keep working, falling back to `en`, but the next
  update of each must add the missing name.
- **Language compatibility of an embedded diagram is enforced only by the selector's pre-filter.**
  The server doesn't validate that a diagram embedded in a `pt_BR` content node has a `pt_BR`
  name. A diagram can still be embedded through the API, or keep an embedding after a node gains a
  language.

### Neutral

- Note names stay letters in every locale. Solfège display (per locale or per user) remains
  possible later, because `note_name` is now a validated letter form that can be mapped
  deterministically.
- The per-language name map is new to this spec. PB-66 (localizing Skill, Concept and difficulty
  level names) is expected to reuse the same shape.

## Related ADRs

- **ADR-024** (i18n approach): vue-i18n and the key-parity test render the interval labels. This
  ADR extends ADR-024 to diagram data.
- **ADR-028** (Prebuilt diagram content model): amended as described above.
- **ADR-032** (Diagram templates and copies): defines basic and custom, which this ADR's
  language requirements hang on, and Save as, whose naming step this ADR specifies.

## Follow-up work (not part of this ADR)

- `motifpath-specs`:
  - The `interval` enum and `note_name` pattern.
  - `names` and `languages` replacing `name`, the basic/custom language rules (400), and the
    `language` filter on `GET /diagrams`.
  - Gherkin for each of the above.
- `motifpath-core`:
  - Migrate `name` into `names` (existing rows → `en`, plus the `pt_BR` names the seed must
    supply for basics), and add validation.
- `motifpath-web`:
  - Interval label keys (en/pt-BR) and the interval picker in the editor.
  - Per-language name inputs, the Save as naming step, locale-resolved names, and the selector's
    language pre-filter.

---

*This ADR was decided on 2026-09-24. To revise, create a new ADR with Status: Supersedes ADR-033.*
