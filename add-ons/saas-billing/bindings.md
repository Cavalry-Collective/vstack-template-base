# saas-billing — suggested stack-pack bindings

Pre-written entries for the stack packs this template ships. At adoption, copy the active pack's entry below into that pack's `backend.md` (its add-on-bindings section), then **delete this file** — the pack appendix is the binding's only home from then on (contrast `add-ons/seo/bindings.md`, which is read in place and kept). Each entry answers the README's *Binds to a stack* seams: provider, gateway home, webhook seam, jobs, config. A shipped pack with no section here is silent — a defect; every pack is covered below.

## `enterprise` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — **Stripe** (`stripe` Node SDK).
- **Gateway home** — a repo-ring adapter behind the domain's `BillingGateway` port token, bound in the billing module's `providers` array; `BILLING_ENABLED=false` binds the stub gateway instead.
- **Webhook seam** — signature verification needs the **raw body**: capture it for the webhook route only (e.g. `fastify-raw-body` scoped to that route) and verify in a guard before the Zod pipe parses.
- **Jobs** — the reconciliation sweep and usage rollover run on the pack's BullMQ / `@nestjs/schedule` binding.
- **Config** — `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` live in the Zod-validated config schema.

## `vercel-csr` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — **Stripe** (`stripe` SDK).
- **Gateway home** — the gateway adapter registers in `container.js`; the flag routes to the stub via a container registration (tests swap it with `overrides`).
- **Webhook seam** — Fastify parses JSON by default: preserve the raw payload for the webhook route only (scoped raw-body plugin / content-type parser) and verify the Stripe signature before parsing.
- **Jobs** — serverless, no resident runner: bind the reconciliation sweep to **Vercel Cron** hitting a dedicated authenticated route, and finish each batch inside the request.
- **Config** — `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` join the boot-time Zod env schema.

## `vercel-ssr` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — **Stripe** (`stripe` SDK).
- **Gateway home** — a repo-ring adapter behind the domain's billing gateway port, registered in `src/server/container.ts`; `BILLING_ENABLED=false` binds the stub gateway instead.
- **Webhook seam** — an external route handler (that pack's *External HTTP* edge — a thin delegate under `app/`) reads the raw payload with `request.text()` and verifies the Stripe signature before anything parses; route handlers don't pre-parse, so the raw body is available by construction.
- **Jobs** — serverless, no resident runner: bind the reconciliation sweep, usage rollover, and trial expiry to **Vercel Cron** hitting a dedicated authenticated route, finishing each batch inside the request.
- **Config** — `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` join the boot-time Zod env schema.
- **Endpoints** — the program's internal billing endpoints bind to this pack's queries/actions controller edge (its `/internal/v1` conflict-register entry applies — same envelope fields, function transport); only the webhook stays an HTTP route handler.

## `wechat` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — market-dependent: **Stripe** for international deployments; a mainland-China product swaps the gateway for **WeChat Pay** behind the same port.
- **Gateway home** — `lib/billing.js` (services call it, never an SDK directly); the default-off billing flag routes it to the stub sink.
- **Webhook seam** — preserve the raw payload (scoped content-type parser) and verify the signature in a `preHandler` before schema validation.
- **Jobs** — the reconciliation sweep is a separately-bundled scheduled SCF function (same pattern as `migrate.js`).
- **Config** — provider secrets are validated at boot in the entry.

## `mern` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — **Stripe** (`stripe` SDK).
- **Gateway home** — a repo-ring adapter behind the domain's billing gateway port, wired in `container.js`; `BILLING_ENABLED=false` binds the stub gateway there instead (tests swap it via `overrides`).
- **Webhook seam** — signature verification needs the **raw body**, and the app-wide `express.json()` consumes it: mount `express.raw({ type: 'application/json' })` on the webhook route only and verify the Stripe signature against the raw buffer before anything parses.
- **Jobs** — the API is a long-lived process, so the reconciliation sweep, usage rollover, and trial expiry run on an in-process scheduler (e.g. `node-cron`) started from the composition root; keep each run idempotent. If the deployment scales past one instance, move the schedule to the pipeline the base `infra/CLAUDE.md` contract stands up (this pack ships no `infra.md`) rather than letting instances double-fire.
- **Config** — `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` join the boot-time Zod env schema.

## `django` — bound

**saas-billing** (`add-ons/saas-billing/`):
- **Provider** — **Stripe** (`stripe` Python SDK).
- **Gateway home** — an adapter module (`billing/gateway.py`) behind one service-facing interface — services call it, never the SDK (that pack's gateway-adapter seam, `stacks/django/backend.md`); `BILLING_ENABLED=False` in the validated settings binds the stub gateway instead, selected once in the gateway factory — tests swap it at that same seam.
- **Webhook seam** — a dedicated view with authentication/permission/throttle classes cleared and **CSRF exempt** reads `request.body` — Django keeps the raw bytes, so the raw payload is available by construction — and verifies the signature via `stripe.Webhook.construct_event` **before** any serializer parses.
- **Jobs** — the reconciliation sweep, usage-period rollover, and trial-expiry handling are idempotent management commands (`manage.py billing_reconcile`, …) scheduled by whatever the base `infra/` contract stands up (cron/scheduler); no resident queue by default — adopt Celery only when a job outgrows a command, as a recorded decision.
- **Config** — `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` join the validated `settings.py` seam (django-environ, required in production) and `.env.example`.
