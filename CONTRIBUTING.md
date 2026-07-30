# Contributing

This repository is a template made of documents. Changes are almost always to a contract, so treat a wording change as seriously as a code change: an ambiguous rule misleads every project cloned afterwards.

## Before you open a PR

- Read [`CLAUDE.md`](CLAUDE.md). It governs this repository too — in particular **Documentation style** and **Development workflow**.
- Keep each rule in the one document that owns it, and link from everywhere else.
- Work on a short-lived branch off `main`. History is linear here: rebase, never merge-commit.
- Use Conventional Commits (`docs:`, `feat:`, `fix:`, `chore:`) with an imperative subject and one logical change per commit.

## What CI checks

`.github/workflows/template-integrity.yml` runs on every pull request. It verifies:

- whitespace invariants — LF endings, a final newline, no trailing whitespace;
- every relative Markdown link resolves;
- every stack pack has its four required files, and every appendix carries the verbatim precedence line and a conflict register;
- every add-on directory has a `README.md`;
- no active workflow mutes a check or ships a placeholder step.

Run the equivalent locally before pushing: `git diff --check` catches whitespace, and a broken link is usually a renamed file.

## Adding a stack pack or add-on

Follow the recipe in the index rather than copying a neighbour wholesale:

- stack packs — [`stacks/README.md`](stacks/README.md) → *Add a pack*;
- add-ons — [`add-ons/README.md`](add-ons/README.md).

A new pack must resolve its disagreements with the base contract in its conflict register. A silent contradiction is a defect.

## Version claims

Any pin — a framework major, a Node LTS, a managed runtime, a database engine — must be checked against the vendor's current documentation in the change that introduces it, and the reference linked. An end-of-life default is a bug, not a detail.

## Reporting problems

- A wrong, unclear, or contradictory rule: open an issue.
- A security concern: follow [`SECURITY.md`](SECURITY.md) instead.
