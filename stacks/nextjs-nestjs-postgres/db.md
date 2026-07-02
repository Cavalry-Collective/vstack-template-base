# Postgres + Prisma db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `db/CLAUDE.md` (+ the backend repo ring) to Postgres + Prisma. Read the base first. Language-neutral: the generated client is identical at runtime in TS and plain JS — TS gets static types; plain JS pins the same shapes with JSDoc `@typedef`. Notes flagged **[JS]** need extra plain-JS setup.

## Binding at a glance

- **ORM / migrations:** Prisma (`schema.prisma` + Prisma Migrate). **Prisma Migrate is forward-only — it generates no `down`** — rejected alternative: hand-written paired down SQL; a paired `down` cannot recover dropped data, so reversibility is served by expand-and-contract plus backups (register).
- **Migrations home:** `db/migrations/`, via `migrations.path` in the root Prisma config (§Migrations) — Prisma's default `apps/backend/prisma/migrations` is redirected to satisfy the base home.
- **Local dev:** one shared Postgres server, one database per worktree (register).
- **Scope:** this file owns the data layer — schema, migrations, seed/reset, indexes/constraints, and the Prisma-row → domain mapper boundary. Ring wiring and the `TransactionRunner` port are defined in the backend appendix; this file binds Prisma to them.

## Schema — `apps/backend/prisma/schema.prisma`

- **One** `schema.prisma`, owned by the backend — the single declarative source; never hand-write `CREATE TABLE` outside a generated migration's SQL.
- Models **PascalCase singular** (`User`, `PaymentMethod`); tables **snake_case plural** via `@@map("payment_methods")`. Fields **camelCase**; columns **snake_case** via `@map`. Apps read camelCase; the database stays idiomatic SQL.
- **Name both sides of every relation** with `@relation(...)` and a named FK field — never rely on implicit naming beyond a trivial 1-1. **Declare `onDelete` explicitly** (default is restrict); choose `Cascade` only with a stated reason that agrees with the soft-delete stance below.
- **Prisma `enum`** (→ native Postgres enum) for any fixed value set — never free text. Postgres enums are append-only: add **one value per migration**, and never use a freshly-added value as a column default in the same migration (`ALTER TYPE … ADD VALUE` is non-transactional).
- **IDs — pack default, not a per-project choice.** Externally-exposed ids are `@id @default(uuid())` (opaque, non-enumerable, URL-safe); `@default(autoincrement())` only for internal-only tables never exposed in an API or URL, with a stated reason.
- **Timestamps** (rule: `db/CLAUDE.md`): every model carries `createdAt DateTime @default(now())` and `updatedAt DateTime @updatedAt`, `@map`ped to `created_at`/`updated_at` and stored `timestamptz`.
- **Money/quantity** (rule: `db/CLAUDE.md`): `Decimal` (`@db.Decimal(p, s)`); the Prisma `Decimal` object stops at the repo mapper — the domain holds its own money/number type. **`Json` only for genuinely schemaless payloads**, never for data you query or join on.
- **Soft delete is opt-in.** Most tables hard-delete. Where history matters add `deletedAt DateTime?` and filter in the repo ring — no "is it deleted?" checks in services/domain, and **no global Prisma soft-delete middleware** that silently rewrites every query. A uniqueness rule on a soft-deletable column is a **partial unique index** (`WHERE deleted_at IS NULL`) so a deleted row never blocks reusing its value.

## Migrations

