# Post-campaign learnings: prod ops, observability, security, staging previews, atomic design

## Goal

Fold the operational and frontend lessons the shipped **PML BMW** campaign taught *after* the `stacks/vercel/` pack was written back into the template, so the next project doesn't re-learn them — the stack itself is already abstracted in that pack, so this captures only the **delta** (prod-migration/release discipline, observability + analytics, three security patterns, a from-day-1 staging environment, and an atomic-design frontend restructure). It deliberately does **not** re-extract anything the base already covers well (backend logging discipline, migration hygiene, per-worktree databases, versioning).

## Decisions (binding, user-confirmed)

| Decision | Choice |
|---|---|
| Placement principle | Agnostic rules go in the base `CLAUDE.md` / `apps/*` / `db` / `infra`; stack-specifics go in `stacks/vercel/*` appendices (additions-only, no restated base). The base/binding split is preserved. |
| Prod migrations | Deploys **don't** run migrations → a manual `DATABASE_URL`-override runbook, run **before** the push that needs it; releases are **expand-first / backward-compatible** (migrate → push) because a push deploys API + frontend together against a strict config contract. |
| Observability | Bringing a Vercel project online includes Observability **on** + an **off-platform log drain** — and the drain is **integration-owned (marketplace), NOT Terraform** (a `vercel_log_drain` resource creates a *duplicate*). Plus **Vercel Web Analytics + Speed Insights** wired in from day 1. |
| Security | HTTP security headers + **CSP** (ship report-only → promote to enforcing), **SSRF guard** for any user-configured outbound URL, **write-only secret** round-trip for admin-managed secrets — agnostic in the base, bound concretely (`@fastify/helmet`, `next.config` headers) in the vercel pack. |
| Preview env | **Persistent `develop` staging branch + dedicated long-lived Neon branch** (chosen over per-PR ephemeral previews), made a **Day-1 default** with its migration discipline. |
| Atomic design | **Full restructure** to `components/{atoms,molecules,organisms,templates}/` (+ `pages` = the route layer). **Atoms & molecules grouped by *type* (global, no feature dimension); organisms grouped by *feature*.** Crossover rule = *business meaning* (atom/molecule speaks no domain vocabulary; organism does — the same line the old `ui/` vs `<feature>/` split drew). Plus an anti-feature-atom guardrail and a **DRY reuse gate**. |
| Deploy gotchas | Not included — the commit-author gate doesn't apply (we deploy as team members), and stale-cache troubleshooting was dropped as noise. |

## User stories

### S1 (P1) — production migration & release ordering

`stacks/vercel/db.md` gains a **Production (Neon) migration runbook**: deploys don't run migrations, so migrate prod manually with `DATABASE_URL="<neon-prod>" pnpm migrate` (a shell-set value wins over `--env-file`) **before** the push that needs it — confirm first, then verify `pgmigrations` and the affected tables. `stacks/vercel/infra.md`'s deploy seam gains a **release-ordering rule**: a push deploys API + frontend together against a strict (Zod) config contract, so schema/config changes ship **expand-first / backward-compatible** — migrate prod, *then* push; never a field the paired deploy breaks on. It cross-links the base `db/CLAUDE.md` expand→migrate→contract rule up from the schema level to the release / API-contract level.

- **AC1:** from `db.md` alone an agent can migrate prod safely (env override, before-push timing, post-check) with no invented step. *Verify: read the runbook; it is self-contained.*
- **AC2:** the release-ordering rule names *why* (paired deploy + strict config contract) and the concrete order. *Verify: read the infra.md deploy seam.*

### S2 (P1) — observability, log drains & Vercel analytics

`stacks/vercel/infra.md` gains an **Observability** section: going live includes Vercel Observability enabled + an **off-platform log drain**, with the load-bearing caveat that the drain is **integration-owned (marketplace, e.g. Sentry), NOT a Terraform `vercel_log_drain` resource** (managing it in TF creates a second, duplicate drain) — plus a one-paragraph "how to query request-logs when prod breaks" pointer. `stacks/vercel/frontend.md` wires **`@vercel/analytics` (Web Analytics)** and **`@vercel/speed-insights` (Core Web Vitals)** into the App Router root layout. `infra/CLAUDE.md` (base, agnostic) elevates "observability + off-platform log retention + product analytics" to a **go-live checklist** line.

- **AC1:** infra.md states the integration-owned-not-Terraform caveat as a concrete DON'T with the duplicate-drain reason. *Verify: read the section.*
- **AC2:** frontend.md names both analytics packages and where they mount. *Verify: read the section.*

### S3 (P1) — security-hardening patterns

