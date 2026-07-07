# Seat-based billing — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Make seats a single, enforced number: one counting rule shared by enforcement, display, and provider sync, so that seat-limited plans block over-invitation at the boundary and per-seat plans bill exactly the seats an organisation occupies — never a recomputed, drifting copy of either.

## Product requirements

1. Two seat models, both driven by plan data (plans-entitlements.md), no code fork per plan:
   - **Seat limits (P1)** — every plan carries `limit.members`; enforcement runs through the shared `EntitlementChecker.assertWithinLimit` at the invite and member-reactivation use cases.
   - **Per-seat billing (P2)** — plans whose price rows are `per_seat` bill quantity × unit price; the occupied count is synced to the provider as the subscription quantity.
2. **The seat-counting rule** (program default pinned by the index): occupied seats = active members + pending (non-expired, non-revoked) invites. Deactivated or removed members free their seat immediately.
3. The counting rule is **one domain function** used by enforcement, display (`GET …/billing/seats`), and quantity sync — never recomputed ad hoc.
4. Invite creation calls `assertWithinLimit('limit.members', occupied + 1)`; exceeding the cap returns `403 PLAN_LIMIT_REACHED` (shared code; `error.details` names the key, cap, and requested value) and emits the structured denial `warn` log (index: entitlements). Bulk invites validate the whole batch atomically — all-or-nothing, race-safe under concurrent invites (base *Integrations* concurrency).
5. Pending-invite lifecycle: expiry or revocation frees the seat; acceptance converts pending → active (net zero to the count).
6. **Included seats (P2)**: a plan may include N seats in its base price, with per-seat charges beyond the included count. The `included_seats` column belongs to the plans data model — plans-entitlements.md owns adding it when per-seat P2 lands (its P1 table list omits it deliberately). The semantic is pinned here: billed overage quantity = max(0, occupied − included).
7. Per-seat quantity sync (P2): on member add, member removal, invite creation, invite expiry/revocation in a per-seat organisation, a use case computes the new occupied count and calls `BillingGateway` to update the subscription quantity. Calls are debounced/coalesced — one provider call per burst of changes (within a use case, or a short window whose scheduling the active pack binds). The confirmed quantity arrives via webhook sync (webhooks-sync.md) and lands in `subscriptions.seat_quantity` (column owned by subscription-lifecycle.md).
8. Drift between the local occupied count and the billed `seat_quantity` is reconciled by the sweep (webhooks-sync.md), which triggers a corrective quantity update.
9. Downgrades: the target plan's seat limit is checked by portal-plan-changes.md (`DOWNGRADE_EXCEEDS_LIMITS`) using this spec's counting function.
10. Checkout: the initial `seatQuantity` is validated ≥ the occupied count — checkout.md calls this spec's function; the violation code `SEAT_QUANTITY_BELOW_OCCUPIED` is defined here (Error cases).
11. Removal is never blocked by billing: freeing seats (removing members, revoking invites) always succeeds; billing gates only the **add** paths.
12. Any authenticated member may read seat availability — inviting members needs it as a rendering hint, and the response carries counts, not amounts, so it sits with the index's effective-entitlements read rather than `billing:read`. Amount-bearing surfaces stay behind `billing:read` (settings-invoices.md).

## User flows

**F1 — Invite blocked at the seat limit (P1).** 1. A member with invite rights opens the invite dialog. 2. The dialog shows remaining seats from `GET …/billing/seats` before submission. 3. On submit at the limit, the backend returns `403 PLAN_LIMIT_REACHED` with key/cap/requested in `error.details`. 4. The UI explains the cap and — for holders of `billing:manage` — offers "manage billing"; for others it names who to ask.

**F2 — Freeing a seat (P1).** 1. An admin removes a member or revokes a pending invite (actions owned by the members module). 2. The occupied count drops immediately. 3. A previously blocked invite now succeeds; in a per-seat org, the quantity sync (F3) follows.

**F3 — Per-seat quantity sync (P2).** 1. A member change lands in a per-seat organisation. 2. The sync use case computes the new occupied count and calls `BillingGateway` (coalesced per burst). 3. The provider confirms via webhook; `subscriptions.seat_quantity` updates through the apply path; `billing.seats.updated` is recorded.

**F4 — Bulk invite at the boundary (P1).** 1. An admin submits a batch of invites. 2. The backend validates `occupied + batch ≤ limit` atomically. 3. A batch that would cross the cap is rejected whole — `403 PLAN_LIMIT_REACHED`, nothing persisted; the UI reports how many seats are free.

**F5 — Seat card in settings (P1).** 1. A member opens billing settings (screen owned by settings-invoices.md). 2. The seat card renders occupied / included / limit and the pending-invite share from `GET …/billing/seats`, with the standard four states.

## Admin capabilities

