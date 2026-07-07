# Audit logs — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: 2026-07-07-enterprise-compliance-controls.md. Status: proposed.

## Goal

Provide the program's spine: one append-only, per-organisation audit store implementing the index's event envelope, written through a single shared `record()` call by every other area, queryable and exportable by org admins, with org-configurable retention — so customers have durable, reviewable evidence of who did what.

## Product requirements

1. An append-only `audit_events` store implements the index envelope exactly (field names snake_case, one row per event). Application code has **no UPDATE or DELETE path**: the repo-ring adapter exposes only append and query operations.
2. All events are emitted through one shared `record()` call in the service ring, invoked by the use case that owns the change. **Consistency: `record()` participates in the caller's transaction** — if the business transaction commits, the event is recorded; if it rolls back, no event exists. Tradeoff: the audit store must live in the same transactional database as the business data for v1 (external/streamed sinks are async consumers layered later, see S6).
3. Coverage classes (each area spec enumerates its exact actions): authentication events, authorisation denials, member/role changes, org-policy changes, CRM data lifecycle events for governed actions (soft-delete, restore, hard-delete, merges), exports, privacy requests (DSAR), and approvals.
4. Denied and failed attempts are recorded, not only successes. **Convention (binding on all area specs):** a denied attempt is recorded under the *attempted* action with `outcome: denied`; a failed one with `outcome: failure`. This is what the index's "…denied audit event" refers to — the action name itself does not fork.
5. An admin audit viewer lists events filtered by actor, action prefix, target, outcome, and date range, with a detail drawer showing the full envelope including the before/after diff. Gated by `audit_logs:read`.
6. Reading audit logs is itself audited **at the search level, not per row**: one `audit.events.viewed` event per executed query or detail read — never one event per returned row.
7. A filtered range can be exported asynchronously to CSV or JSON, gated by `audit_logs:export`; the export itself is audited (`audit.events.exported`). Job mechanics (job resource, status polling, object-storage delivery, size/rate bounds) follow `2026-07-07-compliance-export-bulk-controls.md`; this spec defines only the audit-specific parameters.
8. Audit-event retention is org-configurable and **governed by this spec** (the retention-deletion spec governs CRM data, not audit events): default **400 days**, compliance floor **90 days**, maximum **2,555 days (7 years)**. A background purge job is the only deletion path; it hard-deletes events older than the org's horizon in batches.
9. The events listing uses **cursor pagination** (documented per-endpoint decision per the backend contract): an offset `COUNT` per request is impractical at audit volume.
10. `organisation_id` is nullable **only** for platform-scope events (operator actions defined in `2026-07-07-compliance-trust-transparency.md`); platform-scope events never appear in tenant queries.

## User flows

**Review audit activity**
1. An admin with `audit_logs:read` opens the audit log viewer.
2. They filter by actor, action prefix (e.g. `rbac.`), target, outcome, and/or date range; results stream in newest-first with cursor paging.
3. They open a row; the detail drawer shows the full envelope, including the redacted before/after diff and correlation id.
4. Each executed query and detail read is recorded as `audit.events.viewed`.

**Export audit events**
1. An admin with `audit_logs:export` applies filters, then requests an export choosing CSV or JSON.
2. The API returns `201` with a job in status `pending`; the admin polls (or the UI polls) until `completed`, then downloads via a short-lived signed URL.
3. `audit.events.exported` is recorded on completion (or with `outcome: failure` if the job fails).

**Configure audit retention**
1. An admin with `org_policy:update` opens the org security settings and sets the audit retention window.
2. The value is validated against the declared bounds (90–2,555 days); `audit.retention.updated` is recorded with before/after.
3. The nightly purge job applies the new horizon on its next run.

## Admin capabilities

