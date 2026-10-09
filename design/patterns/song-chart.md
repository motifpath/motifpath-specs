# Pattern: song chart

**Source:** ADR-049 §1, §4 and §6 · ADR-050 §3–§4 (song charts, as amended) · MOT-73 (Figma "Song
charts", rows 1–6; decisions D1–D13, approved 2026-10-09, D2 revised by the PO) · reuses MOT-55
(chord card, song chart practice) and MOT-61 (authoring)

## When

Use it whenever a song chart is read, shown in content or authored:

- the **reader** (a chart opened from a link, from a lesson card, or as an admin preview);
- the **SongChartCard** wherever content shows a chart (lesson articles and video cues);
- **admin authoring** in Teach (list, editor, ChordPro, rights, publish and withdraw);
- the **teacher picker** that embeds a published chart in a lesson.

Song chart *practice* (a song as a practice item, MOT-76) runs in the Practice Shell
(`session.md`, `self-rating.md`) and shares the chart, the chord card and the metronome with the
reader.

## Why

A student playing from a chart has the instrument in their hands. The chart must stay first, a chord
must be one tap away without losing the place, and a beginner must be able to slow the song down.
Admins bring charts in and clear their rights, so the editor has to make chord mistakes and missing
rights obvious before anything reaches learners.

## How

### The reader (rows 1–2)

- **A full-screen layer**, not an App Shell page: × only, no app bar or navigation. × goes back to
  where the chart was opened (a lesson at the same moment, practice home, the editor for a preview);
  a chart opened directly goes home. On scroll the title moves into the bar.
- **Header:** title, artist, then chips for key, capo, meter and tempo ("Key G · No capo · 3/4 ·
  72 BPM").
- **Chords in this song (D1):** the song's chords as chord boxes under the header; tapping one opens
  the chord card. The strip scrolls away with the header.
- **Chart:** labelled sections (`VERSE 1`, or the kind when there's no label) and chords over the
  words they fall on. A long line wraps at word boundaries and every chord stays over its word.
  "N.C." is plain text, not tappable.
- **Chords:** tapping a chord highlights it and opens the floating chord card on the author's voicing
  (`chord-card.md`). A slash chord the catalog lacks opens the chord without its bass, with the note
  "Shows C — the bass note B isn't shown" (1e).
- **Tempo and metronome (D2):** a practice aid, never tracking. The metronome button in the reader
  bar opens the tempo control (`TempoControl`, as in play-along). The song's tempo is the target tick;
  the student starts slower and works up to it ("Song tempo 72 BPM · you're at 56"). The chosen tempo
  is remembered per song on the device and nothing is sent. A chart without a tempo starts at 80 BPM
  with no target tick.
- **I played it (D3):** the primary action. After the tap it becomes a quiet "Played ✓" with a
  success toast; tapping again sends nothing; a new opening starts fresh.
- **Admin preview (D4):** the same reader under an amber "Preview of the draft · nothing is recorded"
  banner; nothing is sent.
- **States:** loading shows the shell and skeleton lines; a chart that can't be read says "This song
  chart isn't available" without a reason (withdrawn, never published or missing) and offers Go home;
  a load error offers Try again.

### Size classes (D5)

| Size class | Chart | Chord card | Metronome |
|---|---|---|---|
| Compact | full width | floats over the chart | tempo bar docked above the action bar |
| Medium | one 560 px column | floats in the free margin | tempo bar at the bottom, aligned to the column |
| Expanded | 560 px column + a 400 px side pane | docked in the pane | top of the pane, under its bar button; keys M (on/off) and − / + |

On Expanded the pane holds, top to bottom, the metronome, the chords in this song and the chord card.
It opens on the first chord tap or when the metronome is turned on; × collapses it and the chart
re-centres. The action bar never moves: "I played it" stays at the bottom, aligned to the column.

### The SongChartCard (D13)

- One shared component for every place content shows a chart: music icon, title, artist · key, the
  first line with its chords over the words, a chevron. The whole card is the tap target.
- Tapping it opens the reader as a layer; in a video lesson the video pauses and resumes at the same
  moment when the reader closes (`lesson.md`).
- Showing a card sends nothing. A chart withdrawn since it was embedded shows no card at all.

### Admin authoring (rows 3–5)

Admins only, in Teach under Admin → Song charts, following `authoring.md`.

- **List:** the authoring list pattern — status chips (All · Drafts · Published · Withdrawn), search by
  title or artist, `AuthoringRow`s with artist · language · revision and a status chip; a search with
  no match says so, with Clear search.
- **Editor layout (D6):** the course-editor layout. Left: details (title, artist, language, key, capo,
  meter, tempo) and one lyrics-and-chords editor (sections with a kind menu and a label, comments,
  chords over words). Right, 320 px: status with Publish / Withdraw…, rights, Preview as a learner,
  revisions (newest first, who and when) and ChordPro import/export.
- **Writing a chord (D7):** select a word or a syllable, then Chord (or type `[`). A popover at the
  selection checks the symbol as it is typed (the server's parser) and offers the voicing learners see
  first as chord-box thumbnails named by position; no pick means the best voicing. It flips above the
  selection when there is no room below.
- **Chord problems (D8):** not a chord = red dashed; not in the catalog = amber dashed; the reason sits
  under the line. The status panel lists every blocker (rights, each chord with its section and line)
  and Publish stays disabled until there are none.
- **Rights and withdrawal (D9):** rights are a checkbox card showing who confirmed them and when.
  Withdraw… opens a dialog (a sheet on Compact) that says what learners lose and requires a reason; a
  withdrawn chart shows who, when and why, with Publish again.
- **ChordPro (D10):** Import opens a dialog — Paste text | Choose a file. Directives fill the details;
  details the text doesn't set keep what the author wrote; skipped lines are listed in the editor with
  their line number; importing over lyrics asks first. Nothing is saved until Save. Export downloads
  the `.cho`.
- **On Compact (D11):** the maintenance tier — status, Publish, Withdraw…, details and rights work; the
  lyrics show as learners see them, with the "larger screen" `InlineNotice` for placing chords.

### Teachers embed a chart (row 6, D12)

- In an **article lesson's** editor, Insert → Song chart ("A published song chart") opens the one
  picker: a full-screen layer on Compact, the 1040 px two-pane dialog on Expanded with the selected
  chart's card and opening lines on the right.
- The picker lists only published charts by title, artist, key and language, with search.
- The inserted chart shows as the SongChartCard; selected, it offers Replace and Remove.
- A whole chart is embedded, never a section. The exercise prompt editor never offers Song chart.

## Do not

- Open a chord in a dialog or a sheet, or block scrolling while the chord card is open.
- Send any event from the metronome or the tempo, from an admin preview, or for showing a card.
- Say why a chart isn't available.
- Show a chart's draft, or a withdrawn chart, to learners or in the teacher picker.
- Publish while a chord or the rights block it, or hide why Publish is disabled.
- Use licensed lyrics in designs, stories or tests.

## Spec changes this needs

- **D1:** `song_chart.chord_viewed` gets an optional anchor and a `source` (`lyrics` | `strip`) so a
  tap in the chord strip is counted (`openapi/components/schemas/events.yaml`,
  `features/event-ingestion/ingest-song-chart-event.feature`, `features/web/song-chart-reader.feature`).
- **D2:** `features/web/song-chart-reader.feature` gains a metronome rule (target = the chart's
  tempo, default 80, remembered per song on the device, nothing sent).
- **D8:** in `features/web/song-chart-authoring.feature`, "Publishing a draft that isn't ready lists
  every reason" becomes: the status lists every reason and Publish waits until there are none.
- No core or OpenAPI change beyond D1.
