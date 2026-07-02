# Postgres (Neon) + node-pg-migrate + pg — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `db/CLAUDE.md` (+ the backend repo ring) to **Postgres** — **Neon** (serverless, via the Vercel marketplace) in production, a fixed-name Docker container locally — via **node-pg-migrate** and **`pg`** (node-postgres).

## Binding at a glance

- **Migrations: node-pg-migrate** — real paired `up`/`down`; the base reversibility and round-trip rules apply verbatim — no override.
- **Query layer: `pg` directly, no ORM** (rejected: Prisma/Drizzle) — repos are thin mappers over explicit SQL; no codegen or client weight on a cold-starting function; SQL is reviewed as SQL.
- **Fixed value sets: `text` + a `CHECK` constraint** (rejected: native enums — `ALTER TYPE … ADD VALUE` is non-transactional and effectively one-way; widening a `CHECK` is a reversible migration).

## Structure

This appendix owns migrations, seed, schema conventions, and repo-ring query/pool/transaction mechanics (container wiring and Vercel entrypoint: `./backend.md`; provisioning: `./infra.md`). Migrations live under `db/migrations/`, run via the root `migrate` verb (rollback: `migrate:down`).

## Migrations

- Create with `node-pg-migrate create <verb_noun>` — its epoch-ms prefix satisfies the base timestamp rule.
- **Migrations are CommonJS `.cjs`** — node-pg-migrate `require()`s them and the workspace is ESM, so a `.js` migration fails to load. Each exports `up(pgm)`/`down(pgm)`.
- **Reversibility:** every `up` ships its real `down`; a genuinely irreversible change sets `exports.down = false` *and* carries the base justification comment — never silently.
- Migrations run **in a transaction by default** (base rule); disable only for DDL that demands it (`CREATE INDEX CONCURRENTLY`), with a comment.
- Prefer `pgm` builders (`createTable`, `addColumns`, `createIndex`); use `pgm.sql` for anything they don't express.
- **Migrate on the direct (non-pooled) connection string** — the app uses the pooled endpoint; DDL and migration locks through a transaction pooler misbehave.

## Schema conventions

- snake_case tables and columns; **uuid primary keys via `gen_random_uuid()`** (opaque, non-enumerable).
- Base *Schema rules* (`db/CLAUDE.md`) bind as: timestamps — `created_at`/`updated_at` `timestamptz` defaulted `now()`; exact money — integer minor units or `numeric(p,s)`; unique→`409` unchanged.
- **Index every FK and frequent filter/sort column explicitly** — Postgres does not auto-index FKs.

## Repo ring (`pg`)

- **One `pg.Pool` per process**, created at boot by the db aspect with `max: DB_POOL_MAX`; repos receive it via the container — never construct their own client.
- **Serverless pooling:** each function instance has its own pool and instances multiply — keep `DB_POOL_MAX` **single-digit in production**; point the runtime `DATABASE_URL` at **Neon's pooled (PgBouncer) endpoint** so many instances share one Postgres. Local defaults are fine.
- **Parameterized queries only** (`$1` placeholders) — the base "never interpolate request data" rule, bound; string-built SQL is the greppable violation.
- **Mappers at the boundary:** repos translate rows ↔ domain objects; a raw row (snake_case) never crosses inward; prefer explicit column lists — no reflexive `SELECT *`.
- **Transactions:** the db aspect's `withTransaction(work)` hands the callback a client; repos accept an optional client so a multi-write use case shares one transaction. Services get `withTransaction` from the container, never importing `pg`. No transaction for a single write — statement atomicity suffices.

## Local dev & seed

- **Local Postgres is one fixed-name Docker container** (`postgres:16`), started by `db:up`/`bootstrap` with start-or-run semantics, shared across worktrees — reuse it, never start a second.
- **One shared server, one database per worktree** (registered): sanitize the branch to `[a-z0-9_]`, truncate to Postgres's 63-byte identifier limit, prefix `app_` (`feature/x` → `app_feature_x`); `bootstrap`/`db:up` creates it if missing (`CREATE DATABASE` — node-pg-migrate won't auto-create); drop it on teardown. Round-trip and destructive checks run only against your own worktree database.
- **Seed:** `db/seed-dev.<ext>`, idempotent (upsert by business key), run via a root script with `--env-file`; non-production only (base rule).

## Production & staging migrations (Neon)

**Deploys do not run migrations** — nothing in the pipeline runs `migrate`; a migration is a **manual step before the push that needs it**, against the target Neon branch:

```bash
DATABASE_URL="<neon-prod-direct-connection-string>" pnpm migrate
```

- A **shell-set `DATABASE_URL` wins over `--env-file`**, overriding the local `.env` without edits; use the **direct** string (*Migrations*). Confirm the target first — this writes the live DB — then verify `pgmigrations` and the affected tables.
- **Migrate, then push.** A push deploys API + frontend together (`infra.md`); neither waits for a migration. Keep each migration **backward-compatible** (expand → migrate → contract, base rule) so old code on new schema — or new on old — never breaks.
- **Staging (`develop` — a registered override; `infra.md` conflict register) runs the same runbook on its own Neon branch** — migrate before pushing `develop`. `vercel env pull --git-branch=develop` does **not** export the branch-scoped `DATABASE_URL` — read it from **Terraform state** or the Neon console. Never migrate through the Neon-injected `POSTGRES_URL`; it points at **production**.

## Testing

In `ci.yml`, against the scratch `postgres:16` service: apply from zero; round-trip **up → down → up** (keep the base round-trip TODO's wording); seed twice (idempotency). Repo integration tests: `./backend.md`.

## Conflict register

- **Base says:** local infrastructure is shared across worktrees by a fixed name and the shared DB's schema is **global state** — destructive checks go to a throwaway DB (root `CLAUDE.md`; `db/CLAUDE.md`). **In this stack:** the *server* stays shared by its fixed name, but each worktree migrates its own `app_<sanitized-branch>` database, created on bootstrap and dropped on teardown. **Because:** parallel worktrees applying different branches' migrations to one schema break each other; per-worktree databases remove the hazard and make the round-trip safe by construction — no second container. **Concretely:** after copying `.env` in, re-point the db-name segment of `DATABASE_URL` at this worktree's database; DON'T run `migrate`/`migrate:down`/reset against the shared default database or another worktree's.
