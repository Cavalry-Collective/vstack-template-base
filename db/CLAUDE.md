# Database

The database contract — read before touching anything under `db/`. Repo-wide rules (principles, workflow, cross-app standards) live in the root `CLAUDE.md`. This file governs migrations and the seed/reset scripts that share this folder.

Migrations are one of the highest-risk surfaces in any project — irreversible data loss, table locks, ordering collisions, and prod/dev divergence all originate here. The rules below are checkable and client-agnostic (no specific migration tool is assumed). **If a stack pack is adopted (a single directory kept under `stacks/`), also read its `db.md` appendix before working here** — it binds these rules to the concrete tool, and its conflict register resolves any disagreement with this file, for that stack only.

`db/` is the shared home for **migrations** (under `db/migrations/`) and related **seed/reset** scripts. The backend's repo-ring adapters read from the database at runtime (see `apps/backend/CLAUDE.md`); the migrations here are applied via the root `migrate` command (see root `CLAUDE.md`).

## Migration rules

- **Ordered, timestamp-prefixed naming.** Name each file with a timestamp/sequence prefix and a short description (e.g. `20260601120000_add_orders_table`), monotonic and never reused. Use a timestamp, never a hand-incremented sequence — parallel branches must never both claim the same number. Before merging, rebase onto trunk and re-check that your migration still sorts after every migration already on trunk.
- **Reversible, or justified.** Every migration is reversible — an `up` paired with a `down` — OR carries an explicit irreversible-change justification comment. Never neither.
- **Never edit an applied migration.** Once a migration is merged or applied anywhere, treat it as immutable — fix forward with a new migration. Editing an applied migration is the single most common way an agent corrupts a shared or production database.
- **Separate schema from data.** Keep schema migrations apart from data backfills. Make backfills batched, idempotent, and resumable, so a large or interrupted run never half-applies.
- **Expand → migrate → contract for destructive changes.** For non-additive or destructive changes (DROP COLUMN/TABLE, NOT NULL on a populated table, type narrowing), split the work across separate migrations/releases so a rollback never loses data: add the new shape, migrate onto it, then remove the old shape once nothing reads it.
- **Prove the down path, not just the up.** Before merging, run the migration up, then down, then up again on a throwaway scratch DB and confirm a clean round-trip — don't rely on the down script being present but untested. State the evidence you observed.
- **Transactional where supported.** Run each migration in a transaction where the engine supports it, so a failed migration rolls back instead of leaving the schema half-changed.
- **Seed/reset are non-production only.** Seed and reset scripts are idempotent and run only against local/throwaway databases — never against a shared or production database. Prefer **realistic, named** seed accounts and content (not `user1` / `user2`) so manual and e2e testing exercises lifelike data. (If the project adopts the **test-mode** add-on, those seeded accounts also back its test-user picker — see `add-ons/test-mode/`.)

## Shared DB across worktrees

The local DB is **global state** shared across worktrees by a fixed name (see *Working in a git worktree* in root `CLAUDE.md`). A migration, reset, or seed run in one worktree changes the schema every other worktree's app depends on. Run round-trip and destructive checks against a throwaway DB, never the shared one, while a parallel worktree depends on the current schema.
