# Vercel platform (single project) — infra appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `infra/CLAUDE.md` to the **Vercel Terraform provider** (`vercel/vercel`): the product runs entirely on Vercel — **one project** (the full-stack Next.js app), marketplace Postgres (Neon), and Vercel Blob when the product stores files. Read the base first; its workflow, risk-review format, and approval guardrails apply unchanged.

## Workload shape

- One self-contained workload directory per product under `infra/<workload>/` (base layout stands): `versions.tf` (provider `vercel/vercel`), `providers.tf` (`api_token` from `TF_VAR_vercel_api_token` — never committed), `variables.tf`, plus concern files — `web.tf` (the project + its env vars), `storage.tf` (Blob store + project connection, only once the product stores files).
- **One `vercel_project` resource:** `framework = "nextjs"`, `root_directory = "apps/frontend"`. Pin `node_version` (keep in sync with the workspace `engines`) and the function region via `resource_config`.
- **One explicit resource block per environment variable** (`vercel_project_environment_variable`), `sensitive = true` for secrets — the base explicit-over-DRY authoring style, bound. Store connections inject their own variables — the Neon marketplace integration injects `DATABASE_URL`, a Blob store connection injects `BLOB_READ_WRITE_TOKEN` — don't duplicate those as Terraform-managed variables.
- **The state file holds the secret env-var values — treat it like a credential.** Use a remote, access-controlled backend from day 1; a laptop-only local state file is unencrypted, unbacked-up, and one `git add` away from a leak. Never commit state.

## Auth / context

The base's start-of-session context check, bound: the provider authenticates with a team API token. Verify identity and team with `vercel whoami` (CLI authenticated via `VERCEL_TOKEN`) and confirm the target team/project with the user before any plan or apply — the base "don't assume the previous context" rule stands.

## Deploy seam

- **Deploys are Vercel's GitHub integration — "CI/CD" is merging code.** The `vercel_project` declares `git_repository` (`type = "github"`, the repo, `production_branch = "main"`); Vercel listens to the repo and runs its own build-and-deploy pipeline: every PR gets a preview deployment, every push to `main` deploys production. Day-1: grant the Vercel GitHub App access to the repo before enabling.
- **`ci.yml` is the merge gate, not the deploy pipeline.** Vercel ships whatever lands on `main`, so protect `main`: PRs merge only on green CI. The trunk-stays-releasable rule and the root merge-back gate carry the deploy weight.
- **`deploy.yml` is never filled in** — see the conflict register. A push to `main` still ships (via Vercel, not a workflow), so the root "confirm before pushing the default branch" rule applies with full force.
- **Deploys do not run migrations — migrate, then push.** One project means UI and server can never deploy out of step with each other, but the *database* still can: run the Neon migration manually **before** the push that reads the new schema, and keep migrations expand-first (`db.md` → *Production & staging migrations*).
- Point Playwright at a PR's preview deployment URL via `E2E_BASE_URL`.
- **`.vercelignore`** keeps non-deploy material out of uploads: `.env*`, `infra/`, `design/`, `docs/`, `.claude/`.
- A local token `vercel deploy` (`VERCEL_TOKEN`) is the emergency path the root contract permits — not normal work.

## Staging environment (`develop`)

Stand up a persistent staging environment on day 1 — a shipped project wants a stable URL to demo and to smoke-test a release before it reaches `main`:

- **The `vercel_project` gets a `develop`-branch preview environment** (branch-scoped env vars); pushing `develop` deploys as Preview at the stable branch alias, while `main` stays production.
- **A dedicated long-lived Neon branch** — a copy-on-write fork of prod, on its own endpoint — backs the develop deployment, Terraform-authored alongside the project. Preview reads/writes never touch prod data.
- **Migrations for `develop` are manual too**, run before the push, with its own connection string — see `db.md` → *Production & staging migrations* (including the `vercel env pull` gotcha).
- Pushing `develop` is a safe staging release; pushing `main` is the production release. Per-PR previews (the git integration's default) still exist for isolated review — `develop` is the shared, always-on one.

## Observability

Bringing a project online includes its observability — treat it as part of go-live, not an afterthought (base `infra/CLAUDE.md`):

- **Enable Vercel Observability** on the project (requests, function invocations, and runtime logs retained and queryable in the dashboard).
- **Ship runtime logs off-platform via a log drain**, so the server side's structured log lines (correlation id, handled errors, integration/webhook results) stay searchable beyond Vercel's short retention.
- **⚠️ The log drain is integration-owned, NOT Terraform.** Wire it through a marketplace integration (e.g. Sentry) that owns the drain on the project. The Terraform `vercel-csr` provider **cannot import an integration-owned drain**, so **do not** author a `vercel_log_drain` / `observability.tf` resource for it — `terraform apply` would create a **second, duplicate drain**. The integration keeps it live; Terraform simply doesn't track it. Widen coverage (preview/`develop` logs) in the integration's settings, not Terraform.
- **Frontend product analytics** — Vercel Web Analytics + Speed Insights — are wired in `frontend.md`.
- **When prod misbehaves**, outcomes that are *log-only* (e.g. OTP attempts, webhook deliveries — not persisted) are still recoverable from the request logs: query the project's request-logs filtered by `environment=production`, path, status, and a content substring, rather than `vercel logs`, which only live-tails the last ~2 minutes.

## Conflict register

- **Base says:** this template's blessed cloud is GCP — the **(GCP)** sections (gcloud context commands, bulk export) and the networking convention (custom-mode VPC, explicit subnets/firewalls) apply, with AWS/Azure equivalents. **In this stack:** the cloud is Vercel (+ Neon via the marketplace). The context check maps to `vercel whoami` + the API token; the VPC/networking convention has no binding — Vercel is a managed platform exposing no VPC, subnet, or firewall surface to author. **Because:** this pack deploys entirely on Vercel. **Concretely:** DO author `vercel_*` resources per the workload shape above; DON'T scaffold a GCP provider, network `.tf` files, or gcloud-based context checks in this stack's workloads.
- **Base says:** deployment goes through CI/CD with workflows under `.github/workflows/`; `deploy.yml` runs after a green CI run on `main` (a `workflow_run` trigger), and once its deploy step is filled in, a push to `main` ships to the configured target (root `CLAUDE.md`). **In this stack:** the deploy pipeline is Vercel's GitHub integration, declared in Terraform (`git_repository` on the project) — `deploy.yml`'s deploy step is never filled in; on day 1 delete the stub (or reduce it to a one-line pointer at this appendix) so no second deploy path exists. **Because:** Vercel's native git pipeline *is* the CI/CD for this platform; a token-driven workflow would duplicate it, and two deploy mechanisms race. **Concretely:** DO enable `git_repository` and protect `main` so PRs merge only on green `ci.yml`; DON'T add a `vercel deploy` step to GitHub Actions. A push to `main` still deploys production — the root confirm-before-push rule stands unchanged.
