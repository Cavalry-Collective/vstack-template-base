# Stack pack: mern

Frontend: **React SPA** (Vite, TypeScript), client-rendered, no SSR. Backend: **Express 5** (plain JavaScript, ESM) as a long-lived Node process. DB: **MongoDB** via **Mongoose**, migrations via **migrate-mongo**. Platform-neutral: the product deploys through whatever the base `infra/` contract stands up — this pack ships no `infra.md`.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for the well-known stack acronym: MongoDB, Express, React, Node. The underlying triple is `react-express-mongo` (per `../README.md`).

Like `enterprise`, this pack is platform-neutral — it binds no deployment platform. Its shape is the `vercel-csr` shape minus the platform: a client-rendered SPA with a separate long-lived Node API.

## Defining constraint — no SSR

The frontend is a single-page app: one static `index.html`, rendered entirely in the browser. There is no server-side rendering, and none may be added — not per request, not at build time. The enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*.

A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a pack change — adopt a server-rendered pack (`vercel-ssr`, `enterprise`) instead.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | the client-only rendering model (no SSR), Vite + React Router, the `dist/` serving requirements (SPA fallback + `/api` proxy), REST-only data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | Express routers/middleware → onion mapping, manual composition root, long-lived-process entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | Mongoose models as the schema home, migrate-mongo (real up/down pairs), replica-set transactions, document-store deltas |

This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped — `../README.md`); the deploy seam is the base `infra/CLAUDE.md` contract plus the serving requirements `frontend.md` names. Each appendix opens with the verbatim precedence line and ends with its conflict register.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`:

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*).
2. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
3. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
4. Skip the root `README.md`'s "soften the SPA framing" step. That instruction targets the server-first packs; this pack is a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave all of them as shipped.
5. Record in root `CLAUDE.md` **Learnings**: `Stack: mern; appendices under stacks/mern/`.

## Commands

pnpm workspaces over `apps/*`; root `"type": "module"`; Node 22. Pin `packageManager` in the root manifest and the Node major in `engines`.

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
pnpm bootstrap   # install + start local MongoDB (fixed-name docker container, single-node replica set, shared across worktrees) + migrate
pnpm dev         # both dev servers in parallel: Express watch (:4000) + Vite dev (:5173, proxying /api → :4000)
pnpm lint        # ESLint (flat config) in both apps
pnpm typecheck   # frontend tsc --noEmit (backend is plain JS — explicit no-op script)
pnpm test        # backend node --test suite (Playwright e2e is separate: pnpm test:e2e)
pnpm build       # vite build → apps/frontend/dist (backend is plain JS — its build/typecheck scripts are explicit no-ops)
pnpm migrate     # migrate-mongo up (rollback: pnpm migrate:down)
```

**CI checklist → `.github/workflows/ci.yml`** (non-interactive):

- A scratch MongoDB started as a **single-node replica set** — a `docker run … mongod --replSet rs0` step; GitHub service containers can't pass the flag, and transactions refuse a standalone (`db.md` → *Gotchas*).
- `pnpm install --frozen-lockfile`.
- Lint; frontend `tsc --noEmit`; backend `node --test`; `vite build`.
- The frontend i18n key-parity check — the base gate stands unchanged.
- Migration round-trip up → down → up on the scratch database. migrate-mongo has real downs, so keep the base `ci.yml` round-trip TODO's wording as written, with drift asserted the document-store way per `db.md` → *Operations*.
- Run the seed twice (idempotency).
- Playwright e2e is not part of this job. It runs against a deployed or locally served stack via `E2E_BASE_URL`.

## Pack decisions

- **Express 5, used directly** — no framework on top (rejected: Fastify — the E in MERN is the identity this pack exists to offer, and Express 5 forwards a rejected async handler to the error middleware natively).
- **Plain JavaScript, ESM, no build/typecheck step** (rejected: TypeScript — `backend.md`'s conflict register records the override).
- **Zod on both sides** — backend edge DTOs and boot-time env schemas, frontend form/response shapes; a shared shape is defined once and reused (rejected: separate validators per app). Details in `backend.md` / `frontend.md`.
- **Mongoose** as the schema/query layer (rejected: the raw `mongodb` driver — a document store has no server-side DDL, so the shape must live somewhere in code, and Mongoose models are that single home).
- **migrate-mongo** for migrations (rejected: no migration tool, i.e. Mongoose `autoIndex` + ad-hoc scripts — index builds and document rewrites need ordered, tracked, reversible history, exactly as the base demands).
- **`node:test`** as the backend runner (rejected: Jest/Vitest — plain ESM JavaScript needs no transform; the built-in runner is zero-dependency).
- **REST-only data flow** (rejected: a BFF or client-side direct-DB layer — the Express backend owns the domain and its aspects).
- **Plain `fetch` through the services layer** (rejected: react-query/SWR — add one only when client-side cache invalidation genuinely appears; don't pre-install).
- **React Context providers for state** (rejected: Redux/Zustand — context + props cover this architecture's needs).
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Add-ons

- **test-mode**, **otp-auth** — bound in `backend.md`.
- **saas-billing** — bound section for this pack in `add-ons/saas-billing/bindings.md`.
- **seo** — recorded **unbound** in `add-ons/seo/bindings.md`: its S1 seam needs routes served complete without client-side scripts, and a client-only SPA has none. Adopting seo means adopting a server-rendered pack instead, or serving the crawlable surface outside this app.
- **llm-calls**, **premium-design**, **enterprise-compliance**, **multi-tenancy** — left unbound. Adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment goes through the base contract — CI/CD workflows under `.github/workflows/`:

- `ci.yml` is the merge gate; the cloud pipeline `infra/CLAUDE.md` stands up does the shipping.
- The pipeline runs two workloads: the Express API as a **long-lived Node process** (any container/Node host target), and the SPA's `dist/` behind a static host or reverse proxy meeting the serving requirements in `frontend.md` → *Serving `dist/`*.
- The root `migrate` verb runs in the pipeline **before** the rollout that reads the new shape (`db.md` → *Operations*).
