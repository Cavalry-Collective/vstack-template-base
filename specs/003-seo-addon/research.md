# Phase 0 Research: SEO Add-on (redo)

**Feature**: `003-seo-addon` · **Date**: 2026-07-07

**Trigger**: The first implementation (uncommitted working-tree changes) was judged inadequate by the user ("it's poorly implemented, so i want you to do it better"). Phase 0 therefore starts with a critique of that implementation, then records the decisions that define the redo. No `NEEDS CLARIFICATION` markers exist in the spec; the sole open question — what "better" means — is resolved here as concrete, checkable deficiencies.

## Critique of the current implementation

Read against the spec's success criteria and the template's own quality bar (checkable imperatives, mechanically auditable seams, sibling-add-on patterns):

| # | Deficiency | Evidence | Spec pressure |
|---|---|---|---|
| C1 | **The stack seam is prose, not enumerable.** "Binds to a stack" is one run-on sentence; a pack binding cannot be audited item-by-item, so "every seam item named" (SC-003, FR-012) is not mechanically checkable. | `add-ons/seo/README.md` seam paragraph | SC-003, FR-012 |
| C2 | **Pack bindings are single unscannable mega-bullets** (~120 words each) with no one-to-one correspondence to seam items; omissions hide. The vercel binding indeed omits locale alternates, and neither Next binding names where the canonical-origin config lives. | `stacks/*/frontend.md` add-on bindings sections | SC-003, FR-005 |
| C3 | **No CI-checkable gates.** The repo's established pattern is named, greppable assertions ("in the spirit of the i18n key-parity check"; test-mode's fail-closed suite assertions). The current doc demands only one test (staging noindex); classification completeness and sitemap↔registry drift are unasserted. | compare `add-ons/test-mode/README.md` *Verify it fails closed* | SC-004, FR-003, FR-009, FR-010 |
| C4 | **Verification is a paragraph, not per-rule observable checks.** SC-004 ("zero rules require reading an implementation to check") can't be demonstrated rule-by-rule. | *Verify by observing* section | SC-004, FR-011 |
| C5 | **Missing load-bearing rule: URL stability.** Slugs that rename without a permanent redirect silently orphan every inbound link — a top-tier real-world SEO failure the doc never mentions (the base *URL routing* covers cleanliness, not stability). | absent from README | FR-005/FR-006 territory |
| C6 | **Missing load-bearing rule: crawl traps.** Parameterized/faceted/filter URLs multiplying into infinite crawl spaces are unaddressed; classification is stated per-route but not per-URL-space. | absent from README | FR-003, FR-009 |
| C7 | **Share-preview image unspecified.** "Open Graph and friends" names tags but not the preview image — half the practical reason teams adopt share metadata. | metadata bullet | FR-007 |
| C8 | **Structured-data home missing from the seam.** Bindings mention "one shared component" for entity markup, but the seam never asks for it — bindings answer a question the contract never posed. | seam paragraph vs. binding bullets | FR-008, FR-012 |
| C9 | **No adoption-fit triage.** Sibling `otp-auth` opens with a decision table; here the adopt/classify/delete decision is buried in the intro prose. | intro paragraph | SC-001 |
| C10 | **Taro declaration is all-or-nothing.** A publicly reachable H5 origin can still get *indexed as garbage* even though it can't be *optimised*; the unbound declaration should still direct the refuse-indexing posture. | `stacks/taro-fastify-mysql-tencent/README.md` blockquote | FR-010 |

What was already right and is kept: the capability boundary (structural indexability, not keyword/paid/performance work), the agnostic wording, the core rule set (classification, render-complete-without-JS, canonicals, honest status codes, centralized metadata, generated sitemap/robots, fail-closed staging, no cloaking), activation via the existing kept-directory mechanism, and the four enumeration updates (FR-013 — already satisfied, untouched by the redo except if wording shifts).

## Decisions

### D1 — Seam becomes an enumerated contract (S1–S7)

**Decision**: Replace the prose seam with numbered items: **S1** rendering mechanism (indexable routes complete without client JS), **S2** metadata helper home (title/description/canonical/share tags + share image), **S3** canonical origin & redirect home (validated-config key + server/edge permanent-redirect mechanism), **S4** sitemap & robots generation home (derived from the route registry), **S5** missing-entity not-found mechanism (real 404/410 status), **S6** structured-data helper home, **S7** locale-alternates home (only if the project is multilingual). Pack bindings answer item-by-item under the same identifiers; an unbound pack declares against the same list.

**Rationale**: Fixes C1/C2/C8. Makes SC-003 a grep: every S-id must appear in each pack's binding or unbound declaration.

**Alternatives considered**: Keep prose seam and rely on reviewer diligence — rejected: exactly what let the C2 omissions through. A formal YAML/JSON seam manifest — rejected: the add-on mechanism is guidance-as-text; machinery contradicts `add-ons/README.md` invariants.

### D2 — Two new approach rules: URL stability, crawl-space classification

**Decision**: Add (a) **URL stability**: an indexable URL is a commitment — slugs are stable; a rename keeps a permanent redirect from every previously published URL; and (b) **crawl-space discipline**: classification covers URL *spaces*, not just routes — parameter/filter/pagination variants of a page are non-indexable (canonical to the base page) unless deliberately classified, so faceted URLs can't multiply into a crawl trap.

