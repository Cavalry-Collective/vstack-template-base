# Feature Specification: Template Guidance Audit & Public Showcase

**Feature Branch**: `002-audit-repo-guidance`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "somewhat gone out of control. Can you do a deep review of this entire repo? At the end of the day we want to ensure that everything we do is according to established conventions and best practices. please review to see if anything is sketchy. Also, we want these instructions to allow us to quickly set up new projects, and a lot of the AI generated additions will include historical context etc which adds unnecessary bloat to this project. the biggest value this repo brings is an opinionated approach to development. hence we wanna keep the context light and just give simple straight forward guidance on how to build software. the backend and frontend/CLAUDE.md in general contains the high-level guidance, and the stacks instructions can provide deeper implementation level detail. however, stacks should not conflict with the generic instructions. lastly, this repo has a lot of README.md and also other files not using CLAUDE.md naming. im wondering if this causes claude to miss out instructions?"

**Input (update, 2026-07-02)**: "please also make it award-winning. we will make this a public repo on our company's github. it should showcase our deep experience, and make us look like award-winning world-class software engineering team. opinionated, concise and quality-driven!"

**Input (update 2, 2026-07-02)**: "also we will have different stacks in future but we want to keep all the stacks structure more or less similar while respecting their individual differences."

**Input (update 3, 2026-07-03)**: "please make sure to pepper Cavalry logo into the readme, and maybe also design guide. anyway make sure people know this is cavalry's work. … for licensing, choose something not restrictive."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deep audit with a findings report (Priority: P1)

As the template maintainer, I receive a complete review of the repository — every guidance document and every structural artifact — measured against established conventions, the template's own stated principles, and the bar of a public flagship repository, so I know exactly what is sketchy, contradictory, bloated, unsuitable for public release, or at risk of being missed before anything is changed.

**Why this priority**: The template has grown through many AI-assisted iterations and the maintainer no longer trusts that every addition is sound. The report is the deliverable the maintainer explicitly asked for ("review to see if anything is sketchy"), and every later slice depends on knowing what is wrong. On its own it is a viable MVP: a trustworthy picture of the repo's health and its readiness to go public.

**Independent Test**: Can be fully tested by picking any guidance or structural file in the repository and confirming the report covers it with either a "no issues" verdict or concrete findings. Delivers standalone value as a review document even if no fixes are ever applied.

**Acceptance Scenarios**:

1. **Given** the current repository, **When** the audit completes, **Then** every guidance document (root guidance, per-area guidance, readme-style documents, stack packs, add-ons) and every structural artifact (workflow definitions, issue/PR templates, ignore rules, directory layout) appears in the report with an explicit verdict.
2. **Given** any finding in the report, **When** the maintainer reads it, **Then** it states the location, what is wrong, which convention or stated principle it violates, a severity, and a recommended remedy.
3. **Given** the findings list, **When** the maintainer scans it, **Then** findings are ordered by severity so the sketchiest items surface first, with release-blocking items (anything unsuitable for a public repository) at the top.
4. **Given** the maintainer's question about instruction-file naming, **When** the report is read, **Then** it definitively explains how the coding agent discovers instructions (which files are loaded automatically, which are only read when explicitly referenced) and lists every instruction file currently at risk of being missed.
5. **Given** the intent to publish the repository, **When** the audit completes, **Then** it has checked the entire repository — including its version history — for content unsuitable for public release (credentials, personal data, internal-only references) and reported any occurrence as release-blocking.

---

### User Story 2 - Lean, opinionated guidance (Priority: P2)

As a maintainer spinning up new projects from this template, I want every guidance file stripped of historical context, change narrative, and AI-generated filler, and rewritten in one confident, opinionated voice, so that agents and developers get the team's approach in the fewest words that still carry every rule — guidance that reads as authored by a world-class team, not accreted by a tool.

**Why this priority**: The maintainer states the repo's biggest value is its opinionated approach and that context must stay light. The guidance body is also the substance the public showcase will be judged on — a polished front door over bloated guidance would not be credible. It ranks below the audit only because the audit tells us precisely what to cut.

**Independent Test**: Can be fully tested by comparing any streamlined file against its previous version — every actionable rule still present, narrative gone, voice consistent — and by comparing the total corpus size before and after.

**Acceptance Scenarios**:

