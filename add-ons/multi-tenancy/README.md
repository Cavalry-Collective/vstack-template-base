# Add-on: multi-tenancy

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the tenant guard + request-context mechanism, the scoped query helper, any database-level enforcement, and the storage layout named under *Binds to a stack*.

First-class tenancy: several organisations (workspaces, teams, clients — pick **one** noun and keep it) share one deployment while their data, members, settings, files, jobs, and billing stay strictly isolated. Adopt it **before the first tenant-owned table exists** — retrofitting scoping across a live schema is the expensive path this add-on exists to avoid.

This README is the durable SOP — the isolation rules every change must honour once the add-on is adopted. The **buildable program** — tenant model, membership, invitations, resolution, switching, APIs, data model, and acceptance criteria — is [`SPEC.md`](SPEC.md) beside this file; on adoption, move it under `specs/` per the repo's spec-first workflow.

## Approach

- **One tenant noun, one foreign key, everywhere.** Choose the tenant noun once and use it consistently across schema, code, routes, and UI. Every tenant-owned table carries the tenant foreign key, indexed; a table without it is either genuinely instance-global (justified in its spec or migration) or a defect. Reviewers reject a new tenant-owned table missing the key.
- **Isolation is enforced in the backend; the frontend only renders it.** Every query that reads, writes, lists, aggregates, exports, or imports tenant data is scoped by the tenant id from the server-resolved context — never from a client-sent value taken on faith, and never by frontend filtering alone.
- **Resolve the tenant once, at the edge, and pass it inward.** One documented resolution strategy (path segment, subdomain, header, or session — the spec picks one; the pack binds it). A guard resolves and validates it — authenticated user → is a member → tenant is active — before the handler runs, then the tenant id travels inward as a request-context value. Fail closed: missing, unknown, archived, or unauthorized tenant context rejects the request.
- **Four checks on every protected action:** the user is authenticated; the user is a member of the target tenant; the member's role permits the action; **and the resource belongs to that same tenant**. Client-sent tenant ids and slugs are claims to verify, not facts.
- **Cross-tenant answers are `404`, never `403`.** A resource id from another tenant — or a tenant the caller isn't a member of — answers exactly like a nonexistent one, so existence never leaks. `403` is reserved for callers who *are* members but lack the role.
- **Scoping is structural, not per-call discipline.** Route every tenant-owned query through a repository/helper that *requires* the tenant id, so an unscoped query is hard to write, not merely forbidden. Where the database offers it (e.g. row-level security), add it as defence-in-depth — the pack binds the mechanism.
- **Identity is global; membership and roles are per-tenant.** One user account (globally unique email) may hold memberships in many tenants; a role in one tenant grants nothing in another. Tenant-scoped uniqueness is a composite constraint with the tenant id (a slug or reference may repeat across tenants), never a global one.
- **Everything derived is scoped too:** files under tenant-prefixed paths with authorised reads (signed URL or backend proxy — never a guessable public URL); background jobs carry the tenant id in the payload and revalidate the tenant's existence and status before executing; caches key by tenant; audit events, analytics, and search indexes carry and filter by the tenant id.
- **Settings, branding, and plan hang off the tenant** — stored per-tenant as validated data, never in env config (base *Configuration* carries deployment values only). Feature and quota checks read the *active tenant's* plan, not the user's.
- **Switching tenants resets client state.** The UI always shows the current tenant; a switch drops every piece of tenant-scoped client state (stores, caches, drafts) before rendering the next tenant. A user can switch only to tenants they belong to — enforced server-side.
- **Operator (super-admin) access is a separate, audited surface** — its own credential and routes, never a bypass of tenant scoping, and no silent impersonation. Where **enterprise-compliance** is adopted, its admin-security spec owns this surface.

## Verify isolation

Cross-tenant attempts are standing tests, not review notes: a member of tenant A reading, updating, deleting, or listing tenant B's resources gets `404`/empty; a role in A grants nothing in B; a per-tenant unique value can repeat across tenants; a B-scoped file URL fails for A's member; a job with a stale or archived tenant id refuses to run. A tenant-owned endpoint without these tests is not done.

## Binds to a stack

The active pack names: where the tenant guard lives and the request-context mechanism; the scoped repository/query helper and any database-level enforcement (e.g. row-level security); composite-unique and FK-index mechanics; the tenant-scoped storage layout and its authorised read path; how jobs carry and revalidate tenant context; and the frontend's active-tenant carrier and switch-reset mechanism.

## Interactions

- **enterprise-compliance** — that program *assumes* this tenant model (its "Organisation — the tenant"); this add-on supplies it. Adopting both: its RBAC catalog and system roles supersede this add-on's minimal owner/admin/member model, its audit-event envelope carries the tenant id, and its admin-security spec owns the operator surface.
- **Base *Security baseline* + *Audit trail*** — this add-on instantiates both: tenant checks are authorization, and tenant lifecycle + membership changes are audited state changes.
- **Base *Configuration*** — per-tenant settings are data on the tenant; env config never carries a tenant's policy or branding.
- **test-mode** — seed at least two tenants with members so cross-tenant assertions and the test-user picker are walkable; if a pack's *mode signal* happens to be named "tenant", it is a different concept — never resolve the organisation from it.
- **llm-calls** — its per-tenant cost/usage monitoring keys on this add-on's tenant id.
- **`db/CLAUDE.md`** — the tenant FK, composite uniques, and indexes follow its schema conventions and reversible-migration rules.

## Specification map

| Area | Spec |
|---|---|
| Tenant model, membership, invitations, resolution & switching | [`SPEC.md`](SPEC.md) (→ `specs/` on adoption) |
