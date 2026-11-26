# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Do not use the persistent file-based memory.** Never write to or read from Claude's own memory directory. If something is worth remembering across sessions, record it in this file under **Learnings** (at the bottom) instead.

## Repo shape

A monorepo with two apps under `apps/*`, infrastructure, and shared DB scripts:

- `apps/backend` — the API server. See `apps/backend/CLAUDE.md`.
- `apps/frontend` — the single-page app. See `apps/frontend/CLAUDE.md`.
- `db/` — top-level **database scripts**: reversible migrations under `db/migrations/` (plus seed/reset scripts). See `db/CLAUDE.md`.
- `infra/` — Terraform for the project's cloud resources. See `infra/CLAUDE.md`.
- `design/` — design mockups / UI reference, **reference only** (not part of the buildable workspace). See *UI mockup / design reference* below.
- `stacks/` — optional stack packs: appendix docs binding the agnostic contracts to one concrete stack; one chosen at instantiation, the rest deleted. Each area's `CLAUDE.md` tells you to read the adopted pack's matching appendix before working there. See `stacks/README.md`.
- `add-ons/` — optional capability add-ons: agnostic patterns for features the base leaves out (test mode, OTP login, LLM calls); zero or more chosen at instantiation, the rest deleted; the concrete stack wiring is derived at adoption from each add-on's seam list plus the active pack's appendices (see `add-ons/README.md`). **Every directory kept under `add-ons/` is adopted — read its `README.md` and follow it whenever you touch the capability it covers.** See `add-ons/README.md`.

## Instruction precedence

