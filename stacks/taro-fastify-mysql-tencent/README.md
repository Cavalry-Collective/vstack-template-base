# Stack pack: taro-fastify-mysql-tencent

Frontend **Taro 4 H5** (React 18, plain JavaScript) · Backend **Fastify 4** (CommonJS) · DB **MySQL 8** — **CynosDB** (serverless) in production, Docker locally — via **Knex** (`mysql2`). Deploys to **Tencent Cloud**: one **SCF Web Function** serves both the JSON API and the built H5 bundle, a separate SCF **event** function runs migrations; **CynosDB** for data, **COS** (private) for media behind signed URLs, **VOD** for video, **EdgeOne** as the CDN/WAF edge; Terraform (`tencentcloud` provider) for IaC and **GitHub Actions** as the deploy pipeline. This is the manifest; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Naming.** The framework triple is `taro-fastify-mysql`; the `-tencent` suffix marks the deployment platform, appended because the Tencent-Cloud specifics (SCF bundling, CynosDB serverless, COS/VOD, EdgeOne, mainland ICP + public-net egress) are load-bearing (`../README.md` permits appending the distinguishing choice). Lift the app to another cloud and the triple stays, the suffix changes.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | Taro 4 H5, Zustand, same-origin `/api`, the two-file route registry, oklch→hex tokens, VOD/HLS video, the test-user picker |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify 4 CommonJS, the layer-first layout, plugins as aspects, `HttpError` + one error site, the SCF Web-Function entry, test-mode / OTP / audit bindings |
| `db.md` | `db/CLAUDE.md` + repo ring | Knex + MySQL 8, the `*_test` destructive test-DB ritual, MySQL-8 schema gotchas, the migrate-in-a-function prod path |
| `infra.md` | `infra/CLAUDE.md` | `tencentcloud` provider, SCF (Web + migrate) shape, CynosDB serverless, COS/VOD/EdgeOne, the GitHub Actions deploy seam |

This pack ships the optional `infra.md` (permitted by `../README.md`): the deployment platform is load-bearing here. Each appendix opens with the verbatim precedence line and ends with its conflict register.

## Day-1 wiring

Part of the root `README.md` Day-1 checklist. `scripts/activate-stack.sh taro-fastify-mysql-tencent` builds four path-scoped rule files under `.claude/rules/` — one per appendix, `infra.md` included. Rerun after editing an appendix; CI's **Stack rule drift** step catches a stale copy. Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Record in root `CLAUDE.md` **Learnings**: `Stack: taro-fastify-mysql-tencent; appendices under stacks/taro-fastify-mysql-tencent/, activated via scripts/activate-stack.sh`.

## Suggested toolchain

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

**CI block → `.github/workflows/ci.yml`:** a `mysql:8` service; `pnpm install --frozen-lockfile`; lint; typecheck (no-op); **vitest against a `*_test` schema** (`pnpm --filter backend test:db:setup` once); `pnpm build`; the **migration up→down→up round-trip**; the frontend **i18n key-parity** check; the two OpenAPI drift guards (`lint:openapi`, `lint:schemas`). Playwright e2e runs against a running stack with `x-tenant: test`, not this job.

**Validation:** Fastify JSON Schema on every route (request and response), all schemas under `schemas/<domain>.js`, with OpenAPI as the source of truth (`lint:openapi` + `lint:schemas` guard drift). See `backend.md`.

## Deploy seam

Deployment is a GitHub Actions pipeline (`.github/workflows/deploy.yml`) — this pack fills it in rather than deleting it (contrast `vercel`). On a push to the default branch (or `workflow_dispatch`): build frontend + backend, compose one SCF zip, resume CynosDB if paused, `terraform apply`, push function code out-of-band, invoke the migrate function, smoke-test the live URL. Terraform owns function config / env / role / triggers and every other resource — see `infra.md`. Protect the default branch so CI is green before merge; a push then both merges and deploys.