1. **Given** a guidance file containing historical narrative (how a rule came to be, references to past refactors or renamed concepts), **When** it is streamlined, **Then** the narrative is gone and each rule it carried remains, stated once in imperative present tense.
2. **Given** a before/after inventory of actionable rules across the corpus, **When** compared, **Then** zero rules are lost or weakened except by an explicit, maintainer-visible decision recorded in the findings report.
3. **Given** any three streamlined guidance documents sampled together, **When** read in sequence, **Then** they read in a single consistent voice — opinionated, imperative, and concise — with no hedging filler or tool-generated commentary.
4. **Given** the streamlined corpus, **When** measured, **Then** it meets the size-reduction target defined in Success Criteria.

---

### User Story 3 - A public front door worthy of the work (Priority: P3)

As a company, when an outside senior engineer lands on our public repository, they should understand within minutes what the template is, the engineering philosophy behind it, and how to start a project from it — and come away with the impression of a quality-driven, world-class team.

**Why this priority**: The public showcase is the company's stated goal for publishing the repository. It follows the streamlining pass because the front door's promise ("opinionated, concise, quality-driven") must be true of the guidance behind it before it is made.

**Independent Test**: Can be fully tested by having someone unfamiliar with the repository read only the front-door document and then correctly state what the template is, its philosophy, and the first steps to use it.

**Acceptance Scenarios**:

1. **Given** an outside engineer landing on the repository, **When** they read the front-door document, **Then** it states what the template is, the opinionated philosophy it encodes, and how to start a new project from it — without requiring any internal context.
2. **Given** the repository at release time, **When** inspected, **Then** it carries an explicit permissive license and contains no internal-only working artifacts whose removal the maintainer approved in the findings report.
3. **Given** the repository's presentation as a whole (front door, directory naming, document titles), **When** browsed, **Then** it is coherent and self-explanatory — nothing looks half-finished except placeholders that are clearly framed as deliberate instantiation points.
4. **Given** any visitor to the public repository, **When** they view the front door or the design guide, **Then** the Cavalry brand mark and attribution make unmistakable whose work this is, using brand assets stored inside this repository.

---

### User Story 4 - Two clean tiers, uniform stack packs (Priority: P4)

As an agent or developer working in an instantiated project, I want the generic guidance files to carry only high-level, stack-agnostic direction and the stack packs to carry the implementation-level detail, with no contradiction between the two — and as a maintainer authoring future stacks, I want every stack pack to follow the same canonical structure, differing only where the stacks genuinely differ, so adding a new stack is predictable and comparing stacks is trivial.

**Why this priority**: A contradiction between tiers silently corrupts every project built from the template — and would be embarrassing in a public showcase. Structural drift between packs compounds with every future stack added. Fixing tier alignment presupposes the audit (P1) has located the conflicts and overlaps with the streamlining pass (P2), so it lands after them.

**Independent Test**: Can be fully tested by reading each stack pack side by side with its generic counterpart (backend, frontend, db, infra) and confirming no instruction in the pack contradicts the generic tier, and by comparing the packs with each other and confirming they share one structure.

**Acceptance Scenarios**:

1. **Given** any generic guidance file, **When** reviewed after the change, **Then** it contains no stack-specific implementation detail — that detail lives only in stack packs.
2. **Given** each stack pack document and its generic counterpart, **When** read together, **Then** no pack instruction contradicts the generic tier, and any sanctioned deviation is explicitly labelled as an exception in the pack.
3. **Given** a conflict discovered during the work, **When** it is resolved, **Then** the generic tier's rule prevails unless the maintainer explicitly sanctions the exception.
4. **Given** any two stack packs, **When** compared side by side, **Then** they share the same document set and cover the same areas in the same shape, and any divergence reflects a genuine difference between the stacks, stated explicitly rather than silently omitted.
5. **Given** a maintainer authoring a future stack pack, **When** they start, **Then** a documented canonical pack structure exists for them to follow.

---

### User Story 5 - No instruction can be silently missed (Priority: P5)

As the maintainer, I want every instruction file that agents must obey to be either automatically loaded or explicitly pointed to (with a "read this before working on X" reference) from a file that is automatically loaded, so no binding guidance can be skipped just because of its file name.

**Why this priority**: A missed instruction defeats the purpose of the template, but the audit (P1) already answers whether the risk is real and how large it is; this slice is the wiring fix and can follow once the map exists.

**Independent Test**: Can be fully tested by tracing each agent-binding instruction file back to an automatically loaded file and confirming the chain is at most one explicit reference deep.

**Acceptance Scenarios**:

