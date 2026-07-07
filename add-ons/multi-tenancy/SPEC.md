# Multi-tenancy — tenant model, membership, resolution & switching

> Buildable program for the `multi-tenancy` add-on (`add-ons/multi-tenancy/README.md`); ships beside it and moves under `specs/` on adoption, per the repo's spec-first workflow. Status: proposed. The tenant noun for this product is **organisation**, matching the enterprise-compliance program (`specs/2026-07-07-enterprise-compliance-controls.md`), which assumes this model where both add-ons are adopted.

## Goal

Give the product a first-class organisation (tenant) model — lifecycle, membership, invitations, tenant resolution, and safe switching — so that multiple real organisations can share one deployment with every read, write, file, job, and event strictly isolated per organisation.

## Product requirements

1. **Organisation**: opaque unique id; `name`; `slug` (globally unique, URL-safe, changeable only by an admin+ and audited); `status` ∈ `active | suspended | archived`; `created_at`/`updated_at`. A `plan` key exists on the organisation for feature/quota checks; billing integration itself is out of scope.
2. **Every tenant-owned table carries `organisation_id`** (FK, indexed). A new table without it must state an instance-global justification in its spec or migration (program cross-cutting rule; shared with the enterprise-compliance program where adopted).
3. **Users are global; membership is per organisation.** Email is globally unique on the user; a user may belong to many organisations; a **member** row binds user ↔ organisation. Uniqueness of tenant-owned values is composite with `organisation_id` (e.g. a project slug repeats across organisations), never global.
4. **Minimal role model**: each member holds one role ∈ `owner | admin | member`. Owner ⊃ admin ⊃ member. At least one active owner must remain at all times — removing, downgrading, or deactivating the last owner is rejected race-safely. *When enterprise-compliance is adopted, its RBAC spec (`specs/2026-07-07-compliance-rbac.md`) supersedes this single-role column with its five system roles and permission catalog; the last-owner rule is the same rule there.*
5. **Tenant resolution is path-based**: every organisation-scoped endpoint lives under `/internal/v1/organisations/{organisationId}/…` (the shape the enterprise-compliance APIs already use). A shared guard resolves the path id and validates, in order: authenticated → the caller has a member row in that organisation → the organisation is `active` → the member's role permits the endpoint. The validated `organisationId` enters the request context and is passed inward as a value; handlers and repos never trust a body- or query-supplied tenant id.
6. **Fail closed, leak nothing.** No or unknown organisation id, or a caller who is not a member → `404 ORGANISATION_NOT_FOUND` (indistinguishable from nonexistence). A member lacking the role → `403 PERMISSION_DENIED`. A resource id belonging to another organisation → `404` for that resource. `status = suspended` → `403 ORGANISATION_SUSPENDED` on every scoped endpoint; `archived` → `404` everywhere except the caller's own membership list and the owner-only unarchive endpoint.
7. **Active organisation & switching**: the client lists the caller's memberships (`GET /internal/v1/users/me/organisations`), renders a switcher, and treats the organisation segment of the URL as the active organisation. Switching is navigation — every request revalidates membership server-side, so a stale or forged selection fails per requirement 6. On switch, the frontend drops all organisation-scoped client state (stores, caches, drafts) before rendering the new organisation.
8. **Invitations**: an admin+ invites by email with a role no higher than their own; a single-use, expiring, hashed token is delivered out-of-band; accepting while authenticated (signing up first if needed) creates the member row. One pending invitation per (organisation, email); inviting an existing member is a `409`. Invitations are listable and revocable by admin+.
9. **Membership lifecycle**: admin+ can change roles (owner grants/revokes owner only — same rule 6 as the RBAC spec) and remove members; any member can leave. All paths enforce the last-owner rule. A removed or departed user loses access on their next request.
10. **Organisation lifecycle**: any authenticated user may create an organisation and becomes its owner; creation seeds the settings row (and, where enterprise-compliance is adopted, the five system roles per its RBAC spec). Owners can archive (soft, reversible) and unarchive. Suspension is an operator action, out of scope here (admin-security spec where adopted).
11. **Settings are one-to-one with the organisation**, stored as validated data (name/branding/preferences as the product grows), never in env config. Settings reads/writes are member/admin+ respectively and scoped like everything else.
12. **Files are tenant-scoped**: every stored object lives under `organisations/{organisationId}/…` and is served only via an authorised read (signed URL or backend proxy) that re-checks membership — never a guessable public URL.
13. **Background jobs carry `organisation_id` in the payload** and revalidate the organisation exists and is `active` before executing; a job for a suspended/archived organisation exits without side effects. Job queries are scoped like request queries.
14. **Audit events** are emitted for organisation lifecycle and membership changes (table below). Where enterprise-compliance is adopted they use its envelope and store; standalone, a minimal append-only log with `{organisation_id, actor, action, target, occurred_at}` suffices.

