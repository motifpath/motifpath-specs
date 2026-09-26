# ADR-039: Single-VM cloud hosting with co-located staging and production

**Status:** Proposed
**Date:** 2026-09-26
**Deciders:** Gilson (PO), Claude Code

---

## Context

MotifPath has never been deployed to the cloud. PB-8a (deployment & hosting) has been on hold
since the alpha was scoped, with the note that "the alpha will use a simpler hosting approach than
full EKS/Terraform (TBD)" (recorded in ADR-016 and ADR-021). The only written deployment design is
ADR-004 together with the `motifpath-infra` README: EKS in two separate AWS accounts, blue/green
cutover via Service selectors, AWS Secrets Manager, and MSK for Kafka (ADR-006). None of it was
built. `motifpath-infra` contains no Terraform modules or environments, and no repository contains
Kubernetes manifests or image build/deploy workflows.

What has to run is known and stable. There are three Go services in `motifpath-core`:
`core-domain` (:8080), `event-ingestion` (:8081) and `aggregation-worker` (:8082). They depend on
Postgres, MongoDB and a Kafka-compatible broker, whose topic `motifpath.events` and consumer group
`aggregation-worker` are hard-coded. Media lives in S3 (ADR-021). The Vue SPA is static assets that
call two base URLs (`VITE_CORE_API_URL`, `VITE_EVENTS_API_URL`). Clerk provides authentication. All
three services already expose health endpoints (PB-30) and have image-boot smoke coverage
(ADR-016), so hosting is no longer blocked on them.

Cost is the constraint that drives this decision. Building ADR-004's design for two environments
costs roughly $400–600/month before a single student arrives: an EKS control plane is ~$73/month
per cluster before any node, MSK's smallest cluster is ~$65–100/month, a NAT gateway is
~$32/month, and Atlas M10 is ~$57/month. For an alpha with tens of students, run by a solo
developer, most of that is fixed overhead, not capacity.

The PO still requires a real **staging** environment. It is not a disposable copy: a local database
is reset at will, but staging keeps its data across releases. Staging is where every migration
first runs against aged data, and where a release is checked before it reaches production.
Dropping staging to save money was considered and rejected on those grounds. The alternatives
considered were ADR-004 as written (EKS), ECS on Fargate, a PaaS (Fly.io, Render, Railway), a
cloud staging database with no staging services, and a single VM hosting both environments.

## Decision

MotifPath will host its alpha on **AWS in `us-east-1`, using a single EC2 instance that runs both
the staging and production environments** as two isolated Docker Compose projects. Managed data
stores and static hosting sit alongside the instance.

### Topology

| Concern | Production | Staging |
|---|---|---|
| Go services | Compose project `production` on the VM | Compose project `staging` on the same VM |
| Kafka | Its own single-node Redpanda container | Its own single-node Redpanda container |
| Postgres | Database `motifpath_production` on a shared RDS instance, own DB user | Database `motifpath_staging` on the same instance, own DB user |
| MongoDB | Atlas **Flex** cluster | Atlas **M0** (free) cluster |
| Media (ADR-021) | S3 bucket + CloudFront | Separate S3 bucket + CloudFront |
| SPA | S3 bucket + CloudFront | Separate S3 bucket + CloudFront |
| Clerk | Production instance | Development instance |

- **VM:** one `t4g.medium`-class (arm64) EC2 instance in a public subnet, with an Elastic IP.
  There is no NAT gateway and no load balancer. Images are built for `linux/arm64`. Each container
  has memory and CPU limits, so staging cannot starve production of resources.
- **Ingress:** Caddy on the VM terminates TLS (with automatic certificates) and routes by
  hostname to the right Compose project. Only ports 80 and 443 are open. No SSH port is open;
  shell and deploy access go through SSM Session Manager and Run Command.
- **RDS:** one `db.t4g.micro` Postgres 16 instance, single-AZ, with 7-day automated backups. It is
  not publicly accessible; only the VM's security group can reach it.
- **Atlas:** clusters in AWS `us-east-1`. Access is allow-listed to the VM's Elastic IP.
- **Redpanda:** one container per environment, because the topic and consumer-group names are
  hard-coded and must not collide. Each has its own data volume on the instance's EBS disk.
  MongoDB `events` stays the store of record (ADR-008), so broker data can be lost and replayed.

