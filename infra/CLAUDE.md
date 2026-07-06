# Infrastructure contract

Binding for the Terraform under `infra/`. Read with it: the root `CLAUDE.md`, and — if the adopted stack pack ships an `infra.md` appendix — that appendix, whose conflict register wins over this file for that stack only. Agent instructions for this folder live here; there is no separate AGENTS.md.

> **This template's blessed cloud is GCP.** Sections marked **(GCP)** apply when using it; on AWS/Azure follow that provider's equivalent context, auth, and discovery tooling.

Work here is one of two things: inspecting/explaining current infrastructure, or proposing and implementing scoped changes. Treat every change as potentially high impact until proven otherwise.

## Never violate

1. **Never `terraform apply` without explicit user approval** of a reviewed plan, presented in the *Risk review checklist* format.
2. **Never run destructive actions without explicit confirmation;** never hide or collapse destructive/replacement actions in a plan summary.
3. **Always state the target environment** — before planning, before approval, in every summary. Never assume a change applies to all environments.
4. **Never commit secrets** — not in `.tf`, not in checked-in `.tfvars`, not in state (treat state as a credential).
5. **Never edit Terraform state directly** unless the user explicitly requests a state operation with risks explained.
6. **Run Terraform from inside the target workload directory** (`infra/<workload>/`), never from `infra/` or the git root.

## Core principles

- Smallest change that solves the request; scoped to the requested environment and outcome.
- Optimize for readability and straightforward rollback; stable patterns over clever abstractions.
- Preserve existing repository conventions unless there is a strong reason not to.
- **Runtime config crosses to the apps through the environment:** a value an app needs (a bucket name, a queue URL) is exposed as a non-sensitive Terraform `output`, set as a platform env var, and lands in the app's validated config schema and `.env.example` in the same change (root contract → *Configuration*).
- **Observability from day 1** — metrics, logs, and (for user-facing apps) product analytics, retained and queryable, as part of bringing a workload online. Where the platform's IaC owns observability, give it its own concern file; platform-specific wiring lives in the active stack pack (which may own none of it in Terraform).

## Execution mode

**At the start of each new session, verify the cloud auth/credential and project context before any changes.** Run the provider's context command **(GCP:** `gcloud config configurations list`**)**, show the available contexts, and ask which account/project to use before running anything that depends on credentials. Never assume the previously used context.

**Read-only work** (repo inspection, code search, dependency tracing, `terraform fmt -check`, `validate`, `plan`, diff generation): continue automatically to a meaningful stopping point — don't pause for confirmation between read-only steps.

**Mutation work** — any change that could modify infrastructure or configuration behaviour:

