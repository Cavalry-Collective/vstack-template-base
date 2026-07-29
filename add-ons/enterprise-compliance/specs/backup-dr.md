# Backup & disaster recovery — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make recovery a drilled, evidenced control. The primary datastore and object storage are backed up automatically and encrypted, with declared RTO/RPO targets held as validated deployment config. Scheduled restore drills produce durable evidence records, and a maintained DR runbook covers the failure scenarios. Concrete backup/restore mechanics are delegated to `infra/` and the active stack pack, per the add-on SOP ("recovery is drilled, not declared").

## Scope & ownership

- **Owns:** backup posture and verification (`backup_runs`), restore drills and their evidence (`recovery_drills`), the DR runbook requirement, production-restore recording, and the config values `RECOVERY_RPO_MINUTES`, `RECOVERY_RTO_MINUTES`, `BACKUP_RETENTION_DAYS`.
- **Consumes:** backup encryption keys per `encryption.md`; execution mechanics from `infra/` runbooks and the stack pack's tooling.
- **Used by:** `retention-deletion.md` — its erasure-in-backups promise is bounded by `BACKUP_RETENTION_DAYS` (requirement 4 here owns the value); `trust-transparency.md` — the trust page documents the declared RPO/RTO and consumes the backup-status summary (S4).
- **Phases:** P1 = backups, drills, runbook (S1–S3). P2 = evidence surface for the trust page (S4). P3 = tenant-scoped recovery (S5). Flows here are **platform-operator** flows, not org-member flows.

## User stories & acceptance criteria

**S1 (P1)** — As a platform operator, I want automated encrypted backups of the datastore and object storage with a declared retention window, so that data survives loss and erasure promises are bounded.

- [ ] Datastore backups run automatically via PITR or ≤-RPO-interval snapshots per the stack pack, encrypted at rest. *Verify: infra review of the backup resources + a `backup_runs` row with `status=succeeded` appearing after a scheduled run.*
- [ ] `BACKUP_RETENTION_DAYS` (default 35), `RECOVERY_RPO_MINUTES` (60), `RECOVERY_RTO_MINUTES` (240) validate at startup; out-of-bounds values fail boot with a named error. *Verify: unit tests on the config schema including rejection cases; boot with a bad value and observe the named failure.*
- [ ] A failed or missed backup raises an alert and a `dr.backup.failed` audit event. *Verify: integration test — feed the verification job a failed-run fixture through the port fake; assert alert hook and audit row.*
- [ ] Backups are readable only by the recovery credential. *Verify: infra IAM review + attempted backup-plane read with the runtime credential is denied.*

**S2 (P1)** — As a platform operator, I want quarterly restore drills recorded as durable evidence, so that auditors see recovery is rehearsed, not declared.

- [ ] A drill restoring the latest backup to an isolated environment passes row-count, checksum, and app-boot checks, and is recorded via the API. *Verify: run the drill procedure per the runbook; `POST /internal/v1/platform/recovery-drills` returns 201; `GET` lists the record.*
- [ ] The drill record captures duration vs RTO and loss window vs RPO, and `dr.drill.recorded` is emitted. *Verify: integration test asserting the evidence row fields and the audit event after the use case runs.*
- [ ] Recording without `recovery_drills:record` returns 403 `PERMISSION_DENIED` and emits a denied event. *Verify: contract test, allowed + denied.*

**S3 (P1)** — As a platform operator, I want a DR runbook under `infra/` covering datastore loss, region loss, and corruption, so that recovery under pressure follows a tested script.

- [ ] Runbook exists under `infra/` with the three scenarios; the corruption scenario specifies point-in-time restore + selective repair. *Verify: doc review as part of the drill — the quarterly drill executes the runbook's datastore-loss steps verbatim and files findings.*
- [ ] A production restore is recorded and emits `dr.restore.executed`. *Verify: integration test on the `recordRestore` use case asserting the audit event and record fields; drill rehearsal exercises the recording call.*

**S4 (P2)** — As a platform operator, I want a backup-status and drill-history evidence surface, so that the trust page can show customers recovery posture without manual reporting.

- [ ] `GET /internal/v1/platform/backup-status` returns last-success age vs RPO, declared targets, retention, last drill summary. *Verify: contract test with seeded runs/drills asserting the summary shape.*
- [ ] The trust-transparency spec's page consumes this summary (its spec owns rendering). *Verify: integration test on the consuming service call once that spec builds.*

