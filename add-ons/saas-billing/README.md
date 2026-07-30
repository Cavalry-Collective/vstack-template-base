# Add-on: saas-billing

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

Subscription billing as an architecture layer: data-defined plans and prices, checkout and payment, renewal on monthly or yearly intervals, invoices, trials, and failed-payment handling — built so pricing changes are data changes, not rewrites. Seat and usage limits are the supporting enforcement areas that keep plan access honest. The payment provider moves the money and hosts the card data; the app owns the billing model and every access decision.

## Adoption
At Day-1 (or later adoption), beyond keeping this directory:
1. Copy the active stack pack's entry from [`bindings.md`](bindings.md) into that pack's `backend.md`, then delete `bindings.md` — the pack appendix is the binding's only home from then on.
2. Update this README's two `bindings.md` links (this step and the *Binds to a stack* closing bullet) to point at the pack appendix instead — the file is gone after step 1.
3. When the project implements an area, write its requirement spec in the top-level `specs/` (per `specs/README.md`), covering that area's bullets under *Implementation areas* below.

## Approach

- **The provider processes payments; the backend decides access.** Local, webhook-synchronised billing state is the single source of truth for paid access. A success redirect, a frontend flag, or an unverified callback never grants access; missing or ambiguous billing data **fails closed** to the free tier.
- **Plans are data; features move between plans.** A plan is a row carrying prices and entitlement keys — never an enum branched on in code. Repricing, a new tier, or moving a feature between plans is a data change plus provider sync, no product code.
- **Every subscription state maps to a defined access tier.** Trialing, active, past-due (bounded grace), canceled-until-period-end, unpaid, incomplete, paused — each state the provider can report has a stated behaviour; unknown or missing state gets the safe one. Trials are bounded, one per tenant, not resettable by re-checkout.
- **Webhooks are the sync spine.** Signature-verified before anything parses, idempotent by provider event id, safe under retries and out-of-order delivery, logged, tenant-resolved — and backed by a reconciliation sweep, because webhooks alone always eventually miss one.
- **Sessions are server-made; money is exact; card data never lands.** Checkout and portal sessions are created server-side, for the caller's own tenant only. Amounts are integer minor units with an ISO currency. The app stores provider ids and receipt metadata — never card numbers or raw payment details.
- **Entitlements are central, not scattered.** Every feature gate, seat limit, and usage quota goes through one resolver (`canUseFeature` / `getPlanLimit` / `assertCanUseFeature` / `assertWithinLimit`), enforced in the backend; the UI only mirrors it. A plan-name check in product code is the defect this add-on exists to prevent.
- **Denials are actionable.** A blocked feature, limit, or downgrade names the key, the cap, and the requested value in the error details, so the UI can say exactly what to fix — never a generic error.
- **Billing is tenant-scoped, permissioned, and audited.** Customer, subscription, plan, seats, usage, and invoices all attach to the organisation, never the individual user — personal billing is a deliberate product decision, not a default. `billing:read` / `billing:manage` are checked server-side; every subscription, plan, and payment state change lands in the audit trail, and denied entitlement checks and limit blocks emit structured (redacted) logs so pricing-support questions are answerable. A cross-tenant id returns `404`, never another organisation's data.
- **Ship behind the default-off flag with a stub gateway.** Billing spends real money — base *Integrations* gating applies in full: a default-off validated-config boolean routes the provider gateway to a stub sink until flipped per environment, and flipping it back is the rollback.

## Binds to a stack

