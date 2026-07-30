# Add-on: enterprise compliance

This add-on provides product controls and evidence for customers pursuing SOC 2, ISO 27001, GDPR, or PDPA programs. Certification also requires organisational policies, operation of the controls, evidence review, and independent audit.

## Prerequisites

Adopt `multi-tenancy` or provide an equivalent organisation model. Scope policy, permissions, audit events, and product records to that organisation.

## Common rules

Implement the shared audit path and role-based access control before the other areas.

Every privileged capability must have:

- a `resource:action` permission checked at the request boundary;
- an audit event recorded by the owning use case;
- organisation scope on every query.

Give export, bulk-delete, purge, and role-escalation actions separate permissions. Keep organisation policy in validated organisation data, validate it against declared bounds, choose safe defaults, and audit every change. Keep deployment settings in environment configuration.

## Implementation areas

### SSO and identity lifecycle

- Support service-provider-initiated and identity-provider-initiated SAML or OIDC login behind the authentication port. Provide provider configuration and a test-connection flow.
- Verify email-domain ownership through DNS and allow one organisation to own a domain.
- Validate signature, issuer, audience, freshness, and replay protection before account lookup.
- Require a verified domain and successful test before enforcing SSO. Block password login and reset, then issue hashed single-use break-glass codes to owners.
- Support JIT and SCIM provisioning. Do not let JIT elevate an existing member, and revoke sessions immediately on deprovisioning.

### Multi-factor authentication

- Support TOTP and WebAuthn with encrypted seeds and hashed single-use recovery codes. Do not treat email or SMS OTP as MFA.
- Store enforcement as `off`, `optional`, or `required` organisation policy with a bounded enrollment grace period.
- Rate-limit failures, apply a temporary lockout, and return a uniform response.
- Provide one short-lived step-up flow for dangerous actions. A trusted-device token must not satisfy it.
- Give administrator MFA reset its own permission, mandatory reason, audit event, and approval option.

### Role-based access control

- Keep one permission catalog and one fixed system-role matrix. Other add-ons extend the catalog rather than creating another checker.
- Reject unknown permission strings and prevent actors from granting permissions they do not hold.
- Allow only owners to grant or revoke owner. Lock owner assignments before checking the last-owner rule.
- Resolve permissions through one `PermissionChecker` port. Check static permissions at the edge and state-dependent rules in the use case.
- Invalidate permission caches synchronously after role changes.

### Audit logs

- Record organisation, actor, action, target, outcome, correlation ID, request context, and a redacted before-and-after diff through one `record()` operation.
- Commit the audit event in the business transaction.
- Use an append-only store with append and query operations. Expose retention purge through a separate narrow port.
- Audit denied and failed attempts. Audit an audit-log search once rather than each returned row.
- Keep retention within declared bounds and allow only the retention job to purge events.

### Retention and deletion

- Use soft delete, a recycle-bin grace period, then background hard purge. Default the grace period to 30 days.
- Let legal holds override user deletion, retention, privacy erasure, and organisation offboarding.
- Keep retention policies off by default and require a fresh affected-record preview before enabling one.
- Purge primary rows and search indexes directly. Give caches, exports, and backups documented maximum retention periods.
- Freeze an offboarded organisation for its recovery window, then purge it and destroy its data-encryption keys.

### Backup and disaster recovery

- Define RTO, RPO, backup retention, and restore-test cadence in validated deployment configuration.
- Restrict backups to a recovery credential the application runtime does not hold.
- Run isolated restore drills at least quarterly and record duration, recovery point, integrity checks, and comparison with RTO and RPO.
- Recover corruption with point-in-time restore and selective repair rather than replacing the live datastore blindly.

### Encryption and key management

- Require TLS externally and encryption at rest for databases and object storage.
- Encrypt identity-provider secrets, TOTP seeds, privacy packages, and other designated sensitive fields.
- Use per-organisation data-encryption keys wrapped by a KMS-held key-encryption key.
- Hash values used only for verification, including API keys and recovery codes.
- Rewrap keys for key-encryption-key rotation and use a batched resumable job for data-encryption-key rotation.
- Treat decryption failure as an integrity incident. Return a named error, alert, and never hand-roll cryptography.

### Administrative security

- Keep server-side sessions with bounded idle and absolute lifetimes. Let members and authorised administrators revoke them immediately.
- Use a minimum password length and breach-corpus check rather than composition rules. Degrade safely if the corpus is unavailable and temporarily lock repeated login failures.
- Apply IP allowlists to sessions and API keys. Roll them out in report-only mode and require confirmation when an administrator would block their own IP.
- Store API keys hashed, show them once, scope them below the creator's permissions, and support expiry, rotation, and revocation.
- Notify affected members of login, password, and MFA security events. Notify administrators of policy changes.

### Exports and bulk actions

- Separate export and bulk permissions from read and update.
- Run exports as bounded asynchronous jobs with encrypted artifacts, a default seven-day expiry, and short-lived links. Record the actor, filter, record count, creation, link issuance, and download.
- Generate a server-side preview and pin its record IDs before a bulk action. Execute only against that set and report revalidation skips.
- Make bulk deletion a soft delete. Provide no bulk hard-delete path.
- Apply organisation policy for role restrictions, record caps, actor quotas, and approval thresholds.

### Maker-checker approval

- Use one shared intent, decision, and execution workflow for every approval-controlled action.
- Prevent the initiator from deciding their own intent with a database constraint.
- Require the underlying permission at initiation and recheck permission, target state, and policy before execution.
- Fail closed when state changed and expire pending intents after a bounded period.
- Keep approval rules off by default. Route approval-policy changes through approval when the current policy requires it.

### Privacy requests

- Track request type, subject, assignee, due date, status, and evidence in an organisation-scoped registry. Search active and soft-deleted data.
- Default the due date to 30 days and allow policy to shorten it.
- Produce encrypted machine-readable access and portability packages with short-lived audited links.
- Run erasure through the legal-hold-aware deletion system. Anonymise records that must remain with random irreversible tokens.
- Add completed erasures to a salted-hash suppression list. Imports and inbound synchronisation must skip and report matches.

### Subprocessors and compliance documents

- Keep the subprocessor register instance-global, operator-managed, and insert-only by version.
- Default change notice to 30 days and notify subscribed administrators in the app and by email.
- Publish the current register, pending changes, and public documents on an unauthenticated trust page.
- Require an organisation grant for restricted documents and return `404` without one.

## Verify

For every implemented area, test its permission, organisation scope, audit event, and failure path.

Also test last-owner concurrency, SSO enforcement, session revocation, audit transactionality, legal holds, maker-checker separation, bulk preview bounds, secret hashing, and restricted-document concealment.

Record restore drills as operational evidence.

## Binds to a stack

The active stack pack identifies:

- SAML or OIDC and WebAuthn libraries;
- session and rate-limit stores;
- KMS and field encryption;
- append-only audit storage;
- background jobs;
- object storage, backups, and restore tooling.

## Interactions

- **Base audit, security, and configuration:** extend their shared request, logging, ownership, and configuration rules.
- **multi-tenancy:** use its organisation and scoping. Replace its minimal roles and operator rules.
- **saas-billing:** add billing permissions to the catalog and use this audit envelope.
- **otp-auth:** use it for contact verification or recovery delivery, not as an MFA factor.
- **test-mode:** stub delivery, identity-provider, and key-management calls without bypassing control logic.
- **Database rules:** use reversible migrations and expand, migrate, contract for sensitive schema changes.
