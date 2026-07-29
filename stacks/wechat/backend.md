# Fastify 4 on Tencent SCF — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` and the root `CLAUDE.md` to **Fastify 4, plain JavaScript (CommonJS), deployed as a Tencent Cloud SCF Web Function**. Read those first; this file does not restate them.

## Scope

This file owns the HTTP layer, the layer-first layout, the aspects, the SCF entry, and the add-on bindings. Data layer → `./db.md`; provisioning and deploys → `./infra.md`.

## Stack binding at a glance

- **HTTP layer: Fastify 4, used directly** — plugins, lifecycle hooks, and decorators are the base's aspect mechanism. **Language: plain JavaScript, CommonJS** (`require`, no `"type": "module"`), no typecheck step (explicit no-op) — the deploy `esbuild` bundle packages, it doesn't verify types.
- **Layout: layer-first, not the base's feature-first onion** — see *Layers* below and the conflict register.
- **Validation: Fastify JSON Schema** — every route declares request *and* response schemas from `schemas/<domain>.js`; **OpenAPI is the source of truth** — the document lives at `apps/backend/openapi.yaml`; `lint:openapi` validates the document itself, `lint:schemas` asserts every route's attached schema matches its OpenAPI operation (pack decision — see the README).

## Layers — the flat shape (`routes/ services/ repos/ schemas/ lib/ utils/ plugins/ db/` under `src/`)

- **`routes/<domain>.js` (controllers)** — thin Fastify plugins: attach JSON Schema, run guards, call **one** `services/` function, shape the reply. Never touch Knex or a repo directly; no business rules beyond validation.
- **`services/<domain>.js` (business layer)** — orchestrate use cases: own the transaction (`knex.transaction`), enforce rules, call `lib/` integrations, emit audit events. Never see `request`/`reply`; raise failures as `HttpError`. This ring carries the domain logic the base places in a separate `domain/` ring — see the register.
- **`repos/<domain>.js` (data access)** — Knex query building only; first arg is always `db` (a knex instance *or* a transaction), then a named-args object. No rules, no `HttpError`. Mechanics → `./db.md`.
- **`schemas/`** — all JSON Schemas (`<Thing>Schema`, `<Action>BodySchema`, params/query), no inline schemas. **`lib/`** — side-effecting integrations (SMS/email/COS/translation/audit). **`utils/`** — pure, no-I/O helpers (code hashing, phone canonicalisation, cursor codec, `HttpError`). **`plugins/`** — the aspects (below).

## Aspects — `plugins/` as Fastify decorators/plugins

