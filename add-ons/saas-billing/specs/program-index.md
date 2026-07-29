# SaaS billing foundation — program index

**Status:** proposed · **Owner:** `<owner>` (set at adoption) · **Add-on:** `add-ons/saas-billing/README.md` (the durable SOP; this spec family is the buildable program)

## Goal

The product charges real customers for subscription billing without ever rewriting it: data-defined plans with monthly and yearly prices, provider-hosted checkout and payment, webhook-synchronised renewal and subscription lifecycle as the single source of truth for access, and a billing settings area with invoices that shows every state honestly. Seats and usage quotas are supporting enforcement areas built on the same entitlements. The payment provider owns money movement and card data; the app owns the billing model and every access decision.

## Area specs

Each area is an independently shippable spec, following one section template: Goal · Scope & ownership · User stories & acceptance criteria · Requirements · User flows · API & permissions · Data model · Audit events · Implementation notes · Edge cases & errors · Notes & decisions · Out of scope · Open questions.

| Area | File | Purpose & phases |
|---|---|---|
| Plan catalog & entitlements | `plans-entitlements.md` | Plans as pure data; the `EntitlementChecker` resolver every access decision goes through. P1; operator packaging changes P2. |
| Checkout | `checkout.md` | Free tier → paid subscription on the provider's hosted payment page. P1; cancelled-checkout return P2. |
| Subscription lifecycle, trials & access states | `subscription-lifecycle.md` | The one `subscriptions` row, trials, cancellation, and the fail-closed access derivation. P1; state surfacing P2; trial notice P3. |
| Customer portal & plan changes | `portal-plan-changes.md` | The hosted billing portal; in-app plan/interval/quantity changes with proration. P2. |
| Billing settings & invoices UI | `settings-invoices.md` | The settings page, status copy, gating hints, and the invoice list. Page P1; invoices P2. |
| Provider webhooks & state sync | `webhooks-sync.md` | Signature-verified events, idempotent sync, and the reconciliation sweep. P1; sweep P2. |
| Seat-based billing | `seats.md` | Seat counting and limit enforcement behind the plans' member caps. Limits P1; per-seat billing P2. |
| Usage metering & quotas | `usage-quotas.md` | Flow-metric metering and quota enforcement per billing period. P2; notifications/overage P3. |

## Phasing & build order

Priorities are set per story inside each area spec. The program-level MVP (all P1 stories):
- Plan catalog with a seeded Free plan; entitlement resolver + backend enforcement.
- Subscription model with the fail-closed access table.
- Hosted checkout with server-side outcome verification; webhook sync with signature verification + idempotency.
- Seat limits (member count + invite gate).
- The billing settings page's current-state view with an upgrade path.

Per-seat quantity billing, the customer portal, plan changes with proration, invoices UI, usage metering, and trial-ending notices build on that spine as P2/P3. Build order: **plans-entitlements and webhooks-sync first** — nothing enforces access until the resolver exists, and checkout is not "done" until its outcome arrives through webhook-synchronised state.

## Cross-cutting acceptance criteria (apply to every area)
1. Every billing endpoint verifies authentication, organisation membership, tenant scope, and its named permission; a cross-tenant id returns `404`, never another organisation's data. *Verify: contract tests per endpoint — allowed, denied, cross-tenant.*
2. No paid feature is reachable when the access tier resolves to `free` — including past-due-beyond-grace, unpaid, expired-trial, and missing-billing-row states. *Verify: integration tests per state driving one gated endpoint through the resolver.*
3. Webhook processing rejects an invalid signature (`400`, logged, no state change) and replays of a seen `provider_event_id` are recorded no-ops. *Verify: integration tests with a tampered payload and a duplicated event.*
4. No card number, CVC, or raw payment detail is ever stored or logged — only provider ids and receipt metadata. *Verify: schema review plus log/audit assertions in the checkout and webhook tests.*
5. Every billing state change emits its audit event; every entitlement denial emits the structured warn log. *Verify: integration tests asserting the audit row / log line after exercising the flow.*
6. With `BILLING_ENABLED=false`, no call reaches the real provider and no paid access is granted. *Verify: use-case tests against the stub sink asserting both.*

## Shared conventions (binding on every area spec)

Area specs inherit these conventions rather than restating them. A conflict between an area spec and this index is a defect; flag it, don't fork.
### Domain model & terminology

