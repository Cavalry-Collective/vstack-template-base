# Design-system survey — gap analysis for the Keystone design guide

**Date**: 2026-07-02
**Purpose**: Research base for `spec.md`. Three parallel investigations: (1) the 14 design
systems on zeroheight's showcase, (2) the documentation structure of ten major public design
systems, (3) how mature systems document their way out of the exact failure modes this
template exhibits (haphazard layering, from-scratch components, inconsistent page spacing).

## Method

- **Showcase survey**: all 14 systems at zeroheight.com/showcase enumerated; 13 accessible
  (Bento/Delivery Hero is SSO-gated). Navigation trees read from each site's embedded
  zeroheight page-tree data — actual page inventories, not marketing copy.
- **Major-systems survey**: Shopify Polaris, IBM Carbon, Atlassian, Adobe Spectrum,
  Material 3, Microsoft Fluent 2, GOV.UK, GitHub Primer, Kiwi.com Orbit, and Ahoy
  (Teamleader — the system Keystone was modelled on), verified against live docs/repos.
- **Failure-mode research**: SAP Fiori floorplans, GOV.UK page templates, Atlassian
  elevation/surfaces, Polaris depth & spatial organization, Carbon spacing scales,
  Nathan Curtis's spacing/system-principles essays, GOV.UK contribution criteria, and
  2024–26 writing on design systems for AI agents (Google DESIGN.md spec, Atlassian's
  DESIGN.md field test, Indeed's MCP/format benchmark).

## What Keystone already covers (at parity with mature systems)

Principles · three-tier tokens · colour (ramps, roles, intent formula) · typography (role
table, line-height rule, digits) · spacing scale bound to relationship bands · app-frame
anatomy + grid + breakpoints · shape/border with concentric-radius rule · elevation
(shadow + z-band pairing, portal rule) · motion bands · icons · control-state ladder +
focus · accessibility floor · voice/copy jobs for empty/error/success/destructive ·
data formatting. Components deliberately absent — same stance as the guide will keep.

This is a strong **foundations** layer. The gaps are almost entirely one altitude up:
**how foundations compose into pages and patterns.**

## The gaps, ranked by evidence strength

### 1. Screen archetypes / page templates (the biggest gap)

The strongest systems document *whole page types*, not just grids:

- **SAP Fiori "floorplans"**: List Report, Worklist, Object Page, Overview Page, Wizard,
  Initial Page — each with a fixed zone skeleton and "when to use / when not to use /
  use X instead" rules, plus a "When to Use Which Floorplan" decision page.
- **Shopify Polaris patterns**: "Resource index layout", "Resource details layout",
  "App settings layout" — full-page compositions for whole classes of admin screens.
- **Material 3**: "Canonical layouts" (list-detail, supporting pane, feed) + "Scaffold"
  regions per window-size class.
- **GOV.UK**: a mandatory Page template skeleton, plus a "Pages" pattern group
  (question, confirmation, 404, service-unavailable, "there is a problem" pages).
- **Ahoy itself** has a Patterns → **Pages** entry; Keystone did not adopt it.
- Showcase systems: Nessie (Templates), NEXT (Templates/starter kit), SoftwareOne
  (Templates incl. error pages, timestamps), Solar (Page Sections).

**Why it matters here**: page-level spacing drift disappears when the archetype owns the
outer structure. This is the documented mechanism that makes page 5 look like page 1.

### 2. Surface & layering rules

- **Atlassian elevation**: a *named surface ladder* — sunken / default / raised / overlay —
  with pairing rules ("always pair matching surface and shadow tokens"), stacking
  prohibitions, and "use whitespace or borders instead" redirections.
- **Material 3**: seven surface-container roles for "creating hierarchy and nested
  containers"; interaction raises elevation by fixed steps.
- **Polaris spatial organization**: nested surfaces instead of lines; **"dividers are
  exclusively for data and index tables"**; nested radius must step *down* from parent.
- **Nord & Mews** publish the prohibition outright: *no card inside card* — use spacing,
  a divider, or a background-fill inset instead.

Keystone's Elevation chapter pairs shadow/z for *floating* surfaces but says nothing about
composing *resting* surfaces: what sits on the page background vs on a card, whether cards
nest, when to separate with whitespace vs background shift vs border vs divider.

### 3. Reuse discipline (the "from scratch every time" fix)

- **GOV.UK contribution criteria**: anything new must be **useful** (evidence of repeated
  need) *and* **unique** ("does not replicate something already in the Design System").
- **designsystems.com contribution workflow**: the first gate is literally "Have you tried
  solving with existing components?"
- **Nathan Curtis**: "Include what's shared, omit what's not"; favour quality over quantity.
- The common documentation shape everywhere (Fiori/Nord/Atlassian/GOV.UK): conditional
  **"when to use / when not to use / use X instead"** blocks — the mechanism that redirects
  a builder to an existing solution instead of a new one.

### 4. Form & feedback patterns (documented as patterns, not components)

- **GOV.UK**: the most prescriptive — question-page skeleton, "never mark mandatory fields
  with asterisks" (mark optional instead), error-recovery pattern, per-data-type patterns.
- **Carbon forms pattern**: top-aligned labels default; field width mirrors expected content
  length; fixed secondary-left / primary-right button order; helper text placement.
- **Carbon patterns generally**: Empty states, Loading, Notifications, Filtering, Search,
  Dialogs, Common actions, Disabled/read-only states — cross-component behaviour written once.
- **Base (Uber) patterns**: Modality, Inputting data, Feedback, States.
- **Primer UI patterns**: Empty states, Loading, Saving, Notification messaging,
  Progressive disclosure, Degraded experiences.

Keystone's Content chapter covers the *copy* for empty/error/success; nothing covers
*placement and behaviour* (where loading lives per zone, skeleton vs spinner, toast vs
inline, button order, label placement, validation position).

### 5. Density & rhythm constants

- **Carbon** separates a *spacing scale* (inside components) from a *layout scale*
  (between components/regions — "controls the density of a design").
- **SAP Fiori** cozy/compact: "Never combine 'cozy' and 'compact' modes within the same
  hierarchy or page. Always set the content density factor at application level."
- Keystone already binds spacing steps to relationship bands (good) and has a three-size
  box scale (good) but has no page-rhythm constants (title-to-content, section gap per
  archetype) and no app-level density declaration.

### 6. AI-agent consumption (directly relevant: this guide's main readers are agents)

- **Google DESIGN.md spec**: agents need persistent, structured design context — tokens as
  data + short prose rationale + first-class Do/Don't sections; without it agents produce
  "different colors on Monday, different spacing on Tuesday".
- **Atlassian's DESIGN.md field test**: a large static style file used ~92% more tokens with
  ~2.7× run-to-run variance, and "encourages agents to recreate components rather than
  import existing ones". Recommendation: short always-on architectural guidance + detail
  on demand + code-level enforcement.
- **Indeed benchmark (1,056 prompts)**: on-demand-only context makes agents "fully ignore
  the spacing, the typography, the colors" — the fix was a small **always-on foundations
  layer** of hard rules, with detail loaded on demand.

**Implication**: the hard rules (reuse gate, archetype requirement, surface rules,
token-only) must live in the instruction surface agents *always* read when building
frontend, with the guide as the canonical detail layer.

## Frequency snapshot (non-component chapters)

Across the 10 major systems (M) and 13 accessible showcase systems (S):

| Chapter | Coverage | Keystone today |
|---|---|---|
| Colour / typography / iconography / a11y | ~10/10 M, 12–13/13 S | ✅ covered |
| Layout & grid / spacing | 9–10/10 M, 12/13 S | ✅ covered (page rhythm missing) |
| Design tokens | 8/10 M | ✅ covered |
| Content / voice & tone | 8/10 M, 9/13 S | ✅ covered (verb vocabulary missing) |
| Motion / elevation | 5–6/10 M | ✅ covered (surface ladder missing) |
| Forms & validation patterns | 5(+2)/10 M | ❌ missing |
| Page templates / screen archetypes | 4(+2)/10 M, 6/13 S — incl. Ahoy | ❌ missing |
| Feedback: empty/loading/notification patterns | 3–4/10 M | ❌ missing (copy only) |
| Interaction states | 4/10 M | ✅ covered (control-level) |
| Data visualization | 4/10 M, 4/13 S | ⏸ deferred (evidence rule) |
| Theming / dark mode | 4/10 M | ⏸ deferred (explicit) |
| Density modes | 1/10 M (+ Fiori) | partial (box scale) |
| Terminology / common-actions vocabulary | 4/10 M | ❌ missing |
| Contribution / reuse governance | 5/10 M | partial (promotion rule only) |
| Brand / illustration / imagery | 7/13 S | out of scope (per-project mockups) |

## Conclusions carried into the spec

1. Add a **screen archetypes** chapter (floorplans) + page-rhythm constants — fixes
   inconsistent pages. (P1)
2. Add a **surface & layering** chapter — named resting-surface ladder, nesting
   prohibition, separator decision rule — fixes improper layering. (P2)
3. Write a **reuse-first gate** into the guide *and* into the always-read agent
   instruction surface — fixes from-scratch invention. (P3)
4. Add **form & feedback patterns** (placement/behaviour, library-agnostic) — removes the
   most common improvisation sites. (P4)
5. Small additions riding along: app-level density rule, common-actions verb list.
6. Keep deferred (guide's own evidence rule): data-viz chapter, dark mode, brand/imagery,
   component inventory.

## Key sources

- SAP Fiori floorplans: sap.com/design-system/fiori-design-web (Page types / floorplans)
- GOV.UK page template & patterns: design-system.service.gov.uk/styles/page-template, /patterns
- Atlassian elevation & spacing: atlassian.design/foundations/elevation, /foundations/spacing
- Polaris depth & spatial organization, layout patterns: polaris-react.shopify.com/design
- Carbon spacing & patterns: carbondesignsystem.com/elements/spacing, v10 patterns
- Material 3 canonical layouts: m3.material.io/foundations/layout
- Nord / Mews card-nesting rules: nordhealth.design/components/card, mews.design
- GOV.UK contribution criteria: design-system.service.gov.uk/community/contribution-criteria
- Nathan Curtis: "Space in Design Systems", "Principles of Designing Systems" (EightShapes)
- Google DESIGN.md spec: github.com/google-labs-code/design.md
- Atlassian DESIGN.md field test: atlassian.com/blog/how-we-build (2026)
- Indeed format/MCP benchmark: intodesignsystems.substack.com (2026)
- Ahoy (Teamleader): ahoy.teamleader.design — About / Foundation / Patterns (incl. Pages)
- zeroheight showcase: Base (Uber), Nessie (NS), NEXT (Hitachi), Ahoy, GRDF, Oxygen
  (Doctolib), Pencil (Brainly), Planview, SoftwareOne, Snorkel, CCV, IE, Solar (Sunrise)
