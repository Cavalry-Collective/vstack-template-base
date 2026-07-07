# Feature Specification: SEO Add-on — Structural Expansion

**Feature Branch**: `004-seo-structural-expansion`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "please enhance seo add-on to include Structural work only: keyword strategy, paid search, rank tracking, and page-speed ranking factors." — read as reversing the exclusion decided in `003-seo-addon`: the **structural** work of those four areas (what is built once into the project and observable from outside) moves in scope; the **ongoing practice** of each (keyword research, campaign management, running rank reports, hands-on performance tuning) stays out.

## Clarifications

### Session 2026-07-07

- Q: Reverse the shipped add-on's exclusion of the four areas, keep it, or include even their ongoing practice? → A: Reverse it — the structural work of all four areas moves in scope; the ongoing practice of each stays out.
- Q: Which new rules join the day-1 CI gates versus verify-by-observation? → A: Gate the registry-derivable checks (intent record present, no same-locale duplicate intents) plus the payload budget; orphan reachability and loading-experience thresholds are verified by observation only.
- Q: If the expansion approaches the add-on size invariant (well under ~150 lines), split, relax, or trim? → A: One document — the expansion stays in the existing add-on README, trimmed to fit comfortably under the invariant.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every indexable page targets one recorded search intent (Priority: P1)

A team building a public page under the add-on's guidance records, at the same home as the page's indexable classification, the search intent the page targets. The page's title, description, slug, and single top-level heading are written against that record; no second indexable page targets the same intent in the same locale; and every indexable page is reachable through descriptive, crawlable links from the rest of the indexable surface — not only via the sitemap.

**Why this priority**: This is the half of "being found" the add-on currently lacks entirely — a page can be perfectly crawlable and still rank for nothing, or two pages can silently compete for the same query and split their standing. The intent record is also the input the rank-tracking story consumes, making it the foundation of the expansion.

**Independent Test**: Review the updated guidance against the add-on invariants; in an instantiated project, ship one page under it and fetch it raw — one top-level heading, title and slug coherent with the recorded intent; add a second page recording the same intent — surfaced as a defect; leave a page linked from nowhere — surfaced as an orphan defect.

**Acceptance Scenarios**:

1. **Given** a new indexable route, **When** it ships, **Then** it carries a recorded target search intent at the same home as its indexable-or-not classification, and a missing record fails a day-1 gate in the project's suite.
2. **Given** two indexable pages recording the same target intent for the same locale, **When** the project's suite runs, **Then** the duplication fails a day-1 gate and is resolved by merging or re-targeting one page.
3. **Given** an indexable page built under the guidance, **When** fetched without client-side scripting, **Then** it has exactly one top-level heading, heading levels descend without skipping, and title, slug, and top heading all reflect the recorded intent.
4. **Given** an indexable page listed in the sitemap but linked from no other indexable page, **When** internal links are traversed, **Then** the orphan is a defect — sitemap presence alone is not linkage.
5. **Given** the add-on's opening description, **When** read at the Day-1 keep-or-delete decision, **Then** keyword strategy's structural side is stated in scope and keyword research/selection is stated out of scope.

---

### User Story 2 - Indexable pages meet the loading-experience ranking bar (Priority: P2)

A team ships indexable pages that meet the search engines' published loading-experience thresholds — main-content loading speed, responsiveness to input, visual stability — because the structural causes of failing them are ruled out at build time: media reserves its space before it arrives, primary content never waits on client scripting or user interaction, and indexable pages carry a payload budget the project's suite asserts.

**Why this priority**: Page experience is a stated ranking input, and its common failures are structural defects cheapest to prevent at build time — but a fast page that targets nothing still ranks for nothing, so this follows the intent discipline.

**Independent Test**: Build an indexable page under the guidance and measure the running page against the engines' published thresholds; remove a media dimension declaration or gate primary content behind scripting — the verification steps and the suite catch it.

**Acceptance Scenarios**:

1. **Given** an indexable page built under the guidance, **When** its loading experience is measured on the running app, **Then** it meets the search engines' currently published thresholds for main-content loading, input responsiveness, and visual stability.
2. **Given** media or embedded content on an indexable page, **When** the page loads, **Then** the space it occupies is reserved before it arrives — no visible layout shift.
3. **Given** an indexable page's primary content, **When** fetched without client-side scripting and without interaction, **Then** it is present and complete — never deferred behind scripting or a user gesture.
4. **Given** the payload budget for indexable routes, **When** the project's suite runs, **Then** an over-budget indexable page fails the gate.
5. **Given** that search engines revise their thresholds over time, **When** the guidance is read, **Then** its bar is the engines' published values — the document names the source of truth and freezes no numbers.

