# Getting started — instantiation checklist

Run this once, top to bottom, the first time you instantiate the template. Every placeholder in the repo carries the same grep-able marker — **`TEMPLATE-TODO`** — and step 12 confirms none survive.

## 1. Create and open the repo

1. Click **Use this template** → **Create a new repository** on GitHub, then clone it.
2. Open `project.code-workspace` in VS Code — its settings keep agent worktrees out of search and file watching.

## 2. Read the contracts

They are the architecture; everything else hangs off them. ~30 minutes total:

- [`CLAUDE.md`](../CLAUDE.md) — root contract: precedence, principles, workflow, Definition of Done
- [`apps/backend/CLAUDE.md`](../apps/backend/CLAUDE.md) — backend onion
- [`apps/frontend/CLAUDE.md`](../apps/frontend/CLAUDE.md) — frontend layering
- [`db/CLAUDE.md`](../db/CLAUDE.md) — migrations
- [`infra/CLAUDE.md`](../infra/CLAUDE.md) — Terraform guardrails

## 3. Choose a stack pack — or stay agnostic

**Pack path (fast).** Pick the pack under `stacks/` matching your stack, then:

1. `rm -rf` every other `stacks/*` directory — the one left is the adopted one; each area contract already points agents at its appendices (mechanism: `stacks/README.md` → *Activation*).
2. Copy the pack README's **dev** command block over the root `CLAUDE.md` *Common commands* placeholder (delete the banner); copy its **CI** block into `.github/workflows/ci.yml`. They are different blocks — never paste a dev-only migration command into CI.
3. Record the choice in root `CLAUDE.md` → **Learnings**: `Stack: <pack-name>; appendices under stacks/<pack-name>/`.
4. Follow any day-1 notes in the pack README (e.g. the `nextjs-nestjs-postgres` and `vercel` packs ask you to soften the "single-page app" wording in root files, since they are server-first; the repo name stays as-is).

**Agnostic path.** Delete `stacks/` (or keep it for reference) and fill in the toolchain yourself in step 5.

## 4. Choose your add-ons

Under `add-ons/`, keep the capabilities you want (`test-mode`, `otp-auth`, `llm-calls`, …) and **delete the directories you don't** — every directory kept is adopted, and the root contract points agents at each kept add-on's README. The active stack pack supplies each adopted add-on's concrete bindings. Record the kept set in **Learnings**.

## 5. Fill the toolchain placeholders

(The pack did most of this in step 3; on the agnostic path, do it by hand.)

- Root `CLAUDE.md` → *Common commands* — replace the seven `<pm>` commands, delete the banner.
- `.github/workflows/ci.yml` — replace the TEMPLATE-TODO steps with real install/lint/typecheck/test/build, plus the i18n key-parity check and the migration verification your migration tool supports.
- `.github/workflows/deploy.yml` — replace the TEMPLATE-TODO deploy step.
- `.env.example` — replace the stub with the project's real, comment-documented variable list (see [`configuration.md`](configuration.md)).

## 6. Declare the primary form factor

In `apps/frontend/CLAUDE.md`, fill in the form-factor line (`mobile-first | desktop-first | responsive-equal` plus the supported viewport range). It drives the default navigation pattern and the shared layout's furniture.

## 7. Rebrand and confirm the design guide — before building any screen

The template ships **Keystone** (`design/design-guide.html` + `design/tokens.css`): design principles plus full foundations — colour, type, spacing, layout, elevation, motion, states, content, data formatting — as a token-driven system with the Cavalry palette by default. Rebrand it by editing the **primitive** token tier in `tokens.css` (or regenerate it from your brand), open the guide in a browser, and confirm it reads as one coherent system. This is the visual keystone gate (`apps/frontend/CLAUDE.md` → *Design guide*): the app's token source and atoms implement what the guide shows — don't build screens against an unconfirmed system.

## 8. Copy runtime config

Copy any gitignored runtime config (`.env`, secrets) into your local checkout — it is not carried by the template.

## 9. Protect `main`

Add a branch protection rule / ruleset requiring the CI workflow before merge. Trunk must stay releasable — and on packs whose pipeline ships whatever lands on `main` (e.g. `vercel`), green-CI-before-merge *is* the deploy gate.

## 10. Stand up staging (if your pack defines one)

Bring up the persistent preview/staging environment your stack pack specifies before feature work — for the `vercel` pack that is the `develop` branch plus its dedicated Neon branch (`stacks/vercel/infra.md` → *Staging environment*), migrated with the same runbook as prod.

## 11. First push

Push and watch the first CI run pass.

## 12. Confirm no placeholder survives

One grep, one marker. This must return nothing (this checklist and the stack packs describe the marker, so they're excluded):

```bash
grep -rn 'TEMPLATE-TODO' . --exclude-dir=.git --exclude-dir=stacks --exclude-dir=node_modules --exclude=getting-started.md
```

Done. Write your first spec under `specs/` and start shipping — [`adding-a-feature.md`](adding-a-feature.md) walks the full loop.
