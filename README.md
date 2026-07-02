# cavalry-template-spa

Cavalry Collective's full-stack SPA monorepo template. Every new project starts here.

## Day-1 checklist

Run this once, top to bottom, the first time you instantiate the template. Each step names the file and the marker to replace. The placeholders are grep-able: `<pm>` in the root `CLAUDE.md` command block, `FILL IN ON SETUP` in `apps/frontend/CLAUDE.md`, and `TODO: replace` in the `.github/workflows/` stubs. Step 13 checks they are all gone.

1. **Create the repo.** Click **Use this template** → **Create a new repository** on GitHub.
2. **Clone** your new repo.
3. **Open the workspace.** Open `project.code-workspace` in VS Code for multi-root support.
4. **Read the CLAUDE.md files** — they are the architecture contract:
   - [`CLAUDE.md`](CLAUDE.md) — root principles, workflow, coding standards
   - [`apps/backend/CLAUDE.md`](apps/backend/CLAUDE.md) — backend onion architecture
   - [`apps/frontend/CLAUDE.md`](apps/frontend/CLAUDE.md) — frontend layering and conventions
   - [`db/CLAUDE.md`](db/CLAUDE.md) — database & migration contract
   - [`infra/CLAUDE.md`](infra/CLAUDE.md) — Terraform authoring style and guardrails
5. **Choose a stack pack — or stay agnostic.**
   - **Pack path (fast):** pick the pack under `stacks/` matching your stack (e.g. `nextjs-nestjs-postgres`), then:
     - `rm -rf` every other `stacks/*` directory.
     - Run `scripts/activate-stack.sh <pack-name>`. It writes one path-scoped rule file per appendix to `.claude/rules/` — the appendix body with `paths:` frontmatter prepended (rule files do **not** resolve `@`-imports, so each rule is self-contained; mechanism and rationale: `stacks/README.md` *Activation*). The appendices stay the source of truth: rerun the script after editing one — CI's **Stack rule drift** step fails on a stale copy.
     - Copy the pack README **dev** command block into the root `CLAUDE.md` "Common commands" placeholder (delete the banner); copy its **CI** block into `.github/workflows/ci.yml`. They are different blocks — never paste a dev-only migration command into CI.
     - Record the choice in root `CLAUDE.md` **Learnings**: `Stack: <pack-name>; appendices under stacks/<pack-name>/, activated via scripts/activate-stack.sh`.
   - **Agnostic path:** keep `stacks/` for reference (or delete it) and fill in the toolchain yourself — see step 6.
6. **Choose your add-ons.** Under `add-ons/`, keep the optional capabilities you want (`test-mode`, `otp-auth`, …) and **delete the directories you don't**, then run `scripts/activate-addons.sh` to write their always-on rules — CI's **Add-on rule drift** step fails on a stale copy. The active stack pack supplies each adopted add-on's concrete bindings. See [`add-ons/README.md`](add-ons/README.md).
7. **Fill the toolchain placeholders** (agnostic path; the pack does this for you in step 5):
   - Root `CLAUDE.md` "Common commands" — replace the seven `<pm>`/`TODO` commands and delete the PLACEHOLDER banner.
   - `.github/workflows/ci.yml` — replace the TODO steps with real install/lint/typecheck/test/build, plus the i18n key-parity check and migration up/down round-trip.
   - `.github/workflows/deploy.yml` — replace the TODO step.
   - Add a real `.env.example` (already whitelisted in `.gitignore`).
8. **Declare the primary form factor.** In `apps/frontend/CLAUDE.md`, fill in the form-factor line:
   ```markdown
   **Primary form factor (FILL IN ON SETUP):** `<mobile-first | desktop-first | responsive-equal>`
   ```
9. **Generate & confirm the design guide — before building any screen.** `design/design-guide.html` + `design/tokens.css` ship as placeholders; **have the Fable 5 model generate** the design guide for your project (foundations + component specimens, driven by your brand tokens), then open it in a browser and confirm it reads as one coherent system. This is the visual keystone gate (`apps/frontend/CLAUDE.md` → *Design guide*); the app's token source and `atoms/` then implement what it shows — don't build screens against an unconfirmed system.
10. **Copy runtime config.** Copy any gitignored runtime config (`.env`, secrets) into your local checkout — it is not carried over from the template.
11. **Protect `main`.** Add a branch protection rule / ruleset requiring the CI workflow to pass before merge. Trunk must stay releasable — and on packs whose pipeline ships whatever lands on `main` (e.g. `vercel`), green-CI-before-merge *is* the deploy gate.
12. **Stand up staging (if your pack defines one).** Bring up the persistent preview/staging environment your stack pack specifies before feature work — for the `vercel` pack that is the `develop` branch plus its dedicated Neon branch (`stacks/vercel/infra.md` → *Staging environment*), migrated with the same manual runbook as prod (`stacks/vercel/db.md` → *Production & staging migrations*).
13. **Confirm green.** Push and watch the first CI run pass. Then confirm no placeholder survives — both must return nothing: `grep -rn 'FILL IN ON SETUP\|TODO: replace' . --exclude-dir=stacks --exclude-dir=specs --exclude-dir=.git --exclude=README.md` and `grep -n '^<pm> ' CLAUDE.md`. (This README's own checklist names the markers, so it is excluded; delete it once instantiation is done if you prefer a clean tree.)

> If you chose the server-first `nextjs-nestjs-postgres` pack, soften the SPA framing the base ships agnostic: root `CLAUDE.md` "the single-page app" → "the web frontend", and the **What's included** "Frontend SPA" row below → "Frontend (server-first Next.js)". The repo name still encodes "spa" and is immutable — accepted as stale.

## What's included

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Root architecture principles and workflow |
| `apps/backend/` | Backend app — onion architecture (Domain → Service → Repo → Controller) |
| `apps/frontend/` | Frontend SPA — layered store / services / pages / components |
| `db/` | Database & migration contract (`db/CLAUDE.md`) with reversible migrations under `db/migrations/` |
| `infra/` | Terraform infrastructure (GCP-first conventions; adaptable) |
| `design/` | UI mockups + the **design guide** (`design-guide.html` + `tokens.css`) — the visual keystone confirmed before UI work; ships as a placeholder the **Fable 5 model** generates per project; reference, not part of the build |
| `specs/` | Feature specs — written before implementation |
| `stacks/` | Optional stack packs — appendix docs binding the agnostic contracts to one concrete stack; one chosen at instantiation, the rest deleted. See [`stacks/README.md`](stacks/README.md) |
| `add-ons/` | Optional capability add-ons — agnostic patterns you opt into at Day-1 (test mode, OTP login); the active stack pack supplies their concrete bindings. See [`add-ons/README.md`](add-ons/README.md) |
| `.github/workflows/` | CI and deploy stubs — fill in your toolchain commands |
| `project.code-workspace` | VS Code multi-root workspace |

## What's not included

The template is intentionally framework-agnostic. You choose:

- Frontend framework (React, Vue, etc.) and build tool
- Backend HTTP layer (Express, Fastify, etc.)
- Package manager
- Cloud provider and Terraform provider
- Database client

Pick what fits the project. The CLAUDE.md files tell you where things go and how to structure them — not which library to use.

Or choose a stack pack under `stacks/` (e.g. `nextjs-nestjs-postgres`) for a vetted set of these choices plus copy-paste commands; the base CLAUDE.md files stay framework-agnostic. The pack is opt-in, not a mandate — see [`stacks/README.md`](stacks/README.md).
