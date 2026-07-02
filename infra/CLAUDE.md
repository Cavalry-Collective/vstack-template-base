# Infra

The infrastructure contract — read before touching anything under `infra/`; repo-wide rules live in the root `CLAUDE.md`. Stack pack adopted (and it ships an `infra.md`)? Read that first — precedence rules in `stacks/README.md`.

> **GCP is the template's default cloud binding; an adopted stack pack's `infra.md` replaces it (items marked (GCP) go with it).** On AWS/Azure, follow the equivalent context, auth, and discovery tooling.

## Core principles

Root `CLAUDE.md` Principles apply with extra force here — infrastructure changes are high impact until proven otherwise.

- Optimize for readability and straightforward rollback; prefer stable patterns over clever abstractions; keep existing conventions absent a strong reason to change them.
- Run Terraform commands from inside the target workload directory (`infra/<workload>/`), never from `infra/` itself or the git root.
- **Set up observability from day 1** — metrics, logs, and (for user-facing apps) product analytics, retained and queryable — when bringing a workload online, not deferred. Where the platform's IaC owns observability, give it its own concern file; the platform wiring (log drains, retention, dashboards) lives in the active stack pack, which may own none of it in Terraform.

## Default execution mode

At the start of each new chat, verify the active cloud auth and project context before making changes: run the provider's context command outside the sandbox, show the contexts **(GCP:** `gcloud config configurations list`**)**, and ask which account/project/configuration to use before anything credential- or context-dependent. Never assume the previous context is correct.

### Read-only workflows

Continue read-only, non-destructive work automatically to a meaningful stopping point or approval boundary — never pause for confirmation between read-only steps:
- repository inspection
- code search
- dependency and reference tracing
- `terraform fmt -check`
- `terraform validate`
- `terraform plan`
- diff generation

### Mutation workflows

For any change that could modify infrastructure or configuration behavior, follow this sequence unless the user explicitly asks otherwise:
1. understand the target environment and requested outcome
2. inspect the relevant module and environment configuration
3. make the smallest reasonable change
4. run formatting and validation
5. run `terraform plan`
6. present the target environment, planned resource actions, and risk summary in the *Risk review checklist* format below
7. ask for approval before `terraform apply` (the approval rule lives in *Guardrails → Safety*)

## Terraform authoring style

- Define each infrastructure object as its own individually named `resource` block — explicit declarations over DRY abstractions. No `for_each`, `count`, `dynamic` blocks, or `locals` collections to generate resources unless the user requests that pattern or a clear repository convention requires it; repetition that improves readability, reviewability, importability, and rollback clarity beats abstraction.
- No `lifecycle.ignore_changes` unless the user confirms the diff is noisy and intentionally acceptable.

## Importing existing resources

- **Prefer import over replacement** — replacement risks availability, data durability, naming continuity, external integrations, and rollback complexity. Replace only when the user explicitly requests it or it is clearly safer; after import, Terraform is the source of truth for that resource.
- **Import the smallest scope that solves the task.** Never bulk-import a project, folder, or organization unless explicitly requested. Import into explicit destination `resource` blocks; larger migrations may bootstrap drafts with the provider's discovery/export tool **(GCP:** `gcloud beta resource-config bulk-export`**)**.
- **Generated output is scaffolding, never repository-ready.** Reshape it to the authoring style above before merging — one named `resource` block per real object, no generated loops, no `lifecycle.ignore_changes` to hide drift, provider-default churn removed. Committed Terraform reads as intentionally authored, not tool output.
- **Before approval:** identify the exact environment and resources, confirm import IDs and destination addresses, run `terraform plan`, review all drift, and call out additions, changes, replacements, deletions, IAM and networking changes, and stateful-resource risk.

## Risk review checklist

Before asking for approval to apply, present the change in this format:

### Plan summary
- Environment: `<environment name>`

### Planned resource actions
- To add:
  - `<resource address>`
- To change:
  - `<resource address>`
- To replace:
  - `<resource address>`
- To destroy:
  - `<resource address>`

If any section is empty, skip.