`apps/backend/CLAUDE.md` **Security baseline** (agnostic) gains three rules: **(a)** set HTTP security headers including a **CSP**, shipped **report-only** then promoted to enforcing; **(b)** an **SSRF guard** for any user-configured outbound URL — public **https** only, rejecting loopback / private / link-local / cloud-metadata literals; **(c)** a **write-only secret round-trip** for admin-managed secrets — mask on GET (+ a `…Set` flag), preserve on a blank PUT. `apps/frontend/CLAUDE.md`'s Security baseline gains the SPA CSP / security-headers counterpart. `stacks/vercel/backend.md` + `frontend.md` add the concrete bindings — **`@fastify/helmet`** and **`next.config` `headers()`** with a report-only CSP allow-listing the embed/payment origins the project actually uses.

- **AC1:** each of the three backend patterns is a checkable rule naming the failure it prevents (not a vibe). *Verify: read the backend Security baseline.*
- **AC2:** the vercel bindings name the concrete mechanism and stay additions-only. *Verify: dovetail read against the base file — no restated base content.*

### S4 (P1) — preview deployments from day 1 (persistent `develop` + Neon)

`stacks/vercel/infra.md` gains a **Staging (`develop`)** section: both `vercel_project` resources get a `develop`-branch preview environment; a **dedicated long-lived Neon branch** (copy-on-write fork of prod) is Terraform-authored; the web preview proxies to the API preview. `stacks/vercel/db.md` gains the **develop migration discipline** — migrate the develop Neon branch before pushing `develop` (same runbook as prod) — plus the gotcha that **`vercel env pull --git-branch` does not export the branch-scoped `DATABASE_URL`** (pull it from Terraform state / the Neon console instead). `README.md`'s **Day-1 checklist** gains a "stand up `develop` staging + its Neon branch" step.

- **AC1:** infra.md describes the two-project `develop` env + dedicated Neon branch as Terraform-authored. *Verify: read the section.*
- **AC2:** db.md carries both the develop runbook and the env-pull gotcha. *Verify: read the section.*
- **AC3:** the Day-1 checklist references standing up staging. *Verify: read README.*

### S5 (P1) — atomic design + DRY gate (frontend restructure)

`apps/frontend/CLAUDE.md` (agnostic): the project-structure diagram and the "Shared primitives — three tiers" section are rewritten to **atomic design** — `components/{atoms,molecules,organisms,templates}/` with `pages` = the route layer. Preserved: the "never skip the headless foundation" principle (re-expressed — the foundation library sits *under* atoms), the three-tier token source, "never build one-offs." Added/made explicit: **atoms & molecules grouped by type (global, no feature dimension); organisms grouped by feature**; the **crossover rule** — an atom/molecule speaks no domain vocabulary, an organism does (the same semantic line the old `components/ui/` vs `components/<feature>/` split drew); the **anti-feature-atom guardrail** (a "feature-specific atom/molecule" is a fork — either it's generic → global `molecules/`, or it carries business meaning → it's an organism); and a **DRY reuse gate** (reuse-first: search for an existing atom/molecule before building one; no ad-hoc/one-off components; a periodic dedup audit in the spirit of the i18n key-parity check). It notes the mirror to the backend's `shared/` + `modules/<feature>/` shape, and that the vertical feature slice spans `store/<feature>` + `services/<feature>` + `components/organisms/<feature>`. `stacks/vercel/frontend.md`'s base-`src/`-shape → App-Router folder-mapping table updates to the atomic vocabulary. Root `CLAUDE.md`'s frontend blurb stays a generic pointer — the atomic detail lives only in the frontend file. The sibling `nextjs-nestjs-postgres` pack's frontend appendix is updated to the same atomic vocabulary so both packs stay consistent with the base.

- **AC1:** the frontend file's structure + shared-primitives sections read as one coherent atomic model — no leftover `components/ui`/`<feature>` references — and the type-vs-feature grouping, crossover rule, and guardrail are all stated. *Verify: consistency read of the final file.*
- **AC2:** no other file still points at the old `components/ui/` / `components/<feature>/` names except where intentionally historical. *Verify: `grep -rn "components/ui\|components/<feature>"` across the repo; only intended references remain.*
- **AC3:** the DRY gate is a checkable rule (names the reuse-first step and the dedup audit), not an aspiration. *Verify: read the section.*

## Out of scope

- **Deploy-gotchas one-liners** — commit-author-must-be-a-team-member (doesn't apply; we deploy as team members) and stale-cache `--force` / `VERCEL_FORCE_NO_BUILD_CACHE=1`. Left out.
- **The PML runtime-config-in-DB pattern** — admin-editable config blob, test/live-mode as a signed-cookie capability, credential-selection-follows-the-data's-`is_test`-flag. Reusable for *campaign* apps specifically, too app-specific for the general SPA template; recorded, not implemented.
- **Per-PR ephemeral previews + per-PR Neon branches** — rejected in favour of the persistent `develop` model (recorded so the choice is traceable, not lost).
- **Scaffold/code inside packs** — docs-only, consistent with the existing packs.
- **A CI job for the DRY dedup audit** — kept as a documented discipline + an "add a check in the spirit of i18n parity" pointer, not a new workflow.

## Open questions

None — both forks resolved above (atomic depth = full restructure + DRY gate; preview model = persistent `develop` + long-lived Neon branch).
