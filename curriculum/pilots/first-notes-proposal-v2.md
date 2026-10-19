# First notes — proposal v2 for review

**MOT-160 · Plan · 2026-10-18 · awaiting PO draft/diagram review.** Supersedes the
v1 guitar-only application and generated-audio requirements in first-notes.md.
Source revision: 98905d4. No full lesson, deck, video or audio production authorized
by this proposal. The older files are retained as historical drafts, not current assets.

## Working agreement for future iterations

1. First deliver a short content draft, proposed learning flow, and diagram concepts.
   Review these with Gilson before producing whole lessons or presentation/media assets.
2. Generate audio files only when explicitly requested. Prefer MotifPath diagram
   playback where appropriate. Public-domain repertoire may be proposed as a reference;
   verify the particular composition, arrangement and recording before selecting it.
3. Plan around MotifPath's actual diagrams, chords, clue/supporting contents, reusable
   exercises and feedback. Article/video connects these resources. Map each resource
   to a learning purpose; do not add features solely to fill a checklist.
4. Universal theory remains instrument-neutral. Keyboard, bass and guitar are examples
   of the same idea, with appropriate pitch registers and instrument-specific diagrams.
5. Explain the practical value up front and show a small payoff in the first attempt.

## Proposed two-part experience

Both parts: pt_BR, beginner, shared musical knowledge. Article/video format remains
open until the content and resources are reviewed. The sequence is explore → explain
briefly → attempt → clue if needed → feedback → transfer to another example.
Instrument choice is an editorial route; no new automatic routing interface is implied.

### A — Conheça as notas: nomes que você pode encontrar

Outcome: relate Dó–Ré–Mi–Fá–Sol–Lá–Si to C–D–E–F–G–A–B, locate supplied examples
using a labelled reference, and recognize the repeating name cycle across octaves.
No absolute-pitch test or fingering proficiency required.

Short learner-facing draft:

> Quando uma cifra mostra C, que nota esse nome representa? C é a letra usada para
> Dó. Conhecer os nomes ajuda você a seguir uma cifra, encontrar uma nota indicada
> e conversar com quem toca outro instrumento. Vamos ligar os nomes às posições
> no teclado, no baixo e na guitarra. O desenho muda; os nomes continuam úteis.
>
> Comece com uma referência: Dó=C, Ré=D, Mi=E, Fá=F, Sol=G, Lá=A e Si=B.
> Depois do Si, os nomes recomeçam em Dó, em outra oitava. Duas notas chamadas Dó
> podem soar em registros diferentes; o nome sozinho não identifica a altura exata.

Proposed resources: labelled keyboard diagram; separate bass/guitar note maps;
letter/name exercise; octave comparison diagram; clue content repeating the relevant
reference only. Attempt: identify F from the name Fá, then locate a labelled C in a
second instrument example. Feedback explains the letter/name relationship; retry with G.
A C chord reference may illustrate where the root name appears; explicitly distinguish
one note from the whole chord, without testing chord construction here.

### B — Tons e semitons: encontre a próxima nota

Outcome: use a diagram to count one or two semitone steps, distinguish Mi–Fá and
Si–Dó from a whole-tone pair, and transfer that reasoning between instrument examples.

Short learner-facing draft:

> Saber os nomes é o começo. Agora precisamos saber a distância entre as notas.
> Essa distância ajuda você a encontrar a próxima nota de uma melodia e entender
> como uma escala é construída. As escalas, por sua vez, ajudam a compreender os
> acordes de um campo harmônico. Hoje vamos praticar a base: tons e semitons.
>
> Na afinação de referência desta atividade, um semitom é um passo entre alturas
> vizinhas; um tom tem dois desses passos. No teclado, conte a próxima tecla,
> branca ou preta. Na mesma corda do baixo ou da guitarra, conte a próxima casa.
> Mi–Fá e Si–Dó ficam a um semitom. Dó–Ré tem uma nota entre eles: Dó♯/Ré♭.
> Por isso, Dó–Ré tem dois semitons, ou um tom.

