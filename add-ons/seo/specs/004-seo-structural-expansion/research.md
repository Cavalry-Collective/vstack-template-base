# Phase 0 Research: SEO Add-on — Structural Expansion

**Feature**: `004-seo-structural-expansion` · **Date**: 2026-07-07 · **Input**: [spec.md](spec.md), shipped `add-ons/seo/README.md` (R1–R11, S1–S7, G1–G3), `add-ons/seo/specs/003-seo-addon/` design artifacts

The open judgments behind the spec, resolved as decisions. D1, D4, D8 restate what `/speckit-clarify` ratified (they anchor the rest); D2 resolves the item clarify deferred to planning.

## D1 — Reversal semantics: what "structural" admits

- **Decision**: In scope = what is built once into the project and observable from outside the running app (records, rules, gates, served artifacts). Out = any recurring human practice: researching/choosing keywords, buying or managing campaigns, running or reading rank reports, hands-on performance-tuning operations. Every candidate rule was screened against this line.
- **Rationale**: Ratified in clarification 1; it keeps the add-on's defining property — every rule checkable by fetch or grep, none requiring marketing judgment.
- **Alternatives considered**: Including ongoing-practice SOPs (rejected in clarify — a marketing-facing doc agents can't verify); keeping the exclusion (rejected — renders the request a no-op).

## D2 — Intent record shape *(resolves the deferred clarify item)*

- **Decision**: One short free-text phrase per indexable route per locale — "the query this page answers" — recorded at the route registry beside the indexable classification. Uniqueness (G5) compares normalized phrases (case/whitespace) within a locale.
- **Rationale**: A phrase is writable at route-creation time without keyword research (structural, per D1); living at the registry keeps one audit surface (the 003 pattern) and makes G4/G5 registry-derivable, as clarification 2 requires; it gives R13's coherence review and R18's inventory a concrete source.
- **Alternatives considered**: Structured record (primary + secondary keywords, volume) — rejected: ongoing-practice creep, unverifiable structurally. Separate keyword file — rejected: a second home drifts from the registry; violates the derive-don't-duplicate posture of R9/R18. No record, infer intent from the title — rejected: nothing to gate, duplicates undetectable before both pages ship.

## D3 — Extend the shared ID vocabulary, don't fork it

- **Decision**: New approach rules are **R12–R20**, seam items **S8–S10**, gates **G4–G6**, observable clauses **O11–O18** — continuing 003's numbering, same sections of the same document, used identically in packs, contracts, and quickstart. R1–R11 / S1–S7 / G1–G3 are never renumbered or reworded beyond the capability statement.
- **Rationale**: The vocabulary is the mechanism that made 003 mechanically auditable; a second scheme would give packs and reviewers two registries to cross-reference.
- **Alternatives considered**: Per-area prefixes (K/P/T/V ids) — rejected: two vocabularies in one doc. Appendix sub-document — rejected by clarification 3 (one doc, trim to fit).

## D4 — Gate split (ratified)

- **Decision**: Three new day-1 gates: **G4** intent record present for every indexable route; **G5** no same-locale duplicate intents; **G6** every indexable route within the declared payload budget. Orphan reachability (R14) and loading-experience thresholds (R19) are verify-by-observation only.
- **Rationale**: Ratified in clarification 2. G4/G5 derive from the registry like G1/G2; G6 asserts build output. The observation-only pair needs a rendered, crawled, measured app — day-1 CI can't carry that in every adopting project.
- **Alternatives considered**: Gating everything measurable (rejected — heavyweight tooling mandated on day 1); budget-only (rejected — duplicate intents would ship silently, the exact failure the area exists to prevent).

## D5 — Agnostic naming for page-experience

- **Decision**: The add-on names the bar as "the search engines' published loading-experience thresholds" across three axes — main-content loading, responsiveness to input, visual stability — and freezes no numbers and no vendor vocabulary. The active pack names the concrete metrics and measurement tooling (S10).
- **Rationale**: Vendor metric names and numeric thresholds are revised by the engines; the invariant bans vendor names from add-ons. The three axes are stable across revisions; packs are the licensed home for concrete names.
- **Alternatives considered**: Naming the vendor metric set in the add-on — rejected: violates the agnostic invariant and rots. Freezing numeric targets — rejected: the doc would silently drift from the real ranking bar (spec edge case).

## D6 — Paid-search boundary: landing readiness only

- **Decision**: Two rules — advertising click parameters never fork content or leak into canonicals/sitemap (R15); landing URLs answer success directly, at most one permanent alias hop (R16). No conversion-event seam, no campaign or destination-quality guidance.
- **Rationale**: Param-invariance and direct answers are structural and fetch-checkable; conversion measurement is analytics, out of scope per spec assumptions (and 003's).
- **Alternatives considered**: A conversion-tracking seam item — rejected: analytics exclusion. UTM taxonomy guidance — rejected: campaign practice, D1's wrong side.

## D7 — Rank-tracking boundary: trackability artifacts only

- **Decision**: Two rules — ownership verification served from validated config (R17); a machine-readable page↔intent inventory derived from the registry (R18). URL continuity under renames is already R5 and is referenced, not restated.
- **Rationale**: These are the exactly-two artifacts any console or tracking tool needs that the project can serve structurally (SC-007); everything further (choosing a tracker, reading reports) is ongoing practice.
- **Alternatives considered**: Recommending or integrating a tracker — rejected: vendor naming + ongoing practice. Putting the inventory in the sitemap — rejected: sitemaps have a fixed standard schema with no intent field; a sidecar derivation keeps both honest.

## D8 — Size budget (ratified)

- **Decision**: The expanded `add-ons/seo/README.md` targets **≤ ~110 lines** (invariant ceiling ~150): one bullet per rule, no per-area subsections, verify lines merged where rules share a fetch, interactions updated in place.
- **Rationale**: Ratified in clarification 3 (one doc, trim to fit). Current doc is 73 lines; the expansion adds 9 rules, 3 gates, 3 seams, ~6 verify lines, ~2 interaction lines ≈ +25–35 — inside budget with terse wording.
- **Alternatives considered**: Sibling add-on, relaxed invariant — both rejected in clarify.

## D9 — Binding surface is now four packs

- **Decision**: The three bound packs (`vercel`, `vercel-ssr`, `nextjs-nestjs-postgres`) each append S8–S10-keyed lines to their existing `**seo**` binding entry in `frontend.md`. The `taro-fastify-mysql-tencent` unbound declaration is re-checked against the expanded add-on: with no indexable surface, the new rules attach to nothing, so the residual posture stays refuse-indexing (R10) — the declaration is extended only if its wording no longer holds. The `add-ons/README.md` registry row's seam range becomes S1–S10.
- **Rationale**: `vercel-ssr` shipped after 003's plan (which named three packs); spec FR-014/SC-005 count four. Unbinding is per-add-on, not per-rule — the declaration's job is accuracy, not enumeration.
- **Alternatives considered**: A separate binding subsection per area — rejected: the S-keyed flat list is the audited format 003 established.