---

### User Story 3 - Point any rank tracker at the product without hand-built lists (Priority: P3)

Once live, the team registers the product with search-engine consoles and a rank-tracking tool: ownership verification is served from validated configuration so it survives redeploys, and the page-to-intent inventory a tracker consumes derives from the route registry and the intent records — never a hand-kept list. Because URL renames already keep permanent redirects, tracking history survives restructures.

**Why this priority**: It only pays off once the product is live and someone is watching results, and its inventory half builds on the intent records of the first story — verification and continuity stand alone.

**Independent Test**: In an instantiated project, verify site ownership using only what the guidance requires, redeploy, and confirm verification holds; derive the page-to-intent inventory from the registry and confirm it lists exactly the indexable pages with their recorded intents.

**Acceptance Scenarios**:

1. **Given** a search-engine console's ownership check, **When** the verification response is requested from the production origin, **Then** it is served from validated configuration and survives a redeploy — never a hand-dropped file.
2. **Given** the route registry and intent records, **When** the page-to-intent inventory is derived, **Then** it pairs exactly the indexable URLs with their recorded intents in machine-readable form, and regenerating it produces no diff.
3. **Given** an indexable page renamed after launch, **When** the old URL is fetched, **Then** it answers a permanent redirect to the new slug (the existing URL-stability rule), so external tracking continuity survives.

---

### User Story 4 - Landing URLs are ad-ready by construction (Priority: P3)

A team buying search ads lands clicks on URLs that answer success directly — no redirect chains — render complete without client scripting so ad-review bots see the real page, tolerate arbitrary advertising click parameters without changing content, and never leak those parameters into canonicals or the sitemap.

**Why this priority**: It only matters to teams buying traffic, and it is the smallest structural surface — mostly sharpening existing variant and redirect rules for the advertising case.

**Independent Test**: Fetch a landing URL with arbitrary click parameters appended and compare against the parameter-free page; inspect its canonical and the sitemap; follow an alias to the landing URL and count the hops.

**Acceptance Scenarios**:

1. **Given** a landing URL with arbitrary advertising click parameters appended, **When** fetched, **Then** the content is identical to the parameter-free page, the declared canonical is parameter-free, and no parameterized variant appears in the sitemap.
2. **Given** an ad click destination, **When** fetched, **Then** it answers success directly; a vanity alias is at most one permanent redirect, never a chain.
3. **Given** a dedicated landing URL space, **When** it ships, **Then** it is deliberately classified indexable-or-not like any other route — never left unclassified.

---

### User Story 5 - Packs bind the expanded seam (Priority: P2)

A team that adopted a stack pack and the SEO add-on finds in their pack either concrete bindings for each new seam item — where the intent record lives, how the ownership-verification response is served, how the payload budget and loading-experience measurements are asserted — or an unbound declaration re-checked and extended to stay accurate against the expanded add-on.

**Why this priority**: The agnostic playbook is viable alone (its stack-seam section tells any project what to supply), but a silent pack would leave adopters re-deriving answers or, worse, an unbound pack's declaration describing an add-on that no longer exists.

**Independent Test**: For each shipped stack pack, determine the expanded add-on's status — bound with every new seam item named, or unbound with an accurate extended declaration — from that pack's own files alone.

**Acceptance Scenarios**:

1. **Given** a shipped pack that binds the add-on, **When** its appendix is read, **Then** each new seam item is answered, keyed by id, one line each, alongside the existing ones.
2. **Given** a shipped pack that declares the add-on unbound, **When** its declaration is read, **Then** it remains accurate against the expanded scope — the reason, the workable alternative, and which residual rules still apply to a publicly reachable origin.
3. **Given** any shipped pack, **When** only that pack's files are read, **Then** the expanded add-on's bound-or-unbound status is unambiguous.

---

### User Story 6 - Every description of the add-on tells the new truth (Priority: P3)

A team running the Day-1 checklist, reading the add-on registry table, or scanning the repository overview sees the expanded capability described consistently — and nowhere does the template still claim the four areas are out of scope.

