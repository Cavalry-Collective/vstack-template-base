# Stack pack: wechat

Use this pack for a mobile-first Taro H5 application on Tencent Cloud.

| Area | Choice |
|---|---|
| Identity | `taro-fastify-mysql` |
| Frontend | Taro 4 H5, React 18, plain JavaScript |
| Backend | Fastify 4, CommonJS, Tencent SCF Web Function |
| Database | MySQL 8, CynosDB serverless, Knex |
| Platform | Tencent Cloud SCF, COS, VOD, EdgeOne, Terraform |

Only the H5 target is active. The `seo` add-on is incompatible with this client-rendered pack.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | Taro H5, routing, Zustand, styling, video |
| `backend.md` | layer-first Fastify application and SCF entrypoint |
| `db.md` | Knex, MySQL, destructive test database, migration function |
| `infra.md` | Tencent Cloud resources and GitHub Actions deployment |

## Day-1 setup

1. Keep this directory and delete the other stack packs.
2. Copy the command block below into root `CLAUDE.md`.
3. Implement the CI checklist in `.github/workflows/ci.yml`.
4. Record `Stack: wechat; appendices under stacks/wechat/` in root `CLAUDE.md` **Learnings**.

Use pnpm workspaces, Node 20, pnpm 9, CommonJS on the backend, and plain JavaScript in both apps.

```bash
pnpm bootstrap   # install + shared MySQL + migrate + dev
pnpm dev         # Fastify watch + Taro H5 watch
pnpm lint        # ESLint both apps + frontend token check
pnpm typecheck   # explicit no-op
pnpm test        # Vitest against the guarded *_test database
pnpm build       # backend esbuild bundle + Taro H5 build
pnpm migrate     # Knex latest; rollback with backend migrate:rollback
```

## CI

- Start a `mysql:8` service.
- Run `pnpm install --frozen-lockfile`.
- Create and migrate the guarded `*_test` database.
- Run lint, the explicit typecheck no-op, Vitest, and both builds.
- Run the i18n parity and accessibility gates from the base workflow.
- Run the migration up, down, and up cycle.
- Run `lint:openapi` and `lint:schemas`.
- Run Playwright separately against a running stack with `x-tenant: test`.

## Decisions

- Use a layer-first Fastify structure with services as the business layer.
- Use Fastify JSON Schema on every route and keep OpenAPI authoritative.
- Use Zustand on the frontend.
- Use Knex for migrations and queries.
- Inject database credentials through deployment secrets.
- Serve the API and built H5 bundle from one SCF Web Function.

## Deployment

`deploy.yml` is the only normal deployment path. On a protected default-branch push or manual dispatch it:

1. builds the frontend and backend;
2. creates the SCF bundle;
3. resumes CynosDB when paused;
4. applies Terraform;
5. uploads function code;
6. invokes the migration function;
7. smoke-tests the live URL.

Keep schema reset and forced reseeding behind explicit manual inputs.