### DNS

The `motifpath.com` zone is hosted in Route 53. The domain stays registered at GoDaddy, which today
also serves its DNS (`ns57`/`ns58.domaincontrol.com`). Terraform creates the Route 53 hosted zone,
and then the domain's nameservers are switched **once, manually, in GoDaddy** to the four
nameservers Route 53 assigns. From then on, every record is managed in Route 53 by Terraform.

| Host | Serves |
|---|---|
| `app.motifpath.com` / `staging.motifpath.com` | SPA |
| `api.motifpath.com` / `api.staging.motifpath.com` | `core-domain` |
| `events.motifpath.com` / `events.staging.motifpath.com` | `event-ingestion` |
| `media.motifpath.com` / `media.staging.motifpath.com` | Media CloudFront |
| `motifpath.com` / `www.motifpath.com` | Permanent redirect to `app.motifpath.com`, served by Caddy |

The Clerk production instance's DNS records also live in this zone. Its DKIM records must exist
before Clerk sends production email, because the domain's DMARC policy is `p=quarantine`.

GoDaddy's existing records are handled as follows when the nameservers switch:

- **A `@` (GoDaddy Website Builder):** dropped. Nothing is published there. The apex points to
  the VM and redirects to the SPA.
- **CNAME `www`:** replaced by the redirect above.
- **TXT `_dmarc`:** kept, with `rua` reports sent to a MotifPath address instead of GoDaddy's.
- **CNAME `_domainconnect`:** dropped. It only serves GoDaddy's own auto-configuration.
- **NS and SOA:** replaced by Route 53's own.

Nothing is live on the domain, so the switch causes no user-visible outage.

### Accounts, state and secrets

- **One AWS account.** Staging and production are separated by Terraform state, resource names,
  the `environment` tag, and IAM policies scoped per environment.
- **Terraform** keeps each environment's state in S3 and uses S3-native state locking
  (Terraform ≥ 1.10), so no DynamoDB table is needed.
- **Secrets** are stored as **SSM Parameter Store** `SecureString` values under
  `/motifpath/<env>/…`. At deploy time they are rendered into that environment's `.env` on the VM.
  The VM's instance role can read only these parameters and the two environments' media buckets.
- **A monthly AWS Budget** alert is created with the account.

### Deployment

The rules of ADR-004 that are independent of the platform are kept:

- manual `workflow_dispatch` trigger with the environment as input
- images built once and tagged with the Git SHA
- the **same image promoted** from staging to production for normal releases
- backward-compatible (expand → migrate → contract) migrations
- rollback by redeploying the previous image

#### Release branch: `stage`

`dev` is the integration branch. It changes on every feature merge and is not always releasable,
so building an image on each `dev` merge would produce many images that are never meant to be
deployed. The deployable repositories (`motifpath-core` and `motifpath-web`) gain a protected
**`stage`** branch between `dev` and `main`:

```
feat/…  →  dev  →  stage  →  main
                    │         │
                 staging   production

hotfix/…  →  main  (then synced back to stage and dev)
```

- **`dev`:** feature integration. No images are built and nothing is deployed.
- **`stage`:** a release candidate. Promoting `dev` to `stage` is a deliberate PR.
- **`main`:** what runs in production.

`motifpath-specs` and `motifpath-infra` do not get a `stage` branch. Specs are not deployed, and
Terraform selects its environment by directory, not by branch.

#### Normal release

1. **Build.** On merge to `stage`, GitHub Actions builds the `linux/arm64` images, tags them with
   the `stage` commit SHA, and pushes them to ECR. It authenticates to AWS through **OIDC**, not
   static access keys.
2. **Deploy to staging.** A deploy workflow sends an SSM Run Command to the VM:
   `IMAGE_TAG=<sha> docker compose -p staging pull && … up -d`. This replaces only the staging
   containers. Migrations run at `core-domain` startup (ADR-005) against the staging database.
