# Phase 0 Research: Template Guidance Audit & Public Showcase

**Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

All Technical Context unknowns are resolved below. No NEEDS CLARIFICATION markers remain.

## R1. How the coding agent discovers instruction files

**Decision**: Classify every file by the documented Claude Code loading model and wire discoverability with lazy, one-hop references — not imports, not renames.

- **Auto-loaded at launch**: managed-policy CLAUDE.md → `~/.claude/CLAUDE.md` → project `./CLAUDE.md` (or `./.claude/CLAUDE.md`) → `./CLAUDE.local.md`, plus `.claude/rules/*.md` without `paths` frontmatter.
- **Lazy-loaded on subtree entry**: nested `CLAUDE.md` files (e.g. `apps/backend/CLAUDE.md`, `db/CLAUDE.md`) load when the agent reads files in that subdirectory — not at session start.
- **Never auto-loaded**: `README.md` and every other markdown file. They are read only when explicitly `@`-imported from a CLAUDE.md or when an instruction tells the agent to read them.
- **`@`-imports are eager**: imported files expand into context at launch (max depth 4). Importing the stack packs or add-on docs would load them into *every* session.

**Rationale**: This directly answers the maintainer's question — yes, content that exists *only* in README-named files is invisible to the agent unless something auto-loaded points at it. But the fix is not renaming (README.md serves GitHub browsing) and not `@`-imports (eager loading contradicts the "keep context light" goal). The repo's existing pattern — an auto-loaded or lazily-loaded CLAUDE.md saying "read `<file>` before working on `<area>`" — is the correct mechanism; the audit verifies every agent-binding file has exactly such a pointer (FR-007), and flags rules that live *only* in never-loaded files.

