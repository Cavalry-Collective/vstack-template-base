# Contract: Stack Seam (add-on ⇄ stack packs)

**Consumers**: stack-pack authors (the shipped packs — four since `vercel-ssr`; future packs via `stacks/README.md` step 4).
**Provider**: the *Binds to a stack* section of `add-ons/seo/README.md`.

## The seam

A pack MUST take exactly one of two stances, and the stance MUST be determinable from that pack's own files alone (FR-012, SC-003).

### Stance A — bound

Home: `add-ons/seo/bindings.md`, section `## <pack> — bound`. (Originally the pack's `frontend.md` `## Add-on bindings (if adopted)` entry; relocated so the add-on's whole footprint lives in its own directory.)
Format: one short line per seam item, **keyed by S-id** so completeness is greppable:

| ID | The pack must name | Answer form (example shape, not content) |
|---|---|---|
| S1 | Rendering mechanism for indexable routes | "indexable routes render via ⟨mechanism⟩, complete without client JS" |
| S2 | Metadata helper home (incl. share image) | "⟨helper/API⟩ in ⟨location⟩ is the only head-writing site" |
| S3 | Canonical-origin config key home + permanent-redirect mechanism | "⟨key⟩ in the validated config; redirects via ⟨server/edge mechanism⟩" |
| S4 | Sitemap + robots generation & serving | "generated at ⟨location⟩ from ⟨the pack's registry binding⟩" |
| S5 | Missing entity → real not-found status | "⟨mechanism⟩ yields a genuine 404/410 response" |
| S6 | Structured-data helper home | "one shared ⟨component/helper⟩ fed by page data" |
| S7 | Locale-alternates home (multilingual only) | "alternates derive from ⟨the pack's locale mechanism⟩" — or "n/a: pack pins no locale mechanism" |

Rules: additions-only (never restate the base or the add-on); no project-specific values; a binding that contradicts a base rule goes through the pack's conflict register, never silently.

### Stance B — unbound-declared

Home: `add-ons/seo/bindings.md`, section `## <pack> — unbound`. (Originally the pack's manifest `README.md` per `stacks/README.md` step 4; relocated with Stance A.)
Must contain: (1) **which seam item(s) are unmeetable and why** (e.g. S1: client-only rendering); (2) **the workable alternative** for a project that grows a public surface; (3) **the residual posture** — a publicly reachable origin that shouldn't appear in search results still serves the refuse-indexing response (R10 posture survives unbinding).

## Compliance check

For each pack directory under `stacks/`: grep `add-ons/seo/bindings.md` for a section named after the pack. Exactly one stance present; if Stance A, all of S1–S6 present (S7 present or explicitly n/a). Anything else = FR-012 violation.
