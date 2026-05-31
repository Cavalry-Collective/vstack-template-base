# Specs

Non-trivial features start from a short written spec here before implementation.

## Convention

- One file per feature: `YYYY-MM-DD-<feature-name>.md`
- Tag user stories with priority: `P1` = MVP (must ship), `P2` = next, `P3` = nice-to-have
- Each story is independently shippable — avoid cross-story coupling that breaks that independence
- P1 stories alone form a viable MVP

## What goes in a spec

1. **Goal** — one sentence on what this builds and why
2. **User stories** — priority-tagged, acceptance criteria per story
3. **Out of scope** — explicit list of what this spec does not cover
4. **Open questions** — decisions not yet made, with a deadline or owner

## Workflow

Feature work starts with a spec. Once approved, create a short-lived branch and open a PR that links the spec. When merged, the spec stays as a record of the decision.
