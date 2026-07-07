# Phase 1 Data Model: SEO Add-on — Structural Expansion

**Feature**: `004-seo-structural-expansion` · **Date**: 2026-07-07 · **Input**: [spec.md](spec.md), [research.md](research.md), `add-ons/seo/specs/003-seo-addon/data-model.md` (defines R1–R11, S1–S7, G1–G3)

The "data" of a docs-only capability is the structured content of its documents. This model **extends** 003's — nothing below renumbers or redefines an existing ID.

## Entity: Add-on Guidance Document (delta)

`add-ons/seo/README.md`, extended in place.

| Field | Change |
|---|---|
| Capability statement | REWRITE: structural discoverability **plus** the structural work of keyword strategy, paid search, rank tracking, and page-speed ranking factors; the ongoing practice of each named as out of scope (spec FR-001; research D1) |
| Approach rules | R1–R11 unchanged; **add R12–R20** (below), one bullet each |
| CI gates | G1–G3 unchanged; **add G4–G6** (below) |
| Verification | **Add per-rule lines for R12–R20** (merged where rules share a fetch — D8) |
| Stack seam | S1–S7 unchanged; **add S8–S10** (below) |
| Interactions | **Add**: base quality guidance owns general performance — this add-on owns only the indexable-page ranking-factor slice (FR-013); per-locale intent uniqueness rides the base i18n locale set |
| Size | ≤ ~110 lines (ceiling ~150; trim-to-fit ratified — D8) |
| Wording | Stack-agnostic throughout — no vendor metric names (D5) |

## Entity: Approach Rule (new: R12–R20)

Each rule = one-line imperative + an outside-observable check. Rules marked ⚙ feed a CI gate.

| ID | Rule (essence) | Observable check | Spec |
|---|---|---|---|
| R12 ⚙G4,G5 | Every indexable route records its target search intent — the query the page answers — at the route registry beside its classification, one per locale; copy iteration updates the record in the same change | Registry review; inventory fetch (O16); G4/G5 assert presence and uniqueness | FR-002, FR-003 |
| R13 | Title, description, slug, and the single top-level heading are written against the recorded intent; exactly one top-level heading; heading levels descend without skipping | Fetch page raw → one top-level heading, coherent title/slug/heading (O11) | FR-004 |
| R14 | Every indexable page is reachable via at least one crawlable link with descriptive anchor text from another indexable page — the sitemap is not linkage | Traverse links from indexable entry pages → page reached (O12) | FR-005 |
| R15 | Advertising click parameters never fork the page: identical content with arbitrary such parameters appended; the parameters never appear in canonicals or the sitemap; landing URL spaces are deliberately classified like any route | Fetch with arbitrary ad params → identical content, param-free canonical, absent from sitemap (O13) | FR-006, FR-007 |
| R16 | An ad landing URL answers success directly — no redirect chain; a vanity alias is at most one permanent redirect | Fetch destination → direct success; alias → single permanent hop (O14) | FR-007 |
| R17 | Search-engine ownership verification is served from validated configuration and survives redeploys — never a hand-placed artifact | Fetch verification response; redeploy; fetch again (O15) | FR-008 |
| R18 | The page↔intent inventory — each indexable URL paired with its recorded intent — derives from the route registry, machine-readable, never hand-kept | Derive twice → no diff; compare against registry (O16) | FR-009 |
| R19 | Indexable pages meet the search engines' published loading-experience thresholds: main-content loading, responsiveness to input, visual stability; the published values are the bar — the doc freezes no numbers | Measure the running page on the three axes (O17) | FR-010 |
| R20 ⚙G6 | The structural causes of failing R19 are ruled out: media and embeds reserve their space before arrival; primary content is never deferred behind client scripting or user interaction; each indexable route respects the declared payload budget | Load page → no visible layout shift, primary content in raw response (O18); G6 asserts the budget | FR-011 |

## Entity: Stack Seam Item (new: S8–S10)

The questions every bound pack must additionally answer.

