# ADR-025: Video player selection — Vidstack as a unified player

**Status:** Accepted
**Date:** 2026-09-19
**Deciders:** Gilson (Product Owner)

---

## Context

PB-55 requires embedding video in `motifpath-web` for three concrete use cases: (1) short
practice/exercise demo clips, (2) teacher-uploaded lesson videos, and (3) curated YouTube videos
as supplementary content. Uploaded video (#1, #2) is stored per **ADR-021** — presigned PUT to
S3 in production / MinIO in local dev, read back via a CloudFront URL, with no transcoding or
adaptive-bitrate pipeline in place, so uploaded files are plain MP4s referenced by a direct URL.
YouTube content (#3) must stay embedded through YouTube's own player — YouTube's terms of
service do not permit downloading, rehosting, or bypassing their player with a generic `<video>`
element.

This creates a real design question, not just a library pick: should the app drive both sources
through **one player abstraction** with a consistent play/pause/seek/speed/fullscreen UI, or
integrate each source separately (native `<video>` for MP4, a thin YouTube iframe wrapper for
YouTube)? The second option is the lowest-dependency path but means students see two different
players — native browser chrome for lesson/exercise clips, YouTube-branded controls for
supplementary videos — with two separate event and progress-tracking models to maintain.

Any candidate is also constrained by **ADR-018**: `motifpath-web` deliberately avoids
opinionated, heavy component frameworks (PrimeVue, Vuetify, Quasar were already rejected there)
in favor of headless behavioral primitives, Tailwind-native styling, and an "island" pattern for
DOM-sensitive modules — mounted behind a thin, ejectable Vue wrapper, with no vendor markup
imposed on the surrounding app. A new video dependency needs to fit that same shape: headless or
easily overridable styling, small and tree-shakeable, and replaceable without a rewrite.

The video-player ecosystem is also mid-consolidation as of this decision: the teams behind
Video.js, Plyr, Vidstack, and Media Chrome have merged their engineering efforts into
**Video.js v10**, now stewarded by Mux. As of 2026-09-19, v10 is at Release Candidate — not GA —
ships with first-class React/Tailwind support, and has no confirmed idiomatic Vue integration
yet. This affects the maintenance read of every other candidate: Vidstack and Plyr are still
patched but their own teams describe feature development as slowed or stopped in favor of v10.

Alternatives considered: **Vidstack**, **Plyr** (+ `vue-plyr`), **Video.js v8** (+ a community
YouTube plugin), **Video.js v10** itself, and **native `<video>` + a lightweight YouTube iframe
wrapper** (e.g. `vue3-youtube`) as two separate integrations. `hls.js` / Shaka Player were ruled
out of scope up front — there is no adaptive-bitrate pipeline per ADR-021, so nothing in this
decision needs them yet.

## Decision

MotifPath will adopt **Vidstack** as a single, unified video-player abstraction for both
self-hosted MP4 sources (exercise/practice clips, teacher-uploaded lesson videos) and
YouTube-embedded supplementary content, mounted behind a thin Vue 3 wrapper component per
ADR-018's island pattern. Vidstack's YouTube provider suppresses YouTube's native chrome and
drives playback through Vidstack's own headless control layer, so both sources present the same
play/pause/seek/speed/fullscreen UI, styled entirely with Tailwind rather than a vendor skin.

This ADR does not adopt Video.js v10. It is tracked as an explicit future migration target
(see Consequences) to be revisited once it reaches GA with a documented Vue integration path.

## Rationale

Vidstack is the only candidate that satisfies every constraint in play today:

- **Real control unification, not a naive wrap.** Its YouTube provider hides YouTube's native
  controls and renders Vidstack's own skin on top, normalizing events across both the YouTube
  and self-hosted MP4 providers — the actual requirement driving this decision.
- **Headless by design, fits ADR-018 directly.** Vidstack ships no default visual skin; it is
  pure web components consumed natively by Vue with no wrapper package, styled entirely through
  Tailwind. This is the same shape ADR-018 already chose for Reka UI, not a new pattern.
- **Small, tree-shakeable, MIT-licensed.** ~53KB gzip for the full player, no evidence of a
  paywalled tier gating core playback, and standards-based web components that are trivially
  ejectable if a future migration is warranted — mirroring the ejectability ADR-018 required of
  Reka UI.
- **Accessibility-oriented.** Vidstack markets WCAG 2.2 / WAI-ARIA alignment, keyboard shortcuts,
  and customizable captions, which matters for both lesson content and exercise demos.

**Rejected — Plyr (+ `vue-plyr`).** Plyr also achieves real YouTube control unification and is a
mature, MIT-licensed library, but loses on three counts: its own maintainers are explicitly
steering users toward Video.js v10 ("Plyr, meet Video.js"), a stronger sunset signal than
Vidstack's feature-freeze; it ships an opinionated default skin rather than headless primitives,
closer to the PrimeVue/Vuetify shape ADR-018 already rejected; and Vue 3 support requires a
third-party wrapper (`vue-plyr`) rather than consuming the library directly, adding exactly the
kind of indirection ADR-018 tries to avoid.

**Rejected (for now) — Video.js v10.** This is the more strategically correct long-term target —
it is architecturally Vidstack's own successor, absorbing its engineering work alongside Plyr's
and Media Chrome's. It is rejected only on timing: as of this decision it is Release Candidate,
not GA, and has no first-class Vue integration (React/Tailwind is the flagship path). Adopting
pre-GA infrastructure as core learner-facing video for a solo-maintained project is an
unnecessary risk when Vidstack already meets every stated requirement today.

**Rejected as primary, kept as fallback — native `<video>` + a YouTube iframe wrapper (e.g.
`vue3-youtube`).** This is the lowest-dependency, most-ejectable option and would be the natural
choice if the "one consistent UI" requirement did not exist — but it does. This approach means
native browser chrome for uploaded video and YouTube-branded controls for supplementary video,
two separate UIs and two separate progress/event models to maintain in the app. It remains the
documented fallback if a Vidstack implementation spike surfaces a blocking issue with its
YouTube provider.

## Consequences

### Positive

- One player component, one event/progress-tracking model, and one visual language across both
  uploaded and YouTube-sourced video, instead of two parallel implementations to build and
  maintain.
- Fits ADR-018's frontend architecture without exception — headless, Tailwind-styled, no vendor
  markup imposed on the surrounding app, mounted as an ejectable island.
- No new licensing cost or vendor lock-in: MIT-licensed, and standards-based web components mean
  a future swap (e.g. to Video.js v10) does not require rearchitecting how video is consumed
  elsewhere in the app.
- No dependency on an adaptive-bitrate pipeline that doesn't exist yet — Vidstack's MP4 provider
  works directly against the plain CloudFront/MinIO URLs ADR-021 already produces.

### Negative / Trade-offs

- **Vidstack is in engineering maintenance mode.** Its own team's attention has moved to
  Video.js v10; expect security and bug fixes, not new features, for the foreseeable future.
  This is an accepted trade-off, not a discovery to be made later.
- A pre-implementation spike is required (not yet done) to verify the YouTube provider's actual
  on-screen behavior — caption handling through Vidstack's unified UI, and any residual YouTube
  branding/overlay limits the iframe still imposes underneath Vidstack's controls — and to
  measure real production bundle size via Vite's bundle analyzer rather than trusting the
  vendor-reported ~53KB gzip figure.
- Adds a third-party dependency to `motifpath-web` with its own (currently slowed) release
  cadence, one more thing the team must track for security patches even without expecting new
  features.

### Neutral

- `hls.js` and Shaka Player remain explicitly out of scope; nothing here blocks adding either if
  MotifPath later adopts adaptive-bitrate streaming.
- **Revisit trigger:** reconsider migrating from Vidstack to Video.js v10 once v10 reaches GA
  with a documented Vue integration path. Migration is expected to be comparatively low-friction
  since v10 is architecturally Vidstack's own successor.

## Related ADRs

- **ADR-018** (Frontend UI architecture) — Vidstack's headless, Tailwind-native, ejectable shape
  is chosen specifically to satisfy this ADR's constraints on new frontend dependencies.
- **ADR-021** (Content media storage strategy) — defines how the plain MP4 URLs Vidstack's
  self-hosted provider consumes are produced (presigned S3/MinIO upload, CloudFront read).

---

*This ADR was proposed on 2026-09-19. To revise, create a new ADR with Status: Supersedes
ADR-025.*