Proposed resources: keyboard Mi–Fá versus Dó–Ré; guitar and bass same-string views;
exercise comparing the two distances; clue content on counting transitions rather
than endpoints; feedback/retry with Si–Dó and Sol–Lá. Optional diagram playback
makes the example audible without creating any audio files.
Application: place tone/semitone labels on Dó–Ré–Mi–Fá–Sol–Lá–Si–Dó with a reference.
Reveal T–T–S–T–T–T–S as the pattern of this major scale. Full scale transposition and
campo harmônico construction are subsequent outcomes, not required in this activity.

## Diagram proposals (content specifications, not finished assets)

| Proposal | What the learner sees | Purpose / attempt / feedback |
|---|---|---|
| D1 — Keyboard names | C4–C5 with all black keys visible; natural-note names and letters; repeated C marked by shape and text | Relate names to letters and repeating cycle. No claim that two Cs are identical pitches. |
| D2 — Keyboard distances | E4–F4 (1 transition) beside C4–C♯4–D4 (2 transitions); label intermediate key | See why adjacent natural names may differ in distance. Count transitions, not number of displayed notes. |
| D3 — Guitar transfer | Standard tuning, sixth string E2; open 0=E2, 1=F2, 2=F♯2, 3=G2; nut and open position explicit | Find the next semitone or move two frets on the same string. Fret number is not finger number. |
| D4 — Bass transfer | Standard four-string bass, fourth string E1; positions 0=E1, 1=F1, 2=F♯1, 3=G1 | Same step reasoning in a lower register. Compare E–F and F–G without pretending the bass/guitar pitches have the same register. |
| D5 — Distances in Dó major | C D E F G A B C with inter-note distances 2 2 1 2 2 2 1, including chromatic intermediate steps where needed | Connect today's counting to scale construction. Distances encoded by text and arrows, not color alone. |

Each resource has an explanatory state and an exercise state. Preserve the labels
needed to orient the learner; hide only what the question is assessing. Offer a written
position/distance description and a meaningful text-choice alternative. A proposal
for a reveal is not evidence that an arbitrary diagram interaction is supported.

## MotifPath resource map and evidence limits

- Diagrams: features/content-management/diagrams.feature specifies keyboard and fretted
  positions. Each instrument uses its own diagram; the shared parent content stays universal.
- Sound from diagrams: features/web/listening-from-a-diagram.feature and
  content-management/exercise-sounds.feature specify playback-driven exercise sounds.
  Reuse supported playback; no WAV generation, recording, export or upload planned.
- Exercises: features/content-management/exercises.feature specifies reusable exercises,
  image/text choices and diagram-driven answer cells. Map each proposed attempt to a
  supported type; verify keyboard answer behavior separately before promising it.
- Clues/support: plan short reusable explanations for C=Dó, octave register, and
  transition counting. Confirm the exact native clue/related-content linking mechanism
  before authoring; expanded-content images alone do not establish a clue-content API.
- Chords: use an existing reviewed C reference only if it clarifies the practical use
  of note names. Chord construction is outside these two beginner outcomes.
- Native runtime, installed IDs and pt_BR persistence are still unverified. This is a
  source-grounded proposal, not a claim that the experience is installed or working.

## Classification and curriculum decisions reopened

Existing universal concepts: note-names, octaves, sharps-and-flats,
tones-and-semitones. Select per resource, not all by default. Previous match-pitch
classification assessed listening and does not prove visual naming/location; previous
find-notes-root-strings is fretted-only and cannot classify a universal parent.
Suitable universal skill mapping needs reconciliation with the catalog/curator before
readiness; do not fabricate a skill or reuse an incompatible one. Fretted exercises
may retain compatible find-notes-root-strings classification within their actual scope.

A remains related to sh-ear-first/Notas lesson 1; splitting distance content into B
reopens exact curriculum placement. B has no approved new path position. Do not edit
curriculum YAML, promote idea-stage paths or claim alignment until the proposed split
is reviewed. Neither part is restricted to guitar.

## Review gate

Next review is limited to the two outcomes, short drafts, diagram proposals and resource
sequence above. After PO feedback, revise the proposal; full production follows explicit
acceptance of this draft/diagram direction. No generated audio. No publication.
