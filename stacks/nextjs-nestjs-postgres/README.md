# Stack pack: nextjs-nestjs-postgres

Frontend **Next.js** (App Router, server-first) · Backend **NestJS** · DB **Postgres via Prisma**. Language-neutral: TypeScript or plain JavaScript, with JS-path notes in each appendix. This is the **manifest** — it wires the pack onto a project; the bindings and conflict registers live in the three appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | App Router, server-first rendering, four-states mapping, form-factor rule |
| `backend.md` | `apps/backend/CLAUDE.md` | NestJS module/provider → onion mapping, Zod validation, JS Babel decorator setup |
| `db.md` | `db/CLAUDE.md` + repo ring | Prisma schema, migrations (`migrations.path → ../db/migrations`), client wiring |

Each appendix opens with the verbatim precedence line and ends with its conflict register (see `../README.md`). Conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: `scripts/activate-stack.sh nextjs-nestjs-postgres` builds the three **path-scoped rule files** under `.claude/rules/` — one per appendix, each loading only when its files are touched (mechanism, `paths:` scopes, and why prepend-copies rather than symlinks or `@`-imports: `../README.md` *Activation*). If you later edit an appendix, rerun the script; CI's **Stack rule drift** step catches a stale copy. Confirm what loaded with the `InstructionsLoaded` hook.

Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and the **CI** block into `.github/workflows/ci.yml` — never the same block in both, and never `prisma migrate dev` in CI.

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

**CI block → `.github/workflows/ci.yml` (non-interactive):** spin up a Postgres service container; `pnpm install --frozen-lockfile`; `prisma generate`; `prisma migrate deploy` (**never `prisma migrate dev` in CI — it can reset the DB or prompt**); `pnpm typecheck`; `next build` + `nest build`; non-watch `pnpm test`. Suggested defaults — keep one verb per base placeholder if you swap tools (turbo, etc.).

**Validation:** **Zod** is the schema library at the NestJS controller edge and for Next form/response schemas; a shape shared across the two is defined once and reused (no class-validator). Details in `backend.md` / `frontend.md`.

## Deploy seam

`prisma migrate deploy` and the Next build output deploy and run through the cloud pipeline — see `infra/CLAUDE.md` (GCP/Terraform) for where migrate-on-deploy runs. This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped).
