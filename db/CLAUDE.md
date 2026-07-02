# Database

The database contract — read before touching anything under `db/`: the migrations in `db/migrations/` (its `README.md` marks the folder; they run via the root `migrate` command) and the seed/reset scripts beside them. Stack pack adopted? Read its `db.md` appendix first — precedence rules in `stacks/README.md`.

## Migration rules

- **Ordered, timestamp-prefixed naming.** Name each file with a timestamp prefix and a short description (e.g. `20260601120000_add_orders_table`), monotonic and never reused — a timestamp, never a hand-incremented sequence, which parallel branches will both claim. Before merging, rebase onto trunk and confirm your migration still sorts after every migration already there.
- **Reversible, or justified.** Every migration pairs an `up` with a `down` OR carries an explicit irreversible-change justification comment. Never neither.
- **Never edit an applied migration.** Once merged or applied anywhere, a migration is immutable — fix forward with a new one.
- **Separate schema from data.** Keep schema migrations apart from data backfills; make backfills batched, idempotent, and resumable so an interrupted run never half-applies.
- **Expand → migrate → contract.** Split non-additive or destructive changes (DROP COLUMN/TABLE, NOT NULL on a populated table, type narrowing) across separate migrations/releases so a rollback never loses data: add the new shape, migrate onto it, remove the old shape once nothing reads it.
- **Prove the down path.** Before merging, run the migration up, then down, then up again on a throwaway scratch DB and confirm a clean round-trip — a down script present but untested proves nothing. State the evidence you observed.
- **Transactional where supported.** Run each migration in a transaction where the engine supports it, so a failure rolls back instead of leaving the schema half-changed.
- **Seed/reset are non-production only.** Seed and reset scripts are idempotent and run only against local/throwaway databases. Seed realistic, named accounts and content (not `user1`/`user2`) so manual and e2e testing exercises lifelike data; if the **test-mode** add-on is adopted, those accounts back its test-user picker (`add-ons/test-mode/`).

## Schema rules

- **Money and quantities are exact types** — integer minor units or fixed-precision decimal, never floats.
- **Every table carries created/updated timestamps** in UTC-aware types.
- **Unique constraints encode business invariants.** A uniqueness violation maps to the domain conflict error — HTTP 409 at the edge.

## Shared DB across worktrees

The local DB is global state, shared across worktrees by a fixed name (worktree mechanics: root `CLAUDE.md`). A migration, reset, or seed run in one worktree changes the schema every other worktree's app depends on. Never run a reset or destructive check against the shared DB while a parallel worktree depends on the current schema — use a throwaway DB.
