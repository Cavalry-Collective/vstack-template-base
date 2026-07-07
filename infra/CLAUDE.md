# Infra

The infrastructure contract — read before touching anything under `infra/`. Repo-wide rules (principles, workflow, cross-app standards) live in the root `CLAUDE.md`; this file governs the Terraform under `infra/`. Agent instructions for this folder are here; there is no separate AGENTS.md. **If a stack pack is adopted (a single directory kept under `stacks/`) and it ships an `infra.md` appendix, also read that before working here** — it adds the concrete bindings, and its conflict register resolves any disagreement with this file, for that stack only.

> **This template's blessed cloud is GCP.** Sections marked **(GCP)** apply when using it; on AWS/Azure follow the equivalent context, auth, and discovery tooling for that provider.

## Purpose
Agents working in this folder will typically do one of two things:
1. inspect and explain the current infrastructure, or
2. propose and implement scoped infrastructure changes.

## Core principles
- Prefer the smallest change that solves the request.
- Keep changes scoped to the requested environment and outcome.
- Optimize for readability and straightforward rollback.
- Prefer stable, maintainable patterns over clever abstractions.
- Preserve existing repository conventions unless there is a strong reason to change them.
- Treat all infrastructure changes as potentially high impact until proven otherwise.
- Run Terraform commands from inside the target workload directory (`infra/<workload>/`), never from `infra/` itself or the git root.
- Do not assume a change applies to all environments.
- Always make the target environment explicit in summaries and approvals.
- **Set up observability from day 1** — metrics, logs, and (for user-facing apps) product analytics, retained and queryable — as part of bringing a workload online, not deferred. Where your platform's IaC owns observability, give it its own concern file; the platform-specific wiring (log drains, retention, dashboards) lives in the active stack pack — which may own none of it in Terraform (e.g. an integration-managed drain).

## Default execution mode
- At the start of each new chat, verify the active cloud auth/credential and project context before making any changes.
- Run the provider's context command and show the available contexts to the user **(GCP:** `gcloud config configurations list`**)** — it needs real cloud credentials, so run it where they are available, not in a restricted shell.
- Ask the user which account/project/configuration to use before running commands that depend on cloud credentials or project context.
- Do not assume the previously used context is correct.

### Read-only workflows
For read-only and non-destructive tasks, continue automatically until a meaningful stopping point or a clear approval boundary is reached.

Read-only actions include:
- repository inspection
- code search
- dependency and reference tracing
- `terraform fmt -check`
- `terraform validate`
- `terraform plan`
- diff generation

Do not stop to ask for confirmation between consecutive read-only steps.

### Mutation workflows
For any change that could modify infrastructure or configuration behavior, follow this sequence unless the user explicitly asks otherwise:
1. understand the target environment and requested outcome
2. inspect the relevant module and environment configuration
3. make the smallest reasonable change
4. run formatting and validation
5. run `terraform plan`
6. before asking for approval, present the target environment, planned resource actions, and risk summary using the format defined in the *Risk review checklist* section below
7. ask for approval before `terraform apply` (see *Guardrails → Safety* — the approval rule lives there)

## Terraform authoring style
- Prefer explicit Terraform resource declarations over DRY abstractions when managing multiple infrastructure objects.
- Define each infrastructure object as its own individually named `resource` block by default.
- Do not use `for_each`, `count`, `dynamic` blocks, or `locals` collections to generate multiple resources unless the user explicitly requests that pattern or there is a clear repository convention requiring it.
- Favor repetition over abstraction when it improves readability, reviewability, importability, and rollback clarity.
- Do not use `lifecycle.ignore_changes` unless the diff is confirmed by the user to be noisy and intentionally acceptable.

## Importing existing resources

A controlled migration workflow for bringing already-running infrastructure under Terraform management.

- **Prefer import over replacement.** Replacing existing infrastructure risks availability, data durability, naming continuity, external integrations, and rollback complexity — replace only when the user explicitly requests it or it is clearly safer than import. After import, Terraform is the source of truth for that resource.
- **Smallest scope that solves the task.** Never bulk-import an entire project, folder, or organization unless explicitly requested. Small migrations import into explicit destination `resource` blocks; larger ones may bootstrap drafts with a provider discovery/export tool **(GCP:** `gcloud beta resource-config bulk-export`**; other providers have analogous tooling)**.
- **Generated output is scaffolding, never repository-ready Terraform.** Reshape it to this folder's conventions before merging: one individually named `resource` block per real object; no generated `for_each`/`count`/`dynamic`/`locals` collections; no `lifecycle.ignore_changes` to hide drift; provider-default churn removed. Final committed Terraform reads like intentionally authored infrastructure, not tool output.
- **Before approval:** identify the exact environment and resources, confirm import IDs and destination addresses, run `terraform plan`, review all drift, and explicitly call out additions, changes, replacements, deletions, IAM changes, networking changes, and any stateful-resource risk.

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
The `infra/` folder is organized **per workload**. Each subdirectory of `infra/` is a self-contained Terraform root module that maps to a single project.

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
- Each workload directory is a Terraform root module with its own `backend.tf` and `terraform.tfvars`.
- **Environments are separate root modules.** A workload with more than one environment splits per environment (`infra/<workload>/<env>/`), each with its own backend and state — never one state file spanning environments, and no Terraform workspaces for prod/non-prod separation. A single-environment workload stays flat (`infra/<workload>/`).
- Do not introduce cross-workload references or shared local modules without explicit approval — workloads are intentionally independent.
- New workloads should follow the same self-contained pattern as existing ones under `infra/`.

