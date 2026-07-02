# Implementation Plan: Design Guide Enhancement — Screen Archetypes, Surface Layering, and Pattern Foundations

**Branch**: `001-enhance-design-guide` (spec dir name; repo currently on `main` — feature work happens in a worktree per root `CLAUDE.md`) | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-enhance-design-guide/spec.md`

## Summary

Extend the Keystone design guide one altitude up — from foundations to composition — so
apps built from this template stop producing haphazard UI. Four slices: (P1) a **screen
archetypes** chapter (seven named page types with zone skeletons and tokenized page
rhythm), (P2) a **surface & layering** ladder (resting-surface composition, nesting
prohibition, separator decision rule), (P3) a **reuse-first gate** written into the guide
plus a minimal never-violate digest in `apps/frontend/CLAUDE.md`, and (P4) **form and
view-state patterns** (placement/behaviour, library-agnostic). All additions are edits to
the existing artifacts (`design/design-guide.html`, `design/tokens.css`) following the
guide's own conventions: token-driven, live-mirrored, each chapter ending in checkable
rules, each new chapter carrying a live specimen figure (FR-021) that serves as ship-time
verification.

## Technical Context

**Language/Version**: HTML5 + CSS custom properties + vanilla JS (no build step) — the
guide's existing, deliberate form; Markdown for the instruction-surface digest.

**Primary Dependencies**: None. Self-contained static files; Google Fonts fetched at
runtime with system-stack fallback (existing behaviour, unchanged).

**Storage**: N/A — static files under `design/`.

**Testing**: Browser review against each chapter's checkable rules (the guide's existing
gate), plus mechanical audits (grep for hex/px literals outside `tokens.css`; token
annotations resolving non-empty at load). No automated suite exists (repo toolchain is
still TODO) — per Definition of Done this is stated, not skipped silently.

**Target Platform**: Any modern browser; guide degrades to one long page without JS
(existing hash-router behaviour must be preserved).

**Project Type**: Static documentation artifact + one instruction-surface edit
(`apps/frontend/CLAUDE.md` digest block).

**Performance Goals**: N/A (static page; no regression concern at ~2× current size).

**Constraints**: Foundations-and-patterns only (no component inventory, FR-017);
single light theme; every value resolves to a token (live-mirror preserved, FR-019);
one home per rule (FR-020); guide remains specimen #1 of its own rules (FR-018/FR-021);
minimal never-violate digest only — no full rule duplication (FR-012 as clarified).

**Scale/Scope**: Guide grows from 15 chapters (~830 lines) to ~18 chapters (~1,400
lines): 3 new chapters, 1 chapter extended in place, 1 chapter rewritten-in-role,
5 small edits to existing chapters (4 in-place chapter edits + an intro line),
2 new semantic tokens, 1 digest block (~8 lines) in `apps/frontend/CLAUDE.md`.

## Constitution Check

*GATE: `.specify/memory/constitution.md` is the unfilled placeholder template — no
project constitution has been ratified. The repo's root `CLAUDE.md` **Principles (must
follow)** section is the operative constitution; gates evaluated against it.*

| Gate (root CLAUDE.md principle) | Pre-Phase-0 | Post-Phase-1 |
|---|---|---|
| Simplicity first / YAGNI | PASS — docs-only feature; no new tooling, no new files beyond spec artifacts; single-file guide retained (see research.md R1); deferred chapters (data-viz, dark mode) stay deferred | PASS |
| Change the right place, surgically | PASS — composition rules land in the guide (their one home); the frontend contract gets only the minimal digest the clarification fixed; existing chapters extended in place rather than paralleled (FR-020) | PASS |
| Don't reinvent existing solutions | PASS — every pattern adopted from evidenced systems (survey); no invented conventions where an industry norm exists | PASS |
| Don't overfit to the immediate request | PASS — archetypes/patterns solve the general SaaS-app case, with escalation rules for no-fit cases | PASS |
| Goal-driven execution | PASS — per-story independent tests in spec; quickstart.md defines the observable verification per phase | PASS |
| Guard every AI/LLM call | N/A — no AI calls in this feature | N/A |

No violations → Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-enhance-design-guide/
├── spec.md                  # Feature spec (complete, clarified)
├── design-system-survey.md  # Research base from /speckit-specify
├── plan.md                  # This file
├── research.md              # Phase 0 output — decisions R1–R7
├── data-model.md            # Phase 1 output — documentation schema for archetypes/surfaces/patterns
├── quickstart.md            # Phase 1 output — verification walkthrough
├── contracts/
│   ├── guide-chapters.md    # Chapter contract: nav placement, required blocks per new chapter
│   ├── tokens.md            # Token contract: new semantic tokens, tiers, naming
│   └── frontend-digest.md   # Digest contract: exact block for apps/frontend/CLAUDE.md
├── checklists/requirements.md
└── tasks.md                 # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
design/
├── design-guide.html        # MODIFIED — nav gains a "Composition" group; new chapters:
│                            #   Screen archetypes · Forms · View states & feedback;
│                            #   Elevation chapter extended into "Surfaces & elevation";
│                            #   Components chapter rewritten as "Components & reuse" (gate);
│                            #   small edits: Spacing, Layout, Content (verb list), Shape (x-ref)
├── tokens.css               # MODIFIED — new semantic page-rhythm tokens (--page-*)
└── README.md                # untouched

apps/frontend/
└── CLAUDE.md                # MODIFIED — one compact "never-violate UI gates" digest block
                             #   inside the existing "Design guide" section, lines pointing
                             #   at owning guide chapters

specs/001-enhance-design-guide/  # feature artifacts (above)
```

**Structure Decision**: No new source directories. The feature is edits to three existing
files; everything else is spec-directory documentation. Implementation runs in a worktree
per the root `CLAUDE.md` workflow, merging back via the standard rebase → verify →
fast-forward gate.

## Complexity Tracking

*No constitution-gate violations — table intentionally empty.*
