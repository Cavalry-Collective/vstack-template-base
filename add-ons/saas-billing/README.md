# Add-on: saas-billing

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

Subscription billing as an architecture layer: data-defined plans and prices, checkout and payment, renewal on monthly or yearly intervals, invoices, trials, and failed-payment handling — built so pricing changes are data changes, not rewrites. Seat and usage limits are the supporting enforcement areas that keep plan access honest. The payment provider moves the money and hosts the card data; the app owns the billing model and every access decision.

## Adoption
At Day-1 (or later adoption), beyond keeping this directory:
1. Copy the active stack pack's entry from [`bindings.md`](bindings.md) into that pack's `backend.md`, then delete `bindings.md` — the pack appendix is the binding's only home from then on.
2. Treat the specs under this add-on's `specs/` as the program's feature specs, written to the repo's spec-first conventions (`specs/README.md`). Move them into the top-level `specs/` if you prefer one spec home — the cross-references use bare sibling filenames and survive the move.

## Approach

- **The provider processes payments; the backend decides access.** Local, webhook-synchronised billing state is the single source of truth for paid access. A success redirect, a frontend flag, or an unverified callback never grants access; missing or ambiguous billing data **fails closed** to the free tier.
- **Plans are data; features move between plans.** A plan is a row carrying prices and entitlement keys — never an enum branched on in code. Repricing, a new tier, or moving a feature between plans is a data change plus provider sync, no product code.
- **Every subscription state maps to a defined access tier.** Trialing, active, past-due (bounded grace), canceled-until-period-end, unpaid, incomplete, paused — each state the provider can report has a stated behaviour; unknown or missing state gets the safe one. Trials are bounded, one per tenant, not resettable by re-checkout.
- **Webhooks are the sync spine.** Signature-verified before anything parses, idempotent by provider event id, safe under retries and out-of-order delivery, logged, tenant-resolved — and backed by a reconciliation sweep, because webhooks alone always eventually miss one.
- **Sessions are server-made; money is exact; card data never lands.** Checkout and portal sessions are created server-side, for the caller's own tenant only. Amounts are integer minor units with an ISO currency. The app stores provider ids and receipt metadata — never card numbers or raw payment details.
- **Entitlements are central, not scattered.** Every feature gate, seat limit, and usage quota goes through one resolver (`canUseFeature` / `getPlanLimit` / `assertCanUseFeature` / `assertWithinLimit`), enforced in the backend; the UI only mirrors it. A plan-name check in product code is the defect this add-on exists to prevent.
- **Billing is tenant-scoped, permissioned, and audited.** Customer, subscription, plan, seats, usage, and invoices all attach to the organisation, never the individual user — personal billing is a deliberate product decision, not a default. `billing:read` / `billing:manage` are checked server-side; every subscription, plan, and payment state change lands in the audit trail, and denied entitlement checks and limit blocks emit structured (redacted) logs so pricing-support questions are answerable.
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

## Specs
The program index — shared conventions (domain model, status→access table, entitlement keys, permissions, canonical routes and tables) and phasing — is `specs/program-index.md`. Per-area specs:

| Area | Spec |
|---|---|
| Plan catalog & entitlements | `specs/plans-entitlements.md` |
| Subscription lifecycle, trials & access states | `specs/subscription-lifecycle.md` |
| Checkout | `specs/checkout.md` |
| Customer portal & plan changes | `specs/portal-plan-changes.md` |
| Provider webhooks & state sync | `specs/webhooks-sync.md` |
| Billing settings & invoices UI | `specs/settings-invoices.md` |
| Seat-based billing | `specs/seats.md` |
| Usage metering & quotas | `specs/usage-quotas.md` |
