# PB-48 — Unified app shell prototype

A single, clickable Claude Design canvas covering the full student and teacher flow — signed
out through sign-in, the student path/lesson/practice loop, and the teacher exercise-authoring
tool — at both desktop and mobile widths, built from the real `motifpath-brand` tokens and the
real brand mark.

**Published prototype:** https://claude.ai/code/artifact/5b9dc838-8206-4820-a9fd-5f8e349dad54

## Working principles

This canvas is where PB-48 first ran into a component-reuse gap (three independently
hand-drawn headers) and then again (the authoring preview and the real student Practice screen
rendering an exercise two different ways). Both were fixed by extracting a shared component.
The rules that came out of that — compose from components instead of duplicating markup,
concentrate new feature work in this one canvas, don't silently touch previously-approved UI —
are recorded in `adrs/ADR-018-frontend-ui-architecture-design-system.md`'s 2026-09-14
amendment. That amendment is the source of truth; treat this section as a pointer to it, not a
duplicate.

## What's in here

- **`Main.dc.html`** — the desktop-width interactive artboard. Click through: landing → sign in
  → my path → lesson → practice (with a result screen and a help popover), or use the
  prototype-only "switch to teacher view" toggle → exercises list → new exercise → the real
  authoring tool → save.
- **`MobileMain.dc.html`** — the identical flow at phone width, through the same components.
- **`AppBar.dc.html`** — the shared header component. One `context` prop (`student` / `teacher`)
  and one `compact` prop (mobile hamburger + nav-only drawer vs. desktop inline nav) cover both
  contexts and both widths from a single implementation.
- **`Authoring.dc.html`** — the exercise-authoring builder (region editor, all four exercise
  types, image-picker and student-preview modals, skill tags). Responsive via CSS media queries
  in its own `<style>` block, so the same component (not a separate mobile build) adapts at any
  width it's mounted at.
- **`ExerciseView.dc.html`** — renders one exercise (prompt + type-specific answer surface).
  Mounted by both Authoring's "Preview as student" modal and the real Practice screen, and
  structurally cannot reveal which option is correct — that data is never passed into it.
- **`Mobile.dc.html`**, **`StickyBehavior.dc.html`** — earlier isolated demos of the hamburger
  drawer and the sticky-header-with-pinned-Save behavior, kept as reference; superseded as the
  primary deliverable by `MobileMain.dc.html` once the full flow existed.
- **`AlternateA.dc.html`**, **`AlternateC.dc.html`** — the two shell directions not chosen
  (Direction B — Raised bar — was), kept on the canvas's "Alternates" page.

## Status

Direction B (raised bar) chosen and built out into the full flow above. Desktop and mobile both
implemented and reviewed. Pure edge/loading states (Registering, RegistrationError, PathHolding,
NotFound from the PB-8j wireframes) are not yet folded into this canvas.
