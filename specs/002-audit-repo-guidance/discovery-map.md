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
| stacks/nextjs-nestjs-postgres/README.md | both | stack-pack | one-hop ✅ (was two-hop) | root Repo shape: "a new adoption starts at the pack's own `README.md`" — adoption-time surface; work-time surface is the one-hop appendices |
| stacks/taro-fastify-mysql-tencent/README.md | both | stack-pack | one-hop ✅ (was two-hop) | same categorical pointer |
| stacks/vercel/README.md | both | stack-pack | one-hop ✅ (was two-hop) | same categorical pointer |
| db/migrations/README.md | both | generic-area | one-hop ✅ (was orphaned) | db/CLAUDE.md intro: "its `README.md` marks the folder" |
| .github/PULL_REQUEST_TEMPLATE.md | both | meta | one-hop ✅ (was orphaned) | root CLAUDE.md *Goal-driven execution* names `.github/PULL_REQUEST_TEMPLATE.md` |
| .github/ISSUE_TEMPLATE/bug.md | human | meta | n/a (GitHub UI) | human-facing only — acceptable if no unique agent-binding rules |
| .github/ISSUE_TEMPLATE/feature.md | human | meta | n/a (GitHub UI) | same |
| .claude/skills/** | agent | vendored | on skill invocation (harness) | untracked in git |
| .specify/** | agent | vendored | read by Spec Kit skills | untracked in git |

## At-risk summary — RESOLVED (US5 wiring, 2026-07-03)

1. `db/migrations/README.md` — ✅ de-orphaned: `db/CLAUDE.md` intro references it; the README frames the empty folder as deliberate and points back at the rules.
2. `stacks/<pack>/README.md` (×3) — ✅ root `CLAUDE.md` Repo shape now points categorically at "the pack's own `README.md`" for adoption; work-time guidance flows through the one-hop area appendices.
3. `.github/PULL_REQUEST_TEMPLATE.md` — ✅ root `CLAUDE.md` *Goal-driven execution* names the file where it states the Test-plan-evidence obligation.
4. Issue templates — ✅ verified human-only (T037): reporter requirements rendered by GitHub's UI; no agent-binding rule exists only there.

**SC-005 status: zero orphaned agent-binding files; every chain ≤ 1 hop from auto/lazy-loaded guidance.**
