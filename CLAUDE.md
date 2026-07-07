# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Do not use the persistent file-based memory.** Never write to or read from the memory directory. If something is worth remembering across sessions, record it in this file under **Learnings** (at the bottom) instead.

## Repo shape

A monorepo with two apps under `apps/*`, infrastructure, and shared DB scripts:

- `apps/backend` — the API server. See `apps/backend/CLAUDE.md`.
- `apps/frontend` — the single-page app. See `apps/frontend/CLAUDE.md`.
- `db/` — top-level **database scripts**: reversible migrations under `db/migrations/` (plus seed/reset scripts). See `db/CLAUDE.md`.
- `infra/` — Terraform for the project's cloud resources. See `infra/CLAUDE.md`.
- `design/` — design mockups / UI reference, **reference only** (not part of the buildable workspace). See *UI mockup / design reference* below.
- `stacks/` — optional stack packs: appendix docs binding the agnostic contracts to one concrete stack; one chosen at instantiation, the rest deleted. Each area's `CLAUDE.md` tells you to read the adopted pack's matching appendix before working there. See `stacks/README.md`.
- `add-ons/` — optional capability add-ons: agnostic patterns for features the base leaves out (test mode, OTP login, LLM calls, SEO, premium design); zero or more chosen at instantiation, the rest deleted, the active stack pack supplying their concrete bindings. **Every directory kept under `add-ons/` is adopted — read its `README.md` and follow it whenever you touch the capability it covers.** See `add-ons/README.md`.

## Instruction precedence

When instruction files disagree: the area file (`apps/*/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md`) wins for its own area; the adopted stack pack's conflict register wins over both, for that stack only; an add-on's README binds only the capability it covers; this file wins for everything cross-cutting. A real contradiction with no register entry is a defect — flag it, don't silently pick a side.

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

**Deployment should go through CI/CD, not a local `deploy` script.** Keep workflows under `.github/workflows/`. A local deploy path may exist for emergencies; do not invoke it as part of normal work.

## Architecture at a glance

### Backend

**Backend** — an onion with a pure domain at the centre (Domain → Service → Repo/Controller), dependencies pointing inward via ports. Cross-cutting concerns are decorators/aspects, not middleware sprinkled in handlers. **Read `apps/backend/CLAUDE.md` before touching `apps/backend/`.**

### Frontend

**Frontend** — store / services / pages / components layering with consistent loading/error/empty/success states and reuse of base UI primitives. **Read `apps/frontend/CLAUDE.md` before touching `apps/frontend/`.**

### UI mockup / design reference

Design mockups live in the **`design/`** folder, kept as **reference only** — not part of the buildable workspace. **They are the reference for a screen's *initial build* only.** Use them as the source for visual design, screen inventory, copy, and flows when planning and first building a screen; **don't copy their code** (the mockup's framework is usually not the app's). After the first build, expect the screen to drift as it's iterated and improved — from then on the **running app is the reference, not the mockup**, so don't re-check later changes against it. When planning a *new* screen, point the relevant mockup files at the spec so it starts aligned.

## Coding standards

These apply to **both** apps and live next to the code they govern — see **Cross-cutting concerns** and **Coding standards** in `apps/backend/CLAUDE.md`, and **Coding standards** in `apps/frontend/CLAUDE.md`. In short: keep cross-cutting concerns in shared decorators/plugins (backend) or hooks/services (frontend), and keep `utils/`/`lib/` pure. (Libraries-over-hand-rolling is a Principle below.)

- **Configuration.** All runtime config is read from the environment in one place per app and validated at startup against a declared schema, so a missing or malformed value fails fast with a clear, named error rather than misbehaving mid-request. `.env.example` is the canonical, comment-documented list of every variable, updated in the same change that adds a config key. No inner layer reads config directly — it is passed inward as values.

### Readability and Naming

Readable code is a review priority. A reviewer should understand intent from names alone.

- Names are precise and state business meaning, not mechanics.
- No abbreviations unless standard in the domain or codebase. No misleading names. No single-letter variables outside trivial loop counters and conventional math.

#### Comments

- Comments explain **why** — the constraint, tradeoff, or external quirk behind the code — never what.
- Delete any comment that repeats what the code says.
- Notes to the reviewer ("fixed X here") go in the commit message, not in comments.

## Principles (must follow)

Load-bearing engineering rules; honor them on every change. They are stack- and tooling-agnostic. The first four are adapted from Andrej Karpathy's coding guidelines, folded into this file so no external reference is needed.

