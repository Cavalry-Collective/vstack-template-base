# Tencent Cloud — infra appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `infra/CLAUDE.md` to the **`tencentcloud` Terraform provider** and Tencent's serverless shape; the base workflow, risk-review format, and approval guardrails apply unchanged.

## Binding at a glance

- **Compute: SCF** — one **Web Function** for API + H5; a separate **event** function for migrations.
- **Data: CynosDB** (MySQL, serverless). **Storage: COS** (private media) + **VOD** (video). **Edge: EdgeOne** (CDN/WAF).
- **Secrets: pipeline-injected env** — `DB_PASSWORD` via pipeline secrets, never committed. Rejected: an SSM/KMS store, on cost.
- **Deploy: GitHub Actions** (`deploy.yml`), filled in — a repo-owned ordered pipeline, not a platform integration.

## Structure & session context

- `infra/terraform/`: per-environment roots (`envs/<env>/`) calling shared `modules/` (`network`, `compute`, `database`, `storage`, `edgeone`) — two-plus environments sharing one shape is when the base permits `modules/`; keep modules focused and the explicit-resource / no-`for_each` style inside.
- **Auth / context** (base start-of-session check): the provider authenticates with `TENCENTCLOUD_SECRET_ID`/`KEY`; verify account + region with `tccli` before any plan/apply and confirm the target environment with the user — never assume prior context.

## Compute — SCF

- **One SCF Web Function** (`type = "HTTP"`) runs the Fastify app — it `listen()`s on the platform port behind `scf_bootstrap` (entry mechanics: `./backend.md`) and serves `/api/*` + the bundled H5; one function is the whole app.
- **A separate SCF *event* function** (`<project>-migrate`, handler `migrate.main_handler`, ~900 s timeout, **no HTTP trigger**, CAM-authenticated) runs migrations + seeds — pipeline-invoked, never public.
- **Terraform owns function config, env vars, the CAM role, and triggers — never the code zip.** The pipeline pushes code **out-of-band** via `UpdateFunctionCode` after `apply` — the provider's `zip_file` drift detection fights a CI rebuilding the artifact each run. One explicit `resource` per object (base style); env vars per function.

## Networking — VPC + public-net egress

Author a VPC with one private subnet — CynosDB serverless is VPC-locked; the SCF functions and DB cluster share the subnet (a DB security group admits it), reaching the DB privately. Outbound uses **public-net egress** (`enable_public_net = true`) — no NAT gateway or EIP. EdgeOne fronts the function URL with WAF + rate limit; leave the direct SCF URL unadvertised.

## Database — CynosDB serverless

- **`SERVERLESS` mode** (min/max CCU, postpaid) **auto-pauses after ~2 h idle**. The pipeline **resumes a paused cluster before `terraform apply`** (`tccli ... ResumeServerless`, poll `serverless_status` until `running`); a cold request may still hit a resuming DB — tolerate first-hit latency.
- **Backups:** the serverless tier hard-caps physical snapshots/PITR at **7 days**; for longer retention, run an automatic logical backup (mysqldump → COS) alongside the physical.
- Migration execution → `./db.md`.

## Storage — COS + VOD

- **Keep the media COS bucket private** (AES256 + versioning) — never serve a public object URL; mint **signed GET** / **presigned PUT** URLs server-side (`lib/cos`). Scope the SCF role to the media prefixes the app writes, never the bucket root; add a lifecycle rule expiring orphaned uploads.
- **Configure cross-region DR replication** for the media bucket — objects replicate from enablement onward (no automatic backfill).
- **VOD:** upload signatures are HMAC-signed with a **permanent CAM key** (`TENCENT_SECRET_ID`/`KEY` of a VOD-scoped sub-user) — **VOD signing does not accept STS temporary creds**, so the key is long-lived by necessity, Terraform-injected. Attach a **procedure** transcoding uploads to adaptive HLS + a cover; the completion **callback is unsigned** — validate by FileId ownership + an authoritative VOD read.

## Edge — EdgeOne + mainland ICP

- An **EdgeOne (TEO) zone** (partial/CNAME) fronts the SCF origin for the app and `api.` acceleration domains; WAF + rate limiting live here.
- **Mainland ICP:** a mainland-region deployment (e.g. `ap-guangzhou`) needs an **ICP filing** per domain. Tencent injects `Content-Disposition: attachment` on un-ICP'd domains — add an EdgeOne response-header rule stripping it until the filing lands; budget the ICP lead time.

## Deploy pipeline — GitHub Actions (`deploy.yml`)

On a push to the default branch (or `workflow_dispatch` with `reset_schema` / `force_reseed_test_users` inputs), the ordered job:

1. builds the frontend same-origin (`TARO_APP_API_BASE=/api`);
2. esbuild-bundles `handler.js` + `migrate.js` and composes **one SCF zip** — bootstrap + `node_modules` (`mysql2` only) + `db/migrations/` + the H5 `public/`;
3. **resumes CynosDB** if auto-paused;
4. `terraform apply` (state in a COS backend);
5. pushes function code out-of-band (`UpdateFunctionCode`);
6. **invokes the migrate function** (`./db.md`);
7. **smoke-tests** the live URL (fetches under an SLO).

Branch protection makes push-equals-deploy safe (register, deploy entry).

## Observability

**Drain SCF logs to CLS** (base go-live rule), setting topic retention **explicitly** (the platform default is short) so the backend's structured lines (correlation id, handled errors, integration/webhook results) stay queryable.

## Testing

No infra test runner — verification is the step-7 smoke test plus the base plan → risk-review gate before any apply.

## Conflict register

- **Base says:** the blessed cloud is **GCP** — its context commands and networking convention (custom-mode VPC, explicit subnets/firewalls/NAT) apply, with AWS/Azure equivalents. **In this stack:** **Tencent Cloud** — the context check maps to `tccli` + `TENCENTCLOUD_SECRET_ID/KEY`; the VPC/subnet convention **partly binds**: VPC + private subnet for the VPC-locked CynosDB, **no NAT gateway** (public-net egress). **Because:** this pack's identity is Tencent-Cloud-serverless. **Concretely:** DO author `tencentcloud_*` resources (VPC/subnet included) and verify context with `tccli`; DON'T scaffold a GCP provider, a NAT gateway, or gcloud context checks.
- **Base says (root `CLAUDE.md`):** `deploy.yml` runs after a green CI run on the default branch (a `workflow_run` trigger). **In this stack:** it triggers **on push to the default branch** (+ `workflow_dispatch`), a first-class ordered pipeline (the seven steps above). **Because:** the release runs Terraform, code push, and migrate as one ordered unit, gated by **branch protection** (green CI before merge) rather than chained after a separate CI run. **Concretely:** DO protect the default branch so push-equals-deploy is safe; put `reset_schema` / reseed behind `workflow_dispatch` inputs; DON'T add a second deploy path (local `pnpm deploy` is emergencies-only, root rule).
