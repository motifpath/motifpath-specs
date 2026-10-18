# Content presentation proposal

**Status: proposed editorial standard, not an architecture decision or approved release.**
Use the content packet as the source of truth for a learning unit. Deliver the learner
experience through supported native article/video, exercises, diagrams and practice items.
Keep Google Slides optional for storyboarding, recording support and collaborative review.

## Editable template

Use [the presentation deck](../assets/content-presentation-template.pptx).
It contains author guidance and a production brief, six reusable learning layouts
(payoff, method, demonstration, attempt, feedback, application), a native-delivery
handoff and a PDCA review page. Every placeholder is intentional and editable.
Duplicate only the layouts the unit needs. Remove the author pages before learner delivery.
The deck is in English as an authoring template; replace learner-facing placeholders
with copy in the unit's declared locale. It contains no working exercise or grading engine.

## Presentation grammar

Lead with the musical payoff, give the complete method, demonstrate, invite an attempt,
provide correction and apply. One main message per frame; use a meaningful title, dominant
musical/audio/visual example and short action prompt. Put production instructions and source
citations in notes, but keep all essential learner instructions in the delivered experience.
Use the current MotifPath brand tokens/assets when producing visuals; avoid inventing a new
brand system. Phone reading must be checked separately from a widescreen storyboard.

Reusable frame specification:

- Frame key and learning beat from the content packet.
- Target-language title, short body and exact narration/caption text.
- Main image/diagram or audio cue, with annotations and accessible description.
- Student prompt and practical benefit.
- Native destination: article section/video timestamp plus linked exercise/diagram/item.
- Correct response/rubric, rationale, feedback and retry (editorial notes, native behavior).
- Asset references/rights and reviewer notes.

Use as many frames as the outcome needs. Avoid decorative title/agenda/outro sequences that
consume time without helping the learner act. Do not shrink notation to fit a slide.

## Google Slides assessment

| Criterion | Google Slides storyboard | Native MotifPath delivery |
|---|---|---|
| Shared visual review | Useful for an optional editorial review deck | Review the actual learner flow before release |
| Linear explanation/recording | Useful support for a demonstration | Article/video as specified by current content contracts |
| Region selection, answer validation, retry | A drawing or link is only a storyboard of the interaction | Use the supported exercise/diagram/practice interaction |
| Practice evidence and knowledge state | Deck viewing is not practice evidence | Use the appropriate specified native item/events |
| Mobile learning | Widescreen layout needs a separate phone review | Verify the actual native screen and controls |
| Version/access boundary | Published Slides can update from edits and expose material under Google sharing settings | Verify native publication, references and access rules separately |

Google documents Slides publishing as a view-only presentation with timed advance and an
embed option. Publishing permissions depend on account settings; automatic updates cannot be
turned off for Slides. These are presentation/distribution features, not evidence that MotifPath
can ingest the deck or grade its interactions:
[Google Docs Editors Help — publish and embed](https://support.google.com/docs/answer/183965?hl=en)
(checked 2026-10-18).

Recommendation: trial Slides with one already-approved content packet if collaborators need
visual review. Compare editing effort, reference fidelity and readability with the native
article-first workflow. Keep the packet and asset inventory portable; no Slides dependency
is required to author a unit. Do not build an embed/import pipeline or publish a Google file
as part of this proposal. A native integration would require its own spec and readiness checks.

## Handoff boundary

A slide labelled “tap the third” does not implement tappable regions, response capture,
feedback or grading. Record the exact native contract and readiness evidence in the packet.
If no supported mapping exists, track a capability gap and use a clearly described honest
alternative where it preserves the outcome; otherwise block delivery of that interaction.
Curriculum `intent` fields such as `ends_with` and `assumes` remain editorial where the app
has no matching field (see `curriculum/README.md`). Never invent a content type to carry them.
