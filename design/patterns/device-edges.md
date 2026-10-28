# Pattern: device edges

**Source:** ADR-049 §5, ADR-063 §4; decided in MOT-174
**Designs:** Figma "MotifPath — Experience Language", page "Device edges — MOT-174" (the rule, the
splash and the icons). Every phone frame on the screen pages carries `Device/StatusBar` and
`Device/HomeIndicator`.

## When

Every screen, in the browser, in the installed PWA and in the iOS and Android apps. The rule only
shows where the device takes part of the screen: the status bar, a notch or the Dynamic Island,
the home indicator, Android's gesture bar, and the sides of a phone in landscape. On a desktop
browser every inset is 0 and nothing changes.

## Why

In the store apps the page fills the whole screen, under the system's own bars. The spike
(MOT-164) found the header under the iPhone's clock and a × that could not be tapped, because iOS
keeps touches near the status bar for itself. A student holding a guitar has one free thumb; a
control they can't hit is worse than a control they can't see.

## How

### Insets are applied once, by whoever owns the edge

- The page draws edge to edge (`viewport-fit=cover`). Each edge has **one owner**, which pads by
  that edge's inset (`env(safe-area-inset-*)`). Screens never add insets of their own.
- **Top edge:** the App Shell top bar, the Practice header, the Teach and editor app bars, and a
  full-screen layer's header. The bar's background fills the area behind the status bar; its
  controls start below the inset. A screen with no bar (the landing page) pads its content
  instead.
- **Bottom edge:** the bottom navigation bar, the Practice action bar, a sheet's last row (its
  actions, or its body when it has none), a page's docked bar, and the toast stack. Each pads by
  the bottom inset or its own bottom padding, whichever is larger. Only the lowest of them pads:
  a toast or docked bar above the bottom navigation bar sits on top of the bar, not on the inset.
- **Sides (landscape):** the rail and the sidebar pad on the left; the content's side gutters are
  the gutter or the side inset, whichever is larger.
- **Overlays:** a sheet never grows into the top inset (its maximum height leaves the status bar
  and a gap clear). A centred dialog stays inside all four insets. The scrim covers the whole
  screen, system bars included.

### Nothing to tap sits in an inset

- No button, link or field sits, even in part, inside an inset. Text and decoration may scroll
  under the status bar, behind the top bar's background.
- Targets stay at least 48 × 48 px after the inset (`navigation.md`, `overlays.md`).

### Status bar

- It overlays the page and is transparent: the colour behind it is the top edge owner's.
- Its icons follow the appearance in use (Auto follows the device): dark icons on the light
  appearance, light icons on the dark one. Changing Appearance updates them at once.
- Android's navigation bar is transparent too, with icons that follow the same rule.

### Back

- Android's back gesture or button does what the browser's Back does. It closes the top layer
  first (`overlays.md`), then goes back one page. In a run it leaves like × (`session.md`).
- On Home with no layer open, Back leaves the app. The app never asks "Exit?".

### Launch

- **Icon:** `Brand/Mark` (`motif-path-mark.svg` in motifpath-brand). Android uses an adaptive icon
  (the mark on the surface colour) with a monochrome layer for themed icons. iOS uses a single
  1024 px icon with no transparency.
- **Splash:** `Brand/Mark` centred on the surface colour, in the device's appearance (light or
  dark). It has no wordmark: Android 12 and later draw only the icon on their launch screen, so
  both platforms match. The installed PWA keeps its own launch screen (`install.md`, screen 3f).
- **The splash stays until the first screen can render** (sign-in is known and the first data has
  loaded or failed). The student never sees a blank page. If that takes longer than 10 s, the
  splash gives way to the screen's own loading state (`states.md`).

## Do not

- Pad a single screen for the status bar or the home indicator: fix the edge owner instead.
- Put a control in an inset, or move one there with a negative margin.
- Paint the status bar a colour of its own that differs from the bar under it.
- Ask for confirmation before Back leaves the app.
- Show a spinner or a blank page between the splash and the first screen.
