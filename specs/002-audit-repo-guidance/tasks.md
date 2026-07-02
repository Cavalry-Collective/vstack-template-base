# Tasks: Template Guidance Audit & Public Showcase

**Input**: Design documents from `/specs/002-audit-repo-guidance/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Not applicable in the TDD sense — this feature edits prose and structure, not runtime code. Each story phase ends with the verification tasks that prove its success criteria (see quickstart.md); the repo's lint/typecheck/test/build verbs are still toolchain TODOs, which the merge gate must state explicitly per the Definition of Done.

**Organization**: Tasks are grouped by user story. Note one deliberate, spec-mandated deviation from full story independence: US2–US5 execute against findings **approved in the US1 report** (FR-010 gates all destructive change on maintainer disposition). Each story remains independently *testable*; execution order is gated by design.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

## Phase 1: Setup

**Purpose**: Working environment and measurement base

- [X] T001 Create a git worktree + branch `002-audit-repo-guidance` per the root `CLAUDE.md` worktree workflow (gitignored env files: none exist yet in the template — note the skip)
- [X] T002 [P] Verify `gitleaks` is installed locally (`gitleaks version`); install via `brew install gitleaks` if missing — used for the scan only, never added to the template
- [X] T003 [P] Write `specs/002-audit-repo-guidance/corpus-baseline.md`: the corpus file inventory (per quickstart.md corpus definition) with per-file and total `wc -w` (baseline 36,978), plus the structural-artifact list (`.github/`, ignore files, `.specify/` config) — the coverage base for SC-001 and SC-003

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The zero-loss ledger — must exist before any file is edited

**⚠️ CRITICAL**: No editing story (US2–US5) may start before this phase; US1 uses it as review input

- [X] T004 Build `specs/002-audit-repo-guidance/rule-inventory.md`: enumerate every actionable rule as `R-###` (source file, condensed statement, disposition blank) across all non-vendored corpus files, per the Rule entity in data-model.md

**Checkpoint**: Baseline and ledger frozen — the audit can begin

---

## Phase 3: User Story 1 — Deep audit with a findings report (Priority: P1) 🎯 MVP

**Goal**: `audit-report.md` covering 100% of guidance and structural files, findings ranked by severity with release-blocking items first, the instruction-discovery map, and the decisions the maintainer must rule on.

**Independent Test**: Pick any in-scope file — the report has a verdict for it (SC-001); the discovery map classifies every file's loading behaviour (SC-002); every finding names its violated convention/principle (FR-002).

### Implementation for User Story 1

