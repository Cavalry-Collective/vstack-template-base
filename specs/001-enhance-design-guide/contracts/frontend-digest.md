# Contract — Never-Violate Digest in `apps/frontend/CLAUDE.md`

FR-012 as clarified: a **minimal never-violate digest** — one compact block inside the
existing **"Design guide — the visual keystone"** section (research R5). Root `CLAUDE.md`
is untouched. This contract fixes the block's shape and bounds; exact prose is an
implementation detail.

## Shape

- One block, ≤ ~8 rule lines plus a one-line preamble; placed as a bulleted sub-list or
  short subsection inside the existing Design-guide section (no new top-level heading).
- Every line = **hard gate + owning guide chapter** (canonical pointer). No line carries
  detail that is absent from the guide (drift control: guide canonical, digest derived).

## Required entries (exactly these gates, one line each)

| # | Gate | Owning chapter (canonical) |
|---|---|---|
| 1 | Every colour/size/space/duration value resolves to a semantic token — a hex/px literal in a screen is the defect | Tokens |
| 2 | Pick the screen archetype before building any screen; page frame and rhythm come from it, never re-derived | Screen archetypes |
| 3 | Surfaces follow the ladder — no card-like container inside another; separators in order: whitespace → background shift → border → divider (tables/dense rows only) | Surfaces & elevation |
| 4 | Reuse-first: archetype → documented pattern → existing screens/primitives → extend a primitive → only then create new (justify exceptions in the PR) | Components & reuse |
| 5 | One density app-wide; never mixed within a page hierarchy | Screen archetypes |
| 6 | Forms and view states follow the composition patterns, whatever the component library — the pattern wins over library defaults | Forms · View states & feedback |

## Bounds & interactions

- **Incremental landing**: gates land with their owning stories — gates 1–5 with US3
  (tasks T023), gate 6 with US4 (T028). The six-gate contract is complete once US4
  ships; the 5-gate state between US3 and US4 is the correct incremental form, not a
  violation.
- **No duplication of existing contract text**: the section already mandates confirming
  the guide and consuming semantic tokens — the digest lines complement, not restate;
  where overlap is unavoidable (gate 1), the digest line replaces or absorbs the existing
  sentence rather than doubling it (root CLAUDE.md "one home per rule").
- **Stack packs**: the digest is stack-agnostic; no stack-pack appendix may weaken a gate
  (consistent with the packs' conflict-register mechanism).
- **Failure mode guarded**: an agent doing frontend work reads this file by contract
  (root `CLAUDE.md` requires it), so the gates are always-on — the survey's documented
  fix for agents ignoring detail-on-demand guidance.
