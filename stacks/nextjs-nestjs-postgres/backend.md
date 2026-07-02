# NestJS backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) to NestJS. Read the base first; this file does not restate it.

## Binding at a glance

Rejected alternatives are named here and nowhere else.

- **HTTP:** NestJS on the **Fastify adapter** (`@nestjs/platform-fastify`) — rejected: the default Express adapter; Fastify wins on throughput and its plugin ecosystem (`@fastify/cookie`, `@fastify/helmet`). Express is acceptable with a concrete reason; record the swap in the pack README.
- **Validation:** **Zod** via a small custom `ZodValidationPipe` — rejected: `class-validator` + `ValidationPipe`. Zod is decorator-free (identical in JS and TS, none of the Babel-fragile decorator metadata `class-validator` DTOs need) and shares one schema language with the frontend appendix (pack README).
- **Request context:** **`AsyncLocalStorage`** (recommend `nestjs-cls`), seeded by a DI-capable guard/interceptor — rejected: request-scoped providers (they rebuild the DI subtree per request) and global `app.use()` middleware (raw `req`/`res`, no DI access, path-to-regexp wildcard syntax — `(.*)`, not `*`).
- **Persistence:** Prisma over PostgreSQL, **owned by `db/`** (db appendix). This file covers only how Prisma is consumed in the repo ring — one adapter kind, not the whole ring. Prisma Migrate is forward-only; that override is registered once, in the db appendix.
- **Language:** TypeScript or plain JS — not mandated. Body rules are language-neutral with TS as the default spine; JS deltas are flagged `JS:` inline or collected in §JavaScript path — silence means "same in JS".

## Structure (base `modules/<feature>` → Nest feature module)

- One base feature module = one Nest `@Module()`. **Keep the base ring folders** (`domain/ service/ repo/ controller/ dtos/`) inside each module — never flatten into Nest's `*.controller.ts`/`*.service.ts` naming. `<feature>.module.ts` sits at the module root and is its composition root (see *Ports & DI*).
- `shared/aspects/` → an exported Nest **`SharedModule`** (guards, interceptors, pipes, filters); `shared/utils/` stays framework-free.
- Cross-module use goes through the other module's **exported service provider** or a shared port token — never by importing its `domain/`/`repo/`.

## Domain ring

- `domain/` is plain classes/functions with **zero Nest imports and zero Prisma imports** (see *Enforced boundaries*). Domain entities are not providers — construct them by hand in services/mappers, never resolve them from the container.
- No third-party `nestjs-prisma`; the pack ships its own `PrismaService` (see *Repo ring*).

## Ports & DI

- A **port** stays defined in `domain/`; to be injectable it carries a concrete DI token — TS: a decorator-free, Nest-import-free `abstract class` used as both type and token (`{ provide: UserRepository, useClass: PrismaUserRepository }`); `JS:` a `Symbol` token (§JavaScript path). The token is wiring metadata, not a language interface — the base's duck-typed port shape is intact.
- **Composition root = each module's `providers` array** — the only place binding a port token to an adapter. No `container.js`, no hand-rolled wiring graph (register).
- Inner code never imports a concrete adapter; services depend on port tokens by constructor injection only.

## Controller ring

- Nest `@Controller()` = base controller ring. DTOs are Zod schemas in `dtos/`; infer the type in TS (`JS:` duck-typed).
- **Prisma types never appear in DTOs.** Map domain objects to response DTOs explicitly — never spread a domain entity onto the response, never return a Prisma row (full-row over-fetch leaks sensitive fields).

## Error mapping

- The **single global exception filter** is the only site mapping domain errors → HTTP status (base status-code table).
- `domain/` and `service/` throw plain domain errors, never Nest `HttpException` — that leaks transport concerns past the controller ring; lint-forbidden outside the controller ring and the filter.

## Aspects (base AOP → Nest constructs)

| Base aspect | Nest construct | Scope |
|---|---|---|
| Auth (edge) | Guard (`CanActivate`) | handler/controller/module |
| Validation | Pipe (`ZodValidationPipe`) | handler/global |
| Request context / correlation id | edge seeder into ALS | bootstrap, once |
| Structured logging | global interceptor (or `pino-http`) reading the id | bootstrap, once |
| Error mapping | one global exception filter | bootstrap, once |
| Audit / analytics | one injectable `AuditService` | injected where used |
| Transaction boundary | service ring (see below) | — |

