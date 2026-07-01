# Fastify on Vercel — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) and the root `CLAUDE.md` to **Fastify, plain JavaScript (ESM), deployed as a Vercel serverless function**. Read those first; this file does not restate them. Data layer → `./db.md`; provisioning and deploys → `./infra.md`.

## Stack binding at a glance

- **HTTP layer: Fastify 5, used directly** — no framework on top. The base's illustrative "Express/Fastify-style" layer is bound to real Fastify: plugins, hooks, and decorators are the aspect mechanism.
- **Language: plain JavaScript, ESM** (`"type": "module"`), with **no build or typecheck step** — the `build`/`typecheck` scripts are explicit no-ops, not omissions. Pack decision — rejected alternative: TypeScript (see conflict register).
- **Folder layout: the base shape verbatim** — `modules/<feature>/{domain,service,repo,controller,dtos}`, `shared/{aspects,utils}`, `container.js`. No mapping table needed; this stack is the layout the base illustrates.
- **Validation: Zod** — `dtos/` are Zod schemas at the controller edge; one Zod schema parses env at boot.

## Composition root — `container.js` is an Awilix container

- `container.js` stays the single composition root, implemented with **Awilix**: every repo, gateway, and use case registered as a factory (`asFunction`/`asValue`), resolved **once at boot** when routes are registered. Pack decision — rejected alternative: the base's manual constructor wiring (see conflict register).
- **Rings never import `awilix`.** Services and repos are plain factory functions — `makeCreateOrder({ orderRepo, withTransaction })` — receiving dependencies as one argument; the container is glue only.
- `buildContainer({ env, overrides })`: tests replace any registration by name via `overrides` (an in-memory gateway fake, a stub repo) without touching a ring.

## Controller ring — one Fastify plugin per module

- Each module exposes `controller/routes.js` — a Fastify plugin receiving the container's cradle. `app.js` registers every module plugin inside **one `/internal/v1` prefix scope**, plus a `/health` route. This realizes the base visibility/versioning rule as a Fastify prefix; add an `/external/v1` scope only when a genuinely third-party consumer exists.
- A handler validates with the module's Zod DTO, invokes **one** use case from the cradle, and maps the result to a response DTO — base rules, bound to Fastify handler signatures.

## Aspects — `shared/aspects/` as Fastify plugins/hooks

| Base concern | Binding |
|---|---|
| Config | `env.js` — one Zod schema, parsed once at boot (`loadEnv()`), **fail fast** on missing/invalid keys; values passed inward — no `process.env` reads in rings |
| DB access | `db.js` — creates the single `pg.Pool` and exports `withTransaction` (mechanics in `./db.md`) |
| Request context | `request-context.js` — correlation id seeded per request at the edge, passed inward as a plain value |
| Errors | `errors.js` — **one** `setErrorHandler` mapping domain errors (plain error helpers in `shared/utils/`) → the base *Error responses* envelope (`error.code` / `error.message` / `error.correlationId` + the `x-correlation-id` header); inner rings never shape an HTTP response |
| Auth | `auth.js` — cookie-session guards as `preHandler` hooks on the route scopes that need them |

**Scope-to-subtree = Fastify plugin encapsulation.** Register an aspect on the route scope that needs it; only the error handler, request context, cookie plugin, and DB pool register app-wide at bootstrap.

## Sessions & edge concerns (serverless-shaped)

- **Sessions are signed HTTP-only cookies** (`@fastify/cookie` with `SESSION_SECRET`) — stateless by construction, so scale-to-zero costs nothing and there is no session store to manage.
- **`TRUST_PROXY=true` in deployed env** (Fastify `trustProxy`): requests arrive through Vercel and the Next `/api` rewrite, so without it rate limiting and logging key on the proxy IP, not the client.
- `@fastify/rate-limit`'s default in-memory store is **per-instance** on serverless — acceptable as a soft limit; reach for a shared store only when a limit must be globally exact.
- **Security headers via `@fastify/helmet`**, registered once at bootstrap — binds the base *Security baseline* header rule. The API's `*.vercel.app` URL is directly reachable, so it sets its own headers rather than trusting the Next app's. Helmet's default `Content-Security-Policy` (`default-src 'self'`) is fine for a JSON API; only tune or relax it if the API serves HTML.
- **SSRF guard + write-only secrets bind the base *Security baseline*.** Put the URL guard in a shared `shared/utils` (or domain) helper — public `https` only; **resolve the host and reject when the resolved IP is loopback/private/link-local or a cloud-metadata address** — called at config-save *and* immediately before the outbound `fetch` (a string-only re-check misses a host that resolves to a private IP). For admin-managed secrets, the read DTO **masks** each secret and adds a `…Set` flag, and the update handler **preserves** a blank field over the stored value, so a secret never round-trips to the client.

## Vercel entrypoint — `src/server.js` (load-bearing)

One file is both entrypoints:

- **Vercel path:** default-export an async `handler(req, res)` that lazily builds the app once (`appPromise ??= buildApp(...)` — **no top-level await**: the module must evaluate to a plain handler), `await app.ready()`, then dispatch with `app.server.emit("request", req, res)`. **Never call `listen()` on Vercel.**
- **Local path:** when `!process.env.VERCEL`, start a real listener on `PORT` (dev: `node --watch --env-file=../../.env src/server.js`) — so the base "exercise the actual endpoint over HTTP" verification gate works unchanged.
- `apps/backend/vercel.json`: an `@vercel/node` build of `src/server.js` with a catch-all rewrite to it — the whole Fastify app is **one function**, keeping Fastify's router (not Vercel's filesystem routing) in charge.
- **Serverless rules:** instances scale to zero and multiply — never rely on instance memory for correctness (durable state lives in Postgres or the signed cookie; a module-level memo is a cache, nothing more), and finish all work inside the request — no fire-and-forget after the response is sent; the instance freezes.

## Testing

- **Runner: `node:test`** (`node --test tests/`; `tests/` mirrors `src/`). Pack decision — rejected alternative: Jest/Vitest (plain ESM JavaScript needs no transform; the built-in runner is zero-dependency).
- Base per-ring kinds, bound: **domain** — plain units; **service** — build the app/container with `overrides` fakes; **controller** — Fastify `app.inject()` (no listener needed); **repo** — integration against the real local Postgres (use `--test-concurrency=1` where suites share it).

## Conflict register

- **Base says:** The stack is unchosen; the JS-style filenames and Express/Fastify-style HTTP layer are illustrative, not mandates. **In this stack:** bound for real — Fastify 5, plain JavaScript ESM, and no build/typecheck step. **Because:** the deploy target is a Vercel Node function running source directly; with duck-typed ports (base default), Zod-guarded edges, and JSDoc `@typedef`s, a transpile step adds weight without payoff here. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `build`/`typecheck` as explicit no-op scripts so workspace-wide commands stay green.
- **Base says:** Wiring lives in `container.js` as manual constructor wiring; reach for a DI container (e.g. Awilix) only once the graph grows unwieldy. **In this stack:** `container.js` is an Awilix container from day one. **Because:** registrations resolve at boot — a typo'd name throws at startup, never at request time — and `overrides` swaps any dependency for a test fake without touching rings; hand-rolling those two properties is exactly the unwieldiness the base defers. **Concretely:** DO register every port in `container.js` via `asFunction`/`asValue`; DON'T `import` awilix anywhere outside `container.js`.
