# Pattern: navigation

**Source:** ADR-049 §1 and §5; decided in MOT-43 (2026-10-07); lessons revised in MOT-56 (D1, D12);
account menu decided in MOT-60 (D1–D4); Learning decided in MOT-57

## When

Every learner screen outside a practice run: the App Shell. A practice run uses the Practice Shell
instead, with no global navigation (see the session pattern). Authoring screens keep their own app
bar and are desktop-first.

## Why

A student on a phone, often with an instrument nearby, should reach every main place in one tap and
always find it in the same spot. A menu behind a hamburger costs an extra tap and hides where the
student can go.

## How

- **Five destinations, always in this order:** Home · Practice · My path · Learning · Discover.
- **The container follows the size class, never the content:**
  - Compact (< 600 px): a bottom navigation bar. Every item shows its icon and its label; the
    current one gets an indicator pill behind the icon and a bolder label. Touch targets are at
    least 48 px, and the bar sits above the home-indicator safe area.
  - Medium (600–839 px): a navigation rail on the left, with the same items.
  - Expanded (≥ 840 px): a sidebar with icon and label rows.
- **Account and settings** sit behind the avatar (MOT-60, D1–D4):
  - Content, at every size: who is signed in (name, and the role for teachers and admins) ·
    Appearance (Auto | Light | Dark; Auto follows the device and is the default) · Language › ·
    Teach (teachers and admins only) · Sign out.
  - Compact: a bottom sheet. Medium and Expanded: a menu anchored to the avatar — at the foot of the
    rail, or the "Account" row at the foot of the sidebar (`overlays.md`).
  - "Teach" is in the menu on Compact and Medium; on Expanded it sits in the sidebar under a divider,
    apart from the learner destinations, and the menu drops it.
  - Language opens a list in the same sheet or menu (back arrow); a choice applies at once and
    returns. It changes the app only, not the lesson content's language.
  - Appearance and language apply at once, with no Save.
  - Sign out happens at once, with no confirm and no toast, and lands on the landing page ("You're
    signed out. Your practice and progress are saved.").
- **Practice** opens the session setup directly, never a page in between.
- **Learning** lists every course and standalone path the student has started (in progress,
  finished, left); tapping a row continues it in My path (see `learning.md`).
- **Discover** joins the course and path catalogs behind a Courses | Paths segmented control (see
  `discover.md`).
- **A lesson** is a pushed page (back arrow to My path): on Compact it hides the bottom bar so the
  lesson gets the height; the rail and the sidebar stay on Medium and Expanded (see `lesson.md`).
- **Before sign-in** there is no App Shell: the landing and the sign-in bridges have their own
  layout, and a student who has never started anything gets the first run on Home (see
  `landing-and-first-run.md`).
- **Back** closes the topmost layer (menu, sheet, dialog) before it leaves the destination.
- Labels are short nouns that fit one line in pt-BR on a 360 px screen: Início, Praticar, Trilha,
  Aprender, Explorar.

## Do not

- Add a sixth destination. A new place is reached from one of the five.
- Hide navigation behind a menu button on any size class.
- Mark the current destination by colour alone.
- Show the learner navigation during a practice run, or before the visitor has signed in.
- Show the bottom bar under a lesson on Compact.
