# Fastify 4 on Tencent SCF — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` to **Fastify 4, plain JavaScript (CommonJS), on a Tencent Cloud SCF Web Function**. Data: `./db.md`; infra: `./infra.md`.

## Binding at a glance

- **HTTP: Fastify 4, used directly** — plugins, hooks, and decorators are the base's aspect mechanism.
- **Language: plain JavaScript, CommonJS** (`require`, no `"type": "module"`); `typecheck` is an explicit no-op.
- **Layout: layer-first** — `routes/ services/ repos/ schemas/ lib/ utils/ plugins/ db/` under `src/`, not the feature-first onion (see the register).
- **Validation: Fastify JSON Schema** — every route declares request *and* response schemas from `schemas/<domain>.js`; **OpenAPI is the source of truth** (drift guards: `lint:openapi` + `lint:schemas`).

## Structure

- **`routes/<domain>.js` (controllers)** — thin Fastify plugins: attach JSON Schema, run guards, call **one** `services/` function, shape the reply. Never touch Knex or a repo; no business rules beyond validation.
- **`services/<domain>.js` (business layer)** — orchestrate use cases: own the transaction (`knex.transaction`), enforce rules, call `lib/`, emit audit; never see `request`/`reply`; raise failures as `HttpError`.
- **`repos/<domain>.js` (data access)** — Knex query building only; first arg is `db` (knex instance *or* transaction), then a named-args object; no rules, no `HttpError` (mechanics: `./db.md`).
- **`schemas/`** — all JSON Schemas (`<Thing>Schema`, `<Action>BodySchema`, params/query), never inline. **`lib/`** — side-effecting integrations (SMS/email/COS/translation/audit). **`utils/`** — pure no-I/O helpers (code hashing, phone canonicalisation, cursor codec, `HttpError`). **`plugins/`** — the aspects.

## Aspects — `plugins/`

| Base concern | Binding |
|---|---|
| Config | validated at boot in the entry — exit non-zero on missing env; values flow inward, no `process.env` in rings |
| DB access | `plugins/db.js` sets the single Knex instance (`getKnex()`); repos receive it (or a `trx`) as first arg, never construct their own |
| Request context | `plugins/ctx.js` packs `{ requestId, sourceIp, userAgent, logger }` into `request.ctx`, passed inward as a value; the id rides `x-request-id` end-to-end |
| Errors | the global `HttpError` handler in `app.js` (see the register); rate limits set `retryAfterSeconds` for it to surface |
| Auth | `plugins/auth.js` — `fastify.requireAuth` / `fastify.requireCommunityRole` as `preHandler` guards on the scopes needing them |
| Mode signal | `plugins/tenant.js` resolves `x-tenant` → `request.tenant` (missing/unknown ⇒ `production`, fail-closed), cached in memory |

**Scope-to-subtree = plugin encapsulation** — guard the route scope needing it; only db, cookie, ctx, tenant, and the error handler are app-wide.

## Audit, gating & add-ons

- **Audit trail**: services call `services/audit.record(ctx, { eventType, ... })` — one durable append per state change; never `lib/audit` directly.
- **Integration gating**: `DEV_OTP_SINK` and `EMAIL_SENDING_ENABLED` — the default-off booleans routing SMS/email to a stdout sink until flipped per environment.
- **`test-mode`, if adopted** (`add-ons/test-mode/`): `x-tenant: test` is the signal (`plugins/tenant.js`); `skipOtpChecks()` swaps OTP *delivery* for a sink — the challenge is still issued and verified; test-only reads (the picker) return empty for `production`.
- **`otp-auth`, if adopted** (`add-ons/otp-auth/`): **model A** (self-managed store) — `utils/otp.js`: code gen + **HMAC-SHA256** hash + short TTL + timing-safe verify; one `otp_challenge` table whose **`purpose`** column (signup/login/contact-change) drives the recent-challenge rate limit; delivery via `lib/sms.js` (Tencent SMS) / `lib/email.js` (Tencent SES); phones canonicalised to E.164 with `libphonenumber-js`; phone and email: two identity records (`repos/phoneIdentity`, `repos/emailIdentity`) on one account.

