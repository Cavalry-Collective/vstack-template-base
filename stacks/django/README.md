# Stack pack: django

Frontend: **React SPA** (Vite, TypeScript), client-rendered, no SSR. Backend: **Django 5 + Django REST Framework** (Python 3.12, managed with **uv**). DB: **Postgres 16** via the **Django ORM** (Django migrations). Platform-neutral: the product deploys through whatever the base `infra/` contract stands up — this pack ships no `infra.md`.

This is the manifest — it wires the pack onto a project. Bindings and conflict registers live in the appendices. For what a pack is and the invariants every appendix follows, see `../README.md`.

## Identity & naming

Named for its backend framework — the dominant Python full-stack combo: a Django + DRF API behind a React SPA. The underlying triple is `react-django-postgres` (per `../README.md`).

Like `enterprise`, this pack is platform-neutral — it ships no `infra.md`. Unlike it, the frontend is a client-rendered SPA with a separate API — the same frontend shape as `vercel-csr`, minus the platform.

## Defining constraint — no SSR

The frontend is a single-page app: one static `index.html`, rendered entirely in the browser. There is no server-side rendering, and none may be added — not per request, not at build time. The enforceable rules and the greppable forbidden list are in `frontend.md` → *Rendering model*.

A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a pack change — adopt a server-rendered pack, or serve the crawlable surface outside this app (see *Add-ons* on `seo`).

## Appendix → base mapping

| Appendix | Binds onto | Scope |
|---|---|---|
| `frontend.md` | `apps/frontend/CLAUDE.md` | client-only rendering (no SSR), Vite + React Router, same-origin `/api` proxy + SPA fallback, Tailwind 4 + Radix, Zod at the edge |
| `backend.md` | `apps/backend/CLAUDE.md` | Django apps as feature modules, `services.py`/`selectors.py` discipline, DRF edge, the `settings.py` config seam, middleware aspects, uv/ruff/mypy/pytest |
| `db.md` | `db/CLAUDE.md` + data access | Django migrations (per-app home, `sqlmigrate` review, drift gate), ORM schema conventions, the fixed-name local Postgres |

Each appendix opens with the verbatim precedence line and ends with its conflict register (see `../README.md`). Conflicts live in the appendices, not here.

## Day-1 wiring

Run as part of the root `README.md` `## Day-1 checklist`:

1. Delete every other `stacks/*` directory. The one pack left is the adopted one; each area's `CLAUDE.md` then points agents at the matching appendix here (mechanism: `../README.md` *Activation*).
2. Copy the **dev block** below over the root `CLAUDE.md` "Common commands" placeholder. Delete the banner.
3. Apply the **CI checklist** below to `.github/workflows/ci.yml`. Never paste the same block in both places.
4. Skip the root `README.md`'s "soften the SPA framing" step. That instruction targets the server-first packs; this pack is a SPA, so the base framing in root `CLAUDE.md`, `apps/frontend/CLAUDE.md`, and the **What's included** "Frontend SPA" row is already correct — leave all of them as shipped.
5. Record in root `CLAUDE.md` **Learnings**: `Stack: django; appendices under stacks/django/`.

## Commands

Two ecosystems, one verb set: **uv** manages `apps/backend` (`pyproject.toml` + committed `uv.lock`), **pnpm** manages `apps/frontend`. Each root command verb exists **once**, in a root **Makefile**, and fans out to both apps.

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

**CI checklist → `.github/workflows/ci.yml`** (non-interactive):

- A `postgres:16` service container.
- `uv sync --frozen` + `pnpm install --frozen-lockfile`.
- Lint (ruff + ESLint); typecheck (mypy + `tsc --noEmit`).
- `pytest`; `vitest run`; `vite build`.
- The frontend i18n key-parity check — the base gate stands unchanged.
- The db appendix's CI checks (`db.md` → *Operations*): migrations apply from zero on the scratch DB; the `makemigrations --check --dry-run` drift gate, this pack's `ci.yml` migration gate — `db.md`'s register replaces the base round-trip rule; the seed run twice (idempotency).

## Pack decisions

- **DRF** as the API layer (rejected: Django Ninja, a FastAPI sidecar — DRF is the ecosystem default with the deepest auth/permission/throttle integration).
- **uv** for Python dependencies (rejected: Poetry, pip-tools).
- **mypy + django-stubs** — the `typecheck` verb is real for both apps (rejected: pyright, whose Django support lacks the mypy plugin; rejected: skipping backend typecheck).
- **`services.py`/`selectors.py`** as the use-case convention (rejected: a hexagonal ports-and-adapters layer over the ORM — `backend.md`'s conflict register records the override).
- **Makefile fan-out** — one root verb set over both ecosystems (rejected: a root `package.json` shelling into uv — it makes Node a hard dependency of backend-only work, and `make` is language-neutral and already on every dev/CI image).
- **Django session auth** — cookie-based, CSRF on (rejected: JWT held by the SPA).
- **DRF serializers + Zod** at the two edges; the shared contract is the OpenAPI schema DRF emits via **drf-spectacular**, and frontend types are generated from it (rejected: hand-copying shapes between the apps). Details in `backend.md` / `frontend.md`.
- **django-environ** as the `settings.py` config seam (rejected: pydantic-settings — a second config object beside `settings` buys nothing).
- **pytest + pytest-django** as the backend runner (rejected: Django's unittest runner — pytest fixtures/parametrize are the ecosystem default).
- **uuid primary keys** (rejected: the default `BigAutoField` — enumerable in URLs).
- **`TextChoices` + `CheckConstraint`** for fixed value sets (rejected: native Postgres enums — `ALTER TYPE … ADD VALUE` is non-transactional and effectively one-way).
- **Plain `fetch` + React Context on the frontend** (rejected: react-query/SWR, Redux/Zustand — add a cache library only when client-side invalidation genuinely appears).
- Further decisions and their rejected alternatives are recorded in each appendix's conflict register.

## Add-ons

- **test-mode**, **otp-auth** — bound in `backend.md`.
- **saas-billing** — bound section for this pack in `add-ons/saas-billing/bindings.md`.
- **seo** — recorded **unbound** in `add-ons/seo/bindings.md`: its S1 seam needs routes served complete without client-side scripts, and a client-only SPA has none. Adopting seo means adopting a server-rendered pack instead, or serving the crawlable surface outside this app.
- **llm-calls**, **premium-design**, **enterprise-compliance**, **multi-tenancy** — left unbound. Adopting one means supplying its *Binds to a stack* answers in the matching appendix as part of adoption.

## Deploy seam

Platform-neutral, like `enterprise` — this pack ships no `infra.md` (infra is cloud-shaped, not app-stack-shaped):

- The SPA's `dist/`, the Django app (ASGI/WSGI behind its process server), and `manage.py migrate` deploy through the pipeline the base `infra/CLAUDE.md` contract stands up.
- Serve `dist/` and the API from **one origin** with the SPA fallback (`frontend.md`).
- Run `manage.py migrate` before the code that reads the new schema goes live, keeping each migration backward-compatible (expand → migrate → contract, `db.md`).
- `deploy.yml` stays the base stub until the infra work fills it in.
