# Feature Specification: SEO Add-on

> **Historical record (annotated 2026-07-07).** Two later changes supersede parts of this spec. **(1)** `004-seo-structural-expansion` reversed the scope boundary — the structural work of keyword targeting, ads-landing readiness, rank tracking, and page-speed is now in scope (R12–R20, S8–S10, G4–G6; the README budget rose to ~110 lines). **(2)** The folder-isolation relocation moved pack bindings to `add-ons/seo/bindings.md` (a fourth pack, `vercel-ssr`, shipped after this spec) and removed the root-file enumerations FR-013/US3 required; a later consistency review restored the add-on's row in the `add-ons/README.md` registry table (the Day-1 registry lists every shipped add-on) while bindings and specs stay in this directory. Read the *Scope* section, US3, FR-013, SC-003, and SC-006 as the 003-era record.

**Feature Branch**: `003-seo-addon`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "i would like to add an add-on for SEO optimised application" — refined 2026-07-07: "enhance seo add-on to include Structural work only: keyword strategy, paid search, rank tracking, and page-speed ranking factors are out of scope."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Adopt an agnostic SEO playbook at Day-1 (Priority: P1)

A team instantiates the template for a product with public pages — marketing pages, listings, articles, profiles — and keeps the SEO add-on at Day-1. From then on, anyone (human or agent) touching a public page follows one written discipline for being found by search engines and previewed correctly when shared: which routes are indexable, how indexable pages must render for crawlers, canonical URLs, honest status codes, centralized metadata, structured data, generated sitemap/robots, environment isolation, and verification by observation.

**Why this priority**: The guidance document *is* the capability — nothing else in this feature has value without it. Single-page-app templates fail search discoverability silently by default (pages empty without scripting, "not found" screens served as successes), and an unindexed product is an expensive failure discovered months late. Codifying the discipline where agents are already required to read it prevents that class of defect at the source.

**Independent Test**: In a fresh instantiation with the add-on kept, ask an agent to plan a public page and confirm the standing instructions route it through the add-on's guidance; separately, review the guidance document against the template's published add-on invariants. Delivers a complete, binding SEO discipline even before any stack pack addresses it.

**Acceptance Scenarios**:

1. **Given** a fresh instantiation where the add-on directory is kept, **When** work touches a public-facing page, **Then** the standing instructions require reading and following the add-on's guidance (adoption is keeping the directory; no extra wiring).
2. **Given** the add-on's guidance document, **When** reviewed against the published add-on invariants, **Then** it is stack-agnostic, names what a stack must supply, names its interactions with base rules and other add-ons, and stays within the size discipline.
3. **Given** a new route added under the guidance, **When** it ships, **Then** it carries an explicit indexable-or-not classification recorded at the route registry, and an unclassified route is treated as a defect.
4. **Given** an indexable page built under the guidance, **When** fetched without client-side scripting, **Then** the full content, unique title and description, and one absolute canonical URL are present in the raw response.
5. **Given** a request for an entity that does not exist, **When** a crawler fetches it, **Then** the response status states "not found" — never a success status wrapping an error screen.
6. **Given** a staging or preview environment, **When** any page on it is fetched, **Then** the response instructs crawlers not to index it, this failing closed to "not indexable", and an automated test asserts it.

---

### User Story 2 - Get concrete guidance for the chosen stack (Priority: P2)

A team that adopted both a stack pack and the SEO add-on reads their pack and finds either the concrete bindings — which rendering mechanism makes indexable pages complete for crawlers, where metadata is set, how sitemap/robots are produced, how permanent redirects and "not found" responses are served — or an explicit, reasoned statement that the pack's form factor cannot support the add-on and what to do instead.

**Why this priority**: The agnostic playbook is viable alone (its stack-seam section tells any project what to supply), so bindings are second — but without them each adopting team re-derives the same answers, and a team on an incompatible stack could discover mid-build that the guidance is unimplementable there.

