# MongoDB and Mongoose: database appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Use MongoDB 7, Mongoose for document shape and queries, and migrate-mongo for indexes and durable data changes.

## Tools and migration ownership

- Keep Mongoose models in each feature's repository ring.
- Disable Mongoose `autoIndex`.
- Keep migrate-mongo files under `db/migrations/` with async `up(db, client)` and `down(db, client)`.
- Configure migrate-mongo with `moduleSystem: 'esm'`.
- Use migrations for indexes, collection validators, and rewrites of existing documents.
- Use model edits for additive document-shape changes that need no rewrite.

## Migrations

- Create migrations with `migrate-mongo create <verb_noun>` and keep the generated timestamp.
- Implement a real `down`. For a justified irreversible change, make `down` throw with the reason.
- Write every migration as idempotent and resumable.
- Keep bounded document rewrites in the migration. Put large or long-running rewrites under `db/backfills/`.
- Do not assume a failed index build or rewrite rolled back.

## Schema and repositories

- Use `timestamps: true`.
- Keep collection names snake_case plural and document fields camelCase.
- Keep the default ObjectId `_id`.
- Use integer minor units or `Decimal128` for money.
- Create unique and query indexes through migrations.
- Map MongoDB duplicate-key error `11000` to the domain conflict response.
- Import Mongoose only in the repository ring.
- Read with `.lean()` and map documents to domain objects.
- Build filters from validated scalars. Never spread request objects into MongoDB filters.
- Use field projections when a subset is sufficient.

## Transactions

- Run MongoDB as a replica set everywhere.
- Expose `withTransaction(work)` from the database aspect.
- Pass the session to every repository in a multi-document use case.
- Prefer one-document aggregates and single-document atomic writes.

## Local databases

Run one fixed-name MongoDB replica-set container and one database per worktree:

1. derive `app_<sanitised-branch>`;
2. update the copied `MONGODB_URL`;
3. run migrations and destructive checks against that database;
4. drop it when removing the worktree.

Keep `db/seed-dev.js` idempotent and non-production only.

## Operations

CI must:

- start MongoDB with `--replSet rs0` and initialise it;
- apply migrations from zero;
- capture collection indexes and the migration changelog;
- run up, down, and up;
- confirm the captured state is unchanged;
- run the seed twice.

Run migrations before rolling out code that needs the new document shape. Keep models compatible with old and new documents during deployment.

## Conflict register

- **Base says:** schema changes are migrations and application code never changes schema. **In this stack:** Mongoose models own document shape; migrations own indexes, validators, and rewrites. **Because:** MongoDB has no table definition for a migration to alter. **Concretely:** DO ship indexes and rewrites through migrate-mongo; DON'T call `schema.index()` or enable `autoIndex`.
- **Base says:** database field names are snake_case. **In this stack:** collections are snake_case and fields are camelCase. **Because:** fields are JavaScript object keys throughout this stack. **Concretely:** pin the collection name and keep document fields camelCase.
- **Base says:** migrations run transactionally where supported. **In this stack:** migrate-mongo operations are resumable rather than transactional. **Because:** index operations cannot run in a MongoDB transaction. **Concretely:** write existence-checked indexes and filtered batched rewrites; DON'T assume a failed migration left no state.
- **Base says:** data backfills stay outside schema migrations. **In this stack:** bounded document rewrites may live in their migration; large rewrites remain separate backfills. **Because:** a shape change has no separate DDL phase. **Concretely:** keep in-migration rewrites bounded and idempotent; DON'T scan an unbounded collection in a migration.
- **Base says:** the fixed-name local database is shared and destructive checks need a throwaway database. **In this stack:** the MongoDB server is shared but each worktree has its own database. **Because:** parallel migration histories cannot safely share one database. **Concretely:** repoint `MONGODB_URL` after copying the environment file; DON'T migrate, reset, or seed another worktree's database.
