# Stack pack: django

Use this pack for a client-rendered React application with a Django REST API and Postgres.

| Area | Choice |
|---|---|
| Identity | `react-django-postgres` |
| Frontend | React, TypeScript, Vite, React Router |
| Backend | Django 5, Django REST Framework, Python 3.12, uv |
| Database | Postgres 16, Django ORM and migrations |
| Platform | Platform-neutral; no `infra.md` |

## Constraint

The frontend is a static SPA with no SSR or prerendering. Use a server-rendered pack or a separate public origin when routes must return complete HTML. The `seo` add-on is incompatible with this pack.

## Appendices

| File | Covers |
|---|---|
| `frontend.md` | SPA rendering, OpenAPI client, `/api` proxy, styling, testing |
| `backend.md` | Django apps, services and selectors, DRF, config, testing |
| `db.md` | Django models, migrations, transactions, local database |

## Day-1 setup

1. Keep this directory and delete the other stack packs.
2. Copy the command block below into root `CLAUDE.md`.
3. Copy `.github/workflows/examples/ci.yml.example` to `.github/workflows/ci.yml` and implement the CI checklist in it.
4. Keep the base SPA wording unchanged.
5. Record `Stack: django; appendices under stacks/django/` in root `CLAUDE.md` **Learnings**.

Use uv for `apps/backend`, pnpm for `apps/frontend`, and one root Makefile to expose the standard verbs.

```bash
make bootstrap   # uv sync + pnpm install + shared Postgres + migrate
make dev         # Django :8000 + Vite :5173 with /api proxy
make lint        # ruff check/format + ESLint
make typecheck   # mypy with django-stubs + tsc --noEmit
make test        # pytest + Vitest; Playwright is test-e2e
make build       # Vite build; Django explicit no-op
make migrate     # manage.py migrate; rollback to an app migration
```

## CI

- Start a `postgres:16` service.
- Run `uv sync --frozen` and `pnpm install --frozen-lockfile`.
- Run ruff, ESLint, mypy, and TypeScript.
- Run pytest, Vitest, and Vite build.
- Run the i18n parity and accessibility gates from the base workflow.
- Apply migrations from zero.
- Run `makemigrations --check --dry-run`.
- Run the seed twice.
- Prove each new migration's reverse locally as required by `db.md`.

## Decisions

- Use DRF for the API and Django session authentication with CSRF enabled.
- Use Django apps with `services.py` and `selectors.py` rather than a parallel repository layer.
- Use django-environ through `settings.py`.
- Use drf-spectacular as the contract and generate frontend types with openapi-typescript.
- Use pytest with pytest-django and mypy with Django stubs.
- Use UUID primary keys and `TextChoices` with database checks.
- Use React Context and plain `fetch` on the frontend by default.

## Deployment

- Deploy Django behind its application server and serve the SPA and `/api` from one origin.
- Run `manage.py migrate` before code that reads the new schema.
- Keep migrations backward-compatible through expand, migrate, contract.
- Use the deployment workflow supplied by the project's infrastructure.