- View seat usage (occupied, included, limit, pending invites) — any authenticated member (req. 12); the settings screen itself is governed by settings-invoices.md.
- Free seats by removing members or revoking invites — those actions and their permissions belong to the members module; this spec never gates them (req. 11).
- Change the seat allowance by changing plan or quantity — portal-plan-changes.md.

## API behavior

Under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/billing/seats` | Seat availability for display and the invite dialog | any authenticated member (req. 12) | `{ occupied, included, limit, pendingInvites }` — `limit` null = unlimited; `included` 0 for flat plans; no amounts |

Enforcement itself has no endpoint — it runs inside the members module's invite/reactivation use cases via the billing module's ports. Quantity changes surface through `PUT …/billing/subscription` (portal-plan-changes.md; seat semantics here).

## Data model changes

None owned here. This spec defines behaviour over columns owned elsewhere:

- `plan_entitlements` (`limit.members`), `plan_prices.per_seat`, `plans.included_seats` — plans-entitlements.md.
- `subscriptions.seat_quantity` — subscription-lifecycle.md; written only by the webhook/sweep apply path.
- Member and invite tables (statuses, expiry) — the members module; this spec reads them through the counting function only.

## Backend implementation requirements

- The counting rule is a domain function in the `billing` module — `countOccupiedSeats(organisationId)` conceptually — the only implementation; enforcement, `GET …/billing/seats`, checkout validation, downgrade checks, and quantity sync all call it.
- Deactivated members do not count; **reactivation is an add path** and runs the same `assertWithinLimit` check as an invite (req. 1) — a deactivate/reactivate cycle cannot smuggle an org past its cap.
- **Cross-module boundary**: the members module calls the billing module's ports — `EntitlementChecker` plus a `SeatCounter` port (or the billing module's exported service) — never billing tables directly (base rule: cross-module via service/port). Symmetrically, the counting function reads member/invite state through a port the members module implements, not by importing its repo ring.
- **Race safety**: the invite use case counts and inserts in one transaction with a serialised check (lock or DB-level constraint per the active pack's `db.md`), so two concurrent invites cannot both pass at the last seat. Bulk invites validate `occupied + batch ≤ limit` atomically — all-or-nothing.
- **Quantity sync (P2)** is a service-ring use case triggered by member-change events; coalescing keeps it to one `BillingGateway` call per burst (mechanism named: a per-organisation debounce keyed on the use case; scheduling bound by the pack). The outbound call's return value is never written locally — confirmation arrives via the webhook apply path (index: provider boundary).
- Drift reconciliation rides the sweep (webhooks-sync.md): where billed `seat_quantity` ≠ current occupied count in a per-seat org, trigger a corrective quantity update through the same sync use case.
- Denied invites emit the structured denial `warn` log (organisation id, key, limit, requested — index rule), not an audit event; the denial is user-visible through the `403` response.
- With `BILLING_ENABLED=false`, seat limits still enforce against the Free plan's `limit.members` (entitlement checks run regardless; index: config & rollout); quantity sync routes to the stub sink.

## Audit log events

Via the shared `record()` in the service ring.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `billing.seats.updated` | A confirmed seat-quantity change lands in `subscriptions.seat_quantity` (webhook or sweep apply path) | `before`/`after` quantity, occupied count at trigger time |

Blocked invites are **not** audited — a denied entitlement check is the structured `warn` log per the index rule; member and invite mutations themselves are audited by the members module.

## Security considerations

- Enforcement is server-side in the use case; the invite dialog's remaining-seats read is a rendering hint only — hiding the button never replaces the check.
- `GET …/billing/seats` is organisation-scoped; a cross-tenant organisation id is `404` (program criterion 1). It exposes counts only — no amounts, no provider ids.
- The counting function is fail-closed by composition: no subscription resolves to the Free plan's `limit.members` (index: entitlements), so a missing billing row can never mean unlimited seats.
- Quantity-sync calls carry only the organisation's provider ids and the new quantity — no member PII crosses the provider boundary.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Invite/reactivation would exceed `limit.members` | 403 | `PLAN_LIMIT_REACHED` (shared; details name key, cap, requested) |
| Requested seat quantity below the occupied count (`PUT …/billing/subscription`, checkout `seatQuantity`) | 409 | `SEAT_QUANTITY_BELOW_OCCUPIED` (defined here; raised by the owning endpoints' specs) |
| Downgrade target's limit below occupied | 409 | `DOWNGRADE_EXCEEDS_LIMITS` — owned by portal-plan-changes.md |
| Missing permission on amount-bearing surfaces | 403 | `PERMISSION_DENIED` (shared) |
| Organisation id from another tenant on `GET …/billing/seats` | 404 | — (index cross-tenant rule) |

## User stories & acceptance criteria

**S1 (P1)** — As an organisation on a limited plan, I want invites blocked at the seat limit with an actionable message, so that we never exceed what the plan allows.

- [ ] An invite at the cap returns `403 PLAN_LIMIT_REACHED` with key, cap, and requested in `error.details`, and emits the denial `warn` log. *Verify: contract test on the invite endpoint at the limit, asserting response and log line.*
- [ ] Two concurrent invites at the last seat: exactly one succeeds. *Verify: integration test firing both in parallel — one `201`, one `403 PLAN_LIMIT_REACHED`.*
- [ ] A bulk invite that would cross the cap is rejected whole. *Verify: contract test — a batch of 3 with 2 seats free returns `403 PLAN_LIMIT_REACHED` and persists no invites.*
- [ ] The blocked state is actionable in the UI. *Verify: screen check — invite dialog at the limit shows the cap, "manage billing" for a `billing:manage` holder, and the named-contact fallback otherwise.*

**S2 (P1)** — As the platform, I want pending invites to consume seats and expiry/revocation to free them, so that the count reflects committed seats, not just accepted ones.

- [ ] A pending invite raises the occupied count by one; acceptance leaves it unchanged. *Verify: integration test asserting `GET …/billing/seats` before/after invite and after acceptance.*
- [ ] Expiring or revoking an invite frees the seat and unblocks the next invite. *Verify: integration test — fill the limit with a pending invite, revoke it, assert the next invite returns `201`.*

**S3 (P1)** — As a member, I want the settings seat card to show occupied / included / limit, so that seat pressure is visible before it blocks anyone.

- [ ] `GET …/billing/seats` returns `{ occupied, included, limit, pendingInvites }` consistent with the counting rule. *Verify: contract test across member/invite fixtures.*
- [ ] Any authenticated member may read it; cross-tenant ids are `404`. *Verify: contract tests — a member without `billing:read` gets `200`; another organisation's id gets `404`.*
- [ ] The seat card renders the four states (loading / error / empty-unlimited / success). *Verify: screen check on the billing settings seat card, forcing each state.*

**S4 (P2)** — As a per-seat organisation, I want the billed quantity to follow member changes automatically, so that we pay for exactly the seats we occupy.

- [ ] A member add/remove triggers one coalesced `BillingGateway` quantity call; the confirmed quantity lands in `subscriptions.seat_quantity` via the webhook apply path and emits `billing.seats.updated`. *Verify: integration test through the apply path (webhooks-sync.md), asserting one outbound call per burst, the column value, and the audit row.*
- [ ] The local row is never updated from the outbound call's return value. *Verify: use-case test with the webhook withheld — `seat_quantity` unchanged until the event applies.*

**S5 (P2)** — As an operator, I want billed-quantity drift corrected automatically, so that a missed confirmation never leaves an org billed for the wrong seat count.

- [ ] Forced drift between occupied count and `seat_quantity` is corrected by the sweep. *Verify: integration test — set `seat_quantity` off by one, run the sweep, assert a corrective sync call and the converged value.*

## UX & non-functional notes

- The invite dialog surfaces remaining seats **before** submission via `GET …/billing/seats`; at the limit it renders the permission-aware blocked state (F1) per the frontend contract's designed-empty rule — copy in the i18n dictionaries, key parity maintained.
- The seat card distinguishes pending invites from active members ("8 of 10 seats — 2 pending invites") so a full-looking org can see which seats are reclaimable without accepting anything.
- No `design/` mockup exists for the seat card or the at-limit invite dialog; per the spec convention they must exist before the initial build (listed with the index's mockup open question).
- The seats read sits on the invite-dialog open path — one cheap counting query; no provider call at read time.
- Seat changes must never make member removal feel gated: freeing actions give immediate feedback; any billing consequence (F3) is asynchronous and invisible to the removing admin.
- Where enterprise-compliance is adopted, `billing:manage` resolution follows its RBAC matrix (index: permissions); the invite dialog's "who to ask" fallback derives from roles holding it.

## Out of scope

- Role-based seat classes (e.g. read-only members not consuming seats) — default: every member consumes a seat; revisit as an open question.
- Guest or external-collaborator concepts and their seat treatment.
- Invite mechanics themselves — expiry windows, resend, acceptance flow — the members module owns them; this spec only counts and gates.
- Proration of mid-period quantity changes — provider behaviour surfaced by portal-plan-changes.md.
- Seat reservations or holds beyond the pending-invite window — a seat is occupied or free, nothing in between.

## Open questions

- Do read-only members consume seats? Program default: yes (simplest honest rule); owner: product, before per-seat P2.
- Invite expiry window — owned by the members module, but it bounds how long a pending invite holds a seat; confirm the default with product.
- Hybrid plans: beyond `included_seats`, is overage billed per seat or blocked at the limit? Default pinned here: `per_seat` plans bill overage, flat plans block at `limit.members`; owner: product before per-seat P2.
