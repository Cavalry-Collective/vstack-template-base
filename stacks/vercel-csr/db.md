# Postgres (Neon) + node-pg-migrate + pg — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds the base `db/CLAUDE.md` (+ the backend repo ring) to **Postgres** — **Neon** (serverless, via the Vercel marketplace) in production, a fixed-name Docker container locally — with **node-pg-migrate** for migrations and **`pg`** (node-postgres) as the query layer. Read the base files first.

## Scope

This file owns migrations, seed, schema conventions, and the repo-ring query/pool/transaction mechanics. Container wiring and the Vercel entrypoint live in `./backend.md`; provisioning lives in `./infra.md`.

## Tool picks

- **node-pg-migrate** — migrations with real paired `up`/`down`, so the base reversibility and up→down→up round-trip rules apply verbatim, with no override.
- **`pg` directly — no ORM** (rejected: Prisma/Drizzle): repos are thin mappers over explicit SQL, there is no codegen step or client weight on a cold-starting function, and the SQL is reviewed as SQL.

## Migrations

- Live under `db/migrations/`, run via the root `migrate` verb (node-pg-migrate `up`, pointed at `db/migrations`; rollback via `migrate:down`). Create with `node-pg-migrate create <verb_noun>` — the generated epoch-ms prefix satisfies the base timestamp rule.
- **Migrations are CommonJS `.cjs` files**, each exporting `up(pgm)` and `down(pgm)`. node-pg-migrate loads them via `require()` and the workspace is `"type": "module"`, so a `.js` ESM migration fails to load.
- **Reversibility, bound:** every `up` ships its real `down`. A genuinely irreversible change sets `exports.down = false` *and* carries the base's justification comment — never silently.
- Each migration runs **in a transaction by default** (base rule satisfied). Disable per migration only for DDL that demands it (e.g. `CREATE INDEX CONCURRENTLY`), with a comment saying so.
- Prefer the `pgm` builders (`createTable`, `addColumns`, `createIndex`); drop to `pgm.sql` for anything they don't express.
- **Run migrations against the direct (non-pooled) connection string.** The app runs on the pooled endpoint (see *Repo ring binding*); DDL and migration locks through a transaction pooler misbehave.

## Schema conventions

- Base schema conventions apply unchanged (`db/CLAUDE.md` *Schema conventions*) — bound here: `created_at`/`updated_at` as `timestamptz` defaulted `now()`; FK/filter indexes declared explicitly (Postgres does not auto-index FKs); money as integer minor units or `numeric(p,s)`; unique-violation → domain conflict → `409`.
- **uuid primary keys** via `gen_random_uuid()` (opaque, non-enumerable).
- **Fixed value sets are `text` + a `CHECK` constraint, not native enums** (rejected: Postgres enum types — `ALTER TYPE … ADD VALUE` is non-transactional and effectively one-way; widening a `CHECK` is a plain reversible migration).

## Repo ring binding (`pg`)

- **One `pg.Pool` per process**, created at boot by the backend's db aspect with `max: DB_POOL_MAX`; repos receive it via the container — never construct their own client.
- **Serverless pooling:** every function instance has its own pool and instances multiply under load. Keep `DB_POOL_MAX` **small in production** (single digits) and point the runtime `DATABASE_URL` at **Neon's pooled (PgBouncer) endpoint**, so many instances share one Postgres safely; locally the defaults are fine.
- **Parameterized queries only** (`$1` placeholders) — the base "never interpolate request data" rule, bound; string-built SQL is the greppable violation.
- **Mappers at the boundary:** each repo translates rows ↔ domain objects; a raw row (snake_case fields) never crosses inward. Select explicit column lists where a subset suffices — no reflexive `SELECT *`.
- **Transactions:** the db aspect exports `withTransaction(work)` — the callback receives a client, and repos accept an optional client argument so a multi-write use case shares one transaction. Services receive `withTransaction` from the container and never import `pg`. A single-write use case relies on the statement's own atomicity — don't open a transaction for one `INSERT`.

## Local dev & seed

- **Local Postgres is one fixed-name Docker container** (`postgres:16`), started by the root `db:up`/`bootstrap` script with start-or-run semantics, shared across worktrees per the root `CLAUDE.md` — reuse it, never start a second copy.
- **Seed:** `db/seed-dev.<ext>`, idempotent (upsert by business key), run explicitly via a root script with `--env-file` — non-production only (base rule stands).
- **One shared container, one database per worktree.** Round-trip and destructive checks run against your own worktree database — scratch by construction; never run `migrate`/`migrate:down`/reset against another worktree's. Set a worktree up like this:
  1. Derive the database name from the branch: sanitize to `[a-z0-9_]`, truncate to Postgres's 63-byte identifier limit, prefix `app_` (`feature/x` → `app_feature_x`).
  2. After copying `.env` in, re-point the db-name segment of `DATABASE_URL` at that database.
  3. Let `bootstrap`/`db:up` create the database if missing (`CREATE DATABASE` — node-pg-migrate does not auto-create it).
  4. Drop the database on worktree teardown.

## Operations

CI runs the db gate from `../README.md`'s CI checklist, against a scratch `postgres:16` service container: migrations apply from zero, the round-trip `up → down → up` passes (this fills the base `ci.yml` migration-gate stub), and the seed runs twice.

### Production & staging migrations (Neon)

**Deploys do not run migrations.** Vercel builds and ships the deployment; nothing runs `migrate`. Run each migration manually, before the push that needs it, against the target Neon branch:

```bash
DATABASE_URL="<neon-prod-direct-connection-string>" pnpm migrate
```

- Use the **direct** (non-pooled) connection string (per *Migrations*); a shell-set `DATABASE_URL` wins over `--env-file`, so this overrides the local `.env` without editing it.
- Confirm the target first — this writes the live DB — then verify the `pgmigrations` table and the affected tables.
- **Migrate before you push the code that reads the new schema.** A push deploys on Vercel's pipeline without waiting for any migration (`./infra.md` → *Deploy seam*).
- Keep each migration **backward-compatible** (expand → migrate → contract, base `db/CLAUDE.md`) so the brief window where the previous deployment meets the new schema — or the new deployment meets the old — never breaks.
- **Staging (`develop`) is the same runbook against its own Neon branch** — migrate it before pushing `develop`; pull its connection string per *Gotchas*.

## Gotchas

- **`vercel env pull --git-branch=develop` does not export the branch-scoped `DATABASE_URL`** — it comes back empty. Take the develop branch's connection string from Terraform state or the Neon console, and never migrate through the Neon-injected `POSTGRES_URL` — it points at the **production** branch.

## Conflict register

- **Base says:** Shared local infrastructure (a containerized DB) is shared across worktrees by a fixed name, and the shared DB's schema is **global state** across worktrees — destructive checks go to a throwaway DB (root `CLAUDE.md`; `db/CLAUDE.md`). **In this stack:** the *server* stays shared by its fixed name, but each worktree migrates its own `app_<sanitized-branch>` database, created on bootstrap and dropped on teardown. **Because:** parallel worktrees applying different branches' migrations to one schema break each other; per-worktree databases remove the hazard and make the up→down→up round-trip safe by construction, with no second container. **Concretely:** after copying `.env` in, re-point the db-name segment of `DATABASE_URL` at this worktree's database; DON'T run `migrate`/`migrate:down`/reset against the shared default database or another worktree's.
