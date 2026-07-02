# Fastify on Vercel — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) to **Fastify, plain JavaScript (ESM), deployed as one Vercel serverless function**. Data layer: `./db.md`; provisioning/deploys: `./infra.md`.

## Binding at a glance

- **HTTP layer: Fastify 5, used directly** — plugins, hooks, decorators are the aspect mechanism.
- **Language: plain JavaScript, ESM** (`"type": "module"`), no build/typecheck step (registered — rejected: TypeScript).
- **Wiring: Awilix** as the composition root from day one (registered — rejected: manual constructor wiring).
- **Validation: Zod** — `dtos/` are Zod schemas at the controller edge; one schema parses env at boot.
- **Test runner: `node:test`** — rejected: Jest/Vitest (plain ESM needs no transform).

## Structure

The base folder shape applies verbatim — `modules/<feature>/{domain,service,repo,controller,dtos}`, `shared/{aspects,utils}`, `container.js`.

## Composition root — Awilix

- Every repo, gateway, and use case registers as a factory (`asFunction`/`asValue`), resolved **once at boot**; `buildContainer({ env, overrides })` replaces any registration by name for tests.
- **Rings never import `awilix`** — services and repos are plain factory functions receiving dependencies as one argument (`makeCreateOrder({ orderRepo, withTransaction })`); the container is glue only.

## Controller ring — one Fastify plugin per module

- Each module's `controller/routes.js` is a Fastify plugin receiving the container's cradle; `app.js` registers every module plugin under **one `/internal/v1` prefix**, plus `/health`. Add `/external/v1` only when a genuine third-party consumer exists.
- A handler validates with the module's Zod DTO, invokes **one** use case from the cradle, and maps the result to a response DTO.

## Aspects — Fastify plugins/hooks

| Base concern | Binding |
|---|---|
| Config | `env.js` — one Zod schema parsed at boot, **fail fast** on missing/invalid keys; values passed inward, no `process.env` in rings |
| DB access | `db.js` — the single `pg.Pool` + `withTransaction` (`./db.md`) |
| Request context | `request-context.js` — correlation id seeded at the edge, passed inward as a value |
| Errors | `errors.js` — **one** `setErrorHandler`: domain errors (plain helpers in `shared/utils/`) → the base envelope + `x-correlation-id`; inner rings never shape HTTP |
| Auth | `auth.js` — cookie-session `preHandler` guards on the scopes that need them |

**Scope-to-subtree = Fastify plugin encapsulation.** Only the error handler, request context, cookie plugin, and DB pool register app-wide; every other aspect scopes to the subtree needing it.

## Sessions & edge

- **Sessions: signed HTTP-only cookies** (`@fastify/cookie`, `SESSION_SECRET`) — stateless; no session store.
- **`TRUST_PROXY=true` when deployed** (Fastify `trustProxy`) — requests arrive through Vercel and the Next `/api` rewrite; without it, rate limiting and logging key on the proxy IP.
- `@fastify/rate-limit`'s in-memory store is **per-instance** on serverless — an acceptable soft limit; a shared store only when a limit must be globally exact.

## Vercel entrypoint — `src/server.js` is both entrypoints

- **Vercel path:** default-export an async `handler(req, res)`: lazily build the app once (`appPromise ??= buildApp(...)` — **no top-level await**), `await app.ready()`, `app.server.emit("request", req, res)`. **Never `listen()` on Vercel.**
- **Local path:** when `!process.env.VERCEL`, a real listener on `PORT` — the base exercise-over-HTTP gate stands.
- `apps/backend/vercel.json`: an `@vercel/node` build of `src/server.js` with a catch-all rewrite — the whole app is **one function**; Fastify's router stays in charge, not Vercel's filesystem routing.
- **Serverless rules:** instances scale to zero and multiply — never rely on instance memory for correctness (durable state: Postgres or the signed cookie; a module memo is only a cache); finish all work inside the request — the instance freezes, so no fire-and-forget after the response.

## Security bindings

- **Headers: `@fastify/helmet`**, once at bootstrap — the API's `*.vercel.app` URL is directly reachable, so it sets its own headers. Helmet's default CSP (`default-src 'self'`) fits a JSON API; tune only if it serves HTML.
- **SSRF guard:** one shared helper (`shared/utils` or domain): public `https` only; resolve the host and reject loopback/private/link-local/cloud-metadata IPs — run at config-save *and* immediately before the outbound `fetch`.
- **Write-only secrets:** the read DTO masks each admin-managed secret behind a `…Set` flag; the update handler preserves a blank field over the stored value.

## Add-on bindings

- **test-mode** (`add-ons/test-mode/`): the mode signal — a signed header or cookie, HMAC-verified (`node:crypto`) — resolves in a `preHandler` beside `auth.js` as `request.testMode`; no/invalid signal = production, fail closed. Sinks hang off the default-off env booleans in the `env.js` schema (base *Integrations*); the test-user picker is a test-mode-gated `/internal/v1` read returning `[]` in production.
- **otp-auth** (`add-ons/otp-auth/`): model A on Postgres — a challenge table of hashed code + short TTL + `purpose` + target; its unique `(target, purpose)` key resolves retries to `409`; hash/verify via `node:crypto` (HMAC + `timingSafeEqual`); rate-limit send/verify via `@fastify/rate-limit` keyed per target; the knowable test code exists only behind the mode signal — delivery goes to the sink.

## Testing

- Run with `node --test tests/`; `tests/` mirrors `src/`.
- Per-ring kinds, bound: **domain** — plain units; **service** — container with `overrides` fakes; **controller** — `app.inject()` (no listener); **repo** — integration against the real local Postgres (`--test-concurrency=1` where shared).

## Conflict register

- **Base says:** the stack is unchosen; JS-style filenames and the Express/Fastify-style HTTP layer are illustrative. **In this stack:** bound for real — Fastify 5, plain JS ESM, no build/typecheck step. **Because:** the deploy target is a Vercel Node function running source directly; duck-typed ports, Zod-guarded edges, and JSDoc `@typedef`s leave a transpile step all weight, no payoff. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `build`/`typecheck` as explicit no-op scripts.
- **Base says:** wiring is manual constructor wiring in `container.js`; adopt a DI container only once the graph grows unwieldy. **In this stack:** `container.js` is an Awilix container from day one. **Because:** registrations resolve at boot — a typo'd name throws at startup, not at request time — and `overrides` swaps test fakes in without touching rings. **Concretely:** DO register every port in `container.js` via `asFunction`/`asValue`; DON'T import `awilix` outside `container.js`.