3. **Check staging.** The release is checked manually at `staging.motifpath.com`.
4. **Promote.** `stage` is merged to `main`. The production deploy takes the **image tag that ran
   in staging** as its input. It does not rebuild from `main`, because merging creates a new
   commit SHA. The workflow refuses a tag whose commit is not already contained in `main`.

The SPA follows the same path. It is built with each environment's variables, synced to that
environment's bucket, and CloudFront is invalidated. The SPA bundle is built per environment
because the API URLs and Clerk key are compiled into it, so for the SPA, "same image" means the
same commit.

#### Hotfix

A hotfix may go **directly to production**. Staging-first is the rule for normal releases, not a
hard gate:

1. A `hotfix/BUG-NNN/…` branch from `main` is merged into `main`.
2. On merge to `main` from a hotfix branch, the images are built and tagged with that commit's SHA.
3. The production deploy runs with that tag.
4. The existing sync workflow brings the fix back to `stage` and `dev`. The next staging deploy
   then includes it.

A hotfix **should avoid schema migrations**. Staging exists to rehearse migrations, and a hotfix
skips it. If a hotfix needs a migration, deploying it to staging first is strongly recommended,
even though it is not enforced.

Each environment's containers are **replaced in place** (Compose recreate), not blue/green.

### Observability

ADR-003 is unchanged in substance. Containers log to stdout, and the Docker `awslogs` log driver
ships each environment to its own CloudWatch Logs group.

## Rationale

**A persistent staging environment, with its own services, over a cloud staging database alone.**
A staging database with no staging services only receives migrations when someone points a local
service at it. That step is easy to forget, and it forces the database to be reachable from the
internet. Running the staging services on the production VM costs almost nothing extra and makes
"migrations ran on staging with this exact image" a normal step of every deploy.

**Co-locating the environments over separate machines.** The cost of an environment is its
always-on pieces: instances, database servers, NAT gateways, load balancers, public IPv4 addresses.
Sharing the VM and the RDS instance keeps staging almost free while keeping its data separate
(separate databases, users, buckets, brokers and Atlas clusters). Buckets and CloudFront
distributions are billed by usage, not per resource, so separate buckets per environment cost the
same as a shared one and remove the risk of staging overwriting production media.

**Rejected: EKS as in ADR-004.** Its fixed cost is dominated by control planes, and it brings the
operational surface ADR-003 and ADR-016 already chose to avoid at MVP.

**Rejected: ECS on Fargate.** It has no control-plane fee, but a load balancer (~$16+/month),
per-task billing for six always-on services across two environments, and either a NAT gateway or
public task IPs. It also has no cheap home for Redpanda. Estimated at 2–3× this design's cost, with
more infrastructure to write.

**Rejected: PaaS (Fly.io, Render, Railway).** It is attractive for stateless services, but Kafka
and co-located persistent volumes are awkward or unavailable there. It would also split the stack
across two vendors, when ADR-021 already commits media and SPA hosting to AWS.

**Rejected: MSK (ADR-006).** At alpha volume, a managed three-broker cluster costs more than the
rest of this design together. The Kafka API is unchanged, so moving back to MSK later is a
configuration change (`KAFKA_BROKERS`), not a code change.

**Rejected: separate AWS accounts per environment.** This is the cleanest isolation, but it
doubles account, IAM and billing setup for one developer. It is postponed, not abandoned.

**Rejected: Secrets Manager.** It costs $0.40 per secret per month and offers rotation features the
alpha does not use. Parameter Store `SecureString` is free at this scale.

**Region `us-east-1` over `sa-east-1`.** Most students are expected to be in Brazil, but `sa-east-1`
is roughly 50% more expensive for the same resources. CloudFront serves the SPA and media from
edge locations, so only API calls pay the ~120 ms round trip.

## Consequences

### Positive

- Estimated **~$45–65/month for both environments**, against ~$400–600 for ADR-004 as written:
  - EC2 `t4g.medium` ~$25
  - RDS `db.t4g.micro` + storage ~$15
  - Atlas Flex ~$8–30 (M0 is free)
  - Elastic IP ~$4
  - Route 53, ECR, S3, CloudFront and CloudWatch a few dollars at alpha traffic

  These are pre-launch estimates, to be checked against the first real invoice.
