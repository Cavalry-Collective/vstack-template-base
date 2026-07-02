# Stack pack: nextjs-nestjs-postgres

Frontend **Next.js** (App Router, server-first) · Backend **NestJS** · DB **Postgres via Prisma**. TypeScript or plain JavaScript, with JS-path notes per appendix. This manifest wires the pack onto a project; bindings and conflict registers live in the appendices — conflicts never live here. Pack invariants: `../README.md`.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, server-first rendering, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | NestJS module/provider → onion mapping, security + add-on bindings, JS Babel setup |
| `db.md` | `db/CLAUDE.md` + repo ring | Prisma schema, migrations (`migrations.path → db/migrations`), client boundaries |
| `infra.md` | `infra/CLAUDE.md` | n/a stub — deployment-platform-agnostic; base applies unchanged |

## Toolchain (pnpm workspaces)

Three library picks bind the pack, each argued once in its owning appendix: NestJS on the **Fastify adapter** (not the default Express adapter), **Zod** as the one schema language at the NestJS edge and for Next form/response schemas — shared shapes defined once, no class-validator — and **AsyncLocalStorage** (`nestjs-cls`) for request context. Details: `backend.md`, `frontend.md`.

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

**CI block → `.github/workflows/ci.yml` (non-interactive):** spin up a Postgres service container; `pnpm install --frozen-lockfile`; `prisma generate`; `prisma migrate deploy` (**never `prisma migrate dev` in CI — it can reset the DB or prompt**); `pnpm typecheck`; `next build` + `nest build`; non-watch `pnpm test`. Suggested defaults — keep one verb per base placeholder if you swap tools (turbo, etc.).

## Day-1 wiring

Run as part of the root `README.md` Day-1 checklist:

1. Delete every other `stacks/*` directory — each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*). The appendices are read in place; nothing to generate.
2. Copy the **dev** block over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and the **CI** block into `.github/workflows/ci.yml` — never the same block in both.
3. Record in root `CLAUDE.md` **Learnings**: `Stack: nextjs-nestjs-postgres; appendices under stacks/nextjs-nestjs-postgres/`.

## Deploy seam

`prisma migrate deploy` and the Next build ship through the cloud pipeline — see `infra/CLAUDE.md` for where migrate-on-deploy runs. This pack's `infra.md` is the platform-agnostic stub.
