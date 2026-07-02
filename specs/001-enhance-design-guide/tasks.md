# Tasks: Design Guide Enhancement — Screen Archetypes, Surface Layering, and Pattern Foundations

**Input**: Design documents from `specs/001-enhance-design-guide/`

**Prerequisites**: plan.md, spec.md (clarified), research.md (R1–R7), data-model.md, contracts/ (guide-chapters, tokens, frontend-digest), quickstart.md

**Tests**: No automated test tasks — the repo toolchain is still TODO and the spec requests none. Each story instead ends with a mandatory **browser verification task** (the guide's operative gate per plan.md Technical Context and root `CLAUDE.md` goal-driven execution); ship-time evidence is the rendered guide (clarified: the guide is its own specimen).

**Organization**: Tasks grouped by user story. Note: most tasks edit the same document (`design/design-guide.html` — single-file decision, research R1), so [P] appears only where files genuinely differ.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 (archetypes) · US2 (surfaces) · US3 (reuse gate) · US4 (forms & feedback)

## Path Conventions

Feature touches exactly three source files: `design/design-guide.html`, `design/tokens.css`, `apps/frontend/CLAUDE.md`. Implementation runs in a git worktree per root `CLAUDE.md`.

---

## Phase 1: Setup

**Purpose**: Worktree + baseline capture so every later change is verifiable against a known-good starting point

- [X] T001 Create git worktree `.claude/worktrees/001-enhance-design-guide` on new branch `001-enhance-design-guide`; copy gitignored env files per root `CLAUDE.md` worktree rule (report "not in main checkout (skipped)" hits — expected for this docs-only feature)
- [X] T002 Baseline check: open `design/design-guide.html` in a browser — confirm all 15 current chapters render, hash router and pager work, every `.resolved` annotation is non-empty, and no-JS fallback shows one long page; record any pre-existing defects (flag, don't fix — root `CLAUDE.md` surgical rule)

**Checkpoint**: Known-good baseline captured; all story work builds on it

---

## Phase 2: Foundational

**Purpose**: None required — stories are self-contained edits to one document; no shared scaffolding may ship ahead of its story (an empty chapter shell would violate "trunk stays releasable"). The nav's new **Composition** group lands with US1 (its first occupant, per contracts/guide-chapters.md); US2/US3 only retitle existing entries; US4 appends to the group.

**Checkpoint**: Proceed directly to user stories after T002

---

## Phase 3: User Story 1 - Start every screen from a named archetype (Priority: P1) 🎯 MVP

**Goal**: Seven named screen archetypes with a shared page skeleton and tokenized page rhythm, so every page of a given type starts structurally identical.

**Independent Test**: Two different screens of the same archetype, sketched from the guide alone, match structurally (US1 acceptance scenarios); 3-brief archetype-selection probe passes (quickstart §3, SC-006).

### Implementation for User Story 1

- [X] T003 [P] [US1] Add semantic tokens `--page-title-gap` and `--page-section-gap` (aliasing existing `--space-*` primitives, with role comments) to tier 2 of `design/tokens.css` per contracts/tokens.md — no primitive values added or changed
- [X] T004 [US1] Add **Composition** nav group with a **Screen archetypes** link, the `section` shell (kicker/h1/lede, id `#archetypes`), and pager-order wiring in `design/design-guide.html` per contracts/guide-chapters.md nav map
- [X] T005 [US1] Author the shared page-skeleton block in the archetypes section of `design/design-guide.html`: page-header anatomy (one title + optional description/nav-context/actions), `--page-title-gap` and `--page-section-gap` with live `.resolved` annotations, cross-reference to Layout for the app frame (FR-002/FR-003, research R7)
- [X] T006 [US1] Author archetype **Collection/list** in `design/design-guide.html` — the US1 archetype fields from data-model.md (purpose, when/when-not naming the alternative, zone skeleton, tokenized zone gaps, `--container-content` width, reflow at both viewport ends; `state_placement` cross-references arrive with US4) + miniature wireframe specimen figure (FR-001, FR-021)
- [X] T007 [US1] Author archetype **Record detail** in `design/design-guide.html` — same field set, `--container-content`, specimen figure
- [X] T008 [US1] Author archetype **Form (create/edit)** in `design/design-guide.html` — same field set, `--container-narrow`, specimen figure
- [X] T009 [US1] Author archetype **Dashboard/overview** in `design/design-guide.html` — same field set, `--container-content`, specimen figure; include the hybrid-screen rule (a zone may host another archetype's content pattern; one archetype owns the frame — spec edge case)
- [X] T010 [US1] Author archetype **Settings** in `design/design-guide.html` — same field set, `--container-content`, specimen figure
- [X] T011 [US1] Author archetype **Multi-step flow** in `design/design-guide.html` — same field set, `--container-narrow`, specimen figure
- [X] T012 [US1] Author archetype **Full-page utility** (sign-in, not-found, full-page error/empty) in `design/design-guide.html` — same field set, `--container-narrow`, specimen figure
- [X] T013 [US1] Author selection guidance ("when to use which" table), no-fit escalation rule, app-wide density rule (one density via the box scale, never mixed in a page hierarchy; each zone states its box size), and the chapter's closing `ul.rules` checkable list in `design/design-guide.html` (FR-004/FR-005/FR-018)
- [X] T014 [US1] Edits-in-place in `design/design-guide.html` per contracts/guide-chapters.md bounds: Spacing chapter pointer to page-rhythm tokens (≤2 lines), Layout chapter cross-reference "what fills the body region → Screen archetypes" (≤2 lines), Introduction builder line "pick the screen archetype before building any screen"
- [X] T015 [US1] Verify US1 in the browser (quickstart §1–§3 US1 row): chapter walk, all archetype fields present, `.resolved` values live for new tokens, no-JS fallback intact, 3-brief selection probe ("audit log", "invoice editor", "plan upgrade wizard") resolves to the right archetypes; record evidence for the PR test plan

**Checkpoint**: US1 fully functional — guide ships with archetypes alone as a valid MVP

---

## Phase 4: User Story 2 - Compose surfaces by a named ladder (Priority: P2)

**Goal**: A named resting-surface ladder with nesting prohibitions and a single separator decision rule, extending the existing Elevation chapter in place.

**Independent Test**: Every container/separator decision on a content-heavy brief (grouped settings, detail page with sub-sections) is citable to a ladder rule; every surface-on-surface combination checkably valid/invalid (quickstart §3 US2 row).

### Implementation for User Story 2

- [X] T016 [US2] Retitle the Elevation chapter to **Surfaces & elevation** in `design/design-guide.html` (nav label + h1; keep the `#elevation` id and all existing shadow/z-band content and rules intact per contracts/guide-chapters.md)
- [X] T017 [US2] Author the resting-surface ladder in `design/design-guide.html`: four levels (recessed · page · card/panel · floating) bound to existing background/surface + shadow + z tokens; extend the pairing rule to resting surfaces; may-contain / may-stack-above table making every combination checkable (FR-006/FR-009)
- [X] T018 [US2] Author the nesting prohibition in `design/design-guide.html`: no card-like container inside another — do/don't specimen pair with the sanctioned alternatives (spacing, background-shift inset, divider where permitted) (FR-007, FR-021)
- [X] T019 [US2] Author the separator decision rule in `design/design-guide.html` — one ordered list: whitespace (default) → background shift → border → divider (dense data rows/tables only) — and update the chapter's closing `ul.rules` (FR-008/FR-018)
- [X] T020 [US2] Add the Shape & border cross-reference line in `design/design-guide.html`: concentric formula also governs nested-surface rounding — single rounding rule, no second formula (research R4, FR-020, ≤2 lines)
- [X] T021 [US2] Verify US2 in the browser (quickstart §3 US2 row): ladder table complete, prohibited combos citable, do/don't renders, existing elevation rules unbroken, `#elevation` anchor still resolves; record evidence

**Checkpoint**: US1 and US2 both independently verifiable

---

## Phase 5: User Story 3 - Reuse before invention (Priority: P3)

**Goal**: The reuse-first gate written into the guide's Components chapter and carried as a minimal never-violate digest in the frontend contract.

**Independent Test**: An overlap brief ("add a filterable list of X" where one exists for Y) resolves through the gate's check order; digest audit passes (quickstart §4).

### Implementation for User Story 3

- [ ] T022 [US3] Rewrite the Components chapter as **Components & reuse** in `design/design-guide.html` (keep the `#components` id and the no-inventory stance + twice/thrice promotion rule with meaning intact): add the 5-step reuse-first check order (archetype → documented pattern → existing screens/shared primitives → extend a primitive → create new), the new-construct bar (demonstrated need + no existing equivalent), the justification path for exceptions, closing `ul.rules`, and a live specimen figure — the check order as a tier-style diagram in the guide's existing idiom (FR-010/FR-011/FR-018/FR-021)
- [ ] T023 [P] [US3] Add the never-violate digest block to the "Design guide — the visual keystone" section of `apps/frontend/CLAUDE.md` per contracts/frontend-digest.md — gates 1–5 (token-only · archetype-first · surface ladder/separator order · reuse-first · one density), each line naming its owning guide chapter; absorb the section's overlapping token-rule sentence rather than doubling it (FR-012 as clarified)
- [ ] T024 [US3] Verify US3 (quickstart §3 US3 row + §4): chapter walk (gate order + bar present, promotion rule preserved), digest audit (one block, ≤ ~8 lines, correct chapter pointers, no guide-absent detail, no doubled rule); record evidence

**Checkpoint**: Guide + always-read instruction surface now enforce reuse at build time

---

## Phase 6: User Story 4 - Build forms and feedback without improvisation (Priority: P4)

**Goal**: Library-agnostic form and view-state/feedback patterns anchored to the archetype zones, plus the common-actions vocabulary.

**Independent Test**: A create/edit form and a data-loading view sketched from the guide alone have every placement decision citable to a pattern rule (quickstart §3 US4 rows).

### Implementation for User Story 4

- [ ] T025 [US4] Add the **Forms** chapter to the Composition nav group in `design/design-guide.html`: label placement, field-width ↔ expected content, group spacing, required/optional marking convention, button order + placement per container (page, dialog, inline), validation placement + recovery; pattern-wins-over-library-default precedence rule; do/don't specimens; closing `ul.rules` (FR-013/FR-017/FR-018/FR-021)
- [ ] T026 [US4] Add the **View states & feedback** chapter to the Composition nav group in `design/design-guide.html`: per-archetype-zone placement for loading/empty/error/partial, skeleton-vs-indicator rule, feedback routing (inline vs floating vs blocking, anchored to the causing control/zone); copy cross-referenced to the Content chapter, never restated; specimens; closing `ul.rules` (FR-014/FR-015/FR-020/FR-021)
- [ ] T027 [US4] Add the common-actions vocabulary table to the Content chapter of `design/design-guide.html` — one canonical verb per recurring action (create, edit, delete, save, cancel, search, filter, export at minimum) + ≤2 rules, per contracts/guide-chapters.md bounds (FR-016)
- [ ] T028 [US4] Extend the digest in `apps/frontend/CLAUDE.md` with gate 6 (forms and view states follow the composition patterns; the pattern wins over library defaults) per contracts/frontend-digest.md — completes the six-gate contract
- [ ] T029 [US4] Verify US4 in the browser (quickstart §3 US4 + vocabulary rows): both chapters' minimum rule sets complete, cross-references (not restatements) to Content, specimens render, digest now has all six gates; record evidence

**Checkpoint**: All four stories independently verified

---

## Phase 7: Polish & Cross-Cutting

**Purpose**: Whole-guide integrity audits and the merge-back gate

- [ ] T030 Run the full quickstart audits (§1 structure smoke incl. no-JS fallback and stable `#elevation`/`#components` anchors; §2 token greps + live-mirror; §5 rule-form/one-home spot-checks, the SC-005 three-failure-modes probe, and the full 10-brief SC-006 selection probe) against the completed guide in the worktree; fix findings and re-run until clean
- [ ] T031 Self-review the full diff end to end per root `CLAUDE.md` (correct layer, no unrelated reformatting, names carry business meaning, no stray TODOs) across `design/design-guide.html`, `design/tokens.css`, `apps/frontend/CLAUDE.md`
- [ ] T032 Merge-back gate per root `CLAUDE.md`: rebase onto trunk; state explicitly that lint/typecheck/test/build remain toolchain-TODO (Definition of Done disclosure); fast-forward merge; remove worktree + branch; confirm with the user before any push (deploy trigger caveat)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → everything.
- **Foundational (Phase 2)**: empty — stories start directly after T002.
- **User stories**: priority order **US1 → US2 → US3 → US4** is the intended sequence, and two real cross-story edges exist beyond priority:
  - **US3 digest (T023)** references chapter titles from US1 and US2 (gates 2, 3, 5) — run after both.
  - **US4** anchors view-state placement to US1's archetype zones (FR-014) and extends US3's digest (T028 after T023).
  - **US2** is technically independent of US1 (could swap order); all others follow priority.
- **Polish (Phase 7)**: after all stories ship (or after any story if stopping early — T030 audits whatever exists).

### Within Each User Story

- Section shell / retitle before content authoring; content before the closing rules list; verification task last.
- Single-file reality (research R1): tasks within a story editing `design/design-guide.html` run sequentially — granularity is for traceability, not concurrency.

### Parallel Opportunities

Genuine [P] pairs (different files):

- **T003** (`design/tokens.css`) ∥ **T004** (`design/design-guide.html`)
- **T023** (`apps/frontend/CLAUDE.md`) ∥ **T022** (`design/design-guide.html`)

Everything else shares `design/design-guide.html` and is sequential by design — the honest ceiling for a single-document feature.

## Parallel Example: User Story 1

```bash
# Start US1 with its only genuine parallel pair:
Task: "Add --page-title-gap / --page-section-gap to design/tokens.css"   # T003
Task: "Add Composition nav group + archetypes section shell to design/design-guide.html"  # T004
# Then T005 → T006..T012 (archetypes, sequential in the one file) → T013 → T014 → T015 (verify)
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 (T001–T002) → baseline.
2. Phase 3 (T003–T015) → archetypes chapter + rhythm tokens.
3. **STOP and VALIDATE**: run T015's browser walk + the quickstart §1–§3 US1 checks.
4. Merge if stopping here — archetypes alone visibly fix page-level inconsistency (the reported #1 pain).

### Incremental Delivery

Each story lands as its own reviewable slice ending in a verification task; trunk stays releasable after every checkpoint. Recommended single-worktree, priority-order execution: US1 → US2 → US3 → US4 → Polish. The digest reaches contract-complete (six gates) only after US4 — until then it carries the gates whose chapters exist, which is the correct incremental state.

---

## Notes

- Total: **32 tasks** (Setup 2 · US1 13 · US2 6 · US3 3 · US4 5 · Polish 3).
- Every guide edit obeys the guide's own conventions (FR-018) — the audits in T030 are the enforcement.
- Commit after each task or logical group (Conventional Commits, e.g. `feat(design): …`).
- Pre-existing defects found during T002/T030 are flagged, not silently fixed (surgical-change rule).
