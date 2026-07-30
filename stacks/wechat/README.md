# Stack pack: wechat

Frontend: **Taro 4 H5** (React 18, plain JavaScript). Backend: **Fastify 4** (CommonJS). DB: **MySQL 8** — **CynosDB** (serverless) in production, Docker locally — via **Knex** (`mysql2`). Everything deploys to **Tencent Cloud**: one **SCF Web Function** serves both the JSON API and the built H5 bundle, and a separate SCF **event** function runs migrations. **CynosDB** holds the data, **COS** (private) serves media behind signed URLs, **VOD** handles video, and **EdgeOne** is the CDN/WAF edge. Terraform (`tencentcloud` provider) is the IaC; **GitHub Actions** runs the deploy pipeline.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for the market it targets — the WeChat ecosystem on Tencent Cloud. The shipped frontend is Taro 4's **H5 target only**; no Mini Program target is active (`frontend.md`), though Taro keeps that build within reach if a project enables it. The underlying triple is `taro-fastify-mysql` on Tencent Cloud (per `../README.md`).

The Tencent-Cloud specifics (SCF bundling, CynosDB serverless, COS/VOD, EdgeOne, mainland ICP + public-net egress) run through every appendix. Lift the app to another cloud and the triple stays; the platform specifics are what change.

The `seo` add-on cannot bind to this pack: client-only H5 rendering cannot meet its rendering seam. Its residual robots posture still applies.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | Taro 4 H5, Zustand, same-origin `/api`, the two-file route registry, oklch→hex tokens, VOD/HLS video |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify 4 CommonJS, the layer-first layout, plugins as aspects, `HttpError` + one error site, the SCF Web-Function entry |
| `db.md` | `db/CLAUDE.md` + repo ring | Knex + MySQL 8, the `*_test` destructive test-DB ritual, MySQL-8 schema gotchas, the migrate-in-a-function prod path |
| `infra.md` | `infra/CLAUDE.md` | `tencentcloud` provider, SCF (Web + migrate) shape, CynosDB serverless, COS/VOD/EdgeOne, the GitHub Actions deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform is this pack's identity. Each appendix opens with the verbatim precedence line and ends with its conflict register.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`:

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here, `infra.md` included (mechanism: `../README.md` *Activation*).
2. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
3. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
4. Record in root `CLAUDE.md` **Learnings**: `Stack: wechat; appendices under stacks/wechat/`.

## Commands

pnpm workspaces over `apps/*`; Node 20 / pnpm 9; backend CommonJS (no `"type": "module"`); frontend a Taro 4 H5 app. Pin `packageManager` in the root manifest.

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local MySQL (fixed-name docker container, shared across worktrees) + migrate + dev servers
pnpm dev         # both dev servers: Fastify --watch + Taro H5 --watch
pnpm lint        # ESLint both apps + the frontend token-discipline check
pnpm typecheck   # explicit no-op — both apps are plain JS
pnpm test        # vitest both apps (backend suite is destructive — runs against a *_test schema; see db.md)
pnpm build       # backend esbuild bundle + Taro H5 production build
pnpm migrate     # knex migrate:latest (rollback: pnpm --filter backend migrate:rollback)
```

**CI checklist → `.github/workflows/ci.yml`:**

- A `mysql:8` service container.
- `pnpm install --frozen-lockfile`.
- Lint; typecheck (no-op).
- Vitest against a `*_test` schema (`pnpm --filter backend test:db:setup` once).
- `pnpm build`.
- The migration up→down→up round-trip.
- The frontend i18n key-parity check.
- The two OpenAPI drift guards (`lint:openapi`, `lint:schemas`).
- Playwright e2e is not part of this job — it runs against a running stack with `x-tenant: test`.

## Pack decisions

- **Fastify JSON Schema** on every route (request and response), all schemas under `schemas/<domain>.js`, with **OpenAPI as the source of truth** (`lint:openapi` + `lint:schemas` guard drift). Details in `backend.md`.
- **DB credentials from env** — `DB_PASSWORD` injected via Terraform / pipeline secrets, never committed (rejected: `DB_SECRET_NAME` + SSM/KMS, on cost for this stack). Details in `infra.md`.
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Deploy seam

Deployment is a GitHub Actions pipeline (`.github/workflows/deploy.yml`) — this pack fills the stub in. On a push to the default branch (or `workflow_dispatch`):

1. Build frontend + backend and compose one SCF zip.
2. Resume CynosDB if paused.
3. `terraform apply`.
4. Push function code out-of-band.
5. Invoke the migrate function.
6. Smoke-test the live URL.

- Terraform owns function config, env, roles, triggers, and every other resource — see `infra.md`.
- Protect the default branch so CI is green before merge; a push then both merges and deploys.
