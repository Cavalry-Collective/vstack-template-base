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
- Use route handlers only for `/health`, webhooks, real external consumers, queue consumers, and streamed responses such as long inference.
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
- Finish request-scoped work before returning a response. Hand anything longer to a queue message (see *Background work: Vercel Queues*).

## Streaming and long-running inference

Bind the llm-calls add-on's streaming inference to Vercel Functions on Fluid compute.

- Stream inference through a route handler that returns a streamed `Response`. Server Actions are not a streaming surface for long model calls.
- Raise `maxDuration` per route (`export const maxDuration = ...`) above the worst-case model call: the default is 300 s, the maximum 800 s on Pro/Enterprise (1,800 s behind Vercel's extended-duration beta).
- Streaming does not extend `maxDuration`; it keeps idle timeouts on the path from closing the connection. A call that can outlast the ceiling runs as a queue job instead.
- Fluid compute bills active CPU rather than total running time, so a handler that spends minutes awaiting a provider stream stays cheap.

## Background work: Vercel Queues

Bind asynchronous jobs, including the llm-calls add-on's asynchronous inference, to Vercel Queues (`@vercel/queue`, public beta).

- Send with `send(topic, payload, { idempotencyKey })`, using the primary business record id as the idempotency key.
- Consume with an App Router route handler wrapped in `handleCallback`, registered under `experimentalTriggers` (type `queue/v2beta`) in `vercel.json`. Consumers have no public URL; Vercel invokes them internally.
- Treat the consumer as a controller edge: parse the message with a Zod DTO and invoke one use case.
- Delivery is at-least-once and not FIFO, even with a single consumer. Guard every consumer with the job record per the base idempotency rules.
- Failed messages retry until their TTL by default and there is no built-in dead-letter queue. Bound attempts in the consumer's `retry` callback: past the limit, record the failure and return `{ acknowledge: true }`.
- For inference jobs, check the job record before calling the model so a redelivery never re-runs a completed or in-flight generation. The SDK extends the message lease while the handler runs; keep the route's `maxDuration` above worst-case inference so the lease never lapses mid-call.
- Local dev publishes to the real queue service and runs handlers in-process; there is no offline emulator.

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