1. Understand the target environment and requested outcome.
2. Inspect the relevant module and environment configuration.
3. Make the smallest reasonable change.
4. `terraform fmt` + `validate`.
5. `terraform plan`.
6. Present the plan in the *Risk review checklist* format.
7. Ask for approval before `apply` (*Never violate* #1).

## Terraform authoring style

- **Explicit over DRY.** Each infrastructure object is its own individually named `resource` block by default. No `for_each`, `count`, `dynamic` blocks, or `locals` collections to generate multiple resources unless the user explicitly requests it or a clear repository convention requires it. Repetition that improves readability, reviewability, importability, and rollback clarity is the point, not a smell.
- No `lifecycle.ignore_changes` unless the user confirms the diff is noisy and intentionally acceptable.

## Importing existing resources

Bringing already-running infrastructure under Terraform, as a controlled migration:

- **Prefer import over replacement** — replacement risks availability, data durability, naming continuity, and integrations; replace only when explicitly requested or clearly safer. After import, Terraform is the source of truth for that resource.
- **Smallest scope that solves the task.** Never bulk-import a project/folder/org unless asked. Small migrations import into explicit destination `resource` blocks; larger ones may bootstrap drafts with a discovery/export tool **(GCP:** `gcloud beta resource-config bulk-export`**)**.
- **Generated output is scaffolding, never repository-ready.** Reshape to this folder's conventions before merging: individually named resource blocks, no generated loops, no `ignore_changes` hiding drift, provider-default churn removed. Committed Terraform reads as intentionally authored.
- **Before approval:** exact environment and resources identified, import IDs and destination addresses confirmed, `terraform plan` run, all drift reviewed, with additions/changes/replacements/deletions, IAM, networking, and stateful-resource risk called out explicitly.

## Risk review checklist

Present every mutation for approval in this format:

### Plan summary
- Environment: `<environment name>`

### Planned resource actions
- To add / To change / To replace / To destroy — `<resource address>` under each (skip empty sections).

### Risk checklist

Per dimension, state `no material impact` or describe it:

- **Security** — public exposure, IAM/permissions, network policy, secrets/encryption.
- **Availability** — downtime, restart/replacement, dependency ordering, LB/DNS/failover.
- **Data durability** — databases, buckets, disks, queues; deletion/recreation of persistent resources; backup/retention/recovery.
- **Cost** — spend direction; sizing, replication, retention, traffic.

## Standard layout

`infra/` is organised **per workload**: each subdirectory is a self-contained Terraform root module mapping to a single project.

```
infra/
├── <workload-a>/
│   ├── backend.tf | providers.tf | versions.tf | variables.tf | terraform.tfvars
│   └── ... concern-grouped .tf files (networking, compute, storage, databases, iam, observability)
└── <workload-b>/
```

- **Environments are separate root modules** — a multi-environment workload splits per environment (`infra/<workload>/<env>/`), each with its own backend and state. Never one state file spanning environments; no Terraform workspaces for prod/non-prod separation. Single-environment workloads stay flat.
- **No cross-workload references or shared local modules without explicit approval** — workloads are intentionally independent. A shared `infra/modules/` appears only when two or more workloads genuinely duplicate a shape; never preemptively, always scoped to the genuinely shared concern, and still under the explicit authoring style above.
- **Naming:** group by concern, not resource count; avoid fragmentation; predictable names. A too-large category splits with still-specific names (`security_kms.tf`, `security_secrets.tf`).

## Local artifacts and git hygiene

- **Remote state from day 1:** every root module uses a remote, access-controlled backend with locking — local state only for first bootstrap. State can hold secrets and full resource detail: treat it as a credential; never commit it.
- **Commit `.terraform.lock.hcl`** (add teammates'/CI platforms via `terraform providers lock -platform=<os_arch>`). Only `.terraform/` directories and plan artifacts stay out of version control.
- Plan files (`tfplan`, `*.tfplan`) are local ephemeral artifacts for review or apply — always gitignored, like every generated execution artifact.

## Infrastructure conventions

### Networking (GCP)

- Never the default VPC or default subnets for managed infrastructure — their auto-created subnets and permissive default firewall rules (broadly open SSH/RDP/ICMP from `0.0.0.0/0`) are not an acceptable posture. Prefer a custom-mode VPC with explicit subnets, secondary ranges, firewall rules, and NAT.
- Find existing resources on a default VPC → call it out and propose a migration path rather than extending usage.
- Same intent on AWS/Azure: define network, subnets, and security rules explicitly; never rely on a provider's default network or default-open ingress.

## Out of scope by default

Only on explicit request: broad architecture migrations, provider/platform switches, state or backend migrations, CI policy changes, cross-environment restructuring, module redesign beyond the task. Avoid unrelated refactors, renames, and moves; call out assumptions when context is ambiguous; if a shared-module change affects multiple environments, say so explicitly.

## Definition of done — verify a change

- [ ] Before apply: plan presented in the *Risk review checklist* format and approved, environment named.
- [ ] After apply: apply output matches the approved plan — no unexpected creates, changes, or destroys.
- [ ] Outcome observed — the endpoint responds, the job runs, the log/metric appears — and stated, not just "apply succeeded". If a plan cannot be run, say why; never guess at impact.
