# Implementation Plan: SEO Add-on (redo)

**Branch**: `003-seo-addon` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/add-ons/seo/specs/003-seo-addon/spec.md`, plus the user's planning directive: the first implementation (currently uncommitted in the working tree) "is poorly implemented" — this plan defines the redo. Amended 2026-07-07 for the spec refinement that ratified the scope boundary (spec *Scope* section, FR-014, SC-006): structural work only; keyword strategy, paid search, rank tracking, and page-speed ranking factors are out of scope.

## Summary

Rework the SEO add-on so its quality is *mechanically auditable* instead of reviewer-dependent. The first implementation stated the right rules but in unenumerable prose: the stack seam couldn't be audited item-by-item, pack bindings were mega-bullets that hid omissions, verification wasn't per-rule, and two load-bearing failure modes (URL stability, crawl traps) were missing. The redo (research.md C1–C10 → D1–D8) introduces shared IDs — approach rules **R1–R11**, seam items **S1–S7**, CI gates **G1–G3** — used identically in the add-on README, the pack bindings, the contracts, and the quickstart checks, so every success criterion becomes a grep or a fetch. Same files as the first attempt; no new mechanism, no scaffolding, docs-only.

## Technical Context

**Language/Version**: English Markdown (GitHub-flavored) instruction files; no programming language.

**Primary Dependencies**: None installable. Governing contracts: `add-ons/README.md` (add-on invariants), `stacks/README.md` (pack invariants, bind-or-declare step 4), root `CLAUDE.md` (precedence, principles), `apps/frontend/CLAUDE.md` (base sections the add-on references).

**Storage**: N/A — git-tracked markdown.

**Testing**: Two-tier per spec *Assumptions*: (1) template-level — grep/wc/read checks runnable in this repo (quickstart Part A); (2) project-level — outside-observable fetch checks + CI gates G1–G3, documented for instantiated apps (quickstart Part B, contracts/observable-behaviour.md).

**Target Platform**: This template repo, and every project instantiated from it (agents + humans reading the kept add-on).

**Project Type**: Documentation capability (template add-on) — docs-only by mechanism.

**Performance Goals**: N/A runtime. Reading budget: add-on README digestible in < 5 minutes (SC-001).

**Constraints**: Add-on invariants (stack-agnostic, seam + interactions sections, well under ~150 lines; redo budget ≤ ~70 — research D7); pack invariants (additions-only, appendices < 200 lines, conflicts only via register); no phantom base references; enumeration updates only where add-ons are already enumerated.

**Scale/Scope**: 1 add-on document (rewrite), 2 pack binding sections (restructure to S-keyed entries), 1 pack unbound declaration (extend with residual posture), 4 enumeration sites (already satisfied; touch only if wording must track), 0 runtime code.

*(No NEEDS CLARIFICATION — the one open judgment, "what does better mean", is resolved as research.md C1–C10 with decisions D1–D8.)*

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled template (no ratified project constitution), so the binding gates are the repo's de facto constitution: root `CLAUDE.md` **Principles** plus the published add-on/pack invariants.

| Gate | Source | Pre-Phase-0 | Post-Phase-1 |
|---|---|---|---|
| Think before coding — surface what's unclear | Principles | PASS — "poorly implemented" decomposed into C1–C10 rather than guessed at | PASS — decisions recorded with alternatives |
| Simplicity / YAGNI — minimum that solves it | Principles | PASS — redo scope limited to critique findings; D8 re-affirms exclusions | PASS — every added structure (IDs, triage, gates) traces to a C-item; size budget enforced (D7) |
| Change the right place | Principles | PASS — capability rules in the add-on; stack concretes in packs; nothing new in base files | PASS — design touches the same file set as the first attempt |
| Don't reinvent | Principles | PASS — reuses the repo's own patterns (parity-check spirit, fail-closed assertions, decision-table style) | PASS |
| Add-on invariants (agnostic, seam, interactions, size) | `add-ons/README.md` | PASS (design targets) | PASS — contracts/add-on-document.md hard-codes them; quickstart A1/A2 checks them |
| Pack invariants (additions-only, register-or-obey) | `stacks/README.md` | PASS | PASS — seam contract forbids silent contradictions; no register entries needed (bindings add, never override) |
| Spec-first | Root workflow | PASS — spec 003 approved shape exists | PASS |

**No violations → Complexity Tracking is empty.**

## Project Structure

### Documentation (this feature)

```text
add-ons/seo/specs/003-seo-addon/
├── spec.md              # Feature specification (/speckit-specify)
├── plan.md              # This file
├── research.md          # Phase 0: critique C1–C10, decisions D1–D8
├── data-model.md        # Phase 1: R1–R11, S1–S7, G1–G3, binding states, lifecycles
├── quickstart.md        # Phase 1: Part A repo checks, Part B app checks, SC traceability
├── contracts/
│   ├── add-on-document.md      # Required README structure + invariants
│   ├── stack-seam.md           # S1–S7, bound / unbound-declared stances
│   └── observable-behaviour.md # O1–O10 fetch clauses + G1–G3 assertions
├── checklists/
│   └── requirements.md  # Spec quality checklist (16/16 pass)
└── tasks.md             # Phase 2 (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

Docs-only feature — the "source" is the instruction files:

```text
add-ons/
├── README.md                          # registry table row (kept; verify wording)
└── seo/
    └── README.md                      # REWRITE: triage, R1–R11, G1–G3, per-rule checks, S1–S7, interactions

stacks/
├── vercel/
│   ├── README.md                      # manifest scope cell (kept)
│   └── frontend.md                    # RESTRUCTURE: seo binding → S1–S7-keyed entries
├── nextjs-nestjs-postgres/
│   ├── README.md                      # manifest scope cell (kept)
│   └── frontend.md                    # RESTRUCTURE: seo binding → S1–S7-keyed entries
└── taro-fastify-mysql-tencent/
    └── README.md                      # EXTEND: unbound declaration + residual refuse-indexing posture

README.md                              # folder table + Day-1 step 6 (kept; verify)
CLAUDE.md                              # repo-map add-on list (kept; verify)
```

**Structure Decision**: Same file set as the first attempt — the redo replaces content in place (all of it uncommitted), so no migration or dual state exists. No new files outside `add-ons/seo/specs/003-seo-addon/`.

## Phase 0 → 1 outcomes

- **research.md**: complete — critique C1–C10 of the working-tree implementation; decisions D1 (enumerated seam), D2 (URL-stability + crawl-space rules), D3 (CI gates G1–G3), D4 (per-rule verification), D5 (adoption triage), D6 (S-keyed pack bindings; Taro residual posture), D7 (≤ ~70-line budget), D8 (scope exclusions — ratified by the user 2026-07-07 as the spec's *Scope* section, no longer an assumption). Zero unresolved clarifications.
- **data-model.md**: complete — entities with IDs, states (`bound`/`unbound-declared`; route classification lifecycle), relationships.
- **contracts/**: complete — the three interfaces (document ⇄ readers, seam ⇄ packs, behaviour ⇄ outside world).
- **quickstart.md**: complete — runnable Part A (incl. A6 scope-boundary check for FR-014/SC-006), documented Part B, SC traceability table.
- **Agent context update**: skipped — this Spec Kit install ships no agent-context script (`.specify/scripts/bash/` has none), and this repo's agent context is its `CLAUDE.md` contract files, which this feature only edits as deliverables.

## Complexity Tracking

No constitution-gate violations to justify.
