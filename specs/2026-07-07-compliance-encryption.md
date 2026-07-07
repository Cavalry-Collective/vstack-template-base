# Encryption & key management — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: 2026-07-07-enterprise-compliance-controls.md. Status: proposed.

## Goal

Encrypt by default and manage keys deliberately: TLS on every external interface, platform encryption at rest, application-layer (field-level) encryption for designated high-sensitivity values under a per-organisation envelope-key hierarchy — enabling blast-radius isolation and crypto-shredding on offboarding — with rotation as a stated, rehearsed, audited procedure and no hand-rolled crypto (root *Don't reinvent*).

## Product requirements

1. **In transit:** every external interface terminates TLS 1.2+ (1.3 preferred; older protocols and known-weak ciphers disabled) and sends HSTS per the base security-header rule (`apps/backend/CLAUDE.md`, *Security response headers*). Internal service-to-datastore links are encrypted wherever the deployment crosses a network boundary; the active stack pack binds the mechanics.
2. **At rest:** the primary datastore and object storage are fully encrypted (AES-256 class) via the platform/stack pack. On by default, deployment-level, **not org-visible configuration** — no tenant can turn it off or needs to turn it on.
3. **Field-level encryption** applies to this definitive list of high-sensitivity values: SSO/IdP client secrets and private keys; MFA/TOTP seeds; DSAR package contents; and (P2) custom-field values an org marks sensitive. **Verify-only values are hashed, not encrypted**: API-key material and MFA recovery codes are stored as one-way hashes via the stack pack's vetted algorithm — the system never needs them back, so it must not be able to get them back. Retrieve-and-use values (IdP secrets, TOTP seeds) are encrypted, because the system must present them again.
4. **Key hierarchy (envelope encryption):** a root KEK lives in the stack pack's KMS; each organisation gets a data-encryption key (DEK) generated at org provisioning, wrapped by the KEK, stored in `org_encryption_keys`. Plaintext DEKs exist only in application memory. This yields (a) blast-radius isolation — one org's key compromise exposes one org — and (b) **crypto-shredding**: destroying an org's DEK at offboarding renders residual ciphertext unreadable. The retention-deletion spec (`2026-07-07-compliance-retention-deletion.md`) relies on this contract for erasure; honour it exactly — destruction nulls the wrapped DEK in the live datastore, and backup copies age out within the backup retention window (backup-dr spec), after which the ciphertext is permanently unrecoverable.
5. **KEK rotation:** performed in the KMS at least annually. Under the envelope scheme this re-wraps DEKs only — **no data re-encryption** — and is recorded as an audited event.
6. **DEK rotation:** available on demand (and mandatory on suspected compromise) per organisation: generate a new DEK version, re-encrypt that org's field-level ciphertext via a batched job that is idempotent and resumable per `db/CLAUDE.md` backfill rules, retire the old version when no rows reference it. Rotation start, completion, and failure are audited.
7. **Sensitive custom fields (P2):** an org admin can mark a custom-field definition `sensitive`. Sensitive field values are field-level encrypted with the org's DEK, **excluded from search indexing**, and **excluded from plaintext exports** (export surfaces show a redaction marker; export-bulk-controls spec governs export gating).
8. **KMS/decrypt access is audited at the adapter level for governed operations** — one event per governed operation (a job run, a DSAR package build, an admin secret retrieval), never per row. Per-row events would be noise that drowns the audit trail; aggregate at the operation boundary.
9. **No hand-rolled crypto:** algorithms, primitives, random generation, and hashing come from the stack pack's vetted library. No custom modes, padding, or key derivation.
10. Decrypt failures are data-integrity incidents: the API returns `DECRYPTION_FAILED` (500-class), never ciphertext or a silent empty value, and an alert fires (observability seam per `infra/CLAUDE.md`).
11. New API surfaces ship behind the program's default-off rollout flag (`COMPLIANCE_ENCRYPTION_ENABLED`); baseline TLS/at-rest posture is not flag-gated.

## User flows

### Flow: marking a custom field sensitive (P2)

1. Org admin opens the custom-field settings screen and sets an existing or new field's type/flag to `sensitive` (requires `custom_fields:update`).
2. The API confirms the change; marking is **one-way** (unmarking would require a decrypt-and-reindex backfill and silently downgrade protection — rejected with `SENSITIVE_FIELD_IMMUTABLE`).
3. A background job encrypts existing values for that field (batched, idempotent, resumable) and removes them from the search index.
4. `encryption.field.marked_sensitive` is emitted; the field's values now render only to members with read permission on the record, are unsearchable, and export as a redaction marker.

### Flow: DEK rotation

1. Platform operator (or an automated compromise response) calls the rotation endpoint for the organisation (requires `encryption_keys:rotate`).
2. Service generates a new DEK, wraps it via the KMS, inserts a new `org_encryption_keys` row with incremented `key_version`; `encryption.dek.rotated` is emitted with outcome pending completion.
3. The re-encrypt job walks the org's field-level ciphertext in batches, re-encrypting rows to the new version (each row's stored `key_version` makes the job idempotent and resumable).
4. When zero rows reference the old version, it is marked `retired_at`; job completion is audited. Failure mid-run is safe: both key versions remain decryptable until retirement.

