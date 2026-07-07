# Maker-checker workflows — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: 2026-07-07-enterprise-compliance-controls.md. Status: proposed.

## Goal

Provide one generic dual-control (maker-checker) framework — a durable intent captured instead of executed, decided by a different member, executed with re-validation — that every guarded capability in the program routes through, so that organisations can require a second pair of eyes on their most dangerous actions without any feature growing its own approval fork (the add-on SOP mandates the shared flow).

## Product requirements

1. There is exactly **one** approval framework, exposed to other modules as a shared port. Any capability an org marks approval-required routes through it; a per-feature approval implementation is a defect, not a variant.
2. Guardable action types form a catalog. Initial entries, contributed by their owning specs: `rbac.role.assign_admin_or_owner`, `org_policy.update`, `retention.policy.update`, `retention.hold.release`, `mfa.member_reset`, `privacy.erasure.execute`, `export.large`, `bulk.delete.large`, `api_key.create`. Action types outside the catalog are rejected on write.
3. Org policy turns each catalog entry on/off independently and sets a record-count threshold where applicable (`export.large`, `bulk.delete.large`). **Every entry is off by default** — dual control is opt-in posture.
4. When a guarded action is initiated, the owning use case captures it as a durable **intent** (approval request): action type, serialized parameters, human-readable summary, initiator, expiry — status `pending` — and does **not** execute. The endpoint responds `202` with the request (or the guarded job/intent) resource in `pending_approval` — the documented `APPROVAL_REQUIRED` contract, not an error.
5. The initiator must hold the guarded action's own permission at initiation; an approval never substitutes for it. Lacking it is a plain `403`, not an intent.
6. Deciders must hold `approvals:decide` **and** must not be the initiator. Self-approval is structurally impossible: a DB-level check plus a use-case rule enforce initiator ≠ decider, including a member deciding a request initiated by their own API key.
7. Approvers see an approvals inbox (`approvals:read`) listing pending requests with the human-readable summary, and can inspect the raw parameters before deciding. Initiators always see their own requests without `approvals:read`.
8. A decision is approve or reject. A rejection **requires** a reason; an approval reason is optional. Rejection executes nothing.
9. On approval, the original action executes **with re-validation**: the registered executor re-checks the state the intent depends on — the target still exists, the initiator still holds the underlying permission, policy/thresholds are still met. A failed re-validation marks the request `failed` with a reason and executes nothing.
10. Exactly one decision wins: concurrent approve/reject calls race through a conditional state transition (`pending` → decided); the loser receives `409 INTENT_ALREADY_DECIDED`.
11. Pending requests expire — default 7 days, org-configurable 1–30 — and are auto-rejected (`expired`) by a background sweep. A decision attempted past expiry (before the sweep runs) is refused with `409 INTENT_EXPIRED`.
12. The initiator can cancel their own pending request; nobody else can.
13. Notifications: approvers (holders of `approvals:decide`) are notified on request creation; the initiator is notified on decision. In-app + email, stubbed under the test-mode add-on.
14. The full lifecycle is audited: `approvals.request.created/approved/rejected/expired/cancelled/failed`, plus denied decision attempts. The guarded action's own audit event on execution names the approving actor and the request id in `context`.

## User flows

**F1 — Enable dual control (P2).** 1. An org admin opens Security settings → Approvals. 2. Sees the catalog with per-entry toggles (and threshold fields for `export.large` / `bulk.delete.large`), all off by default. 3. Enables entries; backend validates and stores per-entry policy, audits `approvals.policy.updated`. 4. From the next request onward, matching actions are guarded.

**F2 — Guarded action captured (P2).** 1. A member initiates a guarded action (e.g. assigns the Admin role while `rbac.role.assign_admin_or_owner` is enabled). 2. The owning use case asks the approval seam whether policy guards this action type at this magnitude; it does. 3. The use case persists the intent (`pending`) and performs no state change; the endpoint returns `202` with the request resource. 4. Approvers are notified; `approvals.request.created` is audited. 5. The initiator sees the request under "My requests" and may cancel it.

