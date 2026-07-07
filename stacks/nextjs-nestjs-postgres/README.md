# Stack pack: nextjs-nestjs-postgres

Frontend **Next.js** (App Router, server-first) · Backend **NestJS** · DB **Postgres via Prisma**. Language-neutral: TypeScript or plain JavaScript, with JS-path notes in each appendix. This is the **manifest** — it wires the pack onto a project; the bindings and conflict registers live in the three appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, server-first rendering, four-states mapping, form-factor rule |
| `backend.md` | `apps/backend/CLAUDE.md` | NestJS module/provider → onion mapping, Zod validation, JS Babel decorator setup |
| `db.md` | `db/CLAUDE.md` + repo ring | Prisma schema, migrations (`migrations.path → db/migrations`, root-config-relative), client wiring |

Each appendix opens with the verbatim precedence line and ends with its conflict register (see `../README.md`). Conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*). Nothing to generate or rerun; the appendices are read in place.

Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and the **CI** block into `.github/workflows/ci.yml` — never the same block in both, and never `prisma migrate dev` in CI.

Record in root `CLAUDE.md` **Learnings**: `Stack: nextjs-nestjs-postgres; appendices under stacks/nextjs-nestjs-postgres/`.

## Suggested toolchain (pnpm workspaces)

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

**CI block → `.github/workflows/ci.yml` (non-interactive):** spin up a Postgres service container; `pnpm install --frozen-lockfile`; `prisma generate`; `prisma migrate deploy` (**never `prisma migrate dev` in CI — it can reset the DB or prompt**); `pnpm lint`; `pnpm typecheck`; `next build` + `nest build`; non-watch `pnpm test`; the frontend **i18n key-parity** check (the base gate stands — `frontend.md` keeps it unchanged); plus the db appendix's **§CI checks** — apply-from-zero on a scratch DB, the `migrate diff` drift gate (replacing the base round-trip TODO, per `db.md`'s register), and the seed run twice. Suggested defaults — keep one verb per base placeholder if you swap tools (turbo, etc.).

**Validation:** **Zod** is the schema library at the NestJS controller edge and for Next form/response schemas; a shape shared across the two is defined once and reused (no class-validator). Details in `backend.md` / `frontend.md`.

**Pack decisions recorded here** (referenced by `backend.md`): NestJS on the **Fastify adapter** (rejected: the default Express adapter); **Zod** for validation (rejected: class-validator); **`AsyncLocalStorage`** via `nestjs-cls` for request context (rejected: request-scoped providers). Build orchestrator: the Nest CLI and `next build` per app under pnpm workspaces — no Nx/Turbo by default.

## Add-ons

Bindings for the shipped add-ons: **test-mode** and **otp-auth** in `backend.md`. **saas-billing** and **seo** carry their own bindings file inside the add-on (`add-ons/<name>/bindings.md`), each with a section for this pack. **llm-calls**, **premium-design**, **enterprise-compliance**, and **multi-tenancy** are left unbound by this pack — adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

`prisma migrate deploy` and the Next build output deploy and run through the cloud pipeline — see `infra/CLAUDE.md` (GCP/Terraform) for where migrate-on-deploy runs. This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped).
