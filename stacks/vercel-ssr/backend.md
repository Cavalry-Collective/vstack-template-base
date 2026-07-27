# Next.js server side (full-stack) — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` — relocated at Day-1 to `apps/frontend/src/server/CLAUDE.md` (manifest → *The one-app restructure*) — to **the server side of the single Next.js app (App Router, TypeScript)**. Read the relocated base file first; this file does not restate it. Data layer → `./db.md`; the UI half → `./frontend.md`; provisioning and deploys → `./infra.md`.

## Stack binding at a glance

- **Delivery mechanism: Next.js itself — no separate HTTP framework.** The onion lives under `src/server/`; the App Router invokes its controller edge directly. Pack decision — rejected alternative: a second in-repo API server (it forks the deploy unit and re-introduces the network hop, proxy, and CORS surface this shape exists to avoid; the sibling `vercel` pack (would-be triple `react-fastify-postgres`, a client-rendered SPA) *is* that architecture, kept separate).
- **Language: TypeScript.** Ports are interfaces; DTOs are Zod schemas with inferred types.
- **Folder layout: the base shape under `src/server/`** — `src/server/modules/<feature>/{domain,service,repo,controller,dtos}`, `src/server/shared/{aspects,utils}`, `src/server/container.ts`. Path references in the relocated contract map `apps/backend/src/` → `apps/frontend/src/server/`.
- **The server boundary is enforced, not hoped for:** `container.ts` and every aspect open with `import 'server-only'`, so a client-component import fails the build instead of leaking server code into the bundle.

## Controller ring — queries, actions, and the external edge

The base controller ring ("validates input, invokes one use case, maps the result") binds to three edge kinds. UI code imports **only** `controller/` files — anything outside `src/server/` importing a module's `domain/`, `service/`, or `repo/` is the greppable violation.

- **Reads — `controller/queries.ts`:** server-only functions imported by Server Components: authorize, invoke one use case, return a plain DTO. Wrap each in React `cache()` so a layout and page calling the same query share one execution per render. List queries return the base pagination envelope shape (`data` / `page` / `recordsPerPage` / `totalRecords`) so tables stay uniform.
- **Mutations — `controller/actions.ts` (`'use server'`):** one Server Action per use case: parse the Zod DTO, authorize, invoke the use case, map the result. **Every Server Action is a publicly invokable HTTP endpoint** — it authorizes inside itself, never relying on the UI that renders it, and treats malformed input as a parse failure, not a crash.
- **External HTTP — route handlers, only for consumers outside the app:** an unauthenticated `/health` liveness route (`app/health/route.ts`), webhooks, a future `/external/v1`. The base RESTful conventions govern these; each `route.ts` stays a thin delegate to the module's controller. Webhooks follow the base *Integrations* rules in full.
- **One result envelope:** every action returns `{ ok: true, data } | { ok: false, error: { code, message, correlationId } }` — the base error envelope's fields, transported as a typed value instead of an HTTP body. Route handlers map the same domain errors to the base HTTP envelope and status table.

## Composition root — `container.ts`

Manual constructor wiring per the base — no DI library; the base's "reach for a container only once the graph grows unwieldy" stands unchanged. `buildContainer({ env, overrides })` lets tests swap any port for a fake; the app resolves it through a module-level memo (`container ??= buildContainer(…)`) so each serverless instance wires once.

## Aspects — `src/server/shared/aspects/`

| Base concern | Binding |
|---|---|
| Config | `env.ts` — one Zod schema, parsed once per process (`loadEnv()`), **fail fast** on missing/invalid keys; values passed inward — no `process.env` reads in rings. `NEXT_PUBLIC_*` build-time values are the client-side exception and are never secrets. |
| DB access | `db.ts` — the single `pg.Pool` and `withTransaction` (mechanics in `./db.md`) |
| Request context | `request-context.ts` — a correlation id per request: React `cache(() => ({ correlationId: randomUUID() }))` within a render; a fresh id per action/route invocation. Passed inward as a plain value and stamped on every structured log line. |
| Errors | `errors.ts` — **one** edge wrapper used by every query, action, and route handler, mapping domain errors (plain error helpers in `shared/utils/`) → the result envelope / HTTP envelope; inner rings never shape a response |
| Auth | `auth.ts` — session read/verify helpers. **The data edge is the security boundary:** every query and action authorizes; a page/layout redirect is UX on top, never the only check. |

## Sessions & edge concerns (serverless-shaped)

