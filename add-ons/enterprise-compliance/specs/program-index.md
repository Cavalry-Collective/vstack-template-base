# Enterprise compliance controls — program index

**Status:** proposed · **Owner:** `<owner>` (set at adoption) · **Add-on:** `add-ons/enterprise-compliance/README.md` (the durable SOP; this spec family is the buildable program)

## Goal

Give the CRM the enterprise controls a compliance-ready SaaS vendor is expected to provide — access control, auditability, data protection, retention/deletion, recovery, and governance — so customers can satisfy SOC 2, ISO 27001, GDPR, and PDPA requirements that depend on their vendor. The product provides controls and evidence; it does not claim certification.

## Area specs

Each control area is an independently shippable spec. Every area spec follows one section template — Goal · Scope & ownership · User stories & acceptance criteria · Requirements · User flows · API & permissions · Data model · Audit events · Implementation notes · Edge cases & errors · Notes & decisions · Out of scope · Open questions — and **inherits the shared conventions below rather than restating them**.

| # | Area | File | Phases | Purpose |
|---|---|---|---|---|
| 1 | SSO & identity lifecycle | `sso-identity.md` | P2–P3 | Federated login (SAML 2.0 / OIDC), domain verification, JIT + SCIM provisioning, enforced SSO with break-glass. |
| 2 | Multi-factor authentication | `mfa.md` | P1–P2 | TOTP + recovery codes now, WebAuthn next; per-org enforcement policy; reusable step-up verification. |
| 3 | Role-based access control | `rbac.md` | P1–P2 | Permission catalog, fixed system roles, custom roles; safe, race-free, audited role changes. |
| 4 | Audit logs | `audit-logs.md` | P1–P3 | The program's spine: append-only store, shared `record()`, viewer, export, retention. |
| 5 | Data retention & deletion | `retention-deletion.md` | P1–P2 | Soft delete → grace → purge lifecycle, retention policies, legal holds, org offboarding. |
| 6 | Backup & disaster recovery | `backup-dr.md` | P1–P3 | Automated encrypted backups, declared RPO/RTO, drilled restores recorded as evidence. |
| 7 | Encryption & key management | `encryption.md` | P1–P3 | TLS + at-rest baseline, field-level encryption under per-org keys, rotation, crypto-shredding. |
| 8 | Admin security controls | `admin-security.md` | P1–P2 | Session and password policy, session management, IP allowlists, API keys, security notifications. |
| 9 | Export & bulk-action controls | `export-bulk-controls.md` | P1–P2 | Permission-gated async exports with expiring artifacts; preview/confirm bulk actions. |
| 10 | Maker-checker workflows | `maker-checker.md` | P2 | One shared dual-control framework every guarded capability routes through. |
| 11 | Privacy requests (DSAR) | `privacy-requests.md` | P1–P2 | DSAR registry, export packages, hold-aware erasure with anonymisation, suppression list. |
| 12 | Subprocessors & compliance documentation | `trust-transparency.md` | P1–P3 | Versioned, change-notified subprocessor register; public trust page; document library. |

## MVP & build order

The program-level MVP (all P1 stories) is: **RBAC (fixed roles), audit logs, MFA (TOTP), admin session controls, export permission gating, retention policy + soft-delete lifecycle, encryption at rest/in transit, documented backups with restore drill, DSAR export & erasure, subprocessor page.** SSO, SCIM, custom roles, maker-checker, BYOK, and the trust-center UI build on that spine as P2/P3.

Build **audit-logs and RBAC first** — every other area depends on `record()` coverage and permission gating existing. Priorities are set per story inside each area spec.

## Shared conventions (binding on every area spec)

A conflict between an area spec and this index is a defect; flag it, don't fork.

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
