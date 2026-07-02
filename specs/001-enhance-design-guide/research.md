# Phase 0 Research — Design Guide Enhancement

External research was completed during `/speckit-specify` and lives in
[`design-system-survey.md`](./design-system-survey.md). This file resolves the
implementation-level unknowns the spec and clarifications deferred to planning.
No NEEDS CLARIFICATION markers remain.

## R1 — Guide document structure: keep one self-contained HTML file

**Decision**: The guide stays a single hash-routed `design-guide.html`; new chapters are
new `<section>` pages in the existing chapter router.

**Rationale**: The existing router already paginates chapters, so reader experience
doesn't degrade with more chapters. A single file preserves the guide's deliberate
properties: zero build step, works from `file://`, one live token mirror, degrades to one
long page without JS. Growth is ~830 → ~1,400 lines — well within hand-maintainable range.

**Alternatives considered**: Per-chapter HTML files (rejected: needs shared-chrome
duplication or a build step, breaks single live mirror, violates YAGNI); a separate
`patterns.html` (rejected: two documents = two sources of truth, the exact failure FR-020
guards against).

## R2 — Chapter placement and navigation architecture

**Decision**: The sidebar gains one new nav group, **Composition**, between Foundations
and Beyond. Final chapter map:

- **Start**: Introduction · Principles · Tokens *(unchanged)*
- **Foundations**: Colour · Typography · Spacing · Layout · Shape & border ·
  **Surfaces & elevation** *(Elevation chapter extended in place — the resting-surface
  ladder, nesting prohibition, and separator rule join the existing shadow/z-band
  content; one home for all layering, FR-006–FR-009)* · Motion · Icons · States & focus ·
  Accessibility · Content *(gains common-actions vocabulary, FR-016)* · Data formatting
- **Composition** *(new group)*: **Screen archetypes** *(new — FR-001–FR-005)* ·
  **Forms** *(new — FR-013)* · **View states & feedback** *(new — FR-014, FR-015)*
- **Beyond**: **Components & reuse** *(existing "Where are the components?" chapter
  rewritten in role: keeps the no-inventory stance and promotion rule, gains the
  reuse-first gate and new-construct bar, FR-010–FR-011)*

**Rationale**: Extending Elevation (rather than a parallel "Surfaces" chapter) and the
Components chapter (rather than a parallel "Reuse" chapter) honours FR-020 — every rule
has exactly one home. A separate Composition group makes the guide's altitude model
legible: foundations → composition → beyond.