- **Organisation** — the tenant, as everywhere else in the product. All billing state hangs off exactly one organisation; nothing billing-related attaches to an individual user.
- **Plan** — a sellable tier (Free, Starter, Pro, Business as working examples): display data, prices per interval, entitlements, trial policy, active/archived status. Data, not code.
- **Entitlement** — a per-plan capability grant: `feature.<name>` (boolean — the row's presence grants it) or `limit.<name>` (integer cap; null = unlimited).
- **Billing customer** — the organisation's identity at the payment provider (`provider_customer_id`). Exactly one per organisation per provider.
- **Subscription** — the organisation's paid relationship: plan, interval (`month` | `year`), seat quantity, provider ids, status, current period start/end, trial window, cancellation intent. At most one non-terminal subscription per organisation.
- **Access tier** — what the app grants from billing state: `paid` (the subscription's plan entitlements) or `free` (the Free plan's entitlements). Always derived, never stored.
- **Billing event** — one received provider webhook event, persisted for idempotency and diagnosis.
- **Provider** — the payment provider, always behind ports; the active stack pack names the concrete one. Provider SDK objects never cross inward (base dependency rule; mappers live in the repo ring).

### The provider boundary

- One outbound domain port, **`BillingGateway`**, implemented as a repo-ring adapter: create/reuse customer, create checkout session, create portal session, change subscription (plan/interval/quantity), set/unset cancel-at-period-end, list invoices. Inbound, webhook **signature verification runs at the controller edge over the raw body** — the seam the active pack binds — before any parsing.
- The provider is the system of record for *payment* state; the local database is the system of record for *access*. Local state is written by webhook processing and the reconciliation sweep — never optimistically from an outbound call's return value, and never from a frontend redirect.

### Access decision (fail-closed, single implementation)

One domain function derives the access tier from the subscription row; every entitlement check goes through it (via the resolver below). No other code interprets subscription status.

| Subscription state | Access tier |
|---|---|
| `trialing`, trial end in the future | paid |
| `active` (including `cancel_at_period_end` set, until `current_period_end`) | paid |
| `past_due`, within the grace window | paid |
| `past_due` beyond grace · `unpaid` · `incomplete` · `incomplete_expired` · `paused` · `canceled` with the period ended | free |
| No subscription row · unrecognised provider status · missing plan · period anomalies | free (**fail closed**) |

Grace window: `BILLING_PAST_DUE_GRACE_DAYS` from validated config (default 7), measured from `current_period_end`.

### Entitlements

- One resolver behind the **`EntitlementChecker`** port: `canUseFeature(organisationId, featureKey)`, `getPlanLimit(organisationId, limitKey)`, `assertCanUseFeature(…)`, `assertWithinLimit(organisationId, limitKey, requested)`. No module outside the billing module reads plans or subscriptions to make an access decision.
- Entitlement keys live in one catalog module (an enum-like list); referencing an unknown key throws — it is a programming error, not a runtime state. Working examples: `feature.api_access`, `feature.exports`, `limit.members`, `limit.projects`, `limit.api_calls`.
- The **Free plan is a real `plans` row** (zero price, no provider ids, `is_default` = true); "no subscription" resolves to its entitlements, so fail-closed access still has defined limits.
- A denied check or limit block emits one structured `warn` log (organisation id, key, limit, requested) — operational logging, not audit; billing *state changes* are audited.

### Permissions

- `billing:read` — view billing status, seats, usage, invoices. `billing:manage` — checkout, plan change, cancel/resume, seat quantity, portal sessions.
- Checked at the controller edge; `403 PERMISSION_DENIED` names the missing permission in `error.details`. Any authenticated member may read the org's *effective entitlements* (a rendering hint); amounts and invoices need `billing:read`.
- With **enterprise-compliance** adopted, both keys join its RBAC catalog and system-role matrix (Owner ✓ both, Admin ✓ both, Manager/Member/Read-only —); a "billing manager" is a custom role holding both. Without it, Owner and Admin hold both via the app's existing role checks.

### Audit event scheme

`billing.<object>.<verb, past tense>` through the shared `record()` in the service ring (compliance envelope where that add-on is adopted): `billing.checkout.created`, `billing.checkout.completed`, `billing.subscription.created` / `.updated` / `.plan_changed` / `.cancel_scheduled` / `.resumed` / `.canceled`, `billing.trial.started` / `.ended`, `billing.invoice.paid` / `.payment_failed`, `billing.seats.updated`, `billing.webhook.rejected`, plus `…denied` events for blocked billing mutations. Area specs enumerate theirs. Envelopes carry ids, plan keys, and amounts in minor units — never card or bank details (none ever reach the app).

### API conventions

Base envelopes, status codes, and pagination apply. Tenant-scoped resources live under `/internal/v1/organisations/{organisationId}/billing/…`. Canonical route homes — an area spec owns its rows and may not move another's:

| Route | Owning spec |
|---|---|
| `GET …/billing/plans` | plans-entitlements |
| `GET …/billing/entitlements` | plans-entitlements |
| `GET …/billing/subscription` | subscription-lifecycle |
| `PUT …/billing/subscription/cancellation` | subscription-lifecycle |
| `POST …/billing/checkout-sessions` · `GET …/billing/checkout-sessions/{checkoutSessionId}` | checkout |
| `POST …/billing/portal-sessions` | portal-plan-changes |
| `PUT …/billing/subscription` (plan/interval/seat quantity) | portal-plan-changes (seat semantics: seats spec) |
| `GET …/billing/seats` | seats |
| `GET …/billing/usage` | usage-quotas |
| `GET …/billing/invoices` | settings-invoices |
| `POST /internal/v1/billing/webhooks/{provider}` (no session auth; signature-verified) | webhooks-sync |

Shared error codes (area specs add their own): `PERMISSION_DENIED` (403), `FEATURE_NOT_AVAILABLE` (403, `error.details` names the feature key), `PLAN_LIMIT_REACHED` (403, details name the limit key, cap, and requested value), `BILLING_DISABLED` (409, flag off), `PROVIDER_UNAVAILABLE` (502 — a provider outage never fabricates success), `SUBSCRIPTION_NOT_FOUND` (404). Cross-tenant ids are `404`, never a leak.

### Data model (canonical table set)

The owning spec defines columns; this index pins names, ownership, and invariants. All tenant-scoped tables carry `organisation_id` (indexed) and follow `db/CLAUDE.md` (snake_case, `created_at`/`updated_at`, UTC, indexed FKs). Money is integer minor units plus an ISO-4217 `currency` — never floats.

| Table | Owning spec | Invariants (unique unless noted) |
|---|---|---|
| `plans`, `plan_prices`, `plan_entitlements` | plans-entitlements | `plans.key` · `(plan_id, interval, currency)` · `(plan_id, entitlement_key)` |
| `billing_customers` | checkout | `(organisation_id, provider)` · `provider_customer_id` |
| `subscriptions` | subscription-lifecycle | `provider_subscription_id` · at most one non-terminal row per organisation (partial unique index or the pack's equivalent race-safe constraint) |
| `billing_events` | webhooks-sync | `(provider, provider_event_id)` — the idempotency key |
| `usage_records` | usage-quotas | `(organisation_id, metric_key, period_start)` |

Index `subscriptions.status` and `subscriptions.current_period_end` (sweep and expiry queries), and every `provider_*` id used for webhook tenant resolution.

### Config & rollout

- Validated at boot (base *Configuration*): `BILLING_ENABLED` (boolean, **default off** — routes `BillingGateway` to the stub sink), `BILLING_PAST_DUE_GRACE_DAYS` (default 7), the provider secret key and webhook signing secret (env names bound by the active pack), and the app base URL the checkout/portal return URLs derive from.
- With billing off: billing screens render the free/empty state; checkout, portal, and subscription mutations return `409 BILLING_DISABLED`; the webhook route returns `503`; entitlement checks still run (everything resolves to the Free plan). The flag never grants paid access in either position.

## Out of scope (program-wide)

- Tax/VAT calculation and invoice legal formatting — delegated to the provider's tax features; configuration only. Refunds, disputes, and chargeback operations — handled in the provider dashboard; webhook sync records the resulting subscription/invoice states only.
- Multiple concurrent subscriptions per organisation; coupons/promotions; multi-currency price localisation beyond each price row's single currency. The data model must not preclude them; nothing implements them.
- A self-serve plan-authoring UI — plans change via seed/operator data change plus provider sync, not product UI. Personal (per-user) billing.

## Open questions

- Concrete launch plan names, prices, and entitlement values (Free/Starter/Pro/Business are working examples). Owner: product; needed before checkout P1 lands. Payment provider per market: the stack packs bind the default; a mainland-China deployment swaps the gateway adapter (e.g. WeChat Pay) behind the same port. Owner: product + infra at instantiation.
- Do pending invites consume seats? Program default: **yes** (the seats spec pins the counting rule); revisit with product before seats P1.
- `design/` has no mockups for the billing surfaces (settings page, plan picker, paywall/limit states); each area spec lists its screens — mockups must exist before each initial build per the spec convention.
