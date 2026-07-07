# Contract: Stack Seam (expansion delta — S8–S10)

**Consumers**: stack-pack authors (the four shipped packs now; future packs via `stacks/README.md` step 4).
**Provider**: the *Binds to a stack* section of `add-ons/seo/README.md`.
**Base**: the 003 stack-seam contract (S1–S7, two stances) stays in force; this delta extends Stance A and re-scopes Stance B's accuracy obligation.

## Stance A — bound (extended)

Home unchanged: the pack's `frontend.md`, under `## Add-on bindings (if adopted)`, entry `**seo**`.
Format unchanged: one short line per seam item, **keyed by S-id**. Three items join:

| ID | The pack must name | Answer form (example shape, not content) |
|---|---|---|
| S8 | Intent-record home on the pack's registry binding + inventory derivation | "each indexable ⟨registry entry⟩ carries the intent phrase; the page↔intent inventory generates at ⟨location⟩ from it" |
| S9 | Ownership-verification serving from validated config | "⟨config key⟩ → verification served via ⟨mechanism⟩; absent key → absent response" |
| S10 | Payload-budget home + suite assertion; loading-experience measurement mechanism | "budget declared in ⟨location⟩, asserted by ⟨suite mechanism⟩ (G6); the three axes measured with ⟨tooling⟩" |

Rules unchanged: additions-only; no project-specific values; concrete vendor metric/tool names are **allowed here** (this is the pack — research D5); contradictions go through the pack's conflict register, never silently.

## Stance B — unbound-declared (accuracy re-scoped)

Home unchanged: the pack's manifest `README.md`. The declaration MUST remain accurate against the **expanded** add-on: with no indexable surface the new rules attach to nothing, so the residual posture remains the refuse-indexing response (R10). If the existing wording already holds, no edit is required — accuracy, not enumeration, is the obligation (research D9).

## Compliance check

For each pack directory under `stacks/`: grep its files for `add-ons/seo`. Exactly one stance present. If Stance A: all of S1–S6 and S8–S10 present (S7 present or explicitly n/a). If Stance B: reason + alternative + residual posture, still true of the expanded doc. Anything else = FR-014 violation. Four packs; zero silent (SC-005).