## User flows

**F1 — Create an organisation (P1).** 1. Authenticated user chooses "New organisation", enters name (slug suggested). 2. Backend creates organisation + owner member + settings row in one transaction, audits `org.created`. 3. UI navigates into the new organisation.

**F2 — Invite & join (P1).** 1. Admin opens Members → "Invite", enters email + role (≤ own). 2. Backend stores the hashed single-use token, delivers the invite, audits. 3. Recipient authenticates (or signs up), accepts; backend validates token liveness, creates the member row, marks the invitation accepted, audits `org.member.joined`. 4. Duplicate accept → `409`; expired → `410`.

**F3 — Switch organisation (P1).** 1. User opens the switcher (listing only their memberships). 2. Picks one; the app navigates to that organisation's URL, dropping organisation-scoped client state. 3. Every subsequent request revalidates membership; a URL for a non-member organisation renders the not-found state.

**F4 — Remove / leave (P1).** 1. Admin removes a member (or a member leaves). 2. Backend enforces the last-owner rule (`409 LAST_OWNER_PROTECTED`), deletes the member row, audits. 3. The removed user's next request to that organisation is a `404`.

**F5 — Archive / unarchive (P2).** 1. Owner archives; scoped endpoints answer `404`; the organisation stays visible with status in the owner's membership list. 2. Owner unarchives via the dedicated endpoint; access resumes.

## API behavior

Base pagination and error envelopes apply. `{organisationId}` endpoints all run the resolution guard (req. 5).

| Method & path | Purpose | Access |
|---|---|---|
| `POST /internal/v1/organisations` | Create; caller becomes owner | any authenticated user |
| `GET /internal/v1/users/me/organisations` | Caller's memberships: `{ organisation { id, name, slug, status }, role }[]` | any authenticated user |
| `GET …/organisations/{organisationId}` | Organisation detail | member |
| `PATCH …/organisations/{organisationId}` | Update name/slug | admin+ |
| `POST …/organisations/{organisationId}/archive` / `…/unarchive` | Lifecycle (F5) | owner |
| `GET …/{organisationId}/settings` / `PUT …/settings` | Read / replace settings | member / admin+ |
| `GET …/{organisationId}/members` | List members with roles | member |
| `PATCH …/{organisationId}/members/{memberId}` | Change role (rules 4, 9) | admin+ (owner for owner grants) |
| `DELETE …/{organisationId}/members/{memberId}` | Remove member | admin+ |
| `DELETE …/{organisationId}/members/me` | Leave | member |
| `POST …/{organisationId}/invitations` | Invite (F2) | admin+ |
| `GET …/{organisationId}/invitations` | List pending invitations | admin+ |
| `DELETE …/{organisationId}/invitations/{invitationId}` | Revoke invitation | admin+ |
| `POST /internal/v1/invitations/{token}/accept` | Accept an invitation | any authenticated user |

## Data model changes

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs indexed):

- **`organisations`** — `id` (PK, opaque); `name`; `slug` (unique); `status` (`active | suspended | archived`, default `active`); `plan` (nullable key); `created_at`; `updated_at`.
- **`organisation_settings`** — `id` (PK); `organisation_id` (FK, unique — one-to-one); validated settings columns added per feature (start minimal); `created_at`; `updated_at`.
- **`members`** — `id` (PK); `organisation_id` (FK, indexed); `user_id` (FK, indexed); `role` (`owner | admin | member`); `created_at`; `updated_at`. Unique `(organisation_id, user_id)`.
- **`invitations`** — `id` (PK); `organisation_id` (FK, indexed); `email`; `role`; `token_hash` (unique; raw token never stored); `invited_by` (member FK); `expires_at`; `accepted_at` (nullable); `revoked_at` (nullable); `created_at`; `updated_at`. One *pending* invitation per `(organisation_id, email)` (partial unique or equivalent — pack `db.md` binds the mechanism).

