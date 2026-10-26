# ADR-063: Store apps with Capacitor — native sign-in, native HTTP, and the release gates

**Status:** Proposed
**Date:** 2026-10-25
**Deciders:** Gilson (PO), Claude Code
**Task:** MOT-164
**Amends:** ADR-049 §9 (delivery order; the auth redirect port; the Capacitor spike)

---

## Context

ADR-049 §9 chose to ship the app as a PWA first, and to build everything so that wrapping it in
Capacitor for the App Store and Google Play would need no rework. It required a Capacitor spike
before any store work. The spike had to verify Clerk sign-in, audio in the WebView and the iOS
silent switch, storage persistence, and the stores' payment rules.

The alpha now runs in production, and the product owner decided to build the iOS and Android apps
now rather than after the PWA. MOT-164 ran the spike on a throwaway branch of `motifpath-web`:
Capacitor 8 with the production web build, on the iOS Simulator, a real iPhone 14 and a real
Android phone. The Android emulator could not run on the Intel Mac, so Android was tested from an
Ubuntu machine.

Most of the web app ran unchanged: navigation, the API clients, practice with Web Audio samples,
the metronome, timed taps and lesson video. **Signing in and staying signed in did not.** Three
problems appeared one after another:

1. **The web sign-in cannot work in the app.** `authenticateWithRedirect` sends the WebView to
   Google. Capacitor does not load external pages in the WebView and hands them to Safari, so the
   user signs in there. The Clerk session ends up in Safari, the return to
   `capacitor://localhost/sso-callback` fails, and the app never gets a session. Google also
   refuses OAuth inside embedded WebViews.
2. **Cookies don't persist.** The app's origin is `capacitor://localhost`, so Clerk's cookies on
   its own domain are third-party and the WebView never stores them. The session was lost on every
   app restart.
3. **Clerk's native mode is refused from the WebView.** With `standardBrowser: false`, clerk-js
   sends the client token in an `Authorization` header instead of a cookie. Clerk's Frontend API
   rejects any request that carries both `Origin` and `Authorization`
   (`400 origin_authorization_headers_conflict`), and a WebView always sends `Origin`.

The spike also found:
- With the silent switch on, iOS mutes web audio on the built-in speaker. Bluetooth output still
  plays.
- The page draws under the status bar and the home indicator, because safe areas are not
  handled. On the iPhone, the header sits under the clock, and a close ("×") button outside the
  safe area cannot be tapped.
- Debug builds log the Google ID token.
- ADR-058 plans digital subscriptions and teacher-path purchases through Stripe. Both stores
  restrict selling digital content inside an app.

## Decision

**MotifPath ships iOS and Android apps built with Capacitor from the same web codebase.** The
installable PWA (MOT-91) stays planned but is no longer a prerequisite. In the app shell:

### 1. Sign-in is native and hands an ID token to Clerk

- Google sign-in uses the platform's own account picker through a Capacitor social-login plugin.
  The resulting **Google ID token** is passed to `clerk.authenticateWithGoogleOneTap({ token })`.
  The browser keeps `authenticateWithRedirect`.
- The ID token's audience is the **Web OAuth client** on both platforms. Clerk's Google connection
  uses custom credentials with that same Web client in every Clerk instance. Each platform also
  needs its own OAuth client: iOS uses the bundle ID and its reversed client ID as a URL scheme;
  Android needs one client per signing key (debug, upload, Play App Signing).
- **Sign in with Apple is required on iOS** before the first App Store review (App Store Review
  Guideline 4.8), using Clerk's `oauth_token_apple` strategy. It follows the usual order: spec,
  then an approved Figma design, then code.
- After `setActive`, the app navigates by itself. Clerk ignores redirect URLs on the `capacitor:`
  scheme.

### 2. Clerk runs in native mode over native HTTP

- clerk-js loads with `standardBrowser: false`.
- The app keeps Clerk's client token, through the clerk-js request and response hooks
  (`__internal_onBeforeRequest`, `__internal_onAfterResponse`), in **secure platform storage**:
  the iOS Keychain or the Android Keystore. Never localStorage.
- **`CapacitorHttp` is enabled.** `fetch` and XHR go through the native network stack, which sends
  no `Origin` header, so Clerk accepts the `Authorization` header. As a result, the app's calls to
  core-domain and event-ingestion are not subject to CORS.
- The hooks are an internal clerk-js API. clerk-js is pinned, and a test covers the token
  round-trip, so a Clerk upgrade cannot silently break sign-in.

### 3. Audio plays through the silent switch

At launch the iOS app sets the audio session category to `playback`, so practice sound is heard
with the silent switch on. This is the "audio session" port ADR-049 §9 anticipated.

