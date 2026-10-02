# ADR-045: Catalog guitar instrument scope

**Status:** Proposed
**Date:** 2026-10-02
**Deciders:** Gilson (Product Owner)

---

## Context

ADR-041 treats acoustic and electric guitar as two voices for one physical
six-string layout. That remains appropriate for audio playback, where a voice
changes timbre without changing a diagram's geometry.

The basic-diagram catalog is also browsed and filtered by `Instrument`. The
production data now has two independently selectable instruments: `Guitar`
(`Violão`) and `Electric guitar` (`Guitarra elétrica`). A `Diagram` has one
`instrument_id`; it cannot belong to both records. Sharing one catalog row
would therefore make one instrument's catalog incomplete, while adding a
many-to-many relationship would enlarge the content schema for this specific
catalog concern.

## Decision

MotifPath will generate an equivalent basic-diagram catalog for each of the
two existing standard-tuned six-string instrument records: Guitar and Electric
guitar. Each generated row is associated with exactly one of those records and
has a stable id derived from its instrument and musical template.

Both instruments use `E2 A2 D3 G3 B3 E4`, have the same 0–12-fret catalog
coverage, and continue to use the current acoustic-guitar default voice until
a distinct electric-guitar voice is supplied. This decision supersedes
ADR-041 only where it says that Electric guitar is not a new instrument. Its
layout-versus-voice model remains in effect for playback.

## Rationale

Duplicating the deterministic catalog rows keeps instrument filtering correct
without changing the Diagram schema or hiding catalog content behind a voice
selection. It also preserves the localised product names that users already
recognise: Guitar/Violão and Electric guitar/Guitarra elétrica.

Using one Guitar record for both would contradict the required instrument
association. A join table was rejected because the identical-geometry case
does not justify a broader authoring and API contract now.

## Consequences

### Positive

- Both instruments expose the complete basic catalog in instrument-scoped views.
- Generated diagrams retain a single, unambiguous `instrument_id`.
- The catalog remains deterministic and needs no Diagram schema migration.

### Negative / Trade-offs

- The catalog stores two rows for each shared musical template.
- A future change to shared musical content must regenerate both instrument variants.
- Electric guitar initially plays through the acoustic-guitar voice.

### Neutral

- The two records share tuning and fretboard geometry.
- A dedicated electric-guitar voice can later become the Electric guitar default
  without changing catalog diagram ownership.

## Related ADRs

- ADR-041: Diagram audio playback — clarifies the catalog-level exception to
  its voice-versus-layout example.
- ADR-044: System catalog curator — the fixed catalog profile owns both
  instrument variants.

---

*This ADR was decided on 2026-10-02. To revise, create a new ADR with Status:
Supersedes ADR-045.*