Existing/future tenant-owned tables gain `organisation_id` (FK, indexed) and organisation-scoped composite uniques per requirement 2/3.

## Backend implementation requirements

- Lives in an `organisations` module (tenant + membership + invitation model, lifecycle rules; the resolution guard is shared edge infrastructure per the app's aspect conventions).
- **The guard is necessary, not sufficient**: rules that depend on state (last owner, role ceilings, org status) are enforced again in the use case.
- **Structural scoping**: tenant-owned repositories require `organisation_id` as a non-optional argument on every method — an unscoped tenant query has no API to call. Database-level enforcement (e.g. row-level security) is optional defence-in-depth the active pack binds.
- **Last-owner race safety**: removal/downgrade/leave runs in one transaction that locks the organisation's owner rows before counting (same mechanics as the RBAC spec's rule 8 where adopted).
- **Membership lookups may be cached** per (user, organisation) with synchronous invalidation on membership/role change and a bounded TTL backstop (≤ 5 minutes).
- **Invitation tokens** are generated with a CSPRNG, stored hashed, compared timing-safely, single-use, expiring — never logged raw (base security baseline; hashing utilities per the active pack).
- **Jobs**: the enqueue site writes `organisation_id` into every tenant-scoped payload; the worker's first step re-reads the organisation and exits cleanly unless `active`.

## Audit log events

| `action` | When emitted |
|---|---|
| `org.created` / `org.updated` / `org.archived` / `org.unarchived` | Lifecycle changes (F1, F5, renames/slug changes) |
| `org.member.invited` / `org.invitation.revoked` | Invitation created / revoked |
| `org.member.joined` | Invitation accepted |
| `org.member.role_changed` | Role change (superseded by `rbac.role.*` where enterprise-compliance is adopted) |
| `org.member.removed` / `org.member.left` | Removal / leave |
| `org.access_denied` | Guard rejection on a scoped endpoint (denied outcome, names the failed check) |

## Security considerations

- Server-side membership validation is the only enforcement point; the memberships list and any client-held active-organisation value are rendering hints.
- Cross-organisation probes are indistinguishable from nonexistence (`404`), including on update/delete — no existence oracle via status-code or timing differences in the guard's happy path.
- File reads re-check membership at request time (revoked members lose file access immediately, not at URL expiry alone).
- Errors, logs, and analytics never carry another organisation's identifiers or counts; log lines carry the acting organisation id for traceability.
- Suspended organisations fail closed everywhere, including jobs and file reads.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Unknown organisation, or caller not a member | 404 | `ORGANISATION_NOT_FOUND` |
| Resource id from another organisation | 404 | `<RESOURCE>_NOT_FOUND` |
| Member lacks the required role | 403 | `PERMISSION_DENIED` |
| Organisation suspended | 403 | `ORGANISATION_SUSPENDED` |
| Slug already taken | 409 | `SLUG_TAKEN` |
| Invitee already a member / pending invitation exists | 409 | `ALREADY_MEMBER` / `INVITATION_PENDING` |
| Invitation expired / revoked | 410 | `INVITATION_EXPIRED` |
| Invitation already accepted | 409 | `INVITATION_ALREADY_ACCEPTED` |
| Last-owner removal/downgrade/leave | 409 | `LAST_OWNER_PROTECTED` |
| Non-owner grants/revokes owner | 403 | `OWNER_GRANT_REQUIRES_OWNER` |

## User stories & acceptance criteria

**S1 (P1)** — As a user, I want to create an organisation and become its owner, so that my team has an isolated home.

- [ ] Creating an organisation seeds the owner member + settings row atomically. *Verify: integration test asserting all three rows (and seeded system roles where enterprise-compliance is adopted) after `POST /internal/v1/organisations`.*
- [ ] Slugs are globally unique; names are not. *Verify: contract test — duplicate slug returns `409 SLUG_TAKEN`; duplicate name succeeds.*