- **Sessions are sealed HTTP-only cookies via `iron-session`** (`SESSION_SECRET` in the env schema) — stateless, no session store. Pack decision — rejected alternatives: hand-rolled cookie signing (the base never-hand-roll-auth/crypto rule) and a full auth framework (adopt Auth.js only when third-party OAuth providers genuinely appear, as a recorded choice).
- **Same-origin by construction.** One app serves UI and data — no proxy, no CORS surface; the base same-origin-first rule is satisfied with zero configuration. Don't add cross-origin affordances speculatively.
- **Rate limiting:** a per-instance in-memory limiter on sensitive edges is a soft limit only (serverless instances multiply); a limit that must be globally exact keeps its counters in Postgres — record that as a decision when the need appears.
- **SSRF guard + write-only secrets bind the base *Security baseline*.** The URL guard lives in `shared/utils/` — public `https` only; **resolve the host and reject when the resolved IP is loopback/private/link-local or a cloud-metadata address** — called at config-save *and* immediately before the outbound `fetch`. Admin-managed secrets: read DTOs mask the value and expose a `…Set` flag; the update path treats a blank field as "keep the stored secret".
- **Serverless rules:** instances scale to zero and multiply — never rely on instance memory for correctness (durable state lives in Postgres or the session cookie; a module-level memo is a cache, nothing more), and finish all work inside the request — no fire-and-forget after the response is sent; the instance freezes.

## Testing

- **Runner: Vitest** (`tests/` mirrors `src/server/`). Pack decision — rejected alternatives: `node:test` (no first-class TypeScript story without loader flags) and Jest (transform-heavy on ESM + TS).
- Base per-ring kinds, bound: **domain** — plain units; **service** — use cases via `buildContainer({ overrides })` fakes; **repo** — integration against the real local Postgres (share it carefully across suites); **controller edge** — actions and queries are plain async functions, unit-test one directly when it accrues logic; the default edge coverage is the Playwright e2e suite (`./frontend.md` *Testing*) driving the real screens.

## Add-on bindings (if adopted)

- **test-mode** (`add-ons/test-mode/`): the mode signal is an inbound header/signed cookie resolved once in `request-context.ts` onto the request context — fail closed: missing or unknown means production. In test mode the flag-gated integrations (the base default-off booleans) route to their stdout/no-op sinks. The test-user picker is a query gated on the same signal; it returns `[]` in production, and a test asserts that.
- **otp-auth** (`add-ons/otp-auth/`): model A (self-managed) — an `otp_challenge` table (hashed code, short TTL, `purpose` column) via node-pg-migrate; hashing + timing-safe verify in `shared/utils/`; delivery through gateway adapters behind domain ports, gated by the default-off flags; phone numbers canonicalised to E.164 with `libphonenumber-js`. A unique constraint on (target, purpose) resolves the double-submit race to the domain conflict error, which the verify action returns as its envelope `error.code` — the client treats it as "already done, proceed". Attempt rate limits keep their counters in Postgres (no separate store on this pack); in test mode delivery is sinked to the structured log — the tester reads the real code there, and verify is never stubbed.
- **llm-calls** (`add-ons/llm-calls/`): the provider SDK lives in a repo-ring gateway adapter behind a domain port, wired in `container.ts`; model id, token/cost caps, timeout, and the default-off flag are keys in the env schema. The canned-response sink is the adapter's no-op twin — selected by the flag or the test-mode signal, so it doubles as the test-mode stub. Calls finish inside the request (no fire-and-forget); per-call usage (model, tokens, latency, user/tenant) is a structured log line, queryable through the log drain (`./infra.md` → *Observability*).

## Conflict register

- **Base says:** the repo has two apps — `apps/backend` (the API server) and `apps/frontend` — with the onion contract at `apps/backend/CLAUDE.md` (root `CLAUDE.md` *Repo shape*). **In this stack:** one full-stack Next.js app; the onion lives under `apps/frontend/src/server/`, the contract file relocates there at Day-1, and `apps/backend/` is deleted (manifest → *The one-app restructure*). **Because:** full-stack Next.js collapses delivery and UI into one deployable — a separate API app would fork the deploy unit for nothing. **Concretely:** DON'T create or resurrect `apps/backend/`; server code goes under `apps/frontend/src/server/`, where every ring rule of the relocated contract still applies.
- **Base says:** the controller ring is REST handlers under an `/internal/v1` prefix, and the HTTP error envelope / status-code table shape every response. **In this stack:** the app's own UI is served by server-only queries and Server Actions — no internal HTTP API, no `/internal/v1`; the RESTful conventions govern only the genuinely external route handlers (`/health`, webhooks, a future `/external/v1`). **Because:** inside one app there is no internal network hop to version or shape; queries and actions are direct function edges. **Concretely:** DON'T build route handlers for the app's own screens; DO keep the base envelope fields (`code` / `message` / `correlationId`) in the action result envelope and the pagination envelope shape on list queries — the contract discipline survives the transport change.
- **Base says:** verifying a backend change means exercising the actual endpoint over HTTP — the happy path plus at least one error path. **In this stack:** queries and actions have no URL to hit; verification is driving the touched flow in the running app (or invoking the action/query directly), happy path plus an error path, confirming the envelope `error.code` and correlation id; route handlers are still verified over HTTP. **Because:** the internal edge is a function boundary, not an HTTP one. **Concretely:** DO state which flow you drove and the envelope you observed; DON'T report a query/action change as verified from unit tests alone.
