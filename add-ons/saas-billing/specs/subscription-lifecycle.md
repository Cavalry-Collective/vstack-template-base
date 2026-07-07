# Subscription lifecycle, trials & access states — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Model the organisation's paid relationship as one local `subscriptions` row whose status is written only by webhook-synchronised state, and derive the access tier from it through one fail-closed pure function, so that every access decision in the app rests on a single, tested, provider-agnostic contract.

## Product requirements

1. At most one non-terminal subscription per organisation, enforced race-safely in the database (index invariant). Terminal = `canceled` with the period ended, or `incomplete_expired`.
2. The normalised status enum is exactly the index's set: `trialing`, `active`, `past_due`, `unpaid`, `incomplete`, `incomplete_expired`, `canceled`, `paused`. The provider's raw status string is always stored alongside in `provider_status`.
3. An unrecognised provider status stores its raw value and normalises to an `unknown` bucket that resolves the access tier to `free` — fail closed, never a crash and never paid.
4. Subscription status transitions are written **only** by webhook processing and the reconciliation sweep (`webhooks-sync.md`), and validated against the allowed-transition rules before applying — never applied just because an event asked (base Business rules, `apps/backend/CLAUDE.md`).
5. Access tier is derived, never stored: one pure domain function implements the index's access table row-for-row (restated below as the implementation contract), with the clock injected and the grace window from `BILLING_PAST_DUE_GRACE_DAYS` (validated config, default 7).
6. Trials start only through checkout (`checkout.md`) on plans with `trial_days` set. One trial per organisation **ever** — derived from history (any subscription row with `trial_start` set), not a resettable flag; a later checkout session for such an org is created without a trial period.
7. Trial expiry follows the provider: `trialing` → `active` (card on file) or `past_due`/`canceled`; local state follows via webhooks. No special no-card handling — whatever the provider reports, the derivation fails closed.
8. Cancellation intent is a `PUT` replace: schedule cancellation at period end, or resume a scheduled cancellation before the period ends, via `BillingGateway`; access is retained until `current_period_end` per the access table. Immediate cancellation and all final states arrive via webhook, never from the outbound call's return value (index provider boundary).
9. Any member with `billing:read` can read the subscription with its derived tier; raw statuses reach end users only through the settings UI's human copy (`settings-invoices.md`), never verbatim.

### Access-tier derivation (the implementation contract)

The index's access table, implemented as one pure domain function (no I/O, injected clock), unit-tested per row:

| Subscription state | Access tier |
|---|---|
| `trialing`, trial end in the future | paid |
| `active` (including `cancel_at_period_end` set, until `current_period_end`) | paid |
| `past_due`, within the grace window (from `current_period_end`) | paid |
| `past_due` beyond grace · `unpaid` · `incomplete` · `incomplete_expired` · `paused` · `canceled` with the period ended | free |
| No subscription row · `unknown` status · missing plan · period anomalies | free (**fail closed**) |

No other code interprets subscription status; the `EntitlementChecker` resolver (`plans-entitlements.md`) consumes this function.

## User flows

**F1 — Member views the subscription state (P1).** 1. A member with `billing:read` opens billing settings (screen: `settings-invoices.md`). 2. The SPA calls `GET …/billing/subscription`. 3. The page renders plan, interval, period, trial window, derived access tier, and any scheduled change/cancellation in human copy.

**F2 — Cancel at period end (P1).** 1. An admin with `billing:manage` chooses "Cancel subscription", confirms the consequence (access retained until the period end date, named). 2. `PUT …/billing/subscription/cancellation` with `{ "cancelAtPeriodEnd": true }`. 3. The use case calls `BillingGateway`, records `billing.subscription.cancel_scheduled`. 4. The confirming webhook updates the local row; access stays paid until `current_period_end`.

**F3 — Resume a scheduled cancellation (P1).** 1. Before the period ends, the admin chooses "Resume subscription". 2. Same route with `{ "cancelAtPeriodEnd": false }`. 3. Gateway call + `billing.subscription.resumed`; the webhook confirms; nothing lapses.

**F4 — Trial expires (P1, system flow).** 1. A trial started at checkout reaches `trial_end`. 2. The provider transitions the subscription; the webhook sync applies the validated transition and emits `billing.trial.ended`. 3. Derived access follows the table — no local timer, no optimistic write.

**F5 — Trial-ending-soon notice (P3).** Named here, depends on the provider's trial-will-end webhook event (`webhooks-sync.md`); surfaces in billing settings. Not part of this spec's P1.

## Admin capabilities

- View subscription state, period, trial, and scheduled changes — `billing:read`.
- Schedule/resume cancellation at period end — `billing:manage`.
- No admin (or any) surface edits status directly — state is webhook-written only (req. 4). Plan/interval/seat changes: `portal-plan-changes.md`.

## API behavior

