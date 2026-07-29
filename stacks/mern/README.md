# Stack pack: mern

Frontend **React SPA** (Vite, TypeScript) — **client-rendered, no SSR** · Backend **Express 5** (plain JavaScript, ESM) · DB **MongoDB** via **Mongoose**, migrations via **migrate-mongo**. Platform-neutral: the product deploys through whatever the base `infra/` contract stands up — this pack ships no `infra.md`. This is the **manifest** — it wires the pack onto a project; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Naming.** Named for the well-known stack acronym — MongoDB, Express, React, Node (the underlying triple is `react-express-mongo`, per `../README.md`). Like `enterprise`, this pack is platform-neutral — it binds no deployment platform. Its shape is the `vercel-csr` shape minus the platform: a client-rendered SPA with a separate long-lived Node API.

> **Rendering model.** The frontend is a **single-page app** — one static `index.html`, rendered entirely in the browser. **There is no server-side rendering, and none may be added** — not per request, not at build time. The base contract's SPA framing applies verbatim; the enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*. A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a **pack change** — adopt a server-rendered pack (`vercel-ssr`, `enterprise`) instead.

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | the client-only rendering model (no SSR), Vite + React Router, the `dist/` serving requirements (SPA fallback + `/api` proxy), REST-only data flow, Tailwind 4 + Radix, four-states mapping |
| `backend.md` | `apps/backend/CLAUDE.md` | Express routers/middleware → onion mapping, manual composition root, long-lived-process entrypoint, plain-JS stance |
| `db.md` | `db/CLAUDE.md` + repo ring | Mongoose models as the schema home, migrate-mongo (real up/down pairs), replica-set transactions, document-store deltas |

This pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped — `../README.md`); the deploy seam is the base `infra/CLAUDE.md` contract plus the serving requirements `frontend.md` names. Each appendix opens with the verbatim precedence line and ends with its conflict register; conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*). Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Finally record in root `CLAUDE.md` **Learnings**: `Stack: mern; appendices under stacks/mern/`.

> **Skip the root `README.md`'s "soften the SPA framing" step.** That instruction targets the server-first packs. This pack **is** a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave every one of them as shipped.

## Suggested toolchain (pnpm workspaces, ESM, Node 22)

pnpm workspaces over `apps/*`; root `"type": "module"`; pin `packageManager` in the root manifest and the Node major (22) in `engines`.

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

**CI block → `.github/workflows/ci.yml` (non-interactive):** a scratch MongoDB started as a **single-node replica set** (a `docker run … mongod --replSet rs0` step — GitHub service containers can't pass the flag, and transactions refuse a standalone); `pnpm install --frozen-lockfile`; lint; frontend `tsc --noEmit`; backend `node --test`; `vite build`; the frontend **i18n key-parity** check (the base gate stands — this pack changes nothing about it); **migration round-trip up → down → up on the scratch database** — migrate-mongo has real downs, so keep the base `ci.yml` round-trip TODO's wording as written, with drift asserted the document-store way per `db.md` → *CI checks*; run the seed twice (idempotency). Playwright e2e is not part of this job — it runs against a deployed or locally served stack via `E2E_BASE_URL`.

**Validation:** **Zod** on both sides — backend edge DTOs and boot-time env schemas, frontend form/response shapes; a shape shared across the two is defined once and reused. Details in `backend.md` / `frontend.md`.

## Add-ons

Bindings for the shipped add-ons: **test-mode** and **otp-auth** in `backend.md`. **saas-billing** carries its own bindings file inside the add-on (`add-ons/saas-billing/bindings.md`), with a bound section for this pack. **seo** carries one too (`add-ons/seo/bindings.md`), where this pack is recorded **unbound**: its S1 seam asks for a rendering mechanism that serves indexable routes complete without client-side scripts, and a client-only SPA has none — adopting `seo` means adopting a server-rendered pack instead, or serving the crawlable surface outside this app. **llm-calls**, **premium-design**, **enterprise-compliance**, and **multi-tenancy** are left unbound by this pack — adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Deployment goes through the base contract — CI/CD workflows under `.github/workflows/`, with `ci.yml` as the merge gate and the cloud pipeline `infra/CLAUDE.md` stands up doing the shipping. The two workloads it must run: the Express API as a **long-lived Node process** (any container/Node host target), and the SPA's `dist/` behind a static host or reverse proxy meeting the serving requirements in `frontend.md` → *Serving `dist/`*. The root `migrate` verb runs in the pipeline **before** the rollout that reads the new shape (`db.md` → *Rolling out*).