**S2 (P1)** — As a member, I can act only inside organisations I belong to, so that tenants never see each other.

- [ ] A non-member request to any scoped endpoint returns `404 ORGANISATION_NOT_FOUND`. *Verify: contract test per endpoint group with a user from another organisation.*
- [ ] A resource id from organisation B via organisation A's path returns `404` on read, update, and delete. *Verify: integration tests for each verb on a representative tenant-owned resource.*
- [ ] List endpoints return only the path organisation's rows. *Verify: seed two organisations with data, assert the list for each contains no foreign rows.*
- [ ] A role in organisation A grants nothing in B. *Verify: owner of A, plain member of B — admin-only calls in B return `403 PERMISSION_DENIED`.*
- [ ] Per-organisation unique values repeat across organisations. *Verify: insert the same scoped-unique value in two organisations; both succeed; a duplicate within one returns `409`.*

**S3 (P1)** — As a user in several organisations, I can see my current organisation and switch safely.

- [ ] `GET /internal/v1/users/me/organisations` returns exactly the caller's memberships with roles and statuses. *Verify: contract test with a two-organisation user.*
- [ ] The switcher lists only those organisations, and switching drops organisation-scoped client state. *Verify: screen check — switch, assert no data or draft from the previous organisation renders.*
- [ ] Navigating to a non-member organisation's URL renders the not-found state. *Verify: screen check + the S2 contract test backing it.*

**S4 (P1)** — As an admin, I manage members through invitations, role changes, and removal, under safe rules.

- [ ] Invite → accept creates the membership; duplicate/expired/revoked accepts fail with the coded errors. *Verify: integration test walking F2 plus each failure case.*
- [ ] An admin cannot invite or promote above their own role; only owners grant owner. *Verify: contract tests returning `403 OWNER_GRANT_REQUIRES_OWNER`.*
- [ ] The last owner cannot be removed, downgraded, or leave — race-safely. *Verify: two concurrent downgrade requests against a two-owner organisation — exactly one succeeds, the other returns `409 LAST_OWNER_PROTECTED`.*
- [ ] Membership and lifecycle changes appear in the audit log. *Verify: integration test asserting the events table above after F1/F2/F4.*

**S5 (P2)** — As the platform, derived surfaces stay tenant-scoped, so that isolation survives beyond request handlers.

- [ ] Stored files live under `organisations/{organisationId}/…` and a member of A cannot fetch B's file by URL. *Verify: integration test — authorised read for A succeeds, same URL/id as B's member returns `404`/denied.*
- [ ] A job whose organisation is suspended or archived exits without side effects. *Verify: unit test on the worker's revalidation step.*
- [ ] Archive/unarchive behaves per F5. *Verify: contract tests — scoped endpoint `404`s while archived; unarchive restores access; both audited.*

## UX & non-functional notes

- Screens: organisation switcher (nav), create-organisation, members list (roles, remove), invitations (create/list/revoke), organisation settings. All need loading/error/empty states; empty states are per-organisation ("no projects *in this organisation* yet").
- The current organisation name is always visible in the app shell; permission-gated controls hide without the backing role (server stays authoritative).
- The membership lookup sits on every scoped request — one cheap indexed query when the cache is cold, O(1) when warm.

## Out of scope

- Billing/subscription/seat integration — the `plan` key exists; charging against it is a future spec.
- Subdomain or custom-domain tenant resolution (path-based chosen; revisit only with a product requirement).
- Cross-organisation sharing or guest access.
- Operator (super-admin) tooling and organisation suspension UX — enterprise-compliance admin-security spec where adopted; otherwise a future spec.
- SCIM/IdP-driven membership provisioning (`specs/2026-07-07-compliance-sso-identity.md`).

## Open questions

- No `design/` mockups exist yet for the switcher, members, invitations, or settings screens; required before initial build.
- Slug rename: do old slugs redirect (tenant URLs in the wild) or hard-break? Owner: product, before P1 build. Default: hard-break (ids, not slugs, in API paths — only frontend URLs are affected).
- Should a suspended organisation stay readable (read-only) for owners to fix billing? Default: fully closed until a billing spec exists.
