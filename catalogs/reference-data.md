# Platform reference data

Rows MotifPath installs in every environment, production included, before any user exists:
languages, voices, instruments, the system catalog profile, the knowledge map
(`knowledge-map.md`) and the basic guitar diagram catalog (`basic-guitar-diagrams.md`).
None of them is seed data.

## Fixed IDs

**Every pre-loaded row has the same ID in every environment** (dev, staging, production), so
an ID in a log, a bug report or a query means the same thing everywhere, and migration
scripts can refer to rows by ID instead of looking them up by name.

- An ID is never random. It is a UUID v5 under the MotifPath catalog namespace
  `4ac75155-7804-5527-a6ba-01b73c0e3e1a`, built from the row's type and stable key:

  | Rows | Name hashed |
  |---|---|
  | Language | `language/<code>` |
  | Instrument | `instrument/<key>` |
  | Knowledge node | `knowledge-node/<key>` |
  | Knowledge edge | `knowledge-edge/<type>/<from key>/<to key>` |
  | Basic diagram, position | the diagram catalog's keys, as `basic-guitar-diagrams.md` defines |

- Voices use their slug as ID (`acoustic-guitar`), which is already fixed.
- Keys never change, so neither do IDs. Renaming a row changes its names, never its ID.
- Rows created later through the API (a node an admin adds, user content) get ordinary
  random IDs. Only pre-loaded rows are fixed.
- The generated migrations write every ID literally, next to its key, so an ID can be found
  by searching the migration files.

## Install order

All of these install from migrations that run after the schema, in this order. Seeds run only
after every migration and never create any of these rows.

1. Languages
2. Voices
3. Instruments
4. The system catalog profile
5. The knowledge map
6. The basic guitar diagram catalog

Until production exists, these migrations are regenerated in place and development databases
are recreated from empty. From the first production install, they are append-only.

## Languages

| Code | Name | ID |
|---|---|---|
| `en` | English | `5a118a9d-1ed7-57d5-b607-395681a862e1` |
| `pt_BR` | Portuguese (Brazil) | `802e1939-95ed-5d17-8b2a-e5dddfe60853` |
| `any` | Language-agnostic | `7d7dda1c-f802-50fd-a30e-45f605fc71b0` |

## Voices

| ID | Family | Names (en / pt_BR) | Samples |
|---|---|---|---|
| `acoustic-guitar` | fretted | Acoustic guitar / Violão | tonejs-instruments acoustic guitar, CC BY 3.0 |
| `electric-bass` | fretted | Electric bass / Contrabaixo elétrico | tonejs-instruments electric bass, CC BY 3.0. Covers at least E1–G4, the 4-string bass's range |
| `piano` | keyboard | Piano / Piano | tonejs-instruments piano, CC BY 3.0 |

Each voice carries the credit its license requires: "\<Instrument> samples from
tonejs-instruments by Nicholaus Brosowsky, CC BY 3.0".

## Instruments

| Key | Names (en / pt_BR) | Strings and tuning | Default voice | ID |
|---|---|---|---|---|
| `guitar` | Acoustic guitar / Violão | 6: E2 A2 D3 G3 B3 E4 | `acoustic-guitar` | `6ea2d087-ab9c-59dc-9657-8546025414d2` |
| `electric-guitar` | Electric guitar / Guitarra elétrica | 6: E2 A2 D3 G3 B3 E4 | `acoustic-guitar` | `e6fac4f3-7d52-5f46-8f44-4de1b239ebdd` |
| `electric-bass` | Electric bass / Contrabaixo elétrico | 4: E1 A1 D2 G2 | `electric-bass` | `14fe11ad-efdb-589a-b713-2e81ec041cbe` |

- `guitar` keeps its key, and therefore its ID, after its English name changes from "Guitar"
  to "Acoustic guitar".
- Its pt_BR name stays "Violão". It covers the steel-string acoustic and the nylon-string violão.

## System catalog profile

The `system:catalog` admin profile that owns every basic diagram keeps the fixed ID
`77d0239a-8d28-5c95-bc6e-53d59f7f84a8`, as `basic-guitar-diagrams.md` defines. It cannot
authenticate.

## Acceptance

- Migrating an empty database twice, in two environments, yields identical IDs for every row
  listed here and in the catalogs.
- No reference-data migration calls a random ID generator.
- Installing aborts if a row with the fixed ID already exists with different data.
