# Tencent Cloud — infra appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `infra/CLAUDE.md` to the **`tencentcloud` Terraform provider**: the product runs on Tencent Cloud — **SCF** (a Web Function serving API + the H5 bundle, plus a separate migrate function), **CynosDB** (MySQL, serverless), **COS** (private media), **VOD** (video), **EdgeOne** (CDN/WAF edge). Read the base first; its workflow, risk-review format, and approval guardrails apply unchanged.

## Workload shape

- `infra/terraform/` with per-environment root modules (`envs/<env>/`) calling shared `modules/` (`network`, `compute`, `database`, `storage`, `edgeone`). The base prefers a flat per-workload layout, but two-or-more environments sharing the same shape is exactly when the base permits a `modules/` directory — keep each module focused, and keep the explicit-resource / no-`for_each` authoring style inside them.
- **Auth / context** (base start-of-session check, bound): the provider authenticates with `TENCENTCLOUD_SECRET_ID`/`KEY`; verify the active account + region with `tccli` before any plan or apply, and confirm the target environment with the user. Don't assume the previous context.

## Compute — SCF

- **One SCF Web Function** (`type = "HTTP"`) runs the Fastify app; `scf_bootstrap` (`exec node handler.js`) is the entry, and the process **`listen()`s** on the platform port — SCF proxies HTTP to it (no request-adapter wrapper; `./backend.md`). It serves both `/api/*` and the bundled H5 (`@fastify/static`) — one function is the whole app.
- **A separate SCF *event* function** (`<project>-migrate`, handler `migrate.main_handler`, ~900 s timeout, **no HTTP trigger**, CAM-authenticated) runs migrations + seeds — invoked by the pipeline, never public.
- **Terraform owns function config, env vars, the CAM role, and triggers — not the code zip.** The pipeline pushes code **out-of-band** via `UpdateFunctionCode` after `apply`, because the provider's `zip_file` drift detection fights a CI that rebuilds the artifact each run. One explicit `resource` per object (base style); env vars set per function.

## Networking — VPC for the DB, public-net for egress

**Author a VPC with one private subnet:** CynosDB serverless is VPC-locked, so the SCF functions and the DB cluster attach to the same subnet (a DB security group admits it) and the app reaches the DB privately. **Outbound internet uses public-net egress** (`enable_public_net = true` on the function), **not a NAT gateway** — there is no NAT/EIP to author for egress. EdgeOne fronts the function URL and carries the WAF + rate limit; the direct SCF URL is unadvertised. Don't scaffold a NAT gateway for egress; do author the VPC/subnet the DB requires.

## Database — CynosDB serverless

- **CynosDB MySQL in `SERVERLESS` mode** (min/max CCU, postpaid), which **auto-pauses after idle** (~2 h). The deploy pipeline **resumes a paused cluster before `terraform apply`** (`tccli ... ResumeServerless`, then poll `serverless_status` until `running`) — and a cold request path may still hit a resuming DB, so tolerate first-hit latency.
- **Backup caveat (serverless):** physical snapshots / PITR are **hard-capped at 7 days** by the serverless tier — any longer retention is rejected. For a longer compliance window, run an **automatic logical backup** (mysqldump → COS) at the retention you need, alongside the 7-day physical.
- DB credentials come from env (`DB_PASSWORD`, or `DB_SECRET_NAME` + SSM — SSM/KMS is costlier, usually skipped). Migration execution → `./db.md`.

## Storage — COS + VOD

- **Media COS bucket is private** (AES256 + versioning); the app never serves a public object URL — it mints **signed GET** URLs and **presigned PUT** URLs server-side (`lib/cos`). The SCF role is scoped to the `users/*` and `posts/*` prefixes only; a lifecycle rule expires orphaned uploads.
- **Cross-region DR replication is configured** — the media bucket replicates to a bucket in a second region (objects written after enablement; no automatic backfill).
- **VOD (video):** upload signatures are HMAC-signed with a **permanent CAM key** (`TENCENT_SECRET_ID`/`KEY` of a dedicated VOD-scoped sub-user) — **VOD upload signing does not accept STS temporary creds**, so this key is long-lived by necessity, injected via Terraform. A VOD **procedure** transcodes to adaptive-HLS + a cover on upload; the completion **callback is unsigned** and validated by FileId ownership + an authoritative VOD read.

