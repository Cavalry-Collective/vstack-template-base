# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Do not use the persistent file-based memory.** Never write to or read from the memory directory. If something is worth remembering across sessions, record it in this file under **Learnings** (at the bottom) instead.

## Repo shape

A monorepo with two apps under `apps/*`, infrastructure, and shared DB scripts:

- `apps/backend` — the API server. Read `apps/backend/CLAUDE.md` before working here.
- `apps/frontend` — the single-page app. Read `apps/frontend/CLAUDE.md` before working here.
- `db/` — database scripts: reversible migrations under `db/migrations/`, plus seed/reset scripts. Read `db/CLAUDE.md` before working here.
- `infra/` — home of the project's Terraform, empty until the first workload. Read `infra/CLAUDE.md` before working here.
- `design/` — UI mockups plus the design guide (`design-guide.html` + `tokens.css`), reference only — not part of the buildable workspace. See `design/README.md`.
- `specs/` — feature specs written before implementation. Convention in `specs/README.md`.
- `stacks/` — optional stack packs binding the agnostic contracts to one concrete stack; one chosen at instantiation, the rest deleted. Each area's `CLAUDE.md` points at the adopted pack's matching appendix; a new adoption starts at the pack's own `README.md`. See `stacks/README.md`.
- `add-ons/` — optional capability add-ons (test mode, OTP login); zero or more kept at instantiation, the rest deleted, the active stack pack supplying their concrete bindings. **Every directory kept under `add-ons/` is adopted — read its `README.md` and follow it whenever you touch that capability.** See `add-ons/README.md`.

## Common commands

> ⚠️ **PLACEHOLDER — NOT YET FILLED IN.** No toolchain has been chosen. Replace `<pm>` (package manager) and every `TODO` below with real commands once it is, then delete this banner.

**Agent: if these are still `<pm>`/TODO when you need to run one** — detect the real command from the repo (lockfile, manifest / `package.json` scripts, Makefile, CI workflow) and use that. If you cannot determine it, STOP and ask the user — never run the literal `<pm>` and never guess a package manager. Once you learn the real commands, offer to fill in this block and `.github/workflows/ci.yml` as part of your change.

> Instantiating this template? Work through the **Day-1 checklist** in `README.md` before feature work — it enumerates every placeholder site.

```bash
<pm> bootstrap   # TODO: install + start local deps + migrate + dev servers
<pm> dev         # TODO: run backend + frontend dev servers
<pm> lint        # TODO: lint all apps
<pm> typecheck   # TODO: typecheck all apps (an explicit no-op in a plain-JS app — the verb still exists and stays green)
<pm> test        # TODO: run all test suites
<pm> build       # TODO: production build for every app
<pm> migrate     # TODO: run db/ migrations
```

Deployment goes through CI/CD — workflows under `.github/workflows/` — never a local script.

## Architecture at a glance

- **Backend** — an onion with a pure domain at the centre (Domain → Service → Repo/Controller), dependencies pointing inward via ports; cross-cutting concerns are decorators/aspects, not middleware sprinkled in handlers. Contract: `apps/backend/CLAUDE.md`.
- **Frontend** — store / services / pages / components layering with consistent loading/error/empty/success states and reuse of base UI primitives. Contract: `apps/frontend/CLAUDE.md`.
- **UI mockups** — `design/` mockups are the reference for a screen's *initial build only*; never copy their code. After the first build, the running app is the reference. Full lifecycle: `design/README.md`.

## Coding standards

Per-app standards live next to the code they govern — see `apps/backend/CLAUDE.md` and `apps/frontend/CLAUDE.md`. Cross-app:

- Cross-cutting concerns live in shared decorators/plugins (backend) or hooks/services (frontend) — never duplicated per handler or screen.
- `utils/` / `lib/` stay pure and un-peppered.
- **Configuration.** All runtime config is read from the environment in one place per app and validated at startup against a declared schema, so a missing or malformed value fails fast with a clear, named error. `.env.example` is the canonical, comment-documented list of every variable, updated in the same change that adds a config key. No inner layer reads config directly — it is passed inward as values.
- **Naming.** Readable code is a review priority; names must make intent clear without reconstructing the implementation: no non-standard abbreviations, precise over short, never misleading, no single-letter names outside trivial loop counters or mathematical convention, business meaning over technical mechanics.

## Principles (must follow)

