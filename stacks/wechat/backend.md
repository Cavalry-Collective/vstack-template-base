# Fastify on Tencent SCF: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend to Fastify 5, plain JavaScript ESM, and a Tencent SCF Web Function deployed as a container image.

## Bindings

| Concern | Binding |
|---|---|
| HTTP | Fastify plugins, hooks, and decorators |
| Runtime | Node 24 LTS from your own container image |
| Language | plain JavaScript ESM; typecheck is an explicit no-op |
| Layout | layer-first `routes`, `services`, `repos`, `schemas`, `lib`, `utils`, `plugins` |
| Validation | Fastify JSON Schema with OpenAPI as source |
| Database | Knex passed explicitly to repositories |
| Tests | Vitest, Fastify `inject()`, guarded test MySQL |

## Layers

- Put request validation, guards, one service call, and response mapping in `routes/`.
- Put business rules, transactions, integrations, and audit calls in `services/`.
- Put Knex query construction in `repos/`; accept `db` or `trx` as the first argument.
- Put all request and response schemas in `schemas/`.
- Put side-effecting provider adapters in `lib/`.
- Put pure helpers and `HttpError` in `utils/`.
- Put Fastify aspects in `plugins/`.

Every route must attach request and response schemas. Keep `apps/backend/openapi.yaml` authoritative and run both drift checks.

## Aspects

| Base concern | Fastify binding |
|---|---|
| Configuration | validate in the entrypoint and pass values inward |
| Database | `plugins/db.js` exposes one Knex instance |
| Request context | `plugins/ctx.js` provides request ID, source IP, user agent, and logger |
| Errors | one global handler maps `HttpError` to the base envelope |
| Authentication | `plugins/auth.js` decorators used as `preHandler` hooks |
| Test mode | `plugins/tenant.js` resolves `x-tenant`; missing or unknown means production |
| Audit | services call the shared durable audit service |
| Integration flags | validated default-off booleans select real adapters or sinks |

Use Fastify encapsulation for subtree scope. Register only database, cookies, context, mode, and errors application-wide.

## Entrypoint

The SCF Web Function runs an ordinary HTTP server. Local and deployed runs execute the same `src/server.js`.

- Expose one `buildApp()`; `src/server.js` builds it and calls `app.listen(...)`.
- Listen on `0.0.0.0` and take the port from the environment: `port: Number(process.env.PORT) || 9000`. SCF routes requests to port 9000, so the image must default to it.
- Do not add a serverless handler wrapper. There is no `handler.js` and no event-to-request adapter.
- Serve `/api/*` and the built H5 bundle from the same Fastify process.
- Add Swagger UI and multipart support only outside production.
- Keep correctness-bearing state in MySQL or signed cookies, and finish background work before returning the response.

## Container image

- Build one image from an official `node:24-alpine` base and copy in the backend source, production `node_modules`, and the built H5 files.
- Install only production dependencies; `mysql2` is the sole SQL driver in the image.
- Set the image start command to `node src/server.js`. SCF starts the container with the configured command and expects the server on port 9000.
- Run migrations from the same image with an overridden command, not from the web function's own process.
- Do not bundle with esbuild. The image carries the source and its dependencies, so a bundler adds a build step that proves nothing.

## Legacy managed runtime

Only for a project that cannot use image deployment. This path requires **Node 18 and Fastify 4, both end-of-life**, so it is not the recommended production baseline.

- Deploy a zip package to the `Nodejs18.15` managed runtime.
- Add an executable `scf_bootstrap` that starts the server on port 9000.
- Pin `fastify@4` and keep CommonJS, since the managed runtime's Node major predates the ESM and Fastify 5 baseline above.
- Treat this as a migration waypoint and record the planned move to image deployment in root `CLAUDE.md` **Learnings**.

## Testing

- Test services and repositories against the guarded `*_test` database.
- Test routes with `app.inject()`.
- Do not run the destructive suite against development or production data.

## Conflict register

- **Base says:** organise feature-first with a separate pure domain ring and a composition root. **In this stack:** organise layer-first, keep business rules in services, and use Fastify plus explicit repository arguments for wiring. **Because:** this pack targets a mostly CRUD product where the extra domain and DI layers did not earn their cost. **Concretely:** keep routes thin, services free of request objects, and repositories free of rules; DON'T scaffold a feature onion unless the domain becomes rules-heavy.
- **Base says:** the language and HTTP stack are illustrative. **In this stack:** Fastify 5 and plain JavaScript ESM are mandatory, on Node 24 LTS from your own container image. **Because:** the image controls the runtime, so the stack tracks supported Fastify and Node majors instead of whatever a managed runtime last shipped. **Concretely:** keep typecheck as an explicit no-op; DON'T add TypeScript, and DON'T pin Fastify 4 outside the legacy managed-runtime path.
- **Base says:** inner rings raise domain failures and the controller maps them to transport. **In this stack:** services raise `HttpError` and one global Fastify handler produces the envelope. **Because:** this pack has no separate domain ring or parallel error taxonomy. **Concretely:** raise `HttpError` only from services; DON'T send replies outside routes or the global handler, and DON'T throw it from repositories.