### When a shared `modules/` directory becomes appropriate
- The flat per-workload layout is preferred while workloads are one-of-a-kind and share little or no infrastructure shape.
- If two or more workloads genuinely need the same shape (for example identical networking, identical bucket conventions, the same compute pattern across environments), a small `infra/modules/` directory may be introduced and called by the affected workload root modules.
- Do not preemptively introduce shared modules in anticipation of future reuse. Wait until concrete duplication exists across at least two workloads.
- When introducing a shared module, keep it focused on the genuinely shared concern only. Do not collapse unrelated workload-specific resources into it.
- Shared modules must still follow the explicit, repetition-friendly authoring style in this document — submodules are not a license to use `for_each`/`count`/`dynamic` to generate resources.

### Naming guidance
- Prefer grouping by concern, not by resource count.
- Avoid excessive file fragmentation.
- Use predictable names that make navigation easy.
- Keep module structure consistent across similar modules.
- If a category becomes too large, split it further with still-specific names, for example:
  - security_kms.tf
  - security_secrets.tf

### Local artifacts and git hygiene
- **Remote state from day 1.** Every root module uses a remote, access-controlled state backend with locking — local state only for first bootstrap. State can hold secrets and full resource detail: treat the state file as a credential; never commit it.
- **Commit `.terraform.lock.hcl`.** The dependency lock file pins provider versions for every machine and CI run; use `terraform providers lock -platform=<os_arch>` to add the platforms teammates and CI use. Only `.terraform/` directories and plan artifacts stay out of version control.
- Always keep Terraform plan artifacts such as `tfplan` and `*.tfplan` gitignored and out of version control.
- Treat plan files as local ephemeral artifacts for review or apply only.
- Do not commit generated local execution artifacts created during planning, validation, or debugging.

## Infrastructure conventions
Opinions on how to set up specific infrastructure concerns. These guide authoring choices when adding or changing resources of these types.

### Networking (GCP)
- Do not use the default VPC or default subnets for managed infrastructure.
- Prefer a custom-mode VPC with explicitly defined subnets, secondary ranges, firewall rules, and NAT.
- Default VPCs typically come with auto-created subnets and permissive default firewall rules (broadly open SSH, RDP, ICMP from `0.0.0.0/0`) that are not an acceptable security posture.
- If existing resources are found on the default VPC, call it out and propose a migration path rather than extending usage.
- On AWS/Azure the same intent holds: define the network, subnets, and security-group/firewall rules explicitly; never rely on a provider's default network or default-open ingress.

## Verifying a change

The root's "verified means observed" gate, applied to infrastructure:

- Before apply: the plan was presented in the *Risk review checklist* format and approved.
- After apply: the apply output matches the approved plan — no unexpected creates, changes, or destroys.
- Then observe the outcome — the endpoint responds, the job runs, the log or metric appears — and state what you observed, not just that the apply succeeded.

## Guardrails

### Safety
- Never run destructive actions without explicit confirmation.
- Never run `terraform apply` without explicit user approval.
- Treat deletion, replacement, and security boundary changes as high risk.
- Treat production as requiring extra caution, even for apparently small changes.
- Always state the target environment before asking for approval.
- Never hide or collapse destructive or replacement actions in the plan summary.
- Never edit or manipulate Terraform state directly unless the user explicitly requests a state operation and the risks are clearly explained.

### Scope control
- Do only what the request asks for.
- Avoid unrelated refactors, renames, and file moves.
- Call out assumptions when context is ambiguous.
- Keep environment boundaries strict.
- Avoid accidental cross-environment edits caused by shared module changes.
- If a shared module change affects multiple environments, state that explicitly.

### Plans and applies
- Never apply without a reviewed plan.
- Never guess about infrastructure impact when a plan cannot be run.
- If a plan cannot be run, explain why clearly.
- Always state the environment being planned or applied.

### Secrets and sensitive data
- Never commit secrets, credentials, keys, tokens, certificates, or private data.
- Do not hardcode secrets in `.tf` files or checked-in `.tfvars` files.
- Prefer injecting sensitive values through:
  - CI/CD environment variables
  - remote secret managers
  - secure variable injection at runtime
  - ignored local override files only when necessary

### Sensitive variables
- Mark Terraform input variables as `sensitive = true` where appropriate.
- Avoid exposing sensitive outputs unless absolutely necessary.

## Out of scope by default
Do not perform these unless explicitly requested:
- broad architecture migrations
- provider or platform switches
- state or backend migrations
- CI policy changes
- cross-environment restructuring
- module redesign beyond what is needed for the task
