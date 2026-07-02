# Stack pack: vercel

Frontend **Next.js** (App Router, TypeScript) · Backend **Fastify** (plain JavaScript, ESM) · DB **Postgres** — **Neon** (serverless) in production, Docker locally — via **node-pg-migrate** + **`pg`**. Everything deploys to **Vercel**: two projects (the Next app; the Fastify API as one serverless function), Vercel Blob storage, Terraform (Vercel provider) as IaC. This is the **manifest**; bindings and conflict registers live in the appendices (invariants: `../README.md`).

> **Naming.** Named for the everything-on-Vercel platform under the platform exception in `../README.md`; the would-be triple is `nextjs-fastify-postgres`. If a second Vercel pack appears, rename to the convention form.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, `/api` proxy, REST-only data flow, Tailwind 4 + Radix, four states |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify plugins → onion, Awilix root, Vercel entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down), `pg` query layer, Neon pooling |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, two-project workload, deploy seam |

The full `infra.md` ships because the platform *is* the pack's identity.

## Dev block → root `CLAUDE.md` "Common commands"

Toolchain: pnpm workspaces over `apps/*`; root `"type": "module"`; Node 22 — pin `packageManager`; keep the Node major synced between `engines` and Terraform's `node_version` (Vercel reads the latter). Validation: **Zod** on both sides — backend edge DTOs + boot-time env schema, frontend form/response shapes; a shared shape is defined once (`backend.md` / `frontend.md`).

```bash
pnpm bootstrap   # install + start local Postgres (fixed-name container, shared across worktrees) + migrate
pnpm dev         # Fastify watch (:4000) + Next dev (:3000) in parallel
pnpm lint        # ESLint (flat config), both apps
pnpm typecheck   # frontend tsc --noEmit (backend plain JS — explicit no-op)
pnpm test        # backend node --test (Playwright e2e separate: pnpm test:e2e)
pnpm build       # next build (backend build/typecheck are explicit no-ops)
pnpm migrate     # node-pg-migrate up (down: pnpm --filter backend migrate:down)
```

## CI block → `.github/workflows/ci.yml`

Non-interactive: a `postgres:16` service container; `pnpm install --frozen-lockfile`; lint; frontend `tsc --noEmit`; backend `node --test`; `next build`; migration round-trip **up → down → up** on the scratch DB (node-pg-migrate has real downs — keep the base `ci.yml` round-trip TODO's wording as written); seed twice (idempotency). Playwright e2e runs against a Vercel preview via `E2E_BASE_URL`, not in this job (*Deploy seam*).

## Day-1 wiring

From the root `README.md` Day-1 checklist: delete every other `stacks/*` directory — each area's `CLAUDE.md` then points at the matching appendix here, `infra.md` included (`../README.md` *Activation*). Copy the **dev** block over the root "Common commands" placeholder (delete the banner); apply the **CI** block to `.github/workflows/ci.yml` — never the same block in both. Record in root `CLAUDE.md` **Learnings**: `Stack: vercel; appendices under stacks/vercel/ (4 appendices incl. infra)`.

## Deploy seam

Deployment is **Vercel's GitHub integration — CI/CD is merging code.** Both projects connect to the repo (Terraform `git_repository`, production branch `main`): every PR gets a preview deployment; a merge to `main` ships production. `ci.yml` is the **merge gate** — protect `main` so PRs merge only on green CI; `deploy.yml` is never filled in (delete the stub — registered in `infra.md`). Point Playwright at a preview URL via `E2E_BASE_URL`; a local token `vercel deploy` is emergency-only. Project, env-var, and Blob provisioning is Terraform-owned — `infra.md`.
