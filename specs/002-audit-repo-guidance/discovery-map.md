# Instruction-Discovery Map — 2026-07-03 (T007, FR-003)

How the coding agent encounters each file, per the documented loading model (research.md R1): only `CLAUDE.md`-named files load automatically — root at session start, nested ones lazily on subtree entry. Everything else is read **only** when a loaded file points at it. `@`-imports are eager (would defeat "context light") and are correctly not used.

| File | Audience | Tier | Loading | Via |
|---|---|---|---|---|
| CLAUDE.md | agent+human | root | **auto** (session start) | naming convention |
| apps/backend/CLAUDE.md | agent | generic-area | **lazy-subtree** | naming convention |
| apps/frontend/CLAUDE.md | agent | generic-area | **lazy-subtree** | naming convention |
| db/CLAUDE.md | agent | generic-area | **lazy-subtree** | naming convention |
| infra/CLAUDE.md | agent | generic-area | **lazy-subtree** | naming convention |
| README.md | both | root | one-hop | root CLAUDE.md (Day-1 checklist pointer) |
| specs/README.md | both | meta | one-hop | root CLAUDE.md |
| stacks/README.md | both | meta | one-hop | root CLAUDE.md |
| add-ons/README.md | both | add-on | one-hop | root CLAUDE.md |
| add-ons/test-mode/README.md | agent+human | add-on | one-hop | root categorical rule ("every kept add-on: read its README") |
| add-ons/otp-auth/README.md | agent+human | add-on | one-hop | root categorical rule |
| design/README.md | both | meta | one-hop | apps/frontend/CLAUDE.md |
| stacks/*/backend.md (×3) | agent | stack-pack | one-hop | apps/backend/CLAUDE.md categorical ("read the adopted pack's backend.md") |
| stacks/*/frontend.md (×3) | agent | stack-pack | one-hop | apps/frontend/CLAUDE.md categorical |
| stacks/*/db.md (×3) | agent | stack-pack | one-hop | db/CLAUDE.md categorical |
| stacks/*/infra.md (×2) | agent | stack-pack | one-hop | infra/CLAUDE.md categorical (conditional "if it ships one") |
| stacks/nextjs-nestjs-postgres/README.md | both | stack-pack | **two-hop** ⚠️ | root → stacks/README.md → pack README |
| stacks/taro-fastify-mysql-tencent/README.md | both | stack-pack | **two-hop** ⚠️ | same chain |
| stacks/vercel/README.md | both | stack-pack | **two-hop** ⚠️ | same chain |
| db/migrations/README.md | unclear | generic-area | **orphaned** ⚠️ | nothing references it |
| .github/PULL_REQUEST_TEMPLATE.md | both | meta | **orphaned** ⚠️ | GitHub UI renders it for humans; no guidance pointer for agents (root mentions "the PR template" without a path) |
| .github/ISSUE_TEMPLATE/bug.md | human | meta | n/a (GitHub UI) | human-facing only — acceptable if no unique agent-binding rules |
| .github/ISSUE_TEMPLATE/feature.md | human | meta | n/a (GitHub UI) | same |
| .claude/skills/** | agent | vendored | on skill invocation (harness) | untracked in git |
| .specify/** | agent | vendored | read by Spec Kit skills | untracked in git |

## At-risk summary (feeds FR-007 wiring in US5)

1. `db/migrations/README.md` — orphaned; 9 words; disposition needed (delete, or fold its content into `db/CLAUDE.md`).
2. `stacks/<pack>/README.md` (×3) — two hops from auto-loaded guidance. Mitigation: they are instantiation-time documents (a human-led moment via the Day-1 checklist), and post-instantiation work flows through the one-hop area appendices — wire an explicit pointer or accept with rationale.
3. `.github/PULL_REQUEST_TEMPLATE.md` — carries the Test-plan-evidence expectation agents must satisfy; root CLAUDE.md names the obligation but not the file. One explicit pointer fixes it.
4. Issue templates — human-only, no unique binding rules (verify in T037).