**Why this priority**: The capability works once the guidance itself is updated; the surrounding descriptions affect only the accuracy of the adoption decision.

**Independent Test**: Search every template surface that describes the add-on for the expanded capability statement, and search the whole template for surviving statements of the old exclusion.

**Acceptance Scenarios**:

1. **Given** the add-on registry's capability table, **When** read, **Then** the SEO row states the expanded capability and the full seam range the pack must supply.
2. **Given** the whole template outside historical spec records, **When** searched, **Then** zero current statements remain that keyword strategy, paid search, rank tracking, or page-speed ranking factors are out of scope.

---

### Edge Cases

- **Multilingual products**: intent uniqueness is per locale — locale equivalents of one page share the same intent translated; the existing locale-alternates rule is unchanged.
- **User-generated media of unknown dimensions**: the space is still reserved structurally before the media arrives; unknown size is not an exemption from layout stability.
- **Search engines revise their thresholds**: the guidance binds to the engines' published values and freezes no numbers, so a revision changes the bar without changing the document.
- **An ad platform introduces a new click parameter**: unclassified parameter variants are already non-indexable and canonical to their base page under the existing crawl-trap rule, so a new parameter cannot create a trap.
- **The unbound pack (phone-first client)**: the expanded rules join its unbound declaration; the declaration restates the residual posture — which rules still bind any publicly reachable origin.
- **Page copy drifts from its recorded intent**: iterating copy updates the intent record in the same change, or the page is deliberately re-targeted — a stale record is a defect, like stale configuration documentation.
- **Non-indexable routes**: carry no intent record and no loading-experience obligation from this add-on — the expanded discipline binds the indexable surface only.

## Requirements *(mandatory)*

### Scope

Decided by the template owner (2026-07-07), superseding the boundary recorded in `003-seo-addon`:

- **In scope**: the **structural** work of keyword strategy, paid search, rank tracking, and page-speed ranking factors — what is built once into the project and observable from outside the running app.
- **Out of scope**: the **ongoing practice** of each — keyword research and selection, campaign purchase and management, running or reading rank reports, and hands-on performance tuning operations. Analytics and conversion measurement remain out of scope.

### Functional Requirements

- **FR-001**: The add-on's guidance MUST state the expanded scope boundary where an adopter first reads it — the structural work of all four areas in scope, the ongoing practice of each out of scope — so the Day-1 keep-or-delete decision is made against an accurate account.
- **FR-002**: The guidance MUST require every indexable route to carry a recorded target search intent at the same home as its indexable-or-not classification, with a missing record failing a day-1 gate in the project's suite.
- **FR-003**: The guidance MUST require at most one indexable page per target intent per locale, with same-locale duplication failing a day-1 gate, resolved by merging or re-targeting.
- **FR-004**: The guidance MUST require an indexable page's title, description, slug, and top-level heading to be written against its recorded intent, with exactly one top-level heading and heading levels that descend without skipping.
- **FR-005**: The guidance MUST require every indexable page to be reachable through at least one crawlable link with descriptive anchor text from another indexable page — sitemap presence alone does not satisfy reachability; this is checked by observation on the running app, not gated.
- **FR-006**: The guidance MUST require pages to serve identical content regardless of appended advertising click parameters, and MUST keep such parameters out of declared canonicals and the sitemap — extending the existing variant rules to the advertising case by name.
- **FR-007**: The guidance MUST require ad landing URLs to answer success directly — a vanity alias is at most one permanent redirect, never a chain — and dedicated landing URL spaces to be deliberately classified like any route.
- **FR-008**: The guidance MUST require search-engine ownership verification to be served from validated configuration so it survives redeploys — never a hand-placed artifact.
- **FR-009**: The guidance MUST require the page-to-intent inventory to be derivable from the route registry and intent records in machine-readable form — the input any rank-tracking tool consumes — never hand-maintained.
- **FR-010**: The guidance MUST require indexable pages to meet the search engines' currently published loading-experience thresholds (main-content loading, input responsiveness, visual stability), naming the published values as the source of truth and freezing no numbers.
- **FR-011**: The guidance MUST rule out the structural causes of failing those thresholds: media and embeds reserve their space before arrival, primary content is never deferred behind client scripting or user interaction, and indexable routes carry a payload budget asserted by the project's suite as a day-1 gate.
- **FR-012**: Every new rule MUST follow the add-on's established style: behaviour observable from outside the running app and a one-to-one entry in the verification-by-observation section. Exactly three new checks join the day-1 gates: intent record present for every indexable route, no same-locale duplicate intents, and the payload budget; orphan reachability and loading-experience thresholds are verified by observation only.
- **FR-013**: The updated guidance MUST continue to satisfy the template's published add-on invariants — stack-agnostic wording, the stack-seam section extended with the new seam items keyed like the existing ones, the interactions section updated (including who owns performance: the base quality guidance keeps general performance; this add-on owns only the indexable-page ranking-factor slice), and the size discipline. The expansion stays in the single existing document, trimmed to fit — no sibling add-on, no relaxed invariant.
- **FR-014**: Every shipped stack pack MUST either bind each new seam item concretely or extend its unbound declaration to remain accurate against the expanded add-on, readable from that pack's own files.
- **FR-015**: Every template surface that describes the add-on (registry table, Day-1 checklist step, repository overview, root instruction map) MUST reflect the expanded capability, and zero statements of the superseded exclusion may remain outside historical spec records.

