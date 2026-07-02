# Implementation Plan: Template Guidance Audit & Public Showcase

**Branch**: `002-audit-repo-guidance` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-audit-repo-guidance/spec.md`

## Summary

Audit the entire template repository — every guidance document, structural artifact, and the git history — against established agent-guidance conventions, the template's own stated principles, and the bar of a public flagship repo, producing a severity-ranked findings report (P1). The report gates four cleanup slices: streamline all guidance into one lean, opinionated voice with zero rules lost (P2); build a public front door with license and release gate (P3); align the generic/stack tiers and impose one canonical stack-pack structure (P4); wire every agent-binding file to within one reference hop of auto-loaded guidance (P5).

Technical approach: this is prose-and-structure engineering, not application code. Verification is measurement-driven — scripted checks (word-count baseline vs. target, cross-reference resolution, secret scan over working tree and history) plus structured manual review against the contracts in `contracts/`. All destructive changes (delete/rename/move/history rewrite) are listed in the findings report and applied only after maintainer approval.

## Technical Context

**Language/Version**: English prose in GitHub-flavored Markdown; no application code is touched

**Primary Dependencies**: git; `gitleaks` (single-binary secret scanner, run locally for the history scan); standard Unix text tools (`wc`, `grep`, `find`) for measurement — no runtime or build dependencies added to the template

**Storage**: N/A — files in the repository; audit deliverables live in `specs/002-audit-repo-guidance/`

**Testing**: scripted verification (corpus word count, relative-link resolution, secret scan) + structured manual review against the contracts (`contracts/findings-report.md`, `contracts/stack-pack-structure.md`, `contracts/guidance-style.md`); acceptance mapped SC-by-SC in `quickstart.md`

**Target Platform**: public GitHub repository (repo is currently private; going public is the maintainer's action after the release gate passes)

**Project Type**: documentation / project-template repository (guidance corpus + scaffolding)

**Performance Goals**: N/A in the machine sense; the human metric is SC-008 — an outside senior engineer orients from the front door in ≤ 10 minutes

**Constraints**: zero actionable rules lost (enforced by a before/after rule inventory); template remains instantiation-ready after every slice; intentional placeholders preserved; vendored Spec Kit tooling (`.claude/skills/`, `.specify/`) is flag-only, never rewritten; destructive changes gated on maintainer approval

**Scale/Scope**: ~30 guidance/doc files at a measured baseline of 36,978 words (re-captured 2026-07-03; 25% target ⇒ ≤ 27,733 words); 3 stack packs × up to 5 docs; 2 add-ons; full git history scanned for release blockers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unratified template (placeholders only), so no formal constitution gates exist. The de facto constitution is the **Principles (must follow)** section of the root `CLAUDE.md`; this plan is gated against those. (The unratified constitution is itself expected to surface as an audit finding.)

| Principle (root CLAUDE.md) | Evaluation | Status |
|---|---|---|
| Think before coding | Ambiguities resolved in spec Assumptions; the one factual unknown (instruction-file discovery) is a Phase 0 research item, not an assumption | PASS |
| Simplicity first / YAGNI | No new frameworks or services; scripted checks use existing Unix tools; the only tool adopted is `gitleaks`, run locally and not added to the template | PASS |
| Change the right place, surgically | Edits land in the guidance files that own each rule; vendored tooling untouched; app skeletons untouched | PASS |
| Goal-driven execution | Every SC has a named verification in `quickstart.md`; the P1 report is evidence, not memory | PASS |
| Don't reinvent existing solutions | Secret scanning via an established tool rather than hand-rolled patterns; grep/wc for the rest | PASS |
| Don't overfit to the immediate request | Canonical stack-pack structure and style contract are written for future packs, not just the three existing ones | PASS |

**Post-design re-check (after Phase 1)**: PASS — the design added only three small contracts, one data model, and one validation guide; no new tooling, no new abstraction beyond what the spec requires.

## Project Structure

### Documentation (this feature)

```text
specs/002-audit-repo-guidance/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── findings-report.md       # format the P1 audit report must follow
│   ├── stack-pack-structure.md  # canonical structure every stack pack must follow
│   └── guidance-style.md        # voice/style contract streamlined guidance must meet
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

No application source is touched. The change surface is the guidance corpus and structural artifacts:

```text
CLAUDE.md                      # root guidance (auto-loaded) — streamline, wire references
README.md                      # public front door — positioning, philosophy, Cavalry lockup, day-1 checklist
LICENSE                        # MIT (maintainer directed "not restrictive") — release gate item
design/brand/                  # Cavalry brand SVGs copied from the company brand pack (FR-016)
design/design-guide.html       # design guide — carries Cavalry mark + attribution (FR-016)
apps/backend/CLAUDE.md         # generic tier — streamline, keep stack-agnostic
apps/frontend/CLAUDE.md        # generic tier — streamline, keep stack-agnostic
db/CLAUDE.md                   # generic tier
db/migrations/README.md        # near-empty; audit decides disposition
infra/CLAUDE.md                # generic tier
design/README.md               # human-facing reference notes
specs/README.md                # spec-workflow conventions
specs/001-enhance-design-guide/  # historical spec — report recommends disposition
add-ons/README.md              # add-on adoption rules
add-ons/{test-mode,otp-auth}/README.md
stacks/README.md               # pack adoption rules + canonical structure documented here
stacks/{nextjs-nestjs-postgres,taro-fastify-mysql-tencent,vercel}/
                               # each: README.md, backend.md, frontend.md, db.md, infra.md
                               # (nextjs-nestjs-postgres currently lacks infra.md — FR-015 target)
.github/workflows/, .github/ISSUE_TEMPLATE/, .github/PULL_REQUEST_TEMPLATE.md
.claude/skills/, .specify/     # vendored Spec Kit tooling — audited, flag-only
```

**Structure Decision**: single documentation surface at the repository root; audit deliverables (findings report, rule inventory) live inside `specs/002-audit-repo-guidance/` so the template's own areas stay clean. The findings report is the sole gate artifact — every P2–P5 edit traces back to an approved finding.

## Complexity Tracking

No constitution-gate violations; table intentionally empty.
