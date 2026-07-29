# Stack pack: enterprise

Frontend: **Next.js** (App Router, server-first). Backend: **NestJS**. DB: **Postgres via Prisma**. Language-neutral: TypeScript or plain JavaScript, with JS-path notes in each appendix.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the three appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for its architectural character — the structured, batteries-included stack (NestJS modules + DI, Prisma, App Router) an adopter picks for team-scale, convention-heavy work. The underlying triple is `nextjs-nestjs-postgres` (per `../README.md`).

Unlike the platform-named siblings (`vercel-csr`, `vercel-ssr`, `wechat`), this pack is platform-neutral — it deploys through whatever the base `infra/` contract stands up.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, server-first rendering, four-states mapping, form-factor rule |
| `backend.md` | `apps/backend/CLAUDE.md` | NestJS module/provider → onion mapping, Zod validation, JS Babel decorator setup |
| `db.md` | `db/CLAUDE.md` + repo ring | Prisma schema, migrations (`migrations.path → db/migrations`, root-config-relative), client wiring |

This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped). Each appendix opens with the verbatim precedence line and ends with its conflict register (see `../README.md`). Conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`:

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*). Nothing to generate or rerun; the appendices are read in place.
2. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
3. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
4. Record in root `CLAUDE.md` **Learnings**: `Stack: enterprise; appendices under stacks/enterprise/`.

## Commands

pnpm workspaces over `apps/*`. Suggested defaults — keep one verb per base placeholder if you swap tools (turbo, etc.).

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install; start local Postgres (TODO: name the docker-compose Postgres service — reuse the shared container across worktrees); prisma generate; prisma migrate dev; run both dev servers
pnpm dev         # Nest watch + Next dev server
pnpm lint        # workspace lint, both apps
pnpm typecheck   # tsc --noEmit per app (explicit no-op in a plain-JS app)
pnpm test        # both suites
pnpm build       # prisma generate, then next build + nest build
pnpm migrate     # prisma migrate dev (the single root `migrate` verb)
```

**CI checklist → `.github/workflows/ci.yml`** (non-interactive):

- A Postgres service container.
- `pnpm install --frozen-lockfile`.
- `prisma generate`, then `prisma migrate deploy` — never `prisma migrate dev` in CI (it can reset the DB or prompt).
- `pnpm lint`; `pnpm typecheck`.
- `next build` + `nest build`.
- Non-watch `pnpm test`.
- The frontend i18n key-parity check — the base gate stands unchanged.
- The db appendix's §Operations gates: apply-from-zero on a scratch DB, the `migrate diff` drift gate (replacing the base round-trip TODO, per `db.md`'s register), and the seed run twice.

## Pack decisions

- **NestJS on the Fastify adapter** (`@nestjs/platform-fastify`), for throughput and the Fastify plugin ecosystem (rejected: the default Express adapter — acceptable with a concrete reason; record the swap here).
- **Zod** for validation — at the NestJS controller edge and for Next form/response schemas; a shape shared across the two apps is defined once and reused. Decorator-free, so it works identically in JS and TS (rejected: class-validator + `ValidationPipe`, whose DTOs need Babel-fragile decorator metadata). Details in `backend.md` / `frontend.md`.
- **`AsyncLocalStorage`** via `nestjs-cls` for request context (rejected: request-scoped providers, which rebuild the DI subtree per request).
- **The pack's own `PrismaService`** (rejected: the third-party `nestjs-prisma` package).
- **Build orchestrator: the Nest CLI and `next build` per app** under pnpm workspaces — no Nx/Turbo by default.
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Add-ons

- **test-mode**, **otp-auth** — bound in `backend.md`.
- **saas-billing**, **seo** — each carries its own bindings file inside the add-on (`add-ons/<name>/bindings.md`), with a section for this pack.
- **llm-calls**, **premium-design**, **enterprise-compliance**, **multi-tenancy** — left unbound. Adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

- `prisma migrate deploy` and the Next build output deploy and run through the cloud pipeline — see `infra/CLAUDE.md` (GCP/Terraform) for where migrate-on-deploy runs.
