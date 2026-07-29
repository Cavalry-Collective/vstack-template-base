# Checkout — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Checkout takes an organisation from the free tier to a paid subscription on the provider's hosted payment page. The backend creates the session and verifies the outcome server-side, through the same apply path the webhooks use. The app grants access only when synchronised local state says the subscription exists. No card data ever transits the app, and the success redirect grants nothing.

## Scope & ownership

- **Owns:** `POST …/billing/checkout-sessions`, `GET …/billing/checkout-sessions/{checkoutSessionId}`, the `billing_customers` table, the error codes `PLAN_NOT_PURCHASABLE`, `ACTIVE_SUBSCRIPTION_EXISTS`, and `CHECKOUT_SESSION_NOT_FOUND`, and the audit events `billing.checkout.created` and `billing.checkout.denied`.
- **Consumes:** the plan catalog (plans-entitlements.md); the trial rule and the one-non-terminal-subscription invariant (subscription-lifecycle.md); the seat counting rule (seats.md); the webhook apply path (webhooks-sync.md).
- **Used by:** settings-invoices.md (the plan picker hands off to F1); portal-plan-changes.md reuses `PLAN_NOT_PURCHASABLE`.
- **Phases:** P1 = the hosted flow end to end (S1–S4). P2 = the cancelled-checkout return (S5).

## User stories & acceptance criteria

**S1 (P1)** — As a member with `billing:manage`, I want to start checkout and land on the hosted payment page, so that my organisation can subscribe without the app handling cards.

- [ ] A valid `POST` returns `201` with `checkoutSessionId` and a `redirectUrl`. *Verify: contract test asserting status and response shape for an active paid plan.*
- [ ] The full flow is walkable against the stub gateway: create session → "pay" → success return → poll to `complete` → paid access. *Verify: stub e2e walking F1 end to end.*
- [ ] Free and archived plans are rejected. *Verify: contract tests asserting `409 PLAN_NOT_PURCHASABLE` for each.*
- [ ] Session creation is audited. *Verify: integration test asserting the `billing.checkout.created` row with plan key, interval, and quantity after the 201.*

**S2 (P1)** — As the platform, I want checkout tenancy and permissions enforced, so that no one starts or inspects another organisation's checkout.

- [ ] A member without `billing:manage` cannot create a session. *Verify: contract test asserting `403 PERMISSION_DENIED` naming the permission, plus the `billing.checkout.denied` audit row.*
- [ ] A session from another organisation reads as absent. *Verify: contract test — `GET` with org B's session id as org A returns `404 CHECKOUT_SESSION_NOT_FOUND`.*

**S3 (P1)** — As the platform, I want access granted only by synchronised state, so that a forged or early success redirect grants nothing.

- [ ] With the provider session `complete` but the sync withheld, the organisation's access tier is still `free`. *Verify: integration test — complete the stub session, suppress the apply, drive one gated endpoint through the entitlement resolver, assert free-tier behaviour.*
- [ ] After the apply runs, access resolves to `paid`. *Verify: same test — release the apply, assert the gated endpoint now passes and `billing.checkout.completed` was recorded.*
- [ ] No card or bank detail appears anywhere in local storage or logs across the flow. *Verify: log/audit assertions in the stub e2e per program cross-cutting criterion 4.*

**S4 (P1)** — As the platform, I want exactly one billing customer per organisation per provider, so that provider identity never forks.

- [ ] Concurrent first checkouts create exactly one `billing_customers` row and both requests succeed. *Verify: race test firing two parallel `POST`s for an org with no billing customer, asserting one row and two `201`s.*
- [ ] A later checkout attempt reuses the existing customer. *Verify: integration test — second `POST` after the first subscription terminates creates no new `billing_customers` row.*

**S5 (P2)** — As a member, I want an abandoned checkout to return me cleanly, so that cancelling isn't an error.

- [ ] The cancel return restores the plan picker with no error state and no billing state change. *Verify: screen check of the cancel route's four states; assert no subscription row and no audit event beyond `billing.checkout.created`.*

## Requirements

Core (P1):

