# Spike Findings: PB-8e — Vidstack for the student lesson screen

**Task:** PB-8e (Notion ID PB-21) — Phase 0 of `plans/PB-8e-lesson-consumption-and-tracking.md`
**Date:** 2026-09-21
**Author:** Gilson
**ADR:** ADR-025 (Vidstack adopted; this spike is its required pre-implementation check)
**Spike branch:** `motifpath-web@spike/PB-8e/vidstack` (throwaway — not for merge; delete after this note lands)

---

## Summary

Built a scratch page (separate Vite entry, `vidstack@1.15.6`, headless — `vidstack/player`,
`vidstack/player/ui`, `vidstack/player/styles/base.css`, no default skin) that plays an MP4 and a
YouTube video through the same `<media-player>`, derives two fake cues from `currentTime`, and
records timing. Driven by headless Chrome (Playwright) against a **production build**.

**Recommendation: proceed with Vidstack as ADR-025 decided. ADR-025's documented fallback
(native `<video>` + `vue3-youtube`) is not needed.** Four things must go into the Phase 3 plan
(see "Consequences for Phase 3"); one of them — the npm dist-tag — is a trap.

| ADR-025 check | Result |
|---|---|
| One unified UI for MP4 and YouTube | **Validated.** Same element, same events (`time-update`, `seeked`, `ended`, `error`, `provider-change`); provider resolves to `video` / `youtube` from the `src` alone |
| YouTube residual branding | **Acceptable, with two documented limits** (below) |
| YouTube captions through Vidstack's UI | **Not available.** `textTracks.length === 0` on the YouTube provider — captions can't be driven by Vidstack's unified caption UI |
| Real bundle size | **~79 kB gzip eager, not ~53 kB** (below) |
| Works in Vue 3 with no wrapper package | **Validated**, needs one compiler option (below) |

---

## Finding 1 — Cue timing is good enough for both sources

Cue visibility was derived purely from `currentTime` (`trigger <= t < hide`), no stored cue state.

| | MP4 (local and cross-origin) | YouTube |
|---|---|---|
| `time-update` interval (p50) | **~17 ms** (animation-frame rate) | **~265 ms** (p95 ~600 ms) |
| Cue shown after its trigger | 2–8 ms late | 35–195 ms late |
| Seek before trigger → cue hidden | yes | yes |
| Seek back into window → cue re-shown | yes | yes |
| Seek past hide → cue hidden | yes | yes |
| Playback paused by cue changes | never | never |
| `ended` fires | yes | yes (seek to `duration - 2`) |

YouTube's ~0.3 s worst-case lateness is fine for lesson cues (teacher-authored to whole seconds).
It would matter only if cues needed sub-second sync — note it if authoring ever allows that.

## Finding 2 — YouTube branding: clean while playing and after the end, two limits remain

With Vidstack's own `base.css` **left unmodified**, the iframe is oversized (`height: 1000%`) and
centred inside an `overflow: hidden` provider, which crops YouTube's title bar, channel avatar and
control bar out of view. The provider also injects a `.vds-blocker` overlay, and marks the iframe
`data-no-controls`.

- **Playing:** no YouTube title, avatar, logo or controls visible.
- **Ended:** fully covered by the blocker's black background — YouTube's suggested-videos screen
  never shows.
- **Limit 1 — paused:** YouTube's own round play glyph shows over the video (it's drawn inside
  the iframe; can't be removed). No title or logo, just the glyph.
- **Limit 2 — clicks:** the iframe keeps `pointer-events: auto`. Without a gesture overlay a
  student can click straight into YouTube's UI. Adding
  `<media-gesture event="pointerup" action="toggle:paused">` above the provider fixes it
  (verified: a click on the video area toggled playback through Vidstack).

**A wrong turn worth recording:** my first attempts put inline styles on `<media-provider>`
(`display: block`). That broke the provider's flex centring, the crop stopped working, and
YouTube's title bar and a 300×150 iframe showed — which looked like the residual-branding failure
ADR-025 feared. It wasn't; it was self-inflicted. **Do not override provider layout; style the
player and the controls only.**