All under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/subscription` | Current subscription + derived access | `billing:read` | `{ subscription (nullable), accessTier, plan: { key, name }, scheduledChange (nullable, from the portal spec's fields) }`; a free org gets `200` with `subscription: null`, `accessTier: "free"` |
| `PUT …/subscription/cancellation` | Set/clear cancel-at-period-end intent | `billing:manage` | req: `{ "cancelAtPeriodEnd": true \| false }`; full replace, idempotent — a no-op replay makes no gateway call and emits no audit event; `200` returns the subscription view above |

Between the gateway call and the confirming webhook, `GET` may briefly show the pre-change value — the UI shows the request as accepted; state converges via webhook (index provider boundary).

## Data model changes

New table (snake_case; reversible up/down migration per `db/CLAUDE.md`; all FKs indexed):

- **`subscriptions`** — `id` (PK); `organisation_id` (FK, indexed); `plan_id` (FK, indexed); `status` (normalised enum, req. 2, incl. `unknown`); `provider_status` (raw provider string); `interval` (`month` | `year`); `seat_quantity` (integer; semantics: `seats.md`); `provider_subscription_id` (nullable until the provider confirms — creation sequencing owned by the checkout/webhooks specs; unique where set, partial unique index); `current_period_start`; `current_period_end`; `trial_start` (nullable); `trial_end` (nullable); `cancel_at_period_end` (boolean); `canceled_at` (nullable); `scheduled_plan_id` (FK, nullable) + `scheduled_interval` (nullable) — written by `portal-plan-changes.md`; `ended_at` (nullable); `created_at`; `updated_at`.
- **One-non-terminal invariant**: partial unique index on `organisation_id` where `ended_at IS NULL` (or the active pack's equivalent race-safe constraint — index rule). The sync site sets `ended_at` when a row becomes terminal (req. 1); a violation maps to the domain conflict, `409`.
- Indexes: `status` and `current_period_end` (sweep/expiry queries) and `provider_subscription_id` (webhook tenant resolution) — index data-model rules.

## Backend implementation requirements

- Lives in the `billing` module's subscription area (domain: subscription entity, status enum + allowed-transition rules, the access-tier derivation function; service: read + cancellation use cases; repo: adapter; controller: the two routes).
- **Derivation function**: pure, stateless, clock injected as a value; grace window passed in from validated config — no config read in the domain (root Configuration rule).
- **Transition validation**: the domain owns the allowed-transition map; the sync use case (`webhooks-sync.md`) validates against it before applying and routes rejects to that spec's handling.
- **Cancellation use cases**: compare the requested `cancelAtPeriodEnd` against the local row — equal is a no-op (no gateway call, no audit); different calls `BillingGateway.setCancelAtPeriodEnd`, records the audit event, and leaves the row for the webhook to update. `PROVIDER_UNAVAILABLE` (`502`, shared) when the gateway fails — never fabricated success.
- **One-trial-ever**: a derived predicate — does any subscription row for the org have `trial_start` set — exposed to the checkout use case (`checkout.md`), which then creates the session without a trial. Not a flag; not resettable.
- **Entitlement cache**: subscription-state writes are the invalidation trigger for the resolver cache (`plans-entitlements.md`); the sync site invokes it after commit.
- No background jobs here; the reconciliation sweep belongs to `webhooks-sync.md`.

## Audit log events

Via the shared `record()` in the service ring, same transaction as the change (index scheme). Envelopes carry ids, plan keys, minor-unit amounts — never card details.

| `action` | When emitted | Emission site |
|---|---|---|
| `billing.subscription.created` / `.updated` / `.canceled` | Local row created/changed/terminal from provider state | the sync site — `webhooks-sync.md` |
| `billing.subscription.cancel_scheduled` | `PUT` cancellation with `true` applied (non-no-op) | this spec's use case |
| `billing.subscription.resumed` | `PUT` cancellation with `false` applied (non-no-op) | this spec's use case |
| `billing.trial.started` | Subscription arrives in `trialing` | the sync site |
| `billing.trial.ended` | Trial window closes (transition out of `trialing`) | the sync site |

## Security considerations

- Fail closed everywhere: no row, `unknown` status, missing plan, or period anomalies resolve `free` — the flag, an outage, or a provider surprise can never grant paid access (index cross-cutting criterion 2 and 6).
- Status is written only by the signature-verified webhook path and the reconciliation sweep — no endpoint here mutates it; the cancellation route sets intent via the gateway only.
- Both routes verify authentication, membership, tenant scope, and their named permission; a cross-tenant id is `404` (index cross-cutting criterion 1).
- With `BILLING_ENABLED=false`, the `PUT` returns `409 BILLING_DISABLED` and no call reaches the provider; `GET` still serves the free/empty view.
- Raw provider statuses and ids appear in operator surfaces and audit envelopes only, never in end-user copy (req. 9).

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| `PUT` cancellation when the org has no non-terminal subscription | 404 | `NO_SUBSCRIPTION` |
| `PUT` cancellation on an already-terminal subscription | 409 | `ALREADY_CANCELED` |
| Billing flag off on the `PUT` | 409 | `BILLING_DISABLED` (shared) |
| Missing `billing:read` / `billing:manage` | 403 | `PERMISSION_DENIED` (shared; missing permission in `error.details`) |
| Gateway failure during the `PUT` | 502 | `PROVIDER_UNAVAILABLE` (shared) |
| Body not `{ cancelAtPeriodEnd: boolean }` | 400 | validation envelope with `error.details` |

## User stories & acceptance criteria

**S1 (P1)** — As the app, I want fail-closed access derivation from subscription state, so that no billing state ever grants unearned paid access.

- [ ] The derivation function returns the contracted tier for every row of the access table, including `unknown`, missing-row, missing-plan, and period-anomaly cases. *Verify: pure unit tests, one per table row, with injected clock values on both sides of each boundary (trial end, period end, grace edge).*
- [ ] No paid feature is reachable in any free-resolving state. *Verify: integration tests driving one gated endpoint through the resolver per subscription state, asserting `403 FEATURE_NOT_AVAILABLE` for free-resolving rows and `200` for paid rows.*
- [ ] The grace window comes from `BILLING_PAST_DUE_GRACE_DAYS` and fails fast when malformed. *Verify: boot-time config validation test; derivation unit test at grace-boundary ± with a non-default value.*

**S2 (P1)** — As the billing model, I want at most one non-terminal subscription per organisation, so that access derivation never has to arbitrate between rows.

- [ ] The partial unique index rejects a second non-terminal row, race-safely. *Verify: integration test issuing two concurrent creates for one org — exactly one commits, the other maps to `409`.*
- [ ] A terminal row (`ended_at` set) permits a new subscription. *Verify: integration test — end a subscription, create a new one, both rows persist.*

**S3 (P1)** — As an org admin, I want to cancel at period end and change my mind, so that leaving is safe and reversible.

- [ ] `PUT` with `true` schedules cancellation, emits `billing.subscription.cancel_scheduled`, and access stays paid until `current_period_end`. *Verify: use-case test against the gateway fake asserting the call, the audit row, and a paid derivation before period end.*
- [ ] `PUT` with `false` before the period ends resumes, emitting `billing.subscription.resumed`. *Verify: use-case test both ways in sequence.*
- [ ] Replaying either value is a no-op: no gateway call, no audit event. *Verify: use-case test replaying the same body, asserting zero gateway invocations and no new audit row.*
- [ ] No subscription → `404 NO_SUBSCRIPTION`; terminal → `409 ALREADY_CANCELED`. *Verify: contract tests for both states.*

**S4 (P1)** — As the business, I want one trial per organisation ever, so that trials cannot be farmed by resubscribing.

- [ ] An org with any historical `trial_start` gets no trial on a new checkout. *Verify: integration test — complete and cancel a trial subscription, start a second checkout session for a `trial_days` plan, assert the session is created without a trial period (via the checkout spec's session read).*
- [ ] The predicate derives from subscription history, not a flag. *Verify: unit test on the predicate over row fixtures; no schema column exists to reset.*

**S5 (P2)** — As an org admin, I want trial-ending and past-due-grace states surfaced, so that I can act before losing access.

- [ ] `GET …/subscription` exposes trial end, grace status, and scheduled cancellation for the settings UI to phrase. *Verify: contract test per state asserting the response fields; screen check that the settings page renders the human copy, never the raw status.*
- [ ] Trial-ending-soon notice (P3 flow F5) is tracked as follow-up, gated on the provider event. *Verify: named in `webhooks-sync.md`'s event handling before implementation.*

## UX & non-functional notes

- No screens of its own — the settings page (`settings-invoices.md`) renders everything here, with the four states and human status copy; raw enum values never reach users.
- The derivation runs on hot request paths via the entitlement resolver — pure and O(1), cacheable per org with the resolver's ≤ 5 min TTL backstop.
- Clock injection is the testing seam: every time-dependent row of the access table is testable without waiting or stubbing globals.

## Out of scope

- Plan/interval changes and proration — `portal-plan-changes.md` (which writes `scheduled_plan_id`/`scheduled_interval`).
- Webhook verification, event persistence, ordering, and the reconciliation sweep — `webhooks-sync.md`.
- Seat quantity semantics and counting — `seats.md`.
- Dunning email sequences — provider-owned retries/emails; P3 open question at the program level.
- Refunds/disputes (index program-wide Out of scope).

## Open questions

- Pause/resume support: provider-dependent — `paused` is modelled in the status enum (resolves free) but no product surface exists; owner: product, if a provider/customer need appears.
- Final grace-window length: `BILLING_PAST_DUE_GRACE_DAYS` defaults to 7 (index); owner: product before launch.
