# Billing settings & invoices UI — SaaS billing

> Part of the saas-billing program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Every organisation gets one billing settings page that shows its true state: plan, status, seats, usage, invoices, and every edge state, phrased through a single status→copy map. One frontend billing slice (store / services / organisms) renders gating hints everywhere while the server stays authoritative. This spec owns all user-facing billing copy.

## Scope & ownership

- **Owns:** `GET …/billing/invoices` and the invoice DTO, the billing settings page and its route/nav entry, the status → copy map, every user-facing billing string (`billing.*` i18n keys), and the frontend billing slice (`store/billing`, `services/billing`, `components/organisms/billing/*`).
- **Consumes:** every sibling read and mutation the page surfaces — subscription state (subscription-lifecycle.md), plans and entitlements (plans-entitlements.md), checkout (checkout.md), portal and plan changes (portal-plan-changes.md), seats (seats.md), usage (usage-quotas.md); `BillingGateway.listInvoices` and `billing_customers` (checkout.md). **Used by:** every screen rendering a locked-feature upgrade affordance from `store/billing`.
- **Phases:** P1 = the settings page, copy map, and upgrade path (S1–S2). P2 = invoices, payment-issue recovery, and paywall affordances (S3–S5).

## User stories & acceptance criteria

**S1 (P1)** — As a member, I want the settings page to show my organisation's plan, status, and renewal truthfully in every state, so that billing is never a surprise.

- [ ] Every copy-map row renders its badge and sentence; no raw provider status ever appears. *Verify: component state walk of CurrentPlanCard across all ten map rows, asserting badge label and sentence per row.*
- [ ] Each card handles loading/error/empty/success; a failed card shows its own error + retry without failing the page. *Verify: screen check forcing all four states per card, including one card failing while siblings succeed.*
- [ ] All billing strings are i18n keys named by meaning, present in every language. *Verify: the CI i18n key-parity check passes over the new `billing.*` keys.*

**S2 (P1)** — As a `billing:manage` member of a free organisation, I want an upgrade path from the settings page, so that subscribing starts where billing lives.

- [ ] The free state shows the PlanPicker with Free marked current, the interval toggle stating the annual saving, and "no invoices yet". *Verify: screen check of the free-org state.*
- [ ] The upgrade CTA walks to checkout and back, and the page reflects the paid state after the success poll. *Verify: e2e walk against the stub gateway from settings → hosted-page hand-off → success return → refreshed CurrentPlanCard.*

**S3 (P2)** — As a `billing:read` member, I want the invoice list with hosted and PDF links, so that accounting needs no support ticket.

- [ ] The endpoint returns mapped items with cursor pagination, tenant-safe. *Verify: contract tests against the stub gateway — two pages via `nextCursor`; missing `billing:read` → `403` naming the permission; another org's id → `404`.*
- [ ] No billing customer → empty list; hosted/PDF links open in a new tab; URLs appear in no log line. *Verify: contract test for the empty case plus a log assertion on the fetch path; screen check of InvoiceList's four states.*

**S4 (P2)** — As a member, I want payment-issue and canceled states to surface the right banner and CTA for my permission, so that recovery is one click for those who can act.

- [ ] `past_due` within grace shows the payment-issue banner; `billing:manage` holders get "Update payment method" → portal session; others get the copy without the CTA. *Verify: component tests of PaymentIssueBanner per permission and per grace state.*
- [ ] A scheduled cancellation shows "Canceled — access until `<date>`" and the danger zone offers the lifecycle spec's resume path. *Verify: screen state walk of the canceling and canceled states.*

**S5 (P2)** — As the product, I want locked features to render upgrade affordances from entitlements, so that the paywall is consistent and permission-aware everywhere.

- [ ] A locked feature renders the upgrade affordance from `store/billing` entitlements — CTA for `billing:manage`, "ask an owner or admin" copy otherwise; nothing renders for features the plan grants. *Verify: component tests of the affordance per permission and per entitlement state.*
- [ ] Hiding is a hint only: the gated endpoint still denies. *Verify: with the control hidden, a direct call returns `403 FEATURE_NOT_AVAILABLE` per plans-entitlements.md.*

## Requirements

Core (P1):
1. The **billing settings page** lives under organisation settings: route registered in the central registry (`routes.<ext>`), nav entry under org settings, visible only with `billing:read`. A member without it who reaches the route gets the access-restricted empty state naming the missing permission (`apps/frontend/CLAUDE.md`).
2. Every subscription status renders through the **status → copy map** below; raw provider statuses never reach the user (index terminology + frontend microcopy rules). All billing strings are i18n keys named by meaning (`billing.status.past_due_grace`, `billing.invoice.status.paid`, …), in every language file in the same change.
3. Every card handles the four data states. The page loads via one aggregated fetch sequence of parallel service calls with per-card skeletons; a failed card shows its own error + retry — never a page-wide failure.
4. The frontend **billing slice** spans `store/billing` + `services/billing` + `components/organisms/billing/` per `apps/frontend/CLAUDE.md`. `store/billing` holds the subscription summary and effective entitlements the whole app reads for gating hints — fetched at session bootstrap alongside effective permissions, refreshed after every billing mutation and by the checkout success page's polling (checkout.md).
5. **Gating hints app-wide:** a locked feature renders an upgrade affordance driven by `store/billing` entitlements, permission-aware — `billing:manage` holders get the upgrade CTA; everyone else gets "ask an owner or admin" copy. The server stays authoritative (plans-entitlements.md).
6. Edge states: a free org (no billing customer) sees the plan picker and "no invoices yet". With `BILLING_ENABLED=false` the page renders the free state without CTAs, and any `409 BILLING_DISABLED` from a sibling endpoint maps to a quiet disabled state — never an error toast.

