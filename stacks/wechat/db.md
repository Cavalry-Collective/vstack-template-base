# MySQL, TDSQL-C, and Knex: database appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Use TDSQL-C (CynosDB) MySQL 8.0 serverless in production, a matching `mysql:8.0` container locally, Knex for migrations and queries, and the `mysql2` driver.

TDSQL-C runs Tencent's own TXSQL kernel and is wire-compatible with MySQL 5.7 and 8.0 — 8.4 is not offered. Pin local and CI MySQL to the same `8.0` line so a query that passes locally behaves the same in production. Oracle's community MySQL 8.0 is end-of-life, so the supported engine here is Tencent's managed one; do not read the local container's support status as the cluster's.

## Migrations

- Keep Knex migrations under `db/migrations/`.
- Create them with `knex migrate:make <verb_noun>` and keep the generated timestamp.
- Implement real `up(knex)` and `down(knex)` functions.
- Keep one logical change per migration because MySQL DDL normally auto-commits.
- Separate schema changes from batched, idempotent, resumable backfills.
- Use expand, migrate, contract for breaking changes.

## Repository binding

- Create one Knex instance in `plugins/db.js`.
- Accept the Knex instance or transaction as the first repository argument.
- Map snake_case rows to camelCase application objects inside repositories.
- Select explicit columns rather than using `SELECT *`.
- Open a transaction in the service for multi-write use cases and pass `trx` to every repository.
- Rely on statement atomicity for one write.
- Use Knex value binding; restrict `raw()` to SQL Knex cannot express safely.

## Local and test databases

- Run one fixed-name `mysql:8.0` container shared across worktrees.
- Keep one development database rather than per-worktree databases.
- Keep development seed data realistic, named, idempotent, and keyed by business identifiers.
- Treat the test suite as destructive.
- Refuse to run tests unless `DB_NAME` ends in `_test`.
- Make `pnpm test` select the test database automatically.
- Create and migrate it through the idempotent `test:db:setup` command.

## Production operations

- Run migrations through the private SCF event function after Terraform and the image-digest update, using the same image as the web function.
- Pass reset and forced-reseed options only through explicit invocation input.
- Keep every migration backward-compatible with the previous function version.
- Keep production bootstrap seeds idempotent and non-fatal.
- Never allow schema reset to run against production by default or unattended.

## MySQL details

- Check existing rows before adding a late `CHECK` constraint. Keep the rule in the service when legacy data cannot satisfy it.
- Native MySQL `ENUM` is allowed for fixed values when every widening is a reversible migration.

## Conflict register

- **Base says:** seed and reset operations never run against production. **In this stack:** controlled bootstrap seeds and imports may run through the private migration function, and the reset capability exists there. **Because:** TDSQL-C is VPC-locked and the migration function is the authenticated production write path. **Concretely:** keep production seeds idempotent and non-fatal; DON'T expose or default `resetSchema`, and never invoke it unattended against production.