### Risk checklist

For each dimension, state `no material impact` or describe the impact:

- **Security** — public exposure, IAM/permission, network policy, secrets/encryption changes.
- **Availability** — downtime, restart/replacement, dependency/ordering, load-balancer/DNS/failover impact.
- **Data durability** — risk to databases, buckets, disks, queues, or stateful services; deletion or recreation of persistent resources; backup/retention/recovery impact.
- **Cost** — likely spend increase or decrease; sizing, replication, retention, or traffic-related changes.

## Standard layout

The `infra/` folder is organized **per workload**: each subdirectory is a self-contained Terraform root module mapping to a single project, with its own `backend.tf` and `terraform.tfvars`.

```
infra/
├── <workload-a>/
│   ├── backend.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── ... (concern-grouped .tf files: networking, compute, storage, databases, iam, observability)
└── <workload-b>/
```

### Workload directories
- No cross-workload references or shared local modules without explicit approval — workloads are intentionally independent.
- New workloads follow the same self-contained pattern as existing ones.

### When a shared `modules/` directory becomes appropriate
- Prefer the flat per-workload layout while workloads are one-of-a-kind and share little infrastructure shape.
- Introduce a small `infra/modules/` directory only after concrete duplication exists across at least two workloads (identical networking, bucket conventions, or compute pattern) — never preemptively in anticipation of reuse.
- Keep a shared module to the genuinely shared concern; do not collapse unrelated workload-specific resources into it.
- Shared modules follow the explicit authoring style above — a submodule is not a license to generate resources.

### Naming guidance
- Group `.tf` files by concern, not resource count — no file-per-resource.
- Use predictable names; keep module structure consistent across similar modules.
- If a concern file grows too large to navigate, split with still-specific names — `security_kms.tf`, `security_secrets.tf`.

### Local artifacts and git hygiene
- **Commit `.terraform.lock.hcl`.** The lock file pins provider versions for every machine and CI run; add the platforms teammates and CI use via `terraform providers lock -platform=<os_arch>`.
- Plan artifacts (`tfplan`, `*.tfplan`), `.terraform/` directories, and generated local execution artifacts stay gitignored — plan files are local, ephemeral, for review or apply only, never committed.

## Networking

- Never use a provider's default network or subnets for managed infrastructure — define the network explicitly: custom network, subnets, secondary ranges, firewall rules, NAT. Provider defaults ship permissive firewall rules (open SSH, RDP, ICMP from `0.0.0.0/0`) — not an acceptable posture.
- **(GCP)** Use a custom-mode VPC with explicitly defined subnets; never the default VPC.
- Existing resources on a default network? Call it out and propose a migration path rather than extending usage.

## Guardrails

### Safety
- Never run destructive actions without explicit confirmation; never `terraform apply` without explicit user approval of a reviewed plan.
- State the target environment in every summary and approval request; never assume a change applies to all environments.
- If a plan cannot be run, never guess the impact — say why.
- Treat deletion, replacement, and security-boundary changes as high risk; give production extra caution even for small changes.
- Never hide or collapse destructive or replacement actions in the plan summary.
- Never edit Terraform state directly unless the user explicitly requests a state operation and the risks are clearly explained.

### Scope control
- Keep changes scoped to the requested environment and outcome; keep environment boundaries strict.
- A shared-module change that affects multiple environments must say so explicitly; watch for accidental cross-environment edits it can cause.

### Secrets and sensitive data
- Never commit secrets, credentials, keys, tokens, certificates, or private data; never hardcode them in `.tf` or checked-in `.tfvars` files.
- Inject sensitive values via CI/CD environment variables, a remote secret manager, or secure runtime injection; use a gitignored local override file only when a local run needs the value and no injected path serves it.
- Mark every secret-bearing input `sensitive = true`; expose a sensitive output only when a consumer needs it, and say which.

## Out of scope by default

Do not perform these unless explicitly requested:
- broad architecture migrations
- provider or platform switches
- state or backend migrations
- CI policy changes
- cross-environment restructuring
- module redesign beyond what is needed for the task