## Finding 3 — Bundle: ~79 kB gzip, not ~53 kB

Measured with two production builds (`vite build`), a Vue-only baseline against the same entry
with Vidstack, gzip sizes from Vite's output:

| Build | Entry chunk (gzip) | Delta over Vue-only baseline (24.6 kB) |
|---|---|---|
| Vue only | 24.6 kB | — |
| Vidstack core (`vidstack/player`) | 61.9 kB | **+37.3 kB** |
| Core + all UI elements (`vidstack/player/ui`) | 103.4 kB | **+78.8 kB** |

- The vendor's ~53 kB claim is not reproduced; `player/ui` alone is ~41 kB gzip because it is a
  side-effect import that registers every control element (no per-control tree-shaking).
- Provider chunks are lazy and only fetched when used: an MP4 run loaded `video` (1.7 kB gzip),
  a YouTube run loaded `youtube` (2.4 kB gzip). **HLS, DASH, Vimeo and Google Cast (~14 kB gzip
  combined) were never requested.**
- Cost is acceptable **only if lazy**: load the player in the lesson route, not in the shared
  app chunk, so the path screen doesn't pay it.

## Finding 4 — Vue integration works with one compiler option and no wrapper

`<media-player>`, `<media-provider>` and the control elements work as native custom elements in
Vue 3 templates with `@time-update`, `@ended` etc. bound directly. Requires
`compilerOptions.isCustomElement: (tag) => tag.startsWith('media-')` in the Vue plugin config
(the real `vite.config.ts` doesn't have it yet). Event payloads arrive as `CustomEvent` with
`detail.currentTime`, so handlers need `CustomEvent<...>`-typed parameters under `strict`.

## Not verified (state of the evidence)

- **Headless Chrome only.** No Firefox, Safari or iOS Safari (fullscreen and `playsinline`
  behaviour differ there).
- **MP4 hosts:** a local file and a cross-origin CDN (MDN) — **not** a real CloudFront URL from
  ADR-021. CORS is only needed if `crossorigin` is set on the player; the spike set it and MDN
  allowed it. If the lesson player omits `crossorigin`, CloudFront needs no CORS headers.
- **Captions on MP4 (`.vtt` tracks)** untested; only relevant if teachers can upload them.
- **Portrait layout** not rendered; the cue layout is plain CSS (flex row/column) and unaffected
  by the player.
- One unexplained `404` console line appeared in early MP4 runs; a later run with a response
  listener showed no HTTP error (likely the browser's automatic `favicon.ico`, which the dev
  server doesn't serve — `curl` confirms a 404 there).

## Consequences for Phase 3

1. **Install the right line.** `npm i vidstack` gives **0.6.15** (the old `latest` tag). The 1.x
   line ADR-025 describes lives under the **`next`** dist-tag. Pin exactly (`1.15.6`, no caret).
2. **Import `vidstack/player`, `vidstack/player/ui`, `vidstack/player/styles/base.css`**, and set
   `isCustomElement` for `media-*` in the Vue plugin options.
3. **Never restyle `<media-provider>`.** Give the player its size; overlay controls and a
   `<media-gesture>` (toggle pause) absolutely inside the player, above the provider.
4. **Lazy-load the player** (`defineAsyncComponent` or a lazy route) — 79 kB gzip must not land in
   the main chunk.
5. **Styling rules still apply** in real code (`CLAUDE.md`): Tailwind utilities and tokens only —
   the spike's inline styles are throwaway.
6. **YouTube captions** are not controllable through Vidstack: decide whether the alpha needs
   them (YouTube's `cc_load_policy` is currently `undefined` in the embed URL).

## Decision

Vidstack stands. No ADR change needed; consider a one-line ADR-025 amendment recording the
`next` dist-tag, the measured ~79 kB gzip figure and the no-YouTube-captions limit.