- **Location.** Set `migrations.path = "db/migrations"` in the project-root Prisma config (`prisma.config.{ts,js,mjs,cjs,mts,cts}`) — the path resolves relative to the config file, so the literal value is `db/migrations`. Config-file-only; no env override. Valid because the "migrations sit next to the datasource" constraint binds only multi-file (`prismaSchemaFolder`) schemas. `db/migrations/` then holds `<timestamp>_<name>/migration.sql` folders + `migration_lock.toml`. **[JS]** plain `prisma.config.js`/`.mjs`.
- **Reversibility = forward-only + expand-and-contract (register).** Additive changes: forward-only `migration.sql` suffices — the obvious inverse is the justification. Destructive changes: restructure as expand-and-contract (§Schema vs data changes), or, if truly one-shot, open `migration.sql` with a one-line `-- IRREVERSIBLE:` header stating why and the recovery path (restore-from-backup) — the base's "explicit justification" made concrete. `db/migrations/README.md` stays a bare pointer at the base rules; don't restate the override there.
- **The base "prove the down path" is met by the §CI gates** — apply-from-zero on a scratch DB + the drift gate, plus proving the expand-and-contract (or `-- IRREVERSIBLE:` recovery) path for destructive changes. State the evidence you observed, as the base demands.
- **Review the generated SQL before committing** (`prisma migrate dev --create-only`): no unintended `DROP`, no unguarded `NOT NULL` on a populated table, no full-table rewrite or lock-heavy DDL on a hot table, enum rule respected. A migration is a reviewed artifact, not generated-and-forgotten.
- **Never edit an applied migration** — once merged, assume applied; corrections go in a new migration (an edit is a checksum mismatch Prisma rejects).
- **Naming:** `prisma migrate dev --name <verb_noun>` in snake_case (`add_orders_status_index`, `drop_legacy_email_column`) — never `update`/`fix`. One logical schema change per migration.
- **Apply path:** `prisma migrate deploy` in CI/release; `prisma migrate dev` is local-only.

## Schema vs data changes

- Structural DDL lives in the Prisma migration SQL. **Backfills are idempotent, re-runnable scripts under `db/backfills/`, invoked explicitly** — never inside a `migrate` SQL file, where they run under the schema lock and block on large tables.
- **Breaking changes are expand → backfill → switch → contract, never one destructive migration:** add the new shape nullable/defaulted → batched idempotent backfill that **asserts source-row count == migrated-row count and exits non-zero on mismatch** → deploy code reading/writing the new shape → drop the old shape in a *later* migration once the switch is live and stable.
- **Zero-downtime mindset.** Old and new code run concurrently during deploy; every migration must be safe against the previously-deployed code — no rename-in-place, no `NOT NULL` without a default or prior backfill, no lock-heavy DDL on a hot table without batching.

## Client boundaries

- `prisma generate` outputs the client **as a backend dependency only**. **[JS]** plain-JS backends still run `prisma generate` and import it normally.
- **Only the repo ring imports the Prisma client.** Domain and service rings never import it, name a Prisma type, or receive a `PrismaClient` — they depend on the domain's ports. `PrismaService`/module wiring and the composition-root override: backend appendix.
- **HARD RULE: the Next.js app never imports Prisma and never touches the database.** Server components / route handlers / server actions fetch through the NestJS API over HTTP, not the DB. A Prisma import anywhere under `apps/frontend/` is a violation — this closes the direct-DB-in-a-server-component loophole the App Router invites.
- **Mapper discipline.** Prisma result objects — including `Decimal`, `Json`, and relation payloads — **stop at the repo boundary**, both directions: rows → domain objects inward, domain objects → Prisma args outward. The row/args shape is a TS `interface`, or a JSDoc `@typedef` on the mapper **[JS]**.

## Transactions

- The `TransactionRunner` unit-of-work port is **defined in the backend appendix**; this file binds it to Prisma's **interactive transaction**: the repo-ring implementation runs the use-case callback inside `prisma.$transaction(async (tx) => …)` and binds `tx` so every repo call inside shares one transaction.
- The service depends only on the port — it never imports `$transaction`; a `$transaction` call outside the repo-ring port implementation is a violation.
- Keep transactions short — no network/LLM/external calls inside an open transaction (it holds a connection and locks); set explicit `timeout`/`maxWait`. The array form `$transaction([...])` only for independent writes with no read-then-write logic between them.

## Local dev — per-worktree database

- **One shared Postgres server, one database per worktree (register).** Reuse the fixed-name shared container (root `CLAUDE.md`) — never start a second; never run `migrate`/`reset` against another worktree's (or a shared/staging) database.
- **DB name, derived deterministically:** sanitize the branch name to `[a-z0-9_]`, truncate to Postgres's 63-byte identifier limit, prefix `app_` (`feature/x` → `app_feature_x`). Copy `.env` in first (root `CLAUDE.md`), then re-point the db-name segment of `DATABASE_URL` at this worktree's database; it is created on first `prisma migrate dev`/`reset`. Drop it on worktree teardown so orphaned databases don't accumulate.
- **Bounded connections:** set an explicit `connection_limit` on `DATABASE_URL`; behind a pooler (PgBouncer) set `pgbouncer=true` and avoid features needing session-level prepared statements.
- **Seed/reset bind the base scripts** — not a parallel mechanism. Seed via `prisma db seed`, configured at `migrations.seed` in the Prisma config (`migrations: { seed: "node db/seed.<ext>" }` — **not** the removed `package.json#prisma` block); idempotent (upsert by business key) and realistic minimal. Reset = `prisma migrate reset` (drops the worktree DB, replays all migrations, runs seed).