## Edge — EdgeOne (CDN / WAF) + mainland ICP

- **EdgeOne (TEO) zone** (partial/CNAME) fronts the SCF Web Function origin for both the app and `api.` acceleration domains; WAF + rate limiting live here.
- **Mainland ICP:** a mainland-region deployment (e.g. `ap-guangzhou`) requires an **ICP filing** for the domain. Un-ICP'd domains get a `Content-Disposition: attachment` header injected by Tencent — an EdgeOne response-header rule strips it until the filing lands. Budget for ICP lead time when standing up a new domain.

## Deploy pipeline — GitHub Actions (`.github/workflows/deploy.yml`)

This stack **fills `deploy.yml` in** (contrast `vercel`, which deletes it). On a push to the default branch (or `workflow_dispatch` with `reset_schema` / `force_reseed_test_users` inputs), the ordered job:

1. builds the frontend same-origin (`TARO_APP_API_BASE=/api`);
2. esbuild-bundles `handler.js` + `migrate.js` and composes **one SCF zip** — bootstrap + `node_modules` (`mysql2` only) + `db/migrations/` + the H5 `public/`;
3. **resumes CynosDB** if auto-paused;
4. `terraform apply` (state in a COS backend);
5. pushes function code out-of-band (`UpdateFunctionCode`);
6. **invokes the migrate function** (`./db.md`);
7. **smoke-tests** the live URL (a few fetches under an SLO).

Protect the default branch so CI is green before merge — that green-CI gate is the release gate (base root rule); a push then both merges and deploys.

## Observability

Bringing the workload online includes its observability (base *infra* go-live rule): **SCF logs drain to CLS (Cloud Log Service)** — set the topic retention **explicitly** (the platform default is short) so the backend's structured lines (correlation id, handled errors, integration/webhook results) stay queryable. COS media has versioning (+ the DR replica); CynosDB has the two-tier backup above.

## Conflict register

- **Base says:** the blessed cloud is **GCP** — the **(GCP)** context commands / bulk-export and the networking convention (custom-mode VPC, explicit subnets/firewalls/NAT) apply, with AWS/Azure equivalents. **In this stack:** the cloud is **Tencent Cloud**. The context check maps to `tccli` + `TENCENTCLOUD_SECRET_ID/KEY`; the VPC/subnet convention **partly binds** — author a VPC + private subnet for the VPC-locked CynosDB, but **no NAT gateway** (SCF uses public-net egress). **Because:** this pack's identity is Tencent-Cloud-serverless. **Concretely:** DO author `tencentcloud_*` resources per the workload shape (VPC/subnet included) and verify context with `tccli`; DON'T scaffold a GCP provider, a NAT gateway for egress, or gcloud-based context checks.
- **Base says (root `CLAUDE.md`):** `deploy.yml` runs after a green CI run on the default branch (a `workflow_run` trigger), shipping once its deploy step is filled in. **In this stack:** `deploy.yml` triggers **on push to the default branch** (+ `workflow_dispatch`) and is a first-class ordered pipeline (build → zip → resume DB → `terraform apply` → out-of-band code push → migrate-invoke → smoke). **Because:** the SCF release must run Terraform, push code, and migrate as one ordered unit, gated by **branch protection** (green CI before merge) rather than chained after a separate CI run. **Concretely:** DO protect the default branch so push-equals-deploy is safe, and put `reset_schema` / reseed behind `workflow_dispatch` inputs; DON'T add a second deploy path (a local `pnpm deploy` exists for emergencies only, per the root contract).
