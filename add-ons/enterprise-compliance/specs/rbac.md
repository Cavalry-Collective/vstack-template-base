# Role-based access control — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Give every organisation a permission catalog and fixed least-privilege system roles, with custom roles later. Every privileged capability in the CRM is gated by a named `resource:action` permission. Every role change is safe, race-free, and audited.

## Scope & ownership

- **Owns:** the canonical permission catalog, the five system roles and their matrix, role assignment rules 6–8, effective-permission resolution and the shared `PermissionChecker` port, and custom roles (P2).
- **Consumes:** the shared approval flow for guarded role changes (`maker-checker.md`); `record()` (`audit-logs.md`).
- **Used by:** every guarded endpoint in the program checks permissions through this module; `admin-security.md` (API-key scopes), `maker-checker.md`, and `export-bulk-controls.md` consume the `PermissionChecker` port. This area builds first, with audit-logs (index build-order note).
- **Phases:** P1 = catalog, system roles, assignment, effective-permissions read (S1–S3). P2 = custom roles (S4). Record-level visibility is P3 and out of scope here.

## User stories & acceptance criteria

**S1 (P1)** — As an org admin, I want fixed system roles with least-privilege defaults, so that access is controlled from day one without configuration.

- [ ] Creating an organisation seeds the five system roles matching the matrix. *Verify: integration test creating an org and asserting the seeded `roles`/`role_permissions` rows against the matrix.*
- [ ] A newly invited member defaults to Member. *Verify: invite flow test asserting the new membership's role, then a `contacts:export` call from that member returns `403 PERMISSION_DENIED`.*
- [ ] Read-only members can read but not mutate CRM records. *Verify: contract tests — `GET /internal/v1/organisations/{id}/contacts` returns `200`, `POST` returns `403 PERMISSION_DENIED`.*
- [ ] System roles reject edits. *Verify: `PUT …/roles/{systemRoleId}` returns `409 SYSTEM_ROLE_IMMUTABLE`.*

**S2 (P1)** — As an org admin, I want to assign and change member roles under safe rules, so that access changes are controlled and reversible.

- [ ] Assigning a role updates access on the member's next request. *Verify: integration test — assign Manager, then the member's previously-403 `contacts:export` call returns `200`.*
- [ ] Only an Owner can grant/revoke Owner. *Verify: `PUT …/members/{id}/roles` including Owner as an Admin returns `403 OWNER_GRANT_REQUIRES_OWNER`; as an Owner returns `200`.*
- [ ] An actor cannot grant a permission they lack. *Verify: contract test — a Manager (holding `roles:assign` in a custom setup) assigning Admin returns `403 GRANT_EXCEEDS_ACTOR`.*
- [ ] The last active Owner cannot be downgraded/removed, even under concurrency. *Verify: unit/integration test with two concurrent downgrade requests against a two-Owner org — exactly one succeeds, the other returns `409 LAST_OWNER_PROTECTED`.*
- [ ] Every assignment/revocation and every denial appears in the audit store. *Verify: integration test asserting `rbac.role.assigned` / `rbac.role.change_denied` rows with full envelope after the calls above.*

**S3 (P1)** — As a member, I want my effective permissions readable, so that the app shows me only what I can do.

- [ ] `GET …/members/me/permissions` returns the union of the actor's roles' permissions. *Verify: contract test per system role asserting the response matches the matrix.*
- [ ] The SPA hides gated controls without the backing permission. *Verify: screen check — Members page as Read-only shows no "Change role" control; as Admin it does.*
- [ ] After a role change, the UI reflects new permissions on next load without re-login. *Verify: change a member's role, reload the SPA as that member, assert gated controls updated.*

**S4 (P2)** — As an org admin, I want custom roles composed from the catalog, so that I can fit access to my org's structure.