### Flow: org key destruction (crypto-shredding at offboarding)

1. The retention-deletion offboarding use case reaches its irreversible hard-delete stage (grace period elapsed, no legal hold — that spec owns the lifecycle and gates).
2. It invokes the encryption service's destroy operation (system actor; no standalone public endpoint — YAGNI, the lifecycle is the only caller).
3. The wrapped DEK material is overwritten/nulled, `destroyed_at` set, the row retained as evidence; any cached plaintext DEK is evicted.
4. `encryption.org_key.destroyed` is emitted. Residual ciphertext anywhere (including backups, until retention ages them out) is now unreadable; subsequent access attempts surface `ORG_KEY_DESTROYED`.

## Admin capabilities

- **Org admins:** mark custom fields sensitive (`custom_fields:update`, the base custom-field permission — RBAC spec owns its definition); view their org's key status — key version, created/rotated dates, never key material — with `encryption_keys:read`; see rotation/destruction events in their audit log. At-rest and TLS posture are visible only as trust-page documentation (trust-transparency spec), not as settings.
- **Platform operators:** trigger DEK rotation (`encryption_keys:rotate`) via the org-scoped endpoint. KEK rotation is a KMS/infra procedure (runbook under `infra/`), recorded in the audit store when performed.
- Nobody — admin or operator — can read a stored secret back: write-only per the base security baseline.

## API behavior

Org-scoped endpoints under the organisation per program convention; base envelopes; long-running work async.

| Method | Path | Permission | Behaviour |
|---|---|---|---|
| GET | `/internal/v1/organisations/{organisationId}/encryption/key` | `encryption_keys:read` | Current key status: `key_version`, `created_at`, `retired_at`/`destroyed_at` of prior versions, last rotation. Never key material. |
| POST | `/internal/v1/organisations/{organisationId}/encryption/key/rotations` | `encryption_keys:rotate` | Start DEK rotation. Async: `201`, rotation resource in status `pending`; the re-encrypt job drives it to `completed`/`failed`. One active rotation per org. |
| GET | `/internal/v1/organisations/{organisationId}/encryption/key/rotations/{rotationId}` | `encryption_keys:rotate` | Poll rotation progress (batch counts, status). |

- The `sensitive` flag rides the existing custom-field definition endpoints (`…/custom-fields`, owned by the base CRM surface); this spec adds the field, its one-way rule, and the backfill it triggers.
- Key destruction has **no direct endpoint** — it is invoked only by the retention-deletion offboarding use case (see flow above).
- Secrets ingestion (IdP secrets etc.) follows the base write-only rule: accepted on `POST`/`PUT`, never echoed on `GET`, blank-on-update means keep.

## Data model changes

