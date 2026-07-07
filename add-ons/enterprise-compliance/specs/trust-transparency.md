# Subprocessors & compliance documentation — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make the vendor's trust posture a maintained product surface: a versioned, change-notified subprocessor register with a public page, and a compliance documentation library (public and restricted) — so customers get the transparency their DPAs and security reviews require instead of a static page that silently drifts.

## Product requirements

1. An **instance-global** subprocessor register records, per subprocessor: name, purpose, data categories processed, processing location/region, and added/removed dates. It carries **no `organisation_id`** — the stated exception under the index's data-model rule: the register describes the *vendor's own* processing chain, which is identical for every tenant; per-org rows would be N copies of one fact.
2. **Register content is managed by the platform operator (vendor staff), never tenant admins.** For v1, operator management is a minimal set of endpoints authenticated by an operator-scoped credential supplied by the active stack pack; an operator admin UI is P3.
3. Every register mutation (add, replace/update, remove) creates an immutable **register version** capturing the change type, announcement time, and effective date. Removal marks the row removed at the effective date; it never deletes history.
4. Changes carry a configurable **advance-notice period** (default **30 days**, bounds 7–90, set per change) between announcement and effective date, so customers can object per their DPA before the change takes effect.
5. On announcement, **subscribed org admins are notified in-app and by email**. Email goes through the gated delivery flag per the backend Integrations rule and is stubbed under the test-mode add-on; notification fan-out is an async background job.
6. Each org-admin member manages their own notification preference (in-app / email toggles) for register changes.
7. A **public, unauthenticated read endpoint and page** serves the current register plus announced pending changes.
8. A **compliance documentation library** holds the DPA template, security overview/whitepaper, pen-test summary, subprocessor-list PDF, and certification reports when they exist. Each document has a visibility level: `public` or `restricted`.
9. `restricted` documents require an **org-level grant** (created by the operator); restricted downloads are audited. `public` documents are downloadable from the public surface.
10. Documents are **versioned with effective dates**; the current version is the latest whose effective date has passed. Older versions stay retrievable to holders of access.
11. Tenant-facing read/notify surfaces are org-scoped and permission-gated; operator mutations are audited as platform-scope events (`organisation_id` null, per the audit-logs spec, requirement 10 there).

## User flows

**Operator announces a subprocessor change**
1. An operator (operator-scoped credential) calls the add, update, or removal endpoint, optionally overriding `noticeDays` (default 30).
2. A register version is created: `announced_at = now`, `effective_at = now + noticeDays`.
3. The notification job fans out in-app notices and emails to subscribed org admins, recording deliveries idempotently.
4. The public page and tenant trust center show the pending change until it becomes effective.

**Org admin reviews a change and manages preferences**
1. An org admin receives the in-app/email notice and opens the trust center.
2. They see the current register, the pending change with its effective date, and the notice window in which to object via their DPA channel.
3. Under notification preferences they toggle in-app/email for future register changes (`trust_notifications:manage`).

**Prospect checks the public trust page**
1. An unauthenticated visitor opens the public trust page.
2. They see the current subprocessor register, announced pending changes, and the public document library with downloads.

**Org admin downloads a restricted document**
1. An admin with `compliance_documents:read` opens the tenant document library; restricted documents appear only if their org holds a grant.
2. They download the current version via a short-lived signed URL; the download is audited (`trust.document.downloaded`).

## Admin capabilities

Tenant org admins:
- **View register + pending changes and the document library** (public docs plus granted restricted docs) — `compliance_documents:read`.
- **Download documents** (restricted downloads audited) — `compliance_documents:read` + an org grant for restricted ones.
- **Manage their own register-change notification preferences** — `trust_notifications:manage`.

Platform operator (operator credential, not org permissions):
- Add/update/remove subprocessors (each creating a version and triggering notice), manage documents, publish document versions, create/revoke org grants for restricted documents.

## API behavior

