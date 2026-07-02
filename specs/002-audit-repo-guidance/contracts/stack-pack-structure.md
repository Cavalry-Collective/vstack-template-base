# Contract: Canonical Stack-Pack Structure

Every directory under `stacks/` is a stack pack and must satisfy this contract (FR-015, SC-011). The contract itself gets documented for future authors in `stacks/README.md` — this file is the checkable form.

## Required files

| File | Purpose |
|---|---|
| `README.md` | What the stack is, when to choose it, adoption steps at instantiation |
| `backend.md` | Binds `apps/backend/CLAUDE.md` contracts to the concrete stack |
| `frontend.md` | Binds `apps/frontend/CLAUDE.md` contracts to the concrete stack |
| `db.md` | Binds `db/CLAUDE.md` contracts to the concrete stack |
| `infra.md` | Binds `infra/CLAUDE.md` contracts to the concrete stack |

## Rules

- **Absence is a statement.** An area that genuinely doesn't apply still ships its file, reduced to a stub: what doesn't apply and **why** (e.g. "no self-managed infrastructure: this stack deploys exclusively to <platform>"). A missing file is a conformance failure.
- **Same shape, parallel reading.** Each area file addresses the same concerns its generic counterpart defines, in the same order, so any two packs can be compared side by side.
- **No silent contradictions.** A pack instruction may not contradict the generic tier. A sanctioned deviation is marked in place: `**Exception** (sanctioned): <rule it deviates from> — <why this stack requires it>`. Unlabelled contradictions are findings (FR-006).
- **Detail lives here.** Implementation-level specifics (framework idioms, service names, tool commands) belong in the pack, never in the generic tier (FR-005).
- **Genuine differences only.** Structural divergence between packs is allowed only where the stacks genuinely differ, and the difference is stated, not implied.

## Conformance check

For each pack: all five files `present` or `n/a-declared`; zero unlabelled contradictions against the generic counterpart; side-by-side comparison with any other pack shows the same section shape.