- [X] T005 [P] [US1] Run `gitleaks git . --verbose` over working tree + full history from the repo root; record tool version, command, and results in `specs/002-audit-repo-guidance/scan-evidence.md` (FR-011)
- [X] T006 [P] [US1] Run the internal-reference/personal-data grep pass (patterns per quickstart.md: internal URLs/hosts, personal emails, internal project names) over the working tree; append results to `specs/002-audit-repo-guidance/scan-evidence.md` (FR-011)
- [X] T007 [P] [US1] Build the instruction-discovery map: classify every corpus file's `audience`, `tier`, and `loading` (auto / lazy-subtree / one-hop / orphaned) per research.md R1 and the GuidanceFile entity; draft as `specs/002-audit-repo-guidance/discovery-map.md` (FR-003, FR-007 input)
- [X] T008 [P] [US1] Run the cross-reference check (quickstart.md command): extract relative links and backticked path references from the corpus, list broken targets and orphaned files; append to `specs/002-audit-repo-guidance/scan-evidence.md` (FR-008)
- [X] T009 [P] [US1] Review root tier against conventions, Principles, and `contracts/guidance-style.md`: `CLAUDE.md`, `README.md`, `specs/README.md`, `design/README.md` — draft findings (bloat, contradictions, sketchy guidance, missing front-door elements) with severity + remedy
- [X] T010 [P] [US1] Review generic area tier: `apps/backend/CLAUDE.md`, `apps/frontend/CLAUDE.md`, `db/CLAUDE.md`, `db/migrations/README.md`, `infra/CLAUDE.md` — draft findings incl. stack-specific detail that belongs in packs (FR-005)
- [X] T011 [P] [US1] Review all three stack packs under `stacks/` against `contracts/stack-pack-structure.md` and their generic counterparts — draft findings: contradictions, unlabelled deviations, structure non-conformance (known: `stacks/nextjs-nestjs-postgres/` lacks `infra.md`), pack-vs-pack drift (FR-006, FR-015)
- [X] T012 [P] [US1] Review add-ons (`add-ons/README.md`, `add-ons/test-mode/README.md`, `add-ons/otp-auth/README.md`) and structural artifacts (`.github/workflows/`, issue/PR templates, ignore files, directory layout); flag-only pass over vendored tooling (`.claude/skills/`, `.specify/` — incl. the unratified constitution); recommend a disposition for `specs/001-enhance-design-guide/`
- [X] T013 [US1] Assemble `specs/002-audit-repo-guidance/audit-report.md` per `contracts/findings-report.md`: header w/ scan metadata, executive summary, release gate w/ evidence, findings `F-###` ordered release-blocking → low with destructive flags, discovery map, file-by-file verdicts, decisions requested (historical specs + every destructive finding; license already decided: MIT)
- [X] T014 [US1] Validate the report: diff file-by-file verdicts against `corpus-baseline.md` (zero missing = SC-001); confirm every finding names a violated convention/principle (FR-002); confirm discovery map covers every file (SC-002); fix gaps
- [ ] T015 [US1] GATE — present the report to the maintainer; record their disposition (`approved`/`rejected`) on every destructive finding and the historical-specs decision in `audit-report.md` (FR-010). **Hard stop: no US2–US5 task runs before this completes**

**Checkpoint**: The review the maintainer asked for is delivered and dispositioned — MVP complete

---

## Phase 4: User Story 2 — Lean, opinionated guidance (Priority: P2)

**Goal**: Every non-stack guidance file stripped of narrative and filler, rewritten in the contract voice, zero rules lost. (Stack pack files are streamlined in US4 during restructuring, to avoid double-editing.)

**Independent Test**: Any streamlined file vs its previous version — rules preserved per the inventory, prohibited content gone (contracts/guidance-style.md); corpus measurably smaller.

### Implementation for User Story 2

- [X] T016 [US2] Streamline root `CLAUDE.md` per `contracts/guidance-style.md`, applying approved findings; update each touched rule's disposition in `rule-inventory.md` — this file sets the voice exemplar for all others
- [X] T017 [P] [US2] Streamline `apps/backend/CLAUDE.md` (same procedure, match the T016 voice)
- [X] T018 [P] [US2] Streamline `apps/frontend/CLAUDE.md`
- [X] T019 [P] [US2] Streamline `db/CLAUDE.md` and apply the approved disposition for `db/migrations/README.md`
- [X] T020 [P] [US2] Streamline `infra/CLAUDE.md`
- [X] T021 [P] [US2] Streamline `design/README.md`, `specs/README.md`, `add-ons/README.md`, `add-ons/test-mode/README.md`, `add-ons/otp-auth/README.md`
- [X] T022 [US2] Sweep `rule-inventory.md`: every rule has a disposition; every `removed` links to an approved finding — zero unapproved losses (FR-004)
- [X] T023 [US2] Measure progress: corpus `wc -w` (interim, final target ≤ 27,733 lands after US4); sample 3 streamlined files against `contracts/guidance-style.md` (SC-010); record evidence in `audit-report.md` dispositions

**Checkpoint**: Non-stack guidance is lean and on-voice; ledger proves zero loss

---

## Phase 5: User Story 3 — A public front door worthy of the work (Priority: P3)

**Goal**: README that positions the template and unmistakably brands it as Cavalry's, MIT license, approved internal-artifact removals applied — the repo looks release-ready.

**Independent Test**: Fresh-reader protocol (research.md R8): README only, 10 minutes, answers what/philosophy/how-to-start (SC-008); lockup renders from local assets (SC-012); `LICENSE` present.

### Implementation for User Story 3

