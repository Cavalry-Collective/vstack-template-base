# Stack pack: mern

Use this pack for a client-rendered React application with a separate Express API and MongoDB.

| Area | Choice |
|---|---|
| Identity | `react-express-mongo` |
| Frontend | React, TypeScript, Vite, React Router |
| Backend | Express 5, plain JavaScript ESM, long-lived Node process |
| Database | MongoDB 7, Mongoose, migrate-mongo |
| Platform | Platform-neutral; no `infra.md` |

## Constraint

The frontend is a static SPA with no SSR or prerendering. Adopt `vercel-ssr` or `enterprise` when public routes must return complete HTML. The `seo` add-on is incompatible with this pack.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | client-only rendering, routing, serving contract, styling, testing |
| `backend.md` | Express onion binding, middleware, sessions, testing |
| `db.md` | Mongoose models, migrations, transactions, local database |

## Day-1 setup

1. Keep this directory and delete the other stack packs.
2. Copy the command block below into root `CLAUDE.md`.
3. Implement the CI checklist in `.github/workflows/ci.yml`.
4. Keep the base SPA wording unchanged.
5. Record `Stack: mern; appendices under stacks/mern/` in root `CLAUDE.md` **Learnings**.

Use pnpm workspaces, Node 22, and root `"type": "module"`. Pin `packageManager` and `engines`.

```bash
pnpm bootstrap   # install + start shared MongoDB replica set + migrate
pnpm dev         # Express :4000 + Vite :5173 with /api proxy
pnpm lint        # ESLint in both apps
pnpm typecheck   # frontend tsc --noEmit; backend explicit no-op
pnpm test        # backend node --test; Playwright is test:e2e
pnpm build       # Vite build; backend explicit no-op
pnpm migrate     # migrate-mongo up; rollback with migrate:down
```

## CI

- Start MongoDB 7 with `docker run` and `--replSet rs0`, then initialise the replica set.
- Run `pnpm install --frozen-lockfile`.
- Run lint, frontend typecheck, backend tests, and Vite build.
- Run the i18n parity and accessibility gates from the base workflow.
- Apply migrations from zero, then run up, down, and up.
- Compare collection indexes and the migration changelog before and after the cycle.
- Run the seed twice.
- Run Playwright separately through `E2E_BASE_URL`.

## Decisions

- Use Express 5 directly with manual factory wiring.
- Use plain JavaScript ESM and `node:test` on the backend.
- Use Zod on both application edges.
- Use Mongoose as the document schema and query layer with `autoIndex: false`.
- Use migrate-mongo for index and document migrations.
- Use React Context and plain `fetch` until client cache invalidation requires another tool.

## Deployment

- Deploy the Express API as a long-lived Node process.
- Serve `apps/frontend/dist` behind the SPA fallback and same-origin `/api` proxy defined in `frontend.md`.
- Run migrations before rolling out code that reads the new document shape.
- Use the deployment workflow supplied by the project's infrastructure.