- **Think before coding.** Don't assume, don't hide confusion, surface tradeoffs. State your assumptions and ask when uncertain; present multiple interpretations rather than silently picking one; suggest simpler alternatives and respectfully push back when warranted; stop and name what's confusing rather than proceeding on unclear requirements.
- **Simplicity first / YAGNI.** Write the minimum code that solves the problem. No unrequested features, no abstractions for single-use code, no configurability or error handling for cases that can't occur. "We might want it later" is not a reason. If 200 lines could be 50, rewrite. Every added layer, dependency, or config key must pass the self-review justification (see *Self-review before merge*).
- **Change the right place, surgically.** First identify *where* a change belongs — the correct layer and boundary — and make it there; don't patch wherever is convenient. Keep business logic out of controllers, repos, UI, jobs, and utilities where it doesn't belong, and don't leak infrastructure details into the wrong layer. Then touch only what you must: match the surrounding style and conventions (error handling, logging, validation), don't reformat or refactor unrelated working code, flag unrelated dead code without removing it, and remove only the imports/variables your own change orphaned.
- **Goal-driven execution.** Define success criteria and loop until verified. Turn requests into measurable objectives with a brief plan and a verification step per phase, so each phase can iterate to a clear success marker. Verified means observed, not inferred: before calling a change done, run it and state the evidence you saw. What "run it" means per change type lives in each app's `CLAUDE.md` (frontend/backend) and in `infra/CLAUDE.md` for infrastructure; record the evidence in the PR's Test plan checklist.
- **Don't reinvent existing solutions.** Use established libraries and project utilities for dates, money, validation, retry, pagination, parsing, and formatting rather than hand-rolling them — especially date/timezone math. Don't duplicate existing abstractions or wrap a library without a clear reason. Before adding a new dependency, confirm an existing dependency or shared util doesn't already cover it, and prefer well-maintained, widely-used, permissively-licensed packages. Weigh the cost the YAGNI rule already requires you to justify: for the frontend, bundle and transitive weight (a few lines can beat a large dep for a cached SPA); for the backend, transitive and security surface. A trivial, stable one-liner doesn't earn a dependency — but dates, money, timezones, auth, and crypto always do; never hand-roll those.
- **Don't overfit to the immediate request.** Solve the general problem, not just the demonstrated case. Avoid hardcoding strings, IDs, statuses, roles, or regions; handle the empty, invalid, duplicate, retry, timeout, and permission cases, not only the happy path; and write tests that assert behavior rather than mirror the implementation.
- **Keep implementations clean, not mechanical.** No noisy logs, no broad `try/catch` that hides errors, no unused parameters or dead branches, no defensive code without a clear failure model. (Comment rules: *Readability and Naming*.)

## Definition of Done

The concrete bar for *Goal-driven execution*: do not report work as done until all of the following hold. If a step cannot be run (e.g. the toolchain TODOs in *Common commands* are still unfilled), say so explicitly rather than skipping it silently. This is a hard self-check the agent runs before claiming completion — while `ci.yml` is still a stub, the gate is not delegated.

- `<pm> lint`, `<pm> typecheck`, `<pm> test`, and `<pm> build` all pass for the touched apps.
- New or changed behaviour is covered by tests that assert behaviour, not implementation.
- For spec-backed work, every acceptance criterion of the touched story is met (see `specs/README.md`).
- Per-app and per-area completion rules in the relevant home file are satisfied — frontend route + i18n parity (`apps/frontend/CLAUDE.md`), reversible (up/down) or explicitly-justified migration (`db/CLAUDE.md`). That file is the source of truth; don't re-derive here.
- No new TODO/FIXME left in code you touched without a tracked follow-up.

## Testing

- Tests are part of "done." Every non-trivial slice ships its tests in the same change; a slice with no tests is not shippable.
- A bug fix starts with a failing test that reproduces the bug, then the fix makes it pass.
- Name the kind of test by what it proves — unit (a rule in isolation), integration (a use case across rings/layers), contract (an API or port boundary). Pick the cheapest kind that proves the behaviour.
- Assertion quality follows *Don't overfit to the immediate request* (assert behaviour, not implementation); test placement and per-ring/per-layer coverage live in each app's `CLAUDE.md`.

## Development workflow

How work flows from spec to merge. These two rules are load-bearing; the worktree mechanics below are how they're carried out day to day.

