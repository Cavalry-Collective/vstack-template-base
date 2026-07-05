# Specs

Non-trivial features start from a short written spec here before implementation. The spec is the decision record: it stays after the work merges.

## Tooling

**Spec Kit is adopted** (`.specify/` + the `/speckit-*` skills): specs live in Spec Kit's numbered feature directories under `specs/`, created via `/speckit-specify`. The conventions below govern content whatever the layout. If a project swaps or drops the tool, record it in root `CLAUDE.md` → **Learnings** and keep `specs/` the single home.

## Conventions

- Tag user stories with priority: `P1` = MVP (must ship), `P2` = next, `P3` = nice-to-have.
- Each story is **independently shippable** — avoid cross-story coupling that breaks that; P1 stories alone form a viable MVP.

## What goes in a spec

1. **Goal** — one sentence: what this builds and why.
2. **User stories** — priority-tagged; each with acceptance criteria *and how each will be verified* (the exact command, endpoint call, or screen + states to exercise). A UI story that **builds a new screen** names the `design/` mockup file(s) it implements — "matches the referenced mockup" is part of done for the initial build (later iterations drift by design and verify against the running app). No mockup for a new screen → record it under **Open questions** and resolve before implementation; never invent the design.
3. **Out of scope** — explicit list of what this spec does not cover.
4. **Open questions** — decisions not yet made, each with a deadline or owner.
5. **UX & non-functional notes** (UI-touching specs) — form-factor impact, states (loading/error/empty), perf/security constraints. One short list, not an essay.

## Workflow

Feature work starts with a spec. Once approved: short-lived branch, PR linking the spec. A story is done only when every acceptance criterion has been demonstrated by its stated verification — evidence in the PR's Test plan. Merged specs stay as the record of the decision. Full loop: `docs/development-workflow.md` and `docs/adding-a-feature.md`.
