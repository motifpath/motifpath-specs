# ADR-065: Engagement emails — Amazon SES over SMTP, sent by a scheduled job in core

**Status:** Accepted
**Date:** 2026-10-26
**Deciders:** Gilson (Product Owner)
**Task:** MOT-35 (PB-79)
**Input:** PO direction, 2026-10-26: no runtime dependency on Clerk for addresses, because any
part of the architecture must stay replaceable.
**Accepted:** 2026-10-26, by Gilson.

> **2026-10-26 (amended):** the SES sandbox covers the whole AWS account, and staging and
> production share one account. So staging can't stay in the sandbox once production has
> production access. Instead, staging's mail user may send only to an allow-list of recipients.
> Each environment also gets its own sending subdomain. See decision 1.
>
> **2026-10-27 (amended):** the PO brought a daily reminder into this slice, by email. It goes out
> on the first days without activity, before the inactivity reminders start, under the same
> `reminders` preference. It sends no daily email to a student who has stopped. It reuses the
> job, the stored time zone and the send claim unchanged. Push (MOT-177) can take the daily
> reminder over later. See Consequences → Neutral.

---

## Context

MOT-35 tests whether emails sent by the platform raise 7-day return and reduce churn from month 2
to month 6. The first slice has three emails:

- a **weekly progress report** to each student;
- an **inactivity nudge** to a student who has stopped practising, and (amended 2026-10-27) a
  **daily reminder** on the first days without activity;
- a **weekly student summary** to the concierge, the team that coaches alpha students over
  WhatsApp (PB-78).

Invitations and sign-in emails are Clerk's and stay that way. MotifPath sends no email of its own
today. Four facts about the current system shape this decision:

1. **Core has no email addresses.** Users sign in with Google through Clerk (ADR-007). `User`
   holds `clerk_user_id`. The address lives only in Clerk.
2. **Both student emails depend on time, not on events.** A nudge goes out because events *stopped*
   arriving. A report summarises a week. Nothing on `motifpath.events` (ADR-006) marks either
   moment.
3. **The figures already exist.** The home overview (ADR-051) already computes minutes practised,
   practice days and the day streak from the worker's aggregates. It needs the student's time
   zone, which the client sends on every request. That zone is never stored, so no server-side
   job knows it.
4. **One VM in one AWS account in `us-east-2` hosts both environments** (ADR-039, ADR-062). Containers cannot
   use the instance role. Each needs an IAM user whose key is stored in the environment's
   parameters. `motifpath.com` sits in Route 53 with `_dmarc` at `p=reject`. Business mail at
   GoDaddy and Clerk's mail records already use the root domain.

The alternatives were Resend or Amazon SES as the provider, and a Kafka consumer or a scheduled
job as the trigger.

## Decision

MotifPath will send engagement emails through **Amazon SES's SMTP interface**. A **scheduled job
in `motifpath-core`** decides who gets which email.

