# Provider webhooks & state sync — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make webhook-synchronised local state the trustworthy source of billing access: every provider event lands in one signature-verified endpoint, is recorded idempotently, and converges local subscription state through a single apply path that a stale or duplicated event can never corrupt — with a reconciliation sweep as the safety net for anything the webhook channel drops.

## Product requirements

1. One inbound endpoint, `POST /internal/v1/billing/webhooks/{provider}`, receives all provider events. No session auth; the provider signature is the only authentication (index: provider boundary).
2. The raw request body is preserved for signature verification — the seam the active stack pack binds — and verification runs **before any parsing**. An invalid or missing signature returns `400 WEBHOOK_SIGNATURE_INVALID`, is logged, and emits `billing.webhook.rejected`; no state changes.
3. An unknown `{provider}` path segment returns `404 UNKNOWN_PROVIDER`.
4. Every verified event is persisted **insert-first** into `billing_events` under the unique `(provider, provider_event_id)` key (index invariant). A duplicate delivery returns `200` immediately, recorded with status `skipped` — safe under provider retries.
5. Tenant resolution maps the event to an organisation via `provider_customer_id` → `billing_customers` (checkout.md) or the `organisation_id` carried in provider object metadata. An event resolving to no tenant is recorded `failed` with an alerting log and still returns `200` — a permanent failure per the base *Integrations* classes; the provider must not retry what can never succeed. Transient handler failures return `500` so the provider retries.
6. Handlers treat events as **triggers, not truth**: on any subscription-affecting event, the apply path fetches the object's current state from the provider (or compares `provider_created_at` against the local row's last-synced timestamp) and converges local state to it. A stale, out-of-order event can never regress newer local state.
7. State writes validate allowed status transitions per subscription-lifecycle.md before applying — never transition merely because a callback asked (base *Business rules*).
8. **The apply path is single.** Webhook processing, the post-redirect verification read (checkout.md), and the reconciliation sweep all call the same use case — conceptually `syncSubscriptionFromProvider(…)`. No second code path writes local billing state.
9. Unhandled or unknown event types are recorded as processed-as-ignored (status `skipped`, with a reason) and return `200` — never `500` on an unknown type.
10. Processing is synchronous within the request by default (small writes only; long work forbidden). Where a pack's serverless shape requires deferral, the pack binds a queue behind this seam — named here, not implemented here.
11. A scheduled reconciliation sweep (runner bound by the active pack) lists local non-terminal subscriptions and converges each against the provider in bounded, resumable batches (base backfill discipline); it also runs targeted after checkout verification. Detected drift — a missed webhook — is corrected, logged `warn` per corrected row, and emits the same audit events the equivalent webhook would.
12. With `BILLING_ENABLED=false` the endpoint returns `503` (index: config & rollout).

### Handled event families

Agnostic family names; the active stack pack maps the provider's concrete event types onto them.

| Event family | Local effect | Audit events |
|---|---|---|
| customer created / updated | upsert the `billing_customers` linkage (columns: checkout.md) | — (linkage, not a billing state change) |
| checkout session completed | converge the resulting subscription via the apply path | `billing.checkout.completed` |
| subscription created | create the local subscription in converged state | `billing.subscription.created`; `billing.trial.started` where a trial begins at creation |
| subscription updated | converge status, plan, interval, quantity, period, cancellation intent | `billing.subscription.updated`; `billing.trial.ended` when the update leaves `trialing` |
| subscription deleted | converge to the terminal state | `billing.subscription.canceled` |
| invoice paid | record the payment outcome; converge the subscription period | `billing.invoice.paid` |
| invoice payment failed | record the failure; converge status (grace handling: subscription-lifecycle.md) | `billing.invoice.payment_failed` |
| payment method updated | refresh the stored payment-method display summary (surface: settings-invoices.md) | — (display metadata; subscription state unchanged) |
| trial will end (where the provider supports it) | record the approaching trial end (notice surface: subscription-lifecycle.md) | — |

## User flows

No end-user flows — this area is entirely backend. Processing flows, for testability:

**F1 — Valid event applied (P1).** 1. Provider POSTs an event. 2. Signature verifies over the raw body. 3. Insert-first into `billing_events` (`received`). 4. Tenant resolves; the apply path fetches current provider state and converges the local row, validating transitions. 5. Audit events emit in the same transaction; row marked `processed`; `200`.

**F2 — Duplicate delivery (P1).** 1. The same `provider_event_id` arrives again. 2. The unique-key insert conflicts. 3. `200` immediately; a row recorded `skipped`; no state change, no audit event.

