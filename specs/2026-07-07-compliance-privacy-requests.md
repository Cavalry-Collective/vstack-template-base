# Privacy requests (DSAR) — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: 2026-07-07-enterprise-compliance-controls.md. Status: proposed.

## Goal

Give org admins a per-organisation registry and tooling to fulfil data-subject requests — access, portability, erasure, rectification, restriction/objection — against their CRM contacts, with due-date tracking, machine-readable export packages, hold-aware erasure with in-place anonymisation, a suppression list against resurrection, and completion evidence fit for a regulator.

**Framing:** our customers are the **controllers**; their CRM contacts are the **data subjects** (GDPR arts 15–21; Singapore PDPA access and correction obligations). The product is the processor's tooling for the controller. Requests from **our own users (members) about their own data** are a separate vendor-level path — see *Admin capabilities → Vendor-level path for members*.

## Product requirements

1. Each organisation has a **privacy-request registry**. A request has a type — `access`, `portability`, `erasure`, `rectification`, `restriction` (covering objection) — and is linked to an identified subject.
2. **Subject locate**: creating a request starts from a search across contacts by email, name, or phone that finds **all** matching records, including soft-deleted ones (via the retention spec's explicit `includeDeleted` capability). The matched record set is snapshotted on the request as the working scope.
3. A request tracks **status** (`received → in_progress → completed | rejected`, plus `blocked_by_hold` for erasure), a **due date** (default 30 days from receipt per GDPR/PDPA; org-adjustable **downward only**), an **assignee** (a member), and a **completion evidence note**. Invalid transitions are rejected.
4. **Access/portability** generate an asynchronous, machine-readable **package** (JSON + CSV) of every record referencing the subject. Packages are stored encrypted with an **expiring, audited download link**; storage, TTL, and link mechanics follow the export job conventions in `2026-07-07-compliance-export-bulk-controls.md`.
5. **Erasure** first validates legal holds: if any matched record is under an active hold, the request enters `blocked_by_hold` and no data changes until the hold is released (see `2026-07-07-compliance-retention-deletion.md`). Otherwise an **erasure job** runs: subject-owned records (the contact and records that exist only about the subject) are hard-deleted through the retention spec's purge machinery; records that must persist for business integrity are **anonymised in place**.
6. **Anonymisation rule**: on a record that persists (e.g. a closed deal keeps its amounts, stage history, and ownership), every subject-identifying field is overwritten with an irreversible placeholder — a fixed label plus a random token generated for the request (e.g. name → `Erased subject a1b2c3`), never derived from the original value (no hashes of the original), and the record is stamped `anonymised_at`. Anonymisation is not reversible by anyone, including the vendor.
7. Completed erasure adds the subject's identifiers to a per-org **suppression list**, stored as **salted hashes** (never plaintext). Imports and inbound syncs check the list and **skip matching rows, reporting them** in the import result — an erased subject cannot be silently resurrected.
8. **Rectification** is fulfilled through normal record-edit flows; the registry records the request and its completion evidence — no parallel edit path.
9. **Restriction/objection** sets a processing-restriction flag on the subject's matched records; while set, those records are excluded from exports, bulk actions, and outbound integrations. Applying/clearing the flag is audited.
10. Completing any request emits **evidence** — who fulfilled it, what was done, when, and record counts — persisted on the request and mirrored in the audit trail, suitable for a regulator response.
11. Running erasure requires `privacy_requests:execute` and is **maker-checker eligible** (see `2026-07-07-compliance-maker-checker.md`) where org policy demands approval.
12. Everything is org-scoped and permission-gated per the program index; denied attempts are audited.

## User flows

**Flow 1 — Register and triage a request**
1. An admin receives a subject request out-of-band (email, form) and opens *Privacy requests → New*.
2. They run subject locate by email/name/phone; matches (incl. soft-deleted) are listed per record class; they confirm the subject.
3. They pick the type; the request is created `received` with due date = receipt + 30 days (shortenable), snapshotted scope, and optional assignee.

**Flow 2 — Fulfil an access/portability request**
1. The assignee moves the request to `in_progress` and starts package generation; a job builds JSON + CSV of every record referencing the subject.
2. When the package is ready, the assignee requests a download link; the link expires and each issue/download is audited.
3. The assignee delivers the package to the subject through their own channel, records the evidence note, and completes the request.

**Flow 3 — Fulfil an erasure request**
1. The executor (with `privacy_requests:execute`, via maker-checker approval where required) starts erasure.
2. The job validates legal holds; a hold moves the request to `blocked_by_hold` with the blocking hold(s) named — nothing is changed.
3. Once clear, the job hard-deletes subject-owned records, anonymises persisting records in place, and adds the subject's identifiers to the suppression list.
4. The request completes with evidence counts (deleted per class, anonymised per class, suppression entries added).

**Flow 4 — Import hits the suppression list**
1. A member imports a CSV (or a sync pushes records); each row's identifiers are hashed and checked against the suppression list.
2. Matching rows are skipped; the import result reports "N rows skipped: suppressed subject", and the match is audited.

**Flow 5 — Restriction/objection**
1. An admin creates a `restriction` request and applies the flag to the subject's matched records.
2. Flagged records are excluded from exports, bulk actions, and outbound integrations until an admin clears the flag (also via the registry, audited).

## Admin capabilities

- **View the registry** (`privacy_requests:read`): list/filter requests by type, status, assignee, due date; overdue requests surfaced; per-request detail with scope, history, and evidence.
- **Manage requests** (`privacy_requests:manage`): subject locate, create requests, assign, shorten due dates, record evidence, complete/reject, generate packages and download links, apply/clear restriction flags, view suppression entries (hashes and source request only — plaintext identifiers are never displayable).
- **Execute erasure** (`privacy_requests:execute`): start erasure jobs; remove a suppression entry (rare, e.g. a subject re-consents) — both audited, erasure maker-checker eligible.
- **Vendor-level path for members**: requests by our users about their own member/account data are not handled in this registry — account settings cover self-service access/rectification/deletion, and anything beyond goes through vendor support under the vendor's own privacy policy. Product work here is limited to linking that path from account settings.

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes; long-running work is async (POST → `201` with a `pending` resource, poll it).

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/privacy-requests` | List/filter requests | `privacy_requests:read` | filters `type`, `status`, `assigneeId`, `dueBefore` |
| `POST …/privacy-requests` | Create a request | `privacy_requests:manage` | `type`, `subjectRecordRefs` (from locate), optional `assigneeId`, `dueAt` (≤ default) |
| `GET …/privacy-requests/{requestId}` | Request detail | `privacy_requests:read` | status, scope snapshot, evidence, package refs |
| `PUT …/privacy-requests/{requestId}` | Update status/assignee/due date/evidence | `privacy_requests:manage` | transitions validated; `dueAt` downward only |
| `GET …/privacy-subject-search` | Subject locate (incl. soft-deleted) | `privacy_requests:manage` | `email` / `name` / `phone` (≥1 required); paginated matches per record class |
| `POST …/privacy-requests/{requestId}/packages` | Start package build (access/portability) | `privacy_requests:manage` | → `201` `{ id, status: "pending" }` |
| `GET …/privacy-requests/{requestId}/packages/{packageId}` | Poll package | `privacy_requests:read` | `status`, `recordCounts`, `expiresAt` |
| `POST …/privacy-requests/{requestId}/packages/{packageId}/download-links` | Issue expiring download link | `privacy_requests:manage` | `url`, `expiresAt`; issuance + download audited |
| `POST …/privacy-requests/{requestId}/erasure` | Start erasure job | `privacy_requests:execute` | → `201` job pending; `409 LEGAL_HOLD_ACTIVE` moves request to `blocked_by_hold`; maker-checker eligible |
| `POST …/privacy-requests/{requestId}/restrictions` | Apply restriction flag to scope | `privacy_requests:manage` | affected record counts |
| `DELETE …/privacy-requests/{requestId}/restrictions` | Clear restriction flag | `privacy_requests:manage` | `204` |
| `GET …/suppression-entries` | List suppression entries | `privacy_requests:read` | `identifierType`, hash prefix, `sourceRequestId` |
| `DELETE …/suppression-entries/{entryId}` | Remove an entry | `privacy_requests:execute` | `204`; audited with reason field |

## Data model changes

All migrations reversible and additive (expand → migrate → contract per `db/CLAUDE.md`); all tables carry `organisation_id` (indexed), `created_at`/`updated_at`, UTC timestamps, indexed FKs.

- **`privacy_requests`** — `organisation_id`, `type` (`access`/`portability`/`erasure`/`rectification`/`restriction`), `status` (`received`/`in_progress`/`blocked_by_hold`/`completed`/`rejected`), `subject_display` (the confirmed subject label), `received_at`, `due_at` (checked ≤ received_at + 30 days), `assignee_member_id` (nullable FK), `evidence_note` (nullable text), `completed_at`, `completed_by`.
- **`privacy_request_records`** — the scope snapshot: `privacy_request_id` (FK), `organisation_id`, `record_class`, `record_id`, `disposition` (nullable: `deleted`/`anonymised`/`restricted`, set as the job processes); unique `(privacy_request_id, record_class, record_id)`.
- **`privacy_packages`** — `organisation_id`, `privacy_request_id` (FK), `status` (`pending`/`completed`/`failed`), `storage_ref` (encrypted object location — **sensitive**, never exposed raw; links are minted per download), `record_counts` (per class), `expires_at`, `built_at`.
- **`suppression_entries`** — `organisation_id`, `identifier_type` (`email`/`phone`), `identifier_hash` (**sensitive**: salted hash of the normalised identifier; per-org salt held by the encryption module — plaintext identifiers are never stored), `source_privacy_request_id` (FK), unique `(organisation_id, identifier_type, identifier_hash)`.
- **Existing CRM tables** — additive nullable columns on subject-bearing classes: `anonymised_at` (record was anonymised in place), `processing_restricted_at` + `processing_restriction_request_id` (restriction flag; indexed so export/bulk/integration paths filter cheaply).
- Erasure job progress reuses the retention spec's `purge_runs` checkpoint pattern (`kind` gains value `privacy_erasure`).

## Backend implementation requirements

- New feature module `modules/privacy` (domain: request state machine, anonymisation rules, suppression matching; service: use cases owning `record()`; repo: adapters incl. package storage and hash lookup; controller: endpoints above). It calls the retention module's service-level lifecycle — it never reimplements hard deletion.
- **Ports**: package storage (encrypted object store — supplied by the active stack pack), download-link minting (shared with export-controls), identifier hashing (salt via the encryption module), subject search across live + soft-deleted rows (the retention repo adapter's explicit `includeDeleted` capability — one of its only sanctioned callers).
- **Background jobs** (runner supplied by the active stack pack), all idempotent, batched, resumable:
  - *Package builder* — walks the scope snapshot per class, streams JSON + CSV into encrypted storage, checkpoints per class/batch; a re-run after interruption resumes without duplicating package content.
  - *Erasure job* — re-validates holds at start of every run (not just enqueue), then per batch: hard-delete via the retention purge machinery or anonymise in place per the domain rule, stamp `disposition` on each scope row (the idempotency marker — a resumed run skips stamped rows), finally write suppression entries and complete the request.
  - *Package expiry* — deletes expired packages from storage.
- Suppression check lives in the shared import/sync pipeline as one service-ring step (hash → lookup → skip + report), not per-importer.
- Restriction exclusion is enforced where exports, bulk actions, and outbound integrations already select records — one shared predicate in the repo ring, mirroring the retention spec's single-place soft-delete exclusion.
- Due-date "downward only" and status transitions are domain invariants, unit-tested in isolation.
- Ships behind a default-off validated-config flag per the program's rollout convention.

## Audit log events

Per the program envelope, via the shared `record()` call. Erasure jobs audit per-batch aggregates with counts — never per-row floods (same rule as the retention spec).

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `privacy.subject.searched` | Subject locate executed (it can reveal soft-deleted data) | search field types used (not values), match counts |
| `privacy.request.created` | Request registered | type, subject display, due date, scope counts |
| `privacy.request.updated` | Status/assignee/due-date/evidence change | before/after of changed fields |
| `privacy.request.completed` | Request completed | evidence summary: dispositions, counts, completed_by |
| `privacy.request.rejected` | Request rejected | rejection reason |
| `privacy.package.generated` | Package build completed | record counts per class, `expires_at` |
| `privacy.package.link_issued` | Download link minted | `expires_at`, target = package |
| `privacy.package.downloaded` | Link used | target = package |
| `privacy.erasure.started` | Erasure job began | scope counts |
| `privacy.erasure.blocked` | Hold validation failed → `blocked_by_hold` | blocking hold ids |
| `privacy.erasure.completed` | Erasure finished (aggregate) | deleted/anonymised counts per class, suppression entries added |
| `privacy.erasure.failed` | Erasure run failed after retries | outcome `failure`, run id |
| `privacy.erasure.denied` | Erasure attempted without `privacy_requests:execute` or approval | outcome `denied` |
| `privacy.suppression.matched` | Import/sync row skipped by the list | import ref, match count (aggregate per import) |
| `privacy.suppression.removed` | Suppression entry removed | reason, source request |
| `privacy.restriction.applied` / `privacy.restriction.cleared` | Restriction flag set/cleared | affected record counts |
| `privacy.request.denied` | Any registry endpoint denied | outcome `denied`, missing permission in details |

## Security considerations

- Packages contain full subject PII: stored encrypted at rest (encryption spec), reachable only via short-lived minted links, every issuance and download audited; `storage_ref` never leaves the backend.
- Suppression identifiers are salted hashes with a per-org salt — the list cannot be reversed into a contact database, and cross-org correlation of the same subject is impossible.
- Anonymisation placeholders are random-token based, never derived from the original value, so no offline dictionary attack recovers the subject.
- Subject search spans soft-deleted rows — hence gated by `privacy_requests:manage` (not plain contact read) and audited per search.
- `privacy_requests:execute` is separate from `manage` per the program's destructive-verb rule; erasure is additionally maker-checker eligible.
- Audit envelopes for this area carry identifiers and counts, never subject payloads (program redaction rules).

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing permission on any endpoint | 403 | `PERMISSION_DENIED` |
| Subject locate finds no matching records when confirming a subject | 404 | `SUBJECT_NOT_FOUND` |
| Erasure start/run against a scope with an active hold | 409 | `LEGAL_HOLD_ACTIVE` |
| Status change violating the state machine (e.g. `completed → in_progress`) | 409 | `INVALID_STATUS_TRANSITION` |
| Due date set later than the statutory default | 400 | `DUE_DATE_EXCEEDS_STATUTORY_LIMIT` |
| Package/download link requested for a non-access/portability request | 409 | `REQUEST_TYPE_MISMATCH` |
| Download link used after expiry | 410 | `DOWNLOAD_LINK_EXPIRED` |
| Package build or link mint on an expired package | 409 | `PACKAGE_EXPIRED` |
| Starting erasure while an erasure job for the request is running | 409 | `ERASURE_ALREADY_RUNNING` |
| Erasure without required maker-checker approval | 403 | `APPROVAL_REQUIRED` |
| Request, package, or suppression entry not found | 404 | `RESOURCE_NOT_FOUND` |
| Subject search with no search field supplied / malformed body | 400 | `VALIDATION_FAILED` |

## User stories & acceptance criteria

**S1 (P1)** — As an org admin, I want a per-org registry of privacy requests with subject locate, statuses, due dates, and assignees, so that every DSAR is tracked and answered on time.

- [ ] Subject locate finds all records matching email/name/phone, including soft-deleted ones. *Verify: integration test seeding a live and a soft-deleted contact for one email; `GET …/privacy-subject-search?email=…` returns both; without `privacy_requests:manage` returns `403 PERMISSION_DENIED`.*
- [ ] Creating a request snapshots the scope, defaults the due date to +30 days, and rejects a later date. *Verify: `POST …/privacy-requests` then `GET` the detail; `PUT` with `dueAt` +45 days returns `400 DUE_DATE_EXCEEDS_STATUTORY_LIMIT`, −15 days returns 200.*
- [ ] Status transitions follow `received → in_progress → completed | rejected`; invalid ones are rejected. *Verify: domain unit tests on the state machine plus a contract test returning `409 INVALID_STATUS_TRANSITION`.*
- [ ] Registry actions emit their audit events. *Verify: integration test asserting `privacy.request.created`/`updated`/`completed` rows with the full envelope.*

**S2 (P1)** — As an org admin, I want access/portability requests to produce an encrypted machine-readable package with an expiring, audited download link, so that I can hand the subject their data.

- [ ] Package build is async and covers every record class referencing the subject in JSON + CSV. *Verify: `POST …/packages` returns `201 pending`; poll to `completed`; inspect the artifact for both formats and per-class counts matching the scope.*
- [ ] Downloads happen only via minted expiring links; issuance and use are audited; expiry returns `410`. *Verify: mint a link, download, assert `privacy.package.link_issued` and `privacy.package.downloaded`; after `expiresAt`, the link returns `410 DOWNLOAD_LINK_EXPIRED`.*
- [ ] A build interrupted mid-run resumes without duplicated content. *Verify: integration test killing the builder between class batches, re-running, validating the final package.*

**S3 (P1)** — As a compliance officer, I want erasure to respect legal holds, hard-delete subject-owned records, and anonymise persisting records in place, so that erasure is real but business integrity survives.

- [ ] Erasure against a held scope moves the request to `blocked_by_hold`, changes nothing, and emits `privacy.erasure.blocked`. *Verify: integration test with a hold from the retention spec; `POST …/erasure` returns `409 LEGAL_HOLD_ACTIVE`; data unchanged; after hold release, re-run succeeds.*
- [ ] Subject-owned records are hard-deleted; a closed deal survives with amounts intact and subject fields replaced by irreversible placeholders, stamped `anonymised_at`. *Verify: integration test asserting the contact row is gone, the deal row keeps `amount` and gains `anonymised_at`, and no subject field contains any substring of the original values.*
- [ ] The job is idempotent and resumable via scope-row dispositions. *Verify: kill mid-run, re-run, assert each scope row processed exactly once and completion evidence counts are correct.*
- [ ] Completion emits `privacy.erasure.completed` with per-class counts and requires `privacy_requests:execute` (denied attempt audited). *Verify: contract test allowed + denied; assert the aggregate event and `privacy.erasure.denied`.*

**S4 (P2)** — As a compliance officer, I want erased subjects on a hashed suppression list that imports check, so that a re-import cannot silently resurrect them.

- [ ] Completed erasure writes salted-hash entries; plaintext identifiers appear nowhere. *Verify: integration test asserting `suppression_entries` rows exist and a full-DB scan finds no plaintext of the erased email/phone.*
- [ ] An import containing a suppressed identifier skips the row and reports it. *Verify: run an import fixture containing the erased email; result reports 1 skipped-suppressed row; the contact is not recreated; `privacy.suppression.matched` is emitted.*
- [ ] Removing an entry requires `privacy_requests:execute` and is audited. *Verify: contract test allowed + denied on `DELETE …/suppression-entries/{id}`; assert `privacy.suppression.removed`.*

**S5 (P2)** — As an org admin, I want restriction/objection to flag a subject's records out of exports, bulk actions, and outbound integrations, so that processing genuinely pauses.

- [ ] Applying restriction stamps the scope's records and is audited. *Verify: `POST …/restrictions`; assert `processing_restricted_at` set and `privacy.restriction.applied` emitted.*
- [ ] Flagged records are absent from exports, bulk-action selections, and outbound integration payloads while set, and return after clearing. *Verify: integration tests exercising one export, one bulk action, and one outbound sync against a flagged record, before and after `DELETE …/restrictions`.*

**S6 (P2)** — As an org admin, I want rectification requests recorded with completion evidence, so that ordinary edits done for a subject are provable.

- [ ] A `rectification` request is created, linked to the subject, and completed with an evidence note referencing the edits made through normal flows. *Verify: create → edit the contact via the standard endpoint → complete with evidence; assert the registry detail and `privacy.request.completed` carry the evidence.*

## UX & non-functional notes

- Screens: **Privacy requests** (registry list with overdue highlighting), **New request / subject locate** (search + match confirmation), **Request detail** (status, scope, package, evidence, erasure/restriction actions), **Suppression list** (read-only table + audited remove). All need loading/error/empty states; lists paginate.
- Package build and erasure are async — the UI polls request/package status and never blocks; erasure actions carry typed confirmation and, where org policy requires, the maker-checker approval banner.
- Subject search must answer interactively (indexed lookups on normalised email/phone); suppression check adds one hash lookup per import row and must not dominate import throughput.
- No subject PII in URLs, logs, or audit payloads; download links are the only egress path for packages.

## Out of scope

- A subject-facing self-service portal (requests arrive out-of-band; the controller operates the tooling).
- Consent management, cookie banners, and lawful-basis tracking.
- Vendor-level DSARs from our own members beyond the account-settings link noted above.
- Identity verification of the subject — the controller verifies identity before registering the request.
- Deletion mechanics themselves (grace, purge, holds, blast radius) — owned by `2026-07-07-compliance-retention-deletion.md`.

## Open questions

- No `design/` mockup exists yet for the new screens (Privacy requests registry, New request / subject locate, Request detail, Suppression list); required before initial build. Owner: design.
- Should PDPA's 30-day access window with extension notices be modelled (a documented extension field) or is downward-only due-date adjustment enough for launch? Owner: product/legal, before S1 GA.
- Do outbound integrations need a push-back signal (delete/redact webhook) when a subject is erased, or is stopping future syncs sufficient for GA? Owner: product, before S4.
