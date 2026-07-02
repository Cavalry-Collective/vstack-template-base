# Feature Specification: Design Guide Enhancement — Screen Archetypes, Surface Layering, and Pattern Foundations

**Feature Branch**: `001-enhance-design-guide`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "please do deep research of the various design systems showcased here https://zeroheight.com/showcase/ — currently we have built a design_guide based on Ahoy. However, I want you to do deep research and see what else we need to enhance. I'm most worried that we will miss out important sections or parts. Components is intentionally left out btw, since for each project we will likely choose a different UI component library like antd or material ui etc. Currently when we use this template to create projects, the biggest problem is that UI feels very haphazard: things are not layered properly, every time we add a new component it writes something entirely new from scratch and inconsistent with the rest of the system, and page spacing etc are never consistent."

**Research base**: `design-system-survey.md` (same directory) — a survey of the 13 accessible
zeroheight-showcase systems, 10 major public design systems (including Ahoy, the guide's
model), and the published mechanisms mature systems use against exactly the failure modes
above. The survey found the existing guide at parity on foundations; every confirmed gap
sits one altitude up — how foundations compose into pages and patterns.

## Clarifications

### Session 2026-07-02

- Q: How are SC-001–SC-003 verified at ship time, given the template has no runnable app? → A: The guide validates itself as specimen — each new chapter ships live specimen figures that are the ship-time audit subject; SC-001, SC-002, and SC-004 are formally measured on the first real project built from the template and do not block this feature.
- Q: How much of the guide's hard rules duplicate into the always-read frontend instruction surface (FR-012)? → A: A minimal never-violate digest — one compact block limited to the hard gates, each line cross-referencing the guide chapter that owns the detail.
- Q: Is the seven-archetype starting set right? → A: Confirmed — all seven (collection/list, record detail, form, dashboard/overview, settings, multi-step flow, full-page utility).

## User Scenarios & Testing *(mandatory)*

The guide's readers are **app builders** (AI agents and developers building screens in
projects created from this template), **reviewers** (who judge whether built UI conforms),
and the **template maintainer** (who evolves the guide). "The guide" means the design
guide and its companion token source under `design/`; "the always-read instruction surface"
means the frontend contract file every builder is required to read before frontend work.

### User Story 1 - Start every screen from a named archetype (Priority: P1)

An app builder starting a new screen finds the one named **screen archetype** that matches
the screen's job (e.g. list/index, record detail, form, dashboard, settings, multi-step
flow, full-page utility). The archetype gives them the page's named zones in order, the
spacing between those zones, the content width, and how the zones behave across the
supported form factors — so the page starts structurally identical to every other page of
its type, and page-level spacing is never re-decided per page.

