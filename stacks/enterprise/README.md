# Stack pack: enterprise

Use this pack for a server-first Next.js frontend with a separate NestJS API and Prisma/Postgres.

| Area | Choice |
|---|---|
| Identity | `nextjs-nestjs-postgres` |
| Frontend | Next.js App Router, server-first, JavaScript or TypeScript |
| Backend | NestJS on Fastify, JavaScript or TypeScript |
| Database | Postgres, Prisma |
| Platform | Platform-neutral; no `infra.md` |

Choose this pack when separate frontend and backend deployables, framework conventions, and team-scale dependency injection are useful.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | App Router, Nest API access, client/server state, testing |
| `backend.md` | Nest modules, onion rings, DI, aspects, testing |
| `db.md` | Prisma schema, forward-only migrations, transactions, local database |

## Day-1 setup

1. Keep this directory and delete the other stack packs.
2. Complete the root checklist for a server-first frontend and remove SPA-only wording.
3. Copy the command block below into root `CLAUDE.md`.
4. Implement the CI checklist in `.github/workflows/ci.yml`.
5. Record `Stack: enterprise; appendices under stacks/enterprise/` in root `CLAUDE.md` **Learnings**.

Use pnpm workspaces across both applications. Choose JavaScript or TypeScript once per app and keep one language within that app.

```bash
pnpm bootstrap   # install + shared Postgres + prisma generate + migrate + dev
pnpm dev         # Nest watch + Next dev
pnpm lint        # lint both apps
pnpm typecheck   # tsc per TS app; explicit no-op per JS app
pnpm test        # both unit suites; Playwright is test:e2e
pnpm build       # prisma generate + Next build + Nest build
pnpm migrate     # prisma migrate dev; local only
```

## CI

- Start a Postgres service.
- Run `pnpm install --frozen-lockfile`.
- Run `prisma generate` and `prisma migrate deploy`.
- Run lint, typecheck, non-watch tests, `next build`, and `nest build`.
- Run the i18n parity and accessibility gates from the base workflow.
- Apply migrations from zero and run the Prisma drift checks from `db.md`.
- Run the seed twice.
- Run Playwright separately against the running stack through `E2E_BASE_URL`.

## Decisions

- Use NestJS on the Fastify adapter.
- Use Zod for Nest DTOs, Next forms, API responses, and environment validation.
- Use `nestjs-cls` over request-scoped providers for request context.
- Use the pack's `PrismaService` rather than `nestjs-prisma`.
- Use Nest modules as composition roots and preserve the onion ring folders within them.
- Use the Nest CLI and `next build`; do not add Nx or Turbo by default.

## Deployment

- Deploy Next.js and NestJS as separate workloads through the infrastructure contract.
- Run `prisma migrate deploy` before code that requires the new schema.
- Keep the browser on the Next.js origin; Next server services call Nest's `/internal/v1` API.
- Keep Prisma out of `apps/frontend`.
