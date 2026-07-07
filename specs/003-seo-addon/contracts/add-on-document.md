# Contract: Add-on Guidance Document

**Consumers**: template adopters, coding agents in instantiated projects, template reviewers.
**Provider**: `add-ons/seo/README.md`.
**Validated by**: review against `add-ons/README.md` invariants + the checks in [quickstart.md](../quickstart.md).

## Required structure (order fixed)

1. **Title**: `# Add-on: seo`
2. **Opt-in banner** (blockquote, sibling-verbatim pattern): optional add-on; kept directory = adopted; the active stack pack supplies the concretes.
3. **Capability statement**: structural discoverability of public pages; names all four exclusions — keyword strategy, paid search, rank tracking, page-speed ranking factors (spec *Scope*, FR-014).
4. **Adoption fit** — 3-row triage table: fully public → adopt; mixed surface → adopt + classify private routes non-indexable; fully login-walled → delete (with the residual refuse-indexing note for publicly reachable origins).
5. **Approach** — rules R1–R11 per [data-model.md](../data-model.md), one bullet each, each stating an outside-observable behaviour.
6. **CI gates** — G1–G3, each one line, anchored "in the spirit of the i18n key-parity check".
7. **Verify by observing** — per-rule check list (fetch X → expect Y), one line per rule; ends with the index-coverage monitoring pointer (vendor-agnostic).
8. **Binds to a stack** — the enumerated seam S1–S7 (see [stack-seam.md](stack-seam.md)), plus the unbound-declaration escape hatch.
9. **Interactions** — base *URL routing*, *Configuration*, *Internationalisation*, *Microcopy & content*; add-on `test-mode` (fail-closed kinship). Only sections that exist in the base may be referenced (phantom references are defects).

## Invariants (hard)

- Stack-agnostic: zero framework/SDK/vendor/cloud names. Web standards (canonical, sitemap, robots, structured data, share tags) are allowed vocabulary.
- ≤ ~150 lines (invariant ceiling); redo budget ≤ ~70 (research D7).
- Every rule checkable from outside a running app — no rule whose only check is reading code.
- IDs R/S/G used exactly as defined in the data model (they are referenced by pack bindings and quickstart checks).
- Scope-clean: no rule, gate, or seam item addresses keyword strategy, paid search, rank tracking, or page-speed ranking factors — the exclusion terms appear only in the capability statement itself (spec *Scope*, SC-006).