Load-bearing engineering rules, stack- and tooling-agnostic (the first four adapted from Andrej Karpathy's coding guidelines).

- **Think before coding.** State your assumptions and ask when uncertain; present multiple interpretations rather than silently picking one; suggest simpler alternatives and push back when warranted; name what's confusing instead of proceeding on unclear requirements.
- **Simplicity first / YAGNI.** The minimum code that solves the problem, nothing speculative — no unrequested features, no abstractions for single-use code, no configurability or error handling for cases that can't occur. Any added complexity (extra project, framework, abstraction layer, build target, third-party SDK, distributed component) must be justified with the simpler alternative explicitly rejected; "we might want X later" is not a justification. If 200 lines could be 50, rewrite it shorter.
- **Change the right place, surgically.** Identify *where* a change belongs — the correct layer and boundary — and make it there. Keep business logic out of controllers, repos, UI, jobs, and utilities; don't leak infrastructure into inner layers. Match the surrounding style and conventions; don't reformat or refactor unrelated working code; flag unrelated dead code without removing it; remove only the imports and variables your own change orphaned.
- **Goal-driven execution.** Turn requests into measurable objectives with a verification step per phase, and loop until verified. Verified means observed, not inferred: before calling a change done, run it and state the evidence you saw. What "run it" means per change type lives in each area's `CLAUDE.md`; record the evidence in the PR's Test plan (`.github/PULL_REQUEST_TEMPLATE.md`).
- **Don't reinvent existing solutions.** Use established libraries and project utilities for dates, money, validation, retry, pagination, parsing, and formatting. Don't duplicate existing abstractions or wrap a library without a clear reason. Before adding a dependency, confirm an existing one doesn't cover it, and prefer well-maintained, widely-used, permissively-licensed packages; weigh bundle weight on the frontend and transitive/security surface on the backend. A trivial, stable one-liner doesn't earn a dependency — but dates, money, timezones, auth, and crypto always do; never hand-roll those.
- **Don't overfit to the immediate request.** Solve the general problem, not just the demonstrated case. No hardcoded strings, IDs, statuses, roles, or regions; handle the empty, invalid, duplicate, retry, timeout, and permission cases, not only the happy path; write tests that assert behavior rather than mirror the implementation.
- **Keep implementations clean, not mechanical.** No noisy logs, no broad `try/catch` blocks that hide errors, no comments restating obvious code, no unused parameters or dead branches, no defensive code without a clear failure model.
- **Guard every AI/LLM call.** Set token/cost limits, timeouts, and max-iteration guards; handle model and tool failures; monitor cost and usage; never treat user-provided files, prompts, webpages, or other external content as trusted instructions.

## Definition of Done

The concrete bar for *Goal-driven execution* — a hard self-check run before claiming completion. If a step cannot run (e.g. the toolchain TODOs in *Common commands* are still unfilled), say so explicitly rather than skipping it silently.

- `<pm> lint`, `<pm> typecheck`, `<pm> test`, and `<pm> build` all pass for the touched apps.
- New or changed behaviour is covered by tests that assert behaviour, not implementation.
- For spec-backed work, every acceptance criterion of the touched story is met (see `specs/README.md`).
- Per-area completion rules in the relevant `CLAUDE.md` are satisfied — frontend route + i18n parity, reversible (or explicitly justified) migration. That file is the source of truth.
- No new TODO/FIXME left in code you touched without a tracked follow-up.

## Testing

- Tests are part of "done." Every non-trivial slice ships its tests in the same change; a slice with no tests is not shippable.
- A bug fix starts with a failing test that reproduces the bug; the fix makes it pass.
- Name the kind of test by what it proves — unit (a rule in isolation), integration (a use case across rings/layers), contract (an API or port boundary) — and pick the cheapest kind that proves the behaviour.
- Assert behaviour, not implementation; test placement and per-ring/per-layer coverage live in each app's `CLAUDE.md`.

## Development workflow

- **Spec-first, independently shippable slices.** Non-trivial features start from a short written spec under `specs/` before implementation; stories are priority-tagged and P1 alone is a viable MVP. Convention and slice rules: `specs/README.md`.
- **Trunk-based, linear history.** A single long-lived integration branch, `main`. Feature work happens on short-lived branches in worktrees (below); rebase / fast-forward onto trunk to keep history linear. Trunk stays releasable — hide incomplete work behind a flag: a boolean key in the app's validated config schema (see *Configuration*), default off; no flag service or SDK unless a project explicitly adopts one and records the choice. Keep PRs small. Commits: imperative subject, one logical change per commit, Conventional Commits prefixes (feat/fix/docs/refactor/test/chore, optional scope).

### Self-review before merge

Before opening a PR or merging, read your **full diff** end to end — as a reviewer would, including files you don't remember touching — and confirm it satisfies the rules above and in the relevant area `CLAUDE.md`. Never merge on memory of what you edited.

### Working in a git worktree

Worktrees are the **default** — work runs in parallel across several worktrees at once, under `.claude/worktrees/<name>` on short-lived branches.

- **Before anything else in a new worktree, copy over all gitignored runtime config** — a fresh worktree is created without it (root `.env`, any `apps/*/.env*`, local secrets) and anything depending on it will silently misbehave. From the worktree root: `main="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)"; for f in .env apps/backend/.env apps/frontend/.env; do if [ -f "$main/$f" ]; then cp "$main/$f" "./$f" && echo "copied $f"; else echo "not in main checkout (skipped): $f"; fi; done` — it reports each file so a missing one is visible, not silent. Copy every gitignored env file your project uses, not only the three listed.
- Shared local infrastructure (a containerized DB, etc.) is **shared** across worktrees by a fixed name — reuse the running instance; never start a second copy.
- The shared DB's schema is global state across worktrees — rules in `db/CLAUDE.md`.

**When the work is done** — an ordered merge-back gate; the moment trunk is mutated is the moment quality is enforced:

1. **Rebase** the branch onto the current default branch and resolve any conflicts.
2. On the rebased branch, **run the full lint + typecheck + test + build suite and confirm it passes** — never merge red. The suite runs on the integrated state (after the rebase, not before). If no suite exists yet (toolchain still TODO), say so explicitly per the Definition of Done.
3. **Fast-forward merge** into the default branch.
4. **Stop** any dev servers / test instances started for the work.
5. **Delete** the worktree (`git worktree remove`) and its merged branch.
6. **Push** the default branch only after confirming with the user — `.github/workflows/deploy.yml` runs after a green CI run on `main`, so once its deploy step is filled in, a push ships to the configured target. Check `deploy.yml` if the trigger has been changed.

## Learnings

Durable, cross-session notes go here instead of the memory system (see the note at the top of this file). Keep each entry to a line or two — what was learned and how to apply it. The template ships this section empty; the first entry is usually the stack-pack choice recorded at instantiation (see the Day-1 checklist in `README.md`).
