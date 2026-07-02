# Corpus Baseline — captured 2026-07-03 at bdd463d

Coverage base for SC-001 (every file gets a verdict) and SC-003 (word-count target). Corpus per quickstart.md: every `*.md` outside `.git/`, `.claude/`, `.specify/`, `specs/`. Counts via `wc -w`, gitleaks 8.30.1 available for the history scan.

**Total: 36,978 words → SC-003 target ≤ 27,733**

## Guidance corpus (29 files)

| Words | File |
|---|---|
| 5,051 | apps/frontend/CLAUDE.md |
| 2,817 | apps/backend/CLAUDE.md |
| 2,804 | stacks/nextjs-nestjs-postgres/backend.md |
| 2,644 | stacks/nextjs-nestjs-postgres/db.md |
| 2,488 | CLAUDE.md |
| 2,035 | stacks/vercel/frontend.md |
| 1,837 | stacks/nextjs-nestjs-postgres/frontend.md |
| 1,778 | infra/CLAUDE.md |
| 1,580 | README.md |
| 1,411 | stacks/taro-fastify-mysql-tencent/frontend.md |
| 1,397 | stacks/taro-fastify-mysql-tencent/backend.md |
| 1,206 | stacks/taro-fastify-mysql-tencent/infra.md |
| 1,196 | stacks/vercel/backend.md |
| 1,183 | stacks/vercel/db.md |
| 1,182 | stacks/vercel/infra.md |
| 846 | stacks/taro-fastify-mysql-tencent/db.md |
| 724 | stacks/vercel/README.md |
| 722 | stacks/README.md |
| 685 | stacks/taro-fastify-mysql-tencent/README.md |
| 560 | db/CLAUDE.md |
| 525 | add-ons/otp-auth/README.md |
| 492 | design/README.md |
| 492 | add-ons/README.md |
| 479 | add-ons/test-mode/README.md |
| 463 | stacks/nextjs-nestjs-postgres/README.md |
| 304 | .github/PULL_REQUEST_TEMPLATE.md |
| 45 | .github/ISSUE_TEMPLATE/bug.md |
| 23 | .github/ISSUE_TEMPLATE/feature.md |
| 9 | db/migrations/README.md |

## Structural artifacts (audited, outside word target)

- `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`
- `.gitignore`
- Directory layout (`apps/`, `db/`, `infra/`, `design/`, `stacks/`, `add-ons/`, `specs/`)
- Vendored Spec Kit tooling: `.claude/skills/`, `.specify/` — **untracked in git** (not committed); flag-only scope
- `specs/001-enhance-design-guide/` — committed; disposition to be recommended (T012)

## Observations for the audit

- Five files carry ~43% of the corpus: frontend CLAUDE.md, backend CLAUDE.md, nextjs backend.md, nextjs db.md, root CLAUDE.md.
- The nextjs pack's `backend.md` (2,804) and `db.md` (2,644) are word-denser than most generic-tier files — possible tier imbalance (implementation detail volume vs. the pack median ~1,200).
- `db/migrations/README.md` is 9 words — likely a placeholder needing disposition.
