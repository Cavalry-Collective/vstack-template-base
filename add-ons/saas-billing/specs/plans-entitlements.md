# Plan catalog & entitlements — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make every sellable tier pure data — key, prices, entitlements, trial policy — and route every paid-capability decision through one `EntitlementChecker` port, so that changing what a plan grants is a data change, not a deploy, and no module outside billing ever interprets plans or subscriptions.

## Product requirements

1. Plans are data rows: `key`, `name`, `description`, display order, trial policy (`trial_days`, nullable = no trial), `is_default` (the Free plan), active/archived status. No plan-specific behaviour in code.
2. Each plan carries prices per interval (`month` | `year`): integer minor units plus ISO-4217 currency (index data-model rule), a provider price mapping (`provider_price_id`, nullable for Free), and a `per_seat` flag whose billing semantics are owned by `seats.md`.
3. Entitlements follow the index key format exactly: `feature.<name>` (granted by row presence) and `limit.<name>` (integer cap; null = unlimited).
4. Entitlement keys live in one catalog module (enum-like list). Referencing a key outside the catalog throws — a programming error surfaced in tests, never a runtime client error.
5. The Free plan is a real seeded `plans` row (`is_default` = true, zero-price rows, no provider ids), so fail-closed access always resolves to defined entitlements (index convention).
6. Archived plans are not purchasable; existing subscriptions keep them, and the resolver still resolves an archived plan's entitlements for its subscribers.
7. The catalog changes only by operator data change: launch rows arrive via the `db/` seed plus an operator runbook (provider price mapping included); plan authoring has no product UI (index Out of scope). Initial catalog rows are seed/operator data, not a migration backfill.
8. `GET …/billing/plans` returns active plans with prices and entitlements for the plan picker. **Decision: any authenticated member, no permission** — catalog list prices are public marketing pricing, distinct from the org's billed amounts, which stay behind `billing:read` (index Permissions).
9. `GET …/billing/entitlements` returns the org's effective entitlements and access tier to any authenticated member — a rendering hint only; the server-side resolver stays authoritative (index Permissions).
10. Every backend paid-feature or limit gate calls the `EntitlementChecker` port; a denied check emits the structured `warn` log (organisation id, key, limit, requested — index convention). Denials are logs, not audit events.
11. Resolution may be cached per organisation with synchronous invalidation on subscription change, TTL backstop ≤ 5 minutes — mirroring the RBAC permission-cache pattern where enterprise-compliance is adopted (`add-ons/enterprise-compliance/specs/rbac.md`).

### Entitlement-key catalog (working set)

The catalog module is the single source of valid keys; `plan_entitlements.entitlement_key` is validated against it on write, and the resolver throws on any key outside it (req. 4). Working examples from the index — the launch set is an open question:

| Key | Kind | Gates |
|---|---|---|
| `feature.api_access` | feature | API key usage |
| `feature.exports` | feature | Data exports (the P1 reference gate) |
| `limit.members` | limit | Active member count — counting rule owned by `seats.md` |
| `limit.projects` | limit | Project count |
| `limit.api_calls` | limit | API calls per period — metering owned by `usage-quotas.md` |

## User flows

**F1 — Plan picker loads the catalog (P1).** 1. A member opens the upgrade/plan-picker surface (screen owned by `settings-invoices.md` / `checkout.md`). 2. The SPA calls `GET …/billing/plans`. 3. Active plans render ordered by `display_order` with prices per interval and entitlement highlights; archived plans never appear.

**F2 — Paid feature denied on the Free tier (P1).** 1. A free-tier member calls a gated endpoint. 2. The endpoint's `assertCanUseFeature` resolves the org's tier → Free plan → key absent. 3. `403 FEATURE_NOT_AVAILABLE` with the feature key in `error.details`; the warn log is emitted. 4. The UI renders its access-restricted state with the upgrade path.

**F3 — Limit reached (P1).** 1. An action would exceed a `limit.<name>` cap. 2. `assertWithinLimit(organisationId, limitKey, requested)` fails. 3. `403 PLAN_LIMIT_REACHED` with limit key, cap, and requested value in `error.details`; warn log emitted.

**F4 — Operator moves a feature between plans (P2).** 1. Operator runs the runbook data change updating `plan_entitlements` rows. 2. The runbook path records the audit event and invalidates affected orgs' resolver cache entries (or waits out the TTL backstop). 3. Access flips with no code change or deploy.

## Admin capabilities

Org admins have no catalog administration — they consume the catalog through checkout and plan changes (sibling specs). Operator (runbook, not product UI): create a plan, map provider prices, edit entitlement rows, archive a plan. Each runbook action records its audit event (table below).

## API behavior

