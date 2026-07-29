# Stack pack: vercel-ssr

One **full-stack Next.js** app (App Router, TypeScript) owning both the UI and the server side — Server Components and Server Actions instead of a separate API app · DB **Postgres** — **Neon** (serverless) in production, Docker locally — via **node-pg-migrate** + **`pg`**. Deploys to **Vercel** as a **single project**; Terraform (Vercel provider) as IaC. This is the **manifest** — it wires the pack onto a project; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Naming.** Named for the platform plus its distinguishing shape — full-stack SSR on Vercel — under the platform exception in `../README.md`; the would-be convention triple collapses to the pair `nextjs-postgres` (Next.js fills both the frontend and backend slots). Sibling contrast: the `vercel-csr` pack (would-be triple `react-fastify-postgres`) is a **client-rendered SPA with no SSR at all**, served as static assets beside a separate Fastify API on the same platform — **this pack is the server-rendered alternative**, and the `-ssr` suffix marks exactly that. Pick this one when routes must arrive as complete HTML (public search indexability above all); pick `vercel-csr` when they need not.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router UI, queries/actions data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` (relocated Day-1 — see below) | the onion under `src/server/`, the queries/actions controller edge, composition root, aspects, test-mode / otp-auth / llm-calls bindings |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down pairs), `pg` query layer, serverless pooling against Neon |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, single-project workload shape, deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform is part of this pack's identity, so the cloud shape is stack-shaped here. Each appendix opens with the verbatim precedence line and ends with its conflict register; conflicts live in the appendices, not here.

## The one-app restructure (Day-1, load-bearing)

This stack has no separate backend app — the onion lives inside the Next.js app under `apps/frontend/src/server/`. Once, at Day-1:

1. `git mv apps/backend/CLAUDE.md apps/frontend/src/server/CLAUDE.md` — the onion contract moves with the code it governs; agents pick it up when working under `src/server/`.
2. Prepend one line to the moved file: `> Relocated from apps/backend/ — this directory is the backend; path references to apps/backend/src/ map here. Bindings: the adopted pack's backend.md.`
3. `rm -rf apps/backend`.
4. Soften the root framing: in the root `CLAUDE.md` repo shape, drop the `apps/backend` row and describe `apps/frontend` as "the full-stack Next.js app (UI + server side)"; update the root `README.md` **What's included** rows to match. The repo name still encodes "spa" and is immutable — accepted as stale.

`backend.md`'s conflict register records this override; the relocated contract applies unchanged apart from paths.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*). Run the one-app restructure above. Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Finally record in root `CLAUDE.md` **Learnings**: `Stack: vercel-ssr; appendices under stacks/vercel-ssr/ (4 appendices incl. infra); one app — apps/backend removed`.

## Suggested toolchain (pnpm, ESM, Node 22)

A pnpm workspace with the single app under `apps/frontend`; root `"type": "module"`; pin `packageManager` in the root manifest and keep the Node major in sync between `engines` and the Terraform `node_version` variable (Vercel reads the latter).

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local Postgres (fixed-name docker container, shared across worktrees) + migrate
pnpm dev         # next dev (:3000) — one app, one server
pnpm lint        # ESLint (flat config)
pnpm typecheck   # tsc --noEmit
pnpm test        # Vitest suite (Playwright e2e is separate: pnpm test:e2e)
pnpm build       # next build
pnpm migrate     # node-pg-migrate up (rollback: pnpm migrate:down)
```

**CI block → `.github/workflows/ci.yml` (non-interactive):** a `postgres:16` service container; `pnpm install --frozen-lockfile`; lint; `tsc --noEmit`; `vitest run`; `next build`; the **i18n key-parity** check (the base gate stands — this pack changes nothing about it); **migration round-trip up → down → up on the scratch DB** — node-pg-migrate has real downs, so keep the base `ci.yml` round-trip TODO's wording as written (a deliberate contrast with ORM packs that must replace it); run the seed twice (idempotency). Playwright e2e is not part of this job — it runs against a Vercel preview deployment via `E2E_BASE_URL` (see *Deploy seam*).

**Validation:** **Zod** everywhere there is an edge — action/route DTOs, the boot-time env schema, form schemas. A shape shared between server and client is defined once and imported from both sides: one app, one module graph, no duplication seam.

## Add-ons

Bindings for the shipped add-ons live in the appendices: **test-mode**, **otp-auth**, and **llm-calls** in `backend.md`. An add-on that carries its own bindings file names this pack there instead — **saas-billing** and **seo** both do (`add-ons/<name>/bindings.md`, each with a `vercel-ssr` section). **premium-design**, **enterprise-compliance**, and **multi-tenancy** are left unbound by this pack — adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment is **Vercel's GitHub integration — CI/CD is merging code.** The single Vercel project connects to the repo (Terraform `git_repository`, production branch `main`): every PR gets a preview deployment, and a merge to `main` ships production on Vercel's own pipeline. `ci.yml` is the **merge gate**, not the deploy pipeline — protect `main` so PRs merge only on green CI; `deploy.yml` is never filled in (delete the stub — `infra.md`'s conflict register records the override). Point Playwright at a PR's preview URL via `E2E_BASE_URL`; a local token `vercel deploy` is the emergency path only. Project, env-var, and storage provisioning is Terraform-owned — see `infra.md`.
