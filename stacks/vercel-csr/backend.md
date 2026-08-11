# Fastify on Vercel: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend onion to Fastify 5, plain JavaScript ESM, and one Vercel serverless function.

## Bindings

| Concern | Binding |
|---|---|
| HTTP | Fastify plugins, hooks, and decorators |
| Language | plain JavaScript ESM; build and typecheck are explicit no-ops |
| Layout | base feature-first ring folders unchanged |
| Validation | Zod DTOs and one boot-time environment schema |
| Composition | Awilix in `container.js` |
| Tests | `node:test`, Fastify `app.inject()`, real Postgres for repos |

## Composition

- Register every repository, gateway, and use case in `container.js` with `asFunction` or `asValue`.
- Resolve registrations once while registering routes.
- Keep Awilix out of every ring.
- Expose `buildContainer({ env, overrides })` so tests can replace registrations by name.

## HTTP edge

- Give each feature one `controller/routes.js` Fastify plugin.
- Register feature plugins under `/internal/v1` and keep `/health` unversioned.
- Add `/external/v1` only for a real third-party consumer.
- Parse the request with the feature's Zod DTO, invoke one use case, and map the response DTO.

## Aspects

| Base concern | Fastify binding |
|---|---|
| Configuration | `env.js`; parse once and pass values inward |
| Database | `db.js`; create one `pg.Pool` and expose `withTransaction` |
| Request context | `request-context.js`; seed and return the correlation ID |
| Errors | one `setErrorHandler` producing the base error envelope |
| Authentication | cookie-session `preHandler` hooks |
| Security headers | `@fastify/helmet` at bootstrap |
| Rate limiting | `@fastify/rate-limit`; in-memory limits are soft per instance |

Use Fastify encapsulation to scope aspects to the route subtree that needs them. Register only request context, errors, cookies, and the database pool application-wide.

## Sessions and serverless behaviour

- Sign HTTP-only session cookies with `@fastify/cookie` and `SESSION_SECRET`.
- Set validated `TRUST_PROXY=true` in Vercel so source IPs survive the proxy.
- Use a shared store when a rate limit must be globally exact.
- Keep correctness-bearing state in Postgres or the signed cookie.
- Complete request-scoped work before returning the response. Hand anything longer to a queue message (see *Background work: Vercel Queues*).

## Streaming and long-running inference

Bind the llm-calls add-on's streaming inference to Vercel Functions on Fluid compute.

- Stream by returning a Node `Readable` or web `ReadableStream` from the Fastify handler; Vercel streams function responses natively.
- Raise the API function's `maxDuration` above the worst-case model call: the default is 300 s, the maximum 800 s on Pro/Enterprise (1,800 s behind Vercel's extended-duration beta).
- Streaming does not extend `maxDuration`; it keeps idle timeouts on the path from closing the connection. A call that can outlast the ceiling runs as a queue job instead.
- Fluid compute bills active CPU rather than total running time, so a handler that spends minutes awaiting a provider stream stays cheap.

## Background work: Vercel Queues

Bind asynchronous jobs, including the llm-calls add-on's asynchronous inference, to Vercel Queues (`@vercel/queue`, public beta).

- Send with `send(topic, payload, { idempotencyKey })`, using the primary business record id as the idempotency key.
- Consume with a route handler wrapped in `handleCallback`, registered under `experimentalTriggers` (type `queue/v2beta`) in the API project's `vercel.json`. Consumers have no public URL; Vercel invokes them internally.
- Treat the consumer as a controller-ring edge: parse the message with a Zod DTO and invoke one use case.
- Delivery is at-least-once and not FIFO, even with a single consumer. Guard every consumer with the job record per the base idempotency rules.
- Failed messages retry until their TTL by default and there is no built-in dead-letter queue. Bound attempts in the consumer's `retry` callback: past the limit, record the failure and return `{ acknowledge: true }`.
- For inference jobs, check the job record before calling the model so a redelivery never re-runs a completed or in-flight generation. The SDK extends the message lease while the handler runs; keep `maxDuration` above worst-case inference so the lease never lapses mid-call.
- Local dev publishes to the real queue service and runs handlers in-process; there is no offline emulator.

## Entrypoint

Vercel detects Fastify and deploys it with no configuration, so the entrypoint is an ordinary Fastify server. Local and deployed runs execute the same file.

- Name the entrypoint `src/server.js` — one of the filenames Vercel detects.
- Build the app in `buildApp()` and start it in the entrypoint with `app.listen(...)`, in every environment.
- Take the port from the environment: `port: Number(process.env.PORT) || 3000`. Vercel supplies `PORT`.
- Bind `host: "0.0.0.0"` so the platform can reach the server.
- Avoid top-level await in the entrypoint; keep plugin registration inside `buildApp()`.
- Do not hand-roll a serverless adapter. No `@vercel/node` handler export, no `app.ready()` bridge, no `app.server.emit("request", req, res)`.
- Add `apps/backend/vercel.json` only when a setting genuinely differs from the defaults. A rewrite to the entrypoint is not one of them.
- Run `vercel dev` to exercise the deployed request path locally; a plain `node src/server.js` is enough for unit-level verification.

**This holds because Vercel's Git integration builds the project** — the deployment model `./infra.md` mandates — and detection runs on every push. Check that before applying this section. A project that has left that model, with Git deployments disabled and `vercel build --prebuilt` running in CI, builds from settings fetched by `vercel pull` and gets no detection at all: the backend builds as a static site and the deploy stops at `No Output Directory named "public" found`.

Restore the Git integration rather than working around it. Where a project genuinely cannot — a deploy that must migrate the database *before* the new code goes live is the usual reason — declare the build instead: `builds: [{ src: "src/server.js", use: "@vercel/node" }]` with a catch-all route to it, and export a default `handler(req, res)` that dispatches through Fastify, guarding the local `listen()` on `!process.env.VERCEL`. **Change both halves together.** The config alone deploys a file that exports no handler, which 404s every request — worse than the failed build, because it reaches production before a health check catches it.

## Reference

- [Fastify on Vercel](https://vercel.com/docs/frameworks/backend/fastify) — entrypoint detection and the supported filenames.
- [Vercel Queues](https://vercel.com/docs/queues) — concepts, SDK, and limits.
- [Function duration](https://vercel.com/docs/functions/configuring-functions/duration) — `maxDuration` defaults and maximums.

## Testing

- Test domain rules as plain units.
- Test services through container overrides.
- Test controllers with `app.inject()`.
- Test repositories against local Postgres and serialise suites that share state.

## Conflict register

- **Base says:** the JavaScript filenames and Express/Fastify HTTP layer are illustrative. **In this stack:** Fastify 5 and plain JavaScript ESM are mandatory, with no backend build or typecheck. **Because:** Vercel runs the source directly and Zod guards the edges. **Concretely:** DON'T add TypeScript or a transpiler under `apps/backend`; keep build and typecheck as explicit no-op scripts.
- **Base says:** use manual constructor wiring until a DI container is justified. **In this stack:** `container.js` uses Awilix from Day 1. **Because:** boot-time resolution and named test overrides are part of this pack's wiring contract. **Concretely:** DO bind every port in `container.js`; DON'T import Awilix anywhere else.
