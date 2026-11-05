# First notes: full lesson drafts

MOT-160 · phase Do · version 1 · 2026-11-03 · ready for human review.

The PO accepted the visual draft direction and authorized these two complete pt_BR article
drafts. They preserve the approved universal scope and separate application openings.

- [Offline visual reader](preview.html): both full lessons, eight visible diagrams, nine
  primary practice questions with hints/feedback and nine follow-ups. Download/open locally;
  GitHub's source view does not render it. The reader saves/submits no answers.
- [Lesson A](lesson-a.pt-BR.md): names, letters, octave references and a short study phrase.
- [Lesson B](lesson-b.pt-BR.md): count tone/semitone steps and apply them to C major.
- [Production packet](production-packet.md): classification, evidence boundaries, native
  resource map, references/rights and remaining review gates.
- [Reusable activity metadata](activities.json) and [asset manifest](assets/manifest.json).

## Review handoff

MOT-161 is in progress. The [review record](review.md) contains the AI editorial
findings, proposed corrections and the educator/pt_BR/learner review protocol.

## Rebuild and check

Use the repository's locked development dependencies (`npm ci`), which include the Markdown
renderer used by the docs tooling. From the repository root:

```bash
node curriculum/content/first-notes/tools/build-preview.mjs
node curriculum/content/first-notes/tools/validate.mjs
```

The builder regenerates diagrams, expands activity markers in the Markdown and embeds the
articles, SVGs and fonts into one offline HTML file. Rebuilding is deterministic; edit activity
prompts/answers in `activities.json`, since the marked inclusion blocks are regenerated.
The validator checks classification, questions/retries, musical distances, fret coordinates,
local links, accessible diagram metadata and offline preview structure. It does not replace
a human music/locale review or verify the running MotifPath application.

No audio generation, deployment, app installation or publication is included. The prior
18-slide [review checkpoint](../../pilots/first-notes-review/README.md) remains the approved
sequence reference; historical production at `98905d4` remains superseded.
