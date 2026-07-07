# saas-billing — suggested stack-pack bindings

Pre-written entries for the stack packs this template ships, kept **inside the add-on** so adopting it touches nothing else. At adoption, copy the active pack's entry below into that pack's `backend.md` (its add-on-bindings section) and delete the others with the unused packs. Each entry supplies what the README's *Binds to a stack* asks for: the provider + SDK/adapter home, the webhook raw-body/signature seam, the stub sink, the job runner, and the config home.

## `nextjs-nestjs-postgres`

- **saas-billing** (`add-ons/saas-billing/`): provider = **Stripe** (`stripe` Node SDK). The gateway is a repo-ring adapter behind the domain's `BillingGateway` port token, bound in the billing module's `providers` array; `BILLING_ENABLED=false` binds the stub gateway instead. Webhook seam: signature verification needs the **raw body** — capture it for the webhook route only (e.g. `fastify-raw-body` scoped to that route) and verify in a guard before the Zod pipe parses. Reconciliation sweep and usage rollover run on the pack's BullMQ / `@nestjs/schedule` binding. `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` live in the Zod-validated config schema.

## `vercel`

- **saas-billing** (`add-ons/saas-billing/`): provider = **Stripe** (`stripe` SDK). The gateway adapter registers in `container.js`; the flag routes to the stub via a container registration (tests swap it with `overrides`). Webhook seam: Fastify parses JSON by default — preserve the raw payload for the webhook route only (scoped raw-body plugin / content-type parser) and verify the Stripe signature before parsing. Jobs on serverless: no resident runner — bind the reconciliation sweep to **Vercel Cron** hitting a dedicated authenticated route, and finish each batch inside the request. `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` join the boot-time Zod env schema.

## `taro-fastify-mysql-tencent`

- **If you adopt the `saas-billing` add-on** (`add-ons/saas-billing/`): the provider is market-dependent — **Stripe** for international deployments; a mainland-China product swaps the gateway for **WeChat Pay** behind the same port. `lib/billing.js` is the gateway home (services call it, never an SDK directly); the default-off billing flag routes it to the stub sink. Webhook route: preserve the raw payload (scoped content-type parser) and verify the signature in a `preHandler` before schema validation. The reconciliation sweep is a separately-bundled scheduled SCF function (same pattern as `migrate.js`); provider secrets are validated at boot in the entry.
