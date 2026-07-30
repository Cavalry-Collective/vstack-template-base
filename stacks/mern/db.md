# MongoDB (Mongoose) + migrate-mongo — db appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds the base `db/CLAUDE.md` (+ the backend repo ring) to **MongoDB** — a fixed-name Docker container locally, whatever the base `infra/` contract stands up in production — with **Mongoose** as the schema/query layer and **migrate-mongo** for migrations. Read the base files first.

## Scope

This file owns migrations, seed, schema conventions, and the repo-ring model/session mechanics. Connection wiring lives in `./backend.md`; where `migrate` runs in the pipeline is the base `infra/CLAUDE.md` contract's call. Rejected alternatives for the tool picks are in the pack README → *Pack decisions*.

## Stack binding at a glance

- **Mongoose** — the schema/query layer. A document store has no server-side DDL, so the shape must live somewhere in code; Mongoose models are that single home (typed casting, schema validation at the app boundary).
- **migrate-mongo** — migrations with real paired `up`/`down` under `db/migrations/`, so the base reversibility and up→down→up round-trip rules apply.

## What a migration *is* here

No DDL: collections and fields materialise on first write. A migration is what the server holds durable state on — **index create/drop, collection/validator setup, and rewrites of existing documents** (shape changes, backfills). The document shape itself lives in the Mongoose models — see the conflict register for both deltas.

## Migrations (migrate-mongo mechanics)

- Live under `db/migrations/`, run via the root `migrate` verb (`migrate-mongo up`; rollback `migrate:down`). `migrate-mongo-config.js` pins `migrationsDir: 'db/migrations'`, the changelog collection, and **`moduleSystem: 'esm'`** — the workspace is `"type": "module"`, and without the option migrate-mongo `require()`s migrations and fails to load them.
- Create with `migrate-mongo create <verb_noun>` — the generated datetime prefix satisfies the base timestamp rule. Each file exports async `up(db, client)` / `down(db, client)`.
- **Reversibility, bound:** every `up` ships its real `down` — drop the index it created, reverse the rename, unset the field it set. A genuinely irreversible change has a `down` that **throws**, carrying the base's justification comment (migrate-mongo has no `down = false` convention) — never a silent empty `down`.
- **Not transactional** — write every migration idempotent and resumable instead; the conflict register owns the rule.

## Schema conventions (bound)

- Base conventions bound: `timestamps: true` on every schema (`createdAt`/`updatedAt` — camelCase per the register below); BSON dates are UTC by construction; money as integer minor units or `Decimal128` — never a plain float; a **unique index** encodes the business invariant, and a duplicate-key error (`E11000`, code `11000`) maps to the domain conflict → `409`.
- Index every reference field and every frequent filter/sort field — **by migration** (register entry below); MongoDB indexes nothing but `_id` for you.
- `_id` stays the default `ObjectId` (opaque, non-enumerable) — exposed as an opaque string at the edge; don't mint a second id field without a reason.

## Repo ring binding (Mongoose)

- **Only the repo ring imports `mongoose`.** Models are repo-ring artifacts — defined in each module's `repo/`, registered on the single connection the backend's db aspect opens at boot; repos receive their models via the container.
- **Reads are `.lean()` + mapper.** A hydrated Mongoose document carries `save()` and a live connection — leaking one inward hands an inner ring database access. Repos return domain objects mapped from lean docs; use explicit field projections where a subset suffices.
- **Query filters are built from validated scalars, never a request-supplied object.** Operator injection (`{"$gt": ""}` arriving in a JSON body) is the document-store shape of SQL injection — this binds the base "never interpolate request data" rule. Spreading `req.query`/`req.body` into a filter is the greppable violation.
- **Transactions:** the db aspect exports `withTransaction(work)` over a Mongoose session; repos accept an optional session argument so a multi-document use case shares one transaction (replica set required — *Gotchas*). A single-document write is atomic by construction — don't open a transaction for one `updateOne`; prefer modelling an aggregate as one document so its invariants commit atomically.

## Local dev & seed

- **Local MongoDB is one fixed-name Docker container** (`mongo:7`), started by the root `bootstrap` script with start-or-run semantics, shared across worktrees per the root `CLAUDE.md` — reuse it, never start a second copy. Run it as a **single-node replica set** (`mongod --replSet rs0`, one-time `rs.initiate()` in bootstrap) — *Gotchas*.
- **One shared mongod, one database per worktree** (register entry below):
  1. Derive the database name deterministically: sanitize the branch to `[a-z0-9_]`, prefix `app_` — `feature/x` → `app_feature_x`.
  2. After copying `.env` into the worktree, re-point the db-name path segment of `MONGODB_URL` at that name. There is nothing to create — MongoDB materialises a database on first write.
  3. Run round-trip and destructive checks against this worktree database — scratch by construction.
  4. Drop it (`dropDatabase`) on worktree teardown.
