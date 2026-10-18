# MotifPath presentation library

Use [the editable deck](../assets/content-presentation-template.pptx) as a library,
not a 47-slide sequence to show every learner. The matching
[PowerPoint template](../assets/content-presentation-template.potx) opens a new
presentation in applications that support POTX. In Google Slides, import the PPTX.

## Choose the right pages

| Pages | Purpose |
|---|---|
| 1–5 | Author orientation, palette, typography and production approach |
| 6–14 | Covers, section divider, outcome, prerequisites, explanation, emphasis, comparison and method |
| 15–18 | Annotated image, image with explanation, audio and video |
| 19–24 | Editable fretboard, chord, rhythm count grid, tablature, progression and form |
| 25–31 | Practice prompt, question, listening comparison, feedback, correction, practice loop and plan |
| 32–36 | Application, reflection, summary, next practice and references |
| 37–41 | Asset/accessibility inventory, production brief, editorial review, PDCA and reusable resources |
| 42–47 | Filled pt_BR example: alternate picking on an open string |

Duplicate only the useful pages. Delete unused layouts, author guidance and the
sample lesson before delivery. Bracketed text is a replacement prompt. The examples
show visual treatment and require musical/editorial review before teaching.
Six native title/body layouts are also supplied, but duplicating a finished library
slide is the most direct way to retain its complete composition and diagrams.

## Visual standard

Source: `motifpath-brand/tokens.json` and `BRAND.md`, inspected 2026-10-18.
Use indigo `#05072C`, violet `#6D28E0`, lilac `#C97CFF`, cream `#FBFAFF`
and ink `#1A1633`. Light, dark and violet slides form one visual family.
Use the original brand mark without recoloring, stretching or adding effects.
The violet variant uses the text name to preserve contrast.

Manrope is the project font. Install the supplied regular, medium, semibold and bold
TTF files before editing locally. The fonts are not embedded in the presentation.
They originate from the project's `@fontsource/manrope` assets and are distributed
with their SIL Open Font License. Google Slides may need Manrope selected manually.
Substitution can change wrapping; inspect the actual application after import.

The canvas is 16:9, 1280 × 720. Keep a 64-pixel outer margin. Headings generally use
48–80 pixels (36–60 points), body text 27–37 pixels (20–28 points). Keep guidance
in speaker notes rather than learner copy. Use fewer words or another slide before
shrinking notation or explanations. Replace the generic image frames with actual
media, preserving aspect ratio. Keep captions, transcripts, alternate tasks and
source/rights evidence in the production packet.

## Music and media

Music diagrams, count markers, labels and tables are native editable objects.
The fretboard example shows A minor pentatonic at frets 5–9 with high e at the top.
The chord example is E minor in standard guitar tuning. The rhythm slide is a count
grid, not conventional staff notation. Check tuning, string direction, fret labels,
intervals and fingerings whenever adapting these examples. Count words and musical
notation follow the unit's locale.

The ribbon and electric-guitar artwork are generated illustrations used for visual
support. They are not documentary photographs or evidence of correct technique.
Use real reviewed demonstrations when hand position, instrument detail or movement
is the teaching subject. The template contains no embedded audio/video playback,
automated grading, response capture or live practice instrumentation.

## Artwork provenance

`artwork/violet-ribbon.png` and `artwork/electric-guitar.png` were created with
OpenAI's built-in image-generation tool on 2026-10-18. Prompts are recorded in
`artwork/provenance.json`. The original MotifPath mark comes from the brand repository.
[SlidesCarnival's music library](https://www.slidescarnival.com/tag/music), accessed
2026-10-18, served as a breadth-of-library reference. No template or artwork was copied.

## Delivery check

Review every slide at presentation size. Check the destination device, media links,
phone readability, notation, translation, image rights, references and installed
classification before release. Remove answer leakage in listening questions.
The filled example is a visual sample, not a complete approved production packet.

The exported PPTX passed structural, layout/font and first-party re-import checks
and every slide was rendered and inspected. These checks do not establish native
PowerPoint or Google Slides compatibility. Import, edit, save and present a copy in
the selected application before making this the shared production baseline.
