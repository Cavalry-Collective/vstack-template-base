# Audit Report — Cavalry Template SPA

**Audited**: 2026-07-03, commit `bdd463d`, branch `worktree-002-audit-repo-guidance`
**Corpus baseline**: 36,978 words / 29 guidance files + structural artifacts ([corpus-baseline.md](./corpus-baseline.md))
**Scanners**: gitleaks 8.30.1 (full history), grep passes, link resolution ([scan-evidence.md](./scan-evidence.md))
**Format**: per [contracts/findings-report.md](./contracts/findings-report.md); finding fields per [data-model.md](./data-model.md)

## Executive summary

The repository's engineering substance is strong — the architecture contracts are coherent, the add-on docs are exemplary, every internal link resolves, and the full git history is secret-free. But it is **not release-ready**: 3 release-blocking findings (publishing strategy for history/personal data, internal references inside committed spec artifacts, missing license), 9 high findings (a real fork-PR hole in `deploy.yml`, security-by-omission in the OTP guidance, two unregistered pack-vs-base contradictions, dangling security delegations, and three self-contradictions in the repo's own conventions), 21 medium (the bloat and duplication the maintainer suspected — though the design-guide revision was *not* the cause), and 5 low. **38 findings total.** Dispositions recorded below after maintainer review (T015).

## Release gate

| Item | Status | Evidence |
|---|---|---|
| Secrets (tree + full history) | ✅ PASS | gitleaks 8.30.1, 54 commits, no leaks |
| Internal references / personal data | ❌ FAIL | F-001 (history emails), F-002 (spec artifacts) |
| License | ❌ FAIL | F-003 — no LICENSE; remedy decided (MIT) |
| Front door | ❌ FAIL | README is a checklist, not a positioning front door; no branding (US3 scope, FR-012/FR-016) |

## Findings

### Release-blocking

