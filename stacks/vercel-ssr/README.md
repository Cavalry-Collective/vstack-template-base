# Stack pack: vercel-ssr

One **full-stack Next.js** app (App Router, TypeScript) owning both the UI and the server side — Server Components and Server Actions instead of a separate API app. DB: **Postgres** — **Neon** in production, Docker locally — via **node-pg-migrate** + **`pg`**. Everything deploys to **Vercel** as a **single project**, with Terraform (Vercel provider) as IaC.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for the platform plus its rendering shape: server-side rendering on Vercel. The would-be convention triple collapses to the pair `nextjs-postgres` — Next.js fills both the frontend and backend slots (per `../README.md`).

Sibling: `vercel-csr` (triple `react-fastify-postgres`) is the client-rendered SPA alternative on the same platform — static assets beside a separate Fastify API, no SSR at all. The `-csr`/`-ssr` suffixes carry the contrast. Pick this pack when routes must arrive as complete HTML (public search indexability above all); pick `vercel-csr` when they need not.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router UI, queries/actions data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` (relocated at Day-1 — see *Day-1 wiring*) | the onion under `src/server/`, the queries/actions controller edge, composition root, aspects, test-mode / otp-auth / llm-calls bindings |
| `db.md` | `db/CLAUDE.md` + repo ring | node-pg-migrate (real up/down pairs), `pg` query layer, serverless pooling against Neon |
| `infra.md` | `infra/CLAUDE.md` | Vercel Terraform provider, single-project workload shape, deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform is this pack's identity, so the cloud shape is stack-shaped here. Each appendix opens with the verbatim precedence line and ends with its conflict register.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`. This stack has no separate backend app — the onion lives inside the Next.js app under `apps/frontend/src/server/`. Steps 2–5 restructure the repo to match, once; `backend.md`'s conflict register records the override, and the relocated contract applies unchanged apart from paths.

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*).
2. `git mv apps/backend/CLAUDE.md apps/frontend/src/server/CLAUDE.md` — the onion contract moves with the code it governs; agents pick it up when working under `src/server/`.
3. Prepend one line to the moved file: `> Relocated from apps/backend/ — this directory is the backend; path references to apps/backend/src/ map here. Bindings: the adopted pack's backend.md.`
4. `rm -rf apps/backend`.
5. Soften the root framing: in the root `CLAUDE.md` repo shape, drop the `apps/backend` row and describe `apps/frontend` as "the full-stack Next.js app (UI + server side)"; update the root `README.md` **What's included** rows to match.
6. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
7. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
8. Record in root `CLAUDE.md` **Learnings**: `Stack: vercel-ssr; appendices under stacks/vercel-ssr/ (4 appendices incl. infra); one app — apps/backend removed`.

## Commands

A pnpm workspace with the single app under `apps/frontend`; root `"type": "module"`; Node 22. Pin `packageManager` in the root manifest. Keep the Node major in sync between `engines` and the Terraform `node_version` variable — Vercel reads the latter.

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

**CI checklist → `.github/workflows/ci.yml`** (non-interactive):

- A `postgres:16` service container.
- `pnpm install --frozen-lockfile`.
- Lint; `tsc --noEmit`; `vitest run`; `next build`.
- The frontend i18n key-parity check — the base gate stands unchanged.
- Migration round-trip up → down → up on the scratch DB. node-pg-migrate has real downs, so keep the base `ci.yml` round-trip TODO's wording as written.
- Run the seed twice (idempotency).
- Playwright e2e is not part of this job. It runs against a Vercel preview deployment via `E2E_BASE_URL` (see *Deploy seam*).

## Pack decisions

- **Zod** at every edge — action/route DTOs, the boot-time env schema, form schemas; a shape shared between server and client is defined once and imported from both sides (rejected: separate validators per side — one app, one module graph, no duplication seam). Details in `backend.md` / `frontend.md`.
- **Sessions: `iron-session`** sealed HTTP-only cookies (rejected: hand-rolled cookie signing — the base never-hand-roll-auth/crypto rule; a full auth framework — adopt Auth.js only when third-party OAuth providers genuinely appear, as a recorded choice). Details in `backend.md`.
- **Test runner: Vitest** (rejected: `node:test` — no first-class TypeScript story without loader flags; Jest — transform-heavy on ESM + TS).
- **Client state: React Context providers** seeded from Server Components (rejected: an external store library, Redux/Zustand — context + props cover this architecture's client-state needs). Details in `frontend.md`.
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Add-ons

- **test-mode**, **otp-auth**, **llm-calls** — bound in `backend.md`.
- **saas-billing**, **seo** — bound sections for this pack in `add-ons/<name>/bindings.md`.
- **premium-design**, **enterprise-compliance**, **multi-tenancy** — left unbound. Adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment is Vercel's GitHub integration — CI/CD is merging code:

- The single Vercel project connects to the repo (Terraform `git_repository`, production branch `main`). Every PR gets a preview deployment; a merge to `main` ships production on Vercel's pipeline.
- `ci.yml` is the merge gate, not the deploy pipeline. Protect `main` so PRs merge only on green CI.
- `deploy.yml` is never filled in — delete the stub. `infra.md`'s conflict register records the override.
- Point Playwright at a PR's preview URL via `E2E_BASE_URL`.
- A local token `vercel deploy` is the emergency path only.
- Project, env-var, and storage provisioning is Terraform-owned — see `infra.md`.
