# Customer portal & plan changes — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

A subscribed organisation manages its paid relationship without support tickets. The provider-hosted portal handles payment methods, invoices, and billing details. Plan, interval, and quantity changes run in-app, so the app's own validation — entitlements, seats, usage — runs before any commercial change. Upgrades apply immediately; downgrades are scheduled at period end.

## Scope & ownership

- **Owns:** `POST …/billing/portal-sessions`, `PUT …/billing/subscription`, the plan-rank comparison rule, the write semantics of `scheduled_plan_id`/`scheduled_interval`, the error codes `DOWNGRADE_EXCEEDS_LIMITS` and `SUBSCRIPTION_TERMINATED`, and the audit events `billing.portal_session.created` and `billing.subscription.plan_changed` / `.plan_change_scheduled` / `.plan_change_unscheduled` / `.plan_change_denied`.
- **Consumes:** `BillingGateway` (portal session; change subscription); plan rank and purchasability data (plans-entitlements.md, `PLAN_NOT_PURCHASABLE` owned by checkout.md); limit-fit checks from seats.md and usage-quotas.md; the `scheduled_plan_id`/`scheduled_interval` columns and `billing_customers` (owned by subscription-lifecycle.md and checkout.md); the apply path and sweep (webhooks-sync.md).
- **Used by:** settings-invoices.md — the "Manage billing" hand-off, plan-change dialog, and pending-change banner render this spec's behaviour.
- **Phases:** P2 = portal and plan changes (S1–S4; index Phasing). P3 = pause/resume (S5, named only).

## User stories & acceptance criteria

**S1 (P2)** — As a member with `billing:manage`, I want to manage payment method and billing details on the hosted portal, so that card handling never enters the app.

- [ ] `POST …/portal-sessions` returns `201 { redirectUrl }` for a subscribed org; the stub flow walks out and back to billing settings. *Verify: contract test on the 201 shape plus a stub e2e walking F1.*
- [ ] Permission and tenancy are enforced. *Verify: contract tests — plain member gets `403 PERMISSION_DENIED`; an org with no billing customer gets `404 NO_SUBSCRIPTION`; cross-tenant is `404`.*
- [ ] Portal-session creation is audited without leaking the URL. *Verify: integration test asserting the `billing.portal_session.created` row and that no envelope or log line contains the `redirectUrl`.*

**S2 (P2)** — As a member, I want an upgrade to apply immediately with proration, so that we get the higher tier the moment we pay for it.

- [ ] An upgrade PUT returns `200`, and the confirmed state lands via the apply path, flipping entitlements. *Verify: integration test — PUT a higher-ranked plan against the stub, run the synthesised webhook apply, assert the synced row and a previously-blocked gated endpoint now passing; assert `billing.subscription.plan_changed`.*
- [ ] An ambiguous gateway outcome changes nothing locally. *Verify: use-case test — gateway timeout on the change call returns `502 PROVIDER_UNAVAILABLE`, subscription row and audit store unchanged.*
- [ ] A plan change during trial keeps the trial window. *Verify: integration test — PUT against a `trialing` subscription; trial end date unchanged after sync, status still `trialing`.*

**S3 (P2)** — As a member, I want a downgrade to take effect at period end and be cancellable, so that we keep what we paid for and can change our mind.

- [ ] A downgrade PUT schedules rather than applies: `scheduled_plan_id`/`scheduled_interval` set, current entitlements unchanged. *Verify: integration test asserting the scheduled columns, unchanged access tier, and `billing.subscription.plan_change_scheduled`.*
- [ ] Billing settings shows the pending change with its effective date. *Verify: screen check of the settings state per settings-invoices.md.*
- [ ] PUTting the current state back unschedules, idempotently. *Verify: integration test — PUT-back clears the columns and emits `…plan_change_unscheduled`; a second identical PUT is a `200` no-op with no further audit event.*

**S4 (P2)** — As a member, I want a blocked downgrade to tell me exactly what to fix, so that the error is actionable.

- [ ] A downgrade below current occupancy returns `409 DOWNGRADE_EXCEEDS_LIMITS` with every violated limit key, current value, and target cap in `error.details`. *Verify: contract test with seats and one usage metric both over the target caps, asserting both entries' contents.*
- [ ] The UI renders the details as concrete guidance. *Verify: screen check — the plan-change dialog shows per-limit "remove N…" copy from `error.details`.*

**S5 (P3)** — As a member, I want to pause and resume the subscription where the provider supports it. Named, not built — aligns with the lifecycle spec's open question; nothing here may preclude it.

- [ ] No implementation; the PUT contract leaves room (a future `status` field is additive). *Verify: n/a — tracked in subscription-lifecycle.md.*

## Requirements

