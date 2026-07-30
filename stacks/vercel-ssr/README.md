# Stack pack: vercel-ssr

Use this pack for one full-stack Next.js application on Vercel with Postgres.

| Area | Choice |
|---|---|
| Identity | `nextjs-postgres` |
| Application | Next.js App Router, TypeScript, Server Components and Actions |
| Server code | Onion under `apps/frontend/src/server/` |
| Database | Postgres 16, Neon in production, `pg`, node-pg-migrate |
| Platform | One Vercel project, optional Blob, Terraform |

Choose `vercel-csr` instead when the product needs a separate API and a purely client-rendered SPA.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | App Router UI, routing, state, styling, testing |
| `backend.md` | relocated onion, queries, actions, sessions, testing |
| `db.md` | Postgres migrations, `pg`, Neon pooling |
| `infra.md` | Vercel project, staging, deployment, observability |

## Day-1 setup

This pack removes the separate backend application:

1. Keep this directory and delete the other stack packs.
2. Move `apps/backend/CLAUDE.md` to `apps/frontend/src/server/CLAUDE.md`.
3. Add this first line to the moved file: `> Relocated from apps/backend/; this directory is the backend. Map apps/backend/src/ paths here. Bindings: the adopted pack's backend.md.`
4. Delete `apps/backend/`.
5. Update root `CLAUDE.md` and `README.md` to describe one full-stack Next.js app.
6. Copy the command block below into root `CLAUDE.md`.
7. Implement the CI checklist in `.github/workflows/ci.yml`.
8. Record `Stack: vercel-ssr; appendices under stacks/vercel-ssr/ (4 appendices incl. infra); one app, apps/backend removed` in **Learnings**.

Use a pnpm workspace with `apps/frontend`, Node 22, and root `"type": "module"`. Pin `packageManager` and align the Node major with Terraform.

```bash
pnpm bootstrap   # install + start shared local Postgres + migrate
pnpm dev         # Next dev server :3000
pnpm lint        # ESLint
pnpm typecheck   # tsc --noEmit
pnpm test        # Vitest; Playwright is test:e2e
pnpm build       # next build
pnpm migrate     # node-pg-migrate up; rollback with migrate:down
```

## CI

- Start a `postgres:16` service.
- Run `pnpm install --frozen-lockfile`.
- Run lint, typecheck, Vitest, and `next build`.
- Run the i18n parity and accessibility gates from the base workflow.
- Apply migrations from zero, then run up, down, and up.
- Run the seed twice.
- Run Playwright separately against a Vercel preview through `E2E_BASE_URL`.

## Decisions

- Use manual constructor wiring through `container.ts`.
- Use Zod for actions, routes, forms, and environment validation.
- Use `iron-session` sealed HTTP-only cookies.
- Use Vitest for server and isolated frontend logic.
- Use React Context only where an interactive subtree shares or mutates server data.
- Use direct SQL through `pg`; do not add an ORM.

## Deployment

- Terraform connects the Vercel project to the repository with `main` as production.
- Protect `main`; green `ci.yml` is the merge gate.
- Delete the `deploy.yml` stub. Vercel's Git integration is the only normal deployment path.
- Run Neon migrations before pushing code that reads the new schema.
- Use the persistent `develop` preview and its dedicated Neon branch for staging.
- Use `vercel deploy` only for an emergency.