- **Seed:** `db/seed-dev.js`, idempotent (`updateOne(..., { upsert: true })` by business key), run explicitly via a root script — non-production only (base rule stands).

## Operations

**CI checks (drop into `.github/workflows/ci.yml`)** — against a scratch MongoDB started as a **single-node replica set** (a `docker run … mongod --replSet rs0` step — *Gotchas*): migrations apply from zero (`up`); **round-trip `up → down → up`** — the base gate stands, migrate-mongo has real downs, so this fills the base `ci.yml` migration-gate stub — with drift asserted the document-store way: there is no schema dump to diff, so capture each collection's `listIndexes` output plus the changelog collection before and after the cycle and fail on any difference; run the seed twice (idempotency).

**Rollout (platform-neutral)** — this pack ships no `infra.md`; where `migrate` runs is the base `infra/CLAUDE.md` pipeline's call. Two rules survive any pipeline: run `migrate` **before** the rollout that reads the new shape, and keep each migration **backward-compatible** (expand → migrate → contract, base `db/CLAUDE.md`) — during a rolling deploy old code meets new documents and new code meets old ones, so a Mongoose model must tolerate both (additive fields with defaults; contract only after nothing reads the old shape).

## Gotchas

- **Multi-document transactions refuse a standalone `mongod`** — a plain container silently breaks `withTransaction`. Run every MongoDB, local and CI, as a single-node replica set; GitHub service containers can't pass `--replSet`, so CI starts the scratch DB with a `docker run` step.

## Conflict register

- **Base says:** schema changes are reversible migrations under `db/`; application code never alters the schema (`apps/backend/CLAUDE.md` *Coding standards*). **In this stack:** the document shape lives in the repo ring's Mongoose models — an additive shape change is a model edit with no migration; migrations own indexes, collection/validator setup, and rewrites of existing documents. **Because:** a document store has no server-side schema object for a migration to alter; the model is the shape's single home, and a parallel "schema" migration would be an empty ritual that drifts. **Concretely:** DO ship every index and every rewrite of existing documents as a migrate-mongo up/down pair under `db/migrations/`; DON'T let app code build indexes — `autoIndex: false` on the connection, and no `schema.index()` calls in models.
- **Base says:** snake_case table and column names. **In this stack:** collection names stay snake_case plural; document fields are camelCase. **Because:** fields are JS object keys end to end (schema → document → mapper) with no storage-side SQL reader to serve; forcing snake_case adds a rename layer with no consumer. **Concretely:** DO pin each collection's snake_case name via the schema's `collection` option; DON'T introduce snake_case field keys — the repo mapper still translates document ↔ domain shapes.
- **Base says:** run each migration in a transaction where the engine supports it, so a failure rolls back cleanly. **In this stack:** migrations are not transactional — migrate-mongo doesn't wrap them, and index builds (most Mongo migrations) can't run inside a MongoDB transaction. **Because:** the engine's transaction support excludes exactly the DDL-like operations migrations mostly perform. **Concretely:** DO write every migration idempotent and resumable (existence-checked creates, batched rewrites keyed on a filter excluding already-rewritten documents) so a failed run re-runs safely; DON'T assume a failed migration left nothing behind.
- **Base says:** keep schema migrations apart from data backfills; backfills live under `db/backfills/`, never inside a schema migration. **In this stack:** a document shape change *is* a data rewrite — a bounded rewrite rides in the migration itself, written to the base's backfill bar (batched, idempotent, resumable); only large or long-running backfills land under `db/backfills/` and run explicitly. **Because:** with no DDL half to separate from, splitting a small rewrite out leaves an empty migration and an orphaned script. **Concretely:** DO keep any in-migration rewrite batched and idempotent; DON'T put an unbounded full-collection scan in a migration — that goes to `db/backfills/`.
- **Base says:** the shared local DB's schema is global state across worktrees; destructive checks go to a throwaway DB (root `CLAUDE.md`; `db/CLAUDE.md`). **In this stack:** the mongod stays shared by its fixed name, but each worktree uses its own `app_<sanitized-branch>` database on it. **Because:** parallel worktrees applying different branches' migrations to one database break each other; per-worktree databases remove the hazard and make the round-trip safe by construction, with no second container. **Concretely:** after copying `.env` in, re-point the db-name path segment of `MONGODB_URL` at this worktree's database; DON'T run `migrate`/`migrate:down`/reset/seed against the shared default database or another worktree's.