**F3 — Out-of-order delivery (P1).** 1. A stale event arrives after a newer one was applied. 2. The apply path converges against current provider state (or the timestamp comparison short-circuits). 3. Local state is unchanged or moves forward — never backward.

**F4 — Reconciliation sweep (P2).** 1. The scheduled job lists non-terminal local subscriptions in bounded batches. 2. Each converges through the same apply path. 3. Corrected rows log `warn` and emit the webhook-equivalent audit events.

## Admin capabilities

None in-product. Operators diagnose via `billing_events` rows (status, error, payload) and structured logs; registering the webhook endpoint and rotating its secret at the provider is an ops runbook (see Open questions). Failed-event replay is out of scope (re-delivery is the provider's; the sweep covers gaps).

## API behavior

| Method & path | Purpose | Auth | Notable behaviour |
|---|---|---|---|
| `POST /internal/v1/billing/webhooks/{provider}` | Receive one provider event | Signature over the raw body — no session, no permission | `200` processed / duplicate / skipped-unknown / unresolvable-tenant; `400` bad signature; `404` unknown provider; `500` transient failure (provider retries); `503` billing disabled |

Response bodies are minimal acknowledgements; the provider only inspects the status code. No pagination, no envelope beyond the base error shape on failures.

## Data model changes

New table **`billing_events`** (owned here; unique key pinned by the index; reversible migration per `db/CLAUDE.md`):

- `id` (PK); `provider`; `provider_event_id` — unique `(provider, provider_event_id)`, the idempotency key.
- `event_type` (provider's type string); `organisation_id` (nullable FK, indexed — set when tenant resolution succeeds).
- `payload` (JSON) — redacted per the logging rules: ids and object snapshots only, no card/bank fields (the provider sends none).
- `status` (`received` | `processed` | `skipped` | `failed`); `error` (nullable text, set on `failed`).
- `provider_created_at` (the provider's event timestamp — the ordering comparand); `processed_at` (nullable).
- `created_at`; `updated_at`.

No other table changes. `subscriptions` columns are owned by subscription-lifecycle.md; `billing_customers` by checkout.md — this spec only writes to them through the apply path.

## Backend implementation requirements

- Lives in the `billing` module. Controller ring: the webhook route, raw-body capture, signature verification, provider-name validation. Service ring: the per-event use case and `syncSubscriptionFromProvider(…)`. Repo ring: the `BillingGateway` calls that fetch current provider state; mappers keep provider SDK objects out of inner rings (index: provider boundary).
- **Idempotency is the database's job**: insert-first against the unique key; the conflict, not a pre-check, detects duplicates (base *Integrations* concurrency — no read-then-write race).
- **One transaction per event**: the `billing_events` status update, local state write, and audit `record()` commit together; a failure rolls all back and the row is marked `failed` (or the request returns `500` for transient classes, leaving the provider to retry).
- **Failure classification** per the base *Integrations* table: bad signature = invalid (400); unknown provider = invalid (404); unresolvable tenant / unknown type = permanent (200, recorded); provider fetch timeout or DB error = transient (500). An unclear outcome is never recorded `processed` (base *Unclear outcomes*).
- **Ordering**: converge-to-current is the primary defence; the `provider_created_at` vs last-synced comparison is the fallback where a fetch is unnecessary or unavailable. Never apply an event's embedded object state directly.
- The sweep job is a service-ring use case invoked by the pack-bound scheduler; batch size and resume cursor per the base backfill discipline. It shares the apply path — no sweep-only write logic.
- **Observability**: one structured log per event (event id, type, organisation id, outcome, duration); counters for signature rejections and `failed` rows; the webhook signing secret (env name bound by the pack; index: config) is never logged.

## Audit log events

Via the shared `record()` in the service ring, same transaction as the state change. Actor is `system` (provider-originated).

| `action` | When emitted |
|---|---|
| `billing.webhook.rejected` | Signature verification failed |
| `billing.checkout.completed` | Checkout-session-completed event applied |
| `billing.subscription.created` / `.updated` / `.canceled` | Subscription state converged (webhook or sweep) |
| `billing.trial.started` / `.ended` | Trial begins at subscription creation / subscription leaves `trialing` |
| `billing.invoice.paid` / `.payment_failed` | Invoice outcome events applied |

Where enterprise-compliance is adopted, these flow through its audit envelope. Duplicate and skipped-unknown events emit no audit event — nothing changed.

## Security considerations

- Signature verification is the **only** authentication; comparison is constant-time. Failure is logged and audited but the response reveals nothing beyond `400`.
- Replay window: where the provider signs a timestamp, reject events older than the provider's documented tolerance — a captured request cannot be replayed later even with a valid signature.
- The endpoint carries a rate limit and a request body size cap (values bound by the active pack) — it is the app's only unauthenticated POST surface besides `/health`.
- `payload` stores ids and object snapshots only; no card, bank, or raw payment data is ever stored or logged (program criterion 4).
- The signing secret comes from validated config, is never logged, and rotates per the ops runbook (Open questions).

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Invalid or missing signature | 400 | `WEBHOOK_SIGNATURE_INVALID` |
| Unknown `{provider}` path segment | 404 | `UNKNOWN_PROVIDER` |
| Transient processing failure (provider fetch, DB) | 500 | — (provider retries) |
| Duplicate `provider_event_id` | 200 | — (recorded `skipped`) |
| Tenant unresolvable | 200 | — (recorded `failed`, alerting log) |
| Unknown event type | 200 | — (recorded `skipped`, reason) |
| `BILLING_ENABLED=false` | 503 | — (index: config & rollout) |

## User stories & acceptance criteria

**S1 (P1)** — As the platform, I want every webhook authenticated by signature over the raw body, so that forged events can never touch billing state.

- [ ] A tampered payload (valid shape, wrong signature) returns `400 WEBHOOK_SIGNATURE_INVALID`, changes no state, and emits `billing.webhook.rejected`. *Verify: integration test POSTing a tampered body to `/internal/v1/billing/webhooks/{provider}`, asserting the response, unchanged `subscriptions`, and the audit row.*
- [ ] A correctly signed event returns `200` and is recorded `processed`. *Verify: same test suite with a validly signed body, asserting the `billing_events` row.*
- [ ] The signing secret never appears in logs. *Verify: log-capture assertion across the signature tests.*

**S2 (P1)** — As the platform, I want duplicate events to be no-ops, so that provider retries never double-apply a change.

- [ ] Delivering the same event twice yields exactly one state change; the second delivery returns `200` and records status `skipped`. *Verify: integration test posting an identical event twice, asserting one subscription write, one audit event, and the second `billing_events` row `skipped`.*

**S3 (P1)** — As the platform, I want out-of-order events to converge rather than regress, so that delivery order never corrupts access state.

- [ ] Delivering a subscription-updated event and then a stale subscription-created event leaves local state at the newer truth. *Verify: integration test delivering the newer event first, then the stale one, asserting final `subscriptions` state matches current provider state.*

**S4 (P1)** — As the platform, I want subscription lifecycle events to synchronise local state and emit audit events, so that access decisions and history stay correct.

- [ ] Each handled family applies its local effect and emits its audit events per the families table. *Verify: one integration test per family through the apply path, asserting the local row, the `billing_events` status, and the audit event(s).*
- [ ] An event resolving to no tenant is recorded `failed` with an alerting log and returns `200`. *Verify: integration test with an unknown `provider_customer_id`.*

**S5 (P2)** — As an operator, I want the reconciliation sweep to correct missed webhooks, so that dropped deliveries never strand access state.

- [ ] Deleting the local sync effect of an applied event and running the sweep converges the row and logs a `warn` plus the webhook-equivalent audit events. *Verify: integration test forcing local drift, invoking the sweep use case, asserting convergence, the `warn` line, and the audit rows.*

## UX & non-functional notes

- No UI — this area has no screens, i18n keys, or frontend states; user-visible consequences surface through the specs that read the synchronised state (settings-invoices.md, subscription-lifecycle.md).
- Per-event processing budget stays well inside the provider's delivery timeout; the converge fetch is the only outbound call per event.
- The sweep's cadence and batch size must keep drift detection under a business day without hammering the provider API (bounded batches, resumable cursor).

## Out of scope

- Entitlement decisions and access-tier interpretation — plans-entitlements.md and the index's access table (lifecycle spec).
- Any UI surface, including webhook diagnostics screens.
- Provider dashboard configuration — registering per-environment endpoint URLs and rotating signing secrets is an ops runbook, not product behaviour (its home is an open question below).
- Queue-based asynchronous processing — the seam is named (req. 10); building it is a pack/scale decision.

## Open questions

- At what event volume or handler latency does the pack-bound queue (req. 10) become mandatory rather than optional? Owner: engineering, revisit at first production load test.
- Webhook signing-secret rotation cadence, and where the per-environment endpoint-registration + rotation runbook lives (`infra/`? the add-on README?). Owner: ops, before production go-live.
- Does `billing_events.payload` need a retention window — and where enterprise-compliance is adopted, how does it interact with that program's retention rules? Owner: product + compliance.