- [ ] Custom role CRUD works within rules 5 and 7. *Verify: contract tests — create/update/delete via `…/roles`; permissions outside the actor's set return `403 GRANT_EXCEEDS_ACTOR`; unknown keys return `400 UNKNOWN_PERMISSION`.*
- [ ] A custom role in use cannot be deleted. *Verify: assign the role, `DELETE …/roles/{id}` returns `409 ROLE_IN_USE`.*
- [ ] Custom-role mutations are audited and maker-checker eligible. *Verify: integration test asserting `rbac.role.created`/`updated`/`deleted` events; with approval policy on, the mutation returns a pending approval instead (per the maker-checker spec's tests).*

## Requirements

1. The backend defines one canonical permission catalog (below); every permission is `resource:action`, lowercase. Any permission string outside the catalog is rejected on write. Another adopted add-on may extend the catalog at build time with its declared permissions (e.g. saas-billing's `billing:read`/`billing:manage`) — extension rows join the catalog and the system-role matrix in the same change that adopts the add-on; runtime writes are still rejected outside the (extended) catalog.
2. Destructive/exfiltrating verbs — `export`, `bulk_update`, `bulk_delete`, `purge` — are separate permissions from `read`/`update`/`delete`; holding `contacts:update` never implies `contacts:export`.
3. Five fixed system roles exist in every organisation: **Owner, Admin, Manager, Member, Read-only**. System roles cannot be renamed, edited, or deleted.
4. New members default to **Member** (least privilege that still allows day-to-day CRM work); invitations may specify any role the inviter is allowed to grant (req. 7).
5. Custom roles (P2) are composed from catalog permissions only; an organisation can create, edit, and delete them. A custom role in use (assigned to ≥1 member) cannot be deleted.
6. Only an Owner may grant or revoke the Owner role.
7. An actor can never grant, via role assignment or custom-role definition, a permission they do not themselves hold. Both paths check the actor's own effective set.
8. Last-Owner protection: an organisation must always retain at least one active Owner. Removing/downgrading the last Owner (or deactivating that member) is rejected, race-safely (see Implementation notes).
9. Role and permission changes take effect on the next request: the member's permission cache entry is invalidated synchronously with the change. Nothing already granted is revoked retroactively — in-flight requests complete — except session-bound elevation (step-up grants from the MFA spec, `mfa.md`), which is dropped immediately on role change.
10. Every member can read their own effective permissions; the frontend uses that read to render or hide gated UI.
11. All role mutations are audited (table below) and are maker-checker eligible: when the org's policy requires approval for role changes, the mutation routes through the shared approval flow (`maker-checker.md`) instead of applying directly.

### Permission catalog

| Resource | Actions |
|---|---|
| `contacts`, `companies`, `deals` | `read`, `create`, `update`, `delete`, `export`, `bulk_update`, `bulk_delete` |
| `activities`, `notes` | `read`, `create`, `update`, `delete`, `export` |
| `records` | `restore`, `purge` — recycle-bin operations spanning record classes; semantics owned by `retention-deletion.md` |
| `pipelines`, `custom_fields` | `read`, `create`, `update`, `delete` |
| `members` | `read`, `invite`, `update`, `remove`, `mfa_reset` |
| `roles` | `read`, `create`, `update`, `delete`, `assign` |
| `org_policy` | `read`, `update` |
| `audit_logs` | `read`, `export` |
| `exports` | `read` (export *jobs*; creating one requires the per-resource `…:export` verb — see `export-bulk-controls.md`) |
| `api_keys` | `read`, `create`, `update`, `revoke` |
| `approvals` | `read`, `decide` |
| `privacy_requests` | `read`, `manage`, `execute` |
| `retention` | `read`, `update`, `hold` |
| `sso_config` | `read`, `manage` |
| `scim_tokens` | `manage` |
| `mfa_policy` | `read`, `update` |
| `encryption_keys` | `read` (key status only, never material) |
| `compliance_documents` | `read` |
| `trust_notifications` | `manage` |

Platform-operator, instance-scope permissions — `backups:read`, `backups:restore`, `recovery_drills:record`, `encryption_keys:rotate` — authenticate via the operator credential, not org roles, and live outside this catalog (see the backup-dr and encryption specs).

### System-role matrix (summary)

| Permission group | Owner | Admin | Manager | Member | Read-only |
|---|---|---|---|---|---|
| CRM records: `read` | ✓ | ✓ | ✓ | ✓ | ✓ |
| CRM records: `create`/`update`/`delete` | ✓ | ✓ | ✓ | ✓ | — |
| CRM records: `export`/`bulk_update`/`bulk_delete` | ✓ | ✓ | ✓ | — | — |
| `records:restore`/`records:purge` (recycle bin) | ✓ | ✓ | — | — | — |
| `members:*`, `roles:*` | ✓ | ✓ (cannot grant Owner) | `members:read`, `roles:read` | — | — |
| `org_policy:*`, `retention:*`, `sso_config:*`, `mfa_policy:*`, `scim_tokens:*` | ✓ | ✓ | — | — | — |
| `audit_logs:*`, `exports:read`, `api_keys:*`, `approvals:*`, `privacy_requests:*`, `encryption_keys:read`, `compliance_documents:read`, `trust_notifications:manage` | ✓ | ✓ | — | — | — |

Owner = every catalog permission. The "cannot grant Owner" restriction on Admin is rule 6, not a missing permission.

## User flows

### F1 — Assign a role (P1)
1. Admin opens Members list → a member → "Change role". 2. UI shows only roles the actor may grant (from effective permissions + rule 6/7). 3. Admin picks role, confirms. 4. Backend validates rules 6–8, applies (or routes to approval per rule 11), invalidates the member's permission cache, records the audit event. 5. UI confirms; the affected member's next request runs with the new role.

### F2 — Blocked last-Owner downgrade (P1)
1. Admin/Owner attempts to downgrade or remove the sole active Owner. 2. Backend rejects with `409 LAST_OWNER_PROTECTED`; a denied audit event is recorded. 3. UI explains an org must keep at least one active Owner.

### F3 — Frontend gates UI by effective permissions (P1)
1. On session start (and after any role-change notification), the SPA fetches the actor's effective permissions. 2. Gated controls (export buttons, admin nav, bulk actions) render only when the backing permission is present. 3. Server remains authoritative — a hidden control's endpoint still enforces the guard.

### F4 — Create a custom role (P2)
1. Admin opens Roles → "New role". 2. Picks a name and permissions from the catalog (UI offers only permissions the actor holds, rule 7). 3. Backend validates catalog membership + rule 7, creates the role, audits. 4. Role becomes assignable in F1.

## API & permissions

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes apply.

- `roles:read` — view the role list, each role's permission set, and the permission catalog. `members:read` — view members with their roles.
- `roles:assign` — assign/revoke roles within rules 6–8. Only Owners see/get the "grant Owner" option (rule 6).
- `roles:create` / `roles:update` / `roles:delete` — custom-role CRUD (P2).

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/permissions` | Permission catalog | `roles:read` | `data[]`: `{ key, resource, action, description }` |
| `GET …/roles` | List roles | `roles:read` | items: `{ id, key, name, isSystem, permissions[], memberCount }` |
| `GET …/roles/{roleId}` | Role detail | `roles:read` | as above |
| `POST …/roles` | Create custom role (P2) | `roles:create` | req: `{ name, permissions[] }`; `201` |
| `PUT …/roles/{roleId}` | Replace custom role (P2) | `roles:update` | full-resource replace; system roles → `409 SYSTEM_ROLE_IMMUTABLE` |
| `DELETE …/roles/{roleId}` | Delete custom role (P2) | `roles:delete` | `204`; in use → `409 ROLE_IN_USE` |
| `PUT …/members/{memberId}/roles` | Set a member's roles | `roles:assign` | req: `{ roleIds[] }`; enforces rules 6–8; maker-checker may capture it as an approval request instead (`202`, status `pending_approval`) per that spec |
| `GET …/members/me/permissions` | Actor's effective permissions | any authenticated member | `{ memberId, roles[], permissions[] }` — no pagination (bounded by catalog size) |

Role mutations are synchronous (small writes); nothing here streams or long-runs.

## Data model

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs indexed):

- **`roles`** — `id` (PK); `organisation_id` (FK, indexed; system roles are still rows per org so custom and system assignment share one shape); `key` (stable slug, e.g. `owner`, unique per org with `name`); `name`; `is_system` (boolean); `created_at`; `updated_at`. Unique `(organisation_id, key)`.
- **`role_permissions`** — `id` (PK); `role_id` (FK, indexed); `permission` (catalog key, validated against the catalog on write); `created_at`; `updated_at`. Unique `(role_id, permission)`.
- **`member_roles`** — `id` (PK); `organisation_id` (FK, indexed — denormalised for the last-Owner constraint and org-scoped queries); `member_id` (FK, indexed); `role_id` (FK, indexed); `assigned_by` (member FK, nullable for `system` actors); `created_at`; `updated_at`. Unique `(member_id, role_id)`.

No sensitive columns; nothing encrypted or hashed here. Seeding the five system roles per org is part of the org-creation use case, not a data migration.

## Audit events

Emitted via the shared `record()` in the service ring, same transaction as the change.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `rbac.role.created` | Custom role created | `after`: name, permissions |
| `rbac.role.updated` | Custom role renamed / permissions changed | `before`/`after`: permission diff |
| `rbac.role.deleted` | Custom role deleted | `before`: name, permissions |
| `rbac.role.assigned` | Role added to a member | target = member; `after`: role key |
| `rbac.role.revoked` | Role removed from a member | target = member; `before`: role key |
| `rbac.role.change_denied` | Any role mutation blocked (missing permission, rule 6/7, last-Owner) | `outcome: denied`; `context` names the violated rule / missing permission |

`403 PERMISSION_DENIED` on any RBAC endpoint also emits the generic denied event per the program's cross-cutting criterion 1.

## Implementation notes

- Lives in a `rbac` module (domain: role/permission entities, assignment rules 6–8; service: use cases; repo: adapters; controller: routes + guards).
- **Permission checks**: a controller-ring guard asserts the endpoint's named permission from the actor's effective set; rules that depend on domain state (6, 7, 8) are enforced again in the use case — the guard is necessary, not sufficient. Server-side enforcement is authoritative; the effective-permissions read is a rendering hint only.
- **Effective-permission resolution** is a domain service: union of the member's roles' permissions. Exposed to other modules through a shared port (`PermissionChecker`) so no module re-implements resolution.
- **Cache**: effective permissions may be cached per member (store supplied by the active stack pack). The role-mutation use cases invalidate the affected members' entries in the same use case, after commit; cache misses fall through to the DB. TTL as a backstop, bounded ≤ 5 minutes. Invalidation is synchronous with the mutation, so a revoked admin cannot act on stale cache beyond the current request (req. 9).
- **Last-Owner race safety**: the downgrade/removal use case runs in one transaction that locks the org's Owner assignments (e.g. `SELECT … FOR UPDATE` on `member_roles` rows for the Owner role, or an equivalent DB-level constraint) before counting; two concurrent "remove Owner" requests cannot both pass the check. Constraint mechanics bound by the active stack pack's `db.md`.
- **Idempotency**: `PUT …/members/{memberId}/roles` is a full replace — replaying it is a no-op; no-op replacements emit no audit event.
- **Maker-checker hand-off**: when org policy requires approval, the use case creates the approval request via the shared approval port instead of mutating, per `maker-checker.md`.
- All queries are org-scoped by `organisation_id`; a role id from another org is a `404`, never a leak. No background jobs.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Missing the endpoint's permission | 403 | `PERMISSION_DENIED` (missing permission in `error.details`) |
| Non-Owner grants/revokes Owner | 403 | `OWNER_GRANT_REQUIRES_OWNER` |
| Actor grants a permission they don't hold | 403 | `GRANT_EXCEEDS_ACTOR` |
| Downgrade/removal would leave zero active Owners | 409 | `LAST_OWNER_PROTECTED` |
| Mutating a system role | 409 | `SYSTEM_ROLE_IMMUTABLE` |
| Deleting a role still assigned | 409 | `ROLE_IN_USE` |
| Permission string not in the catalog | 400 | `UNKNOWN_PERMISSION` |
| Role/member id not found (or other org's) | 404 | `ROLE_NOT_FOUND` / `MEMBER_NOT_FOUND` |

## Notes & decisions

- **Owner grant is doubly protected:** rule 6 (actor must be Owner) plus rule 7 (Owner holds all permissions, so no lesser actor can compose it into a custom role).
- UX: screens are the Members list (role column + change-role dialog), Roles list + role editor (P2), and permission-gated rendering across the app. Each needs loading/error/empty states; the role editor needs an unsaved-changes guard.
- Performance: the effective-permissions fetch is on the session-bootstrap path — one cheap indexed query; the response is small (bounded by the catalog). Guard evaluation runs on every request and must stay O(set lookup) after resolution; no per-request DB scan when the cache is warm.

## Out of scope

- **Record-level visibility (P3)** — team/ownership scoping of CRM records (a Member seeing only their own deals). Named here explicitly; a future spec revision owns it. Nothing in this spec's data model may preclude it, but nothing implements it.
- Cross-organisation roles or platform-level (super-admin) roles.
- Permission checks inside exports/bulk jobs beyond gating their creation (owned by `export-bulk-controls.md`).
- SCIM-driven role mapping (owned by `sso-identity.md`).

## Open questions

- No `design/` mockup exists yet for the new screens (Members role management, Roles list & custom-role editor); required before initial build.
- Should Manager hold `records:restore` (grace-period recycle-bin restore)? Owner: product, before retention-deletion P1 lands.
- Do we need per-role member caps or expiry on assignments for contractors? Owner: product; default is no (YAGNI) unless a customer commitment says otherwise.
