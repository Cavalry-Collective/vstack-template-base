# cavalry-template-spa

**An opinionated template for spinning up production-ready, full-stack projects — fast, and without re-litigating a single engineering decision.**

Every new Cavalry Collective project starts here. Instantiate it, run the setup checklist once, and ship features the same day — with the architecture, quality gates, and conventions of a mature codebase already in force.

## Why this exists

Most templates give you scaffolding: generated code that's stale a week after it's cut. This template ships something more durable — **contracts**. A small set of binding documents encodes how software is built here: a backend onion with a pure domain at the centre, a layered frontend on a design-token keystone, reversible migrations, spec-first slices, and a Definition of Done where *verified means observed, not inferred*.

The contracts are written for humans **and** AI agents. An agent working in this repo auto-loads the contract for whatever area it touches, so the hundredth feature is built to the same standard as the first. That's the entire bet: **the biggest lever on project quality is an opinionated approach, stated where the work happens.**

Five commitments shape everything:

1. **Opinionated where it matters, agnostic where it doesn't.** The base contracts pin the *shape* of the system — rings, layers, envelopes, gates — never the framework. A **stack pack** (`stacks/`) binds them to one concrete stack through an explicit conflict register. No silent contradictions.
2. **Simplicity first.** The minimum code that solves the problem; every abstraction defeats the simpler alternative on the record.
3. **Quality is a gate, not a vibe.** Nothing is done until run and observed: four data states exercised, endpoints hit, migrations proven, screens checked at 320 px.
4. **Spec-first, independently shippable slices.** Trunk stays releasable; history stays linear; P1 stories alone form a viable MVP.
5. **Instructions over machinery.** No generators, hooks, or scaffolding — precise instructions in the files agents and humans already read. What you see is the whole mechanism.

## Getting started

1. Click **Use this template** on GitHub and clone your new repo.
2. Work through **[`docs/getting-started.md`](docs/getting-started.md)** once — pick a stack pack (or stay agnostic), pick your add-ons, fill the toolchain placeholders, confirm the design guide.
3. Build, spec-first: write a spec under `specs/`, then implement. The contracts do the rest.

There is nothing to install and no generator to run — the template is documentation-shaped on purpose.

## Repository layout

| Path | What it is |
|---|---|
| `CLAUDE.md` | **Root contract** — precedence, principles, workflow, Definition of Done |
| `docs/` | Guides: onboarding, architecture, structure, workflows, testing, config — start at [`docs/README.md`](docs/README.md) |
| `apps/backend/` | API server — onion architecture; contract in `apps/backend/CLAUDE.md` |
| `apps/frontend/` | Web app — layered store/services/pages/components; contract in `apps/frontend/CLAUDE.md` |
| `db/` | Migrations + seed/reset scripts; contract in `db/CLAUDE.md` |
| `infra/` | Terraform, one root module per workload; contract in `infra/CLAUDE.md` |
| `design/` | Mockups + the **design guide** (`design-guide.html` + `tokens.css`) — the visual keystone, confirmed before UI work; reference only |
| `specs/` | Feature specs, written before implementation (Spec Kit adopted) |
| `stacks/` | Optional **stack packs** — one chosen at instantiation, the rest deleted ([`stacks/README.md`](stacks/README.md)) |
| `add-ons/` | Optional **capability add-ons** — test mode, OTP login, LLM calls ([`add-ons/README.md`](add-ons/README.md)) |
| `.github/workflows/` | CI + deploy stubs — every quality gate, waiting for your toolchain commands |
| `project.code-workspace` | VS Code workspace (keeps agent worktrees out of search and watchers) |

## What you choose per project

The base is framework-agnostic on purpose: frontend framework, backend HTTP layer, package manager, database client, cloud provider are all yours to pick — either by adopting a vetted **stack pack** under `stacks/` (fast path, with copy-paste commands and resolved conflicts) or by filling in the toolchain yourself. The contracts tell you where things go and how to structure them, not which library to use.

**The end state:** a template you can instantiate in an afternoon and trust for years — every project born production-ready, every convention already decided, every agent already briefed.