**Alternatives considered**: New standalone "Surfaces" chapter (rejected: overlaps
Elevation's shadow/z pairing rule — two homes); putting archetypes inside the existing
Layout chapter (rejected: Layout owns the app frame/chrome; archetypes own what fills the
body region — distinct concerns, see R7 — and the combined chapter would be unwieldy).

## R3 — Page-rhythm tokens

**Decision**: Add a small `--page-*` semantic family to `tokens.css` (tier 2), aliasing
existing primitives — no new primitive values:

- `--page-title-gap` — page-header block → first content (aliases an existing space step)
- `--page-section-gap` — between content sections (formalizes the existing
  "space-5 between sections" spacing rule as a named decision)
- Archetype content widths reuse the existing `--container-content` / `--container-narrow`;
  the archetype chapter maps each archetype to one of them:
  collection/list, dashboard, settings, record detail → `--container-content`;
  form, multi-step flow, full-page utility → `--container-narrow`.

**Rationale**: FR-003 requires the rhythm constants to be *named decisions*, not per-page
choices; aliasing keeps the token count small (the guide's "deliberately small" property)
and the primitive scale untouched. `--gutter-screen` and the clearance tokens already
exist and are reused as-is.

**Alternatives considered**: A full layout-scale tier à la Carbon (rejected: more surface
than seven archetypes need — extend when evidence demands); putting widths per archetype
into new tokens (rejected: the two existing containers already express the decision).

## R4 — Corner-rounding reconciliation (spec edge case, US2/AS4)

**Decision**: The existing concentric formula in Shape & border — *outer radius = inner
radius + padding* — remains the single rounding rule. The Surfaces content cross-references
it; no second formula is introduced.

**Rationale**: The concentric formula already implies the survey's "nested radius steps
down" rule (inner < outer whenever padding > 0), so the industry rule is a corollary, not
a competitor. One home per rule (FR-020): Shape & border owns rounding.

**Alternatives considered**: Polaris-style "never match or exceed parent radius" as a
separate stated rule in Surfaces (rejected: duplicate home, and it's derivable from the
concentric formula).

## R5 — Never-violate digest: location and shape

**Decision**: One compact block (~8 lines) added inside the existing **"Design guide —
the visual keystone"** section of `apps/frontend/CLAUDE.md`, titled as the never-violate
UI gates: token-only values · archetype-first (pick one before building any screen) ·
surface ladder (no card-in-card; separator order) · reuse-first gate (check order before
any new construct) · one density app-wide. Each line names the owning guide chapter as
the canonical detail source. Root `CLAUDE.md` is untouched.

**Rationale**: The clarification fixed "minimal never-violate digest". The frontend
contract is the always-read surface for frontend work (root CLAUDE.md mandates reading it
before touching `apps/frontend/`), and its Design-guide section is the digest's natural
home — extending an existing section, not adding a new surface. Research (Atlassian,
Indeed — see survey) shows always-on hard rules are what agents actually follow.

**Alternatives considered**: Root `CLAUDE.md` (rejected: loaded for backend/infra work
too — wrong altitude, bloats every session); a standalone `design/RULES.md` (rejected:
new surface nobody is forced to read — recreates the detail-on-demand failure the
research documented).

## R6 — Specimen figures (FR-021)

**Decision**: Each new chapter demonstrates its rules with the guide's existing figure
vocabulary: miniature wireframe figures in the style of the current `.app-frame` demo
(archetype zone skeletons), `.dodont` pairs (nesting prohibition, separator choice, form
layout, feedback routing), and token-annotated tables (`.resolved` live values). All
figure styling consumes semantic tokens only, keeping the guide specimen #1 of its rules.

**Rationale**: The conventions already exist and are proven in the current chapters;
inventing a new illustration style would itself violate the guide's consistency ethos.
Live figures double as the ship-time audit subject per the clarification.

**Alternatives considered**: Static images/screenshots (rejected: break the live token
mirror — a rebrand would stale them); full interactive demos (rejected: YAGNI, and
components are explicitly out of scope).

## R7 — Division of labour: Layout vs Screen archetypes vs frontend contract

**Decision**: Three-way split, each with one home:
- **Layout chapter (guide)** keeps the app frame — chrome regions, grid, breakpoints,
  containers, clearances. Unchanged scope; gains a cross-reference to archetypes.
- **Screen archetypes chapter (guide)** owns what fills the body region: the shared page
  skeleton (page-header anatomy), the seven archetypes' zone skeletons, rhythm, density,
  and selection/escalation rules.
- **`apps/frontend/CLAUDE.md`** keeps implementation mechanics (shared layout component,
  clearance-token ownership, route registry) and gains only the digest (R5). The
  archetype chapter's "pages pick a layout variant / never re-derive the frame" language
  stays consistent with the contract's existing "One shared layout" section, referenced
  not restated.

**Rationale**: Matches the survey's finding (GOV.UK/M3 separate scaffold from page
types) and FR-020. The existing sentence in the guide's Layout chapter — "Pages pick a
layout variant; they never re-derive gutters" — becomes the seam the archetype chapter
plugs into.

**Alternatives considered**: Folding archetypes into `apps/frontend/CLAUDE.md` (rejected:
archetypes are visual-system decisions that must survive a stack-pack swap and be
reviewable in the browser gate; the contract file is not the visual keystone).
