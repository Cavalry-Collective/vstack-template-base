# docs/ — guides

Guides for humans (and curious agents). **Guides explain; contracts bind.** The binding rules live in the root `CLAUDE.md` and the per-area contracts (`apps/*/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md`); if a guide and a contract ever disagree, the contract wins and the guide has a bug — fix the guide.

Read in this order when joining a project built from this template:

| Guide | Answers |
|---|---|
| [`getting-started.md`](getting-started.md) | How do I instantiate the template? (run once, Day 1) |
| [`architecture.md`](architecture.md) | How does the system fit together? |
| [`project-structure.md`](project-structure.md) | What belongs in each directory — and what doesn't? |
| [`development-workflow.md`](development-workflow.md) | How does work flow from spec to merged trunk? |
| [`adding-a-feature.md`](adding-a-feature.md) | What does one full feature slice touch, end to end? |
| [`testing.md`](testing.md) | What do we test, where, and with what kind of test? |
| [`configuration.md`](configuration.md) | How do env vars, config, and flags work? |
| [`agents.md`](agents.md) | How do AI agents work in this repo? |
| [`contributing.md`](contributing.md) | Commit, PR, and review conventions |

Keep these current: a change that alters structure, workflow, commands, or a public contract updates the affected guide **in the same change** (root contract, *Working rules for agents → Reporting*).
