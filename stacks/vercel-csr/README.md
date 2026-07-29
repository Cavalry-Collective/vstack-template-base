# Stack pack: vercel-csr

Frontend **React SPA** (Vite, TypeScript) — **client-rendered, no SSR** · Backend **Fastify** (plain JavaScript, ESM) · DB **Postgres** — **Neon** (serverless) in production, Docker locally — via **node-pg-migrate** + **`pg`**. The whole product deploys to **Vercel**: two Vercel projects (the SPA as static assets on the CDN, and the Fastify API as a serverless function), Vercel Blob for object storage, Terraform (Vercel provider) as IaC. This is the **manifest** — it wires the pack onto a project; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Rendering model — the choice this pack exists to make.** The frontend is a **single-page app**: one static `index.html`, rendered entirely in the browser. **There is no server-side rendering, and none may be added** — not per request, not at build time. The base contract's SPA framing applies verbatim; the enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*. A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a **pack change** — adopt `vercel-ssr` instead.

> **Naming.** Named for the platform plus its distinguishing shape — client-side rendering on Vercel (the underlying triple is `react-fastify-postgres`, per `../README.md`). Sibling: `vercel-ssr` is the server-rendered, one-app full-stack Next.js alternative on the same platform; **the `-csr`/`-ssr` suffixes are the contrast — this pack is the SPA one**, and it keeps a separate Fastify API. Platform packs coexist by shape suffix per `../README.md`.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | the client-only rendering model (no SSR), Vite + React Router, `vercel.json` SPA fallback + `/api` proxy, REST-only data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify plugins → onion mapping, Awilix composition root, the Vercel function entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down pairs), `pg` query layer, serverless pooling against Neon |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, two-project workload shape, deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform *is* this pack's identity, so the cloud shape is stack-shaped here. Each appendix opens with the verbatim precedence line and ends with its conflict register; conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*). Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Finally record in root `CLAUDE.md` **Learnings**: `Stack: vercel-csr; appendices under stacks/vercel-csr/ (4 appendices incl. infra)`.

> **Skip the root `README.md`'s "soften the SPA framing" step.** That instruction targets the server-first packs. This pack **is** a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave every one of them as shipped.

## Suggested toolchain (pnpm workspaces, ESM, Node 22)

pnpm workspaces over `apps/*`; root `"type": "module"`; pin `packageManager` in the root manifest and keep the Node major in sync between `engines` and the Terraform `node_version` variable (Vercel reads the latter).

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

**CI block → `.github/workflows/ci.yml` (non-interactive):** a `postgres:16` service container; `pnpm install --frozen-lockfile`; lint; frontend `tsc --noEmit`; backend `node --test`; `vite build`; the frontend **i18n key-parity** check (the base gate stands — this pack changes nothing about it); **migration round-trip up → down → up on the scratch DB** — node-pg-migrate has real downs, so keep the base `ci.yml` round-trip TODO's wording as written (a deliberate contrast with ORM packs that must replace it); run the seed twice (idempotency). Playwright e2e is not part of this job — it runs against a Vercel preview deployment via `E2E_BASE_URL` (see *Deploy seam*).

**Validation:** **Zod** on both sides — backend edge DTOs and boot-time env schemas, frontend form/response shapes; a shape shared across the two is defined once and reused. Details in `backend.md` / `frontend.md`.

## Add-ons

Bindings for the shipped add-ons: **test-mode** and **otp-auth** in `backend.md`. **saas-billing** carries its own bindings file inside the add-on (`add-ons/saas-billing/bindings.md`), with a bound section for this pack. **seo** carries one too (`add-ons/seo/bindings.md`), where this pack is recorded **unbound**: its S1 seam asks for a rendering mechanism that serves indexable routes complete without client-side scripts, and a client-only SPA has none — adopting `seo` means adopting `vercel-ssr` instead, or serving the crawlable surface outside this app. **llm-calls**, **premium-design**, **enterprise-compliance**, and **multi-tenancy** are left unbound by this pack — adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment is **Vercel's GitHub integration — CI/CD is merging code.** Both Vercel projects connect to the repo (Terraform `git_repository`, production branch `main`): every PR gets a preview deployment, and a merge to `main` ships production on Vercel's own pipeline. `ci.yml` is the **merge gate**, not the deploy pipeline — protect `main` so PRs merge only on green CI; `deploy.yml` is never filled in (delete the stub — `infra.md`'s conflict register records the override). Point Playwright at a PR's preview URL via `E2E_BASE_URL`; a local token `vercel deploy` is the emergency path only. Project, env-var, and Blob provisioning is Terraform-owned — see `infra.md`.
