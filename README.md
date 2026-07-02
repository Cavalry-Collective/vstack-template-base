<picture>
  <source media="(prefers-color-scheme: dark)" srcset="design/brand/cavalry-lockup-light-1600.png">
  <img src="design/brand/cavalry-lockup-dark-1600.png" alt="Cavalry" width="420">
</picture>

**An opinionated template for spinning up production-ready, full-stack projects — fast, and without re-litigating a single engineering decision.**

Every new Cavalry project starts here. Clone it, run the Day-1 checklist once, and start shipping features the same day — with the architecture, quality gates, and conventions of a mature codebase already in force.

## Why this exists

Most project templates give you scaffolding: a folder of generated code that's stale the week after it's cut. This template ships something more durable — **contracts**. A set of `CLAUDE.md` files encode how software is built here: a backend onion with a pure domain at the centre, a layered frontend with a design-token keystone, reversible migrations, spec-first slices, and a Definition of Done where *verified means observed, not inferred*.

The contracts are written for humans **and** for AI agents. An agent working in this repo auto-loads the contract for whatever area it touches, so the hundredth feature is built to the same standard as the first — whether a person or an agent wrote it. That is the entire bet: **the biggest lever on project quality is an opinionated approach, stated where the work happens.**

## The ideology

- **Opinionated where it matters, agnostic where it doesn't.** The base contracts pin the *shape* of the system — rings, layers, envelopes, gates — and deliberately not the framework. A **stack pack** (`stacks/`) then binds those contracts to one concrete stack, resolving every disagreement in an explicit conflict register. No silent contradictions.
- **Simplicity first.** The minimum code that solves the problem; every added abstraction must beat the simpler alternative on the record — and shorter wins.
- **Quality is a gate, not a vibe.** Nothing is "done" until it's been run and observed: four data states exercised, endpoints hit, migrations round-tripped, screens checked at the narrowest supported width. The design guide (`design/`) locks the visual system *before* the first screen is built.
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
| `db/` | Database & migration contract, reversible migrations under `db/migrations/` |
| `design/` | UI mockups + the **Keystone design guide** — confirmed before any UI work (see step 10) |
| `infra/` | Terraform conventions and guardrails |
| `specs/` | Feature specs — written before implementation |
| `stacks/` | Optional stack packs — one chosen at instantiation, the rest deleted ([`stacks/README.md`](stacks/README.md)) |
| `add-ons/` | Optional capabilities — test mode, OTP login — opted into at Day-1 ([`add-ons/README.md`](add-ons/README.md)) |
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

Or choose a stack pack under `stacks/` (e.g. `nextjs-nestjs-postgres`) for a vetted set of these choices plus copy-paste commands; the base CLAUDE.md files stay framework-agnostic. The pack is opt-in, not a mandate — see [`stacks/README.md`](stacks/README.md).

## Day-1 checklist

Run this once, top to bottom, the first time you instantiate the template. Each step names the file and the marker to replace. The placeholders are grep-able: `<pm>` in the root `CLAUDE.md` command block, `FILL IN ON SETUP` in `apps/frontend/CLAUDE.md`, and `TODO:` in the `.github/workflows/` stubs. Step 14 checks they are all gone.

1. **Create the repo.** Click **Use this template** → **Create a new repository** on GitHub.
2. **Clone** your new repo.
3. **Open the workspace.** Open `project.code-workspace` in VS Code — its settings keep agent worktrees out of search and file watching.
4. **Read the CLAUDE.md files** — they are the architecture contract:
   - [`CLAUDE.md`](CLAUDE.md) — root principles, workflow, coding standards
   - [`apps/backend/CLAUDE.md`](apps/backend/CLAUDE.md) — backend onion architecture
   - [`apps/frontend/CLAUDE.md`](apps/frontend/CLAUDE.md) — frontend layering and conventions
   - [`db/CLAUDE.md`](db/CLAUDE.md) — database & migration contract
   - [`infra/CLAUDE.md`](infra/CLAUDE.md) — Terraform authoring style and guardrails
