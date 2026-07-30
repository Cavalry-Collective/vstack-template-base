# Postgres and Neon: database appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Use Postgres 16 locally, Neon in deployed environments, node-pg-migrate for migrations, and `pg` for queries.

## Tools

- Keep migrations under `db/migrations/`.
- Use CommonJS `.cjs` migration files with `up(pgm)` and `down(pgm)`.
- Use `pg` directly in repositories; do not add an ORM.
- Use Neon's pooled endpoint for application traffic and its direct endpoint for migrations.

## Migrations

- Create migrations with `node-pg-migrate create <verb_noun>`.
- Keep the generated timestamp prefix.
- Implement a real `down` for every `up`. Use `exports.down = false` only with the base irreversible-change justification.
- Keep the default transaction. Disable it only for DDL that requires it and explain why in the migration.
- Prefer node-pg-migrate builders and use `pgm.sql` only when needed.
- Run migration DDL through the direct, non-pooled connection.

## Schema

- Use `uuid` primary keys from `gen_random_uuid()`.
- Use `timestamptz` with `now()` for timestamps.
- Add indexes for every foreign key and frequent filter or sort.
- Use integer minor units or `numeric(p,s)` for money.
- Represent fixed value sets as `text` with a `CHECK`, not native Postgres enums.
- Map unique violations to the domain conflict response.

## Repository binding

- Create one `pg.Pool` per process with an explicit `DB_POOL_MAX`.
- Keep the production pool small and point it at Neon's pooled endpoint.
- Use parameterised `$1` queries only.
- Map snake_case rows to domain objects inside the repository.
- Select explicit columns where a subset is sufficient.
- Expose `withTransaction(work)` from the database aspect. Pass its client to every repository participating in the use case.
- Do not open a transaction for one atomic statement.

## Local databases

Run one fixed-name `postgres:16` container and one database per worktree:

1. derive `app_<sanitised-branch>` using lowercase letters, digits, and underscores;
2. truncate within Postgres's identifier limit;
3. update the copied `DATABASE_URL`;
4. create the database during bootstrap;
5. drop it when removing the worktree.

Keep the development seed idempotent and non-production only.

## Operations

CI must apply migrations from zero, run up, down, and up, then run the seed twice.

Vercel does not run migrations during deployment:

1. confirm the target Neon branch;
2. run `pnpm migrate` with its direct connection string;
3. verify the migration table and affected schema;
4. push the code that reads the new schema.

Use the same order for the persistent `develop` environment. Keep every migration backward-compatible.

## Gotcha

`vercel env pull --git-branch=develop` may omit the branch-scoped `DATABASE_URL`. Read it from Terraform state or the Neon console. Do not use an injected production `POSTGRES_URL` for staging.

## Conflict register

- **Base says:** the fixed-name local database is shared and destructive checks need a throwaway database. **In this stack:** the Postgres server is shared but each worktree has its own database. **Because:** parallel migration histories cannot safely share one schema. **Concretely:** repoint `DATABASE_URL` after copying the environment file; DON'T migrate, reset, or roll back another worktree's database.
