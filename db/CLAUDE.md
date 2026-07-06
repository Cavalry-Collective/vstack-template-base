# Database contract

Binding for everything under `db/` — migrations (`db/migrations/`), data backfills (`db/backfills/`), and the seed/reset scripts. Read with it: the root `CLAUDE.md`, and — if a stack pack is adopted — its `db.md` appendix, which binds these client-agnostic rules to the concrete tool; its conflict register wins over this file for that stack only.

Migrations are one of the highest-risk surfaces in any project — irreversible data loss, table locks, ordering collisions, and prod/dev divergence all originate here. The backend's repo-ring adapters *read* the schema at runtime; only migrations here *change* it, applied via the root `migrate` command.

## Never violate

1. **Never edit an applied migration.** Once merged or applied anywhere it is immutable — fix forward with a new migration. Editing applied history is the single most common way an agent corrupts a shared or production database.
2. **Reversible, or justified.** Every migration pairs an `up` with a `down`, OR carries an explicit irreversible-change justification. Never neither.
3. **No destructive change in one step.** Non-additive changes go expand → migrate → contract (below).
4. **Seed/reset never touch a shared or production database.**
5. **No DDL from application code** — schema changes happen here, only here.

## Migration rules

- **Ordered, timestamp-prefixed naming:** `<timestamp>_<verb_noun>` (`20260601120000_add_orders_table`), monotonic, never reused. A timestamp, never a hand-incremented sequence — parallel branches must not claim the same number. Before merging, rebase and confirm your migration still sorts after everything on trunk; if it no longer sorts last, regenerate it with a current timestamp.
- **Prove the down path, not just the up.** Before merge: up → down → up on a throwaway scratch DB, confirming a clean round-trip. State the evidence observed. (A forward-only tool binds this differently — see the adopted pack's `db.md` register.)
- **Expand → migrate → contract for destructive changes** (DROP, NOT NULL on populated tables, type narrowing): add the new shape → migrate data onto it → remove the old shape once nothing reads it — split across migrations/releases so a rollback never loses data.
- **Separate schema from data.** Backfills live under `db/backfills/`, invoked explicitly, never inside a schema migration. Batched, idempotent, resumable — a large or interrupted run never half-applies.
- **Transactional where the engine supports it,** so a failed migration rolls back rather than leaving the schema half-changed.
- **Seed/reset are non-production only,** idempotent, with **realistic, named** accounts and content (not `user1`/`user2`) so manual and e2e testing exercise lifelike data. (With the `test-mode` add-on, these accounts also back its test-user picker.)

## Schema conventions (engine-agnostic)

The active pack binds the mechanics; these hold regardless:

- snake_case table and column names.
- Every table carries `created_at` and `updated_at`.
- Timestamps in UTC, in the engine's timezone-aware type; convert for display at the edge.
- Index every foreign key and every frequent filter/sort column — engines don't do this for you.
- Money and quantities in exact types (integer minor units or decimal) — never floats.
- Unique constraints encode business invariants in the database, not in service-layer checks that race; map violations to the domain conflict (`409`).

## Shared DB across worktrees

The local DB is **global state** shared across worktrees by a fixed name (root contract → *Working in a git worktree*). A migration, reset, or seed run in one worktree changes the schema every other worktree's app depends on. Round-trip and destructive checks run against a **throwaway DB**, never the shared one, while parallel worktrees depend on the current schema.

## Definition of done — verify a change

- [ ] The migration applied cleanly to a scratch DB, and the round-trip (up → down → up) succeeded — or the adopted pack's bound gate passed, or the irreversible justification is recorded.
- [ ] Destructive work is staged expand → migrate → contract, each stage a separate migration.
- [ ] Seed still runs twice in a row successfully (idempotent).
- [ ] Evidence stated: what you ran, against which database, what you observed.