- Scope-to-subtree, Nest form: prefer `@UseGuards`/`@UseInterceptors`/module `providers` over `app.useGlobalX()`. Only the error filter and the single correlation-id + logging path (seeder + interceptor — two halves of one path) register globally (register).
- All audit/analytics events flow through **one injectable `AuditService`** injected into the emitting services — never scattered across handlers.

## Service ring

- A use case = one `@Injectable()` in `service/`, depending only on domain + port tokens.
- **Transactions:** the boundary stays in the service ring via a `TransactionRunner` unit-of-work port defined in `domain/`, implemented in `repo/` over Prisma's interactive transaction (binding: db appendix). `TransactionRunner.run(work)` yields a transaction-scoped repository set (a repo factory already bound to `tx`); the service calls its repos inside that callback and **never names `Prisma.TransactionClient`**. No `tx` travels via ALS — request-context ALS is edge-only and unrelated.
- **YAGNI guard (register):** `TransactionRunner` only when a use case spans multiple repository writes; a single-repository write relies on the repo's own atomic call.
- **No nested use-case transactions:** a use-case service never calls another use-case service — compose in domain services within the one boundary.

## Repo ring — Prisma adapters

- Repositories in `repo/` implement domain port tokens over `PrismaClient`, bound in the module `providers` array.
- Every repository carries a **mapper**; Prisma row types/objects never cross inward.
- **Explicit `select`s** — no implicit full-row returns where a subset suffices.
- One **`PrismaService`** (extends `PrismaClient`; connect/disconnect in `OnModuleInit`/`OnModuleDestroy`) provided by a shared `PrismaModule` and injected into repositories — never `new PrismaClient()` in a repository.

## Repo ring — external clients

- External gateways (storage, mail/SMS, payments, translation) are also repo-ring adapters implementing domain ports, each with its own mapper — the repo ring is not Prisma-only.
- HTTP integrations bind to `@nestjs/axios` `HttpService` (or a thin `fetch` wrapper) with per-call timeout, bounded retry + backoff, and idempotency keys; queue/scheduled work binds to BullMQ / `@nestjs/schedule`. The base *Integrations* rules apply unchanged; the decisions they enforce stay in the domain.

## Request context / correlation id

- The ALS seeder generates the correlation id, honouring inbound `x-request-id`/`x-correlation-id`.
- **Inner rings never read ALS.** The controller pulls context at the edge and passes it inward as plain values (base: "passed inward as an argument") — the ALS store is an edge/aspect detail only.

## Cookies

Register `@fastify/cookie` at bootstrap. Cookies are read/written at the controller/aspect edge via the Fastify request and passed inward as plain values — never read by an inner ring.

## Config

`@nestjs/config` with one Zod schema validated at boot (`validate`) — fail fast on missing/invalid env with a named error, never a mid-request undefined. No `process.env` reads outside the config module.

## Enforced boundaries (lint)

The single import-boundary checklist (ESLint `no-restricted-imports` / `import/no-restricted-paths`); verify changes against it:

- `domain/` may not import `@nestjs/*` or `@prisma/client`.
- `service/` may not import `repo/` or `PrismaClient`.
- `@prisma/client` only under `repo/` and `PrismaService`.
- `HttpException` only in the controller ring and the global exception filter.
- `process.env` only in the config module.

## App bootstrap & routes

- `main` creates the Fastify Nest app and registers the global exception filter, the global `ZodValidationPipe`, `@fastify/cookie`, and the correlation-id/logging path.
- **Route scope vs version are separate concerns.** Nest's URI version segment is the `v1` token only; one global prefix + `enableVersioning` cannot yield both `/internal/v1` and `/external/v1`. Model `internal`/`external` as a **path segment** (e.g. `@Controller({ path: 'users', version: '1' })` under an `internal`/`external` route group), default internal. All other base RESTful conventions apply unchanged.
- The **Next.js server tier** (server-to-server calls) is an internal trusted consumer on `/internal/v1`; only genuinely third-party consumers use `/external/v1`.

## Security bindings

The base *Security baseline* states the rules; these are the mechanisms.