1. **Provider: Amazon SES in `us-east-2`.** Each environment sends from its own subdomain:
   production from `mail.motifpath.com`, staging from `mail.staging.motifpath.com`. Each one has
   its own Easy DKIM records and a custom MAIL FROM domain (`bounce.mail.…`), so SPF and DKIM both
   align under `p=reject`. The root domain's GoDaddy and Clerk records stay as they are. Each
   environment has its own **mail IAM user**, allowed only `ses:SendRawEmail` from its own
   identity. Its SMTP credentials go in the environment's parameters. The account requests
   production access, which production needs. The sandbox covers the whole account, so it can't
   guard staging. Instead, **staging's mail user may only send to an allow-list of recipients**
   (the team's domain and named test addresses), enforced by an IAM condition on the recipients.
   Bounces and complaints rely on SES's account-level suppression list. There is no SNS feedback
   pipeline in this slice.
2. **One SMTP adapter everywhere.** Core sends through an `EmailSender` port with a single SMTP
   adapter. Locally it points at **Mailpit**, which joins the local stack (ADR-016, ADR-048). In
   staging and production it points at SES SMTP. Tests and local runs exercise the same code path
   as production.
3. **Trigger: a scheduled job, not a Kafka consumer.** A new `engagement-mailer` service, built
   from the `core-domain` module, runs in each environment's Compose project. Every hour it:
   1. finds the students whose **local time** has reached a send window;
   2. evaluates each email's rule from the same aggregates that serve the home overview;
   3. **claims** each send by inserting a row into a Postgres `email_send` table. The row is unique
      on `(user_id, kind, period_key)`, where `period_key` is the ISO week for a report or the
      start date of the inactive spell for a nudge;
   4. sends the email only when the claim succeeds.

   Sending is at-most-once: a crash after the claim loses that email and never duplicates it.
   `email_send` also records which student got which email and when, which the cohort comparison
   needs. The exact thresholds and windows (for example, nudge after 3 and 10 days without
   practice, report on Monday at 09:00 local time) belong in the feature spec, not here.
4. **Core stores each user's email address, the same way it stores the name (ADR-035).** The
   session-token template adds an `email` claim with the user's primary address. `users.email`
   holds it. `POST /users` stores the claim at registration. On every authenticated request,
   the caller-resolution step writes it when it differs from the stored value. A missing or
   empty claim never overwrites a stored address. Users created outside sign-up (seeds, the admin
   setup step) get theirs the way they get a name. The mailer reads addresses only from core's
   database and never calls the identity provider. Replacing Clerk then needs only a provider
   that issues an email claim, which every OIDC provider does (`email` is a standard claim).
5. **Core stores the student's time zone.** `User` gains an optional `time_zone` (IANA). The web
   client sets it through `PATCH /users/me` when the browser's zone differs from the stored one.
   When it is unset, the job uses `America/Sao_Paulo`.
6. **Preferences and one-click unsubscribe (LGPD).** `User` gains one opt-out flag per student
   email kind: `email_progress_report` and `email_reminders`, both on by default. Every email
   carries `List-Unsubscribe` and `List-Unsubscribe-Post` (RFC 8058). The unsubscribe link holds an
   HMAC-signed token naming the user and the kind. It turns that kind off with no sign-in. The
   student can switch either flag back on in settings. The concierge summary goes only to a
   configured team address (`CONCIERGE_EMAIL`) and has no student preference.
7. **Localized templates.** Templates are Go `html/template` with a plain-text alternative part.
   Text comes from per-locale message catalogs in core, chosen by the user's locale (ADR-024).
   `en` is canonical and `pt-BR` is required. Copy follows ADR-049's practice-first language and
   ADR-051's rule: **no email ever says a streak was lost**.

## Rationale

**SES over Resend.** Resend has the better developer experience, React email templates and a free
tier (3,000 emails a month) that covers the alpha. But it is one more vendor, with its own data
processing agreement for LGPD, its own account and its own API key outside Terraform. SES is in
the AWS account that already holds DNS, IAM and the parameters (ADR-062). Its domain identity,
DKIM records and IAM user are Terraform resources next to the existing ones. It costs $0.10 per
1,000 emails at any volume. SES's weaker parts are the production-access request and a rawer API.
Using SMTP hides the raw API. Staging's recipient allow-list does what the sandbox would have done,
and keeps doing it after the account leaves the sandbox.

**SMTP over the SES API.** The SES v2 API would need an AWS SDK adapter for production and a
second adapter for Mailpit. SMTP is one adapter for every environment, set by configuration only.
The SES API features we give up (templates stored in SES, configuration sets) are not needed in
this slice.

**A scheduled job over a Kafka consumer.** Kafka has no event for "nothing happened for 3 days" or
"it is Monday at 09:00 in São Paulo". A consumer would have to keep per-student activity state.
That state would duplicate the aggregation worker's and still need a timer to fire on. The job
reads the figures the home already shows, so the email and the home can never disagree. Emails
that follow an event (for example, "you finished a course") can later get a consumer group of
their own. That would add a trigger without replacing this one.

**A separate service over a goroutine in `core-domain`.** A ticker inside the API process would tie
email to API restarts and deploys, and would run twice if the API ever ran two replicas. A
separate container can be stopped alone, as a kill switch. Building it from the `core-domain`
module reuses the ent client, the repositories and the overview logic without an HTTP hop.

**A copy in core over a lookup in Clerk at send time.** Looking addresses up through Clerk's
Backend API would avoid a copy. But the mailer would then depend on Clerk at runtime and on a
Clerk-specific API, and replacing Clerk would mean rewriting the mailer. Any part of the
architecture must stay replaceable. With the copy, the only contract with the identity
provider is a token claim, the same contract the name already uses. A Clerk webhook could keep
the copy in sync too, but it would be another Clerk-specific integration and another endpoint to
secure. The claim needs neither, because the token is already signed and verified.

**Opt-out over opt-in.** Under LGPD, the progress report and reminders are product
communications sent on legitimate interest (Art. 7, IX), with an easy opt-out. Opt-in would leave
most of the cohort unmailed and the hypothesis untestable. This is a product and legal call,
recorded here for review.

## Consequences

### Positive
- No new vendor. Email infrastructure is Terraform in the existing account and costs cents.
- Local, staging and production send through the same code. Mailpit makes every email visible
  locally.
- The `email_send` claim gives at-most-once delivery and the cohort record from one table.
- The emails show the same figures as the home.
- The sending identity on `mail.` keeps engagement mail's reputation apart from business mail
  and Clerk's.

### Negative / Trade-offs
- SES production access is a manual request that AWS can refuse or delay. It gates the first
  production send. Before the infra work starts, we also need to confirm that SES is available on
  the AWS project's plan, since the new AWS experience doesn't offer every service.
- Without an SNS feedback pipeline, bounces and complaints are only visible in the SES console. A
  rising complaint rate would not alert anyone.
- One more container per environment on the single VM, and one more service to build and deploy.
- Core now holds a second piece of personal data, the email address. Like the name, it must be
  covered by the data inventory and deleted with the user.
- An address changed at the identity provider reaches core only on the user's next request. An
  inactive student, the one a nudge targets, gets the last address core saw.
- `User` gains `email`, `time_zone` and two preference flags, and the web client gains a call that reports
  the zone. A student who never opens the app after this ships gets emails timed in
  `America/Sao_Paulo`.
- At-most-once means a crash between the claim and the send drops that email silently.
- Email copy is translated in core, apart from the web's vue-i18n files. Two places hold
  user-facing strings.
- The alpha cohort is small. A comparison between emailed students and a baseline will be
  directional, not statistically conclusive.

### Neutral
- Clerk keeps invitations and sign-in emails. The two senders share no code.
- WhatsApp templates for nudges remain a possible later test. They would be a second
  `EmailSender`-like port, not a change to the trigger.
- The settings page needs a design for the two preferences before any UI work.
- The daily reminder goes out by email, at a fixed local time, on the first days without
  activity only (thresholds in the feature spec). A reminder at a time the student chooses, and
  moving the daily reminder to push, stay with MOT-177. Email then keeps only the inactivity
  reminders.

## Related ADRs

- ADR-006: Kafka topology — the event stream this ADR chooses not to use as a trigger
- ADR-007: Clerk auth — the issuer of the email claim and the owner of auth emails
- ADR-035: User display names — the claim-to-column pattern this ADR reuses for email
- ADR-016 / ADR-048: Local dev stack — Mailpit joins it
- ADR-024: i18n — user locale and the `en`/`pt-BR` requirement
- ADR-039 / ADR-062: Hosting — the VM, the Compose projects, IAM users and parameters, the Route
  53 zone
- ADR-046 / ADR-051: Practice days, minutes and streak — the figures the emails report, and the
  "never say a streak was lost" rule
- ADR-049: Practice-first language — tone of the copy

---

*This ADR was decided on 2026-10-26. To revise, create a new ADR with Status: Supersedes ADR-065.*