Migrations reversible up/down per `db/CLAUDE.md`; the `sensitive` column addition is additive (expand-only).

`org_encryption_keys` — org-scoped per the index rule (`organisation_id` indexed):

| Column | Notes |
|---|---|
| `id` | PK |
| `organisation_id` | FK → organisations, indexed |
| `wrapped_dek` | DEK ciphertext wrapped by the KEK (binary/encoded); nulled on destruction; **never** plaintext |
| `key_version` | integer, unique with `organisation_id` |
| `created_at`, `updated_at` | standard |
| `retired_at` | nullable — set when a rotation drains the last row off this version |
| `destroyed_at` | nullable — set by crypto-shredding; row retained as evidence |

Invariant: at most one active (non-retired, non-destroyed) version per organisation — partial-unique constraint or engine equivalent, per `db/CLAUDE.md` (constraints encode invariants, not service-layer checks that race).

`custom_field_definitions` (existing table) gains:

| Column | Notes |
|---|---|
| `sensitive` | boolean, not null, default `false`; one-way `false → true` enforced in the use case |

Field-level ciphertext columns store an envelope of `{key_version, iv/nonce, ciphertext, tag}` (exact encoding bound by the stack pack) so every row names the DEK version that encrypted it — this is what makes the re-encrypt job idempotent.

## Backend implementation requirements

- **Ports in the domain ring** of a new `encryption` module: `EncryptionPort` (`encrypt(orgId, plaintext, context)` / `decrypt(orgId, envelope, context)`) and `KeyManagementPort` (`generateDek`, `wrapDek`, `unwrapDek`, KEK identifiers). The domain names no KMS vendor or SDK type.
- **Repo-ring KMS adapter** implements `KeyManagementPort` against the stack pack's KMS and emits the aggregate governed-operation access events (requirement 8) — the adapter is the single choke point, so auditing there catches every path.
- **Encrypt/decrypt boundary sits in repo-ring mappers:** rows carry ciphertext envelopes; mappers decrypt on read and encrypt on write, so the service and domain rings see plaintext values only and no ciphertext shape travels inward. Hashing of verify-only values likewise lives at the adapter/shared-util layer using the vetted library.
- Unwrapped DEKs may be cached in memory per org with a bounded TTL to avoid per-row KMS round-trips; cache eviction on rotation completion and destruction is mandatory.
- **Jobs:** (a) DEK re-encrypt — batched, idempotent via per-row `key_version`, resumable, one active run per org (concurrency guard on the rotation resource); (b) sensitive-field backfill — same discipline, plus search-index removal per batch. Both live under `db/backfills/`-style invocation rules (explicit, never inside a schema migration) and run as `system` actor.
- Decrypt failure in a mapper raises a domain-level integrity error; the controller ring maps it to `DECRYPTION_FAILED` once (single error-mapping site), and the alerting hook fires. Never return partial rows with ciphertext or blanks in place of the failed value.
- Config: KMS endpoint/KEK identifier are validated env config, injected inward as values.

## Audit log events

Standard envelope. Denied attempts on every endpoint emit the matching `…denied` event per program criterion 1.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `encryption.org_key.created` | DEK provisioned for a new org | target `org_encryption_key`; `after`: key_version |
| `encryption.dek.rotated` | Rotation started and (second event row) completed | actor operator/system; `after`: old/new key_version, rows re-encrypted |
| `encryption.dek.rotation_failed` | Re-encrypt job exhausts retries | outcome `failure`; `after`: batch position, reason |
| `encryption.kek.rotated` | Annual/ad-hoc KEK rotation performed in KMS | actor `system`/operator; target KEK identifier (no material) |
| `encryption.org_key.destroyed` | Crypto-shredding at offboarding | actor `system`; target org key; `after`: destroyed_at |
| `encryption.field.marked_sensitive` | Custom field flagged sensitive | actor org admin; target field definition |
| `encryption.dek.unwrapped` | Governed operation obtains an org DEK (aggregate — one per operation, e.g. a DSAR build or job run, never per row) | context: operation name, correlation_id |
| `encryption.decrypt.failed` | Mapper decrypt failure (integrity incident) | outcome `failure`; target record type/id — **never** the ciphertext |

