# Architecture

How the system fits together. Normative detail lives in the area contracts; this is the map.

## The shape

```
 Browser ──► apps/frontend (SPA / web app)          design/  ← visual keystone (tokens + guide)
                │  services/ (all network access)
                ▼  one error envelope, correlation id on every response
 apps/backend (API server — the onion)
                │  Controller → Service → Domain ◄─ Repo (ports point inward)
                ▼
 Database  ◄── db/migrations (reversible, ordered)     infra/ (Terraform, per workload)
```

Two apps, one database, one infrastructure area — bound together by a handful of cross-app conventions rather than shared code.

## Backend — an onion

`apps/backend` is four rings with dependencies pointing strictly inward: **Domain** (pure business rules, defines ports; no I/O, no framework) ← **Service** (one use case each; owns the transaction boundary) ← **Repo** (adapters implementing the ports: database repositories, external clients, each with a mapper) and **Controller** (REST edge: validation, auth guards, DTOs, the single error-mapping site). Code is organised **by feature module first, rings within**, so a feature can be understood and removed as a unit. Cross-cutting concerns (auth, logging, transactions, error mapping) are decorators/aspects declared once — never sprinkled through handlers.

Why: the expensive parts of a backend — business rules — end up in the one place that's cheap to test and impossible for a framework migration to disturb.

Contract: [`apps/backend/CLAUDE.md`](../apps/backend/CLAUDE.md).

## Frontend — layers × feature slices

`apps/frontend` is organised along two axes that never blur: horizontal **layers** (store → services → pages → components) and vertical **feature slices** (store slice + service + feature organisms). Components follow **atomic design** over a headless UI foundation: atoms and molecules are generic and global; organisms carry business meaning and group by feature. Every data-backed screen handles the same four states — loading / error / empty / success. All visual values resolve to design tokens seeded from `design/tokens.css`; the design guide is confirmed before the first screen is built.

Why: consistency comes from reuse, not per-screen discipline — one layout, one token source, one primitive per widget.

Contract: [`apps/frontend/CLAUDE.md`](../apps/frontend/CLAUDE.md).

## The seam between them

The backend's **endpoint contract** is the single source of truth for shapes and status codes; the frontend's services layer mirrors it and never invents its own. Three conventions bind the two apps:

- **One error envelope** (`{ error: { code, message, correlationId } }`) mapped in exactly one backend site; clients branch on `code`, never parse `message`.
- **Correlation id on every response** (`x-correlation-id`), surfaced unobtrusively in error UI and attached to telemetry — a support report can always be traced to a request.
- **One auth interceptor** on the frontend handles 401/403 centrally; sessions default to HTTP-only cookies.

## Database

Schema changes are **ordered, reversible migrations** under `db/migrations/`, never DDL from application code. Destructive changes go expand → migrate → contract so a rollback never loses data. Seed/reset scripts are idempotent and non-production-only.

Contract: [`db/CLAUDE.md`](../db/CLAUDE.md).

## Infrastructure

Terraform under `infra/`, one self-contained root module per workload, environments split into separate root modules with separate state. Authoring favours explicit, repetitive resource blocks over clever DRY generation — readability, reviewability, and rollback beat abstraction here. Every apply is preceded by a reviewed plan and an explicit risk checklist.

Contract: [`infra/CLAUDE.md`](../infra/CLAUDE.md).

## The variability model

The base contracts are deliberately framework-agnostic; two mechanisms specialise a project without forking the template:

- **Stack packs** (`stacks/`) bind the contracts to one concrete stack. A pack only *adds* bindings and resolves conflicts through an explicit **conflict register** — the audit surface for every place the stack overrides the base. Exactly one pack is adopted; adoption = being the only directory left.
- **Add-ons** (`add-ons/`) opt a project into recurring cross-cutting capabilities (test mode, OTP auth, LLM calls), stated agnostically; the active pack supplies their concrete bindings. Adoption = keeping the directory.

Precedence when documents disagree: pack conflict register → area contract → add-on README → root contract (root `CLAUDE.md` → *Instruction precedence*).
