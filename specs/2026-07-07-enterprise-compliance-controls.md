# Enterprise compliance controls — program index

**Status:** proposed · **Owner:** adam@hydrax.io · **Add-on:** `add-ons/enterprise-compliance/README.md` (the durable SOP; this spec family is the buildable program)

## Goal

Give the CRM the enterprise controls a compliance-ready SaaS vendor is expected to provide — access control, auditability, data protection, retention/deletion, recovery, and governance — so customers can satisfy SOC 2, ISO 27001, GDPR, and PDPA requirements that depend on their vendor. The product provides controls and evidence; it does not claim certification.

## How this program is organised

Each control area is an independently shippable spec (listed at the bottom). Every area spec follows one section template — Goal · Product requirements · User flows · Admin capabilities · API behavior · Data model changes · Backend implementation requirements · Audit log events · Security considerations · Error cases · User stories & acceptance criteria · UX & non-functional notes · Out of scope · Open questions — and **inherits the shared conventions below rather than restating them**. A conflict between an area spec and this index is a defect; flag it, don't fork.

## Shared conventions (binding on every area spec)

### Domain model & terminology

- **Organisation** — the tenant. All CRM data (contacts, companies, deals, pipelines, activities, notes, custom fields) and all policy hang off exactly one organisation.
- **Member** — a user's membership in an organisation, carrying their role(s). A user may belong to several organisations; policy and permissions are always evaluated per-membership.
- **Actor** — whoever causes a state change: `user` (a member), `api_key` (a programmatic credential), or `system` (jobs, retention sweeps, IdP-initiated provisioning). Every audited action names its actor.
- **Org policy** — per-organisation compliance settings (MFA enforcement, session lifetimes, retention windows, export permissions, approval rules…). Stored as data, validated against declared bounds, safe-by-default, audited on change. Env config never carries tenant policy.

### Permissions

- Named `resource:action`, lowercase (`contacts:export`, `audit_logs:read`, `org_policy:update`, `members:manage`). Destructive/exfiltrating verbs (`export`, `bulk_delete`, `purge`) are **separate permissions** from plain `read`/`update` — a role can edit contacts yet be unable to export them.
- Checked at the controller edge (guard) with rule-level authorisation in the use case where it depends on domain state. `403` uses error code `PERMISSION_DENIED` with the missing permission named in `error.details`.

### Audit event envelope

One append-only audit store, one envelope (field names snake_case; see the audit-logs spec for storage and query semantics):

```
id, occurred_at (UTC), organisation_id, actor { type, id, display }, action,
target { type, id, display }, outcome (success | failure | denied),
before, after (redacted diffs, only where the area spec says so),
context { correlation_id, ip, user_agent, session_id, request_path }
```

- `action` is dot-separated `area.object.verb` past tense: `auth.login.succeeded`, `rbac.role.updated`, `retention.policy.updated`, `export.contacts.completed`. Area specs enumerate their events using this scheme.
- Events are emitted through the base backend's single shared `record()` call in the service ring, in the same transaction/use case as the change. **Denied and failed attempts are audited, not only successes.**
- Envelope contents are PII-redacted per the base logging rules: identifiers and diffs of governed fields, never secrets, tokens, or full sensitive payloads.

### API conventions

- Everything ships under `/internal/v1/…` per the backend contract (external exposure is a later, per-endpoint decision). Compliance/admin resources live under the organisation: `/internal/v1/organisations/{organisationId}/…` (e.g. `…/audit-events`, `…/policies`, `…/exports`).
- Base pagination envelope for lists; audit and export listings may adopt cursor pagination (documented per endpoint). Base error envelope with `SCREAMING_SNAKE_CASE` codes; each area spec enumerates its codes.
- Long-running work (exports, erasure, restores, DSAR packages) is **asynchronous**: `POST` returns `201` with a job/resource in status `pending`; clients poll the resource. No endpoint streams an unbounded dataset synchronously.

### Data model

