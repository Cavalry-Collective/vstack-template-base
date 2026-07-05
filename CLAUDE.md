# CLAUDE.md — root contract

This file is binding for every change in this repository, human- or agent-made. Each area has its own binding contract; guides under `docs/` explain and walk through, but never override a contract.

> **Do not use the persistent file-based memory.** Never write to or read from the memory directory. Anything worth remembering across sessions goes in **Learnings** at the bottom of this file.

## Repo map and reading order

A monorepo template: two apps, a database area, infrastructure, and the documents that govern them.

| Area | Contract / entry point | Read before touching |
|---|---|---|
| `apps/backend/` | `apps/backend/CLAUDE.md` | anything under `apps/backend/` |
| `apps/frontend/` | `apps/frontend/CLAUDE.md` | anything under `apps/frontend/` |
| `db/` | `db/CLAUDE.md` | migrations, seed/reset scripts |
| `infra/` | `infra/CLAUDE.md` | any Terraform |
| `design/` | `design/README.md` | building or changing a screen |
| `specs/` | `specs/README.md` | starting a non-trivial feature |
| `stacks/` | `stacks/README.md` | system doc — read once, not per task |
| `add-ons/` | `add-ons/README.md` + each kept add-on's README | the capability an add-on covers |
| `docs/` | `docs/README.md` | onboarding; guides, not contracts |

Two conditional layers ride on the area contracts:

- **Stack pack.** If exactly one directory exists under `stacks/`, it is adopted. Read its matching appendix (`backend.md`, `frontend.md`, `db.md`, `infra.md` — the last is optional; some packs ship none) before working in that area — it binds the agnostic contract to the concrete stack. Several directories mean the template is not yet instantiated and no pack binds (`docs/getting-started.md`); **Learnings** (bottom) records the adopted pack and add-ons — if the directory state and Learnings disagree, flag it, don't guess.
- **Add-ons.** Every directory kept under `add-ons/` is adopted. Read its `README.md` and follow it whenever you touch the capability it covers (they are cross-cutting: backend + frontend + db at once).

## Instruction precedence

When instruction files disagree, resolve in this order:

1. The **adopted stack pack's conflict register** — over everything, for that stack only, and only through an explicit register entry.
2. The **area contract** (`apps/*/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md`) — for its own area.
3. An **add-on's README** — for the capability it covers only.
4. **This file** — for everything cross-cutting.

A real contradiction with no register entry is a defect: flag it in your report, don't silently pick a side. Guides under `docs/` carry no authority in a conflict.

## Common commands

> ⚠️ **TEMPLATE-TODO — commands not yet filled in.** No toolchain has been chosen. Replace `<pm>` (package manager) and every command below with real ones, then delete this banner. If a stack pack is adopted, its README ships a ready-made block to paste here.

**Agent: if this block still says TEMPLATE-TODO when you need a command** — detect the real command from the repo (lockfile, `package.json` scripts, Makefile, CI workflow) and use that. If you cannot determine it, stop and ask; never run the literal `<pm>` and never guess a package manager. Once you learn the real commands, offer to fill in this block and `.github/workflows/ci.yml` as part of your change.

```bash
<pm> bootstrap   # TEMPLATE-TODO: install + start local deps + migrate + dev servers
<pm> dev         # TEMPLATE-TODO: run backend + frontend dev servers
<pm> lint        # TEMPLATE-TODO: lint all apps
<pm> typecheck   # TEMPLATE-TODO: typecheck all apps (explicit no-op in plain JS — the verb stays and stays green)
<pm> test        # TEMPLATE-TODO: run all test suites
<pm> build       # TEMPLATE-TODO: production build for every app
<pm> migrate     # TEMPLATE-TODO: run db/ migrations
```

**Deployment goes through CI/CD** (`.github/workflows/`), never a local deploy script, except in a declared emergency.

## Working rules for agents

How to make a change here. The full walkthrough is `docs/agents.md`; these rules are the contract.

**Before changing anything:**

- Read this file's relevant sections, the area contract, and — if adopted — the stack pack appendix and any add-on README covering what you touch.
- Read the code you are about to change *and its neighbours*: the existing module or slice closest to your task is the pattern to follow. Never design from memory of "how projects usually do it". In a fresh project with no neighbours yet, the pattern is the area contract's structure plus `docs/adding-a-feature.md` — propose it, don't stall.
- For a non-trivial feature, find or write the spec first (`specs/README.md`). No spec, no feature.

