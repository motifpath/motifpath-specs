# Pattern: standard states (loading, empty, failed, locked, not found, offline)

**Source:** ADR-049 §5 (standard-state set) · MOT-60 (Figma "Overlays & states", row 4; decision D8)
· replaces the look of `StateLoading`, `StateEmpty`, `StateError`, `StateLocked`, `NotFoundView`
and `ErrorRetryNotice`

## When

Use it on every App Shell page or section that can be waiting for data, have nothing to show, fail
to load, be not yet allowed, point at something gone, or need a connection it doesn't have. Failures
inside a practice run follow `unavailable-and-errors.md` instead.

## Why

A state is a moment where the student can get lost. If each one says what happened and gives one
way forward, in the same place and the same shape, the student never hits a dead end.

## How

- **The shell stays.** Top bar, bottom bar (or rail / sidebar) and the page title stay in place; a
  state fills only the part of the page it is about.
- **Which state:**

  | Situation | Shows | Action |
  |---|---|---|
  | Content is coming | `Skeleton` shaped like the content (lines, cards), only after 300 ms (D8) | — |
  | A short action is running (Save, Send) | the button's Busy state; the page doesn't change | — |
  | Failed, may work on retry | `InlineNotice` Error where the content would be | Secondary **Try again** |
  | Nothing there yet | `StateBlock` (Empty): why it is empty | the one way to fill it ("Find a course") |
  | Not yet allowed | `StateBlock` (Locked): why, and what unlocks it | go to the thing that unlocks it |
  | Gone, unpublished or not yours | `StateBlock` (Not found) | the nearest useful place |
  | Offline and nothing cached | `StateBlock` (Offline) | none — the app retries by itself |
  | One section of a page is empty | one muted line under the section heading | none |

- **`StateBlock`:** icon disc, title, one sentence, at most one action. The copy is specific to the
  page ("No courses yet"), never "No data" or an error code.
- **Locked** never says just "Locked": it names the step or condition that opens it (`path.md`).
- **Empty sections** don't get a block or a button: the page already has its primary action
  (`primary-action.md`).
- Every state string is checked in pt-BR for length.

## Do not

- Show a full-page spinner or "Loading…" text.
- Flash a skeleton on loads faster than 300 ms.
- Replace the whole app with an error page.
- Leave a state without a way forward, except Offline (which recovers by itself).
- Show an error code or a raw server message.

Out of scope: offline banners, the cache and sync (MOT-62).