Three surfaces; base error envelope everywhere; lists use the base offset pagination envelope (register and library volumes are small — no cursor case here).

**Public — `/external/v1/trust/…`** (unauthenticated; deliberate external exposure per the backend visibility rule: this surface exists precisely for people without accounts):

| Method | Path | Permission | Purpose / notable fields |
|---|---|---|---|
| GET | `/external/v1/trust/subprocessors` | none | Current register + announced pending changes (`changeType`, `effectiveAt`). |
| GET | `/external/v1/trust/documents` | none | Public documents, current versions only (title, category, `effectiveAt`). |
| GET | `/external/v1/trust/documents/{documentId}/download` | none | Download a public document's current version (short-lived signed URL response). `404` for restricted/unknown ids — existence of restricted docs is not disclosed here. |

**Tenant — `/internal/v1/organisations/{organisationId}/trust/…`** (session auth + org membership):

| Method | Path | Permission | Purpose / notable fields |
|---|---|---|---|
| GET | `…/trust/subprocessors` | `compliance_documents:read` | Register + pending changes, same shape as public (in-app trust center source). |
| GET | `…/trust/documents` | `compliance_documents:read` | Public docs + restricted docs the org is granted; each with visibility, category, current-version `effectiveAt`, prior versions. |
| GET | `…/trust/documents/{documentId}/download?version={n}` | `compliance_documents:read` (+ org grant if restricted) | Download current (or a named prior) version via short-lived signed URL. Restricted downloads audited. |
| GET | `…/trust/subprocessor-notifications` | `trust_notifications:manage` | The calling member's preferences: `inAppEnabled`, `emailEnabled`. |
| PUT | `…/trust/subprocessor-notifications` | `trust_notifications:manage` | Replace the calling member's preferences (full-resource `PUT` per the backend contract). |

**Operator — `/internal/v1/operator/trust/…`** (operator-scoped credential per the stack pack; sits outside the organisation path because the resources are instance-global vendor content, not tenant data):

