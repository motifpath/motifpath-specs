# ADR-067: Voice samples are committed to motifpath-core and published by every deploy

**Status:** Proposed
**Date:** 2026-11-01
**Deciders:** Gilson (Product Owner)
**Input:** MOT-180 (production and staging had no voice samples, so every played sound failed).
PO answer, 2026-11-01: commit the rendered samples and have the deploy sync them.
**Amends:** ADR-041's "Samples live on the ADR-021 media stack" bullet, by saying how they get there.

---

## Context

ADR-041 puts voice samples at `/audio/voices/{voice_id}/{midi}.mp3` on the ADR-021 media stack,
with the `voices` table's `pitches` as the manifest. It doesn't say how the files reach a hosted
bucket. In practice only `scripts/voice-samples.sh` writes them. It renders each pitch with ffmpeg
from tonejs-instruments and uploads the result to the local object store during `make db:reset`.
Nothing uploads to staging or production. On 2026-11-01 both returned `403` for every sample, and
every metronome take and hearing exercise in production failed with "O som não carregou". They were
fixed that day by a manual `aws s3 sync` of the local render cache.

The `voices` rows come from migrations, which core-domain applies as it starts during a deploy
(ADR-005, ADR-062). The samples therefore have to change in the same release as those rows. If they
lag behind, a new voice or pitch is listed by `GET /voices` but can't be played.

The constraints:

- The VM unpacks only `deploy/` from the commit it deploys (ADR-062's deploy document). Anything
  else reaches it inside an image.
- Each environment's media IAM key can already read, write and list only that environment's media
  bucket. The deploy has that key in its rendered secrets.
- Rendering needs ffmpeg, Bash 4+ and network access to GitHub. None of these is on the VM or in the
  runtime images.
- Samples are cached as immutable at their URL (`Cache-Control: immutable`, `samplePrefetch.ts`).

## Decision

**The rendered samples are source files.** motifpath-core commits every voice's rendered MP3s at
`assets/voice-samples/{voice_id}/{midi}.mp3`. Rendering stays in `scripts/voice-samples.sh`, but it
becomes an authoring step: it writes new files into that folder, and they are committed with the
migration that adds or changes the voice. `make db:reset` uploads the committed files to the local
object store and needs no ffmpeg. The upstream recordings stay outside the repository, in a
gitignored download cache.

**The core-domain image carries them.** Its runtime stage copies `assets/voice-samples/` to
`/app/voice-samples/`, so every build has exactly the samples of its commit.

**Every deploy publishes them before the new containers start.** After pulling the images and
before `up`, `deploy/deploy.sh` copies `/app/voice-samples/` out of the core-domain image with
`docker create` and `docker cp`. It then runs `aws s3 sync` to
`s3://$MEDIA_S3_BUCKET/audio/voices/` with the environment's media key, `Content-Type: audio/mpeg`
and `Cache-Control: public, max-age=31536000, immutable`. The sync never deletes. A rollback keeps
newer files, and a URL that once served a sound keeps serving it. Once the services are healthy,
the deploy sends a `HEAD` for every published sample at `MEDIA_PUBLIC_BASE_URL`. It fails unless
each one answers `200 audio/mpeg`.

**A test holds files and manifest together.** A core-domain test applies the migrations. It fails
when a `voices` row lists a pitch that has no file under `assets/voice-samples/`, and when a file
belongs to no listed pitch.

**A sample's sound never changes at its URL.** Because of the immutable caching, re-rendering a
voice (a longer note, a better recording) means a new `voice_id`, migrated in place of the old one.
It never means overwriting the existing files.

## Rationale

- **Committed files vs. rendering in CI at deploy time.** If CI rendered the samples, every deploy
  would depend on GitHub's API and the upstream repository being up. The deploy key would also need
  write access to the buckets, which is a new permission (ADR-062 limits it to sending the deploy
  command). The bytes would also be rebuilt rather than reviewed: an ffmpeg upgrade could quietly
  change every sound. Rejected.
- **In the image vs. under `deploy/`.** `deploy/` is the only part of the commit the VM unpacks, so
  putting the samples there would also work. It would make the deploy bundle the samples' home, and
  local dev reads them from there. The image already ties a release's migrations to its commit, and
  the samples belong with the migrations that list them.
- **The deploy publishes, not core-domain at startup.** Alternatively, core-domain could embed the
  files and upload missing ones after migrating. That would give the service an asset-publishing
  side effect on every start and every replica. It would also turn an S3 outage into a readiness
  failure. The deploy already runs once per release, with the key and the bucket name.
- **A documented manual release step.** This was rejected because it's what failed: nothing forced
  the step, so it was never done.

## Consequences

### Positive
- A release can't list a voice it can't play: the sync runs before the migrations that add the
  rows, and the deploy fails if any sample is missing afterwards.
- Local setup no longer needs ffmpeg or network access to GitHub.
- Changes to the samples are reviewed in pull requests like any other content.

### Negative / Trade-offs
- About 2 MB of binary files go into motifpath-core's history, and more with each new voice. A
  re-rendered voice adds its files again.
- The core-domain image grows by the same amount.
- Each deploy spends a few seconds syncing and checking about 60 small objects. The sync uploads
  only what changed.
- Redistributing the samples is covered by CC BY 3.0 only while the attribution stays with them.
  `assets/voice-samples/` carries a README with the credit, besides the `voices` table's
  `attribution`.

### Neutral
- The bucket can hold files no voice lists any more. Nothing serves them, and they are never
  deleted.

## Related ADRs

- ADR-041: Diagram audio playback. It defines the voices, the sample path and the sampling rules,
  and this ADR amends where the samples come from.
- ADR-021: Content media storage. It covers the bucket and CloudFront the samples are served from.
- ADR-062: Alpha hosting as built. It covers the deploy document, `deploy.sh` and the per-environment
  media key.
- ADR-005: Migrations at startup. That ordering is why the sync runs before `up`.

---

*This ADR was decided on 2026-11-01. To revise, create a new ADR with Status: Supersedes ADR-067.*
