# ADR-048: Local dev toolchain via mise; SeaweedFS as the local S3 stand-in

**Status:** Proposed
**Date:** 2026-10-04
**Deciders:** Gilson (Product Owner)
**Supersedes (in part):** ADR-010 (Atlas via `devbox.json`), ADR-016 (process-compose bundled
with Devbox, `devbox services up`), ADR-021 (MinIO in local dev)

---

## Context

Two parts of `motifpath-core`'s local dev environment stopped working on a fresh machine in
October 2026.

**MinIO's images are gone.** `quay.io/minio/minio` and `quay.io/minio/mc` answer 401, and the
Docker Hub repositories were deleted. `make dev` only succeeds on a machine that already has the
images cached, so no new contributor (and no reinstalled laptop) can start the stack. ADR-021
chose MinIO as the local stand-in for S3 + CloudFront; the reason for that choice — one S3 API in
every environment, so no upload/read code branches on environment — still holds. Only the
product filling the role has to change.

**Devbox cannot serve Intel Macs.** nixpkgs 26.11 dropped `x86_64-darwin`, and four of the six
tools pinned in `devbox.json` (Go 1.27, golangci-lint 2.13.1, Node 26, wgo 0.7.1) have no Intel
Mac build. ADR-016 relied on Devbox to ship process-compose, and ADR-010 put the Atlas CLI in
`devbox.json`; both now inherit the same gap.

Constraints: production is unaffected (S3 + CloudFront per ADR-021, images built by CI per
ADR-016); service `.env` files, the bucket name, port 9000 and the dev credentials should stay
the same so no service configuration changes; and the tool versions stay pinned per repository,
which is what Devbox gave us.

## Decision

**Toolchain.** `motifpath-core` will pin its toolchain in a committed `mise.toml` and developers
will install it with [mise](https://mise.jdx.dev) (`mise trust && mise install`). Go and Node
come from mise's own backends; golangci-lint, oapi-codegen, wgo and process-compose are built
from source with mise's `go:` backend, so they run on every platform Go supports. The versions
are the ones `devbox.json` pinned. `mise.toml` also carries the dev environment variables the
tooling needs (`PC_PORT_NUM=8099`, so process-compose's own API stops colliding with
`core-domain` on 8080) and task shortcuts: `mise run services` replaces `devbox services up`, and
`mise run full` starts the full-stack profile.

The Atlas CLI is installed separately (Atlas's installer, pinned to the same version as
`services/core-domain/Dockerfile`, bumped in both places together). GNU `timeout`, Bash 4+ and
ffmpeg — which Nix used to supply implicitly — are documented prerequisites in the
`motifpath-core` README.

**Local object store.** `motifpath-core`'s `docker-compose.yml` will run
[SeaweedFS](https://github.com/seaweedfs/seaweedfs) (`weed server` with its S3 gateway on port
9000) in place of MinIO, as the `objectstore` service. A one-shot `objectstore-init` container
running the official AWS CLI image creates the `motifpath-content-media` bucket. Access is
declared in the gateway's identity file: the `motifpath` key pair has full access, and anonymous
callers can only read objects in the media bucket — the dev stand-in for CloudFront public reads
that ADR-021 described. The gateway answers CORS itself, because browser uploads go straight to
the presigned PUT URL.

Everything else in ADR-010, ADR-016 and ADR-021 is unchanged.

## Rationale

**mise over the alternatives:**
- *Keep Devbox, pin an older nixpkgs.* Only defers the problem: no new Intel builds will ever be
  published, so every future version bump re-opens it.
- *Homebrew.* Installs one global version per machine, so per-repo pinning — the property we
  chose Devbox for — is lost.
- *asdf.* Same plugin model mise is compatible with, but has no equivalent of `[env]` or
  `[tasks]`, which this repo uses for `PC_PORT_NUM` and the process-compose shortcuts.
- *A dev container.* Would cover every OS, but Go services, `wgo` reloads and the debugger would
  run inside a VM on macOS, which is exactly the inner-loop cost ADR-016 chose processes to avoid.

**SeaweedFS over the alternatives:**
- *Keep MinIO from a locally cached image, or build it from source.* Neither works for a new
  machine, which is the case that broke.
- *LocalStack.* Emulates all of AWS behind one container; much more surface than the one S3
  bucket we need.
- *Garage.* Needs a cluster layout and key creation through its own CLI before a bucket can
  exist, so the init step grows instead of shrinking.

SeaweedFS runs as a single container, ships an S3 gateway that accepts the existing credentials
and port, and supports the features the authoring flow uses: presigned PUT, CORS, and anonymous
object reads. Those were verified end to end on an Intel Mac (image upload from exercise
authoring, diagram audio playback).

## Consequences

### Positive
- `make dev` works again on a fresh machine, and the toolchain installs on Intel Macs.
- No service `.env` file, bucket name, port or credential changes; production is untouched.
- Atlas's local version now matches the Dockerfile's (Devbox had pinned 0.28 against the image's
  1.3.2).
- No Nix bootstrap and no `sudo` prompt to install the toolchain.

### Negative / Trade-offs
- mise does not provide Atlas, GNU `timeout`, Bash 4+ or ffmpeg; each developer installs them,
  and macOS needs all of them except Atlas from outside the base system.
- The first `mise install` compiles the Go-based tools locally, which takes a few minutes.
- Every developer has to switch from Devbox to mise once. Media uploaded to the old `minio_data`
  volume does not carry over.
- SeaweedFS's S3 gateway is less widely used than MinIO; an S3 feature we start relying on
  later (for example multipart uploads or object tagging) needs checking against it before we
  assume local dev covers it.
- `PC_PORT_NUM` is only set inside mise's environment; calling `process-compose` outside mise
  needs `-p 8099`.

### Neutral
- `process-compose.yaml` itself is unchanged apart from names; ADR-016's orchestration model
  (dependency containers in Docker Compose, services as processes) still holds.
- CI never used Devbox (`setup-go` plus `go install`), so it is unaffected.

## Related ADRs

- **ADR-010** (Atlas CLI for ent migrations): the Atlas CLI is no longer installed through
  `devbox.json`; the rest of the migration workflow stands.
- **ADR-016** (local dev orchestration): process-compose is installed through mise instead of
  Devbox, and `mise run services` / `mise run full` replace `devbox services up`.
- **ADR-021** (content media storage): SeaweedFS replaces MinIO in local dev; production S3 +
  CloudFront is unchanged.

---

*This ADR was decided on 2026-10-04. To revise, create a new ADR with Status: Supersedes ADR-048.*
