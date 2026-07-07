# Tasks: SEO Add-on — Structural Expansion

**Input**: Design documents from `/add-ons/seo/specs/004-seo-structural-expansion/`

**Prerequisites**: plan.md, spec.md (3 ratified clarifications), research.md (D1–D9), data-model.md (R12–R20 / S8–S10 / G4–G6), contracts/ (3 deltas), quickstart.md

**Tests**: No test-code tasks — docs-only feature. Each story ends with its quickstart Part A validation task (the spec's review-based acceptance bar; see spec *Assumptions*). Part B checks (O11–O18, G4–G6) bind instantiated projects, not this repo.

**Organization**: Tasks grouped by user story, phases in spec priority order (P1 → P2 → P3). US1–US4 all extend `add-ons/seo/README.md` — single writer per phase, so those stories are sequential; US5 and US6 touch disjoint files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 (P1 intent discipline), US2 (P2 page-speed), US5 (P2 pack bindings), US3 (P3 rank-tracking), US4 (P3 paid-search), US6 (P3 consistency)

## Path Conventions

Docs-only feature — paths are instruction files at the repository root (see plan.md *Project Structure*); no `src/`/`tests/` trees exist.

---

## Phase 1: Setup

**Purpose**: Confirm the expansion starts from the intended baseline — the 003 deliverables, currently uncommitted in the working tree.

- [X] T001 Verify baseline: `add-ons/seo/README.md` is the 003 redo (73 lines; R1–R11 / S1–S7 / G1–G3 greppable; capability statement still names the four exclusions); `stacks/vercel/frontend.md`, `stacks/vercel-ssr/frontend.md`, `stacks/nextjs-nestjs-postgres/frontend.md` each carry an S1–S7-keyed `**seo**` binding; `stacks/taro-fastify-mysql-tencent/README.md` carries the unbound declaration; `git status --short` shows these uncommitted. Stop and report if any target was committed, reverted, or externally modified since planning — 004 stacks edits on top of the 003 diff, and the user decides at commit time whether they land together or 003 lands first

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pin the extended shared vocabulary all six stories key off, before any prose is written.

**⚠️ CRITICAL**: No user story work until complete — a drifting ID scheme would fork the mechanism that makes the add-on auditable.

- [X] T002 Re-read `add-ons/seo/specs/004-seo-structural-expansion/data-model.md` and the three contracts (`contracts/add-on-document.md`, `contracts/stack-seam.md`, `contracts/observable-behaviour.md`); extract the exact R12–R20 / S8–S10 / G4–G6 / O11–O18 definitions to work from verbatim, and the untouchable list (R1–R11 / S1–S7 / G1–G3 never renumbered or reworded; capability statement excepted). Any wording change to an ID's meaning goes back into `data-model.md` first, never forked locally in a deliverable

**Checkpoint**: Vocabulary fixed — user stories can begin

---

## Phase 3: User Story 1 - Every indexable page targets one recorded search intent (Priority: P1) 🎯 MVP

**Goal**: The add-on gains the intent discipline — record at the registry (R12 ⚙G4/G5), on-page coherence (R13), linked reachability (R14) — and its capability statement states the new boundary.

**Independent Test**: Quickstart A1 (boundary rewritten) + the A2/A3 subsets for R12–R14, G4–G5, S8 pass against `add-ons/seo/README.md` alone, with zero regressions on R1–R11 greps.

### Implementation for User Story 1

- [X] T003 [US1] Extend `add-ons/seo/README.md` per `add-ons/seo/specs/004-seo-structural-expansion/contracts/add-on-document.md`: (a) REWRITE the capability statement (line 5) to the ratified boundary — structural work of keyword strategy, paid search, rank tracking, and page-speed ranking factors in scope; the ongoing practice of each (keyword research/selection, campaign purchase/management, running/reading rank reports, hands-on performance-tuning operations) out — one sentence covering all four areas now, so US2–US4 verify rather than re-edit it; the old "…are out of scope" sentence must not survive; (b) append to *Approach*, one bullet each per `data-model.md`: **R12** (every indexable route records its target search intent — the query the page answers — at the route registry beside its classification, one per locale, updated in the same change as copy iteration; ⚙G4/G5), **R13** (title, description, slug, and the single top-level heading written against the recorded intent; exactly one top-level heading; levels descend without skipping), **R14** (every indexable page reachable via at least one crawlable, descriptive-anchor link from another indexable page — the sitemap is not linkage); (c) append **G4** and **G5** to *CI gates*, one line each, same parity-check anchor; (d) append per-rule lines to *Verify by observing* for R12–R14 (registry/inventory review; fetch raw → one top heading, coherent title/slug; traverse links → no orphans); (e) append **S8** to *Binds to a stack* — where the intent record lives on the pack's registry binding (US3 extends this line with inventory derivation); (f) append the interactions line: per-locale intent uniqueness derives from the same locale set the base i18n dictionaries define. Stack-agnostic throughout; terse — one bullet per item
- [X] T004 [US1] Validate US1 per `add-ons/seo/specs/004-seo-structural-expansion/quickstart.md`: run A1 (boundary statement — in-scope/ongoing-out wording present, old exclusion sentence gone), A2 subset (`R12 R13 R14 G4 G5 S8` greppable; regression greps for R1/R11/S1/S7/G1/G3 still hit), A3 subset (each of R12–R14 covered exactly once in *Verify by observing*); fix and re-run until green, recording the evidence (commands + output) for the PR test plan

**Checkpoint**: The intent discipline alone is a shippable MVP — the boundary is accurate and the foundational area (whose records US3 consumes) is live

---

## Phase 4: User Story 2 - Indexable pages meet the loading-experience ranking bar (Priority: P2)

**Goal**: Page-speed ranking factors as structural rules — published thresholds (R19), structural causes ruled out with the payload budget gated (R20 ⚙G6) — plus the performance-ownership interaction line.

**Independent Test**: A2/A3 subsets for R19–R20, G6, S10 pass; A9 finds no vendor metric names (three axes described generically per research D5).

### Implementation for User Story 2

- [X] T005 [US2] Extend `add-ons/seo/README.md` per the same contracts: (a) append to *Approach*: **R19** (indexable pages meet the search engines' published loading-experience thresholds — main-content loading, responsiveness to input, visual stability; the published values are the bar, the doc freezes no numbers) and **R20** (structural causes ruled out: media/embeds reserve their space before arrival; primary content never deferred behind client scripting or user interaction; each indexable route respects the declared payload budget; ⚙G6); (b) append **G6** to *CI gates* (every indexable route within the declared payload budget); (c) append *Verify by observing* lines for R19–R20 (measure the running page on the three axes → meets published thresholds; load page → no visible layout shift, primary content in the raw response); (d) append **S10** to *Binds to a stack* — the payload-budget home and its suite assertion, plus the measurement mechanism for the three axes; (e) append the interactions line: the base quality guidance keeps general performance — this add-on owns only the indexable-page ranking-factor slice. No vendor metric names (research D5)
- [X] T006 [US2] Validate US2 per quickstart: A2 subset (`R19 R20 G6 S10` greppable, no regressions), A3 subset (R19–R20 each covered once in *Verify by observing*), A9 read (no framework/SDK/vendor/cloud/vendor-metric names in the added lines); record evidence

**Checkpoint**: US1 + US2 green — the README carries the two highest-priority areas

---

## Phase 5: User Story 5 - Packs bind the expanded seam (Priority: P2)

**Goal**: All four shipped packs take an auditable stance on the expanded seam — S8–S10-keyed lines in the three bound packs, accuracy re-check for the unbound one.

**Independent Test**: Quickstart A4 (9 × `ok` across three bound packs) and A5 (taro declaration still accurate) pass from each pack's own files alone.

**Soft dependency note**: S-id definitions live in `contracts/stack-seam.md`, so these tasks are executable regardless of README state (the 003 precedent) — but for a coherent partial ship, bind only seams the README already asks for: S8 lands in US1, S10 in US2, **S9 in US3** — so run Phase 6 (US3) first, or hold the S9 lines until it completes.

### Implementation for User Story 5

- [X] T007 [P] [US5] Append to the `**seo**` binding entry in `stacks/vercel/frontend.md`, one line per item keyed by S-id per `add-ons/seo/specs/004-seo-structural-expansion/contracts/stack-seam.md`: **S8** intent record as a field on the `routes` link-helper entries (the pack's registry binding), page↔intent inventory generated from it alongside the sitemap; **S9** ownership verification served from a validated env key (console token → response), absent key → absent response; **S10** payload budget declared and asserted in the suite (G6), the three loading-experience axes measured with the pack's tooling (vendor metric/tool names allowed here). Additions-only; appendix stays < 200 lines
- [X] T008 [P] [US5] Same S8–S10 append for `stacks/vercel-ssr/frontend.md`, phrased against that pack's existing S1–S7 entries (routes-module indexable entries carry the intent field; verification and budget via that pack's validated-config and suite homes). Additions-only; < 200 lines
- [X] T009 [P] [US5] Same S8–S10 append for `stacks/nextjs-nestjs-postgres/frontend.md`, phrased against that pack's existing S1–S7 entries. Additions-only; < 200 lines
- [X] T010 [P] [US5] Re-check the `seo` unbound declaration in `stacks/taro-fastify-mysql-tencent/README.md` against the expanded add-on (research D9): reason (S1 unmeetable), workable alternative, residual refuse-indexing posture — with no indexable surface the new rules attach to nothing, so extend the wording only if it no longer holds; otherwise record "verified, no edit"
- [X] T011 [US5] Validate US5 per quickstart A4 (S8/S9/S10 grep — 9 × `ok`) and A5 (declaration read-through); `wc -l` on the three edited appendices < 200; confirm no conflict-register entry is needed (bindings add, never override); record evidence

**Checkpoint**: Four packs unambiguous against the expanded seam (SC-005)

---

## Phase 6: User Story 3 - Point any rank tracker at the product without hand-built lists (Priority: P3)

**Goal**: Trackability artifacts — config-served ownership verification (R17), derived page↔intent inventory (R18) — with URL continuity referenced from R5, not restated.

**Independent Test**: A2/A3 subsets for R17–R18, S9 pass; the S8 line now names inventory derivation.

### Implementation for User Story 3

- [X] T012 [US3] Extend `add-ons/seo/README.md`: (a) append to *Approach*: **R17** (search-engine ownership verification served from validated configuration, surviving redeploys — never a hand-placed artifact) and **R18** (the page↔intent inventory — each indexable URL paired with its recorded intent — derives from the route registry, machine-readable, never hand-kept; renames keep continuity per R5); (b) append *Verify by observing* lines for R17–R18 (fetch verification response, redeploy, fetch again → present both times; derive the inventory twice → exactly the indexable URLs with their intents, no diff); (c) append **S9** to *Binds to a stack* — how the verification response is served from the validated-config home; (d) extend the **S8** line with the inventory-derivation clause per `data-model.md` (record home *and* how the inventory is derived and served)
- [X] T013 [US3] Validate US3 per quickstart: A2 subset (`R17 R18 S9` greppable; S8 line mentions the inventory; no regressions), A3 subset (R17–R18 each covered once); record evidence

**Checkpoint**: A tracker needs only what the guidance requires (SC-007 inputs complete)

---

## Phase 7: User Story 4 - Landing URLs are ad-ready by construction (Priority: P3)

**Goal**: Paid-search structural rules — ad-parameter invariance (R15), direct-answering landing URLs (R16) — sharpening R1/R2/R4 for the advertising case without restating them.

**Independent Test**: A2/A3 subsets for R15–R16 pass; no new seam items (paid-search rules ride the existing S3/S4 mechanisms).

### Implementation for User Story 4

- [X] T014 [US4] Extend `add-ons/seo/README.md`: (a) append to *Approach*: **R15** (advertising click parameters never fork the page — identical content with arbitrary such parameters appended; the parameters never appear in canonicals or the sitemap; dedicated landing URL spaces are deliberately classified like any route — the R2/R4 variant discipline applied to the ad case by name) and **R16** (an ad landing URL answers success directly — no redirect chain; a vanity alias is at most one permanent redirect); (b) append *Verify by observing* lines for R15–R16 (fetch with arbitrary ad params → identical content, param-free canonical, absent from sitemap; fetch destination → direct success, alias → single permanent hop). No new seam item
- [X] T015 [US4] Validate US4 per quickstart: A2 subset (`R15 R16` greppable; no regressions), A3 subset (R15–R16 each covered once); record evidence

**Checkpoint**: All nine new rules in the README — the document is content-complete

---

## Phase 8: User Story 6 - Every description of the add-on tells the new truth (Priority: P3)

**Goal**: The template's surrounding surfaces describe the expanded capability; zero stale statements of the old exclusion anywhere current.

**Independent Test**: Quickstart A6 (registry row) and A7 (repo-wide stale-exclusion sweep — zero hits outside historical specs) pass.

### Implementation for User Story 6

- [X] T016 [P] [US6] Update the `seo/` row in `add-ons/README.md`: capability one-liner reflects the new boundary (structural discoverability + the structural work of the four areas), and the "Pack supplies" cell spans the seam items **S1–S10**; verify (read, expect no edit) that root `README.md` folder table + Day-1 step 6 and root `CLAUDE.md` repo map don't state the old exclusion — edit only if a line does
- [X] T017 [US6] Validate US6 per quickstart A6 (row wording + S1–S10) and A7 (`grep -rn "keyword strategy, paid search, rank tracking" --include="*.md" .` filtered of `specs/003-*` and `specs/004-*` → zero out-of-scope claims); record evidence

**Checkpoint**: All user stories independently functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Whole-document and whole-diff quality gates the repo demands before any merge.

- [X] T018 Trim pass on `add-ons/seo/README.md` to ≤ ~110 lines (quickstart A8; hard ceiling well under 150 — clarification 3, research D8): merge verify lines where rules share a fetch, tighten wording, never drop an ID; then run the **full** quickstart Part A end to end (A1–A9) and fix until all green, recording final evidence
- [X] T019 Full self-review per root `CLAUDE.md` *Self-review before merge*: re-read the complete `git diff` end to end (the six touched instruction files **and** `add-ons/seo/specs/004-seo-structural-expansion/` artifacts); confirm additions-only in pack appendices, no unrelated reformatting, R1–R11 / S1–S7 / G1–G3 byte-identical outside the capability statement, and R/S/G IDs used identically across the README, the three pack bindings, and the contracts (grep-compare against `data-model.md`); then state the Definition-of-Done caveat explicitly in the completion summary — the root toolchain placeholders are unfilled, so no `lint/typecheck/test/build` suite exists to run, and this docs-only diff has no runtime surface (per root `CLAUDE.md` *Definition of Done*, said, not skipped silently)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none — start immediately
- **Foundational (Phase 2)**: after Setup — BLOCKS all stories (shared ID vocabulary)
- **User Stories (Phases 3–8)**: any can start once Phase 2 completes, with two constraints: US1–US4 share `add-ons/seo/README.md` (single writer — run those phases sequentially), and US5 coherently binds S9 only after US3 defines it in the README (see the soft-dependency note in Phase 5)
- **Polish (Phase 9)**: after all desired stories — T018 is a whole-document pass and must be last for the README

### User Story Dependencies

- **US1 (P1)**: independent — rewrites the boundary and adds the foundational records
- **US2 (P2)**: independent of US1's completion; same file, so sequenced after it
- **US5 (P2)**: executable from `contracts/stack-seam.md` alone; *coherent* partial shipping wants README seams first (S8←US1, S10←US2, S9←US3)
- **US3 (P3)**: consumes US1's intent records conceptually; its verification/continuity half stands alone; extends the S8 line US1 wrote
- **US4 (P3)**: independent; same file, sequenced
- **US6 (P3)**: wording-aligns to the final capability statement (soft dependency on T003 for phrasing); greps independent

### Parallel Opportunities

- **T007, T008, T009, T010** — four different pack files, fully parallel
- **T016** (registry row) can run in parallel with any US5 task — disjoint files
- US1–US4 tasks are NOT parallel with each other (single writer on `add-ons/seo/README.md`)
- Validation tasks (T004, T006, T011, T013, T015, T017) are sequential within their stories (validate after write)

## Parallel Example: User Story 5

```bash
# All four pack-stance tasks touch different files — launch together:
Task: "Append S8–S10 seo binding lines in stacks/vercel/frontend.md"                  # T007
Task: "Append S8–S10 seo binding lines in stacks/vercel-ssr/frontend.md"              # T008
Task: "Append S8–S10 seo binding lines in stacks/nextjs-nestjs-postgres/frontend.md"  # T009
Task: "Re-check seo unbound declaration in stacks/taro-fastify-mysql-tencent/README.md" # T010
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 (T001) → Phase 2 (T002)
2. Phase 3: T003 extend + boundary rewrite, T004 validate
3. **STOP and VALIDATE**: A1 + A2/A3 subsets green → the boundary is accurate and the intent discipline shippable (remaining areas still absent from the doc — by design, incremental)

### Incremental Delivery

1. US1 → validate → boundary + intent discipline live (MVP)
2. US2 → validate → page-speed factors live
3. US3 → US4 → validate each → README content-complete
4. US5 (all four packs, parallel) → validate → SC-005 met
5. US6 → validate → zero stale descriptions
6. Polish (T018 trim + full Part A, T019 self-review + DoD statement) — then hand back for commit approval (commits happen only when the user asks; the merge-back gate in root `CLAUDE.md` applies if this moves to a worktree/PR)

## Notes

- Docs-only: "tests" are the quickstart Part A checks; evidence (commands + output) is recorded per validation task for the PR test plan
- The capability-statement rewrite happens ONCE, in T003 (all four areas — it is one sentence); US2–US4 verify their area's wording rather than re-editing it
- Single-writer per file per phase: never edit `add-ons/seo/README.md` from a US5/US6 task, and never edit pack files from US1–US4 tasks
- The full-feature execution order that avoids all soft-dependency friction is simply: Phases 3 → 4 → 6 → 7 → 5 → 8 → 9 (i.e. finish the README's four areas before binding packs); the phase numbering above follows spec priority instead, and either order is valid