## SCF entrypoint — two entries, one `buildApp()`

- **SCF: `handler.js`** — **`listen()`s on the SCF-provided port** (default `9000`); a Web Function is a real HTTP server the platform proxies to — no per-request wrapper (no `tencent-serverless-http`). `scf_bootstrap` runs `exec node /var/user/handler.js`.
- **Local: `server.js`** — the same `buildApp()`, `listen()`ing on `PORT` under `node --watch`, plus swagger-ui + multipart in non-production — the base exercise-over-HTTP gate works unchanged.
- **One function, API + UI:** the built H5 bundle ships in the zip behind `@fastify/static` at `/` — one process answers `/api/*` and the SPA (zip + edge: `./infra.md`).
- **Bundle:** `esbuild src/handler.js --bundle --platform=node --target=node18 --external:mysql2` — every SQL driver external, only `mysql2` installed into the zip's `node_modules`; `migrate.js` bundles likewise as a separate function (`./db.md`).
- **Serverless:** instances scale to zero and multiply — never rely on instance memory for correctness (durable state lives in MySQL or the signed session cookie; a module-level value is a cache only); finish all work inside the request. CynosDB **auto-pauses** when idle — a cold path may hit a resuming DB (resume: `./infra.md`).

## Security bindings

- **Headers: `@fastify/helmet`, once at bootstrap in `buildApp()`** (rejected: EdgeOne header rules — the direct SCF URL would go bare and header config would leave the app). This process serves HTML (the H5 bundle), so a real **CSP** applies — report-only first, then enforce; allow-list only the COS/VOD origins the bundle loads.
- **SSRF guard: `lib/safeUrl.js`** — `https` to public hosts only; resolve the hostname; reject loopback/private/link-local/cloud-metadata IPs — at URL save *and* again before the outbound fetch (save-time alone misses a later private re-resolve).
- **Write-only secrets via response schemas.** Fastify serialises replies through the declared schema — a secret left out never leaves the process; declare only the `…Set` boolean. On update, a blank value means "keep the stored secret".

## Testing

**Vitest** (`pnpm test`); base per-ring kinds, bound: **service** — drive the use case on real Knex against the `*_test` schema (rules live in services — most coverage sits here); **route** — `app.inject()`; **repo** — integration against `*_test`. The suite is **destructive** (`./db.md` owns the guard ritual). Unset `DEV_OTP_SINK` so OTP paths exercise the real verify.

## Conflict register

- **Base says:** **feature-first** — `modules/<feature>/{domain,service,repo,controller}`, a pure `domain/` ring, a composition root (`container.js`). **In this stack:** **layer-first** (the layout above) — no separate `domain/` ring (business rules live in `services/`), no DI container (plugins + the `getKnex()` singleton wire everything). **Because:** a pure-domain ring and a resolver earn little in a mostly-CRUD product — the discipline stays, only the axis differs. **Concretely:** DO flag a repo with branching logic or a service reading `request`; DON'T scaffold a `domain/` tree or DI container unless a genuinely rules-heavy domain appears — then reach for the base onion.
- **Base says:** the stack is unchosen — JS-style filenames and the Express/Fastify layer are illustrative. **In this stack:** bound for real — Fastify 4, plain JavaScript **CommonJS**, no typecheck, an **esbuild bundle** for the SCF artifact. **Because:** the target runs bundled Node source directly; JSON-Schema edges and small pure `utils/` make a typecheck step weight without payoff. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `typecheck` an explicit no-op — the esbuild bundle packages, it doesn't verify types.
- **Base says:** the domain raises failures in domain terms; the controller ring alone maps them onto transport. **In this stack:** services raise `HttpError` (`utils/httpError`) — transport-shaped, carrying its status — and the global handler in `app.js` maps it to the base envelope. **Because:** with no domain ring, a parallel error taxonomy plus a mapping table earns nothing over one helper; the transport leak into `services/` is deliberate. **Concretely:** DO raise `HttpError` from `services/` only; DON'T shape a reply outside the global handler; DON'T throw `HttpError` from `repos/` — repo failures stay plain errors for the service to classify.
