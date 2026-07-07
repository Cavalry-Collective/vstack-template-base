# Implementation Plan: SEO Add-on — Structural Expansion

**Branch**: `004-seo-structural-expansion` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/add-ons/seo/specs/004-seo-structural-expansion/spec.md`, with three clarifications ratified 2026-07-07 (spec *Clarifications*): the `003-seo-addon` exclusion is reversed (structural work of keyword strategy, paid search, rank tracking, and page-speed ranking factors in scope; the ongoing practice of each out); day-1 gates are exactly the registry-derivable checks plus the payload budget; the expansion stays in the single existing document, trimmed to fit.

## Summary

Extend the shipped SEO add-on's shared ID vocabulary with the structural half of the four previously excluded areas: approach rules **R12–R20** (intent records, on-page coherence, linked reachability, ad-parameter invariance, direct-answering landing URLs, config-served ownership verification, derived page↔intent inventory, published loading-experience thresholds, structural speed causes), seam items **S8–S10**, CI gates **G4–G6**, and observable clauses **O11–O18** — used identically in the add-on README, the pack bindings, the contracts, and the quickstart checks, exactly as 003 established. The capability statement's exclusion sentence is rewritten as the structural-in / ongoing-out boundary. Docs-only; same mechanism, no scaffolding.

## Technical Context

**Language/Version**: English Markdown (GitHub-flavored) instruction files; no programming language.

**Primary Dependencies**: None installable. Governing contracts: `add-ons/README.md` (add-on invariants), `stacks/README.md` (pack invariants, bind-or-declare step 4), root `CLAUDE.md` (precedence, principles), the shipped `add-ons/seo/README.md` (the R/S/G/O vocabulary this feature extends), `add-ons/seo/specs/003-seo-addon/` design artifacts (ID definitions).

**Storage**: N/A — git-tracked markdown.

**Testing**: Two-tier, inherited from 003: (1) template-level — grep/wc/read checks runnable in this repo (quickstart Part A); (2) project-level — outside-observable fetch checks O11–O18 plus gates G4–G6, documented for instantiated apps (quickstart Part B, contracts/observable-behaviour.md).

**Target Platform**: This template repo, and every project instantiated from it (agents + humans reading the kept add-on).

**Project Type**: Documentation capability (template add-on extension) — docs-only by mechanism.

**Performance Goals**: N/A runtime. Reading budget: expanded README still digestible in < 5 minutes (SC-001).

**Constraints**: Add-on invariants (stack-agnostic, seam + interactions sections, well under ~150 lines — expanded target ≤ ~110, research D8); pack invariants (additions-only, appendices < 200 lines, conflicts only via register); no phantom base references; the expansion never renumbers or contradicts R1–R11 / S1–S7 / G1–G3; enumeration updates only where the add-on is already described.

**Scale/Scope**: 1 add-on document (extend + trim in place), 3 bound pack binding sections (append S8–S10 entries), 1 pack unbound declaration (verify accuracy against expanded scope), 1 registry-table row (seam range S1–S10), 2 root enumeration sites (verify only), 0 runtime code.

*(No NEEDS CLARIFICATION — the one item deferred from `/speckit-clarify`, the intent record's concrete shape, is resolved as research.md D2.)*

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled template (no ratified project constitution), so the binding gates are the repo's de facto constitution: root `CLAUDE.md` **Principles** plus the published add-on/pack invariants.

| Gate | Source | Pre-Phase-0 | Post-Phase-1 |
|---|---|---|---|
| Think before coding — surface what's unclear | Principles | PASS — the scope reversal, gate split, and size handling were asked, not assumed (spec *Clarifications*) | PASS — remaining judgment calls recorded as research D1–D9 with alternatives |
| Simplicity / YAGNI — minimum that solves it | Principles | PASS — structural half only; no analytics, no conversion seam, no tracker integration (D6, D7) | PASS — every new rule/seam/gate traces to a spec FR; size budget enforced (D8) |
| Change the right place | Principles | PASS — new rules in the add-on; stack concretes in packs; nothing new in base files | PASS — design touches only the 003 file set plus the registry row |
| Don't reinvent | Principles | PASS — extends 003's ID mechanism instead of inventing a parallel one (D3) | PASS |
| Add-on invariants (agnostic, seam, interactions, size) | `add-ons/README.md` | PASS (design targets; trim-to-fit ratified) | PASS — contracts/add-on-document.md hard-codes them; quickstart A-checks assert them |
| Pack invariants (additions-only, register-or-obey) | `stacks/README.md` | PASS | PASS — S8–S10 entries add, never override; no register entries needed |
| Spec-first | Root workflow | PASS — spec 004 with 16/16 quality checklist and 3 ratified clarifications | PASS |

**No violations → Complexity Tracking is empty.**

## Project Structure

### Documentation (this feature)

```text
add-ons/seo/specs/004-seo-structural-expansion/
├── spec.md              # Feature specification (/speckit-specify + /speckit-clarify)
├── plan.md              # This file
├── research.md          # Phase 0: decisions D1–D9
├── data-model.md        # Phase 1: R12–R20, S8–S10, G4–G6, new entities, lifecycles
├── quickstart.md        # Phase 1: Part A repo checks, Part B app checks, SC traceability
├── contracts/
│   ├── add-on-document.md      # Required README delta + invariants after expansion
│   ├── stack-seam.md           # S8–S10 answer forms; four-pack compliance
│   └── observable-behaviour.md # O11–O18 fetch clauses + G4–G6 assertions
├── checklists/
│   └── requirements.md  # Spec quality checklist (16/16 pass)
└── tasks.md             # Phase 2 (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

