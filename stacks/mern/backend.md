# Express 5 — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) and the root `CLAUDE.md` to **Express 5, plain JavaScript (ESM), run as a long-lived Node process**. Read those first; this file does not restate them. Data layer → `./db.md`; where the process runs → the base `infra/CLAUDE.md` contract (this pack ships no `infra.md`).

## Stack binding at a glance

- **HTTP layer: Express 5, used directly** — no framework on top. The base's illustrative "Express/Fastify-style" layer is bound to real Express: routers and middleware are the aspect mechanism the base already names for Node. Pack decision — rejected alternative: Fastify (the Vercel siblings' pick): the E in MERN is the identity this pack exists to offer, and Express 5 forwards a rejected async handler to the error middleware natively — the historic reason to leave Express is gone.
- **Language: plain JavaScript, ESM** (`"type": "module"`), with **no build or typecheck step** — the `build`/`typecheck` scripts are explicit no-ops, not omissions. Pack decision — rejected alternative: TypeScript (see conflict register).
- **Folder layout: the base shape verbatim** — `modules/<feature>/{domain,service,repo,controller,dtos}`, `shared/{aspects,utils}`, `container.js`. No mapping table needed; this stack is the layout the base illustrates.
- **Validation: Zod** — `dtos/` are Zod schemas at the controller edge; one Zod schema parses env at boot.

## Composition root — `container.js`, manual wiring (base default)

- The base's manual factory wiring stands — no DI container. One exported `buildContainer({ env, overrides })` wires every repo, gateway, and use case as plain factory calls (`makeCreateOrder({ orderRepo, withTransaction })`), resolved once at boot; tests replace any dependency by name via `overrides` without touching a ring.

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
- **`trust proxy` from validated config** — deployed, the API sits behind the SPA origin's `/api` reverse proxy (`./frontend.md`), so without it rate limiting and logging key on the proxy IP, not the client.
- **Rate limiting: `express-rate-limit`** — its in-memory store is per-process; fine for a single long-lived instance. A limit that must survive restarts or span instances keeps its counters in MongoDB (the otp-auth binding below does).
- **SSRF guard + write-only secrets bind the base *Security baseline*.** The URL guard is a shared helper — public `https` only; **resolve the host and reject loopback/private/link-local/cloud-metadata IPs** — called at config-save *and* immediately before the outbound `fetch`. Admin-managed secrets: the read DTO masks each secret and adds a `…Set` flag; the update handler preserves a blank field over the stored value.

## Entrypoint — `src/server.js`

- `buildApp({ container })` assembles middleware + routers and returns the app; `src/server.js` builds it and calls `listen(PORT)`. Dev: `node --watch --env-file=../../.env src/server.js`.
- One long-lived process: in-process schedulers and memos are legitimate here — but anything correctness-bearing still lives in MongoDB, so a restart or a second instance never corrupts state.

## Testing

- **Runner: `node:test`** (`node --test tests/`; `tests/` mirrors `src/`). Pack decision — rejected alternative: Jest/Vitest (plain ESM JavaScript needs no transform; the built-in runner is zero-dependency).
- Base per-ring kinds, bound: **domain** — plain units; **service** — `buildContainer` with `overrides` fakes; **controller** — **supertest** against the `buildApp` instance (no listener needed); **repo** — integration against the real local MongoDB replica set (`--test-concurrency=1` where suites share it).

## Add-on bindings (if adopted)

- **test-mode** (`add-ons/test-mode/`): a `shared/aspects/` middleware resolves the mode signal from an inbound header onto the request context — fail closed: missing or unknown means production. In test mode the flag-gated integrations (the base default-off booleans) route to their stdout/no-op sinks. The test-user picker is a route gated on the same signal; it returns `[]` in production, and a test asserts that.
- **otp-auth** (`add-ons/otp-auth/`): model A (self-managed) — an `otp_challenges` collection via a repo-ring Mongoose model; its migrate-mongo migration ships the **unique index on (target, purpose)** — a duplicate-key error (`E11000`) resolves the double-submit race to `409` per the base status table — and a **TTL index** on the expiry field (TTL deletion is a lazy ~60s sweep, so verify still checks expiry itself). Hashing + timing-safe verify in `shared/utils/`; delivery through gateway adapters behind domain ports, gated by the default-off flags; phone numbers canonicalised to E.164 with `libphonenumber-js`. Attempt rate limits keep their counters in MongoDB; in test mode delivery is sinked to the structured log — the tester reads the real code there, and verify is never stubbed.

## Conflict register

- **Base says:** The stack is unchosen; the JS-style filenames and Express/Fastify-style HTTP layer are illustrative, not mandates. **In this stack:** bound for real — Express 5, plain JavaScript ESM, and no build/typecheck step. **Because:** a long-lived Node process runs source directly; with duck-typed ports (base default), Zod-guarded edges, and JSDoc `@typedef`s, a transpile step adds weight without payoff here. **Concretely:** DON'T add a `tsconfig`/transpiler under `apps/backend/`; keep `build`/`typecheck` as explicit no-op scripts so workspace-wide commands stay green.
