# ADR-049: Practice-First Experience Language, Mobile-First UI, and a PWA Built for Capacitor

**Status:** Accepted
**Date:** 2026-10-05 (Proposed) · 2026-10-05 (Accepted, in review of specs#184)
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-43
**Amended:** 2026-10-06, by Gilson (PB-22 slice 4): the pilot's practice home became the app's
general home, and Practice opens the session setup directly (see §10 and ADR-046).
**Amends:** ADR-018 (decision points 1 and 3, and the deferred documentation site; see Relation to
ADR-018)

---

## Context

MotifPath's retention is the platform's job, not a teacher's (platform-first premise), and practice
is the main lever for it (ADR-046, PB-22). Students practise mostly on a phone, often for a few
minutes, and often **with the instrument in their hands**: every tap on the screen competes with the
guitar. The UI has to be judged first by how a short practice session feels on a phone.

ADR-018 gave the web app a sound foundation — tokens, Reka UI primitives, an owned component library,
and framework-agnostic islands for the SVG diagrams and Canvas runners — and PB-48 added a shared
`AppBar` and an `ExerciseView` that is both the student's practice screen and the authoring preview.
What it did not give is a **language for how the app behaves**:

- Each way of practising has invented its own screen: the S7 challenge, the play-along runner, and now
  exercises inside sessions (PB-22 slice 3). Headers, progress, feedback and "what happens after an
  answer" differ between them.
- There are no rules for when to use a dialog, a sheet or a page, how many primary actions a screen
  may have, or how selection works on a phone, so each screen decides again.
- The learner navigation (my path, practice, my courses, find a course, find a path) and the
  authoring sections share one shell that was laid out for the desktop.
- The app ships only as a website. There is no installable app, no store presence and no offline
  behaviour, while a practice session on a train or in a basement with bad signal is a normal case.

The practice model now constrains the UI concretely (ADR-046 as amended 2026-10-05):

- a session starts with the instrument in hand and the minutes, and may end with an application
  play-along;
- answers are graded on the server from raw responses, and **response latency is measured from the
  moment the prompt appears**, with the audio's length taken off for audio exercises;
- a challenge answer is the selection the student moves on with, once per exercise per run-through;
- a session with no end event is abandoned after its planned minutes + 15, and a later event reopens
  it.

Perception is not a separate feature: it is the `audio_recognition` and `audio_selection` exercise
types, and any exercise whose prompt embeds a diagram with playback (ADR-041).

Alternatives considered:

- **(a) Rewrite in Flutter or React Native** for native apps. Rejected (see Rationale).
- **(b) Two UIs, one per platform** (Material on Android, Human Interface on iOS). Rejected.
- **(c) Adopt Ionic's UI components** with Capacitor. Rejected.
- **(d) Build a complete design system first**, then return to the product. Rejected.
- **(e) A paid Figma file as the design system's source of truth.** Rejected.
- **(f) Go straight to Capacitor and the stores**, or **(g) stay a website only.** Both rejected in
  favour of a PWA built so that Capacitor needs no rework.

## Decision

MotifPath will design its UI as **one practice-first experience language**: a mobile-first,
responsive web app in Vue that follows conventions iOS and Android share, built from an extracted
design system, and delivered first as a **PWA engineered to run unchanged inside Capacitor**.

### 1. Two shells

- **App Shell** — navigation and discovery. In the Compact size class, the learner destinations sit in
  a **bottom navigation bar with at most five destinations**; in Medium and Expanded it becomes a
  navigation rail or sidebar. Which five destinations is decided in the App Shell iteration, not here.
- **Practice Shell** — the only layout for any practice run: a practice session, an S7 challenge run,
  an application ending. Global navigation disappears. Its anatomy is fixed:

  ```text
  ┌────────────────────────────┐
  │ ×        4 / 10        ⋯   │  Session: exit, progress, options
  │ ██████████░░░░░░░░         │
  │          STIMULUS          │  what is played or shown
  │         INTERACTION        │  what the student does
  ├────────────────────────────┤
  │   FEEDBACK / PRIMARY ACT.  │  one action, in the thumb zone
  └────────────────────────────┘
  ```

  The authoring preview keeps rendering the same `ExerciseView` (PB-48), so a teacher previews what a
  student actually gets.

### 2. The practice experience language

Every way of practising is composed from shared primitives instead of its own screen:

| Group | Primitives |
|---|---|
| Session | Setup (instrument in hand, minutes), Progress, Timer, Exit, Options, Summary |
| Stimulus | Text, Image, Audio, Diagram with playback, Notation, Count-in |
| Interaction | Choice, MultipleChoice, Region, Sequence, SelfRating, TempoLadder |
| Feedback | Correct, Incorrect, Explanation |
| Flow | Commit, Retry, Continue, Complete |

A new practice item kind (ADR-046's recipe) states which primitives it uses. A kind that needs a
primitive not listed adds it to this table by amending this ADR, with its pattern documented.

### 3. The commit point is a rule per interaction, not one global flow

What happens between an answer and the next item is decided by the interaction and by how it is
graded:

- **The tap is the answer** for Choice and Region in a practice session: feedback appears in place
  and the session moves on (auto-advance, configurable, with Continue as the fallback). No "Check"
  step, because latency counts from the prompt and an extra tap would be measured as slowness.
- **An explicit commit** for MultipleChoice and Sequence, and for every exercise in an S7 challenge:
  the answer is the selection the student moves on with (ADR-046).
- **SelfRating closes** a play-along take or a chord change.
- **Retry** follows each mode's existing rule and never produces new evidence where ADR-046 says it
  does not.

Cases this rule leaves open are settled by comparing coded prototypes in the pilot (point 9), then
written down as patterns.

### 4. Hands-busy rules for the Practice Shell

- The primary action sits at the bottom, at least 48 px tall; no hover-only affordance anywhere.
- **No modal inside a run.** Feedback and explanations render in place.
- The screen stays on during a run (Screen Wake Lock, released when the run ends).
- Keyboard shortcuts for answer, continue, replay and exit, so a Bluetooth page-turner pedal works.
- Audio is unlocked by the tap that starts the run, since iOS allows audio only after a gesture.
  Silent-mode and latency behaviour are verified on real iOS and Android devices.
- Reduced motion is respected; feedback never depends on colour alone.

### 5. One UI, platform conventions both systems share

- **Size classes, not devices:** Compact (< 600 px), Medium (600–839 px), Expanded (≥ 840 px), as
  breakpoint tokens.
- Safe areas (`viewport-fit=cover`, `env(safe-area-inset-*)`), `dvh` units, touch targets ≥ 48 px.
- **Back closes the topmost layer first:** every sheet, dialog or full-screen layer adds a history
  entry, so Android's back gesture and the browser's back button close it before leaving the route.
- **Overlays:** a short task opens a bottom sheet in Compact and a dialog in Medium and Expanded; a
  complex form is a page; a confirm dialog only guards a destructive, irreversible action; a reversible
  action completes at once and offers Undo in a toast.
- **Actions:** at most one primary action per screen, in the thumb zone on Compact; secondary, tertiary
  and destructive variants are distinct.
- **Selection:** up to about five options as tiles or a segmented control; more as a searchable list in
  a sheet; the native `<select>` stays allowed for plain lists.
- Every screen keeps using the standard-state set (`StateLoading` / `StateEmpty` / `StateError` /
  `StateLocked`), and every layout is checked with pt-BR strings, which run longer than English.

### 6. Authoring is desktop-first, with minimal responsiveness

| Tier | On Compact | Examples |
|---|---|---|
| Maintenance | Fully usable | fix text and metadata, publish and unpublish, reorder, open the student preview |
| Heavy editing | Opens and shows the content; editing may be deferred with "best edited on a larger screen" | diagram editor, region drawing, rich-text tables |
| Never | Broken or overlapping layout | every screen |

### 7. The design system: foundations, components, patterns — extracted, not front-loaded

- **Foundations:** tokens with semantic names (`color.action.primary`, `color.surface.elevated`,
  `color.feedback.correct`, `spacing.md`, `motion.fast`, breakpoints). Components reference semantic
  tokens only, never raw values. Tokens keep ADR-018's single source.
- **Components** stay in `motifpath-web` (`src/shared/components`), not a separate package. Component
  names take no prefix (no `Mp*`), new or existing; nothing is renamed. A component enters the library when a real flow needs it;
  there is no upfront generic set.
- **Patterns** — when, why and how components are used (navigation, primary action, selection,
  feedback, error, loading, session, exercise, completion) — are written in
  `motifpath-specs/design/patterns/` and are the layer that keeps screens consistent.
- **Storybook** is added as the executable catalog: every library component, in its states, in each
  size class, with long pt-BR strings, in light and dark, with the accessibility addon. Visual
  regression testing stays deferred.

### 8. Tools: Figma for the visual language, code for interaction

- **Figma Starter (free)** is used to explore the visual language and static screens, worked on a
  **Full** seat (a View seat allows only 20 MCP reads a month). It is not a source of truth: code and
  Storybook are.
- **Interaction hypotheses are compared in throwaway coded prototypes on a real phone**, as the PB-22
  spike did, because a Figma prototype cannot reproduce audio, timing or latency — exactly what
  separates one practice flow from another.
- A paid Figma plan is reconsidered when a designer joins or shared libraries start paying off.

### 9. Delivery: a PWA first, built to run unchanged in Capacitor

The app ships first as an installable **PWA**. Everything is built so that wrapping it in
**Capacitor** for the App Store and Google Play needs no rework:

- **One codebase, no platform forks in feature code.** Device capabilities sit behind small
  TypeScript ports with a web adapter now and a Capacitor adapter later: storage, wake lock, haptics,
  audio session, network status, share, push and the auth redirect.
- **Offline works the same in both.** It does not depend on the service worker: the service worker
  only caches the app shell for the PWA (Capacitor bundles the shell). Offline data lives in app code:
  - an **event outbox** in IndexedDB holds practice events until the network returns; each event keeps
    its `event_id` and `occurred_at`, so a re-sent event is safe: ingestion stores it once (ADR-012),
    the worker drops duplicate evidence by its id and rebuilds an item when older evidence arrives
    late, and a late event reopens a session that had been derived as abandoned (ADR-046);
  - a **session cache** prefetches a run's media and instrument samples when the run starts, so a run
    that started online finishes offline.
- **No same-origin assumptions:** API and media URLs come from configuration, and sign-in never relies
  on a third-party OAuth page inside the WebView.
- **A Capacitor spike precedes any store work** and verifies: Clerk sign-in, audio latency and the
  iOS silent switch in WKWebView, IndexedDB persistence, and the stores' payment rules.

### 10. Rollout: incremental, practice first

- **The pilot is the Practice Shell plus the practice home.** PB-22 slice 3 Phases 0–6 proceed; Phase 7
  (practice home) waits for this ADR and is built as the pilot. The pilot's representative session
  mixes an `audio_recognition` exercise with diagram playback, an image or region exercise, and the
  application play-along.
  Amended 2026-10-06: after the pilot, its practice home moved to the app's general home, and
  **Practice** opens the setup directly. This takes back the tap the home had added before the first
  item.
- **Baseline before, compare after:** taps per item, time from opening the app to the first item, and
  the share of sessions left early or abandoned (already in ADR-046's events).
- Then the App Shell and navigation, then the remaining screens as they are next touched. No big-bang
  restyle.

## Rationale

- **Practice first** because it is where retention is won or lost and where the student's hands are
  busy. A language derived from the hardest screen generalises to the easy ones; the reverse does not.
- **A commit rule per interaction instead of one winning flow** because the flows are not
  interchangeable: ADR-046 measures latency from the prompt, which rules out a Check step on timed
  taps, while the challenge's "selection the student moves on with" requires one. Picking one global
  flow would break grading on one side or the other.
- **Not Flutter or React Native (a)**: a rewrite would discard a working Vue SPA — SVG diagrams,
  Canvas runners, `smplr` Web Audio, Vidstack, Tiptap, hundreds of tests — for a solo developer, while
  the product hypotheses, not the stack, are what is unproven. The content is SVG, audio and video,
  which the web handles natively.
- **Not two platform UIs (b)**: double the design and test surface for no learning benefit. Both
  platforms already share bottom navigation, sheets and large touch targets; the remaining differences
  (back gesture, safe areas, audio unlocking) are handled by rules, not separate screens.
- **Not Ionic UI (c)**: the same objection ADR-018 raised against component frameworks — opinionated
  DOM and CSS fighting the islands and the owned library. Capacitor is used without it.
- **Not a full design system first (d)**: weeks of generic components before any student benefit, and
  components designed without a real flow get redesigned when one arrives.
- **Not Figma as source of truth (e)**: for one developer, a second representation drifts from the
  code. Storybook renders the real components, so it cannot drift.
- **PWA first, Capacitor-ready (f, g)**: a PWA reaches Android users, the large majority in Brazil,
  without store review, and is enough to validate the redesign. Staying web-only forever forgoes store
  presence, reliable push and iOS storage guarantees; going to Capacitor first spends store work before
  validation. Building every capability behind a port, and offline in app code rather than in the
  service worker, makes the later wrap a packaging step instead of a migration.

## Consequences

### Positive

- Every practice kind, present and future, looks and behaves like the same product, and adding one
  means choosing primitives rather than designing a screen.
- Grading and UI cannot disagree about when an answer happens: the commit rule is written next to the
  evidence rules.
- Screens stop re-deciding overlays, actions and selection; reviews check against written patterns.
- Practice survives bad connectivity, and offline behaves the same in the browser and in the app.
- The move to the stores is a bounded, pre-scoped spike, not a rewrite.

### Negative / Trade-offs

- PB-22 slice 3's practice home waits for the pilot, delaying the full student-facing slice.
- Storybook, pattern documents and the platform ports are new things to maintain alone.
- An outbox and a session cache add client-side state, eviction and replay edge cases that need tests.
- On iOS, a PWA that is not added to the home screen can have its storage evicted after a period
  without use, so the offline guarantee is best-effort there until the Capacitor app ships.
- A web UI inside a WebView can feel less native than a native app, and WKWebView audio latency may
  limit future real-time features; those would need a native plugin.
- Figma on a free plan limits the number of design files; exploration stays small.

### Neutral

- The existing components, tokens and islands of ADR-018 remain; this ADR adds behaviour rules on top
  and changes naming only for new tokens.
- Which five destinations the bottom navigation holds is left to the App Shell iteration.
- Haptics are native-only on iOS, so they arrive with Capacitor.

## Relation to ADR-018

ADR-018 stays in force. This ADR amends it in three places:

- **Decision point 1 (tokens):** tokens gain semantic names and breakpoint and motion tokens;
  components reference semantic tokens only.
- **Decision point 3 (owned library):** the library grows by vertical extraction from real flows, and
  each component carries a pattern that says when to use it.
- **Deferred documentation site:** Storybook is adopted now as the executable catalog. Visual
  regression and formal token governance remain deferred.

## Related ADRs

- ADR-018: Frontend UI architecture — the foundation this ADR builds on and amends.
- ADR-046: Practice is evidence-based — the grading and session rules the commit point follows.
- ADR-019: Practice content model — the exercise types the primitives render.
- ADR-041: Diagram audio playback — the diagram stimulus with playback.
- ADR-025: Video player selection — the video stimulus.
- ADR-024: i18n approach — pt-BR strings are part of every layout check.
- ADR-012: Idempotency and delivery guarantees — ingestion stores an event once per `event_id`;
  with ADR-046's evidence-id dedupe and late-evidence rebuild, the offline outbox can re-send safely.
- ADR-037: Every user can learn — the learner shell serves every role.

---

*This ADR was proposed and accepted on 2026-10-05. To revise, create a new ADR with Status: Supersedes ADR-049.*