**F-001 — Personal email in git history**
- Location: git history (author/committer identities, all 54 commits)
- Issue: history publishes `adam@raspberri.es` (personal-looking) alongside `adam@cavalry.sg` / `adam@cavalry.online` (company)
- Violates: FR-011 (personal data in a public release)
- Remedy: choose a publishing strategy — see Decision 1. A fresh-history public release solves this without touching the private repo; an in-place rewrite is destructive; acceptance is legitimate (it is the maintainer's own address)
- Destructive: yes (if history rewrite) | Disposition: **pending — Decision 1**

**F-002 — Committed spec artifacts carry internal-only references**
- Location: `specs/002-audit-repo-guidance/` (tasks.md T024: absolute path `/Users/adam/GitHub/cavalry-website/...` with machine username; scan-evidence.md: personal-email deliberation), `specs/001-enhance-design-guide/` (template-development history)
- Issue: if the historical spec dirs ship, internal paths and personal-data discussion ship with them — and deleting them later still leaves them in history unless the publishing strategy addresses it
- Violates: FR-011; SC-012 (no internal references)
- Remedy: exclude template-development specs from the public artifact — see Decisions 1 & 3
- Destructive: yes (directory removal) | Disposition: **pending — Decisions 1 & 3**

**F-003 — No LICENSE**
- Location: repo root; README has no license section
- Issue: an unlicensed public repo is all-rights-reserved — legally unusable, fatal for a template whose first instruction is "Use this template"
- Violates: FR-013; front-door completeness
- Remedy: add MIT LICENSE with Cavalry copyright line + README license section
- Destructive: no | Disposition: **approved — maintainer chose "not restrictive" → MIT (2026-07-03); lands in US3 (T025)**

### High

**F-004 — `deploy.yml` gate is bypassable by a fork PR**
- Location: `.github/workflows/deploy.yml` `jobs.deploy.if`
- Issue: gate is `conclusion == 'success' && head_branch == 'main'`; a fork PR from a branch named `main` with green CI satisfies both, then checks out the fork's SHA with base-repo secrets
- Violates: the workflow's own stated contract; *Don't overfit* (handle the adversarial case)
- Remedy: add `github.event.workflow_run.event == 'push'` to the condition, with a comment so it survives the TODO fill-in
- Destructive: no | Disposition: proposed

**F-005 — OTP guidance is unsound by omission**
- Location: `add-ons/otp-auth/README.md` §Choose a model / §Make it robust
- Issue: never mandates CSPRNG generation or minimum length, single-use consumption on successful verify, a bounded TTL (minutes), or max-failed-attempts-then-invalidate — the four classic OTP failure modes
- Violates: add-on invariant (SOP for a capability that's easy to get wrong); never hand-roll auth
- Remedy: add the four rules to "Make it robust"
- Destructive: no | Disposition: proposed

**F-006 — Stale claim: "CI and the PR template are still stubs"**
- Location: `CLAUDE.md` §Definition of Done preamble
- Issue: the PR template is fully authored (evidence-based test plan, DB and UI gates); the stale clause invites agents to disregard it
- Violates: accuracy of the always-loaded file; guidance-style (no historical narrative)
- Remedy: drop the clause (or "CI is still a stub")
- Destructive: no | Disposition: proposed

**F-007 — Spec convention contradicts the repo's own specs**
- Location: `specs/README.md` §Convention; echoed in `design/README.md` example and `.github/PULL_REQUEST_TEMPLATE.md`
- Issue: declares `YYYY-MM-DD-<feature>.md` single files while the repo's tracked specs are `NNN-<feature>/` directories; root CLAUDE.md promises spec-tool agnosticism but the convention has no escape hatch
- Violates: stated-rule vs repo reality; guidance-style (default + escape hatch)
- Remedy: state the file convention as default with the directory-per-feature escape hatch; point the two echoes at `specs/README.md` instead of restating the shape
- Destructive: no | Disposition: proposed

**F-008 — `stacks/README.md` contradicts the five-file canon**
- Location: `stacks/README.md` §Required file set + closing note
- Issue: mandates four files with "infra.md the only optional fifth" — the canonical structure (FR-015) requires five with absence-is-a-statement stubs
- Violates: FR-015; SC-011
- Remedy: rewrite the required-file section to the five-file canon + n/a-stub rule + per-area section skeleton (also fixes F-029)
- Destructive: no | Disposition: proposed

**F-009 — nextjs pack missing `infra.md`**
- Location: `stacks/nextjs-nestjs-postgres/` (absence declared only as a README aside)
- Issue: conformance failure under the canon; absence must be an in-pack stub
- Violates: FR-015 (absence is a statement)
- Remedy: add the n/a-stub `infra.md` (precedence line; platform-agnostic declaration; deploy-seam pointers; no-conflicts line); trim the README aside to a pointer
- Destructive: no | Disposition: proposed

**F-010 — vercel staging prescribes an unregistered long-lived `develop` branch**
- Location: `stacks/vercel/infra.md` §Staging + `stacks/vercel/db.md` §Production & staging migrations
- Issue: contradicts root's trunk-based/single-long-lived-branch rule; neither conflict register mentions it
- Violates: FR-006 (no silent contradictions)
- Remedy: add the register entry (develop receives only fast-forwards from main, never feature work — Vercel branch-scoped previews need a stable branch)
- Destructive: no | Disposition: proposed

**F-011 — vercel pins analytics SDKs against the vendor-agnostic base rule**
- Location: `stacks/vercel/frontend.md` §Analytics & Speed Insights
- Issue: base says "stay vendor-agnostic; don't pin an analytics SDK"; the pack mandates `@vercel/analytics` + `@vercel/speed-insights` unregistered
- Violates: FR-006
- Remedy: add the register entry (platform identity; product events still flow through the shared analytics service)
- Destructive: no | Disposition: proposed

**F-012 — Security bindings delegated to packs that don't deliver them**
- Location: `stacks/nextjs-nestjs-postgres/{backend,frontend}.md`, `stacks/taro-fastify-mysql-tencent/{backend,frontend}.md`
- Issue: the base delegates security headers/CSP mechanism, SSRF concrete check, and secret write-only masking to "the active stack pack"; only the vercel pack supplies them — two packs leave adopters with dangling security-critical delegations
- Violates: FR-006 (base promises the pack binds it); SC-011 (same coverage)
- Remedy: add a security-bindings section to each of the four files
- Destructive: no | Disposition: proposed

### Medium

**F-013 — Root CLAUDE.md historical/meta narrative** — §Coding standards "now live next to the code" (references the past move); §Principles "adapted from Andrej Karpathy's guidelines, folded into this file so no external reference is needed". Violates: guidance-style (no historical narrative). Remedy: state where standards live; reduce credit to a bare parenthetical or cut. Disposition: proposed

**F-014 — Mockup lifecycle rule stated in five places** — root §UI mockup, `design/README.md` (which points at root then restates all of it), `specs/README.md` item 2 (90-word parenthetical), `apps/frontend/CLAUDE.md` §Verify, PR template. Violates: one rule, one statement. Remedy: `design/README.md` owns the full loop; everyone else keeps one line + pointer. Disposition: proposed

**F-015 — Spec-slice rules triplicated** — root §Development workflow, `specs/README.md` §Convention, README §ideology, near-identical wording. Remedy: `specs/README.md` owns it; root keeps one line; README paraphrases philosophy. Disposition: proposed

**F-016 — README restates contract text verbatim** — What's-included rows copy root Repo-shape lines; the Keystone description appears twice (row + step 9); ideology quotes the Principles line. Remedy: one-clause rows with links; detail only in step 9. Disposition: proposed

**F-017 — README's false "repo name is immutable" note** — GitHub repos can be renamed; template-derived repos are user-named; self-deprecating admission on a flagship front door. Remedy: delete the sentence. Disposition: proposed

**F-018 — Day-1 checklist never clears template-development specs** — instantiated repos inherit the template's own specs; step 13's grep even excludes `specs/`. Remedy: add a Day-1 step ("delete the template's development specs, keep `specs/README.md`") — moot for the public artifact if Decision 3 removes them, still right for future template development. Disposition: proposed

**F-019 — Root Repo-shape map is stale** — omits `specs/` entirely (load-bearing for the workflow); `design/` bullet omits the design guide that Day-1 gates on; `infra/` bullet doesn't frame emptiness as deliberate. Remedy: add/extend the three bullets. Disposition: proposed

**F-020 — Vendored tooling untracked *and* unignored** — `.claude/` and `.specify/` sit as `??` in git status; one `git add -A` ships ten Spec Kit skills + an unratified bracket-placeholder constitution. Remedy: gitignore both (recommended) — see Decision 2. Disposition: **pending — Decision 2**

**F-021 — `apps/frontend/CLAUDE.md` intra-file duplication** — largest file (5,051 words); atomic-tier definitions stated twice; grouping rule three times; `lib/` helpers rule twice; 320px/200% floor three times; never-violate gates restate body rules; connective aphorisms and companion-note meta. History shows the bloat predates the design-guide work (3,360 → 5,312 → trimmed 4,850 → 5,051): accreted via "fold learnings" commits, re-grew past its own trim. Remedy: single-owner per rule; ~3,500 words holds every rule (ledger-verified). Disposition: proposed

**F-022 — `apps/frontend/CLAUDE.md` toolchain leaks & fossils** — `package.json`/semver named in a toolchain-TBD file; `BidTable` example leaks a prior project's auction domain; restates root's mockup + dates rules. Remedy: "package manifest" wording; neutral example names; pointers. Disposition: proposed

**F-023 — `apps/backend/CLAUDE.md` stack leaks & meta** — unhedged "In Node this is Express middleware / Fastify plugins…" sentence; "(e.g. Awilix)"; security-baseline preamble summarizes the document; "Standards reference" grab-bag with a one-bullet subsection; ring-naming heritage clause. Remedy: packs own the bindings; cut meta; promote sections. Disposition: proposed

**F-024 — `db/CLAUDE.md` duplication & meta** — "rules below are checkable and client-agnostic" meta sentence; shared-DB-across-worktrees rule stated in root *and* here *and* inside the round-trip rule. Remedy: db file owns the rule once; root keeps a pointer. Disposition: proposed

**F-025 — GCP specifics in the generic infra tier** — "blessed cloud is GCP", `gcloud` commands, GCP networking section — while two of three packs bind other platforms and register "replaces the GCP blessing". Remedy: keep agnostic intents (verify context; never default networks; provider export tooling); mark GCP material explicitly as the *default binding that an adopted pack's infra.md replaces* — no new pack invented (YAGNI). Disposition: proposed

**F-026 — `infra/CLAUDE.md` restates root principles & self-triplicates** — smallest-change/scope-control bullets mirror root Principles; environment-explicit rule ×3; apply-needs-approval ×3; "Purpose" section narrates the doc; "no separate AGENTS.md" meta; hedged rules without triggers ("where appropriate", "unless absolutely necessary"). Remedy: Guardrails owns approval + environment rules once; cut restatements/meta; default + named exception wording. Disposition: proposed

**F-027 — nextjs pack meta & register narrative** — "How to read this file" section about the document; register Because-clauses citing "the draft" and "the overhaul"; "three picks recorded in the pack README" is false (README records one). Remedy: cut meta; present-tense Because clauses; record the three picks. Disposition: proposed

**F-028 — nextjs pack density is duplication, not topics** — db.md register entries restate §Migrations at ~150 words/field; backend.md re-registers the forward-only conflict db.md owns; rejected-alternative rationales stated twice. Detail itself is legitimate (Babel order, enum ordering, `migrate diff` flags are load-bearing). Remedy: registers point at owning sections; one statement per rationale. Disposition: proposed

**F-029 — Pack shape drift** — backend.md: 16 sections (nextjs) vs 6 (taro) vs 8 (vercel); register formats differ; equivalent decisions registered in one pack, unregistered in siblings; nextjs README omits the Learnings step both siblings carry. Remedy: define the per-area skeleton in `stacks/README.md` (with F-008) and normalize all three. Disposition: proposed

**F-030 — Stack-agnostic rules trapped in packs** — money-never-float, timestamps-on-every-table, unique-constraints-encode-invariants→409, per-worktree DB naming scheme (duplicated verbatim in two packs), serverless instance-memory rule (×2), pagination windowing, modal-sizing-once. Violates: the packs' own "if a line is true without naming the stack, it does not belong". Remedy: hoist each to its base file; packs keep only the engine binding. Disposition: proposed

**F-031 — Cross-pack references dangle after instantiation** — "contrast `vercel`" ×5 in the taro pack; "the sibling nextjs pack" in vercel — siblings are deleted on Day-1. Remedy: self-contained statements. Disposition: proposed

**F-032 — Project-specific values in the taro pack** — `users/*`/`posts/*` COS prefixes from a prior product; deployed-product voice ("Cross-region DR replication is configured"); a leftover `purpose` example. Remedy: generalize to imperative template guidance. Disposition: proposed

**F-033 — Discovery wiring gaps** — `db/migrations/README.md` orphaned (nothing references it); pack READMEs two hops from auto-loaded guidance; PR template carries agent obligations but no guidance pointer names it. Violates: FR-007. Remedy: US5 wiring (pointer from `db/CLAUDE.md`; explicit pack-README pointer in `stacks/README.md` chain acknowledged at root; name the PR template where root cites the Test-plan obligation). Disposition: proposed

### Low

**F-034 — Root minor filler** — "These two rules are load-bearing…" announcement; self-review restates the rules it points to; "In short" digest re-owns the dates rule; Readability section is two orphan sentences + a lone sub-heading; local-deploy hedge legislates a nonexistent script. Remedy: cut/merge. Disposition: proposed

**F-035 — Placeholder grep doesn't match the placeholders** — Day-1 step 13 greps `TODO: replace`; the seven commented CI gates say `# TODO: install command` etc. Remedy: unify the marker or widen the grep. Disposition: proposed

**F-036 — Ignore/template polish** — `.gitignore` lacks `coverage/` and `pnpm-debug.log*` (pnpm is the CI worked example); `ISSUE_TEMPLATE/` has no `config.yml`. Remedy: cheap additions. Disposition: proposed

**F-037 — Provenance narrative in vercel pack** — "Validated end to end by a shipped production project" (README) + "validated in production use" (register). Remedy: cut both. Disposition: proposed

**F-038 — Minor cross-file dedups** — frontend re-quotes the backend's correlation-id transport shape; the 45-word stack-pack pointer paragraph is near-verbatim ×4 (trim to one sentence + pointer to `stacks/README.md` precedence). Remedy: pointers. Disposition: proposed

## Instruction-discovery map (SC-002)

**The maintainer's question answered**: yes — only `CLAUDE.md`-named files load automatically (root at session start; nested ones lazily when the agent enters that subtree). `README.md` and every other markdown file are **never** auto-loaded; they are read only when a loaded file explicitly points at them. The template's "read X before working on Y" pointer pattern is the correct mechanism (`@`-imports would load eagerly and defeat "context light"; mass-renaming would break human browsing). Verified against current Claude Code docs (research.md R1).

Classification of all 29 files: [discovery-map.md](./discovery-map.md). Summary: 5 auto/lazy-loaded (the CLAUDE.md tier) · 18 correctly one-hop referenced · 3 at risk (orphaned `db/migrations/README.md`; two-hop pack READMEs; unreferenced PR template → F-033) · 3 human-facing with no unique agent-binding rules (issue templates, verified in T037).

## File-by-file verdicts (SC-001)

| File | Verdict |
|---|---|
| CLAUDE.md | F-006, F-013, F-015, F-019, F-034, F-038 |
| README.md | F-003, F-016, F-017, F-018, F-035 |
| specs/README.md | F-007, F-014, F-015 |
| design/README.md | F-007 (echo), F-014 |
| apps/backend/CLAUDE.md | F-023, F-038 |
| apps/frontend/CLAUDE.md | F-014, F-021, F-022, F-038 |
| db/CLAUDE.md | F-024, F-030 (receives hoists) |
| db/migrations/README.md | F-033 |
| infra/CLAUDE.md | F-025, F-026 |
| stacks/README.md | F-008, F-029 |
| stacks/nextjs-nestjs-postgres/README.md | F-027, F-029 |
| stacks/nextjs-nestjs-postgres/backend.md | F-012, F-027, F-028 |
| stacks/nextjs-nestjs-postgres/frontend.md | F-012 |
| stacks/nextjs-nestjs-postgres/db.md | F-027, F-028, F-030 |
| stacks/nextjs-nestjs-postgres/infra.md | F-009 (missing) |
| stacks/taro-fastify-mysql-tencent/README.md | F-031 |
| stacks/taro-fastify-mysql-tencent/backend.md | F-012, F-030 |
| stacks/taro-fastify-mysql-tencent/frontend.md | F-030, F-031 |
| stacks/taro-fastify-mysql-tencent/db.md | F-030, F-031, F-032 |
| stacks/taro-fastify-mysql-tencent/infra.md | F-031, F-032 |
| stacks/vercel/README.md | F-037 |
| stacks/vercel/backend.md | F-030 |
| stacks/vercel/frontend.md | F-011, F-030, F-031, F-037 |
| stacks/vercel/db.md | F-010, F-030 |
| stacks/vercel/infra.md | F-010 |
| add-ons/README.md | ✅ clean |
| add-ons/test-mode/README.md | ✅ clean |
| add-ons/otp-auth/README.md | F-005 |
| .github/PULL_REQUEST_TEMPLATE.md | F-007 (echo), F-033 |
| .github/ISSUE_TEMPLATE/bug.md | ✅ clean (F-036 optional) |
| .github/ISSUE_TEMPLATE/feature.md | ✅ clean (F-036 optional) |
| .github/workflows/ci.yml | F-035 |
| .github/workflows/deploy.yml | F-004 |
| .gitignore | F-020, F-036 |
| git history | F-001 |
| specs/001-* + specs/002-* (committed) | F-002 |
| .claude/skills/, .specify/ (vendored, untracked) | F-020 — flag-only; constitution.md is an unratified placeholder |

## Decisions requested

1. **Publishing strategy (F-001, F-002)** — how does this repo go public?
   - **(a) Fresh-history release (recommended)**: publish a clean snapshot (orphan branch or new repo, single initial commit authored with a company email). Solves the personal email AND everything ever committed (spec artifacts, machine paths) in one move; the private repo keeps full history untouched.
   - (b) Rewrite history in place (destructive: all SHAs change) then publish this repo.
   - (c) Accept exposure: publish as-is history; only delete unwanted files going forward (they remain visible in old commits).
2. **Vendored Spec Kit tooling (F-020)** — `.claude/` + `.specify/`: gitignore (recommended), commit, or delete?
3. **Template-development specs (F-002, F-018)** — do `specs/001-*` and `specs/002-*` ship in the public template? Recommended: no (keep `specs/README.md`; the work stays in the private history).

All other findings are non-destructive edits already authorized by the spec's P2–P5 stories; they proceed after this gate.
