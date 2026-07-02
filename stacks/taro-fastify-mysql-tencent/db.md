# MySQL 8 (CynosDB) + Knex — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `db/CLAUDE.md` (+ the backend repo ring) to **MySQL 8** — **CynosDB** serverless in production, a fixed-name Docker container locally — via **Knex** over **`mysql2`**. Owns migrations, seed, schema conventions, and repo-ring query/transaction mechanics — SCF entry/bundle: `./backend.md`; provisioning/invocation: `./infra.md`.

## Binding at a glance

- **Knex migrations** — real paired `up`/`down`; base reversibility and round-trip rules apply **verbatim**. Create with `knex migrate:make <verb_noun>`; **keep Knex's default timestamp prefix**, never hand-numbered sequences (the base's parallel-branch collision).
- **Knex query builder, no ORM.** Repos are thin builders over explicit queries; Knex binds values (the base never-interpolate rule, by construction). `db.raw()` only for `INSERT ... ON DUPLICATE KEY UPDATE` / `INSERT IGNORE`.

## Structure & migrations

- Migrations live under `db/migrations/` and run via the root `migrate` verb (`knex migrate:latest`; rollback `migrate:rollback`); each exports `up(knex)` and `down(knex)`.
- Most MySQL DDL **auto-commits** — the base transactional rule binds weakly, so keep one logical change per migration for diagnosable failures.
- **Separate schema from data**, bound: add the column nullable, backfill in an idempotent batched data migration, enforce/consume in a later one.

## Schema & MySQL-8 gotchas

- snake_case tables/columns; the base timestamps-on-every-table rule lands as `created_at`/`updated_at` [merged → `db/CLAUDE.md`]. Index every FK and frequent filter/sort column explicitly, in the migration that adds it.
- **A `CHECK` constraint validates *existing* rows on MySQL 8** — you cannot add one to a table whose legacy rows violate it — enforce such invariants **in the service** when legacy or imported data may.
- **Fixed value sets: native MySQL `ENUM` is acceptable** — widening one (`ALTER TABLE ... MODIFY ... ENUM(...)`) is a plain reversible migration, so the usual reasons to avoid native enums don't bite here.

## Repo ring binding (Knex)

- **One Knex instance per process**, created at boot by `plugins/db.js`; repos receive it (or a transaction) as **first arg** (`db`), then a named-args object — never their own connection.
- **Mappers at the boundary:** rows (snake_case) ↔ DTOs (camelCase); a raw row never crosses inward. Explicit column lists over `SELECT *`.
- **Transactions:** a multi-write use case opens `knex.transaction(async (trx) => …)` in the **service**, passing `trx` as each repo's `db`; a single write relies on statement atomicity.

## Local dev & seed

- **Local MySQL: one fixed-name Docker container shared across worktrees** (base shared-DB rule) — reuse it and run `migrate`; never a second copy, never per-worktree databases.
- **Seed** realistic, named accounts + content (base rule) — lifelike data for manual/e2e testing and the **test-mode** picker; idempotent, upsert by business key.

## Production migrations — a separate SCF function

**The deploy never runs `migrate` inline** — a dedicated SCF **event** function (`<project>-migrate`) runs migrations, pipeline-invoked **after** `terraform apply` (`scripts/invoke-migrate.js` → SCF Invoke; `ClientContext` options: `resetSchema`, `forceReseedTestUsers`). Code and schema ship in one pipeline run, so keep every migration **backward-compatible** (expand → migrate → contract, base rule): the window where old code meets new schema must never break. Pipeline order: `./infra.md`.

## Testing — the `*_test` ritual

The suite **truncates tables**; the runner **refuses unless `DB_NAME` ends in `_test`**, and `pnpm test` auto-suffixes it — the dev schema is never touched. One-time setup creates and migrates the `*_test` schema (`pnpm --filter backend test:db:setup`, idempotent). This guard *is* the stack's binding of the base throwaway-DB rule for destructive checks.

## Conflict register

- **Base says:** seed/reset scripts are **non-production only** — run only against local/throwaway databases. **In this stack:** controlled **data** seeds *do* run against production — admin bootstrap and one-off imports ride the migrate function; the destructive **reset** path exists there too. **Because:** the migrate function is the one authenticated write path to the VPC-locked production DB, so idempotent data bootstrapping rides it rather than a second mechanism. **Concretely:** DO keep any prod-run seed idempotent + upsert-by-business-key + non-fatal (a failed seed logs rather than failing the deploy); DON'T let `resetSchema` reach production — it is an explicit opt-in `ClientContext`/`workflow_dispatch` flag, never the default, never unattended.
