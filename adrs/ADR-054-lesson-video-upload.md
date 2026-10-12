# ADR-054: Lesson Video Upload — One Presigned PUT of an MP4, Capped at 1 GB

**Status:** Proposed
**Date:** 2026-10-11
**Deciders:** Gilson Yamada (Product Owner, solo engineering)
**Task:** MOT-19 (PB-59; found while finishing PB-40's video lessons)

---

## Context

ADR-021 decided where content-authoring media lives (S3 behind CloudFront in production, an
S3-compatible store in local dev, per ADR-048) and how it gets there: `POST /media/upload-url` issues
a presigned PUT and the browser uploads straight to storage. That flow was designed for exercise
images and audio stimuli, a few megabytes each. It accepts only `content_type` `image` or `audio`,
sets no size limit, and the web client uploads with `fetch`, which cannot report progress.

A video lesson's `media_url` therefore has to be pasted: a YouTube link or an MP4 the teacher hosts
somewhere else. ADR-025 already chose Vidstack so that the lesson player plays both YouTube and
self-hosted MP4s, and named "teacher-uploaded lesson videos" as one of its sources. Only the upload
was never built. Since MotifPath has to show value without depending on outside teachers (the
platform-first premise), the team authors lessons too, and asking it to host files elsewhere is
friction we can remove.

Video changes the numbers ADR-021 relied on. A ten-minute 1080p lesson is several hundred megabytes,
uploads take minutes rather than seconds, and a file the browser cannot play (an iPhone `.mov` in
HEVC, for instance) would reach students as a broken player. Before any code, four things needed a
decision: the size limit and how it is enforced, one PUT or a multipart upload, which formats are
accepted, and whether anything processes the file after upload.

Alternatives considered: S3 multipart upload; accepting WebM and MOV as well; a transcoding step
(AWS Elemental MediaConvert) with generated posters; and keeping video URL-only.

## Decision

MotifPath will let teachers and admins upload a lesson's video through the existing presigned-PUT
flow, extended as follows:

1. **A new purpose, `lesson_video`.** Its objects are stored under the `lessons/` prefix. It is the
   only purpose that accepts the new `content_type` `video`, and `video` is accepted for no other
   purpose. Like `library_asset` and `thumbnail`, it takes no `exercise_id`: a new lesson has no id
   until it is saved, and the returned `object_url` simply becomes the lesson's `media_url`.
   The content-node API does not change.
2. **MP4 only.** `file_name` must end in `.mp4` (any case), and the upload is signed for
   `Content-Type: video/mp4`. The web client accepts only `video/mp4` files and asks for H.264 video
   with AAC audio. The server cannot check the codec, so the hint in the upload control carries
   that rule.
3. **At most 1 GB, enforced by storage.** A `video` request must declare `file_size` in bytes,
   between 1 and 1,073,741,824. Core rejects a larger or missing size with a validation error on
   `file_size`, and signs that exact `Content-Length` into the presigned URL, so storage rejects a
   PUT of any other size. `file_size` stays optional for images and audio, whose behaviour is
   unchanged.
4. **One PUT.** No multipart upload. A failed upload starts again from the beginning. The presigned
   URL keeps ADR-021's 15-minute lifetime: storage checks the expiry when the PUT starts, not when
   it ends.
5. **No processing.** No transcoding, no adaptive bitrate and no generated poster frame. The lesson's
   existing thumbnail is the poster students see before the video plays. CloudFront serves the MP4
   as is, with byte-range requests for seeking.
6. **The client shows progress and can cancel.** The web client uploads with `XMLHttpRequest`, the
   browser API that reports upload progress, and offers Cancel and Try again. Save waits for an
   upload in progress. The upload control is the `VideoSource` component (Figma "Authoring",
   row 15).

Out of scope, each a follow-up: deleting the object a lesson stops using (replaced, removed or
deleted lessons leave it in storage, as images and audio already do) and a per-teacher storage
quota.

## Rationale

- **One PUT over multipart.** Multipart would add three endpoints (start, sign parts, complete)
  plus an abort path, and a client that tracks parts, all to resume interrupted uploads. Authoring
  is desktop-first (MOT-61) on a home or office connection, and a single PUT reaches 5 GB, five
  times our limit. If real failures show up, multipart can be added behind the same purpose without
  changing what the content-node stores.
- **Content-Length in the signature over a server-side check after upload.** A presigned PUT cannot
  carry a size range (only a presigned POST policy can), but it can sign an exact `Content-Length`.
  Declaring the size up front lets core refuse an oversized file before a byte is sent, and makes
  storage, not the client, the final guard. A check after upload would mean storing the file first,
  plus a cleanup job.
- **1 GB.** That covers a ten- to twenty-minute lesson at 1080p with a sensible bitrate, which is
  the length MotifPath's lessons aim for. Anything larger is better split into two lessons than
  uploaded.
- **MP4/H.264 over WebM and MOV.** H.264 in MP4 plays in every browser Vidstack's MP4 provider
  supports (ADR-025). WebM still has gaps on older Safari, and MOV files from phones are often HEVC,
  which most desktop browsers cannot play. Accepting them would move the failure from the upload
  form, where the teacher can fix it, to the student's lesson.
- **No transcoding.** MediaConvert would normalise every format and generate posters, but it adds a
  vendor job, an asynchronous "processing" state on lessons, a per-minute cost and a pipeline to
  operate, ahead of any evidence that teachers upload files that need it. The thumbnail already
  gives every lesson a picture.
- **Rejected: keep video URL-only.** That keeps every teacher dependent on an outside host for MP4s
  and makes YouTube the only easy path, which brings its ads, recommendations and branding into the
  lesson.

## Consequences

### Positive

- A teacher can author a complete video lesson inside MotifPath, from file to published lesson.
- No new endpoint, schema shape or vendor: one purpose, one `content_type`, one optional field.
- Storage enforces the size limit, so a modified client cannot upload more than 1 GB.
- Students get files their browser can play, because the wrong formats are refused at upload.

### Negative / Trade-offs

- A dropped connection restarts the upload from zero, which is costly near the end of a large file.
- Files are served as uploaded. A high-bitrate upload costs more CloudFront egress and buffers on
  slow connections, and an MP4 without "fast start" takes longer to begin playing.
- The H.264 rule is guidance, not a check. An MP4 holding HEVC still uploads and will not play
  everywhere.
- Orphaned videos accumulate until the cleanup follow-up lands. Each one can be up to 1 GB, where an
  orphaned image is a few hundred kilobytes.
- `file_size` is required for one `content_type` only, a conditional rule the OpenAPI schema can
  describe but not enforce. Core's domain validation enforces it.

### Neutral

- Video storage and delivery fit within the estimate of ADR-039 at alpha volume: a hundred lessons
  of about 300 MB is around 30 GB in S3, and alpha viewing is expected to stay inside CloudFront's
  free monthly transfer. Revisit the estimate before opening sign-ups.
- Exercise demo clips (ADR-025's third video source) are not covered. They would need their own
  purpose, or `exercise_asset` widened, in a later ADR.

## Related ADRs

- **ADR-021** (Content media storage strategy): this ADR extends its presigned-PUT flow with a video
  purpose. Its bucket layout, read flow and "URL stored as is" rule are unchanged.
- **ADR-025** (Video player selection): Vidstack plays the MP4 this ADR stores. Its "no adaptive
  bitrate yet" stance is kept.
- **ADR-039** (Single-VM hosting): one media bucket and CloudFront distribution per environment;
  the cost estimate above lives there.
- **ADR-048** (mise and SeaweedFS local dev): the local store must honour the signed
  `Content-Length` the same way S3 does.

---

*This ADR was decided on 2026-10-11. To revise, create a new ADR with Status: Supersedes ADR-054.*
