# Stack pack: vercel-csr

Frontend: **React SPA** (Vite, TypeScript), client-rendered, no SSR. Backend: **Fastify** (plain JavaScript, ESM) as a serverless function. DB: **Postgres** — **Neon** in production, Docker locally — via **node-pg-migrate** + **`pg`**. Everything deploys to **Vercel**: two projects (static SPA + API function), Vercel Blob for object storage, Terraform (Vercel provider) as IaC.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for the platform plus its rendering shape: client-side rendering on Vercel. The underlying triple is `react-fastify-postgres` (per `../README.md`).

Sibling: `vercel-ssr` is the server-rendered, one-app full-stack Next.js alternative on the same platform. The `-csr`/`-ssr` suffixes carry the contrast. This pack is the SPA one and keeps a separate Fastify API.

## Defining constraint — no SSR

The frontend is a single-page app: one static `index.html`, rendered entirely in the browser. There is no server-side rendering, and none may be added — not per request, not at build time. The enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*.

A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a pack change — adopt `vercel-ssr` instead.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | the client-only rendering model (no SSR), Vite + React Router, `vercel.json` SPA fallback + `/api` proxy, REST-only data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify plugins → onion mapping, Awilix composition root, the Vercel function entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down pairs), `pg` query layer, serverless pooling against Neon |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, two-project workload shape, deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform is this pack's identity, so the cloud shape is stack-shaped here. Each appendix opens with the verbatim precedence line and ends with its conflict register.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`:

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*).
2. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
3. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
4. Skip the root `README.md`'s "soften the SPA framing" step. That instruction targets the server-first packs. This pack is a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave all of them as shipped.
5. Record in root `CLAUDE.md` **Learnings**: `Stack: vercel-csr; appendices under stacks/vercel-csr/ (4 appendices incl. infra)`.

## Commands

pnpm workspaces over `apps/*`; root `"type": "module"`; Node 22. Pin `packageManager` in the root manifest. Keep the Node major in sync between `engines` and the Terraform `node_version` variable — Vercel reads the latter.

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local Postgres (fixed-name docker container, shared across worktrees) + migrate
pnpm dev         # both dev servers in parallel: Fastify watch (:4000) + Vite dev (:5173, proxying /api → :4000)
pnpm lint        # ESLint (flat config) in both apps
pnpm typecheck   # frontend tsc --noEmit (backend is plain JS — explicit no-op script)
pnpm test        # backend node --test suite (Playwright e2e is separate: pnpm test:e2e)
pnpm build       # vite build → apps/frontend/dist (backend is plain JS — its build/typecheck scripts are explicit no-ops)
pnpm migrate     # node-pg-migrate up (rollback: pnpm --filter backend migrate:down)
```

**CI checklist → `.github/workflows/ci.yml`** (non-interactive):

- A `postgres:16` service container.
- `pnpm install --frozen-lockfile`.
- Lint; frontend `tsc --noEmit`; backend `node --test`; `vite build`.
- The frontend i18n key-parity check — the base gate stands unchanged.
- Migration round-trip up → down → up on the scratch DB. node-pg-migrate has real downs, so keep the base `ci.yml` round-trip TODO's wording as written.
- Run the seed twice (idempotency).
- Playwright e2e is not part of this job. It runs against a Vercel preview deployment via `E2E_BASE_URL` (see *Deploy seam*).

## Pack decisions

- **Zod** on both sides — backend edge DTOs and boot-time env schemas, frontend form/response shapes; a shared shape is defined once and reused (rejected: separate validators per app). Details in `backend.md` / `frontend.md`.
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Add-ons

- **test-mode**, **otp-auth** — bound in `backend.md`.
- **saas-billing** — bound section for this pack in `add-ons/saas-billing/bindings.md`.
- **seo** — recorded **unbound** in `add-ons/seo/bindings.md`: its S1 seam needs routes served complete without client-side scripts, and a client-only SPA has none. Adopting seo means adopting `vercel-ssr` instead, or serving the crawlable surface outside this app.
- **llm-calls**, **premium-design**, **enterprise-compliance**, **multi-tenancy** — left unbound. Adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment is Vercel's GitHub integration — CI/CD is merging code:

- Both Vercel projects connect to the repo (Terraform `git_repository`, production branch `main`). Every PR gets a preview deployment; a merge to `main` ships production on Vercel's pipeline.
- `ci.yml` is the merge gate, not the deploy pipeline. Protect `main` so PRs merge only on green CI.
- `deploy.yml` is never filled in — delete the stub. `infra.md`'s conflict register records the override.
- Point Playwright at a PR's preview URL via `E2E_BASE_URL`.
- A local token `vercel deploy` is the emergency path only.
- Project, env-var, and Blob provisioning is Terraform-owned — see `infra.md`.