Docs-only feature — the "source" is the instruction files:

```text
add-ons/
├── README.md                          # UPDATE: seo row — capability wording + seam range S1–S10
└── seo/
    └── README.md                      # EXTEND IN PLACE: scope sentence rewrite, R12–R20, G4–G6,
                                       #   per-rule verify lines, S8–S10, interactions; trim to ≤ ~110 lines

stacks/
├── vercel/frontend.md                 # APPEND: seo binding gains S8–S10-keyed entries
├── vercel-ssr/frontend.md             # APPEND: seo binding gains S8–S10-keyed entries
├── nextjs-nestjs-postgres/frontend.md # APPEND: seo binding gains S8–S10-keyed entries
└── taro-fastify-mysql-tencent/
    └── README.md                      # VERIFY/EXTEND: unbound declaration accurate against expanded scope

README.md                              # VERIFY ONLY: folder table + Day-1 step 6 wording still true
CLAUDE.md                              # VERIFY ONLY: repo-map add-on list wording still true
```

**Structure Decision**: Extend in place — the same file set 003 shipped, plus the registry row whose seam range changes. One document absorbs the expansion (clarification 3); no new files outside `add-ons/seo/specs/004-seo-structural-expansion/`.

## Phase 0 → 1 outcomes

- **research.md**: complete — decisions D1 (reversal semantics), D2 (intent-record shape — resolves the deferred clarify item), D3 (extend the shared ID vocabulary), D4 (gate split G4–G6), D5 (agnostic page-experience naming), D6 (paid-search boundary: landing readiness only), D7 (rank-tracking boundary: trackability artifacts only), D8 (size budget ≤ ~110), D9 (four-pack binding surface). Zero unresolved clarifications.
- **data-model.md**: complete — R12–R20, S8–S10, G4–G6 defined; new entities (intent record, page↔intent inventory, ownership-verification response, landing URL space, payload budget) with lifecycles and relationships.
- **contracts/**: complete — the three 003 interfaces, extended: document ⇄ readers (README delta), seam ⇄ packs (S8–S10, four packs), behaviour ⇄ outside world (O11–O18, G4–G6).
- **quickstart.md**: complete — runnable Part A (incl. the no-stale-exclusion sweep for FR-015/SC-002), documented Part B, SC traceability table.
- **Agent context update**: skipped — this Spec Kit install ships no agent-context script (`.specify/scripts/bash/` has none), and this repo's agent context is its `CLAUDE.md` contract files, which this feature only edits as deliverables.

## Complexity Tracking

No constitution-gate violations to justify.