- **Provider** — the payment provider for the market, and the SDK/adapter home (a repo-ring adapter behind the domain's billing gateway port).
- **Webhook seam** — raw-body access plus the signature check at the controller edge.
- **Stub gateway** — the sink the flag routes to.
- **Jobs** — the background-job runner for the reconciliation sweep, usage-period rollover, and trial-expiry handling.
- **Config** — the validated-config home for the provider secret key and webhook signing secret.
- Per-pack answers are pre-written in [`bindings.md`](bindings.md); adoption copies the active pack's entry into its appendix and deletes the file (*Adoption*, step 1).

## Interactions

- **Base *Integrations*, *Security baseline*, *Audit trail*, *Configuration*** — the provider is an untrusted, unreliable external integration (idempotency, classified failures, unclear-outcomes-never-success, ownership checks, default-off gating all apply); billing state changes go through the shared `record()`; provider keys and the billing flag are validated env config, passed inward as values.
- **`db/CLAUDE.md`** — money in exact types; unique constraints encode the billing invariants (one customer per tenant per provider, one active subscription per tenant, unique provider event id); reversible migrations.
- **multi-tenancy** — supplies the organisation every billing row hangs off; adopt it (or another organisation model, e.g. enterprise-compliance's) before this add-on — without one there is no tenant to bill. Its stored organisation `plan` key is superseded by this add-on's derived entitlements.
- **enterprise-compliance** — `billing:read`/`billing:manage` join its RBAC catalog (Owner and Admin hold both); a "billing manager" is a custom role holding them; billing audit events use its envelope. Adopt both for compliance-grade billing evidence.
- **test-mode / llm-calls** — the stub gateway doubles as the test-mode sink, keeping checkout, portal, and webhook flows walkable without a live provider; llm-calls' per-tenant cost/usage monitoring can feed the usage-metering counters, making AI usage a billable, quota-enforced metric.

## Implementation areas

What a project must cover in each area, and the calls already made. Build plans & entitlements and webhooks & sync first: nothing enforces access until the resolver exists, and checkout is only done once its outcome arrives through synced state.

- **Plans & entitlements** — the catalog, and the single resolver behind every gate.
  - A plan row carries key, display data, prices per interval (with the provider price mapping), entitlement rows, and trial policy. Seed the Free plan as a real row (`is_default`, zero price, no provider ids) so fail-closed access still resolves to defined limits.
  - Entitlement keys are `feature.<name>` (granted by row presence) and `limit.<name>` (integer cap, null = unlimited), listed in one catalog module. Referencing an unknown key throws: a programming error, never a runtime client error.
  - Archived plans are never purchasable but keep their entitlements for existing subscribers.
  - Packaging changes (reprice, new tier, move a feature between plans) are operator data changes plus provider sync — no plan-authoring UI, no deploy.
- **Checkout** — free tier to paid on the provider's hosted page.
  - Create sessions server-side only, from the organisation's own billing customer and the catalog's provider price; the client sends a plan key and interval, never a price, customer, or amount.
  - Verify the outcome server-side: the success page polls a verification read that syncs the resulting subscription through the same apply path webhooks use. The success redirect itself grants nothing.
  - Keep exactly one billing customer per organisation per provider, race-safe via a unique constraint; every later checkout reuses it.
  - Reject the Free plan, archived plans, and organisations already holding a non-terminal subscription; validate any seat quantity against the seat counting rule.
  - Attach a trial only when the plan allows one and the organisation has never had one; when no trial is available, proceed silently without one.
- **Subscription lifecycle** — one row, one derivation, every state defined.
  - Keep at most one non-terminal subscription per organisation, enforced by a database constraint, not a service-layer check.
  - Only webhook processing and the reconciliation sweep write status transitions, each validated against an allowed-transition map before applying.
  - Derive the access tier, never store it: one pure function maps every provider status to a tier (trialing, active, and past-due within grace are paid; everything else, unknown, or missing is free), with the clock injected and the grace window from validated config (`BILLING_PAST_DUE_GRACE_DAYS`, default 7, from the period end).
  - Cancellation is an idempotent intent flag: schedule at period end, resumable until then, access retained until the period ends.
  - Grant one trial per organisation ever, derived from subscription history — no resettable flag, no farming by re-checkout.
- **Portal & plan changes** — self-serve management with the app's validation in front.
  - Hand payment methods, billing details, and invoice viewing to the provider-hosted portal; disable in-portal plan switching so every commercial change passes the app's checks.
  - Apply upgrades immediately with proration; schedule downgrades at period end, cancellable by putting the current state back. The change request is an idempotent full replace.
  - Validate a downgrade against current occupancy (seats and usage): the target plan's limits must fit before the provider is asked to change anything.
  - Portal and checkout redirect URLs are short-lived secrets: return them to the caller, never log, store, or audit them.
- **Settings & invoices** — one page that never lies about state.
  - Render every subscription state through one status→copy map (trial, renewing, canceling, payment issue within and beyond grace, paused, free); raw provider statuses never reach users.
  - Treat edge states as designed states, not errors: free organisation, billing disabled, over-cap usage, and pending scheduled change each get an honest rendering.
  - Drive locked-feature upgrade affordances from one shared entitlements read, permission-aware (`billing:manage` holders get the CTA, everyone else sees who to ask); the server stays authoritative.
  - List invoices live from the provider — no local invoice table; hosted and PDF links are short-lived signed URLs, never stored or logged.
- **Webhooks & sync** — the one writer of billing state.
  - Verify the provider signature over the raw body before any parsing; it is the endpoint's only authentication. An invalid signature is rejected and logged, changing nothing.
  - Record every event insert-first under the unique provider event id; a duplicate delivery is a recorded no-op, safe under retries.
  - Answer by whether a retry could help: permanent failures (duplicate, unresolvable tenant, unknown event type) return success so the provider stops retrying, recorded as skipped or failed; transient failures return a server error so it retries.
  - Treat events as triggers, not truth: on any subscription-affecting event, fetch current provider state and converge local state to it, so out-of-order delivery can never regress it.
  - Keep one apply path: webhook processing, checkout's verification read, and the reconciliation sweep all call the same sync use case; no second code path writes billing state.
  - Run a scheduled reconciliation sweep over non-terminal subscriptions in bounded batches — webhooks alone always eventually miss one; corrected drift logs a warning and emits the audit events the missed event would have.
- **Seats** — one counting rule, enforced only on the way in.
  - Occupied seats = active members + pending (non-expired, non-revoked) invites. Implement the rule as one function; enforcement, display, checkout validation, downgrade checks, and quantity sync all call it.
  - Enforce the limit only when adding: block invites and reactivations at the cap, race-safe at the last seat, bulk invites all-or-nothing.
  - Never block removing a member or revoking an invite; freeing a seat always succeeds.
  - On per-seat plans, the billed quantity follows the occupied count automatically; the confirmed quantity lands via webhook sync, and the sweep corrects drift.
- **Usage & quotas** — flow metering that never gets in the user's way.
  - Distinguish limit kinds: stock limits count live records at the mutation (members, projects); flow limits meter consumption per billing period (API calls, exports) in one counter per organisation, metric, and period, incremented atomically.
  - Check the cap before the guarded action, record after it succeeds; a bounded overshoot from concurrent checks is accepted — a metric that must never overshoot is a stock limit, not a flow one.
  - Metering never blocks the user's action: a failed usage write logs an error and the request still succeeds.
  - Roll periods lazily: a new period is a new row on first use, no reset job; free organisations meter against UTC calendar months, and a mid-period plan change keeps the running counter.
  - Report usage honestly, including `used` above the cap.