**Why this priority**: Inconsistent page structure and spacing is the reported #1 failure,
and the research shows page archetypes ("floorplans", "canonical layouts", "page
templates") are the single documented mechanism mature systems use to fix it. Every other
rule hangs off a predictable page frame, so this slice alone delivers visible consistency.

**Independent Test**: Have two builders (or two independent build sessions) each build a
different screen of the same archetype from only the enhanced guide; compare the two pages
structurally. Deliverable is testable without any other story shipped.

**Acceptance Scenarios**:

1. **Given** the enhanced guide, **When** a builder needs a screen of any common
   application type (browsing a collection, viewing/editing one record, submitting a form,
   monitoring status, adjusting settings, completing a multi-step task, or a full-page
   utility such as sign-in or not-found), **Then** exactly one named archetype matches, and
   it states: its purpose, when to use it, when *not* to use it (naming the alternative
   archetype), its zone skeleton, the named spacing for every zone gap, and its content
   width.
2. **Given** two screens of the same archetype built independently, **When** compared side
   by side, **Then** their page-level structure is identical — same edge gutters, same page
   header anatomy, same title-to-content gap, same section gaps — with zero unexplained
   deviations.
3. **Given** a screen idea that no archetype fits, **When** the builder consults the guide,
   **Then** an explicit escalation rule applies (extend the archetype set through the
   guide, never improvise a one-off page shape on the screen).
4. **Given** the project's declared primary form factor, **When** a builder reads an
   archetype, **Then** the archetype defines how its zones reflow at both ends of the
   supported viewport range, so the same screen stays consistent on mobile and desktop.

---

### User Story 2 - Compose surfaces by a named ladder (Priority: P2)

An app builder placing content into containers follows a named **surface ladder** — which
backgrounds sit at which level (recessed, page, card/panel, floating), what may nest inside
what, and how to separate adjacent content (whitespace first, background shift, border, or
divider) — so screens read as deliberately layered instead of arbitrarily boxed.

**Why this priority**: "Things are not layered properly" is the second reported failure.
The guide already pairs shadows with stacking bands for *floating* surfaces; what's missing
is the *resting*-surface composition rules (card nesting, separator choice, what sits on
what) that mature systems publish as hard rules.

**Independent Test**: Give a builder a content-heavy screen brief (grouped settings, a
detail page with sub-sections); verify every container/separator decision on the built
screen is citable to a ladder rule. Testable with only this story shipped.

**Acceptance Scenarios**:

1. **Given** the enhanced guide, **When** a builder wants to visually group or elevate
   content, **Then** a named surface ladder tells them which surface level applies, which
   levels may contain which, and which combinations are prohibited.
2. **Given** a builder about to nest one card-like container inside another, **When** they
   consult the guide, **Then** an explicit rule prohibits it and names the sanctioned
   alternatives (spacing, a background-shift inset, or — where allowed — a divider).
3. **Given** two adjacent blocks of content, **When** the builder chooses how to separate
   them, **Then** a single decision rule orders the options (whitespace by default, then
   background shift, then border, with dividers restricted to dense data rows/tables), so
   the choice is derivable, not stylistic.
4. **Given** any nested container that is legitimately inset, **When** its corner rounding
   is chosen, **Then** one reconciled rounding formula (consistent with the guide's
   existing nesting rule) determines it — the guide must not carry two conflicting rules.

---

### User Story 3 - Reuse before invention (Priority: P3)

Before building any new piece of UI, an app builder passes a written **reuse-first gate**:
check the archetypes, then the guide's patterns, then the app's existing screens and
shared primitives — and only build new when nothing fits, justifying why. The gate's hard
rules ride in the always-read instruction surface so they are applied at build time, not
discovered later in review.

**Why this priority**: "Every new component is written from scratch" is the third failure.
Research on agent-consumed design guidance shows static guides alone push builders toward
re-creation; the fix is a small set of always-on hard rules plus an explicit
check-existing-first order. This story turns the guide's existing promotion rule into an
enforceable pre-build gate.

**Independent Test**: Present a builder with a brief that overlaps an existing pattern
(e.g. "add a filterable list of X" when a filterable list of Y exists); verify the build
reuses/extends the existing construct or records an explicit justification. Testable
without other stories.

**Acceptance Scenarios**:

1. **Given** a builder about to create any new screen, section, or control, **When** they
   follow the guide, **Then** a written gate defines the check order (archetype →
   documented pattern → existing screens and shared primitives → extend an existing
   primitive → only then create new).
2. **Given** something genuinely new is created, **When** it is proposed for the app or the
   guide, **Then** it must pass a stated bar: demonstrably needed and not replicating
   anything that already exists (consistent with the guide's existing
   twice-coincidence/thrice-pattern promotion rule).
3. **Given** an AI agent building frontend in a template-derived project, **When** it
   begins any UI work, **Then** the always-read instruction surface it is required to load
   already carries the gate and the guide's hard rules in compact form, with the guide as
   the canonical detail reference.

---

### User Story 4 - Build forms and feedback without improvisation (Priority: P4)

An app builder assembling a form or an asynchronous view follows documented, component-
library-agnostic **patterns**: label placement, field widths, action-button order and
placement, validation-message position and recovery behaviour; and per archetype zone,
where loading, empty, error, and success states render, when to use a skeleton versus an
indicator, and when feedback is inline versus floating.

**Why this priority**: Forms and async feedback are the most frequently built UI and
therefore the biggest improvisation sites. The guide's Content chapter already owns the
*copy* for these states; this story adds the missing *placement and behaviour* layer.
It lands last because archetypes (P1) define the zones these patterns anchor to.

**Independent Test**: Have a builder produce a create/edit form and a data-loading view
from the guide alone; verify every layout/placement decision (labels, widths, buttons,
validation, state placement) is citable to a pattern rule. Testable independently.

**Acceptance Scenarios**:

1. **Given** a builder creating any form, **When** they consult the guide, **Then** the
   form pattern determines label placement, how field width relates to expected content,
   required/optional marking convention, action-button order and placement, and where
   validation messages appear and how the user recovers — regardless of which component
   library the project adopted.
2. **Given** any view that loads data, **When** the builder designs its states, **Then**
   the guide prescribes, per archetype zone, where loading/empty/error render and a rule
   for choosing skeleton versus progress indicator — and the states use the copy rules the
   Content chapter already defines.
3. **Given** an action completes or fails, **When** feedback is shown, **Then** a single
   routing rule decides inline versus floating versus blocking feedback, anchored to the
   control or zone that caused it.

---

### Edge Cases

- **No archetype fits**: the escalation rule (US1/AS3) applies — extend the system, never
  the screen; the extension lands in the guide first, consistent with the guide's existing
  "extend the scale, never the screen" principle.
- **Hybrid screens** (e.g. a dashboard zone embedding a list): the guide must state the
  composition rule — a zone may host another archetype's *content pattern*, but exactly one
  archetype owns the page frame.
- **Conflicting rules across chapters** (e.g. the existing concentric-rounding rule vs a
  new nested-surface rounding rule): one home per rule; new chapters must reconcile and
  cross-reference rather than duplicate, and a violation must be citable to exactly one rule.
- **Adopted component library contradicts a pattern** (e.g. a library's default label
  placement differs): the guide must state precedence — the pattern wins, and the library is
  configured to match; if it cannot, the deviation is recorded per the reuse-gate
  justification path.
- **Screens built before this enhancement**: no retrofit mandate; existing screens migrate
  opportunistically when next touched (trunk stays releasable, consistent with template
  workflow).
- **Extremely small apps** (one or two utility pages): archetypes still apply — full-page
  utility is itself an archetype, so minimal apps don't fall outside the system.
- **Form-factor extremes**: each archetype's reflow definition covers both ends of the
  declared viewport range; a builder must never invent a mobile arrangement ad hoc.

## Requirements *(mandatory)*

### Functional Requirements

**Screen archetypes & page rhythm (US1)**

- **FR-001**: The guide MUST define a named set of screen archetypes covering at least:
  collection/list, record detail, form (create/edit), dashboard/overview, settings,
  focused multi-step flow, and full-page utility (sign-in, not-found, full-page
  error/empty). Each archetype MUST state: purpose, when to use, when not to use (naming
  the alternative), its ordered zone skeleton, the named spacing for every zone gap, its
  content width, and its reflow behaviour across the supported viewport range.
- **FR-002**: All archetypes MUST share one common page skeleton — a single page-header
  anatomy (title, with optional supporting description, navigation context, and page-level
  actions) and a content region that each archetype specializes — so no page defines its
  own frame.
- **FR-003**: The page-rhythm constants the archetypes depend on (edge gutters,
  title-to-content gap, section gap, per-archetype content widths) MUST exist as named
  entries in the single token source, and archetypes MUST reference those names — never
  restate raw values.
- **FR-004**: The guide MUST include archetype-selection guidance ("when to use which") and
  an escalation rule for screens no archetype fits, consistent with the existing
  extend-the-system-never-the-screen principle.
- **FR-005**: The guide MUST require one density declared app-wide (via the existing
  container-padding scale) and MUST prohibit mixing densities within one page hierarchy;
  each archetype zone states its container-padding size.

**Surface & layering (US2)**

- **FR-006**: The guide MUST define a named resting-surface ladder (recessed, page,
  card/panel, floating) bound to the existing background/surface, shadow, and stacking
  tokens, with the existing pairing rule (surface, shadow, and stacking level travel
  together) extended to cover resting surfaces.
- **FR-007**: The guide MUST prohibit nesting card-like raised containers inside one
  another and MUST name the sanctioned alternatives (spacing, background-shift inset,
  divider where permitted). Corner rounding for legitimate insets MUST resolve to one
  formula reconciled with the guide's existing concentric-nesting rule.
- **FR-008**: The guide MUST provide a single separator decision rule ordering whitespace
  (default), background shift, border, and divider — with dividers restricted to dense
  data rows and tables.
- **FR-009**: For each surface level, the guide MUST state which levels may sit on it and
  which may stack above it, so any surface combination is checkably valid or invalid.

**Reuse-first gate (US3)**

- **FR-010**: The guide MUST define a reuse-first gate with an ordered check — archetype →
  documented pattern → existing screens/shared primitives → extend an existing primitive →
  create new — required before any new UI construct is built.
- **FR-011**: The guide MUST state the bar new constructs must pass (demonstrated need and
  no existing equivalent), aligned with the existing promotion rule
  (twice-coincidence/thrice-pattern) rather than replacing it.
- **FR-012**: The hard rules a builder must never violate (token-only values, archetype
  requirement, surface ladder, reuse gate) MUST be carried in the always-read frontend
  instruction surface as a **minimal never-violate digest**: one compact block limited to
  those hard gates, each line cross-referencing the guide chapter that owns the detail —
  so agents apply them at build time without loading the full guide, and the duplicated
  (drift-prone) surface stays as small as possible.

**Form & feedback patterns (US4)**

- **FR-013**: The guide MUST document a component-library-agnostic form pattern fixing:
  label placement, field-width-to-content relationship, grouping/spacing of fields,
  required/optional marking convention, action-button order and placement per container
  type (page, dialog, inline), and validation-message placement plus error-recovery
  behaviour.
- **FR-014**: The guide MUST document view-state placement: for each archetype zone, where
  loading, empty, error, and partial states render; a rule for skeleton versus progress
  indicator; all referencing the Content chapter's existing copy rules rather than
  restating them.
- **FR-015**: The guide MUST document a feedback-routing rule deciding inline versus
  floating versus blocking feedback, anchored to the causing control or zone, deepening
  the existing "feedback lands on the control that caused it" principle into a checkable
  pattern.
- **FR-016**: The guide's Content chapter MUST gain a common-actions vocabulary — one
  canonical verb per recurring action (create, edit, delete, save, cancel, search, filter,
  export, and similar) — so identical actions never carry different labels across screens.

**Guide integrity (all stories)**

- **FR-017**: All additions MUST remain foundations-and-patterns only: no component
  inventory, and every pattern expressed so any adopted component library can implement it.
- **FR-018**: Every new or changed rule MUST be written in checkable form following the
  guide's existing conventions (each chapter ends in checkable rules; do/don't examples
  with "use instead" pointers), and the guide document itself MUST demonstrate the new
  rules it states (it remains specimen #1 of its own system).
- **FR-019**: Any new named token MUST land in the single token source and be visible in
  the guide in the same change, preserving the guide's live-mirror property.
- **FR-020**: Where new chapters touch existing ones (spacing, elevation, content,
  layout), the existing chapter MUST be updated or cross-referenced rather than
  duplicated — every rule has exactly one home.
- **FR-021**: Each new archetype and pattern chapter MUST include a live specimen figure
  built from the token source, demonstrating its zone skeleton or rule in action; these
  specimens are the ship-time audit subject for this feature's success criteria.

### Key Entities

- **Screen archetype**: a named whole-page type (purpose, zone skeleton, rhythm, reflow);
  the unit a builder selects before building any screen.
- **Zone**: a named region within an archetype (e.g. page header, primary content,
  side panel); the anchor for spacing, density, and state-placement rules.
- **Surface level**: a named layer in the resting/floating surface ladder, bound to
  background, shadow, and stacking tokens; carries nesting and stacking permissions.
- **Pattern**: a documented, library-agnostic solution to a recurring compositional
  problem (form anatomy, view states, feedback routing), expressed as checkable rules.
- **Reuse gate**: the ordered pre-build check plus the bar for creating something new.
- **Rule digest**: the compact always-read subset of hard rules carried in the frontend
  instruction surface, pointing at the guide as canonical.

## Success Criteria *(mandatory)*

### Measurable Outcomes

**Verification vehicle** (clarified 2026-07-02): at ship time, every criterion is audited
against the guide's own specimen figures (FR-021) — the guide remains specimen #1 of its
rules. SC-001, SC-002, and SC-004 are then formally measured on the first real project
built from the template; they do not block this feature's completion.

- **SC-001**: Two screens of the same archetype, built in independent sessions from the
  enhanced guide alone, show **zero page-level structural deviations** (edge gutters, page
  header anatomy, title-to-content gap, section gaps, content width) in a side-by-side
  audit.
- **SC-002**: **100% of screens** in a template-derived reference app map to exactly one
  named archetype, verified by walking every route.
- **SC-003**: On any sampled screen, **every** spacing, surface, and layout decision traces
  to a named guide rule or token — an audit finds zero unexplained one-off values or
  unclassifiable containers.
- **SC-004**: Across ten consecutive new-screen or new-feature reviews after adoption, at
  least **nine** reuse existing archetypes/patterns/primitives without introducing a
  parallel construct, and every exception carries a written justification.
- **SC-005**: Each of the three reported failure modes (improper layering, from-scratch
  components, inconsistent page spacing) is covered such that a reviewer can cite the
  specific violated rule for any reproduced instance — no failure mode lacks a citable rule.
- **SC-006**: A builder unfamiliar with the project can select the correct archetype for a
  described screen using only the selection guidance, for at least **9 of 10** screen
  descriptions drawn from typical application briefs.

## Assumptions

- The guide's primary readers are AI coding agents and developers; rules are therefore
  written as checkable conditionals (the research shows this is also what agents follow
  most reliably).
- The foundations-only stance stands: no component inventory; per-project component
  libraries (e.g. AntD, Material UI) remain free choices that must be able to express
  every pattern.
- The existing guide artifacts and single token source under `design/` remain the home of
  the enhancement; this feature enhances them in place rather than introducing a new
  documentation platform.
- The archetype set targets the template's domain — business/SaaS single-page apps; the
  seven listed archetypes are the confirmed starting set (see Clarifications), extensible
  by the guide's own evidence rule.
- Single light theme continues (dark mode stays deferred, as the guide already records).
- No retrofit of apps already built from the template is required; conformance applies to
  screens built or next touched after adoption.
- Verification of screens built in derived projects (SC-001–SC-004) uses the template's
  existing view-and-compare gate for frontend work; this feature adds no new tooling
  mandate. Ship-time verification of this feature itself runs against the guide's
  specimen figures (FR-021).

## Out of Scope

- **Component inventory or specimens** — excluded by explicit user constraint; the existing
  cross-project promotion rule is the only path by which one may later appear.
- **Data-visualization chapter** — a minority of major systems document it (4/10), and the
  guide's own evidence rule ("grows from evidence, not speculation") defers it until a
  project needs charts.
- **Dark mode / theming** — already explicitly deferred by the guide; unchanged.
- **Brand, illustration, photography, marketing assets** — showcase systems carrying these
  are brand portals; this template's per-project mockups own visual identity.
- **Automated enforcement tooling** (lint/CI checks for token violations) — the research
  says code-level enforcement is the strongest long-term fix for agent drift, but it is a
  separate feature; this spec covers the documentation layer only. Natural follow-up.
- **Contribution/governance process** beyond the reuse bar (documentation templates, QA
  checklists à la Uber Base) — out of scope for a single-maintainer template.