1. **Given** any instruction file agents must obey, **When** its loading path is traced, **Then** it is either loaded automatically or referenced from an automatically loaded file in at most one hop, with the reference stating when it must be read.
2. **Given** a document intended for humans browsing the repository, **When** reviewed, **Then** it is identifiable as human-facing and contains no agent-binding rule that exists nowhere else.

---

### Edge Cases

- Narrative that turns out to be load-bearing (e.g., a recorded decision that justifies a rule): the decision survives as a one-line rule or learnings entry; only the story around it is cut.
- A stack pack that genuinely must deviate from generic guidance: the deviation is kept only as an explicitly labelled exception — never as a silent contradiction.
- An area that genuinely does not apply to a particular stack (today, one pack ships without an infrastructure document while the other two have one): the pack says so explicitly in its canonical place rather than silently omitting the document, so absence is always a statement, never an oversight.
- Intentional placeholders (unfilled toolchain commands, day-1 checklist items) are part of the template's design and must not be flagged or removed as bloat — but in a public repository they must be clearly framed as deliberate instantiation points, not unfinished work.
- Vendored third-party tooling (the spec-workflow skills and their templates) is audited for problems but not rewritten by the streamlining pass.
- Historical feature specs produced while building the template itself: the audit must recommend whether they belong in a public template that ships to fresh projects, and the maintainer decides.
- Documents that serve two audiences (humans browsing the repo and agents working in it): the remedy must preserve both — mass-renaming human-facing documents to the auto-loaded name is not an acceptable fix.
- Unsuitable content found in version history (not just the working tree): remediation rewrites published history, which is destructive — it is reported as release-blocking and applied only with explicit maintainer approval.
- Brand assets originate in another company repository: the asset files are copied into this repository — the public repo must never reference an internal or private location, which would itself be a release-blocking finding.
- "Award-winning" has no objective judge: the spec holds it to measurable proxies (consistency, concision, zero contradictions, fast outside-reader comprehension, zero embarrassing artifacts) rather than an unfalsifiable impression.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The audit MUST cover 100% of the repository's guidance and documentation files and its structural artifacts (workflow definitions, issue and PR templates, ignore rules, directory layout, spec-workflow configuration).
- **FR-002**: Every finding MUST record its location, a description of the issue, the convention or stated principle it violates, a severity (including a release-blocking tier for public-readiness issues), and a recommended remedy.
- **FR-003**: The report MUST definitively explain how the coding agent discovers instruction files — which are loaded automatically and which are read only on explicit reference — and list every instruction file currently at risk of being missed.
- **FR-004**: Streamlining MUST remove historical context, change narrative, and self-referential commentary from guidance files while preserving every actionable rule; any removal or weakening of a rule MUST be an explicit, maintainer-visible decision.
- **FR-005**: After the change, generic guidance files MUST contain only stack-agnostic guidance; implementation-level detail MUST live in stack packs.
- **FR-006**: After the change, no stack pack instruction may contradict the generic tier; where the two disagreed, the generic tier prevails unless a deviation is explicitly labelled as a sanctioned exception.
- **FR-007**: Every agent-binding instruction file MUST be reachable from automatically loaded guidance in at most one explicit reference hop, with the reference stating when the file must be read.
- **FR-008**: The audit MUST verify that cross-references between guidance files resolve — no pointers to files that do not exist and no instruction file that nothing points to.
- **FR-009**: The template MUST remain instantiation-ready throughout: intentional placeholders preserved, the day-1 checklist accurate, and no broken references introduced by renames, moves, or deletions.
- **FR-010**: All structural or destructive changes (deleting, renaming, or moving files, or rewriting version history) MUST appear in the findings report and be approved by the maintainer before they are applied.
- **FR-011**: The audit MUST check the entire repository — working tree and version history — for content unsuitable for public release (credentials, tokens, personal data, internal-only URLs or references) and report every occurrence as a release-blocking finding.
- **FR-012**: The repository's front-door document MUST state what the template is, the opinionated philosophy it encodes, and how to start a new project from it, in terms an outside senior engineer can absorb without internal context.
- **FR-013**: The public repository MUST carry an explicit permissive (non-restrictive) license, per the maintainer's direction; its absence is a release-blocking finding.
- **FR-014**: All guidance MUST read in a single consistent voice — opinionated, imperative, and concise — across every file in the corpus.
- **FR-015**: All stack packs MUST follow one canonical structure — the same document set, coverage areas, and organization — with stack-specific differences expressed inside that structure and areas that do not apply declared explicitly; the canonical structure MUST be documented so future packs follow it.
- **FR-016**: The front door MUST display the Cavalry brand mark and attribute the template to Cavalry, and the design guide MUST carry the same attribution; the brand assets MUST live inside this repository so the public repo is self-contained.