- **Spec-first, independently testable slices.** Non-trivial features start from a short written spec before implementation, kept under `specs/`. User stories are priority-tagged (P1 = MVP) and each slice is shippable / demoable on its own; P1 alone is a viable MVP. Avoid cross-story coupling that breaks that independence. Keep this discipline regardless of which spec tool (if any) you use.
- **Trunk-based, linear history.** A single long-lived integration branch, `main`. Feature work happens on short-lived branches (see *Working in a git worktree* below); rebase / fast-forward onto trunk to keep history linear. Trunk stays releasable — hide incomplete work behind a flag. A flag here is a boolean key in the app's validated config schema (see *Configuration*), default off — no flag service or SDK unless a project explicitly adopts one and records the choice. Keep PRs small where practical. Commits: imperative subject, one logical change per commit; follow the repo's existing Conventional Commits prefix style (feat/fix/docs/refactor/test/chore, optional scope) so history stays scannable.

**Spikes are sanctioned and never merge.** Exploratory work runs on a `spike/<topic>` branch in its own worktree. Tests, self-review, and the Definition of Done do not apply there. Two rules: a spike branch never merges into trunk, and the real implementation starts on a normal branch at the full bar — even if it copies spike code. Record what you learned in the feature spec, then delete the spike branch and its worktree (a spike skips the merge-back gate below).

### Self-review before merge

Before opening a PR or merging, re-read the full diff end to end — including files you don't remember touching. Do not review from memory. Confirm:

- The change sits in the correct layer/ring, and no business logic leaked outside it (see *Change the right place, surgically*).
- No unrelated code was reformatted or refactored; only imports your own change orphaned were removed.
- Names state business meaning (see *Readability and Naming*).
- Every new abstraction, dependency, or config key has one line in the PR: the simpler option and why it was rejected. If you can't write that line, build the simpler option. No second caller yet → no abstraction.
- New code follows an existing pattern, named in the PR — or the PR says why none fits. If the pattern itself is wrong, fix it repo-wide in its own change; don't fork it locally.

### Working in a git worktree

Worktrees are the **default** here — most work runs in parallel with Claude across several worktrees at once. Feature work happens in a git worktree under `.claude/worktrees/<name>` (or your preferred location) on its own short-lived branch.

- **Before anything else in a new worktree, copy over all gitignored runtime config** — a fresh worktree is created without it (root `.env`, any `apps/*/.env*`, local secrets) and anything depending on it will silently misbehave. From the worktree root: `main="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)"; for f in .env apps/backend/.env apps/frontend/.env; do if [ -f "$main/$f" ]; then cp "$main/$f" "./$f" && echo "copied $f"; else echo "not in main checkout (skipped): $f"; fi; done` — it reports each file so a missing one is visible, not silent. Copy every gitignored env file your project uses, not only the three listed.
- Shared local infrastructure (a containerized DB, etc.) is typically **shared** across worktrees by a fixed name — starting a second copy will conflict; reuse the running one.
- The shared DB's schema is **global state** across worktrees — a migration, reset, or seed run in one worktree changes every worktree's app. Don't run a reset or destructive migration check while a parallel worktree depends on the current schema; use a throwaway DB for round-trip/destructive checks.

**When the work is done** — an ordered merge-back gate; the moment trunk is mutated is the moment quality is enforced:

1. **Rebase** the branch onto the current default branch and resolve any conflicts — pulling in changes that landed on trunk while you worked.
2. On the rebased branch, **run the full lint + typecheck + test + build suite and confirm it passes** — never merge red. The suite must run on the integrated state (after the rebase, not before). If no suite exists yet (toolchain still TODO), say so explicitly per the Definition of Done.
3. **Fast-forward merge** into the default branch (the rebase makes this a clean ff, preserving linear history).
4. **Stop** any dev servers / test instances started for the work.
5. **Delete** the worktree (`git worktree remove`) and its merged branch.
6. **Push** the default branch only after confirming. By default this template's `.github/workflows/deploy.yml` runs after a green CI run on `main` (a `workflow_run` trigger), so once its deploy step is filled in a push to the default branch ships to the configured target — confirm with the user before pushing, and check `deploy.yml` if the trigger has been changed.

## Learnings

Durable, cross-session notes go here instead of the memory system (see the note at the top of this file). Keep each entry to a line or two — what was learned and how to apply it. The template ships this section empty; the first entry is usually the stack-pack choice recorded at instantiation (see the Day-1 checklist in `README.md`).
