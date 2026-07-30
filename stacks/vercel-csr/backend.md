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
- Complete background work before returning the response.

## Entrypoint

Use `src/server.js` for Vercel and local development.

- Build and memoise the Fastify app lazily without top-level await.
- On Vercel, export the request handler, call `app.ready()`, and dispatch through `app.server.emit("request", req, res)`.
- Never call `listen()` on Vercel.
- Outside Vercel, call `listen(PORT)` so local verification exercises HTTP.
- Configure `apps/backend/vercel.json` as one `@vercel/node` function with a catch-all rewrite to `src/server.js`.

## Testing

- Test domain rules as plain units.
- Test services through container overrides.
- Test controllers with `app.inject()`.
- Test repositories against local Postgres and serialise suites that share state.

## Conflict register

- **Base says:** the JavaScript filenames and Express/Fastify HTTP layer are illustrative. **In this stack:** Fastify 5 and plain JavaScript ESM are mandatory, with no backend build or typecheck. **Because:** Vercel runs the source directly and Zod guards the edges. **Concretely:** DON'T add TypeScript or a transpiler under `apps/backend`; keep build and typecheck as explicit no-op scripts.
- **Base says:** use manual constructor wiring until a DI container is justified. **In this stack:** `container.js` uses Awilix from Day 1. **Because:** boot-time resolution and named test overrides are part of this pack's wiring contract. **Concretely:** DO bind every port in `container.js`; DON'T import Awilix anywhere else.