1. A member with `billing:manage` starts checkout with `planKey`, `interval`, and, for per-seat plans, `seatQuantity`. The backend creates a provider checkout session and returns a redirect URL to the hosted page.
2. Only active, purchasable plans are checkout targets. Reject the Free plan and archived plans with `409 PLAN_NOT_PURCHASABLE`.
3. An organisation with an existing non-terminal subscription cannot start checkout — `409 ACTIVE_SUBSCRIPTION_EXISTS`. Subscribed organisations change plans through portal-plan-changes.md.
4. For per-seat plans, validate `seatQuantity` against the counting rule in seats.md. That spec owns the rule and the rejection semantics for a quantity below current occupancy.
5. Exactly one billing customer exists per organisation per provider. The first checkout creates it; every later checkout reuses it. Creation is race-safe: two concurrent first checkouts resolve to one `billing_customers` row.
6. Attach a trial only when the plan allows trials and the organisation has never used one (rule owned by subscription-lifecycle.md). Trial unavailability is not an error; checkout proceeds without a trial, silently.
7. Success and cancel return URLs derive from the app base URL config and carry the `checkoutSessionId`. They are UI destinations only; reaching them changes no state.
8. After the success redirect, the frontend polls `GET …/checkout-sessions/{checkoutSessionId}`. The backend fetches the session state from the provider, syncs the resulting subscription through the webhook apply path (webhooks-sync.md — one apply path, two triggers), and returns the outcome so the success page can poll until local state reflects it.
9. The app grants access only from the synchronised local subscription state, per the index's access table. Returning to the success URL with the provider session complete but the sync not yet applied still resolves the organisation to `free`.
10. With `BILLING_ENABLED=false`, both endpoints return `409 BILLING_DISABLED`. Where the test-mode add-on is adopted, the stub gateway returns a fake session whose verification read immediately reports `complete` and applies a synthesised webhook-equivalent event, so the full flow stays walkable without a provider.

## User flows

### F1 — Upgrade from the plan picker (P1)

1. A member with `billing:manage` picks a plan and interval (plan picker screen: settings-invoices.md).
2. `POST …/checkout-sessions` validates plan, subscription state, and seats; creates or reuses the billing customer; creates the provider session.
3. The frontend redirects to the hosted checkout page, leaving the SPA. The member pays; the provider redirects to the success URL.
4. The success page polls `GET …/checkout-sessions/{id}` until `status: complete` and the local subscription grants paid access. The UI confirms; entitlements now resolve from the new subscription.

### F2 — Checkout with a trial (P1)

1. As F1, on a plan that allows trials, for an organisation that has never used one: the session carries the trial period, the subscription lands as `trialing`, and access resolves to `paid` per the index table. With no trial available, the same flow runs with no trial period and no error.

### F3 — Cancelled checkout (P2)

1. The member abandons the hosted page; the provider redirects to the cancel URL.
2. The plan picker restores cleanly: no error toast, no state change, prior selection preserved where practical.

### F4 — Billing disabled (P1)

1. With `BILLING_ENABLED=false`, both endpoints return `409 BILLING_DISABLED` and the billing screens render the free/empty state per the index's rollout rules.
2. No call reaches the provider (program cross-cutting criterion 6).

## API & permissions

Both under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `POST …/checkout-sessions` | Create a hosted checkout session | `billing:manage` | req: `{ planKey, interval, seatQuantity? }`; `201 { checkoutSessionId, redirectUrl }` |
| `GET …/checkout-sessions/{checkoutSessionId}` | Post-redirect verification read; triggers on-demand sync | `billing:read`, own-organisation sessions only | `{ status: open \| complete \| expired, subscriptionStatus? }` — `subscriptionStatus` present once the synced subscription exists |

- `checkoutSessionId` is the provider's session id, treated as opaque. The frontend never sends a provider customer or price id — it sends `planKey`/`interval` and the backend resolves everything against the plan catalog. Request fields: `planKey` (string, a `plans.key`), `interval` (`month` | `year`), `seatQuantity` (positive integer, only meaningful for per-seat plans). Validation failures use the base `400` envelope with `error.details`.

## Data model

One new table (reversible up/down migration per `db/CLAUDE.md`; snake_case, UTC, indexed FKs). No local `checkout_sessions` table exists (Notes & decisions):