- Follows `db/CLAUDE.md`: snake_case, `created_at`/`updated_at`, UTC timestamps, indexed FKs, unique constraints encoding invariants. Every new table introduced by this program carries `organisation_id` (indexed) unless it is genuinely instance-global (e.g. the subprocessor register).
- Soft-deletable CRM records gain `deleted_at` (nullable) + `deleted_by`; hard deletion is performed only by background jobs honouring grace periods and legal holds (retention-deletion spec owns the lifecycle).

### Rollout & flags

Each area ships behind a default-off validated-config boolean (base *Integrations* gating) until GA'd; org-visible behaviour changes (e.g. MFA enforcement) additionally respect the org's own policy switch so a platform flag flip never force-changes a tenant's posture.

### Phasing

Priorities are set per story inside each area spec, but the program-level MVP (all P1 stories) is: **RBAC (fixed roles), audit logs, MFA (TOTP), admin session controls, export permission gating, retention policy + soft-delete lifecycle, encryption at rest/in transit, documented backups with restore drill, DSAR export & erasure, subprocessor page.** SSO, SCIM, custom roles, maker-checker, BYOK, and the trust-center UI build on that spine as P2/P3.

Build order note: **audit-logs and RBAC first** — every other area depends on `record()` coverage and permission gating existing.

## Cross-cutting acceptance criteria (apply to every area)

1. Every new privileged endpoint has a named permission; calling it without that permission returns `403 PERMISSION_DENIED` and emits a `…denied` audit event. *Verify: contract test per endpoint exercising allowed + denied.*
2. Every state change named in an area spec's audit-events table appears in the audit store with the full envelope. *Verify: integration test asserting the event row after exercising the flow.*
3. No new table without `organisation_id` scoping (or a stated instance-global justification in the spec). *Verify: migration review + a repo query test proving cross-org reads return nothing.*
4. All new settings validate against declared bounds and default to the safe value. *Verify: unit tests on the policy schema, including out-of-bounds rejection.*
5. No secret, token, or governed-field plaintext appears in logs or audit payloads. *Verify: assertion on log/audit output in the relevant integration tests.*

## Out of scope (program-wide)

- Achieving or asserting certification (SOC 2 report, ISO 27001 certificate) — organisational work, not product code.
- Region-pinned data residency and customer-dedicated infrastructure.
- A customer-facing compliance API for third-party GRC tools (revisit after GA).
- Anonymisation/pseudonymisation analytics pipelines beyond what erasure requires.

## Open questions

- Which IdPs must be certified for launch (Okta, Entra ID, Google Workspace assumed)? Owner: product; needed before the SSO spec's P2 stories start.
- Are audit-log and backup retention floors contractual (per-plan) or uniform? Owner: product/legal; before retention GA.
- `design/` has no mockups for the new admin surfaces (security settings, audit viewer, approvals, trust center) — each area spec lists its screens; mockups must exist before each initial build per the spec convention.

## Area specs

| # | Area | File |
|---|---|---|
| 1 | SSO & identity lifecycle | `2026-07-07-compliance-sso-identity.md` |
| 2 | Multi-factor authentication | `2026-07-07-compliance-mfa.md` |
| 3 | Role-based access control | `2026-07-07-compliance-rbac.md` |
| 4 | Audit logs | `2026-07-07-compliance-audit-logs.md` |
| 5 | Data retention & deletion | `2026-07-07-compliance-retention-deletion.md` |
| 6 | Backup & disaster recovery | `2026-07-07-compliance-backup-dr.md` |
| 7 | Encryption & key management | `2026-07-07-compliance-encryption.md` |
| 8 | Admin security controls | `2026-07-07-compliance-admin-security.md` |
| 9 | Export & bulk-action controls | `2026-07-07-compliance-export-bulk-controls.md` |
| 10 | Maker-checker workflows | `2026-07-07-compliance-maker-checker.md` |
| 11 | Privacy requests (DSAR) | `2026-07-07-compliance-privacy-requests.md` |
| 12 | Subprocessors & compliance documentation | `2026-07-07-compliance-trust-transparency.md` |
