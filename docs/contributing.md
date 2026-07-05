# Contributing

Conventions for humans and agents alike. The binding versions live in root `CLAUDE.md` (*Development workflow*, *Self-review before merge*, *Definition of Done*); this is the quick reference.

## Branches

Short-lived, off `main`, in a worktree: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `refactor/<topic>`, `spike/<topic>` (spikes never merge). Rebase onto trunk; history stays linear — no merge commits.

## Commits

Conventional Commits, imperative subject, one logical change per commit:

```
feat(billing): add invoice issuing use case
fix(frontend): keep focus on trigger after modal close
docs(db): record the pack's forward-only migration gate
```

- `feat` / `fix` / `docs` / `refactor` / `test` / `chore`, optional scope.
- Reviewer notes ("moved X because Y") go in the commit body — never in code comments.
- Refactors are their own commits (and usually their own PRs), never folded into features.

## Pull requests

- Small where practical; one spec story is a good size.
- Fill the template honestly: the Test plan holds **observed evidence** (commands run, output seen, states forced), not "tests pass".
- Link the spec. New abstractions/dependencies/config keys each carry their one-line justification (the simpler option and why it was rejected). New code names the existing pattern it follows — or says why none fits.
- UI changes attach before/after screenshots at the primary form factor and the narrow width.

## Review checklist (what reviewers actually check)

1. Right layer/ring — no business logic in controllers, repos, pages, or utils.
2. Scope — nothing unrelated reformatted, renamed, or refactored.
3. Names state business meaning.
4. Tests assert behaviour and shipped in this PR.
5. Public contracts unbroken (routes, shapes, error codes, i18n keys, migrations) — or the break was explicitly decided.
6. Contracts/docs updated if structure, workflow, commands, or contracts changed.
7. Evidence in the Test plan is observation, not inference.

## Merging

The merge-back gate is ordered and non-negotiable: rebase → full suite green on the rebased state → fast-forward merge → clean up worktree/branch → push only after confirming (a green `main` deploys once `deploy.yml` is filled in). Never merge red; incomplete work goes behind a default-off flag.

## After merging

Record durable learnings in root `CLAUDE.md` → **Learnings** (one line each). Specs remain as decision records — don't delete them.
