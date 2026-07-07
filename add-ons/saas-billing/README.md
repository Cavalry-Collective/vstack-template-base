# Add-on: saas-billing

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the payment provider + SDK, the webhook verification seam, the stub gateway, and the job runner named under *Binds to a stack*.

Production-grade SaaS billing as an architecture layer: data-defined plans, trials, tenant-level subscriptions, seat and usage limits, invoices, failed-payment handling, and plan-based feature access — built so pricing changes are data changes, not rewrites. The payment provider moves the money and hosts the card data; the app owns the billing model and every access decision.

This README is the durable SOP — the rules every change must honour once the add-on is adopted. The **buildable program** — flows, APIs, data models, and acceptance criteria — lives as specs in this add-on's own `specs/` directory (map at the bottom), written to the repo's spec-first conventions (`specs/README.md`). Everything the add-on ships is contained in this directory; at adoption, wire it in per *Adopting this add-on* below.

## Approach

- **Billing hangs off the tenant, never the individual user.** Customer, subscription, plan, seats, usage, and invoices all attach to the organisation; every billing row, query, and provider object is tenant-scoped. Personal billing is a deliberate product decision, not a default.
- **The provider processes payments; the backend decides access.** Local, webhook-synchronised billing state is the single source of truth for paid access. A success redirect, a frontend flag, or an unverified callback never grants access; missing or ambiguous billing data **fails closed** to the free tier.
- **Entitlements are central, not scattered.** Every feature gate and limit goes through one resolver (`canUseFeature` / `getPlanLimit` / `assertCanUseFeature` / `assertWithinLimit`), enforced in the backend; the UI only mirrors it. A plan-name check in product code is the defect this add-on exists to prevent.
- **Plans are data; features move between plans.** A plan is a row carrying prices and entitlement keys — never an enum branched on in code. Repricing, a new tier, or moving a feature between plans is a data change plus provider sync, no product code.
- **Every subscription state maps to a defined access tier.** Trialing, active, past-due (bounded grace), canceled-until-period-end, unpaid, incomplete, paused — each state the provider can report has a stated behaviour; unknown or missing state gets the safe one. Trials are bounded, one per tenant, not resettable by re-checkout.
- **Webhooks are the sync spine.** Signature-verified before anything parses, idempotent by provider event id, safe under retries and out-of-order delivery, logged, tenant-resolved — and backed by a reconciliation sweep, because webhooks alone always eventually miss one.
- **Sessions are server-made; money is exact; card data never lands.** Checkout and portal sessions are created server-side, for the caller's own tenant only. Amounts are integer minor units with an ISO currency. The app stores provider ids and receipt metadata — never card numbers or raw payment details.
- **Billing mutations are permissioned and audited.** `billing:read` / `billing:manage`, checked server-side; every subscription, plan, and payment state change lands in the audit trail. Denied entitlement checks and limit blocks emit structured (redacted) logs so pricing-support questions are answerable.
- **Ship behind the default-off flag with a stub gateway.** Billing spends real money — base *Integrations* gating applies in full: a default-off validated-config boolean routes the provider gateway to a stub sink until flipped per environment, and flipping it back is the rollback.

## Binds to a stack

The active pack names: the payment provider for its market and the SDK/adapter home (a repo-ring adapter behind the domain's billing gateway port); the webhook verification seam (raw-body access + signature check at the controller edge); the stub gateway sink; the background-job runner (reconciliation sweep, usage-period rollover, trial-expiry handling); and the validated-config home for the provider secret key and webhook signing secret. Suggested bindings for each stack pack this template ships are pre-written in [`bindings.md`](bindings.md) — copy the active pack's entry into its `backend.md` add-on-bindings section at adoption.

## Adopting this add-on

Self-contained by design — nothing outside `add-ons/saas-billing/` references it until you adopt it. At Day-1 (or later adoption): keep this directory; copy the active stack pack's entry from [`bindings.md`](bindings.md) into that pack's `backend.md`; and treat the specs under this add-on's `specs/` as the program's feature specs (move them into the repo's top-level `specs/` then if you prefer one spec home — the cross-references use bare sibling filenames and survive the move).

## Interactions

- **Base *Integrations* + *Security baseline*** — the provider is an untrusted, unreliable external integration; all rules (idempotency, classified failures, unclear-outcomes-never-success, ownership checks, default-off gating) apply in full.
- **Base *Audit trail* + *Configuration*** — billing state changes go through the shared `record()`; provider keys and the billing flag are validated env config, passed inward as values.
- **`db/CLAUDE.md`** — money in exact types; unique constraints encode the billing invariants (one customer per tenant per provider, one active subscription per tenant, unique provider event id); reversible migrations.
- **multi-tenancy** — supplies the organisation every billing row hangs off; adopt it (or another organisation model, e.g. enterprise-compliance's) before this add-on — without one there is no tenant to bill. Its stored organisation `plan` key is superseded by this add-on's derived entitlements.
- **enterprise-compliance** — `billing:read`/`billing:manage` join its RBAC catalog (Owner and Admin hold both); a "billing manager" is a custom role holding them; billing audit events use its envelope. Adopt both for compliance-grade billing evidence.
- **test-mode** — the stub gateway doubles as the test-mode sink, so checkout, portal, and webhook flows stay walkable without a live provider.
- **llm-calls** — its per-tenant cost/usage monitoring can feed the usage-metering counters, making AI usage a billable, quota-enforced metric.

## Specification map

The program index — shared conventions (domain model, status→access table, entitlement keys, permissions, canonical routes and tables) and phasing — is `specs/program-index.md`. Per-area specs:

| Area | Spec |
|---|---|
| Plan catalog & entitlements | `specs/plans-entitlements.md` |
| Subscription lifecycle, trials & access states | `specs/subscription-lifecycle.md` |
| Checkout | `specs/checkout.md` |
| Customer portal & plan changes | `specs/portal-plan-changes.md` |
| Provider webhooks & state sync | `specs/webhooks-sync.md` |
| Seat-based billing | `specs/seats.md` |
| Usage metering & quotas | `specs/usage-quotas.md` |
| Billing settings & invoices UI | `specs/settings-invoices.md` |