| ID | The pack names... | Serves |
|---|---|---|
| S8 | Where the intent record lives on the pack's route-registry binding, and how the page↔intent inventory is derived and served from it | R12, R18 |
| S9 | How the ownership-verification response is served from the validated-config home | R17 |
| S10 | The payload-budget home and its suite assertion, and the mechanism used to measure the three loading-experience axes on the running page | R19, R20 |

## Entity: CI Gate (new: G4–G6)

Day-1 assertions in the adopting project's suite (clarification 2; research D4).

| ID | Asserts | Silent failure prevented |
|---|---|---|
| G4 | Every indexable route has an intent record | Page ships targeting nothing — unrankable by design |
| G5 | No two same-locale indexable routes record the same normalized intent | Two pages silently split one query's standing (cannibalisation) |
| G6 | Every indexable route's payload is within the declared budget | Page weight creeps past the ranking bar unnoticed |

## Entity: Intent Record (in adopting projects)

The per-indexable-route attribute R12 requires (shape: research D2).

- **Attributes**: route; locale; intent phrase ("the query this page answers"); normalized form (case/whitespace) for G5 comparison.
- **Consumers**: R13 coherence review; page↔intent inventory (R18); G4/G5.
- **Lifecycle**: route classified indexable → **unrecorded** (G4 fails — cannot ship) → **recorded** (must be unique per locale, else G5 fails) → **maintained** (copy iteration updates it in the same change, or the page is re-targeted; a stale record is a defect). Non-indexable routes never enter this lifecycle.

## Entity: Page↔Intent Inventory (in adopting projects)

- **Derivation**: route registry (indexable set) × intent records → machine-readable pairs; regeneration produces no diff (kin of the sitemap, R9).
- **Consumers**: any rank-tracking tool (SC-007); reviewers checking R13.

## Entity: Ownership-Verification Response (in adopting projects)

- **Source**: validated configuration (the S9 binding); one per console the project registers with.
- **Property**: survives redeploys; absent config → absent response (fail closed, nothing hand-placed).

## Entity: Landing URL Space (in adopting projects)

- **Attributes**: URL space; deliberate classification (R1 applies); direct-success obligation (R16); ad-parameter invariance (R15).
- **Note**: not a new registry concept — an existing route-registry entry with the paid-search rules bearing on it.

## Entity: Payload Budget & Loading Thresholds (in adopting projects)

- **Budget**: per-indexable-route weight ceiling, declared by the project, asserted by G6.
- **Thresholds**: the engines' published values on the three axes; measured (O17), never gated (clarification 2), never frozen into the doc (D5).

## Entity: Pack Binding Entry (delta)

States unchanged (`bound` | `unbound-declared`; `silent` forbidden — FR-014).

| Pack | Target state |
|---|---|
| `vercel`, `vercel-ssr`, `nextjs-nestjs-postgres` | `bound`: existing S1–S7 entries **plus S8–S10**, keyed, one line each, in `frontend.md` |
| `taro-fastify-mysql-tencent` | `unbound-declared`: declaration re-checked against the expanded add-on; residual posture stays refuse-indexing (D9) |

## Entity: Adoption Choice Point (delta)

| Location | Change |
|---|---|
| `add-ons/README.md` registry table | Row: capability wording tracks the new boundary; seam range **S1–S10** |
| Root `README.md` folder table + Day-1 step 6 | Verify only — wording doesn't state the old exclusion |
| Root `CLAUDE.md` repo map | Verify only |

## Relationships

```text
Guidance Document 1──contains──n Approach Rule (R1–R20)
Guidance Document 1──contains──n Seam Item (S1–S10)
Guidance Document 1──contains──n CI Gate (G1–G6);  Gate n──asserts──1 Rule
Pack Binding Entry n──answers──n Seam Item   (bound: all applicable S-ids)
Intent Record n──instantiates──1 Rule R12   (in adopting projects)
Intent Record n──feeds──1 Page↔Intent Inventory (R18)──consumed by──rank tracking (SC-007)
Route Classification 1──gains──0..1 Intent Record (indexable routes only)
```