### Key Entities

- **Guidance corpus**: the set of instruction and documentation files that direct how software is built from this template — root guidance, per-area guidance, readme-style documents, stack packs, and add-on documents.
- **Finding**: a single identified issue — location, description, violated convention or principle, severity (release-blocking, high, medium, low), recommended remedy, and (once decided) the maintainer's disposition.
- **Guidance tier**: the level a rule belongs to — generic (always true for any project from this template) or stack pack (true only for the concrete stack adopted at instantiation).
- **Instruction-loading chain**: the path by which an agent encounters a file — loaded automatically by naming convention, or read because an automatically loaded file explicitly points to it.
- **Release gate**: the set of findings that must be resolved before the repository can be made public — unsuitable content anywhere in working tree or history, missing license, missing front-door positioning.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of guidance and structural files appear in the audit report with an explicit verdict (no issues, or one or more findings).
- **SC-002**: The maintainer's instruction-discovery question is answered in writing, with every current instruction file classified by how (or whether) an agent will encounter it.
- **SC-003**: The guidance corpus shrinks by at least 25% in total word count while a before/after rule inventory shows zero actionable rules lost without an explicit decision.
- **SC-004**: A side-by-side read of every stack pack against its generic counterpart finds zero unlabelled contradictions.
- **SC-005**: Every agent-binding instruction file is reachable from automatically loaded guidance within one reference hop; none is orphaned.
- **SC-006**: A dry-run instantiation following the day-1 checklist encounters no broken references, missing files, or stale placeholders introduced by the cleanup.
- **SC-007**: A newcomer can state the binding rules for any one area after reading at most two documents: the root guidance plus that area's guidance file.
- **SC-008**: A reader unfamiliar with the company can correctly state what the template is, its philosophy, and how to start a project from it within 10 minutes of landing on the repository, using only the front-door document.
- **SC-009**: Zero release-blocking findings remain open at release time: no credentials, personal data, or internal-only references anywhere in the working tree or version history, and a permissive license and positioning statement are present.
- **SC-010**: A reviewer sampling any three guidance documents finds one consistent voice — opinionated, imperative, concise — with no tool-generated filler or historical narrative.
- **SC-011**: A side-by-side comparison of all stack packs shows one shared structure — same document set and coverage areas — with every divergence explicitly declared as a genuine stack difference, and a documented canonical structure exists for authoring future packs.
- **SC-012**: A visitor viewing the front door or the design guide sees the Cavalry brand mark and attribution, rendered from assets stored in this repository — no reference to any internal or private location.

## Assumptions

- "Established conventions and best practices" means current best practice for agent-facing guidance (concise, imperative, stated once, hierarchically organized) plus the template's own stated principles; where the two disagree, the template's stated principles win and the disagreement is flagged.
- "Award-winning / world-class" is operationalized through the measurable proxies in Success Criteria (consistency, concision, zero contradictions, fast outside-reader comprehension, zero release-blocking artifacts); no literal award or external judge adjudicates the outcome.
- The vendored spec-workflow tooling and its templates are third-party: the audit flags problems, but the streamlining pass does not rewrite them.
- The applications are placeholder skeletons, so the audit targets guidance, structure, and configuration rather than application source code.
- The 25% size-reduction target is a default the maintainer can tune; the hard constraint is zero rules lost, not the percentage.
- The P1 report acts as the gate: the maintainer reviews findings before the P2–P5 slices apply structural or destructive changes.
- Historical spec directories from building the template are audit subjects like any other file; the report recommends a disposition and the maintainer decides.
- Human-facing documents keep their conventional names for repository browsing; discoverability is fixed by wiring explicit references from auto-loaded files, not by mass-renaming.
- The maintainer directed a non-restrictive license (2026-07-03); MIT is selected as the most permissive mainstream choice — Apache-2.0 was considered and set aside because its patent and notice obligations add restriction the maintainer didn't ask for.
- Cavalry's official brand asset pack (mark and lockup variants) exists in the company's website repository; the needed files are copied into this repository at implementation time so the public repo stands alone.
- Actually making the repository public is a maintainer action outside this feature's scope; the feature's job is to make the repository release-ready as defined by the release gate.
- The canonical stack-pack structure is derived from the existing packs (their common shape wins by default); which divergences count as "genuine stack differences" versus drift is recommended by the audit and decided by the maintainer.