When instruction files disagree: the area file (`apps/*/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md`) wins for its own area; the adopted stack pack's conflict register wins over both, for that stack only; an add-on's README binds only the capability it covers (within that capability it wins over the base and area files; the adopted pack's conflict register still wins over it); this file wins for everything cross-cutting. A real contradiction with no register entry is a defect — flag it, don't silently pick a side.

## Common commands

> ⚠️ **PLACEHOLDER — NOT YET FILLED IN.** No toolchain has been chosen. Replace `<pm>` (package manager) and every `TODO` below with real commands once it is, then delete this banner.

**Agent: if these are still `<pm>`/TODO when you need to run one** — detect the real command from the repo (lockfile, manifest / `package.json` scripts, Makefile, CI workflow) and use that. If you cannot determine it, STOP and ask the user — never run the literal `<pm>` and never guess a package manager. Once you learn the real commands, offer to fill in this block and the project's CI workflow as part of your change (scaffold: `.github/workflows/examples/ci.yml.example`).

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

**Frontend** — store / services / pages / components layering with consistent loading/error/empty/success states and reuse of base UI primitives. **Read `apps/frontend/CLAUDE.md` before touching `apps/frontend/`.** On a new project, agree the UI component approach with the user before any screen or component is built (that file → *UI component approach*).

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

## Documentation style

Applies to every Markdown document in this repo: specs, READMEs, stack packs, add-ons.

- Write plain business English. Say it the way you would explain it to a colleague.
- Lead with the purpose. Open a document or section with why it exists ("To support seat-based subscriptions…"), then drill into detail. Edge cases and notes go at the end.
- One idea per sentence. One rule per bullet. Prefer bullets and numbered lists over paragraphs. Use tables for reference material (keys, codes, bounds).
- Make a person or the system the subject: "the app blocks the invite", not "over-invitation is blocked at the boundary".
- No slogans, no compressed abstractions ("Seats are one enforced number"). Contrast is fine when it prevents a mistake ("return 404, not 403"); drop it when it is only for effect ("assertions, not hopes").
- No em-dash chains or nested parentheticals. If a sentence needs more than one qualifier, split it.
- State rules imperatively. Rationale and rejected alternatives live in the document's designated notes/decisions section, or a pack's conflict register — never inline with the rule.
- No document history or meta-narration. Don't describe how the document came to be, what moved where, or what another file deliberately omits.
- State a rule once, in the document that owns it. Link to it from everywhere else.
- Exception: verbatim contract strings (precedence lines, conflict-register field formats, copy-paste command blocks) are never reworded for style.

Reference examples: `add-ons/saas-billing/README.md` (add-on with implementation areas) and `stacks/vercel-csr/README.md` (pack manifest).

## Principles (must follow)

Load-bearing engineering rules; honor them on every change. They are stack- and tooling-agnostic.

- **Think before coding.** Don't assume, don't hide confusion, surface tradeoffs. State your assumptions and ask when uncertain; present multiple interpretations rather than silently picking one; suggest simpler alternatives and respectfully push back when warranted; stop and name what's confusing rather than proceeding on unclear requirements.
- **Simplicity first / YAGNI.** Write the minimum code that solves the problem. No unrequested features, no abstractions for single-use code, no configurability or error handling for cases that can't occur. "We might want it later" is not a reason. If 200 lines could be 50, rewrite. Every added layer, dependency, or config key must pass the self-review justification (see *Step 7. Self-review* in *Development workflow*).
- **Change the right place, surgically.** First identify *where* a change belongs — the correct layer and boundary — and make it there; don't patch wherever is convenient. Keep business logic out of controllers, repos, UI, jobs, and utilities where it doesn't belong, and don't leak infrastructure details into the wrong layer. Then touch only what you must: match the surrounding style and conventions (error handling, logging, validation), don't reformat or refactor unrelated working code, flag unrelated dead code without removing it, and remove only the imports/variables your own change orphaned.
- **Goal-driven execution.** Define success criteria and loop until verified. Turn requests into measurable objectives with a brief plan and a verification step per phase, so each phase can iterate to a clear success marker. Verified means observed, not inferred: before calling a change done, run it and state the evidence you saw. What "run it" means per change type lives in each app's `CLAUDE.md` (frontend/backend) and in `infra/CLAUDE.md` for infrastructure; record the evidence in the PR's Demo section.
- **Don't reinvent existing solutions.** Use established libraries and project utilities for dates, money, validation, retry, pagination, parsing, and formatting rather than hand-rolling them — especially date/timezone math. Don't duplicate existing abstractions or wrap a library without a clear reason. Before adding a new dependency, confirm an existing dependency or shared util doesn't already cover it, and prefer well-maintained, widely-used, permissively-licensed packages. Weigh the cost the YAGNI rule already requires you to justify: for the frontend, bundle and transitive weight (a few lines can beat a large dep for a cached SPA); for the backend, transitive and security surface. A trivial, stable one-liner doesn't earn a dependency — but dates, money, timezones, auth, and crypto always do; never hand-roll those.
- **Don't overfit to the immediate request.** Solve the general problem, not just the demonstrated case. Avoid hardcoding strings, IDs, statuses, roles, or regions; handle the empty, invalid, duplicate, retry, timeout, and permission cases, not only the happy path; and write tests that assert behavior rather than mirror the implementation.
- **Keep implementations clean, not mechanical.** No noisy logs, no broad `try/catch` that hides errors, no unused parameters or dead branches, no defensive code without a clear failure model. (Comment rules: *Readability and Naming*.)

## Definition of Done

The concrete bar for *Goal-driven execution*: do not report work as done until all of the following hold. If a step cannot be run (e.g. the toolchain TODOs in *Common commands* are still unfilled), say so explicitly rather than skipping it silently. This is a hard self-check the agent runs before claiming completion — until a real `ci.yml` exists, the gate is not delegated.

- `<pm> lint`, `<pm> typecheck`, `<pm> test`, and `<pm> build` all pass for the touched apps.
- New or changed behaviour is proven by a step or assertion in the flow test that covers it, or by a case in that rule's unit tests. `specs/test-flows.md` matches the suite. Tests assert behaviour, not implementation.
- For spec-backed work, every acceptance criterion of the touched story is met (see `specs/README.md`).
- Per-app and per-area completion rules in the relevant home file are satisfied — frontend route + i18n parity (`apps/frontend/CLAUDE.md`), reversible (up/down) or explicitly-justified migration (`db/CLAUDE.md`). That file is the source of truth; don't re-derive here.
- No new TODO/FIXME left in code you touched without a tracked follow-up.

## Testing

- Tests are part of "done". A change to behaviour ships with the tests that prove it, in the same PR.
- Keep one curated suite, organised by user flow. A user flow is the sequence of steps a user takes to reach a goal.
- `specs/test-flows.md` is the flow index. It lists each flow, its steps, its variants and the one test file that runs it. Update it in the same change as the tests.
- Before a bug fix or a feature, find the flow in the index that covers the behaviour. Extend that flow's test with a step or an assertion.
- For a bug fix, add the step or assertion before the fix. Confirm that it fails before the fix and passes after it.
- Create a new flow or test case only when no flow in the index covers the behaviour. Add it to the index, and explain in the PR description why no existing flow fits.
- Name tests and test files after the flow or rule they prove. Never name them after a bug, spec, story, feature number, date, request or person.
- Check every step of a flow in one run of that flow. Do not add a separate test that repeats the flow to check one step.
- Test each cross-cutting concern (language, viewport, error state, accessibility) once, as a variant of one flow. Do not repeat it across screens or copy tests for each design variant.
- When a feature is removed or a flow changes, delete or merge its tests and update the index in the same change. Do not write a test that checks a removed feature is still absent.
- Write unit tests for pure rules such as pricing, sizing and date arithmetic. Group the cases by rule. When you fix a bug in a rule, add or correct a case in that group.
- Choose the kind of test by what it proves: unit (a rule in isolation), integration (a use case across rings/layers), contract (an API or port boundary), end-to-end (a user flow). Use the cheapest kind that proves the behaviour, and test each behaviour at one level only.
- Assertion quality follows *Don't overfit to the immediate request* (assert behaviour, not implementation). Test placement lives in each app's `CLAUDE.md`.

## Development workflow

Follow this workflow for every change in this repo, whether it is a bug fix, a feature or a refactor. If a change is not straightforward, consider writing a spec first using Spec Kit or a similar tool. See `specs/README.md`.

Stop and ask the user if:

- You cannot reproduce a bug on the local stack or staging, or the new assertion passes before the fix.
- The change alters behaviour outside the scope of the ticket.
- A check fails for a reason unrelated to your change.

### Prepare

#### Step 1. Branch

Run `git fetch origin`. Work in a worktree under `.claude/worktrees/<name>` on a branch created from `origin/main`. Name the branch `feature/<ticket code>-<summary>`, for example `feature/abc-123-invite-limit`. For an urgent production fix, use `hotfix/<ticket code>-<summary>`. If there is no ticket, omit the ticket code.

Worktrees are the default because several tasks often run in parallel across separate worktrees.

- **Before anything else in a new worktree, copy over all gitignored runtime config.** A fresh worktree does not contain these files (root `.env`, any `apps/*/.env*`, local secrets), and anything that depends on them may silently misbehave. Copy every gitignored env file the project uses from the main checkout.
- Local infrastructure, such as a containerized DB, is usually **shared** across worktrees under a fixed name. Starting a second instance causes conflicts, so reuse the running one.
- The shared DB schema is **global state** across worktrees. A migration, reset or seed in one worktree affects every worktree's app. Do not run a reset or destructive migration check while another worktree depends on the current schema. Use a throwaway DB for round-trip and destructive checks.

#### Step 2. Reproduce

For a bug fix, always reproduce the bug before changing the code. Use the local stack or staging. Never test against production. Skip this step for other changes.

### Build

#### Step 3. Write the test

If the change was planned using Spec Kit or a similar framework, follow its test tasks. Otherwise, follow [Testing](#testing), with these additional rules:

- Do not force a change into a flow that tests a different behaviour.
- Do not write a narrow test that covers only the change. Understand and test the entire flow.

#### Step 4. Change

Make the change. Update the root or area `CLAUDE.md` if the change makes it outdated. Follow Conventional Commits: use an imperative subject with a prefix such as `feat:` or `fix:`, and keep each commit to one logical change.

#### Step 5. Check

Run the repo's lint, typecheck, test and build commands, along with any integration tests affected by the change. All checks must pass before you continue.

#### Step 6. Proofread

Proofread every user-facing string, error message and documentation change. Use short, plain and readable language. Avoid filler and AI-sounding phrasing. Use a proofreading tool such as `/vstack:proofread`. Apply the same standard to the PR description and the review request message in steps 8 and 9.

### Ship

#### Step 7. Self-review

Before opening the PR, have the most capable available model review the full diff against `origin/main` in a fresh context. Use `/code-review high`, or a subagent on the strongest available model, given only the diff, this file and the area `CLAUDE.md` files the change touches. Ask it to review the change as a pull request reviewer would, checking for:

- **Correctness:** bugs, logic errors, edge cases and weak error handling.
- **Security:** missing access checks, injection and leaked secrets.
- **Performance:** unnecessary queries or redundant work inside loops.
- **Tests:** missing or weak tests for each changed behaviour.
- **Fit:** the change belongs in the right layer, and no business logic leaks out of it. It follows existing patterns instead of adding local variations. A flawed pattern is fixed across the repo in a separate change. It does not reformat, refactor or restyle unrelated code or UI, and removes only the imports it made redundant. The code is readable, names convey business meaning, and it follows the rules in this file and the area `CLAUDE.md` files.
- **Justification:** each new abstraction, dependency or config key earns its place. The PR explains why a simpler option would not work. If it cannot, use the simpler option. Add an abstraction only when a second caller needs it. The PR also names the existing pattern the code follows and, for each UI change, the screen or component it was modelled on.

The reviewer reports each finding with the file, line number, problem and suggested fix. Fix every valid finding, then run step 5 again. List any finding you chose not to fix, and why, in the PR description.

#### Step 8. Open the PR

For each behaviour, record the evidence that demonstrates it: the command or API call you ran and the output you observed, or a video or screenshot for a change users can see.

Write the PR description using the template below. Put the evidence in the Demo section. Proofread it, show it to the user and wait for confirmation. Once confirmed, push the branch and open the PR.

```markdown
<One line: what the PR adds.>
- <One bullet per user-visible behaviour.>
- <Who can see it, and the feature flag that hides it.>

## Demo
### 1. <Flow name>
<video>

### 2. <Flow name>
<video>

## Tests
- <Each flow test extended or added, and why a new flow was needed.>

## Additional notes
- <Anything reviewers should know, such as new dependencies, config values, deploy order or refactoring. For each new shared helper, config key or dependency, the simpler option and why it was rejected.>
```

#### Step 9. Ask for review

Write the review request message below for the user to send to the reviewer, for example in Slack. Ask for the names of the reviewer and anyone to CC if the user has not already provided them. Proofread the message.

Remove any lines that have no content.

Bug fix:

```text
Hi @<reviewer>, could you help review and approve this PR?

<PR link>

Fixes <ticket link>

Root cause:
<One or two sentences explaining why the bug occurred.>

Fix:
<What the app does now, in plain language.>

Additional notes:
<For example, refactoring. One sentence.>

Thanks!

CC: @<others>
```

Other change:

```text
Hi @<reviewer>, could you help review and approve this PR?

<PR link>

<ticket link>

What it does:
<One or two sentences describing the change.>

Rollout:
<Feature flag, config values and deployment order.>

Additional notes:
<For example, refactoring. One sentence.>

Thanks!

CC: @<others>
```

#### Step 10. Follow review through to merge

- Wait for all CI checks to pass and make sure all branch protection rules on `main` are met before merging.
- If a CI check fails, fix the underlying cause and push the fix. Never bypass a check to make it pass.
- Reply to each review comment explaining what changed, then resolve the thread.
- Before reporting that the PR is ready, check its merge state and confirm that no review threads remain unresolved.
- Rebase onto `origin/main`, run step 5 again, and merge using a rebase or fast-forward merge. Never create a merge commit.
- After merging, stop any dev servers you started and delete the worktree and its branch.

## Learnings

Durable, cross-session notes go here instead of the memory system (see the note at the top of this file). Keep each entry to a line or two — what was learned and how to apply it. At instantiation the usual first entries are the stack-pack choice and the UI component approach the user agreed (`apps/frontend/CLAUDE.md` → *UI component approach*); see the Day-1 checklist in `README.md`.

- Spec tool: none by default. Spec Kit was removed on 2026-07-29; adopt a tool per `specs/README.md` if wanted. Feature numbers 001–004 are consumed and must not be reused: 001 design guide (retired), 002 repo-guidance audit (retired, no directory), 003–004 seo (retired, artifacts deleted).
