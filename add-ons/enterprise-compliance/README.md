# Add-on: enterprise-compliance

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

Enterprise controls that make the product **compliance-ready** for customers pursuing SOC 2, ISO 27001, GDPR, and PDPA: access control, auditability, data protection, retention and deletion, recovery, and governance. The software provides the *controls and evidence*; certification itself is organisational work this add-on deliberately does not claim.

## Approach

- **Every privileged capability ships with three things: a permission, audit events, and org scoping.** No admin or bulk feature merges without a named permission checked at the edge, audit events recorded in the service ring, and every query scoped to the caller's organisation. This is the add-on's core invariant; reviewers reject changes that add capability without all three.
- **Shared naming and scoping conventions bind every area.** Permissions are named `resource:action`, and destructive or exfiltrating verbs (`export`, `bulk_delete`, `purge`) are separate permissions from plain `read`/`update` — a role can edit records yet be unable to export them. Every new table carries the organisation id; a genuinely instance-global table (backups, the subprocessor register) is a stated exception, never a silent default.
- **The audit trail is the spine.** It instantiates the base *Audit trail* rule at product grade: one shared `record()` call per meaningful state change, an append-only store with one fixed event envelope — actor, action, target, outcome, redacted before/after diff, request context — never updated or deleted in place, queryable per organisation, and exportable. If an area below says an action is audited, emitting that event is part of that change's Definition of Done.
- **Policy lives in per-org data, not code or env.** Retention windows, MFA enforcement, session lifetimes, IP allowlists, export permissions, and approval thresholds are organisation settings: stored, validated against declared bounds, defaulting to the safe value, and audited on every change. Env config (base *Configuration*) carries only deployment-level values and default-off rollout flags — never a tenant's policy.
- **Deletion is a lifecycle, not a `DELETE`.** Erasure and retention expiry follow soft-delete → grace period → irreversible hard-delete by a background job, with legal hold overriding both. Hard deletion states its blast radius (search indexes, exports, caches, backups) and how each is purged or ages out; "deleted from the primary DB" alone is not erasure.
- **Exfiltration and destruction are gated.** Exports, bulk edits/deletes, and role escalations are permissioned separately from read/write, size- and rate-bounded, audited with scope (what left, how much), and eligible for maker-checker approval where the org's policy demands it. Maker-checker guards other add-ons' actions too: any capability an org marks approval-required routes through the shared approval flow, not a forked one.
- **Identity is federated-ready.** Authentication sits behind ports so SSO (SAML/OIDC) and MFA slot in as adapters; sessions are server-revocable; provisioning and deprovisioning are first-class flows (an offboarded user loses access in minutes, not at token expiry).
- **Encrypt by default; recovery is drilled, not declared.** TLS everywhere in transit, encryption at rest, field-level encryption for designated sensitive fields, and key rotation as a stated, rehearsed procedure — never hand-rolled crypto (root *Don't reinvent*). Backups run on schedule with stated RTO/RPO targets; restores are rehearsed on a cadence and the evidence recorded. An untested backup is a hope, not a control.
- **Trust artifacts are versioned product content.** The subprocessor register and compliance documentation are maintained, versioned, and change-notified — not a static page that silently drifts.

## Binds to a stack

- **Identity** — the SAML/OIDC library, and the MFA/WebAuthn library (OTP delivery via **otp-auth** if adopted).
- **Stores** — the session store and the rate-limit store.
- **Keys & encryption** — the KMS/key-management service and the at-rest / field-level encryption mechanics.
- **Audit** — the append-only audit store and its query/export path.
- **Jobs** — the background-job runner (deletion, retention, DSAR, backup verification).
- **Storage & backups** — object storage for exports and DSAR packages, and the backup/restore tooling.

## Interactions

- **Base *Audit trail* + *Security baseline*** — this add-on instantiates and extends both; their rules apply in full.
- **Base *Configuration*** — env config holds deployment values and default-off flags; tenant policy lives in org settings per the Approach.
- **multi-tenancy** — supplies the organisation ("the tenant") this program's org scoping, policies, and audit assume; adopt it (or an equivalent organisation model) alongside. Its minimal role model is superseded by this program's RBAC catalog.
- **saas-billing** — its `billing:read`/`billing:manage` permissions join this program's RBAC catalog and its audit events use this program's envelope (details in that add-on's README).
- **otp-auth** — supplies the OTP channel for MFA and step-up verification; adopt both if OTP is an MFA factor.
- **test-mode** — keeps SSO/MFA/DSAR flows walkable without a live IdP, KMS, or mail provider; stub delivery, never the control logic.
- **`db/CLAUDE.md`** — retention, erasure, and legal-hold schema changes follow its reversible-migration and expand→migrate→contract rules.

## Implementation areas

Twelve control areas make up the program. Each area's bullets state what a project must cover there and the calls this add-on has already made — follow them as written. Build audit logs and RBAC first: every other area depends on the shared `record()` call and permission gating. Where an area names record classes, they are a CRM worked example (contacts, companies, deals); substitute your product's record classes.

- **SSO & identity lifecycle (SAML/OIDC, SCIM, JIT).**
  - Cover IdP configuration with a test-connection flow, DNS-verified email domains (one owning org per domain), SP- and IdP-initiated login, and JIT + SCIM provisioning.
  - Validate every assertion/token fully before any account lookup: signature, audience, issuer, freshness with bounded skew, and one-time replay protection.
  - Enforced SSO blocks password login **and** password reset; enabling it requires a verified domain and a successful test, and issues one-time hashed break-glass recovery codes to org owners.
  - JIT provisioning never elevates an existing member's role; only audited group→role mapping changes roles.
  - Deprovisioning revokes all the member's sessions synchronously in the same transaction — access ends in minutes, not at token expiry.
- **Multi-factor authentication.**
  - Factors are TOTP and WebAuthn with hashed one-time recovery codes; OTP over email or SMS is deliberately not a factor.
  - Enforcement is per-org policy (off / optional / required with a grace period); challenge attempts are rate-limited into a temporary lockout with a uniform response that gives no oracle.
  - Provide one reusable step-up verification: a fresh challenge marks the session verified for a short window; dangerous actions across all areas demand it, and a trusted-device token never satisfies it.
  - Admin MFA reset has cross-organisation blast radius (factors are user-level): gate it behind its own permission, a mandatory reason, and approval eligibility.
- **Role-based access control.**
  - One canonical permission catalog and one fixed system-role matrix are the shared registry; other add-ons extend the catalog rather than forking it, and permission strings outside it are rejected on write.
  - Only an Owner grants or revokes Owner, and no actor grants a permission they do not themselves hold.
  - Protect the last active Owner race-safely: lock the Owner assignments before counting so concurrent downgrades cannot both pass.
  - Expose permission resolution through one shared `PermissionChecker` port; guards check at the edge, use cases re-check state-dependent rules, and role changes invalidate the permission cache synchronously.
- **Audit logs.**
  - The store is append-only: the adapter exposes append and query only, and purging goes through a narrow port that accepts nothing but a retention horizon.
  - `record()` runs in the caller's transaction — the event commits or rolls back with the business change.
  - Denied and failed attempts are audited under the attempted action, not only successes; reading audit logs is itself audited, at the search level rather than per row.
  - Audit retention is org-configurable within compliance bounds; the purge job is the only deletion path.
- **Data retention & deletion.**
  - Deletion is soft delete → recycle bin with an org-configurable grace period (default 30 days) → irreversible hard purge by a background job; no synchronous endpoint hard-deletes, so grace and holds cannot be bypassed.
  - State the full blast radius of a hard delete: primary rows and search-index entries are purged in the run; caches, export artifacts, and backups age out on bounded TTLs, and the erasure timelines are documented to customers.
  - Legal holds override every deletion path — purge, retention sweeps, and privacy erasure alike.
  - Retention policies are off by default and require a fresh preview ("this would delete ~N records") before enabling; sweeps soft-delete as actor `system` so swept records still pass through the recycle bin.
  - Org offboarding freezes the organisation read-only for a contractual window, then purges everything and destroys the org's encryption keys.
- **Backup & disaster recovery (RTO/RPO).**
  - Declare RTO, RPO, and backup retention as validated deployment config; the retention window bounds the erasure-in-backups promise, and the declared targets are what the trust page documents.
  - Drill restores at least quarterly into an isolated environment and record each drill as durable evidence: duration vs RTO, loss window vs RPO, integrity checks passed.
  - Corruption recovery is point-in-time restore plus selective repair — never a blind full rollback of a live multi-tenant datastore.
  - Backups are readable only by a dedicated recovery credential the application runtime never holds.
- **Encryption & key management.**
  - TLS on every external interface and at-rest encryption on datastore and object storage are the non-negotiable baseline; designated high-sensitivity values (IdP secrets, TOTP seeds, DSAR packages) additionally get field-level encryption.
  - Field-level keys are per-org DEKs wrapped by a KMS-held KEK: one org's compromise stays contained, and destroying a DEK at offboarding crypto-shreds residual ciphertext, backups included.
  - Hash-vs-encrypt is a hard review rule: a value that is only ever verified (API keys, recovery codes) is hashed one-way; encrypting such a value is a defect.
  - KEK rotation re-wraps DEKs without re-encrypting data; DEK rotation runs as a batched, idempotent, resumable re-encrypt job.
  - Never hand-roll crypto; a decrypt failure is an integrity incident that returns a named error and alerts — never ciphertext or a silent blank.
- **Admin security controls.**
  - Session policy (idle and absolute lifetimes) is bounded org policy; sessions are server-side records the member or an admin can list and revoke with immediate effect.
  - Password policy is a configurable minimum length plus a breach-corpus check (k-anonymity style, degrading safely on outage) — no composition rules; repeated login failures throttle into a temporary lockout.
  - IP allowlisting rolls out through a report-only mode before enforcement, applies to sessions and API keys alike, and a self-lockout guard demands explicit confirmation when the saving admin's own IP would be blocked.
  - API keys are scoped to a subset of the creator's permissions, stored hash-only, shown exactly once, and support expiry, rotation with an overlap window, and immediate revocation.
  - Notify the affected member on new-device login, password change, and MFA change; notify admins on policy change.
- **Export & bulk-action controls.**
  - Export and bulk verbs are separate per-resource permissions — holding read or update never implies export or bulk delete, for members and API keys alike.
  - Exports run as bounded async jobs producing encrypted artifacts stamped with provenance (who, when, what filter, how many), expiring on a bounded TTL (default 7 days), downloadable only via short-lived signed links with issuance and download audited.
  - Bulk actions require a server-computed preview/confirm: the intent pins the matched record ids at preview, so execution touches exactly what was shown and reports skips.
  - Bulk delete is always soft delete; no bulk hard-delete path exists.
  - Org policy layers on role restrictions, record caps, per-actor quotas, and approval thresholds for large exports and bulk deletes.
- **Maker-checker workflows.**
  - One generic intent → decide → execute framework guards every approval-required capability; a per-feature approval implementation is a defect.
  - Initiator ≠ decider is enforced in the store (a DB-level check), not only in code; approval never substitutes for the underlying permission, which the initiator must hold at initiation.
  - Approved intents re-validate at execution — target still exists, initiator still permitted, thresholds still met — and fail closed; pending intents expire on a bounded window.
  - Every guardable entry is off by default, and while policy changes are guarded, changing the approval policy itself routes through approval.
- **Privacy requests (DSAR).**
  - A per-org registry tracks each request's type, subject scope (found via a locate that spans soft-deleted records), assignee, and completion evidence; due dates default to the statutory 30 days and adjust downward only.
  - Access and portability produce encrypted machine-readable packages with expiring, audited download links.
  - Erasure is hold-aware: subject-owned records hard-delete through the retention machinery, and records that must persist are anonymised in place with a random token never derived from the original value — irreversible by anyone, vendor included.
  - Completed erasures feed a salted-hash suppression list that imports and inbound syncs check, skipping and reporting matches so an erased subject cannot be silently resurrected.
- **Subprocessors & compliance documentation.**
  - The subprocessor register is instance-global, operator-managed vendor content with insert-only version history — never tenant-editable, never silently edited.
  - Every register change is announced with an advance-notice period (default 30 days) before it takes effect, and subscribed org admins are notified in-app and by email.
  - A public, unauthenticated trust page serves the current register, pending changes, and public compliance documents.
  - Restricted documents require an org-level grant; the public surface returns 404 for them, not 403, so their existence is never disclosed.

When implementing an area, write the project's requirement spec in the top-level `specs/` (per `specs/README.md`), covering that area's bullets.