**Rationale**: Fixes C5/C6 — the two highest-impact real-world failures the current doc misses. Both are agnostic, observable from outside, and small (one bullet each).

**Alternatives considered**: A full URL-design section (casing, hyphens, hierarchy) — rejected: the base *URL routing* already owns URL cleanliness; duplicating it violates the additions-only ethos. Leaving crawl traps to packs — rejected: the failure is stack-independent.

### D3 — Named CI gates, anchored to the repo's parity-check pattern

**Decision**: The add-on names three assertions that belong in an adopting project's suite/CI, "in the spirit of the i18n key-parity check" (the base's established pattern): **G1** every route carries a classification (completeness); **G2** the generated sitemap and the route registry cannot drift (derivation is asserted, not hoped); **G3** non-production origins answer noindex (fail-closed, per environment).

**Rationale**: Fixes C3. Converts the three most silent failures into red CI instead of discovered-months-later deindexing.

**Alternatives considered**: Shipping actual check scripts — rejected: add-ons are docs-only; scripts are stack-specific and belong to packs/projects. A crawler/audit tool mandate (e.g. scheduled external audits) — rejected: names a vendor, violates agnosticism; the verification section already points at index-coverage tooling generically.

### D4 — Verification becomes a per-rule observable-check list

**Decision**: Replace the verification paragraph with a compact checklist mapping each approach rule to its outside-observable check (fetch X, expect Y) — raw-response content, status codes, canonical, sitemap membership, robots/noindex, redirect behaviour.

**Rationale**: Fixes C4; makes SC-004 demonstrable rule-by-rule and gives `/speckit-tasks` a ready acceptance list. Mirrors `test-mode`'s "verify it fails closed" posture.

**Alternatives considered**: Keep prose — rejected (C4). A full per-page-type checklist matrix (article vs listing vs profile) — rejected: overfits; page types vary per product.

### D5 — Adoption-fit triage table

**Decision**: Open the doc with a three-row triage in the style of `otp-auth`'s model table: fully public surface → adopt; mixed (public shell + private app) → adopt, classify private routes non-indexable; fully login-walled → delete the add-on (no indexable surface) — noting the refuse-indexing posture still applies to any publicly reachable origin.

**Rationale**: Fixes C9; makes the Day-1 keep-or-delete decision (SC-001) answerable from the doc's first screenful.

**Alternatives considered**: Keep intro prose — rejected: the decision is the first thing an adopter needs and was easy to miss.

### D6 — Pack bindings restructured as per-seam-item entries; gaps filled

**Decision**: Both Next.js pack bindings become an S1–S7-keyed list (one short line per item), adding the two current omissions: the canonical-origin validated-config key home (S3) and locale alternates (S7 — vercel too, since its i18n is inherited from the base unchanged). The Taro declaration stays unbound but gains the partial posture from C10: a publicly reachable H5 origin that shouldn't appear in search results still serves the refuse-indexing response regardless of the add-on being unbound.

**Rationale**: Fixes C2/C10; makes SC-003's "every seam item named" literal.

**Alternatives considered**: Prose-bullet bindings kept — rejected (C2). Binding Taro partially (S4/S5 only) — rejected: a half-bound pack blurs the bound/unbound contract; the refuse-indexing note is posture guidance, not a binding.

### D7 — Size budget

**Decision**: Target ≤ 70 lines for the add-on README (currently 32; invariant ceiling ~150). The additions (triage table, S1–S7, per-rule checks, two rules, three gates) must fit by keeping every rule to one line-anchored bullet.

**Rationale**: "Better" must not mean "longer for its own sake" — the invariant is terse-and-checkable; density is the quality bar, so the budget forces the D1–D5 structures to stay compact.

**Alternatives considered**: No budget — rejected: the failure mode of a redo is bloat that trades one defect (thin) for another (unscannable).

### D8 — Explicitly out of scope (ratified by the user 2026-07-07 as the spec's *Scope* section — a decided boundary, no longer an assumption)

**Decision**: Still excluded: Core Web Vitals / performance budgets (base quality guidance owns performance; the spec's assumptions exclude ranking-factor chasing), keyword/content strategy, paid search, rank tracking, analytics SDKs, AMP, `meta keywords`, pagination link-relation attributes (obsolete), and any shipped tooling/scaffolding.

**Rationale**: The critique found the current doc too *thin in the wrong places*, not too narrow. Widening scope would violate YAGNI and the docs-only mechanism. The spec refinement adds two checkable obligations on top of the exclusion list itself: the guidance must state the boundary where an adopter first reads it (FR-014), and no rule in the guidance may address an excluded topic (SC-006) — both auditable by grep (quickstart A6).

**Alternatives considered**: Adding a performance rule "because SEO" — rejected: no base section exists to anchor it (a phantom reference, which this repo treats as a defect), and page-speed discipline is a separate capability.

## Best-practice anchors (existing repo patterns reused)

- **Enumerated, greppable contract items** — mirrors the pack invariant's "checkable imperative" register format (`stacks/README.md`).
- **Fail-closed + suite-asserted** — mirrors `add-ons/test-mode` (*Verify it fails closed*).
- **Decision table up front** — mirrors `add-ons/otp-auth` (*Choose a model*).
- **Derived-artifact-never-hand-kept** — mirrors the base *URL routing* one-registry rule and the i18n key-parity check.

All decisions resolved; no NEEDS CLARIFICATION remains. → Phase 1.