- **View and filter audit events** (list + detail drawer with diff) — `audit_logs:read`.
- **Export a filtered range to CSV/JSON** (async job) — `audit_logs:export` (separate from read, per the index's exfiltration rule).
- **Set the org's audit retention window** — `org_policy:update` (the setting is an org-policy key; see API behavior).

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base error envelope throughout.

| Method | Path | Permission | Purpose / notable fields |
|---|---|---|---|
| GET | `…/audit-events` | `audit_logs:read` | List events. Filters: `actorType`, `actorId`, `actionPrefix`, `targetType`, `targetId`, `outcome`, `occurredFrom`, `occurredTo` (UTC ISO-8601). **Cursor pagination**: base envelope minus `page`/`totalRecords`, plus `nextCursor` (`null` when exhausted); `recordsPerPage` capped at 100. Sorted `occurred_at` desc only. |
| GET | `…/audit-events/{eventId}` | `audit_logs:read` | One event, full envelope including `before`/`after` and `context`. |
| POST | `…/audit-events/exports` | `audit_logs:export` | Start an async export. Body: `format` (`csv` \| `json`) + the same filters as the list. Returns `201` with the job in status `pending`. Job resource shape per the export-controls spec. |
| GET | `…/audit-events/exports/{exportId}` | `audit_logs:export` | Poll the job: `status` (`pending` \| `running` \| `completed` \| `failed`), `downloadUrl` (short-lived, only when `completed`), row count. |

The retention setting is a key (`audit_retention_days`) on the shared org-policy resource (`…/policies`, endpoints owned by `2026-07-07-compliance-admin-security.md`), permission `org_policy:update`; this spec owns its bounds and default.

## Data model changes

New table `audit_events` (reversible migration per `db/CLAUDE.md` — up creates, down drops; the table starts empty so the down path loses nothing at introduction time):

| Column | Notes |
|---|---|
| `id` | PK, opaque unique id (generation per stack pack). |
| `organisation_id` | FK, indexed. **Nullable only for platform-scope operator events** (requirement 10) — the stated exception to the index's org-scoping rule. |
| `occurred_at` | UTC timestamp, when the action happened. |
| `actor_type` / `actor_id` / `actor_display` | `user` \| `api_key` \| `system`; id + human-readable display, denormalised so events outlive the actor. |
| `action` | Dot-separated `area.object.verb`, past tense. Indexed (composite, below). |
| `target_type` / `target_id` / `target_display` | Nullable; denormalised display. |
| `outcome` | `success` \| `failure` \| `denied`. |
| `before` / `after` | Nullable JSON, redacted diffs only where the emitting area's spec says so. |
| `context` | JSON: `correlation_id`, `ip`, `user_agent`, `session_id`, `request_path`. |
| `created_at` / `updated_at` | Per db convention; rows are insert-only so `updated_at` never changes after insert. |

**Indexes (volume note):** `(organisation_id, occurred_at desc, id)` for the default listing and keyset cursor; `(organisation_id, action, occurred_at desc)` for action-prefix filters; `(organisation_id, actor_type, actor_id, occurred_at desc)` for actor filters. No further indexes until a real query needs one.

No other new tables: export jobs reuse the shared export-job table from the export-controls spec; the retention setting rides the org-policy store.

## Backend implementation requirements

- **Module:** `audit` with the standard rings. Domain: the `AuditEvent` value object validating the envelope (action grammar, outcome enum, redaction contract). Service: the `record()` use case plus query, export, and retention use cases. Repo: the store adapter. Controller: the viewer/export endpoints.
- **Append-only enforcement:** the store port defines exactly two operations — `append(event, tx)` and `query(filters, cursor)`. No update/delete method exists to call. Purging goes through a **separate retention port** exposing only `purgeBefore(organisationId, horizon, batchSize)` — no arbitrary delete. Where the engine supports it, the stack pack additionally revokes UPDATE/DELETE on `audit_events` from the runtime DB role (defence in depth; the port is the primary control).
- **`record()` as a shared port:** other modules receive the audit service's `record()` via the composition root (cross-module use through the service ring, never its inner rings). It takes the caller's transaction handle/context so the event commits or rolls back with the business change (requirement 2).
- **Purge job:** a scheduled background job (runner per stack pack) resolves each org's horizon (configured value or the 400-day default), deletes in bounded batches, and is **idempotent** — deleting below a horizon twice is a no-op, so an interrupted run simply resumes. Runs as `actor.type = system` and records `audit.events.purged` per org per run.
- **Export job:** async via the shared job runner; streams the filtered range to object storage (port per stack pack) — never buffers the full range in memory. Idempotent per job id; re-running a failed job overwrites its own partial artifact.
- **Concurrency:** appends are insert-only and conflict-free; cursor queries are keyset on `(occurred_at, id)` so concurrent inserts never skip or duplicate rows within a page chain.
- Rollout behind a default-off validated-config boolean per the index; `record()` calls no-op (with a startup warning) only while the flag is off in non-production.

## Audit log events

Meta-events owned by this spec (denied attempts follow requirement 4: same action, `outcome: denied`):

| Action | When emitted | Notable envelope fields |
|---|---|---|
| `audit.events.viewed` | Each executed audit query or detail read (search level — one per request, never per row) | target = the org (list) or the event (detail); filter set visible via `context.request_path` |
| `audit.events.exported` | Export job completes (`outcome: failure` if the job fails) | target = export job; `after` = format, filter set, row count |
| `audit.retention.updated` | Org's `audit_retention_days` changed | `before`/`after` = old/new value |
| `audit.events.purged` | Purge job finishes an org's run | actor = `system`; `after` = horizon, purged count |

Denied examples: `audit.events.viewed` / `audit.events.exported` with `outcome: denied` when the caller lacks the permission (emitted alongside the `403`).

## Security considerations

- Append-only is the tamper control: the two-operation port, the separate purge-only port, and (where supported) a runtime DB role without UPDATE/DELETE on `audit_events`.
- Redaction happens at the `record()` boundary per the base logging rules: identifiers and governed-field diffs only — never secrets, tokens, session values, or full sensitive payloads (cross-cutting criterion 5).
- Every tenant query is org-scoped; platform-scope (`organisation_id` null) events are reachable only via the operator surface defined in the trust-transparency spec, never tenant endpoints.
- Export artifacts live in object storage, downloadable only via short-lived signed URLs (mechanics per the export-controls spec / stack pack).
- Reading and exporting are themselves audited, so access to evidence is evidence.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Caller lacks the endpoint's permission | 403 | `PERMISSION_DENIED` (missing permission named in `error.details`) |
| Event id not found in the caller's org | 404 | `AUDIT_EVENT_NOT_FOUND` |
| Export job id not found in the caller's org | 404 | `AUDIT_EXPORT_NOT_FOUND` |
| Malformed or expired cursor | 400 | `INVALID_CURSOR` |
| `occurredFrom` after `occurredTo`, or unparseable date | 400 | `INVALID_DATE_RANGE` |
| Unsupported export format | 400 | `UNSUPPORTED_EXPORT_FORMAT` |
| `audit_retention_days` outside 90–2,555 | 400 | `RETENTION_OUT_OF_BOUNDS` |

## User stories & acceptance criteria

**S1 (P1)** — As a platform engineer, I want a shared `record()` call writing to an append-only store, so that every other compliance area has one reliable place to emit evidence.

- [ ] `record()` writes a row matching the index envelope field-for-field, in the caller's transaction: commit → event exists; rollback → no event. *Verify: service-ring integration test running a use case with `record()` twice — once committing, once forcing rollback — asserting the `audit_events` row exists/doesn't.*
- [ ] The store adapter exposes only append and query; no update/delete method exists, and the purge port only accepts a horizon. *Verify: unit test enumerating the port's surface + repo integration test showing purge-below-horizon is the sole row-removing path.*
- [ ] Denied and failed attempts are recorded with `outcome: denied`/`failure` under the attempted action. *Verify: contract test calling a guarded endpoint without the permission, asserting the 403 and the denied event row.*
- [ ] Cross-org isolation: a query scoped to org A returns nothing written for org B. *Verify: repo query test seeding two orgs.*

**S2 (P1)** — As an org admin, I want to search and inspect my organisation's audit events, so that I can investigate incidents and answer auditors.

- [ ] `GET …/audit-events` filters by actor, action prefix, target, outcome, and date range, cursor-paginated newest-first. *Verify: contract test per filter + a page-chain test following `nextCursor` to exhaustion (`null`).*
- [ ] The viewer lists events and its detail drawer shows the full envelope including the before/after diff. *Verify: screen walkthrough — loading, empty (no matches), error, and success states; open a drawer on an event carrying a diff.*
- [ ] Without `audit_logs:read` the endpoint returns `403 PERMISSION_DENIED` and the UI hides the viewer. *Verify: contract test + screen check as an unpermissioned member.*

**S3 (P1)** — As a compliance owner, I want audit-log access itself audited, so that reading evidence leaves evidence.

- [ ] Each executed query and detail read emits exactly one `audit.events.viewed` (search level, never per row). *Verify: integration test — one list call returning N rows yields exactly one event; one detail call yields one.*

**S4 (P2)** — As an org admin, I want to export a filtered range to CSV/JSON, so that I can hand evidence to auditors or load it into other tooling.

- [ ] `POST …/audit-events/exports` returns `201 pending`; polling reaches `completed` with a working short-lived `downloadUrl`; the artifact matches the filters and format. *Verify: integration test driving the job to completion and parsing the artifact.*
- [ ] The export requires `audit_logs:export` (read alone is not enough) and emits `audit.events.exported` on completion and `outcome: failure` on job failure. *Verify: contract test with a read-only role (403 + denied event) + integration tests for both job outcomes.*

**S5 (P2)** — As an org admin, I want to configure audit retention within compliance bounds, so that our audit history matches our own policy without breaking the floor.

- [ ] `audit_retention_days` accepts 90–2,555, defaults to 400, rejects out-of-bounds with `400 RETENTION_OUT_OF_BOUNDS`, and emits `audit.retention.updated` with before/after. *Verify: policy-schema unit tests incl. bounds + integration test asserting the event.*
- [ ] The purge job deletes only events older than each org's horizon, in batches, idempotently, and records `audit.events.purged` as `system`. *Verify: integration test seeding events straddling the horizon, running the job twice, asserting survivors, deletions, and the purge event.*

**S6 (P3)** — As a security engineer at a customer, I want audit events streamed to our SIEM via a signed webhook, so that they enter our own monitoring in near-real time.

- [ ] An org can register a webhook target (SSRF-guarded per the backend baseline); events are delivered async with a payload signature, bounded retries, and a defined final-failure path. *Verify: integration test against a stub receiver — signature validation, retry on 5xx, dead-letter after exhaustion.*

## UX & non-functional notes

- Screens: **audit log viewer** (filter bar + list + detail drawer), **export dialog** (in the viewer), **audit retention field** (in the org security-settings screen). Each with loading/error/empty states; empty = "no events match", never an error.
- Desktop-first admin surface; the drawer must handle large diffs (scroll within, no page overflow).
- Perf: list queries are keyset-indexed; no `COUNT`; p95 list response is expected interactive (<1s) at millions of rows per org.
- Security: constraints above; no event payload is ever rendered unescaped.

## Out of scope

- **Hash-chain / cryptographic tamper evidence** — append-only storage plus restricted DB access is the v1 control; chaining adds operational complexity (anchoring, verification tooling) no customer requirement yet justifies.
- Vendor-specific SIEM connectors (Splunk/Datadog apps) — S6's generic signed webhook is the boundary.
- Analytics/anomaly detection over audit data.
- A tenant-facing UI over platform-scope operator events (operator surface: trust-transparency spec).

## Open questions

- No `design/` mockup exists yet for the new screens (audit log viewer with detail drawer, export dialog, audit retention setting); required before initial build. Owner: design.
- Are audit retention floors contractual per plan or uniform (mirrors the index's open question)? Owner: product/legal, before retention GA.
- Should a legal hold (retention-deletion spec) also freeze audit-event purging for the affected org? Owner: product/legal, before S5 ships.