Core (P2):
1. A member with `billing:manage` opens the provider-hosted billing portal. The backend creates the portal session server-side for the organisation's own `provider_customer_id` and returns a redirect URL. An organisation with no billing customer yet has nothing to manage — reject the request.
2. Portal scope: update payment method, view invoices, update billing details. Plan switching inside the portal is disabled in provider configuration (Notes & decisions). The portal's return URL points back to the billing settings page (settings-invoices.md).
3. `PUT …/billing/subscription` is a full-resource replace of the desired commercial state — `{ planKey, interval, seatQuantity }` — against the current subscription (base PUT semantics; seat quantity semantics owned by seats.md, passed through here).
4. Compute upgrade vs downgrade by comparing plan rank — the display order/rank from plans-entitlements.md, not price arithmetic.
5. Upgrades, and interval changes that increase commitment, apply immediately via `BillingGateway` with the provider's default proration. The confirmed final state still arrives through webhook sync (webhooks-sync.md); the outbound call's return value grants nothing, per the index's provider boundary.
6. Downgrades, and interval changes that reduce commitment, are scheduled at period end: stored on the subscription row (`scheduled_plan_id` / `scheduled_interval`, columns owned by subscription-lifecycle.md), applied at rollover by the provider schedule or the reconciliation sweep. PUTting the current state back cancels a scheduled change — the replace is idempotent.
7. Downgrade validation: the target plan's limits must fit current occupancy — seats (seats.md) and metered usage / stored counts (usage-quotas.md). A violation is `409 DOWNGRADE_EXCEEDS_LIMITS` with `error.details` listing each violated limit key with current value and target cap, which the UI turns into actionable guidance ("remove N members first").
8. A `PUT` matching the current subscription state exactly is a no-op `200`, not an error. No provider call, no audit event.
9. Reject terminal subscriptions with `409 SUBSCRIPTION_TERMINATED`: a canceled-with-period-ended organisation starts over through checkout.md. A cancel-scheduled subscription is resumed via the cancellation resource (subscription-lifecycle.md), not this PUT.
10. A `trialing` subscription accepts the PUT; a plan/interval change during trial keeps the trial window (provider semantics — the trial neither restarts nor ends early).
11. The frontend always shows a confirmation before the PUT, naming what changes, when it takes effect, and the proration consequence in human copy ("You'll be charged a prorated amount today" / "Takes effect on <date>"). Copy owner: settings-invoices.md; the confirmation-first behaviour is a requirement here.

## User flows

### F1 — Update payment method via the portal (P2)

1. A member with `billing:manage` clicks "Manage billing" in billing settings; `POST …/portal-sessions` returns the redirect URL and the frontend redirects (leaves the SPA).
2. The member updates the card on the hosted portal and returns to billing settings; any resulting subscription/invoice state arrives via webhook sync.

### F2 — Immediate upgrade (P2)

1. The member picks a higher-ranked plan; the confirmation states the prorated charge.
2. `PUT …/billing/subscription`; the backend validates and calls the gateway.
3. The provider applies with proration; webhook sync lands the confirmed state, entitlements flip on the synced row, and billing settings shows the new plan.

### F3 — Scheduled downgrade (P2)

1. The member picks a lower-ranked plan; the confirmation states the effective date (period end).
2. The backend validates limits (req. 7), stores the scheduled change, and mirrors it to the provider schedule. Billing settings shows "Changes to <plan> on <date>" until rollover; PUTting the current plan back unschedules it.

### F4 — Blocked downgrade (P2)

1. The member picks a plan whose limits current usage exceeds.
2. `409 DOWNGRADE_EXCEEDS_LIMITS`; the UI lists each violated limit with the concrete action ("remove 4 members to fit 10 seats"). The member resolves and retries, or abandons.

## API & permissions

Both under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `POST …/portal-sessions` | Create a hosted billing-portal session | `billing:manage` | no body; `201 { redirectUrl }`; requires an existing billing customer |
| `PUT …/subscription` | Replace the desired commercial state | `billing:manage` | req: `{ planKey, interval, seatQuantity }`; `200` — immediate change applied or change scheduled; body mirrors the subscription read incl. any scheduled change |

- The response never claims a provider-confirmed state ahead of sync: an immediate upgrade returns the local row as-is with the change in flight; the frontend refreshes from the subscription read after sync (same poll-until-synced posture as checkout).
- Request fields: `planKey` (string, a `plans.key`), `interval` (`month` | `year`), `seatQuantity` (positive integer; semantics per the seats spec). Validation failures use the base `400` envelope with `error.details`. Cancelling a scheduled downgrade is the idempotent PUT-back — `billing:manage`. Viewing current and scheduled state is `billing:read`, on the subscription read owned by subscription-lifecycle.md.

## Data model

None owned here. The scheduled-change columns (`scheduled_plan_id`, `scheduled_interval`) live on `subscriptions`, owned by subscription-lifecycle.md; this spec owns their write semantics (reqs. 6 and 8). `billing_customers` is read for the portal session — owned by checkout.md.

## Audit events

