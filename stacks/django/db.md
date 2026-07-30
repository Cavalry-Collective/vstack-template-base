# Postgres and Django ORM: database appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Use Postgres 16 through the Django ORM and Django migrations.

## Migrations

- Keep migrations inside each Django app's `migrations/` package.
- Create named migrations with `makemigrations --name <verb_noun>`.
- Keep one logical schema change per migration.
- Use Django's dependency graph and generated numeric prefix.
- Review every migration with `sqlmigrate` before committing.
- Keep migrations atomic unless an operation such as `AddIndexConcurrently` requires `atomic = False`.
- Give every `RunPython` a real reverse or `RunPython.noop`.
- Raise `IrreversibleError` only with the base irreversible-change justification.
- Never edit an applied migration or use merge migrations to preserve a forked history.
- Put backfills in batched, idempotent, resumable management commands.

## Schema

- Keep `USE_TZ = True`.
- Use Django's default snake_case table names.
- Use UUID primary keys.
- Keep `created_at` and `updated_at` on every model.
- Add explicit indexes for frequent filters and sorts; Django already indexes foreign keys.
- Use `DecimalField` or integer minor units for money.
- Use `TextChoices` with `CheckConstraint` for fixed values.
- Use `UniqueConstraint` for business invariants.

## Queries and transactions

- Wrap each write service in `transaction.atomic`.
- Use `select_for_update()` for read-then-write races.
- Pass parameters to raw SQL; never interpolate them.
- Use `select_related`, `prefetch_related`, and projections to prevent N+1 queries.
- Use one DRF pagination class with validated sort columns and the base envelope.

## Local databases and seed

Run one fixed-name `postgres:16` container and one database per worktree:

1. derive `app_<sanitised-branch>`;
2. update the copied `DATABASE_URL`;
3. create the database during bootstrap;
4. drop it when removing the worktree.

Implement development seed and backfill operations as management commands. Keep the seed idempotent and non-production only. Let pytest-django create its own `test_*` database.

## Operations

CI must:

- apply migrations from zero;
- run `makemigrations --check --dry-run`;
- run the seed twice.

Before merge, reverse each migration added by the change to its previous app state, then migrate forward again on the worktree database.

## Conflict register

- **Base says:** migrations and database scripts live under top-level `db/`. **In this stack:** migrations live in each Django app and seed or backfill logic is a management command. **Because:** Django's loader and autodetection operate on app migration packages. **Concretely:** DO create changes through `makemigrations`; DON'T create a parallel `db/migrations/` directory.
- **Base says:** migration filenames use timestamps rather than incrementing numbers. **In this stack:** Django uses per-app numbers and an explicit dependency graph. **Because:** the graph is authoritative and Django rejects conflicting leaves. **Concretely:** after rebasing over a same-app migration, regenerate yours after the new leaf; DON'T commit a merge migration.
- **Base says:** CI proves a whole migration up, down, and up cycle. **In this stack:** CI applies from zero and checks drift; each new migration is reversed locally. **Because:** whole-project reversal is impractical across app dependencies and prior irreversible migrations. **Concretely:** run and report the reverse of every migration you add; DON'T merge one whose reverse was not exercised or justified.
- **Base says:** the fixed-name local database is shared and destructive checks need a throwaway database. **In this stack:** the Postgres server is shared but each worktree has its own database. **Because:** parallel Django migration histories cannot safely share one schema. **Concretely:** repoint `DATABASE_URL` after copying the environment file; DON'T migrate, reverse, or seed another worktree's database.
