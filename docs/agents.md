# AI agents in this repo

This template assumes most changes are made by AI agents working alongside humans. The binding rules are in root `CLAUDE.md` → *Working rules for agents*; this guide is the fuller playbook — how a good agent session in this repo actually runs.

## The contract-loading model

Contracts sit where agents already look: a `CLAUDE.md` in each area auto-loads when an agent works there. Two conditional layers ride on top — the adopted stack pack's appendix for the area, and any adopted add-on's README for the capability. **The reading for a task is therefore mechanical:**

| Task touches | Read |
|---|---|
| `apps/backend/` | root contract → `apps/backend/CLAUDE.md` → `stacks/<pack>/backend.md` (if adopted) → relevant add-on READMEs |
| `apps/frontend/` | root contract → `apps/frontend/CLAUDE.md` → `stacks/<pack>/frontend.md` → relevant add-on READMEs |
| `db/` | root contract → `db/CLAUDE.md` → `stacks/<pack>/db.md` |
| `infra/` | root contract → `infra/CLAUDE.md` → `stacks/<pack>/infra.md` (if the pack ships one) |
| a screen's look/flow | `design/README.md` + the design guide's never-violate gates (`apps/frontend/CLAUDE.md` → *Design guide*) |

Precedence on disagreement: pack conflict register → area contract → add-on README → root contract. A contradiction with no register entry is a defect — report it; don't arbitrate silently.

## Inspect before you change

1. **Read the target code and its neighbours.** The nearest existing feature module/slice is the pattern; diverge only deliberately and say so. Grep for prior art before writing anything shared — a second implementation of something that exists is the canonical failure here.
2. **Find the spec.** Feature work without a spec under `specs/` starts by writing one, not by coding.
3. **Check the seams you're about to cross.** Changing an endpoint? Read its consumers in `apps/frontend/src/services/`. Changing schema? Read the repo-ring adapters that map it. Changing a shared primitive? Grep its call sites first.

## Where new code goes

Use the decision path in [`project-structure.md`](project-structure.md#where-does-a-new-file-go-decision-path). Two rules of thumb resolve most hesitation:

- **Business meaning decides the home.** Speaks the business's language → domain ring / feature organism / feature module. Doesn't → shared tier, and only once genuinely shared.
- **When two homes seem right, pick the more inward/specific one.** Promotion outward (to `shared/`, `lib/`, atoms) happens when a second caller appears — never in anticipation.

## Avoiding overengineering

The root Principles are the law (Simplicity first / YAGNI); in practice, before adding anything, an agent should be able to answer:

- *What breaks today without it?* If nothing, don't add it.
- *What's the simpler option, and why is it rejected?* That line goes in the PR verbatim. Can't write it → build the simpler option.
- *Is this the second caller?* No → no abstraction, co-locate instead.

Symptoms to self-check: a config key nothing reads yet, an interface with one implementation, error handling for a state the code can't reach, a util file with one import.

## Refactors

- A refactor is its own branch and PR — never smuggled into a feature diff.
- Behaviour is pinned before the shape changes: the existing tests pass unmodified after the refactor (if tests must change, it wasn't a pure refactor — say so).
- Repo-wide pattern fixes beat local forks: if the established pattern is wrong, fix the pattern everywhere in one dedicated change rather than deviating in one spot.
- Leave unrelated dead code alone; flag it in the PR instead.

## Tests

Write them in the same change as the behaviour; pick the cheapest kind that proves it (unit → integration → contract); assert behaviour, not implementation (no broad DOM snapshots, no mocking internals). Bug fixes start with the failing test. Placement per area: each contract's *Testing* section; strategy: [`testing.md`](testing.md).

## Public contracts — do not break

Treat as append-only unless the user explicitly decides otherwise: API routes and shapes, error `code`s and the envelope, URL routes, applied migrations, in-use i18n keys, exported shared utilities and their signatures. The safe moves are **extend** (new field, new route, new key), **version** (`/internal/v2`), or **deprecate with a migration path**. If a task seems to require a breaking change, stop and surface it — with the blast radius you found by grepping consumers.

## Asking questions

Ask when — and only when — the repo can't answer:

- Requirements are ambiguous in a way that changes the design (two readings, different architectures).
- The action is destructive or irreversible (data loss, dropping a public contract, force-push, prod apply).
- Two instruction files genuinely conflict with no conflict-register entry.

Everything else — placement, naming, conventions, test expectations — is written down; look it up and proceed, stating assumptions in the PR. One good clarifying question beats three speculative implementations; three questions that the contracts already answer waste everyone's time.

## Making the change safely

- Smallest diff that solves the problem; match surrounding style; no drive-by reformatting.
- Keep trunk releasable: incomplete work behind a default-off flag.
- Verify by observation (run it, force the states, hit the endpoint) and report exactly what you saw — the area contract's *Definition of done* checklist is the script.
- Run the self-review (root contract) on the full diff before opening the PR.

## Documenting what you did

- Commit messages: Conventional Commits, imperative, one logical change each. Reviewer notes ("moved X because Y") go here, not in code comments.
- The PR fills the template honestly — evidence, not adjectives.
- Structure/workflow/command/contract changes update the governing contract and any affected `docs/` guide **in the same change**.
- Durable discoveries → root `CLAUDE.md` **Learnings**, one line.

## Multi-agent etiquette

Parallel agents each work in their own worktree (root contract → *Working in a git worktree*). The shared traps: one local infra stack by fixed name (reuse it), one shared dev DB whose schema is global state (destructive checks on a throwaway DB), and the merge-back gate serialises trunk mutations — rebase, green suite, fast-forward, delete the worktree.
