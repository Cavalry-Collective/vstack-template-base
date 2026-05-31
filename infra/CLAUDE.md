## Purpose
Agents working in this folder will typically do one of two things:
1. inspect and explain the current infrastructure, or
2. propose and implement scoped infrastructure changes.

## Core Principles
- Prefer the smallest change that solves the request.
- Keep changes scoped to the requested environment and outcome.
- Optimize for readability and straightforward rollback.
- Prefer stable, maintainable patterns over clever abstractions.
- Preserve existing repository conventions unless there is a strong reason to change them.
- Treat all infrastructure changes as potentially high impact until proven otherwise.
- Run Terraform commands from the target environment directory, never from the repository root.
- Do not assume a change applies to all environments.
- Always make the target environment explicit in summaries and approvals.

## Default Execution Mode
- At the start of each new chat, verify the active gcloud authentication context before making any changes.
- Run `gcloud config configurations list` outside the sandbox and show the available configurations to the user.
- Ask the user which configuration to use before running commands that depend on GCP credentials or project context.
- Do not assume the previously used gcloud configuration is correct.

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
6. before asking for approval, present the target environment, planned resource actions, and risk summary using the format defined in the Risk Review Checklist section below
7. ask for approval before `terraform apply`

Never run `terraform apply` without explicit user approval.

## Terraform Authoring Style
- Prefer explicit Terraform resource declarations over DRY abstractions when managing multiple infrastructure objects.
- Define each infrastructure object as its own individually named `resource` block by default.
- Do not use `for_each`, `count`, `dynamic` blocks, or `locals` collections to generate multiple resources unless the user explicitly requests that pattern or there is a clear repository convention requiring it.
- Favor repetition over abstraction when it improves readability, reviewability, importability, and rollback clarity.
- Do not use `lifecycle.ignore_changes` unless the diff is confirmed by the user to be noisy and intentionally acceptable.

## Importing Existing Resources

Importing existing infrastructure is a controlled migration workflow for bringing real infrastructure under Terraform management.

### Default approach
- Prefer importing existing resources instead of replacing them when the goal is to bring already-running infrastructure under Terraform.
- Avoid replacement of existing resources unless the user explicitly requests it or replacement is clearly safer than import.
- Treat replacement of existing infrastructure as higher risk by default because it may affect availability, data durability, naming continuity, external integrations, or rollback complexity.
- After import, Terraform becomes the source of truth for that resource.

### Scope and tool choice
- Prefer the smallest import scope that solves the task.
- Do not bulk-import an entire project, folder, or organization unless the user explicitly requests that scope.
- For small or targeted migrations, prefer Terraform import workflows tied to explicit destination `resource` blocks.
- For larger Google Cloud migrations, `gcloud beta resource-config bulk-export` may be used as a bootstrap tool to discover and generate initial Terraform for existing resources.

### Using Google Cloud bulk export
- Treat `gcloud beta resource-config bulk-export` output as migration scaffolding, not final repository-ready Terraform.
- Do not commit raw bulk-export output without review and cleanup.
- Normalize generated configuration into repository conventions before considering the migration complete.
- Check that the exported resource types are actually supported for export before relying on the generated output.
- Prefer using bulk export to accelerate discovery and drafting, then rewrite or reshape the result into explicit repository-managed Terraform.

### Authoring requirements after import
- Represent each real infrastructure object with its own individually named Terraform `resource` block unless the user explicitly requests a different pattern.
- Do not keep generated `for_each`, `count`, `dynamic` blocks, or `locals`-driven resource generation unless that pattern is explicitly requested or already established in that part of the repository.
- Prefer explicit naming, straightforward review diffs, and easy rollback over generated abstractions.
- Remove generated noise, provider-default churn, and repository-inconsistent structure before merging.
- Do not use `lifecycle.ignore_changes` to hide drift found during import.
- Only use `lifecycle.ignore_changes` if the specific diff is confirmed by the user to be noisy and intentionally acceptable to ignore.

### Required review before approval
- Identify the exact target environment and exact resources being imported.
- Confirm the import IDs and destination resource addresses are correct.
- Run `terraform plan` after import-related changes.
- Review all drift before approval.
- Explicitly call out additions, changes, replacements, deletions, IAM changes, networking changes, and any stateful resource risk.
- Do not apply imported configuration without explicit user approval.

