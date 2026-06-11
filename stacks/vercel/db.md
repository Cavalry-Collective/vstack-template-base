# Postgres (Neon) + node-pg-migrate + pg — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds the base `db/CLAUDE.md` (+ the backend repo ring) to **Postgres** — **Neon** (serverless, via the Vercel marketplace) in production, a fixed-name Docker container locally — with **node-pg-migrate** for migrations and **`pg`** (node-postgres) as the query layer. Read the base files first.

**Scope.** This file owns migrations, seed, schema conventions, and the repo-ring query/pool/transaction mechanics. Container wiring and the Vercel entrypoint live in `./backend.md`; provisioning lives in `./infra.md`.

## Tool picks

- **node-pg-migrate** — migrations with real paired `up`/`down`. Chosen deliberately so the base reversibility and up→down→up round-trip rules apply **verbatim, with no override** (contrast: ORM-based packs must rewrite them).
- **`pg` directly — no ORM.** Pack decision — rejected alternatives: Prisma/Drizzle. Repos are thin mappers over explicit SQL; no codegen step or client weight on a cold-starting function; the SQL is reviewed as SQL.

## Migrations

- Live under `db/migrations/`, run via the root `migrate` verb (node-pg-migrate `up`, pointed at `db/migrations`; rollback via `migrate:down`). Create with `node-pg-migrate create <verb_noun>` — the generated epoch-ms prefix satisfies the base timestamp rule.
- **Migrations are CommonJS `.cjs` files.** node-pg-migrate loads them via `require()` and the workspace is `"type": "module"`, so a `.js` ESM migration fails to load. Each exports `up(pgm)` and `down(pgm)`.
- **Reversibility, bound:** every `up` ships its real `down`. A genuinely irreversible change sets `exports.down = false` *and* carries the base's justification comment — never silently.
- Each migration runs **in a transaction by default** (base rule satisfied). Disable per migration only for DDL that demands it (e.g. `CREATE INDEX CONCURRENTLY`), with a comment saying so.
- Prefer the `pgm` builders (`createTable`, `addColumns`, `createIndex`); drop to `pgm.sql` for anything they don't express.
- **Run migrations against the direct (non-pooled) connection string.** The app runs on the pooled endpoint (below); DDL and migration locks through a transaction pooler misbehave.

## Schema conventions

- snake_case tables and columns. **uuid primary keys** via `gen_random_uuid()` (opaque, non-enumerable). Every table carries `created_at`/`updated_at` as `timestamptz` defaulted `now()`.
- **Index every FK and frequent filter/sort column explicitly** — Postgres does not auto-index FKs.
- **Fixed value sets are `text` + a `CHECK` constraint, not native enums.** Pack decision — rejected alternative: Postgres enum types (`ALTER TYPE … ADD VALUE` is non-transactional and effectively one-way; widening a `CHECK` is a plain reversible migration).
- **Money is integer minor units (or `numeric(p,s)`) — never `float`/`real`.** Unique constraints encode business invariants in the database; map a unique-violation to the domain conflict → `409` (base status-code table).

## Repo ring binding (`pg`)

- **One `pg.Pool` per process**, created at boot by the backend's db aspect with `max: DB_POOL_MAX`; repos receive it via the container — never construct their own client.
- **Serverless pooling:** every function instance has its own pool and instances multiply under load — keep `DB_POOL_MAX` **small in production** (single digits) and point the runtime `DATABASE_URL` at **Neon's pooled (PgBouncer) endpoint**, so many instances share one Postgres safely. Locally the defaults are fine.
- **Parameterized queries only** (`$1` placeholders) — the base "never interpolate request data" rule, bound; string-built SQL is the greppable violation.
- **Mappers at the boundary:** each repo translates rows ↔ domain objects; a raw row (snake_case fields) never crosses inward. Select explicit column lists where a subset suffices — no reflexive `SELECT *`.
- **Transactions:** the db aspect exports `withTransaction(work)` — the callback receives a client, and repos accept an optional client argument so a multi-write use case shares one transaction. Services receive `withTransaction` from the container and never import `pg`. A single-write use case relies on the statement's own atomicity — don't open a transaction for one `INSERT`.

## Local dev & seed

- **Local Postgres is one fixed-name Docker container** (`postgres:16`), started by the root `db:up`/`bootstrap` script with start-or-run semantics, shared across worktrees per the root `CLAUDE.md` — reuse it, never start a second copy.
- **Seed:** `db/seed-dev.<ext>`, idempotent (upsert by business key), run explicitly via a root script with `--env-file` — non-production only (base rule stands).
- Worktrees: the base shared-DB global-state rules stand unchanged; run round-trip and destructive checks against a scratch database created on the same server, never the shared one.

## CI checks (drop into `.github/workflows/ci.yml`)

Against a scratch `postgres:16` service container: migrations apply from zero (`up`); **round-trip `up → down → up`** — the base gate, mechanically possible in this stack, so keep the base `ci.yml` round-trip TODO's wording; run the seed twice (idempotency).

## Conflict register

_No conflicts — this appendix only adds bindings; the base contract is unchanged._
