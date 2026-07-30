# Tencent Cloud: infrastructure appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind infrastructure to the Tencent Cloud Terraform provider, SCF, TDSQL-C (CynosDB), TCR, COS, VOD, and EdgeOne.

## Layout and context

- Keep environment roots under `infra/terraform/envs/<env>/`.
- Keep shared `network`, `compute`, `database`, `registry`, `storage`, and `edgeone` modules under `infra/terraform/modules/`.
- Preserve explicit resource blocks inside modules.
- Authenticate through `TENCENTCLOUD_SECRET_ID` and `TENCENTCLOUD_SECRET_KEY`.
- Verify account and region with `tccli`, then confirm the target environment before planning or applying.

## Network and edge

- Create one VPC and private subnet for TDSQL-C and both functions.
- Allow database access only from the function security group.
- Enable SCF public-network egress instead of adding a NAT gateway.
- Put an EdgeOne partial or CNAME zone in front of the Web Function.
- Configure WAF and rate limiting at EdgeOne.
- Keep the direct SCF URL unadvertised.

## Compute

- Run the application as one SCF HTTP Web Function deployed from a container image.
- Set the function's start command to `node src/server.js` and let Fastify listen on port 9000, the port SCF routes requests to.
- Serve both `/api/*` and the H5 bundle from that function.
- Host images in a private Tencent Container Registry instance and grant the function's role pull access only.
- Reference the image by digest, never by a floating tag, so a rollback names an exact artifact.
- Run migrations and controlled seeds from the same image with an overridden command, through a CAM-authenticated event function with no HTTP trigger.
- Let Terraform own function configuration, environment, roles, and triggers.
- Update the function's image digest out of band after Terraform, so the release does not depend on Terraform seeing a freshly pushed artifact.

## Database

- Run TDSQL-C MySQL 8.0 in serverless mode with explicit minimum and maximum capacity.
- Resume an auto-paused cluster before Terraform and poll until it is running.
- Accept first-request resume latency in application behaviour.
- Keep physical snapshots and point-in-time recovery within the platform's seven-day limit.
- Add scheduled logical backups to COS when compliance requires longer retention.
- Inject database credentials through deployment secrets.

## Storage and video

- Keep the media COS bucket private, encrypted, versioned, and replicated to another region.
- Issue signed reads and presigned writes from the backend.
- Limit the SCF role to the application's prefixes.
- Expire orphaned uploads.
- Use a dedicated VOD-scoped permanent CAM key for upload signing.
- Transcode uploads to adaptive HLS and generate a cover through a VOD procedure.
- Validate unsigned completion callbacks by FileId ownership and an authoritative VOD read.

## Deployment

The protected default-branch pipeline must:

1. build H5 with `TARO_APP_API_BASE=/api`;
2. build the backend image, including the built H5 files, and push it to TCR;
3. resume the TDSQL-C cluster;
4. apply Terraform using the COS state backend;
5. update the function to the new image digest;
6. invoke the migration function against the same digest;
7. smoke-test the live URL.

Keep reset and forced reseed behind manual workflow inputs.

## Observability and domain setup

- Send SCF logs to CLS with explicit retention.
- Keep structured correlation, error, integration, and webhook fields queryable.
- Use COS versioning and replication for media recovery.
- Account for ICP filing lead time for mainland domains.
- Remove Tencent's temporary download header through EdgeOne only until the ICP filing is active.

## Conflict register

- **Base says:** the infrastructure guide uses GCP networking as its worked example. **In this stack:** use Tencent Cloud, a private VPC for TDSQL-C, and SCF public-network egress without NAT. **Because:** TDSQL-C is VPC-locked while SCF provides managed outbound access. **Concretely:** DO author `tencentcloud_*` resources and verify context with `tccli`; DON'T add GCP resources or a NAT gateway.
- **Base says:** `deploy.yml` runs after CI through a workflow-run trigger. **In this stack:** the protected default-branch push runs one ordered build, image, infrastructure, migration, and smoke pipeline. **Because:** the SCF release must coordinate all of those states as one unit. **Concretely:** protect the branch and keep one deploy workflow; DON'T add a second deployment path.
- **Base says:** use `infra/<workload>/<env>/` for environment roots. **In this stack:** roots live at `infra/terraform/envs/<env>/` and share focused modules. **Because:** all environments are one workload with the same Tencent shape. **Concretely:** add environments under `envs/` and reuse the modules; DON'T create one top-level workload directory per environment.