Later phases (P2):
7. `GET …/billing/invoices` lists the organisation's invoices fetched live from the provider via `BillingGateway.listInvoices` for the org's own billing customer. No local invoices table exists (Notes & decisions). No billing customer yet → an empty list, not an error.
8. The endpoint uses **cursor pagination**: the base envelope minus `page`/`totalRecords`, plus `nextCursor` — a documented per-endpoint decision as `apps/backend/CLAUDE.md` requires (Notes & decisions).
9. Invoice items: `{ id, number, date, amountMinor, currency, status, hostedInvoiceUrl, pdfUrl }`. `status` is normalised to `paid | open | void | uncollectible` at the repo-ring mapper and rendered only through i18n copy (`billing.invoice.status.*`); an unrecognised provider status renders a neutral fallback, never raw.
10. `hostedInvoiceUrl`/`pdfUrl` are provider-signed and short-lived — fetched on demand, never stored or logged; the UI opens them in a new tab.

### Page composition

Cards are `components/organisms/billing/*`; pages hold no business logic.

- **CurrentPlanCard** — plan name, price, interval, status badge via the copy map, renewal or cancellation date, and the scheduled-change line from `GET …/billing/subscription` (subscription-lifecycle.md).
- **TrialBanner** — days left, convert CTA (checkout). **PaymentIssueBanner** — `past_due`/`unpaid`: human copy plus "Update payment method" → portal session (portal-plan-changes.md), CTA `billing:manage` only.
- **SeatsCard** — from `GET …/billing/seats` (seats.md). **UsageCard** — from `GET …/billing/usage` (usage-quotas.md), including unlimited and near-limit renderings.
- **PlanPicker** — from `GET …/billing/plans`: tier cards, interval toggle with the annual saving stated, current plan marked; upgrade/downgrade CTAs route to the confirmation flow (portal-plan-changes.md) or checkout for free orgs (checkout.md).
- **InvoiceList** — this spec. **"Open billing portal"** link — `billing:manage` (portal-plan-changes.md). **CancelSubscription** — danger zone; typed-confirm per the frontend destructive-action rule, names the access-until date, calls the lifecycle spec's cancellation resource.

### Status → copy map (pinned here)

Normalised subscription state + access tier (index access table) → badge + explanatory sentence. Dates and counts interpolate through i18n parameters; the badge uses semantic intent tokens paired with text.

| Subscription state | Tier | Badge | Sentence (reference copy) |
|---|---|---|---|
| `trialing` | paid | Trial | "Trial — `<n>` days left" |
| `active` | paid | Active | "Renews on `<date>`" (scheduled change appends its line) |
| `active`, cancellation scheduled | paid | Canceling | "Canceled — access until `<date>`" |
| `past_due` within grace | paid | Payment issue | "Payment issue — update your payment method to keep access" |
| `past_due` beyond grace · `unpaid` | free | Payment issue | "Access paused — update your payment method to restore your plan" |
| `incomplete` · `incomplete_expired` | free | Setup incomplete | "Checkout wasn't completed — choose a plan to subscribe" |
| `paused` | free | Paused | "Subscription paused — you're on the Free plan for now" |
| `canceled`, period ended | free | Free plan | "Your subscription ended — you're on the Free plan" |
| No subscription | free | Free plan | "Free plan" |
| Unrecognised status | free | Free plan | Free-plan copy — the fail-closed row renders like no subscription |

## User flows

### F1 — View billing settings (P1)

1. A member with `billing:read` opens org settings → Billing; parallel service calls load each card, with skeletons per card.
2. Every card resolves to one of its four states; the status badge and sentence come from the copy map.

### F2 — Upgrade from Free (P1)

1. A free org's `billing:manage` member opens the PlanPicker (current plan Free, marked) and picks tier + interval (annual saving stated).
2. The CTA hands off to checkout (checkout.md, F1); the success page's polling refreshes `store/billing`, and the settings page now shows the paid state.

### F3 — Payment issue surfaced (P2)

1. The subscription is `past_due`; PaymentIssueBanner shows the grace or beyond-grace copy per the map.
2. A `billing:manage` member's "Update payment method" opens a portal session; others see the copy without the CTA.

### F4 — Browse invoices (P2)

1. InvoiceList loads the first page from `GET …/billing/invoices`; "Load more" follows `nextCursor` until null. Hosted invoice and PDF links open in a new tab.

### F5 — Cancel from the danger zone (P2)

