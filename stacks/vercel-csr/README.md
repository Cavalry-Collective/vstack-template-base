# Stack pack: vercel-csr

Use this pack for a client-rendered React application with a separate Fastify API, Postgres, and Vercel deployment.

| Area | Choice |
|---|---|
| Identity | `react-fastify-postgres` |
| Frontend | React 19, TypeScript, Vite 7, React Router |
| Backend | Fastify 5, plain JavaScript ESM, Vercel function |
| Database | Postgres 16, Neon in production, `pg`, node-pg-migrate |
| Platform | Two Vercel projects, Blob, Terraform |

## Constraint

The frontend is a static SPA with no SSR or prerendering. Adopt `vercel-ssr` when public routes must return complete HTML. The `seo` add-on is incompatible with this pack.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | client-only rendering, routing, `/api` proxy, styling, testing |
| `backend.md` | Fastify onion binding, Awilix, Vercel entrypoint, streaming, queues |
| `db.md` | Postgres migrations, `pg`, Neon pooling |
| `infra.md` | Vercel projects, staging, deployment, observability |

## Day-1 setup

1. Keep this directory and delete the other stack packs.
2. Copy the command block below into root `CLAUDE.md`.
3. Copy `.github/workflows/examples/ci.yml.example` to `.github/workflows/ci.yml` and implement the CI checklist in it.
4. Keep the base SPA wording unchanged.
5. Record `Stack: vercel-csr; appendices under stacks/vercel-csr/ (4 appendices incl. infra)` in root `CLAUDE.md` **Learnings**.

Use pnpm workspaces, Node 22, and root `"type": "module"`. Pin `packageManager` and keep the Node major aligned between `engines` and Terraform.

```bash
pnpm bootstrap   # install + start shared local Postgres + migrate
pnpm dev         # Fastify :4000 + Vite :5173 with /api proxy
pnpm lint        # ESLint in both apps
pnpm typecheck   # frontend tsc --noEmit; backend explicit no-op
pnpm test        # backend node --test; Playwright is test:e2e
pnpm build       # Vite build; backend explicit no-op
pnpm migrate     # node-pg-migrate up; rollback with backend migrate:down
```

## CI

- Start a `postgres:16` service.
- Run `pnpm install --frozen-lockfile`.
- Run lint, frontend typecheck, backend tests, and Vite build.
- Run the i18n parity and accessibility gates from the base workflow.
- Apply migrations from zero, then run up, down, and up.
- Run the seed twice.
- Run Playwright separately against a Vercel preview through `E2E_BASE_URL`.

## Decisions

- Use Awilix only in `container.js`; rings remain plain factories.
- Use Zod for backend DTOs, environment validation, frontend forms, and response validation.
- Use signed HTTP-only cookies for sessions.
- Use React Context and plain `fetch` until client cache invalidation requires another tool.
- Use direct SQL through `pg`; do not add an ORM.
- Use Vercel Queues (public beta) for background jobs; do not add a third-party job runner.

## Deployment

- Terraform connects both Vercel projects to the repository with `main` as the production branch.
- Protect `main`; green `ci.yml` is the merge gate.
- Do not copy the `deploy.yml` example. Vercel's Git integration is the only normal deployment path.
- Run Neon migrations before pushing code that reads the new schema.
- Use the persistent `develop` preview and its dedicated Neon branch for staging.
- Use `vercel deploy` only for an emergency.