**F3 — Approve and execute (P2).** 1. An approver opens the inbox, inspects a request's summary and raw parameters. 2. Approves (optional reason). 3. Backend wins the conditional `pending → approved` transition, re-validates, executes the action via the registered executor in the same use case, audits `approvals.request.approved` **and** the action's own event naming the approver. 4. Initiator is notified; the request shows `approved` with decider and timestamp.

**F4 — Reject (P2).** 1. As F3, but the approver rejects and must supply a reason. 2. Nothing executes; `approvals.request.rejected` is audited; the initiator is notified with the reason.

**F5 — Race, expiry, cancellation (P2).** 1. Two approvers decide simultaneously: one transition wins; the other gets `409 INTENT_ALREADY_DECIDED` and the UI refreshes to the settled state. 2. A request untouched for the expiry window is auto-rejected by the sweep (`expired`, audited, initiator notified). 3. An initiator cancels a pending request; it leaves the inbox as `cancelled`.

## Admin capabilities

- Enable/disable each catalog entry and set thresholds — `org_policy:update` (read with `org_policy:read`). Note the deliberate recursion: while `org_policy.update` is enabled, changing approval policy itself routes through an approval — dual control cannot be switched off unilaterally and silently.
- Review the approvals inbox and request history — `approvals:read`.
- Decide requests — `approvals:decide`.
- Trace every request and decision in the audit viewer — `audit_logs:read`.

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes apply. Decisions are synchronous small writes; only the guarded action's own execution may be long-running (its owning spec's async rules apply).

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/approval-requests` | Inbox / history | `approvals:read`; initiators always see their own | filters `status`, `actionType`, `initiatedBy`; items: `{ id, actionType, summary, status, initiator, decidedBy, expiresAt, createdAt }`; base pagination |
| `GET …/approval-requests/{requestId}` | Request detail | `approvals:read` or initiator | adds `parameters` (raw, redacted per governed-field rules), `decisionReason`, `failureReason` |
| `POST …/approval-requests/{requestId}/approve` | Approve + execute | `approvals:decide`, not the initiator | req: `{ reason? }`; `200` with the request in `approved`; `409` on race/expiry/re-validation failure |
| `POST …/approval-requests/{requestId}/reject` | Reject | `approvals:decide`, not the initiator | req: `{ reason }` (required); `200` with `rejected` |
| `POST …/approval-requests/{requestId}/cancel` | Cancel own pending request | initiator only | `200` with `cancelled` |
| `GET …/approval-policies` | Catalog + per-org policy | `org_policy:read` | one entry per catalog action type: `{ actionType, enabled, threshold?, expiryDays }` |
| `PUT …/approval-policies/{actionType}` | Set one entry | `org_policy:update` | req: `{ enabled, threshold? }`; threshold only valid for thresholded types; unknown type → `400` |

Guarded endpoints elsewhere in the program respond `202` with their resource in `pending_approval` plus `approvalRequestId` when capture occurs — that contract is defined here once and referenced by the owning specs.

## Data model changes

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs and sweep/filter columns indexed):

- **`approval_requests`** — `id` (PK); `organisation_id` (FK, indexed); `action_type` (validated against the catalog); `parameters` (validated document — the serialized inputs the executor needs, schema-checked per action type on write; **never contains secret material** — e.g. `api_key.create` captures key name/scopes, the secret is generated only at execution); `summary` (human-readable, generated at capture); `initiated_by_actor_type` (`user` | `api_key`), `initiated_by_actor_id`; `status` (`pending` | `approved` | `rejected` | `expired` | `cancelled` | `failed`); `decided_by` (nullable member FK, indexed); `decided_at` (nullable); `decision_reason` (nullable — the use case requires it for rejections); `failure_reason` (nullable — set when re-validation/execution fails after approval); `expires_at` (indexed for the sweep); `created_at`; `updated_at`. DB check encoding rule 6: `decided_by IS NULL OR initiated_by_actor_type <> 'user' OR decided_by <> initiated_by_actor_id`; the API-key-ownership variant is enforced in the use case.
- **`approval_policies`** — `id` (PK); `organisation_id` (FK, indexed); `action_type` (catalog-validated); `enabled` (boolean, default false); `threshold` (nullable integer — only for thresholded action types, bounds validated); `expiry_days` (default 7, bounds 1–30); `created_at`; `updated_at`. Unique `(organisation_id, action_type)`; a missing row means disabled.

Guarded resources in other specs carry a nullable `approval_request_id` FK (e.g. `export_jobs`, `bulk_action_intents`) — owned by those specs.

## Backend implementation requirements

- One shared module `approvals` with the four rings — domain: request entity, the state machine (`pending` → `approved`/`rejected`/`expired`/`cancelled`/`failed`) and decision rules 5–11; service: capture/decide/cancel/expire use cases owning transactions and `record()`; repo: adapters; controller: routes + guards.
- **The seam:** the module defines an `ApprovalGate` port other modules consume. A guarded use case calls `evaluate(organisationId, actionType, magnitude)` — "does org policy guard this action type at this magnitude?" — and either proceeds normally or calls `capture(…)` to persist the intent and return it (its controller then responds `202`). No guarded module reads `approval_policies` directly.
- **Executor registry:** each guarded module registers, at the composition root, an executor for its action type — `revalidate(parameters)` + `execute(parameters, approvalContext)`. The approvals module owns the lifecycle, never the guarded business logic; the guarded module owns re-validation and execution. An action type with no registered executor fails capture loudly at boot, not at decision time.
- **Decision use case:** one transaction — conditional `UPDATE … WHERE status = 'pending'` (single winner), then re-validate, then execute via the registered executor, then audit. Where the guarded action is itself async (`export.large`, `bulk.delete.large`), "execute" transitions the owning job/intent to its normal execution path rather than doing the work inline.
- **Background job — expiry sweep:** batched, idempotent, resumable; conditionally transitions `pending → expired` where `expires_at < now()`, audits, notifies. Re-running is a no-op; a crash mid-batch resumes safely because each transition is conditional.
- **Notifications** are emitted after commit through the base notification path (in-app + email adapters supplied by the active stack pack, no-op/stub sink under test-mode); a delivery failure never rolls back or blocks the state change.
- Permission checks go through the RBAC module's `PermissionChecker` port; edge guards assert `approvals:read`/`approvals:decide`, and rules that depend on state (initiator ≠ decider, expiry, status) are enforced again in the use case.

## Audit log events

Emitted via the shared `record()` in the service ring, same transaction as the change.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `approvals.request.created` | Guarded action captured as an intent | action type, summary, magnitude/threshold; target = the guarded object |
| `approvals.request.approved` | Approver approved (before/with execution) | decider, optional reason |
| `approvals.request.rejected` | Approver rejected | decider, required reason |
| `approvals.request.cancelled` | Initiator cancelled | — |
| `approvals.request.expired` | Expiry sweep auto-rejected | actor `system` |
| `approvals.request.failed` | Approved but re-validation/execution failed | decider, failure reason |
| `approvals.request.decision_denied` | Decision blocked (self-approval, missing permission, race loser, expired) | `outcome: denied`; violated rule |
| `approvals.policy.updated` | A catalog entry's policy changed | `before`/`after`: enabled, threshold, expiry |

On execution, the guarded action's **own** event (e.g. `rbac.role.assigned`, `export.contacts.completed`) is emitted by its owning module with `context.approval_request_id` and the approving actor — the audit trail links intent, decision, and effect.

## Security considerations

- Self-approval is impossible at two levels: the DB check and the decision use case (which also blocks a member deciding a request their own API key initiated). No UI-only enforcement.
- An approval never substitutes for the underlying permission: it is required at initiation (rule 5) and re-checked at execution (rule 9) — a demoted initiator's pending request cannot execute.
- Re-validation closes the time-of-capture/time-of-execution gap: stale targets, changed thresholds, or revoked permissions fail closed with `failed`, never a partial execution.
- `parameters` never hold secret material; request detail rendering redacts governed fields per the program envelope rules.
- All queries org-scoped by `organisation_id`; a request id from another org is `404`.
- Dual control cannot be silently disabled: policy changes are audited, and while `org_policy.update` is guarded, they themselves require approval.
- Bounded expiry prevents zombie intents from executing long after context changed.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing `approvals:read`/`approvals:decide` (or the underlying permission at initiation) | 403 | `PERMISSION_DENIED` (missing permission in `error.details`) |
| Decider is the initiator (or owns the initiating API key) | 403 | `SELF_APPROVAL_FORBIDDEN` |
| Deciding/cancelling a request already decided, cancelled, or expired-and-swept | 409 | `INTENT_ALREADY_DECIDED` |
| Deciding a request past `expires_at` (sweep not yet run) | 409 | `INTENT_EXPIRED` |
| Rejecting without a reason | 400 | `REJECTION_REASON_REQUIRED` |
| Re-validation fails on approval | 409 | `REVALIDATION_FAILED` (request transitions to `failed`) |
| Cancel attempted by a non-initiator | 403 | `PERMISSION_DENIED` (rule named in `error.details`) |
| Policy write for an action type outside the catalog | 400 | `UNKNOWN_ACTION_TYPE` |
| Threshold on a non-thresholded type, or out-of-bounds value | 400 | `INVALID_APPROVAL_POLICY` (field details) |
| Request id not found (or another org's) | 404 | `APPROVAL_REQUEST_NOT_FOUND` |
| Guarded action captured instead of executing | 202 | `APPROVAL_REQUIRED` — **not an error envelope**: the guarded endpoint returns `202` with its resource in `pending_approval` + `approvalRequestId`; the constant names this contract, and clients branch on the status field |

## User stories & acceptance criteria

The framework is P2 per the program index — no P1 stories here; nothing in the program MVP depends on it.

**S1 (P2)** — As an org admin, I want to switch dual control on per action type with thresholds where relevant, so that approval friction applies exactly where my compliance posture demands it.

- [ ] Every catalog entry is off by default and guarded actions execute directly. *Verify: fresh-org integration test — `GET …/approval-policies` shows all entries `enabled: false`; an Admin-role assignment applies immediately with no approval request row.*
- [ ] Enabling an entry guards the next matching action. *Verify: `PUT …/approval-policies/rbac.role.assign_admin_or_owner` `{ enabled: true }`, then the same assignment returns `202` with a `pending` request.*
- [ ] Thresholds are accepted only where applicable and bounds-checked. *Verify: unit tests — threshold on `export.large` accepted; on `mfa.member_reset` → `400 INVALID_APPROVAL_POLICY`; unknown type → `400 UNKNOWN_ACTION_TYPE`.*
- [ ] Policy changes are audited. *Verify: integration test asserting an `approvals.policy.updated` row with before/after diff after the PUT.*

**S2 (P2)** — As an initiator, I want my guarded action captured as a pending intent instead of executing, so that nothing dangerous happens on my say-so alone.

- [ ] The guarded endpoint returns `202` and performs no state change. *Verify: with `rbac.role.assign_admin_or_owner` enabled, `PUT …/members/{id}/roles` granting Admin returns `202` with `approvalRequestId`; the member's roles are unchanged and an `approval_requests` row is `pending` with serialized parameters.*
- [ ] Initiation still requires the underlying permission. *Verify: the same call by an actor lacking `roles:assign` returns `403 PERMISSION_DENIED` and creates no request.*
- [ ] Capture is audited and approvers are notified. *Verify: integration test asserting the `approvals.request.created` row and a notification per `approvals:decide` holder in the test-mode sink.*
- [ ] The initiator can cancel while pending. *Verify: `POST …/cancel` by the initiator returns `200 cancelled` + `approvals.request.cancelled` audit row; by another member returns `403`.*

**S3 (P2)** — As an approver, I want an inbox where I can inspect and decide requests — never my own — so that decisions are informed and dual control is real.

- [ ] The inbox lists pending requests with summaries; detail shows raw parameters. *Verify: contract tests on `GET …/approval-requests?status=pending` and the detail endpoint as an `approvals:read` holder; a member with neither `approvals:read` nor authorship gets an empty view of others' requests.*
- [ ] Approval executes the action with the full audit chain. *Verify: integration test — approve the S2 request; the member now holds Admin, and both `approvals.request.approved` and `rbac.role.assigned` (with `context.approval_request_id` + approver) rows exist.*
- [ ] Rejection requires a reason and executes nothing. *Verify: `POST …/reject` with no reason → `400 REJECTION_REASON_REQUIRED`; with a reason → `200`, roles unchanged, `approvals.request.rejected` audited with the reason.*
- [ ] Self-approval is blocked even with `approvals:decide`. *Verify: initiator holding `approvals:decide` calls approve → `403 SELF_APPROVAL_FORBIDDEN` + `approvals.request.decision_denied` audit row; a DB-level insert violating the check is rejected in a repo test.*
- [ ] Exactly one concurrent decision wins. *Verify: integration test firing simultaneous approve + reject — one returns `200`, the other `409 INTENT_ALREADY_DECIDED`, and the stored status matches the winner.*

**S4 (P2)** — As an org admin, I want approved intents re-validated at execution and stale intents auto-rejected, so that yesterday's approval cannot execute against today's changed state.

- [ ] A vanished target fails closed. *Verify: capture a role-assignment request, delete the target membership, approve → `409 REVALIDATION_FAILED`; request `failed` with reason; `approvals.request.failed` audited; no partial change.*
- [ ] An initiator who lost the underlying permission fails closed. *Verify: capture, downgrade the initiator's role, approve → `409 REVALIDATION_FAILED`.*
- [ ] Expiry auto-rejects and blocks late decisions. *Verify: clock advanced past 7 days — the sweep transitions the request to `expired` (audited, actor `system`); an approve attempted just past `expires_at` before the sweep returns `409 INTENT_EXPIRED`; re-running the sweep is a no-op.*

**S5 (P3)** — As a participant, I want in-app and email notifications on creation and decision, so that requests don't stall unseen.

- [ ] Approvers are notified on creation, the initiator on decision, via both channels. *Verify: integration test under test-mode asserting stubbed in-app + email deliveries for creation, approval, and rejection.*
- [ ] A notification failure never blocks the state change. *Verify: use-case test with a throwing notifier — the decision commits and audits; the failure is logged once.*

## UX & non-functional notes

- Screens: Approvals inbox (pending list + status filters, request detail with summary, raw parameters, decide dialog with reason field), "My requests" view with cancel, and an Approvals section in Security settings (catalog toggles + thresholds). All need loading/error/empty states; the inbox's empty state explains dual control is opt-in.
- A pending-approvals badge count for `approvals:decide` holders — one cheap indexed count on `(organisation_id, status)`.
- Capture adds a single insert to the guarded path — no measurable latency budget change; decisions are synchronous small writes.
- Security: parameter rendering follows the governed-field redaction rules; decision buttons are disabled for the viewer's own requests (server remains authoritative).

## Out of scope

- Multi-step or n-of-m approval chains — one approver decides; a second layer is a future revision if a customer commitment demands it.
- Delegation, escalation, reminder schedules, or SLA tracking beyond the expiry sweep.
- Non-member (external) approvers and chat-channel decision surfaces.
- Retroactive approval of actions that already executed.
- The guarded actions' own semantics and endpoints — each owning spec defines them; this spec owns only the shared framework and catalog.

## Open questions

- No `design/` mockup exists yet for the new screens (Approvals inbox & request detail, approval policy settings); required before initial build.
- Should Owners be exempt from guards they trip themselves? Default **no** — dual control applies to every role; confirm with product before GA.
- Catalog growth: proposal — a new guardable action type is added by amending the catalog list here in the same change that registers its executor. Owner: engineering, before the first post-initial entry lands.