1. A `billing:manage` member opens CancelSubscription; typed confirmation names the consequence and the access-until date.
2. The lifecycle spec's cancellation resource applies; `store/billing` refreshes, and the badge flips to "Canceled — access until `<date>`".

## API & permissions

Under `/internal/v1/organisations/{organisationId}/billing/…`; base envelopes apply.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/invoices` | List the org's provider invoices | `billing:read` | cursor envelope: `data[]` of req. 9 items, `nextCursor` (null when exhausted); optional `cursor`, `recordsPerPage` params; `data: []` when no billing customer |

- All other data on the page comes from the sibling specs' routes named in *Page composition*; this spec adds no other endpoint.
- Viewing the page and invoices needs `billing:read`. Upgrade, plan change, payment-method update (portal), and cancel/resume need `billing:manage`, each executed by its owning sibling spec — this page is the surface. No operator surface; invoice corrections happen in the provider dashboard (program Out of scope).

## Data model

**None.** No local invoices table (req. 7; Notes & decisions). The frontend slice additions (`store/billing`, `services/billing`, `organisms/billing/*`) are code structure, not schema.

## Audit events

**None owned.** Reads are not audited — consistent with the compliance program's convention that views generally go unaudited and with the index's rule that billing *state changes* are audited by the specs that make them (checkout, lifecycle, portal, seats, webhooks-sync).

## Implementation notes

- Thin by design: controller guard (`billing:read`, tenant scope) → one use case → `BillingGateway.listInvoices` with the org's `billing_customers` row (checkout.md owns the table). No row → return the empty page without a provider call. No background jobs. The repo-ring adapter's **mapper** translates provider invoices to the req. 9 DTO; provider SDK objects never cross inward (index provider boundary).
- The cursor is opaque provider state: validated as a string, passed through, never parsed or logged. `hostedInvoiceUrl`/`pdfUrl` are never logged (they embed signed access); log invoice ids only. Signed URLs render as links opening a new tab with opener isolation — never stored, logged, or embedded elsewhere.
- A provider fetch failure or ambiguous response is `502 PROVIDER_UNAVAILABLE` — never a fabricated empty list (backend *Integrations*: unclear outcomes are never success). With `BILLING_ENABLED=false` the stub sink serves the read: no billing customer exists, so the response is the empty list; no call reaches a real provider.
- Invoices are fetched only through the org's own `billing_customers` mapping — the client never supplies a provider customer or invoice id for listing; a cross-tenant organisation id is `404` (program cross-cutting criterion 1). All frontend gating (hidden CTAs, locked-feature affordances) is a rendering hint; every action's endpoint re-checks its permission and entitlement server-side. Raw provider statuses, error text, and internal codes never render — the copy map and the frontend error-copy rules stand between the provider and the user.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Missing `billing:read` on the invoices read | 403 | `PERMISSION_DENIED` (missing permission in `error.details`) |
| Organisation id not the caller's | 404 | base membership guard (cross-cutting criterion 1) |
| Provider unreachable / ambiguous on invoice fetch | 502 | `PROVIDER_UNAVAILABLE` (UI: card error state + retry) |
| Malformed `cursor` / pagination params | 400 | base validation envelope |
| Sibling-endpoint failures surfaced on this page (`BILLING_DISABLED`, `SUBSCRIPTION_NOT_FOUND`, …) | — | owned by their specs; the UI maps `409 BILLING_DISABLED` to the quiet disabled state (req. 6) |

## Notes & decisions

- **No local invoices table (req. 7):** the provider is the invoice system of record; hosted URLs are short-lived and must not be persisted, and a cache would only duplicate state the app never decides on. The app caches nothing sensitive.
- **Cursor pagination (req. 8):** provider list APIs are cursor-shaped, and an offset+COUNT emulation would fabricate totals the app doesn't hold.
- UX: this is a data-heavy settings screen — pick the **settings archetype** from the design guide before building (gate 2); cards follow the surface ladder, no card-in-card (gate 3). No `design/` mockup exists yet — a blocker for the initial build per `specs/README.md` (open question below).
- UX: amounts render minor units through the shared currency formatter (locale-pinned); dates through the shared date formatter — never inline formatting. Status badges use semantic intent tokens always paired with text, never colour alone. The page passes the 320 px / 200% zoom floor; the invoice list scrolls inside its own box, never the page. Performance: the session-bootstrap `store/billing` fetch stays cheap — one small subscription+entitlements read alongside effective permissions.

## Out of scope

- Receipt and invoice emails — provider-sent. Invoice PDF generation — provider-owned; the app only links.
- Dunning configuration and retry schedules — provider dashboard. Admin/operator billing consoles — program-wide Out of scope.
- Mutation semantics behind the page's CTAs — checkout, portal/plan-change, cancellation, and seat rules belong to their sibling specs.

## Open questions

- Mockups for the settings page, plan picker, and paywall/locked states — required before the initial build (program open question). Owner: design.
- Do invoices need date/status filters at launch? Default **no** (YAGNI) — the list is short for years for most orgs; revisit on demand.
- Where is the billing contact email edited — the hosted portal only, or in-app? Align with the checkout spec's open question on `billing_email`; default portal-only.