**Deciding where code goes:**

- Identify the correct layer/ring first, then place the change there — never wherever is convenient. Each area contract's structure section says what goes where; the cross-area decision path is in `docs/project-structure.md`, and the end-to-end slice walkthrough is `docs/adding-a-feature.md`.
- New capability → a new feature module/slice. Change to existing behaviour → inside the owning module/slice. Genuinely shared, pure helper → the area's shared/`lib` home, only once a second caller exists.
- If no existing pattern fits, say so in the PR and propose one — don't invent silently, and don't fork a local variant of an existing pattern (fix the pattern repo-wide in its own change instead).

**Scope and safety:**

- Make the smallest change that solves the problem. Don't reformat, rename, or refactor unrelated working code; flag unrelated dead code without removing it; remove only imports/variables your own change orphaned.
- Refactors are their own change — never folded into a feature. A refactor changes shape, not behaviour, and the test suite proves it.
- **Public contracts are append-only by default:** API routes and their request/response shapes, error codes, the error envelope, URL routes, migration history, i18n keys in use, and exported shared utilities. Extend, version, or deprecate with a migration path — never silently rename, remove, or change semantics. Breaking one is a decision the user makes, not you.

**Asking vs. proceeding:**

- Ask when requirements are genuinely ambiguous or contradictory, when a change is destructive or crosses a public contract, or when two instruction files conflict with no register entry.
- Do not ask about things the repo already answers — conventions, placement, naming are all written down. Otherwise state your assumptions explicitly and proceed.

**Reporting:**

- Report outcomes faithfully: what you ran, what you observed, what you skipped and why. "Done" claims are governed by the Definition of Done below.
- When a change alters structure, workflow, commands, or a public contract, update the governing contract/doc **in the same change** — a doc that lies is worse than no doc.

## Principles

Load-bearing engineering rules; honor them on every change. Stack- and tooling-agnostic.

- **Think before coding.** Don't assume, don't hide confusion. State assumptions; present real alternatives when the choice matters; push back respectfully when the request has a simpler or safer shape; stop and name what's unclear rather than proceeding on guesswork.
- **Simplicity first / YAGNI.** The minimum code that solves the problem. No unrequested features, no abstraction for single-use code, no configurability or error handling for cases that can't occur. "We might want it later" is not a reason. If 200 lines could be 50, write 50. Every new abstraction, dependency, or config key must survive the self-review justification (below).
- **Change the right place, surgically.** Locate the correct layer and boundary; make the change there; touch nothing else. Match the surrounding style — error handling, logging, validation, naming.
- **Goal-driven execution.** Turn the request into success criteria and loop until verified. **Verified means observed, not inferred:** run it and state the evidence you saw. What "run it" means per area lives in each area contract's *Definition of done* section.
- **Don't reinvent existing solutions.** Dates, money, timezones, validation, retry, pagination, parsing, formatting, auth, crypto: an established library or existing project utility, never hand-rolled — dates, money, timezones, auth, and crypto without exception. Before adding a dependency, confirm nothing already in the project covers it, and weigh its cost (frontend: bundle weight; backend: security surface). A stable one-liner doesn't earn a dependency.
- **Don't overfit to the demonstrated case.** Solve the general problem: no hardcoded strings/IDs/statuses/roles; handle empty, invalid, duplicate, retry, timeout, and permission cases, not just the happy path; write tests that assert behaviour, not implementation.
- **Keep implementations clean.** No noisy logs, no broad `try/catch` that hides errors, no dead branches, no defensive code without a concrete failure model.

### Readability and naming

A reviewer should understand intent from names alone.

- Names state business meaning, not mechanics. No misleading names; no abbreviations unless standard in the domain; no single-letter variables outside trivial loop counters and conventional math.
- Comments explain **why** — a constraint, tradeoff, or external quirk — never what the code already says. Notes to the reviewer belong in the commit message, not comments.

### Configuration

- All runtime config is read from the environment **in one place per app** and validated at startup against a declared schema — a missing or malformed value fails fast with a named error, never mid-request.
- `.env.example` is the canonical, comment-documented list of every variable, updated in the same change that adds a key.
- Inner layers never read config directly; it is passed inward as values.
- Incomplete work hides behind a **flag**: a boolean key in the validated config schema, default off. No flag service or SDK unless the project adopts one and records it in Learnings.

Guide: `docs/configuration.md`.

## Testing

