# Phase 1 Data Model: SEO Add-on (redo)

**Feature**: `003-seo-addon` · **Date**: 2026-07-07 · **Input**: [spec.md](spec.md), [research.md](research.md)

The "data" of a docs-only capability is the structured content of its documents. The redo's core move (research D1–D6) is making that structure *enumerable*, so every downstream check is a lookup, not a judgment call. IDs below (R/S/G) are the shared vocabulary across the add-on README, pack bindings, contracts, and quickstart checks.

## Entity: Add-on Guidance Document

The agnostic playbook at `add-ons/seo/README.md`.

| Field | Value / constraint |
|---|---|
| Opt-in banner | Verbatim sibling pattern: kept directory = adopted; pack supplies concretes |
| Capability statement | Structural discoverability of public pages; names all four decreed exclusions — keyword strategy, paid search, rank tracking, page-speed ranking factors — where an adopter first reads it (spec *Scope*, FR-014; research D8) |
| Adoption-fit triage | 3-row table (research D5): fully public → adopt; mixed → adopt + classify; login-walled → delete (refuse-indexing posture still noted) |
| Approach rules | R1–R11 (below), one bullet each |
| CI gates | G1–G3 (below), anchored to the base parity-check pattern |
| Verification | Per-rule observable checks (research D4), one line per rule |
| Stack seam | Enumerated S1–S7 (research D1) |
| Interactions | Base *URL routing*, *Configuration*, *Internationalisation*, *Microcopy & content*; add-on `test-mode` |
| Size | ≤ ~70 lines (invariant ceiling ~150) |
| Wording | Stack-agnostic throughout — no framework, SDK, vendor, or cloud names |

## Entity: Approach Rule (R1–R11)

Each rule = one-line imperative + an outside-observable check. Rules marked ⚙ feed a CI gate.

| ID | Rule (essence) | Observable check |
|---|---|---|
| R1 ⚙G1 | Every route/URL space carries an indexable-or-not classification at the route registry | Registry review; G1 asserts completeness |
| R2 | Parameter/filter/pagination variants are non-indexable and canonical to their base page unless deliberately classified (no crawl traps) | Fetch a variant URL → canonical points at base page |
| R3 | Indexable pages are complete without client-side scripting | Fetch raw response → full content, title, description present |
| R4 | One canonical URL per page; variants redirect permanently; canonical origin from validated config | Fetch variant → permanent redirect; page declares one absolute canonical |
| R5 | Indexable URLs are stable; a slug rename keeps a permanent redirect from every previously published URL | Fetch old URL after rename → permanent redirect to new |
| R6 | Missing entity answers not-found/gone status, never success + error screen | Fetch nonexistent entity → 404/410 |
| R7 | All metadata (title, description, share tags **and share image**) flows through one shared helper; copy lives in the central copy home | Fetch page → unique title/description/share image present; helper is the only head-writing site |
| R8 | Structured entity markup only for real entity types, generated from displayed data | Markup content ⊆ page content |
| R9 ⚙G2 | Sitemap + robots generated from the route registry (+ entity data); sitemap lists exactly the indexable routes | Fetch sitemap → compare against registry classification |
| R10 ⚙G3 | Non-production origins refuse indexing, fail-closed; only the configured production origin is indexable | Fetch any staging page → noindex directive present |
| R11 | Crawlers see what users see — no user-agent content branching | Fetch as bot UA and as browser UA → same content |

## Entity: Stack Seam Item (S1–S7)

The question every pack must answer (or declare unbound against). S7 applies only to multilingual projects.

| ID | The pack names... |
|---|---|
| S1 | The rendering mechanism that makes indexable routes complete without client JS |
| S2 | The metadata helper and its home (title/description/canonical/share tags + share image) |
| S3 | The canonical-origin validated-config key home and the server/edge permanent-redirect mechanism |
| S4 | How sitemap and robots are generated from the route registry and served |
| S5 | How a missing entity becomes a real not-found status |
| S6 | The structured-data (entity markup) helper home |
| S7 | The locale-alternates (language variants) home — multilingual projects only |

## Entity: CI Gate (G1–G3)

Assertions the adopting project's suite/CI carries, in the spirit of the base i18n key-parity check.

| ID | Asserts | Silent failure prevented |
|---|---|---|
| G1 | Every route/URL space has a classification | New page ships unclassified → accidental (de)indexing |
| G2 | Sitemap ↔ route-registry derivation holds (no drift) | Hand-edited or stale sitemap |
| G3 | Non-production origins answer noindex | Staged copy gets indexed / outranks production |

## Entity: Pack Binding Entry

One per shipped stack pack. **States**: `bound` | `unbound-declared`. (`silent` — neither present — is the defect FR-012 forbids.)

| Field | bound | unbound-declared |
|---|---|---|
| Home | pack `frontend.md`, *Add-on bindings (if adopted)* | pack manifest `README.md` |
| Content | One short entry per seam item, keyed S1–S7 (S7 only if the pack pins a locale mechanism) | Reason (which seam items are unmeetable and why) + workable alternative + residual refuse-indexing posture (research D6/C10) |
| Audit | Every S-id present — greppable | Explicit statement — greppable |

Current-pack targets: both Next.js packs → `bound` (S1–S7); Taro H5 pack → `unbound-declared` (S1 unmeetable: client-only rendering).

## Entity: Route Classification (in adopting projects)

The per-route/URL-space attribute R1 requires.

- **Attributes**: route or URL space; `indexable` flag; canonical target (for non-indexable variants); recorded at the project's route registry (or the pack's designated registry replacement).
- **Consumers**: sitemap generation (indexable set), robots generation (disallowed set), per-page metadata (noindex directives), G1/G2.
- **Lifecycle**: route created → **unclassified** (G1 fails — cannot ship) → classified **indexable** (enters sitemap; must satisfy R3–R8) or **non-indexable** (robots/noindex; excluded from sitemap). On slug rename: old URL enters the **redirected** state permanently (R5).

## Entity: Adoption Choice Point

Where adopters discover the add-on (FR-013). All four already satisfied by the working tree; the redo touches them only if wording must track the new doc.

| Location | Required content |
|---|---|
| `add-ons/README.md` registry table | Row: capability one-liner + what the pack supplies |
| Root `README.md` folder table | SEO in the add-on examples list |
| Root `README.md` Day-1 step 6 | `seo` among the named options |
| Root `CLAUDE.md` repo map | SEO in the add-on examples list |

## Relationships

```text
Guidance Document 1──contains──n Approach Rule (R1–R11)
Guidance Document 1──contains──n Seam Item (S1–S7)
Guidance Document 1──contains──n CI Gate (G1–G3);  Gate n──asserts──1 Rule
Pack Binding Entry n──answers──n Seam Item   (bound: all applicable S-ids)
Route Classification n──instantiates──1 Rule R1   (in adopting projects)
Adoption Choice Point n──references──1 Guidance Document
```
