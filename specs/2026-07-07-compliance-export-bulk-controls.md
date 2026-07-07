# Export & bulk-action controls — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: 2026-07-07-enterprise-compliance-controls.md. Status: proposed.

## Goal

Gate every data exfiltration and mass mutation behind its own permission, org policy, and audit trail — exports run as bounded async jobs with provenance and expiring encrypted artifacts, and bulk actions require a server-computed preview/confirm step — so that a compromised or careless account cannot silently drain or destroy an organisation's CRM data. This spec **owns the async export-job mechanics**; the audit-logs and DSAR specs reuse them for their own artifacts.

## Product requirements

1. Export is a separate permission per resource — `contacts:export`, `companies:export`, `deals:export`, `activities:export`, `notes:export` (per the RBAC catalog). Holding `read`/`update` never implies `export`.
2. Every export is an asynchronous job: `POST …/exports` returns `201` with the job in status `pending`; clients poll the job resource. No endpoint streams an unbounded dataset synchronously.
3. Supported formats: CSV and JSON. The artifact is stored **encrypted at rest in object storage** per `2026-07-07-compliance-encryption.md`, and is referenced by storage key — file bytes never live in the DB.
4. Every artifact embeds a provenance manifest — a leading manifest row (CSV) or `manifest` object (JSON) carrying: exporting actor (type, id, display), organisation id, UTC timestamp, human-readable filter summary, and record count.
5. Download happens only via a short-lived signed link (default expiry 24 h, org-configurable 1–72 h). Every link issuance and every download is audited.
6. Export artifacts expire and are purged by a background job after a bounded TTL — default **7 days**, bounds 1–30 (the retention-deletion spec's blast-radius table relies on this bound). A purged export's job row remains as history in status `expired`.
7. A failed job carries a `failure_reason`; a partial artifact is never downloadable.
8. Org policy can additionally restrict export: to named roles (`export_allowed_role_ids`), by a per-export record cap (default 100,000; platform ceiling 1,000,000), and by a per-actor daily quota (default 25 jobs/UTC day). Violations are rejected at job creation and audited as denied.
9. Bulk update and bulk delete are separate permissions per resource: `contacts:bulk_update` / `contacts:bulk_delete`, and likewise for `companies` and `deals`. Both verbs are registered in the RBAC permission catalog (`2026-07-07-compliance-rbac.md`).
10. Bulk actions are bounded: a server-enforced maximum matched-record count per intent (platform ceiling 10,000, validated; org policy may lower it). Requests matching more records are rejected, not truncated.
11. Bulk actions require a mandatory server-computed **preview/confirm** step: the client creates a `bulk_action_intent` returning the exact matched count and a sample; execution happens only by confirming that intent id. **Chosen approach: the intent pins the matched record ids at preview time** (bounded by req. 10, so the pin is small); execution operates only on pinned ids, skipping records that were meanwhile deleted or moved out of scope and reporting the skipped count. (Rejected alternative: re-count at confirm within a tolerance — pinning eliminates filter drift entirely instead of bounding it.)
12. Bulk delete is always **soft delete** — `deleted_at`/`deleted_by`, restorable via the recycle bin; lifecycle owned by `2026-07-07-compliance-retention-deletion.md`. No bulk hard-delete path exists.
13. Per-actor bulk rate limit: default 20 intents/hour, org-configurable; store supplied by the active stack pack.
14. Thresholds → approval: org policy may enable the maker-checker entries `export.large` and `bulk.delete.large` with record-count thresholds (`2026-07-07-compliance-maker-checker.md` owns the policy rows). Above threshold, the job/intent is captured as an approval request — `202`, status `pending_approval` — and executes only when approved.
15. API-key actors (`2026-07-07-compliance-admin-security.md` scoped keys) pass the same permission, policy, cap, quota, and rate checks; quotas and rate limits count per actor, member or key.
16. Every creation, completion, failure, download, purge, execution, and **denial** is audited per the program envelope.

## User flows

**F1 — Export contacts (P1).** 1. A member with `contacts:export` opens the Contacts list, applies filters, chooses "Export" → format (CSV/JSON). 2. Backend checks permission, org policy (roles/cap/quota), counts matches, creates the job (`201 pending`), audits `export.contacts.requested`. 3. The export builder job streams matching records to an encrypted artifact with the provenance manifest, then marks the job `completed`. 4. The member polls (or revisits Export history), sees `completed` with record count.

**F2 — Download an export (P1).** 1. From Export history, the member requests a download link for a `completed` job. 2. Backend issues a signed URL (default 24 h), audits `export.contacts.link_issued`. 3. The browser fetches the file endpoint with the signature; backend validates it, audits `export.contacts.downloaded`, and serves the artifact. 4. After the artifact TTL, the purge job deletes the object and the file endpoint returns `410`.

**F3 — Export blocked by policy (P2).** 1. A member holding the permission but outside `export_allowed_role_ids`, or exceeding cap/quota, POSTs an export. 2. Backend rejects (`403`/`400`/`429` per Error cases), audits `export.contacts.denied` with the violated rule. 3. UI explains the policy and who to contact.

**F4 — Bulk delete with preview/confirm (P2).** 1. A member with `contacts:bulk_delete` selects a filter, chooses "Delete matching". 2. Backend creates an intent: exact matched count, sample of up to 10 records, pinned ids, expiry. 3. UI shows the count and sample; the member confirms the intent id. 4. Backend re-checks the permission, transitions the intent `previewed → executing` (conditional), soft-deletes the pinned records in batches, records `bulk.contacts.deleted` with counts. 5. UI links to the recycle bin for undo.

**F5 — Large action routed to approval (P2).** 1. An export or bulk delete exceeds the org's `export.large` / `bulk.delete.large` threshold. 2. On creation (export) or confirm (bulk), the backend captures an approval request instead of executing — `202`, status `pending_approval`. 3. On approval, the job/intent proceeds as F1/F4 with the approving actor named in the audit context; on rejection/expiry it terminates without executing.

## Admin capabilities

- Configure export/bulk policy keys (allowed roles, record cap, daily quota, link expiry, artifact TTL, batch max, bulk rate limit) via the org policy resource — `org_policy:update`; read them — `org_policy:read`.
- View the org-wide export history (all actors' jobs, statuses, counts — never file contents) — `exports:read`. Any member always sees their **own** jobs without it.
- Configure the `export.large` / `bulk.delete.large` approval thresholds — `org_policy:update`, via the maker-checker policy resource.
- Grant/revoke the export and bulk permissions themselves — RBAC (`roles:assign` etc.).

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `POST …/exports` | Create export job | `<resource>:export` for the requested `resourceType` | req: `{ resourceType, format (csv\|json), filters }`; `201` `{ id, resourceType, format, status: "pending", matchedCount, artifactExpiresAt }`; `202` with `status: "pending_approval"` + `approvalRequestId` when threshold-guarded |
| `GET …/exports` | Export history | `exports:read` for org-wide; every member sees own jobs | filters `status`, `resourceType`, `requestedBy`; base pagination envelope |
| `GET …/exports/{exportId}` | Poll a job | creator or `exports:read` | adds `recordCount`, `failureReason`, `purgedAt` |
| `POST …/exports/{exportId}/download-link` | Issue signed link | creator or `exports:read` | `201` `{ url, expiresAt }`; only for `completed` jobs; audited |
| `GET …/exports/{exportId}/file?signature=…` | Fetch artifact via signed link | valid, unexpired signature (no session — the link is the bearer) | serves the artifact; audits the download; `410` once purged |
| `POST …/bulk-action-intents` | Preview a bulk action | `<resource>:bulk_update` / `<resource>:bulk_delete` per `action` | req: `{ resourceType, action (update\|delete), filters, changes? }` (`changes` required for `update`); `201` `{ id, matchedCount, sample[≤10], expiresAt, status: "previewed" }` |
| `GET …/bulk-action-intents/{intentId}` | Poll an intent | creator | `resultSummary { affected, skipped }`, `failureReason`, `approvalRequestId` |
| `POST …/bulk-action-intents/{intentId}/confirm` | Execute the pinned intent | same permission, re-checked | `202` with `status: "executing"` (poll the intent) or `"pending_approval"` when guarded; replay → `409 INTENT_ALREADY_DECIDED` |
| `PUT …/policies` | Set the policy keys below | `org_policy:update` | existing org-policy resource (admin-security spec); this spec adds keys only |

Long-running work is async per the index: creation returns `201 pending`, clients poll; confirm returns `202` and clients poll the intent. Bulk `sample` is derived from the pinned ids at read time, redacted to display fields.

## Data model changes

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs and frequent filter columns indexed; artifacts referenced by storage key, never stored in the DB):

- **`export_jobs`** — `id` (PK); `organisation_id` (FK, indexed); `requested_by_actor_type` (`user` | `api_key`), `requested_by_actor_id` (indexed together with org + `created_at` for quota counting); `resource_type` (validated against the exportable set); `format` (`csv` | `json`); `filters` (validated document — the submitted filter DTO, schema-checked on write); `status` (`pending` | `pending_approval` | `running` | `completed` | `failed` | `expired`); `matched_count` (counted at creation); `record_count` (rows actually written, set on completion); `storage_key` (nullable — object-storage reference); `failure_reason` (nullable); `approval_request_id` (nullable FK → maker-checker); `claimed_at`, `attempt_count` (worker-claim fields for the exactly-once transition); `artifact_expires_at` (indexed for the purge sweep); `purged_at` (nullable); `created_at`; `updated_at`.
- **`bulk_action_intents`** — `id` (PK); `organisation_id` (FK, indexed); `initiated_by_actor_type`, `initiated_by_actor_id`; `resource_type`; `action` (`update` | `delete`); `filters` (validated document); `changes` (nullable validated document — update only, checked against the resource's editable fields); `matched_count`; `pinned_record_ids` (validated document — id array, bounded by the batch max; the pin that prevents filter drift); `status` (`previewed` | `pending_approval` | `executing` | `completed` | `failed` | `rejected` | `cancelled` | `expired`); `result_summary` (nullable document — affected/skipped counts); `failure_reason` (nullable); `approval_request_id` (nullable FK); `expires_at` (default 1 h after creation for unconfirmed previews; once `pending_approval`, the approval request's expiry governs); `created_at`; `updated_at`.

Org-policy keys added to the existing policy document (validated bounds, safe defaults, audited on change per the index): `export_allowed_role_ids` (nullable — null = any role holding the permission), `export_record_cap` (default 100,000; 1–1,000,000), `export_daily_quota_per_actor` (default 25; 1–1,000), `export_link_expiry_hours` (default 24; 1–72), `export_artifact_ttl_days` (default 7; 1–30), `bulk_max_batch_size` (default 10,000; 1–10,000), `bulk_intents_per_hour_per_actor` (default 20; 1–500). Approval thresholds live in the maker-checker spec's `approval_policies`, not duplicated here. Soft-delete columns on CRM tables are owned by the retention-deletion spec.

## Backend implementation requirements

- Two modules: `exports` and `bulk_actions`, each with the four rings (domain: job/intent entities and transition rules; service: use cases owning transactions and `record()` calls; repo: adapters; controller: routes + guards).
- **Ports** (defined inward, implemented by the active stack pack's adapters): `ObjectStoragePort` (put encrypted object, issue signed URL, delete), `JobRunnerPort` (enqueue/claim background work), the rate-limit store. Permission checks go through the RBAC module's shared `PermissionChecker` port; threshold/approval routing goes through the maker-checker module's `ApprovalGate` port — never a local re-implementation.
- **Background jobs**, all idempotent and resumable:
  - *Export builder* — claims a `pending` job via a conditional `pending → running` transition (exactly-once claim; two workers cannot both win), streams records in batches to a deterministic storage key, writes the manifest, then conditionally transitions `running → completed`. A crashed build is re-claimed after a claim timeout and overwrites the same key — no duplicate artifacts.
  - *Artifact purge sweep* — finds `completed` jobs past `artifact_expires_at`, deletes the object, sets `purged_at`, transitions to `expired`, audits. Batched; re-running is a no-op.
  - *Bulk executor* — processes a confirmed intent's pinned ids in batches inside per-batch transactions, recording progress in `result_summary` so an interrupted run resumes without re-applying (soft delete and full-field update are naturally idempotent per record).
  - *Intent expiry sweep* — conditionally transitions stale `previewed` intents to `expired`.
- **Concurrency:** every status change is a conditional transition (`UPDATE … WHERE status = …`); the loser of a confirm race gets `409 INTENT_ALREADY_DECIDED`. Quota checks count committed job rows atomically with creation in the use-case transaction.
- Cap/quota/role policy is evaluated in the creation use case (rule-level authorisation), after the controller-edge permission guard; all counts use bound query parameters.
- CSV/JSON serialisation uses established libraries (root *Don't reinvent*), including CSV formula-injection escaping.

## Audit log events

Emitted via the shared `record()` in the service ring. `<resource>` instantiates per resource type (`contacts`, `companies`, …); counts and filter summaries are recorded — **never the exported payload or record contents**.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `export.<resource>.requested` | Export job created | `context`: format, filter summary, matched count |
| `export.<resource>.completed` | Builder finished the artifact | record count, artifact expiry |
| `export.<resource>.failed` | Builder failed permanently | `outcome: failure`; failure-reason class |
| `export.<resource>.denied` | Creation blocked (permission, role policy, cap, quota) | `outcome: denied`; violated rule / missing permission |
| `export.<resource>.link_issued` | Signed download link issued | link expiry |
| `export.<resource>.downloaded` | Artifact fetched via the file endpoint | actor from the issuing context |
| `export.<resource>.purged` | Purge sweep deleted the artifact | actor `system`; record count |
| `bulk.<resource>.previewed` | Intent created | action, matched count, filter summary |
| `bulk.<resource>.updated` | Bulk update executed | affected + skipped counts, changed-field names (not values) |
| `bulk.<resource>.deleted` | Bulk soft-delete executed | affected + skipped counts, filter summary |
| `bulk.<resource>.denied` | Preview/confirm blocked (permission, batch limit, rate limit) | `outcome: denied`; violated rule |
| `bulk.intent.expired` | Expiry sweep expired an unconfirmed intent | actor `system` |

When an action executed via approval, its event's `context` carries `approval_request_id` and the approving actor (maker-checker spec).

## Security considerations

- Server-side gating is authoritative; hiding export/bulk controls in the UI is rendering only.
- Artifacts are encrypted at rest (encryption spec) and reachable only through the signed-link flow; the signature covers export id + expiry and is issued only to an authenticated, authorised caller. The link is a bearer within its window — hence the short default and per-issue/per-download auditing; orgs can shorten `export_link_expiry_hours`.
- The bounded artifact TTL keeps exported PII's lifetime finite — erasure and retention blast-radius calculations (retention-deletion spec) depend on it.
- All queries org-scoped by `organisation_id`; a job/intent id from another org is `404`, never a leak. Ownership is verified on every client-supplied id.
- API-key actors get no bypass: same guards, policy, quotas, rate limits, and audit identity.
- Bulk delete is soft-only, so a permission mistake is recoverable through the recycle bin during the grace period.
- Manifest and audit envelopes carry identifiers, counts, and filter summaries — never governed-field plaintext or the payload itself.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing the endpoint's permission | 403 | `PERMISSION_DENIED` (missing permission in `error.details`) |
| Actor's role not in `export_allowed_role_ids` | 403 | `EXPORT_ROLE_RESTRICTED` |
| Matched count exceeds the org's record cap | 400 | `EXPORT_CAP_EXCEEDED` |
| Actor's daily export quota reached | 429 | `EXPORT_QUOTA_EXCEEDED` |
| Download link requested before job `completed` | 409 | `EXPORT_NOT_READY` |
| Artifact past TTL / purged | 410 | `EXPORT_FILE_EXPIRED` (410 is a documented per-endpoint addition to the standard set) |
| Invalid or expired download signature | 403 | `SIGNED_LINK_INVALID` |
| Bulk filter matches more than the batch max | 400 | `BULK_LIMIT_EXCEEDED` |
| Confirming an expired intent | 409 | `INTENT_EXPIRED` |
| Confirming an already-confirmed/terminal intent | 409 | `INTENT_ALREADY_DECIDED` |
| Actor's bulk rate limit reached | 429 | `BULK_RATE_LIMITED` |
| Unknown/unsupported `resourceType` or format | 400 | `UNSUPPORTED_RESOURCE_TYPE` |
| Job / intent id not found (or other org's) | 404 | `EXPORT_NOT_FOUND` / `INTENT_NOT_FOUND` |
| Threshold-guarded action captured instead of executing | 202 | `APPROVAL_REQUIRED` — **not an error envelope**: the `202` body is the job/intent resource with `status: "pending_approval"` and `approvalRequestId`; the constant names the contract clients branch on |

## User stories & acceptance criteria

**S1 (P1)** — As an org admin, I want export gated by its own permission, so that members and API keys that can read or edit data cannot exfiltrate it.

- [ ] A member with `contacts:read`+`contacts:update` but not `contacts:export` cannot create an export. *Verify: contract test — `POST …/exports` `{ resourceType: "contacts" }` returns `403 PERMISSION_DENIED` naming `contacts:export` in `error.details`, and an `export.contacts.denied` audit row exists.*
- [ ] The same member's read/update endpoints are unaffected. *Verify: `GET`/`PUT` a contact returns `200` for that member in the same test.*
- [ ] An API key without the export scope is equally blocked. *Verify: contract test with a scoped key (admin-security spec fixture) — `403 PERMISSION_DENIED` + denied audit row with actor type `api_key`.*
- [ ] Export controls are hidden without the permission. *Verify: screen check — Contacts list as Member shows no Export action; as Manager it does.*

**S2 (P1)** — As a permitted member, I want exports to run as async jobs producing provenance-stamped, encrypted, expiring artifacts, so that what left the system is bounded, attributable, and short-lived.

- [ ] Creating an export returns `201 pending` and polling reaches `completed` with a record count. *Verify: integration test — `POST …/exports`, run the builder, `GET …/exports/{id}` shows `status: "completed"` and `recordCount` equal to the seeded matches.*
- [ ] CSV and JSON artifacts embed the provenance manifest. *Verify: integration test building one job per format, fetching the artifact, asserting manifest actor, organisation id, UTC timestamp, filter summary, and record count.*
- [ ] The artifact is stored encrypted in object storage and referenced by storage key only. *Verify: repo test asserting the put goes through the encrypting storage adapter (encryption spec's test helper) and `export_jobs` holds a `storage_key`, no file bytes.*
- [ ] Download works only via a fresh signed link; issue and download are both audited; a tampered signature fails. *Verify: `POST …/download-link` then `GET …/file?signature=…` returns the file and `export.contacts.link_issued` + `export.contacts.downloaded` audit rows exist; a modified signature returns `403 SIGNED_LINK_INVALID`.*
- [ ] Artifacts are purged after the TTL and downloads then fail. *Verify: integration test with the clock advanced past 7 days — purge sweep runs, job becomes `expired` with `purgedAt` set, file endpoint returns `410 EXPORT_FILE_EXPIRED`, `export.contacts.purged` audit row exists.*
- [ ] A failed build surfaces its reason. *Verify: integration test forcing a builder failure — job reaches `failed` with `failureReason`, `export.contacts.failed` audit row exists, download-link returns `409 EXPORT_NOT_READY`.*

**S3 (P2)** — As an org admin, I want export policy knobs — allowed roles, record cap, daily quota — so that even permitted exports stay inside my compliance posture.

- [ ] Role restriction applies on top of the permission. *Verify: set `export_allowed_role_ids` to Admin only; a Manager holding `contacts:export` gets `403 EXPORT_ROLE_RESTRICTED` + denied audit; an Admin succeeds.*
- [ ] The record cap rejects oversized exports at creation. *Verify: set cap 100, seed 101 matches — `POST …/exports` returns `400 EXPORT_CAP_EXCEEDED` and a denied audit row.*
- [ ] The daily quota rejects the quota+1th job per actor per UTC day. *Verify: integration test creating quota jobs then one more — `429 EXPORT_QUOTA_EXCEEDED`; a different actor still succeeds.*
- [ ] All policy keys validate against their bounds. *Verify: unit tests on the policy schema — out-of-bounds values (e.g. `export_link_expiry_hours: 100`) rejected with `400` and field details.*

**S4 (P2)** — As a member with bulk permissions, I want bounded bulk edit/delete with a server-computed preview and confirm, so that mass changes are deliberate, capped, and reversible.

- [ ] `bulk_update` and `bulk_delete` are distinct permissions from `update`/`delete`. *Verify: contract test — a member with `contacts:update` only gets `403 PERMISSION_DENIED` on `POST …/bulk-action-intents` with `action: "update"`.*
- [ ] Preview returns the exact matched count and sample; execution touches only the pinned set. *Verify: integration test — create an intent (count N), then insert a record matching the filter, confirm; exactly N records change and the extra record is untouched; deleting a pinned record before confirm yields `skipped: 1` in `resultSummary`.*
- [ ] Filters matching more than the batch max are rejected. *Verify: set `bulk_max_batch_size` 50, seed 51 matches — preview returns `400 BULK_LIMIT_EXCEEDED` + `bulk.contacts.denied` audit.*
- [ ] Bulk delete is soft: records get `deleted_at`/`deleted_by` and are restorable. *Verify: integration test — confirm a delete intent, assert soft-delete columns set and rows absent from the list endpoint, then restore via the recycle bin (retention-deletion spec flow) and see them return.*
- [ ] Stale intents cannot execute. *Verify: advance the clock past the intent expiry, confirm → `409 INTENT_EXPIRED`; the expiry sweep marks it `expired` with a `bulk.intent.expired` audit row.*
- [ ] The per-actor rate limit applies. *Verify: create limit+1 intents within an hour — `429 BULK_RATE_LIMITED` + denied audit.*

**S5 (P2)** — As an org admin, I want large exports and large bulk deletes to require maker-checker approval, so that a single account cannot execute a mass exfiltration or destruction alone.

- [ ] An export above the `export.large` threshold is captured, not executed. *Verify: enable the policy at threshold 100, request an export matching 101 — `202` with `status: "pending_approval"` and `approvalRequestId`; no builder run; on approval (maker-checker fixture) the job completes and its `export.contacts.completed` context names the approving actor.*
- [ ] A bulk delete above the `bulk.delete.large` threshold behaves the same at confirm. *Verify: integration test mirroring the above on `…/confirm`; rejection leaves every record untouched and the intent `rejected`.*
- [ ] Below-threshold actions are unaffected. *Verify: same policy on, a 99-record export returns `201 pending` and completes without an approval request.*

## UX & non-functional notes

- Screens: Export dialog (format + filter summary + policy hints) on list views; Export history (per-member and org-wide admin view) with status, counts, download, expiry countdown; Bulk-action toolbar + confirm dialog (matched count, sample, "this will soft-delete N records" + recycle-bin pointer). All need loading/error/empty states; confirm dialog needs an explicit typed/press-and-hold confirmation for deletes.
- Preview count is one indexed COUNT at intent/job creation; the builder and bulk executor stream in batches — no request-path full scans.
- Polling: history/detail reads are cheap indexed lookups; frontend polls with backoff while `pending`/`running`/`executing`.
- Security: no exported payload in logs or audit; artifact links never rendered into URLs that get logged by proxies beyond the signed endpoint itself.

## Out of scope

- Imports, scheduled/recurring exports, and export-completion webhooks.
- The content and permissions of audit-log exports (`2026-07-07-compliance-audit-logs.md`) and DSAR packages (`2026-07-07-compliance-privacy-requests.md`) — they reuse this spec's job, storage, signed-link, and TTL mechanics only.
- Field-level export redaction/column selection beyond the resource's readable fields.
- Bulk actions on non-CRM resources (members, roles, policies).
- The recycle-bin UI and hard-delete lifecycle (retention-deletion spec).

## Open questions

- No `design/` mockup exists yet for the new screens (Export dialog, Export history, Bulk-action confirm dialog); required before initial build.
- Should export quota and record cap be plan-tiered rather than uniform defaults? Owner: product, before S3 lands.
- Do `activities`/`notes` need bulk actions too, or only export? Default is export-only (YAGNI) unless a customer commitment says otherwise. Owner: product.
