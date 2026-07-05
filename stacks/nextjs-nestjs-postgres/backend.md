# NestJS backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) and the root `CLAUDE.md` to NestJS. Read those first; this file does **not** restate them.

## How to read this file

- Rules are **language-neutral**; TypeScript is the default spine. JS-specific deltas are flagged `JS:` inline or collected in `## JavaScript path`. Silence means "same in JS", not "forgot".
- `## Enforced boundaries (lint)` is the single import-boundary checklist; ring sections reference it rather than restate it.
- Three library picks (Fastify adapter, Zod, AsyncLocalStorage) are **pack decisions with a rejected alternative named**, not things "NestJS" implies — also recorded in the pack README.

## Stack binding at a glance

- **HTTP layer:** NestJS on the **Fastify** adapter (`@nestjs/platform-fastify`). Pack decision — rejected alternative: the default Express adapter. Chosen for throughput and the Fastify plugin ecosystem (`@fastify/cookie` etc.). Express is acceptable with a concrete reason; record the swap in the pack README.
- **Persistence:** Prisma over PostgreSQL, **owned by `db/`** (see the db appendix). This file covers only how Prisma is **consumed** in the repo ring — one kind of repo adapter, not the whole ring.
- **Language:** TypeScript **or** plain JS — not mandated. The JS realization of every type-bearing rule lives in `## JavaScript path`.

## Module mapping (base `modules/<feature>` → Nest feature module)

- One base feature module = one Nest `@Module()`. **Keep the base ring folders** (`domain/ service/ repo/ controller/ dtos/`) **inside** each module — do not flatten into Nest's `*.controller.ts`/`*.service.ts` convention. `<feature>.module.ts` sits at the module root and is its composition root (see *Ports & DI*).
- `shared/aspects/` → a Nest **`SharedModule`** (guards, interceptors, pipes, filters) exported for reuse; `shared/utils/` stays framework-free.
- Cross-module use goes through the other module's **exported service provider** or a shared port token — never by importing its `domain/`/`repo/`.

## Domain ring purity

- `domain/` is **plain classes/functions only**, with **zero Nest imports and zero Prisma imports** (see *Enforced boundaries*). Domain entities are **not** Nest providers — they are constructed by hand in services/mappers, never resolved from the container.
- We deliberately do **not** use the third-party `nestjs-prisma` package; the pack provides its own `PrismaService` (see *Repo ring*).

## Ports & DI (composition root = the module's `providers` array)

- A **port** stays defined in `domain/`. To be injectable it needs a concrete **DI token**:
  - **Default (TS):** an `abstract class` used as both type and token (`{ provide: UserRepository, useClass: PrismaUserRepository }`). It **must stay decorator-free and Nest-import-free** — Nest only uses its constructor reference as the token. (`JS:` a `Symbol` token — see JavaScript path.)
- **Composition root = each Nest module's `providers` array** — the only place that binds a port token to a concrete adapter. There is no `container.js` and no hand-rolled wiring graph.
- **Inner code never imports a concrete adapter.** Services depend on port tokens via constructor injection only (`service/` may not import `repo/` — see *Enforced boundaries*).

## Controller ring (controllers, DTOs, validation)