### Repository expectations
- Imported resources must be reshaped to match this repository’s file layout, naming, and guardrails.
- Generated code is a starting point only.
- Final committed Terraform should read like intentionally authored infrastructure, not tool output.

## Risk Review Checklist
Before asking for approval to apply, present the change in this format:

### Plan Summary
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

### Risk Checklist

#### Security
State either:
- `no material security impact`

or describe relevant impact, such as:
- public exposure changes
- IAM or permission changes
- network policy changes
- secrets or encryption impact

#### Availability
State either:
- `no expected availability impact`

or describe relevant impact, such as:
- downtime risk
- restart or replacement risk
- dependency or ordering risk
- load balancer, DNS, or failover impact

#### Data durability
State either:
- `no expected data durability impact`

or describe relevant impact, such as:
- risk to databases, buckets, disks, queues, or stateful services
- deletion or recreation of persistent resources
- backup, retention, or recovery impact

#### Cost
State either:
- `no material cost impact`

or describe relevant impact, such as:
- likely spend increase or decrease
- sizing, replication, retention, or traffic-related cost changes

## Standard Repository Layout
This repository is organized **per workload**. Each top-level directory is a self-contained Terraform root module that maps to a single project.

```
/
├── AGENTS.md
├── README.md
├── <workload-a>/
│   ├── backend.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── networking.tf
│   ├── compute.tf
│   ├── storage.tf
│   ├── databases.tf
│   ├── iam.tf
│   ├── observability.tf
│   └── ... (other concern-grouped .tf files)
├── <workload-b>/
└── .github/
    └── workflows/
```

### Workload directories
- Each workload directory is a Terraform root module with its own `backend.tf` and `terraform.tfvars`.
- Run all Terraform commands from inside the target workload directory, never from the repository root.
- Do not introduce cross-workload references or shared local modules without explicit approval — workloads are intentionally independent.
- New workloads should follow the same self-contained pattern as existing ones in the repository.

### When a shared `modules/` directory becomes appropriate
- The flat per-workload layout is preferred while workloads are one-of-a-kind and share little or no infrastructure shape.
- If two or more workloads genuinely need the same shape (for example identical networking, identical bucket conventions, the same compute pattern across environments), a small `modules/` directory at the repository root may be introduced and called by the affected workload root modules.
- Do not preemptively introduce shared modules in anticipation of future reuse. Wait until concrete duplication exists across at least two workloads.
- When introducing a shared module, keep it focused on the genuinely shared concern only. Do not collapse unrelated workload-specific resources into it.
- Shared modules must still follow the explicit, repetition-friendly authoring style in this document — submodules are not a license to use `for_each`/`count`/`dynamic` to generate resources.

### AGENTS.md
- Store agent instructions in `AGENTS.md` at the repository root.
- Keep this document aligned with actual repository conventions and workflows.

### Naming guidance
- Prefer grouping by concern, not by resource count.
- Avoid excessive file fragmentation.
- Use predictable names that make navigation easy.
- Keep module structure consistent across similar modules.
- If a category becomes too large, split it further with still-specific names, for example:
  - security_kms.tf
  - security_secrets.tf

### Local artifacts and git hygiene
- Always keep Terraform plan artifacts such as `tfplan` and `*.tfplan` gitignored and out of version control.
- Treat plan files as local ephemeral artifacts for review or apply only.
- Do not commit generated local execution artifacts created during planning, validation, or debugging.

## Infrastructure Conventions
Opinions on how to set up specific infrastructure concerns. These guide authoring choices when adding or changing resources of these types.

### Networking
- Do not use the default VPC or default subnets for managed infrastructure.
- Prefer a custom-mode VPC with explicitly defined subnets, secondary ranges, firewall rules, and NAT.
- Default VPCs typically come with auto-created subnets and permissive default firewall rules (broadly open SSH, RDP, ICMP from `0.0.0.0/0`) that are not an acceptable security posture.
- If existing resources are found on the default VPC, call it out and propose a migration path rather than extending usage.

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

### Secrets and Sensitive Data
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

## Out of Scope by Default
Do not perform these unless explicitly requested:
- broad architecture migrations
- provider or platform switches
- state or backend migrations
- CI policy changes
- cross-environment restructuring
- module redesign beyond what is needed for the task
