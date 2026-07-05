# Development workflow

How work flows from idea to merged trunk. The binding rules live in the root `CLAUDE.md` (*Development workflow*, *Merge-back gate*, *Self-review*); this guide walks the loop.

## The loop at a glance

```
spec (specs/) ──► worktree + branch ──► implement + tests ──► verify (observe, don't infer)
      ▲                                                            │
      └────────── record learnings ◄── merge gate (rebase → green suite → ff-merge) ◄──┘
```

## 1. Spec first

Non-trivial work starts as a short written spec under `specs/` (Spec Kit — `/speckit-specify` and friends). Stories are priority-tagged (P1 = MVP) and independently shippable; each acceptance criterion names *how it will be verified* — the exact command, endpoint call, or screen + states. UI stories that build a new screen name their `design/` mockup. Small fixes and chores don't need a spec — use judgement, but never build a feature from a chat message alone.

## 2. Branch in a worktree

Worktrees are the default so several pieces of work (and several agents) proceed in parallel:

```bash
git worktree add .claude/worktrees/<name> -b feat/<name>
```

Then immediately copy gitignored runtime config into it — the snippet and rules are in root `CLAUDE.md` → *Working in a git worktree*. Remember the two shared-state traps: local infra containers are shared by fixed name (reuse, don't duplicate), and the shared dev database's schema is global across worktrees (destructive checks go to a throwaway DB).

Branch names: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `spike/<topic>`. Spikes are sanctioned exploration — no tests, no DoD — but **never merge**; the real implementation restarts clean on a normal branch.

## 3. Implement in slices

Follow the area contract for whatever you touch; keep each commit one logical change with a Conventional Commits subject. Incomplete work that must land anyway hides behind a default-off config flag — trunk stays releasable at every commit.

## 4. Verify — observed, not inferred

Before calling anything done, run it and state what you saw. Each area contract ends with a *Definition of done* checklist saying what "run it" means there: endpoints exercised over HTTP, four UI states forced, migrations proven on a scratch DB, plans reviewed before apply. The evidence goes in the PR's Test plan.

## 5. The merge-back gate

Ordered, from root `CLAUDE.md`: rebase onto trunk → full suite green **on the rebased state** → fast-forward merge → stop dev servers → delete worktree + branch → push only after confirming (deploy fires from green CI on `main`). The moment trunk is mutated is the moment quality is enforced — never merge red, never skip the rebase.

Before the merge, do the self-review: re-read the whole diff end to end, check layer placement, scope, naming, and that every new abstraction/dependency/config key carries its one-line justification.

## 6. Afterwards

- The spec stays as the record of the decision.
- Anything durable you learned (a toolchain quirk, a decided convention) goes in root `CLAUDE.md` → **Learnings** — one line, not an essay.
- If the change altered structure, commands, workflow, or a public contract, the affected contract/doc was updated in the same change (if not, that's a defect to fix now, not later).

## Releases and deployment

Deployment goes through CI/CD: `deploy.yml` fires only after a green CI run on `main` and checks out the exact commit CI tested. A local deploy path may exist for declared emergencies only. Version bumps follow semver; the frontend renders its version visibly (contract: `apps/frontend/CLAUDE.md` → *Versioning*).