**Alternatives considered**: mass-rename README→CLAUDE.md (rejected: destroys human-facing repo browsing; GitHub renders README.md); `@`-import everything from root (rejected: eager expansion bloats every session, the opposite of the feature's goal); `.claude/rules/` with `paths` scoping (viable mechanism, rejected for now: the nested-CLAUDE.md + pointer pattern already covers the need — adopting a second mechanism adds concept count for no new capability).

**Source**: Claude Code memory documentation, https://code.claude.com/docs/en/memory.md (current as of 2026-06-30).

## R2. Secret and unsuitable-content scanning for public release

**Decision**: `gitleaks` over the working tree **and full git history** (`gitleaks git .`), plus a targeted grep pass for what secret scanners don't model: internal hostnames/URLs, personal email addresses, company-internal project references.

**Rationale**: Established, single-binary, widely-used scanner beats hand-rolled regexes (root-CLAUDE.md principle: never hand-roll security). History matters because making the repo public publishes every commit ever made, not just HEAD. The grep pass covers the "internal-only reference" class that is release-blocking per FR-011 but not a "secret."

**Alternatives considered**: trufflehog (heavier, credential-verification features unneeded here); manual review only (rejected: unreliable for history); GitHub secret scanning after publishing (rejected: too late — the point is to find blockers *before* going public).

## R3. Corpus measurement and the zero-rules-lost proof

**Decision**: The measured corpus is every `*.md` outside `.git/`, `.claude/`, `.specify/`, and `specs/`. Baseline re-captured 2026-07-03 after the design-guide revision landed (it touched `apps/frontend/CLAUDE.md`): **36,978 words** (`wc -w`); SC-003 target ≤ **27,733**. The zero-loss proof is a **rule inventory**: before editing, enumerate every actionable rule per file with an ID; after streamlining, every rule maps to kept / merged / moved / removed-with-approval (FR-004).

**Rationale**: Word count is the honest size metric for prose (line counts reward cramming). A rule inventory is the only way to *prove* nothing was lost rather than assert it; it also becomes the maintainer's approval surface for any deliberate removals.

**Alternatives considered**: diff review alone (rejected: demonstrates change, not preservation); token counts (rejected: tooling-dependent, word count is stable and reproducible).

## R4. Voice and style standard

**Decision**: A one-page style contract at `contracts/guidance-style.md`: imperative present tense, one rule = one statement, opinionated default + explicit escape hatch, no historical narrative, no meta-commentary, no hedging. Derived from agent-guidance best practice (concise, direct, structured) and the template's own Principles.

**Rationale**: "Award-winning voice" must be checkable, so it becomes a short contract that any reviewer can hold a sampled page against (SC-010). One page, because a style guide longer than the files it governs would fail its own standard.

**Alternatives considered**: adopting a full external prose style guide (Microsoft/Google) — rejected: built for end-user product docs, would add far more rules than this corpus needs (YAGNI).

## R5. License

**Decision**: **MIT**. The maintainer resolved the open decision on 2026-07-03 with the direction "choose something not restrictive"; MIT is the most permissive mainstream license and the norm for public templates.

**Rationale**: MIT imposes essentially one obligation (keep the copyright notice), maximizing adoption — exactly what "not restrictive" asks for. The release-gate item becomes concrete: `LICENSE` at root containing the MIT text with Cavalry's copyright line.

**Alternatives considered**: Apache-2.0 (rejected: its patent grant and NOTICE obligations add restriction the maintainer didn't ask for); no license (rejected: an unlicensed public repo is all-rights-reserved — unusable by others and the opposite of a showcase).

## R6. Canonical stack-pack structure

**Decision**: Every pack ships the same five files — `README.md` (identity, when to choose it, adoption steps) plus `backend.md`, `frontend.md`, `db.md`, `infra.md` binding the generic contracts to the concrete stack. An area that genuinely doesn't apply ships a short stub stating **why** it doesn't, in place — absence is always a statement. Sanctioned deviations from generic guidance are labelled exceptions. The canonical structure is documented once in `stacks/README.md` (the file a future pack author reads first) and contract-tested via `contracts/stack-pack-structure.md`.

**Rationale**: Derived from the packs' existing common shape — the majority already follow it; `nextjs-nestjs-postgres` lacking `infra.md` is the live conformance failure FR-015 exists to fix. Per-area files (not one monolith) preserve the one-hop pointer pattern from each area's CLAUDE.md.

**Alternatives considered**: single monolithic doc per pack (rejected: breaks per-area lazy references, forces agents to load irrelevant areas); free-form packs (rejected: structural drift is the defect being repaired).

## R7. Cross-reference verification

**Decision**: A small grep-based check: extract relative markdown links and backticked file paths from the corpus, verify each target exists; list files nothing references (orphan candidates for FR-008).

**Rationale**: The corpus is ~30 files with few external links; existing Unix tools cover it. Adding a link-checker dependency fails YAGNI.

**Alternatives considered**: lychee / markdown-link-check (rejected: new tooling for a job grep does at this scale).

## R8. Front-door comprehension test (SC-008)

**Decision**: A fresh-reader protocol: a reader (person or agent session) with no prior context gets the front-door README only, 10 minutes, then must answer three questions — *what is this repo, what philosophy does it encode, what are the first steps to start a project from it*. Pass = all three answered correctly.

**Rationale**: Cheap, repeatable, and measures exactly what SC-008 promises an outside engineer.

**Alternatives considered**: readability formulas (rejected: measure sentence mechanics, not orientation); no test (rejected: SC-008 must be observable, not asserted).

## R9. Cavalry branding assets

**Decision**: Copy the needed SVGs from the official brand pack in the company website repository (`cavalry-website/design/brand/` — lockup and mark variants in light/dark/mono) into this repository under `design/brand/`. The front-door README renders the lockup via a `<picture>` element with light/dark variants (GitHub supports `prefers-color-scheme` source switching); the design guide embeds the mark inline with an attribution line. Attribution text names Cavalry alongside the mark.

**Rationale**: FR-016 requires self-containment — the public repo may not reference the private website repository or any internal URL (that would itself be a release blocker). SVG lockups scale cleanly in READMEs; the light/dark pair keeps the mark legible in both GitHub themes. Copying only the variants actually used keeps the template lean.

**Alternatives considered**: hotlinking assets from the company website (rejected: external dependency, and the source repo is private — broken image for the public); embedding as base64 (rejected: unreadable diffs, no reuse); copying the whole brand pack (rejected: YAGNI — take the lockup light/dark pair and one mark, add more only when something uses them).
