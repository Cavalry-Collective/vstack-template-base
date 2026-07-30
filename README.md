# vstack-template-base

**An opinionated template for spinning up production-ready, full-stack projects — fast, and without re-litigating a single engineering decision.**

Every new Cavalry Collective project starts here. Clone it, run the Day-1 checklist once, and start shipping features the same day — with the architecture, quality gates, and conventions of a mature codebase already in force.

## Why this exists

Most project templates give you scaffolding: a folder of generated code that's stale the week after it's cut. This template ships something more durable — **contracts**. A set of `CLAUDE.md` files encode how software is built here: a backend onion with a pure domain at the centre, a layered frontend with a design-token keystone, reversible migrations, spec-first slices, and a Definition of Done where *verified means observed, not inferred*.

The contracts are written for humans **and** for AI agents. An agent working in this repo auto-loads the contract for whatever area it touches, so the hundredth feature is built to the same standard as the first — whether a person or an agent wrote it. That is the entire bet: **the biggest lever on project quality is an opinionated approach, stated where the work happens.**

## The ideology

- **Opinionated where it matters, agnostic where it doesn't.** The base contracts pin the *shape* of the system — rings, layers, envelopes, gates — and deliberately not the framework. A **stack pack** (`stacks/`) then binds those contracts to one concrete stack, resolving every disagreement in an explicit conflict register. No silent contradictions.
- **Simplicity first.** The minimum code that solves the problem; every added abstraction must defeat the simpler alternative on the record. If 200 lines could be 50, it's 50.
- **Quality is a gate, not a vibe.** Nothing is "done" until it's been run and observed: four data states exercised, endpoints hit, migrations round-tripped, screens checked at 320 px. The design guide (`design/`) locks the visual system *before* the first screen is built.
- **Spec-first, independently shippable slices.** Non-trivial work starts as a short written spec under `specs/`; P1 stories alone form a viable MVP. Trunk stays releasable, history stays linear.
- **Instructions over machinery.** The template carries no build scripts, hooks, or generated artifacts — just precise instructions in the files agents and humans already read. What you see is the whole mechanism.

**The end state:** a template you can instantiate in an afternoon and trust for years — every project born production-ready, every convention already decided, every agent already briefed.

## How to use it

1. **Clone it** — click *Use this template* on GitHub.
2. **Run the [Day-1 checklist](#day-1-checklist)** below, once: pick a stack pack (or stay agnostic), pick your add-ons, fill the toolchain placeholders, confirm the design guide.
3. **Build, spec-first** — write a short spec under `specs/`, then implement it with your spec-driven-development tooling of choice. The contracts do the rest: any agent (or human) touching an area picks up its rules automatically.

That's it. There is nothing to install and no generator to run — the template is documentation-shaped on purpose.

## What's included

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Root architecture principles and workflow |
| `apps/backend/` | Backend app — onion architecture (Domain → Service → Repo → Controller) |
| `apps/frontend/` | Frontend SPA — layered store / services / pages / components |
| `db/` | Database & migration contract (`db/CLAUDE.md`) with reversible migrations under `db/migrations/` |
| `infra/` | Terraform infrastructure (provider chosen per project; GCP worked examples) |
| `design/` | UI mockups + the **design guide** (`design-guide.html` + `tokens.css`) — "Keystone", the visual keystone confirmed before UI work: design principles + full foundations as a token-driven SaaS system (Cavalry palette by default), rebranded per project; components deliberately left flexible; reference, not part of the build |
| `specs/` | Feature specs — written before implementation |
| `stacks/` | Optional stack packs — appendix docs binding the agnostic contracts to one concrete stack; one chosen at instantiation, the rest deleted. See [`stacks/README.md`](stacks/README.md) |
| `add-ons/` | Optional capability add-ons — agnostic patterns you opt into at Day-1 (test mode, OTP login, LLM calls, …); the concrete stack wiring is derived at adoption from each add-on's seam list plus the active pack's appendices. See [`add-ons/README.md`](add-ons/README.md) |
| `.github/workflows/` | CI and deploy stubs — fill in your toolchain commands |
| `project.code-workspace` | VS Code workspace (hides agent worktrees from search and watchers) |

## What's not included

The template is intentionally framework-agnostic. You choose:

- Frontend framework (React, Vue, etc.) and build tool
- Backend HTTP layer (Express, Fastify, etc.)
- Package manager
- Cloud provider and Terraform provider
- Database client

Pick what fits the project. The CLAUDE.md files tell you where things go and how to structure them — not which library to use.

Or choose a stack pack under `stacks/` (e.g. `enterprise`) for a vetted set of these choices plus copy-paste commands; the base CLAUDE.md files stay framework-agnostic. The pack is opt-in, not a mandate — see [`stacks/README.md`](stacks/README.md).

## Day-1 checklist

Run this once, top to bottom, the first time you instantiate the template. Each step names the file and the marker to replace. The placeholders are grep-able: `<pm>` in the root `CLAUDE.md` command block, `FILL IN ON SETUP` in `apps/frontend/CLAUDE.md`, and `TODO: replace` in the `.github/workflows/` stubs. Step 13 checks they are all gone.

1. **Create the repo.** Click **Use this template** → **Create a new repository** on GitHub.
2. **Clone** your new repo.
3. **Open the workspace.** Open `project.code-workspace` in VS Code — its settings keep agent worktrees out of search and file watching.
4. **Read the CLAUDE.md files** — they are the architecture contract:
   - [`CLAUDE.md`](CLAUDE.md) — root principles, workflow, coding standards
   - [`apps/backend/CLAUDE.md`](apps/backend/CLAUDE.md) — backend onion architecture
   - [`apps/frontend/CLAUDE.md`](apps/frontend/CLAUDE.md) — frontend layering and conventions
   - [`db/CLAUDE.md`](db/CLAUDE.md) — database & migration contract
   - [`infra/CLAUDE.md`](infra/CLAUDE.md) — Terraform authoring style and guardrails
5. **Choose a stack pack — or stay agnostic.**
   - **Pack path (fast):** pick the pack under `stacks/` matching your stack (e.g. `enterprise`), then:
     - `rm -rf` every other `stacks/*` directory — the one pack left is the adopted one; each area's `CLAUDE.md` already points agents at its appendices (mechanism: `stacks/README.md` *Activation*).
     - Copy the pack README **dev** command block into the root `CLAUDE.md` "Common commands" placeholder (delete the banner); copy its **CI** block into `.github/workflows/ci.yml`. They are different blocks — never paste a dev-only migration command into CI.
     - Record the choice in root `CLAUDE.md` **Learnings**: `Stack: <pack-name>; appendices under stacks/<pack-name>/`.
   - **Agnostic path:** keep `stacks/` for reference (or delete it) and fill in the toolchain yourself — see step 6.
6. **Choose your add-ons.** Under `add-ons/`, keep the optional capabilities you want and **delete the directories you don't** — every directory kept is adopted, and the root `CLAUDE.md` points agents at each kept add-on's README. The full inventory is the **Current add-ons** table in [`add-ons/README.md`](add-ons/README.md). Check each chosen add-on's **Prerequisites** against your pack and other add-ons before keeping it; the concrete stack wiring is derived at implementation time from its *Binds to a stack* seam list plus the active pack's appendices.
7. **Fill the toolchain placeholders.** On the pack path, step 5 already filled the first two bullets; **both paths** still do the last two:
   - Root `CLAUDE.md` "Common commands" — replace the seven `<pm>`/`TODO` commands and delete the PLACEHOLDER banner.
   - `.github/workflows/ci.yml` — replace every commented gate (**the file is the canonical gate list**): install/lint/typecheck/test/build, the i18n key-parity check, the migration gate, and the a11y scan. A pack's CI block covers the toolchain gates; still wire the remaining `ci.yml` gates (migration gates per the pack's `db.md`, the a11y scan).
   - `.github/workflows/deploy.yml` — replace the TODO step (or, on a pack whose register deletes the stub, e.g. `vercel-csr`/`vercel-ssr`, delete it per that register).
   - Add a real `.env.example` (already whitelisted in `.gitignore`).
