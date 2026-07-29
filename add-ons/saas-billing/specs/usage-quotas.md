# Usage metering & quotas — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

The app tracks flow-metric consumption per organisation per billing period in one race-safe `usage_records` table. Plan caps are enforced through the shared `assertWithinLimit` helper before the guarded action runs. Periods roll lazily, so quota enforcement is one pattern everywhere and a metering write never blocks a user's work.

## Scope & ownership

- **Owns:** the `usage_records` table, the flow-limit semantics and the metered flag's meaning, the period-derivation helper, `recordUsage(…)`, and `GET …/billing/usage`.
- **Consumes:** the entitlement catalog and `assertWithinLimit` (plans-entitlements.md); billing-period dates (subscription-lifecycle.md); plan-change application via the sync path (webhooks-sync.md). **Used by:** feature use cases metering flow limits; portal-plan-changes.md (downgrade limit fit); settings-invoices.md (the usage card renders this spec's data contract).
- **Phases:** P2 = recording, enforcement, the usage read (S1–S4). P3 = soft-limit notifications and provider overage (S5; reqs. 12–13, seams only).

## User stories & acceptance criteria

**S1 (P2)** — As the backend, I want flow usage recorded atomically per organisation, metric, and period, so that concurrent activity converges to an exact count.

- [ ] `recordUsage` maintains exactly one row per `(organisation_id, metric_key, period_start)` and increments atomically. *Verify: integration test firing N concurrent `recordUsage` calls for one org+metric, asserting one row and `used` equal to the exact sum.*
- [ ] A failed metering write never fails the guarded request. *Verify: use-case test with a failing repo fake — the action's use case still succeeds and the single `error` log line (org id, metric key) is asserted.*
- [ ] An unknown or non-metered key throws. *Verify: unit test asserting `recordUsage(org, "limit.members", 1)` (stock, unmetered) throws.*
- [ ] Free organisations meter against UTC calendar months. *Verify: unit test of the period-derivation helper across a month boundary with no subscription row, plus the concurrent-increment test run for a free org.*

**S2 (P2)** — As the platform, I want hard limits to block the guarded action with actionable details and reset naturally next period, so that caps are enforceable without a reset job.

- [ ] At the cap, the guarded action returns `403 PLAN_LIMIT_REACHED` with key, cap, used, and requested, and emits the denial warn log. *Verify: integration test driving a gated endpoint to its cap and asserting the error details and log line.*
- [ ] The same action passes again in the next period with a fresh counter, and the old period's row is retained. *Verify: integration test crossing a period boundary with an injected clock — the blocked action passes, a new row exists, the old row is unchanged.*
- [ ] A null (unlimited) cap never blocks and never creates denial logs. *Verify: use-case test with an unlimited plan asserting pass-through at arbitrary `used`.*

**S3 (P2)** — As the platform, I want usage to survive plan changes mid-period, so that upgrades take effect immediately without forgiving or forfeiting consumption.

- [ ] A cap change applies immediately against the same period's counter — no reset, no new row. *Verify: integration test — reach a lower plan's cap, upgrade mid-period through the sync apply path (webhooks-sync.md), assert the previously blocked action now passes and `usage_records` is unchanged by the plan change.*
- [ ] A mid-period downgrade below current usage blocks further consumption but never errors retroactively. *Verify: same test shape — downgrade, assert the next `assertWithinLimit` fails with the new cap and prior state is intact.*
- [ ] A first subscription (free → paid) starts a fresh billing-period row; the calendar-month row remains history (F5). *Verify: integration test — meter as free, complete the stub checkout, assert the next recording lands in a new row keyed by the subscription period.*

**S4 (P2)** — As a member, I want current-period usage readable, so that the billing settings card can show consumption against limits honestly.

- [ ] `GET …/usage` returns the period bounds and per-metric `used`/`limit`/`thresholdReached` for the caller's organisation, for any authenticated member; cross-tenant ids are `404`. *Verify: contract tests — member without `billing:read` gets `200`; other org's id gets `404`; unlimited metric returns `limit: null`.*
- [ ] `used` above `limit` is reported honestly (overshoot or mid-period downgrade, req. 11). *Verify: contract test seeding `used` > cap and asserting the values come back unclamped.*
- [ ] The settings usage card renders from this contract, including unlimited and near-limit states. *Verify: screen check of the usage card (screen: settings-invoices.md) across its four data states plus the unlimited and `thresholdReached` renderings.*

**S5 (P3)** — As the product, I want soft-limit notifications and provider overage reporting designed on named seams, so that they can land without reworking metering.

- [ ] The scheduled soft-limit sweep, its notification hook, and `BillingGateway.reportUsage` are specified in a revision of this spec before any build. *Verify: spec revision exists; no code lands under this story until it does.*

## Requirements

Core (P2):
1. **Metered metrics** are the subset of `limit.<name>` entitlement keys flagged **metered** in the entitlement catalog module. The catalog itself is owned by plans-entitlements.md; this spec owns what the metered flag means.
2. Two limit kinds apply program-wide: **stock** limits count live records at the mutation (members, projects — exemplar: seats.md); **flow** limits meter consumption over a billing period (API calls, exports, AI tokens) in `usage_records`. Metered ⇒ flow. This spec owns flow and changes nothing about stock enforcement.
3. **Period definition:** for an organisation with a non-terminal subscription, the subscription's current billing period (subscription-lifecycle.md); for a free organisation, UTC calendar months. One domain helper derives `(period_start, period_end)`; no other code derives periods.
4. **Rollover is lazy.** The recording path upserts the row for the *current* period; a new period simply means a new row on first use. Old rows remain as history. No scheduled reset job exists; the only scheduled work in this area is the soft-limit notification sweep (req. 12).
5. **Recording API (internal):** `recordUsage(organisationId, metricKey, amount, context)` — called by feature use cases *after* the guarded action succeeds; an atomic upsert-increment on the current period's row.
6. **Recording never blocks the user action.** A failed metering write logs an `error` and the request still succeeds (Notes & decisions).
7. **Enforcement:** `assertWithinLimit(organisationId, metricKey, requested)` (an `EntitlementChecker` helper — port owned by plans-entitlements.md) is called *before* the expensive action. For flow metrics it reads the current-period row (absent = 0) plus the plan cap; `used + requested > cap` → `403 PLAN_LIMIT_REACHED` with the key, cap, used, and requested in `error.details`, plus the structured denial `warn` log (index rule).
8. **Check-then-act race, accepted:** two concurrent requests may both pass at cap − 1 — a bounded overshoot for flow metrics (Notes & decisions). A metric that must never overshoot is not a flow metric; it uses the stock-limit pattern instead.
9. `GET …/billing/usage` is readable by **any authenticated member** (Notes & decisions). The settings page rendering it still gates on `billing:read` (settings-invoices.md).
10. Backend enforcement is authoritative; frontend usage counters are display only (index rule).
11. The read reports every metered key in the org's effective plan — zero-use metrics included, so the card has a defined row per metric — and reports `used` honestly even when it exceeds `limit` (accepted overshoot, or a mid-period downgrade).

Later phases (P3):
12. **Soft limits:** 80% and 100%-of-cap thresholds surface in `GET …/billing/usage` (`thresholdReached`) and feed a notification hook driven by a scheduled sweep — a named seam, gated on story S5.
13. **Overage:** metered overage is billed via provider usage records; when built, `BillingGateway` gains a `reportUsage` method (the seam, named now). Nothing in this spec implements overage.

## User flows

### F1 — Guarded action within limit (P2)

1. A feature use case calls `assertWithinLimit(org, metric, n)` before the expensive work; the check passes (`used + n ≤ cap`, or cap null = unlimited) and the action runs.
2. On success the use case calls `recordUsage(org, metric, n, context)` — one atomic upsert-increment. If the write fails, the error is logged and the request still succeeds (req. 6).

### F2 — Hard limit reached (P2)

1. `assertWithinLimit` finds `used + requested > cap`: `403 PLAN_LIMIT_REACHED` with key, cap, used, requested; the denial warn log is emitted.
2. The UI renders its at-limit state with the upgrade affordance (settings-invoices.md). In the next period the check reads a fresh (absent → 0) counter and passes again.

### F3 — Period rolls over, lazily (P2)

1. The billing period ends (subscription renewal, or a new UTC month for free orgs); nothing runs.
2. The next `recordUsage`/`assertWithinLimit` resolves the new current period; recording upserts a fresh row starting from the increment; the old row stays as history.

### F4 — Approaching the cap (P3)

1. The sweep finds organisations crossing 80% or 100% of a cap; the notification hook fires (named, not built — S5). `GET …/billing/usage` already reports `thresholdReached` for the settings card's near-limit banner.

### F5 — Free organisation subscribes mid-month (P2)

1. A free org meters against UTC calendar months (req. 3) with identical recording and enforcement; it then completes checkout (checkout.md), and a new subscription billing period begins.
2. The next check/recording resolves the new period definition and starts a fresh row; the calendar-month row is closed history. A new subscription is a genuine new period — distinct from a plan change within a running period (S3), which keeps the counter.

## API & permissions

Under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply. Bounded by the metered-metric count — no pagination.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/usage` | Current-period usage vs caps for every metered metric | any authenticated member (req. 9) | `{ periodStart, periodEnd, metrics: [{ key, used, limit, thresholdReached }] }` — `limit` null = unlimited; `thresholdReached` is the highest soft threshold crossed (null below 80%) |

- With `BILLING_ENABLED=false` the read still serves: caps resolve to the Free plan and the period is the UTC calendar month (index Config & rollout). No usage mutation surface exists — counters change only through feature use cases calling `recordUsage`; caps change with the plan (plans-entitlements.md, portal-plan-changes.md). This spec adds no permission keys; where enterprise-compliance is adopted, `billing:read`/`billing:manage` sit in its RBAC matrix per the index Permissions. No operator runbook; correcting a corrupted counter is a one-off data fix, not product UI.

## Data model

One new table (snake_case; reversible up/down migration per `db/CLAUDE.md`; UTC; indexed FKs; invariant pinned by the index). No backfill: the table starts empty and fills lazily, and stock limits never touch it (req. 2).

- **`usage_records`** — `id` (PK); `organisation_id` (FK, indexed); `metric_key` (validated against the catalog module's metered set on write); `period_start`; `period_end`; `used` (bigint, mutated only by atomic increments); `created_at`; `updated_at`. Unique `(organisation_id, metric_key, period_start)` — the upsert target for lazy rollover.

## Audit events

**None owned.** Routine metering emits no audit events — per-request volume, and an increment is not a billing state change in the index's audit sense. Blocked actions are covered by the structured denial `warn` log (index Entitlements rule); period rollover is implicit — no row, no event. Cap changes are audited by the specs that change plans (plans-entitlements.md, portal-plan-changes.md).

## Implementation notes

- The usage area lives in the `billing` module (domain: flow/stock kind semantics and the period-derivation helper; service: `recordUsage` and the read use case; repo: the upsert adapter; controller: the one route). No background jobs except the P3 soft-limit sweep (S5 — named, not built).
- **`recordUsage` is exposed to other modules through a shared port** (mirroring `EntitlementChecker`), so feature modules never import billing internals. Passing a key that is unknown or not flagged metered throws — a programming error surfaced in tests, never a runtime client error (catalog rule, plans spec). **Atomic upsert-increment:** one statement (insert-on-conflict-increment or the active stack pack's equivalent) so concurrent recordings converge exactly — the backend *Integrations* concurrency rule; never read-modify-write.
- **Failure isolation:** the recording boundary catches its own failures, logs once at `error` level with organisation id and metric key, and never propagates (req. 6). `context` carries structured-logging identifiers (actor, correlation id) — log identifiers, never payload contents (backend logging rule). All reads and writes are organisation-scoped; a cross-tenant organisation id in the path is `404` per the program's cross-cutting criterion 1.
- **`assertWithinLimit` flow branch:** resolve the cap through the plans spec's resolution (cached per its rules), read the current-period row, compare. Absent row = 0 used. Cap changes from plan changes apply immediately — the counter is period-keyed, not plan-keyed (story S3). Fail-closed is inherited: a missing subscription or unresolvable plan resolves to the Free plan's caps (index access table), never to unlimited.
- **`period_end` is stored denormalised** for the read response and history; the current-period lookup keys on the derivation helper's `period_start`. A subscription's period dates come from the lifecycle spec's row — never re-derived from provider data here. **Time is injected:** the period helper takes a clock, so period-boundary tests (S2, F5) run without waiting out real periods.

## Edge cases & errors

Enforcement errors surface on the guarded feature endpoints, not on the usage read itself:

| Scenario | HTTP | Code |
|---|---|---|
| Flow action would exceed the plan cap | 403 | `PLAN_LIMIT_REACHED` (shared — semantics owned by plans-entitlements.md; flow denials add `used` to `error.details`) |
| `recordUsage` called with an unknown / non-metered key | 500 | none — thrown programming error; caught by tests, never a client contract |
| Metering write fails after the guarded action succeeded | — | no client error; single `error` log (req. 6) |
| Organisation id not the caller's | 404 | base membership guard (program cross-cutting criterion 1) |
| Unauthenticated `GET …/usage` | 401 | base auth envelope |

## Notes & decisions

- **Metering loss over user-facing failure (req. 6):** blocking users on a metering write is not acceptable; losing an increment is. This is a deliberate exception to "don't hide errors": the failure model is explicit and the catch is confined to the recording boundary.
- **Bounded overshoot is accepted (req. 8):** the check-then-act race is tolerated because the atomic increment keeps the *record* accurate. The overshoot is a documented property, not a bug to fix later.
- **Any-member read (req. 9):** the usage response is a rendering hint carrying no amounts or invoice data, so the index's hint-read carve-out applies (amounts and invoices need `billing:read`), consistent with `GET …/billing/entitlements` and `GET …/billing/seats`.
- UX: the billing settings usage card — screen, copy, and near/at-limit banner wording — is owned by settings-invoices.md; this spec owns only the data contract behind it. Over-cap display (`used` > `limit`) is a designed state on the card, not an error. Performance: `recordUsage` sits on hot request paths — one statement, no read before write; `assertWithinLimit`'s flow branch is one indexed unique-key read plus the plans spec's cached cap resolution, and the read response is small enough to fetch alongside the settings page's other cards.

## Out of scope

- Stock-limit enforcement mechanics — seats.md is the exemplar; other stock limits follow it.
- Usage analytics, BI, or historical dashboards beyond the settings card — old `usage_records` rows are retained history, not a reporting product.
- Per-user usage attribution (metering is tenant-level only) and real-time streaming counters or push updates (the card reads on load).
- Request rate limiting (`429`) — a traffic concern, distinct from plan quotas; nothing here implements it.
- Building overage billing or the notification sweep (P3 seams named in reqs. 12–13; S5 gates them).

## Open questions

- Which metrics ship metered at launch (working examples: `limit.api_calls`, exports, AI tokens)? Owner: product; needed before the first flow gate lands.
- Retention window for old `usage_records` rows — indefinite history vs a pruning rule, and how that interacts with retention policies where enterprise-compliance is adopted (`add-ons/enterprise-compliance/specs/retention-deletion.md`). Default: keep indefinitely until data volume forces the question.
- Does AI-token metering (the llm-calls add-on, where adopted) land as a launch metric, and at what grain (tokens vs requests)? Owner: product + the add-on's binding.
