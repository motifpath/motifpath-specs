# ADR-062: Alpha hosting as built — us-east-2, IAM-user CI keys, fixed deploy documents, merge-commit promotions

**Status:** Proposed
**Date:** 2026-10-20
**Deciders:** Gilson (PO), Claude Code
**Supersedes (in part):** ADR-039 (Region `us-east-1`; CI authentication through GitHub OIDC;
deploys as free-form SSM Run Command; the instance role reading the media buckets)

---

## Context

ADR-039 chose to host the alpha on one EC2 instance that runs staging and production as two
Compose projects, next to a shared RDS instance, Atlas, and S3 + CloudFront. PB-8a built that
design end to end, and both environments are now live. While it was being applied to the real AWS
account, four parts of ADR-039 turned out to be either impossible or weaker than they had to be.

**The account cannot use `us-east-1`.** The MotifPath account is an AWS *project* in the new AWS
experience. Projects are pinned to one Region by an AWS-managed service control policy (SCP), and
this one is pinned to `us-east-2`. Every regional call outside `us-east-2` is denied, including
read-only calls such as `DescribeAvailabilityZones`. The SCP is managed by AWS, not by MotifPath,
so it cannot be changed.

**The account cannot trust GitHub's OIDC provider.** The same SCP denies creating the IAM OIDC
identity provider that GitHub Actions needs, so the OIDC roles ADR-039 assumed for image builds and
deploys cannot exist.

**Containers must not inherit the host's permissions.** ADR-039 gave the VM's instance role read
access to both environments' SSM parameters and media buckets. The role is needed on the host to
render secrets, pull images and ship logs. But any container that can reach the instance metadata
service can use that role, so a staging container could read production's secrets. The two
environments share one host, so this matters more here than it would on separate machines.

**A deploy command must not be able to run arbitrary code.** ADR-039 described a deploy as an SSM
Run Command (`docker compose … pull && … up -d`). With `AWS-RunShellScript`, whoever holds a deploy
key can run any command as root on the host that serves both environments.

The first production promotion added a fifth finding. `stage` was merged into `main` with a
**squash** merge. That rewrote the commits under new SHAs, and the production deploy correctly
refused images whose commit was not contained in `main`.

## Decision

The design of ADR-039 stands: one VM, two Compose projects, shared RDS, Atlas, S3 + CloudFront,
Route 53, Parameter Store, and the `dev → stage → main` release flow. The following parts change.

### Region: `us-east-2`

Every regional resource lives in **`us-east-2` (Ohio)**. The one exception is the ACM certificates
for the CloudFront distributions, which CloudFront accepts only from `us-east-1`. Terraform creates
them through a dedicated `us-east-1` provider alias, and nothing else may use that alias. The
Atlas clusters are allow-listed to the VM's Elastic IP, as before.

### CI authentication: one IAM user per CI job

Each CI job that touches AWS signs in with an access key of **its own IAM user**, scoped to that
job's actions:

| User | Can |
|---|---|
| ECR push | Push images to the three `motifpath/*` repositories |
| core deploy, per environment | Send that environment's deploy document to the VM; production's can also add the `production-<sha>` tag to images |
| web deploy, per environment | Sync that environment's SPA bucket and invalidate its CloudFront distribution |

The keys are created by Terraform and stored as **GitHub environment secrets**. Each GitHub
environment is limited by deployment-branch rules: `images` and `staging` to `stage` and `main`,
and `production` to `main`. A workflow run from any other branch cannot read the keys.

A key is rotated by replacing its Terraform resource and updating the secret.

### No instance role in containers

The VM's metadata service has a **hop limit of 1**, so only processes on the host can reach it and
containers cannot use the instance role. The instance role keeps what the host needs: reading the
environments' parameters, pulling from ECR, and writing CloudWatch logs.

`core-domain` reaches its media bucket with the access key of **its environment's media IAM
user**. That user can reach only that environment's bucket. The key is stored in the environment's
parameters, like any other secret.

### Deploys: one fixed SSM document per environment

Each environment has **one SSM document**, `motifpath-<env>-deploy`, and its deploy user can send
only that document. The document:

1. takes a single parameter, the image tag, which must be a full commit SHA;
2. asks GitHub whether that commit is contained in the environment's release branches (`main` for
   production; `stage` or `main` for staging), and refuses it otherwise;
3. downloads the `deploy/` directory **from that commit** and runs its deploy script.