8. **Declare the primary form factor.** In `apps/frontend/CLAUDE.md`, fill in the form-factor line:
   ```markdown
   **Primary form factor (FILL IN ON SETUP):** `<mobile-first | desktop-first | responsive-equal>`
   ```
9. **Rebrand & confirm the design guide — before building any screen.** The template ships **Keystone** (`design/design-guide.html` + `design/tokens.css`): design principles plus the full foundations — colour, type, spacing, layout, elevation, motion, states, content, data formatting — as a token-driven SaaS system shipping the Cavalry palette by default (components deliberately left flexible per app). Rebrand it — edit the **primitive** tier in `tokens.css`, or have your AI assistant regenerate it from your brand — then open the guide in a browser and confirm it reads as one coherent system. This is the visual keystone gate (`apps/frontend/CLAUDE.md` → *Design guide*); the app's token source and `atoms/` then implement what it shows — don't build screens against an unconfirmed system.
10. **Copy runtime config.** Copy any gitignored runtime config (`.env`, secrets) into your local checkout — it is not carried over from the template.
11. **Protect `main`.** Add a branch protection rule / ruleset requiring the CI workflow to pass before merge. Install the rule **after step 13's first green push** (or run steps 5–10 on a branch and merge them via a PR) — a required-status rule rejects a direct push whose CI has never run. Trunk must stay releasable — and on packs whose pipeline ships whatever lands on `main` (e.g. `vercel-csr`), green-CI-before-merge *is* the deploy gate.
12. **Stand up staging (if your pack defines one).** Bring up the persistent preview/staging environment your stack pack specifies before feature work — for the `vercel-csr` and `vercel-ssr` packs that is the `develop` branch plus its dedicated Neon branch (the pack's `infra.md` → *Staging environment*), migrated with the same manual runbook as prod (the pack's `db.md` → *Production & staging migrations*).
13. **Confirm green.** Push and watch the first CI run pass. Then confirm no placeholder survives — both must return nothing: `grep -rn 'FILL IN ON SETUP\|TODO:' . --exclude-dir=stacks --exclude-dir=specs --exclude-dir=.git | grep -v '^\./README\.md:'` and `grep -n '^<pm> ' CLAUDE.md`. (Only this root README — whose checklist names the markers — is filtered out; delete it once instantiation is done if you prefer a clean tree.)

> If you chose a server-first Next.js pack (`enterprise` or `vercel-ssr`), soften the SPA framing the base ships agnostic: root `CLAUDE.md` "the single-page app" → "the web frontend", the opening line of `apps/frontend/CLAUDE.md` ("how the single-page app is structured") likewise, and the **What's included** "Frontend SPA" row above → "Frontend (server-first Next.js)". (`vercel-ssr`'s one-app restructure step covers this and more — see its README.)
>
> **The `vercel-csr` pack is not one of them** — it is a client-rendered SPA with no SSR, so the base framing above is already correct for it and every one of those files stays exactly as shipped. Don't soften anything.