All under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply. Both responses are bounded by catalog size — no pagination.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/plans` | Active plan catalog for the picker | any authenticated member (req. 8) | `data[]`: `{ key, name, description, displayOrder, trialDays, isDefault, prices[{ interval, unitAmountMinor, currency, perSeat }], entitlements[{ key, limitValue }] }` |
| `GET …/entitlements` | Org's effective entitlements | any authenticated member (req. 9) | `{ accessTier, features[], limits: { "<limit key>": <cap or null> } }` |

Neither endpoint mutates; with `BILLING_ENABLED=false` both still serve (everything resolves to the Free plan — index Config & rollout).

## Data model changes

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs indexed; invariants pinned by the index):

- **`plans`** — `id` (PK); `key` (stable slug, unique); `name`; `description`; `display_order` (integer); `trial_days` (integer, nullable); `is_default` (boolean); `status` (`active` | `archived`); `created_at`; `updated_at`.
- **`plan_prices`** — `id` (PK); `plan_id` (FK, indexed); `interval` (`month` | `year`); `unit_amount_minor` (integer); `currency` (ISO-4217); `provider_price_id` (nullable — Free has none); `per_seat` (boolean; consumed by `seats.md`); `created_at`; `updated_at`. Unique `(plan_id, interval, currency)`.
- **`plan_entitlements`** — `id` (PK); `plan_id` (FK, indexed); `entitlement_key` (validated against the catalog module on write); `limit_value` (integer, nullable = unlimited; null for `feature.*` rows); `created_at`; `updated_at`. Unique `(plan_id, entitlement_key)`.

Seeding: the Free plan row plus launch plans/prices/entitlements land via the `db/` seed and the operator runbook — a data change, not a migration backfill (req. 7).

## Backend implementation requirements

- Lives in the `billing` module's plan-catalog area (domain: plan/entitlement entities, the entitlement-key catalog module, the `EntitlementChecker` port; service: resolution + read use cases; repo: adapters; controller: the two routes).
- **`EntitlementChecker` port** (index Entitlements): `canUseFeature(organisationId, featureKey)`, `getPlanLimit(organisationId, limitKey)`, `assertCanUseFeature(…)`, `assertWithinLimit(organisationId, limitKey, requested)`. The only entry point for access decisions outside the billing module.
- **Resolution**: access tier from the derivation owned by `subscription-lifecycle.md` → `paid` resolves the subscription's plan, `free` resolves the Free (`is_default`) plan → key lookup in that plan's entitlement rows. Unknown key → throw (req. 4).
- **Cache**: per-organisation resolved entitlements may be cached (store supplied by the active stack pack); subscription-change use cases (the sync site in `webhooks-sync.md`) invalidate synchronously after commit; TTL backstop ≤ 5 minutes; misses fall through to the DB.
- **Enforcement example (P1)**: one representative paid feature endpoint is gated via `assertCanUseFeature` as the reference pattern (working key: `feature.exports` or the app's equivalent); further gates follow it.
- **Error semantics owned here**: `FEATURE_NOT_AVAILABLE` and `PLAN_LIMIT_REACHED` are raised by the assert helpers (shared codes — this spec pins their semantics); `PLAN_NOT_FOUND` is returned by any endpoint given a plan key/id that matches no catalog row. Rejecting a *known but not purchasable* plan (Free, archived) is `409 PLAN_NOT_PURCHASABLE`, owned by `checkout.md` and reused by the portal spec.
- No background jobs.

## Audit log events

Catalog changes are operator actions; the runbook path emits via the shared `record()` in the service ring (index Audit event scheme). Entitlement denials are warn logs, never audit (index rule).

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `billing.plan.created` | Operator adds a plan (with prices/entitlements) | `after`: plan key, prices (minor units), entitlement keys |
| `billing.plan.updated` | Operator changes display data, prices, or entitlement rows | `before`/`after`: changed fields / entitlement diff |
| `billing.plan.archived` | Operator archives a plan | `before`: plan key, status |

## Security considerations

- The server-side resolver is authoritative; `GET …/entitlements` is a rendering hint only — a hidden control's endpoint still asserts through the port.
- Catalog prices are deliberately public (req. 8); nothing org-specific leaks through `GET …/plans` — it is catalog data only.
- Fail-closed behaviour is inherited from the access derivation (`subscription-lifecycle.md`); a resolver failure to find a plan resolves free, never paid.
- "Archived = not purchasable" is enforced at checkout time by `checkout.md` (`409 PLAN_NOT_PURCHASABLE`); this spec only guarantees archived plans never appear in `GET …/plans`.
- All queries org-scoped where org-scoped data is touched; entitlement reads never expose another organisation's tier.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Gated feature not granted by the effective plan | 403 | `FEATURE_NOT_AVAILABLE` (feature key in `error.details`) |
| Action exceeds a plan limit | 403 | `PLAN_LIMIT_REACHED` (limit key, cap, requested in `error.details`) |
| Plan key/id matches no catalog row | 404 | `PLAN_NOT_FOUND` (known-but-not-purchasable: `PLAN_NOT_PURCHASABLE`, owned by `checkout.md`) |
| Code references a key outside the catalog module | 500 | none — thrown programming error; caught by tests, never a client contract |

## User stories & acceptance criteria

**S1 (P1)** — As the product team, I want plans as seeded data with a real Free plan, so that tiers exist before any payment flow does.

- [ ] Migrations create `plans`, `plan_prices`, `plan_entitlements` with the index's invariants. *Verify: migration up/down/up round-trip on a scratch DB per `db/CLAUDE.md`, asserting the unique constraints.*
- [ ] The seed creates the Free plan (`is_default`, zero price, no provider ids) plus launch plans. *Verify: run the seed, assert the Free row and that exactly one `is_default` plan exists.*
- [ ] Archived plans keep their rows and entitlements for existing subscribers. *Verify: integration test — archive a plan, resolver still returns its entitlements for a subscribed org.*
- [ ] Entitlement rows are validated against the catalog module on write. *Verify: repo integration test — inserting a row with a key outside the catalog is rejected.*

**S2 (P1)** — As the backend, I want one entitlement resolver enforcing features and limits, so that no paid capability is reachable outside it.

- [ ] All four `EntitlementChecker` helpers resolve tier → plan → key correctly for paid and free orgs. *Verify: use-case tests with in-memory port fakes covering paid, free, and no-subscription orgs per helper.*
- [ ] An unknown entitlement key throws. *Verify: unit test asserting `canUseFeature(org, "feature.nonexistent")` throws, not returns false.*
- [ ] The representative gated endpoint denies free-tier access with the shared codes and emits the warn log. *Verify: integration test — free org hits the gated endpoint, asserts `403 FEATURE_NOT_AVAILABLE` and the structured warn log line (org id, key).*
- [ ] Cache invalidation on subscription change is synchronous. *Verify: use-case test — resolve (cache warm), apply a subscription change through the sync path, resolve again, assert the new tier without waiting for TTL.*

**S3 (P1)** — As a member, I want the plan catalog and my org's entitlements readable, so that the UI can render pricing and gate controls.

- [ ] `GET …/plans` returns active plans ordered by `display_order` with prices and entitlements; archived plans excluded. *Verify: contract test seeding active + archived plans and asserting the response set and shape.*
- [ ] `GET …/entitlements` returns access tier, features, and limits for the caller's org; any authenticated member may call both. *Verify: contract tests — member without `billing:read` gets `200` on both; unauthenticated gets `401`.*
- [ ] The SPA hides gated controls the org's entitlements don't grant, with the server still authoritative. *Verify: screen check — free-org member sees the upgrade/access-restricted state; direct endpoint call still returns `403 FEATURE_NOT_AVAILABLE`.*
- [ ] With `BILLING_ENABLED=false`, both reads still serve and every org resolves to the Free plan. *Verify: use-case tests with the flag off asserting `200` responses and `accessTier: "free"` (index Config & rollout).*

**S4 (P2)** — As an operator, I want to move a feature between plans as a data change, so that packaging changes never need a deploy.

- [ ] Moving a `feature.<name>` row between plans flips access after cache invalidation, with no code change. *Verify: integration test — change the `plan_entitlements` row via the runbook path, assert no source change needed, access flips after synchronous invalidation.*
- [ ] The runbook path records `billing.plan.updated` with the entitlement diff. *Verify: assert the audit row after the change above.*

## UX & non-functional notes

- Screens consuming these reads: plan picker and gated-control rendering (owned by `settings-invoices.md` and `checkout.md`); each handles loading/error/empty/success per `apps/frontend/CLAUDE.md`. No `design/` mockups exist yet (index open question) — required before initial build.
- Plan `name`/`description` are catalog data rendered as-is; UI chrome strings around them go through the i18n dictionaries as usual.
- The resolver sits on hot request paths — O(set/map lookup) once resolved; no per-request DB scan when the cache is warm (mirrors the RBAC guard budget).

## Out of scope

- Plan authoring/product UI (index program-wide Out of scope — seed + runbook only).
- Coupons/promotions and multi-currency localisation beyond each price row's currency (index).
- Per-plan overage pricing — overage rules belong to `usage-quotas.md`.
- Seat counting and per-seat quantity semantics — `seats.md` consumes `per_seat`.
- Per-organisation entitlement overrides (see Open questions).

## Open questions

- Concrete launch entitlement values per plan (which features/limits at which tier) — owner: product; needed before checkout P1 lands (index open question).
- Do Business/Enterprise tiers need custom per-organisation entitlement overrides? Default **no** (YAGNI — plan-level rows only); flagged here so the data model isn't silently extended if a deal demands it.
