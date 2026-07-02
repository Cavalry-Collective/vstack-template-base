# Scan Evidence — 2026-07-03, commit bdd463d (branch worktree-002-audit-repo-guidance)

## T005 — Secret scan (FR-011)

- Tool: gitleaks **8.30.1** — `gitleaks git . --redact --no-banner`
- Scope: full git history, **54 commits**, ~817 KB scanned
- Result: **no leaks found** ✅

## T006 — Internal references & personal data (FR-011)

**Working tree** (all files, excluding `.git/`, `.claude/`, `.specify/`):

- Email-shaped strings: only `name@company.com` (an intentional placeholder) ✅
- URLs: `code.claude.com` docs citation (in specs/002), `fonts.googleapis.com` / `fonts.gstatic.com` (design guide webfonts), `zeroheight.com/showcase/` (public reference) — no internal hosts ✅
- IP-shaped strings: only `0.0.0.0` ✅

**Git history author/committer identities** (published if the repo goes public):

| Email | Assessment |
|---|---|
| `adam@cavalry.sg` | company address — normal for a company repo |
| `adam@cavalry.online` | company address — normal |
| `adam@raspberri.es` | **personal-looking address** — release-gate decision needed: accept exposure, or rewrite history (destructive) |

→ Finding F-001 (release-blocking, pending maintainer disposition).

## T008 — Cross-reference check (FR-008)

- Every relative markdown link in the corpus resolves: **0 broken links** ✅
- Reference-edge scan (which loaded files point at each README-named file):
  - `specs/README.md`, `stacks/README.md`, `add-ons/README.md`, `README.md` ← root `CLAUDE.md` ✅
  - `design/README.md` ← `apps/frontend/CLAUDE.md` ✅
  - add-on READMEs ← root's categorical rule ("every directory kept under `add-ons/` is adopted — read its `README.md`") ✅
  - stack pack area docs (`backend/frontend/db/infra.md`) ← categorical pointers in each matching area `CLAUDE.md` ✅
  - `db/migrations/README.md` ← **nothing** (orphaned)
  - `stacks/<pack>/README.md` ← only via `stacks/README.md` (two hops from auto-loaded guidance)
  - `.github/PULL_REQUEST_TEMPLATE.md` ← no guidance pointer (GitHub UI only)
