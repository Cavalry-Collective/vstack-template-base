# Vercel platform — infra appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `infra/CLAUDE.md` to the **Vercel Terraform provider**: the product runs entirely on Vercel. The base workflow, risk-review format, and approval guardrails apply unchanged.

## Binding at a glance

- **Provider: `vercel/vercel`**, team-API-token auth (registered — replaces the GCP blessing).
- **Workload: two `vercel_project`s** (web + api) + Blob; marketplace Neon for Postgres.
- **Deploys: Vercel's GitHub integration**; `deploy.yml` never filled in (registered).
- **Staging: a long-lived `develop` branch** backs a persistent preview environment (registered).
- **Context check:** `vercel whoami` (CLI auth: `VERCEL_TOKEN`); confirm team/project with the user before any plan or apply.

## Structure

- One self-contained workload directory under `infra/<workload>/` (base layout): `versions.tf`, `providers.tf` (`api_token` from `TF_VAR_vercel_api_token` — never committed), `variables.tf`, plus concern files: `web.tf` (frontend project + env vars), `api.tf` (backend), `storage.tf` (Blob store + connection).
- **Two `vercel_project` resources:** web (`framework = "nextjs"`, `root_directory = "apps/frontend"`) and api (`root_directory = "apps/backend"`); pin `node_version` (synced with `engines`) and the function region via `resource_config`.
- **One explicit resource block per env var** (`vercel_project_environment_variable`), `sensitive = true` for secrets — the base explicit-over-DRY style, bound. Store connections inject their own variables (Neon: `DATABASE_URL`; Blob: `BLOB_READ_WRITE_TOKEN`) — never duplicate those in Terraform.
- **The state file holds secret values — treat it as a credential:** remote, access-controlled backend from day 1; never commit state.

## Deploy seam

- **Deploys are Vercel's GitHub integration — "CI/CD" is merging code.** Both projects declare `git_repository` (`type = "github"`, `production_branch = "main"`): every PR gets a preview; every push to `main` deploys production. Day 1: grant the Vercel GitHub App repo access.
- **`ci.yml` is the merge gate, not the deploy pipeline** — protect `main` so PRs merge only on green CI (`deploy.yml`: conflict register).
- **A push deploys API and frontend together — releases must be backward-compatible.** A single push can't stage "API first, then frontend"; the config contract between them is strict (Zod). Expand-first: migrate the Neon branch manually **before** the push (`db.md`); never introduce a field whose absence breaks the other side while the two deploy out of step.
- **`.vercelignore`** keeps `.env*`, `infra/`, `design/`, `docs/`, `.claude/` out of uploads.
- A local token `vercel deploy` (`VERCEL_TOKEN`) is emergency-only — not normal work.

## Staging (`develop`)

Stand up persistent staging on day 1 — a stable URL to demo and smoke-test releases:

- **Both projects get a `develop`-branch preview environment** (branch-scoped env vars): pushing `develop` — fast-forwarded from `main` only (registered) — deploys both as Preview at the stable branch alias while `main` stays production; the web preview's `BACKEND_URL` points at the API preview alias.
- **A dedicated long-lived Neon branch** — a copy-on-write fork of prod on its own endpoint — backs the develop API, Terraform-authored with the projects; preview reads/writes never touch prod data.
- **`develop` migrations are manual too**, run before the push with its own connection string — `db.md` (note the `vercel env pull` gotcha).
- Per-PR previews still exist for isolated review — `develop` is the shared, always-on one.

## Observability

Go-live includes observability:

- **Enable Vercel Observability** on both projects (requests, invocations, runtime logs in the dashboard).
- **Ship runtime logs off-platform via a log drain** so structured backend lines (correlation id, handled errors, webhook results) outlive Vercel's short retention.
- **⚠️ The log drain is integration-owned, NOT Terraform.** Wire it through a marketplace integration (e.g. Sentry) owning the drain on the API project; the provider can't import an integration-owned drain — authoring `vercel_log_drain`/`observability.tf` creates a duplicate. Widen coverage (frontend, preview/`develop` logs) in the integration's settings.
- **Frontend analytics** (Web Analytics + Speed Insights): wired in `frontend.md`.
- **When prod misbehaves,** log-only outcomes (OTP attempts, webhook deliveries) are recovered from the dashboard request logs — filter by `environment=production`, path, status, content substring — not `vercel logs`, which live-tails ~2 minutes.

## Testing

The base read-only workflow (`terraform fmt -check`, `validate`, `plan`) is the suite. Point Playwright at a preview deployment (a PR's or the `develop` alias) via `E2E_BASE_URL`.

## Conflict register

- **Base says:** the template's blessed cloud is GCP — the **(GCP)** sections and the custom-VPC networking convention apply. **In this stack:** Vercel (+ marketplace Neon); the context check maps to `vercel whoami` + the API token; the networking convention has no binding — Vercel exposes no VPC, subnet, or firewall surface. **Because:** the pack's identity is everything-on-Vercel. **Concretely:** DO author `vercel_*` resources per the workload shape; DON'T scaffold a GCP provider, network `.tf` files, or gcloud context checks.
- **Base says:** deployment goes through CI/CD workflows under `.github/workflows/`; once `deploy.yml` is filled in, a push to `main` ships (root `CLAUDE.md`). **In this stack:** the deploy pipeline is Vercel's GitHub integration declared in Terraform — `deploy.yml` is never filled in; delete the stub on day 1 (or reduce it to a pointer) so no second deploy path exists. **Because:** Vercel's git pipeline *is* this platform's CI/CD; a second, token-driven workflow would race it. **Concretely:** DO declare `git_repository` and protect `main`; DON'T add a `vercel deploy` step to GitHub Actions — a push to `main` still deploys production, so confirm-before-push stands.
- **Base says:** one long-lived integration branch (`main`); feature work happens on short-lived branches (root `CLAUDE.md`). **In this stack:** a second long-lived `develop` branch backs the persistent staging alias. **Because:** Vercel branch-scoped preview environments need a stable branch to bind env vars and a Neon branch to. **Concretely:** `develop` receives only fast-forwards from `main` — never feature work, never a merge target; DO protect it like `main`; DON'T open PRs against it.