## Security considerations

- Key material never appears in logs, audit payloads, error messages, or API responses — identifiers and versions only (program criterion 5).
- Plaintext DEKs exist only in process memory; never persisted, never in crash dumps by policy (stack pack binds process hardening).
- Hash vs encrypt is a hard rule reviewers enforce: anything only ever *verified* is hashed; encryption of such values is a defect.
- Sensitive custom-field values must not leak via search indexes, plaintext exports, logs, or audit diffs — the redaction marker is the only representation outside the read path.
- Destruction is deliberately unrecoverable; it runs only behind the retention-deletion spec's grace-period and legal-hold gates, and its audit event is the durable proof.
- SSRF/secret-handling/session baselines inherit from `apps/backend/CLAUDE.md`; nothing here relaxes them.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Caller lacks the required permission | 403 | `PERMISSION_DENIED` |
| Ciphertext fails authentication/decryption (integrity incident) | 500 | `DECRYPTION_FAILED` |
| Access touches data whose org DEK was destroyed | 409 | `ORG_KEY_DESTROYED` (409 chosen from the base status set — the resource state conflicts irrecoverably with the request; revisit if the base adopts 410) |
| Rotation requested while one is active | 409 | `ROTATION_ALREADY_IN_PROGRESS` |
| Rotation id unknown | 404 | `ROTATION_NOT_FOUND` |
| Attempt to unmark a sensitive field | 409 | `SENSITIVE_FIELD_IMMUTABLE` |
| KMS unreachable after bounded retries | 500 | `KMS_UNAVAILABLE` |

## User stories & acceptance criteria

**S1 (P1)** — As a customer security reviewer, I want all traffic encrypted in transit with modern TLS, so that data cannot be intercepted between clients and the service.

- [ ] External interfaces accept TLS 1.2+ only (1.3 preferred) and send HSTS. *Verify: TLS scan of the deployed endpoint (protocol/cipher enumeration) + contract test asserting the HSTS header from the shared header site.*
- [ ] Service-to-datastore links crossing a network boundary are encrypted per the stack pack. *Verify: infra review of connection config; connection attempt without TLS is refused in staging.*

**S2 (P1)** — As a customer security reviewer, I want the datastore and object storage encrypted at rest by default, so that stolen media exposes nothing.

- [ ] At-rest encryption (AES-256 class) is enabled on datastore and object storage with no org-visible toggle. *Verify: infra/Terraform review showing encryption enabled + provider console/API attestation recorded for the trust page.*

**S3 (P1)** — As a platform operator, I want designated high-sensitivity values field-level encrypted under per-org DEKs (and verify-only values hashed), so that a datastore leak does not expose secrets and one org's compromise stays contained.

- [ ] IdP secrets, TOTP seeds, and DSAR package contents are stored as ciphertext envelopes; API keys and recovery codes as one-way hashes. *Verify: repo-ring integration test reading raw rows and asserting no plaintext; hash columns verify but never decrypt.*
- [ ] Each org gets a wrapped DEK at provisioning (`encryption.org_key.created` emitted); domain/service rings only ever see plaintext values via mappers. *Verify: use-case test with an in-memory KMS fake asserting the audit event and that no ciphertext type crosses the service boundary.*
- [ ] A decrypt failure returns `DECRYPTION_FAILED` with no ciphertext/empty fallback and fires an alert. *Verify: integration test corrupting a stored envelope, asserting the 500 envelope, the `encryption.decrypt.failed` event, and the alert hook.*

**S4 (P1)** — As a platform operator, I want crypto-shredding on offboarding and rehearsed KEK rotation, so that erasure is provable and key hygiene is routine.

