# Stack pack: vercel

Frontend **Next.js** (App Router, TypeScript) · Backend **Fastify** (plain JavaScript, ESM) · DB **Postgres** — **Neon** (serverless) in production, Docker locally — via **node-pg-migrate** + **`pg`**. The whole product deploys to **Vercel**: two Vercel projects (the Next app, and the Fastify API as a serverless function), Vercel Blob for object storage, Terraform (Vercel provider) as IaC. Validated end to end by a shipped production project. This is the **manifest** — it wires the pack onto a project; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Naming.** Named for its distinguishing choice — the everything-on-Vercel platform — under the platform exception in `../README.md` (the convention triple would be `nextjs-fastify-postgres`). If a second Vercel-platform pack ever appears, rename this one to the convention form.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, the `/api` proxy to the backend, REST-only data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify plugins → onion mapping, Awilix composition root, the Vercel function entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down pairs), `pg` query layer, serverless pooling against Neon |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, two-project workload shape, deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform *is* this pack's identity, so the cloud shape is stack-shaped here. Each appendix opens with the verbatim precedence line and ends with its conflict register; conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the instantiation checklist (`docs/getting-started.md`): delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*). Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Finally record in root `CLAUDE.md` **Learnings**: `Stack: vercel; appendices under stacks/vercel/ (4 appendices incl. infra)`.

**Add-ons:** this pack binds `test-mode` and `otp-auth` (`backend.md` → *Add-on bindings*) and **leaves `llm-calls` unbound** — it pins no LLM provider. A project adopting `llm-calls` binds the SDK, adapter home, canned-response sink (reuse the test-mode sink), and cost/usage metrics home in `backend.md` at adoption time.

## Suggested toolchain (pnpm workspaces, ESM, Node 22)

pnpm workspaces over `apps/*`; root `"type": "module"`; pin `packageManager` in the root manifest and keep the Node major in sync between `engines` and the Terraform `node_version` variable (Vercel reads the latter).

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local Postgres (fixed-name docker container, shared across worktrees) + migrate
pnpm dev         # both dev servers in parallel: Fastify watch (:4000) + Next dev (:3000)
pnpm lint        # ESLint (flat config) in both apps
pnpm typecheck   # frontend tsc --noEmit (backend is plain JS — explicit no-op script)
pnpm test        # backend node --test suite (Playwright e2e is separate: pnpm test:e2e)
pnpm build       # next build (backend is plain JS — its build/typecheck scripts are explicit no-ops)
pnpm migrate     # node-pg-migrate up (rollback: pnpm --filter backend migrate:down)
```

**CI block → `.github/workflows/ci.yml` (non-interactive):** a `postgres:16` service container; `pnpm install --frozen-lockfile`; lint; frontend `tsc --noEmit`; backend `node --test`; `next build`; **migration round-trip up → down → up on the scratch DB** — node-pg-migrate has real downs, so keep the base `ci.yml` round-trip TODO's wording as written (a deliberate contrast with ORM packs that must replace it); run the seed twice (idempotency). Playwright e2e is not part of this job — it runs against a Vercel preview deployment via `E2E_BASE_URL` (see *Deploy seam*).

**Validation:** **Zod** on both sides — backend edge DTOs and boot-time env schemas, frontend form/response shapes; a shape shared across the two is defined once and reused. Details in `backend.md` / `frontend.md`.

## Deploy seam

Deployment is **Vercel's GitHub integration — CI/CD is merging code.** Both Vercel projects connect to the repo (Terraform `git_repository`, production branch `main`): every PR gets a preview deployment, and a merge to `main` ships production on Vercel's own pipeline. `ci.yml` is the **merge gate**, not the deploy pipeline — protect `main` so PRs merge only on green CI; `deploy.yml` is never filled in (delete the stub — `infra.md`'s conflict register records the override). Point Playwright at a PR's preview URL via `E2E_BASE_URL`; a local token `vercel deploy` is the emergency path only. Project, env-var, and Blob provisioning is Terraform-owned — see `infra.md`.
