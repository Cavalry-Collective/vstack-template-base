# Stack pack: django

Frontend **React SPA** (Vite, TypeScript) — **client-rendered, no SSR** · Backend **Django 5 + Django REST Framework** (Python 3.12, managed with **uv**) · DB **Postgres 16** via the **Django ORM** (Django migrations). Platform-neutral: the product deploys through whatever the base `infra/` contract stands up. This is the **manifest** — it wires the pack onto a project; bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

> **Naming.** Named for its backend framework — the dominant Python full-stack combo: a Django + DRF API behind a React SPA; the underlying triple is `react-django-postgres` (per `../README.md`). Like `enterprise`, this pack is platform-neutral — it ships no `infra.md`. Unlike it, the frontend is a client-rendered SPA with a separate API — the same frontend shape as `vercel-csr`, minus the platform.

> **Rendering model.** The frontend is a **single-page app**: one static `index.html`, rendered entirely in the browser. **There is no server-side rendering, and none may be added.** The enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*. A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a **pack change** — adopt a server-rendered pack, or serve the crawlable surface outside this app (see *Add-ons* on `seo`).

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | client-only rendering (no SSR), Vite + React Router, same-origin `/api` proxy + SPA fallback, Tailwind 4 + Radix, Zod at the edge |
| `backend.md` | `apps/backend/CLAUDE.md` | Django apps as feature modules, `services.py`/`selectors.py` discipline, DRF edge, the `settings.py` config seam, middleware aspects, uv/ruff/mypy/pytest |
| `db.md` | `db/CLAUDE.md` + data access | Django migrations (per-app home, `sqlmigrate` review, drift gate), ORM schema conventions, the fixed-name local Postgres |

Each appendix opens with the verbatim precedence line and ends with its conflict register (see `../README.md`). Conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`: delete every other `stacks/*` directory so this pack is the only one left — each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*). Then copy the **dev** block below over the root `CLAUDE.md` "Common commands" placeholder (delete the banner) and apply the **CI** notes to `.github/workflows/ci.yml` — never the same block in both. Finally record in root `CLAUDE.md` **Learnings**: `Stack: django; appendices under stacks/django/`.

> **Skip the root `README.md`'s "soften the SPA framing" step.** That instruction targets the server-first packs. This pack **is** a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave every one of them as shipped.

## Suggested toolchain (uv + pnpm, fanned out by a root Makefile)

Two ecosystems, one verb set: **uv** manages `apps/backend` (`pyproject.toml` + committed `uv.lock`), **pnpm** manages `apps/frontend`; each root command verb exists **once**, in a root **Makefile**, and fans out to both apps. Pack decision — rejected alternative: a root `package.json` whose scripts shell into uv (it makes Node a hard dependency of backend-only work and hides the Python half behind npm scripts; `make` is language-neutral and already on every dev/CI image).

**Dev block → root `CLAUDE.md` "Common commands":**

```bash
make bootstrap   # uv sync + pnpm install + start local Postgres (fixed-name docker container, shared across worktrees) + migrate
make dev         # both dev servers: Django runserver (:8000) + Vite dev (:5173, proxying /api → :8000)
make lint        # ruff check + ruff format --check (backend); ESLint (frontend)
make typecheck   # mypy with django-stubs (backend); tsc --noEmit (frontend)
make test        # pytest (backend); vitest run (frontend; Playwright e2e separate: make test-e2e)
make build       # vite build → apps/frontend/dist (Django has no build step — explicit no-op; collectstatic is a deploy concern)
make migrate     # python manage.py migrate (rollback: manage.py migrate <app> <previous>)
```

**CI block → `.github/workflows/ci.yml` (non-interactive):** a `postgres:16` service container; `uv sync --frozen` + `pnpm install --frozen-lockfile`; lint (ruff + ESLint); typecheck (mypy + `tsc --noEmit`); `pytest`; `vitest run`; `vite build`; the frontend **i18n key-parity** check (the base gate stands — this pack changes nothing about it); plus the db appendix's **§CI checks** — migrations apply from zero on the scratch DB, the `makemigrations --check --dry-run` drift gate (**replacing** the base `ci.yml` round-trip TODO, per `db.md`'s register), and the seed run twice (idempotency).

**Validation:** **DRF serializers** at the backend edge (request DTOs + response shaping) and **Zod** on the frontend (env at boot, response parsing). The shared contract is the OpenAPI schema DRF emits via **drf-spectacular** — generate frontend types from it rather than hand-copying shapes (details in `backend.md` / `frontend.md`).

**Pack decisions recorded here** (referenced by the appendices): **DRF** (rejected: Django Ninja, a FastAPI sidecar); **uv** (rejected: Poetry, pip-tools); **mypy + django-stubs** — the `typecheck` verb is real for both apps (rejected: pyright, whose Django support lacks the mypy plugin; rejected: skipping backend typecheck); **`services.py`/`selectors.py`** as the use-case convention (rejected: a hexagonal ports-and-adapters layer over the ORM — see `backend.md`'s register); the **Makefile fan-out** (rejected above); **Django session auth** — cookie-based, CSRF on (rejected: JWT held by the SPA).

## Add-ons

Bindings for the shipped add-ons: **test-mode** and **otp-auth** in `backend.md`. **saas-billing** carries its own bindings file inside the add-on (`add-ons/saas-billing/bindings.md`), with a bound section for this pack. **seo** carries one too (`add-ons/seo/bindings.md`), where this pack is recorded **unbound**: its S1 seam asks for a rendering mechanism that serves indexable routes complete without client-side scripts, and a client-only SPA has none — adopting `seo` means adopting a server-rendered pack instead, or serving the crawlable surface outside this app. **llm-calls**, **premium-design**, **enterprise-compliance**, and **multi-tenancy** are left unbound by this pack — adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Platform-neutral, like `enterprise`: the SPA's `dist/`, the Django app (ASGI/WSGI behind its process server), and `manage.py migrate` deploy through the pipeline the base `infra/CLAUDE.md` contract stands up — this pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped). Two seams the pipeline must honour: serve `dist/` and the API from **one origin** with the SPA fallback (`frontend.md`); run `manage.py migrate` before the code that reads the new schema goes live, keeping each migration backward-compatible (expand → migrate → contract, `db.md`). `deploy.yml` stays the base stub until the infra work fills it in.