- [ ] Destroying an org's DEK nulls `wrapped_dek`, sets `destroyed_at`, evicts caches, and emits `encryption.org_key.destroyed`; subsequent access yields `ORG_KEY_DESTROYED`. *Verify: integration test running the destroy use case against a seeded org, then attempting a read.*
- [ ] Destruction is callable only from the retention-deletion offboarding use case. *Verify: code/contract review — no route exposes it; use-case test confirms the single caller path.*
- [ ] KEK rotation re-wraps DEKs without data re-encryption and emits `encryption.kek.rotated`. *Verify: rehearsal in staging per the `infra/` runbook — rotate, confirm reads still succeed and row ciphertext unchanged, assert the audit event.*

**S5 (P2)** — As a platform operator, I want on-demand DEK rotation via a batched re-encrypt job, so that a suspected compromise is recoverable without downtime.

- [ ] `POST …/encryption/key/rotations` returns `201 pending`; the job re-encrypts in batches; interrupting and resuming produces no data loss or double-encryption. *Verify: integration test seeding N encrypted rows, killing the job mid-run, resuming, asserting all rows on the new `key_version` and decryptable.*
- [ ] Old version is retired only at zero references; concurrent second rotation returns `409 ROTATION_ALREADY_IN_PROGRESS`. *Verify: contract test firing two POSTs; repo test asserting `retired_at` gating.*

**S6 (P2)** — As an org admin, I want to mark a custom field sensitive, so that regulated values my org stores get field-level protection.

- [ ] Marking a field sensitive encrypts existing values via backfill, removes them from the search index, and excludes them from plaintext exports (redaction marker shown). *Verify: screen flow — mark field, then search for a known value (no hit) and run an export (marker present); repo test asserting raw-row ciphertext.*
- [ ] Unmarking is rejected with `409 SENSITIVE_FIELD_IMMUTABLE`; the marking emits `encryption.field.marked_sensitive`. *Verify: contract test on the update endpoint + audit-row assertion.*

**S7 (P3)** — As an enterprise customer, I want BYOK / customer-managed keys, so that my organisation controls its own KEK.

- [ ] One-line scope: a per-org KEK reference into the customer's KMS replacing the shared KEK for that org's DEK wrapping — requiring KMS cross-account grants, availability/lockout handling when the customer revokes, and per-org KEK rotation contracts. Deferred; no work in this program phase. *Verify: n/a until scheduled — revisit at P3 planning.*

## UX & non-functional notes

- **Screens touched:** custom-field settings (add the sensitive flag + irreversibility warning, P2); org security settings (read-only key-status card, P2); trust page states the posture (owned by trust-transparency spec).
- States: rotation shows pending/in-progress/completed/failed on the key-status card; sensitive-field backfill shows an in-progress indicator until search de-indexing completes.
- Perf: field-level encryption costs a mapper round-trip per row — acceptable because the designated fields are low-volume (secrets, seeds) or read singly (sensitive custom fields); DEK caching keeps KMS calls off the request path. Sensitive fields are excluded from search by design, not by perf necessity.
- Security: redaction markers, not blanks, wherever a sensitive value is withheld — a blank reads as "no data" and corrupts user trust in exports.

## Out of scope

- Region-pinned data residency and customer-dedicated infrastructure (program-wide exclusion).
- Client-side / end-to-end encryption where the server never sees plaintext.
- Encrypting every CRM field by default — field-level scope is the definitive list in requirement 3.
- Password storage policy (base auth owns it; already hashed via the vetted library).

## Open questions

- No `design/` mockup exists yet for the new screens (custom-field sensitive flag in field settings; org security-settings key-status card); required before initial build. Owner: design, before S5/S6 implementation.
- Should `sensitive` be a distinct custom-field *type* or a flag on existing text types? Flag proposed (keeps filtering/validation semantics); decide before S6. Owner: product.
- Is annual KEK rotation sufficient for target contracts, or do some demand quarterly? Owner: product/legal, before trust-page GA.
- Confirm the base status-code set stays without `410 Gone`; if it is adopted repo-wide, `ORG_KEY_DESTROYED` should move to 410. Owner: backend, at implementation.