The only code that can reach the host is code merged to a release branch. No deploy user holds
`AWS-RunShellScript` or any document that runs caller-supplied commands.

### Production image tags

When an image is deployed to production, it gets a second tag, **`production-<sha>`**. The ECR
lifecycle rules expire `production-*` images only among themselves. Staging builds therefore cannot
push out an image that production may need to roll back to.

### Promotions use merge commits

`dev → stage` and `stage → main` are merged with a **merge commit**. Squash and rebase merges are
not allowed on `stage` and `main`. A merge commit keeps the original commits, so the SHA that was
built and deployed to staging is still contained in `main`. Repository rulesets on `stage` and
`main` in `motifpath-core` and `motifpath-web` allow only merge commits and require a pull
request.

### DNS additions

The Route 53 zone also holds:
- the records of MotifPath's business email at GoDaddy (SPF, MX, DKIM and autodiscover);
- `_dmarc`, with the policy that email setup requires (`p=reject`);
- the CNAMEs of the Clerk production instance (frontend API, accounts, mail, DKIM).

All of them are managed by Terraform.

## Rationale

**`us-east-2` over moving to a classic account in `us-east-1`.** The Region was chosen in ADR-039
for price and latency to Brazil. `us-east-2` costs the same as `us-east-1` for every service used
here, and it is a few milliseconds further from São Paulo. Leaving the project for a new standalone
account would mean new billing, a new root identity and new guardrails, all to gain nothing.

**Rejected: IAM roles assumed with a long-lived key.** A bootstrap user that assumes a role per job
still keeps a long-lived key in GitHub, so it gives the same exposure as a per-job user with one
more moving part. Scoping each user to a single job keeps the blast radius of a leaked key to that
job's actions.

**Rejected: raising the metadata hop limit and trusting containers.** That is simpler, since media
access would come from the instance role. But it would give every container, in both environments,
the host's ability to read production secrets.

**Rejected: deploying through `AWS-RunShellScript`.** It is the most flexible option, but a deploy
key would then be equivalent to root on the host. The fixed document gives the same outcome, with
the commit check done on the host instead of only in the workflow.

**Rejected: rebuilding images on `main`.** That would allow squash merges, but production would
then run an image that staging never ran. The point of `stage` is to deploy to production the exact
image that staging already ran.

## Consequences

### Positive

- Both environments run in the Region the account allows, with no workaround to maintain.
- A leaked CI key reaches only one job's actions, and only from its GitHub environment's branches.
- No container can read either environment's secrets through the host.
- A deploy key cannot run code that is not on a release branch.
- Production's rollback images survive any number of staging builds.

### Negative / Trade-offs

- **Long-lived keys exist.** There are five CI keys and two media keys, with no automatic rotation.
  Rotation is a manual Terraform step plus a secret update, and it has to be remembered.
- **Deploys depend on GitHub at deploy time.** The document asks GitHub's API for the commit check
  and downloads `deploy/` from GitHub. If GitHub is unavailable, nothing can be deployed, including
  a rollback.
- **The account needs AWS's paid plan.** The free plan rejected the `t4g.medium` instance and the
  RDS backup retention that ADR-039 chose. Cost estimates are unchanged, but there are no free-tier
  credits.
- **Merge-commit history.** `main` carries a merge commit for every release, and contributors must
  not use GitHub's default squash button on release PRs. The rulesets enforce this.

### Neutral

- **Amends ADR-039.** Its Region, CI authentication, deploy mechanism and instance-role scope are
  replaced as above. Its topology, release flow, hotfix path and cost model stand.
- The `motifpath-infra` and `motifpath-core` READMEs and the `motifpath-infra` CLAUDE.md already
  describe the system as built.
- **Revisit if** the account leaves the AWS project (OIDC could then replace the CI keys), or
  staging moves to its own instance (the instance-role scope could then be split).

## Related ADRs

- **ADR-004: Deployment pipeline.** Its same-image promotion and rollback model are kept; this ADR
  adds the merge-commit rule they depend on.
- **ADR-021: Media storage.** Unchanged; `core-domain` reaches the bucket with a per-environment
  IAM user instead of the instance role.
- **ADR-039: Single-VM hosting with staging.** Partly superseded; see Neutral.

---

*This ADR was decided on 2026-10-20. To revise, create a new ADR with Status: Supersedes ADR-062.*
