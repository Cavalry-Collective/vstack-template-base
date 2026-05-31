# cavalry-template-spa

Cavalry Collective's full-stack SPA monorepo template. Every new project starts here.

## Using this template

1. Click **Use this template** → **Create a new repository** on GitHub
2. Clone your new repo
3. Open `project.code-workspace` in VS Code for multi-root workspace support
4. Read through the CLAUDE.md files — they are the architecture contract:
   - [`CLAUDE.md`](CLAUDE.md) — root principles, workflow, coding standards
   - [`apps/backend/CLAUDE.md`](apps/backend/CLAUDE.md) — backend onion architecture
   - [`apps/frontend/CLAUDE.md`](apps/frontend/CLAUDE.md) — frontend layering and conventions
   - [`infra/CLAUDE.md`](infra/CLAUDE.md) — Terraform authoring style and guardrails
5. Choose your toolchain and fill in the `TODO` commands in root `CLAUDE.md` and `.github/workflows/ci.yml`
6. Copy any runtime config (`.env`, secrets) into your local checkout — it is gitignored and not carried over from the template

## What's included

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Root architecture principles and workflow |
| `apps/backend/` | Backend app — onion architecture (Domain → Service → Repo → Controller) |
| `apps/frontend/` | Frontend SPA — layered store / services / pages / components |
| `db/migrations/` | Reversible DB migrations |
| `infra/` | Terraform infrastructure (cloud-agnostic authoring conventions) |
| `design/` | UI mockups and design reference (not part of the build) |
| `specs/` | Feature specs — written before implementation |
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