### Key Entities

- **Target intent record**: the search intent an indexable page targets, recorded alongside its classification at the route registry; the source for on-page coherence checks and the rank-tracking inventory.
- **Page-to-intent inventory**: the machine-readable pairing of indexable URLs and recorded intents, derived from the registry; what a rank-tracking tool is pointed at.
- **Ownership-verification response**: the artifact a search-engine console checks to prove site ownership, served from validated configuration.
- **Landing URL space**: a URL space designated as an advertising destination, deliberately classified and held to the direct-success, parameter-tolerant rules.
- **Loading-experience thresholds and payload budget**: the engines' published page-experience bar and the project's declared per-route weight ceiling; the budget is gated day-1, the thresholds verified by observation.
- **Expanded seam items**: the new stack-seam entries a pack binds — the intent-record home, the verification-response home, the budget/measurement home.
- **Scope boundary statement**: the opening description naming the four areas' structural side in scope and their ongoing practice out.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A template adopter can make the keep-or-delete decision from the Day-1 checklist and the add-on's one-page description in under 5 minutes, with the expanded boundary — all four areas structurally in, their ongoing practice out — stated where they read.
- **SC-002**: A repo-wide search finds zero current statements of the superseded exclusion outside historical spec records.
- **SC-003**: The updated guidance passes 100% of the template's published add-on invariants on review, including the size discipline.
- **SC-004**: Every new behavioural rule is verifiable by observing a running application from the outside, each with a one-to-one verification entry; zero rules require reading an implementation to check.
- **SC-005**: For 4 of 4 shipped stack packs, the expanded add-on's status — bound with every new seam item named, or unbound with an accurate extended declaration — is determinable from that pack's own files, with zero packs silent.
- **SC-006**: An application built to the expanded guidance observably exhibits: one intent-coherent top-level heading per indexable page, no same-locale duplicate intents, every indexable page reachable by internal links, identical content under arbitrary advertising parameters with parameter-free canonicals, direct-success landing URLs, a configuration-served ownership verification, and indexable pages meeting the engines' published loading-experience thresholds.
- **SC-007**: A rank-tracking tool can be configured against the product using only artifacts the guidance requires — verification plus the derived page-to-intent inventory — with zero hand-built page or query lists.

## Assumptions

- Rank-tracking support means making the product trackable, not shipping or integrating a tracker; paid-search support means landing readiness, not campaign tooling; analytics and conversion measurement remain out of scope, consistent with `003-seo-addon`.
- The add-on remains guidance-as-text only — no dependencies, scaffolding, or runtime code ship with it.
- The four currently shipped stack packs are the binding surface for FR-014; future packs inherit the bind-or-declare obligation from the existing pack-authoring rules.
- The loading-experience bar defers to the search engines' currently published thresholds; the template freezes no numeric values of its own.
- The template itself has no runnable application, so the runtime-facing rules (FR-002 through FR-011) are verified in instantiated projects; the template's own acceptance bar is the review-based checks (FR-001, FR-012 through FR-015).
- The expanded add-on composes with, and never contradicts, the base contracts and pack conflict registers; a real contradiction is a defect to flag, per the template's precedence rules.
