# Vercel single-project platform: infrastructure appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind infrastructure to the `vercel/vercel` Terraform provider, one full-stack Vercel project, Neon, and optional Blob.

## Workload

Keep one root module under `infra/<workload>/` with:

- `versions.tf` and `providers.tf`;
- `web.tf` for the Next.js project;
- `storage.tf` when Blob is needed;
- one explicit environment-variable resource per value.

Configure:

- one project with `framework = "nextjs"` and `root_directory = "apps/frontend"`;
- the Node version in Terraform and workspace `engines`;
- the function region through `resource_config`;
- a remote access-controlled Terraform backend.

Let the Neon and Blob integrations inject their connection variables. Do not duplicate them in Terraform. Treat Terraform state as a credential.

## Context

Authenticate with a team API token. Run `vercel whoami`, confirm the team and project, then confirm the target environment before planning or applying.

## Deployment

- Connect the project to the repository and use `main` as production.
- Protect `main`; Vercel deploys every accepted push.
- Do not copy the GitHub Actions deploy example.
- Run database migrations before pushing code that reads the new schema.
- Point Playwright at preview deployments with `E2E_BASE_URL`.
- Exclude `.env*`, `infra/`, `design/`, `docs/`, and `.claude/` in `.vercelignore`.
- Use token-driven local deployment only for emergencies.

## Staging

- Create a stable `develop` preview with branch-scoped variables.
- Back it with a dedicated long-lived Neon branch.
- Apply staging migrations before pushing `develop`.
- Keep per-PR previews for isolated review.

## Observability

- Enable Vercel Observability on the project.
- Send server runtime logs to an external drain through one marketplace integration.
- Configure Analytics and Speed Insights through `frontend.md`.
- Use request-log search for historical production incidents; the CLI live tail is not durable evidence.
- When queues are in use, watch backlog and max message age under Observability → Queues; queue topics and triggers live in code (`vercel.json`), not Terraform.

Do not declare an integration-owned log drain in Terraform. Manage its environment coverage in the integration.

## Conflict register

- **Base says:** the infrastructure guide uses GCP networking as its worked example. **In this stack:** use Vercel and Neon, with no VPC, subnet, or firewall resources. **Because:** Vercel exposes no customer-managed network surface for this workload. **Concretely:** DO author `vercel_*` resources and verify context with `vercel whoami`; DON'T add GCP providers or network files.
- **Base says:** deployment runs through `.github/workflows/deploy.yml`. **In this stack:** Vercel's Git integration is the deployment pipeline and no deploy workflow is created. **Because:** a second token-driven deployment path would race the platform integration. **Concretely:** protect `main` and keep Vercel Git integration enabled; DON'T add `vercel deploy` to GitHub Actions.
