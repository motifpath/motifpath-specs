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
(`Violão`) and `Electric guitar` (`Guitarra elétrica`). Their standard tuning
and fretboard geometry are identical, so duplicating each musical diagram
would create two mutable copies of the same content.

## Decision

MotifPath will store each basic musical diagram once. Its existing
`instrument_id` remains the immutable layout instrument that defines position
coordinates and the fallback playback voice. A new `diagram_instruments` join
links it to every instrument for which that layout is valid. The catalog links
every basic guitar diagram to both Guitar and Electric guitar.

Every linked instrument must have the same coordinate geometry as the layout
instrument: family, and for fretted instruments, string count and tuning (or
the equivalent keyboard range). Both catalog instruments use `E2 A2 D3 G3 B3
E4`, have the same 0–12-fret coverage, and retain the current acoustic-guitar
fallback voice until a distinct electric-guitar voice is supplied.

## Rationale

The join keeps instrument filtering correct without copying the content or
hiding availability behind a voice selection. It preserves the localised
product names that users already recognise: Guitar/Violão and Electric
guitar/Guitarra elétrica.

Using only one Guitar record would contradict the required instrument
association. Duplicating diagrams was rejected because corrections and
translations could diverge between two rows that represent the same pattern.

## Consequences

### Positive

- Both instruments expose the complete basic catalog in instrument-scoped views.
- A correction or translation changes one diagram, for both instruments.
- The catalog remains deterministic and records compatible instruments explicitly.

### Negative / Trade-offs

- The additional join table and compatibility checks add persistence complexity.
- An incompatible layout cannot share a diagram even when its musical idea is similar.
- Electric guitar initially plays through the acoustic-guitar fallback voice.

### Neutral

- The two records share tuning and fretboard geometry.
- A dedicated electric-guitar voice can later become the Electric guitar default
  without changing catalog diagram ownership or associations.

## Related ADRs

- ADR-041: Diagram audio playback — clarifies the catalog-level exception to
  its voice-versus-layout example.
- ADR-044: System catalog curator — the fixed catalog profile owns both
  instrument variants.

---

*This ADR was decided on 2026-10-02. To revise, create a new ADR with Status:
Supersedes ADR-045.*
