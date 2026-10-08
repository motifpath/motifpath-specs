# Pattern: overlays (sheets, dialogs, confirm, Undo, toasts)

**Source:** ADR-049 §4 and §5 · MOT-60 (Figma "Overlays & states", rows 1–3; decisions D1, D5–D7)

## When

Use it whenever something opens on top of a screen: a short task, a menu, a confirmation, or a
message about an action that just happened. Outside a practice run only — a run never opens a modal
(ADR-049 §4, `unavailable-and-errors.md`).

## Why

If every screen decides on its own how to ask, confirm and report, the app feels like several
products. Sheets keep short tasks in the thumb zone on a phone; Undo is faster and kinder than a
question the student answers without reading.

## How

### Sheet or dialog

- **A short task** (a few fields or one choice) opens a **bottom sheet** on Compact and a centred
  **dialog** on Medium and Expanded. It is one thing with two presentations: same title, body and
  actions (rows 3a, 3b).
  - Sheet: grabber, title and × (`SheetHeader` Kind=Sheet), body, the primary action at the bottom
    spanning the width. It grows to its content up to 90% of the screen; then the body scrolls and
    the action stays.
  - Dialog: 480 px wide, title and × (`SheetHeader` Kind=Dialog), actions bottom-right, primary
    last, a Tertiary "Cancel" before it.
- **A complex form** (more than about three fields, or anything that scrolls a lot) is a **page**,
  not a sheet.
- **A menu** (a list of destinations or settings, like the account menu) is a sheet on Compact and
  an **anchored menu** next to its trigger on Medium and Expanded — not a dialog, because it is not a
  task (D1, `navigation.md`).
- **Never a sheet on a sheet.** A sub-step replaces the sheet's content and gets a back arrow
  (row 1c).
- **Scrim:** black at 40% in both themes. A tap on it closes the layer, except a confirm.

### Confirm or Undo

- **Reversible action → do it at once and offer Undo** in a toast (row 3e). Example: making another
  course current (Undo switches back).
- **Destructive and irreversible → confirm first** (rows 3c, 3d). Nothing else gets a confirm.
  - Title: "Verb the thing?" ("Leave Fingerstyle basics?"). One sentence says what is lost and what
    stays. The button is the verb ("Leave course"), never "OK" or "Yes".
  - Compact: a sheet without ×. Destructive button on top, the safe choice ("Keep learning") at the
    bottom, where the thumb rests, so a slip lands on the safe choice (D5).
  - Medium and Expanded: an alert dialog, 400 px, no ×. Safe button left, destructive right. Focus
    starts on the safe button; Esc is the safe choice.
- **Leaving a course or a path keeps its confirm** (D6): enrolling again starts from checkpoint 1
  and there is no way to restore the old enrollment, so it is not reversible today. It moves to Undo
  only if a restore operation is added (spec-first).

### Toasts

- **Where:** at the bottom — above the bottom bar on Compact, bottom-centre on Medium and Expanded
  (D7). Width up to 480 px.
- **Look:** inverse surface (ink background, surface text), so it reads in both themes. `Toast`
  Kind=Neutral, Success or Error.
- **One at a time:** a new toast replaces the current one.
- **Timing:** 5 s; 10 s when it has an action. Hover or keyboard focus pauses it.
- **At most one action:** Undo for a reversible action, Retry for a background action that failed.
- **Errors:** if the student is still on the screen, the error shows in place (`InlineNotice`,
  `states.md`), never only in a toast. A toast is for something that failed after the student moved
  on; an error toast stays until dismissed.
- `role="status"` for Neutral and Success, `role="alert"` for Error.

### Every layer

- **Back closes the top layer first:** each sheet, dialog or menu adds a history entry, so Android's
  back gesture and the browser back button close it before leaving the page (ADR-049 §5).
- Esc closes it; focus is trapped inside and returns to the trigger when it closes.
- Targets are at least 48 × 48 px.

## Do not

- Ask to confirm a reversible action, or a sign-out (`navigation.md`).
- Stack two overlays.
- Put a form that needs scrolling in a sheet.
- Show a toast as the only place an error is explained.
- Open any overlay inside a practice run.
