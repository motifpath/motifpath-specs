# ADR-021: Content media storage strategy — dev & production

**Status:** Accepted
**Date:** 2026-09-13
**Deciders:** Gilson (Product Owner)

---

## Context

PB-40's exercise-authoring implementation plan (`plans/PB-40-exercise-authoring-implementation.md`,
PR #48, currently on hold) surfaced a gap while scoping its authoring UI: nobody had ever
decided where exercise/prompt images, audio stimuli, or the predefined image-picker library
are actually stored, in either environment. Every existing content schema in
`core-domain-service.yaml` (`ExpandedContent`, and the exercise types added by ADR-019)
references media through a plain `media_url` / `image_url` / `audio_url` string — an
already-hosted URL, with no upload endpoint anywhere in the spec. PB-40's plan initially
papered over this by deferring to that pattern, but the pattern itself was never a deliberate
decision for content-authoring assets specifically; it was just "some URL exists somewhere,"
inherited from schemas where the asset was assumed to be hosted externally by whoever wrote
the content.

PB-40's builder needs three concrete capabilities the current pattern doesn't support: (1)
uploading a new image or audio file for a specific exercise (`image_recognition` regions,
`image_choice` custom options, `audio_recognition` stimuli), (2) picking from a *predefined*,
curated image library reused across exercises, and (3) doing both against a local dev
environment that doesn't have real AWS credentials.

Three constraints frame the decision:

1. **The frontend is already committed to S3 + CloudFront** (Platform Architecture), and
   `motifpath-infra` already uses S3 for Terraform state — an S3-based approach adds no new
   vendor to the stack.
2. **PB-8a (compute hosting) is explicitly on hold** — "the alpha will use a simpler hosting
   approach than full EKS/Terraform (TBD)." Object storage is independent of what runs the
   application containers, so this decision does not need to wait on PB-8a.
3. **ADR-016 established the pattern of mirroring production services locally** (Postgres,
   MongoDB, Redpanda all run via `docker-compose` in dev) specifically so upload/read code
   never has to branch on environment.

Alternatives considered at a high level: a managed media service (e.g. Cloudinary), storing
files as database blobs, and continuing to defer storage entirely (URL-paste only, no upload).

## Decision

MotifPath will store content-authoring media (exercise/prompt images, audio stimuli, and the
predefined image-picker library) in **S3 in production, fronted by CloudFront for reads**, and
in **MinIO (S3-compatible) in local dev**, added to `motifpath-core`'s `docker-compose.yml`
alongside Postgres/MongoDB/Redpanda. Both environments speak the same S3 API, so no
upload/read code branches on environment.

1. **Bucket layout:** one bucket per environment, prefixed by asset purpose —
   `exercises/{exercise_id}/...` for exercise-specific uploads, `library/...` for the curated,
   reusable image-picker library.
2. **Upload flow:** `core-domain` issues a short-lived **presigned PUT URL** via a new
   endpoint (`POST /media/upload-url` or equivalent — to be added to
   `openapi/core-domain-service.yaml` in a follow-up spec change, not part of this ADR). The
   browser uploads the file directly to S3/MinIO; no file bytes are ever proxied through a Go
   service.
3. **Read flow:** the resulting object is referenced by its CloudFront URL in production (or
   MinIO's local-equivalent URL in dev), stored as-is in the existing `media_url` /
   `image_url` / `audio_url` string fields. **This is not an OpenAPI schema shape change** —
   only how those URL fields get populated changes, from "paste an external URL" to "upload,
   then the URL is handed back."
4. **Upload vs. URL-paste, split by use case:** exercise-specific images/audio use the real
   upload flow described above. The predefined image-picker library is *also* backed by real
   S3/MinIO storage — curated and uploaded once by the concierge team — and referenced the
   same way, rather than allowing URL-paste to arbitrary external hosts for library images.

## Rationale

S3 + CloudFront (MinIO locally) was chosen over the alternatives because:

- It reuses infrastructure the platform has already committed to (frontend hosting,
  Terraform state) rather than introducing a new vendor or service to operate and pay for.
- The presigned-URL upload pattern mirrors ADR-020's "upload-not-base64" precedent from the
  Tiptap editor decision — direct-to-storage upload is already the project's chosen shape for
  this problem, not a new pattern invented here.
- MinIO's S3-compatible API means the upload/read code path is identical in dev and
  production, consistent with ADR-016's rationale for running Postgres/MongoDB/Redpanda
  locally instead of pointing dev at hosted equivalents.
- It does not require resolving PB-8a first — object storage has no dependency on the
  eventual compute hosting target.

**Rejected alternative — managed media service (e.g. Cloudinary).** Offers image
transformation and CDN out of the box, but introduces a new vendor, a new cost line, and a new
credential to manage for a capability (basic image/audio hosting with no transform
requirements yet) that S3 + CloudFront already covers. Revisit if a real
transformation/optimization need emerges later.

**Rejected alternative — database blob storage.** Simplest to wire up (no new
infrastructure), but a poor fit for audio files specifically, and bloats Postgres backups with
binary data that has nothing to do with the relational domain model.

**Rejected alternative — continue deferring (URL-paste only, no upload).** This is the
status quo PB-40's plan initially fell back to. It blocks the actual authoring workflow
Gilson wants (upload a file, don't require it to already be hosted somewhere else first) and
leaves the predefined image-picker library with no real storage to curate images into.

## Consequences

### Positive

- PB-40's on-hold implementation plan (PR #48) is unblocked — `image_url` / `audio_url`
  population can move from "paste a URL" to a real upload flow without changing the OpenAPI
  schema shape already drafted there.
- No bytes are proxied through `core-domain` or `event-ingestion`; presigned uploads keep the
  Go services out of the request path for large files.
- Local dev exercises the same upload/read code as production, closing a class of
  "works in dev, breaks in prod" bugs before they can occur.
- No new vendor or credential type is introduced — S3 is already used elsewhere in the stack.

### Negative / Trade-offs

- A new core-domain endpoint (presigned-URL issuance) must be designed and specified before
  PB-40's Phase 3 authoring UI can be built against it — this ADR does not include that spec
  change.
- MinIO is one more container in `docker-compose.yml`, adding to local dev's resource
  footprint and startup time (mitigated by ADR-016's existing healthcheck-gated startup
  pattern).
- Presigned uploads require the client to handle upload failure/retry itself (the browser
  talks to S3/MinIO directly, not through `core-domain`), which is new error-handling surface
  the authoring UI must cover.

### Neutral

- The predefined image-picker library is curated content-team data, not user-generated — it
  has no moderation or abuse-prevention requirement the way arbitrary user uploads might.

## Related ADRs

- **ADR-016** (Local dev orchestration) — this decision follows the same "mirror production
  services locally" pattern MinIO extends to object storage.
- **ADR-019** (Practice content model) — defines the exercise types (`image_recognition`,
  `image_choice`, `audio_recognition`) whose media this ADR provides real storage for; ADR-019
  itself made no storage decision.
- **ADR-020** (Content-authoring text editor) — established the "upload-not-base64" precedent
  this ADR's presigned-upload flow follows.

---

*This ADR was decided on 2026-09-13. To revise, create a new ADR with Status: Supersedes
ADR-021.*
