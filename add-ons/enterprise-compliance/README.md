# Add-on: enterprise-compliance

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the IdP/SSO libraries, key management, backup mechanics, job runner, and stores named under *Binds to a stack*.

Enterprise controls that make the product **compliance-ready** for customers pursuing SOC 2, ISO 27001, GDPR, and PDPA: access control, auditability, data protection, retention and deletion, recovery, and governance. The software provides the *controls and evidence*; certification itself is organisational work this add-on deliberately does not claim.

This README is the durable SOP — the rules every change must honour once the add-on is adopted. The **buildable program** — per-area product requirements, flows, APIs, data models, and acceptance criteria — ships with the add-on under `specs/` in this directory (see the map at the bottom), so keeping or deleting the add-on carries the whole program. When a project implements an area, that file is its feature spec: follow the repo's spec-first workflow against it (copy it into the top-level `specs/` first if the project prefers specs in one home).

## Approach

- **Every privileged capability ships with three things: a permission, audit events, and org scoping.** No admin or bulk feature merges without a named permission checked at the edge, audit events recorded in the service ring, and every query scoped to the caller's organisation. This is the add-on's core invariant; reviewers reject changes that add capability without all three.
- **The audit trail is the spine.** It instantiates the base *Audit trail* rule at product grade: one shared `record()` call per meaningful state change, an append-only store with a fixed event envelope (defined in the program-index spec), never updated or deleted in place, queryable per organisation, and exportable. If a control's spec says an action is audited, emitting that event is part of that change's Definition of Done.
- **Policy lives in per-org data, not code or env.** Retention windows, MFA enforcement, session lifetimes, IP allowlists, export permissions, and approval thresholds are organisation settings: stored, validated against declared bounds, defaulting to the safe value, and audited on every change. Env config (base *Configuration*) carries only deployment-level values and default-off rollout flags — never a tenant's policy.
- **Deletion is a lifecycle, not a `DELETE`.** Erasure and retention expiry follow soft-delete → grace period → irreversible hard-delete by a background job, with legal hold overriding both. Hard deletion states its blast radius (search indexes, exports, caches, backups) and how each is purged or ages out; "deleted from the primary DB" alone is not erasure.
- **Exfiltration and destruction are gated.** Exports, bulk edits/deletes, and role escalations are permissioned separately from read/write, size- and rate-bounded, audited with scope (what left, how much), and eligible for maker-checker approval where the org's policy demands it.
- **Identity is federated-ready.** Authentication sits behind ports so SSO (SAML/OIDC) and MFA slot in as adapters; sessions are server-revocable; provisioning and deprovisioning are first-class flows (an offboarded user loses access in minutes, not at token expiry).
- **Encrypt by default; keys are managed.** TLS everywhere in transit, encryption at rest, field-level encryption for designated sensitive fields, and key rotation as a stated, rehearsed procedure — never hand-rolled crypto (root *Don't reinvent*).
- **Recovery is drilled, not declared.** Backups run on schedule with stated RTO/RPO targets; restores are rehearsed on a cadence and the evidence recorded. An untested backup is a hope, not a control.
- **Trust artifacts are versioned product content.** The subprocessor register and compliance documentation are maintained, versioned, and change-notified — not a static page that silently drifts.

## Binds to a stack

The active pack names: the SAML/OIDC library and session store; the MFA/WebAuthn library (and OTP delivery, via **otp-auth** if adopted); the KMS/key-management service and at-rest/field-level encryption mechanics; the append-only audit store and its query/export path; the background-job runner (deletion, retention, DSAR, backup verification); object storage for exports and DSAR packages; the backup/restore tooling; and the rate-limit store.

## Interactions

- **Base *Audit trail* + *Security baseline*** — this add-on instantiates and extends both; their rules apply in full.
- **Base *Configuration*** — env config holds deployment values and default-off flags; tenant policy lives in org settings per the Approach.
- **otp-auth** — supplies the OTP channel for MFA and step-up verification; adopt both if OTP is an MFA factor.
- **test-mode** — keeps SSO/MFA/DSAR flows walkable without a live IdP, KMS, or mail provider; stub delivery, never the control logic.
- **`db/CLAUDE.md`** — retention, erasure, and legal-hold schema changes follow its reversible-migration and expand→migrate→contract rules.
- **Maker-checker guards other add-ons' actions too** — any capability an org marks approval-required routes through the shared approval flow, not a forked one.

## Specification map

The program index — shared conventions (event envelope, permission naming, org-policy model) and phasing — is `specs/program-index.md`. Per-area specs:

| Area | Spec |
|---|---|
| SSO & identity lifecycle (SAML/OIDC, SCIM, JIT) | `specs/sso-identity.md` |
| Multi-factor authentication | `specs/mfa.md` |
| Role-based access control | `specs/rbac.md` |
| Audit logs | `specs/audit-logs.md` |
| Data retention & deletion | `specs/retention-deletion.md` |
| Backup & disaster recovery (RTO/RPO) | `specs/backup-dr.md` |
| Encryption & key management | `specs/encryption.md` |
| Admin security controls | `specs/admin-security.md` |
| Export & bulk-action controls | `specs/export-bulk-controls.md` |
| Maker-checker workflows | `specs/maker-checker.md` |
| Privacy requests (DSAR) | `specs/privacy-requests.md` |
| Subprocessors & compliance documentation | `specs/trust-transparency.md` |
