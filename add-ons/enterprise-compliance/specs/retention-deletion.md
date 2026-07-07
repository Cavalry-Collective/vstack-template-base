# Data retention & deletion — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make deletion a governed lifecycle — soft delete → grace period → irreversible hard delete with a stated blast radius — plus per-record-class retention policies, legal holds that override every deletion path, and org offboarding with crypto-shredding, so customers can meet GDPR/PDPA erasure and retention obligations with evidence. **This spec owns the deletion lifecycle; every other area spec references it rather than redefining it.**

## Product requirements

1. Deleting a CRM record (contact, company, deal, activity, note) is a **soft delete**: `deleted_at` and the deleting actor are recorded; the record disappears from all default queries, list endpoints, and search results immediately.
2. Soft-deleted records appear in an admin **recycle bin**, restorable during a grace period. The grace period is org policy: default **30 days**, bounds **7–90 days**, validated on write, changes audited.
3. Restore returns the record to full visibility with its prior data intact. Restore after grace expiry, or of a record already claimed by a purge batch, fails with a clear error — it never partially restores.
4. A background **purge job** irreversibly hard-deletes records whose grace period has expired, in idempotent, resumable batches (per `db/CLAUDE.md` backfill rules). A purged record is unrecoverable from the primary store.
5. Hard deletion covers the full **blast radius**: primary rows are deleted by the purge job; search-index entries are removed in the same run; caches and generated export files containing the record expire via their own bounded TTLs; backups age out per the backup retention window (see `backup-dr.md`). **Documented customer commitment: erasure completes in the primary within grace + 24h, and in backups within the backup retention window — both stated in customer-facing documentation.**
6. Per-record-class **retention policies** (contacts, companies, deals, activities, notes) auto-delete records not updated for N days. Off by default; N validated against declared bounds; enabling requires a fresh preview (req 7). Audit-event retention is **not** governed here — it belongs to `audit-logs.md`.
7. Before a retention policy can be enabled, admins must run a **preview** stating "this policy would currently delete ~N records". Enabling without a recent preview is rejected. Retention sweeps perform **soft** deletes (actor `system`), so swept records still pass through the recycle bin and grace period.
8. Retention policy changes are audited and **maker-checker eligible** (see `maker-checker.md`) where org policy demands approval.
9. **Legal holds**: named holds with a reason, attachable to explicit record sets or whole record classes. A held record is excluded from soft-delete purge, retention sweeps, **and** privacy-erasure jobs — erasure requests against held records are blocked with a distinct status (see `privacy-requests.md`). Hold create/release requires `retention:hold` and is audited.
10. **Org offboarding**: on account closure the organisation's data is frozen (read-only) for a contractual window (default **60 days**, documented to customers), then fully purged — including destruction of the org's encryption keys as crypto-shredding (see `encryption.md`).
11. Everything in this spec is org-scoped and permission-gated per the program index; denied attempts are audited.

## User flows

**Flow 1 — Soft-delete and restore**
1. A member deletes a contact from the app; the record gains `deleted_at`/`deleted_by` and vanishes from lists and search.
2. An admin opens the recycle bin, filters by record class, and finds the contact with deletion date, actor, and days remaining.
3. The admin restores it; the contact reappears in default queries; the restore is audited.

**Flow 2 — Configure the grace period**
1. An admin opens retention settings and changes the grace period (e.g. 30 → 14 days).
2. The value is validated against bounds 7–90; out-of-bounds is rejected with `RETENTION_BOUNDS_EXCEEDED`.
3. The change is audited and applies to deletions from that point on (already-deleted records keep the grace window in force at deletion time).

**Flow 3 — Enable a retention policy**
1. An admin sets a policy for a record class (e.g. activities older than 730 days) — created disabled.
2. The admin runs a preview; a job computes "~N records would be deleted today".
3. The admin enables the policy (routed through maker-checker if org policy requires); enabling without a fresh preview is rejected.
4. The nightly retention sweep soft-deletes matching records as actor `system`; they enter the recycle bin.

**Flow 4 — Create and release a legal hold**
1. A permitted admin creates a hold with a name and reason, scoped to selected records or a whole class.
2. Purge and retention sweeps skip held records; privacy-erasure jobs targeting them block.
3. When the matter closes, the admin releases the hold; held records rejoin normal lifecycle on the next sweep. Both actions are audited.

