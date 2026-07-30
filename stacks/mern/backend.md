# Express 5 — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) and the root `CLAUDE.md` to **Express 5, plain JavaScript (ESM), run as a long-lived Node process**. Read those first; this file does not restate them.

## Scope

This file owns the HTTP layer, composition root, aspects, edge hardening, entrypoint, and backend testing. Data layer → `./db.md`; where the process runs → the base `infra/CLAUDE.md` contract (this pack ships no `infra.md`). Rejected alternatives for the tool picks are in the pack README → *Pack decisions*.

## Stack binding at a glance

- **HTTP layer: Express 5, used directly** — no framework on top. The base's illustrative "Express/Fastify-style" layer is bound to real Express: routers and middleware are the aspect mechanism the base already names for Node.
- **Language: plain JavaScript, ESM** (`"type": "module"`), with **no build or typecheck step** — the `build`/`typecheck` scripts are explicit no-ops (conflict register below).
- **Folder layout: the base shape verbatim** — `modules/<feature>/{domain,service,repo,controller,dtos}`, `shared/{aspects,utils}`, `container.js`; this stack is the layout the base illustrates.
- **Composition root: `container.js`, manual factory wiring** (the base default — no DI container). One exported `buildContainer({ env, overrides })` wires every repo, gateway, and use case as plain factory calls (`makeCreateOrder({ orderRepo, withTransaction })`), resolved once at boot; tests replace any dependency by name via `overrides` without touching a ring.
- **Validation: Zod** — `dtos/` are Zod schemas at the controller edge; one Zod schema parses env at boot.

## Controller ring — one Express router per module

- Each module exposes `controller/routes.js` — a factory receiving its use cases from the container and returning an `express.Router`. `app.js` mounts every module router under **one `/internal/v1` prefix**, plus an unversioned `/health` — the base visibility/versioning rule as a mount path; add an `/external/v1` mount only when a genuinely third-party consumer exists.
- A handler parses with the module's Zod DTO, invokes **one** use case, and maps the result to a response DTO — base rules, bound to Express handler signatures.
- **Async errors need no wrapper.** Express 5 routes a rejected handler promise to the error middleware; a hand-rolled `asyncHandler`/`try-catch` wrapper is the greppable smell.

## Aspects — `shared/aspects/` as Express middleware

| Base concern | Binding |
|---|---|
| Config | `env.js` — one Zod schema, parsed once at boot (`loadEnv()`), **fail fast** on missing/invalid keys; values passed inward — no `process.env` reads in rings |
| DB access | `db.js` — opens the single Mongoose connection and exports `withTransaction` (mechanics in `./db.md`) |
| Request context | `request-context.js` — correlation id seeded per request at the edge, passed inward as a plain value, echoed as the `x-correlation-id` header |
| Errors | `errors.js` — **one** 4-arg error middleware, registered last, mapping domain errors (plain error helpers in `shared/utils/`) → the base *Error responses* envelope; inner rings never shape an HTTP response |
| Auth | `auth.js` — cookie-session guard middleware applied to the routers that need it |

**Scope-to-subtree = router-level `use`.** Apply an aspect on the module router (or route) that needs it — not `app.use` by reflex; only the error middleware, request context, session/cookie handling, helmet, and the JSON body parser register app-wide at bootstrap.

## Sessions & edge hardening

- **Sessions are signed HTTP-only cookies** (`cookie-session` with `SESSION_SECRET`) — stateless, no session store to run; binds the base cookie-session default.
- **Security headers via `helmet`**, registered once at bootstrap — binds the base *Security baseline* header rule. Helmet's default `Content-Security-Policy` is fine for a JSON API; tune it only if the API ever serves HTML.
- **`trust proxy` from validated config** — deployed, the API sits behind the SPA origin's `/api` reverse proxy (`./frontend.md`); without it, rate limiting and logging key on the proxy IP, not the client.
- **Rate limiting: `express-rate-limit`** — its in-memory store is per-process; fine for a single long-lived instance. A limit that must survive restarts or span instances keeps its counters in MongoDB.
- **SSRF guard** (base *Security baseline*) — a shared URL-guard helper allows public `https` only: resolve the host, reject loopback/private/link-local/cloud-metadata IPs. It runs at config-save *and* immediately before the outbound `fetch`.
- **Write-only secrets** (base *Security baseline*) — the read DTO masks each admin-managed secret and adds a `…Set` flag; the update handler preserves a blank field over the stored value.

## Entrypoint — `src/server.js`

- `buildApp({ container })` assembles middleware + routers and returns the app; `src/server.js` builds it and calls `listen(PORT)`. Dev: `node --watch --env-file=../../.env src/server.js`.
- One long-lived process: in-process schedulers and memos are legitimate here — but anything correctness-bearing still lives in MongoDB, so a restart or a second instance never corrupts state.

## Testing

- **Runner: `node:test`** (`node --test tests/`; `tests/` mirrors `src/`).
- Base per-ring kinds, bound: **domain** — plain units; **service** — `buildContainer` with `overrides` fakes; **controller** — **supertest** against the `buildApp` instance (no listener needed); **repo** — integration against the real local MongoDB replica set (`--test-concurrency=1` where suites share it).

## Gotchas

- **TTL deletion is a lazy sweep** (roughly every 60 seconds): an expired document can still be readable, so any read that depends on expiry checks the expiry field itself — never rely on a TTL index for correctness.

## Conflict register

- **Base says:** The stack is unchosen; the JS-style filenames and Express/Fastify-style HTTP layer are illustrative, not mandates. **In this stack:** bound for real — Express 5, plain JavaScript ESM, and no build/typecheck step. **Because:** a long-lived Node process runs source directly; with duck-typed ports (base default), Zod-guarded edges, and JSDoc `@typedef`s, a transpile step adds weight without payoff here. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `build`/`typecheck` as explicit no-op scripts so workspace-wide commands stay green.
