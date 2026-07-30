# Stack pack: wechat

Use this pack for a mobile-first Taro H5 application on Tencent Cloud.

| Area | Choice |
|---|---|
| Identity | `taro-fastify-mysql` |
| Frontend | Taro 4 H5, React 18, plain JavaScript |
| Backend | Fastify 5, ESM, Tencent SCF Web Function from a container image |
| Database | TDSQL-C (CynosDB) MySQL 8.0 serverless, Knex, `mysql2` |
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
3. Copy `.github/workflows/examples/ci.yml.example` to `.github/workflows/ci.yml` and implement the CI checklist in it.
4. Record `Stack: wechat; appendices under stacks/wechat/` in root `CLAUDE.md` **Learnings**.

Use pnpm workspaces, Node 24 LTS, pnpm 10, ESM on the backend, and plain JavaScript in both apps. Pin `packageManager` and keep the Node major aligned across `engines`, the backend container image, and CI.

```bash
pnpm bootstrap   # install + shared MySQL + migrate + dev
pnpm dev         # Fastify watch + Taro H5 watch
pnpm lint        # ESLint both apps + frontend token check
pnpm typecheck   # explicit no-op
pnpm test        # Vitest against the guarded *_test database
pnpm build       # Taro H5 build + backend container image
pnpm migrate     # Knex latest; rollback with backend migrate:rollback
```

## CI

- Start a `mysql:8.0` service matching the TDSQL-C engine.
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
- Deploy that function as a container image so the stack owns its Node major. The managed Node runtime is a documented fallback only (`backend.md` → *Legacy managed runtime*).

## Deployment

`deploy.yml` is the only normal deployment path. On a protected default-branch push or manual dispatch it:

1. builds the H5 bundle;
2. builds the backend image and pushes it to Tencent Container Registry;
3. resumes the TDSQL-C cluster when paused;
4. applies Terraform;
5. points the function at the new image digest;
6. runs migrations from the same image;
7. smoke-tests the live URL.

Keep schema reset and forced reseeding behind explicit manual inputs.
