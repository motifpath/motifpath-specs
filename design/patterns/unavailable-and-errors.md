# Pattern: errors and unavailable items in a run

**Source:** ADR-049 §4 (no modal inside a run) and §5 (standard states) · ADR-046 ("not answered",
amended 2026-10-08) · MOT-55 (Figma "Practice Shell — flows", row 12; decisions D20, D21) ·
implements MOT-28 (PB-69)

## When

Use it when something in the Practice Shell fails or can't be shown: instruments or the session
didn't load, a sound or image didn't load, an item can't be shown on this device, or nothing was
answered.

## Why

A run is short and hands-busy. A dialog stops it; a failure that counts as a wrong answer punishes the
student for the app's problem and corrupts their levels.

## How

- **In place, never a modal.** `InlineNotice` renders where the failed part would be:
  - **Error:** it failed and may work on retry. The primary action is **Try again**.
  - **Unavailable:** it won't work here; move on. The primary action is **Skip**.
- **One primary action only:** the way forward. × still leaves at any time; Esc, Enter and the pedal
  work as usual.
- **Never a wrong answer.** A skipped or unavailable item is "not answered": no accuracy, no response
  time, no level change. Skip sends a `not_answered` response with its reason (`failed_to_load` or
  `unavailable`), which is kept as an event but yields no evidence (ADR-046).
- **Options lock** while the stimulus is missing (a clip that didn't load), so a guess can't be
  recorded (D21).
- **Composing failed:** the student's choices on the setup are kept; Try again sends them again.
- **Nothing to practise on the chosen instrument:** the way out is **Choose what to practise**
  (MOT-77, D20), not an error line.
- **Loading** shows the shape of what's coming (skeleton rows) with a sentence, never a blank spinner.
- **The summary of a run with nothing answered** says so plainly and offers to practise again; it
  shows no score.
- **Copy** says what happened and what to do: no codes, no blame. Strings reuse the web locale where
  they exist.

## Do not

- Open a dialog or a toast for a failure during a run.
- Grade an item the student couldn't see or hear.
- Leave the student with no action but ×.
- Show an error code.

Outside a run, pages and sections use the standard states in `states.md` and the overlay rules in
`overlays.md`.

Out of scope: going offline or losing the connection mid-run (answers queued, "saved when you're back
online") is designed in MOT-62.
