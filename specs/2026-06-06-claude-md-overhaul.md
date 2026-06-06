# CLAUDE.md overhaul + `nextjs-nestjs-postgres` stack pack

## Goal

Upgrade the template's convention files so projects instantiated from it come out consistently high quality — good UI/UX and clean code — by (a) closing the 43 high+medium gaps a multi-agent review confirmed in the existing CLAUDE.md/README files, and (b) adding the first stack pack: appendix docs that bind the agnostic contracts to Next.js (App Router, server-first) + NestJS + Postgres/Prisma.

## Decisions (binding, user-confirmed)

| Decision | Choice |
|---|---|
| Base files | Stay fully framework/toolchain-agnostic |
| Form factor | Responsive baseline + per-project primary-form-factor declaration (`mobile-first \| desktop-first \| responsive-equal`), filled in on setup |
| Stack guidance | Separate appendix files under `stacks/<pack>/`, never merged into base; each ends with an explicit conflict register ("base says X → in this stack Y → because Z → concretely: one checkable DO/DON'T") |
| Pack activation | Path-scoped `.claude/rules/stack-*.md` files (`paths:` frontmatter) carrying a prepend-copy of the appendix body — auto-loads exactly when matching files are touched. (Amended during implementation: rule files don't resolve `@`-imports per current docs, so the originally chosen `@import` form would silently never load.) |
| Language | Pack is language-neutral: TS or plain JS, no TS mandate; JS deltas documented (Nest Babel decorators, `@Inject(TOKEN)`) |
| Pack defaults | pnpm workspaces · Zod on both sides (no class-validator) · Radix UI blessed as headless lib · Prisma with `migrations.path → ../db/migrations` |
| Scope | All 20 high + 23 medium findings; 14 lows deferred (recorded under Out of scope) |
| File moves | `db/README.md` promoted to `db/CLAUDE.md`; `.github/` files (PR template, ci.yml, deploy.yml) in scope |

Full review artifacts (57 findings with verified recommendations; 4 reviewed pack outlines) are preserved in the session directory: `review-findings-full.json`, `review-findings-trimmed.json`, `stack-pack-design-full.json`.

## User stories

### S1 (P1) — Frontend UI/UX quality bar

As an agent building a screen, I have a checkable definition of *good*, not just *consistent*.

`apps/frontend/CLAUDE.md` gains: **Visual quality bar** (one modular type scale, ≤2 families / ~4 sizes / 2 weights per screen, 60–75ch measure; spacing only from the scale's steps; exactly one primary action per view; one H1, no skipped headings; meaning via semantic intent tokens, never color alone; grid/gutter alignment, density per declared form factor) · **Interaction feedback** (control states defined once on `ui/` primitives; in-flight feedback on the triggering control, never a full-screen spinner for a local action; optimistic updates for low-risk mutations with rollback; skeletons matching final layout; ~150 ms indicator delay, ~250 ms search debounce as tunable defaults; deliberate focus movement) · **Forms** (validate on blur after first interaction → on change once errored, never error-shout on first keystroke; inline `aria-describedby` errors; failed submit focuses first invalid field; destructive confirm names the consequence; unsaved-changes guard; submit disables in flight) · **Accessibility baseline** (headless lib covers widget-level only — overclaim corrected; AA contrast as token-set constraint; keyboard operability + visible focus; modal focus trap/restore; labels/alt/landmarks; `prefers-reduced-motion`; ~44 px touch targets on touch-primary) · **Form-factor declaration + responsive baseline** (fill-in line; mobile furniture like `--bottom-nav-clearance` becomes conditional; no horizontal scroll across declared range) · designed empty states (guidance + CTA) · 3-line microcopy rule.

- **AC1:** every S1 finding in Appendix A is addressed in the file. *Verify: diff cross-checked against Appendix A.*
- **AC2:** no rule contradicts the base file's existing token/layout/primitives sections or the form-factor decision. *Verify: consistency read of the final file.*

### S2 (P1) — Verification spine

As an agent claiming "done", I must pass a defined gate, with evidence I observed.

Root `CLAUDE.md` gains **Testing** (tests ship in the same change — a slice with no tests is not shippable; bug fixes start with a failing test; cheapest kind that proves the behavior; placement per app file), **Definition of Done** (lint+test+build pass for touched apps; behavior covered by tests; acceptance criteria met; per-area completion rules satisfied; no untracked TODOs; if a step can't run, say so — never skip silently), and one sentence under Goal-driven execution: *verified means observed, not inferred*. `apps/backend/CLAUDE.md` gains **Testing the rings** (domain = pure units no mocks; service = use-case tests with in-memory port fakes; repo = integration vs real DB; controller = contract tests; most coverage in fast inner rings) + **Verifying a change** (module tests; hit real endpoint happy + error path; confirm status/error shape/correlation id). `apps/frontend/CLAUDE.md` gains **Testing** (store/lib as units; services with network mocked at edge; components for behavior + four states; no broad DOM snapshots) + **Verifying a change** (run dev server; force all four states; keyboard-only pass; mockup compare at primary form factor + other width; report what was observed). `design/README.md` gains the **mockup fidelity loop** (build → run → capture and look → compare → iterate; no mockup → sketch in spec for new screens / "built to convention" for minor changes) + **mockup inventory table** + semantic naming rule. `specs/README.md`: each acceptance criterion states how it's verified; UI stories link their mockup; story done only when every criterion demonstrated, evidence in PR Test plan; UX/non-functional notes dimension.

- **AC1:** every S2 finding in Appendix A is addressed. *Verify: diff cross-check.*
- **AC2:** root additions stay ≤ ~25 lines total (attention budget); detail lives in the app/satellite files via pointers. *Verify: line count of root diff.*

### S3 (P1) — Consistency repairs

As an agent reading two files, I never get contradicting instructions.

Root *Architecture at a glance* paraphrases → one-line pointers (fixes the onion contradiction + invented middleware list). `infra/CLAUDE.md` re-rooted for the monorepo (header matching sibling files; layout tree under `infra/`; AGENTS.md section deleted; "run Terraform from `infra/<workload>/`"; standalone-repo wording swept; GCP-specific framing acknowledged vs README's "cloud-agnostic" claim). `apps/backend/CLAUDE.md` de-pinned (stack line becomes illustrative-default hedge mirroring the frontend file; ports phrased neutrally for typed/untyped languages). `db/README.md` → `db/CLAUDE.md` with migration discipline (never edit applied migrations — fix forward; ordered timestamped naming; schema vs data backfills, batched/idempotent; expand→migrate→contract for destructive changes; up→down→up round-trip proof on scratch DB; transactional where supported; seeds idempotent, never prod); `db/migrations/README.md` reduced to a pointer. Small: backend "Conventions" → "Coding standards"; hand-maintained route table dropped (registry file is the auditable surface); "don't reinvent dates" deduplicated to one canonical home + pointers.

- **AC1:** every S3 finding in Appendix A is addressed. *Verify: diff cross-check.*
- **AC2:** zero remaining cross-file contradictions. *Verify: final adversarial consistency pass over all changed files (fresh agent).*

### S4 (P2) — Workflow hardening

As an agent finishing work, the path to trunk has gates; as an agent in a fresh project, placeholders have defined behavior.

Root `CLAUDE.md`: ordered worktree merge-back gate (rebase onto current trunk → full suite on the integrated state — never merge red → ff-merge → stop servers → remove worktree+branch → push only after confirming, and push **will** deploy); `<pm>` TODO fallback (detect from lockfile/manifest/CI; if undeterminable stop and ask — never run literal `<pm>`, never guess; offer to fill the block in); day-1 fill-in checklist (consolidates every placeholder: commands, ci.yml, form factor, stack pack, `.env`); per-worktree database name on the shared server (migration-collision hazard); Conventional Commits stated; self-review-before-merge loop; dependency-addition criteria; runtime-config schema + fail-fast convention. `apps/frontend/CLAUDE.md`: API contract drift guard (backend contract is source of truth; mirroring service changes in the same PR; services validate responses → typed errors); correlation-id surfaced to the frontend (error display carries it); session-expiry UX convention; analytics events through one service wrapper. `apps/backend/CLAUDE.md`: logging discipline (what to log, no payloads/PII); app-level security baseline (validate at edge, authz placement, secrets never in code/logs). `.github/`: PR template gets real test-plan + UI checklist (states exercised, keyboard pass, mockup ref); ci.yml gets the conventions→checks map as TODO comments (lint, typecheck, tests, build, i18n parity, migration round-trip, a11y scan); deploy.yml gated on CI success.

- **AC1:** every S4 finding in Appendix A is addressed. *Verify: diff cross-check.*
- **AC2:** ci.yml/deploy.yml remain valid YAML stubs (no real toolchain commands invented). *Verify: YAML parse + read.*

### S5 (P1) — `stacks/nextjs-nestjs-postgres/` pack

As a team starting a project on the common stack, I activate one pack and get concrete, conflict-resolved conventions plus copy-paste commands.

Four files. **`README.md`** (manifest): identity, file→base mapping table, precedence line, day-1 wiring steps, suggested **dev** command block (pnpm: bootstrap incl. dockerized Postgres + `prisma generate` + `migrate dev`; dev; lint; test; build; migrate) and separate **CI** block (`migrate deploy`, never `migrate dev` in CI), deploy seam pointer to `infra/CLAUDE.md`. **`backend.md`**: ring→Nest cheat-sheet; module providers array = composition root (no `container.js`); domain decorator-free with lint-enforceable boundary list; Zod `ZodValidationPipe` at the edge (rejected alternative: class-validator — decorator-free works identically in JS); Fastify adapter default; domain errors only, `HttpException` confined to controller ring + one global filter; aspects table (guards/pipes/interceptors/filters, scoped not global); `TransactionRunner` unit-of-work port yielding tx-bound repos; JS path (Babel decorator setup, `@Inject(TOKEN)` mandatory); conflict register. **`frontend.md`**: server components default, client directive at interaction leaves; server data = props, client store = UI/optimistic state only; `services/` fetch sites move server-side calling NestJS `/internal/v1` with correlation-id + auth forwarded; `routes` path-helper replaces the registry file (never hand-build a URL); four states ↔ `loading.js`/`error.js` per segment; Radix-based `ui/` wrappers; Next deployment-skew handling replaces `version.json` poll (banner stays); i18n server/client dictionary split; conflict register (5 entries incl. SPA framing). **`db.md`**: `prisma.config` `migrations.path → ../db/migrations`; every migration commits a generated down (`prisma migrate diff --to-migrations … --script`) or an explicit irreversibility justification — never neither; Prisma rows stop at the repo-ring mapper; query hygiene (select/include only needed fields, never query in a loop, FK indexes explicit — Prisma doesn't auto-index FKs); seed/reset bound to `prisma db seed`; conflict register. Plus: `stacks/README.md` pattern note for future packs, `.claude/rules/` activation snippet documented in the pack README, root README + root CLAUDE.md gain the `stacks/` row/bullet and day-1 step.

- **AC1:** each appendix is additions-only (no restated base content) and ends with its conflict register; every base collision identified by the design review appears there. *Verify: adversarial dovetail pass per appendix against its base file.*
- **AC2:** all framework claims are current-version-correct (Prisma `migrations.path`, Nest JS/Babel path, App Router conventions, `.claude/rules` `paths:` frontmatter semantics). *Verify: doc-check pass with web verification on the named claims.*
- **AC3:** pack activation snippets are copy-paste runnable (paths resolve from the repo root). *Verify: dry-run the day-1 steps in a scratch copy.*

## Out of scope

- The 14 low findings (spec TEMPLATE.md, `.env.example`, feature-flag mechanics, size/complexity rule, ADR convention, memory-worthiness definition, trunk-name mismatch, `.claude/` settings artifacts, etc.) — recorded as a Learnings backlog note, not implemented now.
- Scaffold code inside packs (docs-only v1; scaffolding noted as possible later evolution).
- Additional stack packs; pinning the base template to any stack.
- Renaming the repo (encodes "spa"; immutable, accepted as stale for server-first pack users).

## Open questions

None — all decisions resolved above (TS-vs-JS README tone: strictly neutral, both paths documented).

## Appendix A — in-scope findings (43)

**S1:** visual quality bar absent · interaction feedback/perceived-performance absent · forms UX undefined · a11y not a checkable baseline · mobile furniture hard-coded / no form-factor declaration · empty states not designed · no microcopy rules.
**S2:** no testing strategy anywhere · backend per-ring testing missing · frontend test/not-test missing · no Definition of Done · no verification loop per change type · mockup fidelity loop missing · design/ mockup organization missing · specs verification/done-definition missing · UI stories not linked to mockups · specs UX/non-functional dimension missing · PR template lacks UI/a11y gate.
**S3:** root glance contradicts backend onion · infra file written for standalone repo · backend pins JS vs agnostic README · db guidance two sentences in non-loaded README · root claims nonexistent backend section · route table will drift · infra GCP vs cloud-agnostic claim · date-rule triplication *(folded from lows where touching the same lines)*.
**S4:** merge-back lacks test/rebase gate · `<pm>` placeholder has no agent behavior · no day-1 checklist · shared-DB worktree hazard · no commit convention · no self-review loop · no dependency criteria · backend logging discipline vague · no app security baseline · CI stub has no conventions→checks map · deploy ungated · worktree config copy under-specified · API contract drift guard · correlation id dead-ends at frontend · no session-expiry UX · no frontend analytics convention · no config fail-fast.
**S5:** the stack pack (new scope, not a finding).
