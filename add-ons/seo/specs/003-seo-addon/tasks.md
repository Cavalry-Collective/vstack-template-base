# Tasks: SEO Add-on (redo)

**Input**: Design documents from `/add-ons/seo/specs/003-seo-addon/`

**Prerequisites**: plan.md, spec.md, research.md (critique C1–C10, decisions D1–D8), data-model.md (R1–R11 / S1–S7 / G1–G3), contracts/ (3), quickstart.md

**Tests**: No test-code tasks — docs-only feature. Each story instead ends with its quickstart Part A validation task (the spec's review-based acceptance bar; see spec *Assumptions*). Part B checks bind instantiated projects, not this repo.

**Organization**: Tasks grouped by user story; stories are independently completable and testable. The redo edits the *uncommitted* first-attempt content in place — same file set, no migration state.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 (P1 playbook), US2 (P2 pack stances), US3 (P3 choice points)

## Path Conventions

Docs-only feature — paths are instruction files at the repository root (see plan.md *Project Structure*); no `src/`/`tests/` trees exist.

---

## Phase 1: Setup

**Purpose**: Confirm the redo starts from the intended baseline — the first attempt exists only as uncommitted working-tree changes.

- [X] T001 Verify baseline: `git status --short` and `git diff --stat` show the first-attempt changes present and uncommitted in `add-ons/seo/README.md`, `add-ons/README.md`, `stacks/vercel/frontend.md`, `stacks/vercel/README.md`, `stacks/nextjs-nestjs-postgres/frontend.md`, `stacks/nextjs-nestjs-postgres/README.md`, `stacks/taro-fastify-mysql-tencent/README.md`, root `README.md`, root `CLAUDE.md`; stop and report if any target was committed, reverted, or externally modified since planning

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Lock the shared vocabulary all three stories key off. The IDs are already *defined* in the design artifacts; this phase pins them as the single source before any prose is written.

**⚠️ CRITICAL**: No user story work until complete — a drifting ID scheme re-creates deficiency C1 (unenumerable seam).

- [X] T002 Re-read `add-ons/seo/specs/003-seo-addon/contracts/add-on-document.md`, `contracts/stack-seam.md`, `contracts/observable-behaviour.md`, and `data-model.md`; extract the exact R1–R11 / S1–S7 / G1–G3 definitions to work from verbatim — any wording change to an ID's meaning goes back into `data-model.md` first, never forked locally in a deliverable

**Checkpoint**: Vocabulary fixed — user stories can begin

---

## Phase 3: User Story 1 - Adopt an agnostic SEO playbook at Day-1 (Priority: P1) 🎯 MVP

**Goal**: Rewrite the add-on README so every rule is enumerable, observable, and CI-anchorable — fixing critique items C1, C3–C7, C9 (research.md).

**Independent Test**: Quickstart A1 + A2 + A5 pass against `add-ons/seo/README.md` alone — structure/IDs greppable, zero stack names, document contract satisfied on read-through — regardless of pack or enumeration state.

### Implementation for User Story 1

- [X] T003 [US1] Rewrite `add-ons/seo/README.md` to the 9-section structure of `add-ons/seo/specs/003-seo-addon/contracts/add-on-document.md`, in order: (1) title `# Add-on: seo`; (2) verbatim-pattern opt-in banner; (3) capability statement naming the exclusions (keyword/paid/rank/performance — research D8); (4) adoption-fit triage table, 3 rows (D5: fully public → adopt; mixed → adopt + classify; login-walled → delete, with residual refuse-indexing note); (5) Approach — rules R1–R11 from `data-model.md`, one bullet each, each stating its outside-observable behaviour (includes the two new rules: R5 URL stability, R2 crawl-space discipline — D2); (6) CI gates G1–G3 anchored "in the spirit of the i18n key-parity check" (D3); (7) Verify by observing — per-rule fetch-X-expect-Y list (D4) ending with the vendor-agnostic index-coverage pointer; (8) Binds to a stack — enumerated seam S1–S7 plus the unbound-declaration escape hatch (D1); (9) Interactions — base *URL routing*, *Configuration*, *Internationalisation*, *Microcopy & content*, add-on `test-mode`. Constraints: ≤ ~70 lines (D7), stack-agnostic throughout, no phantom base references
- [X] T004 [US1] Validate US1 per `add-ons/seo/specs/003-seo-addon/quickstart.md` Part A: run A1 (file present; `wc -l` ≤ ~70; R1–R11, S1–S7, G1–G3 all greppable), A2 (agnosticism grep returns zero matches), A5 (read-through against the document contract; spot-check every referenced base heading exists in `apps/frontend/CLAUDE.md` / root `CLAUDE.md`); fix and re-run until all green, recording the evidence (commands + output) for the PR test plan

**Checkpoint**: The playbook alone is a shippable MVP — adopting projects get the full discipline from the kept directory

---

## Phase 4: User Story 2 - Get concrete guidance for the chosen stack (Priority: P2)

**Goal**: Every shipped pack takes exactly one auditable stance — S-keyed bindings (both Next.js packs) or a reasoned unbound declaration (Taro) — fixing C2, C8, C10.

**Independent Test**: Quickstart A3 passes: for each `stacks/*/` directory, exactly one stance is greppable from that pack's own files; both bound packs answer every applicable S-id; the unbound pack states reason + alternative + residual posture. (S-ids come from `contracts/stack-seam.md`, so this story is executable and testable even before/without T003.)

### Implementation for User Story 2

- [X] T005 [P] [US2] Restructure the `**seo**` entry under `## Add-on bindings (if adopted)` in `stacks/vercel/frontend.md` into one short line per seam item keyed S1–S7 per `add-ons/seo/specs/003-seo-addon/contracts/stack-seam.md`: keep the existing S1/S2/S4/S5/S6 content (server-rendered indexable routes; Metadata API + `metadataBase`; `app/sitemap.*`/`app/robots.*` via the `routes` helper; `notFound()`; shared JSON-LD component); add the missing S3 (canonical-origin validated-config key home + `next.config` `redirects()` `permanent: true`) and S7 stance (bind to the base i18n locale set, or explicit "n/a" if the project is single-language — state it, don't omit it); keep the Vercel-preview `X-Robots-Tag: noindex` note under S4 or a closing line. Additions-only, no base restatement, appendix stays < 200 lines
- [X] T006 [P] [US2] Same restructure for `stacks/nextjs-nestjs-postgres/frontend.md`: S1–S7 keyed lines, keeping existing content (Server Components via `services/server/`; Metadata API; sitemap/robots off the `routes` helper; `notFound()`; config-keyed non-production noindex + test assertion; shared JSON-LD component) and binding S7 explicitly to `app/[locale]/` alternates from the parity-checked locale set; add the missing S3 config-key home. Additions-only, < 200 lines
- [X] T007 [P] [US2] Extend the `seo` unbound declaration blockquote in `stacks/taro-fastify-mysql-tencent/README.md` to the Stance-B contract: (1) name the unmeetable seam item — S1, Taro H5 client-only rendering cannot render indexable routes complete without JS; (2) keep the workable alternative (public surface served outside the Taro bundle, add-on bound there); (3) add the residual posture — a publicly reachable H5 origin that shouldn't appear in search results still serves the refuse-indexing response (deny-all robots / noindex) even with the add-on unbound (C10)
- [X] T008 [US2] Validate US2 per quickstart A3: per-pack stance grep (`grep -rl 'add-ons/seo' stacks/<pack>/` — no pack silent); S-id completeness grep on both Next packs (S1–S7 or explicit S7 n/a); unbound reason + alternative + residual posture present in the Taro manifest; `wc -l` on both edited appendices < 200; confirm no conflict-register entry is needed (bindings add, never override) — record evidence

**Checkpoint**: All three packs auditable item-by-item; US1 + US2 independently green

---

## Phase 5: User Story 3 - Discover the add-on at every choice point (Priority: P3)

**Goal**: The four enumeration sites name the add-on with wording that matches the redone doc (the sites already exist from the first attempt — this story verifies and aligns, not creates).

**Independent Test**: Quickstart A4 greps hit all four locations; the registry row's capability one-liner and "Pack supplies" cell match the redone doc's capability statement and S1–S7 seam.

### Implementation for User Story 3

- [X] T009 [US3] Run quickstart A4 and align wording: `add-ons/README.md` registry-table row (capability one-liner reflects the redone capability statement; "Pack supplies" cell summarizes the S1–S7 seam) and intro example list; root `README.md` folder-table mention + Day-1 step 6 `seo` entry; root `CLAUDE.md` repo-map add-on list — edit only lines whose wording drifted from the redone doc; leave already-accurate mentions untouched, and record the A4 grep evidence

**Checkpoint**: All user stories independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Whole-diff quality gates the repo demands before any merge.

- [X] T010 Full self-review per root `CLAUDE.md` *Self-review before merge*: re-read the complete `git diff` end to end (all nine touched instruction files **and** `add-ons/seo/specs/003-seo-addon/` artifacts); confirm additions-only in pack appendices, no unrelated reformatting, no orphaned wording from the first attempt, and R/S/G IDs used identically across `add-ons/seo/README.md`, both pack bindings, and the contracts (grep-compare against `data-model.md`)
- [X] T011 Run the SC traceability table at the bottom of `add-ons/seo/specs/003-seo-addon/quickstart.md`: confirm SC-001→A4+A5, SC-002→A1+A2+A5, SC-003→A3, SC-004→A5+Part-B mapping (every R has an O/G), SC-005→Part B documented; then state the Definition-of-Done caveat explicitly in the completion summary — the root toolchain placeholders are unfilled, so no `lint/typecheck/test/build` suite exists to run, and this docs-only diff has no runtime surface (per root `CLAUDE.md` *Definition of Done*, said, not skipped silently)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none — start immediately
- **Foundational (Phase 2)**: after Setup — BLOCKS all stories (shared ID vocabulary)
- **User Stories (Phases 3–5)**: each can start once Phase 2 completes; recommended order US1 → US2 → US3 (priority), though US2 and US3 are executable from the contracts alone and touch disjoint files
- **Polish (Phase 6)**: after all desired stories

### User Story Dependencies

- **US1 (P1)**: independent — the document contract is its only input
- **US2 (P2)**: independent of US1's *completion* (S-ids live in `contracts/stack-seam.md`); reads the same IDs, touches only `stacks/*` files
- **US3 (P3)**: wording-aligns to US1's output — soft dependency on T003 for final phrasing; greps themselves are independent

### Parallel Opportunities

- **T005, T006, T007** — three different pack files, fully parallel
- After Phase 2, US1 (T003–T004) and US2 (T005–T008) can proceed in parallel — disjoint file sets
- T004/T008/T009 validation tasks are sequential within their stories (validate after write)

## Parallel Example: User Story 2

```bash
# All three pack-stance tasks touch different files — launch together:
Task: "Restructure seo binding to S1–S7 keys in stacks/vercel/frontend.md"           # T005
Task: "Restructure seo binding to S1–S7 keys in stacks/nextjs-nestjs-postgres/frontend.md"  # T006
Task: "Extend unbound declaration in stacks/taro-fastify-mysql-tencent/README.md"    # T007
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 (T001) → Phase 2 (T002)
2. Phase 3: T003 rewrite, T004 validate
3. **STOP and VALIDATE**: A1/A2/A5 green → the playbook alone is shippable (packs still carry first-attempt bindings — functional, just pre-redo)

### Incremental Delivery

1. US1 → validate → the discipline is live for any adopter
2. US2 → validate → all three packs auditable
3. US3 → validate → choice-point wording aligned
4. Polish (T010–T011) → full-diff self-review + DoD statement — then hand back for commit approval (commits happen only when the user asks; the merge-back gate in root `CLAUDE.md` applies if this moves to a worktree/PR)

## Notes

- Docs-only: "tests" are the quickstart Part A checks; evidence (commands + output) is recorded per validation task for the PR test plan
- The four enumeration sites already exist from the first attempt — US3 is verify-and-align, not create; don't duplicate rows
- Avoid re-editing `add-ons/seo/README.md` from US2/US3 tasks — single-writer per file per story keeps the phases independent