- Nest `@Controller()` = base controller ring.
- **Validation default: Zod** via a small custom `ZodValidationPipe`. Pack decision — rejected alternative: `class-validator` + `ValidationPipe`. Chosen because Zod is **decorator-free** (works identically in JS and TS, avoiding the Babel-fragile decorator metadata `class-validator` DTOs need). DTOs are Zod schemas in `dtos/`; infer the type in TS (`JS:` duck-typed). Sharing one schema language with the frontend pack is a deliberate cross-pack choice recorded in the pack README.
- **Prisma types never appear in DTOs.** The controller maps domain objects to response DTOs **explicitly** — never spread a domain entity onto the response, never return a Prisma row (guards against Prisma's full-row over-fetch leaking sensitive fields).

## Error mapping

- The single global exception filter is the **only** place that maps **domain errors → HTTP status** (reuse the base status-code table).
- **`domain/` and `service/` throw domain errors (plain classes), never Nest `HttpException`** — throwing it inward would leak transport concerns past the controller ring. `@nestjs/common` `HttpException` is **forbidden outside the controller ring and the filter** (see *Enforced boundaries*).

## Aspects mapping (base AOP → Nest constructs)

| Base aspect | Nest construct | Scope |
|---|---|---|
| Auth (edge) | **Guard** (`CanActivate`) | handler/controller/module |
| Validation | **Pipe** (`ZodValidationPipe`) | handler/global |
| Request context / correlation id | edge **seeder** into ALS (see *Request context*) | bootstrap, once |
| Structured logging | **global interceptor** (or `pino-http`) reading the id | bootstrap, once |
| Error mapping | **one global exception filter** | bootstrap, once |
| Audit / analytics | **one injectable `AuditService`** | injected where used |
| Transaction boundary | service-ring concern (see *Service ring*) | — |

- **Scope-to-subtree (base rule), Nest form:** prefer `@UseGuards`/`@UseInterceptors`/module `providers` over `app.useGlobalX()`. The only global registrations are the two singletons base itself treats globally — the **error filter** and the **single correlation-id + logging path** (seeder + interceptor are two halves of *one* path, registered once at bootstrap).
- **Audit/analytics (base *Logging & audit* path):** all events flow through **one injectable `AuditService`**, injected into the services that emit them. Never scatter event emission across handlers.

## Service ring (use-case providers + transaction boundary)

- A use case = one `@Injectable()` provider in `service/`, depending only on domain + port tokens.
- **Transaction boundary stays in the service ring; Prisma stays in the repo ring.** Resolved with a Unit-of-Work port — `TransactionRunner` — defined in `domain/`, implemented in `repo/` over Prisma's interactive transaction.
  - **Mechanism:** `TransactionRunner.run(work)`'s callback yields a **transaction-scoped repository set** (a repo factory already bound to `tx`) to the service. The service calls its repos **inside** that callback and **never names `Prisma.TransactionClient`** — the tx-binding happens entirely in `repo/` (that type stays in the **repo**). No `tx` travels via ALS; request-context ALS is edge-only and unrelated.
  - **YAGNI guard:** the `TransactionRunner` port is required **only when a use case spans multiple repository writes**. A single-repository write may rely on the repository's own atomic call — do not open an explicit UoW boundary for every trivial write.
- **No nested use-case transactions:** a use-case service must **not** call another use-case service. Cross-use-case composition happens in **domain services** within the one boundary.

## Repo ring — Prisma adapters

- Repositories in `repo/` **implement domain port tokens** over `PrismaClient`, bound in the module `providers` array.
- **Mappers (base, hard):** every repository carries a mapper translating Prisma rows ↔ domain objects; **Prisma row types/objects never cross inward**.
- **Explicit selects:** `select` the fields a domain object needs — no implicit full-row returns where a subset suffices.
- **PrismaClient lives in one place:** a `PrismaService` (extends `PrismaClient`, `OnModuleInit`/`OnModuleDestroy` for connect/disconnect) provided by a shared `PrismaModule`, injected into repositories. One client instance per app; never `new PrismaClient()` in a repository.

## Repo ring — external clients

- External gateways (storage, mail/SMS, payments, translation) are **also repo-ring adapters** implementing domain ports, each with its **own mapper**. Prisma is just one adapter kind.
- **HTTP integrations** bind to `@nestjs/axios` `HttpService` (or a thin `fetch` wrapper) with **per-call timeout, bounded retry + backoff, and idempotency-key support**. Queue/scheduled work binds to BullMQ / `@nestjs/schedule`.
- The base **Integrations** rules (idempotency, concurrency, ordering, classified failures, untrusted-external handling) **apply unchanged**; the **decisions** they enforce stay in the domain.

## Request context / correlation id

- **Pack decision: `AsyncLocalStorage` (recommend `nestjs-cls`), seeded by a Nest guard/interceptor — not global `app.use()` middleware.** Rejected alternative: request-scoped providers (they rebuild the DI subtree per request). Rejected mechanism: global `app.use()` middleware on Fastify — it receives **raw `req`/`res`**, **cannot access DI**, and uses path-to-regexp wildcard syntax (`(.*)`, not `*`); a DI-capable guard/interceptor avoids all three traps.
- The seeder generates/propagates the correlation id (honour inbound `x-request-id`/`x-correlation-id`) into the ALS store.
- **Inner rings never read ALS.** The controller pulls context out at the edge and passes it into the service call as a plain value (base: "passed inward as an argument"). The ALS store is an edge/aspect detail only.

## Cookies

- Register **`@fastify/cookie`** at bootstrap. Cookies are read/written at the **controller/aspect edge** via the Fastify request and passed inward as plain values — never read by an inner ring.

## Config / env

- **`@nestjs/config`** with a single Zod schema validated at boot via `validate` — the app **fails fast** on missing/invalid env (root CLAUDE.md config convention: a missing key fails startup with a named error, never a mid-request undefined).
- **No `process.env` reads outside the config module** (see *Enforced boundaries*). Inner rings receive config values by injection.

## Enforced boundaries (lint)

One import-boundary checklist (e.g. ESLint `no-restricted-imports` / `import/no-restricted-paths`). Verify a change against it:

- `domain/` may not import `@nestjs/*` or `@prisma/client`.
- `service/` may not import `repo/` or `PrismaClient`.
- `@prisma/client` may be imported only under `repo/` and `PrismaService`.
- `@nestjs/common` `HttpException` may not be imported outside the controller ring and the global exception filter.
- `process.env` may not be read outside the config module.

## Testing per ring

- **Domain:** plain instantiation, **no `Test.createTestingModule`**.
- **Service:** `Test.createTestingModule` with **in-memory port fakes** bound to the port tokens (`useValue`/`useClass`); no Prisma, no DB.
- **Controller / e2e:** Nest `Test` against the assembled module, driven by **Fastify's native `.inject()`** (`app.getHttpAdapter().getInstance().inject()`) — the default on this adapter. `supertest` is the Express-adapter fallback only.
- **Repo:** **integration against real Postgres** — the test-DB/migration harness lives in the **db appendix**; do not mock Prisma.

## App bootstrap

- `main` entry: create the Fastify Nest app; register the **global exception filter**, the **global `ZodValidationPipe`**, **`@fastify/cookie`**, and the **correlation-id/logging path**.
- **Route scope vs version are separate concerns.** Nest's URI version segment is the **`v1` token only**, inserted between the single global prefix and the controller path. `internal`/`external` is a **visibility scope, not a Nest version** — so one global prefix + `enableVersioning` **cannot** yield both `/internal/v1` and `/external/v1`. Model the scope as a **path segment** (e.g. `@Controller({ path: 'users', version: '1' })` under an `internal`/`external` path group, or two route groups). Default to internal. All other base RESTful conventions apply unchanged.
- **Consumer boundary:** the **Next.js server tier** (server-first App Router, server-to-server calls) is an **internal trusted consumer** on `/internal/v1`; only genuinely third-party consumers use `/external/v1`.
- Form-factor concerns live in the frontend appendix; backend pagination follows base unchanged. The build orchestrator (Nest CLI per-app vs Nx vs Turborepo) is a pack-README decision; this bootstrap assumes the Nest CLI per app.

## JavaScript path

JS stays supported but un-mandated. All JS-specific setup lives here; the body rules above are otherwise identical.

- **Babel is required** so Nest decorators + DI metadata work without `tsc`. Use a known-good `babel.config` (or `nest-cli` with the **SWC** builder) as the canonical recipe rather than hand-ordering plugins. If hand-listing: `@babel/plugin-proposal-decorators` with `{ legacy: true }` (`legacy` is the **option**, not a separate plugin), `@babel/plugin-transform-class-properties`, `babel-plugin-transform-typescript-metadata` (**ordered before** the decorators plugin so `design:type`/`design:paramtypes` emit), and `babel-plugin-parameter-decorator` (constructor-parameter DI — omitting it is the usual "Nest can't resolve dependencies" cause). **Plugin order matters.**
- **Port DI tokens:** a `Symbol` (or string) token exported from `domain/`, e.g. `export const USER_REPOSITORY = Symbol('UserRepository')`; the port shape pinned by a JSDoc `@typedef`. Inject via `@Inject(USER_REPOSITORY)`.
- **DTOs / config schemas:** Zod schemas used directly (duck-typed, no inferred type).
- **`@nestjs/config` validate and testing utilities** (`Test.createTestingModule`, Fastify `.inject()`) are identical in JS.

## Add-on bindings (if adopted)

- **test-mode** (`add-ons/test-mode/`): a `SharedModule` guard resolves the mode signal from an inbound header into the request context — fail closed: missing or unknown means production. In test mode the flag-gated integrations (the base default-off booleans) route to a stdout/no-op adapter bound in the module `providers` array. The test-user picker is a controller gated on the same signal; it returns `[]` in production, and a controller test asserts that.
- **otp-auth** (`add-ons/otp-auth/`): model A (self-managed) — one `OtpChallenge` Prisma model (hashed code, short TTL, `purpose` discriminator); hashing + timing-safe verify in `shared/utils/`; delivery gateways are repo-ring adapters behind domain ports, gated by the default-off flags; phone numbers canonicalised to E.164 with `libphonenumber-js`; a unique constraint on (target, purpose) resolves the double-submit race to `409` per the base status table.

## Conflict register

Where this appendix and a base file disagree, these resolutions win for this stack.

- **Base says:** The stack is unchosen; the base presents JS-style filenames and an Express/Fastify-style HTTP layer **illustratively**, not as mandates. **In this stack:** that unchosen slot is filled with NestJS (a full framework) on the Fastify adapter; language relaxed to TS **or** JS. **Because:** NestJS is the chosen framework, Fastify chosen on throughput + plugin ecosystem (not base continuity). **Concretely:** DON'T treat Nest as "a lightweight layer"; the JS path requires the `## JavaScript path` Babel setup.
- **Base says:** Wiring lives in `container.js`; manual constructor wiring, reach for a DI container only when the graph grows unwieldy. **In this stack:** No `container.js`, no manual graph — each module's `providers` array is the composition root from day one. **Because:** Nest's IoC container is mandatory infrastructure; a parallel manual graph or a second container would duplicate it. **Concretely:** DO bind every port token to its adapter in the module `providers` array; DON'T add `container.js` or Awilix.
- **Base says:** A port is a duck-typed shape, optionally pinned with a JSDoc `@typedef`. **In this stack:** Ports still live in `domain/` as shapes, plus a concrete DI token — TS: a decorator-free `abstract class` as type+token; JS: a `Symbol`/string token injected via `@Inject(TOKEN)`. **Because:** the token is wiring metadata, not a language interface — duck-typing is intact. **Concretely:** DO keep the abstract class decorator-free and Nest-import-free.
- **Base says:** Cross-cutting concerns are middleware/plugins scoped to the subtree, not globally. **In this stack:** Aspects map to Nest guards/interceptors/pipes/filters, scoped via `@UseGuards`/`@UseInterceptors`/module providers; only the error filter and the single correlation-id + logging path register globally. **Because:** those two are genuinely app-wide; everything else stays branch-scoped. **Concretely:** DON'T reach for `app.useGlobalX()` for anything but those two singletons.
- **Base says:** One transaction per use case; the service owns the boundary, the repo builds queries, and the service/domain never touch the DB client. **In this stack:** A domain-defined `TransactionRunner` port whose `run(work)` callback yields a tx-bound repository set to the service; the service never names `Prisma.TransactionClient`. Required only for multi-write use cases. **Because:** keeps the boundary in the service ring while Prisma's transaction API stays in the repo ring. **Concretely:** DON'T open a UoW boundary for a single-repository write.
- **Base says:** Request context is established at the edge and passed inward as an argument — never read from a global by an inner ring. **In this stack:** Context lives in `AsyncLocalStorage` (recommend `nestjs-cls`), seeded by a DI-capable guard/interceptor — not request-scoped providers, not global `app.use()` middleware. **Because:** ALS gives per-request context with singleton providers while honouring "never read from a global inward". **Concretely:** only the edge reads ALS; inner rings receive context as a plain value.
- **Base says:** Organise by feature, layers within (`domain/ service/ repo/ controller/ dtos/`), with `shared/` and `container.js` beside the modules. **In this stack:** Ring folders kept verbatim inside each Nest module (Nest's flat `*.controller`/`*.service` naming overridden); `container.js` replaced by `<feature>.module.ts` + `providers`; `shared/aspects` becomes a `SharedModule`. **Because:** preserve the onion on top of Nest modules. **Concretely:** DON'T flatten ring folders into Nest's default file naming.
- **Base says:** Use `/internal/v1` and `/external/v1` route prefixes, default internal. **In this stack:** Nest URI versioning cannot produce both (its version segment is the `v1` token only, one global prefix per app). Model `internal`/`external` as a path segment, not a Nest version; default internal; the Next.js server tier is an internal trusted consumer. **Because:** base's required route shape is otherwise silently unachievable. **Concretely:** DON'T expect `enableVersioning` + one global prefix to yield both scopes.
- **Base says:** The controller ring is the single place that maps domain failures onto transport responses. **In this stack:** The single global exception filter is the only domain-error → HTTP mapping site; `domain/` and `service/` throw plain domain errors, never Nest `HttpException` (lint-forbidden outside the controller ring and the filter). **Because:** Nest's `HttpException` hierarchy tempts inner rings to throw transport errors. **Concretely:** DON'T `import { HttpException }` in `domain/` or `service/`.
- **Base says:** Logging & audit run on one shared path carrying the request's correlation id, kept out of the domain. **In this stack:** that one path is bound to a single injectable `AuditService` (or an interceptor feeding it) for audit/analytics events. **Because:** Nest's DI makes it tempting to emit events from any handler, fragmenting the one path. **Concretely:** DON'T emit events ad hoc from handlers. (Cookies have no base rule to conflict with — `@fastify/cookie` is a plain binding; see *Cookies*.)
- **Base says:** External clients (storage, mail/SMS, payments) are repo-ring adapters under the Integrations rules. **In this stack:** Bound explicitly — each is a repo-ring adapter implementing a domain port with its own mapper; HTTP via `@nestjs/axios` (timeout + bounded retry/backoff + idempotency keys), queues via BullMQ/`@nestjs/schedule`. **Because:** the draft mapped `repo/` to Prisma only and left the external-client side unbound. **Concretely:** DON'T treat the repo ring as Prisma-only.
- **Base says:** Migrations are reversible (up paired with down, or explicit justification). **In this stack:** Prisma Migrate is forward-only — it generates no `down.sql` and never auto-rolls-back; the down obligation is met by expand-and-contract for destructive changes, or a `-- IRREVERSIBLE:` justification header for one-shot ones. Mechanics are owned by the db appendix; flagged here because this appendix consumes Prisma. **Because:** an agent must not assume Prisma gives reversible up/down pairs out of the box. **Concretely:** DON'T expect `prisma migrate` to roll back; see the db appendix.
