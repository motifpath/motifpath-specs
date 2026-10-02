# Basic guitar diagram catalog

All three catalog tiers cover 12 tonic pitch classes on standard six-string Guitar
and Electric guitar, strings numbered 1 (E4) through 6 (E2), frets 0–12. Each
musical diagram is stored once and linked to both instruments. Stored text uses `en` and
`pt_BR`; Portuguese tonic names use Dó/Ré/Mi/Fá/Sol/Lá/Si, with sustenido/bemol
where appropriate. Note tokens remain language-independent letter spellings.

Generation is deterministic, offline and validated. Production installs frozen SQL
through a separate Atlas data-migration directory after schema migrations. The
catalog migration creates a fixed `system:catalog` system profile, which owns every
basic row and cannot authenticate through Clerk. Ambiguous standard-guitar layouts
or missing offered-language translations abort installation; never invent a production
user or silently skip content. The catalog uses the accepted octave tuning, voice, mode and sequence
model. No nullable owner, catalog CRUD entity or additional MIDI field is introduced.

Names, marker notes and region descriptions are localized together. SQL includes
stable diagram/position UUIDs, canonical spelled notes and intervals, not SVGs.
Published migration files are append-only. Existing diagrams, copies, exercises and
position references are never overwritten by a regeneration or a seed run.

## Coverage

A: chromatic/root/interval maps, dyad maps, major/minor pentatonics and blues,
major/natural-minor scales, pentatonic boxes that fit inside the range, CAGED
major grips and scale/arpeggio windows, major/minor/diminished/augmented triads
and five seventh-chord arpeggio maps.

B: seven diatonic modes, harmonic/jazz melodic minor, seven 3NPS patterns for
major/harmonic/melodic minor where the complete pattern fits, ninth/eleventh/
thirteenth arpeggio maps.

C: whole-tone and both diminished scales, major/minor pentatonic substitutions
over major seventh/dominant seventh/minor seventh contexts, quartal/quintal
structures, disjoint diatonic triad pairs/hexatonics, 1-2-3-5 and 1-3-4-5 patterns.

Modes of harmonic/melodic minor beyond the current interval vocabulary are not
silently mislabeled: they require a separate contract extension. The catalog's
mode field uses an accepted diatonic enum or null, never an invented enum value.

The 12th fret is the catalog boundary: it is the octave of the open string, and
the catalog deliberately does not duplicate the same templates at higher frets.
Position IDs derive from diagram key and physical cell, not array order.
Scale windows are explicitly named windows, not claimed to be ergonomic fingerings.
Chord shapes are limited to CAGED grips and full-range arpeggio maps; there are no
three-string triad/tetrad, shell or drop-voicing templates.

Maps are silent. Playable shapes use the diagram step list and a tempo, with
quarter-note ascending runs or simultaneous chord steps. Every step refers to an
existing position. No removed `sequence_index` field may be emitted.

## Acceptance

- Every generated family covers all 12 roots; IDs and serialized output repeat exactly.
- Each coordinate sounds its note and its root-relative interval; spelling preserves
  distinctions such as F#/#4 and Gb/b5, and Bbb/bb7 in C diminished seventh.
- All names and non-null prose annotations contain complete en/pt_BR text.
- Full chromatic maps contain 78 unique cells each; pentatonic boxes contain 12;
  3NPS patterns contain 18. No coordinate lies outside the defined instrument.
- Fresh schema installs with the fixed system catalog profile and no human admin; an incompatible
  pre-existing reserved profile fails atomically.
- Repeat Atlas apply is a no-op. Colliding IDs fail; existing diagrams are preserved.
- Local demonstration seeds reuse the installed Guitar and classification nodes without
  duplicating the canonical data; demo-only shapes remain explicit.
- The generated payload passes the current Go domain constructors before release.
