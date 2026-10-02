# ADR-044: A fixed, non-loginable system profile owns platform catalog content

**Status:** Proposed
**Date:** 2026-10-01
**Deciders:** Gilson (Product Owner)

---

## Context

The bilingual basic-guitar catalog is production data installed through a database migration. A
previous design made the earliest human admin the owner of every generated diagram. That makes a
fresh production migration depend on a separate bootstrap-user process, makes attribution depend
on deployment order, and leaves the catalog associated with a person who may leave the team.

The current `users` model associates authored content with a user and already permits database-
provisioned admins. Clerk identities are resolved only by their `sub` value, so a reserved value
that Clerk does not issue cannot be used to log in.

## Decision

Catalog migrations create and reuse one fixed system profile:

- `id`: `77d0239a-8d28-5c95-bc6e-53d59f7f84a8`
- `clerk_user_id`: `system:catalog`
- `role`: `admin`
- `display_name`: `MotifPath Catalog`
- `locale`: `en`

The `system:` Clerk-user-id prefix is reserved for database-owned system profiles. Application
registration rejects it, and Clerk does not mint identifiers in that namespace. The profile has no
credentials and is therefore not loginable.

Every platform-provided basic diagram uses this fixed id as `created_by`. The migration verifies
that any pre-existing row using either fixed identity component has exactly these values; otherwise
it fails before catalog rows are written. Human admins continue to administer catalog content under
the existing authorization rules.

The profile's display name is stable attribution metadata. Learner-facing catalog data remains
localized independently through each diagram's required `en` and `pt_BR` names.

## Consequences

- A fresh production schema can install catalog content without a human bootstrap admin.
- Catalog ownership is deterministic across development, staging, and production.
- The platform can show `MotifPath Catalog` as the creator where creator attribution is exposed.
- Future database-owned content may use another explicitly documented reserved system profile; it
  must not impersonate this catalog curator.
- This does not introduce a general `system` role or change existing admin authorization.
