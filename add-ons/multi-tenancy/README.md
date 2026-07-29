# Add-on: multi-tenancy

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

First-class tenancy: several organisations (workspaces, teams, clients — pick **one** noun and keep it) share one deployment while their data, members, settings, files, jobs, and billing stay strictly isolated. Adopt it **before the first tenant-owned table exists** — retrofitting scoping across a live schema is the expensive path this add-on exists to avoid.

## Approach
### Core invariants
- **One tenant noun, one foreign key, everywhere.** Choose the tenant noun once and use it consistently across schema, code, routes, and UI. Every tenant-owned table carries the tenant foreign key, indexed; a table without it is either genuinely instance-global (justified in its spec or migration) or a defect. Reviewers reject a new tenant-owned table missing the key.
- **Resolve the tenant once, at the edge; check four things on every protected action.** One documented resolution strategy (path segment, subdomain, header, or session — the spec picks one; the pack binds it). A guard validates before the handler runs: the user is authenticated, is a member of the target tenant, holds a role permitting the action, **and the resource belongs to that same tenant**; the validated tenant id then travels inward as a request-context value. Fail closed: missing, unknown, archived, or unauthorized tenant context rejects the request, and client-sent tenant ids or slugs are claims to verify, not facts.
- **Scoping is backend-enforced and structural, never per-call discipline.** Every query that reads, writes, lists, aggregates, exports, or imports tenant data is scoped by the tenant id from the server-resolved context — never by frontend filtering alone. Route every tenant-owned query through a repository/helper that *requires* the tenant id, so an unscoped query is hard to write, not merely forbidden; where the database offers it (e.g. row-level security), add it as defence-in-depth.
- **Cross-tenant answers are `404`, never `403`.** A resource id from another tenant — or a tenant the caller isn't a member of — answers exactly like a nonexistent one, so existence never leaks. `403` is reserved for callers who *are* members but lack the role.
- **Identity is global; membership and roles are per-tenant.** One user account (globally unique email) may hold memberships in many tenants; a role in one tenant grants nothing in another. Tenant-scoped uniqueness is a composite constraint with the tenant id (a slug or reference may repeat across tenants), never a global one.

### Derived surfaces
- **Everything derived is scoped too.** Files live under tenant-prefixed paths with authorised reads (signed URL or backend proxy — never a guessable public URL); background jobs carry the tenant id in the payload and revalidate the tenant's existence and status before executing; caches key by tenant; audit events, analytics, and search indexes carry and filter by the tenant id.
- **Settings, branding, and plan hang off the tenant** — stored per-tenant as validated data, never in env config (base *Configuration* carries deployment values only). Feature and quota checks read the *active tenant's* plan, not the user's — through **saas-billing**'s entitlement resolver where that add-on is adopted.
- **Switching tenants resets client state.** The UI always shows the current tenant; a switch drops every piece of tenant-scoped client state (stores, caches, drafts) before rendering the next tenant. A user can switch only to tenants they belong to — enforced server-side.

### Operator surface
- **Operator (super-admin) access is a separate, audited surface** — its own credential and routes, never a bypass of tenant scoping, and no silent impersonation. Where **enterprise-compliance** is adopted, its program owns this surface (the operator-scoped credential and platform-scope audit defined in its `rbac.md` and `trust-transparency.md`).

## Verify
Cross-tenant attempts are standing tests, not review notes; a tenant-owned endpoint without them is not done. Assert:
- a member of tenant A reading, updating, deleting, or listing tenant B's resources gets `404`/empty, and a role in A grants nothing in B;
- a per-tenant unique value can repeat across tenants;
- a B-scoped file URL fails for A's member, and a job with a stale or archived tenant id refuses to run.

## Binds to a stack

- **Guard** — where the tenant guard lives, and the request-context mechanism.
- **Data layer** — the scoped repository/query helper, any database-level enforcement (e.g. row-level security), and composite-unique + FK-index mechanics.
- **Files & jobs** — the tenant-scoped storage layout with its authorised read path, and how jobs carry and revalidate tenant context.
- **Frontend** — the active-tenant carrier and the switch-reset mechanism.

## Interactions

- **enterprise-compliance** — that program *assumes* this tenant model (its "Organisation — the tenant"); this add-on supplies it. Adopting both: its RBAC catalog and system roles supersede this add-on's minimal owner/admin/member model, its audit-event envelope carries the tenant id, and its program owns the operator surface (see its `rbac.md` / `trust-transparency.md`).
- **saas-billing** — hangs subscriptions, seats, usage, and invoices off this add-on's organisation; adopt this (or another organisation model) before billing. Its derived entitlements supersede direct reads of the organisation's stored `plan` key.
- **Base *Security baseline*, *Audit trail*, *Configuration*; `db/CLAUDE.md`** — this add-on instantiates the first two: tenant checks are authorization, and tenant lifecycle + membership changes are audited state changes. Per-tenant settings are data on the tenant, never env config. The tenant FK, composite uniques, and indexes follow the db schema conventions and reversible-migration rules.
- **test-mode** — seed at least two tenants with members so cross-tenant assertions and the test-user picker are walkable; if a pack's *mode signal* happens to be named "tenant", it is a different concept — never resolve the organisation from it.
- **llm-calls** — its per-tenant cost/usage monitoring keys on this add-on's tenant id.

## Specs
The buildable program — tenant model, membership, invitations, resolution, switching, APIs, data model, and acceptance criteria — is [`SPEC.md`](SPEC.md); on adoption you may move it under `specs/` (renamed to the dated convention) if the project keeps one spec home.