- [X] T024 [P] [US3] Copy the Cavalry brand SVGs — lockup light + dark, one mark — from `/Users/adam/GitHub/cavalry-website/design/brand/` into `design/brand/` in this repo (only the variants used; FR-016, research.md R9)
- [X] T025 [P] [US3] Add `LICENSE` at repo root: MIT text with Cavalry's copyright line (FR-013, research.md R5)
- [X] T026 [US3] Rewrite `README.md` as the public front door: Cavalry lockup via light/dark `<picture>` element referencing `design/brand/`, what-this-is positioning, the opinionated philosophy, how to start (Day-1 checklist kept accurate), attribution naming Cavalry (FR-012, FR-016; depends on T024)
- [X] T027 [P] [US3] Add the Cavalry mark + attribution line to `design/design-guide.html`, referencing `design/brand/` assets (FR-016)
- [ ] T028 [US3] Apply the maintainer-approved destructive dispositions from `audit-report.md`: remove approved internal-only artifacts (e.g. `specs/001-enhance-design-guide/` if approved); if history remediation was approved for release-blocking content, execute it against the repo's git history — only what T015 approved (FR-010, FR-011)
- [X] T029 [US3] Validate: run the fresh-reader 10-minute test on `README.md` (SC-008); verify every brand-asset reference resolves to files under `design/brand/` with no external/internal URLs (SC-012); confirm `LICENSE` present; update release-gate section in `audit-report.md`

**Checkpoint**: The repo presents as Cavalry's public flagship

---

## Phase 6: User Story 4 — Two clean tiers, uniform stack packs (Priority: P4)

**Goal**: Generic tier fully stack-agnostic; all three packs conform to the canonical structure, streamlined in the contract voice, with labelled exceptions only.

**Independent Test**: Side-by-side read of each pack vs its generic counterpart — zero unlabelled contradictions (SC-004); pack-vs-pack comparison shows one shape, `stacks/README.md` documents it (SC-011).

### Implementation for User Story 4

