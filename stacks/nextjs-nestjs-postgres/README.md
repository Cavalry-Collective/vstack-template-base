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

Run as part of the root `README.md` `## Day-1 checklist`. Create three **path-scoped rule files** so each appendix loads only when its files are touched. The `paths:` frontmatter is the documented "load only for matching files" mechanism; the appendix content is the rule **body** (rule files do not resolve `@`-imports — only `CLAUDE.md` files do, per `code.claude.com/docs/en/memory`, so each rule must be self-contained). Build each by prepending the frontmatter to a copy of its appendix:

```bash
PACK=stacks/nextjs-nestjs-postgres; mkdir -p .claude/rules
{ printf -- '---\npaths: ["apps/backend/**"]\n---\n'; cat "$PACK/backend.md"; } > .claude/rules/stack-backend.md
{ printf -- '---\npaths: ["apps/frontend/**"]\n---\n'; cat "$PACK/frontend.md"; } > .claude/rules/stack-frontend.md
{ printf -- '---\npaths: ["db/**", "apps/backend/**/repo/**"]\n---\n'; cat "$PACK/db.md"; } > .claude/rules/stack-db.md
```

The copy is the cost of staying within documented behaviour: if you later edit an appendix, regenerate its rule file. (Symlinking a rule to an appendix also works — the docs support symlinks under `.claude/rules/` — but the symlinked appendix carries no `paths:` frontmatter, so it would load unconditionally instead of path-scoped; prefer the prepend-frontmatter copy above when you want scoping.) Confirm what loaded with the `InstructionsLoaded` hook.

Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and the **CI** block into `.github/workflows/ci.yml` — never the same block in both, and never `prisma migrate dev` in CI.

## Suggested toolchain (pnpm workspaces)

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install; start local Postgres (TODO: name the docker-compose Postgres service — reuse the shared container across worktrees); prisma generate; prisma migrate dev; run both dev servers
pnpm dev         # Nest watch + Next dev server
pnpm lint        # workspace lint, both apps
pnpm test        # both suites
pnpm build       # prisma generate, then next build + nest build
pnpm migrate     # prisma migrate dev (the single root `migrate` verb)
```

**CI block → `.github/workflows/ci.yml` (non-interactive):** spin up a Postgres service container; `pnpm install --frozen-lockfile`; `prisma generate`; `prisma migrate deploy` (**never `prisma migrate dev` in CI — it can reset the DB or prompt**); `next build` + `nest build`; non-watch `pnpm test`. Suggested defaults — keep one verb per base placeholder if you swap tools (turbo, etc.).

**Validation:** **Zod** is the schema library at the NestJS controller edge and for Next form/response schemas; a shape shared across the two is defined once and reused (no class-validator). Details in `backend.md` / `frontend.md`.

## Deploy seam

`prisma migrate deploy` and the Next build output deploy and run through the cloud pipeline — see `infra/CLAUDE.md` (GCP/Terraform) for where migrate-on-deploy runs. This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped).