**Independent Test**: For each shipped stack pack, determine the add-on's status (bound with every seam item named, or declared unbound with a reason) from that pack's own files alone.

**Acceptance Scenarios**:

1. **Given** a shipped pack whose stack can meet the add-on's bar, **When** its appendix is read, **Then** it names each item the add-on's stack-seam section asks for: the rendering mechanism, the metadata home, the sitemap/robots home, the redirect home, and the missing-entity handling.
2. **Given** a shipped pack whose form factor cannot meet the add-on's rendering bar, **When** its manifest is read, **Then** it declares the add-on unbound, states why, and points at the workable alternative for a project that grows a public surface.
3. **Given** any shipped pack, **When** only that pack's files are read, **Then** the add-on's bound-or-unbound status is unambiguous.

---

### User Story 3 - Discover the add-on at every choice point (Priority: P3)

A team running the Day-1 checklist sees the SEO add-on named everywhere add-ons are enumerated — the checklist's choose-your-add-ons step, the repository overview, the add-on registry table, and the root instruction file's map — so keeping or deleting it is a conscious decision, not an omission.

**Why this priority**: Activation is automatic once the directory is kept, so the enumerations affect only the visibility of the choice; the capability works without them.

**Independent Test**: Search each of the template's add-on enumerations for the SEO add-on's name and its one-line capability description.

**Acceptance Scenarios**:

1. **Given** the Day-1 checklist's add-on step, **When** read, **Then** the SEO add-on appears among the named options.
2. **Given** the add-on registry's capability table, **When** read, **Then** the SEO add-on has a row stating its capability and what the active pack must supply.
3. **Given** the root instruction file's repository map and the repository overview table, **When** read, **Then** their add-on example lists include SEO.

---

### Edge Cases

- **Fully login-walled product**: there is no indexable surface — the guidance directs deleting the add-on rather than half-applying it.
- **Mostly-private app with a small public shell**: the guidance directs adopting the add-on and classifying every private route non-indexable, rather than skipping adoption.
- **A pack that replaces the base route registry with its own mechanism**: the classification and sitemap rules attach to whatever that pack designates as its registry; the add-on must not contradict a pack's registered conflicts.
- **Multilingual products**: language-alternate declarations derive from the same locale set the base internationalisation rules define — never a second, hand-kept locale list.
- **Serving crawlers different content than users**: explicitly forbidden; the fix for an unindexable page is rendering, not user-agent branching.
- **Staged copy outranking production**: prevented by the fail-closed rule — only the configured production origin is ever indexable.

## Requirements *(mandatory)*

### Scope

Structural work only — decided by the template owner (2026-07-07), superseding the earlier assumption:

- **In scope**: the structural/technical discoverability of public pages — being crawled, indexed, and previewed correctly when shared.
- **Out of scope**: keyword strategy, paid search, rank tracking, and page-speed ranking factors. Performance stays owned by the template's existing quality guidance; nothing in this add-on duplicates it.

### Functional Requirements