- **`billing_customers`** — `id` (PK); `organisation_id` (FK, indexed); `provider`; `provider_customer_id`; `billing_email` (the organisation's billing contact email sent to the provider); `created_at`; `updated_at`. Unique `(organisation_id, provider)` — the race-safety constraint for requirement 5 — and unique `provider_customer_id`, which backs webhook tenant resolution. Both per the index's canonical table set.

## Audit events

Via the shared `record()` in the service ring (compliance envelope where enterprise-compliance is adopted). Amounts, where present, are minor units; no card or bank details ever appear (program cross-cutting criterion 4).

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `billing.checkout.created` | Provider session created | actor member; `planKey`, `interval`, `seatQuantity`, `checkoutSessionId` |
| `billing.checkout.completed` | The session's subscription lands via the sync apply path — owner: webhooks-sync.md | `checkoutSessionId`, resulting subscription id, plan key |
| `billing.checkout.denied` | Checkout blocked (missing permission, non-purchasable plan, existing subscription, billing disabled) | `outcome: denied`; `context` names the rejection |

## Implementation notes

- Checkout lives in the `billing` module. Session creation is a use case calling the **`BillingGateway`** port (index: provider boundary); the controller validates and invokes, the repo-ring adapter talks to the provider.
- Race-safe customer creation: insert relying on the `(organisation_id, provider)` unique constraint; on conflict, reuse the existing row (`db/CLAUDE.md` — constraints encode invariants, not service-layer checks that race). The conflict is resolution, not an error.
- Validation order: billing enabled → plan exists/active/purchasable → seat rules → no non-terminal subscription. Each failure maps to its error code before any provider call is made. The trial decision is asked of the lifecycle module's rule (via its service/port), never re-derived here.
- The verification read never writes state directly. It fetches the provider session and, when a subscription resulted, hands it to the webhooks-sync apply path — the single writer of local subscription state. A provider fetch failure is `502 PROVIDER_UNAVAILABLE`, never a fabricated `complete` (backend *Integrations*: unclear outcomes are never success). The read also enforces ownership: a session whose customer does not match the caller organisation's billing customer is `404 CHECKOUT_SESSION_NOT_FOUND`.
- Repeating the `POST` creates a fresh provider session; sessions expire and the provider tolerates abandoned ones, so no background expiry job exists. The guarded invariants are the single billing customer and the single non-terminal subscription; the latter holds even if two sessions complete, because the apply path enforces the subscriptions invariant (lifecycle spec).
- Sessions are created server-side only, with the organisation's own `provider_customer_id` and the plan's `provider_price_id` resolved from local data. The client can never substitute a price, customer, or amount. `redirectUrl` is never logged (it can embed provider session secrets); log the session id only.
- Return URLs are built from the validated app-base-URL config key in one place, never from request headers.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Missing `billing:manage` / `billing:read` | 403 | `PERMISSION_DENIED` |
| Plan is Free, archived, or unknown as a checkout target | 409 | `PLAN_NOT_PURCHASABLE` |
| Organisation already has a non-terminal subscription | 409 | `ACTIVE_SUBSCRIPTION_EXISTS` |
| Seat quantity violates the seats spec's rules | — | owned by seats.md |
| Session id unknown, expired at the provider and unknown, or another org's | 404 | `CHECKOUT_SESSION_NOT_FOUND` |
| Provider unreachable / ambiguous provider response | 502 | `PROVIDER_UNAVAILABLE` |
| `BILLING_ENABLED=false` | 409 | `BILLING_DISABLED` |

Trial unavailability produces no error (requirement 6). The success/cancel URLs are worthless to forge: requirement 9 means access flows only from synchronised local state.

## Notes & decisions

- **No local `checkout_sessions` table.** The provider session carries `organisation_id` and the requested plan/quantity in its metadata, and the verification read proves ownership by matching the session's customer to the caller organisation's `billing_customers` row. Webhook tenant resolution uses the same `provider_customer_id` plus metadata (webhooks-sync.md). A local session table would duplicate provider state the app never decides on.
- UX: screens are the plan-picker hand-off, checkout success (polling), and checkout cancelled, each handling loading/error/empty/success per the frontend contract. No `design/` mockups exist yet (program open question); they are required before the initial build. The redirect leaves the SPA — preserve return-to state so the member lands back in billing settings, not at the app root (same care as the 401 redirect convention).
- UX: the success page polls with the shared loading state, capped (bounded attempts/backoff); on cap, fall back to "processing — we'll email you" copy without implying failure. Final copy owner: settings-invoices.md. Poll responses stay small and cheap: one provider fetch plus the apply path, no long-running work in the request.

## Out of scope

- Plan and interval changes for already-subscribed organisations — portal-plan-changes.md.
- Invoice display and billing settings copy — settings-invoices.md.
- Webhook mechanics, signature verification, and the apply path's internals — webhooks-sync.md.
- Seat counting rules and seat-driven enforcement — seats.md.

## Open questions

- Collecting VAT/company details at checkout: the provider's tax/address collection features are configuration, but whether to enable them at launch is a product decision. Owner: product, before checkout P1 ships.
- Is the billing contact email (`billing_email`) editable in-app before first checkout, or only through the hosted billing portal afterwards? Default: portal-only (YAGNI) unless onboarding feedback says otherwise.