**S5 (P3)** — As a platform operator, I want tenant-scoped recovery of one organisation's destroyed data, so that a customer's catastrophic mistake is recoverable without a global rollback.

- [ ] One org's rows are restored from backup into the live system via side-instance extract; other tenants unaffected. *Verify: drill-style rehearsal in staging — destroy a seeded org's data, execute the procedure, assert restored rows and untouched sibling org.*
- [ ] The restore emits `dr.restore.executed` with `target.type=organisation` visible in that org's audit trail. *Verify: integration test asserting the org-scoped audit event.*

## Requirements

1. The primary datastore is backed up automatically and encrypted at rest. Where the stack pack's engine supports point-in-time recovery (PITR), continuous archiving is enabled so any moment inside the retention window is restorable; otherwise scheduled snapshots run at an interval no larger than the declared RPO. Both paths are valid; the active stack pack states which applies.
2. Object storage (exports, DSAR packages, attachments) is backed up or versioned+replicated to the same retention window, per the stack pack's mechanics.
3. Recovery objectives are declared as validated deployment config (root *Configuration*): `RECOVERY_RPO_MINUTES` (default **60**) and `RECOVERY_RTO_MINUTES` (default **240**). Startup fails on missing/malformed values. The declared values are what the trust page documents to customers (trust-transparency spec `trust-transparency.md`).
4. Backup retention is a validated config value `BACKUP_RETENTION_DAYS` (default **35**, bounds 7–365). This window bounds the erasure-in-backups promise: erased data disappears from all backups once the window elapses. The retention-deletion spec (`retention-deletion.md`) depends on this value and must state it verbatim.
5. Backups are readable only by a dedicated recovery role/credential. Application runtime credentials can neither read nor delete backups. Backup encryption keys are managed per the encryption spec (`encryption.md`); key mechanics belong to the stack pack's KMS.
6. Every backup run's outcome (success/failure, size, reference) is recorded as a `backup_runs` evidence row by a verification job; a failed or missed run raises an operational alert (observability seam: `infra/CLAUDE.md`, *Set up observability from day 1*).
7. A restore drill runs at least quarterly: restore a backup into an isolated environment, verify integrity (row counts vs source, checksums, application boots and serves authenticated requests), and record the outcome as a durable `recovery_drills` evidence record.
8. A DR runbook lives under `infra/` covering at minimum: datastore loss, region loss, and bad deploy / data corruption. The corruption scenario requires point-in-time restore plus selective repair (restore to a side instance, extract, repair forward) — never blind full rollback of a live multi-tenant datastore.
9. Any restore into production is a major audited event (`dr.restore.executed`) with a durable record: which backup, why, who, data-loss window.
10. Tenant-scoped recovery (restoring one organisation's accidentally destroyed data from backup into the live system) is P3.
11. Evidence API surfaces ship behind the program's default-off rollout flag (`COMPLIANCE_BACKUP_DR_ENABLED`).

## User flows

### F1 — Quarterly restore drill (P1)

1. Scheduler (or operator, off-cycle) selects the most recent successful `backup_runs` entry for the primary datastore.
2. Operator restores it into an isolated drill environment per the runbook (no production network access, no outbound delivery — mail/webhook sinks disabled).
3. Operator verifies integrity: row counts for key tables vs the source's recorded counts, checksum comparison where the engine supports it, application boots against the restored datastore and serves an authenticated read.
4. Operator records the outcome via `POST /internal/v1/platform/recovery-drills` — backup reference, duration vs RTO target, data-loss window vs RPO target, outcome, notes.
5. System emits `dr.drill.recorded`; the drill environment is torn down.

### F2 — Production restore, DR event (P1)

1. Operator declares the incident and selects the runbook scenario (datastore loss / region loss / corruption).
2. Operator identifies the restore point (PITR timestamp or snapshot id) and confirms the implied data-loss window against the declared RPO.
3. Restore is executed with the recovery credential per the runbook; for the corruption scenario, restore lands in a side instance and repair is applied selectively.
4. Operator records the restore via `POST /internal/v1/platform/restores` (async resource); system emits `dr.restore.executed` with the full context.
5. Post-incident: duration vs RTO and loss window vs RPO are captured on the restore record; findings feed the runbook.

### F3 — Tenant-scoped restore (P3)

1. Org admin request arrives (data destroyed beyond the recycle-bin window).
2. Operator restores the relevant backup to a side instance, extracts only the target organisation's rows, and re-inserts them into the live system through an import path that respects current schema and constraints.
3. Restore recorded as above with `target.type = organisation`; the affected org's audit trail also receives the event.

## API & permissions

All endpoints authenticated as platform operator; base error envelope; base pagination envelope. Operator endpoints sit under `/internal/v1/platform/…`, use the same session mechanics as the app, and are guarded by instance-scoped operator permissions named `resource:action` per the program index — never by org membership.

- **Org admins have no direct backup controls** — backup posture is instance-global. They see the documented RPO/RTO, retention window, and last-drill summary on the trust page (owned by the trust-transparency spec).
- **Platform operators:** `backups:read` — list backup runs and drill history; `recovery_drills:record` — record drill outcomes; `backups:restore` — record/initiate production restores.

| Method | Path | Permission | Behaviour |
|---|---|---|---|
| GET | `/internal/v1/platform/backup-runs` | `backups:read` | Paginated list of `backup_runs`, newest first; filter by `scope`, `status`. |
| GET | `/internal/v1/platform/backup-status` | `backups:read` | Summary: last successful run per scope, age vs RPO, retention window, declared RPO/RTO, last drill outcome/date. Feeds the trust page via the trust-transparency spec's service (that spec owns the public rendering). |
| GET | `/internal/v1/platform/recovery-drills` | `backups:read` | Paginated drill history. |
| POST | `/internal/v1/platform/recovery-drills` | `recovery_drills:record` | Record a completed drill. `201` with the evidence record. Validates backup reference exists and outcome fields are complete. |
| POST | `/internal/v1/platform/restores` | `backups:restore` | Record/initiate a production restore. Async per program convention: `201` with resource in status `pending`; operator updates/polls the resource as the runbook executes. Only one restore may be `pending`/`in_progress` at a time. |
| GET | `/internal/v1/platform/restores/{restoreId}` | `backups:restore` | Poll restore record status. |

No endpoint ever returns backup *contents* — evidence metadata only.

## Data model

Both tables are **instance-global** (no `organisation_id`), justified per the index rule: backups and drills cover the whole datastore, not one tenant. The P3 tenant-restore record carries the target org in its audit event, not as table scoping. Migrations are reversible up/down per `db/CLAUDE.md`.

`backup_runs` — one row per verified backup run:

| Column | Notes |
|---|---|
| `id` | PK |
| `scope` | `datastore` \| `object_storage` |
| `kind` | `pitr_checkpoint` \| `snapshot` \| `incremental` — which path the stack pack uses |
| `backup_ref` | opaque reference in the backup tooling; unique — the verification job's idempotency key |
| `started_at`, `completed_at` | UTC |
| `size_bytes` | integer |
| `status` | `succeeded` \| `failed` |
| `failure_reason` | nullable text |
| `verified_at` | when the verification job confirmed the run |
| `created_at`, `updated_at` | standard |

`recovery_drills` — one row per drill, the SOC 2 evidence record:

| Column | Notes |
|---|---|
| `id` | PK |
| `backup_run_id` | FK → `backup_runs`, indexed |
| `performed_at` | UTC |
| `duration_seconds` | restore-to-serving time |
| `rto_target_seconds`, `rpo_target_seconds` | targets in force at drill time (config may change later) |
| `data_loss_window_seconds` | measured backup-age at restore point |
| `row_counts_ok`, `checksums_ok`, `app_boot_ok` | booleans — the three integrity checks |
| `outcome` | `passed` \| `passed_with_findings` \| `failed` |
| `operator` | actor id/display of the recording operator |
| `notes` | nullable text |
| `created_at`, `updated_at` | standard |

## Audit events

Standard envelope; instance-global events carry `organisation_id = null` (tenant restore carries the target org). Denied attempts on every endpoint emit the matching `…denied` event per program criterion 1.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `dr.backup.completed` | Verification job confirms a successful run | actor `system`; target `backup_run`; `after`: scope, kind, size |
| `dr.backup.failed` | Verification job records a failed/missed run | outcome `failure`; `after`: failure_reason |
| `dr.drill.recorded` | Drill outcome recorded | target `recovery_drill`; `after`: outcome, duration vs targets |
| `dr.restore.executed` | Production restore recorded/completed | target `datastore` or `organisation`; `after`: backup_ref, restore point, loss window, scenario |
| `dr.restore.failed` | A recorded restore ends in failure | outcome `failure`; `after`: failure_reason |
| `dr.restore.denied` | `backups:restore` missing on a restore attempt | outcome `denied`; missing permission in context |

## Implementation notes

- New `recovery` module with the standard rings. Domain: `RecoveryDrill` and `BackupRun` entities with invariants (a drill passes only if all three integrity checks pass and `duration_seconds ≤ rto_target_seconds`; `data_loss_window_seconds ≤ rpo_target_seconds` or the outcome is at best `passed_with_findings`). Domain defines a `BackupStatusPort` (list/verify recent runs in the backup tooling).
- Repo ring: `BackupStatusPort` adapter bound by the active stack pack; evidence-table repositories with mappers.
- Service ring: `recordDrill`, `recordRestore`, `verifyBackupRuns` use cases; each emits its audit event through the shared `record()` in the same transaction.
- **Verification job** (system actor, scheduled): queries the backup tooling via the port, upserts `backup_runs` idempotently keyed on `backup_ref` (safe under retries and overlapping runs), alerts on failure or on no successful run within the RPO window. It must tolerate backup-tooling latency/outage without marking runs failed on transient errors (bounded retries per the backend *Integrations* rules).
- Restore concurrency: a partial-unique constraint (or equivalent) enforces at most one non-terminal restore; a second `POST` returns `409 RESTORE_ALREADY_IN_PROGRESS`.
- Restore/backup *execution* is not application code — it is `infra/` runbook + stack-pack tooling. The backend records evidence and emits audit events only.
- Backup read/delete is restricted to the recovery credential in `infra/` IAM (reviewed via the infra risk checklist); backups are encrypted with keys the application runtime never holds (encryption spec).
- Drill environments are isolated: no production network path, outbound delivery disabled, torn down after the drill. Restored data in a drill is production data and is handled as such.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Operator lacks the required permission | 403 | `PERMISSION_DENIED` |
| Drill or restore record id unknown | 404 | `DRILL_NOT_FOUND` / `RESTORE_NOT_FOUND` |
| `backup_run_id` / backup reference unknown | 400 | `BACKUP_RUN_NOT_FOUND` |
| Referenced backup outside retention window or unverified | 409 | `BACKUP_NOT_RESTORABLE` |
| A restore is already pending/in progress | 409 | `RESTORE_ALREADY_IN_PROGRESS` |
| Drill payload incomplete/out of bounds | 400 | `VALIDATION_FAILED` (base) |

## Notes & decisions

- **The drill record is the control (req. 7):** it is the auditable evidence SOC 2 asks for; a backup with no passing drill in the last quarter is a red control.
- **Tenant-scoped recovery deferred to P3 (req. 10):** soft-delete + recycle bin (retention-deletion spec) is the product-level answer for most accidental-deletion cases.
- **Retention is deployment config, not org policy:** an org can never shorten the instance's backup retention.
- **This spec adds no end-user screens.** Evidence is API-level; the customer-facing rendering (trust page) belongs to the trust-transparency spec.
- Performance: evidence endpoints are low-traffic operator reads — no special perf work; standard pagination.

## Out of scope

- Multi-region active-active / automatic failover topology (runbook covers region loss as a manual procedure).
- Customer-downloadable backups or org-initiated backup scheduling.
- Backups of subprocessor-held data (covered by the subprocessor register, trust-transparency spec).
- Recycle-bin/soft-delete UX — owned by the retention-deletion spec.

## Open questions

- Do any customer contracts demand tighter than RPO 1h / RTO 4h? If so, targets become per-plan documentation (config already supports tightening). Owner: product/legal, before trust-page GA.
- Is the 35-day backup retention floor contractual or uniform? (Shared with the program index's open question.) Owner: product/legal, before retention GA.
- How much of the drill is automated vs operator-run at first? Proposal: manual with recorded evidence for the first two quarters, then automate the restore+checks. Owner: eng, before the second drill.