5. **Start with a clean `specs/`.** If numbered spec directories from the template's own development are present under `specs/`, delete them (keep `specs/README.md`) — they document building this template, not your project.
6. **Choose a stack pack — or stay agnostic.**
   - **Pack path (fast):** pick the pack under `stacks/` matching your stack (e.g. `nextjs-nestjs-postgres`), then:
     - `rm -rf` every other `stacks/*` directory — the one pack left is the adopted one; each area's `CLAUDE.md` already points agents at its appendices (mechanism: `stacks/README.md` *Activation*).
     - Copy the pack README **dev** command block into the root `CLAUDE.md` "Common commands" placeholder (delete the banner); copy its **CI** block into `.github/workflows/ci.yml`. They are different blocks — never paste a dev-only migration command into CI.
     - Record the choice in root `CLAUDE.md` **Learnings**: `Stack: <pack-name>; appendices under stacks/<pack-name>/`.
   - **Agnostic path:** keep `stacks/` for reference (or delete it) and fill in the toolchain yourself — see step 8.
7. **Choose your add-ons.** Under `add-ons/`, keep the optional capabilities you want (`test-mode`, `otp-auth`, …) and **delete the directories you don't** — every directory kept is adopted, and the root `CLAUDE.md` points agents at each kept add-on's README. The active stack pack supplies each adopted add-on's concrete bindings. See [`add-ons/README.md`](add-ons/README.md).
8. **Fill the toolchain placeholders** (agnostic path; the pack does this for you in step 6):
   - Root `CLAUDE.md` "Common commands" — replace the seven `<pm>`/`TODO` commands and delete the PLACEHOLDER banner.
   - `.github/workflows/ci.yml` — replace the TODO steps with real install/lint/typecheck/test/build, plus the i18n key-parity check and migration up/down round-trip.
   - `.github/workflows/deploy.yml` — replace the TODO step (keep the `event == 'push'` guard in the job condition — it prevents fork PRs from triggering a deploy).
   - Add a real `.env.example` (already whitelisted in `.gitignore`).
9. **Declare the primary form factor.** In `apps/frontend/CLAUDE.md`, fill in the form-factor line:
   ```markdown
   **Primary form factor (FILL IN ON SETUP):** `<mobile-first | desktop-first | responsive-equal>`
   ```
10. **Rebrand & confirm the design guide — before building any screen.** The template ships **Keystone** (`design/design-guide.html` + `design/tokens.css`): design principles plus the full foundations — colour, type, spacing, layout, elevation, motion, states, content, data formatting — as a token-driven SaaS system shipping the Cavalry palette by default (components deliberately left flexible per app). Rebrand it — edit the **primitive** tier in `tokens.css`, or have your AI assistant regenerate it from your brand — then open the guide in a browser and confirm it reads as one coherent system. This is the visual keystone gate (`apps/frontend/CLAUDE.md` → *Design guide*); the app's token source and `atoms/` then implement what it shows — don't build screens against an unconfirmed system. Replace the Cavalry brand assets under `design/brand/` with your own (and swap the lockup at the top of this README).
11. **Copy runtime config.** Copy any gitignored runtime config (`.env`, secrets) into your local checkout — it is not carried over from the template.
12. **Protect `main`.** Add a branch protection rule / ruleset requiring the CI workflow to pass before merge. Trunk must stay releasable — and on packs whose pipeline ships whatever lands on `main` (e.g. `vercel`), green-CI-before-merge *is* the deploy gate.
13. **Stand up staging (if your pack defines one).** Bring up the persistent preview/staging environment your stack pack specifies before feature work — for the `vercel` pack that is the `develop` branch plus its dedicated Neon branch (`stacks/vercel/infra.md` → *Staging environment*), migrated with the same manual runbook as prod (`stacks/vercel/db.md` → *Production & staging migrations*).
14. **Confirm green.** Push and watch the first CI run pass. Then confirm no placeholder survives — all three must return nothing: `grep -rn 'FILL IN ON SETUP' . --exclude-dir=stacks --exclude-dir=specs --exclude-dir=.git --exclude=README.md`, `grep -n 'TODO:' .github/workflows/*.yml`, and `grep -n '^<pm> ' CLAUDE.md`. (This README's own checklist names the markers, so it is excluded; delete it once instantiation is done if you prefer a clean tree.)

> If you chose the server-first `nextjs-nestjs-postgres` pack, soften the SPA framing the base ships agnostic: root `CLAUDE.md` "the single-page app" → "the web frontend", and the **What's included** "Frontend SPA" row above → "Frontend (server-first Next.js)".

## License

MIT © [Cavalry](LICENSE). Projects created from this template may keep or replace the license — the template itself stays free to use, copy, and adapt.

---

Built and maintained by **Cavalry** — an opinionated software engineering team. This template is how we start everything we ship.
