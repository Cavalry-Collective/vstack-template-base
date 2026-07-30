# Fastify on Tencent SCF: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend to Fastify 4, plain JavaScript CommonJS, and a Tencent SCF Web Function.

## Bindings

| Concern | Binding |
|---|---|
| HTTP | Fastify plugins, hooks, and decorators |
| Language | plain JavaScript CommonJS; typecheck is an explicit no-op |
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

## SCF entrypoints

- Expose one `buildApp()` used by `handler.js` and local `server.js`.
- In SCF, listen on the platform port through `scf_bootstrap`; do not add an HTTP adapter wrapper.
- In development, listen on the configured port and add Swagger UI or multipart only outside production.
- Bundle `handler.js` and `migrate.js` with esbuild for Node 20.
- Externalise SQL drivers, install only `mysql2` into the deployment bundle, and include the built H5 files.
- Serve `/api/*` and the SPA from the same Fastify process.
- Keep correctness-bearing state in MySQL or signed cookies and finish work before returning.

## Testing

- Test services and repositories against the guarded `*_test` database.
- Test routes with `app.inject()`.
- Do not run the destructive suite against development or production data.

## Conflict register

- **Base says:** organise feature-first with a separate pure domain ring and a composition root. **In this stack:** organise layer-first, keep business rules in services, and use Fastify plus explicit repository arguments for wiring. **Because:** this pack targets a mostly CRUD product where the extra domain and DI layers did not earn their cost. **Concretely:** keep routes thin, services free of request objects, and repositories free of rules; DON'T scaffold a feature onion unless the domain becomes rules-heavy.
- **Base says:** the language and HTTP stack are illustrative. **In this stack:** Fastify 4 and plain CommonJS JavaScript are mandatory; esbuild packages but does not typecheck. **Because:** Tencent SCF runs the bundled Node artifact. **Concretely:** keep typecheck as a no-op and CommonJS throughout; DON'T add TypeScript or treat the bundle as type verification.
- **Base says:** inner rings raise domain failures and the controller maps them to transport. **In this stack:** services raise `HttpError` and one global Fastify handler produces the envelope. **Because:** this pack has no separate domain ring or parallel error taxonomy. **Concretely:** raise `HttpError` only from services; DON'T send replies outside routes or the global handler, and DON'T throw it from repositories.