**Flow 5 — Purge sweep (system)**
1. The scheduled purge job selects recycle-bin entries whose grace expired and are not under hold, claims them in batches, hard-deletes primary rows and search-index entries, and records per-batch counts.
2. An interrupted run resumes from its checkpoint without re-deleting or skipping records.

**Flow 6 — Org offboarding**
1. The org owner closes the account through base account settings (the trigger is outside this spec's API).
2. The org is frozen: all writes rejected, reads allowed, integrations paused.
3. After the contractual window (default 60 days) the offboarding purge deletes all org data across the blast radius and requests destruction of the org's encryption keys; completion is recorded as evidence.

## Admin capabilities

- **View retention settings and policies** (`retention:read`): grace period, per-class policies with status and last preview, legal-hold list, purge-run history with counts.
- **Change grace period and retention policies** (`retention:update`): edit bounds-validated values, run previews, enable/disable policies (maker-checker eligible).
- **Manage legal holds** (`retention:hold`): create holds with reason and scope, release them, see what each hold protects.
- **Use the recycle bin** (`records:restore`): list soft-deleted records with deletion metadata and time remaining; restore.
- **Purge early** (`records:purge`): request immediate purge of a recycle-bin entry before grace expiry (processed by the next sweep) — separate from restore per the program's destructive-verb rule.

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes; long-running work is async (POST → `201` with a `pending` resource, poll it).

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/retention-settings` | Read grace period | `retention:read` | `gracePeriodDays` |
| `PUT …/retention-settings` | Update grace period | `retention:update` | `gracePeriodDays` (7–90) |
| `GET …/retention-policies` | List per-class policies | `retention:read` | `recordClass`, `maxAgeDays`, `enabled`, `lastPreview` |
| `PUT …/retention-policies/{recordClass}` | Create/update a policy | `retention:update` | `maxAgeDays`, `enabled`; enabling checks fresh preview; maker-checker eligible |
| `POST …/retention-policies/{recordClass}/previews` | Start a preview job | `retention:update` | → `201` `{ id, status: "pending" }` |
| `GET …/retention-policies/{recordClass}/previews/{previewId}` | Poll preview | `retention:read` | `status`, `estimatedRecordCount`, `generatedAt` |
| `GET …/recycle-bin` | List soft-deleted records | `records:restore` | filters `recordClass`, `deletedBy`; each entry: record summary, `deletedAt`, `purgeAt`, `status` |
| `POST …/recycle-bin/{recordClass}/{recordId}/restore` | Restore a record | `records:restore` | `200` restored record ref; `409` if claimed/held-state conflicts |
| `POST …/recycle-bin/{recordClass}/{recordId}/purge` | Request early purge | `records:purge` | → `201`, entry status `purge_pending`; poll the bin entry |
| `GET …/legal-holds` | List holds | `retention:read` | `name`, `reason`, `status`, scope summary |
| `POST …/legal-holds` | Create a hold | `retention:hold` | `name`, `reason`, `scope`: `{ recordClass, recordIds? }` (omit `recordIds` = whole class) |
| `GET …/legal-holds/{holdId}` | Hold detail | `retention:read` | scope entries, created/released metadata |
| `POST …/legal-holds/{holdId}/release` | Release a hold | `retention:hold` | `200`; `409` if already released |
| `GET …/purge-runs` | Purge/sweep run history | `retention:read` | `kind` (`purge`/`retention_sweep`/`offboarding`), per-class counts, `status` |

## Data model changes

All migrations reversible; destructive steps follow expand → migrate → contract per `db/CLAUDE.md`. All new tables carry `created_at`/`updated_at`, UTC timestamps, indexed FKs, and `organisation_id` (indexed).

- **Existing CRM tables** (`contacts`, `companies`, `deals`, `activities`, `notes`) — additive columns:
  - `deleted_at` — nullable timestamp; null = live. Indexed (partial index on non-null where the engine supports it).
  - `deleted_by_actor_type` / `deleted_by_actor_id` — nullable; `user`, `api_key`, or `system`.
- **`retention_settings`** — one row per org: `organisation_id` (unique), `grace_period_days` (default 30, checked 7–90).
- **`retention_policies`** — `organisation_id`, `record_class`, `max_age_days`, `enabled` (default false), `enabled_by`, `enabled_at`; unique `(organisation_id, record_class)`.
- **`retention_previews`** — `organisation_id`, `record_class`, `status` (`pending`/`completed`/`failed`), `estimated_record_count`, `generated_at`.
- **`legal_holds`** — `organisation_id`, `name`, `reason`, `status` (`active`/`released`), `created_by`, `released_by`, `released_at`.
- **`legal_hold_scopes`** — `legal_hold_id` (FK), `organisation_id`, `record_class`, `record_id` (nullable; null = whole class); unique `(legal_hold_id, record_class, record_id)`.
- **`purge_runs`** — `organisation_id`, `kind` (`purge`/`retention_sweep`/`offboarding`), `record_class`, `status` (`running`/`completed`/`failed`), `checkpoint` (last processed id — makes runs resumable), `records_processed`, `started_at`, `finished_at`.
- **`organisation_closures`** — `organisation_id` (unique), `status` (`frozen`/`purging`/`purged`), `frozen_at`, `purge_after`, `purged_at`, `keys_destroyed_at`.
- Recycle-bin entries are the soft-deleted rows themselves (no shadow table); early-purge requests set a `purge_requested_at` additive column on the CRM tables.

No column here is sensitive beyond ordinary CRM PII already governed by base redaction rules.

## Backend implementation requirements

- New feature module `modules/retention` (domain: lifecycle rules, hold invariants, bounds; service: use cases owning `record()` calls; repo: adapters; controller: the endpoints above).
- **Default-query exclusion in one place**: the repo ring's shared base repository/query adapter appends `deleted_at IS NULL` to every read for soft-deletable classes. Callers opt in to deleted rows only via an explicit `includeDeleted` capability exposed solely to the recycle-bin, legal-hold, and privacy-request use cases — never per-query, never in controllers.
- Search indexing is behind a port; soft delete and purge both call its remove-by-id contract in the same use case as the row change. Cache and export-artifact expiry rely on TTLs declared ≤ 24h (caches) and the export-controls TTL (artifacts) — the purge job does not chase them individually.
- **Background jobs** (runner supplied by the active stack pack), all idempotent, batched, resumable via `purge_runs.checkpoint`:
  - *Purge sweep* — hard-deletes grace-expired, non-held rows; deleting an already-deleted id is a no-op (idempotent).
  - *Retention sweep* — soft-deletes policy-matching, non-held rows as actor `system`.
  - *Offboarding purge* — freezes, waits out the window, purges all classes, then calls the encryption module's key-destruction port.
- **Concurrency — restore vs purge**: the purge batch claims bin entries with a conditional update (`status: deleted → purge_in_progress`); restore is a conditional update requiring `status = deleted`. A restore losing the race gets `409 PURGE_IN_PROGRESS`; a claimed entry is never restored half-purged. Assume multiple workers per the base *Integrations → Concurrency* rule.
- Hold checks happen inside the sweep's selection query (join against `legal_hold_scopes`), not per-row in application code, and again as a domain invariant before any hard delete.
- Frozen orgs: a shared controller-ring guard rejects writes for organisations in `frozen`/`purging` status with `403 ORGANISATION_FROZEN`.
- Ships behind a default-off validated-config flag per the program's rollout convention.

## Audit log events

Per the program envelope; emitted via the shared `record()` call in the owning use case. **Purge and sweep jobs audit one aggregate event per batch with counts — never a per-row flood.**

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `records.record.deleted` | Soft delete (user, api_key, or system via sweep) | target = record; actor type distinguishes sweep |
| `records.record.restored` | Successful restore from recycle bin | target = record |
| `records.record.purge_requested` | Early purge requested | target = record |
| `records.record.purged` | Per purge batch (aggregate) | `after`: `{ record_class, count, run_id }` |
| `records.record.restore_denied` | Restore blocked (permission, grace expired, purge in progress) | outcome `denied`/`failure`, reason code in context |
| `retention.settings.updated` | Grace period changed | before/after `grace_period_days` |
| `retention.policy.updated` | Policy created/edited/enabled/disabled | before/after policy values |
| `retention.policy.previewed` | Preview completed | `after`: `estimated_record_count` |
| `retention.policy.update_denied` | Policy change without permission or without fresh preview | outcome `denied` |
| `retention.sweep.completed` | Per retention-sweep run (aggregate) | per-class soft-delete counts, `run_id` |
| `retention.sweep.failed` | Sweep run failed after retries | outcome `failure`, `run_id` |
| `retention.hold.created` | Legal hold created | `after`: name, reason, scope summary |
| `retention.hold.released` | Legal hold released | target = hold |
| `retention.hold.denied` | Hold create/release without `retention:hold` | outcome `denied` |
| `organisation.closure.frozen` | Offboarding freeze applied | `after`: `purge_after` |
| `organisation.closure.purged` | Offboarding purge completed (aggregate) | per-class counts, `keys_destroyed_at` |

Every endpoint denial additionally satisfies the program's cross-cutting criterion 1 (denied attempts audited).

## Security considerations

- `records:purge` and `retention:hold` are separate from read/update per the program's destructive-verb rule; no role bundles them by default.
- Recycle-bin listings expose record summaries only (name/identifier), not full payloads; audit envelopes carry identifiers, not record bodies (program redaction rules).
- Hard deletion is only ever performed by the background jobs — no synchronous endpoint issues a hard `DELETE`, so grace and holds cannot be bypassed at the edge.
- Key destruction on offboarding renders backup copies of field-encrypted data unreadable (crypto-shredding), shrinking the backup exposure window; mechanics per the encryption spec.
- Cross-org access is impossible by construction: every query is org-scoped; contract tests assert cross-org reads return nothing (program criterion 3).

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing permission on any endpoint | 403 | `PERMISSION_DENIED` |
| Grace period or `max_age_days` outside declared bounds | 400 | `RETENTION_BOUNDS_EXCEEDED` |
| Enabling a policy without a fresh preview | 409 | `RETENTION_PREVIEW_REQUIRED` |
| Restore attempted after grace expiry | 409 | `GRACE_PERIOD_EXPIRED` |
| Restore while a purge batch has claimed the record | 409 | `PURGE_IN_PROGRESS` |
| Purge/erasure/sweep action against a held record | 409 | `LEGAL_HOLD_ACTIVE` |
| Recycle-bin entry or record not found (or not soft-deleted) | 404 | `RECORD_NOT_FOUND` |
| Legal hold not found | 404 | `HOLD_NOT_FOUND` |
| Releasing an already-released hold | 409 | `HOLD_ALREADY_RELEASED` |
| Write to a frozen/purging organisation | 403 | `ORGANISATION_FROZEN` |
| Malformed request body | 400 | `VALIDATION_FAILED` |

## User stories & acceptance criteria

**S1 (P1)** — As an org admin, I want deleted records to land in a recycle bin and be restorable during a grace period, so that mistakes are recoverable and deletion is governed.

- [ ] Deleting a contact sets `deleted_at`/`deleted_by` and removes it from list endpoints and search. *Verify: integration test — `DELETE` the contact, then `GET …/contacts` and the search endpoint return it absent; direct repo read shows `deleted_at` set.*
- [ ] The recycle bin lists the record with deletion metadata and time remaining. *Verify: `GET …/recycle-bin?recordClass=contacts` as a member with `records:restore` returns the entry; without the permission returns `403 PERMISSION_DENIED`.*
- [ ] Restore returns the record to default queries and emits `records.record.restored`. *Verify: `POST …/recycle-bin/contacts/{id}/restore`, then `GET …/contacts/{id}` returns 200 and the audit store holds the event.*
- [ ] Soft-deleted rows are excluded by the shared repo adapter, not per-query. *Verify: repo-ring test asserting a default query on each soft-deletable class omits a seeded deleted row without any per-call filter.*

**S2 (P1)** — As a compliance officer, I want expired records irreversibly purged by a background job across the full blast radius, so that "deleted" means erased.

- [ ] The purge sweep hard-deletes grace-expired rows and their search-index entries in batches, resuming from its checkpoint after interruption. *Verify: integration test seeding expired entries, killing the run mid-batch, re-running, and asserting exactly-once deletion and index removal.*
- [ ] Each batch emits one aggregate `records.record.purged` event with counts. *Verify: assert one event per batch, none per row, in the same test.*
- [ ] Restore racing a claiming batch fails cleanly. *Verify: test forcing `purge_in_progress`, then `POST …/restore` returns `409 PURGE_IN_PROGRESS` and the row state is unchanged.*
- [ ] Restore after grace expiry returns `409 GRACE_PERIOD_EXPIRED`. *Verify: contract test with an expired seeded entry.*

**S3 (P1)** — As an org admin, I want to configure the grace period within safe bounds, so that our recovery window matches policy.

- [ ] Grace period defaults to 30 and accepts only 7–90. *Verify: unit tests on the policy schema; `PUT …/retention-settings` with 5 and 120 returns `400 RETENTION_BOUNDS_EXCEEDED`, with 14 returns 200.*
- [ ] Changes emit `retention.settings.updated` with before/after. *Verify: integration test asserting the audit row.*

**S4 (P1)** — As an org admin, I want per-record-class retention policies with a mandatory preview, so that old data expires automatically and never by surprise.

- [ ] A policy can be set per class, off by default, bounds-validated. *Verify: `PUT …/retention-policies/activities` creates disabled; out-of-bounds `maxAgeDays` returns `400 RETENTION_BOUNDS_EXCEEDED`.*
- [ ] Enabling without a fresh preview is rejected. *Verify: enable with no preview → `409 RETENTION_PREVIEW_REQUIRED`; run `POST …/previews`, poll to `completed`, enable → 200.*
- [ ] The retention sweep soft-deletes matching records as actor `system` and emits an aggregate `retention.sweep.completed`. *Verify: integration test seeding stale activities, running the sweep, asserting recycle-bin entries with actor `system` and the aggregate event.*

**S5 (P2)** — As a compliance officer, I want legal holds that override purge, retention, and erasure, so that litigation data is preserved.

- [ ] Creating/releasing a hold requires `retention:hold` and is audited. *Verify: contract tests for allowed + denied on `POST …/legal-holds` and `…/release`; assert `retention.hold.created`/`released`/`denied` events.*
- [ ] Held records are skipped by purge and retention sweeps. *Verify: integration test — seed an expired held record, run both sweeps, record survives; release the hold, re-run, record is processed.*
- [ ] An erasure job targeting a held record blocks with `LEGAL_HOLD_ACTIVE` (behaviour co-owned with the privacy spec). *Verify: the privacy spec's erasure test with a hold in place.*

**S6 (P2)** — As the vendor, I want closed organisations frozen and then fully purged with key destruction, so that offboarding meets contractual erasure commitments.

- [ ] A frozen org rejects writes with `403 ORGANISATION_FROZEN` and still serves reads. *Verify: contract test on a representative write and read endpoint for a frozen org.*
- [ ] After `purge_after`, the offboarding purge deletes all org data, calls key destruction, and emits `organisation.closure.purged` with counts. *Verify: integration test on a throwaway DB asserting empty org-scoped tables, the key-destruction port invoked, and the audit event.*

## UX & non-functional notes

- Screens: **Retention settings** (grace period, per-class policies with preview results), **Recycle bin** (filterable list, restore/purge actions), **Legal holds** (list, create, release). Each needs loading/error/empty states; recycle bin and preview counts paginate.
- Preview and purge run asynchronously — the UI polls and never blocks on a sweep.
- Sweeps are batched and off-peak-schedulable so they never lock hot CRM tables; index and query plans for `deleted_at` filters verified before GA.
- All destructive actions require typed confirmation in the UI; nothing here weakens the base security baseline.

## Out of scope

- Audit-event retention and export (audit-logs spec) and backup schedules/restore drills (backup-dr spec).
- Privacy-request orchestration, anonymisation, and the suppression list (privacy-requests spec) — this spec only supplies the lifecycle they invoke.
- Per-field retention (whole records only) and customer-configurable backup windows.
- Region-pinned residency (program-wide out of scope).

## Open questions

- No `design/` mockup exists yet for the new screens (Retention settings, Recycle bin, Legal holds); required before initial build. Owner: design.
- Is the 60-day offboarding window uniform or per-plan/contract? Owner: product/legal, before S6 build.
- Does "inactive" for retention need per-class definitions (e.g. contacts by last activity rather than last update)? Owner: product, before S4 GA.
