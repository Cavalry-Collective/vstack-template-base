# NestJS: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend onion to NestJS on the Fastify adapter. Use TypeScript by default; the JavaScript path is defined below.

## Module and ring mapping

- Use one Nest module per feature.
- Keep `domain/`, `service/`, `repo/`, `controller/`, and `dtos/` inside each feature.
- Put `<feature>.module.*` at the feature root as its composition root.
- Map shared aspects to a `SharedModule`.
- Keep shared utilities framework-independent.
- Use another module through its exported service provider or port token.

The domain ring imports neither Nest nor Prisma. Construct domain entities in services or repository mappers rather than registering them as providers.

## Dependency injection

- Define ports in the domain ring.
- In TypeScript, use a decorator-free abstract class as the port type and DI token.
- In JavaScript, export a `Symbol` token and document the port shape with JSDoc.
- Bind tokens to adapters only in the module's `providers` array.
- Inject port tokens into use-case services.
- Never import a concrete repository into a service.

## Controller edge

- Use Nest controllers for the controller ring.
- Define DTOs as Zod schemas and parse them through one `ZodValidationPipe`.
- Map domain objects to response DTOs explicitly.
- Do not return Prisma results or spread domain entities into responses.
- Throw plain domain errors from inner rings.
- Map domain errors to HTTP once in the global exception filter.
- Restrict Nest `HttpException` to controllers and the exception filter.

## Aspects

| Base concern | Nest binding |
|---|---|
| Authentication | guards |
| Validation | Zod pipe |
| Request context | `nestjs-cls` over AsyncLocalStorage |
| Logging | one interceptor or pino path using the correlation ID |
| Errors | one global exception filter |
| Audit | one injected `AuditService` |
| Configuration | `@nestjs/config` with one Zod boot schema |

- Scope guards and interceptors at the controller, handler, or module.
- Register only the error filter and correlation/logging path globally.
- Seed ALS at the edge, then pass context inward as a plain value.
- Read `process.env` only in the configuration module.

## Transactions and repositories

- Implement each use case as one injectable service.
- Define `TransactionRunner` as a domain port only when a use case spans several repository writes.
- Implement it in the repository ring with a Prisma interactive transaction.
- Yield repositories already bound to the transaction; do not expose `Prisma.TransactionClient` inward.
- Do not call one use-case service from another.
- Keep external calls outside database transactions.
- Implement repository ports over the shared `PrismaService`.
- Map every Prisma result to a domain object and select only required fields.
- Put email, storage, payments, queues, and other external clients in repository-ring adapters behind ports.

## Boundary checks

Enforce these import rules:

- `domain/` cannot import Nest or Prisma;
- `service/` cannot import `repo/` or Prisma;
- Prisma imports are limited to repositories and `PrismaService`;
- `HttpException` is limited to controllers and the global filter;
- `process.env` is limited to configuration.

## Bootstrap and routing

- Create Nest with `@nestjs/platform-fastify`.
- Register Zod validation, cookies, errors, and correlation/logging once.
- Treat `internal` and `external` as path segments.
- Use Nest URI versioning only for the `v1` segment.
- Default routes to `/internal/v1`; expose `/external/v1` only for third parties.
- Treat the Next.js server tier as an internal consumer.

## JavaScript path

JavaScript still needs decorator metadata. Use Nest's supported SWC setup or Babel with these plugins in order:

1. `babel-plugin-transform-typescript-metadata`;
2. `@babel/plugin-proposal-decorators` with `legacy: true`;
3. `@babel/plugin-transform-class-properties`;
4. `babel-plugin-parameter-decorator`.

Use `Symbol` port tokens with `@Inject(TOKEN)` and Zod schemas directly.

## Testing

- Test domain code without the Nest test module.
- Test services with `Test.createTestingModule` and in-memory port fakes.
- Test controllers through Fastify's native `inject()`.
- Test repositories against real Postgres.

## Conflict register

- **Base says:** manual wiring lives in `container.js` until a DI container is justified. **In this stack:** each Nest module's `providers` array is the composition root from the start. **Because:** Nest's container is mandatory framework infrastructure and a second container would duplicate it. **Concretely:** bind every port token in the owning module; DON'T add `container.js` or Awilix.