## Query hygiene & correctness

- **Index every foreign key and every frequent filter/sort column** (`@@index`) — Postgres does not auto-index FKs and Prisma does not add one; an un-indexed FK is the default lock-contention and slow-join trap.
- **Unique invariants** (rule + 409 mapping: `db/CLAUDE.md`): model them as `@@unique` — a partial unique index where soft delete applies — and map Prisma's unique-violation error (`P2002`) to the domain conflict in the repo ring.
- **Avoid N+1.** Load relations with `include`/`select` in one query, never a per-row loop; `select` only the columns the use case needs.
- **Pagination binds the base REST params.** The controller validates `page`/`recordsPerPage`/`sortBy`/`sortOrder` against an allow-list of sortable columns; the repo applies the matching `skip`/`take`/`orderBy` (never fetch-all-then-slice) and **whitelists the column against that same allow-list** before building a dynamic `orderBy`. Prefer keyset/cursor (Prisma `cursor` + `take`) over deep `skip` for large or frequently-paged datasets.

## CI checks

Run in `ci.yml` against a scratch Postgres service container — the single home for the migration/seed gates referenced above:

- **Migrations apply from zero:** `prisma migrate deploy` on a clean scratch DB.
- **Drift gate** (catches a schema edited without a migration, or an edited applied migration): `prisma migrate status` (all applied, checksums intact) **and** `prisma migrate diff --from-migrations ./db/migrations --to-schema ./apps/backend/prisma/schema.prisma --exit-code` — exit 2 (non-empty) fails the build. Use `--to-schema`, not the legacy `--to-schema-datamodel`. `--from-migrations` needs a shadow database — pass `--shadow-database-url $DATABASE_URL` (pre-v7) or read it from the datasource (`--from-config-datasource`/`--to-config-datasource`, v7+).
- **Seed idempotency:** run the seed on the freshly-migrated scratch DB, then a **second time** — both must succeed.

## Conflict register

- **Base says:** every migration pairs `up` with `down` or carries an explicit irreversible-change justification, and the down path is proved up→down→up on a scratch DB before merge (`db/CLAUDE.md`). **In this stack:** Prisma Migrate is forward-only — no `down` exists; reversibility is expand-and-contract, destructive one-shots carry the `-- IRREVERSIBLE:` header + recovery path, and the merge-time proof is the §CI gates (mechanics: §Migrations). **Because:** the header *is* the base's permitted explicit justification, and the CI gates replace a round-trip that has no `down` to run. **Concretely:** DON'T commit a destructive `migration.sql` without an expand-and-contract plan or that header; DO state the CI-gate evidence you observed.
- **Base says:** three surfaces reference a paired up→down→up round-trip — `ci.yml`'s TODO gate, root `README.md`'s Day-1 checklist, and the PR template's Database checkbox. **In this stack:** the round-trip is impossible; the §CI drift gate is the bound check. **Because:** leaving the TODO in place would tell an instantiating agent to wire a check this pack made impossible. **Concretely:** when pasting the pack CI block, DO replace the `ci.yml` "Migration round-trip" TODO with the §CI drift gate; read the Day-1 line and the PR-template Database checkbox as that gate.
- **Base says:** shared local infrastructure is shared across worktrees by a fixed name, and the local DB is global state (root `CLAUDE.md`, `db/CLAUDE.md`). **In this stack:** keep the single shared Postgres server, but each worktree migrates its own `app_<sanitized-branch>` database (mechanics: §Local dev). **Because:** two worktrees running `migrate dev` against one shared database corrupt each other's migration history. **Concretely:** after copying `.env`, DO re-point `DATABASE_URL` at this worktree's DB; DON'T run `migrate`/`reset` against the shared `app` database or another worktree's.
