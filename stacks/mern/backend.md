# Express 5: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend onion to Express 5, plain JavaScript ESM, and a long-lived Node process.

## Bindings

| Concern | Binding |
|---|---|
| HTTP | Express routers and middleware |
| Language | plain JavaScript ESM; build and typecheck are explicit no-ops |
| Layout | base feature-first ring folders unchanged |
| Validation | Zod DTOs and one boot-time environment schema |
| Composition | manual factories in `container.js` |
| Tests | `node:test`, Supertest, real MongoDB for repositories |

Expose `buildContainer({ env, overrides })` and resolve the graph once at startup.

## HTTP edge

- Give each feature a `controller/routes.js` router factory.
- Mount feature routers under `/internal/v1` and keep `/health` unversioned.
- Add `/external/v1` only for a real third-party consumer.
- Parse with Zod, invoke one use case, and map the response DTO.
- Let Express 5 forward rejected async handlers. Do not add an async wrapper.

## Aspects

| Base concern | Express binding |
|---|---|
| Configuration | `env.js`; parse once and pass values inward |
| Database | `db.js`; open one Mongoose connection and expose `withTransaction` |
| Request context | middleware that seeds and returns the correlation ID |
| Errors | one four-argument middleware registered last |
| Authentication | router-scoped cookie-session guards |
| Security headers | `helmet` at bootstrap |
| Rate limiting | `express-rate-limit` |

- Apply feature-specific middleware at the router or route.
- Configure `trust proxy` through validated config.
- Use a shared rate-limit store when running several instances or when limits must survive restarts.
- Sign HTTP-only session cookies with `cookie-session`.

## Entrypoint

- Assemble middleware and routers in `buildApp({ container })`.
- Call `listen(PORT)` only in `src/server.js`.
- Run development with Node watch and the root environment file.
- Keep correctness-bearing state in MongoDB even when one long-lived process is deployed.

## Testing and gotcha

- Test domain code as plain units.
- Test services through container overrides.
- Test controllers with Supertest against `buildApp`.
- Test repositories against the local replica set.
- Check expiry fields in reads; MongoDB TTL cleanup is delayed and cannot enforce immediate expiry.

## Conflict register

- **Base says:** the JavaScript filenames and Express/Fastify HTTP layer are illustrative. **In this stack:** Express 5 and plain JavaScript ESM are mandatory, with no backend build or typecheck. **Because:** the long-lived Node process runs source directly and Zod guards the edges. **Concretely:** DON'T add TypeScript or a transpiler under `apps/backend`; keep build and typecheck as explicit no-op scripts.