- Tests are part of "done": every non-trivial slice ships its tests in the same change.
- A bug fix starts with a failing test that reproduces the bug.
- Pick the cheapest kind that proves the behaviour — unit (a rule in isolation), integration (a use case across layers), contract (an API or port boundary). Per-area placement lives in each area contract; strategy tour: `docs/testing.md`.
- CI is the enforcement point and **fails hard**: a failing check fails the build — never `|| true`, never warn-only.

## Definition of Done

Do not report work as done until all of these hold. If a step cannot run (e.g. the toolchain block above is still TEMPLATE-TODO), say so explicitly — never skip it silently.

1. `<pm> lint`, `<pm> typecheck`, `<pm> test`, and `<pm> build` pass for the touched apps.
2. New or changed behaviour is covered by tests that assert behaviour.
3. For spec-backed work, every acceptance criterion of the touched story is met, demonstrated by its stated verification.
4. The touched area's own *Definition of done* checklist is satisfied (that contract is the source of truth — don't re-derive it here).
5. Contracts and docs affected by the change are updated in the same change.
6. No new TODO/FIXME in touched code without a tracked follow-up.

## Development workflow

Full narrative: `docs/development-workflow.md`. The binding rules:

- **Spec-first, independently shippable slices.** Non-trivial features start from a short written spec under `specs/`. Stories are priority-tagged (P1 = MVP); each slice is shippable alone; P1 alone is a viable MVP.
- **Trunk-based, linear history.** One long-lived branch, `main`, always releasable. Short-lived feature branches rebase and fast-forward onto it. Commits: Conventional Commits style (`feat|fix|docs|refactor|test|chore(scope): imperative subject`), one logical change per commit.
- **Spikes never merge.** Exploratory work runs on `spike/<topic>` in its own worktree, exempt from tests and the Definition of Done. The real implementation restarts on a normal branch at the full bar; record what the spike taught in the feature spec, then delete the spike branch and worktree.

### Working in a git worktree

Worktrees are the default — parallel work runs in several at once, under `.claude/worktrees/<name>` (or your preferred location), each on its own short-lived branch.

- **First act in a new worktree: copy gitignored runtime config** (root `.env`, `apps/*/.env*`, local secrets) from the main checkout — a fresh worktree has none, and everything depending on it misbehaves silently. Copy every env file the project uses and report each one copied or missing:

  ```bash
  main="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)"
  for f in .env apps/backend/.env apps/frontend/.env; do
    if [ -f "$main/$f" ]; then cp "$main/$f" "./$f" && echo "copied $f"; else echo "not in main checkout (skipped): $f"; fi
  done
  ```

- Shared local infrastructure (a containerized DB, etc.) is shared across worktrees by a fixed name — reuse the running one, never start a second copy.
- The shared DB's **schema is global state** across worktrees: a migration, reset, or seed in one worktree changes every worktree's app. Destructive or round-trip checks run against a throwaway DB, never the shared one (details: `db/CLAUDE.md`).

### Merge-back gate (ordered — run when the work is done)

1. **Rebase** onto the current default branch; resolve conflicts.
2. On the rebased branch, **run lint + typecheck + test + build and confirm green** — on the integrated state, never before the rebase. No suite wired yet? Say so per the Definition of Done. Never merge red.
3. **Fast-forward merge** into the default branch.
4. **Stop** dev servers / test instances started for the work.
5. **Delete** the worktree and its merged branch.
6. **Push only after confirming with the user** — `.github/workflows/deploy.yml` runs after green CI on `main`, so once its deploy step is filled in, pushing the default branch ships.

## Self-review before merge

Re-read the full diff end to end — including files you don't remember touching; never review from memory. Confirm:

- The change sits in the correct layer/ring; no business logic leaked outside it.
- Nothing unrelated was reformatted or refactored; only self-orphaned imports removed.
- Names state business meaning.
- Every new abstraction, dependency, or config key has one line in the PR: *the simpler option and why it was rejected*. Can't write that line → build the simpler option. No second caller yet → no abstraction.
- New code follows an existing pattern, named in the PR — or the PR says why none fits.

## Learnings

Durable, cross-session notes — one or two lines each: what was learned, how to apply it. Instantiation records the stack-pack and add-on choices here first (see `docs/getting-started.md`).

- Spec tooling: **Spec Kit** is adopted (`.specify/` + the `/speckit-*` skills); specs live in Spec Kit feature directories under `specs/`, superseding the one-file convention.