| Base concern | Binding |
|---|---|
| Config | validated at boot in the entry (below) — `handler.js`/`server.js` fail fast (exit non-zero) on a missing required env var; values flow inward, no `process.env` in rings |
| DB access | `plugins/db.js` sets the single Knex instance (`getKnex()`); repos receive it (or a `trx`) as their first arg — never construct their own |
| Request context | `plugins/ctx.js` packs `{ requestId, sourceIp, userAgent, logger }` into `request.ctx`, passed inward as a value (the base correlation-id rule: honour an inbound `x-request-id`/`x-correlation-id`, and return the id as the base's `x-correlation-id` response header on every response) |
| Errors | one global handler in `app.js` maps `HttpError` (from `utils/httpError`) → the base *Error responses* envelope; rings never shape an HTTP response. A rate-limit sets `retryAfterSeconds` for the handler to surface |
| Auth | `plugins/auth.js` — `fastify.requireAuth` plus one `fastify.require<Role>` decorator per role the app defines, as `preHandler`s on the scopes that need them |
| Mode signal | `plugins/tenant.js` — resolves the `x-tenant` header to `request.tenant`, selecting test vs `production` (missing/unknown ⇒ `production`, fail-closed), cached in memory; backs the optional **test-mode** add-on |
| Audit trail | services call `services/audit.record(ctx, { eventType, ... })` — one durable append per state change, never `lib/audit` directly (base *Cross-cutting → Audit trail*) |
| Integration gating | `DEV_OTP_SINK` and `EMAIL_SENDING_ENABLED` are the default-off booleans that route SMS/email to a stdout sink until flipped per-environment (base *Integrations*) |
| Scope-to-subtree | Fastify plugin encapsulation — register a guard on the route scope that needs it; only db, cookie, ctx, tenant, and the error handler register app-wide |

## SCF entrypoint — `handler.js` (SCF) vs `server.js` (local)

- **Two entries, one `buildApp()`.** `handler.js` builds the app and **`listen()`s on the SCF-provided port** (default `9000`) — SCF Web Functions run a normal HTTP server the platform proxies to, so there is **no per-request wrapper** (no `tencent-serverless-http`); `scf_bootstrap` (`exec node /var/user/handler.js`) is the container entry. `server.js` does the same `buildApp()` and `listen()`s on `PORT` for `node --watch`, adding swagger-ui + multipart in non-production, so the base "exercise the actual endpoint over HTTP" gate works unchanged.
- **Deploy bundle, one function serving API + UI:** `esbuild src/handler.js --bundle --platform=node --target=node20 --external:mysql2` (all other SQL drivers externalized too, then only `mysql2` is `npm install`ed into the zip's `node_modules`); `migrate.js` bundles the same way as a separate function — `./db.md`. The built Taro H5 bundle ships inside the zip and is served by `@fastify/static` at `/`, so the same process answers `/api/*` and the SPA (`./infra.md` owns the zip + EdgeOne edge).
- **Serverless rules:** instances scale to zero and multiply — never rely on instance memory for correctness (durable state is in MySQL or the signed session cookie; a module-level value is a cache only), and finish all work inside the request. CynosDB **auto-pauses** when idle, so a cold path may hit a resuming DB — `./infra.md` covers the deploy-time resume.

## Testing

- **Runner: Vitest** (`pnpm test`). Base per-ring kinds, bound: **service** — drive the use case with the real Knex against the `*_test` schema (this stack keeps rules in services, not a pure domain ring, so most coverage sits here); **route** — Fastify `app.inject()`; **repo** — integration against the `*_test` MySQL schema. The suite is **destructive** and guarded — `./db.md` owns the `*_test` ritual. If `otp-auth` is adopted, unset `DEV_OTP_SINK` in the test env so tests read codes from the challenge store instead of stdout — the sink gates delivery only; verify runs real either way.

## Add-on bindings (if adopted)

- **test-mode** (`add-ons/test-mode/`): `x-tenant: test` is the mode signal (resolved by `plugins/tenant.js`, fail-closed to `production`); `skipOtpChecks()` swaps OTP *delivery* for a sink on a test-mode request — the challenge is still issued/verified, the tester reads the real code from the stdout sink line, and verify is never stubbed; every test-only read (e.g. the picker) returns empty for `production`.
- **otp-auth** (`add-ons/otp-auth/`): this stack is **model A** (self-managed store) — `utils/otp.js` does code gen + **HMAC-SHA256** hash + short TTL + timing-safe verify.
  - **Challenge store:** one `otp_challenge` table with a **`purpose`** column (signup / login / contact-change) drives the recent-challenge rate limit.
  - **Delivery & identity:** `lib/sms.js` (Tencent SMS) / `lib/email.js` (Tencent SES); phone numbers canonicalised to E.164 with `libphonenumber-js`; phone and email are two identity records (`repos/phoneIdentity`, `repos/emailIdentity`) against one account. On a test-mode request delivery is sinked (see **test-mode** above).

## Conflict register

- **Base says:** organise **feature-first** — `modules/<feature>/{domain,service,repo,controller}` with a pure `domain/` ring at the centre and a composition root (`container.js`) wiring ports to implementations. **In this stack:** the layout is **layer-first** — `routes/ services/ repos/ schemas/ lib/ utils/ plugins/` — with **no separate `domain/` ring** (business rules live in `services/`) and **no DI container** (Fastify plugins + a `getKnex()` singleton do the wiring). **Because:** in a mostly-CRUD product a distinct pure-domain ring and a resolver earned little over disciplined layers. **Concretely:** DO keep each rule at its layer (a repo with branching logic, or a service reading `request`, is the violation to flag); DON'T scaffold a `modules/<feature>/domain` tree or a DI container for this stack unless a genuinely rules-heavy domain appears — then reach for the base onion.
- **Base says:** the stack is unchosen; JS-style filenames and the Express/Fastify HTTP layer are illustrative, and (per the base) inner rings are pure with ports. **In this stack:** bound for real — Fastify 4, plain JavaScript **CommonJS**, no typecheck, but an **esbuild bundle** for the SCF artifact. **Because:** the deploy target runs bundled Node source directly, and JSON-Schema-guarded edges plus small pure `utils/` make a transpile/typecheck step weight without payoff. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `typecheck` an explicit no-op; DON'T confuse the deploy `esbuild` bundle with a typecheck — it packages, it doesn't verify types.
- **Base says:** the domain raises failures in domain terms; the controller ring is the single place that maps them onto transport responses. **In this stack:** services raise `HttpError` (from `utils/httpError`) — a transport-shaped error carrying its status — and the one global handler in `app.js` maps it to the base error envelope. **Because:** with no separate domain ring (see the layout entry above), a parallel domain-error taxonomy plus a mapping table earned nothing over one error helper. **Concretely:** DO raise `HttpError` from `services/` only; DON'T shape a reply (`reply.code(...)`/`send`) anywhere but the global handler, and DON'T throw `HttpError` from `repos/` — data-access failures surface as plain errors for the service to classify.
