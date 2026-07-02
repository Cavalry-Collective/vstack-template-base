# Specs

Non-trivial features start from a short written spec here before implementation.

## Convention

- One file per feature: `YYYY-MM-DD-<feature-name>.md`
- Tag user stories with priority: `P1` = MVP (must ship), `P2` = next, `P3` = nice-to-have
- Each story is independently shippable — avoid cross-story coupling that breaks that independence
- P1 stories alone form a viable MVP

## What goes in a spec

1. **Goal** — one sentence on what this builds and why
2. **User stories** — priority-tagged; each carries acceptance criteria *and how each one will be verified* (the exact command, endpoint call, or screen + states to exercise). For a UI story that **builds a new screen**, name the specific `design/` mockup file(s) it implements (screen, copy, and flow); "matches the referenced mockup" is part of done for that initial build (later iterations drift from the mockup by design — they verify against the running app). If no mockup exists for a new screen, record it under **Open questions** and resolve it before implementation rather than inventing the design.
3. **Out of scope** — explicit list of what this spec does not cover
4. **Open questions** — decisions not yet made, with a deadline or owner
5. **UX & non-functional notes** — for UI-touching specs: primary form factor impact, states (loading/error/empty), and any perf/security constraints; one short list, not an essay

## Workflow

Feature work starts with a spec. Once approved, create a short-lived branch and open a PR that links the spec. A story is done only when every acceptance criterion has been demonstrated by its stated verification; capture that evidence in the PR's Test plan checklist. When merged, the spec stays as a record of the decision.
