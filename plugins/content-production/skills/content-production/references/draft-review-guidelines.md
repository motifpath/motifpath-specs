# Draft review guidelines

These editorial requirements capture the MOT-160 review decisions from 2026-11-02.
They are authoring decisions, not measured evidence of learner improvement.

## Make the draft reviewable before full production

Review the syllabus, content transitions, proposed visuals and supporting resources together.
Provide a short visual draft with the proposed diagrams actually visible, preferably as
preliminary slides. A list of diagram names or a prose production packet alone is insufficient
for this review. Keep the complete method in scope, but review the direction before expanding
into whole lessons or final media. Feedback on a draft does not authorize publication.

Keep review artifacts separate from working native interactions. A diagram, question,
feedback state or playback proposal in a slide does not establish runtime support.
Do not generate audio unless the user explicitly requests it. Prefer supported MotifPath
diagram playback when it serves the outcome, and verify it before claiming it works.

## Start each lesson with its application

Every lesson, including the most basic, starts with a learner-facing application summary
before explanation or exercises. In a slide-based draft, give each lesson its own dedicated
opening application slide. A course cover, syllabus, subtitle or closing summary cannot
replace it. For other formats, use a clearly separate opening section.

Explain both:
- **Learner goal:** a musical result the learner already wants and can picture reaching,
  such as playing songs with other people, following chord charts or improvising. The
  opening should make the learner think “I need this”.
- **First step:** how today's content moves the learner toward that goal, and which later
  subjects it supports on the way.

Anchor the opening in the goal, not in an intermediate skill or a technical instruction.
Learners rarely want scales for their own sake; they want to improvise, and scales are a
step on that path. A literal instruction the lesson teaches to decode is evidence of use,
not a goal. Keep the claim honest: show the step, not the arrival.

## Close with the goal

The success check mirrors the opening. Name what the learner can now do, return to the
goal from the opening and recognize the step just taken on the way to becoming a musician.
Keep the limits of the evidence explicit: a completed lesson is progress, not mastery.

## Title lessons so learners open them

Learners decide whether to skip a lesson from its title. A topic label can read as trivial
or already known. Name the payoff or a puzzle the lesson resolves, in idiomatic locale
language, and promise only what the lesson delivers.

Use later topics to explain relevance without requiring their mastery or teaching them all
in this lesson. Avoid vague claims such as “this will be important later.” Do not withhold
today's useful result to motivate a future lesson.

## Review cohesion across the sequence

State the syllabus and observable outcome of each lesson. Check what the learner knows
at each transition, the question that motivates the next concept, and how the next example
reuses earlier work. Introduce new notation when it becomes useful, with enough explanation
for the next action. Identify jumps, repetition and missing bridges explicitly. For each teaching step,
trace prior knowledge, the new idea, the next learner action and the evidence it
provides for the outcome. State any support used in the action.

For the pilot, naming a note precedes measuring the distance to the next note. The question
“Are Mi–Fá and Dó–Ré the same distance?” motivates counting all keys, including black keys.
This is an example of a bridge, not a required sequence for unrelated topics.

## Give visible diagrams meaningful names and context

Keep production IDs such as D1–D5 in editorial metadata. Learner-facing titles identify
what the diagram teaches, such as “Names on the keyboard” or “Distances on the E string.”

A fretted-instrument diagram must make the instrument and highlighted string recognizable:
- Show the fretboard with the instrument's strings, rather than an unexplained isolated line.
- Label the instrument, tuning, viewing orientation, string names/direction, nut, open-string
  position and fret numbers as needed to interpret the example.
- Highlight the relevant string with text and a visual distinction, not color alone.
- Place stopped-note markers between fret wires. Distinguish the open-string marker and
  clarify whether displayed positions are alternatives or simultaneous notes.
- Show the movement and count when teaching distance: E to F is one semitone; F through F♯
  to G is two semitones on the same string. Do not confuse fret number with finger number.
- Keep guitar and bass examples separate, with accurate registers (E2 versus E1 in the
  standard-tuning pilot examples). Universal theory can use keyboard, bass and guitar
  examples without turning the whole lesson into an instrument-specific unit.

Review labels and diagrams at presentation size for collisions, legibility and musical
accuracy. Provide a useful text description or equivalent activity for each diagram.

## Name practice activities in learner language

Use direct labels appropriate to the locale, such as “Prática”, “Sua vez” and “Pratique de
novo” in pt_BR. Do not expose “Tentativa A/B” as unexplained editorial terminology.
Explain what the learner does, why it helps, what reference is available, and how to check
the answer. Distinguish the prompt, optional hint, feedback/rationale and a follow-up question.
A static review slide may show these states together for editorial review; learner delivery
must respect the intended timing and supported interaction.

For each assessed outcome, identify a likely mistake and give feedback the learner can
act on. Provide a fresh example to check the same reasoning after correction. Label
guided practice, retries and application in the editorial packet. For example, if the
learner counts both notes in Mi–Fá, explain how to count the move between them and ask
them to apply the rule to Si–Dó.

During planning, record the native feature and verification level for each essential
diagram, prompt and feedback step. Provide a fallback that preserves the outcome or
flag the gap for resolution.

## Map complementary resources precisely

Include internal MotifPath content and suitable external references when they support the
outcome. For each, record:

| Resource and exact section | When to use it | Learning purpose | Language, access and availability | Local bridge or alternative | Source/rights |
|---|---|---|---|---|---|
| Verified title, course/path/unit key and URL when known | Before, during or after a named step | What it adds | Planned/idea/published evidence, permissions and runtime limits | Keep essential understanding reachable | Link or reuse with documented permission |

A curriculum key or source-code link identifies an editorial plan, not an installed course.
Mark planned or idea-stage resources honestly. Do not invent course URLs, installed IDs,
access rights or keyboard courses absent from the inspected sources. Distinguish verified
page text from untested playback or interactions. Keep essential material inline if a
reference is unavailable. Record rights and accessible alternatives before asset reuse.

## Review checklist

Use the exact preview revision for both passes. Reuse applicable shared validators
alongside the editorial walkthrough. Add automated tests when a software change or
a recurring objective error justifies a reusable check, following repository requirements.
Record the reason and result in the production packet's selected checks.

1. Follow the lesson in learner order. Check that diagrams make sense in context and
   that learners can attempt each task with the support provided. Check that hints are
   optional when offered, and verify when answers, feedback and retries become visible.
   Record whether early answer reveal is intentional.
2. Inspect all states as an editor. Check musical accuracy, locale, answer rationales,
   likely mistakes, retry equivalence and accessibility. Compare intended behavior with
   the preview and the delivery format. Record pending runtime checks separately.

- The short visual draft exposes the syllabus, transitions, diagrams and resource map.
- Each lesson has a dedicated opening application slide or section anchored in a learner
  goal, with today's first step and a concrete connection to later subjects.
- The success check returns to that goal and recognizes the step taken.
- The lesson title names a payoff or puzzle and promises only what the lesson delivers.
- Each transition follows from knowledge already introduced and motivates the next step.
- Diagram titles are understandable; instrument, string, positions and movements are clear.
- Practice prompts explain the action, purpose, support and feedback in the target locale.
- The review draft shows proposed exercises and the packet maps them to platform
  authoring. If there is a final PowerPoint, inspect slides, hidden slides and notes
  for exercise prompts, answers, feedback and retries and remove any that remain.
- Resource references identify exact sections, purpose, access, status and alternatives.
- Classification, curriculum placement, human music/locale review, native runtime support
  and publication approval remain separate gates. Neither a visual draft nor its approval
  resolves those checks automatically.
