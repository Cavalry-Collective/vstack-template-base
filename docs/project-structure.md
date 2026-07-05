# Project structure

What belongs where — and what doesn't. Naming conventions in each section. The per-area contracts are normative; this guide is the tour.

```
.
├─ CLAUDE.md                  # root contract (binding)
├─ README.md                  # pitch + map
├─ docs/                      # guides (this directory) — explain, never override
├─ apps/
│  ├─ backend/                # API server (+ its contract)
│  └─ frontend/               # web app (+ its contract)
├─ db/
│  ├─ migrations/             # ordered, reversible schema migrations
│  └─ backfills/              # idempotent, batched data scripts (created when first needed)
├─ infra/                     # Terraform — one root module per workload
├─ design/                    # mockups + design guide; reference only, not built
├─ specs/                     # feature specs (Spec Kit)
├─ stacks/                    # optional stack packs — one kept at instantiation
├─ add-ons/                   # optional capability add-ons — keep = adopt
└─ .github/                   # CI, deploy, PR/issue templates
```

## `apps/backend/` — the API server

**Belongs:** everything that serves the API — feature modules (`src/modules/<feature>/` with `domain/ service/ repo/ controller/ dtos/` inside), shared aspects and pure utils (`src/shared/`), the composition root, and the backend's tests.

**Does not belong:** schema DDL (→ `db/migrations/`), frontend-consumable code (the apps share conventions, not code), business logic in controllers/repos/utilities, direct `process.env` reads outside the config module.

**Naming:** feature modules by business capability, singular and domain-flavoured (`user`, `billing`, `order`) — never technical groupings like `helpers` or `managers`. One use case per service file, named by the use case (`place-order`, not `order-utils`).

**Example:** `src/modules/billing/domain/invoice.js`, `src/modules/billing/service/issue-invoice.js`, `src/modules/billing/repo/invoice-repo.js`, `src/modules/billing/controller/invoices.controller.js`.

Full layout and ring rules: [`apps/backend/CLAUDE.md`](../apps/backend/CLAUDE.md). The adopted stack pack may re-home pieces (e.g. Nest modules as composition roots) — its appendix wins via the conflict register.

## `apps/frontend/` — the web app

**Belongs:** the layered source — `src/store/` (state, one slice per domain), `src/services/` (all network access), `src/pages/`, `src/components/{atoms,molecules,organisms/<feature>,templates}`, `src/i18n/`, `src/lib/`, the route registry, and the token source.

**Does not belong:** network calls in components, business logic in pages, feature-specific atoms/molecules ("a billing button" is a smell), hardcoded colour/space/copy literals (tokens and i18n own those), secrets of any kind (the bundle ships to the client).

**Naming:** atoms/molecules by type, generic (`Button`, `FormField`); organisms by feature (`organisms/billing/InvoiceTable`); i18n keys by meaning (`order.confirm_button`, never `page3.btn`).

Full layering, four-states, token, and a11y rules: [`apps/frontend/CLAUDE.md`](../apps/frontend/CLAUDE.md).

## `db/` — schema and data scripts

**Belongs:** migrations under `db/migrations/` (timestamp-prefixed, reversible or justified), data backfills under `db/backfills/`, seed/reset scripts.

**Does not belong:** anything the app imports at runtime, destructive one-off scripts without an explicit justification, backfills hidden inside schema migrations.

**Naming:** `<timestamp>_<verb_noun>` in snake_case (`20260601120000_add_orders_table`) — never `fix`/`update`.

Contract: [`db/CLAUDE.md`](../db/CLAUDE.md).

## `infra/` — Terraform

**Belongs:** one self-contained root module per workload (`infra/<workload>/`, or `infra/<workload>/<env>/` once a second environment exists), concern-grouped `.tf` files (`networking.tf`, `iam.tf`, `observability.tf`…), committed `.terraform.lock.hcl`.

**Does not belong:** state files or plan artifacts (gitignored, always), secrets in `.tf`/`.tfvars`, cross-workload references or speculative shared modules (a `infra/modules/` directory appears only when two workloads genuinely duplicate a shape).

Contract: [`infra/CLAUDE.md`](../infra/CLAUDE.md).

## `design/` — reference, never built

**Belongs:** screen mockups (one file/folder per screen, named by the screen's semantic name matching the route registry) with the inventory table in `design/README.md`, plus the design guide (`design-guide.html` + `tokens.css`).

**Does not belong:** anything imported by the apps, tool-export names (`screen-3-final-v2`), a second route→URL table.

Rules for building from (and drifting from) mockups: [`design/README.md`](../design/README.md).

## `specs/` — decisions before code

**Belongs:** one spec per feature (Spec Kit feature directories), with priority-tagged, independently shippable stories and per-criterion verification steps.

**Does not belong:** implementation detail that belongs in code review, retroactive specs written to bless finished work.

Convention: [`specs/README.md`](../specs/README.md).

## `stacks/` and `add-ons/` — the variability seams

**`stacks/`** holds stack packs: guidance-as-text appendices binding the agnostic contracts to one concrete stack. Exactly one directory survives instantiation. A pack never restates the base; overrides live only in its conflict register. System doc: [`stacks/README.md`](../stacks/README.md).

**`add-ons/`** holds optional cross-cutting capabilities. Keeping a directory *is* adopting it. Docs only, agnostic; the active pack supplies concrete bindings. System doc: [`add-ons/README.md`](../add-ons/README.md).

**Does not belong (both):** installed dependencies, lockfiles, generated scaffolding, project-specific values (URLs, secrets, form factors).

## `docs/` — guides

**Belongs:** onboarding, walkthroughs, strategy tours — anything that explains. **Does not belong:** rules. If you're writing "must/never" here, it belongs in a contract; link to it instead. One home per rule, links everywhere else — duplication is how docs start lying.

## `.github/` — automation and templates

CI (`ci.yml`) enforces the Definition of Done; deploy (`deploy.yml`) runs only after green CI on `main`. PR and issue templates encode the evidence the contracts require. A failing check fails the build — never `|| true`, never "warn".

## Where does a new file go? (decision path)

1. **Is it a business rule?** Backend domain ring of the owning feature module.
2. **Is it a use case / orchestration?** That module's service ring.
3. **Does it talk to the outside (DB, HTTP, providers)?** Repo-ring adapter (backend) or `services/` (frontend).
4. **Is it UI?** Generic → atoms/molecules; business-meaningful → `organisms/<feature>`; a screen → `pages/` + its route entry.
5. **Is it shared and pure?** Backend `shared/utils/` or frontend `lib/` — only once a second caller exists; until then co-locate with its caller.
6. **Is it schema?** A new migration — never inline DDL.
7. **Is it a rule about how we work?** The narrowest contract that covers it (area file first, root only if cross-cutting).
8. **Is it an explanation?** `docs/`, linking to the contracts it explains.
