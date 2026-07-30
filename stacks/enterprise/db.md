# Postgres and Prisma: database appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the database layer to Postgres and Prisma. The generated client belongs to the backend repository ring only.

## Prisma layout

- Keep one schema at `apps/backend/prisma/schema.prisma`.
- Keep the Prisma config at the repository root.
- Set `migrations.path = "db/migrations"` in that config.
- Configure the seed through `migrations.seed`.
- Run `prisma generate` for JavaScript and TypeScript backends.

## Migrations

Prisma migrations are forward-only:

- Create with `prisma migrate dev --create-only --name <verb_noun>`.
- Review the generated SQL before applying or committing.
- Reject unintended drops, unsafe `NOT NULL`, hot-table rewrites, and lock-heavy DDL.
- Never edit an applied migration.
- Use `prisma migrate dev` locally and `prisma migrate deploy` in CI and deployment.
- Keep one logical schema change per migration.

For breaking changes:

1. add the new shape as nullable or defaulted;
2. run a batched idempotent backfill from `db/backfills/`;
3. deploy code that reads and writes the new shape;
4. remove the old shape in a later migration.

Make the backfill assert source and migrated counts. If a destructive one-step change is unavoidable, start `migration.sql` with `-- IRREVERSIBLE:` and state the recovery path.

## Schema

- Map PascalCase singular models to snake_case plural tables with `@@map`.
- Map camelCase fields to snake_case columns with `@map`.
- Name relation fields and set `onDelete` explicitly.
- Use Prisma enums for fixed values. Add one Postgres enum value per migration and do not use it as a default in that same migration.
- Use UUID primary keys for externally visible records.
- Use autoincrement only for internal records and state the reason.
- Add `createdAt` and `updatedAt` to every model.
- Use `Decimal` or integer minor units for money; do not expose Prisma `Decimal` beyond the repository mapper.
- Use `Json` only for data that is genuinely schemaless and not queried relationally.
- Add soft deletion only when history requires it.
- Implement soft-delete uniqueness with a partial unique index on active rows.
- Do not add global Prisma soft-delete middleware.

## Client boundary

- Import Prisma only in backend repositories and `PrismaService`.
- Keep Prisma types and result objects out of domain and service code.
- Map every row and relation payload to a domain object.
- Never import Prisma under `apps/frontend`.
- Make the Next.js server call the Nest API rather than the database.

## Transactions and queries

- Implement the domain's `TransactionRunner` port with Prisma interactive transactions.
- Yield repositories already bound to the transaction.
- Keep external calls outside a transaction.
- Set explicit transaction wait and timeout limits.
- Use the array transaction form only for independent writes.
- Add `@@index` for every foreign key and frequent filter or sort.
- Use `@@unique` for normal uniqueness and migration SQL for partial uniqueness.
- Map Postgres unique violations to the domain conflict response.
- Select or include relations in one query to avoid N+1.
- Validate sort fields against one allow-list.
- Use cursor pagination for large or frequently paged datasets.

## Local databases

Run one fixed-name Postgres container and one database per worktree:

1. derive `app_<sanitised-branch>`;
2. update the copied `DATABASE_URL`;
3. create it through local Prisma migration setup;
4. drop it when removing the worktree.

Set an explicit connection limit. Configure PgBouncer when using a transaction pooler.

Keep the seed idempotent, realistic, and safe to run twice. Use `prisma migrate reset` only against the worktree database.

## Operations

CI must:

- run `prisma generate`;
- apply migrations from zero with `prisma migrate deploy`;
- run `prisma migrate status`;
- run `prisma migrate diff --from-migrations ./db/migrations --to-schema ./apps/backend/prisma/schema.prisma --exit-code` with the required shadow database;
- run the seed twice.

Treat a non-empty drift result as failure.

## Conflict register

- **Base says:** each migration has a down path and CI proves up, down, and up. **In this stack:** Prisma is forward-only; expand-contract, explicit irreversible headers, apply-from-zero, and drift checks provide the proof. **Because:** Prisma generates no down migration and a generated inverse cannot recover dropped data. **Concretely:** DON'T commit destructive SQL without an expand-contract plan or `-- IRREVERSIBLE:` recovery note; wire the Prisma drift gate into CI.
- **Base says:** the fixed-name local database is shared and destructive checks need a throwaway database. **In this stack:** the Postgres server is shared but each worktree has its own database. **Because:** parallel Prisma migration histories cannot safely share one schema. **Concretely:** repoint `DATABASE_URL` after copying the environment file; DON'T migrate or reset another worktree's database.
