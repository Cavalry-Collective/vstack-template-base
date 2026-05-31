# Database scripts

Top-level home for DB **migrations** and related scripts (seed, reset, etc.),
shared across the repo. Migrations are reversible (`up` paired with `down`, or an
explicit justification for an irreversible change), one per schema change, kept in
order under `db/migrations/`. The backend reads/runs them; see
`apps/backend/CLAUDE.md` for the runtime DB client.
