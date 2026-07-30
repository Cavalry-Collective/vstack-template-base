# Vercel two-project platform: infrastructure appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind infrastructure to the `vercel/vercel` Terraform provider, two Vercel projects, Neon, and Blob.

## Workload

Keep one root module under `infra/<workload>/` with:

- `versions.tf` and `providers.tf`;
- `web.tf` for the Vite project;
- `api.tf` for the Fastify project;
- `storage.tf` when Blob is needed;
- one explicit environment-variable resource per value.

Configure:

- the web project with `framework = "vite"`, `root_directory = "apps/frontend"`, and `output_directory = "dist"`;
- the API project with `root_directory = "apps/backend"`;
- the Node version in both Terraform and workspace `engines`;
- secrets only on the API project;
- a remote access-controlled Terraform backend.

Do not give the web project a runtime. Keep frontend routing in `apps/frontend/vercel.json`.

Let the Neon and Blob integrations inject their connection variables. Do not duplicate those variables in Terraform. Treat Terraform state as a credential.

## Context

Authenticate with a team API token. Run `vercel whoami`, confirm the team and both projects, then confirm the target environment before planning or applying.

## Deployment

- Connect both projects to the repository and use `main` as production.
- Protect `main`; Vercel deploys every accepted push.
- Delete the GitHub Actions deploy stub.
- Run database migrations before pushing code that reads the new schema.
- Keep frontend and API changes backward-compatible while the two projects deploy.
- Point Playwright at preview deployments with `E2E_BASE_URL`.
- Exclude `.env*`, `infra/`, `design/`, `docs/`, and `.claude/` in `.vercelignore`.
- Use token-driven local deployment only for emergencies.

## Staging

- Create stable `develop` previews for both projects.
- Give the staging API a stable domain for the frontend rewrite.
- Back staging with a dedicated long-lived Neon branch.
- Apply staging migrations before pushing `develop`.
- Keep per-PR previews for isolated review.

## Observability

- Enable Vercel Observability on both projects.
- Send API runtime logs to an external log drain through one marketplace integration.
- Configure frontend Analytics and Speed Insights through `frontend.md`.
- Use request-log search for historical production incidents; the CLI live tail is not durable evidence.

Do not declare an integration-owned log drain in Terraform. Manage its project and environment coverage in the integration.

## Conflict register

- **Base says:** the infrastructure guide uses GCP networking as its worked example. **In this stack:** use Vercel and Neon, with no VPC, subnet, or firewall resources. **Because:** Vercel exposes no customer-managed network surface for this workload. **Concretely:** DO author `vercel_*` resources and verify context with `vercel whoami`; DON'T add GCP providers or network files.
- **Base says:** deployment runs through `.github/workflows/deploy.yml`. **In this stack:** Vercel's Git integration is the deployment pipeline and the workflow stub is deleted. **Because:** a second token-driven deployment path would race the platform integration. **Concretely:** protect `main` and keep Vercel Git integration enabled; DON'T add `vercel deploy` to GitHub Actions.