Via the shared `record()` in the service ring (compliance envelope where enterprise-compliance is adopted).

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `billing.portal_session.created` | Portal session created | actor member (no URL in the envelope) |
| `billing.subscription.plan_changed` | Immediate change applied | `before`/`after`: plan key, interval, seat quantity |
| `billing.subscription.plan_change_scheduled` | Downgrade/reduction scheduled | `after`: target plan key, interval, effective date |
| `billing.subscription.plan_change_unscheduled` | Scheduled change cancelled by PUT-back | `before`: the cancelled target |
| `billing.subscription.plan_change_denied` | Change blocked (permission, limits, terminal state, non-purchasable plan) | `outcome: denied`; `context` names the violated rule / limit keys |

## Implementation notes

- Portal-session creation and subscription change are separate use cases in the `billing` module over the **`BillingGateway`** port (create portal session; change subscription plan/interval/quantity). No background jobs owned here.
- **Validation order** for the PUT: billing enabled → subscription exists and is non-terminal → plan purchasable (same rule as checkout — Free/archived rejected) → direction computed from plan rank → for downgrades, limit fit via the seats and usage modules' services (never re-implemented here) → no-op check (req. 8).
- **Downgrade scheduling** writes `scheduled_plan_id`/`scheduled_interval` and mirrors the schedule to the provider in the same use case. Rollover application belongs to the provider schedule plus the reconciliation sweep (webhooks-sync.md); this module never applies a scheduled change itself.
- **Idempotency:** the PUT is a full replace — replaying it is a no-op. A PUT equal to the current state clears any scheduled change (unschedule) or does nothing, emitting audit events only on actual change. **Unclear outcomes are never success:** a gateway timeout or ambiguous response on the change call returns `502 PROVIDER_UNAVAILABLE` with local state untouched; reconciliation resolves what actually happened (backend *Integrations*).
- **Portal URLs are secrets:** single-use and short-lived (provider property) — returned to the caller, never logged, never persisted, never placed in an audit envelope. The session is created strictly for the caller organisation's own billing customer; there is no client-supplied customer id to tamper with, and any cross-tenant reference is `404`.
- Rank comparison is a domain rule over the plan catalog — pure, unit-testable, no provider types inward. The PUT validates purchasability, rank, and entitlement fit server-side; the confirmation copy is rendering, not authority.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Missing `billing:manage` | 403 | `PERMISSION_DENIED` |
| No subscription to change / no billing customer for the portal | 404 | `NO_SUBSCRIPTION` |
| Target plan is Free, archived, or unknown | 409 | `PLAN_NOT_PURCHASABLE` |
| Downgrade target's limits below current seats/usage | 409 | `DOWNGRADE_EXCEEDS_LIMITS` (violated limits in `error.details`) |
| Subscription is terminal (canceled, period ended) | 409 | `SUBSCRIPTION_TERMINATED` |
| PUT equals current state | 200 | — (no-op, not an error) |
| Provider unreachable / ambiguous outcome (incl. portal creation) | 502 | `PROVIDER_UNAVAILABLE` |
| `BILLING_ENABLED=false` | 409 | `BILLING_DISABLED` |

## Notes & decisions

- **In-portal plan switching is disabled (req. 2)** so that plan changes must go through the app, where entitlement, seat, and usage validation runs before the provider is asked to change anything. Disabling it closes the bypass where a provider-side change would skip that validation; the webhook apply path still records whatever the provider reports, fail-closed per the index access table.
- **Proration amounts shown pre-confirmation are informational**; the provider's invoice is authoritative and arrives via sync.
- UX: screens are the "Manage billing" hand-off, the plan-change dialog (confirmation + blocked-downgrade guidance), and the pending-change banner — four states each; no `design/` mockups exist yet (program open question), required before initial build. Downgrade and cancel-adjacent actions follow the frontend's destructive-action rules: an explicit confirm naming the consequence, timing copy always stating the effective date. The portal redirect leaves the SPA; preserve return-to state, same care as checkout's redirect.
- UX: after an immediate upgrade, the settings page refreshes from the subscription read until sync confirms — reuse checkout's capped-poll pattern, not a bespoke one. The plan-change dialog's month/year interval toggle renders prices from the plans read (plans-entitlements.md), never hardcoded amounts.

## Out of scope

- Cancellation and resumption — the cancellation resource in subscription-lifecycle.md.
- Invoice list/display and all user-facing billing copy — settings-invoices.md.
- Seat counting, occupancy rules, and seat-quantity sync beyond passing `seatQuantity` through — seats.md.
- Webhook processing and the reconciliation sweep — webhooks-sync.md.

## Open questions

- Proration display precision: fetch a provider preview for the exact amount, or ship generic copy? Default: generic copy ("a prorated amount"); provider preview is a P3 enhancement. Owner: product.
- Do interval upgrades (month → year on the same plan) prorate immediately or schedule at period end? Default: immediate, the provider's default. Owner: product, before plan-changes P2 lands.
