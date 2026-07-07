# Contract: Add-on Guidance Document (expansion delta)

**Consumers**: template adopters, coding agents in instantiated projects, template reviewers.
**Provider**: `add-ons/seo/README.md` (extended in place — the 003 contract's structure stays in force; this delta amends it).
**Validated by**: review against `add-ons/README.md` invariants + the checks in [quickstart.md](../quickstart.md).

## Required changes (section order unchanged from 003)

1. **Capability statement** — REWRITE: structural discoverability **plus** the structural work of keyword strategy, paid search, rank tracking, and page-speed ranking factors; names the ongoing practice of each (keyword research/selection, campaign purchase/management, running/reading rank reports, hands-on performance-tuning operations) as out of scope. The old "…are out of scope" sentence listing the four areas MUST NOT survive.
2. **Adoption fit** — unchanged (triage is about the public surface, which the expansion doesn't alter).
3. **Approach** — R1–R11 verbatim; **append R12–R20** per [data-model.md](../data-model.md), one bullet each, each stating an outside-observable behaviour.
4. **CI gates** — G1–G3 verbatim; **append G4–G6**, each one line, same parity-check anchor.
5. **Verify by observing** — **append per-rule checks for R12–R20** (fetch/measure X → expect Y); merging lines where rules share a fetch is allowed (size); every new rule MUST be covered exactly once.
6. **Binds to a stack** — S1–S7 verbatim; **append S8–S10** (see [stack-seam.md](stack-seam.md)); the unbound-declaration escape hatch stays.
7. **Interactions** — **append**: base quality/performance ownership split (base keeps general performance; this add-on owns only the indexable-page ranking-factor slice) and per-locale intent uniqueness deriving from the base i18n locale set. Only sections that exist in the base may be referenced.

## Invariants (hard)

- Stack-agnostic: zero framework/SDK/vendor/cloud names — including vendor metric names for page experience; the three axes are described generically (research D5). Web standards remain allowed vocabulary.
- ≤ ~150 lines (invariant ceiling); expansion target ≤ ~110 (research D8; clarification 3 — one doc, trimmed, no sibling add-on).
- Every rule checkable from outside a running app — no rule whose only check is reading code.
- IDs R/S/G/O used exactly as defined in the data model; R1–R11 / S1–S7 / G1–G3 never renumbered or reworded (capability statement excepted).
- Scope-clean, new boundary: no rule, gate, or seam item addresses keyword research/selection, campaign management, rank-report reading, or performance-tuning operations — the ongoing-practice terms appear only in the capability statement itself (spec *Scope*, SC-002).