- **FR-001**: The template MUST offer the SEO capability as an optional add-on under the established add-on mechanism: adopted by keeping its directory at Day-1, dropped by deleting it, and activated by the existing standing instruction to follow every kept add-on.
- **FR-002**: The add-on's guidance MUST satisfy the template's published add-on invariants: stack-agnostic wording throughout, a section naming what the active stack must supply, a section naming interactions with base rules and other add-ons, and the size discipline.
- **FR-003**: The guidance MUST require every route to carry an explicit indexable-or-not classification, recorded where the project's route registry lives, with an unclassified route treated as a defect.
- **FR-004**: The guidance MUST require indexable pages to be complete for crawlers and link-preview bots without client-side scripting, with the concrete rendering mechanism left to the active stack.
- **FR-005**: The guidance MUST require exactly one canonical URL per page: variants redirect permanently at the server, each indexable page declares its canonical absolutely, and the canonical origin comes from validated configuration rather than the incoming request.
- **FR-006**: The guidance MUST require honest status codes: a missing entity answers "not found" (or "gone"), never a success status with an error screen, and moved pages answer permanent server-side redirects.
- **FR-007**: The guidance MUST require all page metadata (titles, descriptions, share-preview tags) to flow through one shared mechanism, with copy kept in the project's central copy home.
- **FR-008**: The guidance MUST require structured entity markup only for entity types the product actually has, generated from the same data the page shows, and MUST forbid markup describing content the page does not show.
- **FR-009**: The guidance MUST require the sitemap and crawler-rules files to be generated from the route registry (plus entity data for parameterized routes), never hand-maintained, with the sitemap listing exactly the indexable routes.
- **FR-010**: The guidance MUST require non-production environments to refuse indexing, failing closed — only the configured production origin is ever indexable — and MUST require that refusal to be asserted by an automated test.
- **FR-011**: The guidance MUST define verification by observation: fetching pages without client-side scripting and inspecting content, status codes, canonicals, and crawler directives — never inferring correctness from code alone.
- **FR-012**: Every shipped stack pack MUST either bind the add-on concretely (naming each item the stack-seam section asks for) or declare in its manifest that it leaves the add-on unbound, with the reason and the workable alternative.
- **FR-013**: The add-on MUST appear in every place the template enumerates add-ons: the add-on registry table, the Day-1 checklist step, the repository overview, and the root instruction file's map.
- **FR-014**: The add-on's guidance MUST state the scope boundary where an adopter first reads it — structural work only, naming keyword strategy, paid search, rank tracking, and page-speed ranking factors as out of scope — so the Day-1 keep-or-delete decision is made against an accurate account of what the add-on covers.

### Key Entities

- **Add-on guidance document**: the agnostic SEO playbook — approach rules, verification-by-observation section, the stack seam (what a pack must supply), and interactions with base rules and sibling add-ons.
- **Pack binding entry**: per shipped stack pack, either the concrete bindings for each seam item or a declared-unbound statement with reason; readable from that pack's own files.
- **Route classification**: the indexable-or-not attribute every route carries, recorded at the project's route registry; the source the sitemap and crawler-rules generation reads.
- **Adoption choice points**: the enumerations through which an adopter discovers and chooses the add-on — Day-1 checklist step, repository overview, add-on registry table, root instruction map.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A template adopter can make the keep-or-delete decision for this add-on from the Day-1 checklist alone — the choice point names it and links a one-page description readable in under 5 minutes.
- **SC-002**: The guidance document passes 100% of the template's published add-on invariants on review.
- **SC-003**: For 3 of 3 shipped stack packs, the add-on's status — bound with every seam item named, or declared unbound with a reason — is determinable from that pack's own files, with zero packs silent on it.
- **SC-004**: Every behavioural rule in the guidance is verifiable by observing a running application from the outside (fetching pages, inspecting responses); zero rules require reading an implementation to check.
- **SC-005**: An application built to the guidance exposes, observably: full content without client-side scripting on every indexable route, "not found" statuses for missing entities, exactly one canonical URL per page, a sitemap listing only indexable routes, and non-production origins that refuse indexing.
- **SC-006**: The guidance names all four out-of-scope items (keyword strategy, paid search, rank tracking, page-speed ranking factors) in its opening description, and zero rules in the guidance address any of them.

## Assumptions

- Beyond the decided exclusions in *Scope*, analytics tooling generally is also out of scope.
- The add-on follows the template's established add-on mechanism: guidance-as-text only — no dependencies, scaffolding, or runtime code ship with it.
- The three currently shipped stack packs are the binding surface for FR-012; future packs inherit the bind-or-declare obligation from the existing pack-authoring rules.
- The template itself has no runnable application, so the runtime-facing rules (FR-003 through FR-011) are verified in instantiated projects; the template's own acceptance bar is the review-based checks (invariants, pack statuses, enumerations — FR-001, FR-002, FR-012, FR-013).
- The add-on composes with, and never contradicts, the base contracts and pack conflict registers; a real contradiction is a defect to flag, per the template's precedence rules.