### 4. Release builds

- Release builds turn Capacitor logging off.
- Release builds allow no cleartext or local-network traffic. Those settings exist only in
  development builds.
- Native projects target JDK 21 for Gradle; the JDK 25 that Android Studio bundles fails.
- The page handles safe areas (`viewport-fit=cover`, `env(safe-area-inset-*)`). No interactive
  control may sit outside them.
- The app id is `com.motifpath.app`, confirmed before the first store upload. It cannot change
  afterwards.

### 5. Distribution

- iOS testers use **TestFlight**. Android testers use **Play internal testing** or Firebase App
  Distribution.
- Both stores need paid developer accounts: the Apple Developer Program and the Google Play
  Console.

### 6. Release gates (store review)

- **No paid feature ships in a store app until the payment rules are decided.** Selling digital
  subscriptions or content inside the app normally requires Apple In-App Purchase and Google Play
  Billing. Alternatives such as external purchase links depend on the region and must be checked
  for Brazil. Until that decision is recorded in its own ADR, the store apps neither sell nor link
  to purchases.
- **Timing is re-checked on a mid-range Android phone before each Android submission.** Android
  is the main market, and WebView audio and touch latency vary by device. The spike's Android run
  passed. The release checklist records the tap check's `median_tap_ms` and the metronome feel
  for the test phone. If latency ever breaks timed grading, a native audio path will be needed.

## Rationale

- **Native ID token over a system-browser redirect.** The browser-sheet flow
  (ASWebAuthenticationSession / Custom Tabs returning through a deep link) was the alternative.
  It relies on a Clerk native-redirect flow that Clerk doesn't document for Capacitor, and it
  shows a browser sheet. The native picker skips the browser and 2FA prompts for accounts already
  on the device. Clerk supports the token directly, as it does for Google One Tap, and native
  Sign in with Apple fits the same pattern.
- **CapacitorHttp over a native Clerk SDK or a proxy.** A native Clerk SDK would split auth state
  between native code and the web app. Proxying Clerk through core-domain would add a security
  component to own and operate. CapacitorHttp is part of Capacitor, removes `Origin` for every
  request, and removes CORS from the app's API calls as a side effect.
- **Secure storage for the client token.** The client token is a long-lived credential.
  localStorage is readable by any script in the page, and the spike used it only for speed.
- **Stores now, PWA later.** ADR-049 put the PWA first because store work would be spent before
  the redesign was validated. The redesign has since shipped to the production alpha, and store
  presence, durable iOS storage and reliable push are now worth more than reaching Android users
  without review. The spike also showed the wrap is bounded: sign-in is the only part that needed
  new design.

## Consequences

### Positive
- One codebase serves the web, iOS and Android. Feature code stays the same, and only sign-in and
  device capabilities branch by platform.
- Students stay signed in across launches, and sign-in uses the familiar native account picker.
- The app's API calls don't depend on CORS configuration.
- Practice sound works on a silenced iPhone.

### Negative / Trade-offs
- Sign-in depends on an internal clerk-js API (`__internal_on*`). A Clerk release can change it,
  as it already renamed `__unstable__on*` to `__internal_on*`.
- CapacitorHttp carries every request. Large binary responses cross the native bridge. A practice
  session (33 native requests, samples included) worked, but uploads, streaming and very large
  media are untested. If one breaks, it needs a per-request opt-out.
- Two more Google OAuth clients, a signing-key inventory, two developer accounts and two store
  listings to maintain.
- Sign in with Apple adds a second identity provider, plus its spec and UI work, before iOS
  review.
- The payment gate can delay paid plans in the apps, or cost the stores' commission.

### Neutral
- Production Clerk and CORS settings don't need to change for the app, because native HTTP sends
  no `Origin`. If that changes, `capacitor://localhost` (iOS) and `https://localhost` (Android)
  are the origins to allow.
- Device testing against a local stack needs `MEDIA_PUBLIC_BASE_URL` set to the Mac's LAN address.
- The spike branch `chore/MOT-164/capacitor-spike` stays unmerged, as a reference.

## Related ADRs

- **ADR-049: Practice-first experience language, mobile-first UI, PWA built for Capacitor.** This
  ADR amends §9: delivery order, the auth redirect port, and the spike's outcome.
- **ADR-046: Practice evidence.** Its latency-based grading is why Android timing is a release
  gate.
- **ADR-058: Stripe as the payment provider.** Its in-app sales are subject to the store payment
  gate.

---

*This ADR was decided on 2026-10-25. To revise, create a new ADR with Status: Supersedes ADR-063.*
