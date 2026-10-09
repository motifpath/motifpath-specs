# Pattern: installing the app (PWA install offer)

**Source:** ADR-049 §9 (a PWA first, built to run unchanged in Capacitor) · MOT-62 (Figma "Offline &
install", row 3; decisions D9–D11 and D13, approved 2026-10-09) · implemented by MOT-91

## When

Use it whenever the app offers to put itself on the student's home screen, explains how to do that,
or launches as an installed app. It covers Android and desktop browsers that can install a PWA
(Chrome, Edge, Samsung Internet), iPhone and iPad Safari, and in-app browsers that can't install
(WhatsApp, Instagram).

Offline access is **not** part of this pattern and not part of the MVP: it comes after the app is in
the stores (MOT-89, MOT-68). The installed app needs a connection just like the website.

## Why

A student who opens MotifPath from the home screen gets there in one tap, full screen, like any
other app, and is more likely to come back for the daily practice. But an install prompt before
the student has seen what the app does is noise, and iPhone has no prompt at all, so the offer has
to come at the right moment and fit the phone.

## How

### When the offer appears — D9

- **First finished session:** an `InstallCard` on the Summary, under the results (screen 3a). Never
  on the landing, the bridges or the first run (`landing-and-first-run.md`), and never during a run.
- **Not now** hides the card for 14 days; after three offers it stops. The count is kept on the
  device (installing is per device).
- **Never shown** when the app is already installed (`display-mode: standalone`) or when the
  browser can't install and isn't iOS Safari (for example Firefox on desktop).
- The card disappears once the browser reports the app installed (`appinstalled`).

### Always reachable — D10

- **"Install the app"** (`MenuRow`, download icon) is the first row of the account sheet or menu
  (`navigation.md`) while the app isn't installed and the browser can install it (screen 3e). It
  opens the same flow as the card.

### Android, desktop and other browsers that can install

- The card reads "Put MotifPath on your home screen" / "It opens like an app — full screen, one tap
  from your home screen." with **Not now** (Tertiary) and **Install** (Secondary).
- **Install** calls the saved `beforeinstallprompt` event; the browser draws its own prompt
  (screen 3b). We don't style it or wrap it in our own dialog.
- If the student cancels the browser prompt, it counts as Not now.

### iPhone and iPad Safari — D11

- iOS has no install prompt. The card's action is **Show me how**, which opens a sheet (Compact) or
  dialog (Medium and Expanded, `overlays.md`) titled "Add MotifPath to your Home Screen" (screen 3c):
  1. Tap Share in the Safari toolbar (share icon)
  2. Scroll down, tap Add to Home Screen (add icon)
  3. Tap Add — MotifPath joins your apps (phone icon)
  The only action is **Got it**; × closes it too.
- Step text uses Safari's own labels in the app language — pt-BR: "Compartilhar", "Adicionar à
  Tela de Início", "Adicionar".

### In-app browsers — D11

- Inside WhatsApp's or Instagram's browser, installing is impossible. The same sheet reads "Open in
  Safari to install" (or "in Chrome" on Android): "You opened MotifPath inside WhatsApp. Its browser
  can't add apps to your Home Screen.", then the steps to open the page in the real browser (screen
  3d). The action is **Copy link**, which copies the current URL and confirms with a toast ("Link
  copied").

### The installed app — D13

- **Manifest:** name and short name "MotifPath", `display: standalone`, portrait not forced, icons
  from motifpath-brand (`Brand/Mark`, with a maskable variant), background = the surface colour,
  theme = the surface colour of the current appearance.
- **Launch:** the splash is `Brand/Mark` and "MotifPath" on the surface colour (screen 3f), then
  Home. There's no browser bar, so every page needs its own way back (the App Shell and the
  Practice Shell already have one).
- **Service worker:** caches only the app shell (HTML, JS, CSS, fonts, icons) so the app opens
  fast. It caches no API data and no media: with no connection, the installed app shows the same
  states as the website (`states.md`).
- **Updates:** a new version applies the next time the app is launched. Never reload during a run,
  and no "update available" prompt.
- **Safe areas:** `viewport-fit=cover`; bars pad with `env(safe-area-inset-*)` (`session.md` already
  does it for the action bar).

### Size classes

| Size class | Install offer |
|---|---|
| Compact | Card on the Summary; iOS steps in a bottom sheet; row in the account sheet. |
| Medium | The same card in the Summary column; iOS steps in a 480 px dialog; row in the account menu. |
| Expanded | The same card in the Summary column; the account menu row. iOS steps rarely apply (iPad landscape) and use the dialog. |

## Do not

- Offer to install before the student has finished a session.
- Show the offer to someone who already installed the app, or in a browser that can't install it.
- Imitate the browser's or the system's own install UI.
- Promise offline use: "works without signal" is not true until MOT-89 / MOT-68.
- Reload or update the app while a run is open.

## Spec changes this needs

- **Web (MOT-91):** a `features/web/install.feature` for the offer rules (first finished session,
  Not now for 14 days, three offers, hidden when installed or not installable, iOS steps, in-app
  browsers, account row).
- **Events (MOT-91, spec first):** tracking events for the offer (shown, dismissed, accepted, and
  `appinstalled`) so the install rate can be measured; schema change in
  `openapi/components/schemas/events.yaml`, with a Gherkin scenario for each.
- No core or OpenAPI change.
