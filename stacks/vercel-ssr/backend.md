# Next.js server side: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the relocated backend onion to the server side of the TypeScript Next.js application.

## Bindings

| Concern | Binding |
|---|---|
| Location | `apps/frontend/src/server/` |
| Delivery | server-only queries, Server Actions, external route handlers |
| Layout | base feature-first ring folders under `src/server/` |
| Validation | Zod DTOs |
| Composition | manual wiring in `container.ts` |
| Session | sealed HTTP-only cookie through `iron-session` |
| Tests | Vitest, real Postgres for repositories, Playwright for flows |

Open `container.ts` and every server aspect with `import 'server-only'`.

## Composition

- Keep manual constructor wiring in `container.ts`.
- Expose `buildContainer({ env, overrides })`.
- Memoise the built container per serverless instance.
- Keep Next.js imports out of the domain, service, and repository rings.

## Controller edge

UI code may import only a module's `controller/` files.

- Put reads in `controller/queries.ts`. Authorise, invoke one use case, return a plain DTO, and use React `cache()` for duplicate reads within one render.
- Put mutations in `controller/actions.ts` with `'use server'`. Parse, authorise, invoke one use case, and return the result envelope.
- Treat every Server Action as a publicly invokable endpoint. Never rely on the rendering UI for authorisation.
- Use route handlers only for `/health`, webhooks, and real external consumers.
- Return `{ ok: true, data }` or `{ ok: false, error: { code, message, correlationId } }` from actions.
- Keep the base pagination envelope on list queries.

## Aspects

| Base concern | Binding |
|---|---|
| Configuration | Zod-parsed `env.ts`; pass values inward |
| Database | one `pg.Pool` and `withTransaction` in `db.ts` |
| Request context | per-render and per-action correlation ID in `request-context.ts` |
| Errors | one wrapper for queries, actions, and route handlers |
| Authentication | session helpers in `auth.ts`; every query and action checks them |

- Keep session redirects in the UI layer and authorisation at the data edge.
- Use an in-memory limiter only for soft per-instance limits.
- Keep correctness-bearing state outside serverless memory.
- Finish all work before returning a response.

## Testing

- Test domain code as plain units.
- Test services with container overrides.
- Test repositories against local Postgres.
- Test a query or action directly when its controller mapping has logic.
- Use Playwright to prove the normal controller edge through the running application.

## Conflict register

- **Base says:** the repository has separate backend and frontend applications. **In this stack:** the backend onion lives under `apps/frontend/src/server/` and `apps/backend/` is removed during Day-1 setup. **Because:** one full-stack Next.js deployment does not need a second API application. **Concretely:** DON'T recreate `apps/backend`; keep all server rings under `src/server/`.
- **Base says:** the controller ring is an internal REST API under `/internal/v1`. **In this stack:** the application's own UI uses queries and Server Actions; REST applies only to external route handlers. **Because:** internal calls stay inside one module graph. **Concretely:** DON'T create route handlers for the application's own screens; preserve the base error and pagination fields at the function edge.
- **Base says:** verify backend work through its HTTP endpoint. **In this stack:** verify queries and actions through the running UI or direct invocation; route handlers still use HTTP. **Because:** internal controller edges do not have URLs. **Concretely:** state the flow and error envelope observed; DON'T claim a query or action is verified from unit tests alone.