- **Headers:** `@fastify/helmet` registered once at bootstrap on the Fastify adapter. Helmet's default CSP (`default-src 'self'`) suits a JSON API; tune it only if the API serves HTML.
- **SSRF guard:** one shared URL-guard helper called by the repo-ring gateway adapters — at config-save *and* again immediately before each outbound request — allowing only permitted schemes and, **after DNS resolution**, rejecting loopback/private/link-local/cloud-metadata IPs (a string-only re-check misses a host that resolves private).
- **Write-only secrets:** response DTOs (Zod schemas in `dtos/`) mask stored secrets to a `…Set`/configured flag; update handlers treat a blank value as "keep the existing secret".

## Add-on bindings

For each add-on kept under `add-ons/`:

- **test-mode:** the mode signal is an inbound header (e.g. `x-test-mode`) resolved once by a `SharedModule` guard that stamps the request context — absent/unknown ⇒ production, fail closed. Each risky integration's no-op/logging sink lives in its repo-ring gateway adapter behind that integration's default-off config boolean (base *Integrations*). The test-user picker endpoint is a controller gated by the mode guard, returning empty in production.
- **otp-auth:** model A (self-managed). The store is a Prisma model — HMAC-SHA256 code hash via `node:crypto` (timing-safe compare), short TTL, a `purpose` column, unique on target + purpose so the verify race resolves to the base 409. Rate-limit counters live in Postgres beside the challenge — no Redis unless the project already runs one. Delivery goes through the mail/SMS gateway adapters behind the default-off booleans; test mode swaps delivery only.

## Testing per ring

- **Domain:** plain instantiation — no `Test.createTestingModule`.
- **Service:** `Test.createTestingModule` with in-memory port fakes bound to the port tokens (`useValue`/`useClass`); no Prisma, no DB.
- **Controller / e2e:** Nest `Test` against the assembled module, driven by Fastify's native `.inject()` (`app.getHttpAdapter().getInstance().inject()`); `supertest` is the Express-adapter fallback only.
- **Repo:** integration against real Postgres (per-worktree/scratch DB — db appendix); never mock Prisma.

## JavaScript path

`JS:` deltas flagged in the body are collected and expanded here; everything unflagged is identical in JS.

- **Babel is required** so Nest decorators + DI metadata work without `tsc`. Use a known-good `babel.config` (or `nest-cli` with the SWC builder) rather than hand-ordering plugins. If hand-listing: `@babel/plugin-proposal-decorators` with `{ legacy: true }` (`legacy` is the option, not a separate plugin), `@babel/plugin-transform-class-properties`, `babel-plugin-transform-typescript-metadata` (ordered **before** the decorators plugin so `design:type`/`design:paramtypes` emit), and `babel-plugin-parameter-decorator` (constructor-parameter DI — omitting it is the usual "Nest can't resolve dependencies" cause). Plugin order matters.
- **Port tokens:** a `Symbol` (or string) exported from `domain/` (`export const USER_REPOSITORY = Symbol('UserRepository')`), the port shape pinned by a JSDoc `@typedef`; inject via `@Inject(USER_REPOSITORY)`.
- **DTOs / config schemas:** Zod schemas used directly (duck-typed, no inferred type).
- `@nestjs/config` `validate` and the testing utilities (`Test.createTestingModule`, Fastify `.inject()`) are identical in JS.

## Conflict register

- **Base says:** wiring lives in `container.js`; manual constructor wiring by default, a DI container only once the graph grows unwieldy. **In this stack:** no `container.js`, no manual graph — each module's `providers` array is the composition root from day one, and `shared/aspects` becomes a `SharedModule`. **Because:** Nest's IoC container is mandatory infrastructure; a parallel graph or second container duplicates it. **Concretely:** DO bind every port token in the module `providers` array; DON'T add `container.js` or Awilix.
- **Base says:** scope each cross-cutting aspect to the subtree that needs it, not globally. **In this stack:** the error filter and the single correlation-id + logging path register globally at bootstrap; everything else stays branch-scoped via `@UseGuards`/`@UseInterceptors`/module providers. **Because:** those two are genuinely app-wide singletons. **Concretely:** DON'T reach for `app.useGlobalX()` for anything but those two.
- **Base says:** the service owns the transaction boundary — one transaction per use case. **In this stack:** an explicit `TransactionRunner` boundary opens only for use cases spanning multiple repository writes; a single-repository write relies on the repo's atomic call. **Because:** a unit-of-work wrapper around every trivial write is speculative machinery. **Concretely:** DON'T open a `TransactionRunner` boundary for a single-repository write.
