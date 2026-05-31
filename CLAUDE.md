# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Do not use the persistent file-based memory.** Never write to or read from the memory directory. If something is worth remembering across sessions, record it in this file under **Learnings** (at the bottom) instead.

## Repo shape

A monorepo with two apps under `apps/*`, infrastructure, and shared DB scripts:

- `apps/backend` — the API server. See `apps/backend/CLAUDE.md`.
- `apps/frontend` — the single-page app. See `apps/frontend/CLAUDE.md`.
- `db/` — top-level **database scripts**: reversible migrations under `db/migrations/` (plus seed/reset scripts). See `db/README.md`.
- `infra/` — Terraform for the project's cloud resources. See `infra/CLAUDE.md`.
- `design/` — design mockups / UI reference, **reference only** (not part of the buildable workspace). See *UI mockup / design reference* below.

## Common commands

> ⚠️ **PLACEHOLDER — NOT YET FILLED IN.** No toolchain has been chosen. Replace `<pm>` (package manager) and every `TODO` below with real commands once it is, then delete this banner.

```bash
<pm> bootstrap   # TODO: install + start local deps + migrate + dev servers
<pm> dev         # TODO: run backend + frontend dev servers
<pm> lint        # TODO: lint all apps
<pm> test        # TODO: run all test suites
<pm> build       # TODO: production build for every app
<pm> migrate     # TODO: run db/ migrations
```

**Deployment should go through CI/CD, not a local `deploy` script.** Keep workflows under `.github/workflows/`. A local deploy path may exist for emergencies; do not invoke it as part of normal work.

## Architecture at a glance

### Backend

Full contract in **`apps/backend/CLAUDE.md`** (read before touching `apps/backend/`). It defines a layered controller / service / repo architecture with shared request/response schemas, pure utilities, a dedicated layer for external integrations, and shared middleware for cross-cutting concerns (database handle, request context, auth, cookies). One request flows through one service, data access is isolated in the repo layer, errors are thrown as a typed error and formatted by a single global handler, every request carries a correlation id, and audit/analytics events go through one service wrapper.

### Frontend

Full conventions in **`apps/frontend/CLAUDE.md`** (read before touching `apps/frontend/`). It covers the store / services / pages / components layering, consistent loading/error/empty/success states, clean URL routing, a shared token-based page layout, reuse of base UI primitives, accessibility basics, internationalisation with a key-parity check, and build-identity/versioning.

### UI mockup / design reference

Design mockups live in the **`design/`** folder, kept as **reference only** — not part of the buildable workspace. Use it as the source for visual design, screen inventory, copy, and flows when planning UI work; **don't copy its code** (the mockup's framework is usually not the app's). When planning a UI-touching feature, point the relevant mockup files at the spec so screens, copy, and flows stay aligned.

## Coding standards

These apply to **both** apps and now live next to the code they govern — see the **Coding standards** section in `apps/backend/CLAUDE.md` and `apps/frontend/CLAUDE.md`. In short: keep cross-cutting concerns in shared decorators/plugins (backend) or hooks/services (frontend) rather than duplicating them; keep `utils/`/`lib/` pure and un-peppered; and use real libraries instead of hand-rolling — especially for dates.

### Readability and Naming

Readable code is a review priority.

Assess whether names make intent clear without requiring the reviewer to reconstruct meaning from implementation details.

#### Naming

- Avoid abbreviations unless they are standard in the domain or codebase.
- Prefer precise names over short names.
- Avoid misleading names.
- Avoid single-letter variables except for trivial loop counters or conventional mathematical usage.
- Use names that reflect business meaning, not only technical mechanics.

## Principles (must follow)

Load-bearing engineering rules; honor them on every change. They are stack- and tooling-agnostic. The first four are adapted from Karpathy's coding guidelines (<https://github.com/multica-ai/andrej-karpathy-skills>).