| Method | Path | Purpose / notable fields |
|---|---|---|
| POST | `/internal/v1/operator/trust/subprocessors` | Add: `name`, `purpose`, `dataCategories`, `processingLocation`, optional `noticeDays` (7–90, default 30). `201`; creates an `added` version. |
| PUT | `/internal/v1/operator/trust/subprocessors/{subprocessorId}` | Replace/update the entry; creates a `replaced` version with its own notice period. |
| POST | `/internal/v1/operator/trust/subprocessors/{subprocessorId}/removal` | Announce removal (`201` with the `removed` version; row's `removed_at` = effective date). A POST, not DELETE — nothing is deleted, a dated change is scheduled. |
| GET | `/internal/v1/operator/trust/register-versions` | List versions (base pagination), for review and evidence. |
| POST | `/internal/v1/operator/trust/documents` | Create a document: `title`, `category`, `visibility` (`public` \| `restricted`). |
| PUT | `/internal/v1/operator/trust/documents/{documentId}` | Update metadata/visibility. |
| POST | `/internal/v1/operator/trust/documents/{documentId}/versions` | Publish a version: file reference (object-storage upload flow per stack pack), `effectiveAt`. |
| POST | `/internal/v1/operator/trust/documents/{documentId}/grants` | Grant an org access to a restricted document: `organisationId`. `409` if it exists. |
| DELETE | `/internal/v1/operator/trust/documents/{documentId}/grants/{grantId}` | Revoke a grant (`204`). |

Notification fan-out is asynchronous per the index (announcement returns immediately; delivery is a job). Nothing here is long-running enough for a polled job resource.

## Data model changes

All migrations reversible per `db/CLAUDE.md` (up creates, down drops; tables start empty). Instance-global tables (no `organisation_id`) are justified per requirement 1; the org-scoped ones carry it as usual.

- `subprocessors` — **instance-global**: `id` PK, `name`, `purpose`, `data_categories` (JSON array of category labels), `processing_location`, `added_at` (effective add date), `removed_at` (nullable effective removal date), `created_at`, `updated_at`.
- `subprocessor_register_versions` — **instance-global**, insert-only history: `id` PK, `version_number` (unique, monotonic), `subprocessor_id` FK indexed, `change_type` (`added` | `replaced` | `removed`), `change_summary`, `snapshot` (JSON of the entry as announced), `notice_days`, `announced_at`, `effective_at`, `created_at`, `updated_at`.
- `compliance_documents` — **instance-global**: `id` PK, `title`, `category` (`dpa_template` | `security_overview` | `pen_test_summary` | `subprocessor_list` | `certification_report`), `visibility` (`public` | `restricted`), `created_at`, `updated_at`.
- `compliance_document_versions` — **instance-global**: `id` PK, `document_id` FK indexed, `version_number` (unique per document), `effective_at`, `storage_key` (object storage, stack pack), `file_name`, `content_type`, `size_bytes`, `created_at`, `updated_at`.
- `compliance_document_grants` — **org-scoped**: `id` PK, `document_id` FK indexed, `organisation_id` FK indexed, `created_at`, `updated_at`; unique `(document_id, organisation_id)` — the invariant lives in the constraint, violation maps to `409`.
- `subprocessor_notification_preferences` — **org-scoped**: `id` PK, `organisation_id` FK indexed, `member_id` FK indexed, `in_app_enabled`, `email_enabled`, `created_at`, `updated_at`; unique `(organisation_id, member_id)`.
- `subprocessor_notice_deliveries` — **org-scoped**, makes fan-out idempotent: `id` PK, `register_version_id` FK indexed, `organisation_id` FK indexed, `member_id`, `channel` (`in_app` | `email`), `sent_at`, `created_at`, `updated_at`; unique `(register_version_id, member_id, channel)`.

## Backend implementation requirements

- **Module:** `trust` with the standard rings. Domain: register/document entities, the version-on-mutation invariant, notice-period bounds, visibility/grant rules. Service: operator mutation use cases (each creating its version and emitting audit + scheduling notices in one transaction), tenant read use cases, preference use case, the fan-out job's use case. Repo: store adapters, object-storage port, notification/email ports. Controller: the three surfaces.
- **Operator authentication** is a controller-edge guard verifying the operator-scoped credential through a port the stack pack implements. The credential is deployment config (env, per the base Configuration rule) — it is vendor staff tooling, not tenant policy.
- **Versioning:** mutations never edit history — `subprocessor_register_versions` is insert-only through its adapter (append + query, same pattern as the audit store); the current register is derived from `subprocessors` + pending versions.
- **Notification fan-out job:** triggered per register version; batched over subscribed org admins; **idempotent** via the unique `(register_version_id, member_id, channel)` delivery row — a retry after partial failure skips already-delivered rows. Email routes through the default-off delivery flag with a stdout/no-op sink (test-mode add-on keeps the flow walkable); in-app notices use the app's notification mechanism (stack pack).
- **Concurrency:** `version_number` allocation and grant creation rely on unique constraints, mapping violations to `409` rather than racing service-layer checks.
- **Downloads** return short-lived signed URLs from the object-storage port; file bytes never stream through the API process.
- **Audit:** all events below go through the shared `record()` (audit-logs spec). Operator mutations record platform-scope events (`organisation_id` null); tenant-visible facts (notices sent, restricted downloads, preference changes) record org-scoped events.
- Rollout behind a default-off validated-config boolean per the index.

## Audit log events

Denied attempts follow the audit-logs spec convention: attempted action with `outcome: denied`.

| Action | When emitted | Notable envelope fields |
|---|---|---|
| `trust.subprocessor.added` | Operator adds a subprocessor (platform-scope) | `after` = entry snapshot, `notice_days`, `effective_at` |
| `trust.subprocessor.replaced` | Operator updates/replaces an entry (platform-scope) | `before`/`after` = entry diff; version id as target |
| `trust.subprocessor.removed` | Operator announces removal (platform-scope) | `after` = `effective_at`, `notice_days` |
| `trust.document.created` | Operator creates a document (platform-scope) | `after` = title, category, visibility |
| `trust.document.updated` | Operator changes metadata/visibility (platform-scope) | `before`/`after` incl. visibility change |
| `trust.document.version_published` | Operator publishes a version (platform-scope) | `after` = version number, `effective_at` |
| `trust.document.grant_created` | Operator grants an org a restricted doc (platform-scope) | target = the org; document id in `after` |
| `trust.document.grant_revoked` | Operator revokes a grant (platform-scope) | target = the org |
| `trust.register.notice_sent` | Fan-out completes for an org on a version (org-scoped, actor `system`) | `after` = version id, channels, recipient count |
| `trust.document.downloaded` | A member downloads a **restricted** document (org-scoped); `outcome: denied` when the grant or permission is missing | target = document version; actor = the member |
| `trust.notifications.updated` | A member changes their notification preferences (org-scoped) | `before`/`after` = toggle values |

## Security considerations

- The operator credential follows the backend security baseline: environment-supplied, never logged or echoed, write-only if ever stored through an API; verification mechanics per the stack pack. Compromise blast radius is vendor trust content only — it grants no tenant-data access.
- Public endpoints are read-only, expose no tenant data or auth artifacts, and are safe to cache/CDN.
- Restricted-document existence is not disclosed on the public surface (`404`, requirement in API table); tenant listings show only granted documents.
- Downloads use short-lived signed URLs; storage keys are never exposed raw.
- Notification emails contain the change summary and effective date only — no tenant data beyond the recipient address.
- Every mutation is audited; the version history plus platform-scope audit events are the evidence trail for DPA notice obligations.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing/invalid operator credential on an operator endpoint | 401 | `OPERATOR_AUTH_REQUIRED` |
| Member lacks the endpoint's permission | 403 | `PERMISSION_DENIED` (missing permission in `error.details`) |
| Restricted document without an org grant (tenant download/list detail) | 403 | `DOCUMENT_ACCESS_NOT_GRANTED` |
| Unknown subprocessor id | 404 | `SUBPROCESSOR_NOT_FOUND` |
| Unknown document id (or restricted id on the public surface) | 404 | `DOCUMENT_NOT_FOUND` |
| Unknown document version | 404 | `DOCUMENT_VERSION_NOT_FOUND` |
| Unknown grant id on revoke | 404 | `GRANT_NOT_FOUND` |
| Grant already exists for that org + document | 409 | `GRANT_ALREADY_EXISTS` |
| Removal announced for an already-removed subprocessor | 409 | `SUBPROCESSOR_ALREADY_REMOVED` |
| `noticeDays` outside 7–90 | 400 | `NOTICE_PERIOD_OUT_OF_BOUNDS` |

## User stories & acceptance criteria

**S1 (P1)** — As a prospect or customer security reviewer, I want a public, current subprocessor page, so that I can assess the vendor's processing chain without an account.

- [ ] `GET /external/v1/trust/subprocessors` returns the current register (name, purpose, data categories, location, added date) plus announced pending changes, unauthenticated. *Verify: contract test without credentials asserting shape and content.*
- [ ] The public trust page renders the register with loading/error/empty states (empty = "no subprocessors listed"). *Verify: screen walkthrough of all three states plus a populated register.*
- [ ] Operators can populate the register via the add/update/removal endpoints; each mutation creates a register version row and its platform-scope audit event. *Verify: integration test per mutation asserting the version row and audit event; call with a bad credential asserting `401 OPERATOR_AUTH_REQUIRED`.*

**S2 (P2)** — As an org admin, I want advance notice of subprocessor changes with my own channel preferences, so that I can exercise my DPA objection rights in time.

- [ ] A mutation with default notice sets `effective_at` 30 days after announcement; `noticeDays` accepts 7–90 and rejects out-of-bounds with `400 NOTICE_PERIOD_OUT_OF_BOUNDS`. *Verify: unit tests on the bounds + integration test on the created version.*
- [ ] The fan-out job delivers in-app + email (email stubbed under test-mode) to subscribed org admins, records delivery rows, emits `trust.register.notice_sent` per org, and skips already-delivered rows on retry. *Verify: integration test running the job, interrupting after partial delivery, re-running, asserting no duplicate deliveries.*
- [ ] `GET`/`PUT …/trust/subprocessor-notifications` read and replace the member's toggles, gated by `trust_notifications:manage`, emitting `trust.notifications.updated`. *Verify: contract test for both verbs, the 403 path, and the audit event.*
- [ ] The tenant trust center shows current register + pending changes with effective dates. *Verify: screen walkthrough with a pending change seeded.*

**S3 (P2)** — As a customer security reviewer, I want a compliance document library with versioned public documents, so that I always retrieve the current DPA template and security overview.

- [ ] Operators can create documents, publish versions with effective dates, and the "current version" is the latest effective one. *Verify: integration test publishing two versions (one future-dated) and asserting which downloads.*
- [ ] Public documents list and download on both the public and tenant surfaces; tenant access requires `compliance_documents:read`. *Verify: contract tests on both surfaces incl. the tenant 403 path.*

**S4 (P3)** — As an org admin at an enterprise customer, I want restricted documents (pen-test summary, certification reports) my org has been granted, so that our vendor review gets evidence without it being public.

- [ ] Restricted documents appear in a tenant's library only with a grant; without one, download returns `403 DOCUMENT_ACCESS_NOT_GRANTED` and the public surface returns `404 DOCUMENT_NOT_FOUND`. *Verify: contract tests for granted, ungranted, and public-surface cases.*
- [ ] Restricted downloads emit `trust.document.downloaded` (and `outcome: denied` on refusal); grant create/revoke emit their platform-scope events and duplicate grants return `409 GRANT_ALREADY_EXISTS`. *Verify: integration tests asserting each event row and the 409.*

**S5 (P3)** — As a platform operator, I want an operator admin UI over the register and library, so that trust content is maintainable without hand-crafting API calls.

- [ ] The UI drives the existing operator endpoints (no new write paths) for register changes, documents, versions, and grants. *Verify: screen walkthrough of each flow, cross-checked against the audit events emitted.*

## UX & non-functional notes

- Screens: **public trust page** (register + pending changes + public documents), **tenant trust center** (register, pending changes, document library, notification preferences), **operator admin UI** (P3). All with loading/error/empty states.
- Public page is anonymous, read-only, cacheable; it must render acceptably on mobile (prospects follow links from procurement emails).
- Notification email copy states subprocessor, change type, and effective date — reviewed copy, not raw field dumps.
- Security constraints per the section above; downloads via signed URLs only.

## Out of scope

- An in-product objection/acknowledgement workflow — objections flow through the customer's DPA channel; the product's job is timely notice and evidence.
- Per-region register variants or residency-specific subprocessor lists (program-wide out of scope).
- E-signature/DPA execution flows; watermarking of restricted documents.
- Live trust-center status widgets (uptime, incident feeds) and machine-readable trust APIs for GRC tools (program-wide out of scope).

## Open questions

- No `design/` mockup exists yet for the new screens (public trust page, tenant trust center, operator admin UI); required before initial build. Owner: design.
- Does an emergency subprocessor replacement (e.g. security-driven) need a notice floor below 7 days, and what does the DPA permit then? Owner: product/legal, before S2 ships.
- Operator credential lifecycle (issuance, rotation, revocation) — owned by the stack pack/ops runbook; confirm before S1 ships.
