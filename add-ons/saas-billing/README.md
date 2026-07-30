# Add-on: SaaS billing

SaaS billing covers plans, checkout, subscriptions, invoices, trials, entitlements, seats, usage limits, and failed payments.

The payment provider processes payments and stores card data. The app owns the plan catalog, synchronised subscription state, and every access decision.

## Prerequisites

Adopt `multi-tenancy` or provide an equivalent organisation model. Attach billing to the organisation rather than an individual user.

## Common rules

- Use integer minor units and an ISO currency for money. Never receive or store card details.
- Keep provider calls behind the base default-off flag and route disabled or test-mode calls to a billing sink.
- Enforce `billing:read` and `billing:manage` on the server. Return `404` for another organisation's billing identifier.
- Audit plan, subscription, and payment-state changes.
- Log entitlement and limit denials with redacted structured fields.
- Never log checkout, portal, invoice, or receipt URLs.

Implement plans and entitlements first, then webhook synchronisation. Nothing else may grant paid access before both exist.

## Implementation areas

### Plans and entitlements

- Store plans as data with a stable key, display data, interval prices, provider mappings, entitlements, and trial policy.
- Seed Free as a real default plan with a zero price and no provider identifiers.
- Name entitlements `feature.<name>` and numeric limits `limit.<name>`. Keep all valid keys in one catalog.
- Use `null` for an unlimited numeric limit and treat an unknown key as a programming error.
- Keep archived plans for existing subscribers but prevent new purchases.
- Apply pricing and packaging changes through catalog data and provider synchronisation.
- Resolve every backend gate through one entitlement service. Do not branch product code on plan names.
- Let the UI mirror entitlements but never grant access.

### Webhooks and synchronisation

- Verify the provider signature against the raw body before parsing.
- Insert the provider event ID before processing. Treat a duplicate as a successful no-op.
- Resolve the organisation before applying the event.
- Treat subscription events as notifications and fetch current provider state before applying them.
- Use one synchronisation use case for webhooks, checkout verification, and reconciliation.
- Return success for duplicate, unsupported, and permanently unresolvable events.
- Return a server error only when retrying may succeed.
- Reconcile non-terminal subscriptions in bounded scheduled batches.
- Record skipped, failed, and drift-correcting events with their reason. Audit corrected state.

### Subscription lifecycle

- Allow at most one non-terminal subscription per organisation and enforce it with a database constraint.
- Validate status changes against an allowed-transition map.
- Derive access from synchronised subscription state. Do not store a separate access tier.
- Grant paid access for trialing, active, and past-due subscriptions inside the grace period.
- Resolve missing, unknown, unpaid, incomplete, paused, and expired state to Free.
- Configure `BILLING_PAST_DUE_GRACE_DAYS`, defaulting to seven days after the period end.
- Inject the clock into access and grace-period calculations.
- Schedule cancellation for period end, retain access until then, and make cancellation and resumption idempotent.
- Allow one trial per organisation and derive eligibility from subscription history.

### Checkout

- Create checkout sessions on the server from a plan key, interval, and permitted seat quantity.
- Resolve price, amount, currency, customer, and organisation on the server.
- Keep one customer per organisation and provider, and enforce uniqueness in the database.
- Reject Free or archived plans and organisations with a non-terminal subscription.
- Validate seat quantity with the shared seat-counting rule.
- Apply a trial only when the plan allows it and subscription history shows eligibility.
- Treat the success redirect as presentation only. Poll a server verification read and grant access only from synchronised state.

### Billing management

- Use the provider portal for payment methods, billing details, and invoices.
- Disable plan switching in the portal so commercial changes pass through app validation.
- Apply upgrades immediately with proration and schedule downgrades for period end.
- Make a plan change an idempotent full replacement and allow a scheduled downgrade to be cancelled.
- Reject a downgrade when current seats or usage exceed the target limits.
- List invoices from the provider instead of storing a local invoice table.
- Treat hosted invoice, checkout, and portal URLs as short-lived secrets. Return them only to the caller; do not persist or audit them.
- Render every billing state through one user-facing status map.
- Show upgrade controls only to users with `billing:manage`.

The status map must cover Free, trialing, renewing, canceling, payment problems inside and outside grace, paused, disabled billing, over-limit usage, and scheduled changes.

### Seats

- Define occupied seats as active members plus pending invitations that have not expired or been revoked.
- Use that definition for display, enforcement, checkout, downgrades, and provider quantity.
- Enforce the cap race-safely when inviting or reactivating. Make bulk invitations all-or-nothing.
- Never block member removal or invitation revocation.
- Accept confirmed billed quantity through synchronisation and correct drift during reconciliation.

### Usage and quotas

- Treat current record counts as stock limits and enforce them inside the guarded mutation.
- Treat per-period consumption as flow limits with one atomic counter per organisation, metric, and period.
- Check a flow cap before the action and increment after success.
- Let the action succeed if metering fails, then log the failure for reconciliation.
- Accept bounded concurrency overshoot for flow limits. Use a stock limit when overshoot is unacceptable.
- Create counters lazily, use UTC calendar months for Free, and keep the current counter across a mid-period plan change.
- Report actual usage even above the cap.

Return limit errors with the entitlement key, cap, current value, and requested value.

## Verify

Test that redirects and client flags cannot grant access, unknown state resolves to Free, and duplicate or out-of-order events cannot duplicate or regress state.

Also test checkout input ownership, single-trial enforcement, concurrent seat and stock limits, cross-organisation isolation, reconciliation, metering failure, and safe logging.

## Binds to a stack

The active stack pack identifies:

- the payment SDK and billing adapter;
- raw-body access and webhook verification;
- the disabled and test-mode sink;
- the job runner;
- validated provider, webhook, rollout, and grace-period configuration.

## Interactions

- **Base integrations:** apply idempotency, failure classification, ownership, rollout, and reconciliation rules.
- **Base security, audit, and configuration:** enforce permissions, use the shared audit path, and validate secrets and settings.
- **Database rules:** use exact money types, reversible migrations, and constraints for billing invariants.
- **multi-tenancy:** attach every billing record to its organisation.
- **enterprise-compliance:** add billing permissions to its catalog and use its audit envelope.
- **test-mode:** retain billing flows while routing provider calls to the sink.
- **llm-calls:** send eligible tenant-level AI usage to the billing meter.