- A real homologation step: each release's migrations run first against a staging database that is
  never reset.
- Same-image promotion and redeploy rollback carry over unchanged from ADR-004.
- There is little infrastructure to write and operate: one instance, one database server, and
  static hosting. The Compose files extend what `compose.images.yaml` already proves.

### Negative / Trade-offs

- **The VM is a single point of failure for both environments.** An instance failure, OS upgrade
  or Docker upgrade takes staging and production down together. Data survives, because RDS and
  Atlas Flex have backups and the Mongo event log can replay Redpanda. The instance can be
  recreated from Terraform. Recovery takes minutes to an hour, not seconds.
- **Staging can still affect production.** Container limits cap CPU and memory, but the two
  environments share disk I/O, the kernel, and the RDS instance. A heavy staging migration can slow
  production briefly.
- **Deploys cause a few seconds of downtime per service** (recreate instead of blue/green). This is
  acceptable for alpha traffic. A deploy may need to happen outside peak hours.
- **Staging and production run different Mongo tiers (M0 vs Flex)** and different Clerk
  instances. Behaviour that depends on tier limits or Clerk production settings is not tested in
  staging.
- **Staging is only as useful as its data.** If staging holds only synthetic data, migrations can
  pass there and fail on real rows. Staging needs an occasional refresh from an anonymised
  production snapshot (process to be defined when production has data).
- **Weaker isolation than separate accounts.** A mistake in an IAM policy or Terraform module can
  reach both environments. This is mitigated by per-environment state, naming and scoped instance
  permissions.
- **One more long-lived branch to maintain.** Every release is two PRs (`dev → stage`,
  `stage → main`). The main-to-dev sync workflow must also sync `main` into `stage`, or a hotfix
  would be missing from the next release candidate.
- **Hotfixes skip the migration rehearsal.** A hotfix that changes the schema reaches production
  without having run against staging data, unless whoever ships it chooses to deploy it to staging
  first.
- **Build pipeline must target arm64.** Images are cross-built with `buildx`, and every
  third-party image used on the VM must publish an arm64 variant.

### Neutral

- **Amends ADR-004.** Its EKS, blue/green and separate-account parts are replaced for the alpha.
  Its trigger model, same-image promotion, migration discipline and rollback model stand. Its
  branch model gains `stage`, and images are built on merge to `stage` (and on hotfix merges to
  `main`) instead of on merge to `dev`.
- **Amends the MotifPath branching convention** (the `git` skill and the core/web READMEs), which
  currently know only `dev` and `main`. They are updated when the `stage` branch is created.
- **Amends ADR-006.** The broker is self-hosted Redpanda instead of MSK. Topic, partitioning and
  consumer-group decisions are unchanged.
- **Amends the `motifpath-infra` README and CLAUDE.md**, which describe EKS, Secrets Manager and
  separate accounts. They are updated in the first `motifpath-infra` implementation PR.
- **Resolves PB-8a's open hosting choice.** ADR-016's deferred "production-grade full-stack
  compose file" becomes needed.
- **Triggers for revisiting:**
  - paying users
  - a production incident caused by staging load
  - sustained load beyond one instance
  - a second developer who needs isolated environments

  The next step would be moving staging to its own instance and database, then a container
  platform (ECS or EKS) in a separate ADR.

## Related ADRs

- **ADR-003: OpenTelemetry with deferred backend.** Unchanged; logs reach CloudWatch through the
  `awslogs` driver.
- **ADR-004: Deployment pipeline.** Partly amended; see Neutral.
- **ADR-005: ent migration strategy.** Startup migrations and the Atlas advisory lock are unchanged;
  staging is where they run first.
- **ADR-006: Kafka topology.** Broker hosting amended; topology unchanged.
- **ADR-008: MongoDB Atlas for events.** Tiers set per environment (Flex and M0 instead of M10).
- **ADR-016: Local dev orchestration.** Its deferred production Compose file is realised here.
- **ADR-021: Media storage.** Unchanged; one bucket and CloudFront distribution per environment.

---

*This ADR was proposed on 2026-09-26. To revise, create a new ADR with Status: Supersedes ADR-039.*
