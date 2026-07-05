# MySQL 8 (CynosDB) + Knex — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds the base `db/CLAUDE.md` (+ the backend repo ring) to **MySQL 8** — **CynosDB** (serverless) in production, a fixed-name Docker container locally — with **Knex** for both migrations and the query layer, over the **`mysql2`** driver. Read the base files first.

**Scope.** This file owns migrations, seed, schema conventions, and the repo-ring query/transaction mechanics. The SCF entry and bundle live in `./backend.md`; provisioning and the migrate-function invocation live in `./infra.md`.

## Tool picks

- **Knex migrations** — real paired `up`/`down`, so the base reversibility and up→down→up round-trip rules apply **verbatim**. Create with `knex migrate:make <verb_noun>`; **keep Knex's default timestamp prefix** — do **not** override it with hand-numbered `0001_`/`0002_` sequences, which is exactly the parallel-branch collision the base warns about.
- **Knex query builder, no ORM.** Repos are thin builders over explicit queries; values are bound by Knex (the base "never interpolate request data" rule holds by construction). Drop to `db.raw()` only for `INSERT ... ON DUPLICATE KEY UPDATE` / `INSERT IGNORE`.

## Migrations

- Live under `db/migrations/`, run via the root `migrate` verb (`knex migrate:latest`; rollback `migrate:rollback`). Each file exports `up(knex)` and `down(knex)`.
- **Reversibility, bound:** every `up` ships its real `down`; a genuinely irreversible change carries the base's justification comment. Each migration runs in a transaction where MySQL DDL permits (note: most MySQL DDL auto-commits — keep one logical change per migration so a failure is diagnosable).
- **Separate schema from data;** backfills are batched, idempotent, resumable and live under `db/backfills/`, invoked explicitly — never inside a schema migration (base rule). So: add a column nullable, backfill it via an explicit `db/backfills/` script, then enforce/consume it in a later migration.

## Schema & MySQL-8 gotchas

- Base schema conventions apply unchanged (`db/CLAUDE.md` *Schema conventions*); MySQL-8 specifics below.
- **A `CHECK` constraint validates against *existing* rows on MySQL 8** — so you cannot add one to a table whose legacy rows already violate it. Enforce such invariants **in the service**, not with a late `CHECK`, when legacy or imported data may violate them.
- **Fixed value sets: a native MySQL `ENUM` is acceptable** — widening it (`ALTER TABLE ... MODIFY ... ENUM(...)`) is a plain reversible migration (contrast Postgres, where the `vercel` pack avoids native enums). A new challenge `purpose` is added this way.

## Repo ring binding (Knex)

- **One Knex instance per process**, created at boot by `plugins/db.js`; repos receive it (or a transaction) as their **first arg** (`db`), then a named-args object — never construct their own connection.
- **Mappers at the boundary:** repos translate rows (snake_case) ↔ DTOs (camelCase); a raw row never crosses inward. Prefer explicit column lists over `SELECT *`.
- **Transactions:** a multi-write use case opens `knex.transaction(async (trx) => …)` in the **service** and passes `trx` as each repo's `db`; a single write relies on the statement's own atomicity.

## Local dev, seed & the destructive test-DB ritual

- **Local MySQL is one fixed-name Docker container**, shared across worktrees per the base — reuse it, run `migrate`, never start a second copy (the base shared-DB rule stands; this stack does **not** use per-worktree databases, unlike the `vercel` pack).
- **Seed** realistic, named accounts + content (base `db/CLAUDE.md`) so manual/e2e testing and the **test-mode** add-on's test-user picker have lifelike data; idempotent, upsert by business key.
- **The test suite is destructive** — it truncates tables. The runner **refuses to run unless `DB_NAME` ends in `_test`**, and `pnpm test` auto-suffixes it, so the dev schema is never touched. One-time setup creates and migrates the `*_test` schema (`pnpm --filter backend test:db:setup`, idempotent). This `*_test`-schema guard *is* this stack's binding of the base "destructive checks go to a throwaway DB" rule.

## Production migrations — a separate SCF function

**The deploy does not run `migrate` inline.** Migrations run in a dedicated SCF **event** function (`<project>-migrate`), invoked by the pipeline **after** `terraform apply` (`scripts/invoke-migrate.js` → SCF Invoke, options passed via `ClientContext`: `resetSchema`, `forceReseedTestUsers`). Because the function code and schema ship in the same pipeline run, keep every migration **backward-compatible** (expand → migrate → contract, base rule) so the brief window where old code meets new schema never breaks. Full pipeline order → `./infra.md`.

## Conflict register

- **Base says:** seed/reset scripts are **non-production only** — idempotent and run only against local/throwaway databases, never a shared or production database. **In this stack:** controlled **data** seeds *do* run against production — admin bootstrap and one-off imports execute inside the migrate function, and the destructive **reset** path exists there too. **Because:** the migrate function is the one authenticated write path to the production DB (CynosDB is VPC-locked), so idempotent data bootstrapping rides it rather than a second mechanism. **Concretely:** DO keep any prod-run seed idempotent + upsert-by-business-key + non-fatal (a failed seed logs, it doesn't fail the deploy); DON'T let `resetSchema` reach production — it is an explicit opt-in `ClientContext`/`workflow_dispatch` flag, never the default, and never wired to run unattended against prod.