- **Think before coding.** Don't assume, don't hide confusion, surface tradeoffs. State your assumptions and ask when uncertain; present multiple interpretations rather than silently picking one; suggest simpler alternatives and respectfully push back when warranted; stop and name what's confusing rather than proceeding on unclear requirements.
- **Simplicity first / YAGNI.** The minimum code that solves the problem, nothing speculative — no unrequested features, no abstractions for single-use code, no configurability or error handling for cases that can't occur. Any added complexity (extra project, framework, abstraction layer, build target, third-party SDK, distributed component) must be justified with the simpler alternative explicitly rejected; "we might want X later" is not a justification. If 200 lines could be 50, rewrite it shorter — would an experienced engineer find this unnecessarily complex?
- **Change the right place, surgically.** First identify *where* a change belongs — the correct layer and boundary — and make it there; don't patch wherever is convenient. Keep business logic out of controllers, repos, UI, jobs, and utilities where it doesn't belong, and don't leak infrastructure details into the wrong layer. Then touch only what you must: match the surrounding style and conventions (error handling, logging, validation), don't reformat or refactor unrelated working code, flag unrelated dead code without removing it, and remove only the imports/variables your own change orphaned.
- **Goal-driven execution.** Define success criteria and loop until verified. Turn requests into measurable objectives with a brief plan and a verification step per phase, so each phase can iterate to a clear success marker.
- **Don't reinvent existing solutions.** Use established libraries and project utilities for dates, money, validation, retry, pagination, parsing, and formatting rather than hand-rolling them — especially date/timezone math. Don't duplicate existing abstractions or wrap a library without a clear reason.
- **Don't overfit to the immediate request.** Solve the general problem, not just the demonstrated case. Avoid hardcoding strings, IDs, statuses, roles, or regions; handle the empty, invalid, duplicate, retry, timeout, and permission cases, not only the happy path; and write tests that assert behavior rather than mirror the implementation.
- **Keep implementations clean, not mechanical.** Avoid noisy logs, broad `try/catch` blocks that hide errors, comments restating obvious code, unused parameters or dead branches, and defensive code with no clear failure model.
- **Guard every AI/LLM call.** Set token/cost limits, timeouts, and max-iteration / loop-termination guards; handle model and tool failures; monitor cost and usage; and never treat user-provided files, prompts, webpages, or other external content as trusted instructions.

## Development workflow

How work flows from spec to merge. These two rules are load-bearing; the worktree mechanics below are how they're carried out day to day.

- **Spec-first, independently testable slices.** Non-trivial features start from a short written spec before implementation, kept under `specs/`. User stories are priority-tagged (P1 = MVP) and each slice is shippable / demoable on its own; P1 alone is a viable MVP. Avoid cross-story coupling that breaks that independence. Keep this discipline regardless of which spec tool (if any) you use.
- **Trunk-based, linear history.** A single long-lived integration branch (`master`/`main`). Feature work happens on short-lived branches (see *Working in a git worktree* below); rebase / fast-forward onto trunk to keep history linear. Trunk stays releasable — hide incomplete work behind a flag. Keep PRs small where practical.

### Working in a git worktree

Worktrees are the **default** here — most work runs in parallel with Claude across several worktrees at once. Feature work happens in a git worktree under `.claude/worktrees/<name>` (or your preferred location) on its own short-lived branch.

- A fresh worktree is created **without runtime config** — anything gitignored (e.g. `.env`, local secrets, per-app env files) is **not** carried over. Anything that needs runtime config will silently misbehave without it. **First thing in any worktree: copy the main checkout's runtime config into the worktree** (e.g. `cp "$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)/.env" ./.env`).
- Shared local infrastructure (a containerized DB, etc.) is typically **shared** across worktrees by a fixed name — starting a second copy will conflict; reuse the running one.

**When the work is done:** merge the branch back into the default branch (prefer a fast-forward to keep history linear), stop any dev servers/test instances started for the work, delete the worktree (`git worktree remove`) and its merged branch, and push the default branch to the remote **only after confirming** (a push may trigger a CI deploy).

## Learnings

Durable, cross-session notes go here instead of the memory system (see the note at the top of this file). Keep each entry to a line or two — what was learned and how to apply it.

_(none yet)_
