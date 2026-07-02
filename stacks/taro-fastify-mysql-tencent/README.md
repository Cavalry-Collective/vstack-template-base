# Stack pack: taro-fastify-mysql-tencent

Frontend **Taro 4 H5** (React 18, plain JavaScript) · Backend **Fastify 4** (CommonJS) · DB **MySQL 8** — **CynosDB** serverless in production, Docker locally — via **Knex** (`mysql2`). On **Tencent Cloud**: one **SCF Web Function** serves the JSON API and built H5 bundle, a separate SCF **event** function runs migrations; **COS** (private) holds media behind signed URLs, **VOD** video, **EdgeOne** the CDN/WAF edge; Terraform (`tencentcloud` provider) for IaC, **GitHub Actions** for deploys. This manifest carries identity + wiring; pack invariants and the appendix skeleton: `../README.md`.

> **Naming.** The framework triple is `taro-fastify-mysql`; `-tencent` marks the load-bearing deployment platform (SCF bundling, CynosDB serverless, COS/VOD, EdgeOne, mainland ICP + public-net egress) — hence a substantive `infra.md`, not an n/a stub. Lift to another cloud: the triple stays, the suffix changes.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | Taro 4 H5, Zustand, same-origin `/api`, two-file routing, oklch→hex tokens, VOD/HLS, test-user picker |
| `backend.md` | `apps/backend/CLAUDE.md` | Fastify 4 CommonJS, layer-first layout, plugins as aspects, `HttpError` + one error site, SCF entry, security + add-on bindings |
| `db.md` | `db/CLAUDE.md` + repo ring | Knex + MySQL 8, destructive `*_test` ritual, MySQL-8 gotchas, migrate-in-a-function prod path |
| `infra.md` | `infra/CLAUDE.md` | `tencentcloud` provider, SCF (Web + migrate), CynosDB serverless, COS/VOD/EdgeOne, deploy seam |

## Toolchain & dev block

pnpm workspaces over `apps/*`; Node 20 / pnpm 9; backend CommonJS (no `"type": "module"`). Pin `packageManager` in the root manifest.

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local MySQL (fixed-name container, shared across worktrees) + migrate + dev servers
pnpm dev         # Fastify --watch + Taro H5 --watch
pnpm lint        # ESLint both apps + frontend token-discipline check
pnpm typecheck   # explicit no-op — both apps are plain JS
pnpm test        # vitest both apps (backend suite is destructive — *_test schema only; see db.md)
pnpm build       # backend esbuild bundle + Taro H5 production build
pnpm migrate     # knex migrate:latest (rollback: pnpm --filter backend migrate:rollback)
```

## CI block → `.github/workflows/ci.yml`

A `mysql:8` service; `pnpm install --frozen-lockfile`; lint; typecheck (no-op); **vitest against a `*_test` schema** (`pnpm --filter backend test:db:setup` once); `pnpm build`; the **migration up→down→up round-trip**; the **i18n key-parity** check; the OpenAPI drift guards `lint:openapi` + `lint:schemas` (validation mechanics: `backend.md`). Playwright e2e runs against a running stack with `x-tenant: test`, not in this job.

## Day-1 wiring

From the root `README.md` Day-1 checklist: Delete every other `stacks/*` directory so this pack is the only one left; each area's `CLAUDE.md` then points at the matching appendix (`../README.md` *Activation*). Copy the **dev block** above over the root "Common commands" placeholder; apply the **CI block** to `.github/workflows/ci.yml` — never the same block in both. Record in root `CLAUDE.md` **Learnings**: `Stack: taro-fastify-mysql-tencent; appendices under stacks/taro-fastify-mysql-tencent/`.

## Deploy seam

Deployment is a repo-owned GitHub Actions pipeline — this pack **fills `.github/workflows/deploy.yml` in**. On a push to the default branch (or `workflow_dispatch`): build frontend + backend, compose one SCF zip, resume CynosDB if paused, `terraform apply`, push function code out-of-band, invoke the migrate function, smoke-test the live URL. Terraform owns function config/env/role/triggers and every other resource — `infra.md`. Protect the default branch so CI is green before merge; a push then both merges and deploys.