- [X] T030 [US4] Document the canonical pack structure in `stacks/README.md` per `contracts/stack-pack-structure.md`: the five files, absence-is-a-statement rule, exception label format, authoring guidance for future packs (FR-015)
- [X] T031 [P] [US4] Conform `stacks/nextjs-nestjs-postgres/`: add `infra.md` (content or n/a-declared stub with reason), align section shape with the contract, label sanctioned deviations, streamline prose to the contract voice, move any misplaced generic content up / pull implementation detail down from generic files per approved findings
- [X] T032 [P] [US4] Conform `stacks/taro-fastify-mysql-tencent/` (same procedure)
- [X] T033 [P] [US4] Conform `stacks/vercel/` (same procedure)
- [X] T034 [US4] Resolve remaining tier conflicts in the generic files per approved findings: strip stack-specific detail from `CLAUDE.md`, `apps/*/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md` — generic prevails unless the pack carries a labelled exception (FR-005, FR-006; touches US2's files, so runs after Phase 4)
- [X] T035 [US4] Validate: build the StackPack conformance table (data-model.md) — five files present/n-a-declared per pack, zero unlabelled contradictions in side-by-side reads (SC-004, SC-011); update `rule-inventory.md` for moved rules

**Checkpoint**: Tiers are clean; packs are parallel; future-pack authoring is documented

---

## Phase 7: User Story 5 — No instruction can be silently missed (Priority: P5)

**Goal**: Every agent-binding file reachable within one explicit "read this when X" hop from auto-loaded or lazy-loaded guidance.

**Independent Test**: Trace each agent-binding file from the discovery map to its loader — max one hop, zero orphans (SC-005).

### Implementation for User Story 5

- [X] T036 [US5] Wire missing references per the discovery map's `orphaned` entries: add "read `<file>` before working on `<area>`" pointers in root `CLAUDE.md` and the area `CLAUDE.md` files so every agent-binding file is one hop from a loaded file (FR-007)
- [X] T037 [US5] For every `audience: human` file, verify no agent-binding rule exists only there; move any such rule into the owning CLAUDE.md-tier file and update `rule-inventory.md` (US5 scenario 2)
- [X] T038 [US5] Validate: update `discovery-map.md` — zero `orphaned` agent-binding files remain (SC-005); re-run the cross-reference check for broken links introduced by wiring (FR-008)

**Checkpoint**: Nothing binding can be missed for naming reasons

---

## Phase 8: Polish & Cross-Cutting Validation

**Purpose**: Final measurements, end-to-end proof, and the merge-back gate

- [X] T039 [P] Final SC-003 measurement: corpus `wc -w` ≤ 27,733 and `rule-inventory.md` shows zero unapproved losses; if over target, iterate on the wordiest files (evidence into `audit-report.md`)
- [X] T040 [P] Dry-run instantiation (SC-006): fresh clone in a scratch directory, follow the README Day-1 checklist end to end; zero broken references, missing files, or stale placeholders
- [X] T041 [P] Run SC-007 (two-doc orientation: root + one area file states the area's binding rules) and re-run SC-008 if `README.md` changed after T029
- [X] T042 Full quickstart.md sweep: every row SC-001…SC-012 passes; release-gate section of `audit-report.md` all-pass with evidence
- [X] T043 Close the ledger: every finding in `audit-report.md` reaches `applied`/`verified` or `rejected`; no new TODO/FIXME in touched files (Definition of Done); note explicitly that lint/typecheck/test/build are still toolchain TODOs
- [ ] T044 Merge-back gate per root `CLAUDE.md`: self-review the full diff end to end, rebase onto `main`, fast-forward merge, remove the worktree — and **confirm with the maintainer before any push** (deploy workflow triggers on `main`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **US1 (Phase 3)**: strictly sequential.
- **T015 (maintainer gate)** blocks Phases 4–8 — this is the FR-010 approval gate, a deliberate deviation from free story parallelism.
- **US2 (Phase 4)** before **US4 (Phase 6)**: T034 edits the same generic files US2 streamlines.
- **US3 (Phase 5)** is independent of US2/US4 (different files) and may run in parallel with Phase 4 after T015.
- **US5 (Phase 7)** last of the stories: wiring targets the post-restructure file set.
- **Polish (Phase 8)** after all stories.

### Parallel Opportunities

- Phase 3: T005–T012 (eight review/scan tasks) all parallel — different scopes, separate draft outputs.
- Phase 4: T017–T021 parallel after T016 sets the voice.
- Phase 5: T024, T025, T027 parallel; T026 after T024.
- Phase 6: T031–T033 (one per pack) parallel after T030.
- Phase 8: T039–T041 parallel.
- Cross-phase: Phase 5 (US3) can run alongside Phase 4 (US2) — disjoint files.

## Parallel Example: User Story 1

```text
# After T004, launch the audit fan-out together:
Task: T005 gitleaks scan → scan-evidence.md
Task: T006 internal-reference grep → scan-evidence.md (own section)
Task: T007 discovery map → discovery-map.md
Task: T008 cross-reference check → scan-evidence.md (own section)
Task: T009 root-tier review        Task: T010 generic-tier review
Task: T011 stack-pack review       Task: T012 add-ons/structural/vendored review
# Then T013 assembles, T014 validates, T015 gates.
```

## Implementation Strategy

**MVP first (US1 only)**: Phases 1–3 deliver the maintainer's actual ask — the deep "is anything sketchy" review — with zero risk, since nothing is edited yet. Stop at T015, get dispositions, demo the report.

**Incremental delivery**: after the gate, each story phase leaves the repo consistent and shippable: lean guidance (US2) → public face (US3) → uniform packs (US4) → wiring (US5) → final proof (Phase 8). Any story can be deferred without breaking the previous ones; SC-003's final number simply waits for US4.

## Notes

- All edits trace to findings in `audit-report.md`; destructive ones only with recorded approval (FR-010).
- Vendored tooling (`.claude/skills/`, `.specify/`) is never edited — findings only.
- Intentional template placeholders are preserved and framed, not "fixed".
- Commit per task or logical group, Conventional Commits style, on the worktree branch.
